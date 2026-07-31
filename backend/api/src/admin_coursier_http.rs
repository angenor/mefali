//! Surface HTTP **EXPLOITATION** du cycle CRS : blocages de remise, voie dépôt,
//! exposition cash, indemnisations et lecture des preuves d'échec.
//!
//! **Périmètre assumé (R16)** : aucun écran Nuxt ce cycle. ADM-02/04/07
//! habilleront ces routes ; ce que CRS doit livrer, c'est de quoi débloquer un
//! coursier planté devant une porte et répondre d'une décision d'argent — sans
//! attendre un cycle qui n'existe pas encore. Elles sont donc exercées **par
//! API** dans les tests, patron du cycle 009.
//!
//! Rôle `Admin` partout. Chaque écriture est **tracée** (qui, quand, motif) et
//! émet son événement dans la même transaction que la mutation.

use actix_web::{get, post, web, HttpResponse};
use chrono::Utc;
use commandes::PgCommandes;
use comptes::Role;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::erreurs_commandes::ErreurCommandesHttp;

// ── Blocages de remise (T036 — FR-044, FR-055) ─────────────────────────────

/// Filtre de zone : l'exploitation travaille par ville.
#[derive(Debug, Deserialize, IntoParams)]
pub struct FiltreZoneDto {
    /// Zone dont on veut les blocages. Absente = toutes les zones.
    pub zone_id: Option<Uuid>,
}

/// Une commande dont le code de remise est bloqué.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RemiseBloquee)]
pub struct RemiseBloqueeDto {
    /// Commande verrouillée.
    pub commande_id: Uuid,
    /// Référence courte, pour se parler au téléphone.
    pub reference: String,
    /// Livraison portée — celle où le coursier est resté devant la porte.
    pub livraison_id: Option<Uuid>,
    /// Zone de la commande.
    pub zone_id: Uuid,
    /// Essais consommés au blocage.
    pub essais_code: i16,
    /// Instant du blocage — **l'ordre de la liste**, le plus ancien d'abord.
    pub bloque_le: chrono::DateTime<Utc>,
    /// Coursier assigné, s'il l'est encore.
    pub coursier_id: Option<Uuid>,
}

/// La file des blocages d'une zone.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RemisesBloquees)]
pub struct RemisesBloqueesDto {
    /// Commandes bloquées, **la plus ancienne d'abord**.
    pub remises: Vec<RemiseBloqueeDto>,
}

/// **FR-044** — les remises dont le code est épuisé et le blocage non levé.
///
/// Le verrou du code protège un secret à quatre chiffres, mais il laisse une
/// commande à la porte du client. Sans cette lecture, l'alerte
/// `remise.code_epuise` partirait dans l'outbox sans que personne ne puisse
/// répondre — et un humain ne s'abonne pas à un journal.
#[utoipa::path(
    get,
    path = "/admin/remises/bloquees",
    tag = "coursier-admin",
    params(FiltreZoneDto),
    responses(
        (status = 200, description = "Blocages en cours, le plus ancien d'abord.",
         body = RemisesBloqueesDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/remises/bloquees")]
pub async fn remises_bloquees(
    auth: Auth,
    filtre: web::Query<FiltreZoneDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Admin)?;
    let remises = depot.remises_bloquees(filtre.zone_id).await?;
    Ok(HttpResponse::Ok().json(RemisesBloqueesDto {
        remises: remises
            .into_iter()
            .map(|r| RemiseBloqueeDto {
                commande_id: r.commande_id,
                reference: r.reference,
                livraison_id: r.livraison_id,
                zone_id: r.zone_id,
                essais_code: r.essais_code,
                bloque_le: r.bloque_le,
                coursier_id: r.coursier_id,
            })
            .collect(),
    }))
}

/// Motif d'une décision d'exploitation — **jamais du texte libre**.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeDeblocage)]
pub struct DemandeDeblocageDto {
    /// Clé i18n du motif (obligatoire).
    pub motif_cle: String,
}

/// **FR-055** — l'exploitation lève le blocage du code, avec motif tracé.
///
/// Le compteur d'essais retombe à zéro : une levée qui laisserait le compteur
/// au plafond serait inopérante — le premier essai suivant rebloquerait la
/// commande, et l'exploitation croirait avoir agi.
#[utoipa::path(
    post,
    path = "/admin/commandes/{commande_id}/code/debloquer",
    tag = "coursier-admin",
    params(("commande_id" = Uuid, Path, description = "Commande dont le code est bloqué.")),
    request_body = DemandeDeblocageDto,
    responses(
        (status = 204, description = "Blocage levé, compteur remis à zéro, événement émis."),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 404, description = "Commande inconnue.", body = ErreurApiDto),
        (status = 409, description = "Le code n'est pas bloqué.", body = ErreurApiDto),
        (status = 422, description = "Motif absent.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/commandes/{commande_id}/code/debloquer")]
pub async fn debloquer_code(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeDeblocageDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Admin)?;
    depot
        .debloquer_code(
            chemin.into_inner(),
            auth.compte_id,
            &corps.motif_cle,
            Utc::now(),
        )
        .await?;
    Ok(HttpResponse::NoContent().finish())
}

// ── Voie dépôt (T037 — FR-116) ─────────────────────────────────────────────

/// Ouverture ou fermeture de la voie « dépôt » sur une commande.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeDepot)]
pub struct DemandeDepotDto {
    /// `true` ouvre la voie, `false` la referme.
    pub autorise: bool,
    /// Clé i18n du motif (obligatoire dans les deux sens).
    pub motif_cle: String,
}

/// État de la voie dépôt après décision.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DecisionDepot)]
pub struct DecisionDepotDto {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// La voie dépôt est-elle ouverte ?
    pub depot_autorise: bool,
    /// Motif retenu.
    pub motif_cle: String,
}

/// **FR-116** — ouvre (ou referme) la voie « dépôt convenu » sur une commande.
///
/// Le cadrage §7.4-5 dit « mode dépôt autorisé **par le client** ». Tant
/// qu'aucune surface cliente ne le porte, c'est l'exploitation qui l'ouvre à sa
/// demande, au téléphone, avec un motif tracé — le contrat ne changera pas
/// quand l'app cliente reprendra la main.
///
/// **Fermé par défaut** : un défaut ouvert aurait rendu le dépôt possible
/// partout sans que personne ne l'ait décidé.
#[utoipa::path(
    post,
    path = "/admin/commandes/{commande_id}/depot",
    tag = "coursier-admin",
    params(("commande_id" = Uuid, Path, description = "Commande concernée.")),
    request_body = DemandeDepotDto,
    responses(
        (status = 200, description = "Décision enregistrée et tracée.", body = DecisionDepotDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 404, description = "Commande inconnue.", body = ErreurApiDto),
        (status = 422, description = "Motif absent.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/commandes/{commande_id}/depot")]
pub async fn autoriser_depot(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeDepotDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Admin)?;
    let decision = depot
        .autoriser_depot(
            chemin.into_inner(),
            auth.compte_id,
            corps.autorise,
            &corps.motif_cle,
            Utc::now(),
        )
        .await?;
    Ok(HttpResponse::Ok().json(DecisionDepotDto {
        commande_id: decision.commande_id,
        depot_autorise: decision.depot_autorise,
        motif_cle: decision.motif_cle,
    }))
}

// ── Lecture des preuves d'échec (T057 — FR-063) ────────────────────────────

/// Durée de vie des URL présignées servies à l'exploitation.
///
/// Le temps de regarder une photo et de répondre au client, pas davantage : une
/// URL qui traînerait une heure dans un onglet serait une heure d'accès à la
/// porte d'un domicile.
const TTL_PHOTOS_PREUVE: std::time::Duration = std::time::Duration::from_secs(15 * 60);

/// Un appel journalisé, tel que l'exploitation le lit.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = AppelJournalise)]
pub struct AppelJournaliseDto {
    /// Appel.
    pub id: Uuid,
    /// `client` | `vendeur`. **Aucun numéro** — le serveur n'en a jamais vu.
    pub vers: String,
    /// Prestataire appelé (si `vers = vendeur`).
    pub prestataire_id: Option<Uuid>,
    /// `suivi` | `substitution` | `client_absent`.
    pub motif: String,
    /// Issue DÉCLARÉE par le coursier — affichée, jamais un critère (R19).
    pub issue: String,
    /// Horodatage **serveur** — celui qui fonde l'espacement.
    pub passe_le: chrono::DateTime<Utc>,
    /// Horodatage de l'appareil — observation seulement.
    pub passe_le_local: chrono::DateTime<Utc>,
}

/// Une photo de preuve, présignée.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PhotoPreuve)]
pub struct PhotoPreuveDto {
    /// Photo.
    pub id: Uuid,
    /// Prise le.
    pub prise_le: chrono::DateTime<Utc>,
    /// Purgée le — la preuve reste **datée**, ses octets sont partis.
    pub purgee_le: Option<chrono::DateTime<Utc>>,
    /// URL présignée de courte durée. Absente si purgée ou indisponible.
    pub url: Option<String>,
}

/// Le dossier de preuves d'une livraison (FR-063).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PreuvesExploitation)]
pub struct PreuvesExploitationDto {
    /// **Tous** les appels — ceux qui ne comptent pas éclairent autant que les
    /// autres quand un client conteste.
    pub appels: Vec<AppelJournaliseDto>,
    /// Photos de preuve.
    pub photos: Vec<PhotoPreuveDto>,
    /// Instant du basculement — absent si les trois preuves ne l'ont jamais été.
    pub reunies_le: Option<chrono::DateTime<Utc>>,
    /// L'état recalculé des trois preuves, et ce qui manque.
    pub etat: crate::coursier_http::EtatPreuvesDto,
}

/// CRS-05 (exploitation) — le dossier de preuves d'une livraison (FR-063).
///
/// C'est ce qui rend les preuves **lisibles**. Sans cet endpoint, elles
/// existeraient en base sans que personne ne puisse répondre à un client qui
/// conteste un échec — et une preuve que personne ne lit ne protège personne.
///
/// ⚠ Aucun numéro de téléphone n'en sort : le serveur n'en a jamais journalisé.
#[utoipa::path(
    get,
    path = "/admin/livraisons/{livraison_id}/preuves",
    tag = "coursier-admin",
    params(("livraison_id" = Uuid, Path, description = "Livraison dont on lit les preuves.")),
    responses(
        (status = 200, description = "Dossier de preuves complet.", body = PreuvesExploitationDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/livraisons/{livraison_id}/preuves")]
pub async fn preuves_de_livraison(
    auth: Auth,
    chemin: web::Path<Uuid>,
    coursier: web::Data<coursier::PgCoursier>,
) -> Result<HttpResponse, crate::coursier_http::ErreurCoursierHttp> {
    auth.exiger_role(Role::Admin)?;
    let dossier = coursier
        .preuves_pour_exploitation(chemin.into_inner(), TTL_PHOTOS_PREUVE)
        .await?;
    Ok(HttpResponse::Ok().json(PreuvesExploitationDto {
        appels: dossier
            .appels
            .into_iter()
            .map(|a| AppelJournaliseDto {
                id: a.id,
                vers: a.vers.comme_str().to_owned(),
                prestataire_id: a.prestataire_id,
                motif: a.motif.comme_str().to_owned(),
                issue: a.issue.comme_str().to_owned(),
                passe_le: a.passe_le,
                passe_le_local: a.passe_le_local,
            })
            .collect(),
        photos: dossier
            .photos
            .into_iter()
            .map(|p| PhotoPreuveDto {
                id: p.id,
                prise_le: p.prise_le,
                purgee_le: p.purgee_le,
                url: p.url,
            })
            .collect(),
        reunies_le: dossier.reunies_le,
        etat: dossier.etat.into(),
    }))
}
