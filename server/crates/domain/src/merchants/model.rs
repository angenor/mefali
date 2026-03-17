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
