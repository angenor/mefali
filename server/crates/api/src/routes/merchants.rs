use std::sync::Arc;

use actix_web::{web, HttpResponse};
use common::config::AppConfig;
use common::error::AppError;
use common::response::ApiResponse;
use domain::merchants::business_hours::SetBusinessHoursEntry;
use domain::merchants::model::{
    CreateMerchantPayload, InitiateOnboardingPayload, UpdateStatusPayload,
};
use domain::merchants::service;
use domain::merchants::service::list_active_merchants;
use domain::products::model::CreateProductPayload;
use domain::users::model::UserRole;
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use sqlx::PgPool;
use uuid::Uuid;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// Query params for GET /api/v1/merchants.
#[derive(Debug, serde::Deserialize)]
pub struct ListMerchantsQuery {
    pub category: Option<String>,
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}

/// GET /api/v1/merchants
///
/// B2C customer browses fully onboarded merchants (discovery screen).
/// Requires Client or Admin role. Returns paginated list ordered by availability then name.
pub async fn list_merchants(
    auth: AuthenticatedUser,
    query: web::Query<ListMerchantsQuery>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client, UserRole::Admin])?;

    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(20);
    let category = query.category.as_deref();

    let result = list_active_merchants(&pool, category, page, per_page).await?;

    let response = ApiResponse::with_pagination(
        result.merchants,
        result.page as i64,
        result.per_page as i64,
        result.total,
    );
    Ok(HttpResponse::Ok().json(response))
}

/// Query params for GET /api/v1/merchants/{id}/products.
#[derive(Debug, serde::Deserialize)]
pub struct ListMerchantProductsQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
}

/// GET /api/v1/merchants/{id}/products
///
/// B2C customer views a merchant's product catalogue.
/// Requires Client or Admin role. Returns paginated product list.
pub async fn list_merchant_products(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    query: web::Query<ListMerchantProductsQuery>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client, UserRole::Admin])?;

    let merchant_id = path.into_inner();
    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(50);

    let result = service::list_merchant_products_public(&pool, merchant_id, page, per_page).await?;

    let response = ApiResponse::with_pagination(
        result.products,
        result.page as i64,
        result.per_page as i64,
        result.total,
    );
    Ok(HttpResponse::Ok().json(response))
}

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

/// PUT /api/v1/merchants/me/status
///
/// Merchant updates their availability status.
pub async fn update_status(
    auth: AuthenticatedUser,
    body: web::Json<UpdateStatusPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    body.validate()?;
    let merchant = service::change_status(&pool, auth.user_id, body.into_inner().status).await?;

    let response = ApiResponse::new(serde_json::json!({ "merchant": merchant }));
    Ok(HttpResponse::Ok().json(response))
}

// ---- Self-service business hours (Story 3.8) ----

/// GET /api/v1/merchants/me/hours
///
/// Merchant reads their own business hours.
pub async fn get_my_hours(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let hours = service::get_my_hours(&pool, auth.user_id).await?;

    let response = ApiResponse::new(hours);
    Ok(HttpResponse::Ok().json(response))
}

/// PUT /api/v1/merchants/me/hours
///
/// Merchant updates their own business hours.
pub async fn update_my_hours(
    auth: AuthenticatedUser,
    body: web::Json<SetHoursPayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let hours = service::update_my_hours(&pool, auth.user_id, &body.hours).await?;

    let response = ApiResponse::new(hours);
    Ok(HttpResponse::Ok().json(response))
}

// ---- Self-service exceptional closures (Story 3.8) ----

/// GET /api/v1/merchants/me/closures
///
/// Merchant lists their upcoming exceptional closures.
pub async fn get_my_closures(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let closures = service::get_my_closures(&pool, auth.user_id).await?;

    let response = ApiResponse::new(closures);
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/merchants/me/closures
///
/// Merchant creates an exceptional closure.
pub async fn create_my_closure(
    auth: AuthenticatedUser,
    body: web::Json<domain::merchants::exceptional_closures::CreateClosurePayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let closure = service::create_my_closure(&pool, auth.user_id, &body).await?;

    let response = ApiResponse::new(closure);
    Ok(HttpResponse::Created().json(response))
}

/// DELETE /api/v1/merchants/me/closures/{id}
///
/// Merchant deletes an exceptional closure.
pub async fn delete_my_closure(
    auth: AuthenticatedUser,
    path: web::Path<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let closure_id = path.into_inner();
    service::delete_my_closure(&pool, auth.user_id, closure_id).await?;

    Ok(HttpResponse::NoContent().finish())
}

// ---- Merchant profile with effective status (Story 3.8) ----

/// GET /api/v1/merchants/me (enhanced with effective_status)
///
/// Merchant gets their own profile data including effective availability status.
pub async fn get_me_with_status(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;

    let result = service::get_current_merchant_with_effective_status(&pool, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "merchant": result }));
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

#[cfg(test)]
mod integration_tests {
    use actix_web::test;
    use domain::test_fixtures::*;
    use domain::users::model::UserRole;
    use sqlx::PgPool;

    // ---- Restaurant Discovery (T7.1) ----

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_200_empty(pool: PgPool) {
        let user = create_test_user_with_role(&pool, UserRole::Client)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(user.id, "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().unwrap().is_empty());
        assert_eq!(body["meta"]["total"].as_i64().unwrap(), 0);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_returns_only_finalized(pool: PgPool) {
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        // Create finalized merchant (onboarding_step = 5) — should be returned
        let _finalized = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();
        // Create merchant with step = 1 — should NOT be returned
        let merchant_user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _partial = create_test_merchant(&pool, merchant_user.id).await.unwrap();

        let client = create_test_user_with_role(&pool, UserRole::Client)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(client.id, "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        let merchants = body["data"].as_array().unwrap();
        assert_eq!(merchants.len(), 1);
        assert_eq!(body["meta"]["total"].as_i64().unwrap(), 1);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchants_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    // ---- Merchant Products B2C (T1 Story 4.2) ----

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchant_products_200(pool: PgPool) {
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        let merchant = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();
        let _product = create_test_product(&pool, merchant.id).await.unwrap();

        let client = create_test_user_with_role(&pool, UserRole::Client)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(client.id, "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/merchants/{}/products", merchant.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        let products = body["data"].as_array().unwrap();
        assert_eq!(products.len(), 1);
        assert_eq!(body["meta"]["total"].as_i64().unwrap(), 1);
        assert!(products[0]["name"].as_str().is_some());
        assert!(products[0]["price"].as_i64().is_some());
        assert!(products[0]["stock"].as_i64().is_some());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchant_products_200_empty(pool: PgPool) {
        let agent = create_test_user_with_role(&pool, UserRole::Agent)
            .await
            .unwrap();
        let merchant = create_test_merchant_for_agent(&pool, agent.id)
            .await
            .unwrap();

        let client = create_test_user_with_role(&pool, UserRole::Client)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(client.id, "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/merchants/{}/products", merchant.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().unwrap().is_empty());
        assert_eq!(body["meta"]["total"].as_i64().unwrap(), 0);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchant_products_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri(&format!(
                "/api/v1/merchants/{}/products",
                uuid::Uuid::new_v4()
            ))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_list_merchant_products_404_not_finalized(pool: PgPool) {
        // Merchant with onboarding_step = 1 (not finalized) — should return 404
        let merchant_user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let merchant = create_test_merchant(&pool, merchant_user.id).await.unwrap();

        let client = create_test_user_with_role(&pool, UserRole::Client)
            .await
            .unwrap();
        let token = crate::test_helpers::create_test_jwt(client.id, "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        // Use the actual non-finalized merchant ID (onboarding_step = 1)
        let req = test::TestRequest::get()
            .uri(&format!("/api/v1/merchants/{}/products", merchant.id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 404);
    }

    // ---- Business Hours (T6.3) ----

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_hours_200(pool: PgPool) {
        let user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant = create_test_merchant(&pool, user.id).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(user.id, "merchant");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/hours")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().is_some());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_put_hours_200(pool: PgPool) {
        let user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant = create_test_merchant(&pool, user.id).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(user.id, "merchant");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let hours_payload = serde_json::json!({
            "hours": [
                {"day_of_week": 0, "open_time": "08:00", "close_time": "18:00", "is_closed": false},
                {"day_of_week": 1, "open_time": "08:00", "close_time": "18:00", "is_closed": false},
                {"day_of_week": 2, "open_time": "08:00", "close_time": "18:00", "is_closed": false},
                {"day_of_week": 3, "open_time": "08:00", "close_time": "18:00", "is_closed": false},
                {"day_of_week": 4, "open_time": "08:00", "close_time": "18:00", "is_closed": false},
                {"day_of_week": 5, "open_time": "09:00", "close_time": "14:00", "is_closed": false},
                {"day_of_week": 6, "open_time": "00:00", "close_time": "00:00", "is_closed": true}
            ]
        });

        let req = test::TestRequest::put()
            .uri("/api/v1/merchants/me/hours")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(&hours_payload)
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        let data = body["data"].as_array().unwrap();
        assert_eq!(data.len(), 7);
    }

    // ---- Exceptional Closures (T6.3) ----

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_get_closures_200_empty(pool: PgPool) {
        let user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant = create_test_merchant(&pool, user.id).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(user.id, "merchant");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/closures")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 200);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().unwrap().is_empty());
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_post_closure_201(pool: PgPool) {
        let user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant = create_test_merchant(&pool, user.id).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(user.id, "merchant");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let payload = serde_json::json!({
            "closure_date": "2027-01-01",
            "reason": "Jour de l'An"
        });

        let req = test::TestRequest::post()
            .uri("/api/v1/merchants/me/closures")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(&payload)
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 201);

        let body: serde_json::Value = test::read_body_json(resp).await;
        assert_eq!(body["data"]["closure_date"].as_str().unwrap(), "2027-01-01");
        assert_eq!(body["data"]["reason"].as_str().unwrap(), "Jour de l'An");
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_delete_closure_204(pool: PgPool) {
        let user = create_test_user_with_role(&pool, UserRole::Merchant)
            .await
            .unwrap();
        let _merchant = create_test_merchant(&pool, user.id).await.unwrap();

        let token = crate::test_helpers::create_test_jwt(user.id, "merchant");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        // Create a closure first
        let payload = serde_json::json!({
            "closure_date": "2027-06-15",
            "reason": "Congé"
        });
        let req = test::TestRequest::post()
            .uri("/api/v1/merchants/me/closures")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(&payload)
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 201);
        let body: serde_json::Value = test::read_body_json(resp).await;
        let closure_id = body["data"]["id"].as_str().unwrap();

        // Delete it
        let req = test::TestRequest::delete()
            .uri(&format!("/api/v1/merchants/me/closures/{}", closure_id))
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 204);

        // Verify it's gone
        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/closures")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
        let resp = test::call_service(&app, req).await;
        let body: serde_json::Value = test::read_body_json(resp).await;
        assert!(body["data"].as_array().unwrap().is_empty());
    }

    // ---- Auth / Role checks (T6.3) ----

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_hours_401_no_token(pool: PgPool) {
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let req = test::TestRequest::get()
            .uri("/api/v1/merchants/me/hours")
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 401);
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn test_closures_403_wrong_role(pool: PgPool) {
        let token = crate::test_helpers::create_test_jwt(uuid::Uuid::new_v4(), "client");
        let app = test::init_service(crate::test_helpers::test_app(pool)).await;

        let payload = serde_json::json!({
            "closure_date": "2027-01-01",
            "reason": "Test"
        });

        let req = test::TestRequest::post()
            .uri("/api/v1/merchants/me/closures")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(&payload)
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status(), 403);
    }
}
