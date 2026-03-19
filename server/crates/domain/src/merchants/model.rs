use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Merchant entity matching the `merchants` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Merchant {
    pub id: Id,
    pub user_id: Id,
    pub name: String,
    pub address: Option<String>,
    #[sqlx(rename = "availability_status")]
    pub status: MerchantStatus,
    pub city_id: Option<Id>,
    pub consecutive_no_response: i32,
    pub photo_url: Option<String>,
    pub category: Option<String>,
    pub onboarding_step: i32,
    pub created_by_agent_id: Option<Id>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// 4-state vendor availability matching PostgreSQL `vendor_status` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "vendor_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum MerchantStatus {
    Open,
    Overwhelmed,
    AutoPaused,
    Closed,
}

impl MerchantStatus {
    /// Returns the list of statuses this status can manually transition to.
    pub fn valid_manual_transitions(&self) -> Vec<MerchantStatus> {
        match self {
            Self::Open => vec![Self::Overwhelmed, Self::Closed],
            Self::Overwhelmed => vec![Self::Open, Self::Closed],
            Self::Closed => vec![Self::Open],
            Self::AutoPaused => vec![Self::Open],
        }
    }

    /// Check if a manual transition to the target status is allowed.
    pub fn can_transition_to(&self, target: &MerchantStatus) -> bool {
        self.valid_manual_transitions().contains(target)
    }
}

impl std::fmt::Display for MerchantStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MerchantStatus::Open => write!(f, "open"),
            MerchantStatus::Overwhelmed => write!(f, "overwhelmed"),
            MerchantStatus::AutoPaused => write!(f, "auto_paused"),
            MerchantStatus::Closed => write!(f, "closed"),
        }
    }
}

/// Payload for creating a merchant during onboarding step 1.
#[derive(Debug, Deserialize)]
pub struct CreateMerchantPayload {
    pub name: String,
    pub address: Option<String>,
    pub category: Option<String>,
    pub city_id: Option<Id>,
}

impl CreateMerchantPayload {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        if self.name.trim().is_empty() {
            return Err(common::error::AppError::BadRequest(
                "Merchant name cannot be empty".into(),
            ));
        }
        if self.name.len() > 200 {
            return Err(common::error::AppError::BadRequest(
                "Merchant name cannot exceed 200 characters".into(),
            ));
        }
        if let Some(ref cat) = self.category {
            if cat.len() > 100 {
                return Err(common::error::AppError::BadRequest(
                    "Category cannot exceed 100 characters".into(),
                ));
            }
        }
        Ok(())
    }
}

/// Payload for updating merchant availability status.
#[derive(Debug, Deserialize)]
pub struct UpdateStatusPayload {
    pub status: MerchantStatus,
}

impl UpdateStatusPayload {
    pub fn validate(&self) -> Result<(), common::error::AppError> {
        // Serde already validates that only valid enum values are accepted.
        Ok(())
    }
}

/// Payload for initiating merchant onboarding (request OTP).
#[derive(Debug, Deserialize)]
pub struct InitiateOnboardingPayload {
    pub phone: String,
    pub name: String,
    pub address: Option<String>,
    pub category: Option<String>,
    pub city_id: Option<Id>,
}

/// Payload for verifying OTP and creating merchant.
#[derive(Debug, Deserialize)]
pub struct VerifyOnboardingPayload {
    pub phone: String,
    pub otp: String,
}

/// Lightweight merchant summary for customer discovery (GET /api/v1/merchants).
/// Only fully onboarded merchants (onboarding_step = 5) are returned.
/// avg_rating and delivery_fee are hardcoded for MVP (no ratings table yet).
#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct MerchantSummary {
    pub id: Id,
    pub name: String,
    pub address: Option<String>,
    #[sqlx(rename = "availability_status")]
    pub status: MerchantStatus,
    pub category: Option<String>,
    pub photo_url: Option<String>,
    pub city_id: Option<Id>,
    pub avg_rating: f64,
    pub total_ratings: i64,
    pub delivery_fee: i64,
}

/// Lightweight product summary for B2C customer catalogue (GET /api/v1/merchants/{id}/products).
/// Excludes internal fields (initial_stock, is_available, timestamps).
#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct ProductSummary {
    pub id: Id,
    pub name: String,
    pub price: i64,
    pub stock: i32,
    pub photo_url: Option<String>,
    pub merchant_id: Id,
}

/// Onboarding status response combining merchant + related data.
#[derive(Debug, Serialize)]
pub struct OnboardingStatus {
    pub merchant: Merchant,
    pub products: Vec<crate::products::model::Product>,
    pub business_hours: Vec<super::business_hours::BusinessHours>,
    pub wallet_created: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_merchant_status_display() {
        assert_eq!(MerchantStatus::Open.to_string(), "open");
        assert_eq!(MerchantStatus::Overwhelmed.to_string(), "overwhelmed");
        assert_eq!(MerchantStatus::AutoPaused.to_string(), "auto_paused");
        assert_eq!(MerchantStatus::Closed.to_string(), "closed");
    }

    #[test]
    fn test_merchant_status_serde() {
        let json = serde_json::to_string(&MerchantStatus::Open).unwrap();
        assert_eq!(json, "\"open\"");
        let back: MerchantStatus = serde_json::from_str(&json).unwrap();
        assert_eq!(back, MerchantStatus::Open);

        let json2 = serde_json::to_string(&MerchantStatus::AutoPaused).unwrap();
        assert_eq!(json2, "\"auto_paused\"");
    }

    #[test]
    fn test_create_payload_valid() {
        let p = CreateMerchantPayload {
            name: "Chez Adjoua".into(),
            address: Some("Marché central".into()),
            category: Some("restaurant".into()),
            city_id: None,
        };
        assert!(p.validate().is_ok());
    }

    #[test]
    fn test_create_payload_empty_name() {
        let p = CreateMerchantPayload {
            name: "  ".into(),
            address: None,
            category: None,
            city_id: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_create_payload_name_too_long() {
        let p = CreateMerchantPayload {
            name: "x".repeat(201),
            address: None,
            category: None,
            city_id: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_create_payload_category_too_long() {
        let p = CreateMerchantPayload {
            name: "Ok".into(),
            address: None,
            category: Some("x".repeat(101)),
            city_id: None,
        };
        assert!(p.validate().is_err());
    }

    #[test]
    fn test_valid_transitions_from_open() {
        let transitions = MerchantStatus::Open.valid_manual_transitions();
        assert!(transitions.contains(&MerchantStatus::Overwhelmed));
        assert!(transitions.contains(&MerchantStatus::Closed));
        assert!(!transitions.contains(&MerchantStatus::AutoPaused));
        assert_eq!(transitions.len(), 2);
    }

    #[test]
    fn test_valid_transitions_from_overwhelmed() {
        let transitions = MerchantStatus::Overwhelmed.valid_manual_transitions();
        assert!(transitions.contains(&MerchantStatus::Open));
        assert!(transitions.contains(&MerchantStatus::Closed));
        assert!(!transitions.contains(&MerchantStatus::AutoPaused));
        assert_eq!(transitions.len(), 2);
    }

    #[test]
    fn test_valid_transitions_from_closed() {
        let transitions = MerchantStatus::Closed.valid_manual_transitions();
        assert!(transitions.contains(&MerchantStatus::Open));
        assert!(!transitions.contains(&MerchantStatus::Overwhelmed));
        assert!(!transitions.contains(&MerchantStatus::AutoPaused));
        assert_eq!(transitions.len(), 1);
    }

    #[test]
    fn test_valid_transitions_from_auto_paused() {
        let transitions = MerchantStatus::AutoPaused.valid_manual_transitions();
        assert!(transitions.contains(&MerchantStatus::Open));
        assert!(!transitions.contains(&MerchantStatus::Overwhelmed));
        assert!(!transitions.contains(&MerchantStatus::Closed));
        assert_eq!(transitions.len(), 1);
    }

    #[test]
    fn test_can_transition_to() {
        assert!(MerchantStatus::Open.can_transition_to(&MerchantStatus::Overwhelmed));
        assert!(MerchantStatus::Open.can_transition_to(&MerchantStatus::Closed));
        assert!(!MerchantStatus::Open.can_transition_to(&MerchantStatus::AutoPaused));

        assert!(MerchantStatus::AutoPaused.can_transition_to(&MerchantStatus::Open));
        assert!(!MerchantStatus::AutoPaused.can_transition_to(&MerchantStatus::Closed));
        assert!(!MerchantStatus::AutoPaused.can_transition_to(&MerchantStatus::Overwhelmed));

        assert!(MerchantStatus::Closed.can_transition_to(&MerchantStatus::Open));
        assert!(!MerchantStatus::Closed.can_transition_to(&MerchantStatus::Overwhelmed));
    }

    #[test]
    fn test_update_status_payload_serde() {
        let json = r#"{"status": "open"}"#;
        let payload: UpdateStatusPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.status, MerchantStatus::Open);

        let json2 = r#"{"status": "auto_paused"}"#;
        let payload2: UpdateStatusPayload = serde_json::from_str(json2).unwrap();
        assert_eq!(payload2.status, MerchantStatus::AutoPaused);

        let json3 = r#"{"status": "overwhelmed"}"#;
        let payload3: UpdateStatusPayload = serde_json::from_str(json3).unwrap();
        assert_eq!(payload3.status, MerchantStatus::Overwhelmed);

        let json4 = r#"{"status": "closed"}"#;
        let payload4: UpdateStatusPayload = serde_json::from_str(json4).unwrap();
        assert_eq!(payload4.status, MerchantStatus::Closed);

        // Invalid status should fail
        let invalid = r#"{"status": "invalid"}"#;
        assert!(serde_json::from_str::<UpdateStatusPayload>(invalid).is_err());
    }

    #[test]
    fn test_update_status_payload_validate() {
        let payload = UpdateStatusPayload {
            status: MerchantStatus::Open,
        };
        assert!(payload.validate().is_ok());
    }

    #[test]
    fn test_merchant_serde_roundtrip() {
        let m = Merchant {
            id: uuid::Uuid::new_v4(),
            user_id: uuid::Uuid::new_v4(),
            name: "Chez Adjoua".into(),
            address: Some("Bouaké".into()),
            status: MerchantStatus::Closed,
            city_id: None,
            consecutive_no_response: 0,
            photo_url: None,
            category: Some("restaurant".into()),
            onboarding_step: 1,
            created_by_agent_id: Some(uuid::Uuid::new_v4()),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let json = serde_json::to_string(&m).unwrap();
        let back: Merchant = serde_json::from_str(&json).unwrap();
        assert_eq!(back.name, "Chez Adjoua");
        assert_eq!(back.status, MerchantStatus::Closed);
        assert_eq!(back.onboarding_step, 1);
    }
}
