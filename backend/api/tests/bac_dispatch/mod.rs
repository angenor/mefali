//! Bac d'essai partagé des tests d'intégration du cycle DSP (009).
//!
//! Monte l'application Actix **RÉELLE** (mêmes handlers, même extracteur `Auth`,
//! mêmes gardes de rôle) au-dessus du bac du cycle CMD, dont il réutilise
//! l'arbre de zones, les vendeurs agréés et les comptes. S'y ajoutent :
//!
//! - les **18 paramètres** de dispatch, résolus par héritage pays → ville ;
//! - **quatre coursiers** au rôle validé, avec un dossier et un **véhicule
//!   `moto` déclaré**, des jetons signés et des positions proches du centre ;
//! - un `PgDispatch` composé de **doubles** : `MemoirePool`, `VerrouMemoire`,
//!   `ProximiteFixe`, `NoteAbsente`, `AucunePaireBloquee` et
//!   `NotificationsCollectees` — toute la suite tourne donc **sans Redis ni
//!   OSRM**, et deux familles de tests dédiées prouvent que les
//!   implémentations réelles tiennent les mêmes promesses.
//!
//! ⚠ **Piège d'environnement recensé** (research R17) : le seed n'active que
//! `transport.actifs = ["a_pied","velo","moto"]`, et `a_pied` plafonne à 800 m
//! dans la grille tarifaire. Un bac de dispatch déclare donc des coursiers
//! **`moto`** et des positions proches, sinon le devis échoue **avant** le
//! dispatch (« aucune règle tarifaire applicable », cycle 008).

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use actix_web::web;
use dispatch::{
    Capacite, ConfigDispatch, MemoirePool, NotificationsCollectees, PgDispatch, ProximiteFixe,
    VerrouMemoire,
};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;
use zones::PgZones;

#[path = "../bac_commandes/mod.rs"]
pub mod bac_commandes;

pub use bac_commandes::Bac as BacCommandes;

/// Position de référence : le centre de Tiassalé (`adb emu geo fix`).
pub const TIASSALE: (f64, f64) = (5.8960, -4.8210);

/// Rayon d'éligibilité seedé par le bac (mètres routiers).
pub const RAYON_M: i64 = 4_000;
/// Compte à rebours d'une offre (s).
pub const TIMER_OFFRE_S: i64 = 40;
/// Durée de l'exclusivité (s) — toujours > [`TIMER_OFFRE_S`].
pub const VERROU_OFFRE_S: i64 = 45;
/// Durée de vie d'une inscription au pool (s).
pub const POOL_TTL_S: i64 = 90;
/// Non-réponses franches par jour.
pub const TIMEOUTS_FRANCS: i64 = 3;
/// Palier d'ENTRÉE de la grille d'avance (unités mineures) — celui d'un
/// coursier sans note, c'est-à-dire de tous tant qu'AVI n'existe pas.
pub const PALIER_ENTREE: i64 = 5_000;
/// Palier HAUT de la grille d'avance.
pub const PALIER_HAUT: i64 = 15_000;

/// Un coursier du bac, prêt à entrer dans le pool.
pub struct Coursier {
    /// Compte.
    pub id: Uuid,
    /// Jeton d'accès signé (ce que l'extracteur `Auth` relit).
    pub jeton: String,
    /// Position déclarée par le bac.
    pub lat: f64,
    /// Position déclarée par le bac.
    pub lon: f64,
}

/// Le bac du cycle dispatch.
pub struct Bac {
    /// Bac du cycle CMD — zones, vendeurs, client, commandes.
    pub cmd: BacCommandes,
    /// Pipeline de dispatch, composé de doubles.
    pub dispatch: PgDispatch,
    /// Index éphémère en mémoire (expiration PILOTÉE, pas subie).
    pub pool_coursiers: Arc<MemoirePool>,
    /// Verrous en mémoire.
    pub verrous: Arc<VerrouMemoire>,
    /// Distances et durées connues d'avance — classement assertable au rang près.
    pub proximite: Arc<ProximiteFixe>,
    /// Annonces retenues (SC-006, SC-012).
    pub notifications: Arc<NotificationsCollectees>,
    /// Les quatre coursiers, tous `moto`, tous proches du centre.
    pub coursiers: Vec<Coursier>,
}

impl Bac {
    /// Monte le bac complet sur une base éphémère.
    pub async fn nouveau(pool: PgPool) -> Self {
        let cmd = BacCommandes::nouveau(pool.clone()).await;
        seeder_parametres_dispatch(&pool, cmd.pays, cmd.ville).await;
        let moto = seeder_type_transport(&pool, "moto", 3).await;

        let pool_coursiers = Arc::new(MemoirePool::nouveau());
        let verrous = Arc::new(VerrouMemoire::nouveau());
        let proximite = Arc::new(ProximiteFixe::nouveau());
        let notifications = Arc::new(NotificationsCollectees::nouveau());

        let dispatch = PgDispatch::new(
            pool.clone(),
            Arc::new(cmd.commandes.clone()),
            Arc::new(cmd.comptes.clone()),
            pool_coursiers.clone(),
            verrous.clone(),
            proximite.clone(),
            Arc::new(dispatch::NoteAbsente),
            Arc::new(dispatch::AucunePaireBloquee),
            notifications.clone(),
        );

        let mut bac = Self {
            cmd,
            dispatch,
            pool_coursiers,
            verrous,
            proximite,
            notifications,
            coursiers: Vec::new(),
        };

        // Quatre coursiers, positions distinctes mais toutes dans le rayon.
        for (i, (lat, lon)) in [
            (5.8961, -4.8211),
            (5.8965, -4.8215),
            (5.8970, -4.8220),
            (5.8975, -4.8225),
        ]
        .into_iter()
        .enumerate()
        {
            let (id, jeton) = bac
                .cmd
                .compte_avec_roles(&format!("+22507000001{i:02}"), &["client", "coursier"])
                .await;
            declarer_vehicule(&pool, id, moto).await;
            bac.coursiers.push(Coursier {
                id,
                jeton,
                lat,
                lon,
            });
        }
        bac
    }

    /// Configuration de dispatch de la ville, telle que le domaine la charge.
    pub async fn config(&self) -> ConfigDispatch {
        self.dispatch
            .config(self.cmd.ville)
            .await
            .expect("configuration de dispatch valide")
    }

    /// Monte l'app Actix avec les routes des DEUX cycles : un test de dispatch
    /// crée de vraies commandes par `POST /commandes`.
    pub fn configurer(&self) -> impl FnOnce(&mut web::ServiceConfig) {
        use api::admin_dispatch_http as adm;
        use api::dispatch_http as dsp;
        let commandes = self.cmd.configurer();
        let dispatch = self.dispatch.clone();
        move |cfg: &mut web::ServiceConfig| {
            commandes(cfg);
            cfg.app_data(web::Data::new(dispatch))
                .service(dsp::basculer_disponibilite_coursier)
                .service(dsp::lire_disponibilite)
                .service(dsp::publier_position)
                .service(dsp::offre_courante)
                .service(dsp::accepter_offre)
                .service(dsp::refuser_offre)
                .service(adm::alertes_dispatch)
                .service(adm::pool_dispatch)
                .service(adm::reprendre_course_admin);
        }
    }

    /// Met un coursier en ligne avec son plafond du jour, **par l'API réelle**.
    pub async fn mettre_en_ligne(&self, index: usize, plafond_unites: i64) -> Value {
        let c = &self.coursiers[index];
        let (statut, corps) = self
            .put(
                "/moi/disponibilite",
                &c.jeton,
                json!({ "en_ligne": true, "plafond_declare_unites": plafond_unites }),
            )
            .await;
        assert_eq!(statut, 200, "mise en ligne : {corps}");
        corps
    }

    /// Publie la position d'un coursier, **par l'API réelle**.
    pub async fn publier_position(&self, index: usize) -> (u16, Value) {
        let c = &self.coursiers[index];
        self.publier_position_a(index, c.lat, c.lon).await
    }

    /// Publie une position choisie (pour exercer le rayon).
    pub async fn publier_position_a(&self, index: usize, lat: f64, lon: f64) -> (u16, Value) {
        let c = &self.coursiers[index];
        self.post(
            "/moi/position",
            &c.jeton,
            json!({
                "uuid_client": Uuid::now_v7(),
                "horodatage_local": chrono::Utc::now(),
                "lat": lat,
                "lon": lon,
                "precision_m": 12,
            }),
        )
        .await
    }

    /// Raccourci : en ligne **et** dans le pool (le chemin nominal de K1).
    pub async fn dans_le_pool(&self, index: usize, plafond_unites: i64) {
        self.mettre_en_ligne(index, plafond_unites).await;
        let (statut, corps) = self.publier_position(index).await;
        assert_eq!(statut, 200, "publication de position : {corps}");
    }

    /// `GET` authentifié sur l'app réelle.
    pub async fn get(&self, uri: &str, jeton: &str) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::get()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        let corps = corps_json(resp).await;
        (statut, corps)
    }

    /// `POST` authentifié sur l'app réelle.
    pub async fn post(&self, uri: &str, jeton: &str, corps: Value) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::post()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .set_json(corps)
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        (statut, corps_json(resp).await)
    }

    /// `PUT` authentifié sur l'app réelle.
    pub async fn put(&self, uri: &str, jeton: &str, corps: Value) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::put()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .set_json(corps)
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        (statut, corps_json(resp).await)
    }

    /// Crée une commande **par l'API réelle**, prête à dispatcher.
    ///
    /// Le vendeur 0 est à ~250 m du centre : la course tient dans le rayon de
    /// 4 km, et le transport `moto` est celui des quatre coursiers du bac.
    pub async fn commande_prete(&self) -> Uuid {
        self.cmd
            .creer_commande_api("marche", vec![self.cmd.vendeurs[0].ligne(1)])
            .await
    }

    /// Déroule un passage de pipeline sur une commande.
    pub async fn dispatcher(&self, commande: Uuid) -> dispatch::DecisionPipeline {
        self.dispatch
            .dispatcher(commande, chrono::Utc::now())
            .await
            .expect("le pipeline ne rend Err que sur une panne d'infrastructure")
    }

    /// Un passage de tic sur la zone du bac.
    pub async fn tic(&self) -> dispatch::ResultatTic {
        self.dispatch
            .tic(self.cmd.ville, chrono::Utc::now())
            .await
            .expect("un incident de tic ne fait jamais tomber l'API")
    }

    /// L'offre en vol d'un coursier, telle que le domaine la voit.
    pub async fn offre_en_vol(&self, index: usize) -> Option<dispatch::Offre> {
        self.dispatch
            .offre_courante(self.coursiers[index].id, chrono::Utc::now())
            .await
            .unwrap()
    }

    /// Vieillit une offre pour la rendre échue, **sans attendre 40 s** :
    /// l'échéance est persistée, donc déplacer l'offre entière dans le passé est
    /// exactement ce que le temps aurait fait.
    ///
    /// ⚠ Les DEUX horodatages reculent : `CHECK (echeance_le > emise_le)`
    /// interdit une offre échue avant d'être émise — un état qui n'existe pas
    /// dans la réalité, et que la base a raison de refuser.
    pub async fn faire_expirer_offre(&self, offre: Uuid) {
        sqlx::query(
            "UPDATE dispatch.offre
                SET emise_le    = now() - interval '60 seconds',
                    echeance_le = now() - interval '20 seconds'
              WHERE id = $1",
        )
        .bind(offre)
        .execute(&self.cmd.pool)
        .await
        .unwrap();
    }

    /// Vieillit une commande — c'est ce que le passage du temps fait à un âge.
    pub async fn vieillir_commande(&self, commande: Uuid, secondes: i64) {
        sqlx::query("UPDATE commandes.commande SET cree_le = cree_le - ($2 || ' seconds')::interval WHERE id = $1")
            .bind(commande)
            .bind(secondes.to_string())
            .execute(&self.cmd.pool)
            .await
            .unwrap();
    }

    /// Vieillit une affectation (base du critère « sans scan »).
    pub async fn vieillir_assignation(&self, livraison: Uuid, secondes: i64) {
        sqlx::query("UPDATE commandes.livraison SET assignee_le = assignee_le - ($2 || ' seconds')::interval WHERE id = $1")
            .bind(livraison)
            .bind(secondes.to_string())
            .execute(&self.cmd.pool)
            .await
            .unwrap();
    }

    /// Vieillit le dernier rapprochement observé (base du « sans mouvement »).
    pub async fn vieillir_progression(&self, livraison: Uuid, secondes: i64) {
        sqlx::query("UPDATE dispatch.suivi_progression SET progresse_le = progresse_le - ($2 || ' seconds')::interval WHERE livraison_id = $1")
            .bind(livraison)
            .bind(secondes.to_string())
            .execute(&self.cmd.pool)
            .await
            .unwrap();
    }

    /// Vrai si l'état de pool d'un coursier existe encore.
    pub async fn pool_coursiers_etat_existe(&self, index: usize) -> bool {
        dispatch::PoolCoursiers::etat(self.pool_coursiers.as_ref(), self.coursiers[index].id)
            .await
            .unwrap()
            .is_some()
    }

    /// Nombre d'événements outbox d'un type.
    pub async fn nb_evenements(&self, type_evenement: &str) -> i64 {
        self.cmd.nb_evenements(type_evenement).await
    }

    /// Payloads d'un type d'événement, dans l'ordre d'écriture.
    pub async fn evenements(&self, type_evenement: &str) -> Vec<Value> {
        self.cmd.evenements(type_evenement).await
    }

    /// Change un paramètre de zone en base — la matière de SC-008 (« sans
    /// redéploiement »).
    pub async fn poser_parametre(&self, zone: Uuid, cle: &str, valeur: Value) {
        let z = PgZones::new(self.cmd.pool.clone());
        let mut tx = self.cmd.pool.begin().await.unwrap();
        z.definir_parametre(&mut tx, zone, cle, valeur, "bac")
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }
}

/// Corps JSON d'une réponse, ou `null` si elle n'en a pas (`204`).
async fn corps_json(resp: actix_web::dev::ServiceResponse) -> Value {
    let octets = actix_web::test::read_body(resp).await;
    if octets.is_empty() {
        Value::Null
    } else {
        serde_json::from_slice(&octets).unwrap_or(Value::Null)
    }
}

/// Les 18 paramètres du cycle, aux MÊMES niveaux que le seed de production :
/// 7 au pays, 11 à la ville. Un test qui les changerait au mauvais niveau ne
/// prouverait pas l'héritage.
async fn seeder_parametres_dispatch(pool: &PgPool, pays: Uuid, ville: Uuid) {
    let z = PgZones::new(pool.clone());
    let mut tx = pool.begin().await.unwrap();
    for (cle, valeur) in [
        ("dispatch.pool_ttl_s", json!(POOL_TTL_S)),
        ("dispatch.timer_offre_s", json!(TIMER_OFFRE_S)),
        ("dispatch.verrou_offre_s", json!(VERROU_OFFRE_S)),
        ("dispatch.timeouts_francs_par_jour", json!(TIMEOUTS_FRANCS)),
        ("dispatch.acceptation_fenetre_jours", json!(7)),
        ("dispatch.note_composante_neutre_millimes", json!(500)),
        ("dispatch.reassignation_deplacement_min_m", json!(150)),
    ] {
        z.definir_parametre(&mut tx, pays, cle, valeur, "bac")
            .await
            .unwrap();
    }
    for (cle, valeur) in [
        ("dispatch.rayon_m", json!(RAYON_M)),
        (
            "dispatch.grille_avance_par_note",
            json!([
                {"note_max_centiemes": 400, "plafond_unites": PALIER_ENTREE},
                {"note_max_centiemes": 450, "plafond_unites": 10_000},
                {"note_max_centiemes": null, "plafond_unites": PALIER_HAUT},
            ]),
        ),
        ("dispatch.poids_proximite", json!(40)),
        ("dispatch.poids_inactivite", json!(30)),
        ("dispatch.poids_note", json!(20)),
        ("dispatch.poids_acceptation", json!(10)),
        ("dispatch.inactivite_plafond_s", json!(1_800)),
        ("dispatch.broadcast_apres_candidats", json!(3)),
        ("dispatch.broadcast_apres_s", json!(120)),
        ("dispatch.reassignation_sans_mouvement_s", json!(300)),
        ("dispatch.reassignation_sans_scan_marge_s", json!(600)),
    ] {
        z.definir_parametre(&mut tx, ville, cle, valeur, "bac")
            .await
            .unwrap();
    }
    tx.commit().await.unwrap();
}

/// Un type de transport du référentiel ZON-03 (idempotent).
async fn seeder_type_transport(pool: &PgPool, slug: &str, ordre: i16) -> Uuid {
    let existant: Option<Uuid> =
        sqlx::query_scalar("SELECT id FROM zones.type_transport WHERE slug = $1")
            .bind(slug)
            .fetch_optional(pool)
            .await
            .unwrap();
    if let Some(id) = existant {
        return id;
    }
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO zones.type_transport (id, slug, nom_cle, ordre) VALUES ($1, $2, $3, $4)",
    )
    .bind(id)
    .bind(slug)
    .bind(format!("transport.{slug}.nom"))
    .bind(ordre)
    .execute(pool)
    .await
    .unwrap();
    id
}

/// Dossier coursier + véhicule déclaré : sans lui, `EtatCoursier` rend un
/// coursier SANS capacité, et rien ne peut lui être offert (FR-017).
async fn declarer_vehicule(pool: &PgPool, compte: Uuid, type_transport: Uuid) {
    sqlx::query(
        "INSERT INTO comptes.dossier_coursier
             (compte_id, piece_cle_objet, piece_mime, referent_nom, referent_telephone_e164)
         VALUES ($1, 'bac/piece.jpg', 'image/jpeg', 'Référent', '+2250700000000')
         ON CONFLICT (compte_id) DO NOTHING",
    )
    .bind(compte)
    .execute(pool)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO comptes.vehicule_declare (id, compte_id, type_transport_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (compte_id, type_transport_id) DO NOTHING",
    )
    .bind(Uuid::now_v7())
    .bind(compte)
    .bind(type_transport)
    .execute(pool)
    .await
    .unwrap();
}

/// La capacité `transport:moto` — celle de tous les coursiers du bac.
pub fn capacite_moto() -> Capacite {
    Capacite::transport("moto")
}
