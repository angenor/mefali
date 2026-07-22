//! Bac d'essai partagé par les tests d'intégration du crate `prestataires`
//! (patron du bac comptes, cycle 003).
//!
//! Monte un `PgPrestataires` sur une base éphémère : arbre CI → Tiassalé,
//! deux catégories (restauration, boutique_superette) avec des seuils
//! d'activation BAS (2 et 1 — franchissables par un test), les paramètres de
//! zone du cycle (masquage 2/7 j, affichage grisé, fuseau, devise XOF), des
//! ports mémoire et le double `CommandesActivesFixes`.

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use chrono::NaiveDate;
use comptes::{MemoireEphemere, PgComptes, SmsTraces};
use prestataires::modele::{HorairesSemaine, Plage};
use prestataires::{
    CommandesActives, CommandesActivesFixes, NouveauPrestataire, PgPrestataires, Prestataire,
};
use serde_json::json;
use socle::{DepotObjets, MemoireObjets};
use sqlx::PgPool;
use uuid::Uuid;
use zones::{PgZones, TypeZone};

pub const SECRET_JWT: &[u8] = b"secret-de-test-de-32-octets-mini";
pub const SECRET_PLAQUE: &[u8] = b"secret-plaque-de-test-32-octets!";

/// Seuil d'activation de `restauration` dans le bac — 2, pour qu'un test
/// puisse franchir le seuil en agréant DEUX prestataires (SC-010) et
/// constater l'inactivité avec UN seul (SC-004).
pub const SEUIL_RESTAURATION: i64 = 2;

pub struct Bac {
    pub depot: PgPrestataires,
    pub comptes: PgComptes,
    pub objets: Arc<MemoireObjets>,
    pub commandes: Arc<CommandesActivesFixes>,
    pub pays: Uuid,
    pub ville: Uuid,
    pub categorie_restauration: Uuid,
    pub categorie_boutique: Uuid,
    /// Compte admin (décideur des transitions — `decide_par`, `acteur`).
    pub admin: Uuid,
    pub pool: PgPool,
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

        // Catégories de service (référentiel du cycle 002).
        let categorie_restauration = Uuid::now_v7();
        let categorie_boutique = Uuid::now_v7();
        for (id, slug, workflow) in [
            (categorie_restauration, "restauration", "restauration"),
            (categorie_boutique, "boutique_superette", "coursier_acheteur"),
        ] {
            sqlx::query(
                "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
                 VALUES ($1, $2, $3, $4)",
            )
            .bind(id)
            .bind(slug)
            .bind(format!("categorie.{slug}.nom"))
            .bind(workflow)
            .execute(&mut *tx)
            .await
            .unwrap();
        }

        // Paramètres hérités — mêmes clés que les seeds (niveau pays), seuils
        // au niveau ville (miroir de 10_zones_tiassale.sql).
        for (cle, valeur) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("zone.fuseau_horaire", json!("Africa/Abidjan")),
            ("charte.conservation_post_relation_annees", json!(5)),
            ("categorie.restauration.affichage_rupture", json!("grise")),
            (
                "categorie.boutique_superette.affichage_rupture",
                json!("grise"),
            ),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        for (cle, valeur) in [
            ("rupture.masquage_seuil", json!(2)),
            ("rupture.masquage_fenetre_jours", json!(7)),
            (
                "categorie.restauration.seuil_activation",
                json!(SEUIL_RESTAURATION),
            ),
            ("categorie.boutique_superette.seuil_activation", json!(1)),
        ] {
            z.definir_parametre(&mut tx, ville, cle, valeur, "bac")
                .await
                .unwrap();
        }
        tx.commit().await.unwrap();

        let objets = Arc::new(MemoireObjets::new());
        let objets_dyn: Arc<dyn DepotObjets> = objets.clone();
        let commandes = Arc::new(CommandesActivesFixes::nouveau());
        let commandes_dyn: Arc<dyn CommandesActives> = commandes.clone();
        let comptes = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            objets_dyn.clone(),
            Arc::from(SECRET_JWT),
        );
        let depot = PgPrestataires::new(
            pool.clone(),
            comptes.clone(),
            objets_dyn,
            commandes_dyn,
            Arc::from(SECRET_PLAQUE),
        );

        let mut bac = Self {
            depot,
            comptes,
            objets,
            commandes,
            pays,
            ville,
            categorie_restauration,
            categorie_boutique,
            admin: Uuid::nil(),
            pool,
        };
        bac.admin = bac.creer_compte("+2250700000001").await;
        bac
    }

    /// Compte MINIMAL (numéro vérifié + consentement) posé en SQL direct : les
    /// parcours OTP appartiennent aux tests du cycle 003 — ici un compte n'est
    /// qu'une cible de FK (`decide_par`, rattachements, signalements).
    pub async fn creer_compte(&self, e164: &str) -> Uuid {
        let id = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO comptes.compte
                 (id, telephone_e164, zone_id, consentement_version, consentement_le)
             VALUES ($1, $2, $3, '2026-07', now())",
        )
        .bind(id)
        .bind(e164)
        .bind(self.ville)
        .execute(&self.pool)
        .await
        .unwrap();
        id
    }

    /// Horaires type de Tantie Affoué : 8 h — 19 h du lundi au samedi.
    pub fn horaires_type() -> HorairesSemaine {
        let mut horaires = HorairesSemaine::default();
        for jour in 0..6 {
            horaires.jours[jour].push(Plage {
                debut: chrono::NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
                fin: chrono::NaiveTime::from_hms_opt(19, 0, 0).unwrap(),
            });
        }
        horaires
    }

    /// Crée une fiche prospect (sans photo, charte ni site).
    pub async fn creer_fiche(&self, nom: &str, categorie_slug: &str) -> Uuid {
        let mut tx = self.pool.begin().await.unwrap();
        let p = self
            .depot
            .creer_prestataire(
                &mut tx,
                &NouveauPrestataire {
                    nom: nom.to_owned(),
                    categorie_slug: categorie_slug.to_owned(),
                    ville_id: self.ville,
                    contact_telephone: "+2250700000099".to_owned(),
                    delai_preparation_min: 20,
                },
                self.admin,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        p.id
    }

    /// Complète un prospect : photo, charte signée, site avec horaires type.
    pub async fn completer_fiche(&self, prestataire: Uuid) {
        let mut tx = self.pool.begin().await.unwrap();
        self.depot
            .ajouter_photo(
                &mut tx,
                prestataire,
                vec![0xFF, 0xD8, 0xFF],
                "image/jpeg",
                self.admin,
            )
            .await
            .unwrap();
        self.depot
            .deposer_charte(
                &mut tx,
                prestataire,
                vec![0x25, 0x50, 0x44, 0x46],
                "application/pdf",
                "2026-07",
                NaiveDate::from_ymd_opt(2026, 7, 18).unwrap(),
                self.admin,
            )
            .await
            .unwrap();
        self.depot
            .definir_site(
                &mut tx,
                prestataire,
                5.898,
                -4.823,
                &Self::horaires_type(),
                None,
                self.admin,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }

    /// Fiche prospect COMPLÈTE (prête à agréer).
    pub async fn prospect_complet(&self, nom: &str, categorie_slug: &str) -> Uuid {
        let id = self.creer_fiche(nom, categorie_slug).await;
        self.completer_fiche(id).await;
        id
    }

    /// Agrée (transaction dédiée) et rend la fiche.
    pub async fn agreer(&self, prestataire: Uuid) -> Prestataire {
        let mut tx = self.pool.begin().await.unwrap();
        let p = self.depot.agreer(&mut tx, prestataire, self.admin).await.unwrap();
        tx.commit().await.unwrap();
        p
    }

    pub async fn compter(&self, sql: &'static str) -> i64 {
        sqlx::query_scalar(sql).fetch_one(&self.pool).await.unwrap()
    }

    /// Payloads des événements d'un type, dans l'ordre d'émission.
    pub async fn evenements(&self, type_evenement: &str) -> Vec<serde_json::Value> {
        sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement WHERE type_evenement = $1 ORDER BY id",
        )
        .bind(type_evenement)
        .fetch_all(&self.pool)
        .await
        .unwrap()
    }

    /// L'état effectif d'activation d'une catégorie dans la ville du bac
    /// (colonne GÉNÉRÉE `actif` — ZON-03).
    pub async fn categorie_active(&self, categorie: Uuid) -> bool {
        sqlx::query_scalar(
            "SELECT actif FROM zones.activation_categorie
             WHERE zone_id = $1 AND categorie_id = $2",
        )
        .bind(self.ville)
        .bind(categorie)
        .fetch_optional(&self.pool)
        .await
        .unwrap()
        .unwrap_or(false)
    }
}
