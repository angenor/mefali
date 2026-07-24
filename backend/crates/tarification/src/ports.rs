//! Traits exposés par le domaine tarification (data-model.md §5).
//!
//! Deux familles :
//!
//! - **Capacités OFFERTES** aux cycles suivants — [`EvaluationTarifaire`]
//!   (CMD verrouillera le devis, DSP composera l'offre) et
//!   [`OptimisationArrets`] (ordre des arrêts pour DSP/CMD, FR-031). Faute de
//!   ces modules, ce cycle les exerce par des **courses simulées dans les
//!   tests** (patron cycle 006).
//! - **Dépendances INJECTÉES** — [`Routage`] (client OSRM réel en production,
//!   doubles déterministes en test) et [`CacheRoutage`] (Redis en production,
//!   [`CacheMemoire`] en test). Les impls réelles vivent dans la couche `api` :
//!   la composition racine connaît l'infrastructure, le domaine ne connaît que
//!   ses traits (constitution II).
//!
//! **Écart assumé au data-model §5**, dans les deux cas pour préserver
//! « tout paramètre paramétrable vit en configuration de zone » (constitution I) :
//! [`OptimisationArrets::optimiser`] prend la **zone** (elle seule résout le
//! facteur de dégradé et la précision de clé de cache), et le **cache n'est pas
//! dans [`Routage`]** mais composé au-dessus par
//! [`crate::routage::matrice_ou_degrade`] — sans quoi un double compteur
//! d'appels ne pourrait pas prouver qu'un 2ᵉ passage ne rappelle PAS le routage
//! (SC-004).

use std::collections::HashMap;
use std::sync::Mutex;

use async_trait::async_trait;
use uuid::Uuid;

use crate::modele::{
    DemandeDevis, Devis, ErreurRoutage, ErreurTarif, Itineraire, Matrice, Point, SourceGrille,
    Troncon,
};

/// Évaluation tarifaire — consommée par CMD (verrouillage du devis), DSP
/// (offre coursier) et le simulateur admin. Prend la **géométrie**, pas la
/// logistique (research R12).
#[async_trait]
pub trait EvaluationTarifaire: Send + Sync {
    /// Produit le devis figé d'une course, contre la grille en vigueur ou un
    /// brouillon (simulateur).
    async fn evaluer(
        &self,
        demande: DemandeDevis,
        source: SourceGrille,
    ) -> Result<Devis, ErreurTarif>;
}

/// Optimisation de l'ordre des arrêts — **exposée à DSP et CMD** (FR-031).
///
/// `zone` résout le facteur de dégradé et les options de cache (constitution I).
#[async_trait]
pub trait OptimisationArrets: Send + Sync {
    /// Ordre de passage minimisant la **distance routière totale** retraits →
    /// client, de façon **déterministe et rejouable**. Exhaustif jusqu'à
    /// 4 retraits ; au-delà, heuristique bornée signalée par
    /// [`Itineraire::exhaustif`] = `false`.
    async fn optimiser(
        &self,
        zone: Uuid,
        retraits: &[Point],
        client: Point,
    ) -> Result<Itineraire, ErreurTarif>;
}

/// Routage — transport BRUT de la matrice distance/durée (OSRM `/table`, R2).
///
/// Ni cache ni dégradé ici : ils sont composés au-dessus
/// ([`crate::routage::matrice_ou_degrade`]). Une erreur n'est donc jamais
/// fatale — elle déclenche le repli (constitution IV).
#[async_trait]
pub trait Routage: Send + Sync {
    /// Matrice `n × n` des distances/durées routières entre tous les points.
    async fn matrice(&self, points: &[Point]) -> Result<Matrice, ErreurRoutage>;
}

/// Erreur du cache de routage. Jamais fatale : un cache muet coûte un appel de
/// routage, rien de plus (éphémère reconstructible, constitution II).
#[derive(Debug, thiserror::Error)]
#[error("cache de routage : {0}")]
pub struct ErreurCache(pub String);

/// Cache de routage par **tronçon** (paire de points arrondis), TTL de zone.
///
/// Redis en production (`tarif:route:v1:{a}:{b}`, research R3) ; le double
/// [`CacheMemoire`] sert les tests. Le cache par tronçon — et non par course —
/// maximise la réutilisation : deux courses partageant un étal → client
/// réutilisent le tronçon.
#[async_trait]
pub trait CacheRoutage: Send + Sync {
    /// Lit les tronçons de plusieurs clés, dans l'ORDRE des clés fournies
    /// (`None` = absent ou périmé).
    async fn lire(&self, cles: &[String]) -> Result<Vec<Option<Troncon>>, ErreurCache>;

    /// Écrit les tronçons avec le TTL de la zone (secondes).
    async fn ecrire(&self, entrees: &[(String, Troncon)], ttl_s: u64) -> Result<(), ErreurCache>;
}

/// Double de test : cache en mémoire, **sans TTL** — la durée d'un test suffit,
/// et l'expiration réelle est la responsabilité de Redis (`EX`), pas du domaine.
#[derive(Debug, Default)]
pub struct CacheMemoire {
    troncons: Mutex<HashMap<String, Troncon>>,
    /// Nombre d'écritures — laisse un test prouver que le cache a été alimenté.
    ecritures: Mutex<usize>,
}

impl CacheMemoire {
    /// Nouveau cache vide.
    pub fn nouveau() -> Self {
        Self::default()
    }

    /// Nombre d'appels d'écriture reçus.
    pub fn ecritures(&self) -> usize {
        *self.ecritures.lock().expect("ecritures")
    }

    /// Nombre de tronçons mémorisés.
    pub fn taille(&self) -> usize {
        self.troncons.lock().expect("troncons").len()
    }

    /// Vide le cache (simule l'expiration du TTL).
    pub fn vider(&self) {
        self.troncons.lock().expect("troncons").clear();
    }
}

#[async_trait]
impl CacheRoutage for CacheMemoire {
    async fn lire(&self, cles: &[String]) -> Result<Vec<Option<Troncon>>, ErreurCache> {
        let map = self.troncons.lock().expect("troncons");
        Ok(cles.iter().map(|c| map.get(c).copied()).collect())
    }

    async fn ecrire(&self, entrees: &[(String, Troncon)], _ttl_s: u64) -> Result<(), ErreurCache> {
        let mut map = self.troncons.lock().expect("troncons");
        for (cle, troncon) in entrees {
            map.insert(cle.clone(), *troncon);
        }
        *self.ecritures.lock().expect("ecritures") += 1;
        Ok(())
    }
}

/// Cache DÉSACTIVÉ — lit toujours vide et jette les écritures.
///
/// Sert la composition avant que Redis soit câblé, et les tests qui veulent
/// mesurer les appels de routage sans interférence de cache.
#[derive(Debug, Default, Clone, Copy)]
pub struct CacheDesactive;

#[async_trait]
impl CacheRoutage for CacheDesactive {
    async fn lire(&self, cles: &[String]) -> Result<Vec<Option<Troncon>>, ErreurCache> {
        Ok(vec![None; cles.len()])
    }

    async fn ecrire(&self, _entrees: &[(String, Troncon)], _ttl_s: u64) -> Result<(), ErreurCache> {
        Ok(())
    }
}
