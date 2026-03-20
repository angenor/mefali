use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::deliveries::service;
use domain::users::model::UserRole;
use serde::Deserialize;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

#[derive(Debug, Deserialize)]
pub struct AvailabilityBody {
    pub is_available: bool,
}

/// PUT /api/v1/drivers/availability
///
/// Driver toggles their availability status (actif / en pause).
pub async fn set_availability(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    body: web::Json<AvailabilityBody>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let is_available =
        service::toggle_driver_availability(&pool, auth.user_id, body.is_available).await?;

    let response = ApiResponse::new(serde_json::json!({ "is_available": is_available }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/drivers/availability
///
/// Driver gets their current availability status.
pub async fn get_availability(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let is_available = service::get_driver_availability(&pool, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "is_available": is_available }));
    Ok(HttpResponse::Ok().json(response))
}
