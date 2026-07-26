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

use actix_multipart::form::{bytes::Bytes as ChampFichier, text::Text, MultipartForm};
use actix_web::{post, web, HttpResponse};
use chrono::{DateTime, Utc};
use commandes::{
    ActionArret, DemandeRupture, DemandeTransitionArret, MotifIndisponible, PgCommandes,
    ResolutionRupture, TransitionArret,
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
    /// Arrêts effectivement COLLECTÉS (la remise n'en est pas une).
    pub collectes_faites: i16,
    /// Arrêts RÉSOLUS — collectés **ou** indisponibles. C'est ce compteur qui
    /// dit au coursier ce qui lui reste à faire : un étal fermé est fini, même
    /// s'il n'y a rien pris.
    pub collectes_resolues: i16,
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
            collectes_resolues: t.progression.nb_resolues,
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

// ── Substitutions (US7 / CMD-06) ───────────────────────────────────────────

/// Partie JSON `demande` du multipart de rupture.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeRupture)]
pub struct DemandeRuptureDto {
    /// Ligne de commande devenue indisponible.
    pub ligne_id: Uuid,
    /// Clé d'idempotence (UUIDv7 client, constitution V).
    pub uuid_client: Uuid,
    /// `retirer` | `remplacer`. Absent = suivre la préférence du client, dont
    /// le défaut sûr est le retrait : on ne fait jamais payer par défaut.
    pub resolution: Option<String>,
    /// Article proposé — obligatoire pour `remplacer`, **du même vendeur**.
    pub article_propose_id: Option<Uuid>,
    /// Prix unitaire proposé (unités mineures) — obligatoire pour `remplacer`.
    pub prix_propose_unites: Option<i64>,
}

/// Schéma OpenAPI du multipart de rupture (contrat honnête : le handler lit un
/// `multipart/form-data`, pas un JSON — le client généré produit un vrai
/// multipart). Sert UNIQUEMENT à `#[utoipa::path]`.
#[derive(ToSchema)]
#[schema(as = RuptureMultipart)]
#[allow(dead_code)]
pub struct RuptureMultipartDto {
    /// Partie JSON `demande`.
    pub demande: DemandeRuptureDto,
    /// Photo du remplacement (obligatoire pour `remplacer` — FR-045).
    #[schema(value_type = Option<String>, format = Binary)]
    pub photo: Option<Vec<u8>>,
}

/// Multipart de rupture : partie `demande` (JSON) + `photo` binaire.
#[derive(Debug, MultipartForm)]
pub struct RuptureForm {
    /// Partie JSON `demande`.
    demande: Text<String>,
    /// Photo du remplacement — 5 Mo max.
    #[multipart(limit = "5MB")]
    photo: Option<ChampFichier>,
}

/// Issue immédiate d'une rupture déclarée.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = IssueRupture)]
pub struct IssueRuptureDto {
    /// `ligne_retiree` | `proposition_ouverte`.
    pub issue: String,
    /// Proposition créée (`null` si l'article a été retiré).
    pub substitution_id: Option<Uuid>,
    /// Secondes dont dispose le client pour décider.
    pub reste_s: Option<i64>,
    /// Écart de prix en pourcent (signé).
    pub ecart_pourcent: Option<i64>,
    /// Montant sorti du total (`null` si une proposition a été ouverte).
    pub montant_retire: Option<i64>,
    /// Montant des articles après révision.
    pub montant_articles_unites: Option<i64>,
    /// Total après révision — **le devis de livraison n'a pas bougé** (FR-050).
    pub total_unites: Option<i64>,
}

impl From<commandes::IssueRupture> for IssueRuptureDto {
    fn from(i: commandes::IssueRupture) -> Self {
        match i {
            commandes::IssueRupture::LigneRetiree {
                montant_retire,
                montants,
                ..
            } => Self {
                issue: "ligne_retiree".to_owned(),
                substitution_id: None,
                reste_s: None,
                ecart_pourcent: None,
                montant_retire: Some(montant_retire),
                montant_articles_unites: Some(montants.montant_articles_unites),
                total_unites: Some(montants.total_unites),
            },
            commandes::IssueRupture::PropositionOuverte {
                substitution_id,
                reste_s,
                ecart_pourcent,
            } => Self {
                issue: "proposition_ouverte".to_owned(),
                substitution_id: Some(substitution_id),
                reste_s: Some(reste_s),
                ecart_pourcent: Some(ecart_pourcent),
                montant_retire: None,
                montant_articles_unites: None,
                total_unites: None,
            },
        }
    }
}

/// CMD-06 — le coursier déclare un article indisponible et applique la
/// préférence du client (FR-044/045).
///
/// Trois chemins, deux invariants : le **devis de livraison ne bouge jamais**
/// (FR-050) et le total reste payé **en une fois** (FR-049). La proposition de
/// remplacement est refusée si l'article vient d'un **autre vendeur** (FR-048)
/// ou si l'écart de prix dépasse le plafond de zone (FR-047).
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/substitutions",
    tag = "courses",
    params(("livraison_id" = Uuid, Path, description = "Course assignée à l'appelant.")),
    request_body(content = RuptureMultipartDto, content_type = "multipart/form-data",
                 description = "Partie `demande` (JSON) + `photo` binaire du remplacement."),
    responses(
        (status = 200, description = "Article retiré (montants révisés) ou proposition ouverte \
         avec sa fenêtre de décision.", body = IssueRuptureDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis, ou course assignée à un autre.",
         body = ErreurApiDto),
        (status = 409, description = "Autre vendeur, écart de prix hors plafond, ou ligne déjà \
         résolue.", body = ErreurApiDto),
        (status = 422, description = "Demande mal formée (photo ou prix manquant).",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/substitutions")]
pub async fn declarer_rupture(
    auth: Auth,
    _chemin: web::Path<Uuid>,
    form: MultipartForm<RuptureForm>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Coursier)?;
    let form = form.into_inner();
    let dto: DemandeRuptureDto = serde_json::from_str(&form.demande).map_err(|_| {
        ErreurCommandesHttp::Domaine(commandes::ErreurCommandes::PanierInvalide(
            "partie `demande` illisible".to_owned(),
        ))
    })?;

    let resolution = match dto.resolution.as_deref() {
        None | Some("retirer") if dto.article_propose_id.is_none() => {
            Some(ResolutionRupture::Retirer)
        }
        None => None,
        Some("retirer") => Some(ResolutionRupture::Retirer),
        Some("remplacer") => {
            // Photo ET prix sont exigés par FR-045 : une proposition sans photo
            // demande au client de décider à l'aveugle.
            let (Some(article_propose_id), Some(prix_propose_unites), Some(photo)) = (
                dto.article_propose_id,
                dto.prix_propose_unites,
                form.photo.as_ref(),
            ) else {
                return Err(ErreurCommandesHttp::Domaine(
                    commandes::ErreurCommandes::PanierInvalide(
                        "un remplacement exige un article, un prix et une photo".to_owned(),
                    ),
                ));
            };
            Some(ResolutionRupture::Remplacer {
                article_propose_id,
                prix_propose_unites,
                photo: photo.data.to_vec(),
                mime: photo
                    .content_type
                    .as_ref()
                    .map(|m| m.to_string())
                    .unwrap_or_else(|| "image/jpeg".to_owned()),
            })
        }
        Some(_) => {
            return Err(ErreurCommandesHttp::Domaine(
                commandes::ErreurCommandes::PanierInvalide(
                    "résolution inconnue : `retirer` ou `remplacer`".to_owned(),
                ),
            ))
        }
    };

    let issue = depot
        .declarer_rupture(
            auth.compte_id,
            DemandeRupture {
                ligne_id: dto.ligne_id,
                uuid_client: dto.uuid_client,
                resolution,
            },
            Utc::now(),
        )
        .await?;
    Ok(HttpResponse::Ok().json(IssueRuptureDto::from(issue)))
}
