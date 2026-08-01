//! Bac d'essai partagé des tests d'intégration du crate `qr` (patron du bac
//! prestataires, cycle 005).
//!
//! Monte un `PgQr` sur base éphémère : arbre CI → Tiassalé, catégories
//! (restauration facultative, pharmacie obligatoire), paramètres de zone QRC
//! (distance de scan 100 m, seuil photo 10 000 XOF), agrément RÉEL via
//! `PgPrestataires` (jeton/code de plaque), et un déclencheur de course simulé
//! (`livraison → segment → arrêt` assigné au coursier — patron R10).

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use chrono::NaiveDate;
use comptes::{MemoireEphemere, PgComptes, SmsTraces};
use prestataires::modele::{HorairesSemaine, Plage};
use prestataires::{
    AucuneCommandeActive, CommandesActives, NouveauPrestataire, PgPrestataires,
};
use qr::{CompteurEssais, CompteurMemoire, PgQr};
use serde_json::json;
use socle::{DepotObjets, MemoireObjets};
use sqlx::PgPool;
use uuid::Uuid;
use zones::{PgZones, TypeZone};

pub const SECRET_JWT: &[u8] = b"secret-de-test-de-32-octets-mini";
pub const SECRET_PLAQUE: &[u8] = b"secret-plaque-de-test-32-octets!";

/// Position du site de test (Tiassalé) — les scans s'y comparent.
pub const SITE_LAT: f64 = 5.898;
pub const SITE_LON: f64 = -4.823;

pub struct Bac {
    pub qr: PgQr,
    pub prestataires: PgPrestataires,
    pub objets: Arc<MemoireObjets>,
    pub essais: Arc<CompteurMemoire>,
    pub pays: Uuid,
    pub ville: Uuid,
    pub categorie_restauration: Uuid,
    pub categorie_pharmacie: Uuid,
    pub admin: Uuid,
    pub coursier: Uuid,
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

        // Catégories : restauration (facultative, défaut) + pharmacie (obligatoire).
        let categorie_restauration = Uuid::now_v7();
        let categorie_pharmacie = Uuid::now_v7();
        for (id, slug, workflow, politique) in [
            (categorie_restauration, "restauration", "restauration", "facultative"),
            (categorie_pharmacie, "pharmacie", "coursier_acheteur", "obligatoire"),
        ] {
            sqlx::query(
                "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur, politique_photo)
                 VALUES ($1, $2, $3, $4, $5::zones.politique_photo)",
            )
            .bind(id)
            .bind(slug)
            .bind(format!("categorie.{slug}.nom"))
            .bind(workflow)
            .bind(politique)
            .execute(&mut *tx)
            .await
            .unwrap();
        }

        for (cle, valeur) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("zone.fuseau_horaire", json!("Africa/Abidjan")),
            ("charte.conservation_post_relation_annees", json!(5)),
            ("qr.distance_scan_max_m", json!(100)),
            ("qr.photo_seuil_montant", json!(10000)),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        tx.commit().await.unwrap();

        let objets = Arc::new(MemoireObjets::new());
        let objets_dyn: Arc<dyn DepotObjets> = objets.clone();
        let commandes_actives: Arc<dyn CommandesActives> = Arc::new(AucuneCommandeActive);
        let comptes = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            objets_dyn.clone(),
            Arc::from(SECRET_JWT),
        );
        let prestataires = PgPrestataires::new(
            pool.clone(),
            comptes.clone(),
            objets_dyn.clone(),
            commandes_actives,
            Arc::from(SECRET_PLAQUE),
        );
        let essais = Arc::new(CompteurMemoire::nouveau());
        let essais_dyn: Arc<dyn CompteurEssais> = essais.clone();
        // Le dépôt commandes a gagné ses collaborateurs au cycle CMD 008. QRC
        // n'exerce que la collecte par arrêt : le tarif et les restrictions
        // passent par des doubles, le catalogue par le dépôt réel.
        let tarif = Arc::new(commandes::TarifFixe::simple(2_500, 2_500, 0));
        let depot_commandes = commandes::PgCommandes::new(
            pool.clone(),
            prestataires.clone(),
            tarif.clone(),
            tarif,
            Arc::new(commandes::RestrictionsSimulees::nouveau()),
            objets_dyn.clone(),
            Arc::new(commandes::PositionFixe::nouveau()),
            Arc::new(commandes::PreuvesFixes::nouveau()),
        );
        let qr = PgQr::new(
            pool.clone(),
            depot_commandes,
            prestataires.clone(),
            objets_dyn,
            essais_dyn,
        );

        let mut bac = Self {
            qr,
            prestataires,
            objets,
            essais,
            pays,
            ville,
            categorie_restauration,
            categorie_pharmacie,
            admin: Uuid::nil(),
            coursier: Uuid::nil(),
            pool,
        };
        bac.admin = bac.creer_compte("+2250700000001").await;
        bac.coursier = bac.creer_compte("+2250700000002").await;
        bac
    }

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

    fn horaires_type() -> HorairesSemaine {
        let mut horaires = HorairesSemaine::default();
        for jour in 0..6 {
            horaires.jours[jour].push(Plage {
                debut: chrono::NaiveTime::from_hms_opt(8, 0, 0).unwrap(),
                fin: chrono::NaiveTime::from_hms_opt(19, 0, 0).unwrap(),
            });
        }
        horaires
    }

    /// Agrée un prestataire (fiche complète) et renvoie `(id, jeton, code)`.
    pub async fn prestataire_agree(&self, nom: &str, categorie_slug: &str) -> (Uuid, String, String) {
        let mut tx = self.pool.begin().await.unwrap();
        let p = self
            .prestataires
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
        self.prestataires
            .ajouter_photo(&mut tx, p.id, vec![0xFF, 0xD8, 0xFF], "image/jpeg", self.admin)
            .await
            .unwrap();
        self.prestataires
            .deposer_charte(
                &mut tx,
                p.id,
                vec![0x25, 0x50, 0x44, 0x46],
                "application/pdf",
                "2026-07",
                NaiveDate::from_ymd_opt(2026, 7, 18).unwrap(),
                self.admin,
            )
            .await
            .unwrap();
        self.prestataires
            .definir_site(&mut tx, p.id, SITE_LAT, SITE_LON, &Self::horaires_type(), None, self.admin)
            .await
            .unwrap();
        self.prestataires.agreer(&mut tx, p.id, self.admin).await.unwrap();
        tx.commit().await.unwrap();

        let ctx = self
            .prestataires
            .contexte_plaque(p.id)
            .await
            .unwrap()
            .expect("plaque posée à l'agrément");
        (p.id, ctx.jeton_plaque, ctx.code_secours)
    }

    /// Suspend un prestataire agréé (révocation observée).
    pub async fn suspendre(&self, prestataire: Uuid) {
        let mut tx = self.pool.begin().await.unwrap();
        self.prestataires
            .suspendre(&mut tx, prestataire, "test", self.admin)
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }

    /// Rétablit un prestataire suspendu.
    pub async fn retablir(&self, prestataire: Uuid) {
        let mut tx = self.pool.begin().await.unwrap();
        self.prestataires
            .retablir(&mut tx, prestataire, self.admin)
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }

    /// Déclencheur de course simulé (R10) : une livraison assignée au coursier
    /// avec un segment et des arrêts (prestataire, montant). Renvoie les
    /// `(arret_id, ...)` dans l'ordre. `montant` par arrêt en unités mineures.
    pub async fn simuler_course(&self, arrets: &[(Uuid, i64)]) -> Vec<Uuid> {
        let commande = Uuid::now_v7();
        let livraison = Uuid::now_v7();
        let segment = Uuid::now_v7();
        let mut tx = self.pool.begin().await.unwrap();
        // Le tronc a reçu ses colonnes métier en migration `0009` (cycle CMD
        // 008) : la fixture les renseigne. Le client de la course est l'admin du
        // bac — le seul compte dont ce harnais dispose ; QRC ne regarde jamais
        // le client, seulement le coursier assigné.
        let total: i64 = arrets.iter().map(|(_, m)| m).sum();
        sqlx::query(
            "INSERT INTO commandes.commande
                (id, client_id, zone_id, categorie_id, lieu_lat, lieu_lon,
                 montant_articles_unites, total_unites, devise, mode_paiement,
                 code_livraison, code_livraison_hash, jeton_reception, jeton_reception_hash)
             VALUES ($1, $2, $3, $4, 5.900, -4.820, $5, $5, 'XOF', 'cash',
                     '7341', 'h-code', 'jeton', 'h-jeton')",
        )
        .bind(commande)
        .bind(self.admin)
        .bind(self.ville)
        .bind(self.categorie_restauration)
        .bind(total)
        .execute(&mut *tx)
        .await
        .unwrap();
        sqlx::query(
            "INSERT INTO commandes.livraison (id, commande_id, coursier_id) VALUES ($1, $2, $3)",
        )
        .bind(livraison)
        .bind(commande)
        .bind(self.coursier)
        .execute(&mut *tx)
        .await
        .unwrap();
        sqlx::query("INSERT INTO commandes.segment (id, livraison_id, ordre) VALUES ($1, $2, 0)")
            .bind(segment)
            .bind(livraison)
            .execute(&mut *tx)
            .await
            .unwrap();
        let mut ids = Vec::new();
        for (i, (prestataire, montant)) in arrets.iter().enumerate() {
            let arret = Uuid::now_v7();
            sqlx::query(
                // Cycle PAY 011 : les trois colonnes de retenue tiennent
                // l'invariant `arret_avance_coherente` — articles = avance,
                // retenue nulle tant que rien n'est collecté.
                "INSERT INTO commandes.arret
                    (id, segment_id, prestataire_id, ordre, site_lat, site_lon, montant_avance, devise,
                     montant_articles_unites, retenue_appliquee_unites)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, 'XOF', $7, 0)",
            )
            .bind(arret)
            .bind(segment)
            .bind(prestataire)
            .bind(i as i16)
            .bind(SITE_LAT)
            .bind(SITE_LON)
            .bind(montant)
            .execute(&mut *tx)
            .await
            .unwrap();
            ids.push(arret);
        }
        tx.commit().await.unwrap();
        ids
    }

    /// Pose un arrêt à `indisponible` (façon CMD-06) pour tester le gating.
    pub async fn poser_indisponible(&self, arret: Uuid) {
        sqlx::query("UPDATE commandes.arret SET statut = 'indisponible' WHERE id = $1")
            .bind(arret)
            .execute(&self.pool)
            .await
            .unwrap();
    }

    pub async fn compter(&self, sql: &'static str) -> i64 {
        sqlx::query_scalar(sql).fetch_one(&self.pool).await.unwrap()
    }

    pub async fn evenements(&self, type_evenement: &str) -> Vec<serde_json::Value> {
        sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement WHERE type_evenement = $1 ORDER BY id",
        )
        .bind(type_evenement)
        .fetch_all(&self.pool)
        .await
        .unwrap()
    }

    /// Statut courant d'un arrêt.
    pub async fn statut_arret(&self, arret: Uuid) -> String {
        sqlx::query_scalar("SELECT statut::text FROM commandes.arret WHERE id = $1")
            .bind(arret)
            .fetch_one(&self.pool)
            .await
            .unwrap()
    }
}

/// Construit une `DemandeCollecte` de scan à la position donnée.
pub fn demande_scan(arret: Uuid, jeton: &str, lat: f64, lon: f64) -> qr::DemandeCollecte {
    qr::DemandeCollecte {
        arret_id: arret,
        mode: commandes::ModeCollecte::ScanQr,
        jeton: Some(jeton.to_owned()),
        code: None,
        position_lat: lat,
        position_lon: lon,
        photo: None,
        uuid_client: Uuid::now_v7(),
        horodatage_local: chrono::Utc::now(),
    }
}

/// Construit une `DemandeCollecte` par code de secours.
pub fn demande_code(arret: Uuid, code: &str, lat: f64, lon: f64) -> qr::DemandeCollecte {
    qr::DemandeCollecte {
        arret_id: arret,
        mode: commandes::ModeCollecte::CodeSecours,
        jeton: None,
        code: Some(code.to_owned()),
        position_lat: lat,
        position_lon: lon,
        photo: None,
        uuid_client: Uuid::now_v7(),
        horodatage_local: chrono::Utc::now(),
    }
}
