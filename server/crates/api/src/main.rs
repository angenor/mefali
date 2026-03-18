use std::sync::Arc;

use actix_web::{web, App, HttpServer};
use notification::sms::dev_provider::DevSmsProvider;
use notification::sms::SmsProvider;
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

    // SMS provider — swap DevSmsProvider for a real provider in production
    let sms_provider: Arc<dyn SmsProvider> = Arc::new(DevSmsProvider);

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
    let s3_data = web::Data::new(s3_client);

    HttpServer::new(move || {
        App::new()
            .app_data(app_config.clone())
            .app_data(db_data.clone())
            .app_data(redis_data.clone())
            .app_data(sms_data.clone())
            .app_data(s3_data.clone())
            .configure(routes::configure)
    })
    .bind(&bind_addr)?
    .run()
    .await
}
