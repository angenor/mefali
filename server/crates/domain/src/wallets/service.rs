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
const DELIVERY_COMMISSION_PERCENT: i64 = 14;

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

    // Atomic: credit + transaction record in a single DB transaction
    let mut tx = pool.begin().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    sqlx::query(
        "UPDATE wallets SET balance = balance + $2, updated_at = NOW() WHERE id = $1"
    )
    .bind(wallet.id)
    .bind(driver_earnings)
    .execute(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to credit driver wallet: {e}")))?;

    sqlx::query(
        "INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, reference, description)
         VALUES ($1, $2, $3, $4, $5)"
    )
    .bind(wallet.id)
    .bind(driver_earnings)
    .bind(WalletTransactionType::Credit)
    .bind(format!("delivery:{}", delivery.id))
    .bind(Some("Gains livraison"))
    .execute(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create driver wallet transaction: {e}")))?;

    tx.commit().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit driver credit: {e}")))?;

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
    let mut db_tx = pool.begin().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    let debit_result = sqlx::query(
        "UPDATE wallets SET balance = balance - $2, updated_at = NOW()
         WHERE id = $1 AND balance >= $2"
    )
    .bind(wallet.id)
    .bind(amount)
    .execute(&mut *db_tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to debit wallet: {e}")))?;

    if debit_result.rows_affected() == 0 {
        return Err(AppError::BadRequest("Solde insuffisant pour ce retrait".into()));
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

    db_tx.commit().await
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

/// Credit merchant wallet after delivery confirmation (all order types).
/// Merchant receives the subtotal (product price, no delivery fee).
pub async fn credit_merchant_for_delivery(
    pool: &PgPool,
    order: &Order,
) -> Result<(), AppError> {
    let merchant = crate::merchants::repository::find_by_id(pool, order.merchant_id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Merchant not found: {}", order.merchant_id)))?;
    let wallet = repository::find_wallet_by_user(pool, merchant.user_id).await?;

    // Atomic: credit + transaction record in a single DB transaction
    let mut tx = pool.begin().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to begin transaction: {e}")))?;

    sqlx::query(
        "UPDATE wallets SET balance = balance + $2, updated_at = NOW() WHERE id = $1"
    )
    .bind(wallet.id)
    .bind(order.subtotal)
    .execute(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to credit merchant wallet: {e}")))?;

    sqlx::query(
        "INSERT INTO wallet_transactions (wallet_id, amount, transaction_type, reference, description)
         VALUES ($1, $2, $3, $4, $5)"
    )
    .bind(wallet.id)
    .bind(order.subtotal)
    .bind(WalletTransactionType::Credit)
    .bind(format!("order:{}", order.id))
    .bind(Some("Paiement commande"))
    .execute(&mut *tx)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create merchant wallet transaction: {e}")))?;

    tx.commit().await
        .map_err(|e| AppError::DatabaseError(format!("Failed to commit merchant credit: {e}")))?;

    info!(
        merchant_id = %order.merchant_id,
        order_id = %order.id,
        amount = order.subtotal,
        "Merchant wallet credited (escrow released)"
    );

    Ok(())
}
