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

// ── Simulation et publication (US3 — T025) ─────────────────────────────────

/// Point géographique d'une course simulée.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = Point)]
pub struct PointDto {
    /// Latitude en degrés décimaux.
    pub lat: f64,
    /// Longitude en degrés décimaux.
    pub lon: f64,
}

impl From<&PointDto> for tarification::Point {
    fn from(p: &PointDto) -> Self {
        tarification::Point {
            lat: p.lat,
            lon: p.lon,
        }
    }
}

/// Attente constatée à un arrêt — les DEUX horodatages sont requis, sinon la
/// prime vaut 0 (FR-029 : jamais inventée).
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = Attente)]
pub struct AttenteDto {
    /// Arrivée géolocalisée du coursier.
    pub arrivee: DateTime<Utc>,
    /// Scan QR de la plaque (fin d'attente).
    pub scan: DateTime<Utc>,
}

/// Offre de livraison du vendeur (VND-08) — **entrée** simulée du calcul ; sa
/// configuration relève de VND, son financement de PAY (hors périmètre).
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = OffreLivraisonVendeur)]
pub struct OffreLivraisonDto {
    /// Le vendeur prend la livraison en charge quel que soit le panier.
    pub toujours: bool,
    /// Prise en charge à partir de ce montant de panier (unités mineures).
    /// Ignoré si `toujours`.
    pub au_dela: Option<i64>,
}

impl OffreLivraisonDto {
    fn vers_domaine(&self) -> Option<tarification::OffreLivraison> {
        if self.toujours {
            Some(tarification::OffreLivraison::Toujours)
        } else {
            self.au_dela.map(tarification::OffreLivraison::AuDela)
        }
    }
}

/// Course simulée — **pas de coursier** : le devis client précède le dispatch
/// (CMD-01/TRF-03, research R11).
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeSimulation)]
pub struct DemandeSimulationDto {
    /// Points de retrait (1..n), dans un ordre quelconque — le moteur optimise.
    pub vendeurs: Vec<PointDto>,
    /// Destination client.
    pub destination: PointDto,
    /// Véhicule.
    pub transport_slug: String,
    /// Instant d'évaluation (plages horaires, jours, dates d'effet).
    pub instant: DateTime<Utc>,
    /// Nombre total d'articles de la commande (paliers d'effort).
    pub nb_articles: i32,
    /// Catégorie de service, `null` = aucune contrainte.
    pub categorie_slug: Option<String>,
    /// Attentes constatées, `null` = aucune.
    pub attentes: Option<Vec<AttenteDto>>,
    /// Montant du panier (unités mineures) — seuil VND-08.
    pub montant_panier: Option<i64>,
    /// Offre de livraison du vendeur, `null` = aucune.
    pub offre_livraison_vendeur: Option<OffreLivraisonDto>,
    /// Commande mono-vendeur — condition NÉCESSAIRE de VND-08.
    pub mono_vendeur: bool,
}

impl DemandeSimulationDto {
    /// Convertit en demande de domaine. La `zone_id` est POSÉE par le moteur
    /// depuis le brouillon simulé, jamais fournie par l'appelant.
    fn vers_domaine(&self) -> Result<tarification::DemandeDevis, ErreurTarif> {
        if self.vendeurs.is_empty() {
            return Err(ErreurTarif::DemandeInvalide("aucun point de retrait"));
        }
        Ok(tarification::DemandeDevis {
            zone_id: Uuid::nil(),
            transport_slug: self.transport_slug.clone(),
            retraits: self.vendeurs.iter().map(Into::into).collect(),
            client: (&self.destination).into(),
            nb_articles: self.nb_articles,
            instant: self.instant,
            categorie_slug: self.categorie_slug.clone(),
            attentes: self
                .attentes
                .iter()
                .flatten()
                .map(|a| tarification::Attente {
                    arrivee: a.arrivee,
                    scan: a.scan,
                })
                .collect(),
            montant_panier: self.montant_panier.unwrap_or(0),
            offre_livraison_vendeur: self
                .offre_livraison_vendeur
                .as_ref()
                .and_then(OffreLivraisonDto::vers_domaine),
            mono_vendeur: self.mono_vendeur,
        })
    }
}

/// Itinéraire retenu par la simulation.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ItineraireSimule)]
pub struct ItineraireDto {
    /// Indices des vendeurs dans l'ordre de passage.
    pub ordre: Vec<usize>,
    /// Distance routière totale (mètres).
    pub distance_m: i64,
    /// Durée estimée (secondes).
    pub eta_s: i64,
    /// Vrai si la distance vient du repli vol d'oiseau × facteur de zone.
    pub degraded: bool,
    /// Vrai si l'ordre est le meilleur de TOUTES les permutations (≤ 4 arrêts) ;
    /// faux si l'heuristique bornée a tranché (FR-031).
    pub exhaustif: bool,
}

/// Détail des composantes (unités mineures) — FR-020.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = Composantes)]
pub struct ComposantesDto {
    /// Prix client de base de la règle.
    pub base: i64,
    /// Composante kilométrique au-delà du seuil.
    pub km: i64,
    /// Suppléments activés (pluie…).
    pub supplements: i64,
    /// Effort — paliers d'articles (100 % coursier).
    pub effort_paliers: i64,
    /// Effort — prime d'attente (100 % coursier).
    pub effort_attente: i64,
    /// Effort — suppléments d'arrêt (100 % coursier).
    pub effort_arrets: i64,
    /// Reliquat d'arrondi — abonde la part coursier.
    pub arrondi: i64,
    /// Montant pris en charge par le vendeur (VND-08).
    pub retenue_vendeur: i64,
}

/// Règle retenue par l'évaluation.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RegleRetenue)]
pub struct RegleRetenueDto {
    /// Identifiant de la règle.
    pub regle_id: Uuid,
    /// Véhicule.
    pub transport_slug: String,
    /// Priorité.
    pub priorite: i32,
}

/// Devis figé.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = Devis)]
pub struct DevisDto {
    /// Prix payé par le client (unités mineures).
    pub prix_client: i64,
    /// Part reversée au coursier.
    pub part_coursier: i64,
    /// Marge Mefali.
    pub marge: i64,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Distance routière totale (mètres).
    pub distance_m: i64,
    /// Durée estimée (secondes).
    pub eta_s: i64,
    /// Distance issue du mode dégradé.
    pub degraded: bool,
    /// Le détour dépasse le plafond de zone : CMD proposera de scinder.
    pub proposer_scission: bool,
}

/// Drapeaux de zone appliqués.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DrapeauxZone)]
pub struct DrapeauxDto {
    /// Prix client forcé à 0 (promo Mefali).
    pub livraison_offerte_mefali: bool,
    /// Marge forcée à 0.
    pub gratuite_commissions: bool,
    /// Supplément de pluie actif.
    pub pluie: bool,
}

/// Résultat COMPLET d'une simulation (FR-020).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ResultatSimulation)]
pub struct ResultatSimulationDto {
    /// Itinéraire utilisé.
    pub itineraire: ItineraireDto,
    /// Règle retenue.
    pub regle_retenue: RegleRetenueDto,
    /// Détail des composantes.
    pub composantes: ComposantesDto,
    /// Devis final.
    pub devis: DevisDto,
    /// Drapeaux appliqués.
    pub drapeaux: DrapeauxDto,
    /// Vrai si l'effort a été calculé mais NON facturé (promo — FR-033).
    pub effort_non_facture: bool,
}

impl From<tarification::Evaluation> for ResultatSimulationDto {
    fn from(e: tarification::Evaluation) -> Self {
        let c = e.devis.composantes;
        Self {
            itineraire: ItineraireDto {
                ordre: e.itineraire.ordre,
                distance_m: e.itineraire.distance_m,
                eta_s: e.itineraire.eta_s,
                degraded: e.itineraire.degraded,
                exhaustif: e.itineraire.exhaustif,
            },
            regle_retenue: RegleRetenueDto {
                regle_id: e.regle.regle_id,
                transport_slug: e.regle.transport_slug,
                priorite: e.regle.priorite,
            },
            composantes: ComposantesDto {
                base: c.base,
                km: c.km,
                supplements: c.supplements,
                effort_paliers: c.effort_paliers,
                effort_attente: c.effort_attente,
                effort_arrets: c.effort_arrets,
                arrondi: c.arrondi,
                retenue_vendeur: c.retenue_vendeur,
            },
            devis: DevisDto {
                prix_client: e.devis.prix_client,
                part_coursier: e.devis.part_coursier,
                marge: e.devis.marge,
                devise: e.devis.devise,
                distance_m: e.devis.distance_m,
                eta_s: e.devis.eta_s,
                degraded: e.devis.degraded,
                proposer_scission: e.devis.proposer_scission,
            },
            drapeaux: DrapeauxDto {
                livraison_offerte_mefali: e.drapeaux.livraison_offerte_mefali,
                gratuite_commissions: e.drapeaux.gratuite_commissions,
                pluie: e.drapeaux.pluie,
            },
            effort_non_facture: e.effort_non_facture,
        }
    }
}

/// Simule une course sur le brouillon — **dry run**, aucun effet de bord.
#[utoipa::path(
    post,
    path = "/admin/tarification/brouillon/{grille_id}/simuler",
    tag = "tarification",
    params(("grille_id" = Uuid, Path, description = "Brouillon à rejouer.")),
    request_body = DemandeSimulationDto,
    responses(
        (status = 200, description = "Détail complet : itinéraire (et `degraded`), règle \
         retenue, composantes, retenue vendeur, arrondi, devis. N'écrit AUCUN événement et \
         ne touche pas la grille en vigueur ; pose seulement la garde de publication.",
         body = ResultatSimulationDto),
        (status = 409, description = "La grille n'est pas un brouillon.", body = ErreurApiDto),
        (status = 422, description = "`aucune_regle` (grille à compléter — condition \
         corrigeable par l'admin, pas une faute serveur) ou corps invalide.", body = ErreurApiDto),
        (status = 404, description = "Grille inconnue.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/tarification/brouillon/{grille_id}/simuler")]
pub async fn simuler(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeSimulationDto>,
    depot: web::Data<PgTarification>,
) -> Result<HttpResponse, ErreurTarifHttp> {
    auth.exiger_role(Role::Admin)?;
    let grille_id = chemin.into_inner();
    let demande = corps.into_inner().vers_domaine()?;

    let evaluation = depot.simuler(grille_id, &demande).await?;
    tracing::info!(
        acteur = %auth.compte_id, grille = %grille_id,
        prix_client = evaluation.devis.prix_client, degraded = evaluation.devis.degraded,
        "simulation tarifaire",
    );
    Ok(HttpResponse::Ok().json(ResultatSimulationDto::from(evaluation)))
}

/// Publie le brouillon — **gardé** par la simulation et les bornes.
#[utoipa::path(
    post,
    path = "/admin/tarification/brouillon/{grille_id}/publier",
    tag = "tarification",
    params(("grille_id" = Uuid, Path, description = "Brouillon à publier.")),
    responses(
        (status = 200, description = "Grille en vigueur à sa date d'entrée en vigueur ; \
         l'ancienne passe à l'historique. Émet `grille.publiee`.", body = GrilleVueDto),
        (status = 409, description = "`simulation_requise` (jamais simulé, ou édité depuis) ou \
         `regle_hors_bornes` / `devise_incoherente` (bornes resserrées après coup).",
         body = ErreurApiDto),
        (status = 404, description = "Grille inconnue.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/tarification/brouillon/{grille_id}/publier")]
pub async fn publier(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgTarification>,
) -> Result<HttpResponse, ErreurTarifHttp> {
    auth.exiger_role(Role::Admin)?;
    let grille_id = chemin.into_inner();

    let mut tx = depot.pool().begin().await.map_err(ErreurTarif::from)?;
    let publiee = depot.publier(&mut tx, grille_id, auth.compte_id).await?;
    tx.commit().await.map_err(ErreurTarif::from)?;

    tracing::info!(
        acteur = %auth.compte_id, zone = %publiee.zone_id, grille = %grille_id,
        version = publiee.version, "grille tarifaire PUBLIÉE",
    );
    Ok(HttpResponse::Ok().json(GrilleVueDto::from(&publiee)))
}
