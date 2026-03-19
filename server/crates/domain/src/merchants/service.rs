use chrono::Datelike;
use common::config::AppConfig;
use common::error::AppError;
use common::types::Id;
use notification::sms::SmsProvider;
use redis::aio::ConnectionManager;
use serde::Serialize;
use sqlx::PgPool;
use tracing::info;

use super::business_hours;
use super::model::{CreateMerchantPayload, InitiateOnboardingPayload, Merchant, MerchantStatus, MerchantSummary, OnboardingStatus, ProductSummary};
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

/// Change the availability status of the current merchant.
/// Validates the transition and resets no_response counter when reactivating from auto_paused.
pub async fn change_status(
    pool: &PgPool,
    user_id: Id,
    new_status: MerchantStatus,
) -> Result<Merchant, AppError> {
    let merchant = repository::find_by_user_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    if !merchant.status.can_transition_to(&new_status) {
        return Err(AppError::BadRequest(format!(
            "Transition de statut invalide: {} → {}",
            merchant.status, new_status
        )));
    }

    // If reactivating from auto_paused, reset the no-response counter
    if merchant.status == MerchantStatus::AutoPaused && new_status == MerchantStatus::Open {
        repository::reset_no_response(pool, merchant.id).await?;
    }

    repository::update_status(pool, merchant.id, &new_status).await
}

/// Check if a merchant should be auto-paused (>= 3 consecutive no-responses).
/// Returns true if auto-pause was triggered.
pub async fn check_auto_pause(pool: &PgPool, merchant_id: Id) -> Result<bool, AppError> {
    let merchant = repository::find_by_id(pool, merchant_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;

    if merchant.consecutive_no_response >= 3 && merchant.status != MerchantStatus::AutoPaused {
        repository::update_status(pool, merchant_id, &MerchantStatus::AutoPaused).await?;
        info!(
            merchant_id = merchant_id.to_string(),
            no_response_count = merchant.consecutive_no_response,
            "Merchant auto-paused after consecutive no-responses"
        );
        return Ok(true);
    }

    Ok(false)
}

/// Get the current merchant for the authenticated user.
pub async fn get_current_merchant(pool: &PgPool, user_id: Id) -> Result<Merchant, AppError> {
    repository::find_by_user_id(pool, user_id)
        .await?
        .ok_or_else(|| AppError::NotFound("Merchant not found".into()))
}

// ---- Restaurant discovery for B2C customers (Story 4.1) ----

/// Paginated result for customer merchant discovery.
#[derive(Debug, Serialize)]
pub struct MerchantListResult {
    pub merchants: Vec<MerchantSummary>,
    pub total: i64,
    pub page: u32,
    pub per_page: u32,
}

/// List fully onboarded merchants for B2C customer discovery.
/// Only merchants with onboarding_step = 5 are returned.
/// Ordered by availability status (open first) then name.
pub async fn list_active_merchants(
    pool: &PgPool,
    category: Option<&str>,
    page: u32,
    per_page: u32,
) -> Result<MerchantListResult, AppError> {
    let page = page.max(1);
    let per_page = per_page.clamp(1, 100);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;

    let merchants = repository::find_active_for_discovery(pool, category, limit, offset).await?;
    let total = repository::count_active_for_discovery(pool, category).await?;

    Ok(MerchantListResult {
        merchants,
        total,
        page,
        per_page,
    })
}

// ---- B2C product catalogue (Story 4.2) ----

/// Paginated result for merchant product catalogue.
#[derive(Debug, Serialize)]
pub struct ProductListResult {
    pub products: Vec<ProductSummary>,
    pub total: i64,
    pub page: u32,
    pub per_page: u32,
}

/// List products for a specific merchant for B2C catalogue view.
/// Only returns products from finalized merchants (onboarding_step = 5).
pub async fn list_merchant_products_public(
    pool: &PgPool,
    merchant_id: Id,
    page: u32,
    per_page: u32,
) -> Result<ProductListResult, AppError> {
    // Verify merchant exists and is finalized
    let merchant = repository::find_by_id(pool, merchant_id).await?;
    match merchant {
        None => return Err(AppError::NotFound("Merchant not found".into())),
        Some(m) if m.onboarding_step < 5 => {
            return Err(AppError::NotFound("Merchant not found".into()));
        }
        _ => {}
    }

    let page = page.max(1);
    let per_page = per_page.clamp(1, 100);
    let offset = ((page - 1) * per_page) as i64;
    let limit = per_page as i64;

    let products = repository::find_products_for_discovery(pool, merchant_id, limit, offset).await?;
    let total = repository::count_products_for_discovery(pool, merchant_id).await?;

    Ok(ProductListResult {
        products,
        total,
        page,
        per_page,
    })
}

// ---- Self-service business hours (Story 3.8) ----

/// Merchant reads their own business hours.
pub async fn get_my_hours(
    pool: &PgPool,
    user_id: Id,
) -> Result<Vec<business_hours::BusinessHours>, AppError> {
    let merchant = get_current_merchant(pool, user_id).await?;
    business_hours::find_by_merchant(pool, merchant.id).await
}

/// Merchant updates their own business hours.
pub async fn update_my_hours(
    pool: &PgPool,
    user_id: Id,
    entries: &[business_hours::SetBusinessHoursEntry],
) -> Result<Vec<business_hours::BusinessHours>, AppError> {
    let merchant = get_current_merchant(pool, user_id).await?;
    business_hours::set_hours(pool, merchant.id, entries).await
}

// ---- Exceptional closures (Story 3.8) ----

use super::exceptional_closures::{self, CreateClosurePayload, ExceptionalClosure};

/// Merchant lists their upcoming exceptional closures.
pub async fn get_my_closures(
    pool: &PgPool,
    user_id: Id,
) -> Result<Vec<ExceptionalClosure>, AppError> {
    let merchant = get_current_merchant(pool, user_id).await?;
    exceptional_closures::find_upcoming(pool, merchant.id).await
}

/// Merchant creates an exceptional closure.
pub async fn create_my_closure(
    pool: &PgPool,
    user_id: Id,
    payload: &CreateClosurePayload,
) -> Result<ExceptionalClosure, AppError> {
    let merchant = get_current_merchant(pool, user_id).await?;
    exceptional_closures::create(pool, merchant.id, payload).await
}

/// Merchant deletes an exceptional closure.
pub async fn delete_my_closure(
    pool: &PgPool,
    user_id: Id,
    closure_id: Id,
) -> Result<(), AppError> {
    let merchant = get_current_merchant(pool, user_id).await?;
    exceptional_closures::delete(pool, closure_id, merchant.id).await
}

// ---- Effective status (Story 3.8) ----

/// Pure computation of effective status — testable without database.
/// Note: Côte d'Ivoire uses GMT+0 (= UTC), so `now` should be UTC.
pub fn compute_effective_status_pure(
    merchant_status: &MerchantStatus,
    hours: &[business_hours::BusinessHours],
    is_exceptional_closure_today: bool,
    now: chrono::DateTime<chrono::Utc>,
) -> MerchantStatus {
    if is_exceptional_closure_today {
        return MerchantStatus::Closed;
    }

    if hours.is_empty() {
        return merchant_status.clone();
    }

    let weekday = now.weekday().num_days_from_monday() as i16;
    let today_hours = hours.iter().find(|h| h.day_of_week == weekday);

    match today_hours {
        None => merchant_status.clone(),
        Some(h) if h.is_closed => MerchantStatus::Closed,
        Some(h) => {
            let current_time = now.time();
            if current_time >= h.open_time && current_time < h.close_time {
                merchant_status.clone()
            } else {
                MerchantStatus::Closed
            }
        }
    }
}

/// Compute the effective status of a merchant considering business hours and exceptional closures.
/// Returns the merchant's real status if no hours are configured (AC8).
/// Returns Closed if outside hours or on an exceptional closure day.
pub async fn compute_effective_status(
    pool: &PgPool,
    merchant: &Merchant,
) -> Result<MerchantStatus, AppError> {
    let now = chrono::Utc::now();
    let today = now.date_naive();

    let is_closed_today = exceptional_closures::is_closed_on(pool, merchant.id, today).await?;
    let hours = business_hours::find_by_merchant(pool, merchant.id).await?;

    Ok(compute_effective_status_pure(&merchant.status, &hours, is_closed_today, now))
}

/// Response struct for GET /merchants/me with effective status.
#[derive(Debug, Serialize)]
pub struct MerchantWithEffectiveStatus {
    #[serde(flatten)]
    pub merchant: Merchant,
    pub effective_status: MerchantStatus,
}

/// Get current merchant with computed effective status.
pub async fn get_current_merchant_with_effective_status(
    pool: &PgPool,
    user_id: Id,
) -> Result<MerchantWithEffectiveStatus, AppError> {
    let merchant = get_current_merchant(pool, user_id).await?;
    let effective_status = compute_effective_status(pool, &merchant).await?;
    Ok(MerchantWithEffectiveStatus {
        merchant,
        effective_status,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::model::MerchantStatus;

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

    #[test]
    fn test_open_to_overwhelmed_allowed() {
        assert!(MerchantStatus::Open.can_transition_to(&MerchantStatus::Overwhelmed));
    }

    #[test]
    fn test_open_to_closed_allowed() {
        assert!(MerchantStatus::Open.can_transition_to(&MerchantStatus::Closed));
    }

    #[test]
    fn test_open_to_auto_paused_forbidden() {
        assert!(!MerchantStatus::Open.can_transition_to(&MerchantStatus::AutoPaused));
    }

    #[test]
    fn test_overwhelmed_to_open_allowed() {
        assert!(MerchantStatus::Overwhelmed.can_transition_to(&MerchantStatus::Open));
    }

    #[test]
    fn test_overwhelmed_to_closed_allowed() {
        assert!(MerchantStatus::Overwhelmed.can_transition_to(&MerchantStatus::Closed));
    }

    #[test]
    fn test_closed_to_open_allowed() {
        assert!(MerchantStatus::Closed.can_transition_to(&MerchantStatus::Open));
    }

    #[test]
    fn test_closed_to_overwhelmed_forbidden() {
        assert!(!MerchantStatus::Closed.can_transition_to(&MerchantStatus::Overwhelmed));
    }

    #[test]
    fn test_auto_paused_to_open_allowed() {
        assert!(MerchantStatus::AutoPaused.can_transition_to(&MerchantStatus::Open));
    }

    #[test]
    fn test_auto_paused_to_overwhelmed_forbidden() {
        assert!(!MerchantStatus::AutoPaused.can_transition_to(&MerchantStatus::Overwhelmed));
    }

    #[test]
    fn test_auto_paused_to_closed_forbidden() {
        assert!(!MerchantStatus::AutoPaused.can_transition_to(&MerchantStatus::Closed));
    }

    // ---- compute_effective_status_pure tests (T6.2) ----

    #[test]
    fn test_effective_status_exceptional_closure_overrides_all() {
        // AC6: Exceptional closure → Closed, even if within normal hours
        let now = chrono::DateTime::parse_from_rfc3339("2026-03-18T10:00:00Z")
            .unwrap()
            .with_timezone(&chrono::Utc);
        let status = compute_effective_status_pure(
            &MerchantStatus::Open,
            &[],
            true,
            now,
        );
        assert_eq!(status, MerchantStatus::Closed);
    }

    #[test]
    fn test_effective_status_no_hours_returns_actual() {
        // AC8: No hours configured → return actual status (no auto-closed)
        let now = chrono::DateTime::parse_from_rfc3339("2026-03-18T10:00:00Z")
            .unwrap()
            .with_timezone(&chrono::Utc);
        let status = compute_effective_status_pure(
            &MerchantStatus::Open,
            &[],
            false,
            now,
        );
        assert_eq!(status, MerchantStatus::Open);
    }

    #[test]
    fn test_effective_status_within_hours_returns_actual() {
        // AC3: Within business hours → return actual merchant status
        // 2026-03-18 = Wednesday (weekday 2, 0=Mon)
        let now = chrono::DateTime::parse_from_rfc3339("2026-03-18T10:00:00Z")
            .unwrap()
            .with_timezone(&chrono::Utc);
        let hours = vec![business_hours::BusinessHours {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            day_of_week: 2,
            open_time: chrono::NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
            close_time: chrono::NaiveTime::from_hms_opt(18, 0, 0).unwrap(),
            is_closed: false,
            created_at: now,
            updated_at: now,
        }];
        let status = compute_effective_status_pure(
            &MerchantStatus::Overwhelmed,
            &hours,
            false,
            now,
        );
        assert_eq!(status, MerchantStatus::Overwhelmed);
    }

    #[test]
    fn test_effective_status_outside_hours_returns_closed() {
        // AC3: Outside business hours → Closed
        // 2026-03-18 = Wednesday, 20:00 is after 18:00 close
        let now = chrono::DateTime::parse_from_rfc3339("2026-03-18T20:00:00Z")
            .unwrap()
            .with_timezone(&chrono::Utc);
        let hours = vec![business_hours::BusinessHours {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            day_of_week: 2,
            open_time: chrono::NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
            close_time: chrono::NaiveTime::from_hms_opt(18, 0, 0).unwrap(),
            is_closed: false,
            created_at: now,
            updated_at: now,
        }];
        let status = compute_effective_status_pure(
            &MerchantStatus::Open,
            &hours,
            false,
            now,
        );
        assert_eq!(status, MerchantStatus::Closed);
    }

    #[test]
    fn test_effective_status_day_marked_closed() {
        // Day with is_closed = true → Closed regardless of time
        let now = chrono::DateTime::parse_from_rfc3339("2026-03-18T10:00:00Z")
            .unwrap()
            .with_timezone(&chrono::Utc);
        let hours = vec![business_hours::BusinessHours {
            id: uuid::Uuid::new_v4(),
            merchant_id: uuid::Uuid::new_v4(),
            day_of_week: 2,
            open_time: chrono::NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
            close_time: chrono::NaiveTime::from_hms_opt(18, 0, 0).unwrap(),
            is_closed: true,
            created_at: now,
            updated_at: now,
        }];
        let status = compute_effective_status_pure(
            &MerchantStatus::Open,
            &hours,
            false,
            now,
        );
        assert_eq!(status, MerchantStatus::Closed);
    }
}
