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

use actix_web::{get, web, HttpResponse};
use commandes::{CommandesADispatcher, PgCommandes};
use comptes::Role;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
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
