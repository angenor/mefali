//! Ports de LECTURE du socle logistique (constitution II).
//!
//! `ArretsDeCollecte` sert la précondition QRC-02 : « le coursier a-t-il une
//! livraison active dont un arrêt `à_collecter` vise ce prestataire ? ».
//! L'impl de production `PgCommandes` (depot.rs) lit `commandes.arret` ; le
//! double `ArretsFixes` simule l'affectation coursier↔livraison (posée par DSP,
//! absente avant CMD) — patron `prestataires::CommandesActivesFixes` (R10).

use std::collections::HashMap;
use std::sync::Mutex;

use async_trait::async_trait;
use uuid::Uuid;

use crate::modele::{ArretACollecter, ErreurCommandes};

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
}
