use actix_web::{web, App, HttpServer};
use tracing::info;
use tracing_subscriber::EnvFilter;

mod extractors;
mod middleware;
mod routes;

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

    // Shared application state injected via web::Data<>
    let app_config = web::Data::new(config.clone());
    let db_data = web::Data::new(db_pool);

    HttpServer::new(move || {
        App::new()
            .app_data(app_config.clone())
            .app_data(db_data.clone())
            // Future: .app_data(web::Data::new(redis_conn.clone()))
            // Future: .app_data(web::Data::new(s3_client.clone()))
            .configure(routes::configure)
    })
    .bind(&bind_addr)?
    .run()
    .await
}
