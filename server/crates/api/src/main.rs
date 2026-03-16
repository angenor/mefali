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

    // Shared application state injected via web::Data<>
    let app_config = web::Data::new(config.clone());

    HttpServer::new(move || {
        App::new()
            .app_data(app_config.clone())
            // Future: .app_data(web::Data::new(db_pool.clone()))
            // Future: .app_data(web::Data::new(redis_conn.clone()))
            // Future: .app_data(web::Data::new(s3_client.clone()))
            .configure(routes::configure)
    })
    .bind(&bind_addr)?
    .run()
    .await
}
