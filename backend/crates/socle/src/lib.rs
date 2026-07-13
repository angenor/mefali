//! Crate `socle` — infrastructure technique transverse du backend Mefali.
//!
//! Porte les briques partagées par tous les crates de domaine : configuration,
//! pool Postgres, télémétrie (tracing + Sentry), journal outbox transactionnel
//! et types de santé. Seul crate du workspace à contenir de la logique ce cycle
//! (constitution IX).
//!
//! Contenu complété par T014 (santé), T018/T019 (outbox) et T021 (télémétrie).

pub mod config;
pub mod db;

pub use config::{AppEnv, Config};
pub use db::connect_pg;
