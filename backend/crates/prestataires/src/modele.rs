//! Types publics du domaine prestataires (specs/005 data-model.md §2, §5).
//!
//! Identifiants métier en français, conventions des cycles 002/003. Les énums
//! Postgres sont lues/écrites par cast `text` (patron de `comptes::Role`) :
//! `comme_str()` pour écrire, [`std::str::FromStr`] pour relire.
//!
//! Aucune chaîne UI ici : les noms de prestataires et d'articles, les motifs
//! admin et les catégories internes sont du CONTENU saisi, pas des clés i18n.
//! Tout montant est un ENTIER en unités mineures accompagné de son code de
//! devise ISO 4217 — jamais de flottant (constitution III).

use std::fmt;
use std::str::FromStr;

use uuid::Uuid;

// ── Statuts et sources ─────────────────────────────────────────────────────

/// Cycle de vie d'un prestataire (FR-004). SEUL `agree` rend la fiche servie
/// et le prestataire commandable ; la validité du jeton de plaque et les
/// capacités vendeur des comptes rattachés en DÉRIVENT (FR-008, FR-015).
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StatutPrestataire {
    /// Fiche en constitution — ni servie, ni commandable.
    Prospect,
    /// Agréé sur le terrain : plaque valide, fiche servie, commandable si sa
    /// catégorie est active et sa boutique ouverte (FR-028).
    Agree,
    /// Suspendu (motif requis) : tout est coupé, la plaque reste en place et
    /// retrouvera sa validité au rétablissement (SC-002, SC-003).
    Suspendu,
}

impl StatutPrestataire {
    /// Représentation = valeur de l'énum Postgres `prestataires.statut_prestataire`.
    pub fn comme_str(self) -> &'static str {
        match self {
            StatutPrestataire::Prospect => "prospect",
            StatutPrestataire::Agree => "agree",
            StatutPrestataire::Suspendu => "suspendu",
        }
    }
}

impl fmt::Display for StatutPrestataire {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for StatutPrestataire {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "prospect" => Ok(StatutPrestataire::Prospect),
            "agree" => Ok(StatutPrestataire::Agree),
            "suspendu" => Ok(StatutPrestataire::Suspendu),
            autre => Err(format!("statut de prestataire inconnu : {autre}")),
        }
    }
}

/// Statut DÉCLARÉ de la boutique d'un site (FR-030). L'état EFFECTIF s'en
/// déduit à la lecture avec les horaires et les échéances (FR-032, research
/// R3) — une pause échue ne réécrit JAMAIS cette colonne.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StatutBoutique {
    /// Reçoit les commandes pendant les horaires.
    Ouvert,
    /// Fermée manuellement — le rappel non bloquant de FR-035 vise cet état.
    Ferme,
    /// Fermée jusqu'au prochain jour d'ouverture, sans action de réouverture.
    FermeJournee,
    /// Pause temporisée — rouvre toute seule à l'échéance, dans les horaires.
    EnPause,
}

impl StatutBoutique {
    /// Représentation = valeur de l'énum Postgres `prestataires.statut_boutique`.
    pub fn comme_str(self) -> &'static str {
        match self {
            StatutBoutique::Ouvert => "ouvert",
            StatutBoutique::Ferme => "ferme",
            StatutBoutique::FermeJournee => "ferme_journee",
            StatutBoutique::EnPause => "en_pause",
        }
    }
}

impl fmt::Display for StatutBoutique {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for StatutBoutique {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "ouvert" => Ok(StatutBoutique::Ouvert),
            "ferme" => Ok(StatutBoutique::Ferme),
            "ferme_journee" => Ok(StatutBoutique::FermeJournee),
            "en_pause" => Ok(StatutBoutique::EnPause),
            autre => Err(format!("statut de boutique inconnu : {autre}")),
        }
    }
}

/// Source d'une bascule de disponibilité d'article — les TROIS chemins de
/// VND-04 (FR-037). Tracée sur la ligne ET dans le payload de l'événement.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SourceBascule {
    /// Le vendeur, depuis Mefali Pro (ou l'Admin agissant côté /vendeur : non —
    /// l'Admin passe par sa propre surface, voir `Admin`).
    Vendeur,
    /// Le coursier sur place — uniquement par le masquage automatique après
    /// seuil de signalements (FR-040) ; jamais une bascule directe.
    Coursier,
    /// L'Admin — une rupture posée par lui n'est levable que par lui (FR-041).
    Admin,
}

impl SourceBascule {
    /// Représentation = valeur de l'énum Postgres `prestataires.source_bascule`.
    pub fn comme_str(self) -> &'static str {
        match self {
            SourceBascule::Vendeur => "vendeur",
            SourceBascule::Coursier => "coursier",
            SourceBascule::Admin => "admin",
        }
    }
}

impl fmt::Display for SourceBascule {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for SourceBascule {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "vendeur" => Ok(SourceBascule::Vendeur),
            "coursier" => Ok(SourceBascule::Coursier),
            "admin" => Ok(SourceBascule::Admin),
            autre => Err(format!("source de bascule inconnue : {autre}")),
        }
    }
}

// ── Erreurs ────────────────────────────────────────────────────────────────

/// Erreurs du domaine prestataires (specs/005 data-model.md §5).
///
/// ⚠ NEUTRALITÉ (FR-017, SC-013) : la couche `api` replie
/// [`ErreurPrestataires::PrestataireInconnu`] ET l'indisponibilité d'un
/// prospect/suspendu sur la MÊME réponse 404 `prestataire_indisponible` pour
/// la consultation publique — le domaine distingue les cas pour ses tests et
/// les surfaces authentifiées, la surface publique n'en laisse rien filtrer.
#[derive(Debug, thiserror::Error)]
pub enum ErreurPrestataires {
    /// Aucun prestataire pour cet identifiant.
    #[error("prestataire inconnu : {0}")]
    PrestataireInconnu(Uuid),
    /// La zone de rattachement n'est pas de type ville — seule granularité que
    /// l'activation de catégorie sait lire (FR-002).
    #[error("zone non-ville : {0}")]
    ZoneNonVille(Uuid),
    /// Slug absent du référentiel de catégories de service (cycle 002).
    #[error("catégorie de service inconnue : {0}")]
    CategorieInconnue(String),
    /// Transition refusée par le cycle de vie (409 côté API — FR-004).
    #[error("transition invalide : {avant} → {apres}")]
    TransitionInvalide {
        /// Statut courant.
        avant: StatutPrestataire,
        /// Statut visé.
        apres: StatutPrestataire,
    },
    /// Agrément refusé — fiche, charte ou site incomplets (FR-005). Les
    /// manques sont des identifiants STABLES (`charte_signee`, `site`,
    /// `horaires`, `photo`), traduits en clés i18n par la couche API.
    #[error("agrément incomplet : {}", manques.join(", "))]
    AgrementIncomplet {
        /// Ce qui manque, dans un ordre stable.
        manques: Vec<&'static str>,
    },
    /// Motif obligatoire absent (suspension — FR-010).
    #[error("motif requis pour cette décision")]
    MotifRequis,
    /// Aucun site pour ce prestataire (l'upsert admin le crée — FR-019).
    #[error("site inconnu pour le prestataire : {0}")]
    SiteInconnu(Uuid),
    /// Aucun article pour cet identifiant chez ce vendeur.
    #[error("article inconnu : {0}")]
    ArticleInconnu(Uuid),
    /// Article retiré du catalogue : ni servi, ni basculable, ni signalable
    /// (FR-055).
    #[error("article retiré du catalogue : {0}")]
    ArticleRetire(Uuid),
    /// Prix barré ≤ prix courant — l'opération ÉCHOUE, la promotion n'est
    /// jamais retirée en silence (FR-023).
    #[error("le prix barré doit être strictement supérieur au prix courant")]
    PrixBarreInvalide,
    /// Montant négatif ou devise inattendue (constitution III).
    #[error("montant invalide : {0}")]
    MontantInvalide(String),
    /// Plages d'horaires incohérentes (début ≥ fin, jour hors 0..6 — FR-031).
    #[error("horaires invalides : {0}")]
    HorairesInvalides(String),
    /// Mise en pause ou prolongation sans durée (FR-033).
    #[error("durée requise pour la pause")]
    DureeRequise,
    /// Prolongation demandée alors qu'aucune pause ne court.
    #[error("aucune pause en cours à prolonger")]
    ProlongationSansPause,
    /// Rattachement exigé sur un prestataire agréé (FR-007, analyse A1).
    #[error("prestataire non agréé : {0}")]
    PrestataireNonAgree(Uuid),
    /// Le compte ne pilote pas ce prestataire (403 — FR-011).
    #[error("compte {compte} non rattaché au prestataire {prestataire}")]
    NonRattache {
        /// Compte appelant.
        compte: Uuid,
        /// Prestataire visé.
        prestataire: Uuid,
    },
    /// Aucun rattachement à détacher pour ce couple.
    #[error("rattachement inconnu : compte {compte}, prestataire {prestataire}")]
    RattachementInconnu {
        /// Compte visé.
        compte: Uuid,
        /// Prestataire visé.
        prestataire: Uuid,
    },
    /// Rupture posée par l'Admin — seule une bascule Admin la lève (409,
    /// FR-041).
    #[error("rupture posée par l'admin : seule une remise admin est acceptée")]
    RuptureAdmin,
    /// Signalement coursier refusé : aucune commande active avec un arrêt chez
    /// ce prestataire portant cet article (403, compté nulle part — FR-038).
    #[error("signalement refusé : aucune commande active éligible")]
    SignalementInterdit,
    /// Média au-delà de la taille autorisée.
    #[error("objet trop volumineux")]
    ObjetTropVolumineux,
    /// Média de type refusé.
    #[error("média invalide : {0}")]
    MediaInvalide(String),
    /// Paramètre de zone requis absent de toute la chaîne d'héritage, ou
    /// inexploitable — le SERVICE est mal configuré (500), pas le client
    /// (patron du cycle 003).
    #[error("configuration de zone « {cle} » : {raison}")]
    ConfigurationZoneInvalide {
        /// Clé du paramètre fautif.
        cle: &'static str,
        /// Ce qui cloche.
        raison: String,
    },
    /// Contrôle de commande active indisponible (port `CommandesActives`).
    #[error("contrôle de commande active : {0}")]
    CommandesActives(#[from] crate::ports::ErreurCommandesActives),
    /// Configuration de zone irrésolvable (devise, seuils, fuseau).
    #[error("configuration de zone : {0}")]
    Zones(#[from] zones::ErreurZones),
    /// Machine à états des rôles du cycle 003 (attribution vendeur — R11).
    #[error("domaine comptes : {0}")]
    Comptes(#[from] comptes::ErreurComptes),
    /// Erreur de la base de données.
    #[error("erreur base de données prestataires : {0}")]
    Sql(#[from] sqlx::Error),
}

impl From<socle::OutboxError> for ErreurPrestataires {
    /// L'écriture d'un événement outbox n'échoue que sur erreur SQL — repliée
    /// sur [`ErreurPrestataires::Sql`] pour préserver l'atomicité
    /// (constitution VI).
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurPrestataires::Sql(e),
        }
    }
}
