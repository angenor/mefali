pub mod auth;
pub mod health;
pub mod users;

use actix_web::web;

/// Configure all API routes under `/api/v1/`
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api/v1")
            .route("/health", web::get().to(health::health_check))
            // Auth routes — no JWT middleware; logout uses refresh token as credential
            .service(
                web::scope("/auth")
                    .route("/request-otp", web::post().to(auth::request_otp))
                    .route("/login", web::post().to(auth::login))
                    .route("/verify-otp", web::post().to(auth::verify_otp))
                    .route("/refresh", web::post().to(auth::refresh))
                    .route("/logout", web::post().to(auth::logout)),
            )
            // Protected routes — JWT required via AuthenticatedUser extractor
            .service(
                web::scope("/users")
                    .route("/me", web::get().to(users::me))
                    .route("/me", web::put().to(users::update_profile))
                    .route(
                        "/me/change-phone/request",
                        web::post().to(users::change_phone_request),
                    )
                    .route(
                        "/me/change-phone/verify",
                        web::post().to(users::change_phone_verify),
                    ),
            ),
    );
}
