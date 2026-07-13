//! Handler de la sonde de vie `GET /health` (non authentifiée, constitution VIII).
//! Ne touche NI Postgres NI Redis : sonde de vie, pas de readiness.

use actix_web::{get, HttpResponse, Responder};
use socle::HealthResponse;

/// Sonde de vie du service. Répond `200 {status:"ok", version}`.
#[utoipa::path(
    get,
    path = "/health",
    tag = "socle",
    responses(
        (status = 200, description = "Service opérationnel", body = HealthResponse)
    )
)]
#[get("/health")]
pub async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse::ok(env!("CARGO_PKG_VERSION")))
}
