//! Crate `tarification` — moteur de tarification à règles, routage et grille
//! d'effort (cycle TRF 007).
//!
//! Transforme une **course** (des retraits, un client, un véhicule, une heure,
//! un panier) en **devis figé** `{prix client, part coursier, marge, devise}`
//! calculé sur des **kilomètres routiers réels** (constitution IV). Montants =
//! entiers en unités mineures + code ISO 4217 de la zone (constitution III) ;
//! jamais de flottant pour l'argent.
//!
//! Découpage (plan.md « Project Structure ») :
//!
//! | Module | Rôle |
//! |---|---|
//! | [`modele`] | types du domaine, erreurs |
//! | [`ports`] | traits exposés (`EvaluationTarifaire`, `OptimisationArrets`, `Routage`, `CacheRoutage`) |
//! | [`regle`] | bornes de marge de zone, sélection de la règle la plus spécifique |
//! | [`grille`] | brouillon, simulation, publication (gardes) |
//! | [`routage`] | client OSRM `/table`, cache par tronçon, dégradé ×1,4 |
//! | [`optimisation`] | ordre des arrêts (permutations ≤ 4, heuristique bornée au-delà) |
//! | [`effort`] | grille d'effort (paliers, prime d'attente, supplément d'arrêt) |
//! | [`evaluation`] | pipeline complet (étapes 1–9 du data-model §3) |
//! | [`depot`] | `PgTarification` — racine de composition du domaine |
//!
//! Conventions du dépôt : **lectures sur pool**, **écritures sur
//! `&mut PgTransaction`** avec l'événement outbox dans la MÊME transaction
//! (constitution VI). L'évaluation prend la **géométrie en entrée** — elle ne lit
//! aucune table `commandes` (research R12) : CMD/DSP fourniront la géométrie, ce
//! cycle l'exerce par des courses simulées dans les tests.

pub mod depot;
pub mod effort;
pub mod evaluation;
pub mod grille;
pub mod modele;
pub mod optimisation;
pub mod ports;
pub mod regle;
pub mod routage;

pub use depot::{BornesMarge, PgTarification};
pub use modele::{
    Attente, Composantes, DemandeDevis, Devis, DrapeauxZone, ErreurRoutage, ErreurTarif, EtatGrille,
    Evaluation, Grille, Itineraire, Matrice, OffreLivraison, Point, Regle, RegleRetenue,
    RegleUpsert, SourceGrille, Troncon,
};
pub use ports::{
    CacheDesactive, CacheMemoire, CacheRoutage, ErreurCache, EvaluationTarifaire,
    OptimisationArrets, Routage,
};
