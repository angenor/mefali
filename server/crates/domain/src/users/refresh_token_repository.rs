use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::RefreshToken;

/// Store a new refresh token hash in the database.
pub async fn create(
    pool: &PgPool,
    user_id: Id,
    token_hash: &str,
    expires_at: chrono::DateTime<chrono::Utc>,
) -> Result<RefreshToken, AppError> {
    sqlx::query_as::<_, RefreshToken>(
        "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) \
         VALUES ($1, $2, $3) \
         RETURNING id, user_id, token_hash, expires_at, revoked_at, created_at",
    )
    .bind(user_id)
    .bind(token_hash)
    .bind(expires_at)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create refresh token: {}", e)))
}

/// Find a refresh token by its SHA-256 hash.
pub async fn find_by_hash(pool: &PgPool, hash: &str) -> Result<Option<RefreshToken>, AppError> {
    sqlx::query_as::<_, RefreshToken>(
        "SELECT id, user_id, token_hash, expires_at, revoked_at, created_at \
         FROM refresh_tokens WHERE token_hash = $1",
    )
    .bind(hash)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find refresh token: {}", e)))
}

/// Revoke a single refresh token by ID.
pub async fn revoke(pool: &PgPool, id: Id) -> Result<(), AppError> {
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to revoke refresh token: {}", e)))?;
    Ok(())
}

/// Revoke all refresh tokens for a user (used on logout-all or security events).
pub async fn revoke_all_for_user(pool: &PgPool, user_id: Id) -> Result<(), AppError> {
    sqlx::query(
        "UPDATE refresh_tokens SET revoked_at = now() \
         WHERE user_id = $1 AND revoked_at IS NULL",
    )
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to revoke all refresh tokens: {}", e)))?;
    Ok(())
}

/// Delete expired refresh tokens (housekeeping).
pub async fn cleanup_expired(pool: &PgPool) -> Result<u64, AppError> {
    let result = sqlx::query("DELETE FROM refresh_tokens WHERE expires_at < now()")
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to cleanup expired tokens: {}", e)))?;
    Ok(result.rows_affected())
}
