use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use crate::users::model::User;
use super::model::{KycDocument, KycDocumentType};

/// Create a new KYC document record.
pub async fn create_document(
    pool: &PgPool,
    user_id: Id,
    document_type: KycDocumentType,
    encrypted_path: &str,
) -> Result<KycDocument, AppError> {
    sqlx::query_as::<_, KycDocument>(
        "INSERT INTO kyc_documents (user_id, document_type, encrypted_path) \
         VALUES ($1, $2, $3) \
         RETURNING id, user_id, document_type, encrypted_path, verified_by, status, created_at, updated_at",
    )
    .bind(user_id)
    .bind(document_type)
    .bind(encrypted_path)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create KYC document: {}", e)))
}

/// Find all KYC documents for a user.
pub async fn find_by_user(pool: &PgPool, user_id: Id) -> Result<Vec<KycDocument>, AppError> {
    sqlx::query_as::<_, KycDocument>(
        "SELECT id, user_id, document_type, encrypted_path, verified_by, status, created_at, updated_at \
         FROM kyc_documents WHERE user_id = $1 ORDER BY created_at",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find KYC documents: {}", e)))
}

/// Verify all pending KYC documents for a user.
pub async fn verify_all_for_user(
    pool: &PgPool,
    user_id: Id,
    verified_by: Id,
) -> Result<Vec<KycDocument>, AppError> {
    sqlx::query_as::<_, KycDocument>(
        "UPDATE kyc_documents SET status = 'verified', verified_by = $2, updated_at = now() \
         WHERE user_id = $1 AND status = 'pending' \
         RETURNING id, user_id, document_type, encrypted_path, verified_by, status, created_at, updated_at",
    )
    .bind(user_id)
    .bind(verified_by)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to verify KYC documents: {}", e)))
}

/// Find all drivers pending KYC verification, ordered by registration date.
pub async fn find_pending_kyc_drivers(pool: &PgPool) -> Result<Vec<User>, AppError> {
    sqlx::query_as::<_, User>(
        "SELECT id, phone, name, role, status, city_id, fcm_token, created_at, updated_at \
         FROM users WHERE role = 'driver' AND status = 'pending_kyc' ORDER BY created_at",
    )
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to list pending KYC drivers: {}", e)))
}

/// Find the active sponsor for a user via the sponsorships table.
pub async fn find_sponsor_for_user(pool: &PgPool, user_id: Id) -> Result<Option<User>, AppError> {
    sqlx::query_as::<_, User>(
        "SELECT u.id, u.phone, u.name, u.role, u.status, u.city_id, u.fcm_token, u.created_at, u.updated_at \
         FROM users u INNER JOIN sponsorships s ON s.sponsor_id = u.id \
         WHERE s.sponsored_id = $1 AND s.status = 'active'",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find sponsor: {}", e)))
}
