use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{CreateMerchantPayload, Merchant};

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
