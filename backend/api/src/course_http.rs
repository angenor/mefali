//! Surface HTTP **COURSIER** du cycle CMD : boucle déclarative d'un arrêt
//! (en route, arrivé, indisponible), puis — aux tâches suivantes — remise,
//! substitutions et déclaration d'échec.
//!
//! Deux gardes, toujours les deux : le **rôle** `Coursier`, et la **propriété**
//! de la course. La propriété n'est pas contrôlée « après coup » : elle est
//! dans le `WHERE` du domaine ([`commandes::PgCommandes::transiter_arret`]), et
//! un arrêt qui n'appartient pas à la livraison de l'URL est traité comme
//! inexistant.
//!
//! Toute écriture porte `uuid_client` + `horodatage_local` (constitution V) et
//! est **idempotente** : la file hors-ligne de l'app coursier rejoue ses actions
//! jusqu'à acquittement, et un rejeu ne doit produire ni double horodatage, ni
//! second événement.
//!
//! Erreurs rendues `{ code, message_cle }` par [`crate::erreurs_commandes`] —
//! le MÊME mapping que les surfaces client et admin.

use actix_web::{post, web, HttpResponse};
use chrono::{DateTime, Utc};
use commandes::{
    ActionArret, DemandeTransitionArret, MotifIndisponible, PgCommandes, TransitionArret,
};
use comptes::Role;
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::erreurs_commandes::ErreurCommandesHttp;

// ── DTO ────────────────────────────────────────────────────────────────────

/// Corps commun des actions déclaratives d'arrêt.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = ActionArret)]
pub struct ActionArretDto {
    /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    pub uuid_client: Uuid,
    /// Horodatage de l'appareil. **Observation seulement** : le serveur écrit
    /// le sien, parce que `arrive_le` fonde une prime (TRF-06).
    pub horodatage_local: DateTime<Utc>,
    /// Pour `indisponible` : `vendeur_ferme` (défaut) ou
    /// `toutes_lignes_retirees`. Ignoré par les autres actions.
    pub motif: Option<String>,
}

impl ActionArretDto {
    /// Motif d'indisponibilité demandé, ou le défaut produit.
    fn motif(&self) -> Result<MotifIndisponible, commandes::ErreurCommandes> {
        match self.motif.as_deref() {
            None => Ok(MotifIndisponible::VendeurFerme),
            Some(m) => m.parse(),
        }
    }
}

/// État de l'arrêt et de sa course après la transition.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = EtatArretCourse)]
pub struct TransitionArretDto {
    /// Arrêt concerné.
    pub arret_id: Uuid,
    /// Statut de l'arrêt : `en_route` | `arrive` | `indisponible`.
    pub statut: String,
    /// Livraison porteuse.
    pub livraison_id: Uuid,
    /// Commande ancre.
    pub commande_id: Uuid,
    /// État de la livraison : `assignee` | `en_collecte` | `en_livraison`.
    pub livraison_etat: String,
    /// Collectes déjà faites (la remise n'en est pas une).
    pub collectes_faites: i16,
    /// Nombre total de COLLECTES de la course.
    pub collectes_total: i16,
    /// Vrai si la course vient de basculer EN_LIVRAISON.
    pub en_livraison: bool,
    /// Vrai si l'appel était un rejeu du même `uuid_client` : rien n'a été
    /// réécrit, aucun événement n'a été ré-émis.
    pub rejeu: bool,
}

impl From<TransitionArret> for TransitionArretDto {
    fn from(t: TransitionArret) -> Self {
        Self {
            arret_id: t.arret_id,
            statut: t.statut.comme_str().to_owned(),
            livraison_id: t.livraison_id,
            commande_id: t.commande_id,
            livraison_etat: t.livraison_etat.comme_str().to_owned(),
            collectes_faites: t.progression.nb_collectes,
            collectes_total: t.progression.nb_arrets,
            en_livraison: t.progression.en_livraison,
            rejeu: t.rejeu,
        }
    }
}

/// Exécute une action déclarative — le corps partagé des trois endpoints.
async fn transiter(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<ActionArretDto>,
    depot: web::Data<PgCommandes>,
    action: fn(&ActionArretDto) -> Result<ActionArret, commandes::ErreurCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Coursier)?;
    let (livraison_id, arret_id) = chemin.into_inner();
    let corps = corps.into_inner();

    let resultat = depot
        .transiter_arret(
            auth.compte_id,
            DemandeTransitionArret {
                livraison_id,
                arret_id,
                action: action(&corps)?,
                uuid_client: corps.uuid_client,
                horodatage_local: corps.horodatage_local,
            },
        )
        .await?;

    Ok(HttpResponse::Ok().json(TransitionArretDto::from(resultat)))
}

// ── Endpoints ──────────────────────────────────────────────────────────────

/// CMD-04 — le coursier déclare partir vers un arrêt.
///
/// Le PREMIER départ d'une course la fait passer EN_COLLECTE (data-model §3.2).
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/arrets/{arret_id}/en-route",
    tag = "courses",
    params(
        ("livraison_id" = Uuid, Path, description = "Course assignée à l'appelant."),
        ("arret_id" = Uuid, Path, description = "Arrêt de cette course."),
    ),
    request_body = ActionArretDto,
    responses(
        (status = 200, description = "Arrêt EN ROUTE (idempotent au rejeu du même uuid_client).",
         body = TransitionArretDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis, ou course assignée à un autre.",
         body = ErreurApiDto),
        (status = 404, description = "Arrêt inconnu, ou hors de la livraison indiquée.",
         body = ErreurApiDto),
        (status = 409, description = "Transition absente de la table fermée (data-model §3.3).",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/arrets/{arret_id}/en-route")]
pub async fn arret_en_route(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<ActionArretDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    transiter(auth, chemin, corps, depot, |_| Ok(ActionArret::EnRoute)).await
}

/// CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.
///
/// `arrive_le` est posé par le serveur : c'est la borne de départ de l'attente
/// facturable (prime TRF-06). C'est pour cela que `en_route → collecte`
/// n'existe pas — on ne saute pas une déclaration qui vaut de l'argent.
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/arrets/{arret_id}/arrive",
    tag = "courses",
    params(
        ("livraison_id" = Uuid, Path, description = "Course assignée à l'appelant."),
        ("arret_id" = Uuid, Path, description = "Arrêt de cette course, déjà EN ROUTE."),
    ),
    request_body = ActionArretDto,
    responses(
        (status = 200, description = "Arrêt ARRIVÉ, `arrive_le` posé par le serveur.",
         body = TransitionArretDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis, ou course assignée à un autre.",
         body = ErreurApiDto),
        (status = 404, description = "Arrêt inconnu, ou hors de la livraison indiquée.",
         body = ErreurApiDto),
        (status = 409, description = "Arriver sans être parti : transition absente de la table.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/arrets/{arret_id}/arrive")]
pub async fn arret_arrive(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<ActionArretDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    transiter(auth, chemin, corps, depot, |_| Ok(ActionArret::Arrive)).await
}

/// CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).
///
/// Vendeur fermé, ou plus une seule ligne à collecter. L'arrêt est compté
/// **résolu** (la course continue), son montant avancé retombe à zéro, et ses
/// lignes sont retirées de la commande — les frais de livraison, eux, ne
/// bougent pas (FR-050).
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/arrets/{arret_id}/indisponible",
    tag = "courses",
    params(
        ("livraison_id" = Uuid, Path, description = "Course assignée à l'appelant."),
        ("arret_id" = Uuid, Path, description = "Arrêt de cette course."),
    ),
    request_body = ActionArretDto,
    responses(
        (status = 200, description = "Arrêt INDISPONIBLE, compté résolu ; avance nulle, lignes \
         retirées, montants révisés.", body = TransitionArretDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis, ou course assignée à un autre.",
         body = ErreurApiDto),
        (status = 404, description = "Arrêt inconnu, ou hors de la livraison indiquée.",
         body = ErreurApiDto),
        (status = 409, description = "Arrêt déjà résolu : transition absente de la table.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/arrets/{arret_id}/indisponible")]
pub async fn arret_indisponible(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<ActionArretDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    transiter(auth, chemin, corps, depot, |c| {
        Ok(ActionArret::Indisponible(c.motif()?))
    })
    .await
}
