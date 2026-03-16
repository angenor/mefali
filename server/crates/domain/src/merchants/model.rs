use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Merchant {
    pub id: Id,
    pub user_id: Id,
    pub name: String,
    pub address: String,
    pub status: MerchantStatus,
    pub city_id: Id,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum MerchantStatus {
    Open,
    Overwhelmed,
    AutoPaused,
    Closed,
}
