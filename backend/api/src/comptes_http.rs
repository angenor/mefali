//! Surface HTTP des rôles (CPT-03) et du dossier coursier (CPT-04) :
//! `/admin/comptes/*` et `/moi/dossier-coursier`.
//!
//! Côté admin, aucun écran n'est construit avant le cycle ADM (tranche T3) :
//! ces actions vivent en API, protégées par le rôle admin et journalisées
//! (spec, §Surface utilisateur). C'est le précédent posé au cycle 002 pour le
//! forçage de zone.

use actix_multipart::form::{bytes::Bytes as ChampFichier, text::Text, MultipartForm};
use actix_web::{get, post, web, HttpResponse};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::dossier::{IssueSoumission, PieceIdentite, SoumissionDossier};
use comptes::{
    ActionRole, DossierCoursier, DossierCoursierAdmin, PgComptes, Role, StatutRole, VehiculeDeclare,
    PIECE_TAILLE_MAX,
};

use crate::auth_http::{Auth, ErreurApi, ErreurApiDto, EtatRoleDto};

/// Durée de vie des URLs présignées servies à l'admin (research R7).
///
/// CONSTANTE PRODUIT : assez pour ouvrir la pièce et la lire, trop court pour
/// qu'un lien copié dans un chat garde une valeur (constitution VIII).
const PRESIGNEE_TTL: std::time::Duration = std::time::Duration::from_secs(10 * 60);

/// Action d'administration sur un rôle (contrat).
#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum ActionRoleDto {
    /// Vendeur (à l'agrément, §5.1) ou admin (FR-012).
    Attribuer,
    /// Coursier : accepte la demande.
    Valider,
    /// Coursier : refuse la demande (motif requis).
    Refuser,
    /// Coursier/vendeur : suspend (motif requis).
    Suspendre,
    /// Coursier/vendeur : rétablit.
    Retablir,
}

impl From<ActionRoleDto> for ActionRole {
    fn from(a: ActionRoleDto) -> Self {
        match a {
            ActionRoleDto::Attribuer => ActionRole::Attribuer,
            ActionRoleDto::Valider => ActionRole::Valider,
            ActionRoleDto::Refuser => ActionRole::Refuser,
            ActionRoleDto::Suspendre => ActionRole::Suspendre,
            ActionRoleDto::Retablir => ActionRole::Retablir,
        }
    }
}

/// Rôle décidable par l'admin. `client` en est ABSENT : il n'est pas décidable
/// (posé à l'inscription, immuable — R9). L'exclure du type le rend
/// irreprésentable, plutôt que de le refuser à l'exécution.
#[derive(Debug, Clone, Copy, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum RoleDecidableDto {
    /// Coursier — demandé in-app avec dossier.
    Coursier,
    /// Vendeur — attribué à l'agrément.
    Vendeur,
    /// Admin — attribué par un admin existant.
    Admin,
}

impl From<RoleDecidableDto> for Role {
    fn from(r: RoleDecidableDto) -> Self {
        match r {
            RoleDecidableDto::Coursier => Role::Coursier,
            RoleDecidableDto::Vendeur => Role::Vendeur,
            RoleDecidableDto::Admin => Role::Admin,
        }
    }
}

/// Corps de la décision.
#[derive(Debug, Deserialize, ToSchema)]
pub struct DecisionRole {
    /// Action à appliquer.
    pub action: ActionRoleDto,
    /// Motif — REQUIS pour `refuser` et `suspendre` (FR-017).
    #[schema(max_length = 500)]
    pub motif: Option<String>,
}

/// Décision admin sur un rôle — machine à états de data-model §4, journalisée.
#[utoipa::path(
    post,
    path = "/admin/comptes/{compte_id}/roles/{role}",
    tag = "admin",
    params(
        ("compte_id" = Uuid, Path, description = "Compte concerné."),
        // `inline` et non un $ref : utoipa ne collecte les schémas que depuis les
        // corps et les réponses, jamais depuis les paramètres de chemin — le $ref
        // pendouillerait et le générateur de clients refuserait la spec. Le
        // contrat attend de toute façon une énumération EN LIGNE.
        ("role" = inline(RoleDecidableDto), Path, description = "Rôle décidé (client exclu : immuable)."),
    ),
    request_body = DecisionRole,
    responses(
        (status = 200, description = "Nouvel état du rôle. Prise d'effet IMMÉDIATE (contrôle par requête, R5).",
         body = EtatRoleDto),
        (status = 409, description = "Transition invalide pour l'état courant.", body = ErreurApiDto),
        (status = 404, description = "Compte inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis — seul un admin existant décide (FR-012).",
         body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 422, description = "Motif absent pour un refus ou une suspension.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/admin/comptes/{compte_id}/roles/{role}")]
pub async fn decider_role(
    auth: Auth,
    chemin: web::Path<(Uuid, RoleDecidableDto)>,
    corps: web::Json<DecisionRole>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    // FR-012 : seul un admin EXISTANT attribue le rôle admin ou décide des
    // rôles professionnels. Le domaine ne connaît pas HTTP — la garde est ici.
    auth.exiger_role(Role::Admin)?;
    let (compte_id, role) = chemin.into_inner();

    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    let attribution = depot
        .decider_role(
            &mut tx,
            compte_id,
            role.into(),
            corps.action.into(),
            auth.compte_id,
            corps.motif.as_deref(),
        )
        .await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    Ok(HttpResponse::Ok().json(EtatRoleDto::from(attribution)))
}

/// `PathConfig` du module : un rôle hors énumération → 404 plutôt que le 400
/// par défaut d'Actix — `/roles/client` désigne une ressource qui n'existe pas.
pub fn config_path() -> web::PathConfig {
    web::PathConfig::default().error_handler(|_err, _req| ErreurApi::Introuvable.into())
}

/// `MultipartFormConfig` du module.
///
/// Le garde-fou de mémoire, pas la règle métier : la borne qui FAIT foi est
/// celle du domaine (`PIECE_TAILLE_MAX`), testée sans HTTP. Celle-ci évite
/// seulement qu'un corps démesuré soit bufferisé avant d'être refusé — d'où la
/// marge pour les entêtes de parties et les champs texte.
pub fn config_multipart() -> actix_multipart::form::MultipartFormConfig {
    actix_multipart::form::MultipartFormConfig::default()
        .total_limit(PIECE_TAILLE_MAX + 64 * 1024)
        .memory_limit(PIECE_TAILLE_MAX + 64 * 1024)
        .error_handler(|_err, _req| ErreurApi::CorpsInvalide.into())
}

// ── Dossier coursier (CPT-04) ──────────────────────────────────────────────

// DTO de CONTRAT uniquement : il décrit l'énumération à utoipa, la lecture
// réelle passe par `FiltreDossiers` et `StatutRole::from_str`. Le doc-comment
// ci-dessous part dans `openapi.json` — il ne parle donc que du contrat.
/// Statut d'un rôle, et donc d'un dossier coursier (R9).
#[derive(Debug, Clone, Copy, ToSchema)]
#[serde(rename_all = "snake_case")]
#[schema(as = StatutRole)]
#[allow(dead_code)] // vu par utoipa seulement — jamais construit
pub enum StatutRoleDto {
    /// Décision admin attendue.
    EnAttente,
    /// Rôle ouvert.
    Valide,
    /// Demande refusée.
    Refuse,
    /// Rôle retiré temporairement.
    Suspendu,
}

/// Filtre de la liste admin des dossiers.
#[derive(Debug, Deserialize)]
pub struct FiltreDossiers {
    /// Statut recherché — tous les dossiers si absent.
    ///
    /// Lu en TEXTE et non en énumération : `web::QueryConfig` est unique pour
    /// toute l'app (une seule par type) et celle de `zones_http` la détient —
    /// un `?statut=` illisible rendrait donc une clé i18n de `zones`. Le parse
    /// manuel garde les clés de ce module.
    pub statut: Option<String>,
}

/// Véhicule déclaré au dossier (contrat).
// Le suffixe `Dto` n'existe que pour ne pas heurter le type de domaine importé
// ici ; le contrat, lui, garde le nom métier (même raison qu'`ErreurApiDto`).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = VehiculeDeclare)]
pub struct VehiculeDeclareDto {
    /// Type de transport du référentiel ZON-03.
    pub type_transport_id: Uuid,
    /// Slug du type (ex. `moto`).
    pub slug: String,
    /// `false` si le type a été DÉSACTIVÉ dans la zone après la déclaration.
    pub actif_zone: bool,
}

impl From<VehiculeDeclare> for VehiculeDeclareDto {
    fn from(v: VehiculeDeclare) -> Self {
        VehiculeDeclareDto {
            type_transport_id: v.type_transport_id,
            slug: v.slug,
            actif_zone: v.actif_zone,
        }
    }
}

/// Dossier coursier tel que son titulaire le voit (contrat).
///
/// ⚠ La CLÉ de la pièce n'en fait pas partie : elle n'a de sens que pour le
/// serveur, et l'exposer donnerait un identifiant de bucket à deviner.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DossierCoursier)]
pub struct DossierCoursierDto {
    /// Statut = celui de l'attribution `coursier` (R9).
    pub statut: String,
    /// Motif de la dernière décision admin.
    pub motif: Option<String>,
    /// Référent local (« caution morale », cadrage §7.1).
    pub referent_nom: String,
    /// Téléphone du référent, normalisé E.164.
    pub referent_telephone_e164: String,
    /// Véhicules déclarés.
    pub vehicules: Vec<VehiculeDeclareDto>,
    /// Dernier dépôt.
    pub soumis_le: chrono::DateTime<chrono::Utc>,
}

impl From<DossierCoursier> for DossierCoursierDto {
    fn from(d: DossierCoursier) -> Self {
        DossierCoursierDto {
            statut: d.statut.comme_str().to_owned(),
            motif: d.motif,
            referent_nom: d.referent_nom,
            referent_telephone_e164: d.referent_telephone_e164,
            vehicules: d.vehicules.into_iter().map(VehiculeDeclareDto::from).collect(),
            soumis_le: d.soumis_le,
        }
    }
}

/// Dossier complet pour la revue admin (contrat `DossierCoursierAdmin`).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DossierCoursierAdmin)]
pub struct DossierCoursierAdminDto {
    /// Compte du coursier.
    pub compte_id: Uuid,
    /// Numéro du coursier — l'admin doit pouvoir le rappeler (FR-017).
    pub telephone_e164: String,
    /// URL présignée de la pièce (TTL 10 min) — DÉTAIL uniquement, absente en
    /// liste : présigner N pièces pour un tableau serait du gaspillage, et
    /// autant de liens vivants qu'aucun œil n'ouvrira.
    pub piece_url: Option<String>,
    /// Statut = celui de l'attribution `coursier`.
    pub statut: String,
    /// Motif de la dernière décision admin.
    pub motif: Option<String>,
    /// Référent local.
    pub referent_nom: String,
    /// Téléphone du référent.
    pub referent_telephone_e164: String,
    /// Véhicules déclarés.
    pub vehicules: Vec<VehiculeDeclareDto>,
    /// Dernier dépôt.
    pub soumis_le: chrono::DateTime<chrono::Utc>,
}

impl DossierCoursierAdminDto {
    fn assembler(admin: DossierCoursierAdmin, piece_url: Option<String>) -> Self {
        let d = admin.dossier;
        DossierCoursierAdminDto {
            compte_id: d.compte_id,
            telephone_e164: admin.telephone_e164,
            piece_url,
            statut: d.statut.comme_str().to_owned(),
            motif: d.motif,
            referent_nom: d.referent_nom,
            referent_telephone_e164: d.referent_telephone_e164,
            vehicules: d.vehicules.into_iter().map(VehiculeDeclareDto::from).collect(),
            soumis_le: d.soumis_le,
        }
    }
}

// DTO de CONTRAT uniquement : il décrit la requête à utoipa, le parsing passe
// par `SoumissionDossierForm`. Les deux ne peuvent pas fusionner — `MultipartForm`
// ne sait pas se décrire à utoipa, et `ToSchema` ne sait pas lire un corps
// multipart — mais ils DOIVENT rester alignés champ pour champ.
/// Dossier soumis par le coursier : pièce d'identité, référent local et
/// véhicules déclarés (FR-015).
#[derive(Debug, ToSchema)]
#[schema(as = SoumissionDossier)]
#[allow(dead_code)] // vu par utoipa seulement — jamais construit
pub struct SoumissionDossierDto {
    /// Pièce d'identité — ≤ 10 Mo, jpeg/png/webp/pdf.
    #[schema(value_type = String, format = Binary)]
    pub piece: Vec<u8>,
    /// Nom du référent local.
    #[schema(max_length = 120)]
    pub referent_nom: String,
    /// Téléphone du référent — normalisé E.164 comme celui du compte.
    pub referent_telephone: String,
    /// Slugs des types de transport, ACTIFS dans la zone (référentiel ZON-03).
    #[schema(min_items = 1, example = json!(["moto"]))]
    pub vehicules: Vec<String>,
}

/// Corps multipart réellement analysé.
#[derive(Debug, MultipartForm)]
pub struct SoumissionDossierForm {
    #[multipart(limit = "10MB")]
    piece: ChampFichier,
    referent_nom: Text<String>,
    referent_telephone: Text<String>,
    /// Champ RÉPÉTÉ (`-F vehicules=moto -F vehicules=velo`) : c'est ainsi qu'un
    /// tableau voyage en multipart.
    vehicules: Vec<Text<String>>,
}

/// Lit l'en-tête `Idempotency-Key` (REQUIS — R14).
///
/// Absent ou illisible → 422 : le rendre optionnel serait un footgun (l'oubli
/// silencieux recrée les doublons que la clé existe pour éviter).
fn idempotency_key(requete: &actix_web::HttpRequest) -> Result<Uuid, ErreurApi> {
    requete
        .headers()
        .get("idempotency-key")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<Uuid>().ok())
        .ok_or(ErreurApi::CorpsInvalide)
}

/// Soumet (ou re-soumet après refus) le dossier coursier — crée la demande de
/// rôle (FR-015).
#[utoipa::path(
    post,
    path = "/moi/dossier-coursier",
    tag = "moi",
    params(
        ("Idempotency-Key" = Uuid, Header,
         description = "UUIDv7 généré par le client — rejeu réseau idempotent (R14)."),
    ),
    request_body(content = SoumissionDossierDto, content_type = "multipart/form-data"),
    responses(
        (status = 201, description = "Dossier soumis — rôle coursier `en_attente`. Émet \
         `role.demande` + `dossier_coursier.soumis` dans la même transaction.",
         body = DossierCoursierDto),
        (status = 200, description = "Rejeu : un dossier est déjà en attente. Rien n'a changé \
         (R14).", body = DossierCoursierDto),
        (status = 409, description = "Transition invalide — dossier déjà `valide` ou `suspendu`.",
         body = ErreurApiDto),
        (status = 422, description = "Incomplet, véhicule hors zone, fichier trop volumineux ou \
         type refusé, en-tête d'idempotence absent.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/moi/dossier-coursier")]
pub async fn soumettre_dossier_coursier(
    auth: Auth,
    requete: actix_web::HttpRequest,
    MultipartForm(form): MultipartForm<SoumissionDossierForm>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    // La clé est exigée par le contrat, et validée pour que son absence se voie
    // tout de suite. Le dossier étant 1:1 avec le compte, c'est la CARDINALITÉ
    // qui porte l'idempotence (R14) : on ne la stocke pas.
    idempotency_key(&requete)?;

    let soumission = SoumissionDossier {
        piece: PieceIdentite {
            octets: form.piece.data.to_vec(),
            mime: form
                .piece
                .content_type
                .map(|m| m.to_string())
                .unwrap_or_default(),
        },
        referent_nom: form.referent_nom.into_inner(),
        referent_telephone: form.referent_telephone.into_inner(),
        vehicules: form.vehicules.into_iter().map(Text::into_inner).collect(),
    };

    let mut tx = depot
        .pool()
        .begin()
        .await
        .map_err(comptes::ErreurComptes::from)?;
    let issue = depot
        .soumettre_dossier_coursier(&mut tx, auth.compte_id, &soumission)
        .await?;
    tx.commit().await.map_err(comptes::ErreurComptes::from)?;

    Ok(match issue {
        IssueSoumission::Soumis(dossier) => {
            HttpResponse::Created().json(DossierCoursierDto::from(dossier))
        }
        IssueSoumission::DejaEnAttente(dossier) => {
            HttpResponse::Ok().json(DossierCoursierDto::from(dossier))
        }
    })
}

/// État du dossier coursier du compte courant (FR-013 : l'app Pro l'affiche).
#[utoipa::path(
    get,
    path = "/moi/dossier-coursier",
    tag = "moi",
    responses(
        (status = 200, description = "Dossier et son statut.", body = DossierCoursierDto),
        (status = 404, description = "Aucun dossier soumis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/dossier-coursier")]
pub async fn mon_dossier_coursier(
    auth: Auth,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let dossier = depot.dossier_coursier(auth.compte_id).await?;
    Ok(HttpResponse::Ok().json(DossierCoursierDto::from(dossier)))
}

/// Liste des dossiers coursier pour la revue admin (FR-017).
#[utoipa::path(
    get,
    path = "/admin/comptes/dossiers-coursier",
    tag = "admin",
    params(
        // `inline` : utoipa ne collecte pas les schémas depuis les paramètres —
        // un $ref y pendouillerait (même raison qu'en chemin, plus bas).
        ("statut" = inline(Option<StatutRoleDto>), Query,
         description = "Filtre — tous les dossiers si absent."),
    ),
    responses(
        (status = 200, description = "Dossiers, du plus récemment soumis au plus ancien. \
         `piece_url` est absente ici (détail uniquement).", body = Vec<DossierCoursierAdminDto>),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/comptes/dossiers-coursier")]
pub async fn lister_dossiers_coursier(
    auth: Auth,
    filtre: web::Query<FiltreDossiers>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    auth.exiger_role(Role::Admin)?;
    let statut = filtre
        .statut
        .as_deref()
        .map(str::parse::<StatutRole>)
        .transpose()
        .map_err(|_| ErreurApi::CorpsInvalide)?;
    let dossiers = depot.dossiers_coursier(statut).await?;
    let dtos: Vec<DossierCoursierAdminDto> = dossiers
        .into_iter()
        .map(|d| DossierCoursierAdminDto::assembler(d, None))
        .collect();
    Ok(HttpResponse::Ok().json(dtos))
}

/// Dossier complet d'un coursier, pièce lisible comprise (FR-017 scénario 2).
#[utoipa::path(
    get,
    path = "/admin/comptes/{compte_id}/dossier-coursier",
    tag = "admin",
    params(("compte_id" = Uuid, Path, description = "Coursier concerné.")),
    responses(
        (status = 200, description = "Dossier complet — `piece_url` est présignée 10 min.",
         body = DossierCoursierAdminDto),
        (status = 404, description = "Compte ou dossier inconnu.", body = ErreurApiDto),
        (status = 403, description = "Rôle admin requis.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/admin/comptes/{compte_id}/dossier-coursier")]
pub async fn consulter_dossier_coursier(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    auth.exiger_role(Role::Admin)?;
    let compte_id = chemin.into_inner();

    let admin = depot.dossier_coursier_admin(compte_id).await?;
    // La pièce ne transite PAS par l'API : le bucket est privé, l'admin reçoit
    // un lien opaque et court (constitution VIII, écart justifié au plan).
    let url = depot
        .objets()
        .presigner_get(&admin.dossier.piece_cle_objet, PRESIGNEE_TTL)
        .await
        .map_err(comptes::ErreurComptes::from)?;

    Ok(HttpResponse::Ok().json(DossierCoursierAdminDto::assembler(admin, Some(url.url))))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    use actix_web::{http::StatusCode, test as atest, App};
    use comptes::{Appareil, Comptes, MemoireEphemere, MemoireObjets, Plateforme, SmsTraces};
    use serde_json::json;
    use sqlx::PgPool;

    const ADMIN: &str = "01900000-0000-7000-8000-000000000401";
    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";
    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    async fn preparer(pool: &PgPool) -> PgComptes {
        crate::charger_seeds(pool).await.unwrap();
        PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(MemoireObjets::new()),
            Arc::from(SECRET),
        )
    }

    async fn jeton(depot: &PgComptes, compte: Uuid) -> String {
        let zone = depot.compte(compte).await.unwrap().zone_id;
        let mut tx = depot.pool().begin().await.unwrap();
        let (_, jetons) = depot
            .creer_session(
                &mut tx,
                compte,
                zone,
                &Appareil {
                    nom: "Console".to_owned(),
                    plateforme: Plateforme::Android,
                },
                comptes::OrigineSession::VerificationOtp,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        jetons.acces
    }

    async fn creer_compte(depot: &PgComptes, numero: &str) -> Uuid {
        let mut tx = depot.pool().begin().await.unwrap();
        let compte = depot
            .creer_compte(&mut tx, numero, TIASSALE.parse().unwrap(), "2026-07")
            .await
            .unwrap();
        tx.commit().await.unwrap();
        compte.id
    }

    macro_rules! app {
        ($depot:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($depot.clone()))
                    .app_data(crate::auth_http::config_json())
                    .app_data(config_path())
                    .app_data(config_multipart())
                    .service(decider_role)
                    // Même ordre qu'en production : la route littérale AVANT
                    // celle à paramètre, sinon « dossiers-coursier » se lirait
                    // comme un `{compte_id}`.
                    .service(lister_dossiers_coursier)
                    .service(consulter_dossier_coursier)
                    .service(soumettre_dossier_coursier)
                    .service(mon_dossier_coursier)
                    .service(crate::auth_http::moi),
            )
            .await
        };
    }

    /// Corps multipart d'une soumission de dossier.
    ///
    /// Écrit à la main : `actix_multipart` ne fournit pas de constructeur de
    /// corps, et c'est justement le format du CÂBLE que ces tests doivent
    /// exercer — un helper typé ne prouverait rien du parsing réel.
    fn corps_multipart(vehicules: &[&str], mime_piece: &str, octets: &[u8]) -> (String, Vec<u8>) {
        const B: &str = "----mefalitest";
        let mut corps: Vec<u8> = Vec::new();
        let mut champ = |nom: &str, valeur: &str| {
            corps.extend_from_slice(
                format!(
                    "--{B}\r\nContent-Disposition: form-data; name=\"{nom}\"\r\n\r\n{valeur}\r\n"
                )
                .as_bytes(),
            );
        };
        champ("referent_nom", "K. Abou");
        champ("referent_telephone", "0705060708");
        for v in vehicules {
            champ("vehicules", v);
        }
        corps.extend_from_slice(
            format!(
                "--{B}\r\nContent-Disposition: form-data; name=\"piece\"; filename=\"piece.jpg\"\r\n\
                 Content-Type: {mime_piece}\r\n\r\n"
            )
            .as_bytes(),
        );
        corps.extend_from_slice(octets);
        corps.extend_from_slice(format!("\r\n--{B}--\r\n").as_bytes());
        (format!("multipart/form-data; boundary={B}"), corps)
    }

    macro_rules! soumettre {
        ($app:expr, $acces:expr, $vehicules:expr) => {
            soumettre!($app, $acces, $vehicules, &Uuid::now_v7().to_string())
        };
        ($app:expr, $acces:expr, $vehicules:expr, $cle:expr) => {{
            let (type_contenu, corps) = corps_multipart($vehicules, "image/jpeg", b"octets-piece");
            let requete = atest::TestRequest::post()
                .uri("/moi/dossier-coursier")
                .insert_header(("authorization", format!("Bearer {}", $acces)))
                .insert_header(("idempotency-key", $cle.to_owned()))
                .insert_header(("content-type", type_contenu))
                .set_payload(corps)
                .to_request();
            atest::call_service(&$app, requete).await
        }};
    }

    macro_rules! decider {
        ($app:expr, $acces:expr, $compte:expr, $role:expr, $corps:expr) => {{
            let requete = atest::TestRequest::post()
                .uri(&format!("/admin/comptes/{}/roles/{}", $compte, $role))
                .insert_header(("authorization", format!("Bearer {}", $acces)))
                .set_json($corps)
                .to_request();
            atest::call_service(&$app, requete).await
        }};
    }

    /// §5.1 — l'admin attribue le rôle vendeur à l'agrément : il naît VALIDE.
    #[sqlx::test(migrations = "../migrations")]
    async fn attribuer_vendeur_200(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let kofi = creer_compte(&depot, "+2250709080706").await;

        let resp = decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "attribuer" })
        );
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["role"], "vendeur");
        assert_eq!(corps["statut"], "valide");
        assert!(corps["decide_le"].is_string());
        assert!(depot
            .roles_valides(kofi)
            .await
            .unwrap()
            .contains(&Role::Vendeur));
    }

    /// FR-012 — un compte NON admin ne décide rien, même sur lui-même. Sans
    /// cette garde, n'importe qui s'auto-promeut admin.
    #[sqlx::test(migrations = "../migrations")]
    async fn decider_403_sans_role_admin(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;

        let resp = decider!(app, acces, yao, "admin", json!({ "action": "attribuer" }));
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.role_requis");
        assert!(!depot
            .roles_valides(yao)
            .await
            .unwrap()
            .contains(&Role::Admin));
    }

    #[sqlx::test(migrations = "../migrations")]
    async fn decider_401_sans_session(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;

        let requete = atest::TestRequest::post()
            .uri(&format!("/admin/comptes/{yao}/roles/vendeur"))
            .set_json(json!({ "action": "attribuer" }))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    }

    /// R9 — une transition hors machine → 409, pas un 500.
    #[sqlx::test(migrations = "../migrations")]
    async fn transition_invalide_409(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let yao = creer_compte(&depot, "+2250709080706").await;

        // Valider un coursier qui n'a jamais rien demandé.
        let resp = decider!(app, acces, yao, "coursier", json!({ "action": "valider" }));
        assert_eq!(resp.status(), StatusCode::CONFLICT);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.transition_invalide");
    }

    /// FR-017 — refuser/suspendre sans motif → 422.
    #[sqlx::test(migrations = "../migrations")]
    async fn suspendre_sans_motif_422(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let kofi = creer_compte(&depot, "+2250709080706").await;
        decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "attribuer" })
        );

        let resp = decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "suspendre" })
        );
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        assert!(
            depot
                .roles_valides(kofi)
                .await
                .unwrap()
                .contains(&Role::Vendeur),
            "le rôle n'a pas bougé"
        );
    }

    /// Compte inconnu → 404.
    #[sqlx::test(migrations = "../migrations")]
    async fn compte_inconnu_404(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;

        let resp = decider!(
            app,
            acces,
            Uuid::now_v7(),
            "vendeur",
            json!({ "action": "attribuer" })
        );
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }

    /// Le rôle `client` n'est pas décidable : il n'existe pas comme ressource.
    #[sqlx::test(migrations = "../migrations")]
    async fn role_client_non_decidable_404(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces = jeton(&depot, ADMIN.parse().unwrap()).await;
        let yao = creer_compte(&depot, "+2250709080706").await;

        let resp = decider!(
            app,
            acces,
            yao,
            "client",
            json!({ "action": "suspendre", "motif": "x" })
        );
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }

    /// US3 scénario 6 / R5 — LE test du cycle : une suspension vaut dès la
    /// requête SUIVANTE, sans attendre l'expiration des 15 min du jeton.
    #[sqlx::test(migrations = "../migrations")]
    async fn suspension_prend_effet_a_la_requete_suivante(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let admin: Uuid = ADMIN.parse().unwrap();
        let acces_admin = jeton(&depot, admin).await;

        // Un seul compte, admin ET vendeur : son jeton restera valide.
        let acces = jeton(&depot, admin).await;
        decider!(
            app,
            acces_admin,
            admin,
            "vendeur",
            json!({ "action": "attribuer" })
        );

        let moi = |acces: String| {
            atest::TestRequest::get()
                .uri("/moi")
                .insert_header(("authorization", format!("Bearer {acces}")))
                .to_request()
        };
        let resp = atest::call_service(&app, moi(acces.clone())).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        let vendeur = corps["roles"]
            .as_array()
            .unwrap()
            .iter()
            .find(|r| r["role"] == "vendeur")
            .unwrap();
        assert_eq!(vendeur["statut"], "valide");

        // Suspension — le jeton d'accès n'est ni renouvelé ni expiré.
        let resp = decider!(
            app,
            acces_admin,
            admin,
            "vendeur",
            json!({ "action": "suspendre", "motif": "contrôle" })
        );
        assert_eq!(resp.status(), StatusCode::OK);

        let resp = atest::call_service(&app, moi(acces)).await;
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        let vendeur = corps["roles"]
            .as_array()
            .unwrap()
            .iter()
            .find(|r| r["role"] == "vendeur")
            .unwrap();
        assert_eq!(
            vendeur["statut"], "suspendu",
            "le MÊME jeton voit déjà la suspension — les rôles sont relus en base"
        );
        assert!(!depot
            .roles_valides(admin)
            .await
            .unwrap()
            .contains(&Role::Vendeur));
    }

    /// SC-008 — la décision est journalisée : qui, quand, pourquoi.
    #[sqlx::test(migrations = "../migrations")]
    async fn decision_journalisee(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let admin: Uuid = ADMIN.parse().unwrap();
        let acces = jeton(&depot, admin).await;
        let kofi = creer_compte(&depot, "+2250709080706").await;

        decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "attribuer" })
        );
        decider!(
            app,
            acces,
            kofi,
            "vendeur",
            json!({ "action": "suspendre", "motif": "boutique fermée" })
        );

        // La table porte la dernière décision…
        let (motif, decide_par): (Option<String>, Option<Uuid>) = sqlx::query_as(
            "SELECT motif, decide_par FROM comptes.attribution_role
             WHERE compte_id = $1 AND role = 'vendeur'",
        )
        .bind(kofi)
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(motif.as_deref(), Some("boutique fermée"));
        assert_eq!(decide_par, Some(admin));

        // …et l'outbox porte l'HISTORIQUE, dans la même transaction.
        let payload: serde_json::Value = sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement WHERE type_evenement = 'role.suspendu'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(payload["decide_par"], json!(admin));
        assert_eq!(payload["motif"], "boutique fermée");
        assert_eq!(payload["avant"], "valide");
        assert_eq!(payload["apres"], "suspendu");
    }

    // ── Dossier coursier (CPT-04, T018) ────────────────────────────────────

    /// US4 — le parcours complet vu du câble : Yao soumet, l'admin voit la
    /// pièce, valide, et la porte s'ouvre (SC-005).
    #[sqlx::test(migrations = "../migrations")]
    async fn soumission_puis_revue_admin_puis_validation(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;
        let acces_admin = jeton(&depot, ADMIN.parse().unwrap()).await;

        let resp = soumettre!(app, acces, &["moto"]);
        assert_eq!(resp.status(), StatusCode::CREATED);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["statut"], "en_attente");
        assert_eq!(corps["referent_telephone_e164"], "+2250705060708");
        assert_eq!(corps["vehicules"][0]["slug"], "moto");
        assert_eq!(corps["vehicules"][0]["actif_zone"], true);
        assert!(
            corps.get("piece_cle_objet").is_none(),
            "la clé du bucket ne sort JAMAIS vers le titulaire"
        );

        // Le titulaire relit son dossier.
        let requete = atest::TestRequest::get()
            .uri("/moi/dossier-coursier")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["statut"], "en_attente");

        // SC-005 — la porte est FERMÉE tant que l'admin n'a pas validé.
        assert!(!depot.coursier_autorise_en_ligne(yao).await.unwrap());

        // Revue admin : la liste, puis le détail avec la pièce présignée.
        let lister = |acces: String, filtre: &str| {
            atest::TestRequest::get()
                .uri(&format!("/admin/comptes/dossiers-coursier{filtre}"))
                .insert_header(("authorization", format!("Bearer {acces}")))
                .to_request()
        };
        let resp = atest::call_service(&app, lister(acces_admin.clone(), "?statut=en_attente")).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps.as_array().unwrap().len(), 1);
        assert_eq!(corps[0]["compte_id"], json!(yao));
        assert_eq!(corps[0]["telephone_e164"], "+2250709080706");
        assert_eq!(
            corps[0]["piece_url"],
            serde_json::Value::Null,
            "la liste ne présigne rien — le détail seul le fait"
        );

        let requete = atest::TestRequest::get()
            .uri(&format!("/admin/comptes/{yao}/dossier-coursier"))
            .insert_header(("authorization", format!("Bearer {acces_admin}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert!(
            corps["piece_url"].as_str().unwrap().contains("comptes/pieces/"),
            "l'admin reçoit un lien vers la pièce (FR-017 scénario 2)"
        );
        assert_eq!(corps["referent_nom"], "K. Abou");

        // Validation → la porte s'ouvre.
        let resp = decider!(app, acces_admin, yao, "coursier", json!({ "action": "valider" }));
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(depot.coursier_autorise_en_ligne(yao).await.unwrap());
    }

    /// R14 — le rejeu rend 200 et l'état courant, sans rien recréer.
    #[sqlx::test(migrations = "../migrations")]
    async fn rejeu_de_soumission_rend_200(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;
        let cle = Uuid::now_v7().to_string();

        let resp = soumettre!(app, acces, &["moto"], &cle);
        assert_eq!(resp.status(), StatusCode::CREATED);

        // Le réseau a coupé : le client rejoue la MÊME requête.
        let resp = soumettre!(app, acces, &["moto"], &cle);
        assert_eq!(
            resp.status(),
            StatusCode::OK,
            "un rejeu n'est pas un conflit : il rend l'état courant (R14)"
        );
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["statut"], "en_attente");

        let evenements: i64 =
            sqlx::query_scalar("SELECT count(*) FROM outbox.evenement WHERE type_evenement = $1")
                .bind("dossier_coursier.soumis")
                .fetch_one(&pool)
                .await
                .unwrap();
        assert_eq!(evenements, 1, "aucun deuxième événement");
    }

    /// L'en-tête d'idempotence est REQUIS (R14) — son oubli est un 422, pas un
    /// succès silencieux.
    #[sqlx::test(migrations = "../migrations")]
    async fn soumission_sans_idempotency_key_422(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;

        let (type_contenu, corps) = corps_multipart(&["moto"], "image/jpeg", b"octets-piece");
        let requete = atest::TestRequest::post()
            .uri("/moi/dossier-coursier")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .insert_header(("content-type", type_contenu))
            .set_payload(corps)
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.corps_invalide");
        assert!(
            depot.dossier_coursier(yao).await.is_err(),
            "rien n'a été soumis"
        );
    }

    /// FR-015 scénario 6 — un véhicule hors zone est un 422 explicite.
    #[sqlx::test(migrations = "../migrations")]
    async fn vehicule_hors_zone_422(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;

        // `camion` existe au référentiel mais n'est pas actif à Tiassalé.
        let resp = soumettre!(app, acces, &["camion"]);
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.corps_invalide");
    }

    /// Un dossier déjà VALIDÉ ne se re-soumet pas (409, distinct du rejeu).
    #[sqlx::test(migrations = "../migrations")]
    async fn re_soumission_sur_dossier_valide_409(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;
        let acces_admin = jeton(&depot, ADMIN.parse().unwrap()).await;

        soumettre!(app, acces, &["moto"]);
        decider!(app, acces_admin, yao, "coursier", json!({ "action": "valider" }));

        let resp = soumettre!(app, acces, &["velo"]);
        assert_eq!(resp.status(), StatusCode::CONFLICT);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.transition_invalide");
    }

    /// Un compte sans dossier n'en a pas un vide : 404.
    #[sqlx::test(migrations = "../migrations")]
    async fn mon_dossier_404_si_jamais_soumis(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;

        let requete = atest::TestRequest::get()
            .uri("/moi/dossier-coursier")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.introuvable");
    }

    /// FR-017 — la revue des dossiers est réservée à l'admin.
    #[sqlx::test(migrations = "../migrations")]
    async fn revue_des_dossiers_403_sans_role_admin(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;
        soumettre!(app, acces, &["moto"]);

        // Yao a bien un dossier — mais consulter CEUX DES AUTRES est une
        // fonction admin, et son propre dossier passe par `/moi`.
        for uri in [
            "/admin/comptes/dossiers-coursier".to_owned(),
            format!("/admin/comptes/{yao}/dossier-coursier"),
        ] {
            let requete = atest::TestRequest::get()
                .uri(&uri)
                .insert_header(("authorization", format!("Bearer {acces}")))
                .to_request();
            let resp = atest::call_service(&app, requete).await;
            assert_eq!(resp.status(), StatusCode::FORBIDDEN, "{uri}");
            let corps: serde_json::Value = atest::read_body_json(resp).await;
            assert_eq!(corps["message_cle"], "comptes.erreur.role_requis");
        }
    }

    /// Sans session, rien du tout (FR-009).
    #[sqlx::test(migrations = "../migrations")]
    async fn dossier_401_sans_session(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);

        let requete = atest::TestRequest::get()
            .uri("/moi/dossier-coursier")
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    }

    /// Un `?statut=` hors énumération est un 422 aux clés de CE module.
    #[sqlx::test(migrations = "../migrations")]
    async fn filtre_statut_invalide_422(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let acces_admin = jeton(&depot, ADMIN.parse().unwrap()).await;

        let requete = atest::TestRequest::get()
            .uri("/admin/comptes/dossiers-coursier?statut=peut_etre")
            .insert_header(("authorization", format!("Bearer {acces_admin}")))
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["message_cle"], "comptes.erreur.corps_invalide");
    }

    /// Une pièce d'un type refusé est un 422 (constante produit).
    #[sqlx::test(migrations = "../migrations")]
    async fn piece_de_type_refuse_422(pool: PgPool) {
        let depot = preparer(&pool).await;
        let app = app!(depot);
        let yao = creer_compte(&depot, "+2250709080706").await;
        let acces = jeton(&depot, yao).await;

        let (type_contenu, corps) =
            corps_multipart(&["moto"], "application/x-msdownload", b"MZ-executable");
        let requete = atest::TestRequest::post()
            .uri("/moi/dossier-coursier")
            .insert_header(("authorization", format!("Bearer {acces}")))
            .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
            .insert_header(("content-type", type_contenu))
            .set_payload(corps)
            .to_request();
        let resp = atest::call_service(&app, requete).await;
        assert_eq!(resp.status(), StatusCode::UNPROCESSABLE_ENTITY);
    }
}
