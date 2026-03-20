use std::sync::Arc;

use actix_web::{web, App, HttpServer};
use notification::sms::dev_provider::DevSmsProvider;
use notification::sms::SmsProvider;
use payment_provider::cinetpay::CinetPayAdapter;
use payment_provider::provider::PaymentProvider;
use tracing::info;
use tracing_subscriber::EnvFilter;

mod extractors;
mod middleware;
mod routes;

#[cfg(test)]
mod test_helpers;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env file
    dotenvy::dotenv().ok();

    // Initialize structured JSON logging
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .json()
        .init();

    let config = common::config::AppConfig::from_env().expect("Failed to load configuration");

    let bind_addr = format!("{}:{}", config.api_host, config.api_port);
    info!(bind = %bind_addr, "Starting mefali API server");

    // Initialize database connection pool
    let db_pool = infrastructure::database::create_pool(&config.database_url)
        .await
        .expect("Failed to create database pool");

    // Run database migrations
    sqlx::migrate!("../../migrations")
        .run(&db_pool)
        .await
        .expect("Failed to run database migrations");
    info!("Database migrations applied successfully");

    // Initialize Redis connection
    let redis_conn = infrastructure::redis::create_connection(&config.redis_url)
        .await
        .expect("Failed to create Redis connection");
    info!("Redis connection established");

    // SMS provider (single) — used for OTP and other direct SMS
    let sms_provider: Arc<dyn SmsProvider> = Arc::new(DevSmsProvider);

    // SMS router (dual-provider with failover) — used for delivery mission fallback
    // Swap DevSmsProvider for real providers (Infobip/Twilio) in production
    let sms_router: Option<notification::sms::SmsRouter> =
        Some(notification::sms::SmsRouter::new(
            Box::new(DevSmsProvider),
            Box::new(DevSmsProvider),
        ));
    info!("SMS router initialized with dual-provider failover (dev providers)");

    // Payment provider — CinetPay adapter (swap for Mock in dev if needed)
    let payment_provider: Arc<dyn PaymentProvider> = Arc::new(CinetPayAdapter::new(
        config.cinetpay_api_key.clone(),
        config.cinetpay_site_id.clone(),
        config.cinetpay_base_url.clone(),
        config.cinetpay_notify_url.clone(),
        config.cinetpay_return_url.clone(),
    ));
    info!("CinetPay payment provider initialized");

    // FCM push notification client (optional — disabled if Firebase credentials not set)
    let fcm_client: Option<notification::fcm::FcmClient> =
        notification::fcm::FcmClient::from_env();
    match &fcm_client {
        Some(_) => info!("FCM push notification client initialized"),
        None => info!("FCM not configured — push notifications disabled (set FIREBASE_PROJECT_ID and FIREBASE_SERVICE_ACCOUNT_JSON)"),
    }

    // Initialize MinIO/S3 client
    let s3_client = infrastructure::storage::create_s3_client(
        &config.minio_endpoint,
        &config.minio_access_key,
        &config.minio_secret_key,
    )
    .await;
    info!("MinIO/S3 client initialized");

    // Shared application state injected via web::Data<>
    let app_config = web::Data::new(config.clone());
    let db_data = web::Data::new(db_pool);
    let redis_data = web::Data::new(redis_conn);
    let sms_data = web::Data::new(sms_provider);
    let payment_data = web::Data::new(payment_provider);
    let s3_data = web::Data::new(s3_client);
    let fcm_data = web::Data::new(fcm_client);
    let sms_router_data = web::Data::new(sms_router);

    HttpServer::new(move || {
        App::new()
            .app_data(app_config.clone())
            .app_data(db_data.clone())
            .app_data(redis_data.clone())
            .app_data(sms_data.clone())
            .app_data(payment_data.clone())
            .app_data(s3_data.clone())
            .app_data(fcm_data.clone())
            .app_data(sms_router_data.clone())
            .configure(routes::configure)
    })
    .bind(&bind_addr)?
    .run()
    .await
}
