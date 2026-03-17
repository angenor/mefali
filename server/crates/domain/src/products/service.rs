use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{CreateProductPayload, Product, UpdateProductPayload};
use super::repository;
use crate::merchants;

/// Add products for a merchant with validation (used during onboarding by agent).
pub async fn add_products(
    pool: &PgPool,
    merchant_id: Id,
    items: &[CreateProductPayload],
) -> Result<Vec<Product>, AppError> {
    if items.is_empty() {
        return Err(AppError::BadRequest(
            "At least one product is required".into(),
        ));
    }

    for item in items {
        item.validate()?;
    }

    let mut created = Vec::with_capacity(items.len());
    for item in items {
        let product = repository::create_product(pool, merchant_id, item).await?;
        created.push(product);
    }

    Ok(created)
}

/// Get all available products for a merchant.
pub async fn get_products(
    pool: &PgPool,
    merchant_id: Id,
) -> Result<Vec<Product>, AppError> {
    repository::find_by_merchant(pool, merchant_id).await
}

/// Delete a product by ID (hard delete, onboarding use).
pub async fn delete_product(pool: &PgPool, product_id: Id) -> Result<(), AppError> {
    repository::delete_product(pool, product_id).await
}

// --- Merchant self-service methods (story 3.3) ---

/// Resolve merchant from user_id (JWT gives user_id, not merchant_id).
pub async fn resolve_merchant_id(pool: &PgPool, user_id: Id) -> Result<Id, AppError> {
    let merchant = merchants::repository::find_by_user_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("No merchant account found for this user".into()))?;
    Ok(merchant.id)
}

/// Verify that a product belongs to the merchant.
fn verify_ownership(product: &Product, merchant_id: Id) -> Result<(), AppError> {
    if product.merchant_id != merchant_id {
        return Err(AppError::Forbidden(
            "Not authorized to modify this product".into(),
        ));
    }
    Ok(())
}

/// Create a single product for the authenticated merchant.
pub async fn create_product_for_merchant(
    pool: &PgPool,
    merchant_id: Id,
    payload: &CreateProductPayload,
) -> Result<Product, AppError> {
    payload.validate()?;
    repository::create_product(pool, merchant_id, payload).await
}

/// Update a product with ownership check. Returns (updated_product, old_photo_url).
pub async fn update_product(
    pool: &PgPool,
    merchant_id: Id,
    product_id: Id,
    payload: &UpdateProductPayload,
) -> Result<(Product, Option<String>), AppError> {
    payload.validate()?;

    let product = repository::find_by_id(pool, product_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Product not found".into()))?;

    verify_ownership(&product, merchant_id)?;

    let old_photo_url = product.photo_url.clone();
    let updated = repository::update_product(pool, product_id, payload).await?;
    Ok((updated, old_photo_url))
}

/// Soft-delete a product with ownership check.
pub async fn soft_delete_product(
    pool: &PgPool,
    merchant_id: Id,
    product_id: Id,
) -> Result<(), AppError> {
    let product = repository::find_by_id(pool, product_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Product not found".into()))?;

    verify_ownership(&product, merchant_id)?;

    repository::soft_delete_product(pool, product_id).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_product_payload_valid() {
        let p = CreateProductPayload {
            name: "Garba".into(),
            price: 500,
            description: Some("Attieke + thon frit".into()),
            photo_url: None,
            stock: Some(50),
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_validate_product_payload_empty_name() {
        let p = CreateProductPayload {
            name: "".into(),
            price: 500,
            description: None,
            photo_url: None,
            stock: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_validate_product_payload_negative_price() {
        let p = CreateProductPayload {
            name: "Garba".into(),
            price: -1,
            description: None,
            photo_url: None,
            stock: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_validate_product_payload_zero_price() {
        let p = CreateProductPayload {
            name: "Garba".into(),
            price: 0,
            description: None,
            photo_url: None,
            stock: None,
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_verify_ownership_ok() {
        let product = Product {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap(),
            name: "Test".into(),
            description: None,
            price: 100,
            stock: 10,
            initial_stock: 10,
            photo_url: None,
            is_available: true,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let mid = uuid::Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap();
        assert!(verify_ownership(&product, mid).is_ok());
    }

    #[test]
    fn test_verify_ownership_forbidden() {
        let product = Product {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap(),
            name: "Test".into(),
            description: None,
            price: 100,
            stock: 10,
            initial_stock: 10,
            photo_url: None,
            is_available: true,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let other = uuid::Uuid::parse_str("00000000-0000-0000-0000-000000000002").unwrap();
        assert!(verify_ownership(&product, other).is_err());
    }

    #[test]
    fn test_update_payload_validation() {
        let valid = UpdateProductPayload {
            name: Some("New name".into()),
            price: Some(1000),
            description: None,
            stock: None,
            photo_url: None,
        };
        assert!(valid.validate().is_ok());

        let invalid = UpdateProductPayload {
            name: Some("  ".into()),
            price: None,
            description: None,
            stock: None,
            photo_url: None,
        };
        assert!(invalid.validate().is_err());
    }
}
