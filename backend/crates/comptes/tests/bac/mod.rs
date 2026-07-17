//! Bac d'essai partagé par les tests d'intégration du crate `comptes`.
//!
//! Monte un `PgComptes` sur une base éphémère, une zone Tiassalé minimale
//! (indicatif hérité du pays, comme le seed `20_comptes.sql`) et des ports en
//! mémoire.

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use comptes::inscription::IssueVerification;
use comptes::{Appareil, MemoireEphemere, MemoireObjets, PgComptes, Plateforme, SmsTraces};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;
use zones::{PgZones, TypeZone};

pub const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";
pub const SAISIE_LOCALE: &str = "0701020304";
pub const E164: &str = "+2250701020304";

/// Session ouverte par un test, avec de quoi la manipuler.
pub struct SessionTest {
    /// Identifiant de session (claim `sid` du jeton d'accès).
    pub session: Uuid,
    /// Jeton d'accès.
    pub acces: String,
    /// Refresh opaque en clair.
    pub rafraichissement: String,
}

pub struct Bac {
    pub depot: PgComptes,
    pub sms: Arc<SmsTraces>,
    pub objets: Arc<MemoireObjets>,
    pub zone: Uuid,
    pub pays: Uuid,
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
        for (cle, valeur) in [
            ("telephone.indicatif_defaut", json!("+225")),
            ("adresse.retention_repere_vocal_jours", json!(365)),
            ("medias.note_vocale_duree_max_s", json!(30)),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "test")
                .await
                .unwrap();
        }
        tx.commit().await.unwrap();

        let sms = Arc::new(SmsTraces::new());
        let objets = Arc::new(MemoireObjets::new());
        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            sms.clone(),
            objets.clone(),
            Arc::from(SECRET),
        );
        Self {
            depot,
            sms,
            objets,
            zone: ville,
            pays,
            pool,
        }
    }

    pub fn appareil(&self, nom: &str) -> Appareil {
        Appareil {
            nom: nom.to_owned(),
            plateforme: Plateforme::Android,
        }
    }

    /// Demande un code et renvoie celui qui est parti au SMS.
    pub async fn code(&self, saisie: &str) -> String {
        self.depot
            .demander_otp(self.zone, saisie, "1.2.3.4")
            .await
            .unwrap();
        self.sms.envoyes().last().unwrap().params["code"]
            .as_str()
            .unwrap()
            .to_owned()
    }

    /// Parcours complet jusqu'au compte créé.
    pub async fn inscrire(&self, saisie: &str) -> Uuid {
        let code = self.code(saisie).await;
        let issue = self
            .depot
            .verifier_otp(self.zone, saisie, &code, &self.appareil("Pixel de test"))
            .await
            .unwrap();
        let IssueVerification::ConsentementRequis { jeton_inscription } = issue else {
            panic!("un numéro inconnu doit exiger le consentement");
        };
        self.depot
            .inscrire(&jeton_inscription, "2026-07")
            .await
            .unwrap()
            .compte
            .id
    }

    /// Ouvre une session supplémentaire sur un numéro DÉJÀ inscrit.
    pub async fn ouvrir_session(&self, saisie: &str, nom_appareil: &str) -> SessionTest {
        let code = self.code(saisie).await;
        let issue = self
            .depot
            .verifier_otp(self.zone, saisie, &code, &self.appareil(nom_appareil))
            .await
            .unwrap();
        let IssueVerification::Session(ouverte) = issue else {
            panic!("le numéro doit déjà être inscrit");
        };
        // L'identifiant de session vit dans le claim `sid` : le lire ici exerce
        // au passage l'émission du jeton.
        let claims = comptes::verifier_acces(SECRET, &ouverte.jetons.acces).unwrap();
        SessionTest {
            session: claims.sid,
            acces: ouverte.jetons.acces,
            rafraichissement: ouverte.jetons.rafraichissement,
        }
    }

    /// Pose le référentiel des transports et les actifs de la ville.
    ///
    /// ⚠ Ces lignes vivent dans `seeds/10_zones_tiassale.sql`, et
    /// `#[sqlx::test]` ne rejoue QUE les migrations : sans cet appel, le
    /// référentiel est vide et toute déclaration de véhicule échoue. Extrait
    /// fidèle du seed (mêmes slugs, même ordre) — dont `camion`, présent au
    /// référentiel mais INACTIF à Tiassalé : c'est lui qui prouve le 422
    /// `VehiculeHorsZone`.
    pub async fn seeder_transports(&self) {
        for (slug, ordre) in [("a_pied", 1), ("velo", 2), ("moto", 3), ("camion", 8)] {
            sqlx::query(
                "INSERT INTO zones.type_transport (id, slug, nom_cle, ordre)
                 VALUES ($1, $2, $3, $4)",
            )
            .bind(Uuid::now_v7())
            .bind(slug)
            .bind(format!("transport.{slug}.nom"))
            .bind(ordre)
            .execute(&self.pool)
            .await
            .unwrap();
        }
        self.definir_transports_actifs(&["a_pied", "velo", "moto"])
            .await;
    }

    /// Redéfinit `transport.actifs` de la VILLE (le seed le pose au niveau
    /// ville, pas pays — la désactivation d'un type est une décision locale).
    pub async fn definir_transports_actifs(&self, slugs: &[&str]) {
        let mut tx = self.pool.begin().await.unwrap();
        PgZones::new(self.pool.clone())
            .definir_parametre(&mut tx, self.zone, "transport.actifs", json!(slugs), "test")
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }

    pub async fn compter(&self, sql: &'static str) -> i64 {
        sqlx::query_scalar(sql).fetch_one(&self.pool).await.unwrap()
    }

    pub async fn evenements(&self, type_evenement: &str) -> Vec<serde_json::Value> {
        sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement WHERE type_evenement = $1
             ORDER BY id",
        )
        .bind(type_evenement)
        .fetch_all(&self.pool)
        .await
        .unwrap()
    }
}
