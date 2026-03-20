pub mod agents;
pub mod auth;
pub mod health;
pub mod kyc;
pub mod merchants;
pub mod orders;
pub mod products;
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
            )
            // KYC routes — Agent role required
            .service(
                web::scope("/kyc")
                    .route("/pending", web::get().to(kyc::pending_drivers))
                    .route("/{user_id}", web::get().to(kyc::kyc_summary))
                    .route("/{user_id}/documents", web::post().to(kyc::upload_document))
                    .route("/{user_id}/activate", web::post().to(kyc::activate_driver)),
            )
            // Order routes
            .service(
                web::scope("/orders")
                    .route("", web::post().to(orders::create_order))
                    .route("/me", web::get().to(orders::get_customer_orders))
                    .route("/{id}", web::get().to(orders::get_customer_order))
                    .route("/{id}/accept", web::put().to(orders::accept_order))
                    .route("/{id}/reject", web::put().to(orders::reject_order))
                    .route("/{id}/ready", web::put().to(orders::mark_ready))
                    .route("/{id}/retry-payment", web::post().to(orders::retry_payment)),
            )
            // Payment webhook — NO JWT auth (CinetPay calls directly)
            .service(
                web::scope("/payments")
                    .route("/webhook", web::post().to(orders::payment_webhook)),
            )
            // Merchant routes — mixed roles
            .service(
                web::scope("/merchants")
                    // Discovery — Client role (must be before /{id} to avoid capture)
                    .route("", web::get().to(merchants::list_merchants))
                    // Merchant self-service routes (must be before /{id} to avoid capture)
                    .route("/me", web::get().to(merchants::get_me_with_status))
                    .route("/me/status", web::put().to(merchants::update_status))
                    .route("/me/orders", web::get().to(orders::get_merchant_orders))
                    .route("/me/stats/weekly", web::get().to(orders::get_weekly_stats))
                    .route("/me/stock-alerts", web::get().to(products::list_stock_alerts))
                    .route("/me/hours", web::get().to(merchants::get_my_hours))
                    .route("/me/hours", web::put().to(merchants::update_my_hours))
                    .route("/me/closures", web::get().to(merchants::get_my_closures))
                    .route("/me/closures", web::post().to(merchants::create_my_closure))
                    .route("/me/closures/{id}", web::delete().to(merchants::delete_my_closure))
                    // Onboarding routes — Agent role required
                    .service(
                        web::scope("/onboard")
                            .route("/request-otp", web::post().to(merchants::onboard_request_otp))
                            .route("/verify-and-create", web::post().to(merchants::onboard_verify_and_create))
                            .route("/in-progress", web::get().to(merchants::in_progress)),
                    )
                    .route("/{id}/products", web::get().to(merchants::list_merchant_products))
                    .route("/{id}/products", web::post().to(merchants::add_products))
                    .route("/{id}/hours", web::put().to(merchants::set_hours))
                    .route("/{id}/finalize", web::post().to(merchants::finalize))
                    .route("/{id}/onboarding-status", web::get().to(merchants::onboarding_status)),
            )
            // Agent routes — Agent/Admin role required
            .service(
                web::scope("/agents")
                    .route("/me/stats", web::get().to(agents::get_my_stats)),
            )
            // Product catalogue routes — Merchant role required
            .service(
                web::scope("/products")
                    .route("", web::get().to(products::list_products))
                    .route("", web::post().to(products::create_product))
                    .route("/{id}", web::put().to(products::update_product))
                    .route("/{id}", web::delete().to(products::delete_product))
                    .route("/{id}/stock", web::put().to(products::update_stock))
                    .route(
                        "/{id}/decrement-stock",
                        web::post().to(products::decrement_stock),
                    ),
            )
            // Stock alerts routes — Merchant role required
            .service(
                web::scope("/stock-alerts")
                    .route(
                        "/{id}/acknowledge",
                        web::post().to(products::acknowledge_alert),
                    ),
            ),
    );
}
