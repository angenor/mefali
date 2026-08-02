//! Surface HTTP **COURSIER** du cycle DSP : disponibilité, plafond du jour,
//! publication de position (DSP-01), puis offre courante et décision (DSP-04).
//!
//! Deux gardes, toujours les deux : le **rôle** `Coursier`, et la **propriété** —
//! un coursier ne lit et n'écrit que sa propre disponibilité et sa propre offre.
//! La propriété n'est pas contrôlée « après coup » : l'identité vient du jeton,
//! jamais du corps de la requête, si bien qu'il n'existe aucun chemin pour
//! écrire l'état d'un autre.
//!
//! Toute écriture porte `uuid_client` + `horodatage_local` (constitution V) et
//! est **idempotente**. ⚠ Ni la position ni l'acceptation n'entrent dans la file
//! hors-ligne de l'app — dérogation DÉCLARÉE au principe V (plan.md, Complexity
//! Tracking) : une position vieille de dix minutes réinscrirait un coursier
//! absent, et une offre acceptée deux minutes trop tard n'a plus d'objet.
//! L'horodatage SERVEUR fait foi ; `horodatage_local` est une observation.
//!
//! Erreurs rendues `{ code, message_cle }` par [`crate::erreurs_dispatch`] —
//! le MÊME mapping que la surface admin.

use actix_web::{get, post, put, web, HttpResponse};
use chrono::{DateTime, Utc};
use comptes::Role;
use dispatch::{Capacite, ErreurDispatch, InscriptionPool, MotifDisponibilite, PgDispatch};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::erreurs_dispatch::ErreurDispatchHttp;

// ── DTO ────────────────────────────────────────────────────────────────────

/// Bascule de disponibilité et déclaration du plafond d'avance du jour.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = BasculeDisponibilite)]
pub struct BasculeDisponibiliteDto {
    /// Vrai pour entrer dans le pool, faux pour en sortir **immédiatement**.
    pub en_ligne: bool,
    /// Ce que le coursier peut avancer aujourd'hui (unités mineures).
    /// Obligatoire pour se mettre en ligne, ignoré pour en sortir.
    pub plafond_declare_unites: Option<i64>,
}

/// Une capacité déclarée, telle que l'app l'affiche.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CapaciteCoursier)]
pub struct CapaciteDto {
    /// Famille de capacité (MVP : `transport`).
    pub famille: String,
    /// Valeur dans la famille (slug de transport).
    pub valeur: String,
}

impl From<&Capacite> for CapaciteDto {
    fn from(c: &Capacite) -> Self {
        Self {
            famille: c.famille.clone(),
            valeur: c.valeur.clone(),
        }
    }
}

/// État de disponibilité, tel que l'écran K1 l'affiche.
///
/// Les DEUX plafonds sont rendus : Yao voit toujours **lequel** s'applique
/// (`plafond_source`) et **pourquoi** (`palier_note_cle`). Un coursier à qui
/// l'on refuse une course sans lui dire que son palier le limite croira à un
/// bug.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = EtatDisponibilite)]
pub struct EtatDisponibiliteDto {
    /// Intention déclarée aujourd'hui.
    pub en_ligne: bool,
    /// Plafond déclaré du jour, ou `null` si rien n'a été déclaré (FR-011 :
    /// jamais reporté — l'app le redemande au nouveau jour).
    pub plafond_declare_unites: Option<i64>,
    /// Ce qui s'applique : `min(déclaré, palier de la grille)`.
    pub plafond_retenu_unites: i64,
    /// `grille_note` | `declaration`.
    pub plafond_source: String,
    /// Clé i18n du palier appliqué.
    pub palier_note_cle: String,
    /// Note du coursier, ou `null` tant qu'AVI n'existe pas.
    pub note_centiemes: Option<i32>,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Jour civil de la déclaration.
    pub jour: String,
    /// Capacités déclarées au dossier coursier.
    pub capacites: Vec<CapaciteDto>,
    /// Vrai seulement après une position publiée : l'intention ne suffit pas.
    pub dans_le_pool: bool,
    /// Période de publication attendue (paramètre de zone du cycle 008).
    pub periode_position_s: i64,
}

/// Publication de position.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = PublicationPosition)]
pub struct PositionDto {
    /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    pub uuid_client: Uuid,
    /// Horodatage de l'appareil. **Observation seulement** : le serveur écrit le
    /// sien (FR-055).
    pub horodatage_local: DateTime<Utc>,
    /// Latitude.
    pub lat: f64,
    /// Longitude.
    pub lon: f64,
    /// Précision annoncée par le téléphone (mètres), informative.
    pub precision_m: Option<i32>,
}

/// Ce que la publication rend à l'app.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = EtatPublicationPosition)]
pub struct EtatPublicationDto {
    /// Vrai si le coursier est (re)devenu membre du pool.
    pub dans_le_pool: bool,
    /// Durée de vie de l'inscription (secondes) — trois périodes manquées.
    pub ttl_s: i64,
    /// Période attendue de la prochaine publication (secondes).
    pub prochaine_publication_s: i64,
}

// ── Assemblage de l'état ───────────────────────────────────────────────────

/// Charge tout ce qu'il faut pour répondre : coursier exploitable, config de sa
/// zone, plafond du jour, appartenance au pool.
async fn etat_courant(
    depot: &PgDispatch,
    coursier: Uuid,
    maintenant: DateTime<Utc>,
) -> Result<EtatDisponibiliteDto, ErreurDispatch> {
    let exploitable = depot
        .coursier_exploitable(coursier)
        .await?
        .ok_or(ErreurDispatch::DossierCoursierInvalide)?;
    let config = depot.config(exploitable.zone).await?;
    let plafond = depot.plafond_du_jour(coursier, &config, maintenant).await?;
    let dans_le_pool = depot.etat_pool(coursier).await?.is_some();
    let en_ligne = depot.est_en_ligne(coursier, maintenant).await?;

    Ok(EtatDisponibiliteDto {
        en_ligne,
        plafond_declare_unites: plafond.declare_unites,
        plafond_retenu_unites: plafond.retenu_unites,
        plafond_source: plafond.source.comme_str().to_owned(),
        palier_note_cle: plafond.palier_cle.to_owned(),
        note_centiemes: plafond.note_centiemes,
        devise: plafond.devise,
        jour: plafond.jour.to_string(),
        capacites: exploitable
            .capacites
            .iter()
            .map(CapaciteDto::from)
            .collect(),
        dans_le_pool,
        periode_position_s: config.position_periode_s,
    })
}

// ── Endpoints ──────────────────────────────────────────────────────────────

/// `PUT /moi/disponibilite` — se mettre en ligne ou hors ligne.
///
/// ⚠ Le suffixe `_coursier` n'est pas décoratif : utoipa dérive l'`operationId`
/// du NOM DE LA FONCTION, et `vendeur_http::basculer_disponibilite` (bascule
/// d'un article en rupture) porte déjà le nom court. Deux `operationId`
/// identiques font échouer la génération des clients — donc la CI.
///
/// Passer `en_ligne: false` retire du pool **immédiatement**, sans attendre
/// l'expiration (FR-005) : un coursier qui a rangé sa moto ne doit pas voir son
/// téléphone sonner 90 s plus tard.
///
/// Se mettre en ligne exige un dossier valide et **au moins une capacité
/// déclarée** : sans véhicule, aucune course ne pourra jamais lui être proposée,
/// et le lui dire tout de suite vaut mieux qu'une attente muette.
#[utoipa::path(
    put,
    path = "/moi/disponibilite",
    tag = "dispatch",
    request_body = BasculeDisponibiliteDto,
    responses(
        (status = 200, description = "Disponibilité à jour, avec le plafond RETENU et son palier.",
         body = EtatDisponibiliteDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 409, description = "Dossier coursier invalide, ou course active (se mettre \
                                      hors ligne en course est un abandon, pas une sortie de pool).",
         body = ErreurApiDto),
        (status = 422, description = "Aucun véhicule déclaré, ou plafond manquant à la mise en ligne.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[put("/moi/disponibilite")]
pub async fn basculer_disponibilite_coursier(
    auth: Auth,
    corps: web::Json<BasculeDisponibiliteDto>,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Coursier)?;
    let corps = corps.into_inner();
    let maintenant = Utc::now();

    let exploitable = depot
        .coursier_exploitable(auth.compte_id)
        .await?
        .ok_or(ErreurDispatch::DossierCoursierInvalide)?;
    let config = depot.config(exploitable.zone).await?;

    if corps.en_ligne {
        if exploitable.capacites.is_empty() {
            return Err(ErreurDispatch::CapaciteNonDeclaree.into());
        }
        let Some(plafond) = corps.plafond_declare_unites else {
            return Err(ErreurDispatch::CapaciteNonDeclaree.into());
        };
        depot
            .declarer_plafond_jour(auth.compte_id, &config, plafond, maintenant)
            .await?;
        depot
            .declarer_en_ligne(auth.compte_id, &config, true, maintenant)
            .await?;
    } else {
        // Se mettre hors ligne AVEC une course en cours n'est pas une sortie de
        // pool : c'est un abandon, et il appartient à CRS. Le refuser ici évite
        // qu'une commande reste assignée à un coursier officiellement absent.
        if depot.course_active(auth.compte_id).await?.is_some() {
            return Err(ErreurDispatch::CourseActive.into());
        }
        depot
            .declarer_en_ligne(auth.compte_id, &config, false, maintenant)
            .await?;
        depot
            .sortir_du_pool(
                auth.compte_id,
                &config,
                MotifDisponibilite::Manuel,
                maintenant,
            )
            .await?;
    }

    Ok(HttpResponse::Ok().json(etat_courant(&depot, auth.compte_id, maintenant).await?))
}

/// `GET /moi/disponibilite` — l'état courant, tel que K1 l'affiche.
#[utoipa::path(
    get,
    path = "/moi/disponibilite",
    tag = "dispatch",
    responses(
        (status = 200, description = "État courant : en ligne, plafond retenu et son palier, \
                                      appartenance au pool.",
         body = EtatDisponibiliteDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 409, description = "Dossier coursier invalide.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/disponibilite")]
pub async fn lire_disponibilite(
    auth: Auth,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Coursier)?;
    Ok(HttpResponse::Ok().json(etat_courant(&depot, auth.compte_id, Utc::now()).await?))
}

/// `POST /moi/position` — publier sa position, et rester dans le pool.
///
/// `204` si le coursier n'est pas en ligne : la position n'est pas **refusée**,
/// elle est **ignorée** — l'app peut être en retard d'un tic après un « hors
/// ligne », et lui rendre une erreur ferait clignoter un écran pour rien.
///
/// **Idempotence** : rejouer la même position repousse simplement la durée de
/// vie ; aucun événement n'est écrit dans les deux cas (une position est un fait
/// éphémère qui se répète toutes les 30 s, et elle porte une coordonnée que la
/// minimisation interdit de journaliser).
#[utoipa::path(
    post,
    path = "/moi/position",
    tag = "dispatch",
    request_body = PositionDto,
    responses(
        (status = 200, description = "Position publiée ; l'inscription au pool est repoussée.",
         body = EtatPublicationDto),
        (status = 204, description = "Coursier hors ligne — position ignorée, pas refusée."),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 409, description = "Dossier coursier invalide.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/moi/position")]
pub async fn publier_position(
    auth: Auth,
    corps: web::Json<PositionDto>,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Coursier)?;
    let corps = corps.into_inner();
    let maintenant = Utc::now();

    let exploitable = depot
        .coursier_exploitable(auth.compte_id)
        .await?
        .ok_or(ErreurDispatch::DossierCoursierInvalide)?;
    let config = depot.config(exploitable.zone).await?;

    if !depot.est_en_ligne(auth.compte_id, maintenant).await? {
        return Ok(HttpResponse::NoContent().finish());
    }

    let plafond = depot
        .plafond_du_jour(auth.compte_id, &config, maintenant)
        .await?;
    let course_active = depot.course_active(auth.compte_id).await?;
    let inscription = InscriptionPool {
        coursier: auth.compte_id,
        zone: exploitable.zone,
        lat: corps.lat,
        lon: corps.lon,
        en_ligne: true,
        capacites: exploitable.capacites.clone(),
        note_centiemes: plafond.note_centiemes,
        plafond_unites: plafond.retenu_unites,
        devise: plafond.devise.clone(),
        course_active,
        age_s: 0,
    };

    let etait_dedans = depot.etat_pool(auth.compte_id).await?.is_some();
    if etait_dedans {
        depot.publier_position(&config, &inscription).await?;
    } else {
        // Première position après la mise en ligne : c'est CE passage qui fait
        // entrer dans le pool, et qui émet `coursier.disponibilite_changee`.
        depot
            .entrer_dans_le_pool(&config, &inscription, maintenant)
            .await?;
    }

    // Une course assignée fait suivre la progression : c'est la matière de
    // DSP-07 (« il ne se rapproche pas »), écrite ici parce que c'est le seul
    // endroit où une position fraîche passe.
    if let Some(livraison) = course_active {
        depot
            .observer_progression(livraison, corps.lat, corps.lon, &config, maintenant)
            .await?;
    }

    Ok(HttpResponse::Ok().json(EtatPublicationDto {
        dans_le_pool: true,
        ttl_s: config.pool_ttl_s,
        prochaine_publication_s: config.position_periode_s,
    }))
}

// ══════════════════════════════════════════════════════════════════════════
// Offre courante et décision (DSP-04)
// ══════════════════════════════════════════════════════════════════════════

/// Un arrêt de l'offre, tel que K2 l'affiche.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ArretOffre)]
pub struct ArretOffreDto {
    /// Rang d'affichage (1 = premier arrêt).
    pub ordre: i32,
    /// Prestataire visé.
    pub prestataire_id: Option<Uuid>,
    /// Nom affiché sur la carte.
    pub nom: String,
    /// Distance INTER-ARRÊTS (mètres) — « + 40 m » de la maquette.
    pub distance_m: i64,
}

/// La destination, **avant** acceptation : jamais de coordonnée (ARTCI).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DestinationOffre)]
pub struct DestinationDto {
    /// Nom de la zone de livraison.
    pub zone_nom: String,
    /// Distance approximative depuis le dernier arrêt (mètres arrondis).
    pub distance_m: i64,
    /// Clé i18n de la mention « adresse exacte après acceptation ».
    pub mention_cle: String,
}

/// Le gain, détaillé comme sur K2.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = GainOffre)]
pub struct GainDto {
    /// Gain total (unités mineures).
    pub total_unites: i64,
    /// Part de déplacement.
    pub deplacement_unites: i64,
    /// Part des arrêts supplémentaires.
    pub arrets_unites: i64,
    /// Part d'effort.
    pub effort_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
}

/// Ce que le coursier devra avancer, avec son plafond.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = AvanceOffre)]
pub struct AvanceDto {
    /// Montant à avancer (unités mineures).
    pub montant_unites: i64,
    /// Plafond RETENU du coursier — pourquoi il peut la prendre.
    pub plafond_retenu_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
}

/// L'offre en vol, telle que l'écran K2 la rend.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = OffreCourante)]
pub struct OffreCouranteDto {
    /// Offre concernée.
    pub offre_id: Uuid,
    /// Commande offerte.
    pub commande_id: Uuid,
    /// `cascade` | `broadcast`.
    pub mode: String,
    /// **AUTORITÉ** du compte à rebours : le widget compte, le serveur tranche.
    pub echeance_le: DateTime<Utc>,
    /// Durée totale du compte à rebours (secondes).
    pub timer_s: i64,
    /// Secondes restantes à l'instant de la lecture.
    pub restant_s: i64,
    /// Arrêts dans l'ordre optimisé du devis FIGÉ.
    pub arrets: Vec<ArretOffreDto>,
    /// Destination approximative.
    pub destination: DestinationDto,
    /// Gain détaillé.
    pub gain: GainDto,
    /// Avance et plafond.
    pub avance: AvanceDto,
    /// Vrai si les distances viennent du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
}

/// Décision sur une offre — accepter ou refuser.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DecisionOffre)]
pub struct DecisionOffreDto {
    /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    pub uuid_client: Uuid,
    /// Horodatage de l'appareil — **observation seulement**.
    pub horodatage_local: DateTime<Utc>,
}

/// Résultat d'une acceptation.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = AcceptationOffre)]
pub struct AcceptationDto {
    /// Commande affectée.
    pub commande_id: Uuid,
    /// Livraison assignée.
    pub livraison_id: Uuid,
    /// État de la livraison après affectation.
    pub etat_livraison: String,
    /// Vrai si l'appel était un rejeu — même corps, aucune seconde affectation.
    pub rejeu: bool,
}

/// Résultat d'un refus.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RefusOffre)]
pub struct RefusDto {
    /// Issue de l'offre après refus.
    pub issue: String,
}

/// `GET /courses/offre-courante` — l'offre en vol de CE coursier, ou `204`.
///
/// Une offre **échue** rend `204` **même si le tic n'a pas encore passé** :
/// l'échéance persistée est l'autorité, et le tic ne fait qu'écrire ce que la
/// lecture savait déjà (research R1).
///
/// C'est l'app qui **va chercher** son offre (toutes les 2 s tant qu'un écran de
/// dispatch est monté) : le push haute priorité appartient à NTF-01, et le jour
/// où il arrivera il réveillera l'app, qui appellera ce même endpoint — aucun
/// contrat à refaire (research R16).
#[utoipa::path(
    get,
    path = "/courses/offre-courante",
    tag = "dispatch",
    responses(
        (status = 200, description = "Offre en vol : arrêts, gain, avance, échéance.",
         body = OffreCouranteDto),
        (status = 204, description = "Aucune offre en vol (ou offre échue)."),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/courses/offre-courante")]
pub async fn offre_courante(
    auth: Auth,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Coursier)?;
    let maintenant = Utc::now();
    let Some(offre) = depot.offre_courante(auth.compte_id, maintenant).await? else {
        return Ok(HttpResponse::NoContent().finish());
    };
    let contenu = depot.contenu_offre(&offre, maintenant).await?;
    Ok(HttpResponse::Ok().json(vers_dto(&offre, contenu, maintenant)))
}

/// `POST /courses/offres/{offre_id}/accepter` — prendre la course.
///
/// **Idempotent** (FR-054) : un rejeu avec le même `uuid_client` rend le même
/// `200` et le même corps ; il ne crée ni seconde affectation ni second
/// événement.
///
/// Un `409 deja_prise` n'est **pas** un échec technique : l'app l'affiche comme
/// l'état K2-1b, ton neutre, sans blâme et **sans pénalité** (FR-049).
#[utoipa::path(
    post,
    path = "/courses/offres/{offre_id}/accepter",
    tag = "dispatch",
    params(("offre_id" = Uuid, Path, description = "Offre adressée à l'appelant.")),
    request_body = DecisionOffreDto,
    responses(
        (status = 200, description = "Course affectée (idempotent au rejeu).", body = AcceptationDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 404, description = "Offre inconnue, ou adressée à un autre coursier.",
         body = ErreurApiDto),
        (status = 409, description = "Course déjà prise (sans pénalité), offre échue, \
                                      ou course active.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/offres/{offre_id}/accepter")]
pub async fn accepter_offre(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DecisionOffreDto>,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Coursier)?;
    let faite = depot
        .accepter_offre(
            chemin.into_inner(),
            auth.compte_id,
            corps.uuid_client,
            Utc::now(),
        )
        .await?;
    Ok(HttpResponse::Ok().json(AcceptationDto {
        commande_id: faite.commande,
        livraison_id: faite.livraison,
        etat_livraison: "assignee".to_owned(),
        rejeu: faite.rejeu,
    }))
}

/// `POST /courses/offres/{offre_id}/refuser` — passer son tour.
///
/// Le candidat suivant est sollicité **immédiatement**, sans attendre la fin du
/// compte à rebours (FR-050). Un refus compte dans le taux d'acceptation ; il
/// n'entraîne **aucune** sanction — l'anti-abus (DSP-08) est hors périmètre.
#[utoipa::path(
    post,
    path = "/courses/offres/{offre_id}/refuser",
    tag = "dispatch",
    params(("offre_id" = Uuid, Path, description = "Offre adressée à l'appelant.")),
    request_body = DecisionOffreDto,
    responses(
        (status = 200, description = "Offre refusée ; le suivant est sollicité aussitôt.",
         body = RefusDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 404, description = "Offre inconnue, ou adressée à un autre coursier.",
         body = ErreurApiDto),
        (status = 409, description = "Offre déjà conclue.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/offres/{offre_id}/refuser")]
pub async fn refuser_offre(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DecisionOffreDto>,
    depot: web::Data<PgDispatch>,
) -> Result<HttpResponse, ErreurDispatchHttp> {
    auth.exiger_role(Role::Coursier)?;
    let offre = depot
        .refuser_offre(
            chemin.into_inner(),
            auth.compte_id,
            corps.uuid_client,
            Utc::now(),
        )
        .await?;
    // Le candidat suivant, TOUT DE SUITE (FR-050) : attendre le tic ferait
    // perdre au client les secondes que le refus vient justement d'économiser.
    //
    // ⚠ Relance EN LIGNE, pas détachée : une tâche détachée n'est pas
    // observable (ni par un test, ni par un journal de requête), et le `spawn`
    // d'Actix exige un contexte que tous les appelants n'ont pas. Le coursier
    // attend quelques millisecondes de plus — le client, lui, gagne 40 s.
    if let Err(e) = depot.dispatcher(offre.commande, Utc::now()).await {
        tracing::warn!(
            commande = %offre.commande, erreur = %e,
            "relance après refus impossible — le tic reprendra la commande",
        );
    }
    Ok(HttpResponse::Ok().json(RefusDto {
        issue: offre.issue.comme_str().to_owned(),
    }))
}

/// Assemble le DTO d'offre depuis le domaine.
fn vers_dto(
    offre: &dispatch::Offre,
    contenu: dispatch::ContenuOffre,
    maintenant: DateTime<Utc>,
) -> OffreCouranteDto {
    OffreCouranteDto {
        offre_id: offre.id,
        commande_id: offre.commande,
        mode: offre.mode.comme_str().to_owned(),
        echeance_le: offre.echeance_le,
        timer_s: (offre.echeance_le - offre.emise_le).num_seconds().max(0),
        restant_s: offre.restant_s(maintenant),
        arrets: contenu
            .arrets
            .into_iter()
            .map(|a| ArretOffreDto {
                ordre: a.ordre,
                prestataire_id: a.prestataire_id,
                nom: a.nom,
                distance_m: a.distance_m,
            })
            .collect(),
        destination: DestinationDto {
            zone_nom: contenu.destination_zone_nom,
            distance_m: contenu.destination_distance_m,
            mention_cle: "dispatch.offre.adresse_apres_acceptation".to_owned(),
        },
        gain: GainDto {
            total_unites: contenu.gain_total_unites,
            deplacement_unites: contenu.gain_deplacement_unites,
            arrets_unites: contenu.gain_arrets_unites,
            effort_unites: contenu.gain_effort_unites,
            devise: offre.devise.clone(),
        },
        avance: AvanceDto {
            montant_unites: offre.montant_a_avancer,
            plafond_retenu_unites: contenu.plafond_retenu_unites,
            devise: offre.devise.clone(),
        },
        degraded: contenu.degraded,
    }
}
