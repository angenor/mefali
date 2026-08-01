//! Ports du domaine coursier (constitution II) — offerts et consommés.
//!
//! **Offert** : l'implémentation de `commandes::PreuvesEchec` vit dans
//! [`crate::preuves`], pas ici — c'est un trait d'un autre crate.
//!
//! **Consommé** : [`LitigesOuverts`], que le module AVI-04 n'a pas construit.
//! Son double par défaut, [`AucunLitige`], n'est pas un bouchon de test : c'est
//! **l'état exact du monde** aujourd'hui — il n'existe aucun litige nulle part.
//! Le distinguer d'un vrai dépôt vide compte le jour où AVI arrivera : il
//! suffira de brancher l'implémentation réelle par `avec_litiges`.

use std::collections::HashMap;
use std::sync::Mutex;

use async_trait::async_trait;
use uuid::Uuid;

use crate::modele::{ErreurCoursier, LitigeVu};

/// Litiges rattachés à un coursier, avec leur état (FR-074).
#[async_trait]
pub trait LitigesOuverts: Send + Sync {
    /// Litiges en cours du coursier — vide s'il n'en a aucun.
    async fn litiges_du_coursier(&self, coursier: Uuid) -> Result<Vec<LitigeVu>, ErreurCoursier>;
}

/// **État exact du monde** tant qu'AVI-04 n'est pas construit : personne n'a de
/// litige, parce qu'aucun litige ne peut être ouvert.
///
/// La carte de litige de K5-1c ne s'affiche donc jamais en production — et
/// c'est correct, pas une régression. Le jour où AVI existera, une seule ligne
/// de composition changera dans `backend/api`.
#[derive(Debug, Clone, Copy, Default)]
pub struct AucunLitige;

#[async_trait]
impl LitigesOuverts for AucunLitige {
    async fn litiges_du_coursier(&self, _coursier: Uuid) -> Result<Vec<LitigeVu>, ErreurCoursier> {
        Ok(Vec::new())
    }
}

/// Double de test : litiges posés d'avance, par coursier.
#[derive(Debug, Default)]
pub struct LitigesFixes {
    litiges: Mutex<HashMap<Uuid, Vec<LitigeVu>>>,
}

impl LitigesFixes {
    /// Nouveau double : aucun litige.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Pose les litiges d'un coursier.
    pub fn definir(&self, coursier: Uuid, litiges: Vec<LitigeVu>) {
        self.litiges
            .lock()
            .expect("litiges")
            .insert(coursier, litiges);
    }
}

#[async_trait]
impl LitigesOuverts for LitigesFixes {
    async fn litiges_du_coursier(&self, coursier: Uuid) -> Result<Vec<LitigeVu>, ErreurCoursier> {
        Ok(self
            .litiges
            .lock()
            .expect("litiges")
            .get(&coursier)
            .cloned()
            .unwrap_or_default())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;

    /// Le double par défaut ne ment pas : il rend vide parce que c'est vrai.
    #[tokio::test]
    async fn aucun_litige_rend_vide_pour_tout_le_monde() {
        let port = AucunLitige;
        assert!(port
            .litiges_du_coursier(Uuid::now_v7())
            .await
            .unwrap()
            .is_empty());
    }

    #[tokio::test]
    async fn litiges_fixes_rendent_ce_qu_on_y_pose() {
        let coursier = Uuid::now_v7();
        let doubles = LitigesFixes::nouveau();
        assert!(doubles
            .litiges_du_coursier(coursier)
            .await
            .unwrap()
            .is_empty());
        doubles.definir(
            coursier,
            vec![LitigeVu {
                id: Uuid::now_v7(),
                commande_id: Uuid::now_v7(),
                reference: "#405".to_owned(),
                etat_cle: "coursier.litige.en_examen".to_owned(),
                montant_unites: 500,
                ouvert_le: Utc::now(),
            }],
        );
        let vus = doubles.litiges_du_coursier(coursier).await.unwrap();
        assert_eq!(vus.len(), 1);
        assert_eq!(vus[0].reference, "#405");
    }
}
