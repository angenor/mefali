//! Journal d'événements métier — outbox transactionnel (TRX-02).
//!
//! Écriture atomique dans la transaction de la transition ([`ecrire_evenement`]),
//! publication at-least-once par un [`WorkerOutbox`] vers des consommateurs
//! idempotents. Table et invariants : data-model.md §1 ; contrat
//! `contracts/outbox.md`.

mod worker;
mod write;

pub use worker::{ConsommateurOutbox, ConsommationError, EvenementPublie, WorkerOutbox};
pub use write::{ecrire_evenement, NouvelEvenement, OutboxError};
