use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Dispute {
    pub id: Id,
    pub order_id: Id,
    pub reporter_id: Id,
    pub status: DisputeStatus,
    pub resolution: Option<String>,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum DisputeStatus {
    Open,
    InProgress,
    Resolved,
    Closed,
}
