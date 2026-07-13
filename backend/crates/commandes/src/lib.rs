//! Crate `commandes` — tronc commande générique + trait [`ServiceWorkflow`].
//!
//! Le tronc commande ne connaît que les états de très haut niveau (cadrage
//! §11.11) et **aucun champ logistique** : la livraison est un composant
//! optionnel rattaché ailleurs, un prestataire n'est pas forcément un vendeur
//! (constitution II). Chaque vertical fournit sa table de détails et son
//! implémentation de [`ServiceWorkflow`].
//!
//! **Ce cycle définit le trait, sans aucune implémentation** (constitution IX).
//! Signature provisoire, stabilisée au cycle CMD — contrat
//! `specs/001-socle-monorepo/contracts/service-workflow.md`.

use async_trait::async_trait;
use uuid::Uuid;

/// États de très haut niveau du tronc commande — les SEULS que le crate
/// `commandes` connaît (cadrage §11.11). Aucun champ logistique.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EtatCommande {
    /// Commande créée, pas encore prise en charge.
    Creee,
    /// Prise en charge, parcours du vertical en cours.
    EnCours,
    /// Terminée avec succès.
    Terminee,
    /// Annulée avant terme.
    Annulee,
    /// Litige ouvert (escalade).
    Litige,
}

/// Un état intermédiaire propre à un vertical, projeté sur le tronc.
#[derive(Debug, Clone, Copy)]
pub struct EtatIntermediaire {
    /// Clé i18n dérivée, jamais de libellé en dur (constitution VII).
    pub code: &'static str,
    /// Projection de cet état sur le tronc commande.
    pub etat_tronc: EtatCommande,
}

/// Contexte passé aux hooks du vertical. Squelette ce cycle — enrichi au
/// cycle CMD (détails de commande, acteur, zone…).
#[derive(Debug, Clone)]
pub struct ContexteWorkflow {
    /// Identifiant de la commande concernée.
    pub commande_id: Uuid,
    /// Identifiant du vertical (ex. `"resto_courses"`).
    pub vertical: String,
}

/// Ajustement de tarif produit par un vertical.
///
/// Montant en **entiers d'unités mineures** + code **ISO 4217** — jamais de
/// float, jamais de montant sans devise (constitution III). Signé : un montant
/// négatif exprime une remise.
#[derive(Debug, Clone)]
pub struct AjustementTarif {
    /// Clé i18n du motif d'ajustement, jamais de libellé en dur.
    pub motif_code: &'static str,
    /// Montant en unités mineures de la devise (peut être négatif).
    pub montant_mineur: i64,
    /// Code devise ISO 4217 (ex. `"XOF"`).
    pub devise: String,
}

/// Erreurs des hooks de workflow. Squelette ce cycle.
#[derive(Debug, thiserror::Error)]
pub enum WorkflowError {
    /// Transition d'état intermédiaire refusée par le vertical.
    #[error("transition invalide de « {de} » vers « {vers} »")]
    TransitionInvalide {
        /// État de départ (code du vertical).
        de: String,
        /// État cible (code du vertical).
        vers: String,
    },
    /// Erreur interne du vertical.
    #[error("erreur interne du workflow : {0}")]
    Interne(String),
}

/// Implémenté par chaque vertical (resto_courses au MVP ; pressing,
/// intervention… ensuite). Le vertical possède sa table de détails
/// (`resto_details`…) et ses états intermédiaires.
///
/// Aucune méthode n'expose de notion logistique : le dispatch filtre sur des
/// capacités requises, la livraison est un composant optionnel (constitution II).
#[async_trait]
pub trait ServiceWorkflow: Send + Sync {
    /// Identifiant du vertical (ex. `"resto_courses"`).
    fn vertical(&self) -> &'static str;

    /// États intermédiaires du vertical, projetés sur [`EtatCommande`].
    fn etats_intermediaires(&self) -> &'static [EtatIntermediaire];

    /// Valide une transition d'état intermédiaire (le serveur fait foi).
    async fn valider_transition(
        &self,
        de: &str,
        vers: &str,
        ctx: &ContexteWorkflow,
    ) -> Result<(), WorkflowError>;

    /// Hook de tarification du vertical (appelé par le crate `tarification`).
    async fn ajustements_tarification(
        &self,
        ctx: &ContexteWorkflow,
    ) -> Result<Vec<AjustementTarif>, WorkflowError>;
}
