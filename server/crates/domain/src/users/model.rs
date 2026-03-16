use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: Id,
    pub role: UserRole,
    pub phone: String,
    pub name: String,
    pub city_id: Id,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum UserRole {
    Client,
    Merchant,
    Driver,
    Agent,
    Admin,
}
