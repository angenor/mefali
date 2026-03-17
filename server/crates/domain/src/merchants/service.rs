use common::config::AppConfig;
use common::error::AppError;
use common::types::Id;
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use sqlx::PgPool;
use tracing::info;

use super::business_hours;
use super::model::{CreateMerchantPayload, InitiateOnboardingPayload, Merchant, OnboardingStatus};
use super::repository;
use crate::products;
use crate::products::model::CreateProductPayload;
use crate::users;

/// Step 1a: Initiate merchant onboarding — validate phone, check uniqueness, send OTP.
pub async fn initiate_onboarding(
    pool: &PgPool,
    redis: &mut ConnectionManager,
    sms_provider: &dyn SmsProvider,
    config: &AppConfig,
    _agent_id: Id,
    payload: &InitiateOnboardingPayload,
) -> Result<(), AppError> {
    // Validate merchant data
    let create_payload = CreateMerchantPayload {
        name: payload.name.clone(),
        address: payload.address.clone(),
        category: payload.category.clone(),
        city_id: payload.city_id,
    };
    create_payload.validate()?;

    // Check phone uniqueness BEFORE sending OTP (race condition prevention)
    let existing = users::repository::find_by_phone(pool, &payload.phone).await?;
    if existing.is_some() {
        return Err(AppError::Conflict(
            "Phone number already in use".into(),
        ));
    }

    // Reuse existing OTP infrastructure
    users::service::request_otp(redis, sms_provider, config, &payload.phone).await?;

    info!(
        phone = payload.phone,
        merchant_name = payload.name,
        "Merchant onboarding OTP sent"
    );
    Ok(())
}

/// Step 1b: Verify OTP and create merchant user + merchant record + wallet.
pub async fn verify_and_create_merchant(
    pool: &PgPool,
    redis: &mut ConnectionManager,
    config: &AppConfig,
    agent_id: Id,
    phone: &str,
    otp_code: &str,
    payload: &CreateMerchantPayload,
) -> Result<Merchant, AppError> {
    payload.validate()?;

    // Re-check phone uniqueness (race condition between OTP send and verify)
    let existing = users::repository::find_by_phone(pool, phone).await?;
    if existing.is_some() {
        return Err(AppError::Conflict(
            "Phone number already in use".into(),
        ));
    }

    // Verify OTP
    users::otp_service::verify_otp(redis, phone, otp_code, config.otp_max_attempts).await?;

    // Create user with role=merchant, status=active
    let user = users::repository::create_user(
        pool,
        phone,
        Some(&payload.name),
        users::model::UserRole::Merchant,
        users::model::UserStatus::Active,
    )
    .await?;

    // Create merchant record linked to user (onboarding_step = 1)
    let merchant = repository::create_merchant(pool, user.id, agent_id, payload).await?;

    // Create wallet with balance = 0
    sqlx::query(
        "INSERT INTO wallets (user_id, balance) VALUES ($1, 0) ON CONFLICT (user_id) DO NOTHING",
    )
    .bind(user.id)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    info!(
        merchant_id = merchant.id.to_string(),
        user_id = user.id.to_string(),
        agent_id = agent_id.to_string(),
        "Merchant created via onboarding"
    );

    Ok(merchant)
}

/// Verify that an agent owns the merchant (created_by_agent_id matches).
async fn verify_agent_ownership(
    pool: &PgPool,
    merchant_id: Id,
    agent_id: Id,
) -> Result<Merchant, AppError> {
    let merchant = repository::find_by_id(pool, merchant_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    if merchant.created_by_agent_id != Some(agent_id) {
        return Err(AppError::Forbidden(
            "Not authorized to modify this merchant".into(),
        ));
    }

    Ok(merchant)
}

/// Step 2: Add products to a merchant during onboarding.
pub async fn add_products(
    pool: &PgPool,
    merchant_id: Id,
    agent_id: Id,
    items: &[CreateProductPayload],
) -> Result<Vec<crate::products::model::Product>, AppError> {
    verify_agent_ownership(pool, merchant_id, agent_id).await?;

    for item in items {
        item.validate()?;
    }

    let mut created = Vec::with_capacity(items.len());
    for item in items {
        let product = products::repository::create_product(pool, merchant_id, item).await?;
        created.push(product);
    }

    // Advance onboarding step to 2
    repository::update_onboarding_step(pool, merchant_id, 2).await?;

    Ok(created)
}

/// Step 3: Set business hours for a merchant during onboarding.
pub async fn set_hours(
    pool: &PgPool,
    merchant_id: Id,
    agent_id: Id,
    entries: &[business_hours::SetBusinessHoursEntry],
) -> Result<Vec<business_hours::BusinessHours>, AppError> {
    verify_agent_ownership(pool, merchant_id, agent_id).await?;

    let hours = business_hours::set_hours(pool, merchant_id, entries).await?;

    // Advance onboarding step to 4 (step 3 = hours, step 4 = payment is auto-created)
    repository::update_onboarding_step(pool, merchant_id, 4).await?;

    Ok(hours)
}

/// Step 5: Finalize onboarding — verify all steps completed.
pub async fn finalize_onboarding(
    pool: &PgPool,
    merchant_id: Id,
    agent_id: Id,
) -> Result<Merchant, AppError> {
    let merchant = verify_agent_ownership(pool, merchant_id, agent_id).await?;

    if merchant.onboarding_step < 1 {
        return Err(AppError::BadRequest(
            "Merchant info not completed (step 1)".into(),
        ));
    }

    // Steps 2-4 are optional but recommended; step 5 = finalized
    let merchant = repository::update_onboarding_step(pool, merchant_id, 5).await?;

    info!(
        merchant_id = merchant_id.to_string(),
        "Merchant onboarding finalized"
    );

    Ok(merchant)
}

/// Get onboarding status: merchant + products + hours + wallet.
pub async fn get_onboarding_status(
    pool: &PgPool,
    merchant_id: Id,
    agent_id: Id,
) -> Result<OnboardingStatus, AppError> {
    let merchant = verify_agent_ownership(pool, merchant_id, agent_id).await?;

    let prods = products::repository::find_by_merchant(pool, merchant_id).await?;
    let hours = business_hours::find_by_merchant(pool, merchant_id).await?;

    // Check if wallet exists for this merchant's user
    let wallet_exists: bool = sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM wallets WHERE user_id = $1)")
        .bind(merchant.user_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(OnboardingStatus {
        merchant,
        products: prods,
        business_hours: hours,
        wallet_created: wallet_exists,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_merchant_payload_validation() {
        let valid = CreateMerchantPayload {
            name: "Test".into(),
            address: None,
            category: None,
            city_id: None,
        };
        assert!(valid.validate().is_ok());

        let empty = CreateMerchantPayload {
            name: "".into(),
            address: None,
            category: None,
            city_id: None,
        };
        assert!(empty.validate().is_err());
    }
}
