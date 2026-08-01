//! Crate `coursier` — parcours coursier : course active, cash et hors-ligne.
//!
//! Le cycle CRS 010 remplit le crate posé **vide au socle** (« prêt ≠
//! construit », constitution IX). Il ne réécrit rien de ce que les cycles 006,
//! 008 et 009 ont livré : il **branche**, **compose** et **comble** les trous
//! que ces cycles ont explicitement laissés — au premier rang desquels le port
//! `commandes::PreuvesEchec`, conçu au cycle 008 pour être implémenté ici.
//!
//! | Module | Rôle |
//! |---|---|
//! | [`modele`] | types purs du domaine, erreurs et leurs clés i18n |
//! | [`config`] | les 7 paramètres de zone du cycle, et le seuil d'essais **réutilisé** |
//! | [`course`] | composition de la course active — trois domaines, une lecture |
//! | [`appels`] | appels journalisés via l'app, sans jamais un numéro |
//! | [`presence`] | présence mesurée sur place — une distance, jamais une position |
//! | [`preuves`] | les trois preuves d'un client absent, et leur basculement |
//! | [`caisse`] | le livre append-only : avances, remboursements, exposition |
//! | [`indemnisation`] | demandée par l'arbre §7.5, décidée par l'exploitation |
//! | [`ports`] | traits consommés (litiges AVI-04) et leurs doubles |
//! | [`depot`] | `PgCoursier` — racine de composition du domaine |
//!
//! Conventions du dépôt : **lectures sur pool**, **écritures sur
//! `&mut PgTransaction`** avec l'événement outbox dans la MÊME transaction
//! (constitution VI). Montants en entiers d'unités mineures + devise ISO 4217
//! (III) ; distances en **mètres entiers arrondis**, jamais de coordonnée
//! persistée (IV, R8).
//!
//! ⚠ Aucune dépendance inverse : `commandes` ne dépend jamais de `coursier`,
//! comme il ne dépend jamais de `dispatch`.

pub mod appels;
pub mod caisse;
pub mod config;
pub mod course;
pub mod depot;
pub mod indemnisation;
pub mod modele;
pub mod ports;
pub mod presence;
pub mod preuves;

pub use config::{cles as cles_config, ConfigCoursier, PHOTOS_PREUVE_MIN};
pub use appels::{AppelEnregistre, DemandeAppel};
pub use presence::{PresenceEnregistree, ReleveDePresence};
pub use preuves::{PhotoPreuveDeposee, PhotoPreuveVue, PreuvesExploitation};
pub use caisse::{AvancesOuvertes, DemandeEcriture, JourneeCoursier};
pub use indemnisation::DecisionIndemnisation;
pub use depot::PgCoursier;
pub use ports::{AucunLitige, LitigesFixes, LitigesOuverts};
pub use modele::{
    ActionRejouee, AppelJournalise, ArretComplet, CibleAppel, ClientCourse, CourseComplete,
    ErreurCoursier, EtatIndemnisation, EtatPreuves, ExpositionCash, IndemnisationVue, IssueAppel,
    IssueRejeu, LigneArret, LigneExposition, LigneHistorique, MouvementCaisse, LitigeVu, MotifAppel, PreuveAppels,
    PreuvePhotos, PreuvePresence, RemisePreprovisionnee, SeuilsPreuves, TypeEcriture, VueCaisse,
    VueJournee,
};
