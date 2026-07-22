//! Ports du domaine prestataires (constitution II — interfaces par traits).
//!
//! Un seul port ce cycle : la précondition de commande active du signalement
//! coursier (FR-038, research R5). Le stockage objet passe par
//! `socle::DepotObjets` (reprise R1), qui n'est pas redéfini ici.

use std::collections::HashSet;
use std::sync::Mutex;

use async_trait::async_trait;
use uuid::Uuid;

/// Échec du contrôle de commande active (indisponibilité du module commandes,
/// plus tard). Distinct d'un refus : un refus est `Ok(false)`.
#[derive(Debug, thiserror::Error)]
#[error("commandes actives : {0}")]
pub struct ErreurCommandesActives(pub String);

/// Précondition du signalement de rupture par un coursier (FR-038, alignée
/// sur QRC-02) : le coursier porte-t-il une commande ACTIVE comportant un
/// arrêt chez le prestataire de cet article, l'article appartenant à cette
/// commande ?
///
/// Le module commandes fournira l'impl réelle (cycle CMD) sans toucher à ce
/// crate ; d'ici là, [`AucuneCommandeActive`] est branchée en production et
/// les tests exercent l'éligibilité via [`CommandesActivesFixes`].
#[async_trait]
pub trait CommandesActives: Send + Sync {
    /// `Ok(true)` si le signalement est recevable pour ce couple
    /// coursier/article ; `Ok(false)` → refus, compté nulle part.
    async fn arret_actif(
        &self,
        coursier: Uuid,
        article: Uuid,
    ) -> Result<bool, ErreurCommandesActives>;
}

/// Impl de PRODUCTION tant que le module commandes n'existe pas : AUCUNE
/// commande active n'existe, donc aucun signalement n'est recevable. Ce n'est
/// pas un bouchon menteur — c'est l'état exact du monde avant le cycle CMD.
pub struct AucuneCommandeActive;

#[async_trait]
impl CommandesActives for AucuneCommandeActive {
    async fn arret_actif(
        &self,
        _coursier: Uuid,
        _article: Uuid,
    ) -> Result<bool, ErreurCommandesActives> {
        Ok(false)
    }
}

/// Double de test : éligibilité posée couple par couple, révocable en cours de
/// test (un signalement APRÈS la fin de la commande doit être refusé).
#[derive(Default)]
pub struct CommandesActivesFixes {
    eligibles: Mutex<HashSet<(Uuid, Uuid)>>,
}

impl CommandesActivesFixes {
    /// Aucun couple éligible au départ.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Rend le couple coursier/article éligible.
    pub fn autoriser(&self, coursier: Uuid, article: Uuid) {
        self.eligibles
            .lock()
            .expect("verrou éligibilités")
            .insert((coursier, article));
    }

    /// Révoque l'éligibilité (fin de commande simulée).
    pub fn retirer(&self, coursier: Uuid, article: Uuid) {
        self.eligibles
            .lock()
            .expect("verrou éligibilités")
            .remove(&(coursier, article));
    }
}

#[async_trait]
impl CommandesActives for CommandesActivesFixes {
    async fn arret_actif(
        &self,
        coursier: Uuid,
        article: Uuid,
    ) -> Result<bool, ErreurCommandesActives> {
        Ok(self
            .eligibles
            .lock()
            .expect("verrou éligibilités")
            .contains(&(coursier, article)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn production_refuse_tout_avant_le_cycle_cmd() {
        let port = AucuneCommandeActive;
        let recevable = port
            .arret_actif(Uuid::now_v7(), Uuid::now_v7())
            .await
            .unwrap();
        assert!(!recevable, "aucune commande active n'existe avant CMD");
    }

    #[tokio::test]
    async fn double_de_test_autorise_puis_revoque() {
        let port = CommandesActivesFixes::nouveau();
        let (coursier, article) = (Uuid::now_v7(), Uuid::now_v7());

        assert!(!port.arret_actif(coursier, article).await.unwrap());

        port.autoriser(coursier, article);
        assert!(port.arret_actif(coursier, article).await.unwrap());
        assert!(
            !port.arret_actif(coursier, Uuid::now_v7()).await.unwrap(),
            "l'éligibilité est par ARTICLE de la commande, pas par coursier",
        );

        port.retirer(coursier, article);
        assert!(
            !port.arret_actif(coursier, article).await.unwrap(),
            "commande terminée → signalement refusé",
        );
    }
}
