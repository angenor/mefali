//! Cycle de vie d'une grille tarifaire : brouillon, simulation, publication
//! (US1/US3, research R7).
//!
//! La **garde de publication** est ici, et nulle part ailleurs : publier exige
//! une simulation portant sur l'**empreinte courante** du brouillon ET aucune
//! règle hors bornes (FR-021). Toute édition de règle change l'empreinte, donc
//! **réarme** l'obligation — « ce qui est simulé est ce qui sera publié ».

use sha2::{Digest, Sha256};

use crate::modele::Regle;

/// Empreinte SHA-256 du CONTENU tarifaire d'une grille.
///
/// Déterministe : les règles sont triées par `id` (UUIDv7, ordre stable) et
/// chaque champ qui influence un prix entre dans le condensé. Les champs
/// purement techniques (`grille_id`) en sont exclus — cloner un brouillon ne
/// doit pas invalider une simulation portant sur un contenu identique.
///
/// `actif` est inclus : désactiver une règle change ce qui sera facturé.
pub fn empreinte(regles: &[Regle]) -> String {
    let mut triees: Vec<&Regle> = regles.iter().collect();
    triees.sort_by_key(|r| r.id);

    let mut hacheur = Sha256::new();
    hacheur.update(b"tarification.grille.v1");
    for r in triees {
        // Séparateurs explicites : sans eux, deux champs adjacents pourraient se
        // « décaler » et deux grilles distinctes partager une empreinte.
        hacheur.update(r.id.as_bytes());
        hacheur.update(b"|");
        hacheur.update(r.transport_slug.as_bytes());
        hacheur.update(b"|");
        hacheur.update(r.categorie_slug.as_deref().unwrap_or("*").as_bytes());
        hacheur.update(b"|");
        for entier in [
            r.distance_min_m as i64,
            r.distance_max_m.map_or(-1, i64::from),
            r.plage_debut_min.map_or(-1, i64::from),
            r.plage_fin_min.map_or(-1, i64::from),
            r.jours_masque.map_or(-1, i64::from),
            r.part_coursier_base,
            r.marge,
            r.prix_par_km,
            r.seuil_km_m as i64,
            r.prix_plafond.unwrap_or(-1),
            r.priorite as i64,
            i64::from(r.actif),
        ] {
            hacheur.update(entier.to_be_bytes());
            hacheur.update(b",");
        }
        hacheur.update(r.devise.as_bytes());
        hacheur.update(b";");
    }
    hex(&hacheur.finalize())
}

/// base16 minuscule (patron `qr::verification` / `comptes::session` — sha2 0.11
/// rend un `Array`, qui n'implémente pas `LowerHex`).
fn hex(octets: &[u8]) -> String {
    use std::fmt::Write;
    let mut s = String::with_capacity(octets.len() * 2);
    for o in octets {
        write!(s, "{o:02x}").expect("écriture en mémoire");
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    fn regle(id: Uuid, marge: i64) -> Regle {
        Regle {
            id,
            grille_id: Uuid::now_v7(),
            transport_slug: "moto".to_owned(),
            categorie_slug: None,
            distance_min_m: 0,
            distance_max_m: None,
            plage_debut_min: None,
            plage_fin_min: None,
            jours_masque: None,
            point_relais_id: None,
            part_coursier_base: 150,
            marge,
            prix_par_km: 50,
            seuil_km_m: 2000,
            prix_plafond: Some(500),
            devise: "XOF".to_owned(),
            priorite: 0,
            actif: true,
        }
    }

    /// L'empreinte ne dépend NI de l'ordre de lecture NI de la grille porteuse :
    /// sans cela, cloner la grille en vigueur en brouillon invaliderait une
    /// simulation portant sur un contenu strictement identique.
    #[test]
    fn empreinte_stable_par_contenu() {
        let (a, b) = (Uuid::now_v7(), Uuid::now_v7());
        let ordre_un = vec![regle(a, 50), regle(b, 60)];
        let mut ordre_deux = vec![regle(b, 60), regle(a, 50)];
        ordre_deux[0].grille_id = Uuid::now_v7();
        assert_eq!(empreinte(&ordre_un), empreinte(&ordre_deux));
    }

    /// Toute édition tarifaire change l'empreinte — c'est ce qui RÉARME la garde
    /// de publication (FR-021).
    #[test]
    fn empreinte_change_a_chaque_edition() {
        let id = Uuid::now_v7();
        let base = vec![regle(id, 50)];
        let reference = empreinte(&base);

        let mut marge_modifiee = base.clone();
        marge_modifiee[0].marge = 60;
        assert_ne!(reference, empreinte(&marge_modifiee), "marge");

        let mut desactivee = base.clone();
        desactivee[0].actif = false;
        assert_ne!(reference, empreinte(&desactivee), "actif");

        let mut plafond_retire = base.clone();
        plafond_retire[0].prix_plafond = None;
        assert_ne!(reference, empreinte(&plafond_retire), "plafond");

        let mut ajout = base.clone();
        ajout.push(regle(Uuid::now_v7(), 50));
        assert_ne!(reference, empreinte(&ajout), "règle ajoutée");

        assert_ne!(reference, empreinte(&[]), "brouillon vidé");
    }
}
