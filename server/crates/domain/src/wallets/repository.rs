use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{Wallet, WalletTransaction, WalletTransactionType};

const WALLET_COLUMNS: &str = "id, user_id, balance, created_at, updated_at";
const TX_COLUMNS: &str = "id, wallet_id, amount, transaction_type, reference, description, created_at";

/// Find a wallet by user ID.
pub async fn find_wallet_by_user(pool: &PgPool, user_id: Id) -> Result<Wallet, AppError> {
    sqlx::query_as::<_, Wallet>(&format!(
        "SELECT {WALLET_COLUMNS} FROM wallets WHERE user_id = $1"
    ))
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find wallet: {e}")))?
    .ok_or_else(|| AppError::NotFound(format!("Wallet not found for user {user_id}")))
}

/// Credit a wallet atomically (balance += amount).
pub async fn credit_wallet(pool: &PgPool, wallet_id: Id, amount: i64) -> Result<Wallet, AppError> {
    sqlx::query_as::<_, Wallet>(&format!(
        "UPDATE wallets SET balance = balance + $2, updated_at = NOW()
         WHERE id = $1
         RETURNING {WALLET_COLUMNS}"
    ))
    .bind(wallet_id)
    .bind(amount)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to credit wallet: {e}")))
}

/// Record a wallet transaction for audit trail.
pub async fn create_transaction(
    pool: &PgPool,
    wallet_id: Id,
    amount: i64,
    tx_type: WalletTransactionType,
    reference: &str,
    description: Option<&str>,
) -> Result<WalletTransaction, AppError> {
    sqlx::query_as::<_, WalletTransaction>(&format!(
        "INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, reference, description)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING {TX_COLUMNS}"
    ))
    .bind(wallet_id)
    .bind(amount)
    .bind(tx_type)
    .bind(reference)
    .bind(description)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create wallet transaction: {e}")))
}
