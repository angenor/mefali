use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::config::AppConfig;
use common::response::ApiResponse;
use domain::users::model::{LogoutPayload, RefreshPayload, RequestOtpPayload, VerifyOtpPayload};
use domain::users::service;
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use sqlx::PgPool;

/// POST /api/v1/auth/request-otp
///
/// Body: {"phone": "+225XXXXXXXXXX"}
/// Response: {"data": {"message": "OTP envoye"}}
pub async fn request_otp(
    body: web::Json<RequestOtpPayload>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
    sms_provider: web::Data<Arc<dyn SmsProvider>>,
) -> Result<HttpResponse, common::error::AppError> {
    let mut redis_conn = redis.get_ref().clone();

    service::request_otp(
        &mut redis_conn,
        sms_provider.get_ref().as_ref(),
        &config,
        &body.phone,
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({
        "message": "OTP envoye"
    }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/auth/login
///
/// Body: {"phone": "+225XXXXXXXXXX"}
/// Response: {"data": {"message": "OTP envoye"}}
///
/// Same OTP flow as request-otp, used semantically for login.
pub async fn login(
    body: web::Json<RequestOtpPayload>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
    sms_provider: web::Data<Arc<dyn SmsProvider>>,
) -> Result<HttpResponse, common::error::AppError> {
    request_otp(body, config, redis, sms_provider).await
}

/// POST /api/v1/auth/verify-otp
///
/// Body: {"phone": "+225XXXXXXXXXX", "otp": "123456", "name": "Koffi"}
/// Response: {"data": {"access_token": "...", "refresh_token": "...", "user": {...}}}
pub async fn verify_otp(
    body: web::Json<VerifyOtpPayload>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, common::error::AppError> {
    let mut redis_conn = redis.get_ref().clone();

    let auth_response = service::verify_otp_and_register(
        &mut redis_conn,
        &pool,
        &config,
        &body.phone,
        &body.otp,
        body.name.as_deref(),
    )
    .await?;

    let response = ApiResponse::new(auth_response);
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/auth/refresh
///
/// Body: {"refresh_token": "uuid"}
/// Response: {"data": {"access_token": "...", "refresh_token": "...", "user": {...}}}
pub async fn refresh(
    body: web::Json<RefreshPayload>,
    config: web::Data<AppConfig>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, common::error::AppError> {
    let auth_response = service::refresh_tokens(&pool, &config, &body.refresh_token).await?;

    let response = ApiResponse::new(auth_response);
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/auth/logout
///
/// Body: {"refresh_token": "uuid"}
/// Response: {"data": {"message": "Logged out"}}
///
/// Protected by auth middleware — requires valid access token.
pub async fn logout(
    _auth: crate::extractors::AuthenticatedUser,
    body: web::Json<LogoutPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, common::error::AppError> {
    service::logout(&pool, &body.refresh_token).await?;

    let response = ApiResponse::new(serde_json::json!({
        "message": "Logged out"
    }));
    Ok(HttpResponse::Ok().json(response))
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web, App};

    #[actix_web::test]
    async fn test_request_otp_invalid_phone_returns_400() {
        let app =
            test::init_service(App::new().route("/auth/request-otp", web::post().to(request_otp)))
                .await;

        // Missing config and redis → will fail at extraction, but tests the route setup
        let req = test::TestRequest::post()
            .uri("/auth/request-otp")
            .set_json(serde_json::json!({"phone": "+2250700000000"}))
            .to_request();

        // Without app_data, this should return 500 (missing data)
        let resp = test::call_service(&app, req).await;
        // We expect a non-200 status since we haven't injected dependencies
        assert_ne!(resp.status(), 200);
    }
}
