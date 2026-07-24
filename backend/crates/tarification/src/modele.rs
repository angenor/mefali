//! Types publics du domaine tarification (data-model.md §1 et §5).
//!
//! Montants = **entiers en unités mineures** (`i64`) + code ISO 4217 porté par
//! la zone (constitution III). Les SEULS flottants du module sont
//! non monétaires : coordonnées géographiques et facteur de dégradé.
//!
//! Les DTO HTTP (annotations `ToSchema`) vivent dans la couche `api`
//! (`admin_tarification_http`) ; ici, seulement le domaine.

use std::fmt;
use std::str::FromStr;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Grille et règles ───────────────────────────────────────────────────────

/// Cycle de vie d'une grille tarifaire (US1/US3, research R7).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EtatGrille {
    /// En édition — aucun effet tarifaire (FR-012).
    Brouillon,
    /// Sert la tarification de la zone (au plus une par zone).
    EnVigueur,
    /// Version archivée par une publication (FR-022).
    Historique,
}

impl EtatGrille {
    /// Représentation textuelle = valeur de l'énum Postgres
    /// `tarification.etat_grille` (binds castés `$n::tarification.etat_grille`).
    pub fn comme_str(self) -> &'static str {
        match self {
            EtatGrille::Brouillon => "brouillon",
            EtatGrille::EnVigueur => "en_vigueur",
            EtatGrille::Historique => "historique",
        }
    }
}

impl fmt::Display for EtatGrille {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for EtatGrille {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "brouillon" => Ok(EtatGrille::Brouillon),
            "en_vigueur" => Ok(EtatGrille::EnVigueur),
            "historique" => Ok(EtatGrille::Historique),
            autre => Err(format!("état de grille inconnu : {autre}")),
        }
    }
}

/// Grille tarifaire versionnée d'une zone (`tarification.grille`).
#[derive(Debug, Clone, PartialEq)]
pub struct Grille {
    /// Identifiant (UUIDv7).
    pub id: Uuid,
    /// Zone dont cette grille tarife les courses.
    pub zone_id: Uuid,
    /// Numéro de version, croissant par zone.
    pub version: i32,
    /// État dans le cycle de vie.
    pub etat: EtatGrille,
    /// Entrée en vigueur (posée à la publication).
    pub effet_le: Option<DateTime<Utc>>,
    /// Dernière simulation réussie (garde de publication, R7).
    pub simulee_le: Option<DateTime<Utc>>,
    /// Empreinte du contenu simulé — toute édition la périme (FR-021).
    pub simulee_empreinte: Option<String>,
    /// Règles de la grille, triées de façon déterministe (par `id`).
    pub regles: Vec<Regle>,
}

impl Grille {
    /// `true` si la simulation couvre le contenu EXACT de la grille — c'est la
    /// garde de publication (FR-021) : simuler puis éditer ne suffit pas.
    pub fn simulation_a_jour(&self) -> bool {
        match (&self.simulee_empreinte, self.simulee_le) {
            (Some(empreinte), Some(_)) => *empreinte == crate::grille::empreinte(&self.regles),
            _ => false,
        }
    }
}

/// Règle tarifaire : conditions → sorties (`tarification.regle`).
///
/// Invariant monétaire DÉRIVÉ (jamais stocké) :
/// `prix_client_base = part_coursier_base + marge`. La composante km, la grille
/// d'effort et le reliquat d'arrondi abondent la **part coursier** ; la
/// **marge reste fixe** (FR-019, clarification 2026-07-24).
#[derive(Debug, Clone, PartialEq)]
pub struct Regle {
    /// Identifiant (UUIDv7) — sert aussi de départage déterministe (R5).
    pub id: Uuid,
    /// Grille porteuse.
    pub grille_id: Uuid,
    /// Véhicule (slug du référentiel `zones.type_transport`).
    pub transport_slug: String,
    /// Catégorie de service, `None` = toutes catégories.
    pub categorie_slug: Option<String>,
    /// Borne basse de la tranche de distance **routière** (mètres).
    pub distance_min_m: i32,
    /// Borne haute, `None` = +∞.
    pub distance_max_m: Option<i32>,
    /// Début de plage horaire (minutes depuis minuit), `None` = toute heure.
    pub plage_debut_min: Option<i16>,
    /// Fin de plage horaire (minutes depuis minuit).
    pub plage_fin_min: Option<i16>,
    /// Masque de jours (bit 0 = lundi … bit 6 = dimanche), `None` = tous.
    pub jours_masque: Option<i16>,
    /// PROVISION point relais — TOUJOURS `None` au MVP (constitution IX,
    /// garde `CHECK (point_relais_id IS NULL)` en base).
    pub point_relais_id: Option<Uuid>,
    /// Part coursier de base (unités mineures).
    pub part_coursier_base: i64,
    /// Marge Mefali — bornée par la zone à l'écriture (FR-009).
    pub marge: i64,
    /// Prix par kilomètre au-delà de `seuil_km_m` (abonde client ET coursier).
    pub prix_par_km: i64,
    /// Seuil (mètres) au-delà duquel le kilométrage est facturé.
    pub seuil_km_m: i32,
    /// Plafond du prix CLIENT, `None` = aucun.
    pub prix_plafond: Option<i64>,
    /// Devise ISO 4217, cohérente avec celle de la zone (FR-023).
    pub devise: String,
    /// Départage volontaire de l'admin (R5).
    pub priorite: i32,
    /// Règle désactivée sans être supprimée.
    pub actif: bool,
}

impl Regle {
    /// Prix client de base dérivé — l'invariant, jamais dénormalisé (FR-019).
    pub fn prix_client_base(&self) -> i64 {
        self.part_coursier_base + self.marge
    }
}

/// Écriture (création ou remplacement) d'une règle de brouillon.
///
/// La `devise` n'est PAS demandée à l'appelant : elle est résolue depuis la zone
/// à l'écriture (FR-023) — un client ne peut pas glisser une devise étrangère.
#[derive(Debug, Clone, PartialEq)]
pub struct RegleUpsert {
    /// Véhicule.
    pub transport_slug: String,
    /// Catégorie, `None` = toutes.
    pub categorie_slug: Option<String>,
    /// Borne basse de la tranche (mètres routiers).
    pub distance_min_m: i32,
    /// Borne haute, `None` = +∞.
    pub distance_max_m: Option<i32>,
    /// Début de plage horaire (minutes depuis minuit).
    pub plage_debut_min: Option<i16>,
    /// Fin de plage horaire.
    pub plage_fin_min: Option<i16>,
    /// Masque de jours.
    pub jours_masque: Option<i16>,
    /// Part coursier de base (unités mineures).
    pub part_coursier_base: i64,
    /// Marge Mefali (bornée par la zone).
    pub marge: i64,
    /// Prix par km au-delà du seuil.
    pub prix_par_km: i64,
    /// Seuil de kilométrage facturé (mètres).
    pub seuil_km_m: i32,
    /// Plafond du prix client.
    pub prix_plafond: Option<i64>,
    /// Devise ISO 4217 déclarée par l'appelant — DOIT égaler celle de la zone,
    /// sinon `devise_incoherente` (FR-025 : jamais de conversion silencieuse).
    pub devise: String,
    /// Priorité de départage.
    pub priorite: i32,
    /// Active à l'évaluation.
    pub actif: bool,
}

// ── Géométrie et routage ───────────────────────────────────────────────────

/// Point géographique. Les coordonnées sont des flottants NON monétaires ; elles
/// ne sortent jamais dans un payload d'événement (minimisation ARTCI, R10).
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Point {
    /// Latitude en degrés décimaux.
    pub lat: f64,
    /// Longitude en degrés décimaux.
    pub lon: f64,
}

/// Tronçon routier entre deux points consécutifs (sous-produit de la matrice).
/// Sert la composante km ET le barème de supplément d'arrêt (FR-029).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Troncon {
    /// Distance routière (mètres).
    pub distance_m: i64,
    /// Durée (secondes).
    pub duree_s: i64,
}

/// Matrice distance/durée entre tous les points d'une course (OSRM `/table`, R2).
///
/// Stockée à plat (`n × n`, ligne majeure) et construite par
/// [`Matrice::nouvelle`], qui refuse une taille incohérente : aucun accès ne
/// peut ensuite lire hors matrice.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Matrice {
    /// Nombre de points.
    n: usize,
    distances_m: Vec<i64>,
    durees_s: Vec<i64>,
    /// Vrai si la matrice vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
}

impl Matrice {
    /// Construit la matrice. `distances_m` et `durees_s` font `n × n`.
    pub fn nouvelle(
        n: usize,
        distances_m: Vec<i64>,
        durees_s: Vec<i64>,
        degraded: bool,
    ) -> Result<Self, ErreurRoutage> {
        if n == 0 || distances_m.len() != n * n || durees_s.len() != n * n {
            return Err(ErreurRoutage::ReponseInvalide(format!(
                "matrice {n}×{n} attendue, reçu {} distances / {} durées",
                distances_m.len(),
                durees_s.len()
            )));
        }
        Ok(Self {
            n,
            distances_m,
            durees_s,
            degraded,
        })
    }

    /// Nombre de points de la matrice.
    pub fn taille(&self) -> usize {
        self.n
    }

    /// Tronçon `de → vers`. Panique si un indice sort de la matrice — c'est un
    /// bug d'appelant, pas une donnée d'entrée (les indices viennent de nos
    /// permutations, jamais du réseau).
    pub fn troncon(&self, de: usize, vers: usize) -> Troncon {
        let i = de * self.n + vers;
        Troncon {
            distance_m: self.distances_m[i],
            duree_s: self.durees_s[i],
        }
    }
}

/// Itinéraire retenu : ordre des retraits, distance/ETA routières, tronçons.
///
/// Exposé à DSP et CMD via [`crate::ports::OptimisationArrets`] (FR-031).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Itineraire {
    /// Indices des retraits dans l'ordre de passage (référence la `DemandeDevis`).
    pub ordre: Vec<usize>,
    /// Distance routière totale retraits → client (mètres).
    pub distance_m: i64,
    /// Durée estimée totale (secondes).
    pub eta_s: i64,
    /// Vrai si la distance vient du repli vol d'oiseau × facteur.
    pub degraded: bool,
    /// Tronçons de l'itinéraire retenu, dans l'ordre — `troncons[0]` est le
    /// PREMIER arrêt (research R6 : « 1er arrêt inclus » pour l'effort), le
    /// dernier est arrêt final → client.
    pub troncons: Vec<Troncon>,
    /// Vrai si l'ordre est le meilleur parmi TOUTES les permutations (≤ 4) ;
    /// faux si l'heuristique bornée a tranché — jamais présenté comme optimal
    /// quand il ne l'est pas (FR-031).
    pub exhaustif: bool,
}

// ── Devis ──────────────────────────────────────────────────────────────────

/// Détail des composantes du devis, en unités mineures (FR-020, simulateur).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Composantes {
    /// Prix client de base de la règle (`part_coursier_base + marge`).
    pub base: i64,
    /// Composante kilométrique au-delà du seuil.
    pub km: i64,
    /// Suppléments activés (pluie, plage horaire…).
    pub supplements: i64,
    /// Effort — paliers d'articles (100 % coursier).
    pub effort_paliers: i64,
    /// Effort — prime d'attente (100 % coursier, une seule fois par course).
    pub effort_attente: i64,
    /// Effort — suppléments d'arrêt (100 % coursier).
    pub effort_arrets: i64,
    /// Reliquat d'arrondi du prix client — abonde la part coursier (FR-016).
    pub arrondi: i64,
    /// Retenue vendeur (VND-08) : part du prix client prise en charge par le
    /// vendeur. Son financement relève de PAY (hors périmètre).
    pub retenue_vendeur: i64,
}

impl Composantes {
    /// Total de la grille d'effort (les trois composantes, 100 % coursier).
    pub fn effort_total(&self) -> i64 {
        self.effort_paliers + self.effort_attente + self.effort_arrets
    }
}

/// Devis **figé** — prêt à être verrouillé par CMD.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Devis {
    /// Prix payé par le client (unités mineures).
    pub prix_client: i64,
    /// Part reversée au coursier (unités mineures).
    pub part_coursier: i64,
    /// Marge Mefali (unités mineures) — fixe par règle.
    pub marge: i64,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Distance routière totale (mètres).
    pub distance_m: i64,
    /// Durée estimée (secondes).
    pub eta_s: i64,
    /// Vrai si la distance vient du dégradé ×facteur (constitution IV).
    pub degraded: bool,
    /// Vrai si le détour dépasse le plafond d'éclatement de la zone : CMD
    /// PROPOSERA de scinder — TRF ne scinde pas (FR-032).
    pub proposer_scission: bool,
    /// Ordre des retraits retenu.
    pub ordre: Vec<usize>,
    /// Détail des composantes.
    pub composantes: Composantes,
}

impl Devis {
    /// Vérifie l'invariant `prix_client = part_coursier + marge` (FR-019).
    ///
    /// `None` dès qu'un prix client a été FORCÉ à 0 (drapeau de zone ou
    /// VND-08) : l'invariant ne s'applique alors pas, la part coursier restant
    /// due (FR-017/FR-018). L'appelant distingue ainsi « invariant vérifié » de
    /// « invariant non applicable », sans jamais lire un faux positif.
    pub fn invariant_verifie(&self) -> Option<bool> {
        if self.prix_client == 0 && self.part_coursier > 0 {
            return None;
        }
        Some(self.prix_client == self.part_coursier + self.marge)
    }
}

/// Règle effectivement retenue par l'évaluation (détail du simulateur, FR-020).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RegleRetenue {
    /// Identifiant de la règle.
    pub regle_id: Uuid,
    /// Véhicule de la règle.
    pub transport_slug: String,
    /// Priorité de la règle.
    pub priorite: i32,
}

/// Drapeaux de zone appliqués à l'évaluation (consommés, jamais redéfinis ici —
/// FR-007).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct DrapeauxZone {
    /// `drapeau.livraison_offerte_mefali` → prix client 0 (FR-017).
    pub livraison_offerte_mefali: bool,
    /// `drapeau.gratuite_commissions` → marge 0 (FR-017).
    pub gratuite_commissions: bool,
    /// `drapeau.pluie` → supplément de zone (FR-016).
    pub pluie: bool,
}

/// Résultat complet d'une évaluation : le devis ET sa traçabilité.
///
/// Le simulateur admin renvoie l'ensemble (FR-020) ; le trait
/// [`crate::ports::EvaluationTarifaire`] n'en expose que le [`Devis`] — un seul
/// cœur de calcul, deux niveaux de détail (research R11).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Evaluation {
    /// Devis figé.
    pub devis: Devis,
    /// Itinéraire utilisé.
    pub itineraire: Itineraire,
    /// Règle retenue.
    pub regle: RegleRetenue,
    /// Drapeaux appliqués.
    pub drapeaux: DrapeauxZone,
    /// Vrai si l'effort a été calculé mais NON facturé (promo — FR-033).
    pub effort_non_facture: bool,
}

// ── Entrée de l'évaluation ─────────────────────────────────────────────────

/// Attente constatée à un arrêt — les DEUX horodatages sont requis, sinon la
/// prime vaut 0 (FR-029 : « jamais inventée »).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Attente {
    /// Arrivée géolocalisée du coursier à l'arrêt.
    pub arrivee: DateTime<Utc>,
    /// Scan QR de la plaque (fin d'attente).
    pub scan: DateTime<Utc>,
}

impl Attente {
    /// Durée d'attente en minutes (négative repliée à 0 — une horloge cliente
    /// incohérente ne doit pas créditer d'attente).
    pub fn minutes(&self) -> i64 {
        (self.scan - self.arrivee).num_minutes().max(0)
    }
}

/// Livraison offerte par le vendeur (VND-08) — **entrée** du calcul ; la
/// configuration vendeur et son financement relèvent de VND/PAY (research R9).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OffreLivraison {
    /// Le vendeur prend la livraison en charge quel que soit le panier.
    Toujours,
    /// Prise en charge à partir de ce montant de panier (unités mineures).
    AuDela(i64),
}

impl OffreLivraison {
    /// L'offre joue-t-elle pour ce montant de panier ?
    pub fn joue(&self, montant_panier: i64) -> bool {
        match self {
            OffreLivraison::Toujours => true,
            OffreLivraison::AuDela(seuil) => montant_panier >= *seuil,
        }
    }
}

/// Demande de devis — porte la **géométrie**, pas la logistique (research R12).
#[derive(Debug, Clone, PartialEq)]
pub struct DemandeDevis {
    /// Zone tarifaire (résout grille, devise, knobs, drapeaux).
    pub zone_id: Uuid,
    /// Véhicule demandé.
    pub transport_slug: String,
    /// Points de retrait (1..n), dans l'ordre SOUMIS — l'évaluation les réordonne.
    pub retraits: Vec<Point>,
    /// Destination client.
    pub client: Point,
    /// Nombre total d'articles de la commande (paliers d'effort).
    pub nb_articles: i32,
    /// Instant d'évaluation (plage horaire, jour, dates d'effet).
    pub instant: DateTime<Utc>,
    /// Catégorie de service, `None` = règle sans condition de catégorie.
    pub categorie_slug: Option<String>,
    /// Attentes constatées (prime d'attente — une seule fois par course).
    pub attentes: Vec<Attente>,
    /// Montant du panier (unités mineures) — seuil VND-08.
    pub montant_panier: i64,
    /// Offre de livraison du vendeur (VND-08), `None` = aucune.
    pub offre_livraison_vendeur: Option<OffreLivraison>,
    /// Commande mono-vendeur — condition NÉCESSAIRE de VND-08 (FR-018).
    pub mono_vendeur: bool,
}

/// Grille contre laquelle évaluer : production ou simulateur (research R11).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SourceGrille {
    /// Grille `en_vigueur` de la zone — production.
    EnVigueur,
    /// Brouillon désigné — simulateur admin, sans effet de bord.
    Brouillon(Uuid),
}

impl SourceGrille {
    /// `true` en simulation : aucun événement outbox ne doit être écrit (R10).
    pub fn est_simulation(&self) -> bool {
        matches!(self, SourceGrille::Brouillon(_))
    }
}

// ── Erreurs ────────────────────────────────────────────────────────────────

/// Erreurs du domaine tarification. Chaque refus métier porte une clé i18n fr
/// ([`ErreurTarif::message_cle`]) — aucune chaîne utilisateur en dur (FR-001).
#[derive(Debug, thiserror::Error)]
pub enum ErreurTarif {
    /// Marge de règle hors des bornes de la zone (FR-009).
    #[error("marge {valeur} hors des bornes de zone [{min}, {max}]")]
    MargeHorsBornes {
        /// Borne basse résolue.
        min: i64,
        /// Borne haute résolue.
        max: i64,
        /// Valeur refusée.
        valeur: i64,
    },
    /// Devise de règle ≠ devise de la zone (FR-023/FR-025) — jamais convertie.
    #[error("devise incohérente : zone en {attendue}, règle en {fournie}")]
    DeviseIncoherente {
        /// Devise de la zone.
        attendue: String,
        /// Devise refusée.
        fournie: String,
    },
    /// Aucune règle applicable — jamais un prix arbitraire (edge case FR-010).
    #[error("aucune règle tarifaire applicable")]
    AucuneRegle,
    /// Publication sans simulation valide sur l'empreinte courante (FR-021).
    #[error("simulation requise avant publication")]
    SimulationRequise,
    /// Publication d'un brouillon contenant une règle hors bornes (FR-021).
    #[error("le brouillon contient une règle hors bornes")]
    RegleHorsBornes,
    /// Grille absente.
    #[error("grille inconnue : {0}")]
    GrilleInconnue(Uuid),
    /// Règle absente de la grille visée.
    #[error("règle inconnue : {0}")]
    RegleInconnue(Uuid),
    /// L'opération exige un brouillon (éditer, simuler, publier).
    #[error("la grille {0} n'est pas un brouillon")]
    PasUnBrouillon(Uuid),
    /// Aucune grille en vigueur dans la zone (rien à tarifer).
    #[error("aucune grille en vigueur pour la zone {0}")]
    AucuneGrilleEnVigueur(Uuid),
    /// Demande mal formée (aucun retrait, plage horaire incohérente…).
    #[error("demande de devis invalide : {0}")]
    DemandeInvalide(&'static str),
    /// Configuration de zone.
    #[error("configuration de zone : {0}")]
    Zones(#[from] zones::ErreurZones),
    /// Erreur base de données.
    #[error("erreur base de données tarification : {0}")]
    Sql(#[from] sqlx::Error),
}

impl ErreurTarif {
    /// Clé i18n fr du refus métier (contrats §5, rendue `tarification.erreur.*`).
    /// `None` pour les erreurs d'infrastructure (500, sans clé stable).
    pub fn message_cle(&self) -> Option<&'static str> {
        Some(match self {
            ErreurTarif::MargeHorsBornes { .. } => "marge_hors_bornes",
            ErreurTarif::DeviseIncoherente { .. } => "devise_incoherente",
            ErreurTarif::AucuneRegle => "aucune_regle",
            ErreurTarif::SimulationRequise => "simulation_requise",
            ErreurTarif::RegleHorsBornes => "regle_hors_bornes",
            ErreurTarif::GrilleInconnue(_) => "grille_inconnue",
            ErreurTarif::RegleInconnue(_) => "regle_inconnue",
            ErreurTarif::PasUnBrouillon(_) => "pas_un_brouillon",
            ErreurTarif::AucuneGrilleEnVigueur(_) => "aucune_grille_en_vigueur",
            ErreurTarif::DemandeInvalide(_) => "corps_invalide",
            _ => return None,
        })
    }
}

/// L'outbox se replie sur `Sql` pour préserver l'atomicité (patron 002/005/006).
impl From<socle::OutboxError> for ErreurTarif {
    fn from(erreur: socle::OutboxError) -> Self {
        match erreur {
            socle::OutboxError::Db(e) => ErreurTarif::Sql(e),
        }
    }
}

/// Erreurs du routage. **Jamais fatales** pour une évaluation : elles
/// déclenchent le repli vol d'oiseau × facteur de zone (constitution IV) — une
/// commande n'est jamais bloquée par le routage.
#[derive(Debug, thiserror::Error)]
pub enum ErreurRoutage {
    /// Service de routage injoignable, en erreur ou trop lent.
    #[error("service de routage indisponible : {0}")]
    Indisponible(String),
    /// Réponse reçue mais inexploitable (matrice incomplète, JSON inattendu).
    #[error("réponse de routage invalide : {0}")]
    ReponseInvalide(String),
}
