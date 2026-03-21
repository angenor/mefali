use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{AdminAuditLog, AdminUserDetail, AdminUserListItem, User, UserRole, UserStatus};

/// Find a user by ID.
pub async fn find_by_id(pool: &PgPool, id: Id) -> Result<Option<User>, AppError> {
    sqlx::query_as::<_, User>(
        "SELECT id, phone, name, role, status, city_id, fcm_token, created_at, updated_at \
         FROM users WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find user: {}", e)))
}

/// Find a user by phone number.
pub async fn find_by_phone(pool: &PgPool, phone: &str) -> Result<Option<User>, AppError> {
    sqlx::query_as::<_, User>(
        "SELECT id, phone, name, role, status, city_id, fcm_token, created_at, updated_at \
         FROM users WHERE phone = $1",
    )
    .bind(phone)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find user: {}", e)))
}

/// Update a user's name.
pub async fn update_name(pool: &PgPool, user_id: Id, name: &str) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "UPDATE users SET name = $2, updated_at = now() \
         WHERE id = $1 \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(user_id)
    .bind(name)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update user name: {}", e)))
}

/// Update a user's phone number.
pub async fn update_phone(pool: &PgPool, user_id: Id, new_phone: &str) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "UPDATE users SET phone = $2, updated_at = now() \
         WHERE id = $1 \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(user_id)
    .bind(new_phone)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update user phone: {}", e)))
}

/// Update a user's status.
pub async fn update_status(
    pool: &PgPool,
    user_id: Id,
    new_status: UserStatus,
) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "UPDATE users SET status = $2, updated_at = now() \
         WHERE id = $1 \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(user_id)
    .bind(new_status)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to update user status: {}", e)))
}

/// Update a user's FCM token.
pub async fn update_fcm_token(
    pool: &PgPool,
    user_id: Id,
    token: Option<&str>,
) -> Result<(), AppError> {
    sqlx::query("UPDATE users SET fcm_token = $2, updated_at = now() WHERE id = $1")
        .bind(user_id)
        .bind(token)
        .execute(pool)
        .await
        .map_err(|e| AppError::DatabaseError(format!("Failed to update FCM token: {e}")))?;
    Ok(())
}

/// Create a new user with the given role, status, and referral code.
pub async fn create_user(
    pool: &PgPool,
    phone: &str,
    name: Option<&str>,
    role: UserRole,
    status: UserStatus,
    referral_code: &str,
) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "INSERT INTO users (phone, name, role, status, referral_code) \
         VALUES ($1, $2, $3, $4, $5) \
         ON CONFLICT (phone) DO UPDATE SET updated_at = now() \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(phone)
    .bind(name)
    .bind(role)
    .bind(status)
    .bind(referral_code)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create user: {}", e)))
}

/// Get a user's referral code by user ID.
pub async fn get_referral_code(pool: &PgPool, user_id: Id) -> Result<String, AppError> {
    sqlx::query_scalar::<_, String>(
        "SELECT referral_code FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to get referral code: {}", e)))
}

/// Find a user ID by referral code (for referral attribution).
pub async fn find_id_by_referral_code(
    pool: &PgPool,
    code: &str,
) -> Result<Option<Id>, AppError> {
    sqlx::query_scalar::<_, Id>(
        "SELECT id FROM users WHERE referral_code = $1",
    )
    .bind(code)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find user by referral code: {}", e)))
}

// --- Admin account management queries ---

/// List users with pagination, optional role/status filters, and search.
pub async fn find_all_paginated(
    pool: &PgPool,
    role_filter: Option<&str>,
    status_filter: Option<&str>,
    search: Option<&str>,
    limit: i64,
    offset: i64,
) -> Result<Vec<AdminUserListItem>, AppError> {
    sqlx::query_as::<_, AdminUserListItem>(
        "SELECT u.id, u.phone, u.name, u.role, u.status, \
                c.city_name, u.created_at \
         FROM users u \
         LEFT JOIN city_config c ON u.city_id = c.id \
         WHERE ($1::user_role IS NULL OR u.role = $1::user_role) \
           AND ($2::user_status IS NULL OR u.status = $2::user_status) \
           AND ($3::TEXT IS NULL OR u.name ILIKE '%' || $3 || '%' OR u.phone ILIKE '%' || $3 || '%') \
         ORDER BY u.created_at DESC \
         LIMIT $4 OFFSET $5",
    )
    .bind(role_filter)
    .bind(status_filter)
    .bind(search)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to list users: {}", e)))
}

/// Count users matching filters (for pagination meta).
pub async fn count_all_filtered(
    pool: &PgPool,
    role_filter: Option<&str>,
    status_filter: Option<&str>,
    search: Option<&str>,
) -> Result<i64, AppError> {
    let count: (i64,) = sqlx::query_as(
        "SELECT COUNT(*)::BIGINT \
         FROM users u \
         WHERE ($1::user_role IS NULL OR u.role = $1::user_role) \
           AND ($2::user_status IS NULL OR u.status = $2::user_status) \
           AND ($3::TEXT IS NULL OR u.name ILIKE '%' || $3 || '%' OR u.phone ILIKE '%' || $3 || '%')",
    )
    .bind(role_filter)
    .bind(status_filter)
    .bind(search)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to count users: {}", e)))?;

    Ok(count.0)
}

/// Get detailed user info with aggregated stats for admin view.
pub async fn find_detail_by_id(pool: &PgPool, user_id: Id) -> Result<Option<AdminUserDetail>, AppError> {
    sqlx::query_as::<_, AdminUserDetail>(
        "SELECT u.id, u.phone, u.name, u.role, u.status, \
                c.city_name, u.referral_code, u.created_at, u.updated_at, \
                COALESCE(( \
                    SELECT COUNT(*)::BIGINT FROM orders \
                    WHERE customer_id = u.id \
                       OR merchant_id = (SELECT id FROM merchants WHERE user_id = u.id LIMIT 1) \
                ), 0) AS total_orders, \
                CASE WHEN COALESCE(( \
                    SELECT COUNT(*)::BIGINT FROM orders \
                    WHERE customer_id = u.id \
                       OR merchant_id = (SELECT id FROM merchants WHERE user_id = u.id LIMIT 1) \
                ), 0) = 0 THEN 0.0 \
                ELSE ( \
                    COALESCE(( \
                        SELECT COUNT(*)::BIGINT FROM orders \
                        WHERE (customer_id = u.id \
                           OR merchant_id = (SELECT id FROM merchants WHERE user_id = u.id LIMIT 1)) \
                          AND status = 'delivered' \
                    ), 0)::FLOAT8 \
                    / COALESCE(( \
                        SELECT COUNT(*)::BIGINT FROM orders \
                        WHERE customer_id = u.id \
                           OR merchant_id = (SELECT id FROM merchants WHERE user_id = u.id LIMIT 1) \
                    ), 1)::FLOAT8 * 100.0 \
                ) END AS completion_rate, \
                COALESCE(( \
                    SELECT COUNT(*)::BIGINT FROM disputes WHERE reporter_id = u.id \
                ), 0) AS disputes_filed, \
                COALESCE(( \
                    SELECT AVG(score)::FLOAT8 FROM ratings WHERE rated_id = u.id \
                ), 0.0) AS avg_rating \
         FROM users u \
         LEFT JOIN city_config c ON u.city_id = c.id \
         WHERE u.id = $1",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to find user detail: {}", e)))
}

/// Insert an admin audit log entry.
pub async fn insert_audit_log(
    pool: &PgPool,
    admin_id: Id,
    target_user_id: Id,
    action: &str,
    old_status: Option<UserStatus>,
    new_status: Option<UserStatus>,
    reason: Option<&str>,
) -> Result<AdminAuditLog, AppError> {
    sqlx::query_as::<_, AdminAuditLog>(
        "INSERT INTO admin_audit_logs (admin_id, target_user_id, action, old_status, new_status, reason) \
         VALUES ($1, $2, $3, $4, $5, $6) \
         RETURNING id, admin_id, target_user_id, action, old_status, new_status, reason, created_at",
    )
    .bind(admin_id)
    .bind(target_user_id)
    .bind(action)
    .bind(old_status)
    .bind(new_status)
    .bind(reason)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to insert audit log: {}", e)))
}

/// Set the referred_by field for a user (referral attribution).
pub async fn set_referred_by(
    pool: &PgPool,
    user_id: Id,
    referrer_id: Id,
) -> Result<(), AppError> {
    sqlx::query(
        "UPDATE users SET referred_by = $2 WHERE id = $1 AND referred_by IS NULL",
    )
    .bind(user_id)
    .bind(referrer_id)
    .execute(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to set referred_by: {}", e)))?;
    Ok(())
}
