use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Delivery entity matching the `deliveries` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Delivery {
    pub id: Id,
    pub order_id: Id,
    pub driver_id: Id,
    pub status: DeliveryStatus,
    pub refusal_reason: Option<String>,
    pub current_lat: Option<f64>,
    pub current_lng: Option<f64>,
    pub picked_up_at: Option<Timestamp>,
    pub delivered_at: Option<Timestamp>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Delivery status matching PostgreSQL `delivery_status` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "delivery_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DeliveryStatus {
    Pending,
    Assigned,
    PickedUp,
    InTransit,
    Delivered,
    Failed,
    Refused,
    ClientAbsent,
}

impl std::fmt::Display for DeliveryStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DeliveryStatus::Pending => write!(f, "pending"),
            DeliveryStatus::Assigned => write!(f, "assigned"),
            DeliveryStatus::PickedUp => write!(f, "picked_up"),
            DeliveryStatus::InTransit => write!(f, "in_transit"),
            DeliveryStatus::Delivered => write!(f, "delivered"),
            DeliveryStatus::Failed => write!(f, "failed"),
            DeliveryStatus::Refused => write!(f, "refused"),
            DeliveryStatus::ClientAbsent => write!(f, "client_absent"),
        }
    }
}

/// Reason for refusing a delivery mission.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum DeliveryRefusalReason {
    TooFar,
    NotEnoughTime,
    WrongDirection,
    VehicleIssue,
    Timeout,
    Other,
}

impl std::fmt::Display for DeliveryRefusalReason {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DeliveryRefusalReason::TooFar => write!(f, "too_far"),
            DeliveryRefusalReason::NotEnoughTime => write!(f, "not_enough_time"),
            DeliveryRefusalReason::WrongDirection => write!(f, "wrong_direction"),
            DeliveryRefusalReason::VehicleIssue => write!(f, "vehicle_issue"),
            DeliveryRefusalReason::Timeout => write!(f, "timeout"),
            DeliveryRefusalReason::Other => write!(f, "other"),
        }
    }
}

/// Enriched delivery with order details for mission card display.
#[derive(Debug, Clone, Serialize)]
pub struct DeliveryMission {
    pub delivery_id: Id,
    pub order_id: Id,
    pub merchant_name: String,
    pub merchant_address: Option<String>,
    pub delivery_address: Option<String>,
    pub delivery_lat: Option<f64>,
    pub delivery_lng: Option<f64>,
    pub estimated_distance_m: Option<i64>,
    pub delivery_fee: i64,
    pub items_summary: String,
    pub payment_type: String,
    pub order_total: i64,
    pub created_at: Timestamp,
}

/// Response returned after confirming a delivery or resolving client absent.
#[derive(Debug, Clone, Serialize)]
pub struct ConfirmDeliveryResponse {
    pub delivery_id: Id,
    pub order_id: Id,
    pub status: DeliveryStatus,
    pub driver_earnings_fcfa: i64,
    pub confirmed_at: Timestamp,
}

/// Resolution for client absent protocol.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum AbsentResolution {
    ReturnedToRestaurant,
    ReturnedToBase,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_delivery_status_display() {
        assert_eq!(DeliveryStatus::Pending.to_string(), "pending");
        assert_eq!(DeliveryStatus::Assigned.to_string(), "assigned");
        assert_eq!(DeliveryStatus::PickedUp.to_string(), "picked_up");
        assert_eq!(DeliveryStatus::InTransit.to_string(), "in_transit");
        assert_eq!(DeliveryStatus::Delivered.to_string(), "delivered");
        assert_eq!(DeliveryStatus::Failed.to_string(), "failed");
        assert_eq!(DeliveryStatus::Refused.to_string(), "refused");
        assert_eq!(DeliveryStatus::ClientAbsent.to_string(), "client_absent");
    }

    #[test]
    fn test_delivery_status_serde() {
        let json = serde_json::to_string(&DeliveryStatus::Pending).unwrap();
        assert_eq!(json, "\"pending\"");
        let back: DeliveryStatus = serde_json::from_str("\"picked_up\"").unwrap();
        assert_eq!(back, DeliveryStatus::PickedUp);
        let back2: DeliveryStatus = serde_json::from_str("\"client_absent\"").unwrap();
        assert_eq!(back2, DeliveryStatus::ClientAbsent);
        let back3: DeliveryStatus = serde_json::from_str("\"refused\"").unwrap();
        assert_eq!(back3, DeliveryStatus::Refused);
    }

    #[test]
    fn test_refusal_reason_serde() {
        let json = serde_json::to_string(&DeliveryRefusalReason::TooFar).unwrap();
        assert_eq!(json, "\"too_far\"");
        let back: DeliveryRefusalReason = serde_json::from_str("\"timeout\"").unwrap();
        assert_eq!(back, DeliveryRefusalReason::Timeout);
        let back2: DeliveryRefusalReason = serde_json::from_str("\"vehicle_issue\"").unwrap();
        assert_eq!(back2, DeliveryRefusalReason::VehicleIssue);
    }

    #[test]
    fn test_refusal_reason_display() {
        assert_eq!(DeliveryRefusalReason::TooFar.to_string(), "too_far");
        assert_eq!(DeliveryRefusalReason::NotEnoughTime.to_string(), "not_enough_time");
        assert_eq!(DeliveryRefusalReason::WrongDirection.to_string(), "wrong_direction");
        assert_eq!(DeliveryRefusalReason::VehicleIssue.to_string(), "vehicle_issue");
        assert_eq!(DeliveryRefusalReason::Timeout.to_string(), "timeout");
        assert_eq!(DeliveryRefusalReason::Other.to_string(), "other");
    }

    #[test]
    fn test_delivery_mission_serde() {
        let mission = DeliveryMission {
            delivery_id: uuid::Uuid::new_v4(),
            order_id: uuid::Uuid::new_v4(),
            merchant_name: "Maman Adjoua".into(),
            merchant_address: Some("Marche central".into()),
            delivery_address: Some("Quartier Commerce".into()),
            delivery_lat: Some(7.69),
            delivery_lng: Some(-5.03),
            estimated_distance_m: Some(800),
            delivery_fee: 50000,
            items_summary: "Garba x1, Alloco x1".into(),
            payment_type: "cod".into(),
            order_total: 300000,
            created_at: chrono::Utc::now(),
        };
        let json = serde_json::to_string(&mission).unwrap();
        assert!(json.contains("Maman Adjoua"));
        assert!(json.contains("50000"));
    }

    #[test]
    fn test_absent_resolution_serde() {
        let json = serde_json::to_string(&AbsentResolution::ReturnedToRestaurant).unwrap();
        assert_eq!(json, "\"returned_to_restaurant\"");
        let json2 = serde_json::to_string(&AbsentResolution::ReturnedToBase).unwrap();
        assert_eq!(json2, "\"returned_to_base\"");
        let back: AbsentResolution = serde_json::from_str("\"returned_to_base\"").unwrap();
        assert_eq!(back, AbsentResolution::ReturnedToBase);
        let back2: AbsentResolution = serde_json::from_str("\"returned_to_restaurant\"").unwrap();
        assert_eq!(back2, AbsentResolution::ReturnedToRestaurant);
    }
}
