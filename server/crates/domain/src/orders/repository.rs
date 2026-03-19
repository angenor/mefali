use common::error::AppError;
use common::types::{Id, Timestamp};
use sqlx::PgPool;

use super::model::{Order, OrderItem, OrderStatus, OrderWithItems, PaymentType};

const ORDER_COLUMNS: &str =
    "id, customer_id, merchant_id, driver_id, status, payment_type, payment_status,
     subtotal, delivery_fee, total, delivery_address, delivery_lat, delivery_lng,
     city_id, notes, created_at, updated_at";

/// Insert a new order.
pub async fn create_order<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    customer_id: Id,
    merchant_id: Id,
    payment_type: &PaymentType,
    subtotal: i64,
    delivery_fee: i64,
    total: i64,
    delivery_address: &Option<String>,
    delivery_lat: Option<f64>,
    delivery_lng: Option<f64>,
    city_id: Option<Id>,
    notes: &Option<String>,
) -> Result<Order, AppError> {
    sqlx::query_as::<_, Order>(&format!(
        "INSERT INTO orders (customer_id, merchant_id, payment_type, subtotal, delivery_fee, total,
                             delivery_address, delivery_lat, delivery_lng, city_id, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
         RETURNING {ORDER_COLUMNS}"
    ))
    .bind(customer_id)
    .bind(merchant_id)
    .bind(payment_type)
    .bind(subtotal)
    .bind(delivery_fee)
    .bind(total)
    .bind(delivery_address)
    .bind(delivery_lat)
    .bind(delivery_lng)
    .bind(city_id)
    .bind(notes)
    .fetch_one(executor)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Insert an order item.
pub async fn create_order_item<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    order_id: Id,
    product_id: Id,
    quantity: i32,
    unit_price: i64,
) -> Result<OrderItem, AppError> {
    sqlx::query_as::<_, OrderItem>(
        "INSERT INTO order_items (order_id, product_id, quantity, unit_price)
         VALUES ($1, $2, $3, $4)
         RETURNING id, order_id, product_id, quantity, unit_price, created_at",
    )
    .bind(order_id)
    .bind(product_id)
    .bind(quantity)
    .bind(unit_price)
    .fetch_one(executor)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find an order by ID.
pub async fn find_by_id(pool: &PgPool, order_id: Id) -> Result<Option<Order>, AppError> {
    sqlx::query_as::<_, Order>(&format!(
        "SELECT {ORDER_COLUMNS} FROM orders WHERE id = $1"
    ))
    .bind(order_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find items for an order, with product names resolved via JOIN.
pub async fn find_items_by_order(pool: &PgPool, order_id: Id) -> Result<Vec<OrderItem>, AppError> {
    sqlx::query_as::<_, OrderItem>(
        "SELECT oi.id, oi.order_id, oi.product_id, oi.quantity, oi.unit_price,
                oi.created_at, p.name AS product_name
         FROM order_items oi
         LEFT JOIN products p ON oi.product_id = p.id
         WHERE oi.order_id = $1 ORDER BY oi.created_at",
    )
    .bind(order_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find an order by ID with its items.
pub async fn find_by_id_with_items(
    pool: &PgPool,
    order_id: Id,
) -> Result<Option<OrderWithItems>, AppError> {
    let order = find_by_id(pool, order_id).await?;
    match order {
        Some(order) => {
            let items = find_items_by_order(pool, order.id).await?;
            Ok(Some(OrderWithItems { order, items, merchant_name: None }))
        }
        None => Ok(None),
    }
}

/// Find orders for a merchant, filtered by statuses.
pub async fn find_by_merchant(
    pool: &PgPool,
    merchant_id: Id,
    statuses: &[OrderStatus],
) -> Result<Vec<Order>, AppError> {
    if statuses.is_empty() {
        return Ok(vec![]);
    }

    // Build placeholder list for IN clause
    let placeholders: Vec<String> = statuses
        .iter()
        .enumerate()
        .map(|(i, _)| format!("${}", i + 2))
        .collect();
    let in_clause = placeholders.join(", ");

    let query = format!(
        "SELECT {ORDER_COLUMNS} FROM orders
         WHERE merchant_id = $1 AND status IN ({in_clause})
         ORDER BY created_at DESC"
    );

    let mut q = sqlx::query_as::<_, Order>(&query).bind(merchant_id);
    for status in statuses {
        q = q.bind(status);
    }

    q.fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find orders for a merchant with items, filtered by statuses.
/// Uses 2 queries instead of N+1: one for orders, one for all items.
pub async fn find_by_merchant_with_items(
    pool: &PgPool,
    merchant_id: Id,
    statuses: &[OrderStatus],
) -> Result<Vec<OrderWithItems>, AppError> {
    let orders = find_by_merchant(pool, merchant_id, statuses).await?;
    if orders.is_empty() {
        return Ok(vec![]);
    }

    // Batch-fetch all items for all orders in a single query
    let order_ids: Vec<Id> = orders.iter().map(|o| o.id).collect();
    let all_items = sqlx::query_as::<_, OrderItem>(
        "SELECT oi.id, oi.order_id, oi.product_id, oi.quantity, oi.unit_price,
                oi.created_at, p.name AS product_name
         FROM order_items oi
         LEFT JOIN products p ON oi.product_id = p.id
         WHERE oi.order_id = ANY($1)
         ORDER BY oi.created_at",
    )
    .bind(&order_ids)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    // Group items by order_id
    let mut items_map: std::collections::HashMap<Id, Vec<OrderItem>> =
        std::collections::HashMap::new();
    for item in all_items {
        items_map.entry(item.order_id).or_default().push(item);
    }

    let result = orders
        .into_iter()
        .map(|order| {
            let items = items_map.remove(&order.id).unwrap_or_default();
            OrderWithItems { order, items, merchant_name: None }
        })
        .collect();

    Ok(result)
}

/// Update order status.
pub async fn update_status<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    order_id: Id,
    status: &OrderStatus,
) -> Result<Order, AppError> {
    sqlx::query_as::<_, Order>(&format!(
        "UPDATE orders SET status = $2, updated_at = NOW()
         WHERE id = $1
         RETURNING {ORDER_COLUMNS}"
    ))
    .bind(order_id)
    .bind(status)
    .fetch_one(executor)
    .await
    .map_err(|e| {
        if matches!(e, sqlx::Error::RowNotFound) {
            AppError::NotFound("Order not found".into())
        } else {
            AppError::DatabaseError(e.to_string())
        }
    })
}

/// Store rejection reason in order notes field and cancel the order.
pub async fn set_rejection_note<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    order_id: Id,
    reason: &str,
) -> Result<Order, AppError> {
    let note = format!("REFUS: {reason}");
    sqlx::query_as::<_, Order>(&format!(
        "UPDATE orders SET notes = $2, status = $3, updated_at = NOW()
         WHERE id = $1
         RETURNING {ORDER_COLUMNS}"
    ))
    .bind(order_id)
    .bind(&note)
    .bind(&OrderStatus::Cancelled)
    .fetch_one(executor)
    .await
    .map_err(|e| {
        if matches!(e, sqlx::Error::RowNotFound) {
            AppError::NotFound("Order not found".into())
        } else {
            AppError::DatabaseError(e.to_string())
        }
    })
}

/// Find orders for a customer, sorted by created_at DESC.
pub async fn find_by_customer(pool: &PgPool, customer_id: Id) -> Result<Vec<Order>, AppError> {
    sqlx::query_as::<_, Order>(&format!(
        "SELECT {ORDER_COLUMNS} FROM orders
         WHERE customer_id = $1
         ORDER BY created_at DESC
         LIMIT 50"
    ))
    .bind(customer_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find orders for a customer with items.
/// Uses 2 queries instead of N+1: one for orders, one for all items.
pub async fn find_by_customer_with_items(
    pool: &PgPool,
    customer_id: Id,
) -> Result<Vec<OrderWithItems>, AppError> {
    let orders = find_by_customer(pool, customer_id).await?;
    if orders.is_empty() {
        return Ok(vec![]);
    }

    let order_ids: Vec<Id> = orders.iter().map(|o| o.id).collect();
    let all_items = sqlx::query_as::<_, OrderItem>(
        "SELECT oi.id, oi.order_id, oi.product_id, oi.quantity, oi.unit_price,
                oi.created_at, p.name AS product_name
         FROM order_items oi
         LEFT JOIN products p ON oi.product_id = p.id
         WHERE oi.order_id = ANY($1)
         ORDER BY oi.created_at",
    )
    .bind(&order_ids)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    let mut items_map: std::collections::HashMap<Id, Vec<OrderItem>> =
        std::collections::HashMap::new();
    for item in all_items {
        items_map.entry(item.order_id).or_default().push(item);
    }

    let result = orders
        .into_iter()
        .map(|order| {
            let items = items_map.remove(&order.id).unwrap_or_default();
            OrderWithItems { order, items, merchant_name: None }
        })
        .collect();

    Ok(result)
}

/// Resolve merchant names for a list of merchant IDs.
pub async fn resolve_merchant_names(
    pool: &PgPool,
    merchant_ids: &[Id],
) -> Result<std::collections::HashMap<Id, String>, AppError> {
    if merchant_ids.is_empty() {
        return Ok(std::collections::HashMap::new());
    }

    #[derive(sqlx::FromRow)]
    struct MerchantNameRow {
        id: Id,
        name: String,
    }

    let rows = sqlx::query_as::<_, MerchantNameRow>(
        "SELECT id, name FROM merchants WHERE id = ANY($1)",
    )
    .bind(merchant_ids)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(rows.into_iter().map(|r| (r.id, r.name)).collect())
}

// --- Weekly sales aggregation queries ---

/// Raw aggregate row for weekly sales.
#[derive(Debug, sqlx::FromRow)]
struct WeekSalesRow {
    total_sales: Option<i64>,
    order_count: Option<i64>,
}

/// Raw aggregate row for product breakdown.
#[derive(Debug, sqlx::FromRow)]
pub struct ProductBreakdownRow {
    pub product_id: Id,
    pub product_name: String,
    pub quantity_sold: Option<i64>,
    pub revenue: Option<i64>,
}

/// Get aggregated sales for a merchant in a time range (delivered orders only).
/// Returns (total_sales, order_count).
pub async fn get_weekly_sales(
    pool: &PgPool,
    merchant_id: Id,
    from: Timestamp,
    to: Timestamp,
) -> Result<(i64, i64), AppError> {
    let row = sqlx::query_as::<_, WeekSalesRow>(
        "SELECT COALESCE(SUM(o.total)::BIGINT, 0) as total_sales,
                COUNT(DISTINCT o.id) as order_count
         FROM orders o
         WHERE o.merchant_id = $1
           AND o.status = $2
           AND o.created_at >= $3
           AND o.created_at < $4",
    )
    .bind(merchant_id)
    .bind(&OrderStatus::Delivered)
    .bind(from)
    .bind(to)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok((row.total_sales.unwrap_or(0), row.order_count.unwrap_or(0)))
}

/// Get product breakdown for a merchant in a time range (delivered orders only).
/// Results sorted by revenue descending.
pub async fn get_product_breakdown(
    pool: &PgPool,
    merchant_id: Id,
    from: Timestamp,
    to: Timestamp,
) -> Result<Vec<ProductBreakdownRow>, AppError> {
    sqlx::query_as::<_, ProductBreakdownRow>(
        "SELECT p.id as product_id,
                p.name as product_name,
                COALESCE(SUM(oi.quantity::BIGINT)::BIGINT, 0) as quantity_sold,
                COALESCE(SUM(oi.quantity::BIGINT * oi.unit_price)::BIGINT, 0) as revenue
         FROM order_items oi
         JOIN orders o ON o.id = oi.order_id
         JOIN products p ON p.id = oi.product_id
         WHERE o.merchant_id = $1
           AND o.status = $2
           AND o.created_at >= $3
           AND o.created_at < $4
         GROUP BY p.id, p.name
         ORDER BY revenue DESC",
    )
    .bind(merchant_id)
    .bind(&OrderStatus::Delivered)
    .bind(from)
    .bind(to)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}
