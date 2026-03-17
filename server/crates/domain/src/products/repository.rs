use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{CreateProductPayload, Product, UpdateProductPayload};

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
            description = COALESCE($4, description),
            stock = COALESCE($5, stock),
            photo_url = COALESCE($6, photo_url)
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
        "UPDATE products SET is_available = false WHERE id = $1 AND is_available = true",
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
