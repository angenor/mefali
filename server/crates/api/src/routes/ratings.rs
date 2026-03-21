use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::ratings::model::SubmitRatingRequest;
use domain::ratings::service;
use domain::users::model::UserRole;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// POST /api/v1/orders/{order_id}/rating
///
/// Submit a double rating (merchant + driver) for a delivered order.
/// Client role required. Order must belong to the authenticated user.
pub async fn submit_rating(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<SubmitRatingRequest>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let order_id = path.into_inner();
    let pair = service::submit_double_rating(&pool, order_id, auth.user_id, &body).await?;

    let response = ApiResponse::new(serde_json::json!({
        "merchant_rating": pair.merchant_rating,
        "driver_rating": pair.driver_rating,
    }));
    Ok(HttpResponse::Created().json(response))
}

/// GET /api/v1/orders/{order_id}/rating
///
/// Check if an order has already been rated. Returns the rating pair if exists.
/// Client role required. Order must belong to the authenticated user.
pub async fn get_order_rating(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let order_id = path.into_inner();
    let pair = service::get_order_ratings(&pool, order_id, auth.user_id).await?;

    let data = pair.map(|p| {
        serde_json::json!({
            "merchant_rating": p.merchant_rating,
            "driver_rating": p.driver_rating,
        })
    });
    Ok(HttpResponse::Ok().json(ApiResponse::new(data)))
}
