//! Implémentation RÉELLE du port [`ProximiteRoutiere`] au-dessus du moteur de
//! routage du cycle 007 (research R5, constitution IV).
//!
//! Vit dans la couche `api` — la composition racine connaît l'infrastructure, le
//! crate `dispatch` ne connaît que son trait (constitution II).
//!
//! **Une seule matrice par évaluation, jamais un appel par candidat.** FR-035
//! interdit « un calcul de routage par candidat » ; il n'interdit pas un appel
//! groupé, et `tarification::routage::matrice_ou_degrade` est justement conçue
//! pour ça : une requête OSRM `/table` pour tous les points, cache par tronçon
//! compris.
//!
//! **Jamais d'erreur.** La fonction rend TOUJOURS une matrice : si OSRM est
//! muet, elle retombe sur le vol d'oiseau × facteur de zone, `degraded=true`
//! journalisé. Une commande n'est jamais bloquée par le routage — c'est
//! exactement ce que la signature du port impose (`-> Trajets`, sans `Result`).
//!
//! **Pourquoi ne pas lire le cache seul.** Ce serait conforme à la lettre la
//! plus stricte de FR-035, mais mettrait le produit en dégradé quasi permanent
//! sur son classement principal : le cache tarifaire ne réchauffe que les
//! tronçons vendeur→vendeur et vendeur→client, jamais coursier→vendeur.

use async_trait::async_trait;
use dispatch::{ProximiteRoutiere, Trajet, Trajets};
use tarification::{
    routage::matrice_ou_degrade, CacheRoutage, Matrice, PgTarification, Point, Routage,
};
use uuid::Uuid;

/// Proximité routière au-dessus du moteur de routage partagé.
///
/// La zone arrive en PARAMÈTRE d'appel, pas en champ : le facteur de dégradé, la
/// vitesse d'estimation et les options de cache sont des **paramètres de zone**
/// (constitution I), et un dispatch multi-villes partage le même client OSRM
/// sans partager ses réglages.
pub struct ProximiteTarification {
    tarification: PgTarification,
    routage: std::sync::Arc<dyn Routage>,
    cache: std::sync::Arc<dyn CacheRoutage>,
}

impl ProximiteTarification {
    /// Compose la proximité au-dessus du moteur de routage.
    pub fn nouvelle(
        tarification: PgTarification,
        routage: std::sync::Arc<dyn Routage>,
        cache: std::sync::Arc<dyn CacheRoutage>,
    ) -> Self {
        Self {
            tarification,
            routage,
            cache,
        }
    }

    /// **UNE** matrice `n×n` pour ces points, jamais d'erreur.
    ///
    /// Les deux mesures du port passent par ici : c'est le seul endroit où le
    /// routage est appelé, donc le seul endroit à relire pour savoir combien
    /// d'appels une évaluation coûte.
    async fn matrice_de_zone(&self, zone: Uuid, points: &[Point]) -> Matrice {
        // Les réglages de dégradé et de cache viennent de la zone. Si la
        // configuration est illisible, on prend les défauts du moteur plutôt que
        // de renoncer à classer : un classement dégradé vaut mieux qu'aucune
        // offre (constitution IV).
        let knobs = self.tarification.knobs(zone).await.ok();
        let (facteur, vitesse, options) = match &knobs {
            Some(k) => (k.facteur_degrade, k.vitesse_degradee_kmh, k.cache),
            None => {
                tracing::warn!(
                    zone = %zone,
                    "réglages de routage illisibles — dégradé aux défauts du moteur",
                );
                (
                    tarification::depot::defauts::FACTEUR_DEGRADE,
                    tarification::depot::defauts::VITESSE_DEGRADEE_KMH,
                    tarification::OptionsCache {
                        ttl_s: tarification::depot::defauts::CACHE_TTL_H as u64 * 3_600,
                        decimales: tarification::depot::defauts::ARRONDI_CLE_DECIMALES,
                    },
                )
            }
        };

        let matrice = matrice_ou_degrade(
            self.routage.as_ref(),
            self.cache.as_ref(),
            points,
            options,
            facteur,
            vitesse,
        )
        .await;

        if matrice.degraded {
            tracing::warn!(
                zone = %zone,
                nb_points = points.len(),
                facteur,
                "proximité de dispatch en DÉGRADÉ vol d'oiseau (jamais bloquant)",
            );
        }
        matrice
    }
}

#[async_trait]
impl ProximiteRoutiere for ProximiteTarification {
    async fn vers_point(&self, zone: Uuid, origines: &[Point], destination: Point) -> Trajets {
        if origines.is_empty() {
            return Trajets {
                trajets: Vec::new(),
                degraded: false,
            };
        }

        // UNE matrice pour tous les candidats : `[origines…, destination]`.
        // L'index de la destination est le dernier ; chaque origine lit sa
        // cellule `(i, destination)`.
        let mut points: Vec<Point> = origines.to_vec();
        points.push(destination);
        let index_destination = points.len() - 1;

        let matrice = self.matrice_de_zone(zone, &points).await;

        Trajets {
            trajets: (0..index_destination)
                .map(|i| {
                    let troncon = matrice.troncon(i, index_destination);
                    Trajet {
                        distance_m: troncon.distance_m,
                        duree_s: troncon.duree_s,
                    }
                })
                .collect(),
            degraded: matrice.degraded,
        }
    }

    async fn troncons_consecutifs(&self, zone: Uuid, points: &[Point]) -> Trajets {
        if points.len() < 2 {
            return Trajets {
                trajets: Vec::new(),
                degraded: false,
            };
        }

        // UNE matrice pour tout l'itinéraire : on n'en lit que la diagonale
        // adjacente `(i, i+1)`, mais `/table` la rend d'un seul aller-retour.
        // Un appel par tronçon coûterait `n-1` requêtes de routage sur le chemin
        // qui prépare l'écran d'offre.
        let matrice = self.matrice_de_zone(zone, points).await;

        Trajets {
            trajets: (0..points.len() - 1)
                .map(|i| {
                    let troncon = matrice.troncon(i, i + 1);
                    Trajet {
                        distance_m: troncon.distance_m,
                        duree_s: troncon.duree_s,
                    }
                })
                .collect(),
            degraded: matrice.degraded,
        }
    }
}
