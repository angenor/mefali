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

/// Create a new user with the given role and status.
pub async fn create_user(
    pool: &PgPool,
    phone: &str,
    name: Option<&str>,
    role: UserRole,
    status: UserStatus,
) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "INSERT INTO users (phone, name, role, status) \
         VALUES ($1, $2, $3, $4) \
         ON CONFLICT (phone) DO UPDATE SET updated_at = now() \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(phone)
    .bind(name)
    .bind(role)
    .bind(status)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create user: {}", e)))
}
