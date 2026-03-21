use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use common::types::PaginationParams;
use domain::disputes::model::{CreateDisputeRequest, DisputeResponse};
use domain::disputes::service;
use domain::users::model::UserRole;
use notification::fcm::{FcmClient, PushNotification};
use sqlx::PgPool;
use tracing::warn;

use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;

/// POST /api/v1/orders/{order_id}/dispute
///
/// Create a dispute for a delivered order.
/// Client role required. Order must belong to the authenticated user.
pub async fn create_dispute(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<CreateDisputeRequest>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let order_id = path.into_inner();
    let dispute = service::create_dispute(&pool, order_id, auth.user_id, &body).await?;

    // Fire-and-forget: notify admins
    {
        let pool = pool.clone();
        let fcm = fcm_client.clone();
        let dispute_type = dispute.dispute_type.to_string();
        actix_web::rt::spawn(async move {
            notify_admins_new_dispute(&pool, &dispute_type, fcm.as_ref().as_ref()).await;
        });
    }

    let response = DisputeResponse::from(dispute);
    Ok(HttpResponse::Created().json(ApiResponse::new(response)))
}

/// GET /api/v1/orders/{order_id}/dispute
///
/// Get the dispute for a specific order (if any).
/// Client role required. Order must belong to the authenticated user.
pub async fn get_order_dispute(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let order_id = path.into_inner();
    let dispute = service::get_dispute_for_order(&pool, order_id, auth.user_id).await?;

    let data = dispute.map(DisputeResponse::from);
    Ok(HttpResponse::Ok().json(ApiResponse::new(data)))
}

/// GET /api/v1/disputes/me
///
/// List disputes filed by the authenticated user, paginated.
/// Client role required.
pub async fn list_my_disputes(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    query: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let (disputes, total) =
        service::list_my_disputes(&pool, auth.user_id, query.per_page, query.offset()).await?;

    let responses: Vec<DisputeResponse> = disputes.into_iter().map(DisputeResponse::from).collect();

    Ok(HttpResponse::Ok().json(ApiResponse::with_pagination(
        responses,
        query.page,
        query.per_page,
        total,
    )))
}

/// Notify the dispute reporter that their dispute has been resolved (best-effort).
/// Ready for Story 8.2 to call from the resolve route handler.
pub async fn notify_reporter_dispute_resolved(
    pool: &PgPool,
    reporter_id: uuid::Uuid,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    let token: Option<(String,)> = match sqlx::query_as(
        "SELECT fcm_token FROM users WHERE id = $1 AND fcm_token IS NOT NULL AND fcm_token != ''",
    )
    .bind(reporter_id)
    .fetch_optional(pool)
    .await
    {
        Ok(row) => row,
        Err(e) => {
            warn!(error = %e, "Failed to fetch reporter FCM token for dispute resolution");
            return;
        }
    };

    if let Some((token,)) = token {
        let notification = PushNotification {
            device_token: token,
            title: domain::disputes::service::DISPUTE_RESOLVED_TITLE.into(),
            body: domain::disputes::service::DISPUTE_RESOLVED_BODY.into(),
            data: {
                let mut map = serde_json::Map::new();
                map.insert("event".into(), "dispute.resolved".into());
                Some(serde_json::Value::Object(map))
            },
        };
        if let Err(e) = fcm.send_push(&notification).await {
            warn!(error = %e, "Failed to send dispute resolution notification to reporter");
        }
    }
}

/// Notify all admin users of a new dispute (best-effort, fire-and-forget).
async fn notify_admins_new_dispute(
    pool: &PgPool,
    dispute_type: &str,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    // Fetch FCM tokens for all admin users
    let tokens: Vec<(String,)> = match sqlx::query_as(
        "SELECT fcm_token FROM users WHERE role = 'admin' AND fcm_token IS NOT NULL AND fcm_token != ''",
    )
    .fetch_all(pool)
    .await
    {
        Ok(rows) => rows,
        Err(e) => {
            warn!(error = %e, "Failed to fetch admin FCM tokens for dispute notification");
            return;
        }
    };

    for (token,) in tokens {
        let notification = PushNotification {
            device_token: token,
            title: "Nouveau litige signale".into(),
            body: format!("Un client a signale un probleme : {dispute_type}"),
            data: {
                let mut map = serde_json::Map::new();
                map.insert("event".into(), "dispute.created".into());
                Some(serde_json::Value::Object(map))
            },
        };
        if let Err(e) = fcm.send_push(&notification).await {
            warn!(error = %e, "Failed to send dispute notification to admin");
        }
    }
}
