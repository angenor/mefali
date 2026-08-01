//! Accès Postgres au domaine prestataires (patron des cycles 002/003).
//!
//! [`PgPrestataires`] est la composition racine du domaine : pool, `PgZones`
//! (paramètres hérités + recalcul d'activation), `PgComptes` (attribution du
//! rôle vendeur au rattachement), le port objets (`socle::DepotObjets`) et le
//! port [`CommandesActives`] (précondition du signalement coursier).
//!
//! Deux surfaces :
//! - LECTURES : les traits [`Prestataires`] (entité générale) et [`Vendeurs`]
//!   (spécialisation MVP), implémentés une fois tous les modules livrés — la
//!   SÉPARATION des deux traits est la forme opposable de « prestataire ≠
//!   vendeur » (constitution II, research R14) ;
//! - ÉCRITURES : méthodes inhérentes prenant `&mut sqlx::PgTransaction`
//!   (réparties dans `prestataire.rs`, `plaque.rs`, `rattachement.rs`,
//!   `site.rs`, `catalogue.rs`, `disponibilite.rs`), pour que l'atomicité
//!   « transition + événement outbox » soit impossible à contourner
//!   (constitution VI).

use std::sync::Arc;

use async_trait::async_trait;
use comptes::PgComptes;
use socle::DepotObjets;
use sqlx::PgPool;
use uuid::Uuid;
use zones::{ConfigurationZones, PgZones};

use crate::modele::{
    ArticleCommandable, Commandabilite, ErreurPrestataires, FichePublique, ResolutionPlaque,
};
use crate::ports::CommandesActives;

/// Lectures de l'ENTITÉ GÉNÉRALE — interface stable offerte aux cycles
/// suivants : QRC (`resoudre_jeton`), CMD (`commandable`), WEB
/// (`fiche_publique`), CRS (`prestataires_pilotables`). AUCUNE méthode ne
/// suppose l'existence d'un catalogue (research R14).
#[async_trait]
pub trait Prestataires: Send + Sync {
    /// FR-028 — la SEULE définition de « commandable » : agréé ∧ catégorie
    /// active dans sa ville ∧ boutique effectivement ouverte.
    async fn commandable(&self, prestataire: Uuid) -> Result<Commandabilite, ErreurPrestataires>;

    /// FR-016 — à un jeton présenté, le prestataire correspondant et sa
    /// validité courante (DÉRIVÉE de l'agrément). `None` = jeton inconnu.
    async fn resoudre_jeton(
        &self,
        jeton: &str,
    ) -> Result<Option<ResolutionPlaque>, ErreurPrestataires>;

    /// FR-027 — le sous-ensemble public de la fiche. `None` = inconnu,
    /// prospect OU suspendu : la couche appelante sert la MÊME réponse neutre
    /// pour les trois (FR-017, research R9).
    async fn fiche_publique(
        &self,
        prestataire: Uuid,
    ) -> Result<Option<FichePublique>, ErreurPrestataires>;

    /// Prestataires que ce compte pilote (rattachements) — la PORTE des
    /// surfaces vendeur (FR-011), et celle du cycle CRS plus tard.
    async fn prestataires_pilotables(
        &self,
        compte: Uuid,
    ) -> Result<Vec<Uuid>, ErreurPrestataires>;
}

/// Lectures de la SPÉCIALISATION vendeur — consommées par le module commandes
/// (panier, CMD-01/03). Un consommateur qui ne dépend que de [`Prestataires`]
/// ne peut structurellement rien supposer du catalogue.
#[async_trait]
pub trait Vendeurs: Send + Sync {
    /// Articles commandables du prestataire : disponibles, non retirés, chez
    /// un prestataire lui-même commandable (SC-004).
    async fn articles_commandables(
        &self,
        prestataire: Uuid,
    ) -> Result<Vec<ArticleCommandable>, ErreurPrestataires>;
}

/// Handle de dépôt du domaine prestataires. Le clone est bon marché (pool et
/// ports partagés).
#[derive(Clone)]
pub struct PgPrestataires {
    pub(crate) pool: PgPool,
    pub(crate) zones: PgZones,
    pub(crate) comptes: PgComptes,
    pub(crate) objets: Arc<dyn DepotObjets>,
    pub(crate) commandes: Arc<dyn CommandesActives>,
    pub(crate) secret_plaque: Arc<[u8]>,
}

impl PgPrestataires {
    /// Construit le dépôt. `PgZones` est dérivé du pool (même base) ;
    /// `PgComptes` est le dépôt DÉJÀ composé par la racine (ses ports à lui ne
    /// regardent pas ce crate) ; `secret_plaque` = `PLAQUE_SECRET` (R2).
    pub fn new(
        pool: PgPool,
        comptes: PgComptes,
        objets: Arc<dyn DepotObjets>,
        commandes: Arc<dyn CommandesActives>,
        secret_plaque: Arc<[u8]>,
    ) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            comptes,
            objets,
            commandes,
            secret_plaque,
        }
    }

    /// Pool sous-jacent — l'appelant ouvre ses transactions.
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Stockage objet — photos de fiche/articles et chartes. Exposé pour que
    /// la couche `api` présigne sans reconstruire un client.
    pub fn objets(&self) -> &dyn DepotObjets {
        &*self.objets
    }

    /// Configuration de zone résolue (seuils de masquage, affichage rupture,
    /// fuseau, devise).
    pub fn zones(&self) -> &dyn ConfigurationZones {
        &self.zones
    }

    /// VND-08 minimal — l'offre de livraison déclarée par le vendeur, telle que
    /// `tarification` sait la lire (cycle 011, research R10).
    ///
    /// `None` couvre le cas `jamais` : le devis ne reçoit alors AUCUNE offre, ce
    /// qui est exactement ce que `DemandeDevis::offre_livraison_vendeur: None`
    /// signifie déjà. Un troisième variant « aucune » ferait dire deux fois la
    /// même chose à deux types.
    ///
    /// La cohérence `au_dela ⇒ seuil > 0` est tenue par le `CHECK`
    /// `offre_livraison_seuil_coherent` (migration 0021) : si la base la
    /// violait, ce serait une corruption, pas un cas métier — d'où le
    /// `PrestataireInconnu` plutôt qu'une variante d'erreur nouvelle.
    pub async fn offre_livraison(
        &self,
        prestataire: Uuid,
    ) -> Result<Option<tarification::OffreLivraison>, ErreurPrestataires> {
        let ligne = sqlx::query!(
            r#"SELECT offre_livraison::text AS "offre!", offre_livraison_seuil_unites
               FROM prestataires.prestataire WHERE id = $1"#,
            prestataire,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurPrestataires::PrestataireInconnu(prestataire))?;

        Ok(match ligne.offre.as_str() {
            "toujours" => Some(tarification::OffreLivraison::Toujours),
            "au_dela" => ligne
                .offre_livraison_seuil_unites
                .map(tarification::OffreLivraison::AuDela),
            _ => None,
        })
    }
}
