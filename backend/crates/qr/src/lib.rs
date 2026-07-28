//! Crate `qr` — traçabilité QR : plaque imprimable et scans de collecte.
//!
//! Cycle QRC 006. Le crate compose le **PDF de plaque** (QRC-01) et orchestre
//! le **scan de collecte** (QRC-02/03/04) : vérification (résolution du jeton,
//! proximité grand-cercle, politique photo, code dégradé + incident), puis
//! bascule de l'arrêt en COLLECTÉ via `commandes::marquer_arret_collecte`.
//! Tout fonctionne hors-ligne (pré-provisionnement d'empreintes, réconciliation
//! serveur au rejeu). Domaine PUR (constitution II) : Garage et Redis n'entrent
//! que par des ports (`socle::DepotObjets`, `CompteurEssais`).

pub mod depot;
pub mod modele;
pub mod plaque;
pub mod ports;
pub mod verification;

pub use depot::PgQr;
pub use modele::{
    ArretPreProvisionne, DemandeCollecte, ErreurQr, PlaqueResolue, ResultatCollecte,
};
pub use ports::{CompteurEssais, CompteurMemoire, ErreurCompteur};
