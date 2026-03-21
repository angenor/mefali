use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "reconciliation_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum ReconciliationStatus {
    Ok,
    Warnings,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "discrepancy_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DiscrepancyType {
    OrphanCredit,
    OrphanWithdrawal,
    AmountMismatch,
    MissingExternalTxnId,
    UnconfirmedAggregator,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ReconciliationReport {
    pub id: Id,
    pub reconciliation_date: chrono::NaiveDate,
    pub total_credits_count: i32,
    pub total_credits_amount: i64,
    pub total_withdrawals_count: i32,
    pub total_withdrawals_amount: i64,
    pub matched_count: i32,
    pub discrepancy_count: i32,
    pub status: ReconciliationStatus,
    pub created_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ReconciliationDiscrepancy {
    pub id: Id,
    pub report_id: Id,
    pub discrepancy_type: DiscrepancyType,
    pub wallet_transaction_id: Option<Id>,
    pub internal_amount: Option<i64>,
    pub external_amount: Option<i64>,
    pub reference: Option<String>,
    pub details: Option<String>,
    pub created_at: Timestamp,
}

/// In-memory discrepancy used during reconciliation before persisting.
#[derive(Debug, Clone)]
pub struct PendingDiscrepancy {
    pub discrepancy_type: DiscrepancyType,
    pub wallet_transaction_id: Option<Id>,
    pub internal_amount: Option<i64>,
    pub external_amount: Option<i64>,
    pub reference: Option<String>,
    pub details: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_reconciliation_status_serde() {
        let json = serde_json::to_string(&ReconciliationStatus::Ok).unwrap();
        assert_eq!(json, "\"ok\"");
        let json2 = serde_json::to_string(&ReconciliationStatus::Warnings).unwrap();
        assert_eq!(json2, "\"warnings\"");
        let json3 = serde_json::to_string(&ReconciliationStatus::Critical).unwrap();
        assert_eq!(json3, "\"critical\"");
    }

    #[test]
    fn test_discrepancy_type_serde() {
        let types = vec![
            (DiscrepancyType::OrphanCredit, "\"orphan_credit\""),
            (DiscrepancyType::OrphanWithdrawal, "\"orphan_withdrawal\""),
            (DiscrepancyType::AmountMismatch, "\"amount_mismatch\""),
            (
                DiscrepancyType::MissingExternalTxnId,
                "\"missing_external_txn_id\"",
            ),
            (
                DiscrepancyType::UnconfirmedAggregator,
                "\"unconfirmed_aggregator\"",
            ),
        ];
        for (variant, expected) in types {
            let json = serde_json::to_string(&variant).unwrap();
            assert_eq!(json, expected);
            let parsed: DiscrepancyType = serde_json::from_str(&json).unwrap();
            assert_eq!(parsed, variant);
        }
    }

    #[test]
    fn test_pending_discrepancy_creation() {
        let d = PendingDiscrepancy {
            discrepancy_type: DiscrepancyType::AmountMismatch,
            wallet_transaction_id: Some(uuid::Uuid::new_v4()),
            internal_amount: Some(150000),
            external_amount: Some(140000),
            reference: Some("order:abc".into()),
            details: Some("Internal 1500 FCFA vs external 1400 FCFA".into()),
        };
        assert_eq!(d.discrepancy_type, DiscrepancyType::AmountMismatch);
        assert_eq!(d.internal_amount, Some(150000));
    }
}
