//! Surface HTTP du cycle QRC (crate `qr`) : téléchargement du PDF de plaque
//! (admin), course active + pré-provisionnement, et collecte d'un arrêt
//! (coursier). Contrat auto-collecté par utoipa-actix-web (patron
//! `prestataires_http`). Toute route sous `bearerAuth`. Erreurs rendues
//! `{ code, message_cle }` (clés i18n fr).

use actix_multipart::form::{bytes::Bytes as ChampFichier, text::Text, MultipartForm};
use actix_web::http::StatusCode;
use actix_web::{get, post, web, HttpResponse, ResponseError};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::json;
use utoipa::ToSchema;
use uuid::Uuid;

use commandes::ModeCollecte;
use comptes::Role;
use qr::{ArretPreProvisionne, DemandeCollecte, ErreurQr, PgQr, ResultatCollecte};

use crate::auth_http::{Auth, ErreurApi, ErreurApiDto};

// ── Erreur HTTP locale ─────────────────────────────────────────────────────

/// Erreur HTTP du module QR : auth/rôle (`ErreurApi`) ou domaine (`ErreurQr`).
#[derive(Debug)]
pub enum ErreurQrHttp {
    /// Erreur d'authentification / de rôle (réutilise le mapping comptes).
    Api(ErreurApi),
    /// Refus métier ou erreur d'infrastructure du domaine QR.
    Qr(ErreurQr),
}

impl From<ErreurApi> for ErreurQrHttp {
    fn from(e: ErreurApi) -> Self {
        ErreurQrHttp::Api(e)
    }
}

impl From<ErreurQr> for ErreurQrHttp {
    fn from(e: ErreurQr) -> Self {
        ErreurQrHttp::Qr(e)
    }
}

impl std::fmt::Display for ErreurQrHttp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErreurQrHttp::Api(e) => write!(f, "{e}"),
            ErreurQrHttp::Qr(e) => write!(f, "{e}"),
        }
    }
}

/// Statut HTTP d'un refus de domaine QR (contrats §2).
fn statut_qr(e: &ErreurQr) -> StatusCode {
    match e {
        ErreurQr::PlaqueAbsente | ErreurQr::ArretHorsCourse => StatusCode::NOT_FOUND,
        ErreurQr::ArretDejaCollecte | ErreurQr::EtatIncompatible => StatusCode::CONFLICT,
        ErreurQr::HorsZone
        | ErreurQr::PrestataireIndisponible
        | ErreurQr::PlaqueInvalide
        | ErreurQr::PhotoRequise
        | ErreurQr::CodeEpuise
        | ErreurQr::CodeIncorrect
        | ErreurQr::DemandeInvalide(_) => StatusCode::UNPROCESSABLE_ENTITY,
        // Infrastructure (Sql, Objets, Commandes, Prestataires, Zones, Compteur).
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

impl ResponseError for ErreurQrHttp {
    fn status_code(&self) -> StatusCode {
        match self {
            // Délègue au mapping comptes (code/clé i18n privés là-bas).
            ErreurQrHttp::Api(e) => e.status_code(),
            ErreurQrHttp::Qr(e) => statut_qr(e),
        }
    }

    fn error_response(&self) -> HttpResponse {
        match self {
            ErreurQrHttp::Api(e) => e.error_response(),
            ErreurQrHttp::Qr(e) => {
                let (code, message_cle) = match e.message_cle() {
                    Some(cle) => (cle.to_owned(), format!("qr.erreur.{cle}")),
                    None => ("erreur_interne".to_owned(), "qr.erreur.interne".to_owned()),
                };
                HttpResponse::build(statut_qr(e))
                    .json(json!({ "code": code, "message_cle": message_cle }))
            }
        }
    }
}

// ── DTO ────────────────────────────────────────────────────────────────────

/// URL présignée de téléchargement du PDF de plaque (TTL 10 min).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PlaqueUrl)]
pub struct PlaqueUrlDto {
    /// URL présignée de lecture.
    pub url: String,
    /// Expiration de l'URL.
    pub expire_le: DateTime<Utc>,
}

/// Arrêt pré-provisionné (empreintes, jamais de secret).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ArretPreProvisionne)]
pub struct ArretPreProvisionneDto {
    /// Arrêt à collecter.
    pub arret_id: Uuid,
    /// Prestataire visé.
    pub prestataire_id: Uuid,
    /// Nom du prestataire (affiché sur la carte K3).
    pub nom: String,
    /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
    pub empreinte_jeton: String,
    /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
    pub empreinte_code: String,
    /// Position attendue du site.
    pub site_lat: f64,
    /// Position attendue du site.
    pub site_lon: f64,
    /// Montant avancé (unités mineures).
    pub montant_avance: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Photo exigée (politique résolue).
    pub photo_exigee: bool,
    /// Rayon max de scan (m) — validation de proximité hors-ligne.
    pub distance_max_m: i64,
}

impl From<ArretPreProvisionne> for ArretPreProvisionneDto {
    fn from(a: ArretPreProvisionne) -> Self {
        Self {
            arret_id: a.arret_id,
            prestataire_id: a.prestataire_id,
            nom: a.nom,
            empreinte_jeton: a.empreinte_jeton,
            empreinte_code: a.empreinte_code,
            site_lat: a.site_lat,
            site_lon: a.site_lon,
            montant_avance: a.montant_avance,
            devise: a.devise,
            photo_exigee: a.photo_exigee,
            distance_max_m: a.distance_max_m,
        }
    }
}

/// Course active du coursier + arrêts pré-provisionnés.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CourseActive)]
pub struct CourseActiveDto {
    /// Livraison active (première des arrêts), `None` si aucune.
    pub livraison_id: Option<Uuid>,
    /// Arrêts à collecter, avec empreintes.
    pub arrets: Vec<ArretPreProvisionneDto>,
}

/// Mode de collecte (contrat).
#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
#[schema(as = ModeCollecte)]
pub enum ModeCollecteDto {
    /// Scan du QR de la plaque.
    ScanQr,
    /// Saisie du code de secours (mode dégradé).
    CodeSecours,
}

impl From<ModeCollecteDto> for ModeCollecte {
    fn from(m: ModeCollecteDto) -> Self {
        match m {
            ModeCollecteDto::ScanQr => ModeCollecte::ScanQr,
            ModeCollecteDto::CodeSecours => ModeCollecte::CodeSecours,
        }
    }
}

/// Corps de la demande de collecte (partie `demande` JSON du multipart).
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeCollecte)]
pub struct DemandeCollecteDto {
    /// Scan du QR ou saisie du code de secours.
    pub mode: ModeCollecteDto,
    /// Jeton lu dans le QR (mode `scan_qr`).
    pub jeton: Option<String>,
    /// Code à 4 chiffres saisi (mode `code_secours`).
    pub code: Option<String>,
    /// Position capturée du coursier.
    pub position_lat: f64,
    /// Position capturée du coursier.
    pub position_lon: f64,
    /// Clé d'idempotence (UUIDv7 client, V).
    pub uuid_client: Uuid,
    /// Horodatage local de l'action.
    pub horodatage_local: DateTime<Utc>,
}

/// Résultat d'une collecte.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ResultatCollecte)]
pub struct ResultatCollecteDto {
    /// Statut de l'arrêt (`collecte`).
    pub arret_statut: String,
    /// État de la livraison (`en_collecte` | `en_livraison`).
    pub livraison_etat: String,
    /// Arrêts collectés.
    pub nb_collectes: i16,
    /// Total d'arrêts.
    pub nb_arrets: i16,
    /// Vrai si la livraison vient de basculer EN_LIVRAISON.
    pub en_livraison: bool,
}

impl From<ResultatCollecte> for ResultatCollecteDto {
    fn from(r: ResultatCollecte) -> Self {
        Self {
            arret_statut: r.arret_statut.comme_str().to_owned(),
            livraison_etat: r.livraison_etat.comme_str().to_owned(),
            nb_collectes: r.nb_collectes,
            nb_arrets: r.nb_arrets,
            en_livraison: r.en_livraison,
        }
    }
}

/// Schéma OpenAPI du corps multipart de collecte (contrat honnête : le handler
/// lit bien un `multipart/form-data`, pas un JSON — le client généré produit
/// alors un vrai multipart). Sert UNIQUEMENT à `#[utoipa::path]`.
#[derive(ToSchema)]
#[schema(as = CollecteMultipart)]
#[allow(dead_code)]
pub struct CollecteMultipartDto {
    /// Partie JSON `demande` (sérialisée par l'app).
    pub demande: DemandeCollecteDto,
    /// Photo de récupération (binaire), si la politique l'exige.
    #[schema(value_type = Option<String>, format = Binary)]
    pub photo: Option<Vec<u8>>,
}

/// Multipart de collecte : partie `demande` (JSON) + `photo` binaire facultative.
#[derive(Debug, MultipartForm)]
pub struct CollecteForm {
    /// Partie JSON `demande` (sérialisée par l'app).
    demande: Text<String>,
    /// Photo de récupération (si la politique l'exige) — 5 Mo max.
    #[multipart(limit = "5MB")]
    photo: Option<ChampFichier>,
}

// ── Endpoints ──────────────────────────────────────────────────────────────

/// QRC-01 — télécharge (génère au besoin) le PDF de plaque d'un prestataire.
#[utoipa::path(
    get,
    path = "/admin/prestataires/{id}/plaque",
    tag = "qr",
    params(("id" = Uuid, Path, description = "Prestataire agréé porteur d'une identité de plaque.")),
    responses(
        (status = 200, description = "PDF (QR + nom + code) déposé ; URL présignée renvoyée.", body = PlaqueUrlDto),
        (status = 404, description = "Prestataire inconnu ou jamais agréé (FR-011).", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/prestataires/{id}/plaque")]
pub async fn telecharger_plaque(
    auth: Auth,
    chemin: web::Path<Uuid>,
    qr: web::Data<PgQr>,
) -> Result<HttpResponse, ErreurQrHttp> {
    auth.exiger_role(Role::Admin)?;
    let url = qr.plaque_pdf(chemin.into_inner(), auth.compte_id).await?;
    Ok(HttpResponse::Ok().json(PlaqueUrlDto {
        url: url.url,
        expire_le: url.expire_le,
    }))
}

/// QRC-02 — course active du coursier + pré-provisionnement hors-ligne.
#[utoipa::path(
    get,
    path = "/courses/active",
    tag = "qr",
    responses(
        (status = 200, description = "Course active du coursier (vide si aucune assignée).", body = CourseActiveDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/courses/active")]
pub async fn course_active(auth: Auth, qr: web::Data<PgQr>) -> Result<HttpResponse, ErreurQrHttp> {
    auth.exiger_role(Role::Coursier)?;
    let arrets = qr.pre_provisionnement(auth.compte_id).await?;
    let livraison_id = None; // posé par DSP ; les arrêts suffisent au client hors-ligne
    Ok(HttpResponse::Ok().json(CourseActiveDto {
        livraison_id,
        arrets: arrets.into_iter().map(ArretPreProvisionneDto::from).collect(),
    }))
}

/// QRC-02/03/04 — collecte un arrêt (multipart : `demande` JSON + `photo`).
#[utoipa::path(
    post,
    path = "/courses/arrets/{arret_id}/collecte",
    tag = "qr",
    params(("arret_id" = Uuid, Path, description = "Arrêt à collecter de la course active.")),
    request_body(content = CollecteMultipartDto, content_type = "multipart/form-data", description = "Partie `demande` (JSON) + `photo` binaire facultative."),
    responses(
        (status = 200, description = "Arrêt COLLECTÉ (idempotent au rejeu du même uuid_client).", body = ResultatCollecteDto),
        (status = 409, description = "Arrêt déjà collecté par un autre uuid, ou état incompatible.", body = ErreurApiDto),
        (status = 422, description = "Refus métier : hors zone, jeton révoqué, plaque invalide, photo requise, code incorrect/épuisé.", body = ErreurApiDto),
        (status = 404, description = "Arrêt inconnu ou hors course active (FR-012).", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/arrets/{arret_id}/collecte")]
pub async fn collecter(
    auth: Auth,
    chemin: web::Path<Uuid>,
    form: MultipartForm<CollecteForm>,
    qr: web::Data<PgQr>,
) -> Result<HttpResponse, ErreurQrHttp> {
    auth.exiger_role(Role::Coursier)?;
    let form = form.into_inner();
    let dto: DemandeCollecteDto = serde_json::from_str(&form.demande)
        .map_err(|_| ErreurQrHttp::Qr(ErreurQr::DemandeInvalide("JSON `demande` illisible")))?;
    let demande = DemandeCollecte {
        arret_id: chemin.into_inner(),
        mode: dto.mode.into(),
        jeton: dto.jeton,
        code: dto.code,
        position_lat: dto.position_lat,
        position_lon: dto.position_lon,
        photo: form.photo.map(|f| f.data.to_vec()),
        uuid_client: dto.uuid_client,
        horodatage_local: dto.horodatage_local,
    };
    let resultat = qr.collecter(auth.compte_id, demande).await?;
    Ok(HttpResponse::Ok().json(ResultatCollecteDto::from(resultat)))
}
