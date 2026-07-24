//! Administration de la tarification (cycle TRF 007).
//!
//! **Les ÉCRANS arrivent au cycle ADM** (maquette `docs/design/png/A3`) : ici
//! l'API, protégée par le rôle admin et journalisée (qui, quand — FR-005), sur
//! le patron des cycles 002/003/005. Le contrat est auto-collecté par
//! utoipa-actix-web ; erreurs rendues `{ code, message_cle }` (clés i18n fr,
//! FR-001).
//!
//! Frontière du cycle : cette surface édite, **simule** et **publie** des
//! grilles. Le devis de production, lui, n'a pas d'endpoint — il est offert aux
//! cycles suivants par le trait `EvaluationTarifaire` (research R13).

use actix_web::http::StatusCode;
use actix_web::{delete, get, post, put, web, HttpResponse, ResponseError};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::json;
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::Role;
use tarification::{ErreurTarif, Grille, PgTarification, Regle, RegleUpsert};

use crate::auth_http::{Auth, ErreurApi, ErreurApiDto};

// ── Erreur HTTP locale ─────────────────────────────────────────────────────

/// Erreur HTTP du module tarification : auth/rôle (`ErreurApi`) ou domaine
/// (`ErreurTarif`).
#[derive(Debug)]
pub enum ErreurTarifHttp {
    /// Erreur d'authentification / de rôle (réutilise le mapping comptes).
    Api(ErreurApi),
    /// Refus métier ou erreur d'infrastructure du domaine tarification.
    Tarif(ErreurTarif),
}

impl From<ErreurApi> for ErreurTarifHttp {
    fn from(e: ErreurApi) -> Self {
        ErreurTarifHttp::Api(e)
    }
}

impl From<ErreurTarif> for ErreurTarifHttp {
    fn from(e: ErreurTarif) -> Self {
        ErreurTarifHttp::Tarif(e)
    }
}

impl std::fmt::Display for ErreurTarifHttp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErreurTarifHttp::Api(e) => write!(f, "{e}"),
            ErreurTarifHttp::Tarif(e) => write!(f, "{e}"),
        }
    }
}

/// Statut HTTP d'un refus de domaine (contrats §5).
fn statut_tarif(e: &ErreurTarif) -> StatusCode {
    match e {
        // Conflits d'ÉTAT ou de GARDE : la requête est bien formée, c'est la
        // situation qui la refuse — l'admin corrige puis rejoue.
        ErreurTarif::MargeHorsBornes { .. }
        | ErreurTarif::DeviseIncoherente { .. }
        | ErreurTarif::SimulationRequise
        | ErreurTarif::RegleHorsBornes
        | ErreurTarif::PasUnBrouillon(_) => StatusCode::CONFLICT,
        ErreurTarif::GrilleInconnue(_) | ErreurTarif::RegleInconnue(_) => StatusCode::NOT_FOUND,
        // Conditions CORRIGIBLES par l'admin (grille à compléter), pas des
        // fautes serveur : 422 et non 500 (contrats §5).
        ErreurTarif::AucuneRegle
        | ErreurTarif::AucuneGrilleEnVigueur(_)
        | ErreurTarif::DemandeInvalide(_) => StatusCode::UNPROCESSABLE_ENTITY,
        // Infrastructure (Zones, Sql).
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

impl ResponseError for ErreurTarifHttp {
    fn status_code(&self) -> StatusCode {
        match self {
            ErreurTarifHttp::Api(e) => e.status_code(),
            ErreurTarifHttp::Tarif(e) => statut_tarif(e),
        }
    }

    fn error_response(&self) -> HttpResponse {
        match self {
            ErreurTarifHttp::Api(e) => e.error_response(),
            ErreurTarifHttp::Tarif(e) => {
                let (code, message_cle) = match e.message_cle() {
                    Some(cle) => (cle.to_owned(), format!("tarification.erreur.{cle}")),
                    None => (
                        "erreur_interne".to_owned(),
                        "tarification.erreur.interne".to_owned(),
                    ),
                };
                // Les bornes accompagnent le refus : l'admin doit voir DANS
                // QUEL intervalle corriger, sans aller lire la config de zone
                // (maquette A3 « marge hors bornes 25–100 »).
                let mut corps = json!({ "code": code, "message_cle": message_cle });
                if let ErreurTarif::MargeHorsBornes { min, max, valeur } = e {
                    corps["min"] = json!(min);
                    corps["max"] = json!(max);
                    corps["valeur"] = json!(valeur);
                }
                if let ErreurTarif::DeviseIncoherente { attendue, fournie } = e {
                    corps["attendue"] = json!(attendue);
                    corps["fournie"] = json!(fournie);
                }
                HttpResponse::build(statut_tarif(e)).json(corps)
            }
        }
    }
}

// ── DTO ────────────────────────────────────────────────────────────────────

/// Écriture d'une règle de brouillon. Montants en **unités mineures**.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = RegleUpsert)]
pub struct RegleUpsertDto {
    /// Slug du véhicule (référentiel `zones.type_transport`).
    pub transport_slug: String,
    /// Slug de catégorie, `null` = toutes catégories.
    pub categorie_slug: Option<String>,
    /// Borne basse de la tranche de distance routière (mètres).
    #[schema(minimum = 0)]
    pub distance_min_m: i32,
    /// Borne haute INCLUSE, `null` = +∞.
    pub distance_max_m: Option<i32>,
    /// Début de plage horaire (minutes depuis minuit, fuseau de la zone).
    pub plage_debut_min: Option<i16>,
    /// Fin de plage horaire (exclue).
    pub plage_fin_min: Option<i16>,
    /// Masque de jours (bit 0 = lundi … bit 6 = dimanche), `null` = tous.
    pub jours_masque: Option<i16>,
    /// Part coursier de base (unités mineures).
    #[schema(minimum = 0)]
    pub part_coursier_base: i64,
    /// Marge Mefali — DOIT être dans les bornes de la zone (FR-009).
    #[schema(minimum = 0)]
    pub marge: i64,
    /// Prix par kilomètre au-delà du seuil (abonde client ET coursier).
    #[schema(minimum = 0)]
    pub prix_par_km: i64,
    /// Seuil (mètres) au-delà duquel le kilométrage est facturé.
    #[schema(minimum = 0)]
    pub seuil_km_m: i32,
    /// Plafond du prix client, `null` = aucun.
    pub prix_plafond: Option<i64>,
    /// Devise ISO 4217 — DOIT égaler celle de la zone (FR-023).
    pub devise: String,
    /// Priorité de départage.
    pub priorite: i32,
    /// Règle active à l'évaluation.
    pub actif: bool,
}

impl From<RegleUpsertDto> for RegleUpsert {
    fn from(d: RegleUpsertDto) -> Self {
        RegleUpsert {
            transport_slug: d.transport_slug,
            categorie_slug: d.categorie_slug,
            distance_min_m: d.distance_min_m,
            distance_max_m: d.distance_max_m,
            plage_debut_min: d.plage_debut_min,
            plage_fin_min: d.plage_fin_min,
            jours_masque: d.jours_masque,
            part_coursier_base: d.part_coursier_base,
            marge: d.marge,
            prix_par_km: d.prix_par_km,
            seuil_km_m: d.seuil_km_m,
            prix_plafond: d.prix_plafond,
            devise: d.devise,
            priorite: d.priorite,
            actif: d.actif,
        }
    }
}

/// Règle servie à l'admin.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = Regle)]
pub struct RegleVueDto {
    /// Identifiant.
    pub id: Uuid,
    /// Véhicule.
    pub transport_slug: String,
    /// Catégorie, `null` = toutes.
    pub categorie_slug: Option<String>,
    /// Borne basse de tranche (mètres).
    pub distance_min_m: i32,
    /// Borne haute incluse.
    pub distance_max_m: Option<i32>,
    /// Début de plage horaire.
    pub plage_debut_min: Option<i16>,
    /// Fin de plage horaire.
    pub plage_fin_min: Option<i16>,
    /// Masque de jours.
    pub jours_masque: Option<i16>,
    /// Part coursier de base.
    pub part_coursier_base: i64,
    /// Marge Mefali.
    pub marge: i64,
    /// Prix par km au-delà du seuil.
    pub prix_par_km: i64,
    /// Seuil de kilométrage facturé (mètres).
    pub seuil_km_m: i32,
    /// Plafond du prix client.
    pub prix_plafond: Option<i64>,
    /// Devise ISO 4217.
    pub devise: String,
    /// Priorité.
    pub priorite: i32,
    /// Active.
    pub actif: bool,
    /// Prix client de base DÉRIVÉ (`part_coursier_base + marge`) — jamais
    /// stocké, servi pour que l'admin lise le tarif sans le recalculer.
    pub prix_client_base: i64,
}

impl From<&Regle> for RegleVueDto {
    fn from(r: &Regle) -> Self {
        Self {
            id: r.id,
            transport_slug: r.transport_slug.clone(),
            categorie_slug: r.categorie_slug.clone(),
            distance_min_m: r.distance_min_m,
            distance_max_m: r.distance_max_m,
            plage_debut_min: r.plage_debut_min,
            plage_fin_min: r.plage_fin_min,
            jours_masque: r.jours_masque,
            part_coursier_base: r.part_coursier_base,
            marge: r.marge,
            prix_par_km: r.prix_par_km,
            seuil_km_m: r.seuil_km_m,
            prix_plafond: r.prix_plafond,
            devise: r.devise.clone(),
            priorite: r.priorite,
            actif: r.actif,
            prix_client_base: r.prix_client_base(),
        }
    }
}

/// Grille servie à l'admin (en-tête + règles + statut de simulation).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = Grille)]
pub struct GrilleVueDto {
    /// Identifiant.
    pub id: Uuid,
    /// Zone tarifée.
    pub zone_id: Uuid,
    /// Version.
    pub version: i32,
    /// `brouillon` | `en_vigueur` | `historique`.
    pub etat: String,
    /// Entrée en vigueur (posée à la publication).
    pub effet_le: Option<DateTime<Utc>>,
    /// Dernière simulation réussie.
    pub simulee_le: Option<DateTime<Utc>>,
    /// **Publiable** : la simulation porte sur le contenu EXACT du brouillon.
    /// Repasse à `false` dès qu'une règle est éditée (FR-021).
    pub simulee: bool,
    /// Règles, triées par identifiant (ordre stable).
    pub regles: Vec<RegleVueDto>,
}

impl From<&Grille> for GrilleVueDto {
    fn from(g: &Grille) -> Self {
        Self {
            id: g.id,
            zone_id: g.zone_id,
            version: g.version,
            etat: g.etat.comme_str().to_owned(),
            effet_le: g.effet_le,
            simulee_le: g.simulee_le,
            simulee: g.simulation_a_jour(),
            regles: g.regles.iter().map(RegleVueDto::from).collect(),
        }
    }
}

/// Vue d'ensemble de la tarification d'une zone.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = GrillesZone)]
pub struct GrillesZoneDto {
    /// Grille qui tarife aujourd'hui, `null` si la zone n'en a aucune.
    pub en_vigueur: Option<GrilleVueDto>,
    /// Brouillon en cours d'édition, `null` s'il n'y en a pas.
    pub brouillon: Option<GrilleVueDto>,
}

// ── Endpoints ──────────────────────────────────────────────────────────────

/// Grille en vigueur ET brouillon d'une zone.
#[utoipa::path(
    get,
    path = "/admin/tarification/zones/{zone_id}/grille",
    tag = "tarification",
    params(("zone_id" = Uuid, Path, description = "Zone tarifée.")),
    responses(
        (status = 200, description = "Grille en vigueur et brouillon (avec statut de \
         simulation et règles).", body = GrillesZoneDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/tarification/zones/{zone_id}/grille")]
pub async fn grille_de_zone(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgTarification>,
) -> Result<HttpResponse, ErreurTarifHttp> {
    auth.exiger_role(Role::Admin)?;
    let zone = chemin.into_inner();
    let en_vigueur = depot.grille_en_vigueur(zone).await?;
    let brouillon = depot.brouillon(zone).await?;
    Ok(HttpResponse::Ok().json(GrillesZoneDto {
        en_vigueur: en_vigueur.as_ref().map(GrilleVueDto::from),
        brouillon: brouillon.as_ref().map(GrilleVueDto::from),
    }))
}

/// Crée (ou rend) le brouillon de la zone — **idempotent**.
#[utoipa::path(
    post,
    path = "/admin/tarification/zones/{zone_id}/brouillon",
    tag = "tarification",
    params(("zone_id" = Uuid, Path, description = "Zone tarifée.")),
    responses(
        (status = 200, description = "Brouillon de la zone. À la CRÉATION, il clone la grille \
         en vigueur (l'admin part du tarif réel) ; un second appel rend le même brouillon, \
         sans rien recréer.", body = GrilleVueDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/tarification/zones/{zone_id}/brouillon")]
pub async fn creer_brouillon(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgTarification>,
) -> Result<HttpResponse, ErreurTarifHttp> {
    auth.exiger_role(Role::Admin)?;
    let zone = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(ErreurTarif::from)?;
    let brouillon = depot.obtenir_ou_creer_brouillon(&mut tx, zone).await?;
    tx.commit().await.map_err(ErreurTarif::from)?;

    tracing::info!(
        acteur = %auth.compte_id, zone = %zone, grille = %brouillon.id,
        version = brouillon.version, "brouillon tarifaire obtenu",
    );
    Ok(HttpResponse::Ok().json(GrilleVueDto::from(&brouillon)))
}

/// Crée ou met à jour une règle du brouillon — **réarme la simulation**.
#[utoipa::path(
    put,
    path = "/admin/tarification/brouillon/{grille_id}/regles/{regle_id}",
    tag = "tarification",
    params(
        ("grille_id" = Uuid, Path, description = "Brouillon."),
        ("regle_id" = Uuid, Path, description = "Règle (identifiant choisi par l'appelant)."),
    ),
    request_body = RegleUpsertDto,
    responses(
        (status = 200, description = "Règle enregistrée. La grille redevient NON publiable \
         tant qu'une nouvelle simulation n'a pas porté sur ce contenu (FR-021).",
         body = RegleVueDto),
        (status = 409, description = "`marge_hors_bornes` (le corps porte `min`/`max`/`valeur`), \
         `devise_incoherente`, ou grille qui n'est pas un brouillon.", body = ErreurApiDto),
        (status = 404, description = "Grille inconnue, ou règle appartenant à une autre grille.",
         body = ErreurApiDto),
        (status = 422, description = "Corps invalide.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/admin/tarification/brouillon/{grille_id}/regles/{regle_id}")]
pub async fn ecrire_regle(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<RegleUpsertDto>,
    depot: web::Data<PgTarification>,
) -> Result<HttpResponse, ErreurTarifHttp> {
    auth.exiger_role(Role::Admin)?;
    let (grille_id, regle_id) = chemin.into_inner();
    let upsert: RegleUpsert = corps.into_inner().into();

    let mut tx = depot.pool().begin().await.map_err(ErreurTarif::from)?;
    let regle = depot
        .ecrire_regle(&mut tx, grille_id, regle_id, &upsert)
        .await?;
    tx.commit().await.map_err(ErreurTarif::from)?;

    tracing::info!(
        acteur = %auth.compte_id, grille = %grille_id, regle = %regle.id,
        transport = %regle.transport_slug, marge = regle.marge,
        "règle tarifaire écrite (brouillon)",
    );
    Ok(HttpResponse::Ok().json(RegleVueDto::from(&regle)))
}

/// Supprime une règle du brouillon — **réarme la simulation**.
#[utoipa::path(
    delete,
    path = "/admin/tarification/brouillon/{grille_id}/regles/{regle_id}",
    tag = "tarification",
    params(
        ("grille_id" = Uuid, Path, description = "Brouillon."),
        ("regle_id" = Uuid, Path, description = "Règle à supprimer."),
    ),
    responses(
        (status = 204, description = "Supprimée. La grille redevient non publiable tant \
         qu'une nouvelle simulation n'a pas porté sur ce contenu."),
        (status = 409, description = "La grille n'est pas un brouillon.", body = ErreurApiDto),
        (status = 404, description = "Grille ou règle inconnues.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[delete("/admin/tarification/brouillon/{grille_id}/regles/{regle_id}")]
pub async fn supprimer_regle(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    depot: web::Data<PgTarification>,
) -> Result<HttpResponse, ErreurTarifHttp> {
    auth.exiger_role(Role::Admin)?;
    let (grille_id, regle_id) = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(ErreurTarif::from)?;
    depot.supprimer_regle(&mut tx, grille_id, regle_id).await?;
    tx.commit().await.map_err(ErreurTarif::from)?;

    tracing::info!(
        acteur = %auth.compte_id, grille = %grille_id, regle = %regle_id,
        "règle tarifaire supprimée (brouillon)",
    );
    Ok(HttpResponse::NoContent().finish())
}
