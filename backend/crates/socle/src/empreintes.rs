//! Empreintes de secrets à usage unique (sha256), partagées par les domaines.
//!
//! **Pourquoi ici et pas dans `qr`** : ces deux fonctions ont été écrites au
//! cycle QRC 006 pour le pré-provisionnement hors-ligne du coursier. Le cycle
//! CMD 008 en a besoin pour les secrets de remise (code à 4 chiffres, jeton de
//! réception — research R6), or `qr` dépend DÉJÀ de `commandes` : l'inverse
//! serait un cycle de dépendances, que Cargo refuse. Les remonter dans `socle`
//! — le seul crate dont tout le monde dépend — donne **une** implémentation
//! pour deux consommateurs, plutôt qu'une copie qui divergerait.
//! `qr::verification` les ré-exporte : ses appelants n'ont rien à changer.
//!
//! Le secret en clair ne quitte jamais le serveur ; c'est l'empreinte qui est
//! pré-provisionnée sur l'appareil du coursier, ce qui lui permet de vérifier
//! **hors ligne** sans jamais connaître le secret (CRS-04).

use sha2::{Digest, Sha256};
use uuid::Uuid;

/// base16(sha256(jeton)) — empreinte publique d'un jeton pour un match hors ligne.
///
/// Le jeton est déjà un aléa long : aucun sel n'est nécessaire pour le
/// protéger d'une table arc-en-ciel.
pub fn empreinte_jeton(jeton: &str) -> String {
    hex(&Sha256::digest(jeton.as_bytes()))
}

/// base16(sha256(sel ‖ code)) — empreinte SALÉE d'un code court.
///
/// Le sel est l'UUID de l'entité porteuse (le prestataire pour un code de
/// secours de plaque, la commande pour un code de remise) : sans lui, un code
/// à 4 chiffres se retrouverait en 10 000 essais hors ligne, et une même
/// empreinte trahirait deux entités portant le même code.
pub fn empreinte_code(sel: Uuid, code: &str) -> String {
    let mut h = Sha256::new();
    h.update(sel.as_bytes());
    h.update(code.as_bytes());
    hex(&h.finalize())
}

/// Encodage hexadécimal minuscule.
fn hex(octets: &[u8]) -> String {
    octets.iter().map(|o| format!("{o:02x}")).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empreinte_jeton_stable_et_hexa() {
        let a = empreinte_jeton("abc");
        assert_eq!(a.len(), 64);
        assert!(a.chars().all(|c| c.is_ascii_hexdigit()));
        assert_eq!(a, empreinte_jeton("abc"), "déterministe");
        assert_ne!(a, empreinte_jeton("abd"));
    }

    #[test]
    fn empreinte_code_salee_par_entite() {
        let e1 = Uuid::now_v7();
        let e2 = Uuid::now_v7();
        assert_ne!(
            empreinte_code(e1, "1234"),
            empreinte_code(e2, "1234"),
            "le même code chez deux entités ne donne PAS la même empreinte",
        );
        assert_eq!(empreinte_code(e1, "1234"), empreinte_code(e1, "1234"));
    }
}
