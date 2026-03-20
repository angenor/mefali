use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::deliveries::service;
use domain::users::model::UserRole;
use sqlx::PgPool;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// GET /api/v1/deliveries/pending
///
/// Driver gets their pending delivery mission with full details.
pub async fn get_pending_mission(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let mission = service::get_pending_mission(&pool, auth.user_id).await?;

    match mission {
        Some(m) => {
            let response = ApiResponse::new(serde_json::json!({ "mission": m }));
            Ok(HttpResponse::Ok().json(response))
        }
        None => {
            let response = ApiResponse::new(serde_json::json!({ "mission": null }));
            Ok(HttpResponse::Ok().json(response))
        }
    }
}
