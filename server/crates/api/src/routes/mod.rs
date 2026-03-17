pub mod auth;
pub mod health;
pub mod users;

use actix_web::web;

/// Configure all API routes under `/api/v1/`
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/v1")
            .route("/health", web::get().to(health::health_check))
            // Public auth routes — no JWT required
            .service(
                web::scope("/auth")
                    .route("/request-otp", web::post().to(auth::request_otp))
                    .route("/login", web::post().to(auth::login))
                    .route("/verify-otp", web::post().to(auth::verify_otp))
                    .route("/refresh", web::post().to(auth::refresh))
                    .route("/logout", web::post().to(auth::logout)),
            )
            // Protected routes — JWT required via AuthenticatedUser extractor
            .service(web::scope("/users").route("/me", web::get().to(users::me))),
    );
}
