use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

pub const MAX_ACTIVE_SPONSORSHIPS: i64 = 3;
pub const DISPUTE_THRESHOLD_FOR_REVOCATION: i64 = 3;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Sponsorship {
    pub id: Id,
    pub sponsor_id: Id,
    pub sponsored_id: Id,
    pub status: SponsorshipStatus,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "sponsorship_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum SponsorshipStatus {
    Active,
    Suspended,
    Terminated,
}

impl std::fmt::Display for SponsorshipStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SponsorshipStatus::Active => write!(f, "active"),
            SponsorshipStatus::Suspended => write!(f, "suspended"),
            SponsorshipStatus::Terminated => write!(f, "terminated"),
        }
    }
}

/// Sponsored driver info with joined user data, for listing a sponsor's filleuls.
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct SponsoredDriverInfo {
    pub id: Id,
    pub name: Option<String>,
    pub phone: String,
    pub status: SponsorshipStatus,
    pub created_at: Timestamp,
}

/// Sponsor info for a sponsored driver's profile view.
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct SponsorInfo {
    pub id: Id,
    pub name: Option<String>,
    pub phone: String,
    pub sponsorship_status: SponsorshipStatus,
    pub sponsored_at: Timestamp,
}

/// Sponsor contact info for notification purposes (includes fcm_token).
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct SponsorContactInfo {
    pub id: Id,
    pub name: Option<String>,
    pub phone: String,
    pub fcm_token: Option<String>,
}

/// Response for GET /api/v1/sponsorships/me
#[derive(Debug, Clone, Serialize)]
pub struct MySponsorshipsResponse {
    pub max_sponsorships: i64,
    pub active_count: i64,
    pub remaining_slots: i64,
    pub can_sponsor: bool,
    pub sponsored_drivers: Vec<SponsoredDriverInfo>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sponsorship_status_display() {
        assert_eq!(SponsorshipStatus::Active.to_string(), "active");
        assert_eq!(SponsorshipStatus::Suspended.to_string(), "suspended");
        assert_eq!(SponsorshipStatus::Terminated.to_string(), "terminated");
    }

    #[test]
    fn test_sponsorship_status_serde() {
        let json = serde_json::to_string(&SponsorshipStatus::Active).unwrap();
        assert_eq!(json, "\"active\"");
        let parsed: SponsorshipStatus = serde_json::from_str("\"terminated\"").unwrap();
        assert_eq!(parsed, SponsorshipStatus::Terminated);
    }

    #[test]
    fn test_max_active_sponsorships() {
        assert_eq!(MAX_ACTIVE_SPONSORSHIPS, 3);
    }

    #[test]
    fn test_my_sponsorships_response_serialization() {
        let response = MySponsorshipsResponse {
            max_sponsorships: 3,
            active_count: 1,
            remaining_slots: 2,
            can_sponsor: true,
            sponsored_drivers: vec![],
        };
        let json = serde_json::to_value(&response).unwrap();
        assert_eq!(json["max_sponsorships"], 3);
        assert_eq!(json["remaining_slots"], 2);
        assert!(json["can_sponsor"].as_bool().unwrap());
    }
}
