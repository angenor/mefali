use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{Delivery, DeliveryStatus};

pub(crate) const DELIVERY_COLUMNS: &str =
    "id, order_id, driver_id, status, refusal_reason, current_lat, current_lng, picked_up_at, delivered_at, created_at, updated_at";

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

/// Accept a delivery: atomically update status from pending to assigned.
/// Returns None if the delivery is not in pending status (race condition).
pub async fn accept_delivery(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET status = 'assigned', updated_at = now()
         WHERE id = $1 AND driver_id = $2 AND status = 'pending'
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(driver_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to accept delivery: {e}")))
}

/// Refuse a delivery: atomically update status from pending to refused.
/// Returns None if the delivery is not in pending status (race condition).
pub async fn refuse_delivery(
    pool: &PgPool,
    delivery_id: Id,
    reason: &str,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET status = 'refused', refusal_reason = $2, updated_at = now()
         WHERE id = $1 AND status = 'pending'
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(reason)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to refuse delivery: {e}")))
}

/// Find the delivery record by ID.
pub async fn find_by_id(pool: &PgPool, delivery_id: Id) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "SELECT {DELIVERY_COLUMNS} FROM deliveries WHERE id = $1"
    ))
    .bind(delivery_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find delivery: {e}")))
}

/// Find an available driver excluding specific drivers (e.g. those who already refused).
/// No GPS proximity sorting in MVP — ordered by created_at ASC (first registered).
pub async fn find_next_available_driver(
    pool: &PgPool,
    excluded_driver_ids: &[Id],
) -> Result<Option<AvailableDriver>, AppError> {
    // Build the exclusion list for the query
    if excluded_driver_ids.is_empty() {
        return find_available_driver(pool).await;
    }

    // Use ANY($3) with a UUID array for exclusion
    sqlx::query_as::<_, AvailableDriver>(
        "SELECT u.id, u.phone, u.fcm_token FROM users u
         WHERE u.role = 'driver' AND u.status = 'active' AND u.is_available = true
           AND u.id != ALL($1)
           AND NOT EXISTS (
             SELECT 1 FROM deliveries d
             WHERE d.driver_id = u.id
               AND d.status IN ('pending', 'assigned', 'picked_up', 'in_transit', 'client_absent')
           )
         ORDER BY u.created_at ASC
         LIMIT 1",
    )
    .bind(excluded_driver_ids)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find next available driver: {e}")))
}

/// Get all driver IDs who have refused deliveries for a specific order.
pub async fn get_refused_driver_ids(
    pool: &PgPool,
    order_id: Id,
) -> Result<Vec<Id>, AppError> {
    let rows = sqlx::query_scalar::<_, Id>(
        "SELECT driver_id FROM deliveries WHERE order_id = $1 AND status = 'refused'",
    )
    .bind(order_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get refused drivers: {e}")))?;
    Ok(rows)
}

/// Find an available driver: role=driver, status=active, is_available=true,
/// and not already assigned to an active delivery.
/// Returns the first one found (no proximity sorting in MVP).
pub async fn find_available_driver(pool: &PgPool) -> Result<Option<AvailableDriver>, AppError> {
    sqlx::query_as::<_, AvailableDriver>(
        "SELECT u.id, u.phone, u.fcm_token FROM users u
         WHERE u.role = 'driver' AND u.status = 'active' AND u.is_available = true
           AND NOT EXISTS (
             SELECT 1 FROM deliveries d
             WHERE d.driver_id = u.id
               AND d.status IN ('pending', 'assigned', 'picked_up', 'in_transit', 'client_absent')
           )
         ORDER BY u.created_at ASC
         LIMIT 1",
    )
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find available driver: {e}")))
}

/// Confirm pickup: atomically update status from assigned to picked_up.
/// Returns None if the delivery is not in assigned status (wrong state).
pub async fn confirm_pickup(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET status = 'picked_up', picked_up_at = now(), updated_at = now()
         WHERE id = $1 AND driver_id = $2 AND status = 'assigned'
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(driver_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to confirm pickup: {e}")))
}

/// Update driver location during an active delivery.
/// Only works for assigned or picked_up status.
pub async fn update_location(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    lat: f64,
    lng: f64,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET current_lat = $3, current_lng = $4, updated_at = now()
         WHERE id = $1 AND driver_id = $2 AND status IN ('assigned', 'picked_up', 'in_transit', 'client_absent')
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(driver_id)
    .bind(lat)
    .bind(lng)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update location: {e}")))
}

/// Confirm delivery: atomically update status from picked_up or client_absent to delivered.
/// Accepts client_absent to support the case where client arrives during absent timer.
/// Returns None if the delivery is not in an acceptable status.
pub async fn confirm_delivery(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    lat: f64,
    lng: f64,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET status = 'delivered', delivered_at = now(),
                current_lat = $3, current_lng = $4, updated_at = now()
         WHERE id = $1 AND driver_id = $2 AND status IN ('picked_up', 'client_absent')
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(driver_id)
    .bind(lat)
    .bind(lng)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to confirm delivery: {e}")))
}

/// Mark delivery as client_absent: atomically update status from picked_up.
/// Returns None if the delivery is not in picked_up status.
pub async fn mark_client_absent(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
) -> Result<Option<Delivery>, AppError> {
    sqlx::query_as::<_, Delivery>(&format!(
        "UPDATE deliveries SET status = 'client_absent', updated_at = now()
         WHERE id = $1 AND driver_id = $2 AND status = 'picked_up'
         RETURNING {DELIVERY_COLUMNS}"
    ))
    .bind(delivery_id)
    .bind(driver_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to mark client absent: {e}")))
}

/// Set driver availability status.
pub async fn set_driver_availability(
    pool: &PgPool,
    driver_id: Id,
    is_available: bool,
) -> Result<bool, AppError> {
    let result = sqlx::query_scalar::<_, bool>(
        "UPDATE users SET is_available = $2, updated_at = NOW()
         WHERE id = $1 AND role = 'driver'
         RETURNING is_available",
    )
    .bind(driver_id)
    .bind(is_available)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to set driver availability: {e}")))?;

    result.ok_or_else(|| AppError::NotFound(format!("Driver not found: {driver_id}")))
}

/// Get driver availability status.
pub async fn get_driver_availability(
    pool: &PgPool,
    driver_id: Id,
) -> Result<bool, AppError> {
    let result = sqlx::query_scalar::<_, bool>(
        "SELECT is_available FROM users WHERE id = $1 AND role = 'driver'",
    )
    .bind(driver_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get driver availability: {e}")))?;

    result.ok_or_else(|| AppError::NotFound(format!("Driver not found: {driver_id}")))
}

/// Minimal driver info for assignment.
#[derive(Debug, sqlx::FromRow)]
pub struct AvailableDriver {
    pub id: Id,
    pub phone: String,
    pub fcm_token: Option<String>,
}

/// Tracking data for the REST fallback endpoint.
#[derive(Debug, sqlx::FromRow, serde::Serialize)]
pub struct TrackingInfo {
    pub driver_lat: Option<f64>,
    pub driver_lng: Option<f64>,
    pub dest_lat: Option<f64>,
    pub dest_lng: Option<f64>,
    pub delivery_status: String,
    pub driver_name: Option<String>,
    pub driver_phone: String,
    pub order_id: Id,
    pub delivery_id: Id,
}

/// Get tracking data for a delivery by order ID (for client B2C tracking screen).
/// Joins deliveries + orders + users to get all needed info.
/// Only returns data for active deliveries (assigned, picked_up, in_transit).
pub async fn get_tracking_info(
    pool: &PgPool,
    order_id: Id,
    customer_id: Id,
) -> Result<Option<TrackingInfo>, AppError> {
    sqlx::query_as::<_, TrackingInfo>(
        "SELECT
            d.current_lat AS driver_lat,
            d.current_lng AS driver_lng,
            o.delivery_lat AS dest_lat,
            o.delivery_lng AS dest_lng,
            d.status::TEXT AS delivery_status,
            u.name AS driver_name,
            u.phone AS driver_phone,
            d.order_id,
            d.id AS delivery_id
         FROM deliveries d
         JOIN orders o ON o.id = d.order_id
         JOIN users u ON u.id = d.driver_id
         WHERE d.order_id = $1
           AND o.customer_id = $2
           AND d.status IN ('assigned', 'picked_up', 'in_transit', 'client_absent')
         ORDER BY d.created_at DESC
         LIMIT 1",
    )
    .bind(order_id)
    .bind(customer_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get tracking info: {e}")))
}
