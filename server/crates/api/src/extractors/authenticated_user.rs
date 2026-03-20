use actix_web::{dev::Payload, web, FromRequest, HttpRequest};
use common::config::AppConfig;
use common::error::AppError;
use domain::users::model::UserRole;
use domain::users::service::JwtClaims;
use jsonwebtoken::{decode, DecodingKey, Validation};
use std::future::{ready, Ready};
use uuid::Uuid;

/// Extracted from the JWT in the Authorization header.
/// Use as a handler parameter to require authentication.
#[derive(Debug, Clone)]
pub struct AuthenticatedUser {
    pub user_id: Uuid,
    pub role: UserRole,
}

impl FromRequest for AuthenticatedUser {
    type Error = AppError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _payload: &mut Payload) -> Self::Future {
        ready(extract_user(req))
    }
}

fn extract_user(req: &HttpRequest) -> Result<AuthenticatedUser, AppError> {
    let config = req
        .app_data::<web::Data<AppConfig>>()
        .ok_or_else(|| AppError::InternalError("AppConfig not configured".into()))?;

    let auth_header = req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| AppError::Unauthorized("Missing Authorization header".into()))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or_else(|| AppError::Unauthorized("Invalid Authorization header format".into()))?;

    let decoding_key = DecodingKey::from_secret(config.jwt_secret.as_bytes());
    let validation = Validation::default();

    let token_data = decode::<JwtClaims>(token, &decoding_key, &validation)
        .map_err(|e| AppError::Unauthorized(format!("Invalid token: {}", e)))?;

    let user_id = Uuid::parse_str(&token_data.claims.sub)
        .map_err(|_| AppError::Unauthorized("Invalid user ID in token".into()))?;

    let role = parse_role(&token_data.claims.role)?;

    Ok(AuthenticatedUser { user_id, role })
}

fn parse_role(role_str: &str) -> Result<UserRole, AppError> {
    match role_str {
        "client" => Ok(UserRole::Client),
        "merchant" => Ok(UserRole::Merchant),
        "driver" => Ok(UserRole::Driver),
        "agent" => Ok(UserRole::Agent),
        "admin" => Ok(UserRole::Admin),
        _ => Err(AppError::Unauthorized(format!(
            "Unknown role: {}",
            role_str
        ))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web, App, HttpResponse};
    use chrono::Utc;
    use jsonwebtoken::{encode, EncodingKey, Header};

    fn test_config() -> AppConfig {
        AppConfig {
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
            cinetpay_api_key: "mock".into(),
            cinetpay_site_id: "mock".into(),
            cinetpay_base_url: "https://api-checkout.cinetpay.com/v2".into(),
            cinetpay_notify_url: "http://localhost:8090/api/v1/payments/webhook".into(),
            cinetpay_return_url: "http://localhost:8090/payment/return".into(),
            cinetpay_webhook_secret: "test-webhook-secret".into(),
        }
    }

    fn create_test_jwt(user_id: &str, role: &str, expired: bool) -> String {
        let now = Utc::now().timestamp();
        let exp = if expired { now - 100 } else { now + 900 };
        let claims = JwtClaims {
            sub: user_id.into(),
            role: role.into(),
            iat: now,
            exp,
        };
        let key = EncodingKey::from_secret("test-secret-key-for-testing".as_bytes());
        encode(&Header::default(), &claims, &key).unwrap()
    }

    async fn protected_handler(auth: AuthenticatedUser) -> HttpResponse {
        HttpResponse::Ok().json(serde_json::json!({
            "user_id": auth.user_id.to_string(),
            "role": auth.role.to_string(),
        }))
    }

    fn test_app() -> App<
        impl actix_web::dev::ServiceFactory<
            actix_web::dev::ServiceRequest,
            Config = (),
            Response = actix_web::dev::ServiceResponse,
            Error = actix_web::Error,
            InitError = (),
        >,
    > {
        App::new()
            .app_data(web::Data::new(test_config()))
            .route("/test", web::get().to(protected_handler))
    }

    #[actix_web::test]
    async fn test_valid_token_extracts_user() {
        let user_id = Uuid::new_v4();
        let token = create_test_jwt(&user_id.to_string(), "client", false);
        let app = test::init_service(test_app()).await;

        let req = test::TestRequest::get()
            .uri("/test")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["user_id"], user_id.to_string());
        assert_eq!(body["role"], "client");
    }

    #[actix_web::test]
    async fn test_expired_token_returns_401() {
        let token = create_test_jwt(&Uuid::new_v4().to_string(), "client", true);
        let app = test::init_service(test_app()).await;

        let req = test::TestRequest::get()
            .uri("/test")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    #[actix_web::test]
    async fn test_missing_token_returns_401() {
        let app = test::init_service(test_app()).await;

        let req = test::TestRequest::get().uri("/test").to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    #[actix_web::test]
    async fn test_invalid_signature_returns_401() {
        let now = Utc::now().timestamp();
        let claims = JwtClaims {
            sub: Uuid::new_v4().to_string(),
            role: "client".into(),
            iat: now,
            exp: now + 900,
        };
        let wrong_key = EncodingKey::from_secret("wrong-secret-key".as_bytes());
        let token = encode(&Header::default(), &claims, &wrong_key).unwrap();

        let app = test::init_service(test_app()).await;

        let req = test::TestRequest::get()
            .uri("/test")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    #[actix_web::test]
    async fn test_admin_role_extracted_correctly() {
        let user_id = Uuid::new_v4();
        let token = create_test_jwt(&user_id.to_string(), "admin", false);
        let app = test::init_service(test_app()).await;

        let req = test::TestRequest::get()
            .uri("/test")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["role"], "admin");
    }

    #[actix_web::test]
    async fn test_parse_role_valid() {
        assert_eq!(parse_role("client").unwrap(), UserRole::Client);
        assert_eq!(parse_role("merchant").unwrap(), UserRole::Merchant);
        assert_eq!(parse_role("driver").unwrap(), UserRole::Driver);
        assert_eq!(parse_role("agent").unwrap(), UserRole::Agent);
        assert_eq!(parse_role("admin").unwrap(), UserRole::Admin);
    }

    #[actix_web::test]
    async fn test_parse_role_invalid() {
        assert!(parse_role("unknown").is_err());
        assert!(parse_role("").is_err());
    }
}
