//! Identité de plaque : jeton signé HMAC et code de secours (FR-013..016,
//! research R2).
//!
//! Le jeton est GÉNÉRÉ au premier agrément, STOCKÉ sur la ligne, et JAMAIS
//! modifié ensuite — la suspension le rend invalide PAR DÉRIVATION (la
//! validité EST `statut = agree`), le rétablissement lui rend sa validité sans
//! changer sa valeur : la plaque physique reste en place (SC-003). La
//! signature HMAC (clé `PLAQUE_SECRET`) reste vérifiable hors base — c'est ce
//! que le cycle QRC exploitera pour le pré-provisionnement hors-ligne.

use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;
use uuid::Uuid;

use crate::depot::PgPrestataires;
use crate::modele::{ErreurPrestataires, ResolutionPlaque};

type HmacSha256 = Hmac<Sha256>;

/// Jeton de plaque : hex(uuid ‖ nonce₈ ‖ hmac₁₆) — 80 caractères sûrs en URL,
/// auto-porteur (le préfixe identifie le prestataire, la signature l'atteste).
pub(crate) fn generer_jeton(secret: &[u8], prestataire: Uuid) -> String {
    let mut nonce = [0u8; 8];
    rand::fill(&mut nonce);
    let mut mac = <HmacSha256 as KeyInit>::new_from_slice(secret)
        .expect("toute longueur de clé est admise par HMAC");
    mac.update(b"plaque:");
    mac.update(prestataire.as_bytes());
    mac.update(&nonce);
    let tag = mac.finalize().into_bytes();

    let mut jeton = String::with_capacity(80);
    pousser_hex(&mut jeton, prestataire.as_bytes());
    pousser_hex(&mut jeton, &nonce);
    pousser_hex(&mut jeton, &tag[..16]);
    jeton
}

/// Code de secours : 4 chiffres tirés uniformément (FR-014). PAS un
/// identifiant global — comparé LOCALEMENT au prestataire attendu (QRC-04) ;
/// aucune unicité requise, aucune recherche par ce code n'existe.
pub(crate) fn generer_code_secours() -> String {
    format!("{:04}", rand::random_range(0..10_000u32))
}

fn pousser_hex(s: &mut String, octets: &[u8]) {
    use std::fmt::Write;
    for o in octets {
        write!(s, "{o:02x}").expect("écriture en mémoire");
    }
}

/// Contexte de plaque d'un prestataire agréé, lu par le cycle QRC pour composer
/// le PDF (nom + jeton + code) et les empreintes hors-ligne, et résoudre la
/// politique photo (data-model 006 §4.3/§5). `None` si le prestataire n'a pas
/// d'identité de plaque (jamais agréé, FR-011).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ContextePlaque {
    /// Prestataire concerné.
    pub prestataire_id: Uuid,
    /// Nom affiché sur la plaque.
    pub nom: String,
    /// Jeton public imprimé dans le QR (stable, cycle 005).
    pub jeton_plaque: String,
    /// Code de secours à 4 chiffres (mode dégradé).
    pub code_secours: String,
    /// Ville du prestataire (résolution des paramètres de zone hérités).
    pub ville_id: Uuid,
    /// Politique photo prestataire > catégorie, AVANT application du seuil de
    /// montant (`obligatoire` | `facultative` | `desactivee`, R4 niveaux 1–2).
    pub politique_photo_base: String,
}

impl PgPrestataires {
    /// Contexte de plaque + politique photo de base d'un prestataire (QRC).
    /// `None` si le prestataire est inconnu ou n'a jamais reçu de plaque.
    pub async fn contexte_plaque(
        &self,
        prestataire_id: Uuid,
    ) -> Result<Option<ContextePlaque>, ErreurPrestataires> {
        let ligne = sqlx::query!(
            r#"SELECT p.nom, p.jeton_plaque, p.code_secours, p.ville_id,
                      COALESCE(p.politique_photo_collecte, c.politique_photo::text)
                          AS "politique_base!"
               FROM prestataires.prestataire p
               JOIN zones.categorie c ON c.id = p.categorie_id
               WHERE p.id = $1"#,
            prestataire_id,
        )
        .fetch_optional(&self.pool)
        .await?;
        Ok(ligne.and_then(|l| match (l.jeton_plaque, l.code_secours) {
            (Some(jeton_plaque), Some(code_secours)) => Some(ContextePlaque {
                prestataire_id,
                nom: l.nom,
                jeton_plaque,
                code_secours,
                ville_id: l.ville_id,
                politique_photo_base: l.politique_base,
            }),
            // Agréé un jour mais plaque incomplète : impossible (contrainte
            // plaque_complete) ; jamais agréé : les deux colonnes sont NULL.
            _ => None,
        }))
    }

    /// FR-016 — résolution d'un jeton : recherche EXACTE sur la colonne
    /// stockée, validité DÉRIVÉE de l'état d'agrément. `None` = jeton inconnu
    /// (ou forgé : il n'a jamais été stocké).
    pub async fn resolution_plaque(
        &self,
        jeton: &str,
    ) -> Result<Option<ResolutionPlaque>, ErreurPrestataires> {
        let ligne = sqlx::query!(
            r#"SELECT id, statut::text AS "statut!"
               FROM prestataires.prestataire WHERE jeton_plaque = $1"#,
            jeton,
        )
        .fetch_optional(&self.pool)
        .await?;
        Ok(ligne.map(|l| ResolutionPlaque {
            prestataire_id: l.id,
            valide: l.statut == "agree",
        }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn jeton_stable_en_forme_et_distinct_par_nonce() {
        let secret = b"secret-plaque-de-test-32-octets!";
        let id = Uuid::now_v7();
        let a = generer_jeton(secret, id);
        let b = generer_jeton(secret, id);
        assert_eq!(a.len(), 80, "16 + 8 + 16 octets en hex");
        assert!(a.chars().all(|c| c.is_ascii_hexdigit()));
        assert_ne!(a, b, "le nonce rend chaque génération unique");
        assert!(
            a.starts_with(&id.simple().to_string()),
            "le préfixe identifie le prestataire (QRC hors-ligne)"
        );
    }

    #[test]
    fn code_secours_a_quatre_chiffres() {
        for _ in 0..100 {
            let code = generer_code_secours();
            assert_eq!(code.len(), 4);
            assert!(code.chars().all(|c| c.is_ascii_digit()));
        }
    }
}
