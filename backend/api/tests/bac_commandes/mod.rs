//! Bac d'essai partagé des tests d'intégration du cycle CMD (008).
//!
//! Monte l'application Actix RÉELLE (mêmes handlers, même extracteur [`Auth`],
//! mêmes gardes de rôle) sur une base éphémère : arbre CI → Tiassalé, catégories
//! `restauration` (NON mixable, périssable) et `marche` (mixable), paramètres de
//! zone du cycle, trois vendeurs agréés avec leur catalogue et leur site, et des
//! comptes porteurs de rôles VALIDES avec de vrais jetons signés.
//!
//! Pourquoi passer par HTTP plutôt que d'appeler le domaine : les refus
//! `401`/`403`, le mapping des clés i18n et les gardes de propriété n'existent
//! QUE dans cette couche. Un test de domaine ne peut pas prouver qu'un endpoint
//! refuse un non-propriétaire — celui-ci, si.
//!
//! Les modules non construits (DSP, PAY, CRS) sont exercés par les doubles du
//! domaine (`AffectationSimulee`, `PaiementSimule`, `PreuvesFixes`,
//! `PositionFixe`, `TarifFixe`), patron du cycle 006 (research R16).

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use actix_web::web;
use chrono::NaiveDate;
use commandes::{PgCommandes, PositionFixe, PreuvesFixes, RestrictionsSimulees, TarifFixe};
use comptes::{MemoireEphemere, PgComptes, SmsTraces};
use prestataires::modele::{HorairesSemaine, Plage};
use prestataires::{AucuneCommandeActive, NouveauPrestataire, PgPrestataires};
use serde_json::{json, Value};
use socle::{DepotObjets, MemoireObjets};
use sqlx::PgPool;
use uuid::Uuid;
use zones::{PgZones, TypeZone};

pub const SECRET_JWT: &[u8] = b"secret-de-test-de-32-octets-mini";
pub const SECRET_PLAQUE: &[u8] = b"secret-plaque-de-test-32-octets!";

/// Devis servi par [`TarifFixe`] : 2 500 au client, 2 500 au coursier, 0 de
/// marge (gratuité des commissions au lancement). Connu d'avance, donc
/// assertable au FCFA près — et INVARIANT, ce que les tests de substitution
/// exploitent (FR-050).
pub const DEVIS_PRIX_CLIENT: i64 = 2_500;
/// Part coursier du devis fixe.
pub const DEVIS_PART_COURSIER: i64 = 2_500;

/// Plafond d'encaissement en espèces seedé par le bac (unités mineures).
pub const PLAFOND_CASH: i64 = 15_000;
/// Plafond réduit — restauration d'un client sans historique.
pub const PLAFOND_CASH_RESTAURATION: i64 = 5_000;
/// Fenêtre de décision d'un remplacement (s).
pub const DELAI_SUBSTITUTION_S: i64 = 60;
/// Écart de prix maximal d'un remplacement (%).
pub const ECART_PRIX_MAX_POURCENT: i64 = 20;

/// Un vendeur du bac, avec son catalogue.
pub struct Vendeur {
    /// Prestataire agréé.
    pub id: Uuid,
    /// Nom.
    pub nom: String,
    /// Articles au catalogue, dans l'ordre de création.
    pub articles: Vec<Uuid>,
    /// Prix des articles, même ordre.
    pub prix: Vec<i64>,
}

impl Vendeur {
    /// Première ligne de panier de ce vendeur (article 0, quantité donnée).
    pub fn ligne(&self, quantite: i16) -> Value {
        self.ligne_de(0, quantite)
    }

    /// Ligne de panier sur l'article d'index donné.
    pub fn ligne_de(&self, index: usize, quantite: i16) -> Value {
        json!({
            "prestataire_id": self.id,
            "article_id": self.articles[index],
            "quantite": quantite,
        })
    }

    /// Ligne de panier avec une préférence de substitution explicite.
    pub fn ligne_avec_preference(&self, index: usize, quantite: i16, preference: &str) -> Value {
        json!({
            "prestataire_id": self.id,
            "article_id": self.articles[index],
            "quantite": quantite,
            "preference": preference,
        })
    }
}

/// Une course prête à être déroulée : la commande, sa livraison affectée, ses
/// arrêts de collecte dans l'ordre optimisé, et son arrêt de remise.
pub struct Course {
    /// Tronc commande.
    pub commande: Uuid,
    /// Livraison assignée au coursier du bac.
    pub livraison: Uuid,
    /// Arrêts de COLLECTE, dans l'ordre de passage.
    pub collectes: Vec<Uuid>,
    /// Arrêt de remise (dernier du segment).
    pub remise: Uuid,
}

pub struct Bac {
    pub pool: PgPool,
    pub comptes: PgComptes,
    pub prestataires: PgPrestataires,
    pub commandes: PgCommandes,
    /// Double des preuves d'échec (CRS-05 non construit).
    pub preuves: Arc<PreuvesFixes>,
    /// Double de la position coursier (DSP-01 non construit).
    pub positions: Arc<PositionFixe>,
    /// Double des restrictions de compte — le bac les pilote sans toucher
    /// `comptes.compte`, comme le fera la sanction §7.5.
    pub restrictions: Arc<RestrictionsSimulees>,
    pub pays: Uuid,
    pub ville: Uuid,
    pub categorie_marche: Uuid,
    pub categorie_restauration: Uuid,
    /// Compte admin (rôles client + admin).
    pub admin: Uuid,
    pub jeton_admin: String,
    /// Compte client propriétaire des commandes du test.
    pub client: Uuid,
    pub jeton_client: String,
    /// Second client — sert à prouver le refus de non-propriété.
    pub intrus: Uuid,
    pub jeton_intrus: String,
    /// Compte coursier.
    pub coursier: Uuid,
    pub jeton_coursier: String,
    /// Trois vendeurs de la catégorie `marche` (mixable).
    pub vendeurs: Vec<Vendeur>,
    /// Un vendeur de la catégorie `restauration` (NON mixable, périssable).
    pub resto: Vendeur,
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

        let categorie_marche = Uuid::now_v7();
        let categorie_restauration = Uuid::now_v7();
        for (id, slug, workflow) in [
            (categorie_marche, "marche", "marche_etals"),
            (categorie_restauration, "restauration", "restauration"),
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
            // Catégorie ACTIVE dans la ville (sans quoi rien n'est commandable).
            // `actif` est une colonne GÉNÉRÉE : on force le mode, pas la valeur.
            sqlx::query(
                "INSERT INTO zones.activation_categorie (id, zone_id, categorie_id, forcage)
                 VALUES ($1, $2, $3, 'force_actif')",
            )
            .bind(Uuid::now_v7())
            .bind(ville)
            .bind(id)
            .execute(&mut *tx)
            .await
            .unwrap();
        }

        // Paramètres au PAYS, hérités par la ville — jamais de valeur en dur
        // dans le code (constitution I).
        for (cle, valeur) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("zone.fuseau_horaire", json!("Africa/Abidjan")),
            ("charte.conservation_post_relation_annees", json!(5)),
            ("qr.distance_scan_max_m", json!(100)),
            ("qr.photo_seuil_montant", json!(10_000)),
            // Cycle CMD 008.
            ("categorie.restauration.mixable", json!(false)),
            ("categorie.marche.mixable", json!(true)),
            ("categorie.restauration.perissable", json!(true)),
            ("categorie.marche.perissable", json!(false)),
            ("commande.repere_texte_min_caracteres", json!(10)),
            ("commande.essais_code_livraison", json!(3)),
            ("commande.historique_min_commandes_terminees", json!(1)),
            ("substitution.delai_validation_s", json!(DELAI_SUBSTITUTION_S)),
            (
                "substitution.ecart_prix_max_pourcent",
                json!(ECART_PRIX_MAX_POURCENT),
            ),
            ("substitution.photo_retention_jours", json!(365)),
            ("suivi.position_periode_s", json!(30)),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        for (cle, valeur) in [
            ("commande.plafond_cash_unites", json!(PLAFOND_CASH)),
            (
                "commande.plafond_cash_restauration_sans_historique_unites",
                json!(PLAFOND_CASH_RESTAURATION),
            ),
            ("commande.escalade_attente_coursier_s", json!(300)),
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
            objets.clone(),
            Arc::from(SECRET_JWT),
        );
        let prestataires = PgPrestataires::new(
            pool.clone(),
            comptes.clone(),
            objets.clone(),
            Arc::new(AucuneCommandeActive),
            Arc::from(SECRET_PLAQUE),
        );
        let tarif = Arc::new(TarifFixe::simple(
            DEVIS_PRIX_CLIENT,
            DEVIS_PART_COURSIER,
            0,
        ));
        let restrictions = Arc::new(RestrictionsSimulees::nouveau());
        let positions = Arc::new(PositionFixe::nouveau());
        let commandes = PgCommandes::new(
            pool.clone(),
            prestataires.clone(),
            tarif.clone(),
            tarif,
            restrictions.clone(),
            objets,
            positions.clone(),
        );

        let mut bac = Self {
            pool,
            comptes,
            prestataires,
            commandes,
            preuves: Arc::new(PreuvesFixes::nouveau()),
            positions,
            restrictions,
            pays,
            ville,
            categorie_marche,
            categorie_restauration,
            admin: Uuid::nil(),
            jeton_admin: String::new(),
            client: Uuid::nil(),
            jeton_client: String::new(),
            intrus: Uuid::nil(),
            jeton_intrus: String::new(),
            coursier: Uuid::nil(),
            jeton_coursier: String::new(),
            vendeurs: Vec::new(),
            resto: Vendeur {
                id: Uuid::nil(),
                nom: String::new(),
                articles: Vec::new(),
                prix: Vec::new(),
            },
        };

        let (admin, jeton_admin) = bac
            .compte_avec_roles("+2250700000001", &["client", "admin"])
            .await;
        bac.admin = admin;
        bac.jeton_admin = jeton_admin;
        let (client, jeton_client) = bac.compte_avec_roles("+2250700000002", &["client"]).await;
        bac.client = client;
        bac.jeton_client = jeton_client;
        let (intrus, jeton_intrus) = bac.compte_avec_roles("+2250700000003", &["client"]).await;
        bac.intrus = intrus;
        bac.jeton_intrus = jeton_intrus;
        let (coursier, jeton_coursier) = bac
            .compte_avec_roles("+2250700000004", &["client", "coursier"])
            .await;
        bac.coursier = coursier;
        bac.jeton_coursier = jeton_coursier;

        // Trois étals de marché (positions distinctes) + un maquis.
        for (i, (nom, lat, lon)) in [
            ("Étal Adjoua", 5.8980, -4.8230),
            ("Étal Kouassi", 5.8990, -4.8240),
            ("Boutique Yao", 5.9000, -4.8250),
        ]
        .into_iter()
        .enumerate()
        {
            let v = bac
                .vendeur_agree(nom, "marche", lat, lon, &[500 + 100 * i as i64, 250])
                .await;
            bac.vendeurs.push(v);
        }
        bac.resto = bac
            .vendeur_agree("Maquis Tantie", "restauration", 5.8975, -4.8225, &[2_000])
            .await;
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

    /// Agrée un vendeur (fiche complète, site positionné, horaires larges) et
    /// lui crée son catalogue. Rend le [`Vendeur`] prêt à être commandé.
    pub async fn vendeur_agree(
        &self,
        nom: &str,
        categorie_slug: &str,
        lat: f64,
        lon: f64,
        prix: &[i64],
    ) -> Vendeur {
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
        // Horaires 0 h — 24 h : l'ouverture effective suit l'horloge, et un test
        // ne doit pas échouer parce qu'il tourne à 21 h (piège du cycle 005).
        let mut horaires = HorairesSemaine::default();
        for jour in 0..7 {
            horaires.jours[jour].push(Plage {
                debut: chrono::NaiveTime::from_hms_opt(0, 0, 0).unwrap(),
                fin: chrono::NaiveTime::from_hms_opt(23, 59, 59).unwrap(),
            });
        }
        self.prestataires
            .definir_site(&mut tx, p.id, lat, lon, &horaires, None, self.admin)
            .await
            .unwrap();
        self.prestataires
            .agreer(&mut tx, p.id, self.admin)
            .await
            .unwrap();

        let mut articles = Vec::new();
        for (i, prix_unites) in prix.iter().enumerate() {
            let a = self
                .prestataires
                .creer_article(
                    &mut tx,
                    p.id,
                    &prestataires::NouvelArticle {
                        nom: format!("{nom} — article {i}"),
                        prix_unites: *prix_unites,
                        prix_barre_unites: None,
                        categorie_interne: None,
                    },
                    prestataires::SourceBascule::Admin,
                    self.admin,
                )
                .await
                .unwrap();
            articles.push(a.id);
        }
        tx.commit().await.unwrap();

        Vendeur {
            id: p.id,
            nom: nom.to_owned(),
            articles,
            prix: prix.to_vec(),
        }
    }

    /// Configure une `App` Actix avec les MÊMES handlers que la production.
    pub fn configurer(&self) -> impl FnOnce(&mut web::ServiceConfig) {
        use api::admin_commandes_http as adm;
        use api::commandes_http as cmd;
        use api::course_http as crs;
        let pool = self.pool.clone();
        let comptes = self.comptes.clone();
        let commandes = self.commandes.clone();
        move |cfg: &mut web::ServiceConfig| {
            cfg.app_data(web::Data::new(pool))
                .app_data(web::Data::new(comptes))
                .app_data(web::Data::new(commandes))
                .service(cmd::devis_panier)
                .service(cmd::creer_commande)
                .service(crs::arret_en_route)
                .service(crs::arret_arrive)
                .service(crs::arret_indisponible)
                .service(crs::declarer_rupture)
                .service(cmd::decider_substitution)
                .service(cmd::mes_commandes)
                .service(cmd::suivre_commande)
                .service(cmd::intention_appel)
                .service(cmd::annuler_commande)
                .service(adm::file_attente)
                .service(adm::annuler_commande_admin);
        }
    }

    // ── Aides de PARCOURS (US4 et suivantes) ──────────────────────────────

    /// Corps de création nominal : repère écrit assez long, cash, lieu fixe.
    pub fn demande_creation(&self, categorie_slug: &str, lignes: Vec<Value>) -> Value {
        json!({
            "zone_id": self.ville,
            "categorie_slug": categorie_slug,
            "transport_slug": "moto",
            "lieu": { "lat": 5.9050, "lon": -4.8300 },
            "repere_texte": "Près de la pharmacie Sainte-Marie",
            "lignes": lignes,
            "mode_paiement": "cash",
        })
    }

    /// Crée une commande par l'API (mêmes gardes qu'en production) et rend son
    /// identifiant. Panique si la création échoue : c'est une PRÉCONDITION du
    /// test, pas son objet.
    pub async fn creer_commande_api(&self, categorie_slug: &str, lignes: Vec<Value>) -> Uuid {
        let app = actix_web::test::init_service(
            actix_web::App::new().configure(self.configurer()),
        )
        .await;
        let req = actix_web::test::TestRequest::post()
            .uri("/commandes")
            .insert_header(("authorization", format!("Bearer {}", self.jeton_client)))
            .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
            .set_json(self.demande_creation(categorie_slug, lignes))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        assert_eq!(resp.status().as_u16(), 201, "création de commande du bac");
        let corps: Value = actix_web::test::read_body_json(resp).await;
        corps["id"].as_str().unwrap().parse().unwrap()
    }

    /// Une commande de 3 vendeurs `marche` (3 collectes + 1 remise), affectée au
    /// coursier du bac. Rend `(commande, livraison, [arrêts de collecte
    /// ordonnés], arrêt de remise)` — la course type d'US4.
    pub async fn course_prete(&self) -> Course {
        let lignes: Vec<Value> = self.vendeurs.iter().map(|v| v.ligne(2)).collect();
        let commande = self.creer_commande_api("marche", lignes).await;
        let livraison = self
            .commandes
            .assigner_coursier(commande, self.coursier, chrono::Utc::now())
            .await
            .expect("affectation simulée (DSP non construit)");
        let (collectes, remise) = self.arrets_de(livraison).await;
        Course {
            commande,
            livraison,
            collectes,
            remise,
        }
    }

    /// Arrêts d'une livraison : collectes dans l'ordre, puis la remise.
    pub async fn arrets_de(&self, livraison: Uuid) -> (Vec<Uuid>, Uuid) {
        let lignes: Vec<(Uuid, String)> = sqlx::query_as(
            "SELECT a.id, a.type_arret::text FROM commandes.arret a
             JOIN commandes.segment s ON s.id = a.segment_id
             WHERE s.livraison_id = $1 ORDER BY a.ordre",
        )
        .bind(livraison)
        .fetch_all(&self.pool)
        .await
        .unwrap();
        let collectes = lignes
            .iter()
            .filter(|(_, t)| t == "collecte")
            .map(|(id, _)| *id)
            .collect();
        let remise = lignes
            .iter()
            .find(|(_, t)| t == "remise")
            .map(|(id, _)| *id)
            .expect("tout segment porte son arrêt de remise");
        (collectes, remise)
    }

    /// Joue une action déclarative du coursier sur un arrêt.
    /// `action` ∈ { `en-route`, `arrive`, `indisponible` }.
    pub async fn action_coursier(
        &self,
        livraison: Uuid,
        arret: Uuid,
        action: &str,
        uuid_client: Uuid,
    ) -> (u16, Value) {
        self.action_coursier_par(&self.jeton_coursier, livraison, arret, action, uuid_client)
            .await
    }

    /// Variante avec un jeton explicite — sert les refus de propriété.
    pub async fn action_coursier_par(
        &self,
        jeton: &str,
        livraison: Uuid,
        arret: Uuid,
        action: &str,
        uuid_client: Uuid,
    ) -> (u16, Value) {
        let app = actix_web::test::init_service(
            actix_web::App::new().configure(self.configurer()),
        )
        .await;
        let req = actix_web::test::TestRequest::post()
            .uri(&format!("/courses/{livraison}/arrets/{arret}/{action}"))
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .set_json(json!({
                "uuid_client": uuid_client,
                "horodatage_local": chrono::Utc::now(),
            }))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        (statut, actix_web::test::read_body_json(resp).await)
    }

    /// Collecte un arrêt par le domaine (le scan lui-même vit dans `qr_http`,
    /// cycle 006, et exige plaque + multipart : hors sujet ici).
    pub async fn collecter(&self, arret: Uuid) -> commandes::ProgressionCollecte {
        let mut tx = self.pool.begin().await.unwrap();
        let p = self
            .commandes
            .marquer_arret_collecte(
                &mut tx,
                arret,
                Uuid::now_v7(),
                commandes::ModeCollecte::ScanQr,
                None,
                10,
                chrono::Utc::now(),
                self.coursier,
            )
            .await
            .expect("collecte d'un arrêt du bac");
        tx.commit().await.unwrap();
        p
    }

    /// Clôt la course (remise déjà prouvée — la preuve est l'objet de T058).
    pub async fn cloturer(&self, course: &Course, mode_remise: &str) {
        let mut tx = self.pool.begin().await.unwrap();
        self.commandes
            .cloturer_livraison_prouvee(
                &mut tx,
                course.livraison,
                course.commande,
                mode_remise,
                0,
                self.coursier,
                chrono::Utc::now(),
            )
            .await
            .expect("clôture de la course");
        tx.commit().await.unwrap();
    }

    /// `GET` authentifié sur une route du bac.
    pub async fn get(&self, uri: &str, jeton: &str) -> (u16, Value) {
        let app = actix_web::test::init_service(
            actix_web::App::new().configure(self.configurer()),
        )
        .await;
        let req = actix_web::test::TestRequest::get()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        (statut, actix_web::test::read_body_json(resp).await)
    }

    /// `POST` JSON authentifié sur une route du bac. Le corps `204 No Content`
    /// est rendu `null` : il n'y a rien à désérialiser.
    pub async fn post(&self, uri: &str, jeton: &str, corps: Value) -> (u16, Value) {
        let app = actix_web::test::init_service(
            actix_web::App::new().configure(self.configurer()),
        )
        .await;
        let req = actix_web::test::TestRequest::post()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .set_json(corps)
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        let octets = actix_web::test::read_body(resp).await;
        let valeur = if octets.is_empty() {
            Value::Null
        } else {
            serde_json::from_slice(&octets).expect("corps JSON")
        };
        (statut, valeur)
    }

    /// État courant du tronc, de la livraison et d'un arrêt.
    pub async fn etat_commande(&self, commande: Uuid) -> String {
        sqlx::query_scalar("SELECT etat::text FROM commandes.commande WHERE id = $1")
            .bind(commande)
            .fetch_one(&self.pool)
            .await
            .unwrap()
    }

    /// État courant de la livraison.
    pub async fn etat_livraison(&self, livraison: Uuid) -> String {
        sqlx::query_scalar("SELECT etat::text FROM commandes.livraison WHERE id = $1")
            .bind(livraison)
            .fetch_one(&self.pool)
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

    /// Nombre d'événements outbox d'un type donné.
    pub async fn nb_evenements(&self, type_evenement: &str) -> i64 {
        sqlx::query_scalar("SELECT count(*) FROM outbox.evenement WHERE type_evenement = $1")
            .bind(type_evenement)
            .fetch_one(&self.pool)
            .await
            .unwrap()
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

    /// Nombre TOTAL d'événements outbox — sert les assertions « ce chemin
    /// n'émet rien » (P4).
    pub async fn total_evenements(&self) -> i64 {
        self.compter("SELECT count(*) FROM outbox.evenement").await
    }

    /// Corps de demande de devis de panier.
    pub fn demande_devis(&self, categorie_slug: &str, lignes: Vec<Value>) -> Value {
        json!({
            "zone_id": self.ville,
            "categorie_slug": categorie_slug,
            "transport_slug": "moto",
            "lieu": { "lat": 5.9050, "lon": -4.8300 },
            "lignes": lignes,
        })
    }
}
