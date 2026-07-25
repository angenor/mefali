//! Ports du domaine commandes (constitution II) — offerts et consommés.
//!
//! **Offerts** aux cycles suivants : [`ArretsDeCollecte`] (précondition QRC-02,
//! cycle 006) et [`CommandesADispatcher`] (file d'attente + affectation, que
//! DSP consommera sans modification).
//!
//! **Consommés** par CMD, implémentés ailleurs ou simulés : [`RestrictionsCompte`]
//! (crate `comptes`, research R12), [`PreuvesEchec`] (CRS-05) et
//! [`PositionCoursier`] (Redis, alimenté par DSP-01).
//!
//! Chaque trait a son **double** juste à côté, sur le modèle d'`ArretsFixes`
//! déjà livré au cycle 006 (research R16) : c'est ce qui permet d'exercer
//! l'arbre §7.5 et la file d'attente sans construire DSP, PAY ni CRS, et laisse
//! ces cycles brancher leur implémentation réelle sans toucher au contrat.

use std::collections::HashMap;
use std::sync::Mutex;

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::modele::{ArretACollecter, ErreurCommandes, Restrictions, Sanction};

/// Lecture de l'arrêt à collecter d'un coursier chez un prestataire donné.
#[async_trait]
pub trait ArretsDeCollecte: Send + Sync {
    /// Renvoie l'arrêt `à_collecter` de la course active du coursier visant ce
    /// prestataire, ou `None` s'il n'y en a pas (aucune course, prestataire
    /// hors course, arrêt déjà résolu).
    async fn arret_a_collecter(
        &self,
        coursier: Uuid,
        prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes>;
}

/// Double de test : arrêts pré-enregistrés par `(coursier, prestataire)`.
/// Simule l'affectation DSP (R10) — en production, aucune course n'est assignée
/// tant que DSP n'existe pas, la lecture renvoie vide (exact et voulu).
#[derive(Debug, Default)]
pub struct ArretsFixes {
    arrets: Mutex<HashMap<(Uuid, Uuid), ArretACollecter>>,
}

impl ArretsFixes {
    /// Nouveau double vide.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Enregistre l'arrêt à collecter d'un coursier chez un prestataire.
    pub fn autoriser(&self, coursier: Uuid, prestataire: Uuid, arret: ArretACollecter) {
        self.arrets
            .lock()
            .expect("arrets")
            .insert((coursier, prestataire), arret);
    }

    /// Retire l'arrêt (simule sa résolution).
    pub fn retirer(&self, coursier: Uuid, prestataire: Uuid) {
        self.arrets
            .lock()
            .expect("arrets")
            .remove(&(coursier, prestataire));
    }
}

#[async_trait]
impl ArretsDeCollecte for ArretsFixes {
    async fn arret_a_collecter(
        &self,
        coursier: Uuid,
        prestataire: Uuid,
    ) -> Result<Option<ArretACollecter>, ErreurCommandes> {
        Ok(self
            .arrets
            .lock()
            .expect("arrets")
            .get(&(coursier, prestataire))
            .cloned())
    }
}

// ── OFFERT à DSP : file d'attente et affectation (CMD-10) ─────────────────

/// Une commande en attente de coursier, telle que DSP la lira.
///
/// ARTCI : aucune coordonnée du CLIENT ici — seul le point de première collecte
/// (position d'un site vendeur, donnée professionnelle) est exposé, parce que
/// c'est lui qui décide de l'éligibilité géographique d'un coursier.
#[derive(Debug, Clone, PartialEq)]
pub struct CommandeADispatcher {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Zone de la commande (résout les paramètres de dispatch).
    pub zone_id: Uuid,
    /// Ancienneté dans la file, en secondes (FIFO par âge — aucune table).
    pub age_s: i64,
    /// Nombre d'arrêts de collecte à desservir.
    pub nb_collectes: i64,
    /// Montant total que le coursier devra avancer (unités mineures, III).
    pub montant_a_avancer: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Position de la PREMIÈRE collecte (site vendeur).
    pub premiere_collecte_lat: Option<f64>,
    /// Position de la première collecte.
    pub premiere_collecte_lon: Option<f64>,
}

/// Contrat offert à **DSP** (dispatch — non construit ce cycle).
#[async_trait]
pub trait CommandesADispatcher: Send + Sync {
    /// File FIFO **par âge** des commandes sans coursier dans une zone (CMD-10).
    /// La plus ancienne d'abord, sans table dédiée (index partiel).
    async fn en_attente_coursier(
        &self,
        zone: Uuid,
    ) -> Result<Vec<CommandeADispatcher>, ErreurCommandes>;

    /// Affecte un coursier : crée la livraison `assignee` et passe le tronc
    /// `en_cours`. Reprend une commande en attente comme une commande neuve.
    async fn affecter(&self, commande: Uuid, coursier: Uuid) -> Result<Uuid, ErreurCommandes>;
}

/// Double de test du **dispatch** (DSP non construit, research R16).
///
/// DSP décidera QUEL coursier prendre ; ce double porte cette décision — un
/// vivier de coursiers éligibles par zone — et délègue l'écriture au vrai
/// [`CommandesADispatcher`]. Vider le vivier force la file d'attente CMD-10,
/// ce qui rend le cas « aucun coursier éligible » exerçable sans DSP.
#[derive(Debug, Default)]
pub struct AffectationSimulee {
    viviers: Mutex<HashMap<Uuid, Vec<Uuid>>>,
}

impl AffectationSimulee {
    /// Nouveau double : aucun coursier éligible nulle part.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Ajoute un coursier au vivier d'une zone.
    pub fn ajouter_coursier(&self, zone: Uuid, coursier: Uuid) {
        self.viviers
            .lock()
            .expect("viviers")
            .entry(zone)
            .or_default()
            .push(coursier);
    }

    /// Vide le vivier d'une zone — plus aucun coursier éligible (CMD-10).
    pub fn vider(&self, zone: Uuid) {
        self.viviers.lock().expect("viviers").remove(&zone);
    }

    /// Prochain coursier éligible de la zone, sans le consommer.
    pub fn coursier_eligible(&self, zone: Uuid) -> Option<Uuid> {
        self.viviers
            .lock()
            .expect("viviers")
            .get(&zone)
            .and_then(|v| v.first().copied())
    }

    /// Affecte le premier coursier éligible de la zone à cette commande, via le
    /// dépôt réel. `Ok(None)` = aucun coursier éligible : c'est à l'appelant de
    /// mettre la commande en attente (la décision reste dans le domaine).
    pub async fn affecter_via<D: CommandesADispatcher + ?Sized>(
        &self,
        depot: &D,
        zone: Uuid,
        commande: Uuid,
    ) -> Result<Option<Uuid>, ErreurCommandes> {
        let Some(coursier) = self.coursier_eligible(zone) else {
            return Ok(None);
        };
        depot.affecter(commande, coursier).await?;
        Ok(Some(coursier))
    }
}

// ── CONSOMMÉ : restrictions de compte (CPT-06, research R12) ───────────────

/// Restrictions de compte — **implémenté dans le crate `comptes`**, dont c'est
/// le schéma (constitution II). CMD ne cite jamais `comptes.compte` en écriture.
#[async_trait]
pub trait RestrictionsCompte: Send + Sync {
    /// Restrictions courantes du compte (prépaiement imposé, blocage).
    async fn restrictions(&self, compte: Uuid) -> Result<Restrictions, ErreurCommandes>;

    /// Pose une sanction DANS la transaction fournie, avec son événement
    /// `sanction.posee` — l'atomicité est impossible à contourner (VI).
    async fn poser_restriction(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        sanction: Sanction,
        motif_cle: &str,
    ) -> Result<(), ErreurCommandes>;
}

/// Double de test : restrictions en mémoire, sanctions mémorisées.
#[derive(Debug, Default)]
pub struct RestrictionsSimulees {
    etat: Mutex<HashMap<Uuid, Restrictions>>,
    posees: Mutex<Vec<(Uuid, Sanction, String)>>,
}

impl RestrictionsSimulees {
    /// Nouveau double : aucun compte restreint.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Force les restrictions d'un compte.
    pub fn definir(&self, compte: Uuid, restrictions: Restrictions) {
        self.etat.lock().expect("etat").insert(compte, restrictions);
    }

    /// Sanctions posées depuis la création du double, dans l'ordre.
    pub fn posees(&self) -> Vec<(Uuid, Sanction, String)> {
        self.posees.lock().expect("posees").clone()
    }
}

#[async_trait]
impl RestrictionsCompte for RestrictionsSimulees {
    async fn restrictions(&self, compte: Uuid) -> Result<Restrictions, ErreurCommandes> {
        Ok(self
            .etat
            .lock()
            .expect("etat")
            .get(&compte)
            .copied()
            .unwrap_or_default())
    }

    async fn poser_restriction(
        &self,
        _tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        sanction: Sanction,
        motif_cle: &str,
    ) -> Result<(), ErreurCommandes> {
        self.posees
            .lock()
            .expect("posees")
            .push((compte, sanction, motif_cle.to_owned()));
        let mut etat = self.etat.lock().expect("etat");
        let r = etat.entry(compte).or_default();
        match sanction {
            Sanction::PrepaiementImpose => r.prepaiement_impose = true,
            Sanction::Bloque => r.bloque = true,
            Sanction::Aucune => {}
        }
        Ok(())
    }
}

// ── CONSOMMÉ : preuves d'échec (CRS-05, non construit) ─────────────────────

/// Preuves réunies pour déclarer un échec (FR-056). Tant qu'elles ne le sont
/// pas, l'échec est REFUSÉ : « le coursier ne perd jamais » suppose une trace.
#[async_trait]
pub trait PreuvesEchec: Send + Sync {
    /// Vrai si les preuves de la livraison sont complètes.
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, ErreurCommandes>;
}

/// Double de test : preuves réunies ou non, par livraison (défaut : non).
#[derive(Debug, Default)]
pub struct PreuvesFixes {
    reunies: Mutex<HashMap<Uuid, bool>>,
    defaut: Mutex<bool>,
}

impl PreuvesFixes {
    /// Nouveau double — par défaut, AUCUNE preuve n'est réunie (le défaut le
    /// plus sûr : un test qui oublie de les poser voit son échec refusé).
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Preuves réunies (ou non) pour une livraison donnée.
    pub fn definir(&self, livraison: Uuid, reunies: bool) {
        self.reunies
            .lock()
            .expect("reunies")
            .insert(livraison, reunies);
    }

    /// Réponse par défaut pour les livraisons non renseignées.
    pub fn definir_defaut(&self, reunies: bool) {
        *self.defaut.lock().expect("defaut") = reunies;
    }
}

#[async_trait]
impl PreuvesEchec for PreuvesFixes {
    async fn preuves_reunies(&self, livraison: Uuid) -> Result<bool, ErreurCommandes> {
        let defaut = *self.defaut.lock().expect("defaut");
        Ok(self
            .reunies
            .lock()
            .expect("reunies")
            .get(&livraison)
            .copied()
            .unwrap_or(defaut))
    }
}

// ── CONSOMMÉ : position du coursier (Redis éphémère, research R13) ─────────

/// Dernière position connue d'un coursier, **avec son âge**.
///
/// L'âge est ce qui empêche l'app d'inventer une position (FR-040, maquette
/// C4-4d « Position non actualisée — il y a 4 min »).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct PositionDatee {
    /// Latitude.
    pub lat: f64,
    /// Longitude.
    pub lon: f64,
    /// Instant de relevé (serveur).
    pub releve_le: DateTime<Utc>,
    /// Âge en secondes au moment de la lecture.
    pub age_s: i64,
}

/// Lecture de la dernière position d'un coursier.
///
/// ⚠ L'absence de position renvoie `None`, **jamais** une erreur : Redis
/// indisponible ne doit pas casser un suivi (research R13).
#[async_trait]
pub trait PositionCoursier: Send + Sync {
    /// Dernière position connue, ou `None` si aucune n'est disponible.
    async fn derniere(&self, coursier: Uuid) -> Result<Option<PositionDatee>, ErreurCommandes>;
}

/// Double de test : position fixe par coursier, ou absence de position.
#[derive(Debug, Default)]
pub struct PositionFixe {
    positions: Mutex<HashMap<Uuid, PositionDatee>>,
}

impl PositionFixe {
    /// Nouveau double — aucun coursier n'a de position.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Pose la position d'un coursier et son âge.
    pub fn definir(&self, coursier: Uuid, position: PositionDatee) {
        self.positions
            .lock()
            .expect("positions")
            .insert(coursier, position);
    }

    /// Retire la position (simule l'expiration du TTL Redis).
    pub fn retirer(&self, coursier: Uuid) {
        self.positions.lock().expect("positions").remove(&coursier);
    }
}

#[async_trait]
impl PositionCoursier for PositionFixe {
    async fn derniere(&self, coursier: Uuid) -> Result<Option<PositionDatee>, ErreurCommandes> {
        Ok(self
            .positions
            .lock()
            .expect("positions")
            .get(&coursier)
            .copied())
    }
}

// ── Double de PAIEMENT (PAY non construit, research R16) ───────────────────

/// Double de test du module paiements : confirme un prépaiement ou le fait
/// expirer. Aucun trait n'est déclaré côté domaine — PAY posera le sien à son
/// cycle ; ici, le double sert à piloter l'état de paiement dans les tests, à
/// travers les transitions gardées du tronc.
#[derive(Debug, Default)]
pub struct PaiementSimule {
    confirmes: Mutex<Vec<Uuid>>,
    expires: Mutex<Vec<Uuid>>,
}

impl PaiementSimule {
    /// Nouveau double.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Note un prépaiement comme confirmé.
    pub fn confirmer(&self, commande: Uuid) {
        self.confirmes.lock().expect("confirmes").push(commande);
    }

    /// Note un prépaiement comme expiré.
    pub fn expirer(&self, commande: Uuid) {
        self.expires.lock().expect("expires").push(commande);
    }

    /// Vrai si le prépaiement de cette commande a été confirmé.
    pub fn est_confirme(&self, commande: Uuid) -> bool {
        self.confirmes.lock().expect("confirmes").contains(&commande)
    }

    /// Vrai si le prépaiement de cette commande a expiré.
    pub fn est_expire(&self, commande: Uuid) -> bool {
        self.expires.lock().expect("expires").contains(&commande)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn arret(arret_id: Uuid, prestataire: Uuid) -> ArretACollecter {
        ArretACollecter {
            arret_id,
            livraison_id: Uuid::now_v7(),
            segment_id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            prestataire_id: prestataire,
            site_lat: 5.898,
            site_lon: -4.823,
            montant_avance: 2000,
            devise: "XOF".to_owned(),
        }
    }

    #[tokio::test]
    async fn autoriser_puis_retirer() {
        let coursier = Uuid::now_v7();
        let presta = Uuid::now_v7();
        let a = Uuid::now_v7();
        let fixes = ArretsFixes::nouveau();
        assert!(fixes
            .arret_a_collecter(coursier, presta)
            .await
            .unwrap()
            .is_none());
        fixes.autoriser(coursier, presta, arret(a, presta));
        assert_eq!(
            fixes
                .arret_a_collecter(coursier, presta)
                .await
                .unwrap()
                .unwrap()
                .arret_id,
            a
        );
        fixes.retirer(coursier, presta);
        assert!(fixes
            .arret_a_collecter(coursier, presta)
            .await
            .unwrap()
            .is_none());
    }

    #[tokio::test]
    async fn preuves_fixes_refusent_par_defaut() {
        let livraison = Uuid::now_v7();
        let preuves = PreuvesFixes::nouveau();
        assert!(
            !preuves.preuves_reunies(livraison).await.unwrap(),
            "le défaut le plus sûr : sans preuve posée, l'échec est refusé",
        );
        preuves.definir(livraison, true);
        assert!(preuves.preuves_reunies(livraison).await.unwrap());
    }

    #[tokio::test]
    async fn position_absente_rend_none_jamais_une_erreur() {
        let coursier = Uuid::now_v7();
        let fixe = PositionFixe::nouveau();
        assert!(fixe.derniere(coursier).await.unwrap().is_none());
        fixe.definir(
            coursier,
            PositionDatee {
                lat: 5.898,
                lon: -4.823,
                releve_le: Utc::now(),
                age_s: 12,
            },
        );
        assert_eq!(fixe.derniere(coursier).await.unwrap().unwrap().age_s, 12);
        // Expiration du TTL Redis → absence, pas erreur (research R13).
        fixe.retirer(coursier);
        assert!(fixe.derniere(coursier).await.unwrap().is_none());
    }

    #[tokio::test]
    async fn restrictions_simulees_cumulent_les_sanctions() {
        let compte = Uuid::now_v7();
        let doubles = RestrictionsSimulees::nouveau();
        assert_eq!(
            doubles.restrictions(compte).await.unwrap(),
            Restrictions::default(),
            "aucun compte n'est restreint par défaut",
        );
        doubles.definir(
            compte,
            Restrictions {
                prepaiement_impose: true,
                bloque: false,
            },
        );
        assert!(doubles.restrictions(compte).await.unwrap().prepaiement_impose);
        assert!(!doubles.restrictions(compte).await.unwrap().bloque);
    }
}
