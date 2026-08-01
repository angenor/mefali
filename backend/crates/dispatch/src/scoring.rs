//! Classer les candidats : rapide **et** équitable (DSP-03).
//!
//! **Entiers de bout en bout** (research R6). Composantes normalisées en
//! millièmes (`0..=1000`), poids en centièmes, score = `Σ(poids × composante)
//! / 100`. Deux raisons, aucune décorative :
//!
//! 1. FR-039 exige qu'« à score égal, l'ordre soit aléatoire » — ce qui suppose
//!    une égalité **exacte**, que des flottants rendraient fortuite ;
//! 2. un classement assertable au rang près ne peut pas dépendre d'un arrondi
//!    de plateforme.
//!
//! **La proximité est RELATIVE au lot** : le meilleur candidat vaut 1000, le
//! pire 0. Un classement est relatif par nature — normaliser sur une constante
//! ferait qu'un jour creux, où tout le monde est loin, tous les candidats
//! auraient la même mauvaise note et l'ordre deviendrait arbitraire.
//!
//! **L'inactivité est ce qui rend le dispatch vivable** (SC-007). Sans elle, le
//! coursier le plus proche du centre prendrait tout, et les autres
//! désinstalleraient l'app. Elle part de la dernière course LIVRÉE, ou de
//! l'entrée dans le pool à défaut : un nouvel arrivant n'est pas quelqu'un qui
//! vient de finir.

use chrono::{DateTime, Duration, Utc};
use uuid::Uuid;

use crate::config::{ConfigDispatch, Poids};
use crate::depot::PgDispatch;
use crate::eligibilite::CandidatEligible;
use crate::modele::{Candidat, Composantes, ErreurDispatch, MesureProximite};

/// Maximum d'une composante normalisée (millièmes).
pub const COMPOSANTE_MAX: i32 = 1000;

/// Barème de la note (centièmes) — 5,00 étoiles.
const NOTE_MAX_CENTIEMES: i32 = 500;

/// Score pondéré d'un jeu de composantes. **Entier**, sans exception.
pub fn score(composantes: Composantes, poids: Poids) -> i32 {
    (poids.proximite * composantes.proximite
        + poids.inactivite * composantes.inactivite
        + poids.note * composantes.note
        + poids.acceptation * composantes.acceptation)
        / 100
}

/// Proximité normalisée **relativement au lot** : le meilleur vaut 1000.
///
/// `pire` est la plus mauvaise valeur du lot. Un lot homogène (tous à la même
/// distance) donne 1000 à tout le monde — et c'est juste : aucun n'est plus
/// proche qu'un autre, la décision doit se jouer sur les autres composantes.
pub fn proximite_normalisee(valeur: i64, pire: i64) -> i32 {
    if pire <= 0 {
        return COMPOSANTE_MAX;
    }
    let ratio = (valeur.max(0).saturating_mul(COMPOSANTE_MAX as i64)) / pire;
    COMPOSANTE_MAX - ratio.clamp(0, COMPOSANTE_MAX as i64) as i32
}

/// Inactivité normalisée : plafonnée par `dispatch.inactivite_plafond_s`.
pub fn inactivite_normalisee(inactivite_s: i64, plafond_s: i64) -> i32 {
    if plafond_s <= 0 {
        return COMPOSANTE_MAX;
    }
    ((inactivite_s.max(0).saturating_mul(COMPOSANTE_MAX as i64)) / plafond_s)
        .clamp(0, COMPOSANTE_MAX as i64) as i32
}

/// Note normalisée, ou la valeur **neutre** de zone si elle manque.
///
/// Research R7 — l'absence de note ne pénalise PAS : pénaliser un nouveau
/// coursier sur une note qu'il n'a pas eu l'occasion de mériter l'empêcherait
/// d'en obtenir une. (C'est l'inverse du plafond d'avance, qui est une
/// exposition financière et démarre au palier d'entrée.)
pub fn note_normalisee(note_centiemes: Option<i32>, neutre_millimes: i32) -> i32 {
    match note_centiemes {
        None => neutre_millimes.clamp(0, COMPOSANTE_MAX),
        Some(note) => {
            ((note.max(0) * COMPOSANTE_MAX) / NOTE_MAX_CENTIEMES).clamp(0, COMPOSANTE_MAX)
        }
    }
}

/// Taux d'acceptation normalisé (pourcentage → millièmes), ou la valeur neutre
/// quand aucune offre n'a été émise sur la fenêtre.
pub fn acceptation_normalisee(taux_pourcent: Option<i32>, neutre_millimes: i32) -> i32 {
    match taux_pourcent {
        None => neutre_millimes.clamp(0, COMPOSANTE_MAX),
        Some(taux) => (taux.max(0) * 10).clamp(0, COMPOSANTE_MAX),
    }
}

impl PgDispatch {
    /// Classe un vivier d'éligibles, mieux classé d'abord.
    ///
    /// À score **égal**, l'ordre est aléatoire (FR-039) : sans cela, le premier
    /// arrivé dans l'index prendrait systématiquement le dessus, et deux
    /// coursiers identiques n'auraient pas la même chance.
    pub async fn classer(
        &self,
        config: &ConfigDispatch,
        eligibles: &[CandidatEligible],
        mesure: MesureProximite,
        maintenant: DateTime<Utc>,
    ) -> Result<Vec<Candidat>, ErreurDispatch> {
        if eligibles.is_empty() {
            return Ok(Vec::new());
        }

        // La grandeur de proximité : durée quand elle est connue, distance
        // sinon (FR-035).
        let valeurs: Vec<i64> = eligibles
            .iter()
            .map(|c| match mesure {
                MesureProximite::Duree => c.duree_s,
                MesureProximite::Distance => c.distance_m,
            })
            .collect();
        let pire = valeurs.iter().copied().max().unwrap_or(0);

        let mut candidats = Vec::with_capacity(eligibles.len());
        for (index, eligible) in eligibles.iter().enumerate() {
            let inactivite_s = self.inactivite_s(eligible, config, maintenant).await?;
            let taux = self
                .taux_acceptation_pourcent(eligible.coursier, config, maintenant)
                .await?;
            let composantes = Composantes {
                proximite: proximite_normalisee(valeurs[index], pire),
                inactivite: inactivite_normalisee(inactivite_s, config.inactivite_plafond_s),
                note: note_normalisee(
                    eligible.inscription.note_centiemes,
                    config.note_composante_neutre_millimes,
                ),
                acceptation: acceptation_normalisee(taux, config.note_composante_neutre_millimes),
            };
            candidats.push(Candidat {
                coursier: eligible.coursier,
                composantes,
                score: score(composantes, config.poids),
                rang: 0,
            });
        }

        // Départage ALÉATOIRE à score égal (FR-039). Le mélange précède le tri
        // stable : deux scores identiques gardent alors l'ordre du mélange.
        melanger(&mut candidats);
        // Tri STABLE décroissant : les scores égaux gardent l'ordre du mélange,
        // et c'est exactement le départage que FR-039 demande.
        candidats.sort_by_key(|c| std::cmp::Reverse(c.score));
        for (rang, candidat) in candidats.iter_mut().enumerate() {
            candidat.rang = rang as u16;
        }

        journaliser_classement(config.zone, &candidats);
        Ok(candidats)
    }

    /// Inactivité d'un candidat, en secondes.
    ///
    /// Depuis la dernière course LIVRÉE ; à défaut, **depuis sa mise en ligne du
    /// jour** — l'instant où il a décidé de travailler.
    ///
    /// ⚠ Surtout pas l'âge de sa dernière PUBLICATION de position : elle date de
    /// quelques secondes, et un coursier en ligne depuis le matin sans avoir
    /// rien reçu aurait alors la même inactivité que celui qui vient de
    /// terminer une course. C'est l'inverse exact de l'équité que DSP-03
    /// cherche — celui qui attend depuis le plus longtemps doit passer devant.
    ///
    /// Sans mise en ligne connue (index reconstruit après un vidage), on prend
    /// le plafond de zone : un coursier dont on ignore l'attente est présumé
    /// avoir attendu, jamais présumé venir de finir.
    async fn inactivite_s(
        &self,
        eligible: &CandidatEligible,
        config: &ConfigDispatch,
        maintenant: DateTime<Utc>,
    ) -> Result<i64, ErreurDispatch> {
        if let Some(fin) = self.commandes.fin_derniere_course(eligible.coursier).await? {
            return Ok((maintenant - fin).num_seconds().max(0));
        }
        let bascule = sqlx::query_scalar!(
            "SELECT bascule_le FROM dispatch.plafond_jour
             WHERE coursier_id = $1 AND jour = $2",
            eligible.coursier,
            maintenant.date_naive(),
        )
        .fetch_optional(&self.pool)
        .await?
        .flatten();
        Ok(match bascule {
            Some(depuis) => (maintenant - depuis).num_seconds().max(0),
            None => config.inactivite_plafond_s,
        })
    }

    /// Taux d'acceptation en pourcentage sur la fenêtre de zone, ou `None` si
    /// aucune offre décidable n'a été émise.
    ///
    /// **Les non-réponses FRANCHES sont exclues** (FR-052) : les trois premières
    /// du jour ne coûtent rien, et les compter ici les transformerait en
    /// pénalité déguisée.
    ///
    /// `pub` depuis le cycle CRS 010 : c'est un compteur RÉELLEMENT tenu, et
    /// K1-1a l'affiche à Yao (FR-093). Le handler `GET /moi/journee` le lit
    /// directement — aucun crate n'apprend l'existence de l'autre (contrat §2).
    pub async fn taux_acceptation_pourcent(
        &self,
        coursier: Uuid,
        config: &ConfigDispatch,
        maintenant: DateTime<Utc>,
    ) -> Result<Option<i32>, ErreurDispatch> {
        let depuis = maintenant - Duration::days(config.acceptation_fenetre_jours.max(0));
        let ligne = sqlx::query!(
            r#"SELECT
                 count(*) FILTER (WHERE issue = 'acceptee')                  AS "acceptees!",
                 count(*) FILTER (
                     WHERE issue IN ('acceptee', 'refusee')
                        OR (issue = 'non_repondue' AND NOT franche)
                 ) AS "decidees!"
               FROM dispatch.offre
               WHERE coursier_id = $1 AND emise_le >= $2"#,
            coursier,
            depuis,
        )
        .fetch_one(&self.pool)
        .await?;

        if ligne.decidees == 0 {
            return Ok(None);
        }
        Ok(Some(((ligne.acceptees * 100) / ligne.decidees) as i32))
    }
}

/// Mélange en place — départage à score égal (FR-039).
///
/// Générateur simple alimenté par l'horloge : le besoin est « pas toujours le
/// même », pas « imprévisible par un adversaire ». Un CSPRNG serait du luxe
/// sur un chemin appelé à chaque dispatch.
fn melanger<T>(items: &mut [T]) {
    if items.len() < 2 {
        return;
    }
    let mut graine = Utc::now().timestamp_nanos_opt().unwrap_or(1) as u64 | 1;
    for i in (1..items.len()).rev() {
        // xorshift64 — suffisant pour un départage.
        graine ^= graine << 13;
        graine ^= graine >> 7;
        graine ^= graine << 17;
        items.swap(i, (graine % (i as u64 + 1)) as usize);
    }
}

/// Journalisation STRUCTURÉE du classement complet (constitution VII).
///
/// Le détail par candidat vit dans les logs, jamais dans l'outbox :
/// `dispatch.evaluation_faite` n'en porte que l'agrégat. Émettre le vivier
/// complet à chaque relance gonflerait l'outbox sans servir de KPI.
///
/// **Aucune coordonnée** (FR-088).
fn journaliser_classement(zone: Uuid, candidats: &[Candidat]) {
    for c in candidats {
        tracing::debug!(
            zone = %zone,
            coursier = %c.coursier,
            rang = c.rang,
            score = c.score,
            proximite = c.composantes.proximite,
            inactivite = c.composantes.inactivite,
            note = c.composantes.note,
            acceptation = c.composantes.acceptation,
            "candidat classé",
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn poids() -> Poids {
        Poids {
            proximite: 40,
            inactivite: 30,
            note: 20,
            acceptation: 10,
        }
    }

    /// La proximité est RELATIVE : le meilleur du lot vaut 1000, le pire 0.
    #[test]
    fn la_proximite_est_relative_au_lot() {
        assert_eq!(proximite_normalisee(0, 600), COMPOSANTE_MAX);
        assert_eq!(proximite_normalisee(600, 600), 0);
        assert_eq!(proximite_normalisee(300, 600), 500);
        // Lot homogène : personne n'est plus proche, tout le monde à 1000 —
        // la décision se joue alors sur les autres composantes.
        assert_eq!(proximite_normalisee(0, 0), COMPOSANTE_MAX);
    }

    /// L'inactivité sature au plafond de zone : au-delà, attendre plus longtemps
    /// ne donne pas plus de droits.
    #[test]
    fn l_inactivite_sature_au_plafond_de_zone() {
        assert_eq!(inactivite_normalisee(0, 1_800), 0);
        assert_eq!(inactivite_normalisee(900, 1_800), 500);
        assert_eq!(inactivite_normalisee(1_800, 1_800), COMPOSANTE_MAX);
        assert_eq!(inactivite_normalisee(10_000, 1_800), COMPOSANTE_MAX);
    }

    /// Research R7 — une note absente vaut la valeur NEUTRE, pas zéro.
    /// L'inverse du plafond d'avance, et pour une raison opposée : pénaliser un
    /// nouveau sur une note qu'il n'a pas pu mériter l'empêcherait d'en obtenir.
    #[test]
    fn une_note_absente_est_neutre_jamais_nulle() {
        assert_eq!(note_normalisee(None, 500), 500);
        assert_eq!(note_normalisee(Some(500), 500), COMPOSANTE_MAX);
        assert_eq!(note_normalisee(Some(250), 500), 500);
        assert_eq!(note_normalisee(Some(0), 500), 0);
        // Une note au-delà du barème ne dépasse pas le maximum.
        assert_eq!(note_normalisee(Some(900), 500), COMPOSANTE_MAX);
    }

    /// Aucune offre sur la fenêtre ⇒ valeur neutre : un coursier qui vient
    /// d'arriver n'a ni bon ni mauvais taux.
    #[test]
    fn un_taux_inconnu_est_neutre() {
        assert_eq!(acceptation_normalisee(None, 500), 500);
        assert_eq!(acceptation_normalisee(Some(100), 500), COMPOSANTE_MAX);
        assert_eq!(acceptation_normalisee(Some(92), 500), 920);
        assert_eq!(acceptation_normalisee(Some(0), 500), 0);
    }

    /// Le score reste sur l'échelle des composantes (0..1000) quand la somme
    /// des poids vaut 100 — c'est ce que la garde de configuration protège.
    #[test]
    fn le_score_reste_sur_l_echelle_des_composantes() {
        let parfait = Composantes {
            proximite: 1000,
            inactivite: 1000,
            note: 1000,
            acceptation: 1000,
        };
        assert_eq!(score(parfait, poids()), 1000);
        assert_eq!(score(Composantes::default(), poids()), 0);

        // Un candidat proche mais fraîchement servi vs un candidat loin mais
        // inactif : c'est le sens même de l'équité de DSP-03.
        let proche_actif = Composantes {
            proximite: 1000,
            inactivite: 0,
            note: 500,
            acceptation: 500,
        };
        let loin_inactif = Composantes {
            proximite: 200,
            inactivite: 1000,
            note: 500,
            acceptation: 500,
        };
        assert_eq!(score(proche_actif, poids()), 550);
        assert_eq!(score(loin_inactif, poids()), 530);
    }

    /// **Le paramètre agit** : retirer le poids d'inactivité change le
    /// classement. C'est la preuve que SC-007 tient à la composante, et non à
    /// un hasard d'ordonnancement.
    #[test]
    fn le_poids_d_inactivite_change_le_classement() {
        let proche_actif = Composantes {
            proximite: 1000,
            inactivite: 0,
            note: 500,
            acceptation: 500,
        };
        let loin_inactif = Composantes {
            proximite: 200,
            inactivite: 1000,
            note: 500,
            acceptation: 500,
        };
        // Sans la composante (poids reversé sur la proximité), l'écart se
        // creuse — et le coursier du centre prend tout.
        let sans_inactivite = Poids {
            proximite: 70,
            inactivite: 0,
            note: 20,
            acceptation: 10,
        };
        let ecart_avec = score(proche_actif, poids()) - score(loin_inactif, poids());
        let ecart_sans =
            score(proche_actif, sans_inactivite) - score(loin_inactif, sans_inactivite);
        assert!(
            ecart_sans > ecart_avec,
            "sans la composante d'inactivité, le plus proche écrase les autres \
             ({ecart_sans} contre {ecart_avec})",
        );
    }

    /// Le mélange varie — sans lui, deux candidats à score égal seraient
    /// toujours départagés par l'ordre de l'index.
    #[test]
    fn le_melange_ne_rend_pas_toujours_le_meme_ordre() {
        let mut vu_ordres = std::collections::HashSet::new();
        for _ in 0..50 {
            let mut items: Vec<u8> = (0..8).collect();
            melanger(&mut items);
            vu_ordres.insert(items);
        }
        assert!(
            vu_ordres.len() > 1,
            "à score égal, l'ordre doit varier (FR-039)",
        );
    }
}
