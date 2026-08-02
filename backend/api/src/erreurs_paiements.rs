//! Mapping HTTP des refus du domaine paiement — `{ code, message_cle }`.
//!
//! **Un seul endroit** pour les trois surfaces du cycle (`paiements_http`
//! client, `paiements_webhook_http` fournisseur, `admin_paiements_http`
//! exploitation) : un refus doit rendre le même statut et la même clé, quelle
//! que soit la porte par laquelle on est entré. Le patron est celui
//! d'[`crate::erreurs_commandes`], et la raison de ne pas le dupliquer par
//! module est la même : deux mappings divergent au premier correctif.
//!
//! Le domaine porte la clé **courte** (`ErreurPaiements::message_cle`), la
//! couche HTTP la préfixe de son espace de noms i18n (`paiement.erreur.…`).
//! Aucune chaîne utilisateur n'est écrite ici (constitution VII).

use actix_web::http::StatusCode;
use actix_web::{HttpResponse, ResponseError};
use paiements::ErreurPaiements;
use serde_json::json;

use crate::auth_http::ErreurApi;

/// Erreur HTTP des surfaces paiement : auth/rôle (`ErreurApi`) ou refus du
/// domaine (`ErreurPaiements`).
#[derive(Debug)]
pub enum ErreurPaiementsHttp {
    /// Erreur d'authentification / de rôle (réutilise le mapping comptes).
    Api(ErreurApi),
    /// Refus métier ou panne du domaine paiement.
    Domaine(ErreurPaiements),
}

impl From<ErreurApi> for ErreurPaiementsHttp {
    fn from(e: ErreurApi) -> Self {
        ErreurPaiementsHttp::Api(e)
    }
}

impl From<ErreurPaiements> for ErreurPaiementsHttp {
    fn from(e: ErreurPaiements) -> Self {
        ErreurPaiementsHttp::Domaine(e)
    }
}

impl From<commandes::ErreurCommandes> for ErreurPaiementsHttp {
    fn from(e: commandes::ErreurCommandes) -> Self {
        ErreurPaiementsHttp::Domaine(ErreurPaiements::Commandes(e))
    }
}

impl std::fmt::Display for ErreurPaiementsHttp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErreurPaiementsHttp::Api(e) => write!(f, "{e}"),
            ErreurPaiementsHttp::Domaine(e) => write!(f, "{e}"),
        }
    }
}

/// Statut HTTP d'un refus du domaine (contrat `paiements-openapi.md`).
///
/// Quatre familles :
/// - **401** — signature de notification absente, invalide ou périmée : la
///   seule garde du webhook, qui n'a pas de porteur ;
/// - **403** — la commande n'appartient pas à l'appelant (FR-005) ;
/// - **404** — aucune transaction (commande cash), fournisseur inconnu du
///   segment d'URL, dossier inexistant ;
/// - **409** — l'état s'y oppose : paiement non requis, session expirée,
///   transition refusée, dossier déjà clos ;
/// - **502** — le fournisseur est injoignable ou a refusé. La commande reste
///   **intacte** (FR-018) : c'est la différence entre « réessayez » et « votre
///   commande est perdue ».
pub fn statut(e: &ErreurPaiements) -> StatusCode {
    match e {
        ErreurPaiements::SignatureInvalide => StatusCode::UNAUTHORIZED,

        ErreurPaiements::CommandeNonProprietaire => StatusCode::FORBIDDEN,

        ErreurPaiements::TransactionInconnue
        | ErreurPaiements::FournisseurInconnu(_)
        | ErreurPaiements::DossierInconnu(_) => StatusCode::NOT_FOUND,

        ErreurPaiements::PaiementNonRequis
        | ErreurPaiements::SessionExpiree
        | ErreurPaiements::TransitionRefusee { .. }
        | ErreurPaiements::DossierDejaClos => StatusCode::CONFLICT,

        ErreurPaiements::MotifRequis
        | ErreurPaiements::ValeurInconnue(_)
        | ErreurPaiements::DemandeInvalide(_) => StatusCode::UNPROCESSABLE_ENTITY,

        // 502 et non 500 : la panne n'est pas la nôtre, et la distinction est
        // celle qu'une supervision lit pour savoir qui appeler.
        ErreurPaiements::FournisseurIndisponible(_) => StatusCode::BAD_GATEWAY,

        // Un refus du domaine commandes traverse avec SON statut : une commande
        // inconnue reste un 404, un compte bloqué reste un 403. Le paiement
        // n'a pas à réinventer un vocabulaire que le cycle 008 a déjà fixé.
        ErreurPaiements::Commandes(e) => crate::erreurs_commandes::statut(e),

        // Infrastructure : configuration de zone absente, base, outbox.
        ErreurPaiements::ParametreAbsent(_)
        | ErreurPaiements::Zones(_)
        | ErreurPaiements::Sql(_) => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

/// Corps `{ code, message_cle }` d'un refus du domaine.
///
/// Une erreur SANS clé i18n est une erreur TECHNIQUE : elle rend un code neutre
/// et n'expose rien de son détail — le détail vit dans les journaux. C'est
/// particulièrement vrai ici : `FournisseurIndisponible` porte le message du
/// tiers, qui peut nommer l'agrégateur (FR-003).
pub fn corps(e: &ErreurPaiements) -> serde_json::Value {
    // Un refus venu de `commandes` garde SON espace de noms i18n : l'app
    // cliente a déjà les clés `commande.erreur.*` dans son ARB, et en créer un
    // doublon sous `paiement.erreur.*` ferait diverger deux traductions du
    // même refus.
    if let ErreurPaiements::Commandes(interne) = e {
        return crate::erreurs_commandes::corps(interne);
    }
    match e.message_cle() {
        Some(cle) => json!({ "code": cle, "message_cle": format!("paiement.erreur.{cle}") }),
        None => json!({ "code": "erreur_interne", "message_cle": "paiement.erreur.interne" }),
    }
}

impl ResponseError for ErreurPaiementsHttp {
    fn status_code(&self) -> StatusCode {
        match self {
            ErreurPaiementsHttp::Api(e) => e.status_code(),
            ErreurPaiementsHttp::Domaine(e) => statut(e),
        }
    }

    fn error_response(&self) -> HttpResponse {
        match self {
            ErreurPaiementsHttp::Api(e) => e.error_response(),
            ErreurPaiementsHttp::Domaine(e) => {
                let statut = statut(e);
                if statut == StatusCode::INTERNAL_SERVER_ERROR || statut == StatusCode::BAD_GATEWAY
                {
                    tracing::error!(erreur = %e, "panne du domaine paiement");
                }
                HttpResponse::build(statut).json(corps(e))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    /// Chaque refus MÉTIER porte sa clé i18n, préfixée de son espace de noms.
    #[test]
    fn chaque_refus_metier_porte_sa_cle_i18n() {
        for erreur in [
            ErreurPaiements::TransactionInconnue,
            ErreurPaiements::PaiementNonRequis,
            ErreurPaiements::CommandeNonProprietaire,
            ErreurPaiements::SessionExpiree,
            ErreurPaiements::SignatureInvalide,
            ErreurPaiements::DossierDejaClos,
            ErreurPaiements::MotifRequis,
        ] {
            let corps = corps(&erreur);
            assert_ne!(
                corps["code"], "erreur_interne",
                "« {erreur} » est un refus MÉTIER : il doit porter sa clé i18n",
            );
            let cle = corps["message_cle"].as_str().unwrap();
            assert!(
                cle.starts_with("paiement.erreur."),
                "clé mal préfixée : {cle}"
            );
        }
    }

    /// FR-003 — le message du tiers peut nommer l'agrégateur. Il ne doit
    /// **jamais** sortir dans une réponse d'API.
    #[test]
    fn le_message_du_fournisseur_ne_sort_jamais() {
        let e = ErreurPaiements::FournisseurIndisponible(
            "compte marchand suspendu chez le prestataire X".to_owned(),
        );
        assert_eq!(statut(&e), StatusCode::BAD_GATEWAY);
        let corps = corps(&e);
        assert_eq!(corps["code"], "fournisseur_indisponible");
        assert!(
            !corps.to_string().contains("prestataire X"),
            "le détail du tiers reste dans les journaux (FR-003, FR-006)",
        );
    }

    /// Une commande inconnue garde le statut ET l'espace de noms du cycle 008 :
    /// l'app cliente résout déjà `commande.erreur.*`.
    #[test]
    fn un_refus_du_domaine_commandes_traverse_avec_son_vocabulaire() {
        let e = ErreurPaiements::Commandes(commandes::ErreurCommandes::CommandeInconnue(
            Uuid::now_v7(),
        ));
        assert_eq!(statut(&e), StatusCode::NOT_FOUND);

        let e = ErreurPaiements::Commandes(commandes::ErreurCommandes::NonProprietaire);
        assert_eq!(statut(&e), StatusCode::FORBIDDEN);
        assert_eq!(corps(&e)["message_cle"], "commande.erreur.non_proprietaire");
    }

    /// Les statuts que le contrat nomme, un par un.
    #[test]
    fn les_statuts_du_contrat() {
        assert_eq!(
            statut(&ErreurPaiements::CommandeNonProprietaire),
            StatusCode::FORBIDDEN,
        );
        assert_eq!(
            statut(&ErreurPaiements::PaiementNonRequis),
            StatusCode::CONFLICT,
        );
        assert_eq!(
            statut(&ErreurPaiements::SessionExpiree),
            StatusCode::CONFLICT,
        );
        assert_eq!(
            statut(&ErreurPaiements::TransactionInconnue),
            StatusCode::NOT_FOUND,
        );
        assert_eq!(
            statut(&ErreurPaiements::SignatureInvalide),
            StatusCode::UNAUTHORIZED,
            "le webhook n'a pas de porteur : sa garde est cryptographique",
        );
    }

    /// Une panne de CONFIGURATION n'expose rien — pas même le nom du paramètre
    /// absent, qui renseignerait sur notre schéma de zone.
    #[test]
    fn une_panne_de_configuration_n_expose_rien() {
        let e = ErreurPaiements::ParametreAbsent("paiement.session_duree_s".to_owned());
        assert_eq!(statut(&e), StatusCode::INTERNAL_SERVER_ERROR);
        let corps = corps(&e);
        assert_eq!(corps["code"], "erreur_interne");
        assert!(!corps.to_string().contains("session_duree_s"));
    }
}
