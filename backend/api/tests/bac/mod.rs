//! Bac d'essai partagé des tests d'intégration HTTP du cycle TRF (007).
//!
//! Monte l'application Actix RÉELLE (mêmes handlers, même extracteur [`Auth`],
//! mêmes gardes de rôle) sur une base éphémère : arbre CI → Tiassalé, devise
//! XOF, bornes de marge 25–100, et des comptes porteurs de rôles VALIDES avec
//! de vrais jetons d'accès signés.
//!
//! Pourquoi passer par HTTP plutôt que d'appeler le domaine : les refus
//! `401`/`403` et le mapping `409` des clés i18n n'existent QUE dans cette
//! couche. Un test de domaine ne peut pas prouver qu'un endpoint d'admin est
//! fermé (FR-005) — celui-ci, si.

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use actix_web::web;
use comptes::{MemoireEphemere, PgComptes, SmsTraces};
use serde_json::{json, Value};
use socle::{DepotObjets, MemoireObjets};
use sqlx::PgPool;
use tarification::{CacheDesactive, PgTarification, RoutageIndisponible};
use uuid::Uuid;
use zones::{PgZones, TypeZone};

pub const SECRET_JWT: &[u8] = b"secret-de-test-de-32-octets-mini";

/// Bornes de marge seedées par le bac (défaut documenté du produit).
pub const MARGE_MIN: i64 = 25;
/// Borne haute de marge du bac.
pub const MARGE_MAX: i64 = 100;

pub struct Bac {
    pub pool: PgPool,
    pub comptes: PgComptes,
    pub tarification: PgTarification,
    pub pays: Uuid,
    pub ville: Uuid,
    /// Compte porteur du rôle admin (valide).
    pub admin: Uuid,
    /// Jeton d'accès de l'admin.
    pub jeton_admin: String,
    /// Compte porteur du seul rôle client — sert à prouver le 403.
    pub client: Uuid,
    /// Jeton d'accès du client.
    pub jeton_client: String,
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
        // Devise et fuseau au PAYS (hérités) ; knobs tarifaires à la VILLE —
        // même répartition que le seed 10_zones_tiassale.sql.
        for (cle, valeur) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("zone.fuseau_horaire", json!("Africa/Abidjan")),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        for (cle, valeur) in [
            ("tarification.marge.min", json!(MARGE_MIN)),
            ("tarification.marge.max", json!(MARGE_MAX)),
        ] {
            z.definir_parametre(&mut tx, ville, cle, valeur, "bac")
                .await
                .unwrap();
        }
        tx.commit().await.unwrap();

        let objets: Arc<dyn DepotObjets> = Arc::new(MemoireObjets::new());
        let comptes = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            objets,
            Arc::from(SECRET_JWT),
        );
        let tarification = PgTarification::new(
            pool.clone(),
            Arc::new(RoutageIndisponible),
            Arc::new(CacheDesactive),
        );

        let mut bac = Self {
            pool,
            comptes,
            tarification,
            pays,
            ville,
            admin: Uuid::nil(),
            jeton_admin: String::new(),
            client: Uuid::nil(),
            jeton_client: String::new(),
        };
        let (admin, jeton_admin) = bac.compte_avec_roles("+2250700000001", &["client", "admin"]).await;
        let (client, jeton_client) = bac.compte_avec_roles("+2250700000002", &["client"]).await;
        bac.admin = admin;
        bac.jeton_admin = jeton_admin;
        bac.client = client;
        bac.jeton_client = jeton_client;
        bac
    }

    /// Crée un compte, lui attribue des rôles VALIDES, ouvre une session et rend
    /// son jeton d'accès signé — exactement ce que l'extracteur `Auth` relit.
    pub async fn compte_avec_roles(&self, e164: &str, roles: &[&str]) -> (Uuid, String) {
        let compte = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO comptes.compte
                 (id, telephone_e164, zone_id, consentement_version, consentement_le)
             VALUES ($1, $2, $3, '2026-07', now())",
        )
        .bind(compte)
        .bind(e164)
        .bind(self.ville)
        .execute(&self.pool)
        .await
        .unwrap();

        for role in roles {
            sqlx::query(
                "INSERT INTO comptes.attribution_role (compte_id, role, statut, decide_le)
                 VALUES ($1, $2::text::comptes.role, 'valide'::comptes.statut_role, now())",
            )
            .bind(compte)
            .bind(role)
            .execute(&self.pool)
            .await
            .unwrap();
        }

        let session = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO comptes.session
                 (id, compte_id, refresh_hash, appareil_nom, appareil_plateforme)
             VALUES ($1, $2, $3, 'bac', 'android')",
        )
        .bind(session)
        .bind(compte)
        .bind(comptes::session::hacher_refresh(&session.to_string()))
        .execute(&self.pool)
        .await
        .unwrap();

        let jeton = comptes::session::emettre_acces(SECRET_JWT, compte, session).unwrap();
        (compte, jeton)
    }

    /// Configure une `App` Actix avec les MÊMES handlers que la production.
    ///
    /// Rendu comme closure de configuration plutôt que comme service déjà monté :
    /// le type concret d'un `init_service` n'est pas nommable sans traîner
    /// `actix_http` en dépendance directe.
    pub fn configurer(&self) -> impl FnOnce(&mut web::ServiceConfig) {
        use api::admin_tarification_http as tarif;
        let pool = self.pool.clone();
        let comptes = self.comptes.clone();
        let tarification = self.tarification.clone();
        move |cfg: &mut web::ServiceConfig| {
            cfg.app_data(web::Data::new(pool))
                .app_data(web::Data::new(comptes))
                .app_data(web::Data::new(tarification))
                .service(tarif::grille_de_zone)
                .service(tarif::creer_brouillon)
                .service(tarif::ecrire_regle)
                .service(tarif::supprimer_regle)
                .service(tarif::simuler)
                .service(tarif::publier);
        }
    }

    pub async fn compter(&self, sql: &'static str) -> i64 {
        sqlx::query_scalar(sql).fetch_one(&self.pool).await.unwrap()
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
}

/// Corps JSON d'une règle bien formée (moto, grille de Tiassalé).
pub fn regle_moto(marge: i64) -> Value {
    json!({
        "transport_slug": "moto",
        "categorie_slug": null,
        "distance_min_m": 0,
        "distance_max_m": null,
        "plage_debut_min": null,
        "plage_fin_min": null,
        "jours_masque": null,
        "part_coursier_base": 150,
        "marge": marge,
        "prix_par_km": 50,
        "seuil_km_m": 2000,
        "prix_plafond": 500,
        "devise": "XOF",
        "priorite": 0,
        "actif": true
    })
}

/// Corps d'une course simulée : un vendeur, une destination, en moto.
pub fn course_simulee() -> Value {
    json!({
        "vendeurs": [{"lat": 5.9020, "lon": -4.8180}],
        "destination": {"lat": 5.8980, "lon": -4.8230},
        "transport_slug": "moto",
        "instant": "2026-07-22T19:30:00Z",
        "nb_articles": 3,
        "categorie_slug": null,
        "attentes": null,
        "montant_panier": 0,
        "offre_livraison_vendeur": null,
        "mono_vendeur": true
    })
}

/// Pose un paramètre de zone au niveau VILLE (bornes, arrondi, drapeaux…).
impl Bac {
    pub async fn poser_parametre(&self, cle: &str, valeur: Value) {
        let z = PgZones::new(self.pool.clone());
        let mut tx = self.pool.begin().await.unwrap();
        z.definir_parametre(&mut tx, self.ville, cle, valeur, "bac")
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }

    /// État courant d'une grille (`brouillon` | `en_vigueur` | `historique`).
    pub async fn etat_grille(&self, grille: Uuid) -> String {
        sqlx::query_scalar("SELECT etat::text FROM tarification.grille WHERE id = $1")
            .bind(grille)
            .fetch_one(&self.pool)
            .await
            .unwrap()
    }
}
