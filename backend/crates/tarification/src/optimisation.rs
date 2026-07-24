//! Optimisation de l'ordre des arrêts : permutations exhaustives ≤ 4,
//! heuristique bornée au-delà (US2 — T017, research R6, FR-031).
//!
//! Objectif : **minimiser la distance routière totale** retraits → client.
//! L'origine est le **premier retrait**, pas le coursier — le devis client est
//! produit AVANT dispatch (CMD-01/TRF-03/A3, research R11) ; la jambe
//! d'approche du coursier relève de DSP.
//!
//! Le résultat est **déterministe et rejouable** : à distance égale, l'ordre
//! lexicographiquement le plus petit gagne. Deux évaluations des mêmes points
//! rendent le même itinéraire, donc le même prix.
//!
//! Au-delà de 4 retraits, l'ordre retenu **n'est pas garanti optimal** et le dit
//! ([`Itineraire::exhaustif`] = `false`) — jamais un ordre sous-optimal présenté
//! comme optimal (FR-031).

use crate::modele::{Itineraire, Matrice, Troncon};

/// Nombre de retraits jusqu'auquel l'énumération EXHAUSTIVE reste raisonnable.
/// 4! = 24 ordres évalués en mémoire sur une matrice déjà chargée (research R6).
pub const RETRAITS_EXHAUSTIF_MAX: usize = 4;

/// Calcule l'itinéraire d'un ordre donné, sur une matrice où les indices
/// `0..nb_retraits` sont les retraits et le DERNIER point la destination client.
fn parcourir(matrice: &Matrice, ordre: &[usize]) -> (i64, i64, Vec<Troncon>) {
    let client = matrice.taille() - 1;
    let mut troncons = Vec::with_capacity(ordre.len());
    let (mut distance, mut duree) = (0i64, 0i64);
    for paire in ordre.windows(2) {
        let t = matrice.troncon(paire[0], paire[1]);
        distance += t.distance_m;
        duree += t.duree_s;
        troncons.push(t);
    }
    if let Some(&dernier) = ordre.last() {
        let t = matrice.troncon(dernier, client);
        distance += t.distance_m;
        duree += t.duree_s;
        troncons.push(t);
    }
    (distance, duree, troncons)
}

/// Toutes les permutations de `0..n`, en ordre **lexicographique**.
///
/// L'ordre d'énumération EST le départage : le premier optimum rencontré gagne,
/// donc c'est toujours le plus petit lexicographiquement — un départage
/// arbitraire mais reproductible, ce qu'exige un devis rejouable.
fn permutations(n: usize) -> Vec<Vec<usize>> {
    fn recurser(restants: &mut Vec<usize>, courant: &mut Vec<usize>, sortie: &mut Vec<Vec<usize>>) {
        if restants.is_empty() {
            sortie.push(courant.clone());
            return;
        }
        for i in 0..restants.len() {
            let valeur = restants.remove(i);
            courant.push(valeur);
            recurser(restants, courant, sortie);
            courant.pop();
            restants.insert(i, valeur);
        }
    }
    let mut restants: Vec<usize> = (0..n).collect();
    let mut sortie = Vec::new();
    recurser(&mut restants, &mut Vec::new(), &mut sortie);
    sortie
}

/// Heuristique bornée pour > 4 retraits : plus proche voisin depuis **chaque**
/// départ possible, puis amélioration 2-opt ; le meilleur des essais gagne.
///
/// Bornée et déterministe (aucun aléa, aucune limite de temps) — mais jamais
/// présentée comme exhaustive.
fn heuristique(matrice: &Matrice, nb_retraits: usize) -> Vec<usize> {
    let mut meilleur: Option<(i64, Vec<usize>)> = None;

    for depart in 0..nb_retraits {
        // Plus proche voisin.
        let mut visites = vec![false; nb_retraits];
        let mut ordre = Vec::with_capacity(nb_retraits);
        let mut courant = depart;
        visites[depart] = true;
        ordre.push(depart);
        while ordre.len() < nb_retraits {
            let suivant = (0..nb_retraits)
                .filter(|i| !visites[*i])
                // Clé (distance, indice) : à distance égale, le plus petit
                // indice — sans quoi l'ordre dépendrait de l'itération.
                .min_by_key(|i| (matrice.troncon(courant, *i).distance_m, *i))
                .expect("au moins un arrêt non visité");
            visites[suivant] = true;
            ordre.push(suivant);
            courant = suivant;
        }

        // 2-opt : inverse un segment tant que la distance totale baisse.
        let mut distance = parcourir(matrice, &ordre).0;
        let mut ameliore = true;
        while ameliore {
            ameliore = false;
            for i in 0..ordre.len().saturating_sub(1) {
                for j in (i + 1)..ordre.len() {
                    let mut essai = ordre.clone();
                    essai[i..=j].reverse();
                    let candidate = parcourir(matrice, &essai).0;
                    if candidate < distance {
                        ordre = essai;
                        distance = candidate;
                        ameliore = true;
                    }
                }
            }
        }

        // `<` strict : à égalité on garde le premier essai (départ le plus
        // petit), ce qui rend le résultat reproductible.
        if meilleur.as_ref().is_none_or(|(d, _)| distance < *d) {
            meilleur = Some((distance, ordre));
        }
    }
    meilleur.map(|(_, ordre)| ordre).unwrap_or_default()
}

/// Ordre de passage minimisant la distance routière totale retraits → client.
///
/// `matrice` couvre `nb_retraits + 1` points : les retraits d'abord, la
/// destination client en DERNIER.
///
/// `troncons` de l'itinéraire rendu : un par jambe, dans l'ordre — les
/// `nb_retraits − 1` premiers relient deux retraits consécutifs (matière du
/// barème de supplément d'arrêt, FR-029), le dernier va du dernier retrait au
/// client (jambe de livraison, jamais un « arrêt supplémentaire »).
pub fn optimiser(matrice: &Matrice, nb_retraits: usize) -> Itineraire {
    debug_assert_eq!(
        matrice.taille(),
        nb_retraits + 1,
        "la matrice couvre les retraits ET le client"
    );
    let exhaustif = nb_retraits <= RETRAITS_EXHAUSTIF_MAX;
    let ordre = if exhaustif {
        let mut meilleur: Option<(i64, Vec<usize>)> = None;
        for candidat in permutations(nb_retraits) {
            let distance = parcourir(matrice, &candidat).0;
            if meilleur.as_ref().is_none_or(|(d, _)| distance < *d) {
                meilleur = Some((distance, candidat));
            }
        }
        meilleur.map(|(_, o)| o).unwrap_or_default()
    } else {
        heuristique(matrice, nb_retraits)
    };

    let (distance_m, eta_s, troncons) = parcourir(matrice, &ordre);
    Itineraire {
        ordre,
        distance_m,
        eta_s,
        degraded: matrice.degraded,
        troncons,
        exhaustif,
    }
}

/// Détour imputable au multi-arrêts : distance totale − trajet direct du
/// **premier retrait retenu** vers le client (FR-032).
///
/// Un retrait unique donne donc toujours 0 : il n'y a rien à scinder. C'est ce
/// détour, et non la distance brute, que compare le plafond d'éclatement — sans
/// quoi une simple course longue déclencherait une proposition de scission qui
/// n'aurait aucun sens.
pub fn detour_m(matrice: &Matrice, itineraire: &Itineraire) -> i64 {
    let Some(&premier) = itineraire.ordre.first() else {
        return 0;
    };
    let client = matrice.taille() - 1;
    (itineraire.distance_m - matrice.troncon(premier, client).distance_m).max(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Matrice symétrique construite depuis des positions sur une ligne (les
    /// « distances » sont alors trivialement vérifiables à la main).
    fn matrice_ligne(positions: &[i64]) -> Matrice {
        let n = positions.len();
        let mut d = vec![0i64; n * n];
        let mut t = vec![0i64; n * n];
        for i in 0..n {
            for j in 0..n {
                d[i * n + j] = (positions[i] - positions[j]).abs();
                t[i * n + j] = d[i * n + j] / 5;
            }
        }
        Matrice::nouvelle(n, d, t, false).unwrap()
    }

    #[test]
    fn permutations_lexicographiques() {
        assert_eq!(
            permutations(3),
            vec![
                vec![0, 1, 2],
                vec![0, 2, 1],
                vec![1, 0, 2],
                vec![1, 2, 0],
                vec![2, 0, 1],
                vec![2, 1, 0],
            ]
        );
        assert_eq!(permutations(4).len(), 24);
    }

    /// SC-009 — l'ordre retenu est la MEILLEURE permutation, et il est rejouable.
    #[test]
    fn ordre_optimal_et_deterministe() {
        // Retraits à 0, 90, 30, 60 ; client à 100. L'ordre soumis (0,90,30,60)
        // coûte 90+60+30+40 = 220 ; le meilleur est 0→30→60→90→100 = 100.
        let matrice = matrice_ligne(&[0, 90, 30, 60, 100]);
        let itineraire = optimiser(&matrice, 4);
        assert_eq!(itineraire.ordre, vec![0, 2, 3, 1]);
        assert_eq!(itineraire.distance_m, 100);
        assert!(itineraire.exhaustif, "4 retraits → exhaustif");
        assert_eq!(itineraire.troncons.len(), 4, "3 jambes + la livraison");

        // Rejouable : mêmes entrées → même sortie, à l'identique.
        assert_eq!(optimiser(&matrice, 4), itineraire);

        // Et c'est bien le minimum de TOUTES les permutations.
        let minimum = permutations(4)
            .into_iter()
            .map(|o| parcourir(&matrice, &o).0)
            .min()
            .unwrap();
        assert_eq!(itineraire.distance_m, minimum);
    }

    #[test]
    fn retrait_unique() {
        let matrice = matrice_ligne(&[0, 500]);
        let itineraire = optimiser(&matrice, 1);
        assert_eq!(itineraire.ordre, vec![0]);
        assert_eq!(itineraire.distance_m, 500);
        assert_eq!(
            itineraire.troncons.len(),
            1,
            "la seule jambe est la livraison"
        );
        assert_eq!(detour_m(&matrice, &itineraire), 0, "rien à scinder");
    }

    /// Au-delà de 4 retraits l'ordre est heuristique — et le DIT.
    #[test]
    fn au_dela_de_quatre_heuristique_annoncee() {
        let matrice = matrice_ligne(&[0, 90, 30, 60, 45, 100]);
        let itineraire = optimiser(&matrice, 5);
        assert!(!itineraire.exhaustif, "jamais présenté comme optimal");
        assert_eq!(itineraire.ordre.len(), 5);
        assert_eq!(optimiser(&matrice, 5), itineraire, "déterministe");
        // Sur cette géométrie simple, l'heuristique retrouve quand même l'optimum.
        assert_eq!(itineraire.distance_m, 100);
    }

    /// Le détour mesure ce que coûte le multi-arrêts, pas la longueur brute.
    #[test]
    fn detour_mesure_le_surcout_multi_arrets() {
        // Retraits à 0 et 200, client à 100 : direct 0→100 = 100 ; réel
        // 0→200→100 = 300. Détour = 200.
        let matrice = matrice_ligne(&[0, 200, 100]);
        let itineraire = optimiser(&matrice, 2);
        assert_eq!(itineraire.distance_m, 300);
        assert_eq!(detour_m(&matrice, &itineraire), 200);
    }
}
