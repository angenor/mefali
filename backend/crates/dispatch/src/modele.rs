//! Types publics du domaine dispatch (cycle DSP 009, data-model §5).
//!
//! Types PURS, sans I/O. Énums miroir des types Postgres
//! (`dispatch.mode_offre`, `.issue_offre`, `.motif_ecart`,
//! `.motif_reassignation`) avec `comme_str()`/`FromStr` — patron du cycle 005
//! (cast SQL `col::text AS "col!"`, jamais l'énum brut).
//!
//! Deux règles d'unité, opposables partout dans le crate :
//!
//! - **argent** : `i64` d'unités mineures + devise ISO 4217 (constitution III) ;
//! - **scores et distances** : entiers de bout en bout (research R6) —
//!   composantes en **millièmes** (`0..=1000`), poids en **centièmes**,
//!   distances en mètres, durées en secondes. Un flottant rendrait l'égalité de
//!   FR-039 fortuite et le classement non reproductible.

use std::str::FromStr;

use chrono::{DateTime, Utc};
use uuid::Uuid;

// ── Capacités ──────────────────────────────────────────────────────────────

/// Exigence GÉNÉRIQUE `(famille, valeur)` — jamais « type de véhicule ».
///
/// MVP : famille `transport`, valeur = slug de `zones.type_transport`. FR-018
/// exige que l'ajout d'une famille (qualification d'artisan, phase N) ne coûte
/// ni migration ni réécriture du filtre : c'est pourquoi la capacité est une
/// paire de chaînes et non une énum.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct Capacite {
    /// Famille de capacité (MVP : `transport`).
    pub famille: String,
    /// Valeur dans la famille (MVP : slug de transport).
    pub valeur: String,
}

impl Capacite {
    /// Capacité de transport — le seul cas du MVP.
    pub fn transport(slug: impl Into<String>) -> Self {
        Self {
            famille: "transport".to_owned(),
            valeur: slug.into(),
        }
    }
}

// ── Pool ───────────────────────────────────────────────────────────────────

/// Ce que le pool sait d'un coursier — image du hash `dispatch:etat:{id}`.
///
/// ⚠ Le pool est un **index**, jamais une autorisation (research R12, FR-009) :
/// l'éligibilité confirme rôle, blocage et course active **en Postgres** avant
/// de retenir un candidat. Un hash Redis survit à une suspension.
#[derive(Debug, Clone, PartialEq)]
pub struct InscriptionPool {
    /// Compte du coursier.
    pub coursier: Uuid,
    /// Zone d'exercice (celle qui résout les 18 paramètres).
    pub zone: Uuid,
    /// Dernière latitude publiée.
    pub lat: f64,
    /// Dernière longitude publiée.
    pub lon: f64,
    /// Vrai si le coursier s'est déclaré en ligne.
    pub en_ligne: bool,
    /// Capacités déclarées (véhicules du dossier coursier).
    pub capacites: Vec<Capacite>,
    /// Note en centièmes, ou `None` tant qu'AVI n'existe pas (research R7).
    pub note_centiemes: Option<i32>,
    /// Plafond d'avance DÉCLARÉ du jour (unités mineures).
    pub plafond_unites: i64,
    /// Devise ISO 4217 de la zone.
    pub devise: String,
    /// Course active, ou `None` — le pool en garde une copie, la base tranche.
    pub course_active: Option<Uuid>,
    /// Âge de la dernière publication, en secondes.
    pub age_s: i64,
}

// ── Classement ─────────────────────────────────────────────────────────────

/// Les quatre composantes du score, en **millièmes** (`0..=1000`), avant
/// pondération (FR-034, research R6).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Composantes {
    /// Proximité — relative au lot : le meilleur vaut 1000, le pire 0.
    pub proximite: i32,
    /// Inactivité depuis la dernière course livrée (ou l'entrée dans le pool).
    pub inactivite: i32,
    /// Note du coursier, ou la valeur neutre de zone si elle manque.
    pub note: i32,
    /// Taux d'acceptation sur la fenêtre de zone, hors non-réponses franches.
    pub acceptation: i32,
}

/// Un éligible CLASSÉ.
#[derive(Debug, Clone, PartialEq)]
pub struct Candidat {
    /// Compte du coursier.
    pub coursier: Uuid,
    /// Composantes normalisées (millièmes).
    pub composantes: Composantes,
    /// Score pondéré — entier (research R6).
    pub score: i32,
    /// Rang dans la cascade, 0 = mieux classé.
    pub rang: u16,
}

/// Ce sur quoi la proximité a été mesurée (FR-035).
///
/// L'ETA routière quand OSRM répond ; la distance sinon. La distinction entre
/// dans l'événement `dispatch.evaluation_faite` : un classement mesuré à la
/// distance ne se compare pas à un classement mesuré à la durée.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MesureProximite {
    /// Durée de trajet routière (secondes).
    Duree,
    /// Distance routière (mètres) — repli quand la durée manque.
    Distance,
}

impl MesureProximite {
    /// Représentation textuelle (payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            MesureProximite::Duree => "duree",
            MesureProximite::Distance => "distance",
        }
    }
}

// ── Éligibilité ────────────────────────────────────────────────────────────

/// Motif d'écart d'éligibilité — miroir de `dispatch.motif_ecart`.
///
/// Un motif par critère de DSP-02, pour que chacun ait son test (SC-013) et que
/// la bascule prépaiement soit **décidable** : FR-026 exige que la capacité
/// d'avance soit le SEUL obstacle, ce qui ne se lit que sur une liste complète.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum MotifEcart {
    /// Absent du pool (jamais publié, ou silence au-delà du TTL).
    HorsLigne,
    /// Déjà une course en cours — pas de superposition au MVP (FR-007).
    CourseActive,
    /// Les capacités requises ne sont pas toutes déclarées (FR-017).
    CapaciteNonCouverte,
    /// Au-delà du rayon de zone, mesuré en distance ROUTIÈRE (FR-021).
    HorsRayon,
    /// Le montant à avancer dépasse son plafond retenu (FR-023).
    CapaciteAvance,
    /// Paire bloquée avec le client ou l'un des vendeurs (FR-025, CRS-07).
    PaireBloquee,
    /// Rôle non validé, ou compte bloqué (FR-009).
    CompteIndisponible,
    /// Déjà destinataire d'une offre en vol (FR-056).
    OffreEnVol,
}

impl MotifEcart {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifEcart::HorsLigne => "hors_ligne",
            MotifEcart::CourseActive => "course_active",
            MotifEcart::CapaciteNonCouverte => "capacite_non_couverte",
            MotifEcart::HorsRayon => "hors_rayon",
            MotifEcart::CapaciteAvance => "capacite_avance",
            MotifEcart::PaireBloquee => "paire_bloquee",
            MotifEcart::CompteIndisponible => "compte_indisponible",
            MotifEcart::OffreEnVol => "offre_en_vol",
        }
    }

    /// Les huit motifs, dans l'ordre de l'énum Postgres — l'ordre dans lequel
    /// le filtre les évalue, et celui dans lequel les tests les parcourent.
    pub const TOUS: [MotifEcart; 8] = [
        MotifEcart::HorsLigne,
        MotifEcart::CourseActive,
        MotifEcart::CapaciteNonCouverte,
        MotifEcart::HorsRayon,
        MotifEcart::CapaciteAvance,
        MotifEcart::PaireBloquee,
        MotifEcart::CompteIndisponible,
        MotifEcart::OffreEnVol,
    ];
}

impl FromStr for MotifEcart {
    type Err = ErreurDispatch;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "hors_ligne" => Ok(MotifEcart::HorsLigne),
            "course_active" => Ok(MotifEcart::CourseActive),
            "capacite_non_couverte" => Ok(MotifEcart::CapaciteNonCouverte),
            "hors_rayon" => Ok(MotifEcart::HorsRayon),
            "capacite_avance" => Ok(MotifEcart::CapaciteAvance),
            "paire_bloquee" => Ok(MotifEcart::PaireBloquee),
            "compte_indisponible" => Ok(MotifEcart::CompteIndisponible),
            "offre_en_vol" => Ok(MotifEcart::OffreEnVol),
            autre => Err(ErreurDispatch::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Pourquoi un coursier est écarté — **la liste** de ses motifs, pas le premier.
///
/// FR-026 en dépend : la bascule prépaiement ne se déclenche que s'il existe un
/// écart dont les motifs valent exactement `[CapaciteAvance]`. Un filtre qui
/// s'arrêterait au premier motif rendrait cette condition indécidable.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EcartEligibilite {
    /// Compte du coursier écarté.
    pub coursier: Uuid,
    /// Tous ses motifs d'écart, dans l'ordre d'évaluation.
    pub motifs: Vec<MotifEcart>,
}

impl EcartEligibilite {
    /// Vrai si la capacité d'avance est le SEUL obstacle (FR-026).
    pub fn seul_obstacle_est_l_avance(&self) -> bool {
        self.motifs == [MotifEcart::CapaciteAvance]
    }
}

/// Résultat d'un passage d'évaluation.
#[derive(Debug, Clone, PartialEq)]
pub struct Evaluation {
    /// Éligibles classés, mieux classé d'abord.
    pub candidats: Vec<Candidat>,
    /// Écartés, avec la liste de leurs motifs.
    pub ecarts: Vec<EcartEligibilite>,
    /// Vrai si la proximité vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
    /// Grandeur sur laquelle la proximité a été mesurée.
    pub mesure_par: MesureProximite,
}

impl Evaluation {
    /// Le premier écart dont la capacité d'avance est le seul obstacle.
    pub fn ecart_bloque_par_l_avance(&self) -> Option<&EcartEligibilite> {
        self.ecarts.iter().find(|e| e.seul_obstacle_est_l_avance())
    }

    /// Comptes par motif — l'agrégat de `dispatch.evaluation_faite`.
    pub fn motifs_comptes(&self) -> Vec<(MotifEcart, usize)> {
        MotifEcart::TOUS
            .iter()
            .filter_map(|m| {
                let n = self.ecarts.iter().filter(|e| e.motifs.contains(m)).count();
                (n > 0).then_some((*m, n))
            })
            .collect()
    }
}

// ── Offres ─────────────────────────────────────────────────────────────────

/// Mode d'émission — miroir de `dispatch.mode_offre`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModeOffre {
    /// Au mieux classé, un à la fois (DSP-04).
    Cascade,
    /// À tous les éligibles en même temps (DSP-05).
    Broadcast,
}

impl ModeOffre {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            ModeOffre::Cascade => "cascade",
            ModeOffre::Broadcast => "broadcast",
        }
    }
}

impl FromStr for ModeOffre {
    type Err = ErreurDispatch;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "cascade" => Ok(ModeOffre::Cascade),
            "broadcast" => Ok(ModeOffre::Broadcast),
            autre => Err(ErreurDispatch::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Issue d'une offre — miroir de `dispatch.issue_offre`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IssueOffre {
    /// Émise, échéance non atteinte, sans réponse.
    EnVol,
    /// Acceptée — la course est affectée.
    Acceptee,
    /// Refusée explicitement : le candidat suivant est sollicité aussitôt.
    Refusee,
    /// Échéance atteinte sans réponse (franche ou non).
    NonRepondue,
    /// Un autre coursier a pris la course d'abord. **Pas un refus** : aucune
    /// pénalité, et le coursier reste dans le pool (FR-049).
    DejaPrise,
    /// Retirée par le système (commande annulée, réassignation).
    Annulee,
}

impl IssueOffre {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            IssueOffre::EnVol => "en_vol",
            IssueOffre::Acceptee => "acceptee",
            IssueOffre::Refusee => "refusee",
            IssueOffre::NonRepondue => "non_repondue",
            IssueOffre::DejaPrise => "deja_prise",
            IssueOffre::Annulee => "annulee",
        }
    }

    /// Vrai si l'issue compte dans le taux d'acceptation (FR-038).
    ///
    /// `DejaPrise` et `Annulee` n'y comptent pas : le coursier n'a rien décidé.
    /// Une non-réponse **franche** en est retirée par le calcul, pas ici — la
    /// franchise dépend du rang du jour, pas du type d'issue.
    pub fn compte_dans_le_taux(self) -> bool {
        matches!(
            self,
            IssueOffre::Acceptee | IssueOffre::Refusee | IssueOffre::NonRepondue
        )
    }
}

impl FromStr for IssueOffre {
    type Err = ErreurDispatch;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "en_vol" => Ok(IssueOffre::EnVol),
            "acceptee" => Ok(IssueOffre::Acceptee),
            "refusee" => Ok(IssueOffre::Refusee),
            "non_repondue" => Ok(IssueOffre::NonRepondue),
            "deja_prise" => Ok(IssueOffre::DejaPrise),
            "annulee" => Ok(IssueOffre::Annulee),
            autre => Err(ErreurDispatch::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Image de la ligne `dispatch.offre`.
///
/// L'`echeance_le` est **persistée** : c'est elle l'autorité du compte à
/// rebours, pas un minuteur en mémoire (research R1). Une lecture d'offre échue
/// rend `204` même si le tic n'est pas encore passé.
#[derive(Debug, Clone, PartialEq)]
pub struct Offre {
    /// Identifiant — UUIDv7, qui sert aussi de **jeton** du double verrou.
    pub id: Uuid,
    /// Commande offerte.
    pub commande: Uuid,
    /// Destinataire.
    pub coursier: Uuid,
    /// Zone de la commande.
    pub zone: Uuid,
    /// Cascade ou broadcast.
    pub mode: ModeOffre,
    /// Rang dans la cascade (0 en broadcast).
    pub rang: i16,
    /// Score du destinataire — trace de la décision.
    pub score: i32,
    /// Montant que le coursier devra avancer (unités mineures).
    pub montant_a_avancer: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Émission (horodatage serveur).
    pub emise_le: DateTime<Utc>,
    /// Échéance PERSISTÉE — autorité du compte à rebours.
    pub echeance_le: DateTime<Utc>,
    /// Issue courante.
    pub issue: IssueOffre,
    /// Horodatage de la réponse, `None` tant qu'elle est en vol.
    pub repondue_le: Option<DateTime<Utc>>,
    /// Non-réponse non pénalisée (FR-052).
    pub franche: bool,
}

impl Offre {
    /// Vrai si l'échéance est atteinte à cet instant — la lecture le sait
    /// **avant** le tic (research R1).
    pub fn est_echue(&self, maintenant: DateTime<Utc>) -> bool {
        maintenant >= self.echeance_le
    }

    /// Secondes restantes avant l'échéance, jamais négatives.
    pub fn restant_s(&self, maintenant: DateTime<Utc>) -> i64 {
        (self.echeance_le - maintenant).num_seconds().max(0)
    }
}

// ── Réassignation ──────────────────────────────────────────────────────────

/// Motif de reprise automatique — miroir de `dispatch.motif_reassignation`.
///
/// DEUX critères distincts (research R13) : le premier est **géographique**
/// (« le coursier ne se rapproche pas »), le second porte sur l'**état de la
/// course** (« aucun arrêt collecté au-delà du délai annoncé »). Les confondre
/// ferait passer un coursier bloqué dans un embouteillage pour un absent.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifReassignation {
    /// Aucun rapprochement significatif sur la fenêtre de zone (FR-071).
    SansMouvement,
    /// Aucun arrêt collecté au-delà de préparation + marge (FR-072).
    SansScan,
}

impl MotifReassignation {
    /// Représentation textuelle = valeur Postgres de l'énum.
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifReassignation::SansMouvement => "sans_mouvement",
            MotifReassignation::SansScan => "sans_scan",
        }
    }
}

impl FromStr for MotifReassignation {
    type Err = ErreurDispatch;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "sans_mouvement" => Ok(MotifReassignation::SansMouvement),
            "sans_scan" => Ok(MotifReassignation::SansScan),
            autre => Err(ErreurDispatch::ValeurInconnue(autre.to_owned())),
        }
    }
}

/// Une réassignation décidée.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Reprise {
    /// Livraison reprise.
    pub livraison: Uuid,
    /// Commande de la livraison.
    pub commande: Uuid,
    /// Coursier retiré — exclu des offres de CETTE commande (FR-074).
    pub coursier_retire: Uuid,
    /// Critère qui a déclenché la reprise.
    pub motif: MotifReassignation,
    /// Distance observée au premier arrêt non résolu, arrondie en mètres.
    pub distance_m: i64,
    /// Durée de stagnation constatée, en secondes.
    pub stagnation_s: i64,
}

// ── Erreurs ────────────────────────────────────────────────────────────────

/// Refus et pannes du domaine dispatch.
///
/// Chaque refus MÉTIER porte sa **clé i18n fr** (`message_cle`) — aucune chaîne
/// utilisateur en dur (constitution VII). Le mapping vers un statut HTTP vit
/// dans la couche `api` (`erreurs_dispatch.rs`), jamais ici.
#[derive(Debug, thiserror::Error)]
pub enum ErreurDispatch {
    /// Offre introuvable, **ou offerte à un autre coursier** : la garde de
    /// propriété rend `404` — une offre qui n'est pas la sienne n'existe pas.
    #[error("offre inconnue : {0}")]
    OffreInconnue(Uuid),
    /// La course a déjà été prise. **Sans pénalité** (FR-049).
    #[error("course déjà prise par un autre coursier")]
    DejaPrise,
    /// Compte à rebours passé — l'échéance persistée fait foi (research R1).
    #[error("offre échue")]
    OffreEchue,
    /// Le coursier a déjà une course en cours (FR-007).
    #[error("course active — pas de superposition au MVP")]
    CourseActive,
    /// Rôle coursier non validé, ou compte bloqué (FR-009).
    #[error("dossier coursier invalide (rôle non validé ou compte bloqué)")]
    DossierCoursierInvalide,
    /// Aucun véhicule déclaré : rien ne peut lui être offert (FR-017).
    #[error("aucune capacité déclarée")]
    CapaciteNonDeclaree,
    /// Motif obligatoire absent (reprise manuelle admin, FR-075).
    #[error("motif obligatoire")]
    MotifRequis,
    /// Reprise manuelle demandée alors qu'aucun arrêt n'est collecté :
    /// l'automatisme suffit, et une action manuelle masquerait un défaut de
    /// pipeline (contrat §2.2).
    #[error("reprise manuelle inutile — aucun arrêt collecté")]
    RepriseInutile,
    /// Configuration de zone refusée AU CHARGEMENT (SC-005) : verrou plus court
    /// que le compte à rebours, ou somme des poids ≠ 100.
    #[error("configuration de dispatch invalide : {0}")]
    ConfigurationInvalide(String),
    /// Paramètre de zone absent — jamais un défaut silencieux (constitution I).
    #[error("paramètre de zone absent : {0}")]
    ParametreAbsent(String),
    /// Valeur d'énum inconnue lue en base.
    #[error("valeur inconnue : {0}")]
    ValeurInconnue(String),
    /// Panne d'une dépendance (Redis, notifications, port consommé).
    #[error("dépendance dispatch : {0}")]
    Dependance(String),
    /// Erreur de la base de données.
    #[error("erreur base de données dispatch : {0}")]
    Sql(#[from] sqlx::Error),
}

impl ErreurDispatch {
    /// Clé i18n **courte** du refus, ou `None` si l'erreur est technique.
    ///
    /// La couche HTTP la préfixe de son espace de noms (`dispatch.erreur.…`) —
    /// patron `erreurs_commandes.rs`. Une erreur sans clé n'expose rien : son
    /// détail vit dans les journaux.
    pub fn message_cle(&self) -> Option<&'static str> {
        Some(match self {
            ErreurDispatch::OffreInconnue(_) => "offre_inconnue",
            ErreurDispatch::DejaPrise => "deja_prise",
            ErreurDispatch::OffreEchue => "offre_echue",
            ErreurDispatch::CourseActive => "course_active",
            ErreurDispatch::DossierCoursierInvalide => "dossier_coursier_invalide",
            ErreurDispatch::CapaciteNonDeclaree => "capacite_non_declaree",
            ErreurDispatch::MotifRequis => "motif_requis",
            ErreurDispatch::RepriseInutile => "reprise_inutile",
            // Techniques : ConfigurationInvalide, ParametreAbsent,
            // ValeurInconnue, Dependance, Sql. Une configuration refusée est un
            // défaut d'exploitation, pas une action du coursier.
            _ => return None,
        })
    }
}

impl From<zones::ErreurZones> for ErreurDispatch {
    fn from(e: zones::ErreurZones) -> Self {
        match e {
            zones::ErreurZones::Sql(sql) => ErreurDispatch::Sql(sql),
            autre => ErreurDispatch::Dependance(autre.to_string()),
        }
    }
}

impl From<commandes::ErreurCommandes> for ErreurDispatch {
    fn from(e: commandes::ErreurCommandes) -> Self {
        match e {
            commandes::ErreurCommandes::Sql(sql) => ErreurDispatch::Sql(sql),
            // Une transition refusée à l'affectation n'est PAS une panne : c'est
            // exactement « la course vient d'être prise » (research R4). C'est
            // ce chemin qui rend SC-001 vrai même sans Redis.
            commandes::ErreurCommandes::TransitionRefusee { .. } => ErreurDispatch::DejaPrise,
            autre => ErreurDispatch::Dependance(autre.to_string()),
        }
    }
}

impl From<socle::OutboxError> for ErreurDispatch {
    fn from(e: socle::OutboxError) -> Self {
        match e {
            socle::OutboxError::Db(sql) => ErreurDispatch::Sql(sql),
        }
    }
}

impl From<comptes::ErreurComptes> for ErreurDispatch {
    fn from(e: comptes::ErreurComptes) -> Self {
        match e {
            comptes::ErreurComptes::Sql(sql) => ErreurDispatch::Sql(sql),
            autre => ErreurDispatch::Dependance(autre.to_string()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Aller-retour énum ↔ texte : la valeur Postgres et le type Rust ne
    /// peuvent pas diverger sans que ce test le dise.
    #[test]
    fn les_enums_font_l_aller_retour_avec_leur_valeur_postgres() {
        for m in MotifEcart::TOUS {
            assert_eq!(MotifEcart::from_str(m.comme_str()).unwrap(), m);
        }
        for m in [ModeOffre::Cascade, ModeOffre::Broadcast] {
            assert_eq!(ModeOffre::from_str(m.comme_str()).unwrap(), m);
        }
        for i in [
            IssueOffre::EnVol,
            IssueOffre::Acceptee,
            IssueOffre::Refusee,
            IssueOffre::NonRepondue,
            IssueOffre::DejaPrise,
            IssueOffre::Annulee,
        ] {
            assert_eq!(IssueOffre::from_str(i.comme_str()).unwrap(), i);
        }
        for m in [
            MotifReassignation::SansMouvement,
            MotifReassignation::SansScan,
        ] {
            assert_eq!(MotifReassignation::from_str(m.comme_str()).unwrap(), m);
        }
    }

    /// FR-026 — la bascule prépaiement ne se lit QUE sur une liste complète de
    /// motifs. Un coursier écarté pour l'avance **et** autre chose ne la
    /// déclenche pas : le prépaiement ne lèverait pas son autre obstacle.
    #[test]
    fn seule_la_capacite_d_avance_declenche_le_prepaiement() {
        let seul = EcartEligibilite {
            coursier: Uuid::now_v7(),
            motifs: vec![MotifEcart::CapaciteAvance],
        };
        assert!(seul.seul_obstacle_est_l_avance());

        let accompagne = EcartEligibilite {
            coursier: Uuid::now_v7(),
            motifs: vec![MotifEcart::CapaciteAvance, MotifEcart::HorsRayon],
        };
        assert!(
            !accompagne.seul_obstacle_est_l_avance(),
            "avancer l'argent ne rapprocherait pas ce coursier de 5 km",
        );

        let autre = EcartEligibilite {
            coursier: Uuid::now_v7(),
            motifs: vec![MotifEcart::CourseActive],
        };
        assert!(!autre.seul_obstacle_est_l_avance());
    }

    /// L'échéance PERSISTÉE est l'autorité : une lecture sait qu'une offre est
    /// échue sans attendre le tic (research R1).
    #[test]
    fn l_echeance_persistee_est_l_autorite_du_compte_a_rebours() {
        let emise = Utc::now();
        let offre = Offre {
            id: Uuid::now_v7(),
            commande: Uuid::now_v7(),
            coursier: Uuid::now_v7(),
            zone: Uuid::now_v7(),
            mode: ModeOffre::Cascade,
            rang: 0,
            score: 700,
            montant_a_avancer: 5_550,
            devise: "XOF".to_owned(),
            emise_le: emise,
            echeance_le: emise + chrono::Duration::seconds(40),
            issue: IssueOffre::EnVol,
            repondue_le: None,
            franche: false,
        };
        assert!(!offre.est_echue(emise + chrono::Duration::seconds(39)));
        assert_eq!(offre.restant_s(emise + chrono::Duration::seconds(9)), 31);
        assert!(offre.est_echue(emise + chrono::Duration::seconds(40)));
        assert_eq!(
            offre.restant_s(emise + chrono::Duration::seconds(120)),
            0,
            "jamais de reste négatif",
        );
    }

    /// `DejaPrise` n'est PAS un refus : elle ne compte pas dans le taux
    /// d'acceptation, parce que le coursier n'a rien décidé (FR-049).
    #[test]
    fn deja_prise_ne_compte_pas_dans_le_taux_d_acceptation() {
        assert!(IssueOffre::Acceptee.compte_dans_le_taux());
        assert!(IssueOffre::Refusee.compte_dans_le_taux());
        assert!(IssueOffre::NonRepondue.compte_dans_le_taux());
        assert!(!IssueOffre::DejaPrise.compte_dans_le_taux());
        assert!(!IssueOffre::Annulee.compte_dans_le_taux());
        assert!(!IssueOffre::EnVol.compte_dans_le_taux());
    }

    /// Chaque refus MÉTIER porte sa clé ; les erreurs techniques n'en ont pas.
    #[test]
    fn chaque_refus_metier_porte_sa_cle_i18n() {
        for e in [
            ErreurDispatch::OffreInconnue(Uuid::now_v7()),
            ErreurDispatch::DejaPrise,
            ErreurDispatch::OffreEchue,
            ErreurDispatch::CourseActive,
            ErreurDispatch::DossierCoursierInvalide,
            ErreurDispatch::CapaciteNonDeclaree,
            ErreurDispatch::MotifRequis,
            ErreurDispatch::RepriseInutile,
        ] {
            assert!(e.message_cle().is_some(), "« {e} » est un refus métier");
        }
        assert!(ErreurDispatch::Dependance("détail interne".to_owned())
            .message_cle()
            .is_none());
        assert!(
            ErreurDispatch::ConfigurationInvalide("verrou ≤ timer".to_owned())
                .message_cle()
                .is_none()
        );
    }

    /// Une transition refusée par la table fermée de `commandes` EST « déjà
    /// prise » (research R4) : c'est ce qui rend SC-001 vrai sans Redis.
    #[test]
    fn une_transition_refusee_devient_deja_prise() {
        let e = ErreurDispatch::from(commandes::ErreurCommandes::TransitionRefusee {
            niveau: "commande",
            depuis: "en_cours".to_owned(),
            vers: "en_cours".to_owned(),
        });
        assert!(matches!(e, ErreurDispatch::DejaPrise));
        assert_eq!(e.message_cle(), Some("deja_prise"));
    }

    /// L'agrégat de `dispatch.evaluation_faite` compte les motifs, jamais les
    /// coursiers : un coursier à deux motifs pèse dans les deux comptes.
    #[test]
    fn l_agregat_compte_les_motifs_pas_les_coursiers() {
        let evaluation = Evaluation {
            candidats: Vec::new(),
            ecarts: vec![
                EcartEligibilite {
                    coursier: Uuid::now_v7(),
                    motifs: vec![MotifEcart::HorsRayon, MotifEcart::CapaciteAvance],
                },
                EcartEligibilite {
                    coursier: Uuid::now_v7(),
                    motifs: vec![MotifEcart::HorsRayon],
                },
            ],
            degraded: false,
            mesure_par: MesureProximite::Duree,
        };
        let comptes = evaluation.motifs_comptes();
        assert_eq!(
            comptes,
            vec![(MotifEcart::HorsRayon, 2), (MotifEcart::CapaciteAvance, 1)],
        );
        assert!(
            evaluation.ecart_bloque_par_l_avance().is_none(),
            "aucun écart n'a l'avance pour SEUL motif",
        );
    }
}
