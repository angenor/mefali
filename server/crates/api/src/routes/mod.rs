pub mod health;

use actix_web::web;

/// Configure all API routes under `/api/v1/`
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(web::scope("/api/v1").route("/health", web::get().to(health::health_check)));
}
