//! Surface HTTP **ADMIN** du cycle CMD : file d'attente coursier, puis — aux
//! tâches suivantes — annulation avec motif et enregistrement d'une issue de
//! l'arbre §7.5.
//!
//! **Périmètre assumé** : ce module est une surface de LECTURE et d'action
//! ponctuelle, pas un écran. L'écran d'exploitation appartient au cycle ADM ;
//! ce que CMD doit livrer, c'est de quoi observer et débloquer la file en test
//! comme en production, sans attendre un cycle qui n'existe pas encore.
//!
//! Rôle `Admin`, journalisé (patron des cycles 002/003/005).

use actix_web::{get, post, web, HttpResponse};
use commandes::{CommandesADispatcher, PgCommandes};
use comptes::Role;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::commandes_http::{DemandeAnnulationDto, ResultatAnnulationDto};
use crate::erreurs_commandes::ErreurCommandesHttp;

/// Zone dont on lit la file.
#[derive(Debug, Deserialize, IntoParams)]
pub struct FiltreFileDto {
    /// Zone (ville) dont on veut la file d'attente.
    pub zone_id: Uuid,
}

/// Une commande en attente de coursier, telle que DSP la lira.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CommandeEnAttente)]
pub struct CommandeEnAttenteDto {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Zone de la commande.
    pub zone_id: Uuid,
    /// Ancienneté dans la file, en secondes — **c'est elle qui ordonne**.
    pub age_s: i64,
    /// Nombre d'arrêts de collecte à desservir.
    pub nb_collectes: i64,
    /// Montant total que le coursier devra avancer (unités mineures).
    pub montant_a_avancer: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Latitude du premier site VENDEUR — donnée professionnelle. Aucune
    /// coordonnée du client n'est exposée ici (minimisation ARTCI).
    pub premiere_collecte_lat: Option<f64>,
    /// Longitude du premier site vendeur.
    pub premiere_collecte_lon: Option<f64>,
}

/// La file d'attente d'une zone.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = FileAttenteCoursier)]
pub struct FileAttenteDto {
    /// Commandes en attente, **la plus ancienne d'abord** (FIFO par âge).
    pub commandes: Vec<CommandeEnAttenteDto>,
}

/// CMD-10 — file FIFO des commandes sans coursier d'une zone.
///
/// L'ordre est l'âge, du plus ancien au plus récent : c'est la promesse
/// produite au client qui attend (« la plus ancienne repart en premier »), et
/// c'est le contrat que **DSP** consommera tel quel.
#[utoipa::path(
    get,
    path = "/admin/commandes/attente",
    tag = "commandes-admin",
    params(FiltreFileDto),
    responses(
        (status = 200, description = "File d'attente de la zone, la plus ancienne d'abord.",
         body = FileAttenteDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/commandes/attente")]
pub async fn file_attente(
    auth: Auth,
    filtre: web::Query<FiltreFileDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Admin)?;
    let zone_id = filtre.into_inner().zone_id;
    tracing::info!(admin = %auth.compte_id, zone = %zone_id, "lecture de la file d'attente coursier");

    let commandes = depot.en_attente_coursier(zone_id).await?;
    Ok(HttpResponse::Ok().json(FileAttenteDto {
        commandes: commandes
            .into_iter()
            .map(|c| CommandeEnAttenteDto {
                commande_id: c.commande_id,
                zone_id: c.zone_id,
                age_s: c.age_s,
                nb_collectes: c.nb_collectes,
                montant_a_avancer: c.montant_a_avancer,
                devise: c.devise,
                premiere_collecte_lat: c.premiere_collecte_lat,
                premiere_collecte_lon: c.premiere_collecte_lon,
            })
            .collect(),
    }))
}

/// CMD-07 — un administrateur annule une commande, **motif obligatoire**.
///
/// Le motif n'est pas une formalité : il est journalisé, il part dans
/// l'événement, et c'est lui que le client lira. C'est une **clé i18n**, jamais
/// du texte libre — un motif écrit à la main serait illisible pour la moitié
/// des clients et impossible à agréger pour l'exploitation.
#[utoipa::path(
    post,
    path = "/admin/commandes/{id}/annuler",
    tag = "commandes-admin",
    params(("id" = Uuid, Path, description = "Commande à annuler.")),
    request_body = DemandeAnnulationDto,
    responses(
        (status = 200, description = "Commande annulée ; `sans_frais` dit si quelque chose est dû.",
         body = ResultatAnnulationDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 404, description = "Commande inconnue.", body = ErreurApiDto),
        (status = 409, description = "État terminal.", body = ErreurApiDto),
        (status = 422, description = "Motif absent — un admin doit motiver son geste (FR-054).",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/commandes/{id}/annuler")]
pub async fn annuler_commande_admin(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeAnnulationDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Admin)?;
    let commande_id = chemin.into_inner();
    let motif = corps.into_inner().motif_cle;
    tracing::info!(
        admin = %auth.compte_id,
        commande = %commande_id,
        motif = motif.as_deref().unwrap_or("—"),
        "annulation administrative",
    );
    let faite = depot
        .annuler_commande(
            commande_id,
            commandes::AuteurAnnulation::Admin,
            auth.compte_id,
            motif.as_deref(),
            chrono::Utc::now(),
        )
        .await?;
    Ok(HttpResponse::Ok().json(ResultatAnnulationDto::from(faite)))
}
