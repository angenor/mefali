use common::error::AppError;
use common::types::Id;
use notification::deep_link;
use notification::fcm::{FcmClient, PushNotification};
use notification::sms::SmsRouter;
use sqlx::PgPool;
use tracing::{info, warn};

use super::model::DeliveryMission;
use super::repository;
use crate::merchants;
use crate::orders;

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
}
