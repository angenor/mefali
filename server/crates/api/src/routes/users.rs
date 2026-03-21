use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::config::AppConfig;
use common::error::AppError;
use common::response::ApiResponse;
use domain::users::model::{
    ChangePhoneRequestPayload, ChangePhoneVerifyPayload, UpdateProfilePayload,
};
use domain::users::{repository, service};
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;

#[derive(Debug, serde::Deserialize)]
pub struct FcmTokenPayload {
    pub token: String,
}

/// PUT /api/v1/users/me/fcm-token
///
/// Register or update the authenticated user's FCM token for push notifications.
pub async fn register_fcm_token(
    auth: AuthenticatedUser,
    body: web::Json<FcmTokenPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    repository::update_fcm_token(&pool, auth.user_id, Some(&body.token)).await?;

    let response = ApiResponse::new(serde_json::json!({ "message": "FCM token enregistre" }));
    Ok(HttpResponse::Ok().json(response))
}

/// DELETE /api/v1/users/me/fcm-token
///
/// Clear the authenticated user's FCM token (e.g., on logout).
pub async fn clear_fcm_token(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    repository::update_fcm_token(&pool, auth.user_id, None).await?;

    let response = ApiResponse::new(serde_json::json!({ "message": "FCM token supprime" }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/users/me
///
/// Returns the authenticated user's profile.
pub async fn me(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    let user = repository::find_by_id(&pool, auth.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("User not found".into()))?;

    let response = ApiResponse::new(serde_json::json!({ "user": user }));
    Ok(HttpResponse::Ok().json(response))
}

/// PUT /api/v1/users/me
///
/// Update the authenticated user's profile (name).
pub async fn update_profile(
    auth: AuthenticatedUser,
    body: web::Json<UpdateProfilePayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    let user = service::update_profile(&pool, auth.user_id, body.into_inner()).await?;

    let response = ApiResponse::new(serde_json::json!({ "user": user }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/users/me/referral
///
/// Returns the authenticated user's referral code.
pub async fn get_referral_code(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    let code = repository::get_referral_code(&pool, auth.user_id).await?;
    let response = ApiResponse::new(serde_json::json!({ "referral_code": code }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/users/me/change-phone/request
///
/// Request a phone number change. Sends OTP to the new phone.
pub async fn change_phone_request(
    auth: AuthenticatedUser,
    body: web::Json<ChangePhoneRequestPayload>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
    sms_provider: web::Data<Arc<dyn SmsProvider>>,
) -> Result<HttpResponse, AppError> {
    let mut redis_conn = redis.get_ref().clone();
    service::request_phone_change(
        &mut redis_conn,
        sms_provider.get_ref().as_ref(),
        &pool,
        &config,
        auth.user_id,
        body.into_inner(),
    )
    .await?;

    let response =
        ApiResponse::new(serde_json::json!({ "message": "OTP envoye au nouveau numero" }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/users/me/change-phone/verify
///
/// Verify the OTP and update the phone number.
pub async fn change_phone_verify(
    auth: AuthenticatedUser,
    body: web::Json<ChangePhoneVerifyPayload>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
) -> Result<HttpResponse, AppError> {
    let mut redis_conn = redis.get_ref().clone();
    let user = service::verify_phone_change(
        &mut redis_conn,
        &pool,
        &config,
        auth.user_id,
        body.into_inner(),
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({ "user": user }));
    Ok(HttpResponse::Ok().json(response))
}
