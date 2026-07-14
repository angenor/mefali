//! Résolution de la configuration effective par héritage (FR-006..010, R2).
//!
//! Cœur du produit : pour chaque paramètre, la valeur retenue est celle de
//! l'ancêtre le plus proche qui le définit (la zone elle-même en tête) ; une clé
//! absente de toute la chaîne est explicitement absente (FR-009). La chaîne
//! d'ancêtres est chargée par une CTE récursive, puis fusionnée avec provenance.
//!
//! Le trait [`ConfigurationZones`] est la SEULE interface d'héritage du produit
//! (FR-007) : tous les modules suivants (tarification, dispatch, commandes…) le
//! consomment sans dupliquer la logique.

use std::collections::BTreeMap;

use async_trait::async_trait;
use serde_json::Value;
use uuid::Uuid;

use crate::modele::{
    CategorieActive, ConfigurationEffective, Devise, ErreurZones, ValeurProvenance,
};
use crate::PgZones;

/// Lecture de la configuration de zone résolue par héritage. Interface interne
/// réutilisable, unique pour tout le produit (FR-007).
#[async_trait]
pub trait ConfigurationZones: Send + Sync {
    /// Configuration effective complète d'une zone (tous paramètres résolus, avec
    /// provenance). Erreur [`ErreurZones::ZoneInconnue`] si la zone n'existe pas.
    async fn configuration_effective(
        &self,
        zone: Uuid,
    ) -> Result<ConfigurationEffective, ErreurZones>;

    /// Valeur résolue d'un paramètre, ou `None` si explicitement absent (FR-009).
    async fn parametre(&self, zone: Uuid, cle: &str) -> Result<Option<Value>, ErreurZones>;

    /// Devise résolue (FR-010). Erreur [`ErreurZones::DeviseIrresolvable`] si la
    /// chaîne d'héritage n'en définit pas.
    async fn devise(&self, zone: Uuid) -> Result<Devise, ErreurZones>;

    /// Drapeau résolu (`cle` = suffixe, ex. `pluie` → clé `drapeau.pluie`).
    /// `None` = absent ; `Some(false)` = défini à faux (distinction FR-009).
    async fn drapeau(&self, zone: Uuid, cle: &str) -> Result<Option<bool>, ErreurZones>;

    /// Slugs des types de transport actifs, résolus par héritage (`transport.actifs`).
    /// Absent → aucun transport actif (liste vide).
    async fn transports_actifs(&self, zone: Uuid) -> Result<Vec<String>, ErreurZones>;

    /// Catégories ACTIVES dans la zone (slug, clé i18n de nom, mixable résolu).
    async fn categories_actives(&self, zone: Uuid) -> Result<Vec<CategorieActive>, ErreurZones>;
}

/// Résout la configuration effective sur une connexion donnée (pool ou
/// transaction) — factorise la CTE récursive + fusion. Consommée par le trait
/// (lecture sur pool) et par les écritures qui doivent résoudre dans LEUR
/// transaction (ex. seuil d'activation — `categorie.rs`).
pub(crate) async fn resoudre(
    conn: &mut sqlx::PgConnection,
    zone: Uuid,
) -> Result<ConfigurationEffective, ErreurZones> {
    let existe = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM zones.zone WHERE id = $1)",
        zone
    )
    .fetch_one(&mut *conn)
    .await?;
    if existe != Some(true) {
        return Err(ErreurZones::ZoneInconnue(zone));
    }

    // Pour chaque clé, la ligne de l'ancêtre le plus proche (profondeur minimale).
    let lignes = sqlx::query!(
        r#"
        WITH RECURSIVE chaine AS (
            SELECT id, parent_id, 0 AS profondeur
            FROM zones.zone WHERE id = $1
            UNION ALL
            SELECT z.id, z.parent_id, c.profondeur + 1
            FROM zones.zone z JOIN chaine c ON z.id = c.parent_id
        )
        SELECT DISTINCT ON (p.cle)
            p.cle     AS "cle!",
            p.valeur  AS "valeur!",
            p.zone_id AS "provenance!"
        FROM chaine c
        JOIN zones.parametre_zone p ON p.zone_id = c.id
        ORDER BY p.cle, c.profondeur ASC
        "#,
        zone,
    )
    .fetch_all(&mut *conn)
    .await?;

    let mut valeurs = BTreeMap::new();
    for ligne in lignes {
        valeurs.insert(
            ligne.cle,
            ValeurProvenance {
                valeur: ligne.valeur,
                provenance: ligne.provenance,
            },
        );
    }
    Ok(ConfigurationEffective { zone, valeurs })
}

#[async_trait]
impl ConfigurationZones for PgZones {
    async fn configuration_effective(
        &self,
        zone: Uuid,
    ) -> Result<ConfigurationEffective, ErreurZones> {
        let mut conn = self.pool.acquire().await?;
        resoudre(&mut conn, zone).await
    }

    async fn parametre(&self, zone: Uuid, cle: &str) -> Result<Option<Value>, ErreurZones> {
        Ok(self
            .configuration_effective(zone)
            .await?
            .valeur(cle)
            .cloned())
    }

    async fn devise(&self, zone: Uuid) -> Result<Devise, ErreurZones> {
        let config = self.configuration_effective(zone).await?;
        let code = config
            .valeur("devise.code")
            .and_then(Value::as_str)
            .map(str::to_owned);
        let decimales = config.valeur("devise.decimales").and_then(Value::as_u64);
        match (code, decimales) {
            (Some(code), Some(decimales)) => Ok(Devise {
                code,
                decimales: decimales as u8,
            }),
            _ => Err(ErreurZones::DeviseIrresolvable(zone)),
        }
    }

    async fn drapeau(&self, zone: Uuid, cle: &str) -> Result<Option<bool>, ErreurZones> {
        let config = self.configuration_effective(zone).await?;
        Ok(config
            .valeur(&format!("drapeau.{cle}"))
            .and_then(Value::as_bool))
    }

    async fn transports_actifs(&self, zone: Uuid) -> Result<Vec<String>, ErreurZones> {
        let config = self.configuration_effective(zone).await?;
        Ok(config
            .valeur("transport.actifs")
            .and_then(Value::as_array)
            .map(|elems| {
                elems
                    .iter()
                    .filter_map(|e| e.as_str().map(str::to_owned))
                    .collect()
            })
            .unwrap_or_default())
    }

    async fn categories_actives(&self, zone: Uuid) -> Result<Vec<CategorieActive>, ErreurZones> {
        // Résout d'abord (valide l'existence + fournit le mixable hérité).
        let config = self.configuration_effective(zone).await?;
        let lignes = sqlx::query!(
            r#"
            SELECT c.slug, c.nom_cle
            FROM zones.activation_categorie a
            JOIN zones.categorie c ON c.id = a.categorie_id
            WHERE a.zone_id = $1 AND a.actif = true
            ORDER BY c.slug
            "#,
            zone,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| {
                let mixable = config
                    .valeur(&format!("categorie.{}.mixable", l.slug))
                    .and_then(Value::as_bool)
                    .unwrap_or(false);
                CategorieActive {
                    slug: l.slug,
                    nom_cle: l.nom_cle,
                    mixable,
                }
            })
            .collect())
    }
}
