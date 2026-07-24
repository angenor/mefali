//! Bac d'essai partagé des tests d'intégration du crate `tarification`.
//!
//! Monte une zone Tiassalé complète (devise XOF, knobs tarifaires) et une
//! **grille en vigueur** aux montants du produit, puis laisse chaque test
//! choisir son double de routage. Aucune socket n'est ouverte : les géométries
//! de course sont **simulées** (research R12) — CMD/DSP fourniront les vraies.

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use serde_json::{json, Value};
use sqlx::PgPool;
use tarification::{
    CacheMemoire, CacheRoutage, DemandeDevis, ErreurRoutage, Matrice, PgTarification, Point,
    Routage, RoutageIndisponible,
};
use uuid::Uuid;
use zones::{PgZones, TypeZone};

/// Degrés de latitude par mètre (approximation méridienne) — sert à fabriquer
/// des géométries dont la distance à vol d'oiseau est connue d'avance.
const DEGRES_PAR_METRE: f64 = 1.0 / 111_320.0;

/// Point de référence à Tiassalé.
pub const BASE_LAT: f64 = 5.898;
/// Longitude de référence à Tiassalé.
pub const BASE_LON: f64 = -4.823;

pub struct Bac {
    pub pool: PgPool,
    pub pays: Uuid,
    pub ville: Uuid,
    /// Grille EN VIGUEUR de la ville (montants du seed produit).
    pub grille: Uuid,
}

impl Bac {
    pub async fn nouveau(pool: PgPool) -> Self {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let pays = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "Côte d'Ivoire")
            .await
            .unwrap()
            .id;
        let ville = z
            .creer_zone(&mut tx, Some(pays), TypeZone::Ville, "Tiassalé")
            .await
            .unwrap()
            .id;
        for (cle, valeur) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("zone.fuseau_horaire", json!("Africa/Abidjan")),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        // Knobs tarifaires de la VILLE. Les drapeaux de lancement sont posés à
        // FAUX par défaut : chaque test qui les veut les allume explicitement,
        // sinon aucun devis nominal ne serait observable.
        for (cle, valeur) in [
            ("tarification.marge.min", json!(25)),
            ("tarification.marge.max", json!(100)),
            ("tarification.arrondi_pas", json!(25)),
            ("tarification.supplement_pluie", json!(100)),
            ("routage.facteur_degrade", json!(1.4)),
            ("routage.cache_ttl_h", json!(24)),
            ("routage.arrondi_cle_decimales", json!(4)),
            ("drapeau.livraison_offerte_mefali", json!(false)),
            ("drapeau.gratuite_commissions", json!(false)),
            ("drapeau.pluie", json!(false)),
        ] {
            z.definir_parametre(&mut tx, ville, cle, valeur, "bac")
                .await
                .unwrap();
        }
        tx.commit().await.unwrap();

        let grille = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO tarification.grille (id, zone_id, version, etat, effet_le)
             VALUES ($1, $2, 1, 'en_vigueur', now())",
        )
        .bind(grille)
        .bind(ville)
        .execute(&pool)
        .await
        .unwrap();

        let bac = Self {
            pool,
            pays,
            ville,
            grille,
        };
        // Grille de départ Tiassalé (FR-026) : à pied 100 (≤ 800 m),
        // vélo 150 (≤ 2 km), moto 200 + 50/km au-delà de 2 km, plafond 500.
        bac.poser_regle("a_pied", 50, 50, 0, 0, Some(800), None).await;
        bac.poser_regle("velo", 100, 50, 0, 0, Some(2_000), None).await;
        bac.poser_regle("moto", 150, 50, 50, 2_000, None, Some(500))
            .await;
        bac
    }

    /// Insère une règle dans la grille en vigueur (la publication arrive en US3).
    #[allow(clippy::too_many_arguments)]
    pub async fn poser_regle(
        &self,
        transport: &str,
        part_coursier_base: i64,
        marge: i64,
        prix_par_km: i64,
        seuil_km_m: i32,
        distance_max_m: Option<i32>,
        prix_plafond: Option<i64>,
    ) -> Uuid {
        let id = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO tarification.regle
                (id, grille_id, transport_slug, distance_min_m, distance_max_m,
                 part_coursier_base, marge, prix_par_km, seuil_km_m, prix_plafond, devise)
             VALUES ($1, $2, $3, 0, $4, $5, $6, $7, $8, $9, 'XOF')",
        )
        .bind(id)
        .bind(self.grille)
        .bind(transport)
        .bind(distance_max_m)
        .bind(part_coursier_base)
        .bind(marge)
        .bind(prix_par_km)
        .bind(seuil_km_m)
        .bind(prix_plafond)
        .execute(&self.pool)
        .await
        .unwrap();
        id
    }

    /// Allume ou éteint un drapeau de la ville (`drapeau.<cle>`).
    pub async fn poser_drapeau(&self, cle: &str, valeur: bool) {
        self.poser_parametre(&format!("drapeau.{cle}"), json!(valeur))
            .await;
    }

    /// Pose un paramètre de zone quelconque au niveau VILLE.
    pub async fn poser_parametre(&self, cle: &str, valeur: Value) {
        let z = PgZones::new(self.pool.clone());
        let mut tx = self.pool.begin().await.unwrap();
        z.definir_parametre(&mut tx, self.ville, cle, valeur, "bac")
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }

    /// Moteur branché sur les doubles fournis.
    pub fn moteur(&self, routage: Arc<dyn Routage>, cache: Arc<dyn CacheRoutage>) -> PgTarification {
        PgTarification::new(self.pool.clone(), routage, cache)
    }

    /// Moteur sur routage indisponible (mode dégradé).
    pub fn moteur_degrade(&self) -> PgTarification {
        self.moteur(Arc::new(RoutageIndisponible), Arc::new(CacheMemoire::nouveau()))
    }

    /// Payloads des événements outbox d'un type, dans l'ordre d'écriture.
    pub async fn evenements(&self, type_evenement: &str) -> Vec<Value> {
        sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement WHERE type_evenement = $1 ORDER BY id",
        )
        .bind(type_evenement)
        .fetch_all(&self.pool)
        .await
        .unwrap()
    }

    /// Nombre total d'événements outbox, tous types confondus.
    pub async fn nb_evenements(&self) -> i64 {
        sqlx::query_scalar("SELECT count(*) FROM outbox.evenement")
            .fetch_one(&self.pool)
            .await
            .unwrap()
    }

    /// Demande de devis nominale : `nb_retraits` retraits + un client, sans
    /// panier vendeur ni attente.
    pub fn demande(&self, transport: &str, nb_retraits: usize) -> DemandeDevis {
        DemandeDevis {
            zone_id: self.ville,
            transport_slug: transport.to_owned(),
            retraits: (0..nb_retraits)
                .map(|i| point_a(100.0 * (i + 1) as f64))
                .collect(),
            client: point_a(0.0),
            nb_articles: 1,
            instant: instant("2026-07-22T19:30:00Z"),
            categorie_slug: None,
            attentes: Vec::new(),
            montant_panier: 0,
            offre_livraison_vendeur: None,
            mono_vendeur: false,
        }
    }
}

/// Point situé à `offset_m` mètres au nord du point de référence.
pub fn point_a(offset_m: f64) -> Point {
    Point {
        lat: BASE_LAT + offset_m * DEGRES_PAR_METRE,
        lon: BASE_LON,
    }
}

/// Instant UTC depuis un littéral RFC 3339.
pub fn instant(s: &str) -> DateTime<Utc> {
    s.parse().unwrap()
}

/// Matrice déterministe depuis des positions sur une ligne (mètres). Les
/// distances sont alors vérifiables à la main.
pub fn matrice_ligne(positions: &[i64]) -> Matrice {
    let n = positions.len();
    let mut d = vec![0i64; n * n];
    let mut t = vec![0i64; n * n];
    for i in 0..n {
        for j in 0..n {
            d[i * n + j] = (positions[i] - positions[j]).abs();
            t[i * n + j] = d[i * n + j] / 5; // ~18 km/h, sans effet sur les montants
        }
    }
    Matrice::nouvelle(n, d, t, false).unwrap()
}

/// Routage DÉTERMINISTE : rend toujours la matrice fournie, et compte ses
/// appels — c'est le compteur qui rend SC-004 démontrable.
pub struct RoutageFixe {
    matrice: Matrice,
    appels: AtomicUsize,
}

impl RoutageFixe {
    /// Double rendant la matrice construite depuis ces positions.
    pub fn depuis_positions(positions: &[i64]) -> Self {
        Self {
            matrice: matrice_ligne(positions),
            appels: AtomicUsize::new(0),
        }
    }

    /// Nombre d'appels de routage reçus.
    pub fn appels(&self) -> usize {
        self.appels.load(Ordering::SeqCst)
    }
}

#[async_trait]
impl Routage for RoutageFixe {
    async fn matrice(&self, points: &[Point]) -> Result<Matrice, ErreurRoutage> {
        self.appels.fetch_add(1, Ordering::SeqCst);
        assert_eq!(
            points.len(),
            self.matrice.taille(),
            "le double doit couvrir exactement les points demandés"
        );
        Ok(self.matrice.clone())
    }
}
