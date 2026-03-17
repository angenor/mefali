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

use super::model::{AuthResponse, User};
use super::otp_service;
use super::refresh_token_repository;
use super::repository;

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

/// Verify OTP, create user if new, return JWT tokens.
pub async fn verify_otp_and_register(
    redis: &mut ConnectionManager,
    pool: &PgPool,
    config: &AppConfig,
    phone: &str,
    otp: &str,
    name: Option<&str>,
) -> Result<AuthResponse, AppError> {
    validate_phone(phone)?;

    otp_service::verify_otp(redis, phone, otp, config.otp_max_attempts).await?;

    // Find or create user — login vs registration distinction
    let user = match repository::find_by_phone(pool, phone).await? {
        Some(existing) => {
            // Login: user exists, no name required
            info!(phone = phone, "Existing user authenticated");
            existing
        }
        None => {
            // Registration: name is required for new users
            let name = name.ok_or_else(|| {
                AppError::NotFound("User not found. Please register first.".into())
            })?;
            let user = repository::create_user(pool, phone, Some(name)).await?;
            info!(phone = phone, user_id = %user.id, "New user registered");
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
}
