use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{Delivery, DeliveryStatus};

const DELIVERY_COLUMNS: &str =
    "id, order_id, driver_id, status, current_lat, current_lng, picked_up_at, delivered_at, created_at, updated_at";

/// Create a new delivery record with status pending.
pub async fn create_delivery(
    pool: &PgPool,
    order_id: Id,
    driver_id: Id,
) -> Result<Delivery, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "INSERT INTO deliveries (order_id, driver_id, status)
         VALUES ($1, $2, 'pending')
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(order_id)
    .bind(driver_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create delivery: {e}")))
}

/// Find a delivery by order ID.
pub async fn find_by_order(pool: &PgPool, order_id: Id) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "SELECT {DELIVERY_COLUMNS} FROM deliveries WHERE order_id = $1"
    ))
    .bind(order_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find delivery: {e}")))
}

/// Find the pending delivery for a driver (the one they need to respond to).
pub async fn find_pending_for_driver(
    pool: &PgPool,
    driver_id: Id,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "SELECT {DELIVERY_COLUMNS} FROM deliveries
         WHERE driver_id = $1 AND status = 'pending'
         ORDER BY created_at DESC LIMIT 1"
    ))
    .bind(driver_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find pending delivery: {e}")))
}

/// Update delivery status.
pub async fn update_status(
    pool: &PgPool,
    delivery_id: Id,
    new_status: &DeliveryStatus,
) -> Result<Delivery, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET status = $2, updated_at = now()
         WHERE id = $1
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(new_status)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update delivery status: {e}")))
}

/// Find an available driver: role=driver, status=active, has fcm_token,
/// and not already assigned to an active delivery.
/// Returns the first one found (no proximity sorting in MVP).
pub async fn find_available_driver(pool: &PgPool) -> Result<Option<AvailableDriver>, AppError> {
    sqlx::query_as::<_, AvailableDriver>(
        "SELECT u.id, u.phone, u.fcm_token FROM users u
         WHERE u.role = 'driver' AND u.status = 'active'
           AND NOT EXISTS (
             SELECT 1 FROM deliveries d
             WHERE d.driver_id = u.id
               AND d.status IN ('pending', 'assigned', 'picked_up', 'in_transit')
           )
         LIMIT 1",
    )
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find available driver: {e}")))
}

/// Minimal driver info for assignment.
#[derive(Debug, sqlx::FromRow)]
pub struct AvailableDriver {
    pub id: Id,
    pub phone: String,
    pub fcm_token: Option<String>,
}
