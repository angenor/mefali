//! Surface HTTP du parcours d'authentification (CPT-01, `/auth/*`).
//!
//! Les DTO du contrat vivent ICI, en couche API ; le crate `comptes` reste un
//! domaine pur (patron du cycle 002). Toute chaîne d'erreur est une clé i18n fr
//! (`message_cle`, constitution VII).
//!
//! ## Anti-énumération (SC-003) — la règle de ce fichier
//!
//! `/auth/otp/demander` n'a QU'UNE réponse : 202 `envoye_si_valide`. Succès,
//! plafond atteint, numéro connu ou non — le même octet près. `/auth/otp/verifier`
//! n'a QU'UN échec : 401 `code_invalide_ou_expire`, que le code soit faux,
//! expiré, sur-essayé ou inexistant.
//!
//! Ces deux endpoints ne consultent AUCUN compte avant d'avoir validé le code :
//! la neutralité n'est pas obtenue en masquant des réponses divergentes, elle
//! est structurelle. La seule divergence — session vs consentement requis —
//! n'apparaît qu'après une vérification RÉUSSIE, donc à quelqu'un qui détient
//! déjà le téléphone : ce n'est pas un oracle.

use std::fmt;
use std::future::Future;
use std::pin::Pin;

use actix_web::dev::Payload;
use actix_web::http::{header, StatusCode};
use actix_web::{delete, get, post, web, FromRequest, HttpRequest, HttpResponse, ResponseError};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::json;
use utoipa::ToSchema;
use uuid::Uuid;

use comptes::inscription::{IssueVerification, SessionOuverte};
use comptes::{Appareil, AttributionRole, Compte, ErreurComptes, PgComptes, Plateforme, Role};

// ── Erreurs HTTP du module comptes ─────────────────────────────────────────

/// Erreur d'API rendue en `{ code, message_cle }` (clé i18n fr).
#[derive(Debug)]
pub enum ErreurApi {
    /// 401 — issue UNIQUE de tous les échecs de vérification (SC-003).
    CodeInvalideOuExpire,
    /// 401 — jeton d'inscription inconnu, expiré ou déjà consommé.
    JetonInscriptionInvalide,
    /// 401 — session absente, invalide ou révoquée.
    NonAuthentifie,
    /// 403 — rôle requis manquant ou suspendu.
    RoleRequis,
    /// 404 — ressource inconnue ou n'appartenant pas au compte.
    Introuvable,
    /// 409 — transition refusée par la machine à états (R9).
    TransitionInvalide,
    /// 422 — consentement ARTCI absent (FR-006).
    ConsentementRequis,
    /// 422 — numéro non normalisable en E.164.
    TelephoneInvalide,
    /// 422 — corps de requête invalide.
    CorpsInvalide,
    /// 500 — erreur interne (SQL, Redis, S3, configuration de zone).
    Interne,
}

impl ErreurApi {
    fn statut(&self) -> StatusCode {
        match self {
            ErreurApi::CodeInvalideOuExpire
            | ErreurApi::JetonInscriptionInvalide
            | ErreurApi::NonAuthentifie => StatusCode::UNAUTHORIZED,
            ErreurApi::RoleRequis => StatusCode::FORBIDDEN,
            ErreurApi::Introuvable => StatusCode::NOT_FOUND,
            ErreurApi::TransitionInvalide => StatusCode::CONFLICT,
            ErreurApi::ConsentementRequis
            | ErreurApi::TelephoneInvalide
            | ErreurApi::CorpsInvalide => StatusCode::UNPROCESSABLE_ENTITY,
            ErreurApi::Interne => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn code(&self) -> &'static str {
        match self {
            ErreurApi::CodeInvalideOuExpire => "code_invalide_ou_expire",
            ErreurApi::JetonInscriptionInvalide => "jeton_inscription_invalide",
            ErreurApi::NonAuthentifie => "non_authentifie",
            ErreurApi::RoleRequis => "role_requis",
            ErreurApi::Introuvable => "introuvable",
            ErreurApi::TransitionInvalide => "transition_invalide",
            ErreurApi::ConsentementRequis => "consentement_requis",
            ErreurApi::TelephoneInvalide => "telephone_invalide",
            ErreurApi::CorpsInvalide => "corps_invalide",
            ErreurApi::Interne => "erreur_interne",
        }
    }

    fn message_cle(&self) -> &'static str {
        match self {
            // Note : la clé du 401 de vérification vit sous `comptes.otp.*` et
            // non `comptes.erreur.*` — c'est le contrat (openapi-comptes.yaml).
            ErreurApi::CodeInvalideOuExpire => "comptes.otp.code_invalide_ou_expire",
            ErreurApi::JetonInscriptionInvalide => "comptes.erreur.jeton_inscription_invalide",
            ErreurApi::NonAuthentifie => "comptes.erreur.non_authentifie",
            ErreurApi::RoleRequis => "comptes.erreur.role_requis",
            ErreurApi::Introuvable => "comptes.erreur.introuvable",
            ErreurApi::TransitionInvalide => "comptes.erreur.transition_invalide",
            ErreurApi::ConsentementRequis => "comptes.erreur.consentement_requis",
            ErreurApi::TelephoneInvalide => "comptes.erreur.telephone_invalide",
            ErreurApi::CorpsInvalide => "comptes.erreur.corps_invalide",
            ErreurApi::Interne => "comptes.erreur.interne",
        }
    }
}

impl fmt::Display for ErreurApi {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.code())
    }
}

impl ResponseError for ErreurApi {
    fn status_code(&self) -> StatusCode {
        self.statut()
    }
    fn error_response(&self) -> HttpResponse {
        HttpResponse::build(self.statut())
            .json(json!({ "code": self.code(), "message_cle": self.message_cle() }))
    }
}

impl From<ErreurComptes> for ErreurApi {
    /// ⚠ SC-003 : `DefiOtpInvalide` couvre déjà les quatre causes d'échec
    /// (faux, expiré, essais épuisés, absent) — le domaine refuse de les
    /// distinguer, cette table ne peut donc pas les trahir.
    ///
    /// `PlafondAtteint` n'apparaît PAS ici : il n'est jamais rendu en erreur.
    /// `demander_otp` le replie sur le 202 neutre — le voir surgir en réponse
    /// signalerait une régression (voir `demander`).
    fn from(erreur: ErreurComptes) -> Self {
        use ErreurComptes as E;
        match erreur {
            E::DefiOtpInvalide => ErreurApi::CodeInvalideOuExpire,
            E::JetonInscriptionInvalide => ErreurApi::JetonInscriptionInvalide,
            // Refresh inconnu, session révoquée, ou rejeu détecté : le contrat
            // n'en fait qu'un 401 (dans le dernier cas, la session est déjà
            // tombée côté domaine — R2).
            E::RefreshInvalide => ErreurApi::NonAuthentifie,
            E::SessionInconnue(_) => ErreurApi::NonAuthentifie,
            E::RoleRequis(_) => ErreurApi::RoleRequis,
            E::CompteInconnu(_) | E::AdresseInconnue(_) | E::DossierInconnu(_) => {
                ErreurApi::Introuvable
            }
            E::TransitionInvalide { .. } => ErreurApi::TransitionInvalide,
            E::ConsentementRequis => ErreurApi::ConsentementRequis,
            E::TelephoneInvalide => ErreurApi::TelephoneInvalide,
            E::MotifRequis
            | E::VehiculeHorsZone(_)
            | E::DossierIncomplet
            | E::ObjetTropVolumineux
            | E::MediaInvalide(_) => ErreurApi::CorpsInvalide,
            // Plafond, infra et configuration : rien d'exploitable côté client.
            E::PlafondAtteint
            | E::Ephemere(_)
            | E::Objets(_)
            | E::Sms(_)
            | E::Zones(_)
            | E::ConfigurationZoneInvalide { .. }
            | E::Jeton(_)
            | E::Sql(_) => ErreurApi::Interne,
        }
    }
}

/// `JsonConfig` du module : un corps illisible → 422 `corps_invalide`.
pub fn config_json() -> web::JsonConfig {
    web::JsonConfig::default().error_handler(|_err, _req| ErreurApi::CorpsInvalide.into())
}

// ── DTO du contrat ─────────────────────────────────────────────────────────

/// Plateforme de l'appareil (contrat).
#[derive(Debug, Clone, Copy, Serialize, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum PlateformeDto {
    /// Android.
    Android,
    /// iOS.
    Ios,
}

impl From<PlateformeDto> for Plateforme {
    fn from(p: PlateformeDto) -> Self {
        match p {
            PlateformeDto::Android => Plateforme::Android,
            PlateformeDto::Ios => Plateforme::Ios,
        }
    }
}

impl From<Plateforme> for PlateformeDto {
    fn from(p: Plateforme) -> Self {
        match p {
            Plateforme::Android => PlateformeDto::Android,
            Plateforme::Ios => PlateformeDto::Ios,
        }
    }
}

/// Appareil déclaré par l'app à l'ouverture de session.
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AppareilDto {
    /// Nom lisible (« Pixel 7 de poche »), affiché tel quel dans la liste.
    #[schema(max_length = 80)]
    pub nom: String,
    /// Plateforme.
    pub plateforme: PlateformeDto,
}

impl From<AppareilDto> for Appareil {
    fn from(a: AppareilDto) -> Self {
        Appareil {
            nom: a.nom,
            plateforme: a.plateforme.into(),
        }
    }
}

/// Corps de `POST /auth/otp/demander`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct DemandeOtp {
    /// Saisie locale ou E.164 — normalisée avec l'indicatif de la zone (R4).
    pub telephone: String,
    /// Zone de l'app (bootstrap Tiassalé — R13).
    pub zone: Uuid,
}

/// Corps de `POST /auth/otp/verifier`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct VerificationOtp {
    /// Le MÊME numéro que celui de la demande.
    pub telephone: String,
    /// Zone de l'app.
    pub zone: Uuid,
    /// Code à 6 chiffres.
    #[schema(pattern = "^[0-9]{6}$")]
    pub code: String,
    /// Appareil — capté ici, conservé jusqu'à l'inscription (R3).
    pub appareil: AppareilDto,
}

/// Corps de `POST /auth/inscription`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct Inscription {
    /// Émis par `/auth/otp/verifier`, usage unique, TTL 10 min.
    pub jeton_inscription: String,
    /// Version du texte ARTCI accepté — servie par la config de zone.
    pub consentement_version: String,
}

/// Réponse UNIQUE de `/auth/otp/demander`.
#[derive(Debug, Serialize, ToSchema)]
pub struct Accepte {
    /// Toujours `comptes.otp.envoye_si_valide`.
    #[schema(example = "comptes.otp.envoye_si_valide")]
    pub message_cle: String,
}

/// Paire de jetons (contrat).
#[derive(Debug, Serialize, ToSchema)]
pub struct JetonsDto {
    /// JWT HS256, 15 min (claims sub/sid).
    pub acces: String,
    /// Opaque 256 bits — tourne à chaque usage.
    pub rafraichissement: String,
}

/// État d'un rôle (contrat).
#[derive(Debug, Serialize, ToSchema)]
pub struct EtatRoleDto {
    /// Rôle concerné.
    pub role: String,
    /// Statut courant.
    pub statut: String,
    /// Motif de la dernière décision admin.
    pub motif: Option<String>,
    /// Horodatage de la dernière décision.
    pub decide_le: Option<DateTime<Utc>>,
}

impl From<AttributionRole> for EtatRoleDto {
    fn from(a: AttributionRole) -> Self {
        EtatRoleDto {
            role: a.role.comme_str().to_owned(),
            statut: a.statut.comme_str().to_owned(),
            motif: a.motif,
            decide_le: a.decide_le,
        }
    }
}

/// Compte courant et l'état de TOUS ses rôles (contrat `CompteMoi`).
#[derive(Debug, Serialize, ToSchema)]
pub struct CompteMoi {
    /// Identifiant du compte.
    pub id: Uuid,
    /// Identité Mefali — aucune donnée nominative au MVP.
    pub telephone_e164: String,
    /// Zone de rattachement.
    pub zone_id: Uuid,
    /// Rôles et leurs statuts (tous, pas seulement les valides).
    pub roles: Vec<EtatRoleDto>,
    /// Création du compte.
    pub cree_le: DateTime<Utc>,
}

impl CompteMoi {
    /// Assemble le DTO à partir du compte et de ses attributions.
    pub fn assembler(compte: Compte, roles: Vec<AttributionRole>) -> Self {
        CompteMoi {
            id: compte.id,
            telephone_e164: compte.telephone_e164,
            zone_id: compte.zone_id,
            roles: roles.into_iter().map(EtatRoleDto::from).collect(),
            cree_le: compte.cree_le,
        }
    }
}

/// Discriminant de [`SessionOuverteDto`] — une seule valeur possible.
///
/// Un type à UNE variante, et non un `String` : la valeur du discriminant ne
/// peut alors pas diverger du schéma, et ce n'est pas à l'appelant de penser à
/// l'écrire juste.
#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum DiscriminantSession {
    /// Toujours `session`.
    Session,
}

/// Discriminant de [`ConsentementRequisDto`].
#[derive(Debug, Serialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub enum DiscriminantConsentement {
    /// Toujours `consentement_requis`.
    ConsentementRequis,
}

/// Session ouverte sur un compte (contrat `SessionOuverte`).
///
/// Schéma NOMMÉ et non une variante anonyme du `oneOf` : c'est aussi le corps
/// entier du 201 de `/auth/inscription`, qui n'a qu'une issue possible.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = SessionOuverte)]
pub struct SessionOuverteDto {
    /// Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
    pub resultat: DiscriminantSession,
    /// Jetons de l'appareil.
    pub jetons: JetonsDto,
    /// Compte connecté.
    pub compte: CompteMoi,
}

/// Consentement ARTCI exigé avant création du compte (contrat
/// `ConsentementRequis`, FR-006).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ConsentementRequis)]
pub struct ConsentementRequisDto {
    /// Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
    pub resultat: DiscriminantConsentement,
    /// Jeton d'inscription à usage unique.
    pub jeton_inscription: String,
}

/// Issue de `/auth/otp/verifier` — `oneOf` discriminé par `resultat`.
///
/// `untagged` : chaque membre porte DÉJÀ son `resultat`, si bien que le JSON du
/// câble est celui d'un `oneOf` discriminé, tandis que le contrat, lui, expose
/// deux schémas NOMMÉS et réutilisables plutôt que deux objets anonymes.
#[derive(Debug, Serialize, ToSchema)]
#[serde(untagged)]
pub enum ResultatVerification {
    /// Numéro connu — session ouverte.
    Session(SessionOuverteDto),
    /// Numéro inconnu — consentement ARTCI exigé avant création (FR-006).
    ConsentementRequis(ConsentementRequisDto),
}

impl From<SessionOuverte> for SessionOuverteDto {
    fn from(ouverte: SessionOuverte) -> Self {
        SessionOuverteDto {
            resultat: DiscriminantSession::Session,
            jetons: JetonsDto {
                acces: ouverte.jetons.acces,
                rafraichissement: ouverte.jetons.rafraichissement,
            },
            compte: CompteMoi::assembler(ouverte.compte, ouverte.roles),
        }
    }
}

/// IP du client pour le plafond anti-pumping (R12).
///
/// `realip_remote_addr` lit `Forwarded`/`X-Forwarded-For` : c'est nécessaire
/// derrière le reverse proxy du VPS (`infra/vps/Caddyfile`), sans quoi TOUTES
/// les requêtes partageraient le compteur du proxy et le plafond serait
/// inopérant. En contrepartie, le port 8080 ne doit JAMAIS être exposé
/// directement : un client qui parle à l'API sans passer par le proxy peut
/// forger cet en-tête et se donner autant de compteurs qu'il veut.
fn ip_client(requete: &HttpRequest) -> String {
    requete
        .connection_info()
        .realip_remote_addr()
        .unwrap_or("inconnue")
        .to_owned()
}

// ── POST /auth/otp/demander ────────────────────────────────────────────────

/// Demande l'envoi d'un code OTP. Réponse TOUJOURS neutre (SC-003).
#[utoipa::path(
    post,
    path = "/auth/otp/demander",
    tag = "auth",
    request_body = DemandeOtp,
    responses(
        (status = 202, description = "Réponse UNIQUE : numéro connu ou non, plafond atteint ou non. \
                                      Chaque demande invalide le code précédent du numéro.",
         body = Accepte),
        (status = 422, description = "Numéro non normalisable — erreur de FORMAT, neutre quant à l'existence d'un compte.",
         body = ErreurApiDto),
    ),
)]
#[post("/auth/otp/demander")]
pub async fn demander(
    requete: HttpRequest,
    corps: web::Json<DemandeOtp>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let issue = depot
        .demander_otp(corps.zone, &corps.telephone, &ip_client(&requete))
        .await;

    // Le plafond N'EST PAS une erreur pour le client : le lui dire donnerait un
    // oracle (« ce numéro a déjà reçu 3 SMS cette heure »). Il est journalisé
    // côté serveur et rendu comme un succès (research R12).
    match issue {
        Ok(()) => {}
        Err(ErreurComptes::PlafondAtteint) => {
            tracing::info!("plafond OTP atteint — aucun SMS envoyé, réponse neutre");
        }
        Err(autre) => return Err(autre.into()),
    }

    Ok(HttpResponse::Accepted().json(Accepte {
        message_cle: "comptes.otp.envoye_si_valide".to_owned(),
    }))
}

// ── POST /auth/otp/verifier ────────────────────────────────────────────────

/// Vérifie le code : ouvre une session (numéro connu) ou exige le consentement.
#[utoipa::path(
    post,
    path = "/auth/otp/verifier",
    tag = "auth",
    request_body = VerificationOtp,
    responses(
        (status = 200, description = "Vérification réussie — deux issues discriminées par `resultat`.",
         body = ResultatVerification),
        (status = 401, description = "Code faux, expiré (> 5 min) ou essais épuisés (3) — message NEUTRE \
                                      unique, identique dans TOUS les cas d'échec.",
         body = ErreurApiDto),
        (status = 422, description = "Numéro non normalisable.", body = ErreurApiDto),
    ),
)]
#[post("/auth/otp/verifier")]
pub async fn verifier(
    corps: web::Json<VerificationOtp>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let corps = corps.into_inner();
    let issue = depot
        .verifier_otp(
            corps.zone,
            &corps.telephone,
            &corps.code,
            &corps.appareil.into(),
        )
        .await?;

    let resultat = match issue {
        IssueVerification::Session(ouverte) => {
            ResultatVerification::Session(SessionOuverteDto::from(ouverte))
        }
        IssueVerification::ConsentementRequis { jeton_inscription } => {
            ResultatVerification::ConsentementRequis(ConsentementRequisDto {
                resultat: DiscriminantConsentement::ConsentementRequis,
                jeton_inscription,
            })
        }
    };
    Ok(HttpResponse::Ok().json(resultat))
}

// ── POST /auth/inscription ─────────────────────────────────────────────────

/// Crée le compte après consentement ARTCI, puis ouvre sa session.
///
/// Le 201 rend `SessionOuverte` SEULE, et non le `oneOf` de
/// `/auth/otp/verifier` : ici le consentement vient d'être fourni, donc
/// `consentement_requis` est une issue que ce chemin ne peut pas produire.
/// L'annoncer obligerait chaque client à traiter une branche morte.
#[utoipa::path(
    post,
    path = "/auth/inscription",
    tag = "auth",
    request_body = Inscription,
    responses(
        (status = 201, description = "Compte créé (réduit au numéro vérifié) + session ouverte.",
         body = SessionOuverteDto),
        (status = 401, description = "Jeton d'inscription invalide, expiré (10 min) ou déjà consommé.",
         body = ErreurApiDto),
        (status = 422, description = "Consentement absent — aucun compte n'est créé (FR-006).",
         body = ErreurApiDto),
    ),
)]
#[post("/auth/inscription")]
pub async fn inscrire(
    corps: web::Json<Inscription>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let ouverte = depot
        .inscrire(&corps.jeton_inscription, &corps.consentement_version)
        .await?;
    Ok(HttpResponse::Created().json(SessionOuverteDto::from(ouverte)))
}

// ── Extracteur Auth + exiger_role (research R5) ────────────────────────────

/// Contexte d'autorisation d'une requête : QUI parle, DEPUIS quelle session, et
/// avec quels rôles VALIDES.
///
/// ## Pourquoi une requête en base à chaque appel
///
/// Le jeton ne porte aucun rôle (R1). Les rôles sont donc relus ici, à chaque
/// requête. C'est ce SELECT indexé — et lui seul — qui rend vraies deux
/// exigences de la spec qu'un JWT porteur de rôles rendrait fausses pendant
/// 15 minutes : une suspension vaut dès la requête suivante (US3 scénario 6),
/// et une session révoquée perd l'accès immédiatement, sans attendre
/// l'expiration de son accès court (US2 scénario 4, mieux que SC-004).
#[derive(Debug, Clone)]
pub struct Auth {
    /// Compte authentifié.
    pub compte_id: Uuid,
    /// Session porteuse (claim `sid`).
    pub session_id: Uuid,
    /// Rôles au statut `valide` UNIQUEMENT.
    pub roles_valides: Vec<Role>,
}

impl Auth {
    /// Exige un rôle valide, sinon 403 (FR-009).
    pub fn exiger_role(&self, role: Role) -> Result<(), ErreurApi> {
        if self.roles_valides.contains(&role) {
            Ok(())
        } else {
            Err(ErreurApi::RoleRequis)
        }
    }

    /// `true` si le compte porte ce rôle validé.
    pub fn a_role(&self, role: Role) -> bool {
        self.roles_valides.contains(&role)
    }
}

impl FromRequest for Auth {
    type Error = actix_web::Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self, Self::Error>>>>;

    fn from_request(requete: &HttpRequest, _payload: &mut Payload) -> Self::Future {
        let jeton = requete
            .headers()
            .get(header::AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "))
            .map(str::to_owned);
        let depot = requete.app_data::<web::Data<PgComptes>>().cloned();

        Box::pin(async move {
            let (Some(jeton), Some(depot)) = (jeton, depot) else {
                return Err(ErreurApi::NonAuthentifie.into());
            };
            // 1. Signature + expiration : sans toucher la base.
            let claims = comptes::verifier_acces(depot.secret(), &jeton)
                .map_err(|_| ErreurApi::NonAuthentifie)?;
            // 2. La base a le dernier mot : session vivante et rôles du moment.
            let Some((compte_id, roles_valides)) = depot
                .contexte_auth(claims.sid)
                .await
                .map_err(ErreurApi::from)?
            else {
                return Err(ErreurApi::NonAuthentifie.into());
            };
            // Un jeton parfaitement signé dont le `sub` ne correspond plus au
            // porteur de la session est une incohérence : on refuse.
            if compte_id != claims.sub {
                return Err(ErreurApi::NonAuthentifie.into());
            }
            Ok(Auth {
                compte_id,
                session_id: claims.sid,
                roles_valides,
            })
        })
    }
}

// ── Endpoints de session (CPT-02) ──────────────────────────────────────────

/// Corps de `POST /auth/rafraichir`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct DemandeRafraichissement {
    /// Jeton de renouvellement opaque courant.
    pub rafraichissement: String,
}

/// Session/appareil du compte (contrat `SessionAppareil`).
#[derive(Debug, Serialize, ToSchema)]
pub struct SessionAppareil {
    /// Identifiant de session.
    pub id: Uuid,
    /// Nom déclaré par l'app.
    pub appareil_nom: String,
    /// Plateforme.
    pub appareil_plateforme: PlateformeDto,
    /// Ouverture.
    pub cree_le: DateTime<Utc>,
    /// Dernier rafraîchissement.
    pub derniere_activite_le: DateTime<Utc>,
    /// Session de l'appareil appelant — celle qu'on ne se coupe pas par erreur.
    pub courante: bool,
}

/// Échange le refresh contre un nouvel accès (rotation systématique, R2).
#[utoipa::path(
    post,
    path = "/auth/rafraichir",
    tag = "auth",
    request_body = DemandeRafraichissement,
    responses(
        (status = 200, description = "Nouveaux jetons — l'ancien refresh est invalidé. Aucune expiration d'inactivité.",
         body = JetonsDto),
        (status = 401, description = "Refresh inconnu, session révoquée, OU réutilisation d'un jeton déjà tourné —                                       dans ce dernier cas la session est RÉVOQUÉE (détection de vol, R2).",
         body = ErreurApiDto),
    ),
)]
#[post("/auth/rafraichir")]
pub async fn rafraichir(
    corps: web::Json<DemandeRafraichissement>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let jetons = depot.tourner_refresh(&corps.rafraichissement).await?;
    Ok(HttpResponse::Ok().json(JetonsDto {
        acces: jetons.acces,
        rafraichissement: jetons.rafraichissement,
    }))
}

/// Révoque la session courante (déconnexion locale).
#[utoipa::path(
    post,
    path = "/auth/deconnexion",
    tag = "auth",
    responses(
        (status = 204, description = "Session révoquée."),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/auth/deconnexion")]
pub async fn deconnexion(
    auth: Auth,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    depot.deconnecter(auth.session_id, auth.compte_id).await?;
    Ok(HttpResponse::NoContent().finish())
}

/// Compte courant et états de TOUS ses rôles.
#[utoipa::path(
    get,
    path = "/moi",
    tag = "moi",
    responses(
        (status = 200, description = "Compte courant.", body = CompteMoi),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi")]
pub async fn moi(auth: Auth, depot: web::Data<PgComptes>) -> Result<HttpResponse, ErreurApi> {
    let compte = depot.compte(auth.compte_id).await?;
    let roles = depot.attributions(auth.compte_id).await?;
    Ok(HttpResponse::Ok().json(CompteMoi::assembler(compte, roles)))
}

/// Appareils/sessions actifs du compte (FR-008).
#[utoipa::path(
    get,
    path = "/moi/sessions",
    tag = "moi",
    responses(
        (status = 200, description = "Appareils actifs.", body = Vec<SessionAppareil>),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/sessions")]
pub async fn mes_sessions(
    auth: Auth,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    let sessions: Vec<SessionAppareil> = depot
        .sessions_actives(auth.compte_id)
        .await?
        .into_iter()
        .map(|s| SessionAppareil {
            courante: s.id == auth.session_id,
            id: s.id,
            appareil_nom: s.appareil.nom,
            appareil_plateforme: s.appareil.plateforme.into(),
            cree_le: s.cree_le,
            derniere_activite_le: s.derniere_activite_le,
        })
        .collect();
    Ok(HttpResponse::Ok().json(sessions))
}

/// Déconnexion à distance d'un appareil (SC-004).
#[utoipa::path(
    delete,
    path = "/moi/sessions/{session_id}",
    tag = "moi",
    params(("session_id" = Uuid, Path, description = "Appareil à déconnecter.")),
    responses(
        (status = 204, description = "Session révoquée — événement `session.revoquee` émis."),
        (status = 404, description = "Session inconnue ou n'appartenant pas au compte.", body = ErreurApiDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[delete("/moi/sessions/{session_id}")]
pub async fn revoquer_session(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgComptes>,
) -> Result<HttpResponse, ErreurApi> {
    depot
        .revoquer_appareil(auth.compte_id, chemin.into_inner(), auth.compte_id)
        .await
        // Une session qui n'est pas la sienne est INTROUVABLE, pas « interdite » :
        // un 403 confirmerait qu'elle existe.
        .map_err(|e| match e {
            ErreurComptes::SessionInconnue(_) => ErreurApi::Introuvable,
            autre => autre.into(),
        })?;
    Ok(HttpResponse::NoContent().finish())
}

/// Corps d'erreur du contrat — `{ code, message_cle }`.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ErreurApi)]
pub struct ErreurApiDto {
    /// Code stable, exploitable par le client.
    pub code: String,
    /// Clé i18n fr — aucune chaîne UI en dur (constitution VII).
    pub message_cle: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;
    use std::time::Duration;

    use actix_web::{body::MessageBody, test as atest, App};
    use comptes::{HorlogeManuelle, MemoireEphemere, MemoireObjets, SmsTraces};
    use sqlx::PgPool;

    /// Zone Tiassalé du seed (l'indicatif +225 y est hérité du pays).
    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";
    /// Numéro du premier admin — le seul numéro CONNU après le seed.
    const NUMERO_INSCRIT: &str = "0700000001";
    /// Numéro jamais vu.
    const NUMERO_INCONNU: &str = "0709080706";
    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    struct Bac {
        depot: PgComptes,
        sms: Arc<SmsTraces>,
        horloge: HorlogeManuelle,
    }

    async fn preparer(pool: &PgPool) -> Bac {
        crate::charger_seeds(pool).await.unwrap();
        let horloge = HorlogeManuelle::new();
        let sms = Arc::new(SmsTraces::new());
        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::avec_horloge(horloge.clone())),
            sms.clone(),
            Arc::new(MemoireObjets::new()),
            Arc::from(SECRET),
        );
        Bac {
            depot,
            sms,
            horloge,
        }
    }

    macro_rules! app {
        ($bac:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($bac.depot.clone()))
                    .app_data(config_json())
                    .service(demander)
                    .service(verifier)
                    .service(inscrire),
            )
            .await
        };
    }

    /// Renvoie (statut, octets EXACTS du corps) — la granularité qu'exige
    /// SC-003 : comparer du JSON désérialisé laisserait passer une divergence
    /// d'ordre de clés ou d'espaces, qui reste un canal d'énumération.
    ///
    /// Macro et non fonction : nommer le type de `Service` rendu par
    /// `init_service` exigerait une dépendance directe sur `actix-http`, qu'
    /// `actix-web` ne ré-exporte pas.
    macro_rules! appeler {
        ($app:expr, $uri:expr, $corps:expr $(,)?) => {{
            let requete = atest::TestRequest::post()
                .uri($uri)
                .peer_addr("1.2.3.4:9000".parse().unwrap())
                .set_json($corps)
                .to_request();
            let reponse = atest::call_service(&$app, requete).await;
            let statut = reponse.status();
            let octets = reponse.into_body().try_into_bytes().unwrap().to_vec();
            (statut, octets)
        }};
    }

    macro_rules! demander {
        ($app:expr, $numero:expr) => {
            appeler!(
                $app,
                "/auth/otp/demander",
                json!({ "telephone": $numero, "zone": TIASSALE })
            )
        };
    }

    macro_rules! verifier {
        ($app:expr, $numero:expr, $code:expr) => {
            appeler!(
                $app,
                "/auth/otp/verifier",
                json!({ "telephone": $numero, "zone": TIASSALE, "code": $code,
                        "appareil": { "nom": "Pixel de test", "plateforme": "android" } })
            )
        };
    }

    fn json_de(octets: &[u8]) -> serde_json::Value {
        serde_json::from_slice(octets).expect("corps JSON")
    }

    /// Dernier code parti au SMS (SMS_MODE=traces le retient — R6).
    fn dernier_code(bac: &Bac) -> String {
        bac.sms.envoyes().last().unwrap().params["code"]
            .as_str()
            .unwrap()
            .to_owned()
    }

    /// Un code faux, garanti différent du bon.
    fn faux_code(bon: &str) -> &'static str {
        if bon == "111111" {
            "222222"
        } else {
            "111111"
        }
    }

    /// SC-001 — parcours complet : demande → vérification → consentement →
    /// session, puis reconnexion du même numéro sans doublon.
    #[sqlx::test(migrations = "../migrations")]
    async fn parcours_complet_inscription_puis_connexion(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        // 1. Demande — saisie LOCALE sans indicatif.
        let (statut, corps) = demander!(app, NUMERO_INCONNU);
        assert_eq!(statut, StatusCode::ACCEPTED);
        assert_eq!(
            json_de(&corps)["message_cle"],
            "comptes.otp.envoye_si_valide"
        );

        // 2. Vérification — numéro inconnu → consentement requis.
        let (statut, corps) = verifier!(app, NUMERO_INCONNU, dernier_code(&bac));
        assert_eq!(statut, StatusCode::OK);
        let corps = json_de(&corps);
        assert_eq!(corps["resultat"], "consentement_requis");
        let jeton = corps["jeton_inscription"].as_str().unwrap().to_owned();

        // 3. Inscription — consentement obligatoire (FR-006).
        let (statut, corps) = appeler!(
            app,
            "/auth/inscription",
            json!({ "jeton_inscription": jeton, "consentement_version": "2026-07" })
        );
        assert_eq!(statut, StatusCode::CREATED);
        let corps = json_de(&corps);
        assert_eq!(corps["resultat"], "session");
        assert_eq!(corps["compte"]["telephone_e164"], "+2250709080706");
        assert_eq!(corps["compte"]["roles"][0]["role"], "client");
        assert_eq!(corps["compte"]["roles"][0]["statut"], "valide");
        assert!(!corps["jetons"]["acces"].as_str().unwrap().is_empty());
        assert!(!corps["jetons"]["rafraichissement"]
            .as_str()
            .unwrap()
            .is_empty());

        // 4. Reconnexion du MÊME numéro → session, aucun doublon.
        demander!(app, NUMERO_INCONNU);
        let (statut, corps) = verifier!(app, NUMERO_INCONNU, dernier_code(&bac));
        assert_eq!(statut, StatusCode::OK);
        assert_eq!(json_de(&corps)["resultat"], "session");

        let comptes: i64 = sqlx::query_scalar("SELECT count(*) FROM comptes.compte")
            .fetch_one(&pool)
            .await
            .unwrap();
        // 3 : l'admin (seed 20) + Kofi (seed 30, cycle 005) + le nouveau.
        assert_eq!(comptes, 3, "les comptes du seed + le nouveau — aucun doublon");
    }

    /// SC-003 — `/auth/otp/demander` : numéro INSCRIT et numéro INCONNU
    /// donnent des réponses identiques OCTET POUR OCTET.
    #[sqlx::test(migrations = "../migrations")]
    async fn demander_neutre_octet_pour_octet(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        let inscrit = demander!(app, NUMERO_INSCRIT);
        let inconnu = demander!(app, NUMERO_INCONNU);

        assert_eq!(inscrit.0, StatusCode::ACCEPTED);
        assert_eq!(inscrit, inconnu, "aucune divergence exploitable (SC-003)");
    }

    /// SC-003 — le cœur de l'anti-énumération : TOUTES les issues d'échec de
    /// `/auth/otp/verifier` (aucun défi, code faux, essais épuisés, expiré)
    /// donnent la MÊME réponse, pour un numéro inscrit comme pour un inconnu.
    #[sqlx::test(migrations = "../migrations")]
    async fn verifier_401_neutre_sur_toutes_les_issues(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);
        let mut reponses = Vec::new();

        for numero in [NUMERO_INSCRIT, NUMERO_INCONNU] {
            // (a) aucun défi n'a jamais été demandé.
            reponses.push(("aucun défi", numero, verifier!(app, numero, "000000")));

            // (b) défi en cours, code FAUX.
            demander!(app, numero);
            let faux = faux_code(&dernier_code(&bac));
            reponses.push(("code faux", numero, verifier!(app, numero, faux)));

            // (c) essais épuisés : même le BON code ne passe plus.
            demander!(app, numero);
            let bon = dernier_code(&bac);
            let faux = faux_code(&bon);
            for _ in 0..3 {
                verifier!(app, numero, faux);
            }
            reponses.push(("essais épuisés", numero, verifier!(app, numero, &bon)));

            // (d) code EXPIRÉ (> 5 min).
            demander!(app, numero);
            let bon = dernier_code(&bac);
            bac.horloge.avancer(Duration::from_secs(301));
            reponses.push(("expiré", numero, verifier!(app, numero, &bon)));
        }

        let (_, _, reference) = &reponses[0];
        assert_eq!(reference.0, StatusCode::UNAUTHORIZED);
        for (cas, numero, reponse) in &reponses {
            assert_eq!(
                reponse, reference,
                "l'issue « {cas} » du numéro {numero} diverge — SC-003 exige \
                 des réponses indistinguables"
            );
        }
        assert_eq!(
            json_de(&reference.1)["message_cle"],
            "comptes.otp.code_invalide_ou_expire"
        );
    }

    /// SC-002 + SC-003 — le 4e SMS de l'heure n'est PAS envoyé, et la réponse
    /// reste exactement celle du succès : le plafond ne doit pas être un oracle.
    #[sqlx::test(migrations = "../migrations")]
    async fn plafond_sms_repond_comme_un_succes(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        let succes = demander!(app, NUMERO_INCONNU);
        demander!(app, NUMERO_INCONNU);
        demander!(app, NUMERO_INCONNU);
        assert_eq!(bac.sms.nombre(), 3);

        let au_plafond = demander!(app, NUMERO_INCONNU);
        assert_eq!(bac.sms.nombre(), 3, "aucun 4e SMS (SC-002)");
        assert_eq!(
            au_plafond, succes,
            "la réponse au plafond est celle du succès (SC-003)"
        );
    }

    /// Numéro non normalisable → 422 de FORMAT, et aucun SMS gaspillé.
    #[sqlx::test(migrations = "../migrations")]
    async fn numero_invalide_422(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        let (statut, corps) = demander!(app, "12");
        assert_eq!(statut, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(
            json_de(&corps)["message_cle"],
            "comptes.erreur.telephone_invalide"
        );
        assert_eq!(bac.sms.nombre(), 0);
    }

    /// Corps illisible → 422 `corps_invalide` (et non le 400 par défaut d'Actix).
    #[sqlx::test(migrations = "../migrations")]
    async fn corps_invalide_422(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        let (statut, corps) = appeler!(
            app,
            "/auth/otp/demander",
            json!({ "telephone": NUMERO_INCONNU, "zone": "pas-un-uuid" })
        );
        assert_eq!(statut, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(json_de(&corps)["code"], "corps_invalide");
    }

    /// FR-006 — sans consentement : 422 et AUCUN compte créé.
    #[sqlx::test(migrations = "../migrations")]
    async fn inscription_sans_consentement_422(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        demander!(app, NUMERO_INCONNU);
        let (_, corps) = verifier!(app, NUMERO_INCONNU, dernier_code(&bac));
        let jeton = json_de(&corps)["jeton_inscription"]
            .as_str()
            .unwrap()
            .to_owned();

        let (statut, corps) = appeler!(
            app,
            "/auth/inscription",
            json!({ "jeton_inscription": jeton, "consentement_version": "" })
        );
        assert_eq!(statut, StatusCode::UNPROCESSABLE_ENTITY);
        assert_eq!(
            json_de(&corps)["message_cle"],
            "comptes.erreur.consentement_requis"
        );

        let comptes: i64 = sqlx::query_scalar("SELECT count(*) FROM comptes.compte")
            .fetch_one(&pool)
            .await
            .unwrap();
        // 2 : admin (seed 20) + Kofi (seed 30) — AUCUN compte créé en plus.
        assert_eq!(comptes, 2, "seuls les comptes du seed — aucun compte créé");
    }

    /// R3 — jeton d'inscription rejoué ou inventé → 401.
    #[sqlx::test(migrations = "../migrations")]
    async fn jeton_inscription_rejoue_401(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        demander!(app, NUMERO_INCONNU);
        let (_, corps) = verifier!(app, NUMERO_INCONNU, dernier_code(&bac));
        let jeton = json_de(&corps)["jeton_inscription"]
            .as_str()
            .unwrap()
            .to_owned();
        let inscription = json!({ "jeton_inscription": jeton, "consentement_version": "2026-07" });

        let (statut, _) = appeler!(app, "/auth/inscription", inscription.clone());
        assert_eq!(statut, StatusCode::CREATED);

        let (statut, corps) = appeler!(app, "/auth/inscription", inscription);
        assert_eq!(statut, StatusCode::UNAUTHORIZED, "usage unique");
        assert_eq!(
            json_de(&corps)["message_cle"],
            "comptes.erreur.jeton_inscription_invalide"
        );

        let (statut, _) = appeler!(
            app,
            "/auth/inscription",
            json!({ "jeton_inscription": "invente", "consentement_version": "2026-07" })
        );
        assert_eq!(statut, StatusCode::UNAUTHORIZED);
    }
}

#[cfg(test)]
mod tests_sessions {
    use super::*;
    use std::sync::Arc;

    use actix_web::{test as atest, App};
    use comptes::{MemoireEphemere, MemoireObjets, SmsTraces};
    use sqlx::PgPool;

    const TIASSALE: &str = "01900000-0000-7000-8000-000000000002";
    const NUMERO: &str = "0709080706";
    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    struct Bac {
        depot: PgComptes,
        sms: Arc<SmsTraces>,
    }

    async fn preparer(pool: &PgPool) -> Bac {
        crate::charger_seeds(pool).await.unwrap();
        let sms = Arc::new(SmsTraces::new());
        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            sms.clone(),
            Arc::new(MemoireObjets::new()),
            Arc::from(SECRET),
        );
        Bac { depot, sms }
    }

    macro_rules! app {
        ($bac:expr) => {
            atest::init_service(
                App::new()
                    .app_data(web::Data::new($bac.depot.clone()))
                    .app_data(config_json())
                    .service(demander)
                    .service(verifier)
                    .service(inscrire)
                    .service(rafraichir)
                    .service(deconnexion)
                    .service(moi)
                    .service(mes_sessions)
                    .service(revoquer_session),
            )
            .await
        };
    }

    /// Inscrit un numéro (ou ouvre une session s'il est connu) et renvoie ses
    /// jetons. Passe par le domaine : ces tests-ci portent sur les endpoints
    /// PROTÉGÉS, pas sur le parcours OTP (couvert par `tests`).
    async fn jetons_pour(bac: &Bac, numero: &str) -> (String, String) {
        bac.depot
            .demander_otp(TIASSALE.parse().unwrap(), numero, "1.2.3.4")
            .await
            .unwrap();
        let code = bac.sms.envoyes().last().unwrap().params["code"]
            .as_str()
            .unwrap()
            .to_owned();
        let issue = bac
            .depot
            .verifier_otp(
                TIASSALE.parse().unwrap(),
                numero,
                &code,
                &Appareil {
                    nom: "Pixel".to_owned(),
                    plateforme: Plateforme::Android,
                },
            )
            .await
            .unwrap();
        match issue {
            IssueVerification::ConsentementRequis { jeton_inscription } => {
                let ouverte = bac
                    .depot
                    .inscrire(&jeton_inscription, "2026-07")
                    .await
                    .unwrap();
                (ouverte.jetons.acces, ouverte.jetons.rafraichissement)
            }
            IssueVerification::Session(ouverte) => {
                (ouverte.jetons.acces, ouverte.jetons.rafraichissement)
            }
        }
    }

    /// R5 — sans jeton, avec un jeton bidon, ou après révocation : 401.
    #[sqlx::test(migrations = "../migrations")]
    async fn moi_401_sans_session_valide(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);

        for entete in [None, Some("Bearer pas-un-jwt"), Some("jwt-sans-prefixe")] {
            let mut requete = atest::TestRequest::get().uri("/moi");
            if let Some(v) = entete {
                requete = requete.insert_header(("authorization", v));
            }
            let resp = atest::call_service(&app, requete.to_request()).await;
            assert_eq!(
                resp.status(),
                StatusCode::UNAUTHORIZED,
                "en-tête = {entete:?}"
            );
        }
    }

    /// US2 scénario 4 — une session révoquée perd l'accès IMMÉDIATEMENT, sans
    /// attendre l'expiration des 15 min de son jeton (mieux que SC-004).
    #[sqlx::test(migrations = "../migrations")]
    async fn session_revoquee_perd_l_acces_des_la_requete_suivante(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);
        let (acces, _) = jetons_pour(&bac, NUMERO).await;

        let porteur = format!("Bearer {acces}");
        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri("/moi")
                .insert_header(("authorization", porteur.clone()))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::OK);

        // Déconnexion, puis RÉUTILISATION du même jeton d'accès, toujours
        // cryptographiquement valide pour 15 minutes.
        let resp = atest::call_service(
            &app,
            atest::TestRequest::post()
                .uri("/auth/deconnexion")
                .insert_header(("authorization", porteur.clone()))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::NO_CONTENT);

        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri("/moi")
                .insert_header(("authorization", porteur))
                .to_request(),
        )
        .await;
        assert_eq!(
            resp.status(),
            StatusCode::UNAUTHORIZED,
            "le jeton est encore signé et non expiré — c'est la BASE qui refuse"
        );
    }

    /// `/moi` expose le compte et TOUS ses rôles.
    #[sqlx::test(migrations = "../migrations")]
    async fn moi_200_expose_compte_et_roles(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);
        let (acces, _) = jetons_pour(&bac, NUMERO).await;

        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri("/moi")
                .insert_header(("authorization", format!("Bearer {acces}")))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(corps["telephone_e164"], "+2250709080706");
        assert_eq!(corps["roles"][0]["role"], "client");
        assert_eq!(corps["roles"][0]["statut"], "valide");
    }

    /// La rotation délivre de nouveaux jetons ; l'ancien refresh ne vaut plus rien.
    #[sqlx::test(migrations = "../migrations")]
    async fn rafraichir_200_puis_ancien_refresh_401(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);
        let (_, refresh) = jetons_pour(&bac, NUMERO).await;

        let requete = |r: String| {
            atest::TestRequest::post()
                .uri("/auth/rafraichir")
                .set_json(json!({ "rafraichissement": r }))
                .to_request()
        };

        let resp = atest::call_service(&app, requete(refresh.clone())).await;
        assert_eq!(resp.status(), StatusCode::OK);
        let corps: serde_json::Value = atest::read_body_json(resp).await;
        assert!(!corps["acces"].as_str().unwrap().is_empty());
        assert_ne!(corps["rafraichissement"], refresh.as_str());

        // Rejeu de l'ancien → 401 (et la session tombe — R2).
        let resp = atest::call_service(&app, requete(refresh)).await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    }

    /// SC-004 — deux appareils, révocation à distance depuis l'autre.
    #[sqlx::test(migrations = "../migrations")]
    async fn liste_et_revocation_a_distance(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);
        let (acces_a, _) = jetons_pour(&bac, NUMERO).await;
        let (acces_b, refresh_b) = jetons_pour(&bac, NUMERO).await;

        // A liste ses appareils : 2, dont le sien marqué `courante`.
        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri("/moi/sessions")
                .insert_header(("authorization", format!("Bearer {acces_a}")))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::OK);
        let sessions: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(sessions.as_array().unwrap().len(), 2);
        assert_eq!(
            sessions
                .as_array()
                .unwrap()
                .iter()
                .filter(|s| s["courante"] == true)
                .count(),
            1
        );

        // A révoque B.
        let session_b = comptes::verifier_acces(SECRET, &acces_b).unwrap().sid;
        let resp = atest::call_service(
            &app,
            atest::TestRequest::delete()
                .uri(&format!("/moi/sessions/{session_b}"))
                .insert_header(("authorization", format!("Bearer {acces_a}")))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::NO_CONTENT);

        // B ne peut plus rafraîchir, A oui.
        let resp = atest::call_service(
            &app,
            atest::TestRequest::post()
                .uri("/auth/rafraichir")
                .set_json(json!({ "rafraichissement": refresh_b }))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);

        let resp = atest::call_service(
            &app,
            atest::TestRequest::get()
                .uri("/moi")
                .insert_header(("authorization", format!("Bearer {acces_a}")))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::OK, "A n'est pas affecté");
    }

    /// La session d'autrui est INTROUVABLE, pas « interdite » : un 403
    /// confirmerait son existence.
    #[sqlx::test(migrations = "../migrations")]
    async fn revoquer_la_session_d_autrui_404(pool: PgPool) {
        let bac = preparer(&pool).await;
        let app = app!(bac);
        let (acces_awa, _) = jetons_pour(&bac, NUMERO).await;
        let (acces_yao, _) = jetons_pour(&bac, "0705060708").await;
        let session_yao = comptes::verifier_acces(SECRET, &acces_yao).unwrap().sid;

        let resp = atest::call_service(
            &app,
            atest::TestRequest::delete()
                .uri(&format!("/moi/sessions/{session_yao}"))
                .insert_header(("authorization", format!("Bearer {acces_awa}")))
                .to_request(),
        )
        .await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    }
}
