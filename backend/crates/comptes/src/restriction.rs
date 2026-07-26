//! Restrictions de compte (CPT-06) — lecture et pose des drapeaux
//! `prepaiement_impose` / `bloque`.
//!
//! **Pourquoi ici** : les colonnes vivent dans le schéma `comptes`, et
//! « un schéma par module » (constitution II) impose que leur ÉCRITURE vive
//! dans son crate. Le cycle CMD 008 en a besoin — la garde de CMD-03 (compte
//! bloqué) et la sanction de CMD-08 (refus de périssable) — mais il y accède
//! par un **port** (`commandes::RestrictionsCompte`), jamais par une requête
//! directe : aucune requête du crate `commandes` ne cite `comptes.compte` en
//! écriture (point obligatoire **P3**, research R12).
//!
//! Les colonnes étaient des PROVISIONS du cycle 003 (« prêt ≠ construit ») :
//! ce module est le premier à les lire et à les écrire.

use async_trait::async_trait;
use chrono::Utc;
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::modele::ErreurComptes;
use crate::PgComptes;

/// Restrictions courantes d'un compte (CPT-06).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Restrictions {
    /// Le compte doit prépayer — le cash lui est refusé (FR-025).
    pub prepaiement_impose: bool,
    /// Le compte ne peut plus commander du tout (FR-026).
    pub bloque: bool,
}

/// Sanction POSABLE sur un compte. Les deux valeurs correspondent exactement
/// aux deux colonnes ; « aucune sanction » n'est pas une pose, c'est une
/// absence — d'où l'absence de troisième variante ici.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SanctionCompte {
    /// 1ᵉʳ manquement : le client doit désormais prépayer.
    PrepaiementImpose,
    /// 2ᵉ manquement : le compte ne peut plus commander.
    Bloque,
}

impl SanctionCompte {
    /// Représentation textuelle, portée par l'événement `sanction.posee`.
    pub fn comme_str(self) -> &'static str {
        match self {
            SanctionCompte::PrepaiementImpose => "prepaiement_impose",
            SanctionCompte::Bloque => "bloque",
        }
    }

    /// Rang de la sanction (1 = 1ᵉʳ manquement, 2 = 2ᵉ).
    pub fn rang(self) -> i16 {
        match self {
            SanctionCompte::PrepaiementImpose => 1,
            SanctionCompte::Bloque => 2,
        }
    }
}

/// Lecture des restrictions — offerte aux modules qui doivent refuser AVANT
/// d'écrire quoi que ce soit (CMD-03).
#[async_trait]
pub trait RestrictionsDeCompte: Send + Sync {
    /// Restrictions courantes du compte. Un compte inconnu est une erreur, pas
    /// un compte « sans restriction » : la différence compte pour une garde.
    async fn restrictions_de(&self, compte: Uuid) -> Result<Restrictions, ErreurComptes>;
}

#[async_trait]
impl RestrictionsDeCompte for PgComptes {
    async fn restrictions_de(&self, compte: Uuid) -> Result<Restrictions, ErreurComptes> {
        let ligne = sqlx::query!(
            "SELECT prepaiement_impose, bloque FROM comptes.compte WHERE id = $1",
            compte,
        )
        .fetch_optional(self.pool())
        .await?
        .ok_or(ErreurComptes::CompteInconnu(compte))?;
        Ok(Restrictions {
            prepaiement_impose: ligne.prepaiement_impose,
            bloque: ligne.bloque,
        })
    }
}

impl PgComptes {
    /// Pose une sanction sur un compte **dans la transaction fournie**, avec son
    /// événement `sanction.posee` — l'atomicité « transition + événement » est
    /// impossible à contourner (constitution VI).
    ///
    /// Idempotent : reposer la même sanction ne réécrit rien et n'émet rien.
    /// Une sanction n'est jamais LEVÉE ici — le rétablissement d'un compte est
    /// une décision admin qui aura sa propre surface (cycle ADM).
    ///
    /// `motif_cle` est une **clé i18n fr**, jamais un texte libre (VII).
    pub async fn poser_restriction(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        compte: Uuid,
        sanction: SanctionCompte,
        motif_cle: &str,
    ) -> Result<(), ErreurComptes> {
        // Verrou de ligne : deux échecs concurrents sur le même compte ne
        // doivent pas poser deux fois la même sanction.
        let avant = sqlx::query!(
            "SELECT prepaiement_impose, bloque FROM comptes.compte
             WHERE id = $1 FOR UPDATE",
            compte,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurComptes::CompteInconnu(compte))?;

        let deja_posee = match sanction {
            SanctionCompte::PrepaiementImpose => avant.prepaiement_impose,
            SanctionCompte::Bloque => avant.bloque,
        };
        if deja_posee {
            return Ok(());
        }

        match sanction {
            SanctionCompte::PrepaiementImpose => {
                sqlx::query!(
                    "UPDATE comptes.compte SET prepaiement_impose = true WHERE id = $1",
                    compte,
                )
                .execute(&mut **tx)
                .await?;
            }
            SanctionCompte::Bloque => {
                // Un compte bloqué doit aussi prépayer s'il est un jour
                // débloqué : le blocage est le rang SUPÉRIEUR, il englobe.
                sqlx::query!(
                    "UPDATE comptes.compte
                     SET bloque = true, prepaiement_impose = true
                     WHERE id = $1",
                    compte,
                )
                .execute(&mut **tx)
                .await?;
            }
        }

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "sanction.posee",
                entite_type: "compte",
                entite_id: compte,
                // ARTCI : ni numéro, ni nom — l'UUID du compte et la clé du motif.
                payload: json!({
                    "sanction": sanction.comme_str(),
                    "motif_cle": motif_cle,
                    "rang": sanction.rang(),
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use sqlx::PgPool;
    use zones::{PgZones, TypeZone};

    use super::*;
    use crate::ports::{MemoireEphemere, MemoireObjets, SmsTraces};

    /// Un compte vivant dans une ville, prêt à être sanctionné.
    async fn bac(pool: &PgPool) -> (PgComptes, Uuid) {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let pays = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "CI")
            .await
            .unwrap()
            .id;
        let ville = z
            .creer_zone(&mut tx, Some(pays), TypeZone::Ville, "Tiassalé")
            .await
            .unwrap()
            .id;
        tx.commit().await.unwrap();

        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(MemoireObjets::new()),
            Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
        );
        let mut tx = pool.begin().await.unwrap();
        let compte = depot
            .creer_compte(&mut tx, "+2250701020304", ville, "2026-07")
            .await
            .unwrap()
            .id;
        tx.commit().await.unwrap();
        (depot, compte)
    }

    /// Pose des deux rangs, idempotence, et un événement par POSE effective.
    #[sqlx::test(migrations = "../../migrations")]
    async fn poser_les_deux_rangs_est_idempotent(pool: sqlx::PgPool) {
        let (depot, compte) = bac(&pool).await;

        assert_eq!(
            depot.restrictions_de(compte).await.unwrap(),
            Restrictions::default(),
            "aucune restriction à l'inscription",
        );

        // Rang 1 — prépaiement imposé.
        let mut tx = pool.begin().await.unwrap();
        depot
            .poser_restriction(
                &mut tx,
                compte,
                SanctionCompte::PrepaiementImpose,
                "commande.sanction.refus_perissable",
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        let r = depot.restrictions_de(compte).await.unwrap();
        assert!(r.prepaiement_impose && !r.bloque);

        // Rejeu du MÊME rang → aucune écriture, aucun second événement.
        let mut tx = pool.begin().await.unwrap();
        depot
            .poser_restriction(
                &mut tx,
                compte,
                SanctionCompte::PrepaiementImpose,
                "commande.sanction.refus_perissable",
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();

        // Rang 2 — blocage (qui englobe le prépaiement).
        let mut tx = pool.begin().await.unwrap();
        depot
            .poser_restriction(
                &mut tx,
                compte,
                SanctionCompte::Bloque,
                "commande.sanction.refus_perissable",
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        let r = depot.restrictions_de(compte).await.unwrap();
        assert!(r.bloque && r.prepaiement_impose);

        let evenements: Vec<(String, i64)> = sqlx::query_as(
            "SELECT payload->>'sanction', (payload->>'rang')::bigint
             FROM outbox.evenement WHERE type_evenement = 'sanction.posee'
             ORDER BY id",
        )
        .fetch_all(&pool)
        .await
        .unwrap();
        assert_eq!(
            evenements,
            vec![
                ("prepaiement_impose".to_owned(), 1),
                ("bloque".to_owned(), 2)
            ],
            "un événement par POSE effective — le rejeu n'en émet aucun",
        );
    }

    #[sqlx::test(migrations = "../../migrations")]
    async fn compte_inconnu_est_une_erreur_pas_un_compte_sans_restriction(pool: sqlx::PgPool) {
        let (depot, _compte) = bac(&pool).await;
        let inconnu = Uuid::now_v7();
        assert!(matches!(
            depot.restrictions_de(inconnu).await,
            Err(ErreurComptes::CompteInconnu(_)),
        ));
    }
}
