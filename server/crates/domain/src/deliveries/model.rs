use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Delivery {
    pub id: Id,
    pub order_id: Id,
    pub driver_id: Id,
    pub status: DeliveryStatus,
    pub lat: f64,
    pub lng: f64,
    pub updated_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum DeliveryStatus {
    Pending,
    Assigned,
    PickedUp,
    InTransit,
    Delivered,
    Failed,
}
