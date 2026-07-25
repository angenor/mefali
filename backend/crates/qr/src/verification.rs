//! Vérifications pures du scan de collecte (data-model §5, research R3/R4/R6).
//!
//! - **Proximité** : distance grand-cercle (haversine) entre la position
//!   capturée et le site de l'arrêt, comparée au paramètre de zone
//!   `qr.distance_scan_max_m`. C'est une porte de PRÉSENCE anti-fraude, jamais
//!   une distance de trajet (Complexity Tracking — OSRM ne s'applique pas).
//! - **Empreintes** : sha256 du jeton (public) et sha256 du code SALÉ par
//!   l'UUID du prestataire (le code en clair ne quitte jamais le serveur, R6).
//! - **Politique photo** : prestataire > catégorie > seuil de montant (R4).

/// Rayon terrestre moyen (m) — suffisant pour une porte de présence < 100 m.
const RAYON_TERRE_M: f64 = 6_371_000.0;

/// Distance grand-cercle (haversine) en mètres entre deux points GPS.
pub fn distance_grand_cercle_m(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let (p1, p2) = (lat1.to_radians(), lat2.to_radians());
    let dphi = (lat2 - lat1).to_radians();
    let dlambda = (lon2 - lon1).to_radians();
    let a = (dphi / 2.0).sin().powi(2) + p1.cos() * p2.cos() * (dlambda / 2.0).sin().powi(2);
    2.0 * RAYON_TERRE_M * a.sqrt().asin()
}

// Les deux empreintes vivent désormais dans `socle::empreintes` : le cycle CMD
// 008 en a besoin pour les secrets de remise, et `qr` dépend déjà de
// `commandes` — l'inverse serait un cycle de dépendances. Une seule
// implémentation, deux consommateurs ; les appelants d'ici ne changent pas.
//
// `empreinte_code` y prend un « sel » générique là où il s'appelait
// `prestataire_id` : c'est exactement le même argument, nommé pour son rôle.
pub use socle::empreintes::{empreinte_code, empreinte_jeton};

/// Résout l'exigence de photo (R4) : la base prestataire > catégorie est forcée
/// à `obligatoire` si le montant avancé atteint le seuil de zone.
pub fn photo_exigee(politique_base: &str, montant_avance: i64, seuil_montant: i64) -> bool {
    if montant_avance >= seuil_montant {
        return true; // niveau 3 : forçage par montant, quel que soit le niveau au-dessus
    }
    politique_base == "obligatoire"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn proximite_ordre_de_grandeur() {
        // ~30 m d'écart en latitude à Tiassalé.
        let d = distance_grand_cercle_m(5.898_000, -4.823_000, 5.898_270, -4.823_000);
        assert!((25.0..35.0).contains(&d), "≈ 30 m, obtenu {d}");
        // même point → 0.
        assert!(distance_grand_cercle_m(5.9, -4.8, 5.9, -4.8) < 1e-6);
    }

    #[test]
    fn empreinte_jeton_stable_et_hexa() {
        let a = empreinte_jeton("abc");
        assert_eq!(a.len(), 64);
        assert!(a.chars().all(|c| c.is_ascii_hexdigit()));
        assert_eq!(a, empreinte_jeton("abc"));
        assert_ne!(a, empreinte_jeton("abd"));
    }

    #[test]
    fn empreinte_code_salee_par_prestataire() {
        let p1 = uuid::Uuid::now_v7();
        let p2 = uuid::Uuid::now_v7();
        // même code, prestataires différents → empreintes différentes (anti arc-en-ciel).
        assert_ne!(empreinte_code(p1, "1234"), empreinte_code(p2, "1234"));
    }

    #[test]
    fn politique_photo_forcee_par_seuil() {
        assert!(!photo_exigee("facultative", 5_000, 10_000));
        assert!(photo_exigee("obligatoire", 0, 10_000));
        // forçage par montant même si la base est facultative/désactivée.
        assert!(photo_exigee("facultative", 10_000, 10_000));
        assert!(photo_exigee("desactivee", 12_000, 10_000));
        assert!(!photo_exigee("desactivee", 9_999, 10_000));
    }
}
