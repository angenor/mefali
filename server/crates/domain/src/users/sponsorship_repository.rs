use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::Sponsorship;

/// Create a new sponsorship link between sponsor and sponsored user.
pub async fn create(
    pool: &PgPool,
    sponsor_id: Id,
    sponsored_id: Id,
) -> Result<Sponsorship, AppError> {
    sqlx::query_as::<_, Sponsorship>(
        "INSERT INTO sponsorships (sponsor_id, sponsored_id) \
         VALUES ($1, $2) \
         RETURNING id, sponsor_id, sponsored_id, status, created_at, updated_at",
    )
    .bind(sponsor_id)
    .bind(sponsored_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create sponsorship: {}", e)))
}

/// Find a sponsorship by sponsored user ID.
pub async fn find_by_sponsored(
    pool: &PgPool,
    sponsored_id: Id,
) -> Result<Option<Sponsorship>, AppError> {
    sqlx::query_as::<_, Sponsorship>(
        "SELECT id, sponsor_id, sponsored_id, status, created_at, updated_at \
         FROM sponsorships WHERE sponsored_id = $1",
    )
    .bind(sponsored_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find sponsorship: {}", e)))
}
