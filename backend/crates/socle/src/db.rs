//! Accès Postgres partagé (constitution II — Postgres, seule vérité durable).

use sqlx::postgres::{PgPool, PgPoolOptions};

/// Ouvre un pool de connexions Postgres.
///
/// Les crates de domaine reçoivent ce pool ; l'écriture d'événements outbox,
/// elle, prend toujours une transaction (voir [`crate::outbox`]).
pub async fn connect_pg(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(10)
        .connect(database_url)
        .await
}
