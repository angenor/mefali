//! Client de routage OSRM `/table`, cache par tronçon et **mode dégradé**
//! (US2 — T014/T015/T016, research R2/R3, constitution IV).

use async_trait::async_trait;

use crate::modele::{ErreurRoutage, Matrice, Point};
use crate::ports::Routage;

/// Routage TOUJOURS indisponible.
///
/// Double de test du mode dégradé (quickstart, SC-003) **et** repli de
/// composition tant qu'aucun serveur OSRM n'est configuré : le service tarife
/// alors en vol d'oiseau × facteur de zone, `degraded=true` journalisé — il ne
/// refuse jamais de tarifer (constitution IV).
#[derive(Debug, Default, Clone, Copy)]
pub struct RoutageIndisponible;

#[async_trait]
impl Routage for RoutageIndisponible {
    async fn matrice(&self, _points: &[Point]) -> Result<Matrice, ErreurRoutage> {
        Err(ErreurRoutage::Indisponible(
            "aucun service de routage configuré".to_owned(),
        ))
    }
}
