use crate::extractors::AuthenticatedUser;
use crate::middleware::require_role;
use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use domain::deliveries::model::DeliveryRefusalReason;
use domain::deliveries::service;
use domain::users::model::UserRole;
use notification::fcm::FcmClient;
use notification::sms::SmsRouter;
use redis::aio::ConnectionManager;
use redis::AsyncCommands;
use serde::Deserialize;
use sqlx::PgPool;

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

/// POST /api/v1/deliveries/{delivery_id}/accept
///
/// Driver accepts a pending delivery mission.
pub async fn accept_mission(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    let mission = service::accept_mission(&pool, delivery_id, auth.user_id).await?;

    let response = ApiResponse::new(serde_json::json!({ "mission": mission }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct RefuseBody {
    pub reason: DeliveryRefusalReason,
}

/// POST /api/v1/deliveries/{delivery_id}/refuse
///
/// Driver refuses a pending delivery mission with a mandatory reason.
pub async fn refuse_mission(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<RefuseBody>,
    fcm_client: web::Data<Option<FcmClient>>,
    sms_router: web::Data<Option<SmsRouter>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    service::refuse_mission(
        &pool,
        delivery_id,
        auth.user_id,
        &body.reason,
        fcm_client.as_ref().as_ref(),
        sms_router.as_ref().as_ref(),
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({ "status": "refused" }));
    Ok(HttpResponse::Ok().json(response))
}

/// POST /api/v1/deliveries/{delivery_id}/confirm-pickup
///
/// Driver confirms order collection at merchant location.
pub async fn confirm_pickup(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    let delivery = service::confirm_pickup(
        &pool,
        delivery_id,
        auth.user_id,
        fcm_client.as_ref().as_ref(),
    )
    .await?;

    let response = ApiResponse::new(serde_json::json!({
        "delivery_id": delivery.id,
        "status": delivery.status,
        "picked_up_at": delivery.picked_up_at,
    }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct LocationBody {
    pub lat: f64,
    pub lng: f64,
}

/// POST /api/v1/deliveries/{delivery_id}/location
///
/// Driver updates current GPS location during active delivery.
/// After DB update: publishes to Redis PubSub for WebSocket relay,
/// calculates ETA, and sends push notification when driver is 2 min away.
pub async fn update_location(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<LocationBody>,
    redis_conn: web::Data<ConnectionManager>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    let delivery =
        service::update_driver_location(&pool, delivery_id, auth.user_id, body.lat, body.lng)
            .await?;

    // Best-effort: Redis publish + ETA notification (don't block 200 response)
    let order_id = delivery.order_id;
    let mut conn = redis_conn.get_ref().clone();

    // TODO(perf): destination coords don't change — cache in Redis to avoid DB query every 10s
    if let Ok(Some(order)) = domain::orders::repository::find_by_id(&pool, order_id).await {
        if let (Some(dest_lat), Some(dest_lng)) = (order.delivery_lat, order.delivery_lng) {
            let eta = service::calculate_eta_seconds(body.lat, body.lng, dest_lat, dest_lng);

            // Publish location update to Redis PubSub channel
            let payload = serde_json::json!({
                "lat": body.lat,
                "lng": body.lng,
                "eta_seconds": eta,
                "updated_at": chrono::Utc::now().to_rfc3339(),
            });
            let channel = format!("delivery:{order_id}");
            let _: Result<(), _> = conn
                .publish::<_, _, ()>(&channel, payload.to_string())
                .await;

            // ETA notification: send push when driver is ~2 min away (120s)
            if eta <= 120 {
                let eta_key = format!("eta_notif:{delivery_id}");
                let already_sent: bool = redis::cmd("EXISTS")
                    .arg(&eta_key)
                    .query_async(&mut conn)
                    .await
                    .unwrap_or(false);

                if !already_sent {
                    service::send_eta_approaching_notification(
                        &pool,
                        order_id,
                        fcm_client.as_ref().as_ref(),
                    )
                    .await;
                    // Set flag with 1h TTL to avoid spam
                    let _: Result<(), _> = redis::cmd("SETEX")
                        .arg(&eta_key)
                        .arg(3600i64)
                        .arg("1")
                        .query_async(&mut conn)
                        .await;
                }
            }
        } else {
            // No destination coords — still publish basic location
            let payload = serde_json::json!({
                "lat": body.lat,
                "lng": body.lng,
                "eta_seconds": 0,
                "updated_at": chrono::Utc::now().to_rfc3339(),
            });
            let channel = format!("delivery:{order_id}");
            let _: Result<(), _> = conn
                .publish::<_, _, ()>(&channel, payload.to_string())
                .await;
        }
    }

    let response = ApiResponse::new(serde_json::json!({ "status": "location_updated" }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct ConfirmDeliveryBody {
    pub driver_location: DriverLocation,
}

#[derive(Debug, Deserialize)]
pub struct DriverLocation {
    pub latitude: f64,
    pub longitude: f64,
}

/// POST /api/v1/deliveries/{delivery_id}/confirm
///
/// Driver confirms delivery at client location. Credits wallets and releases escrow.
pub async fn confirm_delivery(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<ConfirmDeliveryBody>,
    redis_conn: web::Data<ConnectionManager>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    let result = service::confirm_delivery(
        &pool,
        delivery_id,
        auth.user_id,
        body.driver_location.latitude,
        body.driver_location.longitude,
        fcm_client.as_ref().as_ref(),
    )
    .await?;

    // Publish delivery.confirmed event to Redis PubSub for WebSocket relay
    {
        let mut conn = redis_conn.get_ref().clone();
        let payload = serde_json::json!({
            "event": "delivery.confirmed",
            "data": {
                "delivery_id": delivery_id.to_string(),
                "status": "delivered",
            }
        });
        let channel = format!("delivery:{}", result.order_id);
        let _: Result<(), _> = conn
            .publish::<_, _, ()>(&channel, payload.to_string())
            .await;
    }

    let response = ApiResponse::new(serde_json::json!({
        "delivery_id": result.delivery_id,
        "status": result.status,
        "driver_earnings_fcfa": result.driver_earnings_fcfa,
        "confirmed_at": result.confirmed_at,
    }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct ClientAbsentBody {
    pub driver_location: DriverLocation,
}

/// POST /api/v1/deliveries/{delivery_id}/client-absent
///
/// Driver reports client is not present at delivery address.
/// Starts the 10-minute client absent protocol.
pub async fn report_client_absent(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<ClientAbsentBody>,
    redis_conn: web::Data<ConnectionManager>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    let delivery = service::report_client_absent(
        &pool,
        delivery_id,
        auth.user_id,
        body.driver_location.latitude,
        body.driver_location.longitude,
        fcm_client.as_ref().as_ref(),
    )
    .await?;

    // Publish delivery.client_absent event to Redis PubSub for WebSocket relay
    {
        let mut conn = redis_conn.get_ref().clone();
        let payload = serde_json::json!({
            "event": "delivery.client_absent",
            "data": {
                "delivery_id": delivery_id.to_string(),
                "status": "client_absent",
            }
        });
        let channel = format!("delivery:{}", delivery.order_id);
        let _: Result<(), _> = conn
            .publish::<_, _, ()>(&channel, payload.to_string())
            .await;
    }

    let response = ApiResponse::new(serde_json::json!({
        "delivery_id": delivery.id,
        "status": delivery.status,
    }));
    Ok(HttpResponse::Ok().json(response))
}

#[derive(Debug, Deserialize)]
pub struct ResolveAbsentBody {
    pub resolution: domain::deliveries::model::AbsentResolution,
    pub driver_location: DriverLocation,
}

/// POST /api/v1/deliveries/{delivery_id}/resolve-absent
///
/// Driver resolves client absent protocol after timer expires.
/// Driver is paid in ALL cases.
pub async fn resolve_client_absent(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<ResolveAbsentBody>,
    redis_conn: web::Data<ConnectionManager>,
    fcm_client: web::Data<Option<FcmClient>>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Driver])?;

    let delivery_id = path.into_inner();
    let result = service::resolve_client_absent(
        &pool,
        delivery_id,
        auth.user_id,
        &body.resolution,
        fcm_client.as_ref().as_ref(),
    )
    .await?;

    // Publish delivery.absent_resolved event to Redis PubSub for WebSocket relay
    {
        let mut conn = redis_conn.get_ref().clone();
        let payload = serde_json::json!({
            "event": "delivery.absent_resolved",
            "data": {
                "delivery_id": delivery_id.to_string(),
                "status": "client_absent",
                "resolution": body.resolution,
                "driver_earnings_fcfa": result.driver_earnings_fcfa,
            }
        });
        let channel = format!("delivery:{}", result.order_id);
        let _: Result<(), _> = conn
            .publish::<_, _, ()>(&channel, payload.to_string())
            .await;
    }

    let response = ApiResponse::new(serde_json::json!({
        "delivery_id": result.delivery_id,
        "status": result.status,
        "driver_earnings_fcfa": result.driver_earnings_fcfa,
        "confirmed_at": result.confirmed_at,
    }));
    Ok(HttpResponse::Ok().json(response))
}

/// GET /api/v1/deliveries/tracking/{order_id}
///
/// REST fallback for delivery tracking when WebSocket is unavailable.
/// Returns current driver position, ETA, status, and driver contact info.
pub async fn get_tracking(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Client])?;

    let order_id = path.into_inner();
    let info = domain::deliveries::repository::get_tracking_info(&pool, order_id, auth.user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("No active delivery found for this order".into()))?;

    // Calculate ETA if driver has GPS coords and destination is known
    let eta_seconds = match (
        info.driver_lat,
        info.driver_lng,
        info.dest_lat,
        info.dest_lng,
    ) {
        (Some(d_lat), Some(d_lng), Some(dest_lat), Some(dest_lng)) => Some(
            service::calculate_eta_seconds(d_lat, d_lng, dest_lat, dest_lng),
        ),
        _ => None,
    };

    let response = ApiResponse::new(serde_json::json!({
        "lat": info.driver_lat,
        "lng": info.driver_lng,
        "eta_seconds": eta_seconds,
        "status": info.delivery_status,
        "driver_name": info.driver_name,
        "driver_phone": info.driver_phone,
        "updated_at": chrono::Utc::now().to_rfc3339(),
    }));
    Ok(HttpResponse::Ok().json(response))
}
