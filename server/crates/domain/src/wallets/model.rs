use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Wallet {
    pub id: Id,
    pub user_id: Id,
    pub balance: i64,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, sqlx::Type)]
#[sqlx(type_name = "wallet_transaction_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum WalletTransactionType {
    Credit,
    Debit,
    Withdrawal,
    Refund,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct WalletTransaction {
    pub id: Id,
    pub wallet_id: Id,
    pub amount: i64,
    pub transaction_type: WalletTransactionType,
    pub reference: Option<String>,
    pub description: Option<String>,
    pub created_at: Timestamp,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wallet_transaction_type_serde() {
        let types = vec![
            (WalletTransactionType::Credit, "\"credit\""),
            (WalletTransactionType::Debit, "\"debit\""),
            (WalletTransactionType::Withdrawal, "\"withdrawal\""),
            (WalletTransactionType::Refund, "\"refund\""),
        ];
        for (variant, expected_json) in types {
            let json = serde_json::to_string(&variant).unwrap();
            assert_eq!(json, expected_json);
            let parsed: WalletTransactionType = serde_json::from_str(&json).unwrap();
            assert_eq!(parsed, variant);
        }
    }

    #[test]
    fn test_wallet_serialization() {
        let wallet = Wallet {
            id: uuid::Uuid::new_v4(),
            user_id: uuid::Uuid::new_v4(),
            balance: 280000, // 2800 FCFA
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        let json = serde_json::to_value(&wallet).unwrap();
        assert_eq!(json["balance"], 280000);
    }

    #[test]
    fn test_wallet_transaction_serialization() {
        let tx = WalletTransaction {
            id: uuid::Uuid::new_v4(),
            wallet_id: uuid::Uuid::new_v4(),
            amount: 35000,
            transaction_type: WalletTransactionType::Withdrawal,
            reference: Some("withdrawal:abc123".into()),
            description: Some("Retrait vers +2250700000000".into()),
            created_at: chrono::Utc::now(),
        };
        let json = serde_json::to_value(&tx).unwrap();
        assert_eq!(json["amount"], 35000);
        assert_eq!(json["transaction_type"], "withdrawal");
        assert_eq!(json["reference"], "withdrawal:abc123");
    }

    #[test]
    fn test_withdrawal_transaction_format() {
        let phone = "+2250700112233";
        let tx = WalletTransaction {
            id: uuid::Uuid::new_v4(),
            wallet_id: uuid::Uuid::new_v4(),
            amount: 200000, // 2000 FCFA
            transaction_type: WalletTransactionType::Withdrawal,
            reference: Some(format!("withdrawal:{}", uuid::Uuid::new_v4())),
            description: Some(format!("Retrait vers {phone}")),
            created_at: chrono::Utc::now(),
        };
        let json = serde_json::to_value(&tx).unwrap();
        assert_eq!(json["transaction_type"], "withdrawal");
        assert!(json["reference"].as_str().unwrap().starts_with("withdrawal:"));
        assert!(json["description"].as_str().unwrap().contains(phone));
        assert_eq!(json["amount"], 200000);
    }

    #[test]
    fn test_merchant_credit_transaction_format() {
        let order_id = uuid::Uuid::new_v4();
        let tx = WalletTransaction {
            id: uuid::Uuid::new_v4(),
            wallet_id: uuid::Uuid::new_v4(),
            amount: 150000, // 1500 FCFA
            transaction_type: WalletTransactionType::Credit,
            reference: Some(format!("order:{order_id}")),
            description: Some("Paiement commande".into()),
            created_at: chrono::Utc::now(),
        };
        let json = serde_json::to_value(&tx).unwrap();
        assert_eq!(json["transaction_type"], "credit");
        assert!(json["reference"].as_str().unwrap().starts_with("order:"));
        assert_eq!(json["description"], "Paiement commande");
        assert_eq!(json["amount"], 150000);
    }
}
