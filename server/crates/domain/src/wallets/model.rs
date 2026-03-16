use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Wallet {
    pub id: Id,
    pub user_id: Id,
    pub balance: i64,
    pub updated_at: Timestamp,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum WalletTransactionType {
    Credit,
    Debit,
    Withdrawal,
    Refund,
}
