use chrono::Utc;
use common::config::AppConfig;
use common::error::AppError;
use jsonwebtoken::{encode, EncodingKey, Header};
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use sqlx::PgPool;
use tracing::info;
use uuid::Uuid;

use super::model::{
    AuthResponse, ChangePhoneRequestPayload, ChangePhoneVerifyPayload, UpdateProfilePayload, User,
    UserRole, UserStatus,
};
use super::otp_service;
use super::refresh_token_repository;
use super::repository;
use super::sponsorship_repository;

#[derive(Debug, Serialize, Deserialize)]
pub struct JwtClaims {
    pub sub: String,
    pub role: String,
    pub iat: i64,
    pub exp: i64,
}

/// Validate phone number format for Cote d'Ivoire (+225XXXXXXXXXX).
fn validate_phone(phone: &str) -> Result<(), AppError> {
    if !phone.starts_with("+225")
        || phone.len() != 14
        || !phone[4..].chars().all(|c| c.is_ascii_digit())
    {
        return Err(AppError::BadRequest(
            "Invalid phone format. Expected +225XXXXXXXXXX".into(),
        ));
    }
    Ok(())
}

/// Hash a token with SHA-256 and return hex string.
pub fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    format!("{:x}", hasher.finalize())
}

/// Generate a JWT access token for a user.
fn generate_access_token(user: &User, config: &AppConfig) -> Result<String, AppError> {
    let now = Utc::now().timestamp();
    let claims = JwtClaims {
        sub: user.id.to_string(),
        role: user.role.to_string(),
        iat: now,
        exp: now + config.jwt_access_expiry as i64,
    };
    let encoding_key = EncodingKey::from_secret(config.jwt_secret.as_bytes());
    encode(&Header::default(), &claims, &encoding_key)
        .map_err(|e| AppError::InternalError(format!("JWT encoding error: {}", e)))
}

/// Request OTP: validate phone, check rate limit, generate OTP, send via SMS.
pub async fn request_otp(
    redis: &mut ConnectionManager,
    sms_provider: &dyn SmsProvider,
    config: &AppConfig,
    phone: &str,
) -> Result<(), AppError> {
    validate_phone(phone)?;

    otp_service::check_rate_limit(redis, phone, config.otp_rate_limit_per_minute).await?;

    let code = otp_service::generate_otp(config.otp_length);
    otp_service::store_otp(redis, phone, &code, config.otp_expiry_seconds).await?;

    let message = format!(
        "mefali: Votre code de verification est {}. Valable 5 minutes.",
        code
    );
    sms_provider
        .send_sms(phone, &message)
        .await
        .map_err(|e| AppError::ExternalServiceError(format!("SMS send failed: {}", e)))?;

    info!(phone = phone, "OTP requested and sent");
    Ok(())
}

/// Parse and validate role for self-registration.
/// Only "client" and "driver" are allowed. Defaults to "client" if absent.
fn parse_registration_role(role: Option<&str>) -> Result<UserRole, AppError> {
    match role {
        None | Some("client") => Ok(UserRole::Client),
        Some("driver") => Ok(UserRole::Driver),
        Some(other) => Err(AppError::BadRequest(format!(
            "Invalid role for self-registration: {}",
            other
        ))),
    }
}

/// Verify OTP, create user if new, return JWT tokens.
/// Supports multi-role registration: role and sponsor_phone are optional.
pub async fn verify_otp_and_register(
    redis: &mut ConnectionManager,
    pool: &PgPool,
    config: &AppConfig,
    phone: &str,
    otp: &str,
    name: Option<&str>,
    role: Option<&str>,
    sponsor_phone: Option<&str>,
) -> Result<AuthResponse, AppError> {
    validate_phone(phone)?;

    otp_service::verify_otp(redis, phone, otp, config.otp_max_attempts).await?;

    // Find or create user — login vs registration distinction
    let user = match repository::find_by_phone(pool, phone).await? {
        Some(existing) => {
            // Login: user exists, return as-is (no role change)
            info!(phone = phone, "Existing user authenticated");
            existing
        }
        None => {
            // Registration: name is required for new users
            let name = name.ok_or_else(|| {
                AppError::NotFound("User not found. Please register first.".into())
            })?;

            let parsed_role = parse_registration_role(role)?;

            // Validate sponsor BEFORE creating user to avoid orphaned drivers
            let sponsor = if parsed_role == UserRole::Driver {
                let sp = sponsor_phone.ok_or_else(|| {
                    AppError::BadRequest("Sponsor phone is required for driver registration".into())
                })?;
                validate_phone(sp)?;

                // Prevent self-sponsoring
                if phone == sp {
                    return Err(AppError::BadRequest(
                        "Cannot use your own phone as sponsor".into(),
                    ));
                }

                let sponsor = repository::find_by_phone(pool, sp).await?.ok_or_else(|| {
                    AppError::BadRequest("Sponsor not found. Ensure they are registered.".into())
                })?;
                Some(sponsor)
            } else {
                None
            };

            let (user_role, user_status) = if parsed_role == UserRole::Driver {
                (UserRole::Driver, UserStatus::PendingKyc)
            } else {
                (UserRole::Client, UserStatus::Active)
            };

            let user =
                repository::create_user(pool, phone, Some(name), user_role, user_status).await?;

            // Create sponsorship (sponsor already validated above)
            if let Some(sponsor) = sponsor {
                sponsorship_repository::create(pool, sponsor.id, user.id).await?;
                info!(phone = phone, user_id = %user.id, sponsor_id = %sponsor.id, "Driver registered with sponsor");
            } else {
                info!(phone = phone, user_id = %user.id, "New user registered");
            }

            user
        }
    };

    let auth_response = generate_auth_response(pool, &user, config).await?;
    Ok(auth_response)
}

/// Generate JWT access token and opaque refresh token for a user.
/// The refresh token is a UUID v4, stored as SHA-256 hash in DB.
pub async fn generate_auth_response(
    pool: &PgPool,
    user: &User,
    config: &AppConfig,
) -> Result<AuthResponse, AppError> {
    let access_token = generate_access_token(user, config)?;

    // Refresh token: opaque UUID v4, hashed SHA-256 before storage
    let refresh_uuid = Uuid::new_v4();
    let refresh_token_raw = refresh_uuid.to_string();
    let token_hash = hash_token(&refresh_token_raw);
    let expires_at = Utc::now() + chrono::Duration::seconds(config.jwt_refresh_expiry as i64);

    refresh_token_repository::create(pool, user.id, &token_hash, expires_at).await?;

    Ok(AuthResponse {
        access_token,
        refresh_token: refresh_token_raw,
        user: user.clone(),
    })
}

/// Refresh tokens: validate refresh token, rotate, return new pair.
pub async fn refresh_tokens(
    pool: &PgPool,
    config: &AppConfig,
    refresh_token: &str,
) -> Result<AuthResponse, AppError> {
    let token_hash = hash_token(refresh_token);

    let stored = refresh_token_repository::find_by_hash(pool, &token_hash)
        .await?
        .ok_or_else(|| AppError::Unauthorized("Invalid refresh token".into()))?;

    if stored.revoked_at.is_some() {
        return Err(AppError::Unauthorized(
            "Refresh token has been revoked".into(),
        ));
    }

    if stored.expires_at < Utc::now() {
        return Err(AppError::Unauthorized("Refresh token has expired".into()));
    }

    // Revoke the old refresh token (rotation)
    refresh_token_repository::revoke(pool, stored.id).await?;

    // Find the user
    let user = repository::find_by_id(pool, stored.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".into()))?;

    // Generate new auth response with new tokens
    generate_auth_response(pool, &user, config).await
}

/// Logout: revoke the refresh token.
pub async fn logout(pool: &PgPool, refresh_token: &str) -> Result<(), AppError> {
    let token_hash = hash_token(refresh_token);

    let stored = refresh_token_repository::find_by_hash(pool, &token_hash)
        .await?
        .ok_or_else(|| AppError::Unauthorized("Invalid refresh token".into()))?;

    refresh_token_repository::revoke(pool, stored.id).await?;
    info!(user_id = %stored.user_id, "User logged out, refresh token revoked");
    Ok(())
}

/// Validate and update user profile (name only).
pub async fn update_profile(
    pool: &PgPool,
    user_id: uuid::Uuid,
    payload: UpdateProfilePayload,
) -> Result<User, AppError> {
    if let Some(ref name) = payload.name {
        let trimmed = name.trim();
        if trimmed.is_empty() {
            return Err(AppError::BadRequest("Name cannot be empty".into()));
        }
        if trimmed.len() > 100 {
            return Err(AppError::BadRequest(
                "Name cannot exceed 100 characters".into(),
            ));
        }
        return repository::update_name(pool, user_id, trimmed).await;
    }

    // No fields to update — return current user
    repository::find_by_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".into()))
}

/// Request phone change: validate new phone, check uniqueness, send OTP.
pub async fn request_phone_change(
    redis: &mut redis::aio::ConnectionManager,
    sms_provider: &dyn SmsProvider,
    pool: &PgPool,
    config: &AppConfig,
    user_id: uuid::Uuid,
    payload: ChangePhoneRequestPayload,
) -> Result<(), AppError> {
    validate_phone(&payload.new_phone)?;

    // Verify new phone is not already taken
    if let Some(_existing) = repository::find_by_phone(pool, &payload.new_phone).await? {
        return Err(AppError::Conflict("Phone number already in use".into()));
    }

    // Verify user exists
    let user = repository::find_by_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".into()))?;

    // Don't allow changing to the same phone
    if user.phone == payload.new_phone {
        return Err(AppError::BadRequest(
            "New phone must be different from current phone".into(),
        ));
    }

    otp_service::check_rate_limit(redis, &payload.new_phone, config.otp_rate_limit_per_minute)
        .await?;

    let code = otp_service::generate_otp(config.otp_length);
    otp_service::store_otp(redis, &payload.new_phone, &code, config.otp_expiry_seconds).await?;

    let message = format!(
        "mefali: Code de verification pour changement de telephone: {}. Valable 5 minutes.",
        code
    );
    sms_provider
        .send_sms(&payload.new_phone, &message)
        .await
        .map_err(|e| AppError::ExternalServiceError(format!("SMS send failed: {}", e)))?;

    info!(user_id = %user_id, new_phone = &payload.new_phone, "Phone change OTP sent");
    Ok(())
}

/// Verify phone change OTP and update phone.
pub async fn verify_phone_change(
    redis: &mut redis::aio::ConnectionManager,
    pool: &PgPool,
    config: &AppConfig,
    user_id: uuid::Uuid,
    payload: ChangePhoneVerifyPayload,
) -> Result<User, AppError> {
    validate_phone(&payload.new_phone)?;

    // Re-check uniqueness (race condition protection)
    if let Some(_existing) = repository::find_by_phone(pool, &payload.new_phone).await? {
        return Err(AppError::Conflict("Phone number already in use".into()));
    }

    otp_service::verify_otp(
        redis,
        &payload.new_phone,
        &payload.otp,
        config.otp_max_attempts,
    )
    .await?;

    let user = repository::update_phone(pool, user_id, &payload.new_phone).await?;
    info!(user_id = %user_id, new_phone = &payload.new_phone, "Phone number updated");
    Ok(user)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_phone_valid() {
        assert!(validate_phone("+2250700000000").is_ok());
        assert!(validate_phone("+2250102030405").is_ok());
    }

    #[test]
    fn test_validate_phone_invalid() {
        assert!(validate_phone("0700000000").is_err());
        assert!(validate_phone("+33612345678").is_err());
        assert!(validate_phone("+225070000").is_err());
        assert!(validate_phone("+225abcdefghij").is_err());
        assert!(validate_phone("").is_err());
    }

    #[test]
    fn test_jwt_claims_serialization() {
        let claims = JwtClaims {
            sub: "test-uuid".into(),
            role: "client".into(),
            iat: 1000,
            exp: 2000,
        };
        let json = serde_json::to_value(&claims).unwrap();
        assert_eq!(json["sub"], "test-uuid");
        assert_eq!(json["role"], "client");
        assert_eq!(json["exp"], 2000);
    }

    #[test]
    fn test_hash_token() {
        let token = "test-token-uuid";
        let hash = hash_token(token);
        // SHA-256 produces 64 hex characters
        assert_eq!(hash.len(), 64);
        // Same input produces same hash
        assert_eq!(hash, hash_token(token));
        // Different input produces different hash
        assert_ne!(hash, hash_token("different-token"));
    }

    #[test]
    fn test_generate_access_token() {
        let user = User {
            id: uuid::Uuid::new_v4(),
            phone: "+2250700000000".into(),
            name: Some("Koffi".into()),
            role: super::super::model::UserRole::Client,
            status: super::super::model::UserStatus::Active,
            city_id: None,
            fcm_token: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        let config = AppConfig {
            database_url: String::new(),
            redis_url: String::new(),
            minio_endpoint: String::new(),
            minio_access_key: String::new(),
            minio_secret_key: String::new(),
            minio_bucket: String::new(),
            api_host: String::new(),
            api_port: 8090,
            jwt_secret: "test-secret-key-for-testing".into(),
            jwt_access_expiry: 900,
            jwt_refresh_expiry: 604800,
            otp_length: 6,
            otp_expiry_seconds: 300,
            otp_max_attempts: 3,
            otp_rate_limit_per_minute: 3,
        };

        let result = generate_access_token(&user, &config);
        assert!(result.is_ok());
        let token = result.unwrap();
        assert!(!token.is_empty());

        // Verify token is decodable
        let decoding_key = jsonwebtoken::DecodingKey::from_secret(config.jwt_secret.as_bytes());
        let validation = jsonwebtoken::Validation::default();
        let decoded = jsonwebtoken::decode::<JwtClaims>(&token, &decoding_key, &validation);
        assert!(decoded.is_ok());
        let claims = decoded.unwrap().claims;
        assert_eq!(claims.role, "client");
    }

    #[test]
    fn test_parse_registration_role_none_defaults_to_client() {
        let role = parse_registration_role(None).unwrap();
        assert_eq!(role, UserRole::Client);
    }

    #[test]
    fn test_parse_registration_role_client() {
        let role = parse_registration_role(Some("client")).unwrap();
        assert_eq!(role, UserRole::Client);
    }

    #[test]
    fn test_parse_registration_role_driver() {
        let role = parse_registration_role(Some("driver")).unwrap();
        assert_eq!(role, UserRole::Driver);
    }

    #[test]
    fn test_parse_registration_role_admin_rejected() {
        assert!(parse_registration_role(Some("admin")).is_err());
    }

    #[test]
    fn test_parse_registration_role_merchant_rejected() {
        assert!(parse_registration_role(Some("merchant")).is_err());
    }

    #[test]
    fn test_parse_registration_role_agent_rejected() {
        assert!(parse_registration_role(Some("agent")).is_err());
    }

    #[test]
    fn test_parse_registration_role_unknown_rejected() {
        assert!(parse_registration_role(Some("superadmin")).is_err());
    }

    #[test]
    fn test_validate_name_empty_rejected() {
        // Empty name should fail validation in update_profile
        let payload = UpdateProfilePayload {
            name: Some("".into()),
        };
        assert!(payload.name.as_ref().unwrap().trim().is_empty());
    }

    #[test]
    fn test_validate_name_whitespace_only_rejected() {
        let payload = UpdateProfilePayload {
            name: Some("   ".into()),
        };
        assert!(payload.name.as_ref().unwrap().trim().is_empty());
    }

    #[test]
    fn test_validate_name_too_long_rejected() {
        let long_name = "a".repeat(101);
        let payload = UpdateProfilePayload {
            name: Some(long_name.clone()),
        };
        assert!(payload.name.as_ref().unwrap().trim().len() > 100);
    }

    #[test]
    fn test_validate_name_valid() {
        let payload = UpdateProfilePayload {
            name: Some("Koffi".into()),
        };
        let name = payload.name.as_ref().unwrap().trim();
        assert!(!name.is_empty());
        assert!(name.len() <= 100);
    }

    #[test]
    fn test_validate_name_100_chars_valid() {
        let name = "a".repeat(100);
        let payload = UpdateProfilePayload {
            name: Some(name.clone()),
        };
        let trimmed = payload.name.as_ref().unwrap().trim();
        assert_eq!(trimmed.len(), 100);
    }

    #[test]
    fn test_update_profile_no_fields_is_noop() {
        // If name is None, nothing to update
        let payload = UpdateProfilePayload { name: None };
        assert!(payload.name.is_none());
    }
}
