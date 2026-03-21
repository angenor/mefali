use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use super::model::{CreateDisputeRequest, Dispute, DisputeStatus};
use super::repository;
use crate::orders;

/// Create a dispute for a delivered order.
/// Validates: order exists, requester owns order, order is delivered, no existing dispute.
pub async fn create_dispute(
    pool: &PgPool,
    order_id: Id,
    reporter_id: Id,
    request: &CreateDisputeRequest,
) -> Result<Dispute, AppError> {
    request.validate().map_err(AppError::BadRequest)?;

    let order = orders::repository::find_by_id(pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Order {order_id} not found")))?;

    if order.customer_id != reporter_id {
        return Err(AppError::Forbidden(
            "You can only report disputes on your own orders".into(),
        ));
    }

    if order.status != orders::model::OrderStatus::Delivered {
        return Err(AppError::BadRequest(
            "Only delivered orders can have disputes reported".into(),
        ));
    }

    // Check for existing dispute (application-level uniqueness)
    if let Some(_existing) = repository::find_by_order(pool, order_id).await? {
        return Err(AppError::Conflict(
            "Un litige a deja ete signale pour cette commande".into(),
        ));
    }

    let dispute = repository::create_dispute(
        pool,
        order_id,
        reporter_id,
        &request.dispute_type,
        request.description.as_deref(),
    )
    .await?;

    info!(
        dispute_id = %dispute.id,
        order_id = %order_id,
        dispute_type = %dispute.dispute_type,
        "Dispute created"
    );

    Ok(dispute)
}

/// Get the dispute for a specific order (if any).
/// Validates order ownership.
pub async fn get_dispute_for_order(
    pool: &PgPool,
    order_id: Id,
    requester_id: Id,
) -> Result<Option<Dispute>, AppError> {
    let order = orders::repository::find_by_id(pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Order {order_id} not found")))?;

    if order.customer_id != requester_id {
        return Err(AppError::Forbidden(
            "You can only view disputes on your own orders".into(),
        ));
    }

    repository::find_by_order(pool, order_id).await
}

/// List disputes filed by the authenticated user, paginated.
pub async fn list_my_disputes(
    pool: &PgPool,
    reporter_id: Id,
    limit: i64,
    offset: i64,
) -> Result<(Vec<Dispute>, i64), AppError> {
    let disputes = repository::find_by_reporter(pool, reporter_id, limit, offset).await?;
    let total = repository::count_by_reporter(pool, reporter_id).await?;
    Ok((disputes, total))
}

/// Resolve a dispute (to be called by admin in Story 8.2).
/// Updates status and sends notification to reporter.
pub async fn resolve_dispute(
    pool: &PgPool,
    dispute_id: Id,
    admin_id: Id,
    resolution: &str,
) -> Result<Dispute, AppError> {
    let dispute = repository::find_by_id(pool, dispute_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Dispute {dispute_id} not found")))?;

    if dispute.status == DisputeStatus::Resolved || dispute.status == DisputeStatus::Closed {
        return Err(AppError::Conflict(
            "Ce litige est deja resolu ou ferme".into(),
        ));
    }

    let resolved = sqlx::query_as::<_, Dispute>(
        "UPDATE disputes SET status = $1, resolution = $2, resolved_by = $3
         WHERE id = $4
         RETURNING id, order_id, reporter_id, dispute_type, status, description, resolution, resolved_by, created_at, updated_at",
    )
    .bind(DisputeStatus::Resolved)
    .bind(resolution)
    .bind(admin_id)
    .bind(dispute_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to resolve dispute: {e}")))?;

    info!(
        dispute_id = %dispute_id,
        admin_id = %admin_id,
        "Dispute resolved"
    );

    Ok(resolved)
}
