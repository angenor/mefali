use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{User, UserRole, UserStatus};

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
