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
