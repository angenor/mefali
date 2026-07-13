//! Crate `socle` — infrastructure technique transverse du backend Mefali.
//!
//! Porte les briques partagées par tous les crates de domaine : configuration,
//! pool Postgres, télémétrie (tracing + Sentry), journal outbox transactionnel
//! et types de santé. Seul crate du workspace à contenir de la logique ce cycle
//! (constitution IX).
//!
//! Télémétrie (T021) complétée ensuite.

pub mod config;
pub mod db;
pub mod health;
pub mod outbox;

pub use config::{AppEnv, Config};
pub use db::connect_pg;
pub use health::HealthResponse;
pub use outbox::{
    ecrire_evenement, ConsommateurOutbox, ConsommationError, EvenementPublie, NouvelEvenement,
    OutboxError, WorkerOutbox,
};
