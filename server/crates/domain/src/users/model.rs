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
    pub role: Option<String>,
    pub sponsor_phone: Option<String>,
    pub referral_code: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub user: User,
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct RefreshToken {
    pub id: Id,
    pub user_id: Id,
    pub token_hash: String,
    pub expires_at: Timestamp,
    pub revoked_at: Option<Timestamp>,
    pub created_at: Timestamp,
}

#[derive(Debug, Deserialize)]
pub struct RefreshPayload {
    pub refresh_token: String,
}

#[derive(Debug, Deserialize)]
pub struct LogoutPayload {
    pub refresh_token: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateProfilePayload {
    pub name: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ChangePhoneRequestPayload {
    pub new_phone: String,
}

#[derive(Debug, Deserialize)]
pub struct ChangePhoneVerifyPayload {
    pub new_phone: String,
    pub otp: String,
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

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct Sponsorship {
    pub id: Id,
    pub sponsor_id: Id,
    pub sponsored_id: Id,
    pub status: SponsorshipStatus,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

impl std::fmt::Display for UserStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserStatus::Active => write!(f, "active"),
            UserStatus::PendingKyc => write!(f, "pending_kyc"),
            UserStatus::Suspended => write!(f, "suspended"),
            UserStatus::Deactivated => write!(f, "deactivated"),
        }
    }
}

// --- Admin account management types ---

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct AdminUserListItem {
    pub id: Id,
    pub phone: String,
    pub name: Option<String>,
    pub role: UserRole,
    pub status: UserStatus,
    pub city_name: Option<String>,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct AdminUserDetail {
    pub id: Id,
    pub phone: String,
    pub name: Option<String>,
    pub role: UserRole,
    pub status: UserStatus,
    pub city_name: Option<String>,
    pub referral_code: String,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
    pub total_orders: i64,
    pub completion_rate: f64,
    pub disputes_filed: i64,
    pub avg_rating: f64,
}

#[derive(Debug, Deserialize)]
pub struct AdminUserListParams {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
    pub role: Option<String>,
    pub status: Option<String>,
    pub search: Option<String>,
}

fn default_page() -> i64 {
    1
}
fn default_per_page() -> i64 {
    20
}

impl AdminUserListParams {
    pub fn offset(&self) -> i64 {
        (self.page - 1) * self.per_page
    }
}

#[derive(Debug, Deserialize)]
pub struct UpdateUserStatusRequest {
    pub new_status: UserStatus,
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct AdminAuditLog {
    pub id: Id,
    pub admin_id: Id,
    pub target_user_id: Id,
    pub action: String,
    pub old_status: Option<UserStatus>,
    pub new_status: Option<UserStatus>,
    pub reason: Option<String>,
    pub created_at: Timestamp,
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
        assert!(payload.role.is_none());
        assert!(payload.sponsor_phone.is_none());
    }

    #[test]
    fn test_verify_otp_payload_with_driver_role() {
        let json = r#"{"phone": "+2250700000000", "otp": "123456", "name": "Moussa", "role": "driver", "sponsor_phone": "+2250700000001"}"#;
        let payload: VerifyOtpPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.role.unwrap(), "driver");
        assert_eq!(payload.sponsor_phone.unwrap(), "+2250700000001");
    }

    #[test]
    fn test_verify_otp_payload_backward_compatible() {
        // B2C payload without role/sponsor_phone still works
        let json = r#"{"phone": "+2250700000000", "otp": "123456"}"#;
        let payload: VerifyOtpPayload = serde_json::from_str(json).unwrap();
        assert!(payload.name.is_none());
        assert!(payload.role.is_none());
        assert!(payload.sponsor_phone.is_none());
    }

    #[test]
    fn test_update_profile_payload_deserialize_with_name() {
        let json = r#"{"name": "Koffi"}"#;
        let payload: UpdateProfilePayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.name.unwrap(), "Koffi");
    }

    #[test]
    fn test_update_profile_payload_deserialize_empty() {
        let json = r#"{}"#;
        let payload: UpdateProfilePayload = serde_json::from_str(json).unwrap();
        assert!(payload.name.is_none());
    }

    #[test]
    fn test_change_phone_request_payload_deserialize() {
        let json = r#"{"new_phone": "+2250700000001"}"#;
        let payload: ChangePhoneRequestPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.new_phone, "+2250700000001");
    }

    #[test]
    fn test_change_phone_verify_payload_deserialize() {
        let json = r#"{"new_phone": "+2250700000001", "otp": "123456"}"#;
        let payload: ChangePhoneVerifyPayload = serde_json::from_str(json).unwrap();
        assert_eq!(payload.new_phone, "+2250700000001");
        assert_eq!(payload.otp, "123456");
    }

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
}
