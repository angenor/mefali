use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Id,
    pub phone: String,
    pub name: Option<String>,
    pub role: UserRole,
    pub status: UserStatus,
    pub city_id: Option<Id>,
    pub fcm_token: Option<String>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "user_role", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum UserRole {
    Client,
    Merchant,
    Driver,
    Agent,
    Admin,
}

impl std::fmt::Display for UserRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserRole::Client => write!(f, "client"),
            UserRole::Merchant => write!(f, "merchant"),
            UserRole::Driver => write!(f, "driver"),
            UserRole::Agent => write!(f, "agent"),
            UserRole::Admin => write!(f, "admin"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "user_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum UserStatus {
    Active,
    PendingKyc,
    Suspended,
    Deactivated,
}

#[derive(Debug, Deserialize)]
pub struct RequestOtpPayload {
    pub phone: String,
}

#[derive(Debug, Deserialize)]
pub struct VerifyOtpPayload {
    pub phone: String,
    pub otp: String,
    pub name: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user: User,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_role_display() {
        assert_eq!(UserRole::Client.to_string(), "client");
        assert_eq!(UserRole::Merchant.to_string(), "merchant");
        assert_eq!(UserRole::Driver.to_string(), "driver");
    }

    #[test]
    fn test_user_role_serde() {
        let json = serde_json::to_string(&UserRole::Client).unwrap();
        assert_eq!(json, "\"client\"");
        let parsed: UserRole = serde_json::from_str("\"merchant\"").unwrap();
        assert_eq!(parsed, UserRole::Merchant);
    }

    #[test]
    fn test_user_status_serde() {
        let json = serde_json::to_string(&UserStatus::PendingKyc).unwrap();
        assert_eq!(json, "\"pending_kyc\"");
        let parsed: UserStatus = serde_json::from_str("\"active\"").unwrap();
        assert_eq!(parsed, UserStatus::Active);
    }

    #[test]
    fn test_request_otp_payload_deserialize() {
        let json = r#"{"phone": "+2250700000000"}"#;
        let payload: RequestOtpPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.phone, "+2250700000000");
    }

    #[test]
    fn test_verify_otp_payload_deserialize() {
        let json = r#"{"phone": "+2250700000000", "otp": "123456", "name": "Koffi"}"#;
        let payload: VerifyOtpPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.phone, "+2250700000000");
        assert_eq!(payload.otp, "123456");
        assert_eq!(payload.name.unwrap(), "Koffi");
    }
}
