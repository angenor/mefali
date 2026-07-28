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
        colonne_vers(&matrice, index_destination)
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
        diagonale_adjacente(&matrice)
    }
}

/// Trajets `i → destination` pour chaque origine — la COLONNE de la matrice.
///
/// Extraite pour être testable : jusqu'ici seul le double de port était
/// exercé, et l'implémentation réelle — celle qui décide du classement des
/// candidats — ne l'était par aucun test.
fn colonne_vers(matrice: &Matrice, destination: usize) -> Trajets {
    Trajets {
        trajets: (0..destination)
            .map(|i| {
                let troncon = matrice.troncon(i, destination);
                Trajet {
                    distance_m: troncon.distance_m,
                    duree_s: troncon.duree_s,
                }
            })
            .collect(),
        degraded: matrice.degraded,
    }
}

/// Trajets `i → i+1` le long de l'itinéraire — la DIAGONALE adjacente.
///
/// ⚠ Le sens compte : `troncon(i, i+1)`, jamais `troncon(i+1, i)`. Un réseau
/// routier n'est pas symétrique (sens uniques), et l'inversion afficherait à Yao
/// la distance du retour. Elle passerait inaperçue en dégradé vol d'oiseau, où
/// la matrice EST symétrique — d'où le test sur une matrice asymétrique.
fn diagonale_adjacente(matrice: &Matrice) -> Trajets {
    Trajets {
        trajets: (0..matrice.taille().saturating_sub(1))
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

#[cfg(test)]
mod tests_lecture_matrice {
    use super::*;

    /// Matrice 3×3 volontairement ASYMÉTRIQUE : `d(i,j) = 100·i + j`.
    ///
    /// C'est ce qui distingue `troncon(i, i+1)` de `troncon(i+1, i)` — en
    /// dégradé vol d'oiseau les deux seraient égaux, et une inversion du sens
    /// resterait invisible.
    fn matrice_asymetrique() -> Matrice {
        let mut distances = Vec::new();
        let mut durees = Vec::new();
        for i in 0..3i64 {
            for j in 0..3i64 {
                distances.push(100 * i + j);
                durees.push(10 * i + j);
            }
        }
        Matrice::nouvelle(3, distances, durees, false).expect("matrice 3×3")
    }

    #[test]
    fn la_diagonale_adjacente_lit_le_sens_de_la_marche() {
        let trajets = diagonale_adjacente(&matrice_asymetrique());
        assert_eq!(trajets.trajets.len(), 2, "n points ⇒ n−1 tronçons");
        // 0 → 1 puis 1 → 2, et surtout PAS 1 → 0 (100) ni 2 → 1 (201).
        assert_eq!(trajets.trajets[0].distance_m, 1);
        assert_eq!(trajets.trajets[1].distance_m, 102);
        assert_eq!(trajets.trajets[0].duree_s, 1);
        assert_eq!(trajets.trajets[1].duree_s, 12);
    }

    #[test]
    fn la_colonne_lit_chaque_origine_vers_la_destination() {
        let trajets = colonne_vers(&matrice_asymetrique(), 2);
        assert_eq!(trajets.trajets.len(), 2, "la destination n'est pas une origine");
        // 0 → 2 puis 1 → 2, et surtout PAS 2 → 0 (200) ni 2 → 1 (201).
        assert_eq!(trajets.trajets[0].distance_m, 2);
        assert_eq!(trajets.trajets[1].distance_m, 102);
    }

    /// Le dégradé se propage : l'écran doit pouvoir dire « distances estimées ».
    #[test]
    fn le_degrade_de_la_matrice_se_propage_aux_trajets() {
        let matrice = Matrice::nouvelle(2, vec![0, 500, 500, 0], vec![0, 60, 60, 0], true)
            .expect("matrice 2×2");
        assert!(diagonale_adjacente(&matrice).degraded);
        assert!(colonne_vers(&matrice, 1).degraded);
    }
}
