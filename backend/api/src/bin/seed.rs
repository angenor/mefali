//! Runner du jeu de démonstration (TRX-05). Charge `backend/seeds/*.sql` en
//! une transaction, idempotent. data-model.md §3.
//!
//!   cargo run -p api --bin seed        (DATABASE_URL requis)

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let database_url = std::env::var("DATABASE_URL")?;
    let pool = socle::connect_pg(&database_url).await?;
    let n = api::charger_seeds(&pool).await?;
    println!("✓ jeu de démo chargé ({n} fichier(s) rejoué(s))");
    Ok(())
}
