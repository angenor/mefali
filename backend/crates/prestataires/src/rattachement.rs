//! Rattachements compte ↔ prestataire (FR-006..008, research R11, analyse A1).
//!
//! Le rattachement ATTRIBUE le rôle vendeur quand le compte ne le porte pas
//! encore (l'agrément vaut validation — cadrage §5.1) ; le détachement ne
//! touche JAMAIS au rôle. Les capacités vendeur DÉRIVENT de
//! `rattachement EXISTS ∧ prestataire agréé` : rien n'est stocké, rien à
//! cascader, un seul état fait foi (FR-008).

use chrono::{DateTime, Utc};
use comptes::{ActionRole, Role};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgPrestataires;
use crate::modele::{ErreurPrestataires, StatutPrestataire};

/// Un rattachement, vue admin.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Rattachement {
    /// Compte rattaché.
    pub compte_id: Uuid,
    /// Qui a rattaché.
    pub rattache_par: Uuid,
    /// Quand.
    pub rattache_le: DateTime<Utc>,
}

impl PgPrestataires {
    /// Rattache un compte vérifié à un prestataire AGRÉÉ (FR-007 — refus 409
    /// sinon, analyse A1). IDEMPOTENT : un rejeu ou un multi-rattachement ne
    /// rejoue ni l'insertion, ni l'attribution du rôle, ni l'événement.
    ///
    /// Le rôle vendeur n'est attribué QUE si le compte ne le porte pas déjà
    /// (à quelque statut que ce soit — la transition `Attribuer` n'est légale
    /// que depuis ∅, research R11) ; `role.attribue` est alors émis par le
    /// domaine comptes dans la MÊME transaction.
    pub async fn rattacher_compte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        compte: Uuid,
        acteur: Uuid,
    ) -> Result<(), ErreurPrestataires> {
        let p = self.prestataire_dans_tx(tx, prestataire).await?;
        if p.statut != StatutPrestataire::Agree {
            return Err(ErreurPrestataires::PrestataireNonAgree(prestataire));
        }
        let compte_existe = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM comptes.compte WHERE id = $1) AS "existe!""#,
            compte,
        )
        .fetch_one(&mut **tx)
        .await?;
        if !compte_existe {
            return Err(comptes::ErreurComptes::CompteInconnu(compte).into());
        }

        let insere = sqlx::query!(
            "INSERT INTO prestataires.rattachement_compte
                 (prestataire_id, compte_id, rattache_par)
             VALUES ($1, $2, $3)
             ON CONFLICT (prestataire_id, compte_id) DO NOTHING",
            prestataire,
            compte,
            acteur,
        )
        .execute(&mut **tx)
        .await?
        .rows_affected();
        if insere == 0 {
            return Ok(()); // déjà rattaché — rejeu sans écriture ni événement
        }

        // Rôle vendeur si le compte n'en porte AUCUNE attribution (∅ → valide).
        let statut_role: Option<String> = sqlx::query_scalar!(
            r#"SELECT statut::text AS "statut!" FROM comptes.attribution_role
               WHERE compte_id = $1 AND role = 'vendeur'::comptes.role"#,
            compte,
        )
        .fetch_optional(&mut **tx)
        .await?;
        let role_attribue = statut_role.is_none();
        if role_attribue {
            self.comptes
                .decider_role(tx, compte, Role::Vendeur, ActionRole::Attribuer, acteur, None)
                .await?;
        }

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "rattachement.cree",
                entite_type: "rattachement",
                entite_id: compte,
                payload: json!({
                    "prestataire": prestataire,
                    "compte": compte,
                    "role_attribue": role_attribue,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }

    /// Détache un compte — le rôle vendeur du compte ne bouge JAMAIS (FR-008) :
    /// un rôle sans rattachement n'autorise rien, c'est la garde qui délimite.
    pub async fn detacher_compte(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        prestataire: Uuid,
        compte: Uuid,
        acteur: Uuid,
    ) -> Result<(), ErreurPrestataires> {
        let supprime = sqlx::query!(
            "DELETE FROM prestataires.rattachement_compte
             WHERE prestataire_id = $1 AND compte_id = $2",
            prestataire,
            compte,
        )
        .execute(&mut **tx)
        .await?
        .rows_affected();
        if supprime == 0 {
            return Err(ErreurPrestataires::RattachementInconnu {
                compte,
                prestataire,
            });
        }
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "rattachement.supprime",
                entite_type: "rattachement",
                entite_id: compte,
                payload: json!({
                    "prestataire": prestataire,
                    "compte": compte,
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;
        Ok(())
    }

    /// Prestataires que ce compte pilote — l'app prend le premier au MVP.
    pub async fn pilotables(&self, compte: Uuid) -> Result<Vec<Uuid>, ErreurPrestataires> {
        Ok(sqlx::query_scalar!(
            "SELECT prestataire_id FROM prestataires.rattachement_compte
             WHERE compte_id = $1 ORDER BY rattache_le",
            compte,
        )
        .fetch_all(&self.pool)
        .await?)
    }

    /// Rattachements d'un prestataire (vue admin).
    pub async fn rattachements(
        &self,
        prestataire: Uuid,
    ) -> Result<Vec<Rattachement>, ErreurPrestataires> {
        let lignes = sqlx::query!(
            "SELECT compte_id, rattache_par, rattache_le
             FROM prestataires.rattachement_compte
             WHERE prestataire_id = $1 ORDER BY rattache_le",
            prestataire,
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(lignes
            .into_iter()
            .map(|l| Rattachement {
                compte_id: l.compte_id,
                rattache_par: l.rattache_par,
                rattache_le: l.rattache_le,
            })
            .collect())
    }

    /// GARDE de pilotage des surfaces vendeur (FR-008, FR-011) — deux des
    /// trois refus distincts (le rôle vendeur est vérifié par l'extracteur
    /// `Auth` de la couche api) :
    /// - compte non rattaché à CE prestataire → `NonRattache` ;
    /// - prestataire non agréé (suspendu, prospect) → `PrestataireNonAgree`,
    ///   SANS que le rôle du compte ait bougé (aucune cascade).
    pub async fn exiger_pilotage(
        &self,
        compte: Uuid,
        prestataire: Uuid,
    ) -> Result<(), ErreurPrestataires> {
        let ligne = sqlx::query!(
            r#"SELECT
                 EXISTS(SELECT 1 FROM prestataires.rattachement_compte
                        WHERE prestataire_id = $1 AND compte_id = $2) AS "rattache!",
                 (SELECT statut::text FROM prestataires.prestataire WHERE id = $1) AS statut"#,
            prestataire,
            compte,
        )
        .fetch_one(&self.pool)
        .await?;
        let Some(statut) = ligne.statut.as_deref() else {
            return Err(ErreurPrestataires::PrestataireInconnu(prestataire));
        };
        if !ligne.rattache {
            return Err(ErreurPrestataires::NonRattache {
                compte,
                prestataire,
            });
        }
        if statut != "agree" {
            return Err(ErreurPrestataires::PrestataireNonAgree(prestataire));
        }
        Ok(())
    }
}
