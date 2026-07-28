//! `PgCoursier` — racine de composition du domaine coursier.
//!
//! Le crate porte sqlx et **son** schéma (`coursier`). Tout ce qui appartient à
//! un autre domaine passe par le dépôt de ce domaine : la course vient de
//! `commandes` (port `CourseCoursier`), les empreintes de plaque et la politique
//! photo de `qr`, le nom et le contact du vendeur de `prestataires`, les seuils
//! de zone de `zones`, les photos de preuve du dépôt objets du `socle`.
//!
//! Aucune dépendance inverse : `commandes` ne dépend jamais de `coursier`.

use std::sync::Arc;

use commandes::PgCommandes;
use prestataires::PgPrestataires;
use qr::PgQr;
use socle::DepotObjets;
use sqlx::PgPool;
use zones::PgZones;

use crate::modele::ErreurCoursier;
use crate::ports::{AucunLitige, LitigesOuverts};

/// Dépôt Postgres du domaine coursier.
#[derive(Clone)]
pub struct PgCoursier {
    pub(crate) pool: PgPool,
    pub(crate) zones: PgZones,
    pub(crate) commandes: PgCommandes,
    pub(crate) qr: PgQr,
    pub(crate) prestataires: PgPrestataires,
    pub(crate) objets: Arc<dyn DepotObjets>,
    /// Litiges du coursier. `AucunLitige` en production tant qu'AVI-04 n'est
    /// pas construit — et c'est **l'état exact du monde**, pas un bouchon : il
    /// n'existe aucun litige nulle part (research R16).
    pub(crate) litiges: Arc<dyn LitigesOuverts>,
}

impl PgCoursier {
    /// Compose le dépôt coursier. `PgZones` est dérivé du pool (même base) ;
    /// les autres dépôts sont injectés déjà composés par la racine `api`.
    pub fn new(
        pool: PgPool,
        commandes: PgCommandes,
        qr: PgQr,
        prestataires: PgPrestataires,
        objets: Arc<dyn DepotObjets>,
    ) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            commandes,
            qr,
            prestataires,
            objets,
            litiges: Arc::new(AucunLitige),
        }
    }

    /// Remplace la source de litiges — AVI-04 s'y branchera sans toucher au
    /// reste, et les tests peuvent en poser.
    pub fn avec_litiges(mut self, litiges: Arc<dyn LitigesOuverts>) -> Self {
        self.litiges = litiges;
        self
    }

    /// Accès au pool applicatif (jobs de purge, tests).
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Vérifie qu'une livraison appartient bien à ce coursier — **la** garde de
    /// propriété du cycle (FR-006).
    ///
    /// Elle vaut à la lecture comme au REJEU : une action arrivée d'une file
    /// hors-ligne, dont la course a été réassignée entre-temps, doit être
    /// refusée et tracée, jamais appliquée en silence. C'était la dette relevée
    /// au cycle 008.
    ///
    /// Une livraison qui n'existe pas et une livraison qui appartient à
    /// quelqu'un d'autre rendent la MÊME erreur : un identifiant deviné ne doit
    /// rien révéler (patron `suivi` du cycle 008).
    pub(crate) async fn exiger_proprietaire(
        &self,
        livraison: uuid::Uuid,
        coursier: uuid::Uuid,
    ) -> Result<(), ErreurCoursier> {
        let a_lui: Option<bool> = sqlx::query_scalar!(
            r#"SELECT (l.coursier_id = $2) AS "a_lui!"
               FROM commandes.livraison l WHERE l.id = $1"#,
            livraison,
            coursier,
        )
        .fetch_optional(&self.pool)
        .await?;
        match a_lui {
            Some(true) => Ok(()),
            _ => Err(ErreurCoursier::CourseNonProprietaire),
        }
    }
}
