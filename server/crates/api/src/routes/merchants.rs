use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::config::AppConfig;
use common::error::AppError;
use common::response::ApiResponse;
use domain::merchants::business_hours::SetBusinessHoursEntry;
use domain::merchants::model::{InitiateOnboardingPayload, CreateMerchantPayload};
use domain::merchants::service;
use domain::products::model::CreateProductPayload;
use domain::users::model::UserRole;
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use sqlx::PgPool;
use uuid::Uuid;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// POST /api/v1/merchants/onboard/request-otp
///
/// Agent initiates merchant onboarding by sending OTP to merchant's phone.
pub async fn onboard_request_otp(
    auth: AuthenticatedUser,
    body: web::Json<InitiateOnboardingPayload>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
    sms_provider: web::Data<Arc<dyn SmsProvider>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let mut redis_conn = redis.get_ref().clone();
    service::initiate_onboarding(
        &pool,
        &mut redis_conn,
        sms_provider.get_ref().as_ref(),
        &config,
        auth.user_id,
        &body,
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({
        "message": "OTP envoye au numero du marchand"
    }));
    Ok(HttpResponse::Ok().json(response))
}

/// Unified onboarding payload: OTP verification + merchant data in one call.
#[derive(Debug, serde::Deserialize)]
pub struct VerifyAndCreatePayload {
    pub phone: String,
    pub otp: String,
    pub name: String,
    pub address: Option<String>,
    pub category: Option<String>,
    pub city_id: Option<Uuid>,
}

/// POST /api/v1/merchants/onboard/verify-and-create
///
/// Agent verifies OTP and creates merchant with full data in one step.
pub async fn onboard_verify_and_create(
    auth: AuthenticatedUser,
    body: web::Json<VerifyAndCreatePayload>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    redis: web::Data<ConnectionManager>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let mut redis_conn = redis.get_ref().clone();
    let create_payload = CreateMerchantPayload {
        name: body.name.clone(),
        address: body.address.clone(),
        category: body.category.clone(),
        city_id: body.city_id,
    };

    let merchant = service::verify_and_create_merchant(
        &pool,
        &mut redis_conn,
        &config,
        auth.user_id,
        &body.phone,
        &body.otp,
        &create_payload,
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({ "merchant": merchant }));
    Ok(HttpResponse::Created().json(response))
}

/// Payload for adding products.
#[derive(Debug, serde::Deserialize)]
pub struct AddProductsPayload {
    pub products: Vec<CreateProductPayload>,
}

/// POST /api/v1/merchants/{id}/products
///
/// Agent adds products to a merchant during onboarding.
pub async fn add_products(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    body: web::Json<AddProductsPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let merchant_id = path.into_inner();
    let products = service::add_products(&pool, merchant_id, auth.user_id, &body.products).await?;

    let response = ApiResponse::new(serde_json::json!({ "products": products }));
    Ok(HttpResponse::Created().json(response))
}

/// Payload for setting hours.
#[derive(Debug, serde::Deserialize)]
pub struct SetHoursPayload {
    pub hours: Vec<SetBusinessHoursEntry>,
}

/// PUT /api/v1/merchants/{id}/hours
///
/// Agent sets business hours for a merchant during onboarding.
pub async fn set_hours(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    body: web::Json<SetHoursPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let merchant_id = path.into_inner();
    let hours = service::set_hours(&pool, merchant_id, auth.user_id, &body.hours).await?;

    let response = ApiResponse::new(serde_json::json!({ "hours": hours }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/merchants/{id}/finalize
///
/// Agent finalizes merchant onboarding.
pub async fn finalize(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let merchant_id = path.into_inner();
    let merchant = service::finalize_onboarding(&pool, merchant_id, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "merchant": merchant }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/merchants/{id}/onboarding-status
///
/// Agent checks onboarding progress for a merchant.
pub async fn onboarding_status(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let merchant_id = path.into_inner();
    let status = service::get_onboarding_status(&pool, merchant_id, auth.user_id).await?;

    let response = ApiResponse::new(status);
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/merchants/onboard/in-progress
///
/// Agent gets list of incomplete onboardings.
pub async fn in_progress(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Agent, UserRole::Admin])?;

    let merchants =
        domain::merchants::repository::find_by_agent_incomplete(&pool, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "merchants": merchants }));
    Ok(HttpResponse::Ok().json(response))
}
