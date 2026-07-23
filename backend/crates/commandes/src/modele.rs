//! Types publics du socle logistique (cycle QRC 006, data-model §1/§4.1).
//!
//! Énums miroir des types Postgres (`commandes.statut_arret`, `.mode_collecte`,
//! `.etat_livraison`) avec `comme_str()`/`FromStr` — patron du cycle 005 (cast
//! SQL `col::text AS "col!"`, jamais l'énum brut). L'énum fige le vocabulaire ;
//! toute transition est GARDÉE dans le crate (jamais par le type seul).

use std::str::FromStr;

use uuid::Uuid;

/// Machine à états de l'arrêt (cadrage §7.2). QRC ne POSE que `Collecte` ;
/// `Indisponible` viendra de CMD-06 — présent dès le socle pour que le gating
/// EN_LIVRAISON le compte comme résolu (spec FR-018).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StatutArret {
    /// En attente de collecte par le coursier.
    ACollecter,
    /// Collecté (scan ou code de secours), horodatage serveur posé.
    Collecte,
    /// Indisponible (substitution CMD-06) — compté comme résolu au gating.
    Indisponible,
}

impl StatutArret {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            StatutArret::ACollecter => "a_collecter",
            StatutArret::Collecte => "collecte",
            StatutArret::Indisponible => "indisponible",
        }
    }

    /// Vrai si l'arrêt est RÉSOLU pour le gating EN_LIVRAISON (spec FR-018).
    pub fn est_resolu(self) -> bool {
        matches!(self, StatutArret::Collecte | StatutArret::Indisponible)
    }
}

impl FromStr for StatutArret {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "a_collecter" => Ok(StatutArret::ACollecter),
            "collecte" => Ok(StatutArret::Collecte),
            "indisponible" => Ok(StatutArret::Indisponible),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Méthode de collecte (unifie scan et dégradé — cadrage §7.2).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModeCollecte {
    /// Scan du QR de la plaque.
    ScanQr,
    /// Saisie du code de secours (mode dégradé QRC-04).
    CodeSecours,
}

impl ModeCollecte {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            ModeCollecte::ScanQr => "scan_qr",
            ModeCollecte::CodeSecours => "code_secours",
        }
    }
}

impl FromStr for ModeCollecte {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "scan_qr" => Ok(ModeCollecte::ScanQr),
            "code_secours" => Ok(ModeCollecte::CodeSecours),
            autre => Err(ErreurCommandes::ModeInconnu(autre.to_owned())),
        }
    }
}

/// État logistique de la livraison (constitution II — PAS sur le tronc commande).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EtatLivraison {
    /// Collecte des arrêts en cours.
    EnCollecte,
    /// Tous les arrêts résolus — en route vers le client.
    EnLivraison,
}

impl EtatLivraison {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatLivraison::EnCollecte => "en_collecte",
            EtatLivraison::EnLivraison => "en_livraison",
        }
    }
}

/// Arrêt qu'un coursier peut collecter chez un prestataire (précondition QRC-02).
/// Position et montant sont DÉNORMALISÉS depuis le site (pré-provisionnement
/// offline R6).
#[derive(Debug, Clone, PartialEq)]
pub struct ArretACollecter {
    /// Identifiant de l'arrêt.
    pub arret_id: Uuid,
    /// Livraison porteuse (état EN_LIVRAISON).
    pub livraison_id: Uuid,
    /// Segment (niveau transporteur).
    pub segment_id: Uuid,
    /// Commande ancre.
    pub commande_id: Uuid,
    /// Prestataire visé à cet arrêt.
    pub prestataire_id: Uuid,
    /// Position ATTENDUE du site (proximité de scan).
    pub site_lat: f64,
    /// Position ATTENDUE du site.
    pub site_lon: f64,
    /// Montant avancé (unités mineures, III).
    pub montant_avance: i64,
    /// Devise ISO 4217.
    pub devise: String,
}

/// Progression renvoyée après une collecte réussie.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ProgressionCollecte {
    /// Nombre d'arrêts déjà collectés (statut `collecte`).
    pub nb_collectes: i16,
    /// Nombre total d'arrêts de la livraison.
    pub nb_arrets: i16,
    /// Vrai si cette collecte a fait basculer la livraison EN_LIVRAISON.
    pub en_livraison: bool,
}

/// Erreurs du domaine commandes.
#[derive(Debug, thiserror::Error)]
pub enum ErreurCommandes {
    /// Arrêt introuvable (ou hors de la course active du coursier).
    #[error("arrêt inconnu : {0}")]
    ArretInconnu(Uuid),
    /// Transition d'arrêt refusée (état incompatible — déjà collecté par un
    /// autre uuid, arrêt indisponible…).
    #[error("état d'arrêt incompatible : « {avant} » ne peut passer à « {apres} »")]
    EtatIncompatible {
        /// État courant de l'arrêt.
        avant: String,
        /// État cible refusé.
        apres: String,
    },
    /// Valeur d'énum `statut_arret` inconnue lue en base.
    #[error("statut d'arrêt inconnu : {0}")]
    StatutInconnu(String),
    /// Valeur d'énum `mode_collecte` inconnue lue en base.
    #[error("mode de collecte inconnu : {0}")]
    ModeInconnu(String),
    /// Erreur base de données.
    #[error("erreur base de données commandes : {0}")]
    Sql(#[from] sqlx::Error),
}

/// L'outbox se replie sur `Sql` pour préserver l'atomicité (patron cycle 005) :
/// écrire l'événement ET la transition dans la même transaction — un échec de
/// l'un est un échec de l'autre.
impl From<socle::OutboxError> for ErreurCommandes {
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurCommandes::Sql(e),
        }
    }
}
