//! Types publics du domaine zones, consommés par les autres crates (data-model §5).
//!
//! Identifiants métier en français, conventions du socle 001 (research R10).
//! Aucun float pour l'argent (constitution III) ; aucune chaîne UI (les libellés
//! sont des clés i18n fr — `nom_cle`).

use std::collections::BTreeMap;
use std::fmt;
use std::str::FromStr;

use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

/// Type d'une zone dans l'arbre (data-model §1). Aucun ordre imposé entre les
/// types (profondeur variable — spec, Assumptions). `village`/`quartier` =
/// PROVISION : présents dans le modèle, sans écran ni logique dédiée (principe IX).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TypeZone {
    /// Racine usuelle (ex. Côte d'Ivoire).
    Pays,
    /// Niveau régional (facultatif — peut être sauté).
    Region,
    /// Ville (ex. Tiassalé — ville unique du MVP).
    Ville,
    /// Commune.
    Commune,
    /// PROVISION — données seulement.
    Village,
    /// PROVISION — données seulement.
    Quartier,
}

impl TypeZone {
    /// Représentation textuelle = valeur de l'énum Postgres `zones.type_zone`
    /// (utilisée pour les binds SQL castés `$n::zones.type_zone`).
    pub fn comme_str(self) -> &'static str {
        match self {
            TypeZone::Pays => "pays",
            TypeZone::Region => "region",
            TypeZone::Ville => "ville",
            TypeZone::Commune => "commune",
            TypeZone::Village => "village",
            TypeZone::Quartier => "quartier",
        }
    }
}

impl fmt::Display for TypeZone {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for TypeZone {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "pays" => Ok(TypeZone::Pays),
            "region" => Ok(TypeZone::Region),
            "ville" => Ok(TypeZone::Ville),
            "commune" => Ok(TypeZone::Commune),
            "village" => Ok(TypeZone::Village),
            "quartier" => Ok(TypeZone::Quartier),
            autre => Err(format!("type de zone inconnu : {autre}")),
        }
    }
}

/// Nœud de l'arbre géographique (FR-001). `parent_id` NULL = racine.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Zone {
    /// Identifiant stable, référençable par toute entité métier (FR-003).
    pub id: Uuid,
    /// Parent (0..1). NULL = racine.
    pub parent_id: Option<Uuid>,
    /// Type dans l'arbre.
    pub type_zone: TypeZone,
    /// Nom administratif (pas une chaîne UI).
    pub nom: String,
}

/// Devise portée par la configuration, résolue par héritage (FR-010, principe III).
/// Montants = entiers en unités mineures + code ISO 4217 ; jamais de float.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Devise {
    /// Code ISO 4217 (ex. `XOF`).
    pub code: String,
    /// Nombre de décimales des unités mineures (0 pour XOF).
    pub decimales: u8,
}

/// Valeur d'un paramètre résolu ET la zone d'où elle provient. La provenance
/// rend testables les surcharges partielles et alimentera l'admin (ADM, T3).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ValeurProvenance {
    /// Valeur JSON telle que stockée dans `zones.parametre_zone`.
    pub valeur: Value,
    /// Zone de la chaîne d'ancêtres qui définit effectivement cette clé.
    pub provenance: Uuid,
}

/// Configuration effective d'une zone (héritage racine → zone), avec provenance
/// par clé (FR-006). `valeurs` ne contient QUE les paramètres définis quelque
/// part dans la chaîne : une clé absente = explicitement absente (FR-009).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConfigurationEffective {
    /// Zone dont la configuration a été résolue.
    pub zone: Uuid,
    /// Paramètres résolus, triés par clé (déterminisme — SC-008).
    pub valeurs: BTreeMap<String, ValeurProvenance>,
}

impl ConfigurationEffective {
    /// Valeur résolue d'une clé, ou `None` si explicitement absente (FR-009).
    pub fn valeur(&self, cle: &str) -> Option<&Value> {
        self.valeurs.get(cle).map(|vp| &vp.valeur)
    }

    /// Zone d'où provient la valeur d'une clé (ancêtre le plus proche).
    pub fn provenance(&self, cle: &str) -> Option<Uuid> {
        self.valeurs.get(cle).map(|vp| vp.provenance)
    }
}

/// Catégorie ACTIVE dans une zone, vue par `/config` et les consommateurs.
/// `mixable` est résolu par héritage (CMD-01 — mixable au panier).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CategorieActive {
    /// Slug stable (ex. `restauration`).
    pub slug: String,
    /// Clé i18n fr du nom (`categorie.<slug>.nom`) — jamais de chaîne UI en dur.
    pub nom_cle: String,
    /// Mixable au panier, résolu par héritage.
    pub mixable: bool,
}

/// Erreurs du domaine zones (data-model §5).
#[derive(Debug, thiserror::Error)]
pub enum ErreurZones {
    /// Zone absente du référentiel.
    #[error("zone inconnue : {0}")]
    ZoneInconnue(Uuid),
    /// Rattachement créant un cycle (FR-002) — détecté côté applicatif.
    #[error("cycle de zones détecté (une zone ne peut être sa propre ancêtre)")]
    CycleDetecte,
    /// Aucune devise résolue dans la chaîne d'héritage (FR-010).
    #[error("devise irrésolvable pour la zone {0}")]
    DeviseIrresolvable(Uuid),
    /// Slug de catégorie absent du référentiel.
    #[error("catégorie inconnue : {0}")]
    CategorieInconnue(String),
    /// Valeur refusée par la validation d'un paramètre de zone.
    #[error("valeur invalide pour « {cle} » : {raison}")]
    ValeurInvalide {
        /// Clé du paramètre concerné.
        cle: String,
        /// Raison du refus (clé/diagnostic).
        raison: String,
    },
    /// Erreur de la base de données.
    #[error("erreur base de données zones : {0}")]
    Sql(#[from] sqlx::Error),
}

impl From<socle::OutboxError> for ErreurZones {
    /// L'écriture d'un événement outbox n'échoue que sur erreur SQL — repliée
    /// sur [`ErreurZones::Sql`] pour préserver l'atomicité (constitution VI).
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurZones::Sql(e),
        }
    }
}
