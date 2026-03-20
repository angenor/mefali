use actix_web::{web, HttpRequest, HttpResponse};
use actix_ws::Message;
use common::config::AppConfig;
use common::error::AppError;
use domain::users::service::JwtClaims;
use futures_util::StreamExt;
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::Deserialize;
use sqlx::PgPool;
use tracing::{info, warn};

#[derive(Debug, Deserialize)]
pub struct WsAuthQuery {
    pub token: String,
}

/// GET /api/v1/ws/deliveries/{order_id}/track?token=JWT
///
/// WebSocket endpoint for real-time delivery tracking.
/// Client B2C receives driver location updates relayed from Redis PubSub.
pub async fn delivery_tracking_ws(
    req: HttpRequest,
    body: web::Payload,
    path: web::Path<uuid::Uuid>,
    query: web::Query<WsAuthQuery>,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let order_id = path.into_inner();

    // Validate JWT from query param
    let decoding_key = DecodingKey::from_secret(config.jwt_secret.as_bytes());
    let validation = Validation::default();
    let token_data = decode::<JwtClaims>(&query.token, &decoding_key, &validation)
        .map_err(|e| AppError::Unauthorized(format!("Invalid token: {e}")))?;

    let user_id = uuid::Uuid::parse_str(&token_data.claims.sub)
        .map_err(|_| AppError::Unauthorized("Invalid user ID in token".into()))?;

    if token_data.claims.role != "client" {
        return Err(AppError::Forbidden(
            "Only clients can track deliveries".into(),
        ));
    }

    // Verify customer owns this order
    let order = domain::orders::repository::find_by_id(&pool, order_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Order not found".into()))?;

    if order.customer_id != user_id {
        return Err(AppError::Forbidden("You don't own this order".into()));
    }

    // Upgrade to WebSocket
    let (response, mut session, mut msg_stream) = actix_ws::handle(&req, body)
        .map_err(|e| AppError::InternalError(format!("WebSocket upgrade failed: {e}")))?;

    let redis_url = config.redis_url.clone();
    let channel = format!("delivery:{order_id}");

    info!(order_id = %order_id, user_id = %user_id, "WebSocket tracking connection established");

    // Spawn task to relay Redis PubSub -> WebSocket
    actix_web::rt::spawn(async move {
        // Create a dedicated Redis PubSub connection
        let client = match redis::Client::open(redis_url.as_str()) {
            Ok(c) => c,
            Err(e) => {
                warn!(error = %e, "Failed to create Redis client for PubSub");
                let _ = session.close(None).await;
                return;
            }
        };

        let mut pubsub = match client.get_async_pubsub().await {
            Ok(p) => p,
            Err(e) => {
                warn!(error = %e, "Failed to get PubSub connection");
                let _ = session.close(None).await;
                return;
            }
        };

        if let Err(e) = pubsub.subscribe(&channel).await {
            warn!(error = %e, channel = %channel, "Failed to subscribe to channel");
            let _ = session.close(None).await;
            return;
        }

        info!(channel = %channel, "Subscribed to Redis PubSub channel");

        let mut pubsub_stream = pubsub.on_message();

        loop {
            tokio::select! {
                // Forward Redis messages to WebSocket client
                redis_msg = pubsub_stream.next() => {
                    match redis_msg {
                        Some(msg) => {
                            let payload: String = match msg.get_payload() {
                                Ok(p) => p,
                                Err(e) => {
                                    warn!(error = %e, "Failed to parse Redis message");
                                    continue;
                                }
                            };
                            // Wrap in event envelope
                            let event = format!(
                                r#"{{"event":"delivery.location_update","data":{payload}}}"#
                            );
                            if session.text(event).await.is_err() {
                                info!(channel = %channel, "WebSocket closed, stopping relay");
                                break;
                            }
                        }
                        None => {
                            info!(channel = %channel, "Redis PubSub stream ended");
                            break;
                        }
                    }
                }
                // Handle incoming WebSocket messages (ping/pong/close)
                ws_msg = msg_stream.next() => {
                    match ws_msg {
                        Some(Ok(Message::Ping(bytes))) => {
                            if session.pong(&bytes).await.is_err() {
                                break;
                            }
                        }
                        Some(Ok(Message::Close(_))) | None => {
                            info!(channel = %channel, "Client closed WebSocket");
                            break;
                        }
                        _ => {}
                    }
                }
            }
        }

        // Cleanup: dropping pubsub automatically unsubscribes
        let _ = session.close(None).await;
        info!(channel = %channel, "WebSocket tracking session ended");
    });

    Ok(response)
}
