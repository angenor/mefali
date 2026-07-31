//! Surface HTTP du cycle CRS (crate `coursier`) : course active complète,
//! appels journalisés, relevés de présence, preuves d'échec, caisse et journée.
//!
//! Contrat auto-collecté par utoipa-actix-web (patron `course_http` /
//! `dispatch_http`). Toute route sous `bearerAuth`. Erreurs rendues
//! `{ code, message_cle }` (clés i18n fr, jamais de texte en dur).
//!
//! **Garde double partout** : rôle **et** propriété. Un coursier ne lit et
//! n'écrit que sa propre course, sa propre caisse, ses propres preuves — y
//! compris au REJEU d'une action venue de la file (FR-006).

use actix_web::http::StatusCode;
use actix_web::{get, patch, post, web, HttpResponse, ResponseError};
use chrono::{DateTime, Utc};
use coursier::{ErreurCoursier, PgCoursier};
use serde::{Deserialize, Serialize};
use serde_json::json;
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::Role;

use crate::auth_http::{Auth, ErreurApi, ErreurApiDto};

// ── Erreur HTTP locale ─────────────────────────────────────────────────────

/// Erreur HTTP du module coursier : auth/rôle (`ErreurApi`) ou domaine.
#[derive(Debug)]
pub enum ErreurCoursierHttp {
    /// Erreur d'authentification / de rôle (réutilise le mapping comptes).
    Api(ErreurApi),
    /// Refus métier ou erreur d'infrastructure du domaine coursier.
    Coursier(ErreurCoursier),
}

impl From<ErreurApi> for ErreurCoursierHttp {
    fn from(e: ErreurApi) -> Self {
        ErreurCoursierHttp::Api(e)
    }
}

impl From<ErreurCoursier> for ErreurCoursierHttp {
    fn from(e: ErreurCoursier) -> Self {
        ErreurCoursierHttp::Coursier(e)
    }
}

impl std::fmt::Display for ErreurCoursierHttp {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErreurCoursierHttp::Api(e) => write!(f, "{e}"),
            ErreurCoursierHttp::Coursier(e) => write!(f, "{e}"),
        }
    }
}

/// Statut HTTP d'un refus de domaine coursier (contrats §1).
///
/// `CourseNonProprietaire` rend `403` et **jamais** `404` : contrairement au
/// suivi client, le coursier SAIT qu'une course existe — il vient d'en être
/// retiré. Lui répondre « inconnue » le laisserait réessayer indéfiniment,
/// alors qu'il doit voir la réconciliation à l'écran (FR-084).
pub fn statut_coursier(e: &ErreurCoursier) -> StatusCode {
    match e {
        ErreurCoursier::AucuneCourseActive => StatusCode::NO_CONTENT,
        ErreurCoursier::CourseNonProprietaire => StatusCode::FORBIDDEN,
        ErreurCoursier::IndemnisationInconnue(_) => StatusCode::NOT_FOUND,
        ErreurCoursier::PreuvesIncompletes
        | ErreurCoursier::IndemnisationDejaDecidee
        | ErreurCoursier::CodeNonBloque => StatusCode::CONFLICT,
        ErreurCoursier::DepotNonAutorise
        | ErreurCoursier::MotifRequis
        | ErreurCoursier::DemandeInvalide(_) => StatusCode::UNPROCESSABLE_ENTITY,
        ErreurCoursier::EcritureImmuable => StatusCode::CONFLICT,
        // Infrastructure et configuration : rien à exposer.
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

impl ResponseError for ErreurCoursierHttp {
    fn status_code(&self) -> StatusCode {
        match self {
            ErreurCoursierHttp::Api(e) => e.status_code(),
            ErreurCoursierHttp::Coursier(e) => statut_coursier(e),
        }
    }

    fn error_response(&self) -> HttpResponse {
        match self {
            ErreurCoursierHttp::Api(e) => e.error_response(),
            ErreurCoursierHttp::Coursier(e) => {
                let (code, message_cle) = match e.message_cle() {
                    Some(cle) => (cle.to_owned(), format!("coursier.erreur.{cle}")),
                    None => (
                        "erreur_interne".to_owned(),
                        "coursier.erreur.interne".to_owned(),
                    ),
                };
                HttpResponse::build(statut_coursier(e))
                    .json(json!({ "code": code, "message_cle": message_cle }))
            }
        }
    }
}

// ── DTO ────────────────────────────────────────────────────────────────────

/// Une ligne d'article à acheter chez un vendeur (K3).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = LigneArret)]
pub struct LigneArretDto {
    /// Ligne de commande.
    pub ligne_id: Uuid,
    /// Libellé de l'article.
    pub libelle: String,
    /// Quantité commandée.
    pub quantite: i32,
    /// Prix unitaire VERROUILLÉ à la création (unités mineures).
    pub prix_unitaire_unites: i64,
    /// `remplacer` | `appeler` | `retirer`.
    pub preference_substitution: String,
    /// `presente` | `remplacee` | `retiree`.
    pub statut: String,
}

/// Un arrêt de collecte, complet.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ArretCourse)]
pub struct ArretCourseDto {
    /// Arrêt de la course.
    pub arret_id: Uuid,
    /// Rang dans l'ordre optimisé.
    pub ordre: i16,
    /// Prestataire visé.
    pub prestataire_id: Uuid,
    /// Nom du vendeur.
    pub nom: String,
    /// Position attendue du site.
    pub site_lat: f64,
    /// Position attendue du site.
    pub site_lon: f64,
    /// Distance depuis l'arrêt précédent (m). **Absente** : le tronçon n'est pas
    /// figé au devis et ce cycle ne recalcule aucun itinéraire (FR-009).
    pub distance_precedent_m: Option<i64>,
    /// base16(sha256(jeton)) — match hors-ligne du QR de plaque.
    pub empreinte_jeton: String,
    /// base16(sha256(prestataire ‖ code)) — mode dégradé hors-ligne.
    pub empreinte_code: String,
    /// Montant à avancer à CE vendeur, lignes retirées exclues (FR-013).
    pub montant_avance: i64,
    /// Photo de récupération exigée (politique résolue).
    pub photo_exigee: bool,
    /// Rayon max de scan (m).
    pub distance_max_m: i64,
    /// `a_collecter` | `en_route` | `arrive` | `collecte` | `indisponible`.
    pub statut: String,
    /// Départ déclaré vers l'arrêt.
    pub en_route_le: Option<DateTime<Utc>>,
    /// Arrivée sur l'arrêt.
    pub arrive_le: Option<DateTime<Utc>>,
    /// Collecte validée.
    pub collecte_le: Option<DateTime<Utc>>,
    /// Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé.
    pub telephone_vendeur: Option<String>,
    /// Articles à acheter chez ce vendeur.
    pub lignes: Vec<LigneArretDto>,
}

/// Le client et son repère (K3-1c, K4).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ClientCourse)]
pub struct ClientCourseDto {
    /// Nom d'usage. **Absent** tant que le produit n'en porte aucun (cycle CPT
    /// 003 : « un numéro vérifié, rien d'autre ») — l'app affiche le repère.
    pub nom_usage: Option<String>,
    /// Contact du client. Jamais journalisé, effacé du cache à la clôture (R6).
    pub telephone: Option<String>,
    /// Repère écrit.
    pub repere_texte: Option<String>,
    /// URL **présignée** de la note vocale — à télécharger tout de suite pour
    /// la jouer hors ligne (FR-024).
    pub repere_vocal_url: Option<String>,
    /// Durée de la note vocale (s).
    pub repere_vocal_duree_s: Option<i32>,
    /// Point de livraison.
    pub lieu_lat: Option<f64>,
    /// Point de livraison.
    pub lieu_lon: Option<f64>,
    /// La voie « dépôt » est-elle ouverte sur cette commande (FR-039) ?
    pub depot_autorise: bool,
}

/// Les seuils de preuve d'échec de la zone.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = SeuilsPreuves)]
pub struct SeuilsPreuvesDto {
    /// Appels `client_absent` exigés.
    pub appels_min: i64,
    /// Espacement minimal entre deux appels retenus (s).
    pub espacement_s: i64,
    /// Présence continue exigée (s).
    pub presence_s: i64,
    /// Rayon dans lequel un relevé compte (m).
    pub rayon_m: i64,
    /// Photos exigées.
    pub photos_min: i64,
}

/// De quoi confirmer la remise **sans réseau** (K4).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = RemisePreprovisionnee)]
pub struct RemisePreprovisionneeDto {
    /// Empreinte salée du code à 4 chiffres — **jamais le code** (FR-037).
    pub empreinte_code: String,
    /// Empreinte du jeton de réception — **jamais le jeton**.
    pub empreinte_jeton: String,
    /// Essais faux déjà comptés côté serveur.
    pub essais_consommes: i16,
    /// Seuil de zone `commande.essais_code_livraison` (cycle 008, réutilisé).
    pub essais_max: i64,
    /// Saisie du code bloquée (K4-1d).
    pub code_bloque: bool,
    /// Total à encaisser chez le client (unités mineures).
    pub montant_a_encaisser_unites: i64,
    /// `cash` | `mobile_money`.
    pub mode_paiement: String,
    /// Seuils de preuve de la zone.
    pub preuves: SeuilsPreuvesDto,
    /// Arrêt de REMISE — la cible de « je suis arrivé chez le client »
    /// (FR-053). Il n'est PAS dans `arrets`, qui ne porte que les collectes.
    pub arret_remise_id: Option<Uuid>,
    /// Statut de l'arrêt de remise (`a_collecter` | `en_route` | `arrive`).
    pub arret_remise_statut: Option<String>,
    /// Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052).
    pub arrive_chez_client_le: Option<DateTime<Utc>>,
}

/// La course active, pré-provisionnée pour fonctionner hors ligne.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CourseActiveComplete)]
pub struct CourseActiveDto {
    /// Livraison active.
    pub livraison_id: Uuid,
    /// Commande portée.
    pub commande_id: Uuid,
    /// `assignee` | `en_collecte` | `en_livraison`.
    pub etat: String,
    /// Devise ISO 4217.
    pub devise: String,
    /// Arrêts de collecte, dans l'ordre de passage.
    pub arrets: Vec<ArretCourseDto>,
    /// Le client et son repère.
    pub client: ClientCourseDto,
    /// De quoi confirmer la remise hors ligne.
    pub remise: RemisePreprovisionneeDto,
}

impl From<coursier::CourseComplete> for CourseActiveDto {
    fn from(c: coursier::CourseComplete) -> Self {
        Self {
            livraison_id: c.livraison_id,
            commande_id: c.commande_id,
            etat: c.etat.comme_str().to_owned(),
            devise: c.devise,
            arrets: c
                .arrets
                .into_iter()
                .map(|a| ArretCourseDto {
                    arret_id: a.arret_id,
                    ordre: a.ordre,
                    prestataire_id: a.prestataire_id,
                    nom: a.nom,
                    site_lat: a.site_lat,
                    site_lon: a.site_lon,
                    distance_precedent_m: None,
                    empreinte_jeton: a.empreinte_jeton,
                    empreinte_code: a.empreinte_code,
                    montant_avance: a.montant_avance,
                    photo_exigee: a.photo_exigee,
                    distance_max_m: a.distance_max_m,
                    statut: a.statut.comme_str().to_owned(),
                    en_route_le: a.en_route_le,
                    arrive_le: a.arrive_le,
                    collecte_le: a.collecte_le,
                    telephone_vendeur: a.telephone_vendeur,
                    lignes: a
                        .lignes
                        .into_iter()
                        .map(|l| LigneArretDto {
                            ligne_id: l.ligne_id,
                            libelle: l.libelle,
                            quantite: l.quantite,
                            prix_unitaire_unites: l.prix_unitaire_unites,
                            preference_substitution: l.preference.comme_str().to_owned(),
                            statut: l.statut.comme_str().to_owned(),
                        })
                        .collect(),
                })
                .collect(),
            client: ClientCourseDto {
                nom_usage: c.client.nom_usage,
                telephone: c.client.telephone,
                repere_texte: c.client.repere_texte,
                repere_vocal_url: c.client.repere_vocal_url,
                repere_vocal_duree_s: c.client.repere_vocal_duree_s,
                lieu_lat: c.client.lieu_lat,
                lieu_lon: c.client.lieu_lon,
                depot_autorise: c.client.depot_autorise,
            },
            remise: RemisePreprovisionneeDto {
                empreinte_code: c.remise.empreinte_code,
                empreinte_jeton: c.remise.empreinte_jeton,
                essais_consommes: c.remise.essais_consommes,
                essais_max: c.remise.essais_max,
                code_bloque: c.remise.code_bloque,
                montant_a_encaisser_unites: c.remise.montant_a_encaisser_unites,
                mode_paiement: c.remise.mode_paiement.comme_str().to_owned(),
                preuves: SeuilsPreuvesDto {
                    appels_min: c.remise.seuils_preuves.appels_min,
                    espacement_s: c.remise.seuils_preuves.espacement_s,
                    presence_s: c.remise.seuils_preuves.presence_s,
                    rayon_m: c.remise.seuils_preuves.rayon_m,
                    photos_min: c.remise.seuils_preuves.photos_min,
                },
                arret_remise_id: c.remise.arret_remise_id,
                arret_remise_statut: c.remise.arret_remise_statut,
                arrive_chez_client_le: c.remise.arrive_chez_client_le,
            },
        }
    }
}

// ── Endpoints ──────────────────────────────────────────────────────────────

/// CRS-03 — course active du coursier, **complète** et pré-provisionnée.
///
/// Cet endpoint a déménagé de `qr_http` : son contenu n'a plus rien à faire
/// dans un domaine dont l'objet est la plaque. Le chemin ne bouge pas, et les
/// champs du cycle 006 restent là — l'app livrée continue de fonctionner
/// pendant la transition.
///
/// `204` sans course : ce n'est pas une erreur, c'est une journée qui commence.
#[utoipa::path(
    get,
    path = "/courses/active",
    tag = "coursier",
    responses(
        (status = 200, description = "Course active complète : arrêts, lignes, client, empreintes de remise.", body = CourseActiveDto),
        (status = 204, description = "Aucune course assignée."),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/courses/active")]
pub async fn course_active(
    auth: Auth,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    match coursier.course_active(auth.compte_id).await? {
        Some(course) => Ok(HttpResponse::Ok().json(CourseActiveDto::from(course))),
        None => Ok(HttpResponse::NoContent().finish()),
    }
}

/// Corps de déclaration d'un appel passé via l'app.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeAppel)]
pub struct DemandeAppelDto {
    /// Clé d'idempotence (UUIDv7 client, constitution V).
    pub uuid_client: Uuid,
    /// `client` | `vendeur`.
    pub vers: String,
    /// Prestataire appelé — obligatoire si `vers = vendeur`.
    pub prestataire_id: Option<Uuid>,
    /// `suivi` | `substitution` | `client_absent`. **Seul `client_absent`
    /// compte** pour la preuve d'échec (FR-035).
    pub motif: String,
    /// Issue DÉCLARÉE : `inconnue` | `sans_reponse` | `repondu`. Facultative —
    /// le serveur ne voit pas l'appel, il ne peut que la recevoir (R19).
    pub issue: Option<String>,
    /// Horodatage de l'appareil — observation seulement.
    pub passe_le_local: DateTime<Utc>,
}

/// Corps de mise à jour de l'issue déclarée d'un appel.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = IssueAppelDeclaree)]
pub struct IssueAppelDto {
    /// Clé d'idempotence de l'appel à mettre à jour.
    pub uuid_client: Uuid,
    /// `inconnue` | `sans_reponse` | `repondu`.
    pub issue: String,
}

/// Ce que le serveur rend après avoir journalisé un appel.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = AppelEnregistre)]
pub struct AppelEnregistreDto {
    /// Appel journalisé.
    pub appel_id: Uuid,
    /// Cet appel compte-t-il pour la preuve d'échec ?
    pub compte_pour_preuve: bool,
}

/// CRS-03 — journalise un appel passé **via l'app** (FR-030, FR-031, FR-033).
///
/// ⚠ **Aucun numéro** n'est transmis ni journalisé : le serveur ne voit pas
/// l'appel, il part du téléphone. Il en garde l'intention, la direction, le
/// motif et l'issue déclarée.
///
/// Idempotent par `uuid_client` : le rejeu rend `200` et le même corps, sans
/// seconde ligne ni second événement.
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/appels",
    tag = "coursier",
    params(("livraison_id" = Uuid, Path, description = "Livraison de la course active du coursier.")),
    request_body = DemandeAppelDto,
    responses(
        (status = 201, description = "Appel journalisé.", body = AppelEnregistreDto),
        (status = 200, description = "Rejeu idempotent — même corps, aucune écriture.", body = AppelEnregistreDto),
        (status = 422, description = "Demande mal formée (appel vendeur sans prestataire).", body = ErreurApiDto),
        (status = 403, description = "Course d'un autre coursier, ou rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/appels")]
pub async fn journaliser_appel(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeAppelDto>,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    let dto = corps.into_inner();
    let demande = coursier::DemandeAppel {
        uuid_client: dto.uuid_client,
        vers: dto.vers.parse()?,
        prestataire_id: dto.prestataire_id,
        motif: dto.motif.parse()?,
        issue: dto.issue.as_deref().map(str::parse).transpose()?,
        passe_le_local: dto.passe_le_local,
    };
    let fait = coursier
        .journaliser_appel(auth.compte_id, chemin.into_inner(), demande)
        .await?;
    let corps = AppelEnregistreDto {
        appel_id: fait.appel_id,
        compte_pour_preuve: fait.compte_pour_preuve,
    };
    Ok(if fait.rejeu {
        HttpResponse::Ok().json(corps)
    } else {
        HttpResponse::Created().json(corps)
    })
}

/// CRS-03 — déclare (ou corrige) l'issue d'un appel (FR-036, R19).
///
/// Le serveur ne peut pas l'observer : l'appel part du téléphone. Cette issue
/// sert l'affichage de K4-1e et **n'est jamais un critère de preuve** — un
/// coursier qui déclarerait « sans réponse » à tort ne gagne rien.
#[utoipa::path(
    patch,
    path = "/courses/{livraison_id}/appels",
    tag = "coursier",
    params(("livraison_id" = Uuid, Path, description = "Livraison de la course active du coursier.")),
    request_body = IssueAppelDto,
    responses(
        (status = 200, description = "Issue mise à jour.", body = AppelEnregistreDto),
        (status = 422, description = "Appel inconnu pour cette livraison.", body = ErreurApiDto),
        (status = 403, description = "Course d'un autre coursier, ou rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[patch("/courses/{livraison_id}/appels")]
pub async fn declarer_issue_appel(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<IssueAppelDto>,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    let dto = corps.into_inner();
    let fait = coursier
        .declarer_issue_appel(
            auth.compte_id,
            chemin.into_inner(),
            dto.uuid_client,
            dto.issue.parse()?,
        )
        .await?;
    Ok(HttpResponse::Ok().json(AppelEnregistreDto {
        appel_id: fait.appel_id,
        compte_pour_preuve: fait.compte_pour_preuve,
    }))
}
