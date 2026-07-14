//! Accès Postgres au domaine zones.
//!
//! [`PgZones`] porte le pool et regroupe deux surfaces :
//! - LECTURES : le trait [`crate::ConfigurationZones`] (consommé par tous les
//!   modules suivants — FR-007), implémenté dans `resolution.rs` ;
//! - ÉCRITURES : méthodes inhérentes prenant `&mut sqlx::PgTransaction`
//!   (`creer_zone`, `definir_parametre`, `forcer_categorie`,
//!   `recalculer_activation`) — l'atomicité avec l'événement outbox est ainsi
//!   impossible à contourner (constitution VI). Réparties dans `arbre.rs`,
//!   `parametre.rs`, `categorie.rs`.

use sqlx::PgPool;

/// Handle de dépôt du domaine zones. Le clone est bon marché (pool partagé).
#[derive(Clone)]
pub struct PgZones {
    pub(crate) pool: PgPool,
}

impl PgZones {
    /// Construit le dépôt à partir d'un pool Postgres.
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}
