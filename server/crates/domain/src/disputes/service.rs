use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use super::model::{CreateDisputeRequest, Dispute, DisputeStatus};
use super::repository;
use crate::orders;

/// Notification title sent to the reporter when a dispute is resolved.
pub const DISPUTE_RESOLVED_TITLE: &str = "Votre reclamation a ete traitee";
/// Notification body template for resolved disputes.
pub const DISPUTE_RESOLVED_BODY: &str =
    "Votre reclamation a ete examinee et traitee par notre equipe.";

/// Notification title sent to sponsor when sponsored driver has a dispute.
pub const SPONSOR_DISPUTE_ALERT_TITLE: &str = "Litige signale pour votre filleul";
/// Format the notification body for sponsor dispute alerts.
pub fn sponsor_dispute_alert_body(dispute_type: &str, driver_name: &str) -> String {
    format!(
        "Un litige de type {} a ete signale pour {}. En tant que parrain, vous etes informe en priorite.",
        dispute_type, driver_name
    )
}
/// Format the SMS for sponsor dispute alerts.
pub fn sponsor_dispute_alert_sms(dispute_type: &str, driver_name: &str, short_id: &str) -> String {
    format!(
        "mefali: Litige ({}) signale pour votre filleul {}. Contactez-le. Ref: {}",
        dispute_type, driver_name, short_id
    )
}

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
/// Updates status in DB. Caller (route handler) is responsible for sending
/// FCM notification to the reporter.
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

    let resolved = repository::resolve(pool, dispute_id, admin_id, resolution).await?;

    info!(
        dispute_id = %dispute_id,
        admin_id = %admin_id,
        "Dispute resolved"
    );

    Ok(resolved)
}
