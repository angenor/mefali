use common::error::AppError;
use common::types::{Id, Timestamp};
use sqlx::PgPool;

use super::model::RecentMerchant;

/// Raw count row from aggregation queries.
#[derive(Debug, sqlx::FromRow)]
struct CountRow {
    count: Option<i64>,
}

/// Count merchants fully onboarded (step=5) by this agent in a time range.
pub async fn count_merchants_onboarded(
    pool: &PgPool,
    agent_id: Id,
    from: Timestamp,
    to: Timestamp,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COALESCE(COUNT(*)::BIGINT, 0) as count
         FROM merchants
         WHERE created_by_agent_id = $1
           AND onboarding_step = 5
           AND created_at >= $2
           AND created_at < $3",
    )
    .bind(agent_id)
    .bind(from)
    .bind(to)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Count all merchants fully onboarded by this agent (no time filter).
pub async fn count_merchants_onboarded_total(
    pool: &PgPool,
    agent_id: Id,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COALESCE(COUNT(*)::BIGINT, 0) as count
         FROM merchants
         WHERE created_by_agent_id = $1
           AND onboarding_step = 5",
    )
    .bind(agent_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Count KYC documents verified by this agent in a time range.
pub async fn count_kyc_validated(
    pool: &PgPool,
    agent_id: Id,
    from: Timestamp,
    to: Timestamp,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COALESCE(COUNT(*)::BIGINT, 0) as count
         FROM kyc_documents
         WHERE verified_by = $1
           AND status = 'verified'
           AND updated_at >= $2
           AND updated_at < $3",
    )
    .bind(agent_id)
    .bind(from)
    .bind(to)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Count all KYC documents verified by this agent (no time filter).
pub async fn count_kyc_validated_total(
    pool: &PgPool,
    agent_id: Id,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COALESCE(COUNT(*)::BIGINT, 0) as count
         FROM kyc_documents
         WHERE verified_by = $1
           AND status = 'verified'",
    )
    .bind(agent_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Count distinct merchants onboarded by this agent that received at least one
/// delivered order in a time range.
pub async fn count_merchants_with_first_order(
    pool: &PgPool,
    agent_id: Id,
    from: Timestamp,
    to: Timestamp,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COALESCE(COUNT(DISTINCT m.id)::BIGINT, 0) as count
         FROM merchants m
         JOIN orders o ON o.merchant_id = m.id
         WHERE m.created_by_agent_id = $1
           AND o.status = 'delivered'
           AND o.created_at >= $2
           AND o.created_at < $3",
    )
    .bind(agent_id)
    .bind(from)
    .bind(to)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Count all distinct merchants onboarded by this agent that received at least
/// one delivered order (no time filter).
pub async fn count_merchants_with_first_order_total(
    pool: &PgPool,
    agent_id: Id,
) -> Result<i64, AppError> {
    let row = sqlx::query_as::<_, CountRow>(
        "SELECT COALESCE(COUNT(DISTINCT m.id)::BIGINT, 0) as count
         FROM merchants m
         JOIN orders o ON o.merchant_id = m.id
         WHERE m.created_by_agent_id = $1
           AND o.status = 'delivered'",
    )
    .bind(agent_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))?;

    Ok(row.count.unwrap_or(0))
}

/// Find the N most recently onboarded merchants by this agent, with first-order flag.
pub async fn find_recent_onboarded(
    pool: &PgPool,
    agent_id: Id,
    limit: i64,
) -> Result<Vec<RecentMerchant>, AppError> {
    sqlx::query_as::<_, RecentMerchant>(
        "SELECT m.id, m.name, m.created_at,
                EXISTS(
                    SELECT 1 FROM orders o
                    WHERE o.merchant_id = m.id AND o.status = 'delivered'
                ) as has_first_order
         FROM merchants m
         WHERE m.created_by_agent_id = $1
           AND m.onboarding_step = 5
         ORDER BY m.created_at DESC
         LIMIT $2",
    )
    .bind(agent_id)
    .bind(limit)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}
