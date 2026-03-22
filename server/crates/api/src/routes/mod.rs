pub mod admin;
pub mod agents;
pub mod auth;
pub mod deliveries;
pub mod disputes;
pub mod drivers;
pub mod health;
pub mod kyc;
pub mod merchants;
pub mod orders;
pub mod products;
pub mod ratings;
pub mod reconciliation;
pub mod share;
pub mod sponsorships;
pub mod users;
pub mod wallets;
pub mod ws;

use actix_web::web;

/// Configure all API routes under `/api/v1/`
pub fn configure(cfg: &mut web::ServiceConfig) {
    // Public share redirect page (outside /api/v1, no auth)
    cfg.route(
        "/share/r/{merchant_id}",
        web::get().to(share::share_redirect_page),
    );

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
                    )
                    .route("/me/fcm-token", web::put().to(users::register_fcm_token))
                    .route("/me/fcm-token", web::delete().to(users::clear_fcm_token))
                    .route("/me/referral", web::get().to(users::get_referral_code)),
            )
            // Delivery routes — Driver role required (except tracking: Client role)
            .service(
                web::scope("/deliveries")
                    .route("/pending", web::get().to(deliveries::get_pending_mission))
                    .route(
                        "/{delivery_id}/accept",
                        web::post().to(deliveries::accept_mission),
                    )
                    .route(
                        "/{delivery_id}/refuse",
                        web::post().to(deliveries::refuse_mission),
                    )
                    .route(
                        "/{delivery_id}/confirm-pickup",
                        web::post().to(deliveries::confirm_pickup),
                    )
                    .route(
                        "/{delivery_id}/location",
                        web::post().to(deliveries::update_location),
                    )
                    .route(
                        "/{delivery_id}/confirm",
                        web::post().to(deliveries::confirm_delivery),
                    )
                    .route(
                        "/{delivery_id}/client-absent",
                        web::post().to(deliveries::report_client_absent),
                    )
                    .route(
                        "/{delivery_id}/resolve-absent",
                        web::post().to(deliveries::resolve_client_absent),
                    )
                    .route(
                        "/tracking/{order_id}",
                        web::get().to(deliveries::get_tracking),
                    ),
            )
            // Driver routes — Driver role required
            .service(
                web::scope("/drivers")
                    .route("/availability", web::put().to(drivers::set_availability))
                    .route("/availability", web::get().to(drivers::get_availability)),
            )
            // Sponsorship routes — Driver role required
            .service(
                web::scope("/sponsorships")
                    .route("/me", web::get().to(sponsorships::get_my_sponsorships))
                    .route("/me/sponsor", web::get().to(sponsorships::get_my_sponsor)),
            )
            // Wallet routes — Driver/Merchant role required
            .service(
                web::scope("/wallets")
                    .route("/me", web::get().to(wallets::get_wallet))
                    .route("/withdraw", web::post().to(wallets::withdraw)),
            )
            // WebSocket routes — JWT via query param
            .service(
                web::scope("/ws/deliveries")
                    .route("/{order_id}/track", web::get().to(ws::delivery_tracking_ws)),
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
                    .route("/{id}/retry-payment", web::post().to(orders::retry_payment))
                    .route("/{id}/rating", web::post().to(ratings::submit_rating))
                    .route("/{id}/rating", web::get().to(ratings::get_order_rating))
                    .route("/{id}/dispute", web::post().to(disputes::create_dispute))
                    .route("/{id}/dispute", web::get().to(disputes::get_order_dispute)),
            )
            // Payment webhook — NO JWT auth (CinetPay calls directly)
            .service(
                web::scope("/payments").route("/webhook", web::post().to(orders::payment_webhook)),
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
                    .route(
                        "/me/stock-alerts",
                        web::get().to(products::list_stock_alerts),
                    )
                    .route("/me/hours", web::get().to(merchants::get_my_hours))
                    .route("/me/hours", web::put().to(merchants::update_my_hours))
                    .route("/me/closures", web::get().to(merchants::get_my_closures))
                    .route("/me/closures", web::post().to(merchants::create_my_closure))
                    .route(
                        "/me/closures/{id}",
                        web::delete().to(merchants::delete_my_closure),
                    )
                    // Onboarding routes — Agent role required
                    .service(
                        web::scope("/onboard")
                            .route(
                                "/request-otp",
                                web::post().to(merchants::onboard_request_otp),
                            )
                            .route(
                                "/verify-and-create",
                                web::post().to(merchants::onboard_verify_and_create),
                            )
                            .route("/in-progress", web::get().to(merchants::in_progress)),
                    )
                    .route(
                        "/{id}/products",
                        web::get().to(merchants::list_merchant_products),
                    )
                    .route("/{id}/products", web::post().to(merchants::add_products))
                    .route("/{id}/hours", web::put().to(merchants::set_hours))
                    .route("/{id}/finalize", web::post().to(merchants::finalize))
                    .route(
                        "/{id}/onboarding-status",
                        web::get().to(merchants::onboarding_status),
                    ),
            )
            // Agent routes — Agent/Admin role required
            .service(web::scope("/agents").route("/me/stats", web::get().to(agents::get_my_stats)))
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
            .service(web::scope("/stock-alerts").route(
                "/{id}/acknowledge",
                web::post().to(products::acknowledge_alert),
            ))
            // Dispute routes — Client role required
            .service(
                web::scope("/disputes")
                    .route("/me", web::get().to(disputes::list_my_disputes)),
            )
            // Share routes — Client role for metadata
            .service(
                web::scope("/share")
                    .route(
                        "/restaurant/{merchant_id}",
                        web::get().to(share::get_share_metadata),
                    ),
            )
            // Admin routes — Admin role required
            .service(
                web::scope("/admin")
                    .route(
                        "/dashboard/stats",
                        web::get().to(admin::dashboard_stats),
                    )
                    .service(
                        web::scope("/disputes")
                            .route("", web::get().to(admin::list_disputes))
                            .route("/{dispute_id}", web::get().to(admin::get_dispute_detail))
                            .route(
                                "/{dispute_id}/resolve",
                                web::post().to(admin::resolve_dispute),
                            ),
                    )
                    .service(
                        web::scope("/reconciliation")
                            .route("/run", web::post().to(reconciliation::run_reconciliation))
                            .route("/reports", web::get().to(reconciliation::list_reports))
                            .route("/reports/{date}", web::get().to(reconciliation::get_report)),
                    )
                    .route(
                        "/wallets/{user_id}/credit",
                        web::post().to(wallets::admin_credit_wallet),
                    )
                    .service(
                        web::scope("/cities")
                            .route("", web::get().to(admin::list_cities))
                            .route("", web::post().to(admin::create_city))
                            .route("/{city_id}", web::put().to(admin::update_city))
                            .route(
                                "/{city_id}/active",
                                web::patch().to(admin::toggle_city_active),
                            ),
                    )
                    .service(
                        web::scope("/users")
                            .route("", web::get().to(admin::list_users))
                            .route("/{user_id}", web::get().to(admin::get_user_detail))
                            .route(
                                "/{user_id}/status",
                                web::patch().to(admin::update_user_status_admin),
                            ),
                    )
                    .service(
                        web::scope("/merchants")
                            .route("", web::get().to(admin::list_merchants_admin))
                            .route(
                                "/{merchant_id}/history",
                                web::get().to(admin::get_merchant_history),
                            ),
                    )
                    .service(
                        web::scope("/drivers")
                            .route("", web::get().to(admin::list_drivers_admin))
                            .route(
                                "/{driver_id}/history",
                                web::get().to(admin::get_driver_history),
                            ),
                    ),
            ),
    );
}
