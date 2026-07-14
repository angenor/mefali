//! Double de [`ConfigurationZones`] pour les tests UNITAIRES du domaine.
//!
//! Le domaine lit trois paramètres hérités (indicatif par défaut, durée max de
//! note vocale, rétention du repère) et le référentiel des transports actifs.
//! Les tester via Postgres exigerait un seed et une base par test pour vérifier
//! des règles qui ne parlent pas de SQL. Ce double sert donc les tests de
//! `otp.rs` et `dossier.rs` ; les tests d'intégration (`#[sqlx::test]`), eux,
//! utilisent le VRAI `PgZones` avec les seeds — les deux niveaux se complètent.

use std::collections::BTreeMap;

use async_trait::async_trait;
use serde_json::{json, Value};
use uuid::Uuid;
use zones::{CategorieActive, ConfigurationEffective, Devise, ErreurZones, ValeurProvenance};

/// [`ConfigurationZones`] servant un jeu de paramètres fixe, quelle que soit la
/// zone demandée (l'héritage lui-même est testé par le cycle 002).
pub struct ZonesFixes {
    valeurs: BTreeMap<String, Value>,
    transports: Vec<String>,
}

impl ZonesFixes {
    /// Jeu de Tiassalé, aligné sur le seed `20_comptes.sql` (T009).
    pub fn tiassale() -> Self {
        Self {
            valeurs: [
                ("telephone.indicatif_defaut", json!("+225")),
                ("adresse.retention_repere_vocal_jours", json!(365)),
                ("medias.note_vocale_duree_max_s", json!(30)),
                ("consentement.artci_version", json!("2026-07")),
            ]
            .into_iter()
            .map(|(c, v)| (c.to_owned(), v))
            .collect(),
            transports: ["a_pied", "velo", "moto"]
                .iter()
                .map(|s| (*s).to_owned())
                .collect(),
        }
    }

    /// Zone sans aucun paramètre — vérifie les erreurs de configuration.
    pub fn vide() -> Self {
        Self {
            valeurs: BTreeMap::new(),
            transports: Vec::new(),
        }
    }

    /// Jeu de Tiassalé avec un autre indicatif.
    pub fn avec_indicatif(indicatif: &str) -> Self {
        let mut zones = Self::tiassale();
        zones
            .valeurs
            .insert("telephone.indicatif_defaut".to_owned(), json!(indicatif));
        zones
    }
}

#[async_trait]
impl zones::ConfigurationZones for ZonesFixes {
    async fn configuration_effective(
        &self,
        zone: Uuid,
    ) -> Result<ConfigurationEffective, ErreurZones> {
        Ok(ConfigurationEffective {
            zone,
            valeurs: self
                .valeurs
                .iter()
                .map(|(cle, valeur)| {
                    (
                        cle.clone(),
                        ValeurProvenance {
                            valeur: valeur.clone(),
                            provenance: zone,
                        },
                    )
                })
                .collect(),
        })
    }

    async fn parametre(&self, _zone: Uuid, cle: &str) -> Result<Option<Value>, ErreurZones> {
        Ok(self.valeurs.get(cle).cloned())
    }

    async fn devise(&self, _zone: Uuid) -> Result<Devise, ErreurZones> {
        Ok(Devise {
            code: "XOF".to_owned(),
            decimales: 0,
        })
    }

    async fn drapeau(&self, _zone: Uuid, cle: &str) -> Result<Option<bool>, ErreurZones> {
        Ok(self
            .valeurs
            .get(&format!("drapeau.{cle}"))
            .and_then(Value::as_bool))
    }

    async fn transports_actifs(&self, _zone: Uuid) -> Result<Vec<String>, ErreurZones> {
        Ok(self.transports.clone())
    }

    async fn categories_actives(&self, _zone: Uuid) -> Result<Vec<CategorieActive>, ErreurZones> {
        // Le domaine comptes ne consulte jamais les catégories.
        Ok(Vec::new())
    }
}
