//! Bac d'essai partagé des tests d'intégration du cycle CRS (010).
//!
//! Monte l'application Actix RÉELLE (mêmes handlers, même extracteur [`Auth`],
//! mêmes gardes de rôle) sur une base éphémère : arbre CI → Tiassalé, catégorie
//! `marche`, **les 7 paramètres du cycle** plus ceux des cycles 006 et 008 dont
//! il dépend, trois vendeurs agréés avec leur catalogue et leur plaque, un
//! coursier au rôle VALIDE et **un second coursier** — celui-ci n'est pas un
//! ornement : c'est lui qui prouve qu'une course d'autrui est refusée, au rejeu
//! comme à la lecture (FR-006, dette relevée au cycle 008).
//!
//! Pourquoi passer par HTTP plutôt que d'appeler le domaine : les refus
//! `401`/`403`, le mapping des clés i18n et les gardes de propriété n'existent
//! QUE dans cette couche. Un test de domaine ne peut pas prouver qu'un endpoint
//! refuse un non-propriétaire — celui-ci, si.
//!
//! **Le temps ne s'attend pas, il se déplace.** Une preuve de présence exige dix
//! minutes et deux appels espacés de trois : aucun test ne peut les attendre.
//! Les helpers [`Bac::reculer_appels`] et [`Bac::poser_presence`] écrivent des
//! horodatages passés directement, ce qui revient à faire avancer l'horloge sans
//! toucher à celle du serveur — dont la constitution V fait l'autorité.

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use actix_web::web;
use chrono::{DateTime, Duration, NaiveDate, Utc};
use commandes::{PgCommandes, PositionFixe, PreuvesFixes, RestrictionsSimulees, TarifFixe};
use comptes::{MemoireEphemere, PgComptes, SmsTraces};
use prestataires::modele::{HorairesSemaine, Plage};
use prestataires::{AucuneCommandeActive, NouveauPrestataire, PgPrestataires};
use qr::{CompteurMemoire, PgQr};
use serde_json::{json, Value};
use socle::{DepotObjets, MemoireObjets};
use sqlx::PgPool;
use uuid::Uuid;
use zones::{PgZones, TypeZone};

pub const SECRET_JWT: &[u8] = b"secret-de-test-de-32-octets-mini";
pub const SECRET_PLAQUE: &[u8] = b"secret-plaque-de-test-32-octets!";

/// Devis servi par [`TarifFixe`] — connu d'avance, donc assertable au FCFA près.
pub const DEVIS_PRIX_CLIENT: i64 = 2_500;
/// Part coursier du devis fixe — c'est le « gain » de K5 et de K1.
pub const DEVIS_PART_COURSIER: i64 = 2_500;
/// Plafond d'encaissement en espèces seedé par le bac (unités mineures).
pub const PLAFOND_CASH: i64 = 15_000;

// ── Les 7 paramètres du cycle, tels que le bac les seede ───────────────────
/// Appels `client_absent` exigés par la preuve.
pub const PREUVE_APPELS_MIN: i64 = 2;
/// Espacement minimal entre deux appels retenus (s).
pub const PREUVE_APPELS_ESPACEMENT_S: i64 = 180;
/// Présence continue exigée (s).
pub const PREUVE_PRESENCE_S: i64 = 600;
/// Rayon dans lequel un relevé compte (m).
pub const PREUVE_PRESENCE_RAYON_M: i64 = 100;
/// Trou au-delà duquel la présence n'est plus continue (s).
pub const PREUVE_PRESENCE_TROU_MAX_S: i64 = 120;
/// Rétention de la photo de preuve (jours).
pub const RETENTION_PHOTO_PREUVE_JOURS: i64 = 365;
/// Période d'interrogation d'offre en arrière-plan (s).
pub const OFFRE_ARRIERE_PLAN_S: i64 = 5;
/// Seuil d'essais du code de remise — paramètre du **cycle 008**, réutilisé.
pub const ESSAIS_CODE_LIVRAISON: i64 = 3;

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
    /// Ligne de panier sur l'article d'index donné.
    pub fn ligne_de(&self, index: usize, quantite: i16) -> Value {
        json!({
            "prestataire_id": self.id,
            "article_id": self.articles[index],
            "quantite": quantite,
        })
    }

    /// Première ligne de panier de ce vendeur (article 0).
    pub fn ligne(&self, quantite: i16) -> Value {
        self.ligne_de(0, quantite)
    }

    /// Ligne avec une préférence de substitution explicite.
    pub fn ligne_avec_preference(&self, index: usize, quantite: i16, preference: &str) -> Value {
        json!({
            "prestataire_id": self.id,
            "article_id": self.articles[index],
            "quantite": quantite,
            "preference": preference,
        })
    }
}

/// Une course prête à être déroulée.
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

/// Les deux secrets de remise, en CLAIR — lisibles ici et **nulle part
/// ailleurs** : le serveur ne les sert jamais, seulement leurs empreintes
/// (FR-037). Un test qui confirme une remise par code doit bien le connaître ;
/// il le lit en base, comme le client le lirait sur son écran.
pub struct SecretsRemise {
    /// Code à 4 chiffres du client.
    pub code: String,
    /// Jeton de réception encodé dans le QR client.
    pub jeton: String,
}

pub struct Bac {
    pub pool: PgPool,
    pub comptes: PgComptes,
    pub prestataires: PgPrestataires,
    pub commandes: PgCommandes,
    pub qr: PgQr,
    /// Double des preuves d'échec — **remplacé par `PgCoursier` en T058**.
    /// Il reste ici tant que le branchement réel n'est pas fait ; les tests de
    /// preuves l'ignorent et exercent le vrai calcul.
    pub preuves: Arc<PreuvesFixes>,
    /// Double de la position coursier (Redis en production).
    pub positions: Arc<PositionFixe>,
    /// Double des restrictions de compte.
    pub restrictions: Arc<RestrictionsSimulees>,
    /// Stockage objet en mémoire — photos de preuve et notes vocales.
    pub objets: Arc<dyn DepotObjets>,
    pub pays: Uuid,
    pub ville: Uuid,
    pub categorie_marche: Uuid,
    /// Compte admin (rôles client + admin).
    pub admin: Uuid,
    pub jeton_admin: String,
    /// Compte client propriétaire des commandes du test.
    pub client: Uuid,
    pub jeton_client: String,
    /// Compte coursier — celui à qui les courses sont assignées.
    pub coursier: Uuid,
    pub jeton_coursier: String,
    /// SECOND coursier, jamais assigné : la garde de propriété se prouve avec
    /// lui, pas avec un client sans rôle (qui échouerait sur le rôle, pas sur la
    /// propriété — deux refus différents que rien ne distinguerait).
    pub autre_coursier: Uuid,
    pub jeton_autre_coursier: String,
    /// Trois vendeurs de la catégorie `marche`.
    pub vendeurs: Vec<Vendeur>,
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
        sqlx::query(
            "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
             VALUES ($1, 'marche', 'categorie.marche.nom', 'marche_etals')",
        )
        .bind(categorie_marche)
        .execute(&mut *tx)
        .await
        .unwrap();
        sqlx::query(
            "INSERT INTO zones.activation_categorie (id, zone_id, categorie_id, forcage)
             VALUES ($1, $2, $3, 'force_actif')",
        )
        .bind(Uuid::now_v7())
        .bind(ville)
        .bind(categorie_marche)
        .execute(&mut *tx)
        .await
        .unwrap();

        // Paramètres au PAYS, hérités par la ville (constitution I). Les 7 du
        // cycle CRS sont marqués ; les autres viennent des cycles 002/006/008 et
        // sont des PRÉCONDITIONS, pas des choix de ce bac.
        for (cle, valeur) in [
            ("devise.code", json!("XOF")),
            ("devise.decimales", json!(0)),
            ("zone.fuseau_horaire", json!("Africa/Abidjan")),
            ("charte.conservation_post_relation_annees", json!(5)),
            ("qr.distance_scan_max_m", json!(100)),
            ("qr.photo_seuil_montant", json!(10_000)),
            ("qr.retention_photo_collecte_jours", json!(365)),
            ("categorie.marche.mixable", json!(true)),
            ("categorie.marche.perissable", json!(false)),
            ("commande.repere_texte_min_caracteres", json!(10)),
            // Le seuil d'essais du cycle 008, RÉUTILISÉ tel quel (R5, FR-106).
            ("commande.essais_code_livraison", json!(ESSAIS_CODE_LIVRAISON)),
            ("commande.historique_min_commandes_terminees", json!(1)),
            ("substitution.delai_validation_s", json!(60)),
            ("substitution.ecart_prix_max_pourcent", json!(20)),
            ("substitution.photo_retention_jours", json!(365)),
            ("suivi.position_periode_s", json!(30)),
            // ── Les 7 du cycle CRS 010 ────────────────────────────────────
            ("coursier.preuve_appels_min", json!(PREUVE_APPELS_MIN)),
            (
                "coursier.preuve_appels_espacement_s",
                json!(PREUVE_APPELS_ESPACEMENT_S),
            ),
            ("coursier.preuve_presence_s", json!(PREUVE_PRESENCE_S)),
            (
                "coursier.preuve_presence_rayon_m",
                json!(PREUVE_PRESENCE_RAYON_M),
            ),
            (
                "coursier.preuve_presence_trou_max_s",
                json!(PREUVE_PRESENCE_TROU_MAX_S),
            ),
            (
                "coursier.retention_photo_preuve_jours",
                json!(RETENTION_PHOTO_PREUVE_JOURS),
            ),
            (
                "coursier.offre_interrogation_arriere_plan_s",
                json!(OFFRE_ARRIERE_PLAN_S),
            ),
        ] {
            z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        for (cle, valeur) in [
            ("commande.plafond_cash_unites", json!(PLAFOND_CASH)),
            (
                "commande.plafond_cash_restauration_sans_historique_unites",
                json!(5_000),
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
        // Composantes cohérentes avec la part coursier : 1 500 + 700 + 300.
        // Un double qui rendrait des zéros ferait passer tout contrôle du détail
        // du gain, même faux (leçon T071 du cycle 009).
        let tarif = Arc::new(
            TarifFixe::simple(DEVIS_PRIX_CLIENT, DEVIS_PART_COURSIER, 0).avec_composantes(
                tarification::Composantes {
                    base: 1_500,
                    km: 700,
                    supplements: 0,
                    effort_paliers: 50,
                    effort_attente: 100,
                    effort_arrets: 150,
                    arrondi: 0,
                    retenue_vendeur: 0,
                },
            ),
        );
        let restrictions = Arc::new(RestrictionsSimulees::nouveau());
        let positions = Arc::new(PositionFixe::nouveau());
        let preuves = Arc::new(PreuvesFixes::nouveau());
        let commandes = PgCommandes::new(
            pool.clone(),
            prestataires.clone(),
            tarif.clone(),
            tarif,
            restrictions.clone(),
            objets.clone(),
            positions.clone(),
            preuves.clone(),
        );
        let qr = PgQr::new(
            pool.clone(),
            commandes.clone(),
            prestataires.clone(),
            objets.clone(),
            Arc::new(CompteurMemoire::nouveau()),
        );

        let mut bac = Self {
            pool,
            comptes,
            prestataires,
            commandes,
            qr,
            preuves,
            positions,
            restrictions,
            objets,
            pays,
            ville,
            categorie_marche,
            admin: Uuid::nil(),
            jeton_admin: String::new(),
            client: Uuid::nil(),
            jeton_client: String::new(),
            coursier: Uuid::nil(),
            jeton_coursier: String::new(),
            autre_coursier: Uuid::nil(),
            jeton_autre_coursier: String::new(),
            vendeurs: Vec::new(),
        };

        let (admin, jeton_admin) = bac
            .compte_avec_roles("+2250700000001", &["client", "admin"])
            .await;
        bac.admin = admin;
        bac.jeton_admin = jeton_admin;
        let (client, jeton_client) = bac.compte_avec_roles("+2250700000002", &["client"]).await;
        bac.client = client;
        bac.jeton_client = jeton_client;
        let (coursier, jeton_coursier) = bac
            .compte_avec_roles("+2250700000004", &["client", "coursier"])
            .await;
        bac.coursier = coursier;
        bac.jeton_coursier = jeton_coursier;
        let (autre, jeton_autre) = bac
            .compte_avec_roles("+2250700000005", &["client", "coursier"])
            .await;
        bac.autre_coursier = autre;
        bac.jeton_autre_coursier = jeton_autre;

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

    /// Agrée un vendeur (fiche complète, site positionné, horaires larges, donc
    /// **plaque créée**) et lui crée son catalogue.
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
        // Horaires 0 h — 24 h : un test ne doit pas échouer parce qu'il tourne à
        // 21 h (piège du cycle 005).
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
        use api::commandes_http as cmd;
        use api::course_http as crs;
        let pool = self.pool.clone();
        let comptes = self.comptes.clone();
        let commandes = self.commandes.clone();
        let qr = self.qr.clone();
        move |cfg: &mut web::ServiceConfig| {
            cfg.app_data(web::Data::new(pool))
                .app_data(web::Data::new(comptes))
                .app_data(web::Data::new(commandes))
                .app_data(web::Data::new(qr))
                .service(cmd::creer_commande)
                .service(cmd::suivre_commande)
                .service(cmd::decider_substitution)
                .service(crs::arret_en_route)
                .service(crs::arret_arrive)
                .service(crs::arret_indisponible)
                .service(crs::declarer_rupture)
                .service(crs::remise)
                .service(crs::declarer_echec);
        }
    }

    // ── Parcours ──────────────────────────────────────────────────────────

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

    /// Crée une commande par l'API (mêmes gardes qu'en production).
    pub async fn creer_commande_api(&self, categorie_slug: &str, lignes: Vec<Value>) -> Uuid {
        self.creer_commande_mode(categorie_slug, lignes, "cash").await
    }

    /// Variante avec le mode de paiement explicite.
    pub async fn creer_commande_mode(
        &self,
        categorie_slug: &str,
        lignes: Vec<Value>,
        mode_paiement: &str,
    ) -> Uuid {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::post()
            .uri("/commandes")
            .insert_header(("authorization", format!("Bearer {}", self.jeton_client)))
            .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
            .set_json({
                let mut demande = self.demande_creation(categorie_slug, lignes);
                demande["mode_paiement"] = json!(mode_paiement);
                demande
            })
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        let corps: Value = actix_web::test::read_body_json(resp).await;
        assert_eq!(statut, 201, "création de commande du bac : {corps}");
        corps["id"].as_str().unwrap().parse().unwrap()
    }

    /// Une course de 3 vendeurs (3 collectes + 1 remise), assignée au coursier
    /// du bac — la course type de tout le cycle.
    pub async fn course_prete(&self) -> Course {
        self.course_prete_mode("cash").await
    }

    /// Variante avec le mode de paiement — `mobile_money` sert le cas « avance
    /// non soldée » (R10, FR-117).
    pub async fn course_prete_mode(&self, mode_paiement: &str) -> Course {
        let lignes: Vec<Value> = self.vendeurs.iter().map(|v| v.ligne(2)).collect();
        let commande = self
            .creer_commande_mode("marche", lignes, mode_paiement)
            .await;
        if mode_paiement != "cash" {
            // Une commande prépayée naît `en_attente_paiement` : sans
            // confirmation, elle ne serait jamais assignable.
            self.commandes
                .confirmer_prepaiement(commande, Utc::now())
                .await
                .expect("confirmation du prépaiement simulé (PAY non construit)");
        }
        let livraison = self
            .commandes
            .assigner_coursier(commande, self.coursier, Utc::now())
            .await
            .expect("affectation (dispatch non monté dans ce bac)");
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

    /// Les deux secrets de remise d'une commande, lus en base — le seul endroit
    /// du dépôt où ils apparaissent en clair côté test.
    pub async fn secrets_remise(&self, commande: Uuid) -> SecretsRemise {
        let (code, jeton): (String, String) = sqlx::query_as(
            "SELECT code_livraison, jeton_reception FROM commandes.commande WHERE id = $1",
        )
        .bind(commande)
        .fetch_one(&self.pool)
        .await
        .unwrap();
        SecretsRemise { code, jeton }
    }

    /// Collecte un arrêt par le domaine (le scan vit dans `qr_http` et exige
    /// plaque + multipart : hors sujet pour la plupart des tests d'ici).
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
                Utc::now(),
                self.coursier,
            )
            .await
            .expect("collecte d'un arrêt du bac");
        tx.commit().await.unwrap();
        p
    }

    /// Déroule toutes les collectes : la livraison finit EN_LIVRAISON, arrivée
    /// chez le client — le point de départ des tests de remise et de preuves.
    pub async fn collecter_tout(&self, course: &Course) {
        for arret in &course.collectes {
            self.collecter(*arret).await;
        }
    }

    // ── Le temps : on le déplace, on ne l'attend pas ──────────────────────

    /// Recule les appels d'une livraison de `duree`, pour que leur espacement
    /// soit celui d'une vraie attente sans que le test ne dorme.
    ///
    /// L'horodatage SERVEUR reste l'autorité (constitution V) : ce helper ne
    /// touche pas l'horloge, il écrit un passé — exactement ce que la base
    /// contiendrait si le test avait duré dix minutes.
    pub async fn reculer_appels(&self, livraison: Uuid, duree: Duration) {
        sqlx::query(
            "UPDATE coursier.appel_coursier
                SET passe_le = passe_le - $2::interval,
                    passe_le_local = passe_le_local - $2::interval
              WHERE livraison_id = $1",
        )
        .bind(livraison)
        .bind(duree)
        .execute(&self.pool)
        .await
        .unwrap();
    }

    /// Recule l'arrivée du coursier chez le client — base du délai des preuves.
    pub async fn reculer_arrivee(&self, arret: Uuid, duree: Duration) {
        sqlx::query("UPDATE commandes.arret SET arrive_le = arrive_le - $2::interval WHERE id = $1")
            .bind(arret)
            .bind(duree)
            .execute(&self.pool)
            .await
            .unwrap();
    }

    /// Pose une série de relevés de présence, espacés de `pas`, en remontant
    /// depuis maintenant. Écrit directement en base : la voie HTTP est testée
    /// ailleurs, et ce helper sert à FABRIQUER un passé, pas à l'exercer.
    pub async fn poser_presence(
        &self,
        livraison: Uuid,
        nb: i64,
        pas: Duration,
        distance_m: i32,
    ) -> Vec<Uuid> {
        let base = Utc::now() - pas * (nb as i32 - 1).max(0);
        let mut ids = Vec::new();
        for i in 0..nb {
            let id = Uuid::now_v7();
            let quand = base + pas * i as i32;
            sqlx::query(
                "INSERT INTO coursier.releve_presence
                     (id, livraison_id, distance_m, releve_le, releve_le_local, uuid_client)
                 VALUES ($1, $2, $3, $4, $4, $5)",
            )
            .bind(id)
            .bind(livraison)
            .bind(distance_m)
            .bind(quand)
            .bind(Uuid::now_v7())
            .execute(&self.pool)
            .await
            .unwrap();
            ids.push(id);
        }
        ids
    }

    // ── Requêtes HTTP ─────────────────────────────────────────────────────

    /// `GET` authentifié. Le corps `204 No Content` est rendu `null`.
    pub async fn get(&self, uri: &str, jeton: &str) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::get()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        Self::lire(resp).await
    }

    /// `POST` JSON authentifié.
    pub async fn post(&self, uri: &str, jeton: &str, corps: Value) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::post()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .set_json(corps)
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        Self::lire(resp).await
    }

    /// `PATCH` JSON authentifié — sert la déclaration d'issue d'appel (R19).
    pub async fn patch(&self, uri: &str, jeton: &str, corps: Value) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::patch()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .set_json(corps)
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        Self::lire(resp).await
    }

    /// `POST` multipart : partie `demande` (JSON) + `photo` binaire optionnelle.
    pub async fn post_multipart(
        &self,
        uri: &str,
        jeton: &str,
        demande: Value,
        avec_photo: bool,
    ) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let frontiere = "----mefali-bac";
        let mut corps = format!(
            "--{frontiere}\r\nContent-Disposition: form-data; name=\"demande\"\r\n\r\n{demande}\r\n"
        );
        if avec_photo {
            corps.push_str(&format!(
                "--{frontiere}\r\nContent-Disposition: form-data; name=\"photo\"; \
                 filename=\"p.jpg\"\r\nContent-Type: image/jpeg\r\n\r\nXXX\r\n"
            ));
        }
        corps.push_str(&format!("--{frontiere}--\r\n"));

        let req = actix_web::test::TestRequest::post()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .insert_header((
                "content-type",
                format!("multipart/form-data; boundary={frontiere}"),
            ))
            .set_payload(corps)
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        Self::lire(resp).await
    }

    async fn lire(resp: actix_web::dev::ServiceResponse) -> (u16, Value) {
        let statut = resp.status().as_u16();
        let octets = actix_web::test::read_body(resp).await;
        let valeur = if octets.is_empty() {
            Value::Null
        } else {
            serde_json::from_slice(&octets).expect("corps JSON")
        };
        (statut, valeur)
    }

    // ── Lectures d'état ───────────────────────────────────────────────────

    /// État courant du tronc.
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

    /// TOUS les événements outbox — sert le balayage transverse de SC-015.
    pub async fn tous_evenements(&self) -> Vec<(String, Value)> {
        sqlx::query_as("SELECT type_evenement, payload FROM outbox.evenement ORDER BY id")
            .fetch_all(&self.pool)
            .await
            .unwrap()
    }

    pub async fn compter(&self, sql: &'static str) -> i64 {
        sqlx::query_scalar(sql).fetch_one(&self.pool).await.unwrap()
    }

    /// Instant serveur — les tests horodatent avec la MÊME horloge que l'API.
    pub fn maintenant(&self) -> DateTime<Utc> {
        Utc::now()
    }
}
