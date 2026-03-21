use common::types::{Id, Timestamp};
use serde::{Deserialize, Serialize};

/// City configuration matching the `city_config` table schema.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CityConfig {
    pub id: Id,
    pub city_name: String,
    pub delivery_multiplier: f64,
    pub zones_geojson: Option<serde_json::Value>,
    pub is_active: bool,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

/// Request payload to create a new city configuration.
#[derive(Debug, Deserialize)]
pub struct CreateCityConfigRequest {
    pub city_name: String,
    pub delivery_multiplier: Option<f64>,
    pub zones_geojson: Option<serde_json::Value>,
    pub is_active: Option<bool>,
}

/// Request payload to update an existing city configuration.
#[derive(Debug, Deserialize)]
pub struct UpdateCityConfigRequest {
    pub city_name: Option<String>,
    pub delivery_multiplier: Option<f64>,
    pub zones_geojson: Option<serde_json::Value>,
    pub is_active: Option<bool>,
}

/// Request payload to toggle city active status.
#[derive(Debug, Deserialize)]
pub struct ToggleActiveRequest {
    pub is_active: bool,
}
