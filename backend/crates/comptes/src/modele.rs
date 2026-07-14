//! Types publics du domaine comptes, consommés par les autres crates
//! (data-model.md §5).
//!
//! Identifiants métier en français, conventions des cycles 001/002. Les énums
//! Postgres sont lues/écrites par cast `text` (patron de `zones::Forcage`) :
//! `comme_str()` pour écrire, [`std::str::FromStr`] pour relire.
//!
//! Aucune chaîne UI ici : les libellés d'adresse et les motifs admin sont du
//! CONTENU saisi par l'utilisateur, pas des clés i18n (data-model §préambule).

use std::fmt;
use std::str::FromStr;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Rôles et statuts ───────────────────────────────────────────────────────

/// Rôle d'un compte. CUMULABLES : un compte en porte 1..n (FR-010) — « tout
/// prestataire n'est pas un vendeur », et le même humain peut être client ET
/// coursier ET vendeur.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    /// Posé automatiquement à l'inscription, toujours valide ce cycle.
    Client,
    /// Demandé in-app avec dossier, validé par un admin (CPT-04).
    Coursier,
    /// Attribué par un admin à l'agrément (§5.1) — jamais demandé in-app.
    Vendeur,
    /// Attribué par un admin existant, ou par le seed du premier admin (FR-012).
    Admin,
}

impl Role {
    /// Représentation = valeur de l'énum Postgres `comptes.role`.
    pub fn comme_str(self) -> &'static str {
        match self {
            Role::Client => "client",
            Role::Coursier => "coursier",
            Role::Vendeur => "vendeur",
            Role::Admin => "admin",
        }
    }
}

impl fmt::Display for Role {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for Role {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "client" => Ok(Role::Client),
            "coursier" => Ok(Role::Coursier),
            "vendeur" => Ok(Role::Vendeur),
            "admin" => Ok(Role::Admin),
            autre => Err(format!("rôle inconnu : {autre}")),
        }
    }
}

/// Statut d'une attribution de rôle — l'UNIQUE machine à états du module
/// (research R9). Le « statut du dossier coursier » (FR-016) EST ce statut :
/// aucune duplication à synchroniser.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StatutRole {
    /// Dossier déposé, décision admin attendue.
    EnAttente,
    /// Rôle actif — SEUL statut qui ouvre les privilèges (SC-005).
    Valide,
    /// Refusé (motif requis) — re-soumission possible.
    Refuse,
    /// Suspendu (motif requis) — rétablissable.
    Suspendu,
}

impl StatutRole {
    /// Représentation = valeur de l'énum Postgres `comptes.statut_role`.
    pub fn comme_str(self) -> &'static str {
        match self {
            StatutRole::EnAttente => "en_attente",
            StatutRole::Valide => "valide",
            StatutRole::Refuse => "refuse",
            StatutRole::Suspendu => "suspendu",
        }
    }
}

impl fmt::Display for StatutRole {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for StatutRole {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "en_attente" => Ok(StatutRole::EnAttente),
            "valide" => Ok(StatutRole::Valide),
            "refuse" => Ok(StatutRole::Refuse),
            "suspendu" => Ok(StatutRole::Suspendu),
            autre => Err(format!("statut de rôle inconnu : {autre}")),
        }
    }
}

// ── Compte et appareils ────────────────────────────────────────────────────

/// Compte Mefali : un numéro vérifié et son consentement, RIEN D'AUTRE
/// (clarification « numéro seul » — aucune donnée nominative au MVP).
///
/// Les colonnes PROVISION de CPT-06 (`prepaiement_impose`, `bloque`) sont
/// volontairement ABSENTES de ce type : elles existent en base et aucune
/// logique ne les lit (constitution IX — « prêt ≠ construit »).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Compte {
    /// Identifiant stable (UUIDv7), référencé par toute entité métier.
    pub id: Uuid,
    /// Identité Mefali, normalisée E.164 (research R4).
    pub telephone_e164: String,
    /// Zone de rattachement (indicatif, paramètres — research R13).
    pub zone_id: Uuid,
    /// Version du texte ARTCI accepté (FR-006).
    pub consentement_version: String,
    /// Horodatage du consentement — jamais NULL (garanti par le schéma).
    pub consentement_le: DateTime<Utc>,
    /// Création du compte.
    pub cree_le: DateTime<Utc>,
    /// Dernière vérification OTP réussie ; `None` avant la toute première.
    pub derniere_connexion_le: Option<DateTime<Utc>>,
}

/// Plateforme de l'appareil porteur d'une session.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Plateforme {
    /// Android.
    Android,
    /// iOS.
    Ios,
}

impl Plateforme {
    /// Représentation stockée dans `comptes.session.appareil_plateforme`.
    pub fn comme_str(self) -> &'static str {
        match self {
            Plateforme::Android => "android",
            Plateforme::Ios => "ios",
        }
    }
}

impl fmt::Display for Plateforme {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for Plateforme {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "android" => Ok(Plateforme::Android),
            "ios" => Ok(Plateforme::Ios),
            autre => Err(format!("plateforme inconnue : {autre}")),
        }
    }
}

/// Appareil déclaré par l'app à l'ouverture de session. `nom` est du CONTENU
/// utilisateur (« Pixel 7 de poche »), affiché tel quel dans la liste des
/// appareils — jamais interprété.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Appareil {
    /// Nom lisible fourni par l'app.
    pub nom: String,
    /// Plateforme.
    pub plateforme: Plateforme,
}

/// Session = un appareil connecté. N'expire JAMAIS d'elle-même (clarification) :
/// seule une révocation y met fin (locale, à distance, ou réutilisation de
/// refresh détectée — research R2).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Session {
    /// Identifiant = claim `sid` du jeton d'accès.
    pub id: Uuid,
    /// Compte propriétaire.
    pub compte_id: Uuid,
    /// Appareil porteur.
    pub appareil: Appareil,
    /// Ouverture de la session.
    pub cree_le: DateTime<Utc>,
    /// Dernier rafraîchissement (aucune expiration d'inactivité n'en découle).
    pub derniere_activite_le: DateTime<Utc>,
    /// `None` = active.
    pub revoquee_le: Option<DateTime<Utc>>,
}

impl Session {
    /// `true` tant que la session n'a pas été révoquée.
    pub fn active(&self) -> bool {
        self.revoquee_le.is_none()
    }
}

/// Origine d'une révocation — portée par le payload de `session.revoquee`
/// (taxonomie CPT).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OrigineRevocation {
    /// Déconnexion depuis l'appareil lui-même.
    Locale,
    /// Déconnexion d'un appareil depuis un autre (US2, SC-004).
    ADistance,
    /// Refresh déjà tourné rejoué → vol présumé, session entière tombée (R2).
    ReutilisationDetectee,
}

impl OrigineRevocation {
    /// Valeur portée par le payload de l'événement.
    pub fn comme_str(self) -> &'static str {
        match self {
            OrigineRevocation::Locale => "locale",
            OrigineRevocation::ADistance => "a_distance",
            OrigineRevocation::ReutilisationDetectee => "reutilisation_detectee",
        }
    }
}

// ── Rôles attribués ────────────────────────────────────────────────────────

/// Une attribution de rôle et l'état de sa décision (journal FR-014 : qui,
/// quand, pourquoi).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AttributionRole {
    /// Rôle concerné.
    pub role: Role,
    /// Statut courant dans la machine à états (R9).
    pub statut: StatutRole,
    /// Motif de la DERNIÈRE décision (requis pour refuser/suspendre).
    pub motif: Option<String>,
    /// Admin décideur ; `None` = automatique (le rôle client à l'inscription).
    pub decide_par: Option<Uuid>,
    /// Horodatage de la dernière décision.
    pub decide_le: Option<DateTime<Utc>>,
    /// Première demande / attribution.
    pub demande_le: DateTime<Utc>,
}

// ── Dossier coursier ───────────────────────────────────────────────────────

/// Type de transport du référentiel ZON-03 tel que déclaré par un coursier —
/// vue minimale suffisante au filtre du dispatch (cycle DSP).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TypeTransport {
    /// Identifiant dans `zones.type_transport`.
    pub id: Uuid,
    /// Slug stable (ex. `moto`).
    pub slug: String,
}

/// Véhicule déclaré au dossier, résolu contre le référentiel de la zone.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VehiculeDeclare {
    /// Type de transport référencé.
    pub type_transport_id: Uuid,
    /// Slug du type (ex. `moto`).
    pub slug: String,
    /// `false` si le type a été DÉSACTIVÉ dans la zone après la déclaration :
    /// le véhicule reste déclaré et signalé, il n'est pas effacé (edge case spec).
    pub actif_zone: bool,
}

/// Dossier coursier : le CONTENU (pièce, référent, véhicules) plus le statut
/// LU sur l'attribution `coursier` — le dossier ne stocke aucun statut propre
/// (une seule source de vérité, research R9).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DossierCoursier {
    /// Compte du coursier (PK — 1:1).
    pub compte_id: Uuid,
    /// Clé S3 de la pièce d'identité (bucket privé — research R7).
    pub piece_cle_objet: String,
    /// Type MIME validé à l'upload.
    pub piece_mime: String,
    /// Référent local (« caution morale », cadrage §7.1).
    pub referent_nom: String,
    /// Téléphone du référent, normalisé E.164 comme le compte.
    pub referent_telephone_e164: String,
    /// Dernier dépôt (réécrit à chaque re-soumission).
    pub soumis_le: DateTime<Utc>,
    /// Véhicules déclarés.
    pub vehicules: Vec<VehiculeDeclare>,
    /// Statut de l'attribution `coursier` (R9) — pas une colonne du dossier.
    pub statut: StatutRole,
    /// Motif de la dernière décision admin (idem).
    pub motif: Option<String>,
}

// ── Adresses ───────────────────────────────────────────────────────────────

/// Adresse enregistrée avec son repère. Une adresse dont le repère vocal a été
/// purgé reste UTILISABLE : elle en redemande un à la prochaine utilisation
/// (FR-022) — d'où l'absence de contrainte « au moins un repère ».
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Adresse {
    /// Identifiant = `Idempotency-Key` du POST créateur (UUIDv7 client — R14).
    pub id: Uuid,
    /// Compte propriétaire.
    pub compte_id: Uuid,
    /// « Maison », « Bureau » ou libre — CONTENU utilisateur, pas une clé i18n.
    pub libelle: String,
    /// Latitude du pin GPS (§8.2) — stockée, jamais routée ce cycle.
    pub lat: f64,
    /// Longitude du pin GPS.
    pub lng: f64,
    /// Repère écrit.
    pub repere_texte: Option<String>,
    /// Clé S3 du repère vocal ; `None` après purge (research R8).
    pub repere_vocal_cle_objet: Option<String>,
    /// Durée du repère vocal (≤ paramètre de zone `medias.note_vocale_duree_max_s`).
    pub repere_vocal_duree_s: Option<i16>,
    /// Zone de l'adresse.
    pub zone_id: Uuid,
    /// PROVISION — posé par CMD/CRS plus tard ; aucune logique ne le lit.
    pub livraison_origine: Option<Uuid>,
    /// Enregistrement.
    pub cree_le: DateTime<Utc>,
    /// Base de la purge — avancée par `marquer_adresse_utilisee` (cycle CMD).
    pub derniere_utilisation_le: DateTime<Utc>,
    /// Soft delete (FR-021) — `None` = vivante.
    pub supprimee_le: Option<DateTime<Utc>>,
}

impl Adresse {
    /// `false` après purge du repère vocal (FR-022).
    pub fn a_repere_vocal(&self) -> bool {
        self.repere_vocal_cle_objet.is_some()
    }
}

// ── Erreurs ────────────────────────────────────────────────────────────────

/// Erreurs du domaine comptes (data-model §5).
///
/// ⚠ ANTI-ÉNUMÉRATION (SC-003) : la couche `api` doit replier
/// [`ErreurComptes::DefiOtpInvalide`] ET [`ErreurComptes::PlafondAtteint`] sur
/// des réponses NEUTRES — le domaine distingue les cas pour ses tests et ses
/// journaux, l'API n'en laisse rien filtrer.
#[derive(Debug, thiserror::Error)]
pub enum ErreurComptes {
    /// Aucun compte pour cet identifiant.
    #[error("compte inconnu : {0}")]
    CompteInconnu(Uuid),
    /// Session absente, révoquée ou n'appartenant pas au compte.
    #[error("session inconnue ou révoquée : {0}")]
    SessionInconnue(Uuid),
    /// Rôle valide requis pour l'opération (403 côté API).
    #[error("rôle requis : {0}")]
    RoleRequis(Role),
    /// Transition refusée par la machine à états (409 côté API — R9).
    #[error("transition invalide : {role} ne peut pas passer de {avant} à {apres}")]
    TransitionInvalide {
        /// Rôle concerné.
        role: Role,
        /// Statut courant.
        avant: String,
        /// Statut visé.
        apres: String,
    },
    /// Motif obligatoire absent (refuser / suspendre — FR-017).
    #[error("motif requis pour cette décision")]
    MotifRequis,
    /// Code OTP faux, expiré, essais épuisés, ou défi inexistant — un SEUL
    /// variant : la distinction ne doit JAMAIS atteindre le client (SC-003).
    #[error("code invalide ou expiré")]
    DefiOtpInvalide,
    /// Plafond anti-abus atteint (3 SMS/h/numéro, 10 demandes/h/IP — R12).
    /// L'API répond le même 202 neutre que le succès.
    #[error("plafond de demandes atteint")]
    PlafondAtteint,
    /// Jeton d'inscription inconnu, expiré (10 min) ou déjà consommé (R3).
    #[error("jeton d'inscription invalide ou expiré")]
    JetonInscriptionInvalide,
    /// Consentement ARTCI absent — aucun compte n'est créé (FR-006).
    #[error("consentement requis")]
    ConsentementRequis,
    /// Numéro non normalisable en E.164 avec l'indicatif de la zone (R4).
    #[error("numéro de téléphone invalide")]
    TelephoneInvalide,
    /// Véhicule absent des types de transport ACTIFS de la zone (FR-015).
    #[error("véhicule hors zone : {0}")]
    VehiculeHorsZone(String),
    /// Dossier coursier incomplet — non soumis (FR-016).
    #[error("dossier coursier incomplet")]
    DossierIncomplet,
    /// Aucun dossier coursier pour ce compte.
    #[error("dossier coursier inconnu : {0}")]
    DossierInconnu(Uuid),
    /// Adresse inconnue ou n'appartenant pas au compte (404 — propriété stricte).
    #[error("adresse inconnue : {0}")]
    AdresseInconnue(Uuid),
    /// Média au-delà de la taille autorisée (pièce 10 Mo, note vocale 1,5 Mo).
    #[error("objet trop volumineux")]
    ObjetTropVolumineux,
    /// Média de type refusé, ou durée au-delà du paramètre de zone.
    #[error("média invalide : {0}")]
    MediaInvalide(String),
    /// Dépôt éphémère (Redis) indisponible.
    #[error("dépôt éphémère indisponible : {0}")]
    Ephemere(#[from] ErreurEphemere),
    /// Stockage objet (Garage/S3) indisponible.
    #[error("stockage objet indisponible : {0}")]
    Objets(#[from] ErreurObjets),
    /// Envoi de SMS en échec.
    #[error("envoi SMS en échec : {0}")]
    Sms(#[from] ErreurSms),
    /// Configuration de zone irrésolvable (indicatif, rétention, transports).
    #[error("configuration de zone : {0}")]
    Zones(#[from] zones::ErreurZones),
    /// Émission ou vérification d'un jeton d'accès en échec.
    #[error("jeton d'accès : {0}")]
    Jeton(String),
    /// Erreur de la base de données.
    #[error("erreur base de données comptes : {0}")]
    Sql(#[from] sqlx::Error),
}

impl From<socle::OutboxError> for ErreurComptes {
    /// L'écriture d'un événement outbox n'échoue que sur erreur SQL — repliée
    /// sur [`ErreurComptes::Sql`] pour préserver l'atomicité (constitution VI).
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurComptes::Sql(e),
        }
    }
}

/// Échec d'accès au dépôt éphémère (Redis — research R3).
#[derive(Debug, thiserror::Error)]
#[error("dépôt éphémère : {0}")]
pub struct ErreurEphemere(pub String);

/// Échec d'envoi de SMS (research R6).
#[derive(Debug, thiserror::Error)]
#[error("SMS : {0}")]
pub struct ErreurSms(pub String);

/// Échec d'accès au stockage objet (Garage/S3 — research R7).
#[derive(Debug, thiserror::Error)]
#[error("stockage objet : {0}")]
pub struct ErreurObjets(pub String);
