use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{
    SponsorContactInfo, SponsorInfo, SponsoredDriverInfo, Sponsorship, SponsorshipStatus,
};

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

/// Count active sponsorships for a sponsor.
pub async fn count_active_by_sponsor(
    pool: &PgPool,
    sponsor_id: Id,
) -> Result<i64, AppError> {
    let row: (i64,) = sqlx::query_as(
        "SELECT COUNT(*) FROM sponsorships WHERE sponsor_id = $1 AND status = 'active'",
    )
    .bind(sponsor_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to count sponsorships: {}", e)))?;
    Ok(row.0)
}

/// Find all sponsored drivers for a sponsor, with joined user info.
pub async fn find_by_sponsor(
    pool: &PgPool,
    sponsor_id: Id,
) -> Result<Vec<SponsoredDriverInfo>, AppError> {
    sqlx::query_as::<_, SponsoredDriverInfo>(
        "SELECT u.id, u.name, u.phone, s.status, s.created_at \
         FROM sponsorships s \
         JOIN users u ON u.id = s.sponsored_id \
         WHERE s.sponsor_id = $1 \
         ORDER BY s.created_at DESC",
    )
    .bind(sponsor_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find sponsored drivers: {}", e)))
}

/// Get sponsor info for a sponsored driver.
pub async fn find_sponsor_info(
    pool: &PgPool,
    sponsored_id: Id,
) -> Result<Option<SponsorInfo>, AppError> {
    sqlx::query_as::<_, SponsorInfo>(
        "SELECT u.id, u.name, u.phone, \
         s.status AS sponsorship_status, s.created_at AS sponsored_at \
         FROM sponsorships s \
         JOIN users u ON u.id = s.sponsor_id \
         WHERE s.sponsored_id = $1",
    )
    .bind(sponsored_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find sponsor info: {}", e)))
}

/// Find the active sponsor for a driver, with contact info (fcm_token, phone).
/// Returns (sponsor_id, name, phone, fcm_token) if an active sponsorship exists.
pub async fn find_active_sponsor_with_contact(
    pool: &PgPool,
    sponsored_id: Id,
) -> Result<Option<SponsorContactInfo>, AppError> {
    sqlx::query_as::<_, SponsorContactInfo>(
        "SELECT u.id, u.name, u.phone, u.fcm_token \
         FROM sponsorships s \
         JOIN users u ON u.id = s.sponsor_id \
         WHERE s.sponsored_id = $1 AND s.status = 'active'",
    )
    .bind(sponsored_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find active sponsor contact: {}", e)))
}

/// Update sponsorship status.
pub async fn update_status(
    pool: &PgPool,
    sponsorship_id: Id,
    status: SponsorshipStatus,
) -> Result<Sponsorship, AppError> {
    sqlx::query_as::<_, Sponsorship>(
        "UPDATE sponsorships SET status = $1 \
         WHERE id = $2 \
         RETURNING id, sponsor_id, sponsored_id, status, created_at, updated_at",
    )
    .bind(status)
    .bind(sponsorship_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update sponsorship status: {}", e)))
}
