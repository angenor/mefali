pub mod auth;
pub mod health;

use actix_web::web;

/// Configure all API routes under `/api/v1/`
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/v1")
            .route("/health", web::get().to(health::health_check))
            .service(
                web::scope("/auth")
                    .route("/request-otp", web::post().to(auth::request_otp))
                    .route("/verify-otp", web::post().to(auth::verify_otp)),
            ),
    );
}
