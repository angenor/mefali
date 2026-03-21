use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{Dispute, DisputeType};

const DISPUTE_COLUMNS: &str =
    "id, order_id, reporter_id, dispute_type, status, description, resolution, resolved_by, created_at, updated_at";

/// Insert a new dispute record. Returns the created dispute.
pub async fn create_dispute(
    pool: &PgPool,
    order_id: Id,
    reporter_id: Id,
    dispute_type: &DisputeType,
    description: Option<&str>,
) -> Result<Dispute, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "INSERT INTO disputes (order_id, reporter_id, dispute_type, description)
         VALUES ($1, $2, $3, $4)
         RETURNING {DISPUTE_COLUMNS}"
    ))
    .bind(order_id)
    .bind(reporter_id)
    .bind(dispute_type)
    .bind(description)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        if let sqlx::Error::Database(ref db_err) = e {
            if db_err.constraint() == Some("disputes_order_id_key") {
                return AppError::Conflict(
                    "Un litige a deja ete signale pour cette commande".into(),
                );
            }
        }
        AppError::DatabaseError(format!("Failed to create dispute: {e}"))
    })
}

/// Find dispute for a specific order (at most one per order).
pub async fn find_by_order(pool: &PgPool, order_id: Id) -> Result<Option<Dispute>, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE order_id = $1"
    ))
    .bind(order_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find dispute by order: {e}")))
}

/// Find dispute by ID.
pub async fn find_by_id(pool: &PgPool, dispute_id: Id) -> Result<Option<Dispute>, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes WHERE id = $1"
    ))
    .bind(dispute_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find dispute: {e}")))
}

/// Find disputes filed by a specific user, paginated, newest first.
pub async fn find_by_reporter(
    pool: &PgPool,
    reporter_id: Id,
    limit: i64,
    offset: i64,
) -> Result<Vec<Dispute>, AppError> {
    sqlx::query_as::<_, Dispute>(&format!(
        "SELECT {DISPUTE_COLUMNS} FROM disputes
         WHERE reporter_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3"
    ))
    .bind(reporter_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find disputes by reporter: {e}")))
}

/// Count total disputes filed by a specific user.
pub async fn count_by_reporter(pool: &PgPool, reporter_id: Id) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, (i64,)>(
        "SELECT COUNT(*)::bigint FROM disputes WHERE reporter_id = $1",
    )
    .bind(reporter_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to count disputes: {e}")))?;

    Ok(row.0)
}
