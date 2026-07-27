//! Surface HTTP **ADMIN** du cycle DSP : alertes, pool, reprise manuelle.
//!
//! Ce sont les **contrats** que l'écran d'opérations (ADM-02, tranche T3)
//! consommera. **Aucun écran n'est construit ici** (FR-096) : le module ADM est
//! en tranche T3, et bâtir son interface maintenant reviendrait à décider sa
//! forme sans sa spécification.
//!
//! Tous les endpoints sont gardés par `Role::Admin`. L'accès au pool est un
//! besoin d'exploitation légitime (la « carte des coursiers » d'ADM-02) — et il
//! reste le seul endroit du cycle où une position est rendue, à un rôle qui a
//! le droit de la voir.

use actix_web::{get, post, web, HttpResponse};
use chrono::Utc;
use comptes::Role;
use dispatch::PgDispatch;
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::erreurs_dispatch::ErreurDispatchHttp;

// ── DTO ────────────────────────────────────────────────────────────────────

/// Une commande escaladée : personne ne l'a prise au seuil de zone (FR-064).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = EscaladeDispatch)]
pub struct EscaladeDto {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Zone de la commande.
    pub zone_id: Uuid,
    /// Ancienneté au moment de l'escalade (secondes).
    pub age_s: i64,
    /// Seuil de zone franchi (secondes).
    pub seuil_s: i64,
    /// Par quel chemin elle est arrivée là : `file` | `pipeline`.
    pub chemin: String,
    /// Nombre d'offres déjà émises pour elle.
    pub nb_offres_emises: i64,
    /// État courant du tronc.
    pub etat: String,
}

/// Une course assignée qui n'avance pas (FR-075).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CourseBloquee)]
pub struct CourseBloqueeDto {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Livraison concernée.
    pub livraison_id: Uuid,
    /// Coursier assigné.
    pub coursier_id: Option<Uuid>,
    /// Critère constaté : `sans_mouvement` | `sans_scan`.
    pub motif: String,
    /// Durée de stagnation constatée (secondes).
    pub stagnation_s: i64,
    /// Arrêts déjà collectés. **`> 0` ⇒ aucune reprise automatique possible.**
    pub nb_arrets_collectes: i64,
    /// Faux quand un arrêt est collecté : seule une décision humaine motivée
    /// peut alors trancher, parce que le coursier a engagé ses fonds propres.
    pub reprise_automatique_possible: bool,
}

/// Le tableau d'alertes de l'exploitation.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = AlertesDispatch)]
pub struct AlertesDto {
    /// Commandes escaladées, **les plus anciennes d'abord**.
    pub escalades: Vec<EscaladeDto>,
    /// Courses assignées sans progression.
    pub courses_bloquees: Vec<CourseBloqueeDto>,
}

/// Un coursier du pool, tel que la carte d'ADM-02 le montrera.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CoursierDuPool)]
pub struct CoursierPoolDto {
    /// Compte du coursier.
    pub coursier_id: Uuid,
    /// Dernière latitude publiée.
    pub lat: f64,
    /// Dernière longitude publiée.
    pub lon: f64,
    /// Âge de la dernière publication (secondes) — l'exploitation doit savoir
    /// si elle regarde une position fraîche ou un point figé.
    pub age_s: i64,
    /// Capacités déclarées (slugs).
    pub capacites: Vec<String>,
    /// Plafond d'avance RETENU du jour — `min(palier de la grille, déclaré)`.
    pub plafond_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Course en cours, s'il y en a une.
    pub course_active: Option<Uuid>,
}

/// Le pool d'une zone.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PoolDeZone)]
pub struct PoolDto {
    /// Zone interrogée.
    pub zone_id: Uuid,
    /// Coursiers présents dans le pool.
    pub coursiers: Vec<CoursierPoolDto>,
}

/// Demande de reprise manuelle — **motif obligatoire**.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeReprise)]
pub struct DemandeRepriseDto {
    /// Pourquoi l'exploitation reprend cette course. Journalisé avec son auteur.
    pub motif: String,
}

/// Résultat d'une reprise manuelle.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RepriseFaite)]
pub struct RepriseFaiteDto {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// État du tronc après reprise.
    pub etat_commande: String,
    /// Incident tracé.
    pub incident_id: Uuid,
}

// ── Endpoints ──────────────────────────────────────────────────────────────

/// `GET /admin/dispatch/alertes` — ce qui demande un humain.
#[utoipa::path(
    get,
    path = "/admin/dispatch/alertes",
    tag = "dispatch-admin",
    responses(
        (status = 200, description = "Escalades et courses bloquées, plus anciennes d'abord.",
         body = AlertesDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/dispatch/alertes")]
pub async fn alertes_dispatch(
    auth: Auth,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Admin)?;
    let alertes = depot.alertes().await?;
    // Conversion explicite vers les DTO : le contrat OpenAPI décrit CE qui sort,
    // pas la forme interne du domaine — sans quoi un renommage de champ dans le
    // domaine changerait le contrat en silence.
    Ok(HttpResponse::Ok().json(AlertesDto {
        escalades: alertes
            .escalades
            .into_iter()
            .map(|e| EscaladeDto {
                commande_id: e.commande_id,
                zone_id: e.zone_id,
                age_s: e.age_s,
                seuil_s: e.seuil_s,
                chemin: e.chemin,
                nb_offres_emises: e.nb_offres_emises,
                etat: e.etat,
            })
            .collect(),
        courses_bloquees: alertes
            .courses_bloquees
            .into_iter()
            .map(|b| CourseBloqueeDto {
                commande_id: b.commande_id,
                livraison_id: b.livraison_id,
                coursier_id: b.coursier_id,
                motif: b.motif,
                stagnation_s: b.stagnation_s,
                nb_arrets_collectes: b.nb_arrets_collectes,
                reprise_automatique_possible: b.reprise_automatique_possible,
            })
            .collect(),
    }))
}

/// `GET /admin/dispatch/pool` — les coursiers en ligne d'une zone.
///
/// Matière de la « carte des coursiers » d'ADM-02. Le rôle `Admin` est la garde :
/// c'est le seul endroit du cycle où une position sort du serveur.
///
/// **Une zone, rien d'autre** (contrat §2.2). L'exploitation demande « qui est en
/// ligne », pas « qui est près d'ici » : elle n'a aucun centre à proposer, et
/// l'approcher par un rayon très large écarterait en silence le coursier qui le
/// dépasse. Le port [`dispatch::PoolCoursiers::membres`] répond exactement à
/// cette question — l'index GEO de Redis est un zset, qui sait s'énumérer.
///
/// Les **fantômes** de l'index (membre survivant à son état, research R2) sont
/// omis : la carte ne montre que ce dont on connaît la position et l'âge.
#[utoipa::path(
    get,
    path = "/admin/dispatch/pool",
    tag = "dispatch-admin",
    params(("zone_id" = Uuid, Query, description = "Zone dont on lit le pool.")),
    responses(
        (status = 200, description = "Coursiers du pool, avec l'âge de leur position.",
         body = PoolDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/dispatch/pool")]
pub async fn pool_dispatch(
    auth: Auth,
    requete: web::Query<RequetePool>,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Admin)?;
    let zone = requete.zone_id;
    let membres = depot.pool_coursiers().membres(zone).await?;
    let mut coursiers = Vec::new();
    for membre in membres {
        if let Some(i) = depot.pool_coursiers().etat(membre).await? {
            coursiers.push(CoursierPoolDto {
                coursier_id: i.coursier,
                lat: i.lat,
                lon: i.lon,
                age_s: i.age_s,
                capacites: i.capacites.into_iter().map(|c| c.valeur).collect(),
                plafond_unites: i.plafond_unites,
                devise: i.devise,
                course_active: i.course_active,
            });
        }
    }
    Ok(HttpResponse::Ok().json(PoolDto {
        zone_id: zone,
        coursiers,
    }))
}

/// Paramètres de lecture du pool — **la zone, et rien d'autre**.
///
/// Tout champ ajouté ici doit l'être aussi dans le `params(...)` de
/// `#[utoipa::path]` ci-dessus : un paramètre exigé par l'extracteur mais absent
/// du contrat rend l'endpoint inappelable depuis les clients générés, qui ne
/// sauraient pas le transmettre.
#[derive(Debug, Deserialize, ToSchema)]
pub struct RequetePool {
    /// Zone dont on lit le pool.
    pub zone_id: Uuid,
}

/// `POST /admin/dispatch/courses/{livraison_id}/reprendre` — la seule voie de
/// reprise d'une course dont un arrêt est **déjà collecté**.
///
/// L'automatisme s'y refuse par construction (FR-075), parce que le coursier a
/// engagé ses fonds propres. Cet endpoint n'annule aucune dette et n'écrit
/// aucune caisse : il émet `dispatch.reassignation` avec `acteur: admin` et
/// laisse la caisse (CRS-06) et le litige (AVI-04) à leurs cycles.
///
/// `422` si aucun arrêt n'est collecté — dans ce cas l'automatisme suffit, et
/// une action manuelle masquerait un défaut de pipeline.
#[utoipa::path(
    post,
    path = "/admin/dispatch/courses/{livraison_id}/reprendre",
    tag = "dispatch-admin",
    params(("livraison_id" = Uuid, Path, description = "Course à reprendre.")),
    request_body = DemandeRepriseDto,
    responses(
        (status = 200, description = "Coursier retiré, incident tracé avec son auteur.",
         body = RepriseFaiteDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 404, description = "Livraison inconnue.", body = ErreurApiDto),
        (status = 422, description = "Motif absent, ou aucun arrêt collecté (l'automatisme suffit).",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/dispatch/courses/{livraison_id}/reprendre")]
pub async fn reprendre_course_admin(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeRepriseDto>,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Admin)?;
    let livraison = chemin.into_inner();
    let maintenant = Utc::now();
    let etat = depot.etat_progression(livraison).await?;
    let incident_id = depot
        .reprendre_manuellement(livraison, auth.compte_id, &corps.motif, maintenant)
        .await?;
    Ok(HttpResponse::Ok().json(RepriseFaiteDto {
        commande_id: etat.commande_id,
        etat_commande: "en_attente_coursier".to_owned(),
        incident_id,
    }))
}
