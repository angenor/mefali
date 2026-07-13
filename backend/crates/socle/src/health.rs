//! Type de la sonde de vie (`GET /health`) — contrat
//! `specs/001-socle-monorepo/contracts/openapi-health.yaml`.

use serde::Serialize;
use utoipa::ToSchema;

/// Réponse de la sonde de vie. Ne contient AUCUNE donnée sensible : la sonde
/// mesure la disponibilité du processus (non authentifiée, constitution VIII).
#[derive(Debug, Clone, Serialize, ToSchema)]
pub struct HealthResponse {
    /// Toujours `"ok"` quand le processus répond.
    #[schema(example = "ok")]
    pub status: String,
    /// Version du binaire (`CARGO_PKG_VERSION`).
    pub version: String,
}

impl HealthResponse {
    /// Construit la réponse « service opérationnel » pour la version courante.
    pub fn ok(version: &str) -> Self {
        Self {
            status: "ok".to_owned(),
            version: version.to_owned(),
        }
    }
}
