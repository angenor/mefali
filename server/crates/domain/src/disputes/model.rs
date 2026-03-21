use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// Dispute entity matching the `disputes` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Dispute {
    pub id: Id,
    pub order_id: Id,
    pub reporter_id: Id,
    pub dispute_type: DisputeType,
    pub status: DisputeStatus,
    pub description: Option<String>,
    pub resolution: Option<String>,
    pub resolved_by: Option<Id>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Dispute type matching PostgreSQL `dispute_type` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "dispute_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DisputeType {
    Incomplete,
    Quality,
    WrongOrder,
    Other,
}

impl std::fmt::Display for DisputeType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DisputeType::Incomplete => write!(f, "incomplete"),
            DisputeType::Quality => write!(f, "quality"),
            DisputeType::WrongOrder => write!(f, "wrong_order"),
            DisputeType::Other => write!(f, "other"),
        }
    }
}

/// Dispute status matching PostgreSQL `dispute_status` enum.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "dispute_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DisputeStatus {
    Open,
    InProgress,
    Resolved,
    Closed,
}

impl std::fmt::Display for DisputeStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DisputeStatus::Open => write!(f, "open"),
            DisputeStatus::InProgress => write!(f, "in_progress"),
            DisputeStatus::Resolved => write!(f, "resolved"),
            DisputeStatus::Closed => write!(f, "closed"),
        }
    }
}

/// Request payload for creating a dispute.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateDisputeRequest {
    pub dispute_type: DisputeType,
    pub description: Option<String>,
}

impl CreateDisputeRequest {
    const MAX_DESCRIPTION_LENGTH: usize = 500;

    pub fn validate(&self) -> Result<(), String> {
        if let Some(ref d) = self.description {
            if d.len() > Self::MAX_DESCRIPTION_LENGTH {
                return Err(format!(
                    "description must be at most {} characters",
                    Self::MAX_DESCRIPTION_LENGTH
                ));
            }
            if d.trim().is_empty() {
                return Err("description cannot be blank".into());
            }
        }
        Ok(())
    }
}

/// Response payload for dispute endpoints.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DisputeResponse {
    pub id: Id,
    pub order_id: Id,
    pub reporter_id: Id,
    pub dispute_type: DisputeType,
    pub status: DisputeStatus,
    pub description: Option<String>,
    pub resolution: Option<String>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

impl From<Dispute> for DisputeResponse {
    fn from(d: Dispute) -> Self {
        Self {
            id: d.id,
            order_id: d.order_id,
            reporter_id: d.reporter_id,
            dispute_type: d.dispute_type,
            status: d.status,
            description: d.description,
            resolution: d.resolution,
            created_at: d.created_at,
            updated_at: d.updated_at,
        }
    }
}

/// Admin dispute list item — dispute + order/reporter summary.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct AdminDisputeListItem {
    pub id: Id,
    pub order_id: Id,
    pub reporter_id: Id,
    pub dispute_type: DisputeType,
    pub status: DisputeStatus,
    pub description: Option<String>,
    pub created_at: Timestamp,
    pub reporter_name: Option<String>,
    pub reporter_phone: String,
    pub merchant_name: Option<String>,
    pub order_total: i64,
}

/// Order timeline event for dispute detail view.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrderTimelineEvent {
    pub label: String,
    pub timestamp: Option<Timestamp>,
}

/// Actor stats for dispute context (merchant or driver).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActorStats {
    pub name: Option<String>,
    pub total_orders: i64,
    pub total_disputes: i64,
}

/// Admin dispute detail — full context for resolution.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AdminDisputeDetail {
    pub dispute: DisputeResponse,
    pub timeline: Vec<OrderTimelineEvent>,
    pub merchant_stats: ActorStats,
    pub driver_stats: Option<ActorStats>,
}

/// Request payload for resolving a dispute (admin).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResolveDisputeRequest {
    pub action: ResolveAction,
    pub resolution: String,
    pub credit_amount: Option<i64>,
}

/// Resolution action type.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ResolveAction {
    Credit,
    Warn,
    Dismiss,
}

impl ResolveDisputeRequest {
    pub fn validate(&self) -> Result<(), String> {
        if self.resolution.trim().is_empty() {
            return Err("resolution is required".into());
        }
        if self.action == ResolveAction::Credit {
            match self.credit_amount {
                None => return Err("credit_amount is required when action is credit".into()),
                Some(amount) if amount <= 0 => {
                    return Err("credit_amount must be positive".into());
                }
                _ => {}
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dispute_type_serde_roundtrip() {
        let types = vec![
            (DisputeType::Incomplete, "\"incomplete\""),
            (DisputeType::Quality, "\"quality\""),
            (DisputeType::WrongOrder, "\"wrong_order\""),
            (DisputeType::Other, "\"other\""),
        ];
        for (variant, expected_json) in types {
            let json = serde_json::to_string(&variant).unwrap();
            assert_eq!(json, expected_json);
            let parsed: DisputeType = serde_json::from_str(&json).unwrap();
            assert_eq!(parsed, variant);
        }
    }

    #[test]
    fn test_dispute_status_serde_roundtrip() {
        let statuses = vec![
            (DisputeStatus::Open, "\"open\""),
            (DisputeStatus::InProgress, "\"in_progress\""),
            (DisputeStatus::Resolved, "\"resolved\""),
            (DisputeStatus::Closed, "\"closed\""),
        ];
        for (variant, expected_json) in statuses {
            let json = serde_json::to_string(&variant).unwrap();
            assert_eq!(json, expected_json);
            let parsed: DisputeStatus = serde_json::from_str(&json).unwrap();
            assert_eq!(parsed, variant);
        }
    }

    #[test]
    fn test_dispute_type_display() {
        assert_eq!(DisputeType::Incomplete.to_string(), "incomplete");
        assert_eq!(DisputeType::Quality.to_string(), "quality");
        assert_eq!(DisputeType::WrongOrder.to_string(), "wrong_order");
        assert_eq!(DisputeType::Other.to_string(), "other");
    }

    #[test]
    fn test_dispute_status_display() {
        assert_eq!(DisputeStatus::Open.to_string(), "open");
        assert_eq!(DisputeStatus::InProgress.to_string(), "in_progress");
        assert_eq!(DisputeStatus::Resolved.to_string(), "resolved");
        assert_eq!(DisputeStatus::Closed.to_string(), "closed");
    }

    #[test]
    fn test_create_dispute_request_valid() {
        let req = CreateDisputeRequest {
            dispute_type: DisputeType::Incomplete,
            description: Some("Il manque le alloco".into()),
        };
        assert!(req.validate().is_ok());
    }

    #[test]
    fn test_create_dispute_request_valid_no_description() {
        let req = CreateDisputeRequest {
            dispute_type: DisputeType::Quality,
            description: None,
        };
        assert!(req.validate().is_ok());
    }

    #[test]
    fn test_create_dispute_request_description_too_long() {
        let req = CreateDisputeRequest {
            dispute_type: DisputeType::Other,
            description: Some("x".repeat(501)),
        };
        assert!(req.validate().is_err());
        assert!(req.validate().unwrap_err().contains("500"));
    }

    #[test]
    fn test_create_dispute_request_blank_description() {
        let req = CreateDisputeRequest {
            dispute_type: DisputeType::Other,
            description: Some("   ".into()),
        };
        assert!(req.validate().is_err());
        assert!(req.validate().unwrap_err().contains("blank"));
    }

    #[test]
    fn test_create_dispute_request_serde() {
        let req = CreateDisputeRequest {
            dispute_type: DisputeType::WrongOrder,
            description: Some("Mauvais plat".into()),
        };
        let json = serde_json::to_value(&req).unwrap();
        assert_eq!(json["dispute_type"], "wrong_order");
        assert_eq!(json["description"], "Mauvais plat");
    }

    #[test]
    fn test_dispute_response_from_dispute() {
        let now = common::types::now();
        let dispute = Dispute {
            id: common::types::new_id(),
            order_id: common::types::new_id(),
            reporter_id: common::types::new_id(),
            dispute_type: DisputeType::Incomplete,
            status: DisputeStatus::Open,
            description: Some("test".into()),
            resolution: None,
            resolved_by: None,
            created_at: now,
            updated_at: now,
        };
        let response = DisputeResponse::from(dispute.clone());
        assert_eq!(response.id, dispute.id);
        assert_eq!(response.dispute_type, DisputeType::Incomplete);
        assert_eq!(response.status, DisputeStatus::Open);
    }
}
