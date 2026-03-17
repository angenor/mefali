use chrono::Utc;
use common::config::AppConfig;
use common::error::AppError;
use jsonwebtoken::{encode, EncodingKey, Header};
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use tracing::info;

use super::model::{AuthResponse, User};
use super::otp_service;
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

    // Find or create user
    let user = match repository::find_by_phone(pool, phone).await? {
        Some(existing) => {
            info!(phone = phone, "Existing user authenticated");
            existing
        }
        None => {
            let user = repository::create_user(pool, phone, name).await?;
            info!(phone = phone, user_id = %user.id, "New user registered");
            user
        }
    };

    let auth_response = generate_auth_response(&user, config)?;
    Ok(auth_response)
}

/// Generate JWT access and refresh tokens for a user.
fn generate_auth_response(user: &User, config: &AppConfig) -> Result<AuthResponse, AppError> {
    let now = Utc::now().timestamp();

    let access_claims = JwtClaims {
        sub: user.id.to_string(),
        role: user.role.to_string(),
        iat: now,
        exp: now + config.jwt_access_expiry as i64,
    };

    let refresh_claims = JwtClaims {
        sub: user.id.to_string(),
        role: user.role.to_string(),
        iat: now,
        exp: now + config.jwt_refresh_expiry as i64,
    };

    let encoding_key = EncodingKey::from_secret(config.jwt_secret.as_bytes());

    let access_token = encode(&Header::default(), &access_claims, &encoding_key)
        .map_err(|e| AppError::InternalError(format!("JWT encoding error: {}", e)))?;

    let refresh_token = encode(&Header::default(), &refresh_claims, &encoding_key)
        .map_err(|e| AppError::InternalError(format!("JWT encoding error: {}", e)))?;

    Ok(AuthResponse {
        access_token,
        refresh_token,
        user: user.clone(),
    })
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
    fn test_generate_auth_response() {
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

        let result = generate_auth_response(&user, &config);
        assert!(result.is_ok());
        let auth = result.unwrap();
        assert!(!auth.access_token.is_empty());
        assert!(!auth.refresh_token.is_empty());
        assert_eq!(auth.user.phone, "+2250700000000");

        // Verify token is decodable
        let decoding_key = jsonwebtoken::DecodingKey::from_secret(config.jwt_secret.as_bytes());
        let validation = jsonwebtoken::Validation::default();
        let decoded =
            jsonwebtoken::decode::<JwtClaims>(&auth.access_token, &decoding_key, &validation);
        assert!(decoded.is_ok());
        let claims = decoded.unwrap().claims;
        assert_eq!(claims.role, "client");
    }
}
