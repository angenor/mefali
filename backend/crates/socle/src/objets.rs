//! Port de stockage objet (Garage/S3) — capacité TECHNIQUE transverse.
//!
//! Défini au cycle 003 dans le domaine `comptes`, repris ici au cycle 005
//! (specs/005 research R1) : le stockage objet n'est pas un concept du domaine
//! comptes, et `prestataires` (photos de fiche et d'articles, charte signée)
//! le consomme désormais aussi. `comptes` ré-exporte ces types — son API
//! publique n'a pas bougé.
//!
//! L'impl RÉELLE (`S3Objets`, aws-sdk-s3 sur Garage) vit dans la couche `api`
//! (composition racine) ; [`MemoireObjets`] rend les parcours testables sans
//! réseau.

use std::collections::HashMap;
use std::sync::Mutex;
use std::time::Duration;

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Échec d'accès au stockage objet (Garage/S3).
#[derive(Debug, thiserror::Error)]
#[error("stockage objet : {0}")]
pub struct ErreurObjets(pub String);

/// URL présignée de lecture d'un objet privé, à durée courte (10 min).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UrlPresignee {
    /// URL opaque, directement consommable par le client.
    pub url: String,
    /// Expiration — au-delà, l'URL ne vaut plus rien.
    pub expire_le: DateTime<Utc>,
}

/// Stockage objet privé. Les octets ENTRANTS passent par l'API (validation
/// taille/type/appartenance côté serveur, bucket jamais public) ; les lectures
/// sortent en URL présignée derrière un endpoint contrôlé (cycle 003 R7 —
/// écart au principe VIII documenté par les plans des cycles consommateurs).
#[async_trait]
pub trait DepotObjets: Send + Sync {
    /// Dépose un objet sous `cle` (écrase si la clé existe).
    async fn deposer(&self, cle: &str, octets: Vec<u8>, mime: &str) -> Result<(), ErreurObjets>;

    /// Émet une URL de lecture présignée valable `ttl`.
    async fn presigner_get(&self, cle: &str, ttl: Duration) -> Result<UrlPresignee, ErreurObjets>;

    /// Supprime un objet. Idempotent : supprimer une clé absente réussit —
    /// la purge rejoue sans état, et le rattrapage d'un échec S3 ne doit pas
    /// se transformer en erreur au passage suivant.
    async fn supprimer(&self, cle: &str) -> Result<(), ErreurObjets>;
}

/// [`DepotObjets`] en mémoire — vérifie que les octets déposés ressortent
/// À L'IDENTIQUE et que la purge supprime bien l'objet, sans Garage.
#[derive(Debug, Default)]
pub struct MemoireObjets {
    objets: Mutex<HashMap<String, (Vec<u8>, String)>>,
}

impl MemoireObjets {
    /// Stockage vide.
    pub fn new() -> Self {
        Self::default()
    }

    /// Octets stockés sous `cle`, ou `None` si absente/supprimée.
    pub fn lire(&self, cle: &str) -> Option<Vec<u8>> {
        self.objets
            .lock()
            .expect("objets")
            .get(cle)
            .map(|(octets, _)| octets.clone())
    }

    /// Nombre d'objets stockés.
    pub fn nombre(&self) -> usize {
        self.objets.lock().expect("objets").len()
    }
}

#[async_trait]
impl DepotObjets for MemoireObjets {
    async fn deposer(&self, cle: &str, octets: Vec<u8>, mime: &str) -> Result<(), ErreurObjets> {
        self.objets
            .lock()
            .expect("objets")
            .insert(cle.to_owned(), (octets, mime.to_owned()));
        Ok(())
    }

    async fn presigner_get(&self, cle: &str, ttl: Duration) -> Result<UrlPresignee, ErreurObjets> {
        if !self.objets.lock().expect("objets").contains_key(cle) {
            return Err(ErreurObjets(format!("objet absent : {cle}")));
        }
        Ok(UrlPresignee {
            url: format!("memoire://{cle}"),
            expire_le: Utc::now() + chrono::Duration::from_std(ttl).expect("ttl"),
        })
    }

    async fn supprimer(&self, cle: &str) -> Result<(), ErreurObjets> {
        self.objets.lock().expect("objets").remove(cle);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Le double mémoire est la base des tests de médias des cycles 003/005 :
    /// si sa sémantique diverge de S3 (restitution à l'identique, DELETE
    /// idempotent), ces tests-là ne prouvent plus rien.
    #[tokio::test]
    async fn objets_restitues_a_l_identique_et_suppression_idempotente() {
        let depot = MemoireObjets::new();
        let octets = vec![0xDE, 0xAD, 0xBE, 0xEF];
        depot
            .deposer("comptes/reperes/c/1", octets.clone(), "audio/mp4")
            .await
            .unwrap();

        assert_eq!(depot.lire("comptes/reperes/c/1"), Some(octets));
        assert!(depot
            .presigner_get("comptes/reperes/c/1", Duration::from_secs(600))
            .await
            .is_ok());

        depot.supprimer("comptes/reperes/c/1").await.unwrap();
        assert_eq!(depot.lire("comptes/reperes/c/1"), None);
        assert!(
            depot.supprimer("comptes/reperes/c/1").await.is_ok(),
            "supprimer une clé absente réussit"
        );
        assert!(
            depot
                .presigner_get("comptes/reperes/c/1", Duration::from_secs(600))
                .await
                .is_err(),
            "aucune URL pour un objet purgé"
        );
    }
}
