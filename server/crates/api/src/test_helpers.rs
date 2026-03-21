use actix_web::{web, App};
use chrono::Utc;
use common::config::AppConfig;
use common::types::Id;
use domain::users::service::JwtClaims;
use jsonwebtoken::{encode, EncodingKey, Header};
use sqlx::PgPool;

use crate::routes::admin;
use crate::routes::agents;
use crate::routes::merchants;
use crate::routes::orders;
use crate::routes::wallets;

pub fn test_config() -> AppConfig {
    AppConfig {
        database_url: String::new(),
        redis_url: String::new(),
        minio_endpoint: String::new(),
        minio_access_key: String::new(),
        minio_secret_key: String::new(),
        minio_bucket: String::new(),
        api_host: String::new(),
        api_port: 8090,
        jwt_secret: "test-secret-key-for-testing".into(),
        jwt_access_expiry: 900,
        jwt_refresh_expiry: 604800,
        otp_length: 6,
        otp_expiry_seconds: 300,
        otp_max_attempts: 3,
        otp_rate_limit_per_minute: 3,
        cinetpay_api_key: "mock".into(),
        cinetpay_site_id: "mock".into(),
        cinetpay_base_url: "https://api-checkout.cinetpay.com/v2".into(),
        cinetpay_notify_url: "http://localhost:8090/api/v1/payments/webhook".into(),
        cinetpay_return_url: "http://localhost:8090/payment/return".into(),
        cinetpay_webhook_secret: "test-webhook-secret".into(),
    }
}

pub fn create_test_jwt(user_id: Id, role: &str) -> String {
    let now = Utc::now().timestamp();
    let claims = JwtClaims {
        sub: user_id.to_string(),
        role: role.into(),
        iat: now,
        exp: now + 900,
    };
    let config = test_config();
    let key = EncodingKey::from_secret(config.jwt_secret.as_bytes());
    encode(&Header::default(), &claims, &key).unwrap()
}

/// Build a test App with only orders/merchants routes registered.
/// Does NOT include auth, kyc, users, or products routes (they need Redis/S3/SMS).
///
/// WARNING: Route paths are duplicated from routes/mod.rs — if routes change there,
/// update them here too. Only exercised routes should be registered.
pub fn test_app(
    pool: PgPool,
) -> App<
    impl actix_web::dev::ServiceFactory<
        actix_web::dev::ServiceRequest,
        Config = (),
        Response = actix_web::dev::ServiceResponse,
        Error = actix_web::Error,
        InitError = (),
    >,
> {
    let fcm_client: Option<notification::fcm::FcmClient> = None;
    let sms_router: Option<notification::sms::SmsRouter> = None;

    App::new()
        .app_data(web::Data::new(test_config()))
        .app_data(web::Data::new(pool))
        .app_data(web::Data::new(fcm_client))
        .app_data(web::Data::new(sms_router))
        .service(
            web::scope("/api/v1")
                .service(
                    web::scope("/orders")
                        .route("", web::post().to(orders::create_order))
                        .route("/{id}/accept", web::put().to(orders::accept_order))
                        .route("/{id}/reject", web::put().to(orders::reject_order))
                        .route("/{id}/ready", web::put().to(orders::mark_ready)),
                )
                .service(
                    web::scope("/agents").route("/me/stats", web::get().to(agents::get_my_stats)),
                )
                .service(
                    web::scope("/admin")
                        .route("/dashboard/stats", web::get().to(admin::dashboard_stats))
                        .service(
                            web::scope("/disputes")
                                .route("", web::get().to(admin::list_disputes))
                                .route("/{dispute_id}", web::get().to(admin::get_dispute_detail))
                                .route(
                                    "/{dispute_id}/resolve",
                                    web::post().to(admin::resolve_dispute),
                                ),
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
                )
                .service(
                    web::scope("/merchants")
                        .route("", web::get().to(merchants::list_merchants))
                        .route("/me", web::get().to(merchants::get_me_with_status))
                        .route("/me/orders", web::get().to(orders::get_merchant_orders))
                        .route("/me/stats/weekly", web::get().to(orders::get_weekly_stats))
                        .route("/me/hours", web::get().to(merchants::get_my_hours))
                        .route("/me/hours", web::put().to(merchants::update_my_hours))
                        .route("/me/closures", web::get().to(merchants::get_my_closures))
                        .route("/me/closures", web::post().to(merchants::create_my_closure))
                        .route(
                            "/me/closures/{id}",
                            web::delete().to(merchants::delete_my_closure),
                        )
                        .route(
                            "/{id}/products",
                            web::get().to(merchants::list_merchant_products),
                        ),
                ),
        )
}
