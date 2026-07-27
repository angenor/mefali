//! Composition racine du domaine dispatch (patron `PgCommandes`, `PgZones`).
//!
//! ÉCRITURES = méthodes inhérentes sur `&mut PgTransaction` — la transition et
//! son événement outbox vivent dans la MÊME transaction, et c'est impossible à
//! contourner (constitution VI). LECTURES = sur le pool.
//!
//! `PgDispatch` porte **six** collaborateurs, et **aucun n'est optionnel** :
//! une composition incomplète ne compile pas. C'est ce qui interdit qu'un
//! chemin oublie l'un d'eux et retombe silencieusement sur un défaut — la
//! panne la plus coûteuse à diagnostiquer, parce qu'elle ne se voit qu'au
//! comportement.
//!
//! | Collaborateur | Implémenté par | Avant lui |
//! |---|---|---|
//! | `zones` | `zones::PgZones` (dérivé du pool) | — |
//! | `commandes` | `commandes::PgCommandes` | — |
//! | `coursiers` | `comptes::PgComptes` | — |
//! | `pool_coursiers` | Redis (`api`) | `MemoirePool` |
//! | `verrous` | Redis + Lua (`api`) | `VerrouMemoire` |
//! | `proximite` | `tarification` (`api`) | `ProximiteFixe` |
//! | `notes` | AVI — **personne** | `NoteAbsente` |
//! | `paires` | CRS-07 — **personne** | `AucunePaireBloquee` |
//! | `notifications` | NTF-01 — **personne** | `AnnoncesJournalisees` |

use std::sync::Arc;

use commandes::CommandesADispatcher;
use sqlx::PgPool;
use uuid::Uuid;
use zones::PgZones;

use crate::config::ConfigDispatch;
use crate::modele::ErreurDispatch;
use crate::ports::{
    EtatCoursier, NotePrestataire, NotificationsDispatch, PairesBloquees, PoolCoursiers,
    ProximiteRoutiere, VerrouOffre,
};

/// Handle de dépôt du domaine dispatch. Clone bon marché (pool et ports
/// partagés).
#[derive(Clone)]
pub struct PgDispatch {
    pub(crate) pool: PgPool,
    /// Configuration héritée — DÉRIVÉE du pool (même base), patron du cycle 005.
    pub(crate) zones: PgZones,
    /// Contrat offert par le cycle 008 : file FIFO, affectation, capacités.
    pub(crate) commandes: Arc<dyn CommandesADispatcher>,
    /// Rôle validé, compte non bloqué, véhicules déclarés — DSP ne cite jamais
    /// `comptes.*`.
    pub(crate) coursiers: Arc<dyn EtatCoursier>,
    /// L'index éphémère (Redis en production, mémoire en test).
    pub(crate) pool_coursiers: Arc<dyn PoolCoursiers>,
    /// L'exclusivité double (scripts Lua en production).
    pub(crate) verrous: Arc<dyn VerrouOffre>,
    /// Une matrice routière par évaluation, jamais un appel par candidat.
    pub(crate) proximite: Arc<dyn ProximiteRoutiere>,
    /// Note du coursier — `NoteAbsente` tant qu'AVI n'existe pas (research R7).
    pub(crate) notes: Arc<dyn NotePrestataire>,
    /// Paires bloquées — `AucunePaireBloquee` tant que CRS-07 n'existe pas.
    pub(crate) paires: Arc<dyn PairesBloquees>,
    /// Contrat d'émission — `AnnoncesJournalisees` tant que NTF-01 n'existe pas.
    pub(crate) notifications: Arc<dyn NotificationsDispatch>,
}

impl PgDispatch {
    /// Compose le domaine. `PgZones` est dérivé du pool ; tous les autres
    /// collaborateurs sont injectés par la racine (`api`), qui seule connaît
    /// l'infrastructure (constitution II).
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        pool: PgPool,
        commandes: Arc<dyn CommandesADispatcher>,
        coursiers: Arc<dyn EtatCoursier>,
        pool_coursiers: Arc<dyn PoolCoursiers>,
        verrous: Arc<dyn VerrouOffre>,
        proximite: Arc<dyn ProximiteRoutiere>,
        notes: Arc<dyn NotePrestataire>,
        paires: Arc<dyn PairesBloquees>,
        notifications: Arc<dyn NotificationsDispatch>,
    ) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            commandes,
            coursiers,
            pool_coursiers,
            verrous,
            proximite,
            notes,
            paires,
            notifications,
        }
    }

    /// Accès au pool (tests d'intégration, tic).
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Accès à l'index éphémère (surface HTTP de disponibilité).
    pub fn pool_coursiers(&self) -> &Arc<dyn PoolCoursiers> {
        &self.pool_coursiers
    }

    /// Accès au contrat de commandes (tic, reprise FIFO).
    pub fn commandes(&self) -> &Arc<dyn CommandesADispatcher> {
        &self.commandes
    }

    /// Accès au contrat d'émission (escalade, retrait).
    pub fn notifications(&self) -> &Arc<dyn NotificationsDispatch> {
        &self.notifications
    }

    /// Configuration de dispatch d'une zone, **validée** (SC-005).
    ///
    /// Rechargée à chaque passage plutôt que mémorisée : c'est ce qui donne
    /// à SC-008 son « sans redéploiement » — un poids changé en base agit au
    /// dispatch suivant.
    pub async fn config(&self, zone: Uuid) -> Result<ConfigDispatch, ErreurDispatch> {
        ConfigDispatch::charger(&self.zones, zone).await
    }
}
