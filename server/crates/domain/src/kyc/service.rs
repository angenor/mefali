use aws_sdk_s3::Client;
use common::config::AppConfig;
use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use crate::users::model::{User, UserStatus};
use crate::users::repository as users_repo;

use super::model::{KycDocument, KycDocumentType, KycSummary};
use super::repository;

/// List all drivers pending KYC verification.
pub async fn list_pending_kyc_users(pool: &PgPool) -> Result<Vec<User>, AppError> {
    repository::find_pending_kyc_drivers(pool).await
}

/// Get KYC summary for a user: user info + documents + sponsor.
pub async fn get_kyc_summary(pool: &PgPool, user_id: Id) -> Result<KycSummary, AppError> {
    let user = users_repo::find_by_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("User {} not found", user_id)))?;

    let documents = repository::find_by_user(pool, user_id).await?;
    let sponsor = repository::find_sponsor_for_user(pool, user_id).await?;

    Ok(KycSummary {
        user,
        documents,
        sponsor,
    })
}

/// Upload a KYC document to MinIO with AES-256 encryption.
pub async fn upload_kyc_document(
    pool: &PgPool,
    s3_client: &Client,
    config: &AppConfig,
    user_id: Id,
    document_type: KycDocumentType,
    file_bytes: Vec<u8>,
    content_type: &str,
) -> Result<KycDocument, AppError> {
    // Validate user exists and is pending KYC
    let user = users_repo::find_by_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("User {} not found", user_id)))?;

    if user.status != UserStatus::PendingKyc {
        return Err(AppError::Conflict("User already active".into()));
    }

    // Generate MinIO key
    let ext = match content_type {
        "image/jpeg" => "jpeg",
        "image/png" => "png",
        _ => {
            return Err(AppError::BadRequest(format!(
                "Invalid content type: {}",
                content_type
            )))
        }
    };
    let file_uuid = uuid::Uuid::new_v4();
    let key = format!("kyc/{}/{}_{}.{}", user_id, document_type, file_uuid, ext);

    // Upload with AES-256 encryption
    infrastructure::storage::upload::upload_encrypted_image(
        s3_client,
        &config.minio_bucket,
        &key,
        file_bytes,
        content_type,
    )
    .await?;

    // Create DB record
    repository::create_document(pool, user_id, document_type, &key).await
}

/// Activate a driver after KYC verification.
///
/// Verifies at least one document exists, marks all documents as verified,
/// and updates user status from pending_kyc to active.
pub async fn activate_driver(
    pool: &PgPool,
    user_id: Id,
    agent_id: Id,
) -> Result<User, AppError> {
    // Verify user exists and is pending_kyc
    let user = users_repo::find_by_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("User {} not found", user_id)))?;

    if user.status != UserStatus::PendingKyc {
        return Err(AppError::Conflict("User already active".into()));
    }

    // Verify at least one document exists
    let documents = repository::find_by_user(pool, user_id).await?;
    if documents.is_empty() {
        return Err(AppError::BadRequest(
            "No KYC documents uploaded".into(),
        ));
    }

    // Transaction: verify documents + activate user atomically
    let mut tx = pool.begin().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {}", e)))?;

    sqlx::query(
        "UPDATE kyc_documents SET status = 'verified', verified_by = $2, updated_at = now() \
         WHERE user_id = $1 AND status = 'pending'",
    )
    .bind(user_id)
    .bind(agent_id)
    .execute(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to verify KYC documents: {}", e)))?;

    let user = sqlx::query_as::<_, User>(
        "UPDATE users SET status = $2, updated_at = now() \
         WHERE id = $1 \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(user_id)
    .bind(UserStatus::Active)
    .fetch_one(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update user status: {}", e)))?;

    tx.commit().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit transaction: {}", e)))?;

    Ok(user)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_kyc_key_format() {
        let user_id = uuid::Uuid::new_v4();
        let file_uuid = uuid::Uuid::new_v4();
        let key = format!("kyc/{}/{}_{}.jpeg", user_id, KycDocumentType::Cni, file_uuid);
        assert!(key.starts_with("kyc/"));
        assert!(key.contains("/cni_"));
        assert!(key.ends_with(".jpeg"));
    }

    #[test]
    fn test_kyc_key_format_permis() {
        let user_id = uuid::Uuid::new_v4();
        let file_uuid = uuid::Uuid::new_v4();
        let key = format!("kyc/{}/{}_{}.png", user_id, KycDocumentType::Permis, file_uuid);
        assert!(key.contains("/permis_"));
        assert!(key.ends_with(".png"));
    }
}
