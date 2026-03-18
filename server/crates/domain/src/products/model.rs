use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Product entity matching the `products` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Product {
    pub id: Id,
    pub merchant_id: Id,
    pub name: String,
    pub description: Option<String>,
    pub price: i64,
    pub stock: i32,
    pub initial_stock: i32,
    pub photo_url: Option<String>,
    pub is_available: bool,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Payload for creating a product during onboarding.
#[derive(Debug, Deserialize)]
pub struct CreateProductPayload {
    pub name: String,
    pub price: i64,
    pub description: Option<String>,
    pub photo_url: Option<String>,
    pub stock: Option<i32>,
}

impl CreateProductPayload {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        if self.name.trim().is_empty() {
            return Err(common::error::AppError::BadRequest(
                "Product name cannot be empty".into(),
            ));
        }
        if self.name.len() > 200 {
            return Err(common::error::AppError::BadRequest(
                "Product name cannot exceed 200 characters".into(),
            ));
        }
        if self.price < 0 {
            return Err(common::error::AppError::BadRequest(
                "Price must be >= 0".into(),
            ));
        }
        if let Some(stock) = self.stock {
            if stock < 0 {
                return Err(common::error::AppError::BadRequest(
                    "Stock must be >= 0".into(),
                ));
            }
        }
        Ok(())
    }
}

/// Stock alert entity matching the `stock_alerts` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct StockAlert {
    pub id: Id,
    pub merchant_id: Id,
    pub product_id: Id,
    pub alert_type: String,
    pub current_stock: i32,
    pub initial_stock: i32,
    pub triggered_at: Timestamp,
    pub acknowledged_at: Option<Timestamp>,
}

/// Payload for updating stock level directly.
#[derive(Debug, Deserialize)]
pub struct UpdateStockPayload {
    pub stock: i32,
}

impl UpdateStockPayload {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        if self.stock < 0 {
            return Err(common::error::AppError::BadRequest(
                "Stock must be >= 0".into(),
            ));
        }
        Ok(())
    }
}

/// Payload for decrementing stock atomically.
#[derive(Debug, Deserialize)]
pub struct DecrementStockPayload {
    pub quantity: i32,
}

impl DecrementStockPayload {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        if self.quantity <= 0 {
            return Err(common::error::AppError::BadRequest(
                "Quantity must be > 0".into(),
            ));
        }
        Ok(())
    }
}

/// Payload for updating a product.
#[derive(Debug, Deserialize)]
pub struct UpdateProductPayload {
    pub name: Option<String>,
    pub price: Option<i64>,
    pub description: Option<String>,
    pub stock: Option<i32>,
    pub photo_url: Option<String>,
}

impl UpdateProductPayload {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        if let Some(ref name) = self.name {
            if name.trim().is_empty() {
                return Err(common::error::AppError::BadRequest(
                    "Product name cannot be empty".into(),
                ));
            }
            if name.len() > 200 {
                return Err(common::error::AppError::BadRequest(
                    "Product name cannot exceed 200 characters".into(),
                ));
            }
        }
        if let Some(price) = self.price {
            if price < 0 {
                return Err(common::error::AppError::BadRequest(
                    "Price must be >= 0".into(),
                ));
            }
        }
        if let Some(stock) = self.stock {
            if stock < 0 {
                return Err(common::error::AppError::BadRequest(
                    "Stock must be >= 0".into(),
                ));
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_product_payload_valid() {
        let p = CreateProductPayload {
            name: "Garba".into(),
            price: 500,
            description: Some("Attiéké + thon frit".into()),
            photo_url: None,
            stock: Some(50),
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_create_product_empty_name() {
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
    fn test_create_product_negative_price() {
        let p = CreateProductPayload {
            name: "Garba".into(),
            price: -100,
            description: None,
            photo_url: None,
            stock: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_create_product_negative_stock() {
        let p = CreateProductPayload {
            name: "Garba".into(),
            price: 500,
            description: None,
            photo_url: None,
            stock: Some(-1),
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_update_product_payload_valid() {
        let p = UpdateProductPayload {
            name: Some("Alloco".into()),
            price: Some(300),
            description: None,
            stock: Some(10),
            photo_url: None,
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_update_product_empty_name() {
        let p = UpdateProductPayload {
            name: Some("".into()),
            price: None,
            description: None,
            stock: None,
            photo_url: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_update_product_negative_price() {
        let p = UpdateProductPayload {
            name: None,
            price: Some(-1),
            description: None,
            stock: None,
            photo_url: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_update_product_negative_stock() {
        let p = UpdateProductPayload {
            name: None,
            price: None,
            description: None,
            stock: Some(-5),
            photo_url: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_update_product_all_none() {
        let p = UpdateProductPayload {
            name: None,
            price: None,
            description: None,
            stock: None,
            photo_url: None,
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_update_stock_payload_valid() {
        let p = UpdateStockPayload { stock: 50 };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_update_stock_payload_zero() {
        let p = UpdateStockPayload { stock: 0 };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_update_stock_payload_negative() {
        let p = UpdateStockPayload { stock: -1 };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_decrement_stock_payload_valid() {
        let p = DecrementStockPayload { quantity: 5 };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_decrement_stock_payload_zero() {
        let p = DecrementStockPayload { quantity: 0 };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_decrement_stock_payload_negative() {
        let p = DecrementStockPayload { quantity: -3 };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_product_serde_roundtrip() {
        let p = Product {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            name: "Garba".into(),
            description: Some("Attiéké + thon".into()),
            price: 500,
            stock: 50,
            initial_stock: 50,
            photo_url: None,
            is_available: true,
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let json = serde_json::to_string(&p).unwrap();
        let back: Product = serde_json::from_str(&json).unwrap();
        assert_eq!(back.name, "Garba");
        assert_eq!(back.price, 500);
    }
}
