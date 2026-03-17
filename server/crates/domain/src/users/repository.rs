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

/// Create a new B2C client user.
pub async fn create_user(pool: &PgPool, phone: &str, name: Option<&str>) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "INSERT INTO users (phone, name, role, status) \
         VALUES ($1, $2, $3, $4) \
         ON CONFLICT (phone) DO UPDATE SET updated_at = now() \
         RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at",
    )
    .bind(phone)
    .bind(name)
    .bind(UserRole::Client)
    .bind(UserStatus::Active)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(format!("Failed to create user: {}", e)))
}
