use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{Wallet, WalletTransaction, WalletTransactionType};

const WALLET_COLUMNS: &str = "id, user_id, balance, created_at, updated_at";
const TX_COLUMNS: &str =
    "id, wallet_id, amount, transaction_type, reference, description, created_at";

/// Find or create a wallet for a user (atomic, race-condition safe).
/// Clients may not have a wallet created at registration — this creates one on the fly.
pub async fn find_or_create_wallet(pool: &PgPool, user_id: Id) -> Result<Wallet, AppError> {
    sqlx::query(
        "INSERT INTO wallets (id, user_id, balance)
         VALUES ($1, $2, 0)
         ON CONFLICT (user_id) DO NOTHING",
    )
    .bind(common::types::new_id())
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find_or_create wallet: {e}")))?;

    find_wallet_by_user(pool, user_id).await
}

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

/// Debit a wallet atomically (balance -= amount). Returns error if insufficient balance.
pub async fn debit_wallet(pool: &PgPool, wallet_id: Id, amount: i64) -> Result<Wallet, AppError> {
    sqlx::query_as::<_, Wallet>(&format!(
        "UPDATE wallets SET balance = balance - $2, updated_at = NOW()
         WHERE id = $1 AND balance >= $2
         RETURNING {WALLET_COLUMNS}"
    ))
    .bind(wallet_id)
    .bind(amount)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to debit wallet: {e}")))?
    .ok_or_else(|| AppError::BadRequest("Solde insuffisant pour ce retrait".into()))
}

/// Get recent wallet transactions (last 50).
pub async fn get_transactions(
    pool: &PgPool,
    wallet_id: Id,
) -> Result<Vec<WalletTransaction>, AppError> {
    sqlx::query_as::<_, WalletTransaction>(&format!(
        "SELECT {TX_COLUMNS} FROM wallet_transactions
         WHERE wallet_id = $1
         ORDER BY created_at DESC
         LIMIT 50"
    ))
    .bind(wallet_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get wallet transactions: {e}")))
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
