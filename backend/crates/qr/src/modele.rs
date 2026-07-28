//! Types publics du domaine QR (data-model §4.2).
//!
//! Réutilise `commandes::ModeCollecte` (une seule définition de la méthode de
//! collecte). Les DTO HTTP (avec annotations `ToSchema`) vivent dans la couche
//! `api` (`qr_http`) ; ici, seulement le domaine.

use chrono::{DateTime, Utc};
use commandes::{EtatLivraison, ModeCollecte, StatutArret};
use uuid::Uuid;

/// Demande de collecte d'un arrêt (QRC-02/03/04), pilotée par l'API.
#[derive(Debug, Clone)]
pub struct DemandeCollecte {
    /// Arrêt visé (chemin de l'endpoint).
    pub arret_id: Uuid,
    /// Scan du QR ou saisie du code de secours.
    pub mode: ModeCollecte,
    /// Jeton lu dans le QR (mode `ScanQr`).
    pub jeton: Option<String>,
    /// Code à 4 chiffres saisi (mode `CodeSecours`).
    pub code: Option<String>,
    /// Position capturée du coursier (grand-cercle vs site, R3).
    pub position_lat: f64,
    /// Position capturée du coursier.
    pub position_lon: f64,
    /// Photo de récupération (si exigée par la politique résolue).
    pub photo: Option<Vec<u8>>,
    /// Clé d'idempotence (UUIDv7 client, V).
    pub uuid_client: Uuid,
    /// Horodatage local de l'action (journalisé, jamais fait autorité).
    pub horodatage_local: DateTime<Utc>,
}

/// Résultat d'une collecte réussie.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ResultatCollecte {
    /// Statut de l'arrêt après collecte (`collecte`).
    pub arret_statut: StatutArret,
    /// État de la livraison après gating.
    pub livraison_etat: EtatLivraison,
    /// COLLECTES faites (progression) — la remise n'en est pas une (P1, R4).
    pub nb_collectes: i16,
    /// Total de COLLECTES de la livraison (arrêt de remise EXCLU).
    pub nb_arrets: i16,
    /// Vrai si cette collecte a fait basculer la livraison EN_LIVRAISON.
    pub en_livraison: bool,
}

/// Arrêt pré-provisionné pour la validation hors-ligne (R6). Empreintes
/// (sha256), jamais le code ni un secret.
#[derive(Debug, Clone, PartialEq)]
pub struct ArretPreProvisionne {
    /// Arrêt à collecter.
    pub arret_id: Uuid,
    /// Prestataire visé.
    pub prestataire_id: Uuid,
    /// Nom du prestataire (public — affiché sur la carte K3).
    pub nom: String,
    /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
    pub empreinte_jeton: String,
    /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
    pub empreinte_code: String,
    /// Position attendue du site.
    pub site_lat: f64,
    /// Position attendue du site.
    pub site_lon: f64,
    /// Montant avancé (unités mineures).
    pub montant_avance: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Politique photo résolue (R4).
    pub photo_exigee: bool,
    /// Rayon max de scan (m) de la zone — validation de proximité HORS-LIGNE (R6).
    pub distance_max_m: i64,
}

/// Plaque d'un prestataire, résolue pour un montant d'arrêt donné (cycle CRS
/// 010, [`crate::PgQr::plaque_resolue`]).
///
/// Le sous-ensemble d'[`ArretPreProvisionne`] qui dépend du PRESTATAIRE et non
/// de l'arrêt : empreintes, politique photo, rayon de scan. Ce que l'arrêt
/// apporte (identité, position, montant) reste au domaine qui le porte.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlaqueResolue {
    /// Nom du prestataire (public — affiché sur la carte K3).
    pub nom: String,
    /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
    pub empreinte_jeton: String,
    /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
    pub empreinte_code: String,
    /// Politique photo résolue pour ce montant (R4).
    pub photo_exigee: bool,
    /// Rayon max de scan (m) de la zone — validation de proximité HORS-LIGNE.
    pub distance_max_m: i64,
}

/// Erreurs du domaine QR. Chaque variante métier porte une clé i18n fr
/// (`message_cle`) et un statut HTTP (mappés dans `qr_http`).
#[derive(Debug, thiserror::Error)]
pub enum ErreurQr {
    /// Prestataire jamais agréé (aucune identité de plaque, FR-011).
    #[error("prestataire sans identité de plaque")]
    PlaqueAbsente,
    /// Hors du rayon de scan (proximité, R3).
    #[error("hors du rayon de scan")]
    HorsZone,
    /// Prestataire suspendu (jeton révoqué, QRC-03).
    #[error("prestataire temporairement indisponible")]
    PrestataireIndisponible,
    /// Jeton inconnu/forgé.
    #[error("plaque invalide")]
    PlaqueInvalide,
    /// Photo exigée non fournie.
    #[error("photo de récupération requise")]
    PhotoRequise,
    /// Code dégradé : 3 essais épuisés.
    #[error("code de secours épuisé")]
    CodeEpuise,
    /// Code dégradé ne correspond pas au prestataire de l'arrêt.
    #[error("code de secours incorrect")]
    CodeIncorrect,
    /// Arrêt déjà collecté par un autre uuid.
    #[error("arrêt déjà collecté")]
    ArretDejaCollecte,
    /// État d'arrêt incompatible.
    #[error("état d'arrêt incompatible")]
    EtatIncompatible,
    /// Arrêt hors de la course active du coursier (précondition, FR-012).
    #[error("arrêt hors de la course active")]
    ArretHorsCourse,
    /// Requête mal formée (jeton/code absent selon le mode).
    #[error("demande de collecte invalide : {0}")]
    DemandeInvalide(&'static str),
    /// Stockage objet indisponible.
    #[error("stockage objet : {0}")]
    Objets(#[from] socle::ErreurObjets),
    /// Domaine commandes.
    #[error("socle logistique : {0}")]
    Commandes(#[from] commandes::ErreurCommandes),
    /// Domaine prestataires.
    #[error("domaine prestataires : {0}")]
    Prestataires(#[from] prestataires::ErreurPrestataires),
    /// Configuration de zone.
    #[error("configuration de zone : {0}")]
    Zones(#[from] zones::ErreurZones),
    /// Compteur d'essais (Redis).
    #[error("compteur d'essais : {0}")]
    Compteur(String),
    /// Erreur base de données.
    #[error("erreur base de données qr : {0}")]
    Sql(#[from] sqlx::Error),
}

impl ErreurQr {
    /// Clé i18n fr du refus métier (contrats §2). `None` pour les erreurs
    /// d'infrastructure (rendues 500 sans clé stable).
    pub fn message_cle(&self) -> Option<&'static str> {
        Some(match self {
            ErreurQr::PlaqueAbsente => "plaque_absente",
            ErreurQr::HorsZone => "hors_zone",
            ErreurQr::PrestataireIndisponible => "prestataire_indisponible",
            ErreurQr::PlaqueInvalide => "plaque_invalide",
            ErreurQr::PhotoRequise => "photo_requise",
            ErreurQr::CodeEpuise => "code_epuise",
            ErreurQr::CodeIncorrect => "code_incorrect",
            ErreurQr::ArretDejaCollecte => "arret_deja_collecte",
            ErreurQr::EtatIncompatible => "etat_incompatible",
            ErreurQr::ArretHorsCourse => "arret_hors_course",
            ErreurQr::DemandeInvalide(_) => "demande_invalide",
            _ => return None,
        })
    }
}

/// L'outbox se replie sur `Sql` pour préserver l'atomicité (patron cycle 005).
impl From<socle::OutboxError> for ErreurQr {
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurQr::Sql(e),
        }
    }
}
