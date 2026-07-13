//! Génère `openapi.json` à la RACINE du dépôt depuis les annotations utoipa.
//! Déterministe (sérialisation pretty stable) — contrôlé en CI (TRX-01).
//!
//!   cargo run -p api --bin export-openapi

use std::path::Path;

fn main() -> std::io::Result<()> {
    let openapi = api::api_openapi();
    let json = serde_json::to_string_pretty(&openapi).expect("sérialisation openapi");

    // backend/api → ../../ = racine du dépôt.
    let dest = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../openapi.json");
    std::fs::write(&dest, format!("{json}\n"))?;

    println!("openapi.json écrit : {}", dest.display());
    Ok(())
}
