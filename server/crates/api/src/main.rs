use std::sync::Arc;

use actix_web::{web, App, HttpServer};
use notification::sms::dev_provider::DevSmsProvider;
use notification::sms::SmsProvider;
use payment_provider::cinetpay::CinetPayAdapter;
use payment_provider::provider::PaymentProvider;
use tracing::{error, info, warn};
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
    let sms_router: Option<notification::sms::SmsRouter> = Some(notification::sms::SmsRouter::new(
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
    let fcm_client: Option<notification::fcm::FcmClient> = notification::fcm::FcmClient::from_env();
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

    // Start daily reconciliation scheduler (awaited so startup failure is caught)
    let cron_expr =
        std::env::var("RECONCILIATION_CRON").unwrap_or_else(|_| "0 0 1 * * *".into()); // default: 01:00 UTC daily
    match start_reconciliation_scheduler(db_pool.clone(), payment_provider.clone(), &cron_expr)
        .await
    {
        Ok(_) => info!("Reconciliation scheduler started (cron: {})", cron_expr),
        Err(e) => error!("Failed to start reconciliation scheduler: {}", e),
    }

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

/// Start the daily reconciliation cron job.
async fn start_reconciliation_scheduler(
    pool: sqlx::PgPool,
    payment_provider: Arc<dyn PaymentProvider>,
    cron_expr: &str,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    use tokio_cron_scheduler::{Job, JobScheduler};

    let sched = JobScheduler::new().await?;

    let cron_owned = cron_expr.to_string();
    sched
        .add(Job::new_async(cron_owned.as_str(), move |_uuid, _lock| {
            let pool = pool.clone();
            let provider = payment_provider.clone();
            Box::pin(async move {
                let yesterday = chrono::Utc::now().date_naive() - chrono::Duration::days(1);
                info!(date = %yesterday, "Running scheduled reconciliation");
                match domain::reconciliation::service::run_daily_reconciliation(
                    &pool,
                    provider.as_ref(),
                    yesterday,
                    false,
                )
                .await
                {
                    Ok(report) => match report.status {
                        domain::reconciliation::model::ReconciliationStatus::Ok => {
                            info!(date = %yesterday, "Scheduled reconciliation: OK");
                        }
                        domain::reconciliation::model::ReconciliationStatus::Warnings => {
                            warn!(
                                date = %yesterday,
                                discrepancies = report.discrepancy_count,
                                "Scheduled reconciliation: warnings"
                            );
                        }
                        domain::reconciliation::model::ReconciliationStatus::Critical => {
                            error!(
                                date = %yesterday,
                                discrepancies = report.discrepancy_count,
                                "Scheduled reconciliation: CRITICAL"
                            );
                        }
                    },
                    Err(e) => {
                        error!(date = %yesterday, error = %e, "Scheduled reconciliation failed");
                    }
                }
            })
        })?)
        .await?;

    sched.start().await?;
    Ok(())
}
