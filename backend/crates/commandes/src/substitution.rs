//! Substitutions : préférences, proposition, échéance persistée, expiration.
//!
//! Ce module porte aussi la **révision du montant** — la seule chose qui bouge
//! quand un article manque. Elle vit ici, et non chez chaque appelant, parce
//! que l'invariant qu'elle protège est global : `total = articles + devis
//! FIGÉ`. Un retrait, un remplacement ou un arrêt entièrement indisponible
//! recalculent tous le même montant par le même chemin ; les frais de
//! livraison, eux, ne sont JAMAIS recalculés (FR-050).
//!
//! Rempli par T047..T050 ; la révision de montant est posée dès T034, qui en a
//! besoin pour l'arrêt entièrement indisponible.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::modele::ErreurCommandes;

/// Montants d'une commande après révision.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MontantsRevises {
    /// Somme des lignes encore vivantes (unités mineures).
    pub montant_articles_unites: i64,
    /// `montant_articles + devis_prix_client` — le devis n'entre dans le calcul
    /// que comme une constante lue.
    pub total_unites: i64,
    /// Prix client du devis FIGÉ, relu tel quel (base de l'assertion FR-050).
    pub devis_prix_client: i64,
}

impl PgCommandes {
    /// Recalcule les montants d'une commande à partir de ses lignes VIVANTES,
    /// et réécrit le tronc.
    ///
    /// ⚠ **Le devis de livraison n'est jamais recalculé** (FR-050) : il est lu
    /// depuis `livraison.devis_prix_client`, où la création l'a figé (R11).
    /// C'est structurel — aucun appel au moteur tarifaire n'existe sur ce
    /// chemin, donc aucun retrait ne peut faire varier les frais, même par
    /// accident. Un remplacement accepté compte au prix PROPOSÉ, un article
    /// retiré ne compte plus du tout.
    ///
    /// Aucun chemin de paiement partiel n'apparaît ici : le total révisé
    /// REMPLACE l'ancien, il ne le fractionne pas (constitution III).
    pub(crate) async fn reviser_montants(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        commande_id: Uuid,
    ) -> Result<MontantsRevises, ErreurCommandes> {
        let articles = sqlx::query_scalar!(
            r#"SELECT COALESCE(SUM(
                          lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites)
                      ) FILTER (WHERE lc.statut <> 'retiree'), 0)::bigint AS "articles!"
               FROM commandes.ligne_commande lc
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               WHERE lc.commande_id = $1"#,
            commande_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        // Une commande SANS livraison (vertical futur, constitution II) n'a
        // aucun frais : son total est celui de ses articles.
        let devis_prix_client = sqlx::query_scalar!(
            "SELECT devis_prix_client FROM commandes.livraison WHERE commande_id = $1",
            commande_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .unwrap_or(0);

        let total_unites = articles + devis_prix_client;

        sqlx::query!(
            "UPDATE commandes.commande
                SET montant_articles_unites = $2, total_unites = $3
              WHERE id = $1",
            commande_id,
            articles,
            total_unites,
        )
        .execute(&mut **tx)
        .await?;

        Ok(MontantsRevises {
            montant_articles_unites: articles,
            total_unites,
            devis_prix_client,
        })
    }

    /// Retire toutes les lignes encore présentes d'un arrêt — un `ligne.retiree`
    /// par ligne — puis révise les montants.
    ///
    /// Sert l'arrêt entièrement indisponible (T034) et la résolution d'une
    /// rupture (T047). Renvoie `(nombre de lignes retirées, montant retiré)`.
    pub(crate) async fn retirer_lignes_de_l_arret(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        commande_id: Uuid,
        motif: &str,
        horodatage: DateTime<Utc>,
    ) -> Result<(i64, i64), ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT lc.id,
                      lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites)
                          AS "montant!",
                      pf.devise
               FROM commandes.ligne_commande lc
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               WHERE lc.arret_id = $1 AND lc.statut = 'presente'
               ORDER BY lc.cree_le"#,
            arret_id,
        )
        .fetch_all(&mut **tx)
        .await?;

        let mut montant_retire = 0_i64;
        for ligne in &lignes {
            sqlx::query!(
                "UPDATE commandes.ligne_commande SET statut = 'retiree' WHERE id = $1",
                ligne.id,
            )
            .execute(&mut **tx)
            .await?;

            ecrire_evenement(
                tx,
                NouvelEvenement {
                    type_evenement: "ligne.retiree",
                    entite_type: "ligne_commande",
                    entite_id: ligne.id,
                    payload: json!({
                        "commande": commande_id,
                        "motif": motif,
                        "montant_retire": ligne.montant,
                        "devise": ligne.devise,
                    }),
                    survenu_le: horodatage,
                },
            )
            .await?;
            montant_retire += ligne.montant;
        }

        if !lignes.is_empty() {
            self.reviser_montants(tx, commande_id).await?;
        }
        Ok((lignes.len() as i64, montant_retire))
    }
}
