use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{CreateMerchantPayload, Merchant, MerchantStatus, MerchantSummary};

/// Insert a new merchant record linked to a user.
pub async fn create_merchant(
    pool: &PgPool,
    user_id: Id,
    agent_id: Id,
    payload: &CreateMerchantPayload,
) -> Result<Merchant, AppError> {
    sqlx::query_as::<_, Merchant>(
        "INSERT INTO merchants (user_id, name, address, category, city_id, created_by_agent_id, onboarding_step)
         VALUES ($1, $2, $3, $4, $5, $6, 1)
         RETURNING id, user_id, name, address, availability_status, city_id,
                   consecutive_no_response, photo_url, category, onboarding_step,
                   created_by_agent_id, created_at, updated_at",
    )
    .bind(user_id)
    .bind(&payload.name)
    .bind(&payload.address)
    .bind(&payload.category)
    .bind(payload.city_id)
    .bind(agent_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find a merchant by its UUID.
pub async fn find_by_id(pool: &PgPool, id: Id) -> Result<Option<Merchant>, AppError> {
    sqlx::query_as::<_, Merchant>(
        "SELECT id, user_id, name, address, availability_status, city_id,
                consecutive_no_response, photo_url, category, onboarding_step,
                created_by_agent_id, created_at, updated_at
         FROM merchants WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find incomplete onboarding merchants created by a specific agent.
pub async fn find_by_agent_incomplete(
    pool: &PgPool,
    agent_id: Id,
) -> Result<Vec<Merchant>, AppError> {
    sqlx::query_as::<_, Merchant>(
        "SELECT id, user_id, name, address, availability_status, city_id,
                consecutive_no_response, photo_url, category, onboarding_step,
                created_by_agent_id, created_at, updated_at
         FROM merchants
         WHERE created_by_agent_id = $1 AND onboarding_step < 5
         ORDER BY created_at DESC",
    )
    .bind(agent_id)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find a merchant by the linked user ID.
pub async fn find_by_user_id(pool: &PgPool, user_id: Id) -> Result<Option<Merchant>, AppError> {
    sqlx::query_as::<_, Merchant>(
        "SELECT id, user_id, name, address, availability_status, city_id,
                consecutive_no_response, photo_url, category, onboarding_step,
                created_by_agent_id, created_at, updated_at
         FROM merchants WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Update the onboarding step for a merchant.
pub async fn update_onboarding_step(
    pool: &PgPool,
    merchant_id: Id,
    step: i32,
) -> Result<Merchant, AppError> {
    sqlx::query_as::<_, Merchant>(
        "UPDATE merchants SET onboarding_step = $1
         WHERE id = $2
         RETURNING id, user_id, name, address, availability_status, city_id,
                   consecutive_no_response, photo_url, category, onboarding_step,
                   created_by_agent_id, created_at, updated_at",
    )
    .bind(step)
    .bind(merchant_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Update the availability status for a merchant.
pub async fn update_status(
    pool: &PgPool,
    merchant_id: Id,
    new_status: &MerchantStatus,
) -> Result<Merchant, AppError> {
    sqlx::query_as::<_, Merchant>(
        "UPDATE merchants SET availability_status = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING id, user_id, name, address, availability_status, city_id,
                   consecutive_no_response, photo_url, category, onboarding_step,
                   created_by_agent_id, created_at, updated_at",
    )
    .bind(new_status)
    .bind(merchant_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Increment the consecutive_no_response counter for a merchant.
pub async fn increment_no_response<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    merchant_id: Id,
) -> Result<Merchant, AppError> {
    sqlx::query_as::<_, Merchant>(
        "UPDATE merchants SET consecutive_no_response = consecutive_no_response + 1, updated_at = NOW()
         WHERE id = $1
         RETURNING id, user_id, name, address, availability_status, city_id,
                   consecutive_no_response, photo_url, category, onboarding_step,
                   created_by_agent_id, created_at, updated_at",
    )
    .bind(merchant_id)
    .fetch_one(executor)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// List fully onboarded merchants for customer discovery, ordered by availability then name.
/// Only merchants with onboarding_step = 5 are returned.
/// avg_rating / total_ratings / delivery_fee are hardcoded for MVP (no ratings table yet).
pub async fn find_active_for_discovery(
    pool: &PgPool,
    category: Option<&str>,
    limit: i64,
    offset: i64,
) -> Result<Vec<MerchantSummary>, AppError> {
    sqlx::query_as::<_, MerchantSummary>(
        "SELECT id, name, address, availability_status, category, photo_url, city_id,
                0.0::float8 AS avg_rating, 0::bigint AS total_ratings, 50000::bigint AS delivery_fee
         FROM merchants
         WHERE onboarding_step = 5 AND ($1::text IS NULL OR category = $1)
         ORDER BY CASE availability_status
                    WHEN 'open' THEN 1
                    WHEN 'overwhelmed' THEN 2
                    WHEN 'auto_paused' THEN 3
                    WHEN 'closed' THEN 4
                  END, name
         LIMIT $2 OFFSET $3",
    )
    .bind(category)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Count fully onboarded merchants matching the optional category filter.
pub async fn count_active_for_discovery(
    pool: &PgPool,
    category: Option<&str>,
) -> Result<i64, AppError> {
    sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM merchants
         WHERE onboarding_step = 5 AND ($1::text IS NULL OR category = $1)",
    )
    .bind(category)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Reset the consecutive_no_response counter to 0 for a merchant.
pub async fn reset_no_response<'e>(
    executor: impl sqlx::PgExecutor<'e>,
    merchant_id: Id,
) -> Result<Merchant, AppError> {
    sqlx::query_as::<_, Merchant>(
        "UPDATE merchants SET consecutive_no_response = 0, updated_at = NOW()
         WHERE id = $1
         RETURNING id, user_id, name, address, availability_status, city_id,
                   consecutive_no_response, photo_url, category, onboarding_step,
                   created_by_agent_id, created_at, updated_at",
    )
    .bind(merchant_id)
    .fetch_one(executor)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}
