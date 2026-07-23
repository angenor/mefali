//! Port du compteur d'essais du code dégradé (Redis en prod, R7).
//!
//! Éphémère (constitution II) : `INCR qr:essais:{arret_id}` + TTL. L'impl réelle
//! vit dans `api` (`infra_redis`) ; le double `CompteurMemoire` sert les tests.

use std::collections::HashMap;
use std::sync::Mutex;

use async_trait::async_trait;
use uuid::Uuid;

/// Erreur du compteur d'essais.
#[derive(Debug, thiserror::Error)]
#[error("compteur d'essais : {0}")]
pub struct ErreurCompteur(pub String);

/// Compteur d'essais du code de secours, borné par arrêt (backstop en ligne).
#[async_trait]
pub trait CompteurEssais: Send + Sync {
    /// Incrémente le compteur de l'arrêt et renvoie la NOUVELLE valeur (1 au
    /// premier essai). Pose un TTL à la création (éphémère).
    async fn incrementer_essai(&self, arret_id: Uuid) -> Result<i64, ErreurCompteur>;
}

/// Double de test : compteur en mémoire (sans TTL — la durée du test suffit).
#[derive(Debug, Default)]
pub struct CompteurMemoire {
    essais: Mutex<HashMap<Uuid, i64>>,
}

impl CompteurMemoire {
    /// Nouveau compteur vide.
    pub fn nouveau() -> Self {
        Self::default()
    }
}

#[async_trait]
impl CompteurEssais for CompteurMemoire {
    async fn incrementer_essai(&self, arret_id: Uuid) -> Result<i64, ErreurCompteur> {
        let mut map = self.essais.lock().expect("essais");
        let n = map.entry(arret_id).or_insert(0);
        *n += 1;
        Ok(*n)
    }
}
