use common::error::AppError;
use common::types::Id;
use notification::deep_link;
use notification::fcm::{FcmClient, PushNotification};
use notification::sms::SmsRouter;
use sqlx::PgPool;
use tracing::{info, warn};

use super::model::{AbsentResolution, ConfirmDeliveryResponse, Delivery, DeliveryMission, DeliveryRefusalReason};
use super::repository;
use crate::merchants;
use crate::orders;
use crate::wallets;

/// Notify an available driver about a ready order.
/// Creates a delivery record, sends push notification, and falls back to SMS if push fails.
pub async fn notify_driver_for_order(
    pool: &PgPool,
    order_id: Id,
    fcm_client: Option<&FcmClient>,
    sms_router: Option<&SmsRouter>,
) -> Result<(), AppError> {
    // Check if delivery already exists for this order
    if let Some(existing) = repository::find_by_order(pool, order_id).await? {
        warn!(
            order_id = %order_id,
            delivery_id = %existing.id,
            "Delivery already exists for order, skipping notification"
        );
        return Ok(());
    }

    // Find an available driver
    let driver = match repository::find_available_driver(pool).await? {
        Some(d) => d,
        None => {
            warn!(order_id = %order_id, "No available driver found for order");
            return Ok(());
        }
    };

    // Create delivery record
    let delivery = repository::create_delivery(pool, order_id, driver.id).await?;

    // Update order with assigned driver
    orders::repository::set_driver(pool, order_id, driver.id).await?;

    info!(
        order_id = %order_id,
        driver_id = %driver.id,
        delivery_id = %delivery.id,
        "Delivery created and driver assigned"
    );

    // Build notification payload with mission details
    let mission = build_mission_payload(pool, &delivery, order_id).await?;

    // Try push notification first
    let push_succeeded = try_send_push(fcm_client, &driver, &mission, &delivery).await;

    // SMS fallback if push failed (NFR22: < 30s after push failure)
    if !push_succeeded {
        if let Some(router) = sms_router {
            let sms_text = build_sms_mission_text(&mission);
            match router.send(&driver.phone, &sms_text).await {
                Ok(result) => {
                    info!(
                        order_id = %order_id,
                        driver_id = %driver.id,
                        provider = %result.provider_used,
                        "SMS fallback sent successfully"
                    );
                }
                Err(e) => {
                    warn!(
                        order_id = %order_id,
                        driver_id = %driver.id,
                        error = %e,
                        "SMS fallback also failed — mission notification lost"
                    );
                }
            }
        } else {
            warn!(
                order_id = %order_id,
                "SMS router not configured — no fallback available"
            );
        }
    }

    Ok(())
}

/// Attempt to send a push notification. Returns true if successful.
async fn try_send_push(
    fcm_client: Option<&FcmClient>,
    driver: &repository::AvailableDriver,
    mission: &DeliveryMission,
    delivery: &super::model::Delivery,
) -> bool {
    let fcm = match fcm_client {
        Some(c) => c,
        None => {
            warn!("FCM not configured — skipping push");
            return false;
        }
    };

    let token = match driver.fcm_token {
        Some(ref t) if !t.is_empty() => t.clone(),
        _ => {
            warn!(driver_id = %driver.id, "Driver has no FCM token — skipping push");
            return false;
        }
    };

    let notification = PushNotification {
        device_token: token,
        title: "Nouvelle course mefali".into(),
        body: format!(
            "{} -> {}",
            mission.merchant_name,
            mission.delivery_address.as_deref().unwrap_or("adresse inconnue")
        ),
        data: {
            let mut map = serde_json::Map::new();
            map.insert("type".into(), "delivery_mission".into());
            map.insert("delivery_id".into(), delivery.id.to_string().into());
            map.insert("order_id".into(), mission.order_id.to_string().into());
            map.insert("merchant_name".into(), mission.merchant_name.clone().into());
            if let Some(ref v) = mission.merchant_address {
                map.insert("merchant_address".into(), v.clone().into());
            }
            if let Some(ref v) = mission.delivery_address {
                map.insert("delivery_address".into(), v.clone().into());
            }
            if let Some(v) = mission.delivery_lat {
                map.insert("delivery_lat".into(), v.to_string().into());
            }
            if let Some(v) = mission.delivery_lng {
                map.insert("delivery_lng".into(), v.to_string().into());
            }
            if let Some(v) = mission.estimated_distance_m {
                map.insert("estimated_distance_m".into(), v.to_string().into());
            }
            map.insert("delivery_fee".into(), mission.delivery_fee.to_string().into());
            map.insert("items_summary".into(), mission.items_summary.clone().into());
            map.insert("payment_type".into(), mission.payment_type.clone().into());
            map.insert("order_total".into(), mission.order_total.to_string().into());
            Some(serde_json::Value::Object(map))
        },
    };

    match fcm.send_push(&notification).await {
        Ok(_) => {
            info!(
                driver_id = %driver.id,
                "Push notification sent successfully"
            );
            true
        }
        Err(e) => {
            warn!(
                driver_id = %driver.id,
                error = %e,
                "Push notification failed — will try SMS fallback"
            );
            false
        }
    }
}

/// Build SMS text with deep link for offline drivers.
/// Format: "Commande #{short_id}. {merchant} -> {address}. {payment} {amount}F. {deep_link}"
/// Readable text is truncated to keep SMS compact; deep link is never truncated.
fn build_sms_mission_text(mission: &DeliveryMission) -> String {
    let encoded = deep_link::encode_deep_link(mission).unwrap_or_default();
    let link = format!("mefali://delivery/mission?data={encoded}");

    let order_short = &mission.order_id.to_string()[..8];
    let address = mission.delivery_address.as_deref().unwrap_or("Adresse a confirmer");
    let payment_label = if mission.payment_type == "cod" { "COD" } else { "MM" };
    let amount_fcfa = mission.order_total / 100;

    // Truncate readable text to keep SMS compact (deep link is never truncated)
    let merchant = truncate_str(&mission.merchant_name, 20);
    let short_addr = truncate_str(address, 25);

    format!(
        "Commande #{order_short}. {merchant} -> {short_addr}. {payment_label} {amount_fcfa}F. {link}",
    )
}

/// Truncate a string to max_len chars, ending at a valid UTF-8 char boundary.
fn truncate_str(s: &str, max_len: usize) -> &str {
    if s.chars().count() <= max_len {
        return s;
    }
    let end = s
        .char_indices()
        .nth(max_len)
        .map_or(s.len(), |(idx, _)| idx);
    &s[..end]
}

/// Build the mission payload with order + merchant details.
async fn build_mission_payload(
    pool: &PgPool,
    delivery: &super::model::Delivery,
    order_id: Id,
) -> Result<DeliveryMission, AppError> {
    let order = orders::repository::find_by_id(pool, order_id)
        .await?
        .ok_or_else(|| AppError::InternalError("Order not found for delivery".into()))?;

    let merchant = merchants::repository::find_by_id(pool, order.merchant_id)
        .await?
        .ok_or_else(|| AppError::InternalError("Merchant not found for order".into()))?;

    let items = orders::repository::find_items_by_order(pool, order_id).await?;
    let items_summary = items
        .iter()
        .map(|i| {
            format!(
                "{} x{}",
                i.product_name.as_deref().unwrap_or("Article"),
                i.quantity
            )
        })
        .collect::<Vec<_>>()
        .join(", ");

    // Haversine distance estimate if both merchant and delivery coords are available
    let estimated_distance_m = estimate_distance(
        merchant.address.as_deref(),
        order.delivery_lat,
        order.delivery_lng,
    );

    Ok(DeliveryMission {
        delivery_id: delivery.id,
        order_id,
        merchant_name: merchant.name,
        merchant_address: merchant.address,
        delivery_address: order.delivery_address,
        delivery_lat: order.delivery_lat,
        delivery_lng: order.delivery_lng,
        estimated_distance_m,
        delivery_fee: order.delivery_fee,
        items_summary,
        payment_type: match order.payment_type {
            orders::model::PaymentType::Cod => "cod".into(),
            orders::model::PaymentType::MobileMoney => "mobile_money".into(),
        },
        order_total: order.total,
        created_at: delivery.created_at,
    })
}

/// Accept a delivery mission. Validates driver ownership and updates status.
/// Returns the enriched mission on success, or Conflict if already taken.
pub async fn accept_mission(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
) -> Result<DeliveryMission, AppError> {
    // First verify the delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    // Atomically accept (only if still pending)
    let accepted = repository::accept_delivery(pool, delivery_id, driver_id)
        .await?
        .ok_or_else(|| {
            AppError::Conflict("Delivery already assigned or no longer pending".into())
        })?;

    info!(
        delivery_id = %delivery_id,
        driver_id = %driver_id,
        "Driver accepted delivery mission"
    );

    // Return enriched mission
    build_mission_payload(pool, &accepted, accepted.order_id).await
}

/// Refuse a delivery mission, then reassign to the next available driver.
/// The refusal reason is logged but not stored in DB (analytics future).
/// Uses a transaction to ensure refuse + reassign are atomic (NFR28: no order loss).
pub async fn refuse_mission(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    reason: &DeliveryRefusalReason,
    fcm_client: Option<&FcmClient>,
    sms_router: Option<&SmsRouter>,
) -> Result<(), AppError> {
    // Verify delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    let order_id = delivery.order_id;

    // Transaction: refuse + reassign atomically
    let mut tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    // Atomically refuse (only if still pending), persist reason
    let reason_str = reason.to_string();
    let refused = sqlx::query_as::<_, super::model::Delivery>(&format!(
        "UPDATE deliveries SET status = 'refused', refusal_reason = $2, updated_at = now()
         WHERE id = $1 AND status = 'pending'
         RETURNING {}",
        repository::DELIVERY_COLUMNS
    ))
    .bind(delivery_id)
    .bind(&reason_str)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to refuse delivery: {e}")))?;

    if refused.is_none() {
        return Err(AppError::Conflict(
            "Delivery already assigned or no longer pending".into(),
        ));
    }

    info!(
        delivery_id = %delivery_id,
        driver_id = %driver_id,
        reason = %reason,
        "Driver refused delivery mission"
    );

    // Get all drivers who already refused this order
    let mut excluded: Vec<Id> = sqlx::query_scalar::<_, Id>(
        "SELECT driver_id FROM deliveries WHERE order_id = $1 AND status = 'refused'",
    )
    .bind(order_id)
    .fetch_all(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get refused drivers: {e}")))?;
    excluded.push(driver_id);

    // Find next available driver (excluding those who already refused)
    let next_driver = sqlx::query_as::<_, repository::AvailableDriver>(
        "SELECT u.id, u.phone, u.fcm_token FROM users u
         WHERE u.role = 'driver' AND u.status = 'active'
           AND u.id != ALL($1)
           AND NOT EXISTS (
             SELECT 1 FROM deliveries d
             WHERE d.driver_id = u.id
               AND d.status IN ('pending', 'assigned', 'picked_up', 'in_transit')
           )
         ORDER BY u.created_at ASC
         LIMIT 1",
    )
    .bind(&excluded)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find next available driver: {e}")))?;

    let new_delivery = match next_driver {
        Some(ref next) => {
            let d = sqlx::query_as::<_, super::model::Delivery>(&format!(
                "INSERT INTO deliveries (order_id, driver_id, status)
                 VALUES ($1, $2, 'pending')
                 RETURNING {}",
                repository::DELIVERY_COLUMNS
            ))
            .bind(order_id)
            .bind(next.id)
            .fetch_one(&mut *tx)
            .await
            .map_err(|e| AppError::DatabaseError(format!("Failed to create delivery: {e}")))?;

            // Update order with new driver
            sqlx::query(
                "UPDATE orders SET driver_id = $2, updated_at = now() WHERE id = $1",
            )
            .bind(order_id)
            .bind(next.id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                AppError::DatabaseError(format!("Failed to update order driver: {e}"))
            })?;

            info!(
                order_id = %order_id,
                next_driver_id = %next.id,
                new_delivery_id = %d.id,
                "Reassigned delivery to next driver"
            );
            Some(d)
        }
        None => {
            warn!(
                order_id = %order_id,
                "No more available drivers for order — delivery stays unassigned"
            );
            None
        }
    };

    tx.commit()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit transaction: {e}")))?;

    // Post-commit: notify new driver or alert admins (best-effort, outside transaction)
    match (next_driver, new_delivery) {
        (Some(next), Some(ref del)) => {
            let mission = build_mission_payload(pool, del, order_id).await?;
            let push_ok = try_send_push(fcm_client, &next, &mission, del).await;
            if !push_ok {
                if let Some(router) = sms_router {
                    let sms_text = build_sms_mission_text(&mission);
                    if let Err(e) = router.send(&next.phone, &sms_text).await {
                        warn!(
                            order_id = %order_id,
                            driver_id = %next.id,
                            error = %e,
                            "SMS fallback failed for reassigned delivery"
                        );
                    }
                }
            }
        }
        _ => {
            // No driver available — notify admins (AC #6, NFR28)
            notify_admins_no_driver(pool, order_id, fcm_client).await;
        }
    }

    Ok(())
}

/// Notify admin users when no driver is available for an order (AC #6, NFR28).
async fn notify_admins_no_driver(
    pool: &PgPool,
    order_id: Id,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    let admins = match sqlx::query_as::<_, repository::AvailableDriver>(
        "SELECT id, phone, fcm_token FROM users WHERE role = 'admin' AND status = 'active'",
    )
    .fetch_all(pool)
    .await
    {
        Ok(a) => a,
        Err(e) => {
            warn!(error = %e, "Failed to query admin users for no-driver alert");
            return;
        }
    };

    let order_short = &order_id.to_string()[..8];
    for admin in &admins {
        if let Some(ref token) = admin.fcm_token {
            if !token.is_empty() {
                let notification = PushNotification {
                    device_token: token.clone(),
                    title: "Commande sans livreur".into(),
                    body: format!(
                        "Aucun livreur disponible pour la commande #{order_short}. Action requise."
                    ),
                    data: None,
                };
                if let Err(e) = fcm.send_push(&notification).await {
                    warn!(admin_id = %admin.id, error = %e, "Failed to notify admin");
                }
            }
        }
    }

    info!(
        order_id = %order_id,
        admins_notified = admins.len(),
        "Admin notification sent for unassigned order"
    );
}

/// Confirm order pickup by driver. Updates status Assigned -> PickedUp and notifies merchant.
pub async fn confirm_pickup(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    fcm_client: Option<&FcmClient>,
) -> Result<Delivery, AppError> {
    // Verify delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    // Atomically confirm pickup (only if assigned)
    let picked_up = repository::confirm_pickup(pool, delivery_id, driver_id)
        .await?
        .ok_or_else(|| {
            AppError::Conflict("Delivery is not in assigned status — cannot confirm pickup".into())
        })?;

    info!(
        delivery_id = %delivery_id,
        driver_id = %driver_id,
        "Driver confirmed order pickup"
    );

    // Notify merchant (best-effort, failure does not rollback pickup)
    notify_merchant_pickup(pool, &picked_up, fcm_client).await;

    Ok(picked_up)
}

/// Update driver location during an active delivery (NFR7: every 10s).
/// Returns the updated Delivery so the caller can compute ETA and publish to Redis.
pub async fn update_driver_location(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    lat: f64,
    lng: f64,
) -> Result<Delivery, AppError> {
    // Validate GPS coordinates bounds
    if lat.is_nan() || lat.is_infinite() || lng.is_nan() || lng.is_infinite()
        || !(-90.0..=90.0).contains(&lat)
        || !(-180.0..=180.0).contains(&lng)
    {
        return Err(AppError::BadRequest(
            "Invalid GPS coordinates: latitude must be -90 to 90, longitude must be -180 to 180"
                .into(),
        ));
    }

    // Verify delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    let updated = repository::update_location(pool, delivery_id, driver_id, lat, lng)
        .await?
        .ok_or_else(|| {
            AppError::Conflict("Delivery is not in an active status for location updates".into())
        })?;

    Ok(updated)
}

/// Notify merchant that driver has collected the order (AC #4).
/// Best-effort: failure is logged but does not affect pickup confirmation.
async fn notify_merchant_pickup(
    pool: &PgPool,
    delivery: &super::model::Delivery,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    // Get merchant user_id via order -> merchant -> user
    let order = match orders::repository::find_by_id(pool, delivery.order_id).await {
        Ok(Some(o)) => o,
        _ => {
            warn!(delivery_id = %delivery.id, "Could not find order for merchant notification");
            return;
        }
    };

    let merchant = match merchants::repository::find_by_id(pool, order.merchant_id).await {
        Ok(Some(m)) => m,
        _ => {
            warn!(merchant_id = %order.merchant_id, "Could not find merchant for notification");
            return;
        }
    };

    // Get merchant's user record for FCM token
    let user = match crate::users::repository::find_by_id(pool, merchant.user_id).await {
        Ok(Some(u)) => u,
        _ => {
            warn!(user_id = %merchant.user_id, "Could not find merchant user for notification");
            return;
        }
    };

    if let Some(ref token) = user.fcm_token {
        if !token.is_empty() {
            let notification = PushNotification {
                device_token: token.clone(),
                title: "Commande collectee".into(),
                body: format!("Le livreur a collecte votre commande #{}", &delivery.order_id.to_string()[..8]),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "order.collected".into());
                    map.insert("order_id".into(), delivery.order_id.to_string().into());
                    map.insert("delivery_id".into(), delivery.id.to_string().into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(
                    merchant_id = %order.merchant_id,
                    error = %e,
                    "Failed to notify merchant of pickup"
                );
            } else {
                info!(
                    merchant_id = %order.merchant_id,
                    delivery_id = %delivery.id,
                    "Merchant notified of order pickup"
                );
            }
        }
    }
}

/// Confirm delivery completion. Validates driver ownership, location proximity,
/// credits wallets, and updates order status.
///
/// Returns driver earnings for the WalletCreditFeedback UI.
pub async fn confirm_delivery(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    lat: f64,
    lng: f64,
    fcm_client: Option<&FcmClient>,
) -> Result<ConfirmDeliveryResponse, AppError> {
    // Verify delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    // Idempotency: if already delivered, return success without double payment
    if delivery.status == super::model::DeliveryStatus::Delivered {
        return Ok(ConfirmDeliveryResponse {
            delivery_id: delivery.id,
            order_id: delivery.order_id,
            status: super::model::DeliveryStatus::Delivered,
            driver_earnings_fcfa: 0,
            confirmed_at: delivery.delivered_at.unwrap_or_else(common::types::now),
        });
    }

    // Validate GPS coordinates bounds
    if lat.is_nan() || lat.is_infinite() || lng.is_nan() || lng.is_infinite()
        || !(-90.0..=90.0).contains(&lat)
        || !(-180.0..=180.0).contains(&lng)
    {
        return Err(AppError::BadRequest(
            "Invalid GPS coordinates: latitude must be -90 to 90, longitude must be -180 to 180"
                .into(),
        ));
    }

    // Validate location proximity (must be within 200m of delivery address)
    let order = orders::repository::find_by_id(pool, delivery.order_id)
        .await?
        .ok_or_else(|| AppError::InternalError("Order not found for delivery".into()))?;

    if let (Some(dest_lat), Some(dest_lng)) = (order.delivery_lat, order.delivery_lng) {
        let distance_m = haversine_distance_m(lat, lng, dest_lat, dest_lng);
        if distance_m > 200.0 {
            return Err(AppError::BadRequest(
                "Vous êtes trop loin de l'adresse de livraison".into(),
            ));
        }
    }

    // Atomically confirm delivery (accepts picked_up or client_absent status)
    let confirmed = repository::confirm_delivery(pool, delivery_id, driver_id, lat, lng)
        .await?
        .ok_or_else(|| {
            AppError::Conflict(
                "Delivery is not in picked_up or client_absent status — cannot confirm delivery".into(),
            )
        })?;

    // Credit driver wallet
    let driver_earnings =
        wallets::service::credit_driver_for_delivery(pool, &confirmed, &order).await?;

    // For prepaid orders: credit merchant wallet + release escrow
    if order.payment_type == orders::model::PaymentType::MobileMoney {
        wallets::service::credit_merchant_for_delivery(pool, &order).await?;
        orders::repository::release_escrow(pool, order.id).await?;
    }

    // Update order status to delivered
    orders::repository::mark_delivered(pool, order.id).await?;

    info!(
        delivery_id = %delivery_id,
        driver_id = %driver_id,
        driver_earnings = driver_earnings,
        payment_type = ?order.payment_type,
        "Delivery confirmed and wallets credited"
    );

    // Best-effort: notify customer
    notify_customer_delivery_confirmed(pool, &order, fcm_client).await;

    let confirmed_at = confirmed.delivered_at.unwrap_or_else(common::types::now);

    Ok(ConfirmDeliveryResponse {
        delivery_id: confirmed.id,
        order_id: confirmed.order_id,
        status: confirmed.status,
        driver_earnings_fcfa: driver_earnings,
        confirmed_at,
    })
}

/// Haversine distance in meters between two GPS points.
fn haversine_distance_m(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
    let r = 6_371_000.0_f64;
    let d_lat = (lat2 - lat1).to_radians();
    let d_lng = (lng2 - lng1).to_radians();
    let a = (d_lat / 2.0).sin().powi(2)
        + lat1.to_radians().cos() * lat2.to_radians().cos() * (d_lng / 2.0).sin().powi(2);
    2.0 * r * a.sqrt().asin()
}

/// Notify customer that delivery is confirmed (best-effort).
async fn notify_customer_delivery_confirmed(
    pool: &PgPool,
    order: &orders::model::Order,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    let customer = match crate::users::repository::find_by_id(pool, order.customer_id).await {
        Ok(Some(u)) => u,
        _ => return,
    };

    if let Some(ref token) = customer.fcm_token {
        if !token.is_empty() {
            let notification = PushNotification {
                device_token: token.clone(),
                title: "Commande livree".into(),
                body: "Votre commande a ete livree ! Bon appetit.".into(),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "delivery.confirmed".into());
                    map.insert("order_id".into(), order.id.to_string().into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(order_id = %order.id, error = %e, "Failed to notify customer of delivery");
            }
        }
    }
}

/// Get the pending mission details for a driver.
pub async fn get_pending_mission(
    pool: &PgPool,
    driver_id: Id,
) -> Result<Option<DeliveryMission>, AppError> {
    let delivery = match repository::find_pending_for_driver(pool, driver_id).await? {
        Some(d) => d,
        None => return Ok(None),
    };

    let mission = build_mission_payload(pool, &delivery, delivery.order_id).await?;
    Ok(Some(mission))
}

/// Simple distance estimate (returns None — proper haversine will come with GPS tracking).
fn estimate_distance(
    _merchant_address: Option<&str>,
    _delivery_lat: Option<f64>,
    _delivery_lng: Option<f64>,
) -> Option<i64> {
    // Distance estimation requires merchant lat/lng which is not yet in the schema.
    // Will be implemented with GPS tracking in story 5.4.
    None
}

/// Calculate ETA in seconds using haversine distance / 25 km/h (moto Bouake).
///
/// Returns the estimated time of arrival from driver position to destination.
/// Uses a constant speed of 25 km/h which is a reasonable average for a moto
/// in Bouake city traffic.
pub fn calculate_eta_seconds(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> i64 {
    let r = 6_371_000.0_f64; // Earth radius in meters
    let d_lat = (lat2 - lat1).to_radians();
    let d_lng = (lng2 - lng1).to_radians();
    let a = (d_lat / 2.0).sin().powi(2)
        + lat1.to_radians().cos() * lat2.to_radians().cos() * (d_lng / 2.0).sin().powi(2);
    let distance_m = 2.0 * r * a.sqrt().asin();
    let speed_mps = 25_000.0 / 3_600.0; // 25 km/h in m/s
    (distance_m / speed_mps).ceil() as i64
}

/// Send "driver arriving in 2 minutes" push notification to customer.
/// Best-effort: failure is logged but does not affect location update.
pub async fn send_eta_approaching_notification(
    pool: &PgPool,
    order_id: Id,
    fcm_client: Option<&notification::fcm::FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    // Get customer user via order
    let order = match orders::repository::find_by_id(pool, order_id).await {
        Ok(Some(o)) => o,
        _ => {
            warn!(order_id = %order_id, "Could not find order for ETA notification");
            return;
        }
    };

    let customer = match crate::users::repository::find_by_id(pool, order.customer_id).await {
        Ok(Some(u)) => u,
        _ => {
            warn!(customer_id = %order.customer_id, "Could not find customer for ETA notification");
            return;
        }
    };

    if let Some(ref token) = customer.fcm_token {
        if !token.is_empty() {
            let notification = notification::fcm::PushNotification {
                device_token: token.clone(),
                title: "Votre livreur arrive bientot".into(),
                body: "Votre livreur arrive dans 2 minutes !".into(),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "delivery.eta_approaching".into());
                    map.insert("order_id".into(), order_id.to_string().into());
                    map.insert("eta_seconds".into(), "120".into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(order_id = %order_id, error = %e, "Failed to send ETA notification to customer");
            } else {
                info!(order_id = %order_id, "ETA approaching notification sent to customer");
            }
        }
    }
}

/// Report client absent at delivery address. Transitions picked_up -> client_absent.
/// Notifies the customer via push notification (best-effort).
pub async fn report_client_absent(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    lat: f64,
    lng: f64,
    fcm_client: Option<&FcmClient>,
) -> Result<Delivery, AppError> {
    // Verify delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    // Validate GPS coordinates bounds
    if lat.is_nan() || lat.is_infinite() || lng.is_nan() || lng.is_infinite()
        || !(-90.0..=90.0).contains(&lat)
        || !(-180.0..=180.0).contains(&lng)
    {
        return Err(AppError::BadRequest(
            "Invalid GPS coordinates".into(),
        ));
    }

    // Atomically mark client absent (only if picked_up)
    let updated = repository::mark_client_absent(pool, delivery_id, driver_id)
        .await?
        .ok_or_else(|| {
            AppError::Conflict(
                "Delivery is not in picked_up status — cannot report client absent".into(),
            )
        })?;

    info!(
        delivery_id = %delivery_id,
        driver_id = %driver_id,
        "Client absent protocol started"
    );

    // Best-effort: notify customer
    notify_customer_client_absent(pool, &updated, fcm_client).await;

    Ok(updated)
}

/// Resolve client absent protocol after timer expires.
/// Driver is paid in ALL cases. Order is cancelled with reason.
pub async fn resolve_client_absent(
    pool: &PgPool,
    delivery_id: Id,
    driver_id: Id,
    resolution: &AbsentResolution,
    fcm_client: Option<&FcmClient>,
) -> Result<ConfirmDeliveryResponse, AppError> {
    // Verify delivery exists and belongs to this driver
    let delivery = repository::find_by_id(pool, delivery_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Delivery not found".into()))?;

    if delivery.driver_id != driver_id {
        return Err(AppError::Forbidden(
            "This delivery is not assigned to you".into(),
        ));
    }

    // Must be in client_absent status
    if delivery.status != super::model::DeliveryStatus::ClientAbsent {
        return Err(AppError::Conflict(
            "Delivery is not in client_absent status — cannot resolve".into(),
        ));
    }

    // Load order for payment info
    let order = orders::repository::find_by_id(pool, delivery.order_id)
        .await?
        .ok_or_else(|| AppError::InternalError("Order not found for delivery".into()))?;

    // Credit driver wallet — driver is paid in ALL cases
    let driver_earnings =
        wallets::service::credit_driver_for_delivery(pool, &delivery, &order).await?;

    // Cancel order with appropriate reason
    let reason = match order.payment_type {
        orders::model::PaymentType::MobileMoney => "client_absent_prepaid",
        orders::model::PaymentType::Cod => "client_absent",
    };
    orders::repository::cancel_order(pool, order.id, reason).await?;

    // For prepaid: do NOT release escrow, do NOT credit merchant
    // Escrow stays held for admin resolution (Epic 8)

    info!(
        delivery_id = %delivery_id,
        driver_id = %driver_id,
        resolution = ?resolution,
        driver_earnings = driver_earnings,
        payment_type = ?order.payment_type,
        "Client absent resolved — driver paid, order cancelled"
    );

    // Best-effort: notify customer of resolution
    notify_customer_absent_resolved(pool, &order, resolution, fcm_client).await;

    Ok(ConfirmDeliveryResponse {
        delivery_id: delivery.id,
        order_id: delivery.order_id,
        status: super::model::DeliveryStatus::ClientAbsent,
        driver_earnings_fcfa: driver_earnings,
        confirmed_at: common::types::now(),
    })
}

/// Notify customer that driver couldn't find them (best-effort).
async fn notify_customer_client_absent(
    pool: &PgPool,
    delivery: &Delivery,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    let order = match orders::repository::find_by_id(pool, delivery.order_id).await {
        Ok(Some(o)) => o,
        _ => return,
    };

    let customer = match crate::users::repository::find_by_id(pool, order.customer_id).await {
        Ok(Some(u)) => u,
        _ => return,
    };

    if let Some(ref token) = customer.fcm_token {
        if !token.is_empty() {
            let notification = PushNotification {
                device_token: token.clone(),
                title: "Livreur ne vous trouve pas".into(),
                body: "Le livreur ne vous trouve pas a l'adresse indiquee. Il attend 10 minutes.".into(),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "delivery.client_absent".into());
                    map.insert("order_id".into(), order.id.to_string().into());
                    map.insert("delivery_id".into(), delivery.id.to_string().into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(order_id = %order.id, error = %e, "Failed to notify customer of client absent");
            }
        }
    }
}

/// Notify customer of absent resolution (best-effort).
async fn notify_customer_absent_resolved(
    pool: &PgPool,
    order: &orders::model::Order,
    resolution: &AbsentResolution,
    fcm_client: Option<&FcmClient>,
) {
    let fcm = match fcm_client {
        Some(c) => c,
        None => return,
    };

    let customer = match crate::users::repository::find_by_id(pool, order.customer_id).await {
        Ok(Some(u)) => u,
        _ => return,
    };

    let (title, body) = match (resolution, &order.payment_type) {
        (_, orders::model::PaymentType::MobileMoney) => (
            "Commande non livree",
            "Votre commande n'a pas pu etre livree. Vous pouvez la recuperer a la base mefali.",
        ),
        _ => (
            "Commande non livree",
            "Votre commande n'a pas pu etre livree car vous n'etiez pas a l'adresse.",
        ),
    };

    if let Some(ref token) = customer.fcm_token {
        if !token.is_empty() {
            let notification = PushNotification {
                device_token: token.clone(),
                title: title.into(),
                body: body.into(),
                data: {
                    let mut map = serde_json::Map::new();
                    map.insert("event".into(), "delivery.absent_resolved".into());
                    map.insert("order_id".into(), order.id.to_string().into());
                    Some(serde_json::Value::Object(map))
                },
            };
            if let Err(e) = fcm.send_push(&notification).await {
                warn!(order_id = %order.id, error = %e, "Failed to notify customer of absent resolution");
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;

    fn sample_mission() -> DeliveryMission {
        DeliveryMission {
            delivery_id: uuid::Uuid::new_v4(),
            order_id: uuid::Uuid::new_v4(),
            merchant_name: "Maman Adjoua".into(),
            merchant_address: Some("Marche central".into()),
            delivery_address: Some("Quartier Commerce".into()),
            delivery_lat: Some(7.69),
            delivery_lng: Some(-5.03),
            estimated_distance_m: Some(800),
            delivery_fee: 35000,
            items_summary: "Garba x1, Alloco x1".into(),
            payment_type: "cod".into(),
            order_total: 300000,
            created_at: Utc::now(),
        }
    }

    #[test]
    fn test_build_sms_mission_text_contains_merchant() {
        let mission = sample_mission();
        let sms = build_sms_mission_text(&mission);
        assert!(sms.contains("Maman Adjoua"));
    }

    #[test]
    fn test_build_sms_mission_text_contains_address() {
        let mission = sample_mission();
        let sms = build_sms_mission_text(&mission);
        assert!(sms.contains("Quartier Commerce"));
    }

    #[test]
    fn test_build_sms_mission_text_contains_payment_info() {
        let mission = sample_mission();
        let sms = build_sms_mission_text(&mission);
        assert!(sms.contains("COD"));
        assert!(sms.contains("3000F")); // 300000 centimes = 3000 FCFA
    }

    #[test]
    fn test_build_sms_mission_text_contains_deep_link() {
        let mission = sample_mission();
        let sms = build_sms_mission_text(&mission);
        assert!(sms.contains("mefali://delivery/mission?data="));
    }

    #[test]
    fn test_build_sms_mission_text_deep_link_decodable() {
        let mission = sample_mission();
        let sms = build_sms_mission_text(&mission);

        // Extract deep link from SMS text
        let link_start = sms.find("mefali://delivery/mission?data=").unwrap();
        let data_start = link_start + "mefali://delivery/mission?data=".len();
        let encoded = &sms[data_start..];

        // Decode and verify JSON roundtrip
        let decoded_json = deep_link::decode_deep_link(encoded).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&decoded_json).unwrap();
        assert_eq!(parsed["merchant_name"], "Maman Adjoua");
        assert_eq!(parsed["delivery_address"], "Quartier Commerce");
        assert_eq!(parsed["payment_type"], "cod");
        assert_eq!(parsed["order_total"], 300000);
    }

    #[test]
    fn test_build_sms_mission_text_mobile_money() {
        let mut mission = sample_mission();
        mission.payment_type = "mobile_money".into();
        let sms = build_sms_mission_text(&mission);
        assert!(sms.contains("MM"));
    }

    #[test]
    fn test_build_sms_mission_text_starts_with_commande() {
        let mission = sample_mission();
        let sms = build_sms_mission_text(&mission);
        assert!(sms.starts_with("Commande #"));
    }

    #[test]
    fn test_build_sms_mission_text_truncates_long_names() {
        let mut mission = sample_mission();
        mission.merchant_name = "Restaurant du Grand Marche Central de Bouake".into();
        mission.delivery_address = Some("Quartier Belleville Residence Les Palmiers Bloc A".into());
        let sms = build_sms_mission_text(&mission);
        // Merchant truncated to 20 chars, address to 25 chars
        assert!(!sms.contains("Central de Bouake"));
        assert!(!sms.contains("Palmiers Bloc A"));
        // Deep link still intact
        assert!(sms.contains("mefali://delivery/mission?data="));
    }

    #[test]
    fn test_build_sms_mission_text_missing_address_fallback() {
        let mut mission = sample_mission();
        mission.delivery_address = None;
        let sms = build_sms_mission_text(&mission);
        assert!(sms.contains("Adresse a confirmer"));
    }

    #[test]
    fn test_calculate_eta_seconds_known_distance() {
        // ~1 km distance (Bouake center to nearby point)
        let eta = calculate_eta_seconds(7.6900, -5.0300, 7.6990, -5.0300);
        // 1 km at 25 km/h = 144 seconds
        assert!(eta > 100 && eta < 200, "ETA {eta}s should be ~144s for ~1km");
    }

    #[test]
    fn test_calculate_eta_seconds_same_point() {
        let eta = calculate_eta_seconds(7.69, -5.03, 7.69, -5.03);
        assert_eq!(eta, 0, "ETA should be 0 for same point");
    }

    #[test]
    fn test_calculate_eta_seconds_short_distance() {
        // ~100m distance
        let eta = calculate_eta_seconds(7.6900, -5.0300, 7.6909, -5.0300);
        // 100m at 25 km/h ≈ 14.4s
        assert!(eta > 10 && eta < 25, "ETA {eta}s should be ~14s for ~100m");
    }

    #[test]
    fn test_calculate_eta_seconds_830m_approx_2min() {
        // ~830m = approx 2 min at 25 km/h (ETA notification threshold)
        let eta = calculate_eta_seconds(7.6900, -5.0300, 7.6975, -5.0300);
        // 830m at 25 km/h ≈ 120s
        assert!(eta > 80 && eta < 160, "ETA {eta}s should be ~120s for ~830m");
    }

    // --- Story 5.6: Delivery confirmation tests ---

    #[test]
    fn test_haversine_distance_same_point() {
        let d = haversine_distance_m(7.69, -5.03, 7.69, -5.03);
        assert!(d < 1.0, "Same point distance should be ~0m, got {d}m");
    }

    #[test]
    fn test_haversine_distance_within_200m() {
        // ~100m apart (driver close to delivery address)
        let d = haversine_distance_m(7.6900, -5.0300, 7.6909, -5.0300);
        assert!(d < 200.0, "~100m distance should be within 200m, got {d}m");
        assert!(d > 50.0, "Should be roughly 100m, got {d}m");
    }

    #[test]
    fn test_haversine_distance_beyond_200m() {
        // ~500m apart (driver too far)
        let d = haversine_distance_m(7.6900, -5.0300, 7.6945, -5.0300);
        assert!(d > 200.0, "~500m distance should exceed 200m, got {d}m");
    }

    #[test]
    fn test_confirm_delivery_response_serde() {
        let resp = ConfirmDeliveryResponse {
            delivery_id: uuid::Uuid::new_v4(),
            order_id: uuid::Uuid::new_v4(),
            status: super::super::model::DeliveryStatus::Delivered,
            driver_earnings_fcfa: 35000,
            confirmed_at: Utc::now(),
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("35000"));
        assert!(json.contains("delivered"));
    }
}
