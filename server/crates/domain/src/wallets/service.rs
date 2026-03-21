use common::error::AppError;
use common::types::Id;
use payment_provider::provider::{PaymentProvider, WithdrawalRequest};
use sqlx::PgPool;
use tracing::{error, info, warn};

use super::model::{Wallet, WalletTransaction, WalletTransactionType};
use super::repository;
use crate::deliveries::model::Delivery;
use crate::orders::model::Order;

/// Delivery commission percentage (driver keeps delivery_fee - commission).
/// TODO: make configurable per city via city_config table.
pub const DELIVERY_COMMISSION_PERCENT: i64 = 14;

/// Credit driver wallet after delivery confirmation.
/// Returns the driver earnings amount in centimes.
pub async fn credit_driver_for_delivery(
    pool: &PgPool,
    delivery: &Delivery,
    order: &Order,
) -> Result<i64, AppError> {
    let commission = order.delivery_fee * DELIVERY_COMMISSION_PERCENT / 100;
    let driver_earnings = order.delivery_fee - commission;

    let wallet = repository::find_wallet_by_user(pool, delivery.driver_id).await?;
    repository::credit_wallet(pool, wallet.id, driver_earnings).await?;
    repository::create_transaction(
        pool,
        wallet.id,
        driver_earnings,
        WalletTransactionType::Credit,
        &format!("delivery:{}", delivery.id),
        Some("Gains livraison"),
    )
    .await?;

    info!(
        driver_id = %delivery.driver_id,
        delivery_id = %delivery.id,
        earnings = driver_earnings,
        "Driver wallet credited for delivery"
    );

    Ok(driver_earnings)
}

/// Get wallet and recent transactions for a user.
pub async fn get_wallet_with_transactions(
    pool: &PgPool,
    user_id: Id,
) -> Result<(Wallet, Vec<WalletTransaction>), AppError> {
    let wallet = repository::find_wallet_by_user(pool, user_id).await?;
    let transactions = repository::get_transactions(pool, wallet.id).await?;
    Ok((wallet, transactions))
}

/// Request a withdrawal from wallet to mobile money.
/// Debit optimistic: debit first, then transfer. Re-credit on failure.
pub async fn request_withdrawal(
    pool: &PgPool,
    user_id: Id,
    amount: i64,
    phone_number: &str,
    payment_provider: &dyn PaymentProvider,
) -> Result<WalletTransaction, AppError> {
    if amount <= 0 {
        return Err(AppError::BadRequest("Le montant doit etre positif".into()));
    }

    let wallet = repository::find_wallet_by_user(pool, user_id).await?;

    let withdrawal_ref = format!("withdrawal:{}", uuid::Uuid::new_v4());

    // Atomic debit + transaction record in a single DB transaction
    let mut db_tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    let debit_result = sqlx::query(
        "UPDATE wallets SET balance = balance - $2, updated_at = NOW()
         WHERE id = $1 AND balance >= $2",
    )
    .bind(wallet.id)
    .bind(amount)
    .execute(&mut *db_tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to debit wallet: {e}")))?;

    if debit_result.rows_affected() == 0 {
        return Err(AppError::BadRequest(
            "Solde insuffisant pour ce retrait".into(),
        ));
    }

    let tx = sqlx::query_as::<_, WalletTransaction>(
        "INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, reference, description)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, wallet_id, amount, transaction_type, reference, description, created_at"
    )
    .bind(wallet.id)
    .bind(amount)
    .bind(WalletTransactionType::Withdrawal)
    .bind(&withdrawal_ref)
    .bind(Some(format!("Retrait vers {phone_number}")))
    .fetch_one(&mut *db_tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create wallet transaction: {e}")))?;

    db_tx
        .commit()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit withdrawal: {e}")))?;

    // Attempt external transfer via payment provider (outside DB transaction)
    let transfer_result = payment_provider
        .initiate_withdrawal(WithdrawalRequest {
            user_id,
            amount,
            currency: "XOF".into(),
            destination_phone: phone_number.to_string(),
        })
        .await;

    match transfer_result {
        Ok(resp) => {
            info!(
                user_id = %user_id,
                amount = amount,
                transaction_id = %resp.transaction_id,
                "Withdrawal transfer initiated successfully"
            );
        }
        Err(e) => {
            // Compensation: re-credit wallet with retry on transfer failure
            warn!(
                user_id = %user_id,
                amount = amount,
                error = %e,
                "Withdrawal transfer failed — re-crediting wallet"
            );
            let mut recredited = false;
            for attempt in 1..=3 {
                match repository::credit_wallet(pool, wallet.id, amount).await {
                    Ok(_) => {
                        info!(
                            wallet_id = %wallet.id,
                            attempt = attempt,
                            "Wallet re-credited after failed transfer"
                        );
                        recredited = true;
                        break;
                    }
                    Err(credit_err) => {
                        error!(
                            wallet_id = %wallet.id,
                            amount = amount,
                            attempt = attempt,
                            error = %credit_err,
                            "Re-credit attempt failed"
                        );
                    }
                }
            }
            if !recredited {
                error!(
                    wallet_id = %wallet.id,
                    amount = amount,
                    "CRITICAL: All 3 re-credit attempts failed — manual intervention required"
                );
            }
            return Err(AppError::ExternalServiceError(format!(
                "Echec du transfert mobile money: {e}"
            )));
        }
    }

    Ok(tx)
}

/// Admin credits a user's wallet for dispute resolution.
/// Uses WalletTransactionType::Refund to avoid reconciliation false positives.
pub async fn admin_credit_wallet(
    pool: &PgPool,
    admin_id: Id,
    target_user_id: Id,
    amount: i64,
    reason: &str,
    order_id: Option<Id>,
) -> Result<(Wallet, WalletTransaction), AppError> {
    if amount <= 0 {
        return Err(AppError::BadRequest("Le montant doit etre positif".into()));
    }
    if reason.trim().is_empty() {
        return Err(AppError::BadRequest("La raison est obligatoire".into()));
    }

    // Verify target user exists
    crate::users::repository::find_by_id(pool, target_user_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Utilisateur non trouve: {target_user_id}")))?;

    // Find or create wallet (clients may not have one)
    let wallet = repository::find_or_create_wallet(pool, target_user_id).await?;

    // Build description with optional order reference
    let description = match order_id {
        Some(oid) => format!("Credit admin ({reason}) - commande {oid}"),
        None => format!("Credit admin ({reason})"),
    };

    let reference = format!("admin_credit:{admin_id}");

    // Atomic: credit wallet + create transaction in a single DB transaction
    let mut db_tx = pool
        .begin()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    let updated_wallet = sqlx::query_as::<_, Wallet>(
        "UPDATE wallets SET balance = balance + $2, updated_at = NOW()
         WHERE id = $1
         RETURNING id, user_id, balance, created_at, updated_at",
    )
    .bind(wallet.id)
    .bind(amount)
    .fetch_one(&mut *db_tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to credit wallet: {e}")))?;

    let tx = sqlx::query_as::<_, WalletTransaction>(
        "INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, reference, description)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, wallet_id, amount, transaction_type, reference, description, created_at",
    )
    .bind(wallet.id)
    .bind(amount)
    .bind(WalletTransactionType::Refund)
    .bind(&reference)
    .bind(Some(&description))
    .fetch_one(&mut *db_tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create wallet transaction: {e}")))?;

    db_tx
        .commit()
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit admin credit: {e}")))?;

    info!(
        admin_id = %admin_id,
        target_user_id = %target_user_id,
        amount = amount,
        reason = %reason,
        "Admin credited user wallet"
    );

    Ok((updated_wallet, tx))
}

/// Credit merchant wallet after delivery confirmation (all order types).
/// Merchant receives the subtotal (product price, no delivery fee).
pub async fn credit_merchant_for_delivery(pool: &PgPool, order: &Order) -> Result<(), AppError> {
    let merchant = crate::merchants::repository::find_by_id(pool, order.merchant_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Merchant not found: {}", order.merchant_id)))?;
    let wallet = repository::find_wallet_by_user(pool, merchant.user_id).await?;
    repository::credit_wallet(pool, wallet.id, order.subtotal).await?;
    repository::create_transaction(
        pool,
        wallet.id,
        order.subtotal,
        WalletTransactionType::Credit,
        &format!("order:{}", order.id),
        Some("Paiement commande"),
    )
    .await?;

    info!(
        merchant_id = %order.merchant_id,
        order_id = %order.id,
        amount = order.subtotal,
        "Merchant wallet credited (escrow released)"
    );

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::postgres::PgPoolOptions;

    fn lazy_pool() -> PgPool {
        PgPoolOptions::new()
            .max_connections(1)
            .connect_lazy("postgres://test:test@localhost:1/test")
            .expect("connect_lazy should not fail")
    }

    #[tokio::test]
    async fn test_admin_credit_rejects_zero_amount() {
        let pool = lazy_pool();
        let result = admin_credit_wallet(
            &pool,
            uuid::Uuid::new_v4(),
            uuid::Uuid::new_v4(),
            0,
            "test reason",
            None,
        )
        .await;
        assert!(matches!(result, Err(AppError::BadRequest(ref msg)) if msg.contains("positif")));
    }

    #[tokio::test]
    async fn test_admin_credit_rejects_negative_amount() {
        let pool = lazy_pool();
        let result = admin_credit_wallet(
            &pool,
            uuid::Uuid::new_v4(),
            uuid::Uuid::new_v4(),
            -500,
            "test reason",
            None,
        )
        .await;
        assert!(matches!(result, Err(AppError::BadRequest(ref msg)) if msg.contains("positif")));
    }

    #[tokio::test]
    async fn test_admin_credit_rejects_empty_reason() {
        let pool = lazy_pool();
        let result = admin_credit_wallet(
            &pool,
            uuid::Uuid::new_v4(),
            uuid::Uuid::new_v4(),
            5000,
            "   ",
            None,
        )
        .await;
        assert!(matches!(result, Err(AppError::BadRequest(ref msg)) if msg.contains("raison")));
    }
}
