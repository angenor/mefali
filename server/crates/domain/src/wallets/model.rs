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
