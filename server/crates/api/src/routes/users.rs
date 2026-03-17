use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::users::repository;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;

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
