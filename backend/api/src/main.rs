//! Binaire Actix du backend Mefali.
//!
//! Squelette minimal ce cycle : le serveur démarre. Les routes (`/health`,
//! `openapi.json`, Swagger UI) et le worker outbox sont ajoutés par les tâches
//! T014 (santé/contrat) et T019 (worker).

use actix_web::{App, HttpServer};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let addr = ("127.0.0.1", 8080);
    println!("Mefali api — démarrage sur http://{}:{}", addr.0, addr.1);

    HttpServer::new(App::new).bind(addr)?.run().await
}
