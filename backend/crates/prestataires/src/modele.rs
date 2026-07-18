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

use chrono::{DateTime, NaiveTime, Utc};
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

/// Rendu des articles en rupture, résolu par catégorie dans la configuration
/// de zone (`categorie.<slug>.affichage_rupture` — FR-042, FR-050, R8).
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AffichageRupture {
    /// L'article est servi, grisé, non commandable (seed — maquettes V2/C2).
    Grise,
    /// L'article est ABSENT de la consultation.
    Masque,
}

impl AffichageRupture {
    /// Valeur du paramètre de zone.
    pub fn comme_str(self) -> &'static str {
        match self {
            AffichageRupture::Grise => "grise",
            AffichageRupture::Masque => "masque",
        }
    }
}

impl FromStr for AffichageRupture {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "grise" => Ok(AffichageRupture::Grise),
            "masque" => Ok(AffichageRupture::Masque),
            autre => Err(format!("affichage de rupture inconnu : {autre}")),
        }
    }
}

// ── Types dérivés (jamais stockés) et de consultation ──────────────────────

/// Une plage d'ouverture dans la journée (heures LOCALES de la zone — FR-031).
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct Plage {
    /// Début (inclus).
    pub debut: NaiveTime,
    /// Fin (exclue) — strictement après le début (CHECK en base).
    pub fin: NaiveTime,
}

/// Horaires hebdomadaires : index 0 = lundi … 6 = dimanche ; un jour sans
/// plage est un jour de fermeture (FR-031).
#[derive(Debug, Clone, PartialEq, Eq, Default, serde::Serialize, serde::Deserialize)]
pub struct HorairesSemaine {
    /// Plages par jour, triées par heure de début.
    pub jours: [Vec<Plage>; 7],
}

/// État EFFECTIF d'une boutique — DÉRIVÉ à chaque lecture, jamais stocké
/// (FR-032, research R3).
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct EffectifBoutique {
    /// La boutique reçoit-elle des commandes en cet instant ?
    pub ouvert: bool,
    /// Prochaine réouverture estimée quand `ouvert` est faux (fin de pause
    /// recalée dans les horaires, sinon prochaine plage — FR-029).
    pub reouverture_estimee: Option<DateTime<Utc>>,
}

/// Décomposition de l'état « commandable » (FR-028) — la SEULE définition ;
/// les modules ultérieurs (CMD) s'y réfèrent sans la redupliquer.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct Commandabilite {
    /// Le prestataire est à l'état `agree`.
    pub agree: bool,
    /// Sa catégorie de service est active dans sa ville (ZON-03).
    pub categorie_active: bool,
    /// L'état effectif de sa boutique est ouvert.
    pub boutique_ouverte: bool,
}

impl Commandabilite {
    /// VRAI si et seulement si les trois conditions tiennent (FR-028).
    pub fn commandable(self) -> bool {
        self.agree && self.categorie_active && self.boutique_ouverte
    }
}

/// Résolution d'un jeton de plaque (FR-016) — la validité DÉRIVE de l'état
/// d'agrément, sans liste de révocation (FR-015).
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct ResolutionPlaque {
    /// Prestataire que la plaque désigne.
    pub prestataire_id: Uuid,
    /// `statut = agree` à l'instant de la résolution.
    pub valide: bool,
}

/// Article tel que la consultation publique le sert (sous-ensemble FR-027).
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct ArticlePublic {
    /// Identifiant.
    pub id: Uuid,
    /// Nom (contenu vendeur).
    pub nom: String,
    /// Prix courant, entier en unités mineures (constitution III).
    pub prix_unites: i64,
    /// Code ISO 4217 de la zone.
    pub devise: String,
    /// Prix barré (présent ⇒ promotion, strictement supérieur — FR-023).
    pub prix_barre_unites: Option<i64>,
    /// URL présignée de la photo (TTL court), s'il y en a une.
    pub photo_url: Option<String>,
    /// Étiquette libre de regroupement (FR-021).
    pub categorie_interne: Option<String>,
    /// Faux = rupture (servi seulement si `affichage_rupture = grise`).
    pub disponible: bool,
}

/// Fiche publique : le sous-ensemble EXACT que FR-027 autorise — ni contact,
/// ni coordonnées de site, ni donnée d'exploitation (SC-013).
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct FichePublique {
    /// Identifiant du prestataire.
    pub id: Uuid,
    /// Nom public.
    pub nom: String,
    /// Slug de la catégorie de service.
    pub categorie: String,
    /// URLs présignées des photos de fiche, dans l'ordre.
    pub photos: Vec<String>,
    /// Délai de préparation moyen déclaré (minutes).
    pub delai_preparation_min: i32,
    /// État effectif de la boutique (dérivé).
    pub boutique: EffectifBoutique,
    /// Horaires hebdomadaires.
    pub horaires: HorairesSemaine,
    /// FR-028 — la seule définition.
    pub commandable: bool,
    /// Mode de rendu des ruptures, résolu pour la catégorie (FR-050).
    pub affichage_rupture: AffichageRupture,
    /// Catalogue servi (retirés absents ; ruptures selon le mode).
    pub articles: Vec<ArticlePublic>,
}

/// Article vu par le module commandes (trait `Vendeurs`) : uniquement les
/// articles COMMANDABLES — disponibles, non retirés, chez un prestataire
/// commandable (SC-004).
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct ArticleCommandable {
    /// Identifiant.
    pub id: Uuid,
    /// Nom.
    pub nom: String,
    /// Prix courant, entier en unités mineures.
    pub prix_unites: i64,
    /// Code ISO 4217.
    pub devise: String,
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
    /// Champ de fiche inexploitable (nom vide, délai négatif…).
    #[error("fiche invalide : {0}")]
    FicheInvalide(String),
    /// Aucune photo pour cet identifiant chez ce prestataire.
    #[error("photo inconnue : {0}")]
    PhotoInconnue(Uuid),
    /// Média au-delà de la taille autorisée.
    #[error("objet trop volumineux")]
    ObjetTropVolumineux,
    /// Média de type refusé.
    #[error("média invalide : {0}")]
    MediaInvalide(String),
    /// Stockage objet (Garage/S3) indisponible.
    #[error("stockage objet indisponible : {0}")]
    Objets(#[from] socle::ErreurObjets),
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
