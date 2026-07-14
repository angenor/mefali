//! Activation des catégories par ville (FR-012..016, research R6).
//!
//! Deux écritures de domaine, toutes deux transactionnelles (événements outbox
//! inclus, constitution VI) :
//! - [`PgZones::recalculer_activation`] applique la règle du seuil
//!   (`actif_auto := actif_auto OR nb ≥ seuil résolu`) — JAMAIS de désactivation
//!   automatique (FR-015) ; le nombre de vendeurs agréés est un PARAMÈTRE
//!   d'entrée (le crate zones ne connaît pas les vendeurs — R6) ;
//! - [`PgZones::forcer_categorie`] pose le forçage admin à trois états, toujours
//!   prioritaire sur la règle (colonne générée `actif`).

use std::fmt;
use std::str::FromStr;

use chrono::Utc;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use uuid::Uuid;

use socle::{ecrire_evenement, NouvelEvenement};

use crate::modele::ErreurZones;
use crate::resolution::resoudre;
use crate::PgZones;

/// Mode de forçage admin d'une catégorie (data-model §1 — trois états).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Forcage {
    /// L'état effectif suit la règle du seuil (`actif_auto`).
    Automatique,
    /// Forcé actif, quel que soit le seuil.
    ForceActif,
    /// Forcé inactif, quel que soit le seuil.
    ForceInactif,
}

impl Forcage {
    /// Représentation = valeur de l'énum Postgres `zones.forcage_categorie`.
    pub fn comme_str(self) -> &'static str {
        match self {
            Forcage::Automatique => "automatique",
            Forcage::ForceActif => "force_actif",
            Forcage::ForceInactif => "force_inactif",
        }
    }
}

impl fmt::Display for Forcage {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.comme_str())
    }
}

impl FromStr for Forcage {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "automatique" => Ok(Forcage::Automatique),
            "force_actif" => Ok(Forcage::ForceActif),
            "force_inactif" => Ok(Forcage::ForceInactif),
            autre => Err(format!("mode de forçage inconnu : {autre}")),
        }
    }
}

/// État effectif d'une catégorie par ville après une opération.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EtatCategorie {
    /// Zone (ville) concernée.
    pub zone: Uuid,
    /// Slug de la catégorie.
    pub categorie: String,
    /// Mode de forçage courant.
    pub forcage: Forcage,
    /// État EFFECTIF (généré) : forçage prioritaire, sinon règle du seuil.
    pub actif: bool,
}

impl PgZones {
    /// Applique la règle du seuil à une catégorie dans une ville. `nb_vendeurs_agrees`
    /// est fourni par l'appelant (cycle VND). Émet `categorie.activation_changee`
    /// seulement si l'état EFFECTIF bascule. Seuil non résolu → aucune action.
    pub async fn recalculer_activation(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ville: Uuid,
        categorie_slug: &str,
        nb_vendeurs_agrees: i64,
    ) -> Result<(), ErreurZones> {
        // Seuil résolu par héritage à la ville, dans CETTE transaction.
        let config = resoudre(&mut **tx, ville).await?;
        let Some(seuil) = config
            .valeur(&format!("categorie.{categorie_slug}.seuil_activation"))
            .and_then(Value::as_i64)
        else {
            return Ok(()); // seuil absent → règle inerte (FR-009)
        };

        let categorie_id = self.categorie_id(tx, categorie_slug).await?;
        self.assurer_activation(tx, ville, categorie_id).await?;

        let avant = sqlx::query!(
            r#"SELECT actif_auto, actif AS "actif!" FROM zones.activation_categorie
               WHERE zone_id = $1 AND categorie_id = $2"#,
            ville,
            categorie_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        // Jamais de désactivation automatique (FR-015) : monotone à la hausse.
        let nouveau_actif_auto = avant.actif_auto || nb_vendeurs_agrees >= seuil;
        if nouveau_actif_auto == avant.actif_auto {
            return Ok(());
        }

        let apres = sqlx::query!(
            r#"UPDATE zones.activation_categorie SET actif_auto = $3, modifie_le = now()
               WHERE zone_id = $1 AND categorie_id = $2
               RETURNING id, actif AS "actif!""#,
            ville,
            categorie_id,
            nouveau_actif_auto,
        )
        .fetch_one(&mut **tx)
        .await?;

        if avant.actif != apres.actif {
            let payload = json!({
                "zone": ville,
                "categorie": categorie_slug,
                "avant": avant.actif,
                "apres": apres.actif,
                "origine": "seuil",
                "nb_vendeurs": nb_vendeurs_agrees,
                "seuil": seuil,
            });
            ecrire_evenement(
                tx,
                NouvelEvenement {
                    type_evenement: "categorie.activation_changee",
                    entite_type: "activation_categorie",
                    entite_id: apres.id,
                    payload,
                    survenu_le: Utc::now(),
                },
            )
            .await?;
        }
        Ok(())
    }

    /// Pose le forçage admin d'une catégorie par ville (prioritaire sur le seuil).
    /// Émet `categorie.forcage_change` TOUJOURS et `categorie.activation_changee`
    /// si l'état effectif bascule — dans la même transaction. Renvoie l'état effectif.
    pub async fn forcer_categorie(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ville: Uuid,
        categorie_slug: &str,
        forcage: Forcage,
        acteur: &str,
    ) -> Result<EtatCategorie, ErreurZones> {
        if !self.zone_existe(tx, ville).await? {
            return Err(ErreurZones::ZoneInconnue(ville));
        }
        let categorie_id = self.categorie_id(tx, categorie_slug).await?;
        self.assurer_activation(tx, ville, categorie_id).await?;

        let avant = sqlx::query!(
            r#"SELECT id, actif AS "actif!", forcage::text AS "forcage!"
               FROM zones.activation_categorie WHERE zone_id = $1 AND categorie_id = $2"#,
            ville,
            categorie_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        let apres = sqlx::query!(
            r#"UPDATE zones.activation_categorie
               SET forcage = $3::text::zones.forcage_categorie, modifie_le = now()
               WHERE zone_id = $1 AND categorie_id = $2
               RETURNING actif AS "actif!""#,
            ville,
            categorie_id,
            forcage.comme_str(),
        )
        .fetch_one(&mut **tx)
        .await?;

        // Journal ADM-05 (qui/quand/avant/après) — émis à chaque forçage.
        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "categorie.forcage_change",
                entite_type: "activation_categorie",
                entite_id: avant.id,
                payload: json!({
                    "zone": ville,
                    "categorie": categorie_slug,
                    "avant": avant.forcage,
                    "apres": forcage.comme_str(),
                    "acteur": acteur,
                }),
                survenu_le: Utc::now(),
            },
        )
        .await?;

        if avant.actif != apres.actif {
            ecrire_evenement(
                tx,
                NouvelEvenement {
                    type_evenement: "categorie.activation_changee",
                    entite_type: "activation_categorie",
                    entite_id: avant.id,
                    payload: json!({
                        "zone": ville,
                        "categorie": categorie_slug,
                        "avant": avant.actif,
                        "apres": apres.actif,
                        "origine": "forcage",
                    }),
                    survenu_le: Utc::now(),
                },
            )
            .await?;
        }

        Ok(EtatCategorie {
            zone: ville,
            categorie: categorie_slug.to_owned(),
            forcage,
            actif: apres.actif,
        })
    }

    /// Identifiant d'une catégorie par slug (erreur explicite si inconnue).
    async fn categorie_id(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        slug: &str,
    ) -> Result<Uuid, ErreurZones> {
        sqlx::query_scalar!("SELECT id FROM zones.categorie WHERE slug = $1", slug)
            .fetch_optional(&mut **tx)
            .await?
            .ok_or_else(|| ErreurZones::CategorieInconnue(slug.to_owned()))
    }

    /// Crée la ligne d'activation (automatique/inactif) si absente, sans l'écraser.
    async fn assurer_activation(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ville: Uuid,
        categorie_id: Uuid,
    ) -> Result<(), ErreurZones> {
        sqlx::query!(
            "INSERT INTO zones.activation_categorie (id, zone_id, categorie_id)
             VALUES ($1, $2, $3)
             ON CONFLICT (zone_id, categorie_id) DO NOTHING",
            Uuid::now_v7(),
            ville,
            categorie_id,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }
}
