use common::error::AppError;
use sqlx::PgPool;
use tracing::info;

use super::model::WalletTransactionType;
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

/// Credit merchant wallet after delivery confirmation (prepaid orders only).
/// Merchant receives the subtotal (product price, no delivery fee).
pub async fn credit_merchant_for_delivery(
    pool: &PgPool,
    order: &Order,
) -> Result<(), AppError> {
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
        Some("Paiement commande (escrow libere)"),
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
