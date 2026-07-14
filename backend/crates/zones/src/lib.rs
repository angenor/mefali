//! Crate `zones` — Zones et configuration héritée (cycle 002).
//!
//! Référentiel géographique en arbre à profondeur variable + configuration
//! héritée parent → enfant avec surcharge au paramètre près. Cœur du produit :
//! « tout paramètre métier paramétrable vit dans la configuration de zone »
//! (constitution I). La résolution est exposée par le trait
//! [`ConfigurationZones`], consommé par TOUS les modules suivants (FR-007).
//!
//! Écritures = méthodes inhérentes de [`PgZones`] sur `&mut PgTransaction`
//! (événements outbox inclus, constitution VI). Lectures = trait sur pool.

pub mod depot;
pub mod modele;

pub use depot::PgZones;
pub use modele::{
    CategorieActive, ConfigurationEffective, Devise, ErreurZones, TypeZone, ValeurProvenance, Zone,
};
