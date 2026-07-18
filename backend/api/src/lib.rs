//! Assemblage Actix du backend Mefali.
//!
//! Ce cycle : contrat OpenAPI (auto-collecté par utoipa-actix-web), sonde
//! `/health`, Swagger UI en dev (absente en production, constitution VIII),
//! export de `openapi.json`. Le worker outbox est branché par T019.

pub mod admin_prestataires_http;
pub mod adresses_http;
pub mod auth_http;
pub mod comptes_http;
/// Surface réservée au dev — montée hors production seulement (voir le module).
pub mod dev_http;
pub mod health;
pub mod infra_redis;
pub mod infra_s3;
pub mod prestataires_http;
pub mod vendeur_http;
pub mod zones_http;

use std::sync::Arc;

use actix_web::{web, App, HttpResponse, HttpServer};
use comptes::{EnvoiSms, PgComptes, SmsTraces};
use utoipa::openapi::security::{HttpAuthScheme, HttpBuilder, SecurityScheme};
use utoipa::openapi::{InfoBuilder, OpenApi};
use utoipa_actix_web::AppExt;
use utoipa_swagger_ui::SwaggerUi;

/// Construit la spec OpenAPI à partir des handlers `#[utoipa::path]`
/// (auto-collectés par utoipa-actix-web). Source de vérité du contrat (TRX-01).
pub fn api_openapi() -> OpenApi {
    let (_, mut openapi) = App::new()
        .into_utoipa_app()
        .service(health::health)
        .service(zones_http::forcer_categorie)
        .service(zones_http::config)
        .service(auth_http::demander)
        .service(auth_http::verifier)
        .service(auth_http::inscrire)
        .service(auth_http::rafraichir)
        .service(auth_http::deconnexion)
        .service(auth_http::moi)
        .service(auth_http::mes_sessions)
        .service(auth_http::revoquer_session)
        .service(comptes_http::decider_role)
        .service(comptes_http::soumettre_dossier_coursier)
        .service(comptes_http::mon_dossier_coursier)
        .service(comptes_http::lister_dossiers_coursier)
        .service(comptes_http::consulter_dossier_coursier)
        .service(adresses_http::mes_adresses)
        .service(adresses_http::enregistrer_adresse)
        .service(adresses_http::modifier_adresse)
        .service(adresses_http::supprimer_adresse)
        .service(adresses_http::ecouter_repere_vocal)
        .service(adresses_http::remplacer_repere_vocal)
        .service(admin_prestataires_http::creer_prestataire)
        .service(admin_prestataires_http::lister_prestataires)
        .service(admin_prestataires_http::consulter_prestataire_admin)
        .service(admin_prestataires_http::modifier_prestataire)
        .service(admin_prestataires_http::ajouter_photo)
        .service(admin_prestataires_http::supprimer_photo)
        .service(admin_prestataires_http::deposer_charte)
        .service(admin_prestataires_http::definir_site)
        .service(admin_prestataires_http::agreer_prestataire)
        .service(admin_prestataires_http::rattacher_compte)
        .service(admin_prestataires_http::detacher_compte)
        .service(vendeur_http::mes_prestataires)
        .service(prestataires_http::consulter_prestataire)
        .service(prestataires_http::resoudre_plaque)
        .split_for_parts();
    openapi.info = InfoBuilder::new()
        .title("Mefali API")
        .version("0.1.0")
        .build();
    // Jeton d'accès JWT (cycle CPT, research R5). Remplace le SecurityScheme
    // `adminToken` (X-Admin-Token) du cycle 002, supprimé avec sa garde.
    openapi
        .components
        .get_or_insert_with(Default::default)
        .add_security_scheme(
            "bearerAuth",
            SecurityScheme::Http(
                HttpBuilder::new()
                    .scheme(HttpAuthScheme::Bearer)
                    .bearer_format("JWT")
                    .build(),
            ),
        );
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

/// Surface réservée au DEV : `/dev/otp` relit le dernier code OTP tracé
/// (`dev_http`). Montée sous le MÊME `prod` que Swagger UI — en production, la
/// route n'est jamais enregistrée et le chemin rend 404.
///
/// Le gate porte sur un `bool`, comme [`mount_docs`] : testable sans toucher à
/// l'environnement du processus, que les tests parallèles partagent.
///
/// `traces` est `None` quand la configuration est absente (mode dégradé,
/// `/health` seul) : pas de journal, donc rien à relire.
fn mount_dev(
    prod: bool,
    traces: Option<Arc<SmsTraces>>,
) -> impl FnOnce(&mut web::ServiceConfig) {
    move |cfg: &mut web::ServiceConfig| {
        if let (false, Some(traces)) = (prod, traces) {
            cfg.app_data(web::Data::new(traces))
                .route("/dev/otp", web::get().to(dev_http::dernier_code));
        }
    }
}

/// Région S3 signée mais non routante côté Garage (`infra/garage/garage.toml`).
const REGION_S3: &str = "garage";

/// Intervalle du job de purge des repères vocaux (research R8).
///
/// Quotidien : la rétention se compte en MOIS (12 par défaut), purger plus
/// souvent ne minimiserait rien de plus et réveillerait la base pour rien.
const PURGE_INTERVALLE: std::time::Duration = std::time::Duration::from_secs(24 * 60 * 60);

/// Purge périodique des repères vocaux inutilisés (FR-022, research R8).
///
/// Même patron que `WorkerOutbox` : une tâche tokio dans le process existant.
/// Une erreur est journalisée et le passage suivant retente — un incident de
/// purge ne doit jamais faire tomber l'API.
async fn job_purge_reperes(depot: PgComptes) {
    let mut horloge = tokio::time::interval(PURGE_INTERVALLE);
    loop {
        horloge.tick().await;
        match depot.purger_reperes_vocaux().await {
            Ok(0) => {}
            Ok(n) => tracing::info!(purgees = n, "repères vocaux purgés (rétention de zone)"),
            Err(e) => tracing::error!(erreur = %e, "purge des repères vocaux échouée"),
        }
    }
}

/// Supprime du stockage objet une donnée personnelle que la transaction qui
/// vient d'être COMMITÉE a rendue orpheline (constitution VIII).
///
/// ⚠ À n'appeler qu'APRÈS `tx.commit()`. Un dépôt écrit toujours une clé neuve
/// et n'écrase jamais : une re-soumission de dossier, un repère vocal refait ou
/// un rejeu concurrent d'adresse laissent derrière eux des octets que plus
/// aucune ligne ne désigne. Supprimer AVANT le commit inverserait le risque —
/// un rollback ferait alors pointer une ligne vivante vers du vide.
///
/// Best-effort, exactement comme `purger_reperes_vocaux` (R8) : la base est
/// déjà juste. Un échec ici laisse un orphelin à rattraper, jamais une
/// incohérence — et ne doit surtout pas transformer en erreur une requête qui a
/// réussi.
pub(crate) async fn supprimer_objet_orphelin(depot: &PgComptes, cle: &str, quoi: &str) {
    if let Err(e) = depot.objets().supprimer(cle).await {
        tracing::warn!(
            cle = %cle,
            erreur = %e,
            "{quoi} déréférencé en base, objet non supprimé — à rattraper",
        );
    }
}

/// Démarre le serveur Actix (lie `0.0.0.0:8080`) et le worker outbox.
pub async fn run() -> std::io::Result<()> {
    // Gate UNIQUE des surfaces réservées au dev (Swagger UI, `/dev/otp`).
    // Défaut fermé, lu avant `Config::from_env` : voir `AppEnv::depuis_env`.
    let prod = socle::AppEnv::depuis_env().is_production();

    // Worker outbox + pool applicatif + ports du domaine comptes : démarrés si
    // la configuration est complète. Sans elle, le service sert `/health` seul
    // (sonde de vie, sans dépendance) ; les endpoints métier renvoient 500.
    //
    // Nuance de sécurité (cycle CPT) : une configuration ABSENTE dégrade
    // silencieusement, une configuration PRÉSENTE mais invalide (JWT_SECRET
    // trop court) échoue au démarrage — `socle::Config::from_env` la refuse.
    let mut comptes_opt: Option<PgComptes> = None;
    let mut prestataires_opt: Option<prestataires::PgPrestataires> = None;
    let mut traces_opt: Option<Arc<SmsTraces>> = None;
    let pool_opt = match socle::Config::from_env() {
        Ok(config) => match socle::connect_pg(&config.database_url).await {
            Ok(pool) => {
                // Migrations embarquées appliquées au démarrage (déploiement prod
                // autonome — pas de sqlx-cli dans l'image).
                if let Err(e) = sqlx::migrate!("../migrations").run(&pool).await {
                    return Err(std::io::Error::other(format!("migrations : {e}")));
                }
                let worker = socle::WorkerOutbox::new(pool.clone(), Vec::new());
                tokio::spawn(worker.run());
                eprintln!("migrations appliquées ; worker outbox démarré");

                let ephemere = infra_redis::RedisEphemere::nouveau(&config.redis_url)
                    .map_err(|e| std::io::Error::other(format!("Redis : {e}")))?;
                // Port PARTAGÉ entre comptes (pièces, repères vocaux) et
                // prestataires (photos, chartes) — un seul client S3.
                let objets: Arc<dyn socle::DepotObjets> = Arc::new(infra_s3::S3Objets::nouveau(
                    &config.s3_endpoint,
                    &config.s3_access_key,
                    &config.s3_secret_key,
                    &config.s3_bucket,
                    REGION_S3,
                ));
                // Le type CONCRET est retenu à côté du port : `EnvoiSms` ne sait
                // qu'envoyer, et `/dev/otp` doit RELIRE le journal. `Arc` partagé
                // — les deux poignées désignent le même journal, sinon la surface
                // dev lirait un journal toujours vide.
                let traces = match config.sms_mode {
                    // Le fournisseur réel arrive au cycle NTF, derrière ce même
                    // port (research R6) — ici le code part dans les logs.
                    socle::SmsMode::Traces => Arc::new(SmsTraces::new()),
                };
                let sms: Arc<dyn EnvoiSms> = traces.clone();
                traces_opt = Some(traces);
                eprintln!(
                    "ports comptes câblés (Redis, Garage, SMS={:?})",
                    config.sms_mode
                );
                // PgComptes EST la composition racine du domaine : pool + les
                // trois ports + le secret. Les handlers ne voient que lui.
                let depot = PgComptes::new(
                    pool.clone(),
                    Arc::new(ephemere),
                    sms,
                    objets.clone(),
                    Arc::from(config.jwt_secret.as_bytes()),
                );
                tokio::spawn(job_purge_reperes(depot.clone()));
                eprintln!("job de purge des repères vocaux démarré (quotidien)");
                // PgPrestataires — composition racine du domaine prestataires
                // (cycle 005) : réutilise le dépôt comptes (rôle vendeur au
                // rattachement, R11), le MÊME port objets, et le bouchon
                // CommandesActives — aucune commande active n'existe avant le
                // cycle CMD, donc aucun signalement coursier n'est recevable
                // (R5, exact et voulu).
                prestataires_opt = Some(prestataires::PgPrestataires::new(
                    pool.clone(),
                    depot.clone(),
                    objets,
                    Arc::new(prestataires::AucuneCommandeActive),
                    Arc::from(config.plaque_secret.as_bytes()),
                ));
                comptes_opt = Some(depot);
                Some(pool)
            }
            Err(e) => {
                eprintln!("base indisponible — worker outbox non démarré : {e}");
                None
            }
        },
        Err(e) => {
            eprintln!("configuration incomplète — worker outbox non démarré (/health seul) : {e}");
            None
        }
    };

    let addr = ("0.0.0.0", 8080);
    println!(
        "Mefali api — démarrage sur http://{}:{} (production={prod})",
        addr.0, addr.1
    );

    // Rate-limit /config par IP (research R4) : burst 30, recharge 1/100 ms.
    // Partagé entre workers (Arc interne) — un seul compteur par IP.
    let gouverneur = zones_http::config_governor(30, 100);

    HttpServer::new(move || {
        let (app, openapi) = App::new()
            .into_utoipa_app()
            .service(health::health)
            .service(zones_http::forcer_categorie)
            .service(zones_http::config)
            .service(auth_http::demander)
            .service(auth_http::verifier)
            .service(auth_http::inscrire)
            .service(auth_http::rafraichir)
            .service(auth_http::deconnexion)
            .service(auth_http::moi)
            .service(auth_http::mes_sessions)
            .service(auth_http::revoquer_session)
            .service(comptes_http::decider_role)
            // ⚠ `/admin/comptes/dossiers-coursier` AVANT
            // `/admin/comptes/{compte_id}/dossier-coursier` : Actix retient la
            // première route qui matche, et « dossiers-coursier » se lirait
            // sinon comme un `{compte_id}` — qui ne parse pas en UUID (404).
            .service(comptes_http::lister_dossiers_coursier)
            .service(comptes_http::consulter_dossier_coursier)
            .service(comptes_http::soumettre_dossier_coursier)
            .service(comptes_http::mon_dossier_coursier)
            .service(adresses_http::mes_adresses)
            .service(adresses_http::enregistrer_adresse)
            .service(adresses_http::modifier_adresse)
            .service(adresses_http::supprimer_adresse)
            .service(adresses_http::ecouter_repere_vocal)
            .service(adresses_http::remplacer_repere_vocal)
            .service(admin_prestataires_http::creer_prestataire)
        .service(admin_prestataires_http::lister_prestataires)
        .service(admin_prestataires_http::consulter_prestataire_admin)
        .service(admin_prestataires_http::modifier_prestataire)
        .service(admin_prestataires_http::ajouter_photo)
        .service(admin_prestataires_http::supprimer_photo)
        .service(admin_prestataires_http::deposer_charte)
        .service(admin_prestataires_http::definir_site)
        .service(admin_prestataires_http::agreer_prestataire)
        .service(admin_prestataires_http::rattacher_compte)
        .service(admin_prestataires_http::detacher_compte)
        .service(vendeur_http::mes_prestataires)
        .service(prestataires_http::consulter_prestataire)
            .service(prestataires_http::resoudre_plaque)
            .split_for_parts();
        let mut app = app
            .configure(mount_docs(prod, openapi))
            // Corps JSON invalide → 422 ; paramètre `zone` invalide → 400 (clés i18n).
            .app_data(zones_http::config_json())
            .app_data(zones_http::config_query())
            // Rôle hors énumération dans le chemin → 404 (ressource inexistante).
            .app_data(comptes_http::config_path())
            // Corps multipart démesuré → 422 avant bufferisation (CPT-04/05).
            .app_data(comptes_http::config_multipart());
        if let Some(pool) = pool_opt.clone() {
            app = app.app_data(web::Data::new(pool));
        }
        if let Some(depot) = comptes_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = prestataires_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        app.configure(mount_dev(prod, traces_opt.clone()))
            // Rate-limit par IP (politeness) sur toute la surface publique.
            .wrap(actix_governor::Governor::new(&gouverneur))
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

    /// Le garde-fou qui compte : `/dev/otp` rend un code OTP en clair à qui
    /// connaît un numéro. En production, la route ne doit pas exister.
    #[actix_web::test]
    async fn surface_dev_otp_absente_en_production() {
        let app = atest::init_service(
            App::new()
                .configure(mount_dev(true, Some(Arc::new(SmsTraces::new()))))
                .service(health::health),
        )
        .await;

        let req = atest::TestRequest::get()
            .uri("/dev/otp?telephone=%2B2250701020304&zone=00000000-0000-0000-0000-000000000000")
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(
            resp.status(),
            StatusCode::NOT_FOUND,
            "un journal PRÉSENT ne suffit pas : c'est `prod` qui décide",
        );
    }

    /// Contrôle négatif du test ci-dessus : hors production la route EXISTE
    /// bel et bien. Sans lui, `surface_dev_otp_absente_en_production` passerait
    /// même si la route avait disparu partout, y compris en dev.
    ///
    /// L'assertion porte sur « pas 404 » et rien d'autre : ce test répond à
    /// « la route est-elle montée ? », pas « que fait-elle ? ». Le handler
    /// replie toute erreur sur 400, donc le code de sortie exact ne prouverait
    /// rien de plus. Le chemin passant est joué en réel (quickstart).
    #[actix_web::test]
    async fn surface_dev_otp_montee_hors_production() {
        let depot = PgComptes::new(
            // Le pool EST touché — et c'est ce qui rend le 400 : `normaliser_e164`
            // lit l'indicatif de la ZONE avant de regarder le numéro
            // (`zones.parametre` → SELECT), et l'hôte « inutilise » ne résout pas.
            // `connect_lazy` n'ouvre rien à la construction, mais la première
            // requête, si.
            sqlx::PgPool::connect_lazy("postgres://inutilise/inutilise").unwrap(),
            Arc::new(comptes::MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(comptes::MemoireObjets::new()),
            Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
        );
        let app = atest::init_service(
            App::new()
                .app_data(web::Data::new(depot))
                .configure(mount_dev(false, Some(Arc::new(SmsTraces::new())))),
        )
        .await;

        let req = atest::TestRequest::get()
            .uri("/dev/otp?telephone=%2B2250701020304&zone=00000000-0000-0000-0000-000000000000")
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_ne!(
            resp.status(),
            StatusCode::NOT_FOUND,
            "hors production, la route doit être montée",
        );
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

    /// T009 — double seed du jeu Tiassalé → état strictement identique (SC-008).
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_zones_idempotent(pool: sqlx::PgPool) {
        type Etat = (
            i64,
            i64,
            i64,
            i64,
            i64,
            Option<serde_json::Value>,
            Option<serde_json::Value>,
        );
        async fn etat(pool: &sqlx::PgPool) -> Etat {
            async fn compter(pool: &sqlx::PgPool, sql: &'static str) -> i64 {
                sqlx::query_scalar(sql).fetch_one(pool).await.unwrap()
            }
            async fn valeur(pool: &sqlx::PgPool, cle: &str) -> Option<serde_json::Value> {
                sqlx::query_scalar("SELECT valeur FROM zones.parametre_zone WHERE cle = $1")
                    .bind(cle)
                    .fetch_optional(pool)
                    .await
                    .unwrap()
            }
            (
                compter(pool, "SELECT count(*) FROM zones.zone").await,
                compter(pool, "SELECT count(*) FROM zones.type_transport").await,
                compter(pool, "SELECT count(*) FROM zones.categorie").await,
                compter(pool, "SELECT count(*) FROM zones.activation_categorie").await,
                compter(pool, "SELECT count(*) FROM zones.parametre_zone").await,
                valeur(pool, "categorie.restauration.mixable").await,
                valeur(pool, "categorie.restauration.seuil_activation").await,
            )
        }

        charger_seeds(&pool).await.unwrap();
        let apres_un = etat(&pool).await;
        charger_seeds(&pool).await.unwrap();
        let apres_deux = etat(&pool).await;

        assert_eq!(
            apres_un, apres_deux,
            "double seed → état strictement identique"
        );
        assert_eq!(apres_un.0, 2, "CI + Tiassalé");
        assert_eq!(apres_un.1, 8, "8 types de transport");
        assert_eq!(apres_un.2, 6, "6 catégories");
        assert_eq!(apres_un.3, 6, "6 activations Tiassalé");
        // 8 (pays, cycle 002) + 4 (pays, cycle 003 : indicatif, rétention du
        // repère vocal, durée max de note vocale, version ARTCI) + 8 (pays,
        // cycle 005 : fuseau, conservation charte, 6 affichages de rupture)
        // + 10 (ville, cycles 002/003) + 2 (ville, cycle 005 : seuil et
        // fenêtre du masquage automatique).
        assert_eq!(apres_un.4, 32, "20 (pays) + 12 (ville) paramètres");
        assert_eq!(
            apres_un.5,
            Some(serde_json::json!(false)),
            "restauration non mixable"
        );
        assert_eq!(
            apres_un.6,
            Some(serde_json::json!(8)),
            "seuil restauration 8"
        );
    }

    /// T009 — double seed du module comptes → état strictement identique
    /// (SC-008), et le premier admin est bien amorcé hors parcours applicatif.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_comptes_idempotent(pool: sqlx::PgPool) {
        const ADMIN: &str = "01900000-0000-7000-8000-000000000401";

        /// Comptes, attributions, et les colonnes qu'un `now()` mal placé dans
        /// le seed ferait dériver à chaque exécution.
        type Etat = (i64, i64, String, chrono::DateTime<chrono::Utc>);
        async fn etat(pool: &sqlx::PgPool) -> Etat {
            let comptes: i64 = sqlx::query_scalar("SELECT count(*) FROM comptes.compte")
                .fetch_one(pool)
                .await
                .unwrap();
            let attributions: i64 =
                sqlx::query_scalar("SELECT count(*) FROM comptes.attribution_role")
                    .fetch_one(pool)
                    .await
                    .unwrap();
            let (telephone, consentement_le): (String, chrono::DateTime<chrono::Utc>) =
                sqlx::query_as("SELECT telephone_e164, consentement_le FROM comptes.compte WHERE id = $1::uuid")
                    .bind(ADMIN)
                    .fetch_one(pool)
                    .await
                    .unwrap();
            (comptes, attributions, telephone, consentement_le)
        }

        charger_seeds(&pool).await.unwrap();
        let apres_un = etat(&pool).await;
        charger_seeds(&pool).await.unwrap();
        let apres_deux = etat(&pool).await;

        assert_eq!(
            apres_un, apres_deux,
            "double seed → état strictement identique (horodatages figés compris)"
        );
        assert_eq!(apres_un.0, 1, "le seul compte est le premier admin");
        assert_eq!(apres_un.1, 2, "ses rôles : client + admin");

        // FR-012 — c'est le seed, et lui seul, qui amorce la chaîne des admins.
        // Colonne QUALIFIÉE : tri par l'énum (client, coursier, vendeur, admin)
        // et non par le texte de la colonne de sortie — cf. depot.rs.
        let roles: Vec<String> = sqlx::query_scalar(
            "SELECT role::text FROM comptes.attribution_role
             WHERE compte_id = $1::uuid AND statut = 'valide'
             ORDER BY attribution_role.role",
        )
        .bind(ADMIN)
        .fetch_all(&pool)
        .await
        .unwrap();
        assert_eq!(
            roles,
            vec!["client", "admin"],
            "les deux rôles sont VALIDES"
        );

        // Aucun événement outbox : un chargement n'est pas une transition.
        let evenements: i64 = sqlx::query_scalar(
            "SELECT count(*) FROM outbox.evenement WHERE type_evenement LIKE 'compte.%'
                OR type_evenement LIKE 'role.%'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(evenements, 0, "le seed n'émet aucun événement");
    }

    /// FR-024 — les paramètres du module sont posés au PAYS et hérités par
    /// Tiassalé : rien de tout cela n'a le droit d'être en dur dans le code.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_comptes_parametres_herites_par_tiassale(pool: sqlx::PgPool) {
        use zones::ConfigurationZones;
        charger_seeds(&pool).await.unwrap();

        let tiassale: uuid::Uuid = "01900000-0000-7000-8000-000000000002".parse().unwrap();
        let depot = zones::PgZones::new(pool.clone());

        for (cle, attendu) in [
            ("telephone.indicatif_defaut", serde_json::json!("+225")),
            (
                "adresse.retention_repere_vocal_jours",
                serde_json::json!(365),
            ),
            ("medias.note_vocale_duree_max_s", serde_json::json!(30)),
            ("consentement.artci_version", serde_json::json!("2026-07")),
        ] {
            assert_eq!(
                depot.parametre(tiassale, cle).await.unwrap(),
                Some(attendu),
                "« {cle} » doit être résolu à Tiassalé par héritage du pays"
            );
        }
    }

    /// Le numéro du premier admin doit être RÉELLEMENT utilisable : c'est par
    /// OTP sur ce numéro que l'admin obtient son jeton (quickstart SC-005). Un
    /// placeholder non normalisable rendrait l'admin inaccessible — sans qu'un
    /// seul test ne le signale.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_admin_a_un_numero_utilisable(pool: sqlx::PgPool) {
        charger_seeds(&pool).await.unwrap();
        let tiassale: uuid::Uuid = "01900000-0000-7000-8000-000000000002".parse().unwrap();
        let telephone: String = sqlx::query_scalar(
            "SELECT telephone_e164 FROM comptes.compte
             WHERE id = '01900000-0000-7000-8000-000000000401'::uuid",
        )
        .fetch_one(&pool)
        .await
        .unwrap();

        let normalise =
            comptes::otp::normaliser_e164(&zones::PgZones::new(pool.clone()), tiassale, &telephone)
                .await
                .expect("le numéro du premier admin doit passer la normalisation E.164");
        assert_eq!(normalise, telephone, "déjà en forme canonique");
    }
}
