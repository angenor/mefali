use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use super::model::{CreateOrderPayload, OrderStatus, OrderWithItems};
use super::repository;
use crate::merchants;
use crate::merchants::model::MerchantStatus;
use crate::products;

/// Create a new order from a client.
/// Validates merchant availability, product existence, and computes totals from DB prices.
/// All writes (order + items) are wrapped in a single transaction.
pub async fn create_order(
    pool: &PgPool,
    customer_id: Id,
    payload: &CreateOrderPayload,
) -> Result<OrderWithItems, AppError> {
    payload.validate()?;

    // Verify merchant exists and is accepting orders
    let merchant = merchants::repository::find_by_id(pool, payload.merchant_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    match merchant.status {
        MerchantStatus::Open | MerchantStatus::Overwhelmed => {} // ok
        MerchantStatus::AutoPaused => {
            return Err(AppError::BadRequest(
                "Merchant is temporarily unavailable (auto-paused)".into(),
            ));
        }
        MerchantStatus::Closed => {
            return Err(AppError::BadRequest("Merchant is closed".into()));
        }
    }

    // Resolve prices from DB for each item (never trust client-provided prices)
    let mut subtotal: i64 = 0;
    let mut resolved_items = Vec::with_capacity(payload.items.len());
    for item in &payload.items {
        let product = products::repository::find_by_id(pool, item.product_id)
            .await?
            .ok_or_else(|| {
                AppError::NotFound(format!("Product {} not found", item.product_id))
            })?;
        if product.merchant_id != payload.merchant_id {
            return Err(AppError::BadRequest(
                "Product does not belong to this merchant".into(),
            ));
        }
        if !product.is_available {
            return Err(AppError::BadRequest(format!(
                "Product {} is not available",
                product.name
            )));
        }
        let line_total = product.price * item.quantity as i64;
        subtotal += line_total;
        resolved_items.push((item.product_id, item.quantity, product.price));
    }

    let delivery_fee: i64 = 0; // Delivery fee calculation is out of scope for MVP
    let total = subtotal + delivery_fee;

    // Transaction: create order + all items atomically
    let mut tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let order = repository::create_order(
        &mut *tx,
        customer_id,
        payload.merchant_id,
        &payload.payment_type,
        subtotal,
        delivery_fee,
        total,
        &payload.delivery_address,
        payload.delivery_lat,
        payload.delivery_lng,
        payload.city_id,
        &payload.notes,
    )
    .await?;

    let mut items = Vec::with_capacity(resolved_items.len());
    for (product_id, quantity, unit_price) in &resolved_items {
        let item =
            repository::create_order_item(&mut *tx, order.id, *product_id, *quantity, *unit_price)
                .await?;
        items.push(item);
    }

    tx.commit()
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    info!(
        order_id = order.id.to_string(),
        merchant_id = merchant.id.to_string(),
        total = total,
        items_count = items.len(),
        "Order created"
    );

    Ok(OrderWithItems { order, items })
}

/// Merchant accepts a pending order.
/// Resets the merchant's no-response counter.
/// Status update + counter reset are wrapped in a transaction.
pub async fn accept_order(
    pool: &PgPool,
    merchant_user_id: Id,
    order_id: Id,
) -> Result<OrderWithItems, AppError> {
    let (order, merchant) = verify_merchant_order(pool, merchant_user_id, order_id).await?;

    validate_accept(&order.status)?;

    // Transaction: update status + reset no-response counter
    let mut tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let updated = repository::update_status(&mut *tx, order_id, &OrderStatus::Confirmed).await?;
    merchants::repository::reset_no_response(&mut *tx, merchant.id).await?;

    tx.commit()
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let items = repository::find_items_by_order(pool, order_id).await?;

    info!(
        order_id = order_id.to_string(),
        merchant_id = merchant.id.to_string(),
        "Order accepted"
    );

    Ok(OrderWithItems {
        order: updated,
        items,
    })
}

/// Merchant rejects a pending order with a reason.
/// Increments no-response counter and checks for auto-pause.
/// Rejection + counter increment are wrapped in a transaction;
/// auto-pause check runs after commit (reads committed data).
pub async fn reject_order(
    pool: &PgPool,
    merchant_user_id: Id,
    order_id: Id,
    reason: &str,
) -> Result<OrderWithItems, AppError> {
    let (order, merchant) = verify_merchant_order(pool, merchant_user_id, order_id).await?;

    validate_reject(&order.status)?;

    // Transaction: cancel order + increment no-response counter
    let mut tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let updated = repository::set_rejection_note(&mut *tx, order_id, reason).await?;
    merchants::repository::increment_no_response(&mut *tx, merchant.id).await?;

    tx.commit()
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    // Auto-pause check after commit (reads the committed increment)
    merchants::service::check_auto_pause(pool, merchant.id).await?;

    let items = repository::find_items_by_order(pool, order_id).await?;

    info!(
        order_id = order_id.to_string(),
        merchant_id = merchant.id.to_string(),
        reason = reason,
        "Order rejected"
    );

    Ok(OrderWithItems {
        order: updated,
        items,
    })
}

/// Merchant marks an accepted order as ready for pickup.
pub async fn mark_ready(
    pool: &PgPool,
    merchant_user_id: Id,
    order_id: Id,
) -> Result<OrderWithItems, AppError> {
    let (order, merchant) = verify_merchant_order(pool, merchant_user_id, order_id).await?;

    validate_ready(&order.status)?;

    let updated = repository::update_status(pool, order_id, &OrderStatus::Ready).await?;
    let items = repository::find_items_by_order(pool, order_id).await?;

    info!(
        order_id = order_id.to_string(),
        merchant_id = merchant.id.to_string(),
        "Order marked ready"
    );

    Ok(OrderWithItems {
        order: updated,
        items,
    })
}

/// Get active orders for the authenticated merchant.
pub async fn get_merchant_orders(
    pool: &PgPool,
    merchant_user_id: Id,
    statuses: &[OrderStatus],
) -> Result<Vec<OrderWithItems>, AppError> {
    let merchant = merchants::repository::find_by_user_id(pool, merchant_user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    repository::find_by_merchant_with_items(pool, merchant.id, statuses).await
}

/// Verify merchant owns the order. Returns (order, merchant).
async fn verify_merchant_order(
    pool: &PgPool,
    merchant_user_id: Id,
    order_id: Id,
) -> Result<(super::model::Order, merchants::model::Merchant), AppError> {
    let merchant = merchants::repository::find_by_user_id(pool, merchant_user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    let order = repository::find_by_id(pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Order not found".into()))?;

    if order.merchant_id != merchant.id {
        return Err(AppError::Forbidden("Not your order".into()));
    }

    Ok((order, merchant))
}

/// Validate that an order can be accepted (must be pending).
fn validate_accept(status: &OrderStatus) -> Result<(), AppError> {
    if *status != OrderStatus::Pending {
        return Err(AppError::BadRequest(format!(
            "Cannot accept order in status: {}",
            status
        )));
    }
    Ok(())
}

/// Validate that an order can be rejected (must be pending).
fn validate_reject(status: &OrderStatus) -> Result<(), AppError> {
    if *status != OrderStatus::Pending {
        return Err(AppError::BadRequest(format!(
            "Cannot reject order in status: {}",
            status
        )));
    }
    Ok(())
}

/// Validate that an order can be marked ready (must be confirmed).
fn validate_ready(status: &OrderStatus) -> Result<(), AppError> {
    if *status != OrderStatus::Confirmed {
        return Err(AppError::BadRequest(format!(
            "Cannot mark ready: order is in status '{}', expected 'confirmed'",
            status
        )));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    // --- accept transition tests ---

    #[test]
    fn test_accept_allows_pending() {
        assert!(validate_accept(&OrderStatus::Pending).is_ok());
    }

    #[test]
    fn test_accept_rejects_confirmed() {
        assert!(validate_accept(&OrderStatus::Confirmed).is_err());
    }

    #[test]
    fn test_accept_rejects_ready() {
        assert!(validate_accept(&OrderStatus::Ready).is_err());
    }

    #[test]
    fn test_accept_rejects_cancelled() {
        assert!(validate_accept(&OrderStatus::Cancelled).is_err());
    }

    // --- reject transition tests ---

    #[test]
    fn test_reject_allows_pending() {
        assert!(validate_reject(&OrderStatus::Pending).is_ok());
    }

    #[test]
    fn test_reject_rejects_confirmed() {
        assert!(validate_reject(&OrderStatus::Confirmed).is_err());
    }

    // --- ready transition tests ---

    #[test]
    fn test_ready_allows_confirmed() {
        assert!(validate_ready(&OrderStatus::Confirmed).is_ok());
    }

    #[test]
    fn test_ready_rejects_pending() {
        assert!(validate_ready(&OrderStatus::Pending).is_err());
    }

    #[test]
    fn test_ready_rejects_ready() {
        assert!(validate_ready(&OrderStatus::Ready).is_err());
    }
}
