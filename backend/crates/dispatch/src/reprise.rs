//! Reprendre une course qui n'avance pas (DSP-07) — et **épargner celui qui
//! roule**.
//!
//! Deux critères, distincts et nommés (research R13) :
//!
//! - **sans mouvement** — le coursier ne s'est pas rapproché du premier arrêt
//!   non résolu d'au moins `dispatch.reassignation_deplacement_min_m` depuis
//!   `dispatch.reassignation_sans_mouvement_s`. L'**absence** de position
//!   récente compte comme absence de mouvement (FR-078) : un téléphone éteint
//!   n'est pas un coursier en route ;
//! - **sans scan** — aucun arrêt collecté au-delà de l'affectation, plus le
//!   délai de préparation annoncé, plus `dispatch.reassignation_sans_scan_marge_s`.
//!
//! **La garde d'argent** (FR-075) prime sur les deux : dès qu'un arrêt est
//! collecté, aucune reprise automatique n'est possible. Le coursier a engagé ses
//! fonds propres, et « le coursier ne perd jamais » (cadrage §7.5) interdit
//! qu'un automatisme lui retire une marchandise payée. Le cas part en escalade
//! vers l'exploitation, qui tranche avec un motif.
//!
//! **Pourquoi persister la distance.** L'index éphémère ne garde que la
//! DERNIÈRE position : il n'y a aucun historique pour dire « il ne s'est pas
//! rapproché depuis 5 minutes ». Et la décision retire une course à quelqu'un —
//! elle ne peut pas dépendre d'un service reconstructible.

use chrono::{DateTime, Utc};
use tarification::Point;
use uuid::Uuid;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::modele::ErreurDispatch;

/// Ce qu'une observation de position a constaté sur une course assignée.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Progression {
    /// Distance routière au premier arrêt non résolu (mètres entiers).
    pub distance_m: i64,
    /// Meilleure distance observée depuis la dernière remise à zéro.
    pub distance_min_m: i64,
    /// Vrai si ce passage a constaté un rapprochement SIGNIFICATIF.
    pub a_progresse: bool,
    /// Vrai si la mesure vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
}

impl PgDispatch {
    /// Enregistre la progression d'une course assignée à chaque position reçue.
    ///
    /// Le rapprochement se mesure contre la **meilleure distance déjà
    /// observée**, jamais contre la précédente : sinon un aller-retour de
    /// 200 m passerait pour une progression toutes les cinq minutes, et un
    /// coursier immobile ne serait jamais repris.
    ///
    /// Ne rend jamais d'erreur de routage : la proximité dégrade (research R5).
    pub async fn observer_progression(
        &self,
        livraison: Uuid,
        lat: f64,
        lon: f64,
        config: &ConfigDispatch,
        horodatage: DateTime<Utc>,
    ) -> Result<Option<Progression>, ErreurDispatch> {
        let etat = self.commandes.etat_progression(livraison).await?;
        let (Some(cible_lat), Some(cible_lon)) =
            (etat.premier_arret_lat, etat.premier_arret_lon)
        else {
            // Plus aucun arrêt à résoudre : il n'y a rien vers quoi progresser.
            return Ok(None);
        };

        let trajets = self
            .proximite
            .vers_point(
                config.zone,
                &[Point { lat, lon }],
                Point {
                    lat: cible_lat,
                    lon: cible_lon,
                },
            )
            .await;
        let Some(trajet) = trajets.trajets.first() else {
            return Ok(None);
        };
        let distance_m = trajet.distance_m.max(0);

        let precedent = sqlx::query!(
            "SELECT distance_min_m, progresse_le FROM dispatch.suivi_progression
             WHERE livraison_id = $1",
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?;

        let (distance_min_m, a_progresse, progresse_le) = match precedent {
            None => (distance_m, true, horodatage),
            Some(p) => {
                let gain = p.distance_min_m - distance_m;
                if gain >= config.reassignation_deplacement_min_m {
                    (distance_m, true, horodatage)
                } else {
                    (p.distance_min_m.min(distance_m), false, p.progresse_le)
                }
            }
        };

        sqlx::query!(
            "INSERT INTO dispatch.suivi_progression
                 (livraison_id, distance_m, distance_min_m, observe_le, progresse_le, degraded)
             VALUES ($1, $2, $3, $4, $5, $6)
             ON CONFLICT (livraison_id)
             DO UPDATE SET distance_m = EXCLUDED.distance_m,
                           distance_min_m = EXCLUDED.distance_min_m,
                           observe_le = EXCLUDED.observe_le,
                           progresse_le = EXCLUDED.progresse_le,
                           degraded = EXCLUDED.degraded",
            livraison,
            distance_m,
            distance_min_m,
            horodatage,
            progresse_le,
            trajets.degraded,
        )
        .execute(&self.pool)
        .await?;

        Ok(Some(Progression {
            distance_m,
            distance_min_m,
            a_progresse,
            degraded: trajets.degraded,
        }))
    }

    /// Oublie le suivi d'une livraison — appelé quand elle change de coursier,
    /// pour que le nouveau ne soit pas jugé sur le trajet du précédent.
    pub async fn oublier_progression(&self, livraison: Uuid) -> Result<(), ErreurDispatch> {
        sqlx::query!(
            "DELETE FROM dispatch.suivi_progression WHERE livraison_id = $1",
            livraison,
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }
}
