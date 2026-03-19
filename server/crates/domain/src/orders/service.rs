use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use chrono::{Datelike, Duration, NaiveTime, Utc};

use super::model::{
    CreateOrderPayload, OrderStatus, OrderWithItems, ProductBreakdown, WeekPeriod, WeekSummary,
    WeeklyStats,
};
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

    Ok(OrderWithItems { order, items, merchant_name: None })
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
        merchant_name: None,
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
        merchant_name: None,
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
        merchant_name: None,
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

/// Get weekly sales stats for the authenticated merchant.
/// Calculates current week (Monday→Sunday) and compares with previous week.
pub async fn get_merchant_weekly_stats(
    pool: &PgPool,
    merchant_user_id: Id,
) -> Result<WeeklyStats, AppError> {
    let merchant = merchants::repository::find_by_user_id(pool, merchant_user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    // Calculate week boundaries (Monday 00:00 → next Monday 00:00)
    let today = Utc::now().date_naive();
    let days_from_monday = today.weekday().num_days_from_monday() as i64;
    let current_monday = today - Duration::days(days_from_monday);
    let next_monday = current_monday + Duration::days(7);
    let prev_monday = current_monday - Duration::days(7);
    let current_sunday = current_monday + Duration::days(6);

    let to_ts = |d: chrono::NaiveDate| d.and_time(NaiveTime::MIN).and_utc();

    // Fetch current + previous week sales + breakdown in parallel
    let ((current_total, current_count), (prev_total, prev_count), breakdown_rows) =
        tokio::try_join!(
            repository::get_weekly_sales(
                pool,
                merchant.id,
                to_ts(current_monday),
                to_ts(next_monday)
            ),
            repository::get_weekly_sales(
                pool,
                merchant.id,
                to_ts(prev_monday),
                to_ts(current_monday)
            ),
            repository::get_product_breakdown(
                pool,
                merchant.id,
                to_ts(current_monday),
                to_ts(next_monday)
            ),
        )?;

    // Build response with averages and percentages
    // Rounded integer division for averages
    let current_avg = if current_count > 0 {
        (current_total + current_count / 2) / current_count
    } else {
        0
    };
    let prev_avg = if prev_count > 0 {
        (prev_total + prev_count / 2) / prev_count
    } else {
        0
    };

    let product_breakdown: Vec<ProductBreakdown> = breakdown_rows
        .into_iter()
        .map(|row| {
            let revenue = row.revenue.unwrap_or(0);
            let percentage = if current_total > 0 {
                (revenue as f64 / current_total as f64) * 100.0
            } else {
                0.0
            };
            ProductBreakdown {
                product_id: row.product_id,
                product_name: row.product_name,
                quantity_sold: row.quantity_sold.unwrap_or(0),
                revenue,
                percentage: (percentage * 10.0).round() / 10.0,
            }
        })
        .collect();

    info!(
        merchant_id = merchant.id.to_string(),
        current_total = current_total,
        current_count = current_count,
        products = product_breakdown.len(),
        "Weekly stats fetched"
    );

    Ok(WeeklyStats {
        period: WeekPeriod {
            start: current_monday,
            end: current_sunday,
        },
        current_week: WeekSummary {
            total_sales: current_total,
            order_count: current_count,
            average_order: current_avg,
        },
        previous_week: WeekSummary {
            total_sales: prev_total,
            order_count: prev_count,
            average_order: prev_avg,
        },
        product_breakdown,
    })
}

/// Get all orders for the authenticated customer.
pub async fn get_customer_orders(
    pool: &PgPool,
    customer_id: Id,
) -> Result<Vec<OrderWithItems>, AppError> {
    let mut orders = repository::find_by_customer_with_items(pool, customer_id).await?;

    // Resolve merchant names in a single batch query
    let merchant_ids: Vec<Id> = orders
        .iter()
        .map(|o| o.order.merchant_id)
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect();
    let names = repository::resolve_merchant_names(pool, &merchant_ids).await?;
    for order in &mut orders {
        order.merchant_name = names.get(&order.order.merchant_id).cloned();
    }

    Ok(orders)
}

/// Get a single order by ID for the authenticated customer.
/// Returns 404 if not found, 403 if not owned by customer.
pub async fn get_customer_order_by_id(
    pool: &PgPool,
    customer_id: Id,
    order_id: Id,
) -> Result<OrderWithItems, AppError> {
    let mut order_with_items = repository::find_by_id_with_items(pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Order not found".into()))?;

    if order_with_items.order.customer_id != customer_id {
        return Err(AppError::Forbidden("Not your order".into()));
    }

    // Resolve merchant name
    let names = repository::resolve_merchant_names(
        pool,
        &[order_with_items.order.merchant_id],
    )
    .await?;
    order_with_items.merchant_name =
        names.get(&order_with_items.order.merchant_id).cloned();

    Ok(order_with_items)
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

#[cfg(test)]
mod integration_tests {
    use super::*;
    use crate::test_fixtures::*;
    use crate::users::model::UserRole;

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_weekly_stats_with_orders(pool: PgPool) {
        let user_m = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let merchant = create_test_merchant(&pool, user_m.id).await.unwrap();
        let customer = create_test_user(&pool).await.unwrap();

        let p1 = create_test_product_with_price(&pool, merchant.id, "Garba", 250000)
            .await
            .unwrap();
        let p2 = create_test_product_with_price(&pool, merchant.id, "Alloco", 150000)
            .await
            .unwrap();

        // Order 1: 2x Garba + 1x Alloco = 500000 + 150000 = 650000
        create_test_delivered_order(
            &pool,
            customer.id,
            merchant.id,
            &[(p1.id, 2, 250000), (p2.id, 1, 150000)],
        )
        .await
        .unwrap();

        // Order 2: 1x Garba = 250000
        create_test_delivered_order(&pool, customer.id, merchant.id, &[(p1.id, 1, 250000)])
            .await
            .unwrap();

        // Order 3: 3x Alloco = 450000
        create_test_delivered_order(&pool, customer.id, merchant.id, &[(p2.id, 3, 150000)])
            .await
            .unwrap();

        // Total: 650000 + 250000 + 450000 = 1350000
        let stats = get_merchant_weekly_stats(&pool, user_m.id).await.unwrap();
        assert_eq!(stats.current_week.total_sales, 1350000);
        assert_eq!(stats.current_week.order_count, 3);
        assert!(!stats.product_breakdown.is_empty());
        // Breakdown sorted by revenue desc: Garba 3*250000=750000 > Alloco 4*150000=600000
        assert_eq!(stats.product_breakdown[0].product_name, "Garba");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_weekly_stats_empty_week(pool: PgPool) {
        let user_m = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant = create_test_merchant(&pool, user_m.id).await.unwrap();

        let stats = get_merchant_weekly_stats(&pool, user_m.id).await.unwrap();
        assert_eq!(stats.current_week.total_sales, 0);
        assert_eq!(stats.current_week.order_count, 0);
        assert!(stats.product_breakdown.is_empty());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_weekly_stats_ownership_check(pool: PgPool) {
        // Merchant A with orders
        let user_a = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let merchant_a = create_test_merchant(&pool, user_a.id).await.unwrap();
        let customer = create_test_user(&pool).await.unwrap();
        let p = create_test_product(&pool, merchant_a.id).await.unwrap();
        create_test_delivered_order(&pool, customer.id, merchant_a.id, &[(p.id, 1, 100000)])
            .await
            .unwrap();

        // Merchant B without orders
        let user_b = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant_b = create_test_merchant(&pool, user_b.id).await.unwrap();

        // user_b should see zero stats (not merchant_a's orders)
        let stats = get_merchant_weekly_stats(&pool, user_b.id).await.unwrap();
        assert_eq!(stats.current_week.total_sales, 0);
        assert_eq!(stats.current_week.order_count, 0);
    }
}
