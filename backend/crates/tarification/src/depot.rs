//! Racine de composition du domaine tarification (`PgTarification`).
//!
//! Compose le pool + la configuration de zone (`PgZones`, knobs/devise/drapeaux
//! hérités) + le port [`Routage`] (client OSRM réel en production, doubles en
//! test) + le port [`CacheRoutage`] (Redis en production, mémoire en test). Les
//! impls réelles sont câblées dans `api::run`.
//!
//! Convention du dépôt (cycles 002/005/006) : **lectures sur pool**, **écritures
//! sur `&mut PgTransaction`**, l'événement outbox écrit dans la MÊME transaction
//! que l'opération (constitution VI).

use std::sync::Arc;

use chrono_tz::Tz;
use serde_json::Value;
use sqlx::PgPool;
use uuid::Uuid;
use zones::{ConfigurationZones, Devise, PgZones};

use crate::effort::ParametresEffort;
use crate::modele::{DrapeauxZone, ErreurTarif, Regle, RegleUpsert};
use crate::ports::{CacheRoutage, Routage};
use crate::regle;
use crate::routage::OptionsCache;

/// Bornes de marge d'une zone (FR-009), résolues par héritage.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BornesMarge {
    /// Borne basse incluse.
    pub min: i64,
    /// Borne haute incluse.
    pub max: i64,
}

impl BornesMarge {
    /// La marge est-elle dans les bornes ?
    pub fn contient(&self, marge: i64) -> bool {
        marge >= self.min && marge <= self.max
    }
}

/// Défauts des knobs de zone — appliqués UNIQUEMENT si la clé est absente de
/// toute la chaîne d'héritage.
///
/// Ce ne sont pas des « paramètres en dur » (constitution I) mais des valeurs de
/// repli documentées : la valeur SERVIE vient du seed
/// `50_tarification_tiassale.sql` et s'édite en configuration de zone. Elles
/// existent pour qu'une zone neuve tarife plutôt que d'échouer, et pour que les
/// bornes de marge restent gardées même sans seed.
pub mod defauts {
    /// Bornes de marge par défaut (spec FR-009 « défaut 25–100 »).
    pub const MARGE_MIN: i64 = 25;
    /// Borne haute de marge par défaut.
    pub const MARGE_MAX: i64 = 100;
    /// Pas d'arrondi du prix client (FCFA supérieur).
    pub const ARRONDI_PAS: i64 = 25;
    /// Facteur du dégradé vol d'oiseau (Récapitulatif « ×1,4 »).
    pub const FACTEUR_DEGRADE: f64 = 1.4;
    /// TTL du cache de routage (heures).
    pub const CACHE_TTL_H: i64 = 24;
    /// Décimales de la clé de cache (~11 m à 4 décimales, research R3).
    pub const ARRONDI_CLE_DECIMALES: u32 = 4;
    /// Supplément de pluie (unités mineures) quand le drapeau est ON.
    pub const SUPPLEMENT_PLUIE: i64 = 100;
    /// Vitesse d'estimation de l'ETA en mode dégradé (km/h, deux-roues en ville).
    /// Ne touche AUCUN montant — la tarification est en distance, jamais en durée.
    pub const VITESSE_DEGRADEE_KMH: f64 = 20.0;
}

/// Paramètres de zone d'une évaluation, résolus par héritage en une lecture.
///
/// Aucune de ces valeurs n'est en dur dans le code de calcul (constitution I) :
/// changer un tarif, un arrondi ou un facteur de dégradé est une édition de
/// configuration de zone, pas un déploiement.
#[derive(Debug, Clone, PartialEq)]
pub struct Knobs {
    /// Devise ISO 4217 de la zone — celle de tous les montants du devis.
    pub devise: Devise,
    /// Drapeaux appliqués après le calcul de base (FR-017).
    pub drapeaux: DrapeauxZone,
    /// Fuseau d'interprétation des plages horaires et jours des règles.
    pub fuseau: Tz,
    /// Bornes de marge (gardent l'écriture ET la publication).
    pub bornes_marge: BornesMarge,
    /// Pas d'arrondi du prix client (unités mineures).
    pub arrondi_pas: i64,
    /// Supplément appliqué quand le drapeau `pluie` est ON.
    pub supplement_pluie: i64,
    /// Facteur du repli vol d'oiseau (non monétaire).
    pub facteur_degrade: f64,
    /// Vitesse d'estimation de l'ETA en dégradé (non monétaire).
    pub vitesse_degradee_kmh: f64,
    /// Options du cache de routage.
    pub cache: OptionsCache,
    /// Plafond de détour au-delà duquel une scission est PROPOSÉE (FR-032).
    /// `None` (défaut) ⇒ aucune scission n'est jamais proposée.
    pub plafond_eclatement_m: Option<i64>,
    /// Barèmes de la grille d'effort (100 % part coursier).
    pub effort: ParametresEffort,
}

/// Handle de dépôt du domaine tarification. Clone bon marché (pool et ports
/// partagés).
#[derive(Clone)]
pub struct PgTarification {
    pub(crate) pool: PgPool,
    pub(crate) zones: PgZones,
    pub(crate) routage: Arc<dyn Routage>,
    pub(crate) cache: Arc<dyn CacheRoutage>,
}

impl PgTarification {
    /// Compose le dépôt. `PgZones` est dérivé du pool (même base) ; le routage
    /// et son cache sont injectés par la racine de composition.
    pub fn new(pool: PgPool, routage: Arc<dyn Routage>, cache: Arc<dyn CacheRoutage>) -> Self {
        Self {
            zones: PgZones::new(pool.clone()),
            pool,
            routage,
            cache,
        }
    }

    /// Accès au pool applicatif (ouverture de transaction par la couche `api`).
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    // ── Knobs de zone (configuration héritée — constitution I) ─────────────

    /// Paramètre hérité brut (`None` si explicitement absent de la chaîne).
    pub(crate) async fn parametre(&self, zone: Uuid, cle: &str) -> Result<Option<Value>, ErreurTarif> {
        Ok(self.zones.parametre(zone, cle).await?)
    }

    /// Paramètre hérité lu comme entier, avec repli documenté.
    pub(crate) async fn parametre_i64(
        &self,
        zone: Uuid,
        cle: &str,
        defaut: i64,
    ) -> Result<i64, ErreurTarif> {
        Ok(self
            .parametre(zone, cle)
            .await?
            .and_then(|v| v.as_i64())
            .unwrap_or(defaut))
    }

    /// Bornes de marge de la zone (`tarification.marge.min` / `.max`, FR-009).
    pub async fn bornes_marge(&self, zone: Uuid) -> Result<BornesMarge, ErreurTarif> {
        Ok(BornesMarge {
            min: self
                .parametre_i64(zone, "tarification.marge.min", defauts::MARGE_MIN)
                .await?,
            max: self
                .parametre_i64(zone, "tarification.marge.max", defauts::MARGE_MAX)
                .await?,
        })
    }

    /// Devise ISO 4217 de la zone (FR-023) — source unique de la devise des
    /// règles et des devis ; jamais une constante du module.
    pub async fn devise(&self, zone: Uuid) -> Result<Devise, ErreurTarif> {
        Ok(self.zones.devise(zone).await?)
    }

    /// TOUS les paramètres de zone d'une évaluation, résolus en **une** lecture.
    ///
    /// La configuration effective résout toute la chaîne d'héritage d'un coup ;
    /// lire chaque clé séparément coûterait une dizaine de requêtes par devis,
    /// pour un objectif de « devis perçu instantané ».
    pub async fn knobs(&self, zone: Uuid) -> Result<Knobs, ErreurTarif> {
        let config = self.zones.configuration_effective(zone).await?;
        let entier = |cle: &str, defaut: i64| {
            config.valeur(cle).and_then(Value::as_i64).unwrap_or(defaut)
        };
        let flottant = |cle: &str, defaut: f64| {
            config.valeur(cle).and_then(Value::as_f64).unwrap_or(defaut)
        };
        // Un drapeau ABSENT vaut `false` : « absent » et « défini à faux » ont
        // ici le même effet tarifaire (aucun forçage).
        let drapeau = |cle: &str| {
            config
                .valeur(&format!("drapeau.{cle}"))
                .and_then(Value::as_bool)
                .unwrap_or(false)
        };

        let (code, decimales) = (
            config.valeur("devise.code").and_then(Value::as_str),
            config.valeur("devise.decimales").and_then(Value::as_u64),
        );
        let (Some(code), Some(decimales)) = (code, decimales) else {
            // Sans devise résolue, aucun montant n'a de sens : on refuse plutôt
            // que de supposer XOF (constitution III, portabilité hors zone CFA).
            return Err(ErreurTarif::Zones(zones::ErreurZones::DeviseIrresolvable(
                zone,
            )));
        };

        Ok(Knobs {
            devise: Devise {
                code: code.to_owned(),
                decimales: decimales as u8,
            },
            drapeaux: DrapeauxZone {
                livraison_offerte_mefali: drapeau("livraison_offerte_mefali"),
                gratuite_commissions: drapeau("gratuite_commissions"),
                pluie: drapeau("pluie"),
            },
            // Repli UTC si la clé est absente ou illisible : un fuseau fautif ne
            // doit pas faire échouer une tarification (précédent VND 005, R8).
            fuseau: config
                .valeur("zone.fuseau_horaire")
                .and_then(Value::as_str)
                .and_then(|s| s.parse::<Tz>().ok())
                .unwrap_or(Tz::UTC),
            bornes_marge: BornesMarge {
                min: entier("tarification.marge.min", defauts::MARGE_MIN),
                max: entier("tarification.marge.max", defauts::MARGE_MAX),
            },
            arrondi_pas: entier("tarification.arrondi_pas", defauts::ARRONDI_PAS),
            supplement_pluie: entier(
                "tarification.supplement_pluie",
                defauts::SUPPLEMENT_PLUIE,
            ),
            facteur_degrade: flottant("routage.facteur_degrade", defauts::FACTEUR_DEGRADE),
            vitesse_degradee_kmh: flottant(
                "routage.vitesse_degradee_kmh",
                defauts::VITESSE_DEGRADEE_KMH,
            ),
            cache: OptionsCache {
                ttl_s: (entier("routage.cache_ttl_h", defauts::CACHE_TTL_H).max(0) as u64) * 3_600,
                decimales: entier(
                    "routage.arrondi_cle_decimales",
                    defauts::ARRONDI_CLE_DECIMALES as i64,
                )
                .clamp(0, 9) as u32,
            },
            // ABSENT par défaut (data-model §2 : « dormant ») : tant que la zone
            // ne pose pas ce seuil, aucune scission n'est jamais proposée.
            plafond_eclatement_m: config
                .valeur("effort.plafond_eclatement_m")
                .and_then(Value::as_i64),
            effort: ParametresEffort::depuis_config(|cle| config.valeur(cle).cloned()),
        })
    }

    // ── Écriture d'une règle de brouillon (US1 — T009, FR-009/FR-023) ──────

    /// Crée ou remplace une règle DANS UN BROUILLON, sous double garde :
    /// **marge dans les bornes** de la zone (FR-009) et **devise = devise de la
    /// zone** (FR-023). Rien d'hors bornes n'entre donc jamais en base.
    ///
    /// Écrire dans une grille `en_vigueur` ou `historique` est refusé
    /// ([`ErreurTarif::PasUnBrouillon`]) : la tarification en cours ne se
    /// modifie pas sous les pieds des clients (FR-012) — elle se remplace par
    /// une publication.
    ///
    /// **Aucun événement outbox** : éditer un brouillon n'est pas une transition
    /// (le brouillon n'a aucun effet tarifaire). Seule la publication en est
    /// une. La garde de simulation se réarme d'elle-même — l'empreinte est
    /// RECALCULÉE à la lecture, jamais mémorisée (research R7).
    pub async fn ecrire_regle(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        grille_id: Uuid,
        regle_id: Uuid,
        upsert: &RegleUpsert,
    ) -> Result<Regle, ErreurTarif> {
        let entete = crate::grille::charger_entete(&mut *tx, grille_id)
            .await?
            .ok_or(ErreurTarif::GrilleInconnue(grille_id))?;
        if entete.etat != crate::modele::EtatGrille::Brouillon {
            return Err(ErreurTarif::PasUnBrouillon(grille_id));
        }

        regle::verifier_marge(self.bornes_marge(entete.zone_id).await?, upsert.marge)?;
        regle::verifier_devise(&self.devise(entete.zone_id).await?.code, &upsert.devise)?;

        let ligne = sqlx::query!(
            r#"
            INSERT INTO tarification.regle
                (id, grille_id, transport_slug, categorie_slug, distance_min_m, distance_max_m,
                 plage_debut_min, plage_fin_min, jours_masque, part_coursier_base, marge,
                 prix_par_km, seuil_km_m, prix_plafond, devise, priorite, actif)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
            ON CONFLICT (id) DO UPDATE SET
                transport_slug = EXCLUDED.transport_slug,
                categorie_slug = EXCLUDED.categorie_slug,
                distance_min_m = EXCLUDED.distance_min_m,
                distance_max_m = EXCLUDED.distance_max_m,
                plage_debut_min = EXCLUDED.plage_debut_min,
                plage_fin_min = EXCLUDED.plage_fin_min,
                jours_masque = EXCLUDED.jours_masque,
                part_coursier_base = EXCLUDED.part_coursier_base,
                marge = EXCLUDED.marge,
                prix_par_km = EXCLUDED.prix_par_km,
                seuil_km_m = EXCLUDED.seuil_km_m,
                prix_plafond = EXCLUDED.prix_plafond,
                devise = EXCLUDED.devise,
                priorite = EXCLUDED.priorite,
                actif = EXCLUDED.actif
            -- Une règle appartenant à une AUTRE grille n'est pas « mise à jour »
            -- ici : la clause exclut la ligne, RETURNING ne rend rien, et
            -- l'appelant reçoit `RegleInconnue` plutôt qu'un déplacement muet.
            WHERE tarification.regle.grille_id = $2
            RETURNING id, grille_id, transport_slug, categorie_slug, distance_min_m,
                      distance_max_m, plage_debut_min, plage_fin_min, jours_masque,
                      point_relais_id, part_coursier_base, marge, prix_par_km, seuil_km_m,
                      prix_plafond, devise, priorite, actif
            "#,
            regle_id,
            grille_id,
            upsert.transport_slug,
            upsert.categorie_slug,
            upsert.distance_min_m,
            upsert.distance_max_m,
            upsert.plage_debut_min,
            upsert.plage_fin_min,
            upsert.jours_masque,
            upsert.part_coursier_base,
            upsert.marge,
            upsert.prix_par_km,
            upsert.seuil_km_m,
            upsert.prix_plafond,
            upsert.devise,
            upsert.priorite,
            upsert.actif,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurTarif::RegleInconnue(regle_id))?;

        Ok(Regle {
            id: ligne.id,
            grille_id: ligne.grille_id,
            transport_slug: ligne.transport_slug,
            categorie_slug: ligne.categorie_slug,
            distance_min_m: ligne.distance_min_m,
            distance_max_m: ligne.distance_max_m,
            plage_debut_min: ligne.plage_debut_min,
            plage_fin_min: ligne.plage_fin_min,
            jours_masque: ligne.jours_masque,
            point_relais_id: ligne.point_relais_id,
            part_coursier_base: ligne.part_coursier_base,
            marge: ligne.marge,
            prix_par_km: ligne.prix_par_km,
            seuil_km_m: ligne.seuil_km_m,
            prix_plafond: ligne.prix_plafond,
            devise: ligne.devise,
            priorite: ligne.priorite,
            actif: ligne.actif,
        })
    }

    /// Supprime une règle d'un brouillon. Réarme la garde de simulation par le
    /// même mécanisme d'empreinte recalculée.
    pub async fn supprimer_regle(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        grille_id: Uuid,
        regle_id: Uuid,
    ) -> Result<(), ErreurTarif> {
        let entete = crate::grille::charger_entete(&mut *tx, grille_id)
            .await?
            .ok_or(ErreurTarif::GrilleInconnue(grille_id))?;
        if entete.etat != crate::modele::EtatGrille::Brouillon {
            return Err(ErreurTarif::PasUnBrouillon(grille_id));
        }
        let effacees = sqlx::query!(
            "DELETE FROM tarification.regle WHERE id = $1 AND grille_id = $2",
            regle_id,
            grille_id,
        )
        .execute(&mut **tx)
        .await?
        .rows_affected();
        if effacees == 0 {
            return Err(ErreurTarif::RegleInconnue(regle_id));
        }
        Ok(())
    }
}
