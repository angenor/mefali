//! Dossiers d'anomalie d'argent — **ce qui ne doit jamais disparaître en
//! silence**.
//!
//! Un dossier n'est pas un log. Un log se perd dans le volume et personne ne le
//! referme ; un dossier a un état, un motif et un auteur de clôture (research
//! R14). Quatre situations en ouvrent un, et chacune est un cas où de l'argent
//! ne se trouve pas là où il devrait :
//!
//! | Type | Situation |
//! |---|---|
//! | `montant_divergent` | la notification annonce un autre montant que le figé |
//! | `devise_divergente` | …ou une autre devise |
//! | `paiement_hors_delai` | un succès arrivé après l'annulation (R8) |
//! | `transaction_orpheline` | une référence qui ne désigne aucune transaction |
//! | `retenue_ecretee` | la retenue dépassait les articles (FR-052) |
//! | `remboursement_client_du` | PAY-04 n'existe pas : le dû est **vu** |
//!
//! # Le motif est une CLÉ, jamais une phrase
//!
//! `dossier.motif_cle` porte une clé i18n. L'exploitation lira le texte dans sa
//! langue ; la colonne, elle, reste comparable et filtrable. Un motif en texte
//! libre aurait été intraduisible et ingroupable dès la première semaine.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;
use uuid::Uuid;

use crate::depot::PgPaiements;
use crate::modele::{ErreurPaiements, TypeDossier};

/// Ce qu'on sait de l'anomalie au moment de l'ouvrir.
///
/// Tout est optionnel sauf le type : une transaction orpheline n'a par
/// définition ni commande ni montant attendu, et forcer des valeurs vides
/// obligerait chaque appelant à inventer.
#[derive(Debug, Clone, Default)]
pub struct Anomalie {
    /// Commande concernée, si elle est connue.
    pub commande_id: Option<Uuid>,
    /// Transaction concernée, si elle est connue.
    pub transaction_id: Option<Uuid>,
    /// Arrêt concerné (retenue écrêtée).
    pub arret_id: Option<Uuid>,
    /// Montant **constaté** — ce que le tiers annonce.
    pub montant_constate: Option<i64>,
    /// Montant **attendu** — ce que nous avions figé.
    pub montant_attendu: Option<i64>,
    /// Devise du constat.
    pub devise: Option<String>,
    /// Événement d'outbox qui a produit ce dossier, quand il vient d'un
    /// consommateur. Porte l'idempotence par la contrainte `UNIQUE` ; `NULL`
    /// pour un dossier né du webhook, qui ne consomme aucun événement.
    pub evenement_id: Option<Uuid>,
}

/// Ouvre un dossier **et son événement**, dans la transaction de l'appelant.
///
/// Rend `None` quand le dossier existait déjà — cas d'un consommateur outbox
/// rejoué. Ce n'est pas une erreur : c'est exactement ce que l'idempotence doit
/// produire.
///
/// ⚠ La charge utile ne porte **aucun** secret : ni accès de paiement, ni
/// signature, ni référence de fournisseur (FR-103). Un dossier est relu,
/// exporté, archivé — il ne transporte que des faits d'argent.
pub async fn ouvrir(
    depot: &PgPaiements,
    tx: &mut sqlx::PgTransaction<'_>,
    type_dossier: TypeDossier,
    anomalie: Anomalie,
    quand: DateTime<Utc>,
) -> Result<Option<Uuid>, ErreurPaiements> {
    let id = Uuid::now_v7();
    let ouvert = depot
        .ouvrir_dossier(
            tx,
            id,
            type_dossier,
            anomalie.commande_id,
            anomalie.transaction_id,
            anomalie.arret_id,
            anomalie.montant_constate,
            anomalie.montant_attendu,
            anomalie.devise.as_deref(),
            type_dossier.motif_cle(),
            anomalie.evenement_id,
            quand,
        )
        .await?;

    let Some(id) = ouvert else {
        return Ok(None);
    };

    socle::ecrire_evenement(
        tx,
        NouvelEvenement {
            type_evenement: "paiement.dossier_ouvert",
            entite_type: "dossier",
            entite_id: id,
            payload: json!({
                "type": type_dossier.comme_str(),
                "commande": anomalie.commande_id,
                "montant_constate": anomalie.montant_constate,
                "montant_attendu": anomalie.montant_attendu,
                "devise": anomalie.devise,
                "motif_cle": type_dossier.motif_cle(),
            }),
            survenu_le: quand,
        },
    )
    .await?;

    tracing::warn!(
        dossier = %id,
        type_dossier = type_dossier.comme_str(),
        commande = ?anomalie.commande_id,
        "dossier d'anomalie d'argent ouvert — à traiter par l'exploitation",
    );
    Ok(Some(id))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Chaque type de dossier porte une clé i18n, et **aucune n'est un texte**.
    ///
    /// Le test existe parce qu'une clé oubliée ne se verrait qu'à l'écran de
    /// l'exploitation, en production, sous la forme d'un identifiant technique.
    #[test]
    fn chaque_type_porte_sa_cle_i18n() {
        for type_dossier in [
            TypeDossier::MontantDivergent,
            TypeDossier::DeviseDivergente,
            TypeDossier::PaiementHorsDelai,
            TypeDossier::TransactionOrpheline,
            TypeDossier::RetenueEcretee,
            TypeDossier::RemboursementClientDu,
        ] {
            let cle = type_dossier.motif_cle();
            assert!(
                cle.starts_with("paiement.dossier."),
                "clé mal préfixée : {cle}",
            );
            assert!(
                cle.ends_with(type_dossier.comme_str()),
                "la clé et le libellé SQL doivent rester alignés : {cle}",
            );
        }
    }

    /// Une anomalie par défaut ne prétend rien savoir — c'est le cas de la
    /// transaction orpheline, qui n'a ni commande ni montant attendu.
    #[test]
    fn une_anomalie_vide_est_legitime() {
        let a = Anomalie::default();
        assert!(a.commande_id.is_none() && a.montant_attendu.is_none());
    }
}
