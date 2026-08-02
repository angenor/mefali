//! Crate `commandes` — le tronc commande et TOUT son cycle de vie.
//!
//! Le tronc commande ne connaît que les états de très haut niveau (cadrage
//! §11.11) et **aucun champ logistique** : la livraison est un composant
//! optionnel (0..n), un prestataire n'est pas forcément un vendeur
//! (constitution II). Le devis figé, le coursier, l'ordre des arrêts et tous
//! les états de collecte vivent sur `livraison`/`segment`/`arret`.
//!
//! Histoire du crate : le cycle QRC 006 y a posé le **socle logistique minimal**
//! (`commande`/`livraison`/`segment`/`arrêt`, `marquer_arret_collecte`, port
//! `ArretsDeCollecte`). Le cycle CMD 008 l'ÉTEND — sans changer de frontière —
//! du panier multi-vendeurs à la remise, ou à l'arbre des échecs.
//!
//! | Module | Rôle |
//! |---|---|
//! | [`modele`] | types du domaine, erreurs et leurs clés i18n |
//! | [`etats`] | table de transitions FERMÉE (3 niveaux), garde unique |
//! | [`ports`] | traits offerts (DSP) et consommés (comptes, preuves, position) |
//! | [`workflow`] | verticaux de service ([`workflow::ServiceWorkflow`]) |
//! | [`panier`] | devis de panier, regroupement, mixage, scission |
//! | [`creation`] | prix figés + devis figé + secrets de remise, idempotent |
//! | [`collecte`] | boucle par arrêt (en route, arrivé, indisponible), remise |
//! | [`substitution`] | préférences, proposition, échéance, expiration |
//! | [`annulation`] | sans frais / après collecte / admin |
//! | [`echec`] | arbre §7.5, détenteurs, sanctions |
//! | [`suivi`] | progression par arrêt, position et son âge |
//! | [`depot`] | `PgCommandes` — racine de composition du domaine |
//!
//! Conventions du dépôt : **lectures sur pool**, **écritures sur
//! `&mut PgTransaction`** avec l'événement outbox dans la MÊME transaction
//! (constitution VI).

pub mod annulation;
pub mod collecte;
pub mod creation;
pub mod depot;
pub mod echec;
pub mod etats;
pub mod exploitation;
pub mod modele;
pub mod panier;
pub mod ports;
pub mod recu;
pub mod substitution;
pub mod suivi;
pub mod workflow;

pub use annulation::{AnnulationFaite, AuteurAnnulation};
pub use echec::{DemandeEchec, IssueEnregistree, ResolutionIssue};
pub use collecte::{
    ActionArret, DemandeRemise, DemandeTransitionArret, MotifIndisponible, PreuveRemise,
    RemiseFaite, TransitionArret,
};
pub use depot::PgCommandes;
pub use etats::{transition_existe, verifier_transition, Acteur, Niveau};
pub use exploitation::{DecisionDepot, RemiseBloquee};
pub use modele::{
    ArretACollecter, Detenteur, ErreurCommandes, EtatCommande, EtatLivraison, EtatPaiement,
    IssueSubstitution, ModeCollecte, ModePaiement, PreferenceSubstitution, ProgressionCollecte,
    reference_courte, Restrictions, Sanction, StatutArret, StatutLigne, TypeArret,
    TypeIssueEchec,
};
pub use panier::{
    CauseScission, DetailsVertical, GroupeVendeur, LignePanier, LigneValidee, PanierValide,
};
pub use ports::{
    AffectationSimulee, ArretDeCourse, ArretsDeCollecte, ArretsFixes, Capacite, ClientDeCourse,
    CommandeADispatcher, CommandeAPayer, CommandesADispatcher, CommandesAPayer,
    CommandesAPayerEnMemoire, CourseCoursier, CourseDuCoursier, CourseFixe, EtatProgression,
    LigneDeCourse, LivraisonLivree, Montant, MotifPrepaiementDispatch, PaiementSimule,
    PositionCoursier, PositionDatee, PositionFixe, PreuvesEchec, PreuvesFixes, RemiseDeCourse,
    RestrictionsCompte, RestrictionsSimulees, TarifFixe, MOTIF_ANNULATION_EXPIRATION,
};
pub use substitution::{
    DemandeRupture, IssueRupture, MontantsRevises, ResolutionRupture,
};
pub use recu::{LigneRecu, RecuArret, RecuCommande, MOTIF_RETENUE_CLE};
pub use suivi::{CommandeResumee, VueSuivi};
pub use workflow::{CoursesWorkflow, RestaurationWorkflow, ServiceWorkflow};
