//! Binaire Actix du backend Mefali. La logique d'assemblage vit dans la lib
//! `api` (partagée avec le binaire `export-openapi` et les tests).

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    api::run().await
}
