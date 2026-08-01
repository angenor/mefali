//! Surface HTTP **CLIENT** du cycle PAY (crate `paiements`) : ouverture de
//! session de prépaiement, lecture de son état, reçu de commande.
//!
//! Contrat auto-collecté par utoipa-actix-web (patron `commandes_http`). Toute
//! route sous `bearerAuth`, rôle `Client`, et **propriété vérifiée dans le
//! domaine** — `paiements::session` compare le propriétaire de la commande à
//! l'appelant avant toute autre chose, y compris avant de dire si un paiement
//! est requis (sinon un tiers apprendrait que la commande existe).
//!
//! Erreurs rendues `{ code, message_cle }` par [`crate::erreurs_paiements`].
//!
//! # Ce que cette surface ne fait jamais
//!
//! Elle **ne crédite rien**. Ni l'ouverture, ni la lecture, ni un retour de
//! navigateur ne confirment un paiement : seule une notification signée, ou une
//! réconciliation auprès du fournisseur, le fait (FR-025). Un client qui revient
//! par le lien de succès voit ici l'état que le **serveur** connaît.

use actix_web::{get, post, web, HttpResponse};
use commandes::PgCommandes;
use comptes::Role;
use paiements::{PaymentProvider, PgPaiements, Transaction};
use serde::Serialize;
use std::sync::Arc;
use utoipa::ToSchema;
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::erreurs_paiements::ErreurPaiementsHttp;

// ── DTO de sortie ──────────────────────────────────────────────────────────

/// État d'une session de prépaiement, tel que l'app cliente le lit.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = SessionPaiement)]
pub struct SessionPaiementDto {
    /// Transaction de paiement.
    pub transaction_id: Uuid,
    /// État : `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
    pub etat: String,
    /// Montant **figé** à l'ouverture (unités mineures).
    pub montant_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Moyen effectivement employé, tel que le fournisseur l'a dit.
    /// `inconnu` tant qu'il ne l'a pas dit — jamais deviné (FR-012).
    pub moyen: String,
    /// Page de paiement à ouvrir dans le **navigateur système**.
    ///
    /// `null` dès que l'état quitte `ouverte` : la colonne est effacée à
    /// l'issue, et un accès d'encaissement survivant à son paiement est une
    /// surface d'attaque sans usage (FR-006).
    pub acces_paiement: Option<String>,
    /// Échéance **persistée**, calculée depuis `paiement.session_duree_s`.
    pub expire_le: chrono::DateTime<chrono::Utc>,
    /// Secondes restantes, **calculées côté serveur** (FR-017).
    ///
    /// L'horloge de l'app ne décide de rien : elle affiche un compte à rebours
    /// qu'elle recale sur cette valeur à chaque lecture. Vaut `0` sur une
    /// session échue, jamais un nombre négatif.
    pub restant_s: i64,
}

impl SessionPaiementDto {
    fn depuis(t: Transaction, maintenant: chrono::DateTime<chrono::Utc>) -> Self {
        let restant_s = t.restant_s(maintenant);
        Self {
            restant_s,
            transaction_id: t.id,
            etat: t.etat.comme_str().to_owned(),
            montant_unites: t.montant_unites,
            devise: t.devise,
            moyen: t.moyen.comme_str().to_owned(),
            // Double sécurité avec l'effacement en base : si un jour un chemin
            // d'écriture oubliait de vider la colonne, la lecture ne la
            // servirait pas pour autant.
            acces_paiement: if t.etat.accepte_paiement() {
                t.acces_paiement
            } else {
                None
            },
            expire_le: t.expire_le,
        }
    }
}

// ── Routes ─────────────────────────────────────────────────────────────────

/// Ouvre — ou renvoie — la session de prépaiement d'une commande.
#[utoipa::path(
    post,
    path = "/commandes/{id}/paiement",
    tag = "paiements",
    params(("id" = Uuid, Path, description = "Commande du compte appelant, en attente de paiement.")),
    responses(
        (status = 200, description = "Session vivante — créée, ou RETROUVÉE si l'appel est rejoué. \
         Rappeler cette route tant que la session vit ne rouvre rien chez le fournisseur : \
         l'identifiant de commande EST la clé d'idempotence (FR-015).",
         body = SessionPaiementDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis, ou commande d'un autre compte.",
         body = ErreurApiDto),
        (status = 404, description = "Commande inconnue.", body = ErreurApiDto),
        (status = 409, description = "La commande n'attend aucun paiement : espèces, déjà réglée, \
         ou plus en attente.", body = ErreurApiDto),
        (status = 502, description = "Fournisseur injoignable ou en erreur. La commande reste \
         INTACTE — rien n'a été écrit, l'appel peut être retenté (FR-018).", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/commandes/{id}/paiement")]
pub async fn ouvrir_paiement(
    auth: Auth,
    chemin: web::Path<Uuid>,
    paiements: web::Data<PgPaiements>,
    commandes: web::Data<PgCommandes>,
    fournisseur: web::Data<Arc<dyn PaymentProvider>>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    auth.exiger_role(Role::Client)?;
    let commande_id = chemin.into_inner();

    let transaction = paiements::ouvrir_session(
        paiements.get_ref(),
        commandes.get_ref(),
        fournisseur.get_ref().as_ref(),
        commande_id,
        auth.compte_id,
    )
    .await?;

    let maintenant = paiements.maintenant();
    Ok(HttpResponse::Ok().json(SessionPaiementDto::depuis(transaction, maintenant)))
}

/// État de la session de prépaiement d'une commande.
#[utoipa::path(
    get,
    path = "/commandes/{id}/paiement",
    tag = "paiements",
    params(("id" = Uuid, Path, description = "Commande du compte appelant.")),
    responses(
        (status = 200, description = "État de la DERNIÈRE session, quel qu'il soit : après une \
         expiration, le client lit « expirée » plutôt qu'un 404 qui lui laisserait croire qu'il \
         n'a jamais rien tenté. `restant_s` est calculé côté SERVEUR (FR-017).",
         body = SessionPaiementDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis, ou commande d'un autre compte.",
         body = ErreurApiDto),
        (status = 404, description = "Aucune session pour cette commande — le cas d'une commande \
         payée en espèces.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/commandes/{id}/paiement")]
pub async fn etat_paiement(
    auth: Auth,
    chemin: web::Path<Uuid>,
    paiements: web::Data<PgPaiements>,
    commandes: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    auth.exiger_role(Role::Client)?;
    let commande_id = chemin.into_inner();

    let transaction = paiements::lire_session(
        paiements.get_ref(),
        commandes.get_ref(),
        commande_id,
        auth.compte_id,
    )
    .await?;

    let maintenant = paiements.maintenant();
    Ok(HttpResponse::Ok().json(SessionPaiementDto::depuis(transaction, maintenant)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use paiements::{EtatTransaction, MoyenPaiement};

    fn transaction(etat: EtatTransaction) -> Transaction {
        let ouverte = chrono::Utc::now();
        Transaction {
            id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            montant_unites: 12_500,
            devise: "XOF".to_owned(),
            etat,
            moyen: MoyenPaiement::Inconnu,
            fournisseur: "simule".to_owned(),
            reference_fournisseur: Some("ref".to_owned()),
            acces_paiement: Some("https://paiement.invalid/x".to_owned()),
            ouverte_le: ouverte,
            expire_le: ouverte + chrono::Duration::seconds(900),
            issue_le: None,
        }
    }

    /// Une session vivante sert son accès de paiement — c'est sa raison d'être.
    #[test]
    fn une_session_ouverte_sert_son_acces() {
        let t = transaction(EtatTransaction::Ouverte);
        let maintenant = t.ouverte_le;
        let dto = SessionPaiementDto::depuis(t, maintenant);
        assert!(dto.acces_paiement.is_some());
        assert_eq!(dto.restant_s, 900);
        assert_eq!(dto.etat, "ouverte");
    }

    /// Dès que l'état quitte `ouverte`, l'accès disparaît de la réponse —
    /// **même si** la colonne portait encore une valeur. La base l'efface déjà ;
    /// ce test ferme le second chemin, celui de la lecture.
    #[test]
    fn une_session_close_ne_sert_plus_son_acces() {
        for etat in [
            EtatTransaction::Reglee,
            EtatTransaction::Expiree,
            EtatTransaction::PayeeHorsDelai,
        ] {
            let t = transaction(etat);
            let maintenant = t.ouverte_le;
            let dto = SessionPaiementDto::depuis(t, maintenant);
            assert!(
                dto.acces_paiement.is_none(),
                "état {} : l'accès ne doit plus être servi (FR-006)",
                etat.comme_str(),
            );
            assert_eq!(dto.restant_s, 0, "plus rien à attendre");
        }
    }

    /// Une session REFUSÉE vit encore : le client réessaie sur le même accès
    /// tant que l'échéance n'est pas franchie (FR-026).
    #[test]
    fn une_session_refusee_sert_encore_son_acces() {
        let t = transaction(EtatTransaction::Echouee);
        let maintenant = t.ouverte_le;
        let dto = SessionPaiementDto::depuis(t, maintenant);
        assert!(dto.acces_paiement.is_some());
        assert!(dto.restant_s > 0);
    }

    /// Le temps restant ne descend jamais sous zéro : un compte à rebours
    /// négatif à l'écran serait un bug visible d'Awa.
    #[test]
    fn le_restant_ne_descend_pas_sous_zero() {
        let t = transaction(EtatTransaction::Ouverte);
        let bien_apres = t.expire_le + chrono::Duration::seconds(500);
        assert_eq!(SessionPaiementDto::depuis(t, bien_apres).restant_s, 0);
    }
}
