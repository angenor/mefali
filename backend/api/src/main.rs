//! Binaire Actix du backend Mefali. La logique d'assemblage vit dans la lib
//! `api` (partagée avec le binaire `export-openapi` et les tests).

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Télémétrie d'abord : logs JSON corrélés + Sentry (si SENTRY_DSN).
    // Le garde est conservé vivant pour toute la durée du process.
    let dsn = std::env::var("SENTRY_DSN").ok();
    let _telemetry = socle::init_telemetry(dsn.as_deref());

    api::run().await
}
