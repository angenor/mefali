use common::error::AppError;
use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Order entity matching the `orders` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Order {
    pub id: Id,
    pub customer_id: Id,
    pub merchant_id: Id,
    pub driver_id: Option<Id>,
    pub status: OrderStatus,
    pub payment_type: PaymentType,
    pub payment_status: PaymentStatus,
    pub subtotal: i64,
    pub delivery_fee: i64,
    pub total: i64,
    pub delivery_address: Option<String>,
    pub delivery_lat: Option<f64>,
    pub delivery_lng: Option<f64>,
    pub city_id: Option<Id>,
    pub notes: Option<String>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Order status matching PostgreSQL `order_status` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "order_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum OrderStatus {
    Pending,
    Confirmed,
    Preparing,
    Ready,
    Collected,
    InTransit,
    Delivered,
    Cancelled,
}

impl std::fmt::Display for OrderStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OrderStatus::Pending => write!(f, "pending"),
            OrderStatus::Confirmed => write!(f, "confirmed"),
            OrderStatus::Preparing => write!(f, "preparing"),
            OrderStatus::Ready => write!(f, "ready"),
            OrderStatus::Collected => write!(f, "collected"),
            OrderStatus::InTransit => write!(f, "in_transit"),
            OrderStatus::Delivered => write!(f, "delivered"),
            OrderStatus::Cancelled => write!(f, "cancelled"),
        }
    }
}

/// Payment type matching PostgreSQL `payment_type` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "payment_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum PaymentType {
    Cod,
    MobileMoney,
}

/// Payment status matching PostgreSQL `payment_status` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "payment_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum PaymentStatus {
    Pending,
    EscrowHeld,
    Released,
    Refunded,
}

/// Order item entity matching the `order_items` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OrderItem {
    pub id: Id,
    pub order_id: Id,
    pub product_id: Id,
    pub quantity: i32,
    pub unit_price: i64,
    pub created_at: Timestamp,
    /// Product name resolved via JOIN (absent on INSERT RETURNING).
    #[sqlx(default)]
    pub product_name: Option<String>,
}

/// Order with its items for enriched responses.
#[derive(Debug, Clone, Serialize)]
pub struct OrderWithItems {
    #[serde(flatten)]
    pub order: Order,
    pub items: Vec<OrderItem>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub merchant_name: Option<String>,
}

/// Item in a create-order request.
#[derive(Debug, Deserialize)]
pub struct CreateOrderItemPayload {
    pub product_id: Id,
    pub quantity: i32,
}

/// Payload for creating an order (from client).
#[derive(Debug, Deserialize)]
pub struct CreateOrderPayload {
    pub merchant_id: Id,
    pub items: Vec<CreateOrderItemPayload>,
    pub payment_type: PaymentType,
    pub delivery_address: Option<String>,
    pub delivery_lat: Option<f64>,
    pub delivery_lng: Option<f64>,
    pub city_id: Option<Id>,
    pub notes: Option<String>,
}

impl CreateOrderPayload {
    pub fn validate(&self) -> Result<(), AppError> {
        if self.items.is_empty() {
            return Err(AppError::BadRequest(
                "Order must contain at least one item".into(),
            ));
        }
        for item in &self.items {
            if item.quantity <= 0 {
                return Err(AppError::BadRequest(
                    "Item quantity must be > 0".into(),
                ));
            }
        }
        Ok(())
    }
}

/// Payload for rejecting an order (from merchant).
#[derive(Debug, Deserialize)]
pub struct RejectOrderPayload {
    pub reason: String,
}

impl RejectOrderPayload {
    pub fn validate(&self) -> Result<(), AppError> {
        if self.reason.trim().is_empty() {
            return Err(AppError::BadRequest(
                "Rejection reason cannot be empty".into(),
            ));
        }
        if self.reason.len() > 500 {
            return Err(AppError::BadRequest(
                "Rejection reason cannot exceed 500 characters".into(),
            ));
        }
        Ok(())
    }
}

/// Week period descriptor for stats responses.
/// `start` is Monday (first day), `end` is Sunday (last day, inclusive).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeekPeriod {
    pub start: chrono::NaiveDate,
    pub end: chrono::NaiveDate,
}

/// Weekly sales summary for a single week.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeekSummary {
    pub total_sales: i64,
    pub order_count: i64,
    pub average_order: i64,
}

/// Product sales breakdown entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProductBreakdown {
    pub product_id: Id,
    pub product_name: String,
    pub quantity_sold: i64,
    pub revenue: i64,
    pub percentage: f64,
}

/// Complete weekly stats for a merchant.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyStats {
    pub period: WeekPeriod,
    pub current_week: WeekSummary,
    pub previous_week: WeekSummary,
    pub product_breakdown: Vec<ProductBreakdown>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_order_status_display() {
        assert_eq!(OrderStatus::Pending.to_string(), "pending");
        assert_eq!(OrderStatus::Confirmed.to_string(), "confirmed");
        assert_eq!(OrderStatus::Preparing.to_string(), "preparing");
        assert_eq!(OrderStatus::Ready.to_string(), "ready");
        assert_eq!(OrderStatus::Collected.to_string(), "collected");
        assert_eq!(OrderStatus::InTransit.to_string(), "in_transit");
        assert_eq!(OrderStatus::Delivered.to_string(), "delivered");
        assert_eq!(OrderStatus::Cancelled.to_string(), "cancelled");
    }

    #[test]
    fn test_order_status_serde() {
        let json = serde_json::to_string(&OrderStatus::Pending).unwrap();
        assert_eq!(json, "\"pending\"");
        let back: OrderStatus = serde_json::from_str(&json).unwrap();
        assert_eq!(back, OrderStatus::Pending);

        let json2 = serde_json::to_string(&OrderStatus::InTransit).unwrap();
        assert_eq!(json2, "\"in_transit\"");
        let back2: OrderStatus = serde_json::from_str(&json2).unwrap();
        assert_eq!(back2, OrderStatus::InTransit);
    }

    #[test]
    fn test_payment_type_serde() {
        let json = serde_json::to_string(&PaymentType::Cod).unwrap();
        assert_eq!(json, "\"cod\"");
        let json2 = serde_json::to_string(&PaymentType::MobileMoney).unwrap();
        assert_eq!(json2, "\"mobile_money\"");

        let back: PaymentType = serde_json::from_str("\"cod\"").unwrap();
        assert_eq!(back, PaymentType::Cod);
    }

    #[test]
    fn test_payment_status_serde() {
        let json = serde_json::to_string(&PaymentStatus::EscrowHeld).unwrap();
        assert_eq!(json, "\"escrow_held\"");
        let back: PaymentStatus = serde_json::from_str("\"pending\"").unwrap();
        assert_eq!(back, PaymentStatus::Pending);
    }

    #[test]
    fn test_create_order_payload_valid() {
        let p = CreateOrderPayload {
            merchant_id: uuid::Uuid::new_v4(),
            items: vec![CreateOrderItemPayload {
                product_id: uuid::Uuid::new_v4(),
                quantity: 2,
            }],
            payment_type: PaymentType::Cod,
            delivery_address: Some("Marche central Bouake".into()),
            delivery_lat: None,
            delivery_lng: None,
            city_id: None,
            notes: None,
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_create_order_payload_empty_items() {
        let p = CreateOrderPayload {
            merchant_id: uuid::Uuid::new_v4(),
            items: vec![],
            payment_type: PaymentType::Cod,
            delivery_address: None,
            delivery_lat: None,
            delivery_lng: None,
            city_id: None,
            notes: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_create_order_payload_zero_quantity() {
        let p = CreateOrderPayload {
            merchant_id: uuid::Uuid::new_v4(),
            items: vec![CreateOrderItemPayload {
                product_id: uuid::Uuid::new_v4(),
                quantity: 0,
            }],
            payment_type: PaymentType::Cod,
            delivery_address: None,
            delivery_lat: None,
            delivery_lng: None,
            city_id: None,
            notes: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_reject_order_payload_valid() {
        let p = RejectOrderPayload {
            reason: "Produit en rupture de stock".into(),
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_reject_order_payload_empty_reason() {
        let p = RejectOrderPayload {
            reason: "  ".into(),
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_reject_order_payload_too_long() {
        let p = RejectOrderPayload {
            reason: "x".repeat(501),
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_order_serde_roundtrip() {
        let o = Order {
            id: uuid::Uuid::new_v4(),
            customer_id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            driver_id: None,
            status: OrderStatus::Pending,
            payment_type: PaymentType::Cod,
            payment_status: PaymentStatus::Pending,
            subtotal: 250000,
            delivery_fee: 50000,
            total: 300000,
            delivery_address: Some("Bouake centre".into()),
            delivery_lat: Some(7.69),
            delivery_lng: Some(-5.03),
            city_id: None,
            notes: Some("Sans piment".into()),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let json = serde_json::to_string(&o).unwrap();
        let back: Order = serde_json::from_str(&json).unwrap();
        assert_eq!(back.status, OrderStatus::Pending);
        assert_eq!(back.total, 300000);
        assert_eq!(back.payment_type, PaymentType::Cod);
    }

    #[test]
    fn test_order_item_serde_roundtrip() {
        let item = OrderItem {
            id: uuid::Uuid::new_v4(),
            order_id: uuid::Uuid::new_v4(),
            product_id: uuid::Uuid::new_v4(),
            quantity: 3,
            unit_price: 50000,
            created_at: chrono::Utc::now(),
            product_name: Some("Garba".into()),
        };
        let json = serde_json::to_string(&item).unwrap();
        let back: OrderItem = serde_json::from_str(&json).unwrap();
        assert_eq!(back.quantity, 3);
        assert_eq!(back.unit_price, 50000);
        assert_eq!(back.product_name, Some("Garba".into()));
    }

    #[test]
    fn test_weekly_stats_serde_roundtrip() {
        let stats = WeeklyStats {
            period: WeekPeriod {
                start: chrono::NaiveDate::from_ymd_opt(2026, 3, 9).unwrap(),
                end: chrono::NaiveDate::from_ymd_opt(2026, 3, 15).unwrap(),
            },
            current_week: WeekSummary {
                total_sales: 4700000,
                order_count: 47,
                average_order: 100000,
            },
            previous_week: WeekSummary {
                total_sales: 4000000,
                order_count: 40,
                average_order: 100000,
            },
            product_breakdown: vec![ProductBreakdown {
                product_id: uuid::Uuid::new_v4(),
                product_name: "Garba".into(),
                quantity_sold: 23,
                revenue: 2300000,
                percentage: 48.9,
            }],
        };
        let json = serde_json::to_string(&stats).unwrap();
        let back: WeeklyStats = serde_json::from_str(&json).unwrap();
        assert_eq!(back.current_week.total_sales, 4700000);
        assert_eq!(back.current_week.order_count, 47);
        assert_eq!(back.product_breakdown.len(), 1);
        assert_eq!(back.product_breakdown[0].product_name, "Garba");
        assert_eq!(back.period.start.to_string(), "2026-03-09");
    }

    #[test]
    fn test_week_summary_zero_values() {
        let summary = WeekSummary {
            total_sales: 0,
            order_count: 0,
            average_order: 0,
        };
        let json = serde_json::to_string(&summary).unwrap();
        let back: WeekSummary = serde_json::from_str(&json).unwrap();
        assert_eq!(back.total_sales, 0);
        assert_eq!(back.order_count, 0);
    }
}
