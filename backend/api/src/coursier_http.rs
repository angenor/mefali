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

use actix_multipart::form::{bytes::Bytes as ChampFichier, text::Text, MultipartForm};
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
        // Une énumération mal orthographiée par l'appelant : sa demande est
        // invalide, le serveur va bien.
        | ErreurCoursier::ValeurInconnue(_)
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

/// Un échantillon de présence tel que l'app le déclare.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = ReleveDePresence)]
pub struct ReleveDePresenceDto {
    /// Clé d'idempotence du relevé (UUIDv7 client, constitution V).
    pub uuid_client: Uuid,
    /// Éloignement du point de livraison, en mètres **arrondis**.
    ///
    /// ⚠ Une distance, **jamais une position** : le serveur ne stocke aucune
    /// coordonnée, donc n'en fuite aucune (R8, patron ARTCI du cycle 006).
    pub distance_m: i64,
    /// Horodatage de l'échantillon sur l'appareil.
    pub releve_le_local: DateTime<Utc>,
}

/// Lot de relevés — la file peut en avoir accumulé plusieurs minutes.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = LotDePresence)]
pub struct LotPresenceDto {
    /// Les échantillons du lot.
    pub releves: Vec<ReleveDePresenceDto>,
}

/// Ce que le serveur rend après avoir enregistré un lot de présence.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PresenceEnregistree)]
pub struct PresenceEnregistreeDto {
    /// Relevés du lot connus du serveur — identique au rejeu (constitution V).
    pub retenus: i64,
    /// Présence **recalculée par le serveur**, en secondes (FR-060).
    pub presence_s: i64,
    /// Durée exigée par la zone.
    pub requis_s: i64,
}

/// CRS-05 — enregistre un lot de relevés de présence (FR-061, FR-064).
///
/// L'app envoie des **échantillons**, jamais une durée : c'est le serveur qui
/// compte, en ignorant tout intervalle supérieur au « trou » de la zone. Sans
/// cette règle, deux relevés espacés de dix minutes vaudraient dix minutes de
/// présence, et un aller-retour vaudrait une attente (R8).
///
/// Idempotent par `uuid_client` : un lot rejoué par la file rend le même corps.
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/presence",
    tag = "coursier",
    params(("livraison_id" = Uuid, Path, description = "Livraison de la course active du coursier.")),
    request_body = LotPresenceDto,
    responses(
        (status = 200, description = "Lot enregistré, présence recalculée.", body = PresenceEnregistreeDto),
        (status = 422, description = "Lot vide, trop grand, ou distance invalide.", body = ErreurApiDto),
        (status = 403, description = "Course d'un autre coursier, ou rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/presence")]
pub async fn enregistrer_presence(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<LotPresenceDto>,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    let lot = corps
        .into_inner()
        .releves
        .into_iter()
        .map(|r| coursier::ReleveDePresence {
            uuid_client: r.uuid_client,
            distance_m: r.distance_m,
            releve_le_local: r.releve_le_local,
        })
        .collect();
    let fait = coursier
        .enregistrer_presence(auth.compte_id, chemin.into_inner(), lot)
        .await?;
    Ok(HttpResponse::Ok().json(PresenceEnregistreeDto {
        retenus: fait.retenus,
        presence_s: fait.presence.secondes,
        requis_s: fait.presence.requis,
    }))
}

/// Partie `demande` du multipart de photo de preuve.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandePhotoPreuve)]
pub struct DemandePhotoPreuveDto {
    /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
    pub uuid_client: Uuid,
    /// Horodatage de la prise de vue sur l'appareil. **Observation** — retenu
    /// comme date de prise pour que l'ordre des photos reste celui du terrain.
    pub prise_le_local: Option<DateTime<Utc>>,
}

/// Schéma OpenAPI du multipart de photo de preuve (partie `demande` + `photo`).
#[derive(Debug, ToSchema)]
#[schema(as = PhotoPreuveMultipart)]
pub struct PhotoPreuveMultipartDto {
    /// Partie JSON `demande`.
    pub demande: DemandePhotoPreuveDto,
    /// Photo de la porte close.
    #[schema(value_type = String, format = Binary)]
    pub photo: Vec<u8>,
}

/// Multipart de photo de preuve : partie `demande` (JSON) + `photo` binaire.
#[derive(Debug, MultipartForm)]
pub struct PhotoPreuveForm {
    /// Partie JSON `demande`.
    demande: Text<String>,
    /// Photo — 5 Mo max, même plafond que la collecte et la rupture.
    #[multipart(limit = "5MB")]
    photo: ChampFichier,
}

/// Ce que le serveur rend après le dépôt d'une photo de preuve.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PhotoPreuveDeposee)]
pub struct PhotoPreuveDeposeeDto {
    /// Photo enregistrée.
    pub photo_id: Uuid,
    /// Photos de preuve de cette livraison après dépôt.
    pub photos: i64,
    /// `true` si la photo existait déjà (rejeu de la file) — rien n'a été redéposé.
    pub rejeu: bool,
}

/// CRS-05 — dépose une photo de preuve d'échec (FR-056, FR-064).
///
/// **Multipart** pour la même raison que la remise (R18) : la photo voyage AVEC
/// la demande, donc dans la file hors-ligne. Une preuve qui exigerait du réseau
/// au moment de la prise serait une preuve qu'on ne peut pas réunir là où elle
/// sert — devant une porte close, dans un quartier sans couverture.
///
/// Idempotent par `uuid_client` : le rejeu ne redépose rien et ne compte pas une
/// seconde photo.
#[utoipa::path(
    post,
    path = "/courses/{livraison_id}/preuves/photo",
    tag = "coursier",
    params(("livraison_id" = Uuid, Path, description = "Livraison de la course active du coursier.")),
    request_body(content = PhotoPreuveMultipartDto, content_type = "multipart/form-data",
                 description = "Partie `demande` (JSON) + `photo` binaire."),
    responses(
        (status = 201, description = "Photo déposée.", body = PhotoPreuveDeposeeDto),
        (status = 200, description = "Rejeu idempotent — aucune écriture.", body = PhotoPreuveDeposeeDto),
        (status = 422, description = "Photo vide ou partie `demande` illisible.", body = ErreurApiDto),
        (status = 403, description = "Course d'un autre coursier, ou rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/courses/{livraison_id}/preuves/photo")]
pub async fn deposer_photo_preuve(
    auth: Auth,
    chemin: web::Path<Uuid>,
    form: MultipartForm<PhotoPreuveForm>,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    let form = form.into_inner();
    let dto: DemandePhotoPreuveDto = serde_json::from_str(&form.demande)
        .map_err(|_| ErreurCoursier::DemandeInvalide("partie `demande` illisible"))?;
    let fait = coursier
        .deposer_photo_preuve(
            auth.compte_id,
            chemin.into_inner(),
            dto.uuid_client,
            form.photo.data.to_vec(),
            dto.prise_le_local,
        )
        .await?;
    let corps = PhotoPreuveDeposeeDto {
        photo_id: fait.photo_id,
        photos: fait.photos,
        rejeu: fait.rejeu,
    };
    Ok(if fait.rejeu {
        HttpResponse::Ok().json(corps)
    } else {
        HttpResponse::Created().json(corps)
    })
}

/// Preuve « appels » — nombre ET espacement (FR-056).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PreuveAppels)]
pub struct PreuveAppelsDto {
    /// Appels `client_absent` **retenus** (espacement respecté).
    pub faits: i64,
    /// Appels exigés par la zone.
    pub requis: i64,
    /// Faux dès qu'un appel a été écarté pour cause d'espacement.
    pub espacement_ok: bool,
    /// Horodatages **serveur** des appels retenus (affichage K4-1e).
    pub horodatages: Vec<DateTime<Utc>>,
    /// Issues DÉCLARÉES par le coursier — affichées, jamais un critère (R19).
    pub issues: Vec<String>,
    /// Preuve réunie.
    pub ok: bool,
    /// Pourquoi elle ne l'est pas — clé i18n.
    pub motif_cle: Option<String>,
}

/// Preuve « présence » — durée mesurée, trous exclus (FR-056).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PreuvePresence)]
pub struct PreuvePresenceDto {
    /// Durée retenue (s), recalculée par le serveur.
    pub secondes: i64,
    /// Durée exigée par la zone.
    pub requis: i64,
    /// Preuve réunie.
    pub ok: bool,
    /// Pourquoi elle ne l'est pas — clé i18n.
    pub motif_cle: Option<String>,
}

/// Preuve « photo » (FR-056).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PreuvePhotos)]
pub struct PreuvePhotosDto {
    /// Photos déposées.
    pub faites: i64,
    /// Photos exigées.
    pub requis: i64,
    /// Preuve réunie.
    pub ok: bool,
}

/// L'état des trois preuves, et **ce qui manque** (contrat §1.4).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = EtatPreuves)]
pub struct EtatPreuvesDto {
    /// Preuve « appels ».
    pub appels: PreuveAppelsDto,
    /// Preuve « présence ».
    pub presence: PreuvePresenceDto,
    /// Preuve « photo ».
    pub photos: PreuvePhotosDto,
    /// Les trois sont réunies — l'échec devient déclarable.
    pub reunies: bool,
    /// Compteur « N sur 3 » de K4-1e.
    pub reunies_sur: u8,
    /// Toujours 3 — le compteur n'a de sens que si le total est explicite.
    pub total: u8,
}

impl From<coursier::EtatPreuves> for EtatPreuvesDto {
    fn from(e: coursier::EtatPreuves) -> Self {
        Self {
            appels: PreuveAppelsDto {
                faits: e.appels.faits,
                requis: e.appels.requis,
                espacement_ok: e.appels.espacement_ok,
                horodatages: e.appels.horodatages,
                issues: e
                    .appels
                    .issues
                    .iter()
                    .map(|i| i.comme_str().to_owned())
                    .collect(),
                ok: e.appels.ok,
                motif_cle: e.appels.motif_cle.map(str::to_owned),
            },
            presence: PreuvePresenceDto {
                secondes: e.presence.secondes,
                requis: e.presence.requis,
                ok: e.presence.ok,
                motif_cle: e.presence.motif_cle.map(str::to_owned),
            },
            photos: PreuvePhotosDto {
                faites: e.photos.faites,
                requis: e.photos.requis,
                ok: e.photos.ok,
            },
            reunies: e.reunies,
            reunies_sur: e.reunies_sur,
            total: coursier::EtatPreuves::TOTAL,
        }
    }
}

/// CRS-05 — état des trois preuves et **ce qui manque** (FR-058, FR-062).
///
/// C'est la **même fonction** que celle qui garde `POST /courses/{id}/echec` :
/// l'écran et le serveur ne peuvent pas diverger (FR-059, FR-060). Un bouton
/// actif dont la déclaration serait refusée serait pire qu'un bouton inactif.
#[utoipa::path(
    get,
    path = "/courses/{livraison_id}/preuves",
    tag = "coursier",
    params(("livraison_id" = Uuid, Path, description = "Livraison de la course active du coursier.")),
    responses(
        (status = 200, description = "État détaillé des trois preuves.", body = EtatPreuvesDto),
        (status = 403, description = "Course d'un autre coursier, ou rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/courses/{livraison_id}/preuves")]
pub async fn etat_preuves(
    auth: Auth,
    chemin: web::Path<Uuid>,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    let livraison = chemin.into_inner();
    // `etat_preuves` sert aussi le port `PreuvesEchec`, qui n'a pas d'acteur :
    // la garde de propriété est donc explicite ici (FR-006).
    coursier.exiger_proprietaire(livraison, auth.compte_id).await?;
    let etat = coursier.etat_preuves(livraison).await?;
    Ok(HttpResponse::Ok().json(EtatPreuvesDto::from(etat)))
}

// ── Caisse (T068 — FR-067 → FR-078) ────────────────────────────────────────

/// Une course de l'historique du jour — **trois chiffres** (K5-1a).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = LigneHistoriqueCaisse)]
pub struct LigneHistoriqueDto {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Livraison concernée.
    pub livraison_id: Option<Uuid>,
    /// Référence lisible (`#418`) — de quoi se parler au téléphone.
    pub reference: String,
    /// Ce que le coursier a avancé (positif).
    pub avance_unites: i64,
    /// Ce qu'il a récupéré (positif).
    pub rembourse_unites: i64,
    /// Sa part sur cette course (devis figé du cycle 007).
    pub gain_unites: i64,
    /// La course est-elle terminée ?
    pub terminee: bool,
    /// Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117).
    pub en_attente_reglement: bool,
    /// Heure de la première écriture (horodatage serveur).
    pub heure: DateTime<Utc>,
}

/// Une indemnisation, telle que la caisse l'affiche.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = IndemnisationVue)]
pub struct IndemnisationDto {
    /// Indemnisation.
    pub id: Uuid,
    /// Commande d'origine.
    pub commande_id: Uuid,
    /// Référence lisible de la commande.
    pub commande_reference: String,
    /// Montant (unités mineures, positif).
    pub montant_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// `demandee` | `validee` | `refusee`.
    pub etat: String,
    /// Litige rattaché — **absent** tant qu'AVI-04 n'existe pas (R16).
    pub litige_id: Option<Uuid>,
    /// Clé i18n du motif.
    pub motif_cle: String,
    /// Clé i18n du motif de décision (refus surtout).
    pub decision_motif_cle: Option<String>,
    /// Quand la décision a été prise.
    pub decide_le: Option<DateTime<Utc>>,
    /// Naissance de la demande.
    pub cree_le: DateTime<Utc>,
}

impl From<coursier::IndemnisationVue> for IndemnisationDto {
    fn from(i: coursier::IndemnisationVue) -> Self {
        Self {
            id: i.id,
            commande_id: i.commande_id,
            commande_reference: i.commande_reference,
            montant_unites: i.montant_unites,
            devise: i.devise,
            etat: i.etat.comme_str().to_owned(),
            litige_id: i.litige_id,
            motif_cle: i.motif_cle,
            decision_motif_cle: i.decision_motif_cle,
            decide_le: i.decide_le,
            cree_le: i.cree_le,
        }
    }
}

/// Un litige en cours vu par le coursier (K5-1c).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = LitigeVu)]
pub struct LitigeVuDto {
    /// Litige.
    pub id: Uuid,
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Référence lisible.
    pub reference: String,
    /// Clé i18n de l'état affiché.
    pub etat_cle: String,
    /// Montant en jeu (unités mineures).
    pub montant_unites: i64,
    /// Ouverture.
    pub ouvert_le: DateTime<Utc>,
}

/// Tout l'écran caisse (K5-1a), en une lecture.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = VueCaisse)]
pub struct VueCaisseDto {
    /// Argent avancé et non encore récupéré (FR-067) — toujours positif.
    pub avance_en_cours_unites: i64,
    /// Combien de courses portent cette avance.
    pub courses_concernees: i64,
    /// Part que le cash ne soldera jamais (commandes prépayées, R10, FR-117).
    pub avances_en_attente_reglement_unites: i64,
    /// Historique du jour civil **de la zone**.
    pub historique_du_jour: Vec<LigneHistoriqueDto>,
    /// Indemnisations rattachées.
    pub indemnisations: Vec<IndemnisationDto>,
    /// Litiges en cours — vide tant qu'AVI-04 n'existe pas.
    pub litiges_en_cours: Vec<LitigeVuDto>,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Les avances en cours dépassent le plafond déclaré du jour (FR-078).
    pub ecart_plafond: bool,
}

impl From<coursier::VueCaisse> for VueCaisseDto {
    fn from(v: coursier::VueCaisse) -> Self {
        Self {
            avance_en_cours_unites: v.avance_en_cours_unites,
            courses_concernees: v.courses_concernees,
            avances_en_attente_reglement_unites: v.avances_en_attente_reglement_unites,
            historique_du_jour: v
                .historique
                .into_iter()
                .map(|l| LigneHistoriqueDto {
                    commande_id: l.commande_id,
                    livraison_id: l.livraison_id,
                    reference: l.reference,
                    avance_unites: l.avance_unites,
                    rembourse_unites: l.rembourse_unites,
                    gain_unites: l.gain_unites,
                    terminee: l.terminee,
                    en_attente_reglement: l.en_attente_reglement,
                    heure: l.heure,
                })
                .collect(),
            indemnisations: v.indemnisations.into_iter().map(Into::into).collect(),
            litiges_en_cours: v
                .litiges
                .into_iter()
                .map(|l| LitigeVuDto {
                    id: l.id,
                    commande_id: l.commande_id,
                    reference: l.reference,
                    etat_cle: l.etat_cle,
                    montant_unites: l.montant_unites,
                    ouvert_le: l.ouvert_le,
                })
                .collect(),
            devise: v.devise,
            ecart_plafond: v.ecart_plafond,
        }
    }
}

/// CRS-06 — la caisse du coursier (FR-067 → FR-077).
///
/// Yao sort de l'argent de sa poche à chaque arrêt et le récupère chez le
/// client. Entre les deux, il porte le risque : cet endpoint est la seule façon
/// qu'il a de vérifier que « le coursier ne perd jamais » est vrai.
///
/// ⚠ Une avance sur commande **prépayée** ne sera jamais soldée en espèces
/// (PAY, tranche T3) : elle reste comptée et **annoncée comme telle** plutôt que
/// masquée — la masquer la ferait disparaître de l'écran dont c'est la seule
/// raison d'être (R10, FR-117).
#[utoipa::path(
    get,
    path = "/moi/caisse",
    tag = "coursier",
    responses(
        (status = 200, description = "Avances en cours, historique du jour, indemnisations, litiges.", body = VueCaisseDto),
        (status = 403, description = "Rôle coursier requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente/révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/caisse")]
pub async fn ma_caisse(
    auth: Auth,
    coursier: web::Data<PgCoursier>,
) -> Result<HttpResponse, ErreurCoursierHttp> {
    auth.exiger_role(Role::Coursier)?;
    // La garde de propriété est la lecture elle-même : elle filtre par
    // `coursier_id = auth.compte_id`, aucun identifiant n'est accepté en entrée.
    let vue = coursier.vue_caisse(auth.compte_id).await?;
    Ok(HttpResponse::Ok().json(VueCaisseDto::from(vue)))
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
