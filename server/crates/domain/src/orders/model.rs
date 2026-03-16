use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Order {
    pub id: Id,
    pub customer_id: Id,
    pub merchant_id: Id,
    pub driver_id: Option<Id>,
    pub status: OrderStatus,
    pub payment_type: String,
    pub total: i64,
    pub city_id: Id,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum OrderStatus {
    Pending,
    Confirmed,
    Preparing,
    Ready,
    Collected,
    Delivered,
    Cancelled,
}
