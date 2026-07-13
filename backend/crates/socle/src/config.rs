//! Configuration d'environnement (data-model.md §4, FR-017).
//!
//! Chargée depuis les variables d'environnement (`.env` sur le VPS, hors Git ;
//! `infra/.env.example` documente le contrat). Aucun paramètre MÉTIER ici : ceux-là
//! iront en configuration de zone dès le cycle ZON (constitution I).

use serde::Deserialize;

/// Environnement d'exécution du backend.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AppEnv {
    /// Développement local (Swagger UI exposée).
    #[default]
    Dev,
    /// Production (Swagger UI absente — constitution VIII).
    Production,
}

impl AppEnv {
    /// `true` en production — protège les surfaces réservées au dev.
    pub fn is_production(self) -> bool {
        matches!(self, AppEnv::Production)
    }
}

/// Contrat du `.env` consommé par le backend.
#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    /// Postgres — seule vérité durable.
    pub database_url: String,
    /// Redis — éphémère uniquement.
    pub redis_url: String,
    /// Garage (API S3) — endpoint.
    pub s3_endpoint: String,
    /// Garage — clé d'accès dédiée au backend.
    pub s3_access_key: String,
    /// Garage — secret dédié au backend.
    pub s3_secret_key: String,
    /// Garage — bucket applicatif.
    pub s3_bucket: String,
    /// OSRM — service de routage (consommé par les cycles suivants).
    pub osrm_url: String,
    /// Sentry — vide en dev (désactivé).
    #[serde(default)]
    pub sentry_dsn: Option<String>,
    /// `dev` (défaut) ou `production`.
    #[serde(default)]
    pub app_env: AppEnv,
}

impl Config {
    /// Charge la configuration depuis l'environnement du processus.
    ///
    /// Toutes les variables non optionnelles doivent être présentes, sinon une
    /// erreur explicite est renvoyée au démarrage.
    pub fn from_env() -> Result<Self, config::ConfigError> {
        config::Config::builder()
            .add_source(config::Environment::default())
            .build()?
            .try_deserialize()
    }
}
