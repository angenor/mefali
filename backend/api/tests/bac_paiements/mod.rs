//! Bac d'essai partagé des tests d'intégration du cycle PAY (011).
//!
//! Monte l'application Actix **réelle** — mêmes handlers, même extracteur
//! `Auth`, mêmes gardes de rôle et de propriété — sur une base éphémère.
//!
//! # Pourquoi il COMPOSE `bac_commandes` au lieu de le recopier
//!
//! Tout ce dont le paiement a besoin en amont (arbre CI → Tiassalé, catégories,
//! paramètres, vendeurs agréés avec leur catalogue, comptes porteurs de rôles
//! valides et de vrais jetons signés, création de commande par l'API) existe
//! déjà et est **exercé par vingt fichiers de tests**. Le recopier aurait donné
//! deux jeux de données à maintenir, qui auraient divergé au premier
//! ajustement — et la divergence ne se serait vue qu'en production.
//!
//! Ce bac n'ajoute donc que ce qui est propre au cycle : les 4 paramètres de
//! zone, le fournisseur simulé, le dépôt de paiement, et trois aides.
//!
//! # Pourquoi passer par HTTP plutôt que d'appeler le domaine
//!
//! Les refus `401`/`403`, le mapping des clés i18n et **les gardes de
//! propriété** n'existent QUE dans la couche HTTP. Un bac qui appellerait le
//! domaine ne prouverait rien sur elles — la leçon a été payée deux fois, aux
//! cycles 009 et 010. Chaque test de ce cycle traverse une vraie requête.

#![allow(dead_code)] // chaque fichier de test n'en consomme qu'une partie

use std::sync::Arc;

use actix_web::web;
use chrono::{DateTime, Duration, Utc};
use paiements::{FournisseurSimule, PaymentProvider, PgPaiements};
use serde_json::{json, Value};
use uuid::Uuid;

#[path = "../bac_commandes/mod.rs"]
pub mod bac_commandes;

// Ré-exportés pour les fichiers de test du cycle : ils écrivent
// `bac_paiements::PLAFOND_CASH` plutôt que de remonter à `bac_commandes`, et le
// jour où le bac cessera de composer celui du cycle 008, un seul fichier
// changera. `#[allow]` parce que ce module est partagé : chaque binaire de test
// n'en consomme qu'une partie, et l'inutilisé ici est utilisé là.
#[allow(unused_imports)]
pub use bac_commandes::{Vendeur, DEVIS_PART_COURSIER, DEVIS_PRIX_CLIENT, PLAFOND_CASH};

/// Durée de session seedée par le bac (secondes) — la valeur de production.
pub const SESSION_DUREE_S: i64 = 900;
/// Fenêtre de réconciliation seedée (secondes).
pub const RECONCILIATION_S: i64 = 60;
/// Seuil d'alerte d'exposition en créances seedé (unités mineures).
pub const CREANCE_ALERTE_UNITES: i64 = 50_000;

/// Montant d'une commande qui **dépasse** le plafond cash, donc exige un
/// prépaiement. Calculé depuis le plafond du bac plutôt qu'écrit en dur : si le
/// plafond bouge, le test doit suivre, pas mentir.
pub const AU_DESSUS_DU_PLAFOND: i64 = PLAFOND_CASH + 1;

/// Corps d'une réponse, `null` si elle est vide (`204`, ou refus sans corps).
///
/// Un corps NON JSON est rendu comme chaîne plutôt que de faire paniquer le
/// test : actix rend certains refus d'infrastructure — un `413` produit par le
/// plafond de charge, par exemple — en texte brut, et le test doit pouvoir
/// asserter le **statut** sans buter sur la forme du corps.
async fn corps_json(resp: actix_web::dev::ServiceResponse) -> Value {
    let octets = actix_web::test::read_body(resp).await;
    if octets.is_empty() {
        return Value::Null;
    }
    serde_json::from_slice(&octets)
        .unwrap_or_else(|_| Value::String(String::from_utf8_lossy(&octets).into_owned()))
}

pub struct Bac {
    /// Le bac du cycle 008, avec toute sa base.
    pub cmd: bac_commandes::Bac,
    /// Dépôt de paiement.
    pub paiements: PgPaiements,
    /// Fournisseur simulé — **la même instance** que celle câblée dans l'app,
    /// pour que le test pilote ce que l'application consomme.
    pub fournisseur: Arc<FournisseurSimule>,
}

impl Bac {
    pub async fn nouveau(pool: sqlx::PgPool) -> Self {
        Self::depuis(bac_commandes::Bac::nouveau(pool.clone()).await, pool).await
    }

    /// Variante dont le devis figé porte une **retenue vendeur** (VND-08) —
    /// sert les tests de reçu, où les trois montants doivent différer.
    pub async fn nouveau_livraison_offerte_par_vendeur(pool: sqlx::PgPool) -> Self {
        Self::depuis(
            bac_commandes::Bac::nouveau_livraison_offerte_par_vendeur(pool.clone()).await,
            pool,
        )
        .await
    }

    async fn depuis(cmd: bac_commandes::Bac, pool: sqlx::PgPool) -> Self {
        // Les 4 paramètres du cycle, au PAYS — hérités par Tiassalé, comme en
        // production. Les poser sur la ville rendrait le test vert alors que la
        // production, qui hérite, échouerait.
        let z = zones::PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        for (cle, valeur) in [
            (
                paiements::cles_config::SESSION_DUREE_S,
                json!(SESSION_DUREE_S),
            ),
            (
                paiements::cles_config::RECONCILIATION_AVANT_EXPIRATION_S,
                json!(RECONCILIATION_S),
            ),
            (
                paiements::cles_config::CREANCE_ALERTE_UNITES,
                json!(CREANCE_ALERTE_UNITES),
            ),
            // VIDE — le cas nominal. FR-011 interdit de masquer un moyen ; un
            // bac qui armerait le coupe-circuit testerait l'exception au lieu
            // de la règle.
            (paiements::cles_config::MOYENS_ACTIFS, json!([])),
        ] {
            z.definir_parametre(&mut tx, cmd.pays, cle, valeur, "bac")
                .await
                .unwrap();
        }
        tx.commit().await.unwrap();

        Self {
            paiements: PgPaiements::new(pool),
            fournisseur: Arc::new(FournisseurSimule::nouveau()),
            cmd,
        }
    }

    /// Configure l'application de test : les routes du cycle 008 **plus** celles
    /// du paiement, et les services que leurs handlers extraient.
    pub fn configurer(&self) -> impl FnOnce(&mut web::ServiceConfig) {
        let base = self.cmd.configurer();
        let paiements = self.paiements.clone();
        let prestataires = self.cmd.prestataires.clone();
        let fournisseur: Arc<dyn PaymentProvider> = self.fournisseur.clone();
        move |cfg: &mut web::ServiceConfig| {
            base(cfg);
            cfg.app_data(web::Data::new(paiements))
                // Le reçu vendeur (T059) vit dans `vendeur_http` : sa garde de
                // pilotage lit le dépôt prestataires, que le bac du cycle 008
                // n'enregistre pas.
                .app_data(web::Data::new(prestataires))
                .app_data(web::Data::new(fournisseur))
                // Le plafond de corps brut du webhook (64 Kio) — enregistré
                // ici comme il l'est dans `api::run`, sinon le bac testerait
                // une route plus permissive que la production.
                .app_data(api::paiements_webhook_http::config_payload());
            // Les routes de paiement s'enregistrent ici à mesure qu'elles
            // arrivent. Le bac est posé AVANT elles pour que chacune n'ait
            // qu'une ligne à ajouter, et pour qu'aucune ne soit tentée d'être
            // testée hors HTTP faute de bac.
            cfg.service(api::paiements_http::ouvrir_paiement)
                .service(api::paiements_http::etat_paiement)
                .service(api::paiements_http::recu_commande)
                .service(api::vendeur_http::recu_arret)
                .service(api::paiements_webhook_http::recevoir_notification)
                // Surfaces d'exploitation du cycle (T071/T072).
                .service(api::admin_paiements_http::registre_transactions)
                .service(api::admin_paiements_http::file_dossiers)
                .service(api::admin_paiements_http::clore_dossier)
                .service(api::admin_paiements_http::file_creances)
                .service(api::admin_paiements_http::regler_creance);
        }
    }

    // ── Requêtes HTTP RÉELLES ─────────────────────────────────────────────
    //
    // Redéfinies ici plutôt qu'empruntées à `bac_commandes` : les siennes
    // montent SON `configurer()`, qui ne connaît aucune route de paiement. Un
    // test qui les emploierait recevrait `404` sur `/commandes/{id}/paiement`
    // et croirait avoir prouvé quelque chose.

    /// `GET` authentifié sur une route du bac.
    pub async fn get(&self, uri: &str, jeton: &str) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::get()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        (statut, corps_json(resp).await)
    }

    /// `POST` JSON authentifié sur une route du bac.
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

    /// `POST` **sans corps** — le cas de l'ouverture de session, qui ne prend
    /// aucun paramètre : l'identifiant de commande porte tout.
    pub async fn post_vide(&self, uri: &str, jeton: &str) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let req = actix_web::test::TestRequest::post()
            .uri(uri)
            .insert_header(("authorization", format!("Bearer {jeton}")))
            .to_request();
        let resp = actix_web::test::call_service(&app, req).await;
        let statut = resp.status().as_u16();
        (statut, corps_json(resp).await)
    }

    /// `POST` de corps **brut**, non authentifié, avec ses en-têtes — le
    /// chemin du webhook.
    ///
    /// Volontairement `&[u8]` et non `Value` : la signature se vérifie sur le
    /// corps **tel qu'il arrive**, et un test qui laisserait `serde_json`
    /// re-sérialiser la charge ne signerait pas les mêmes octets que ceux
    /// vérifiés (research R6).
    pub async fn post_brut(
        &self,
        uri: &str,
        corps: &[u8],
        entetes: &[(&str, String)],
    ) -> (u16, Value) {
        let app =
            actix_web::test::init_service(actix_web::App::new().configure(self.configurer())).await;
        let mut req = actix_web::test::TestRequest::post()
            .uri(uri)
            .insert_header(("content-type", "application/json"))
            .set_payload(corps.to_vec());
        for (nom, valeur) in entetes {
            req = req.insert_header((*nom, valeur.clone()));
        }
        let resp = actix_web::test::call_service(&app, req.to_request()).await;
        let statut = resp.status().as_u16();
        (statut, corps_json(resp).await)
    }

    // ── Aides propres au cycle ────────────────────────────────────────────

    /// Crée une commande **prépayée** par l'API : mode `mobile_money`, montant
    /// au-dessus du plafond cash, donc née `en_attente_paiement`.
    ///
    /// C'est le seul chemin vers une session de paiement : le forcer en SQL
    /// sauterait la garde du plafond, et le test prouverait alors quelque chose
    /// que la production ne fait pas.
    pub async fn commande_prepayee(&self) -> Uuid {
        let vendeur = &self.cmd.vendeurs[0];
        // Quantité choisie pour franchir le plafond cash avec le prix seedé.
        let quantite = (AU_DESSUS_DU_PLAFOND / vendeur.prix[0] + 1) as i16;
        self.cmd
            .creer_commande_mode("marche", vec![vendeur.ligne(quantite)], "mobile_money")
            .await
    }

    /// Un passage de balayage, tel que le job le fait toutes les 10 s.
    ///
    /// Appelé directement plutôt qu'en montant le job : un test qui attend un
    /// ordonnancement asynchrone n'est pas un test, c'est un pari.
    pub async fn balayer(&self) -> paiements::BilanBalayage {
        paiements::balayer(
            &self.paiements,
            &self.cmd.commandes,
            self.fournisseur.as_ref(),
        )
        .await
        .expect("le balayage aboutit")
    }

    /// Crée un compte porteur du rôle **vendeur**, rattaché au prestataire
    /// donné, et rend `(compte, jeton)`.
    ///
    /// Le bac du cycle 008 n'en a pas : ses tests n'exercent que le client, le
    /// coursier et l'admin. Le reçu vendeur (T059) est le premier à en avoir
    /// besoin ici.
    pub async fn compte_vendeur(&self, prestataire: Uuid, e164: &str) -> (Uuid, String) {
        let (compte, jeton) = self
            .cmd
            .compte_avec_roles(e164, &["client", "vendeur"])
            .await;
        let mut tx = self.cmd.pool.begin().await.unwrap();
        self.cmd
            .prestataires
            .rattacher_compte(&mut tx, prestataire, compte, self.cmd.admin)
            .await
            .expect("rattachement du compte vendeur");
        tx.commit().await.unwrap();
        (compte, jeton)
    }

    /// Signe un corps de notification comme le fournisseur le ferait.
    ///
    /// Délègue au double : un test qui signerait autrement que le vérificateur
    /// ne testerait que sa propre arithmétique.
    pub fn signer(&self, corps: &[u8]) -> String {
        self.fournisseur.signer(corps, Utc::now())
    }

    /// En-tête de signature d'un corps, prêt à être posé sur la requête.
    pub fn entete_signature(&self, corps: &[u8]) -> (&'static str, String) {
        (
            paiements::fournisseur::simule::ENTETE_SIGNATURE,
            self.signer(corps),
        )
    }

    /// Poste une notification **signée** sur la route réelle du webhook.
    ///
    /// Passe par HTTP, comme un fournisseur le ferait : appeler le domaine
    /// directement ne prouverait rien sur la lecture du corps brut, ni sur le
    /// segment `{fournisseur}` de l'URL.
    pub async fn notifier(
        &self,
        transaction: Uuid,
        montant_unites: i64,
        devise: &str,
        issue: paiements::IssuePaiement,
    ) -> (u16, Value) {
        self.notifier_moyen(transaction, montant_unites, devise, issue, None)
            .await
    }

    /// Notification annonçant le **moyen** employé (FR-012). Le moyen est
    /// optionnel dans le protocole : un fournisseur qui le tait laisse le
    /// produit sur `inconnu`, jamais sur une supposition.
    pub async fn notifier_moyen(
        &self,
        transaction: Uuid,
        montant_unites: i64,
        devise: &str,
        issue: paiements::IssuePaiement,
        moyen: Option<&str>,
    ) -> (u16, Value) {
        let corps = FournisseurSimule::corps_notification_moyen(
            transaction,
            montant_unites,
            devise,
            issue,
            moyen,
        );
        let entete = self.entete_signature(&corps);
        self.post_brut(
            &format!(
                "/paiements/notifications/{}",
                paiements::PaymentProvider::nom(self.fournisseur.as_ref()),
            ),
            &corps,
            &[(entete.0, entete.1)],
        )
        .await
    }

    /// Corps d'une notification, tel que le double le comprend.
    pub fn corps_notification(
        transaction: Uuid,
        montant_unites: i64,
        devise: &str,
        issue: paiements::IssuePaiement,
    ) -> Vec<u8> {
        FournisseurSimule::corps_notification(transaction, montant_unites, devise, issue)
    }

    /// **Porte l'horloge au-delà de l'échéance** d'une session.
    ///
    /// Techniquement, c'est l'inverse : c'est l'ÉCHÉANCE qui recule, pas
    /// l'horloge qui avance. Le choix est délibéré et mérite d'être expliqué,
    /// parce qu'il détermine ce que le test prouve.
    ///
    /// `PgPaiements::maintenant()` lit l'horloge **serveur** (constitution :
    /// aucune décision d'argent ne dépend de l'horloge d'un appareil). La
    /// remplacer par une horloge injectable pour les besoins du test rendrait
    /// le code de production configurable sur exactement le point qu'il ne doit
    /// pas l'être — et un jour, quelqu'un l'injecterait ailleurs qu'en test.
    ///
    /// Reculer `expire_le` en base produit **l'état que le temps produirait**,
    /// sans toucher au code de production. Le balayage voit une session échue
    /// pour la seule raison qui vaille : sa date d'échéance est passée.
    pub async fn perimer_session(&self, commande: Uuid) {
        sqlx::query(
            "UPDATE paiements.transaction
                SET expire_le = now() - interval '1 second',
                    ouverte_le = now() - make_interval(secs => $2)
              WHERE commande_id = $1 AND etat = 'ouverte'",
        )
        .bind(commande)
        .bind(SESSION_DUREE_S as f64 + 1.0)
        .execute(&self.cmd.pool)
        .await
        .unwrap();
    }

    /// Échéance persistée d'une session — pour vérifier qu'elle est calculée
    /// depuis `paiement.session_duree_s` et non depuis une constante.
    pub async fn echeance(&self, commande: Uuid) -> Option<DateTime<Utc>> {
        sqlx::query_scalar(
            "SELECT expire_le FROM paiements.transaction
              WHERE commande_id = $1 ORDER BY ouverte_le DESC LIMIT 1",
        )
        .bind(commande)
        .fetch_optional(&self.cmd.pool)
        .await
        .unwrap()
    }

    /// Durée nominale d'une session, sous forme de `Duration` — évite qu'un
    /// test réécrive `900` à la main.
    pub fn duree_session() -> Duration {
        Duration::seconds(SESSION_DUREE_S)
    }

    /// Transactions d'une commande, l'état de chacune.
    pub async fn etats_transactions(&self, commande: Uuid) -> Vec<String> {
        sqlx::query_scalar(
            "SELECT etat::text FROM paiements.transaction
              WHERE commande_id = $1 ORDER BY ouverte_le",
        )
        .bind(commande)
        .fetch_all(&self.cmd.pool)
        .await
        .unwrap()
    }

    /// Événements outbox d'un type donné, dans l'ordre.
    ///
    /// Sert autant à vérifier qu'un événement est écrit qu'à vérifier qu'il
    /// l'est **une seule fois** — le rejeu d'une notification ne doit produire
    /// ni second effet ni second événement (FR-021).
    pub async fn evenements(&self, type_evenement: &str) -> Vec<Value> {
        sqlx::query_scalar(
            "SELECT payload FROM outbox.evenement
              WHERE type_evenement = $1 ORDER BY survenu_le, id",
        )
        .bind(type_evenement)
        .fetch_all(&self.cmd.pool)
        .await
        .unwrap()
    }

    /// Dossiers d'anomalie ouverts, du plus récent au plus ancien.
    pub async fn dossiers(&self) -> Vec<(String, String)> {
        sqlx::query_as(
            "SELECT type_dossier::text, motif_cle FROM paiements.dossier
              ORDER BY ouvert_le DESC",
        )
        .fetch_all(&self.cmd.pool)
        .await
        .unwrap()
    }

    /// Notifications reçues, avec la validité de leur signature.
    pub async fn notifications(&self) -> Vec<(String, bool)> {
        sqlx::query_as(
            "SELECT issue, signature_valide FROM paiements.notification_recue
              ORDER BY recue_le",
        )
        .fetch_all(&self.cmd.pool)
        .await
        .unwrap()
    }

    /// État de paiement du tronc — la valeur que R16 pose enfin.
    pub async fn etat_paiement(&self, commande: Uuid) -> String {
        sqlx::query_scalar("SELECT etat_paiement::text FROM commandes.commande WHERE id = $1")
            .bind(commande)
            .fetch_one(&self.cmd.pool)
            .await
            .unwrap()
    }

    /// État du tronc.
    pub async fn etat_commande(&self, commande: Uuid) -> String {
        sqlx::query_scalar("SELECT etat::text FROM commandes.commande WHERE id = $1")
            .bind(commande)
            .fetch_one(&self.cmd.pool)
            .await
            .unwrap()
    }
}
