use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{CreateProductPayload, Product, StockAlert, UpdateProductPayload};

/// Insert a new product for a merchant.
pub async fn create_product(
    pool: &PgPool,
    merchant_id: Id,
    payload: &CreateProductPayload,
) -> Result<Product, AppError> {
    let stock = payload.stock.unwrap_or(0);
    sqlx::query_as::<_, Product>(
        "INSERT INTO products (merchant_id, name, description, price, stock, initial_stock, photo_url)
         VALUES ($1, $2, $3, $4, $5, $5, $6)
         RETURNING id, merchant_id, name, description, price, stock, initial_stock,
                   photo_url, is_available, created_at, updated_at",
    )
    .bind(merchant_id)
    .bind(&payload.name)
    .bind(&payload.description)
    .bind(payload.price)
    .bind(stock)
    .bind(&payload.photo_url)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find a product by ID.
pub async fn find_by_id(pool: &PgPool, product_id: Id) -> Result<Option<Product>, AppError> {
    sqlx::query_as::<_, Product>(
        "SELECT id, merchant_id, name, description, price, stock, initial_stock,
                photo_url, is_available, created_at, updated_at
         FROM products WHERE id = $1",
    )
    .bind(product_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find all available products for a merchant.
pub async fn find_by_merchant(pool: &PgPool, merchant_id: Id) -> Result<Vec<Product>, AppError> {
    sqlx::query_as::<_, Product>(
        "SELECT id, merchant_id, name, description, price, stock, initial_stock,
                photo_url, is_available, created_at, updated_at
         FROM products WHERE merchant_id = $1 AND is_available = true ORDER BY created_at",
    )
    .bind(merchant_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Update a product by ID.
pub async fn update_product(
    pool: &PgPool,
    product_id: Id,
    payload: &UpdateProductPayload,
) -> Result<Product, AppError> {
    sqlx::query_as::<_, Product>(
        "UPDATE products SET
            name = COALESCE($2, name),
            price = COALESCE($3, price),
            description = CASE WHEN $4 IS NOT NULL THEN NULLIF($4, '') ELSE description END,
            stock = COALESCE($5, stock),
            photo_url = COALESCE($6, photo_url),
            updated_at = NOW()
         WHERE id = $1
         RETURNING id, merchant_id, name, description, price, stock, initial_stock,
                   photo_url, is_available, created_at, updated_at",
    )
    .bind(product_id)
    .bind(&payload.name)
    .bind(payload.price)
    .bind(&payload.description)
    .bind(payload.stock)
    .bind(&payload.photo_url)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        if matches!(e, sqlx::Error::RowNotFound) {
            AppError::NotFound("Product not found".into())
        } else {
            AppError::DatabaseError(e.to_string())
        }
    })
}

/// Soft-delete a product (set is_available = false).
pub async fn soft_delete_product(pool: &PgPool, product_id: Id) -> Result<(), AppError> {
    let result = sqlx::query(
        "UPDATE products SET is_available = false, updated_at = NOW() WHERE id = $1 AND is_available = true",
    )
    .bind(product_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("Product not found".into()));
    }
    Ok(())
}

/// Update only the stock field of a product.
pub async fn update_stock(pool: &PgPool, product_id: Id, stock: i32) -> Result<Product, AppError> {
    sqlx::query_as::<_, Product>(
        "UPDATE products SET stock = $2, updated_at = NOW()
         WHERE id = $1 AND is_available = true
         RETURNING id, merchant_id, name, description, price, stock, initial_stock,
                   photo_url, is_available, created_at, updated_at",
    )
    .bind(product_id)
    .bind(stock)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        if matches!(e, sqlx::Error::RowNotFound) {
            AppError::NotFound("Product not found".into())
        } else {
            AppError::DatabaseError(e.to_string())
        }
    })
}

/// Atomically decrement stock. Returns None if insufficient stock.
pub async fn decrement_stock_atomic(
    pool: &PgPool,
    product_id: Id,
    quantity: i32,
) -> Result<Option<Product>, AppError> {
    sqlx::query_as::<_, Product>(
        "UPDATE products SET stock = stock - $2, updated_at = NOW()
         WHERE id = $1 AND stock >= $2 AND is_available = true
         RETURNING id, merchant_id, name, description, price, stock, initial_stock,
                   photo_url, is_available, created_at, updated_at",
    )
    .bind(product_id)
    .bind(quantity)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

// --- Stock alerts ---

/// Create a stock alert for a product.
pub async fn create_stock_alert(
    pool: &PgPool,
    merchant_id: Id,
    product_id: Id,
    current_stock: i32,
    initial_stock: i32,
) -> Result<StockAlert, AppError> {
    sqlx::query_as::<_, StockAlert>(
        "INSERT INTO stock_alerts (merchant_id, product_id, current_stock, initial_stock)
         VALUES ($1, $2, $3, $4)
         RETURNING id, merchant_id, product_id, alert_type, current_stock, initial_stock,
                   triggered_at, acknowledged_at",
    )
    .bind(merchant_id)
    .bind(product_id)
    .bind(current_stock)
    .bind(initial_stock)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find unacknowledged alerts for a merchant.
pub async fn find_alerts_by_merchant(
    pool: &PgPool,
    merchant_id: Id,
) -> Result<Vec<StockAlert>, AppError> {
    sqlx::query_as::<_, StockAlert>(
        "SELECT id, merchant_id, product_id, alert_type, current_stock, initial_stock,
                triggered_at, acknowledged_at
         FROM stock_alerts
         WHERE merchant_id = $1 AND acknowledged_at IS NULL
         ORDER BY triggered_at DESC",
    )
    .bind(merchant_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Check if an unacknowledged alert already exists for a product.
pub async fn find_unacknowledged_alert(
    pool: &PgPool,
    product_id: Id,
) -> Result<Option<StockAlert>, AppError> {
    sqlx::query_as::<_, StockAlert>(
        "SELECT id, merchant_id, product_id, alert_type, current_stock, initial_stock,
                triggered_at, acknowledged_at
         FROM stock_alerts
         WHERE product_id = $1 AND acknowledged_at IS NULL
         LIMIT 1",
    )
    .bind(product_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Acknowledge a stock alert (with merchant ownership check).
pub async fn acknowledge_alert(
    pool: &PgPool,
    alert_id: Id,
    merchant_id: Id,
) -> Result<StockAlert, AppError> {
    sqlx::query_as::<_, StockAlert>(
        "UPDATE stock_alerts SET acknowledged_at = NOW()
         WHERE id = $1 AND merchant_id = $2 AND acknowledged_at IS NULL
         RETURNING id, merchant_id, product_id, alert_type, current_stock, initial_stock,
                   triggered_at, acknowledged_at",
    )
    .bind(alert_id)
    .bind(merchant_id)
    .fetch_one(pool)
    .await
    .map_err(|e| {
        if matches!(e, sqlx::Error::RowNotFound) {
            AppError::NotFound("Alert not found or already acknowledged".into())
        } else {
            AppError::DatabaseError(e.to_string())
        }
    })
}

/// Hard-delete a product by ID (used during onboarding only).
pub async fn delete_product(pool: &PgPool, product_id: Id) -> Result<(), AppError> {
    let result = sqlx::query("DELETE FROM products WHERE id = $1")
        .bind(product_id)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("Product not found".into()));
    }
    Ok(())
}
