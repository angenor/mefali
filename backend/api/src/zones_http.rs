//! Surface HTTP du domaine zones (cycle 002) : forçage admin de catégorie
//! (ZON-02, écriture) et configuration produit publique (ZON-04, lecture — T015).
//!
//! ⚠ La garde `AdminAuth` (X-Admin-Token) du cycle 002 a été SUPPRIMÉE au cycle
//! CPT, comme prévu à son research R5 : `forcer_categorie` prend désormais
//! l'extracteur `Auth` + `exiger_role(Admin)` sans que sa logique change — c'est
//! précisément ce que l'isolation de la garde devait permettre.
//!
//! Les DTO du contrat (schémas utoipa) vivent ICI, dans la couche API ; le crate
//! `zones` reste un domaine pur. Toute chaîne d'erreur utilisateur est une clé
//! i18n fr (`message_cle`, constitution VII).

use std::collections::BTreeMap;
use std::fmt;

use actix_governor::governor::middleware::NoOpMiddleware;
use actix_governor::{GovernorConfig, GovernorConfigBuilder, PeerIpKeyExtractor};
use actix_web::http::{header, StatusCode};
use actix_web::{get, put, web, HttpRequest, HttpResponse, ResponseError};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::PgPool;
use utoipa::ToSchema;
use uuid::Uuid;

use zones::{ConfigurationZones, Forcage, PgZones};

// ── Erreurs HTTP (corps JSON { code, message_cle } — i18n fr) ───────────────

/// Erreur d'API rendue en `{ code, message_cle }` (clé i18n fr, jamais de
/// message en dur — constitution VII).
#[derive(Debug)]
pub(crate) enum ErreurApi {
    /// 404 — zone inconnue.
    ZoneInconnue,
    /// 404 — catégorie inconnue.
    CategorieInconnue,
    /// 400 — paramètre de requête absent ou invalide.
    ParametreManquant,
    /// 422 — corps de requête invalide.
    CorpsInvalide,
    /// 500 — erreur interne (SQL, configuration).
    Interne,
}

impl ErreurApi {
    fn statut(&self) -> StatusCode {
        match self {
            ErreurApi::ZoneInconnue | ErreurApi::CategorieInconnue => StatusCode::NOT_FOUND,
            ErreurApi::ParametreManquant => StatusCode::BAD_REQUEST,
            ErreurApi::CorpsInvalide => StatusCode::UNPROCESSABLE_ENTITY,
            ErreurApi::Interne => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn code(&self) -> &'static str {
        match self {
            ErreurApi::ZoneInconnue => "zone_inconnue",
            ErreurApi::CategorieInconnue => "categorie_inconnue",
            ErreurApi::ParametreManquant => "parametre_zone_manquant",
            ErreurApi::CorpsInvalide => "corps_invalide",
            ErreurApi::Interne => "erreur_interne",
        }
    }

    fn message_cle(&self) -> &'static str {
        match self {
            ErreurApi::ZoneInconnue => "zones.erreur.zone_inconnue",
            ErreurApi::CategorieInconnue => "zones.erreur.categorie_inconnue",
            ErreurApi::ParametreManquant => "zones.erreur.parametre_zone_manquant",
            ErreurApi::CorpsInvalide => "zones.erreur.corps_invalide",
            ErreurApi::Interne => "zones.erreur.interne",
        }
    }
}

impl fmt::Display for ErreurApi {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.code())
    }
}

impl ResponseError for ErreurApi {
    fn status_code(&self) -> StatusCode {
        self.statut()
    }
    fn error_response(&self) -> HttpResponse {
        HttpResponse::build(self.statut())
            .json(json!({ "code": self.code(), "message_cle": self.message_cle() }))
    }
}

impl From<zones::ErreurZones> for ErreurApi {
    fn from(erreur: zones::ErreurZones) -> Self {
        use zones::ErreurZones as E;
        match erreur {
            E::ZoneInconnue(_) => ErreurApi::ZoneInconnue,
            E::CategorieInconnue(_) => ErreurApi::CategorieInconnue,
            E::ValeurInvalide { .. } | E::CycleDetecte => ErreurApi::CorpsInvalide,
            E::DeviseIrresolvable(_) | E::Sql(_) => ErreurApi::Interne,
        }
    }
}

impl From<sqlx::Error> for ErreurApi {
    fn from(_: sqlx::Error) -> Self {
        ErreurApi::Interne
    }
}

/// `JsonConfig` : une erreur de désérialisation du corps → 422 `corps_invalide`
/// (ex. `forcage` hors énumération), plutôt que le 400 par défaut d'Actix.
pub(crate) fn config_json() -> web::JsonConfig {
    web::JsonConfig::default().error_handler(|_err, _req| ErreurApi::CorpsInvalide.into())
}

// ── DTO du contrat ──────────────────────────────────────────────────────────

/// Mode de forçage (contrat) — mappé sur [`zones::Forcage`].
#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub(crate) enum ForcageDto {
    /// L'état suit la règle du seuil.
    Automatique,
    /// Forcé actif.
    ForceActif,
    /// Forcé inactif.
    ForceInactif,
}

impl From<ForcageDto> for Forcage {
    fn from(f: ForcageDto) -> Self {
        match f {
            ForcageDto::Automatique => Forcage::Automatique,
            ForcageDto::ForceActif => Forcage::ForceActif,
            ForcageDto::ForceInactif => Forcage::ForceInactif,
        }
    }
}

impl From<Forcage> for ForcageDto {
    fn from(f: Forcage) -> Self {
        match f {
            Forcage::Automatique => ForcageDto::Automatique,
            Forcage::ForceActif => ForcageDto::ForceActif,
            Forcage::ForceInactif => ForcageDto::ForceInactif,
        }
    }
}

/// Corps de la requête de forçage.
#[derive(Debug, Deserialize, ToSchema)]
pub(crate) struct CorpsForcage {
    /// Nouveau mode de forçage à appliquer.
    forcage: ForcageDto,
}

/// État effectif d'une catégorie renvoyé après forçage (contrat).
#[derive(Debug, Serialize, ToSchema)]
pub(crate) struct EtatCategorie {
    /// Ville concernée.
    zone: Uuid,
    /// Slug de la catégorie.
    categorie: String,
    /// Mode de forçage appliqué.
    forcage: ForcageDto,
    /// État EFFECTIF après application.
    actif: bool,
}

impl From<zones::EtatCategorie> for EtatCategorie {
    fn from(e: zones::EtatCategorie) -> Self {
        EtatCategorie {
            zone: e.zone,
            categorie: e.categorie,
            forcage: e.forcage.into(),
            actif: e.actif,
        }
    }
}

// ── Handler : PUT forçage (SEULE écriture admin du cycle) ───────────────────

/// Force l'état d'une catégorie dans une ville (ZON-02). Journalisé via outbox
/// (categorie.forcage_change + categorie.activation_changee si bascule) dans la
/// même transaction.
#[utoipa::path(
    put,
    path = "/admin/zones/{zone_id}/categories/{categorie_slug}/forcage",
    tag = "zones",
    params(
        ("zone_id" = Uuid, Path, description = "Ville dont on force la catégorie."),
        ("categorie_slug" = String, Path, description = "Slug de la catégorie."),
    ),
    request_body = CorpsForcage,
    responses(
        (status = 200, description = "Nouveau mode appliqué ; état effectif.", body = EtatCategorie),
        (status = 401, description = "Session absente, invalide ou révoquée."),
        (status = 403, description = "Rôle admin requis."),
        (status = 404, description = "Zone ou catégorie inconnue."),
        (status = 422, description = "Corps invalide (forcage hors énumération)."),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/admin/zones/{zone_id}/categories/{categorie_slug}/forcage")]
pub async fn forcer_categorie(
    auth: crate::auth_http::Auth,
    chemin: web::Path<(Uuid, String)>,
    corps: web::Json<CorpsForcage>,
    pool: web::Data<PgPool>,
    // `actix_web::Error` plutôt que `ErreurApi` : le 403 « rôle requis » est une
    // erreur du module comptes (clé i18n `comptes.erreur.role_requis`), pas de
    // zones. Chaque module garde ses clés ; les deux savent se rendre en HTTP.
) -> Result<HttpResponse, actix_web::Error> {
    auth.exiger_role(comptes::Role::Admin)?;
    let (zone_id, categorie_slug) = chemin.into_inner();
    let depot = PgZones::new(pool.get_ref().clone());

    let mut tx = pool.begin().await.map_err(ErreurApi::from)?;
    let etat = depot
        .forcer_categorie(
            &mut tx,
            zone_id,
            &categorie_slug,
            corps.forcage.into(),
            &auth.compte_id.to_string(),
        )
        .await
        .map_err(ErreurApi::from)?;
    tx.commit().await.map_err(ErreurApi::from)?;

    Ok(HttpResponse::Ok().json(EtatCategorie::from(etat)))
}

// ── Configuration produit publique : GET /config?zone= (ZON-04) ─────────────

/// Configuration du rate-limit de `/config` (par IP, en mémoire de processus —
/// research R4) : `burst` requêtes immédiates, recharge d'une toutes les
/// `intervalle_ms` millisecondes.
pub(crate) fn config_governor(
    burst: u32,
    intervalle_ms: u64,
) -> GovernorConfig<PeerIpKeyExtractor, NoOpMiddleware> {
    GovernorConfigBuilder::default()
        .milliseconds_per_request(intervalle_ms)
        .burst_size(burst)
        .finish()
        .expect("configuration governor valide")
}

/// `QueryConfig` : paramètre `zone` absent ou invalide → 400 (clé i18n).
pub(crate) fn config_query() -> web::QueryConfig {
    web::QueryConfig::default().error_handler(|_err, _req| ErreurApi::ParametreManquant.into())
}

/// Devise (contrat) — montants entiers en unités mineures (principe III).
#[derive(Debug, Serialize, ToSchema)]
struct DeviseDto {
    /// Code ISO 4217 (ex. XOF).
    code: String,
    /// Nombre de décimales des unités mineures (0 pour XOF).
    decimales: u8,
}

/// Catégorie active (contrat).
#[derive(Debug, Serialize, ToSchema)]
struct CategorieDto {
    /// Slug de la catégorie.
    slug: String,
    /// Clé i18n fr du nom.
    nom_cle: String,
    /// Mixable au panier (CMD-01).
    mixable: bool,
}

/// Document `/config` (contrat) — sous-ensemble public de la config effective.
#[derive(Debug, Serialize, ToSchema)]
struct ConfigZone {
    /// Zone servie.
    zone: Uuid,
    /// Empreinte SHA-256 hex du document canonique (= ETag).
    version: String,
    /// Devise résolue.
    devise: DeviseDto,
    /// Drapeaux (clés `drapeau.*` sans préfixe).
    drapeaux: BTreeMap<String, bool>,
    /// Catégories actives dans la zone.
    categories: Vec<CategorieDto>,
    /// Slugs des types de transport actifs.
    transports_actifs: Vec<String>,
    /// Durée maximale d'une note vocale, en secondes — borne l'enregistreur des
    /// apps (FR-019). `null` si la zone ne la résout pas.
    note_vocale_duree_max_s: Option<i64>,
    /// Textes (clés `texte.*` sans préfixe) — clés i18n fr.
    textes: BTreeMap<String, String>,
    /// Paramètres client (clés `client.*` sans préfixe).
    #[schema(value_type = Object)]
    parametres: BTreeMap<String, serde_json::Value>,
}

impl From<zones::ConfigZonePublique> for ConfigZone {
    fn from(d: zones::ConfigZonePublique) -> Self {
        ConfigZone {
            zone: d.zone,
            version: d.version,
            devise: DeviseDto {
                code: d.devise.code,
                decimales: d.devise.decimales,
            },
            drapeaux: d.drapeaux,
            categories: d
                .categories
                .into_iter()
                .map(|c| CategorieDto {
                    slug: c.slug,
                    nom_cle: c.nom_cle,
                    mixable: c.mixable,
                })
                .collect(),
            transports_actifs: d.transports_actifs,
            note_vocale_duree_max_s: d.note_vocale_duree_max_s,
            textes: d.textes,
            parametres: d.parametres,
        }
    }
}

/// Paramètre de requête de `/config`.
#[derive(Debug, Deserialize)]
struct ConfigQuery {
    zone: Uuid,
}

/// Configuration produit publique d'une zone (ZON-04). PUBLIC en lecture seule
/// (clarification Q1), liste blanche de namespaces (R4), versionnée par ETag
/// (304 sur If-None-Match — polling horaire économe).
#[utoipa::path(
    get,
    path = "/config",
    tag = "zones",
    params(("zone" = Uuid, Query, description = "Zone dont on veut la configuration effective.")),
    responses(
        (status = 200, description = "Configuration effective résolue.", body = ConfigZone),
        (status = 304, description = "Non modifiée (If-None-Match == version)."),
        (status = 400, description = "Paramètre zone absent ou UUID invalide."),
        (status = 404, description = "Zone inconnue — erreur explicite, jamais une config vide."),
        (status = 429, description = "Rate-limit dépassé."),
    ),
)]
#[get("/config")]
pub async fn config(
    requete: HttpRequest,
    zone: web::Query<ConfigQuery>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, ErreurApi> {
    let zone = zone.zone;
    let depot = PgZones::new(pool.get_ref().clone());

    // configuration_effective valide l'existence (404 si zone inconnue — FR-021).
    let config = depot.configuration_effective(zone).await?;
    let devise = depot.devise(zone).await?;
    let categories = depot.categories_actives(zone).await?;
    let transports = depot.transports_actifs(zone).await?;
    let document = zones::assembler(&config, devise, categories, transports);

    // 304 si le client détient déjà cette version.
    if let Some(entrant) = requete
        .headers()
        .get(header::IF_NONE_MATCH)
        .and_then(|v| v.to_str().ok())
    {
        if etag_correspond(entrant, &document.version) {
            return Ok(HttpResponse::NotModified()
                .insert_header((header::ETAG, document.version))
                .finish());
        }
    }

    let dto = ConfigZone::from(document);
    Ok(HttpResponse::Ok()
        .insert_header((header::ETAG, dto.version.clone()))
        .json(dto))
}

/// Compare un en-tête `If-None-Match` (guillemets ou préfixe `W/` tolérés) à la
/// version ; `*` correspond toujours.
fn etag_correspond(entrant: &str, version: &str) -> bool {
    entrant.split(',').any(|etag| {
        let e = etag.trim().trim_start_matches("W/").trim_matches('"');
        e == version || e == "*"
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    use actix_web::{test as atest, App};
    use comptes::{Appareil, MemoireEphemere, MemoireObjets, PgComptes, Plateforme, SmsTraces};

    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";
    /// Premier admin du seed `20_comptes.sql`.
    const ADMIN: &str = "01900000-0000-7000-8000-000000000401";
    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    async fn preparer(pool: &PgPool) -> PgComptes {
        crate::charger_seeds(pool).await.unwrap();
        PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(MemoireObjets::new()),
            Arc::from(SECRET),
        )
    }

    /// Ouvre une session pour un compte et renvoie son jeton d'accès.
    async fn jeton(depot: &PgComptes, compte: Uuid) -> String {
        let zone = depot.compte(compte).await.unwrap().zone_id;
        let mut tx = depot.pool().begin().await.unwrap();
        let (_, jetons) = depot
            .creer_session(
                &mut tx,
                compte,
                zone,
                &Appareil {
                    nom: "Console admin".to_owned(),
                    plateforme: Plateforme::Android,
                },
                comptes::OrigineSession::VerificationOtp,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        jetons.acces
    }

    /// Jeton d'un compte SANS rôle admin — pour prouver le 403.
    async fn jeton_client(depot: &PgComptes, pool: &PgPool) -> String {
        let zone: Uuid = TIASSALE.parse().unwrap();
        let mut tx = pool.begin().await.unwrap();
        let compte = depot
            .creer_compte(&mut tx, "+2250709080706", zone, "2026-07")
            .await
            .unwrap();
        tx.commit().await.unwrap();
        jeton(depot, compte.id).await
    }

    macro_rules! app {
        ($pool:expr, $depot:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($pool.clone()))
                    .app_data(web::Data::new($depot.clone()))
                    .app_data(config_json())
                    .service(forcer_categorie),
            )
            .await
        };
    }

    /// R5 — le forçage passe désormais sous JWT + rôle admin, sans que la
    /// logique du handler ait changé (contrat passé au cycle 002).
    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_200_avec_jwt_admin(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(pool, depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;

        let req = atest::TestRequest::put()
            .uri(&format!(
                "/admin/zones/{TIASSALE}/categories/marche/forcage"
            ))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["categorie"], "marche");
        assert_eq!(corps["forcage"], "force_actif");
        assert_eq!(corps["actif"], true);

        // ADM-05 — l'acteur journalisé est le COMPTE décideur, plus la chaîne
        // « admin » : le journal doit dire QUI, pas « quelqu'un d'admin ».
        let acteur: String = sqlx::query_scalar(
            "SELECT payload->>'acteur' FROM outbox.evenement
             WHERE type_evenement = 'categorie.forcage_change'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(acteur, ADMIN);
    }

    /// Un compte authentifié SANS rôle admin est refusé (FR-009, SC-005).
    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_403_sans_role_admin(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(pool, depot);
        let acces = jeton_client(&depot, &pool).await;

        let req = atest::TestRequest::put()
            .uri(&format!(
                "/admin/zones/{TIASSALE}/categories/marche/forcage"
            ))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.role_requis");
    }

    /// L'ANCIENNE garde est bel et bien morte : un X-Admin-Token, quel qu'il
    /// soit, ne vaut plus rien. Sans ce test, la garde pourrait survivre en
    /// double sans que personne ne s'en aperçoive.
    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_401_avec_ancien_x_admin_token(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(pool, depot);

        let req = atest::TestRequest::put()
            .uri(&format!(
                "/admin/zones/{TIASSALE}/categories/marche/forcage"
            ))
            .insert_header(("X-Admin-Token", "jeton-test-admin"))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_401_sans_jeton(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(pool, depot);
        let req = atest::TestRequest::put()
            .uri(&format!(
                "/admin/zones/{TIASSALE}/categories/marche/forcage"
            ))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.non_authentifie");
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_404_categorie_inconnue(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(pool, depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let req = atest::TestRequest::put()
            .uri(&format!(
                "/admin/zones/{TIASSALE}/categories/inexistante/forcage"
            ))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["code"], "categorie_inconnue");
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_422_corps_invalide(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(pool, depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let req = atest::TestRequest::put()
            .uri(&format!(
                "/admin/zones/{TIASSALE}/categories/marche/forcage"
            ))
            .insert_header(("authorization", format!("Bearer {acces}")))
            .set_json(json!({ "forcage": "n_importe_quoi" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }

    macro_rules! app_config {
        ($pool:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($pool.clone()))
                    .app_data(config_query())
                    .service(config),
            )
            .await
        };
    }

    /// SC-003 — une consultation restitue exactement la config de Tiassalé.
    #[sqlx::test(migrations = "../migrations")]
    async fn config_200_sc003(pool: PgPool) {
        let _ = preparer(&pool).await;
        let app = app_config!(pool);
        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri(&format!("/config?zone={TIASSALE}"))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::OK);
        let etag = resp
            .headers()
            .get(header::ETAG)
            .and_then(|v| v.to_str().ok())
            .map(str::to_owned);
        let corps: serde_json::Value = atest::read_body_json(resp).await;

        assert_eq!(corps["devise"]["code"], "XOF");
        assert_eq!(corps["devise"]["decimales"], 0);
        assert_eq!(corps["drapeaux"]["livraison_offerte_mefali"], true);
        assert_eq!(corps["drapeaux"]["gratuite_commissions"], true);
        assert_eq!(corps["drapeaux"]["pluie"], false);
        assert_eq!(
            corps["transports_actifs"],
            json!(["a_pied", "velo", "moto"])
        );
        assert_eq!(
            corps["categories"],
            json!([]),
            "aucun vendeur → aucune catégorie active"
        );
        let version = corps["version"].as_str().unwrap();
        assert!(!version.is_empty());
        assert_eq!(etag.as_deref(), Some(version), "ETag == version");
        // Liste blanche : aucun namespace interne ne fuit.
        assert!(!corps.to_string().contains("seuil_activation"));
    }

    /// Zone inconnue → 404 explicite (FR-021), jamais une config vide.
    #[sqlx::test(migrations = "../migrations")]
    async fn config_404_zone_inconnue(pool: PgPool) {
        let _ = preparer(&pool).await;
        let app = app_config!(pool);
        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri("/config?zone=00000000-0000-7000-8000-00000000dead")
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["code"], "zone_inconnue");
    }

    /// If-None-Match == version → 304 (polling horaire économe).
    #[sqlx::test(migrations = "../migrations")]
    async fn config_304_if_none_match(pool: PgPool) {
        let _ = preparer(&pool).await;
        let app = app_config!(pool);
        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri(&format!("/config?zone={TIASSALE}"))
                .to_request(),
        )
        .await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        let version = corps["version"].as_str().unwrap().to_owned();

        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri(&format!("/config?zone={TIASSALE}"))
                .insert_header((header::IF_NONE_MATCH, version))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::NOT_MODIFIED);
    }

    /// Paramètre `zone` absent ou UUID invalide → 400.
    #[sqlx::test(migrations = "../migrations")]
    async fn config_400_zone_invalide(pool: PgPool) {
        let _ = preparer(&pool).await;
        let app = app_config!(pool);
        for uri in ["/config", "/config?zone=pas-un-uuid"] {
            let resp =
                atest::call_service(&app, atest::TestRequest::get().uri(uri).to_request()).await;
            assert_eq!(resp.status(), StatusCode::BAD_REQUEST, "uri = {uri}");
        }
    }

    /// Rate-limit par IP : 2e requête rapide de la même IP → 429.
    #[sqlx::test(migrations = "../migrations")]
    async fn config_429_rate_limit(pool: PgPool) {
        let _ = preparer(&pool).await;
        let gouverneur = config_governor(1, 60_000);
        let app = atest::init_service(
            App::new()
                .app_data(web::Data::new(pool.clone()))
                .wrap(actix_governor::Governor::new(&gouverneur))
                .service(config),
        )
        .await;
        let requete = || {
            atest::TestRequest::get()
                .uri(&format!("/config?zone={TIASSALE}"))
                .peer_addr("1.2.3.4:9000".parse().unwrap())
                .to_request()
        };
        let r1 = atest::call_service(&app, requete()).await;
        assert_eq!(r1.status(), StatusCode::OK);
        let r2 = atest::call_service(&app, requete()).await;
        assert_eq!(r2.status(), StatusCode::TOO_MANY_REQUESTS);
    }
}
