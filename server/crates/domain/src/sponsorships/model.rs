use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sponsorship {
    pub id: Id,
    pub sponsor_id: Id,
    pub sponsored_id: Id,
    pub status: SponsorshipStatus,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SponsorshipStatus {
    Active,
    Suspended,
    Terminated,
}
