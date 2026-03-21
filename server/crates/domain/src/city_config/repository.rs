use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;

use super::model::{CityConfig, CreateCityConfigRequest, UpdateCityConfigRequest};

const COLUMNS: &str = "id, city_name, delivery_multiplier::FLOAT8 as delivery_multiplier, zones_geojson, is_active, created_at, updated_at";

/// List all city configurations ordered by city_name.
pub async fn list_all(pool: &PgPool) -> Result<Vec<CityConfig>, AppError> {
    let query = format!("SELECT {COLUMNS} FROM city_config ORDER BY city_name");
    sqlx::query_as::<_, CityConfig>(&query)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Find a city configuration by its UUID.
pub async fn find_by_id(pool: &PgPool, id: Id) -> Result<Option<CityConfig>, AppError> {
    let query = format!("SELECT {COLUMNS} FROM city_config WHERE id = $1");
    sqlx::query_as::<_, CityConfig>(&query)
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))
}

/// Create a new city configuration. Returns 409-style error on duplicate city_name.
pub async fn create(
    pool: &PgPool,
    req: &CreateCityConfigRequest,
) -> Result<CityConfig, AppError> {
    let query = format!(
        "INSERT INTO city_config (city_name, delivery_multiplier, zones_geojson, is_active)
         VALUES ($1, $2, $3, $4)
         RETURNING {COLUMNS}"
    );
    sqlx::query_as::<_, CityConfig>(&query)
        .bind(&req.city_name)
        .bind(req.delivery_multiplier.unwrap_or(1.0))
        .bind(&req.zones_geojson)
        .bind(req.is_active.unwrap_or(true))
        .fetch_one(pool)
        .await
        .map_err(|e| {
            if e.to_string().contains("city_config_city_name_key")
                || e.to_string().contains("duplicate key")
            {
                AppError::Conflict("Une ville avec ce nom existe deja".into())
            } else {
                AppError::DatabaseError(e.to_string())
            }
        })
}

/// Update an existing city configuration. All fields are optional (partial update).
/// `zones_geojson_provided` distinguishes "field absent" (false) from "field = null" (true).
pub async fn update(
    pool: &PgPool,
    id: Id,
    req: &UpdateCityConfigRequest,
    zones_geojson_provided: bool,
) -> Result<CityConfig, AppError> {
    let query = format!(
        "UPDATE city_config SET
            city_name = COALESCE($2, city_name),
            delivery_multiplier = COALESCE($3, delivery_multiplier),
            zones_geojson = CASE WHEN $4::boolean THEN $5 ELSE zones_geojson END,
            is_active = COALESCE($6, is_active)
         WHERE id = $1
         RETURNING {COLUMNS}"
    );
    sqlx::query_as::<_, CityConfig>(&query)
        .bind(id)
        .bind(&req.city_name)
        .bind(req.delivery_multiplier)
        .bind(zones_geojson_provided)
        .bind(&req.zones_geojson)
        .bind(req.is_active)
        .fetch_optional(pool)
        .await
        .map_err(|e| {
            if e.to_string().contains("city_config_city_name_key")
                || e.to_string().contains("duplicate key")
            {
                AppError::Conflict("Une ville avec ce nom existe deja".into())
            } else {
                AppError::DatabaseError(e.to_string())
            }
        })?
        .ok_or_else(|| AppError::NotFound("City config not found".into()))
}

/// Toggle the is_active flag for a city configuration.
pub async fn toggle_active(
    pool: &PgPool,
    id: Id,
    is_active: bool,
) -> Result<CityConfig, AppError> {
    let query = format!(
        "UPDATE city_config SET is_active = $2 WHERE id = $1 RETURNING {COLUMNS}"
    );
    sqlx::query_as::<_, CityConfig>(&query)
        .bind(id)
        .bind(is_active)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
        .ok_or_else(|| AppError::NotFound("City config not found".into()))
}
