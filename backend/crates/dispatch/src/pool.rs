//! Le pool temps réel vu du domaine : entrer, publier, sortir (DSP-01).
//!
//! **Le silence EST l'information.** Un coursier appartient au pool tant que son
//! inscription vit ; il en sort quand il se tait au-delà de
//! `dispatch.pool_ttl_s` (trois périodes de publication manquées). Ce n'est pas
//! un défaut à compenser : c'est le seul moyen honnête de savoir qu'un téléphone
//! a perdu le réseau, et c'est ce que l'app affiche à Yao par son bandeau de
//! reconnexion.
//!
//! **Le retrait volontaire, lui, est IMMÉDIAT** (FR-005). Attendre 90 s après
//! un « je passe hors ligne » ferait sonner le téléphone d'un coursier qui a
//! rangé sa moto.
//!
//! **Deux écritures, deux natures.** L'inscription est éphémère et
//! reconstructible (Redis) ; l'événement de disponibilité est durable (outbox).
//! Une position publiée n'émet AUCUN événement : c'est un fait qui se répète
//! toutes les 30 s et qui porte une coordonnée — l'émettre noierait l'outbox et
//! violerait la minimisation (FR-088).

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::modele::{Capacite, ErreurDispatch, InscriptionPool};

/// Pourquoi la disponibilité a changé — payload de
/// `coursier.disponibilite_changee`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifDisponibilite {
    /// Yao a basculé l'interrupteur lui-même.
    Manuel,
    /// Constaté après expiration : le coursier s'est tu.
    TtlExpire,
}

impl MotifDisponibilite {
    /// Représentation textuelle (payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifDisponibilite::Manuel => "manuel",
            MotifDisponibilite::TtlExpire => "ttl_expire",
        }
    }
}

/// Ce qu'une publication de position rend à l'app.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EtatPublication {
    /// Vrai si le coursier est (re)devenu membre du pool.
    pub dans_le_pool: bool,
    /// Durée de vie restante de l'inscription (secondes).
    pub ttl_s: i64,
    /// Période attendue de la prochaine publication (secondes).
    pub prochaine_publication_s: i64,
}

impl PgDispatch {
    /// Entrée (ou renouvellement) au pool, avec son événement quand l'état
    /// **change**.
    ///
    /// Rejouable sans bruit : republier alors qu'on est déjà en ligne repousse
    /// la durée de vie et n'émet rien. Seule une bascule émet.
    pub async fn entrer_dans_le_pool(
        &self,
        config: &ConfigDispatch,
        inscription: &InscriptionPool,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurDispatch> {
        let etait_dedans = self
            .pool_coursiers
            .etat(inscription.coursier)
            .await?
            .is_some();

        self.pool_coursiers
            .publier(inscription, config.pool_ttl())
            .await?;

        if !etait_dedans {
            self.emettre_disponibilite(
                inscription.coursier,
                config,
                true,
                &inscription.capacites,
                MotifDisponibilite::Manuel,
                horodatage,
            )
            .await?;
        }
        Ok(())
    }

    /// Sortie IMMÉDIATE du pool (FR-005), avec son événement.
    ///
    /// Idempotente : sortir deux fois n'émet qu'un événement — un coursier qui
    /// tape deux fois sur l'interrupteur ne doit pas produire deux lignes.
    pub async fn sortir_du_pool(
        &self,
        coursier: Uuid,
        config: &ConfigDispatch,
        motif: MotifDisponibilite,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurDispatch> {
        let etat = self.pool_coursiers.etat(coursier).await?;
        self.pool_coursiers.retirer(coursier, config.zone).await?;

        if let Some(etat) = etat {
            self.emettre_disponibilite(
                coursier,
                config,
                false,
                &etat.capacites,
                motif,
                horodatage,
            )
            .await?;
        }
        Ok(())
    }

    /// Publication de position : repousse la durée de vie, rend l'état.
    ///
    /// **Aucun événement** — voir l'en-tête du module. L'horodatage SERVEUR fait
    /// foi : `horodatage_local` est une observation de l'app, jamais l'autorité
    /// (FR-055, patron `ActionArretDto` du cycle 008).
    pub async fn publier_position(
        &self,
        config: &ConfigDispatch,
        inscription: &InscriptionPool,
    ) -> Result<EtatPublication, ErreurDispatch> {
        self.pool_coursiers
            .publier(inscription, config.pool_ttl())
            .await?;
        Ok(EtatPublication {
            dans_le_pool: true,
            ttl_s: config.pool_ttl_s,
            prochaine_publication_s: config.position_periode_s,
        })
    }

    /// État de pool d'un coursier, ou `None` s'il en est sorti.
    ///
    /// `None` n'est jamais une erreur : c'est **l'information** que DSP-01
    /// produit.
    pub async fn etat_pool(
        &self,
        coursier: Uuid,
    ) -> Result<Option<InscriptionPool>, ErreurDispatch> {
        self.pool_coursiers.etat(coursier).await
    }

    /// Élague les membres fantômes de l'index d'une zone et rend leur nombre.
    ///
    /// Journalisé : ce qui est élagué est **compté**. Un plafond silencieux
    /// ferait passer une fuite d'index pour un fonctionnement normal.
    pub async fn elaguer_pool(&self, zone: Uuid) -> Result<usize, ErreurDispatch> {
        let elagues = self.pool_coursiers.elaguer(zone).await?;
        if elagues > 0 {
            tracing::info!(zone = %zone, elagues, "fantômes de l'index de pool élagués");
        }
        Ok(elagues)
    }

    /// Écrit `coursier.disponibilite_changee` — **aucune coordonnée** (FR-088).
    async fn emettre_disponibilite(
        &self,
        coursier: Uuid,
        config: &ConfigDispatch,
        en_ligne: bool,
        capacites: &[Capacite],
        motif: MotifDisponibilite,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurDispatch> {
        let mut tx = self.pool.begin().await?;
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "coursier.disponibilite_changee",
                entite_type: "coursier",
                entite_id: coursier,
                payload: json!({
                    "zone": config.zone,
                    "en_ligne": en_ligne,
                    "capacites": capacites
                        .iter()
                        .map(|c| c.valeur.clone())
                        .collect::<Vec<_>>(),
                    "motif": motif.comme_str(),
                }),
                survenu_le: horodatage,
            },
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn les_motifs_de_disponibilite_ont_leur_valeur_de_payload() {
        assert_eq!(MotifDisponibilite::Manuel.comme_str(), "manuel");
        assert_eq!(MotifDisponibilite::TtlExpire.comme_str(), "ttl_expire");
    }
}
