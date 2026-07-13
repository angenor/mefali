//! Assemblage Actix du backend Mefali.
//!
//! Ce cycle : contrat OpenAPI (auto-collecté par utoipa-actix-web), sonde
//! `/health`, Swagger UI en dev (absente en production, constitution VIII),
//! export de `openapi.json`. Le worker outbox est branché par T019.

pub mod health;

use actix_web::{web, App, HttpResponse, HttpServer};
use utoipa::openapi::{InfoBuilder, OpenApi};
use utoipa_actix_web::AppExt;
use utoipa_swagger_ui::SwaggerUi;

/// Construit la spec OpenAPI à partir des handlers `#[utoipa::path]`
/// (auto-collectés par utoipa-actix-web). Source de vérité du contrat (TRX-01).
pub fn api_openapi() -> OpenApi {
    let (_, mut openapi) = App::new()
        .into_utoipa_app()
        .service(health::health)
        .split_for_parts();
    openapi.info = InfoBuilder::new()
        .title("Mefali API")
        .version("0.1.0")
        .build();
    openapi
}

/// Surfaces annexes au contrat :
/// - `/api-docs/openapi.json` : servi en dev ET en prod (contrat public) ;
/// - Swagger UI : seulement hors production (constitution VIII).
fn mount_docs(prod: bool, openapi: OpenApi) -> impl FnOnce(&mut web::ServiceConfig) {
    move |cfg: &mut web::ServiceConfig| {
        if prod {
            cfg.route(
                "/api-docs/openapi.json",
                web::get().to(move || {
                    let openapi = openapi.clone();
                    async move { HttpResponse::Ok().json(openapi) }
                }),
            );
        } else {
            cfg.service(
                SwaggerUi::new("/swagger-ui/{_:.*}").url("/api-docs/openapi.json", openapi.clone()),
            );
        }
    }
}

/// Démarre le serveur Actix (lie `0.0.0.0:8080`) et le worker outbox.
pub async fn run() -> std::io::Result<()> {
    let prod = std::env::var("APP_ENV")
        .map(|v| v == "production")
        .unwrap_or(false);

    // Worker outbox : démarré si la base est configurée. Aucun consommateur
    // enregistré ce cycle (les parcours métier en ajouteront). Sans base,
    // le service sert `/health` seul (sonde de vie, sans dépendance).
    match socle::Config::from_env() {
        Ok(config) => match socle::connect_pg(&config.database_url).await {
            Ok(pool) => {
                // Migrations embarquées appliquées au démarrage (déploiement prod
                // autonome — pas de sqlx-cli dans l'image).
                if let Err(e) = sqlx::migrate!("../migrations").run(&pool).await {
                    return Err(std::io::Error::other(format!("migrations : {e}")));
                }
                let worker = socle::WorkerOutbox::new(pool, Vec::new());
                tokio::spawn(worker.run());
                eprintln!("migrations appliquées ; worker outbox démarré");
            }
            Err(e) => eprintln!("base indisponible — worker outbox non démarré : {e}"),
        },
        Err(_) => eprintln!("configuration incomplète — worker outbox non démarré (/health seul)"),
    }

    let addr = ("0.0.0.0", 8080);
    println!(
        "Mefali api — démarrage sur http://{}:{} (production={prod})",
        addr.0, addr.1
    );

    HttpServer::new(move || {
        let (app, openapi) = App::new()
            .into_utoipa_app()
            .service(health::health)
            .split_for_parts();
        app.configure(mount_docs(prod, openapi))
            // Corrélation par requête (request id) dans les logs JSON…
            .wrap(tracing_actix_web::TracingLogger::default())
            // …et capture des erreurs HTTP par Sentry (actif si SENTRY_DSN).
            .wrap(sentry_actix::Sentry::new())
    })
    .bind(addr)?
    .run()
    .await
}

/// Charge le jeu de démonstration en UNE transaction (idempotent, rollback si
/// interruption). Rejoue `backend/seeds/NN_*.sql` dans l'ordre lexicographique.
/// Renvoie le nombre de fichiers appliqués. data-model.md §3.
pub async fn charger_seeds(pool: &sqlx::PgPool) -> Result<usize, sqlx::Error> {
    let dir = std::env::var("SEED_DIR")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../seeds"));
    let mut fichiers: Vec<std::path::PathBuf> = std::fs::read_dir(&dir)
        .expect("dossier backend/seeds introuvable")
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.extension().is_some_and(|ext| ext == "sql"))
        .collect();
    fichiers.sort();

    let mut tx = pool.begin().await?;
    for fichier in &fichiers {
        let sql = std::fs::read_to_string(fichier).expect("lecture d'un fichier seed");
        // SQL issu de nos fichiers de seed commités (jamais d'entrée utilisateur).
        sqlx::raw_sql(sqlx::AssertSqlSafe(sql))
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok(fichiers.len())
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{http::StatusCode, test as atest};

    #[test]
    fn openapi_contient_health() {
        let openapi = api_openapi();
        assert_eq!(openapi.info.title, "Mefali API");
        assert!(openapi.paths.paths.contains_key("/health"));
    }

    #[actix_web::test]
    async fn health_repond_ok() {
        let app = atest::init_service({
            let (app, openapi) = App::new()
                .into_utoipa_app()
                .service(health::health)
                .split_for_parts();
            app.configure(mount_docs(false, openapi))
        })
        .await;

        let req = atest::TestRequest::get().uri("/health").to_request();
        let resp = atest::call_service(&app, req).await;
        assert!(resp.status().is_success());

        let body: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(body["status"], "ok");
        assert!(body["version"].is_string());
    }

    #[actix_web::test]
    async fn swagger_presente_en_dev() {
        let app = atest::init_service({
            let (app, openapi) = App::new()
                .into_utoipa_app()
                .service(health::health)
                .split_for_parts();
            app.configure(mount_docs(false, openapi))
        })
        .await;

        let req = atest::TestRequest::get()
            .uri("/api-docs/openapi.json")
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn swagger_absente_en_production() {
        let app = atest::init_service({
            let (app, openapi) = App::new()
                .into_utoipa_app()
                .service(health::health)
                .split_for_parts();
            app.configure(mount_docs(true, openapi))
        })
        .await;

        // Swagger UI absente…
        let req = atest::TestRequest::get().uri("/swagger-ui/").to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);

        // …mais le contrat openapi.json reste exposé.
        let req2 = atest::TestRequest::get()
            .uri("/api-docs/openapi.json")
            .to_request();
        let resp2 = atest::call_service(&app, req2).await;
        assert!(resp2.status().is_success());
    }

    /// T6 — seed sur base vierge puis re-seed → état identique, zéro doublon.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_idempotent(pool: sqlx::PgPool) {
        let n1 = charger_seeds(&pool).await.unwrap();
        assert!(n1 >= 1, "au moins le marqueur de démo");
        let compte1: i64 = sqlx::query_scalar("SELECT count(*) FROM demo.marqueur")
            .fetch_one(&pool)
            .await
            .unwrap();

        let n2 = charger_seeds(&pool).await.unwrap();
        let compte2: i64 = sqlx::query_scalar("SELECT count(*) FROM demo.marqueur")
            .fetch_one(&pool)
            .await
            .unwrap();

        assert_eq!(n1, n2);
        assert_eq!(compte1, 1);
        assert_eq!(compte2, 1, "re-seed → état identique, zéro doublon");
    }
}
