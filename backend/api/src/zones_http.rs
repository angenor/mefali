//! Surface HTTP du domaine zones (cycle 002) : forçage admin de catégorie
//! (ZON-02, écriture) et configuration produit publique (ZON-04, lecture — T015).
//!
//! Les DTO du contrat (schémas utoipa) vivent ICI, dans la couche API ; le crate
//! `zones` reste un domaine pur. Toute chaîne d'erreur utilisateur est une clé
//! i18n fr (`message_cle`, constitution VII).

use std::fmt;
use std::future::{ready, Ready};

use actix_web::dev::Payload;
use actix_web::http::StatusCode;
use actix_web::{put, web, FromRequest, HttpRequest, HttpResponse, ResponseError};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::PgPool;
use utoipa::ToSchema;
use uuid::Uuid;

use zones::{Forcage, PgZones};

// ── Erreurs HTTP (corps JSON { code, message_cle } — i18n fr) ───────────────

/// Erreur d'API rendue en `{ code, message_cle }` (clé i18n fr, jamais de
/// message en dur — constitution VII).
#[derive(Debug)]
pub(crate) enum ErreurApi {
    /// 401 — jeton admin absent ou invalide.
    NonAutorise,
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
            ErreurApi::NonAutorise => StatusCode::UNAUTHORIZED,
            ErreurApi::ZoneInconnue | ErreurApi::CategorieInconnue => StatusCode::NOT_FOUND,
            ErreurApi::ParametreManquant => StatusCode::BAD_REQUEST,
            ErreurApi::CorpsInvalide => StatusCode::UNPROCESSABLE_ENTITY,
            ErreurApi::Interne => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn code(&self) -> &'static str {
        match self {
            ErreurApi::NonAutorise => "non_autorise",
            ErreurApi::ZoneInconnue => "zone_inconnue",
            ErreurApi::CategorieInconnue => "categorie_inconnue",
            ErreurApi::ParametreManquant => "parametre_zone_manquant",
            ErreurApi::CorpsInvalide => "corps_invalide",
            ErreurApi::Interne => "erreur_interne",
        }
    }

    fn message_cle(&self) -> &'static str {
        match self {
            ErreurApi::NonAutorise => "zones.erreur.non_autorise",
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

// ── Garde admin temporaire (research R5, remplacée par JWT au cycle CPT) ─────

/// Extracteur validant l'en-tête `X-Admin-Token` contre `ADMIN_API_TOKEN`
/// (comparaison à temps constant). Isolé pour que le cycle CPT remplace la
/// stratégie d'authentification sans toucher aux handlers.
pub(crate) struct AdminAuth;

impl FromRequest for AdminAuth {
    type Error = actix_web::Error;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _payload: &mut Payload) -> Self::Future {
        let attendu = std::env::var("ADMIN_API_TOKEN").unwrap_or_default();
        let fourni = req
            .headers()
            .get("X-Admin-Token")
            .and_then(|v| v.to_str().ok())
            .unwrap_or_default();
        let ok = !attendu.is_empty()
            && egalite_temps_constant(attendu.as_bytes(), fourni.as_bytes());
        ready(if ok {
            Ok(AdminAuth)
        } else {
            Err(ErreurApi::NonAutorise.into())
        })
    }
}

/// Égalité d'octets à temps constant (indépendant du contenu ; la longueur peut
/// différer tôt — un jeton n'est pas un secret de longueur variable sensible).
fn egalite_temps_constant(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (x, y) in a.iter().zip(b.iter()) {
        diff |= x ^ y;
    }
    diff == 0
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
        (status = 401, description = "Jeton admin absent ou invalide."),
        (status = 404, description = "Zone ou catégorie inconnue."),
        (status = 422, description = "Corps invalide (forcage hors énumération)."),
    ),
    security(("adminToken" = [])),
)]
#[put("/admin/zones/{zone_id}/categories/{categorie_slug}/forcage")]
pub async fn forcer_categorie(
    _admin: AdminAuth,
    chemin: web::Path<(Uuid, String)>,
    corps: web::Json<CorpsForcage>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, ErreurApi> {
    let (zone_id, categorie_slug) = chemin.into_inner();
    let depot = PgZones::new(pool.get_ref().clone());

    let mut tx = pool.begin().await?;
    let etat = depot
        .forcer_categorie(&mut tx, zone_id, &categorie_slug, corps.forcage.into(), "admin")
        .await?;
    tx.commit().await?;

    Ok(HttpResponse::Ok().json(EtatCategorie::from(etat)))
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test as atest, App};

    const JETON: &str = "jeton-test-admin";
    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";

    async fn preparer(pool: &PgPool) {
        crate::charger_seeds(pool).await.unwrap();
        std::env::set_var("ADMIN_API_TOKEN", JETON);
    }

    macro_rules! app {
        ($pool:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($pool.clone()))
                    .app_data(config_json())
                    .service(forcer_categorie),
            )
            .await
        };
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_200(pool: PgPool) {
        preparer(&pool).await;
        let app = app!(pool);
        let req = atest::TestRequest::put()
            .uri(&format!("/admin/zones/{TIASSALE}/categories/marche/forcage"))
            .insert_header(("X-Admin-Token", JETON))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["categorie"], "marche");
        assert_eq!(corps["forcage"], "force_actif");
        assert_eq!(corps["actif"], true);
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_401_sans_jeton(pool: PgPool) {
        preparer(&pool).await;
        let app = app!(pool);
        let req = atest::TestRequest::put()
            .uri(&format!("/admin/zones/{TIASSALE}/categories/marche/forcage"))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "zones.erreur.non_autorise");
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_404_categorie_inconnue(pool: PgPool) {
        preparer(&pool).await;
        let app = app!(pool);
        let req = atest::TestRequest::put()
            .uri(&format!("/admin/zones/{TIASSALE}/categories/inexistante/forcage"))
            .insert_header(("X-Admin-Token", JETON))
            .set_json(json!({ "forcage": "force_actif" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["code"], "categorie_inconnue");
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn forcage_422_corps_invalide(pool: PgPool) {
        preparer(&pool).await;
        let app = app!(pool);
        let req = atest::TestRequest::put()
            .uri(&format!("/admin/zones/{TIASSALE}/categories/marche/forcage"))
            .insert_header(("X-Admin-Token", JETON))
            .set_json(json!({ "forcage": "n_importe_quoi" }))
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }
}
