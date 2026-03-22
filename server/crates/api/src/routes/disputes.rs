use actix_web::{web, HttpResponse};
use common::error::AppError;
use common::response::ApiResponse;
use common::types::PaginationParams;
use domain::disputes::model::{CreateDisputeRequest, DisputeResponse};
use domain::disputes::service;
use domain::users::model::UserRole;
use notification::fcm::{FcmClient, PushNotification};
use notification::sms::SmsRouter;
use sqlx::PgPool;
use tracing::{info, warn};

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
    sms_router: web::Data<Option<SmsRouter>>,
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

    // Fire-and-forget: notify sponsor if the driver is sponsored (Story 9.2)
    {
        let pool = pool.clone();
        let fcm = fcm_client.clone();
        let sms = sms_router.clone();
        let dispute_id = dispute.id;
        let dispute_type = dispute.dispute_type.to_string();
        actix_web::rt::spawn(async move {
            notify_sponsor_if_applicable(
                &pool,
                order_id,
                dispute_id,
                &dispute_type,
                fcm.as_ref().as_ref(),
                sms.as_ref().as_ref(),
            )
            .await;
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

/// Notify the sponsor of a sponsored driver when a dispute is created (best-effort).
/// Does nothing if the driver has no active sponsor or if the order has no driver.
async fn notify_sponsor_if_applicable(
    pool: &PgPool,
    order_id: uuid::Uuid,
    dispute_id: uuid::Uuid,
    dispute_type: &str,
    fcm_client: Option<&FcmClient>,
    sms_router: Option<&SmsRouter>,
) {
    // 1. Get driver_id from the order
    let driver_id = match sqlx::query_as::<_, (Option<uuid::Uuid>,)>(
        "SELECT driver_id FROM orders WHERE id = $1",
    )
    .bind(order_id)
    .fetch_optional(pool)
    .await
    {
        Ok(Some((Some(id),))) => id,
        Ok(_) => return, // No order or no driver assigned
        Err(e) => {
            warn!(error = %e, "Failed to fetch driver_id for sponsor notification");
            return;
        }
    };

    // 2. Find active sponsor for this driver
    let sponsor = match domain::sponsorships::service::find_active_sponsor_for_driver(
        pool, driver_id,
    )
    .await
    {
        Ok(Some(s)) => s,
        Ok(None) => return, // No active sponsor — skip silently
        Err(e) => {
            warn!(error = %e, "Failed to find sponsor for driver");
            return;
        }
    };

    // 3. Get driver name for notification message
    let driver_name: String = match sqlx::query_as::<_, (Option<String>,)>(
        "SELECT name FROM users WHERE id = $1",
    )
    .bind(driver_id)
    .fetch_optional(pool)
    .await
    {
        Ok(Some((Some(name),))) => name,
        _ => "votre filleul".into(),
    };

    // 4. Send FCM push if sponsor has a token, otherwise SMS fallback
    let mut notification_type: Option<&str> = None;

    if let Some(ref token) = sponsor.fcm_token {
        if !token.is_empty() {
            if let Some(fcm) = fcm_client {
                let body = service::sponsor_dispute_alert_body(dispute_type, &driver_name);
                let notification = PushNotification {
                    device_token: token.clone(),
                    title: service::SPONSOR_DISPUTE_ALERT_TITLE.into(),
                    body,
                    data: {
                        let mut map = serde_json::Map::new();
                        map.insert("event".into(), "sponsorship.dispute_alert".into());
                        map.insert("dispute_id".into(), dispute_id.to_string().into());
                        map.insert("driver_name".into(), driver_name.clone().into());
                        Some(serde_json::Value::Object(map))
                    },
                };
                match fcm.send_push(&notification).await {
                    Ok(_) => {
                        notification_type = Some("push");
                        info!(
                            sponsor_id = %sponsor.id,
                            driver_id = %driver_id,
                            "Sponsor notified via FCM for dispute"
                        );
                    }
                    Err(e) => {
                        warn!(error = %e, "Failed to send FCM to sponsor, falling back to SMS");
                    }
                }
            }
        }
    }

    // SMS fallback if FCM not sent
    if notification_type.is_none() {
        if let Some(sms) = sms_router {
            let short_id = &dispute_id.to_string()[..8];
            let message = service::sponsor_dispute_alert_sms(dispute_type, &driver_name, short_id);
            match sms.send(&sponsor.phone, &message).await {
                Ok(_) => {
                    notification_type = Some("sms");
                    info!(
                        sponsor_id = %sponsor.id,
                        sponsor_phone = %sponsor.phone,
                        "Sponsor notified via SMS for dispute"
                    );
                }
                Err(e) => {
                    warn!(error = %e, "Failed to send SMS to sponsor");
                }
            }
        }
    }

    // 5. Record sponsor_contacted event in dispute timeline
    if let Some(notif_type) = notification_type {
        let sponsor_name = sponsor.name.as_deref().unwrap_or("Parrain");
        let label = format!("Parrain contacte : {} ({})", sponsor_name, sponsor.phone);
        let metadata = {
            let mut map = serde_json::Map::new();
            map.insert("sponsor_id".into(), sponsor.id.to_string().into());
            map.insert("notification_type".into(), notif_type.into());
            serde_json::Value::Object(map)
        };
        if let Err(e) = domain::disputes::repository::insert_dispute_event(
            pool,
            dispute_id,
            "sponsor_contacted",
            &label,
            Some(metadata),
        )
        .await
        {
            warn!(error = %e, "Failed to record sponsor_contacted event in timeline");
        }
    }

    // 6. Check progressive penalties: revoke sponsorship rights if threshold reached (Story 9.3)
    check_sponsor_penalties(
        pool,
        sponsor.id,
        dispute_id,
        &sponsor,
        fcm_client,
        sms_router,
    )
    .await;
}

/// Check if sponsor's drivers have accumulated enough disputes to trigger revocation.
/// If revoked: send notification, insert audit log, and record dispute event.
async fn check_sponsor_penalties(
    pool: &PgPool,
    sponsor_id: uuid::Uuid,
    dispute_id: uuid::Uuid,
    sponsor: &domain::sponsorships::model::SponsorContactInfo,
    fcm_client: Option<&FcmClient>,
    sms_router: Option<&SmsRouter>,
) {
    let revoked =
        match domain::sponsorships::service::check_and_revoke_sponsor_rights(pool, sponsor_id)
            .await
        {
            Ok(r) => r,
            Err(e) => {
                warn!(error = %e, "Failed to check sponsor penalties");
                return;
            }
        };

    if !revoked {
        return;
    }

    // Send revocation notification (FCM + SMS fallback)
    let mut notified = false;

    if let Some(ref token) = sponsor.fcm_token {
        if !token.is_empty() {
            if let Some(fcm) = fcm_client {
                let notification = PushNotification {
                    device_token: token.clone(),
                    title: domain::sponsorships::service::SPONSOR_RIGHTS_REVOKED_TITLE.into(),
                    body: domain::sponsorships::service::SPONSOR_RIGHTS_REVOKED_BODY.into(),
                    data: {
                        let mut map = serde_json::Map::new();
                        map.insert("event".into(), "sponsorship.rights_revoked".into());
                        Some(serde_json::Value::Object(map))
                    },
                };
                match fcm.send_push(&notification).await {
                    Ok(_) => {
                        notified = true;
                        info!(sponsor_id = %sponsor_id, "Sponsor notified of rights revocation via FCM");
                    }
                    Err(e) => {
                        warn!(error = %e, "Failed to send FCM for rights revocation, falling back to SMS");
                    }
                }
            }
        }
    }

    if !notified {
        if let Some(sms) = sms_router {
            match sms
                .send(
                    &sponsor.phone,
                    domain::sponsorships::service::SPONSOR_RIGHTS_REVOKED_SMS,
                )
                .await
            {
                Ok(_) => {
                    info!(sponsor_id = %sponsor_id, "Sponsor notified of rights revocation via SMS");
                }
                Err(e) => {
                    warn!(error = %e, "Failed to send SMS for rights revocation");
                }
            }
        }
    }

    // Record dispute event for timeline
    let sponsor_name = sponsor.name.as_deref().unwrap_or("Parrain");
    let label = format!(
        "Droits de parrainage revoques pour {} ({})",
        sponsor_name, sponsor.phone
    );
    let metadata = {
        let mut map = serde_json::Map::new();
        map.insert("sponsor_id".into(), sponsor_id.to_string().into());
        map.insert("reason".into(), "dispute_threshold_reached".into());
        serde_json::Value::Object(map)
    };
    if let Err(e) = domain::disputes::repository::insert_dispute_event(
        pool,
        dispute_id,
        "sponsor_rights_revoked",
        &label,
        Some(metadata),
    )
    .await
    {
        warn!(error = %e, "Failed to record sponsor_rights_revoked event");
    }

    // Insert audit log (system action — use sponsor_id as actor since UUID nil violates FK)
    if let Err(e) = domain::users::repository::insert_audit_log(
        pool,
        sponsor_id,
        sponsor_id,
        "revoke_sponsorship_rights",
        None,
        None,
        Some("Seuil de litiges filleuls atteint (3+)"),
    )
    .await
    {
        warn!(error = %e, "Failed to insert audit log for sponsorship revocation");
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
