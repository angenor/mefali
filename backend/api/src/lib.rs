//! Assemblage Actix du backend Mefali.
//!
//! Ce cycle : contrat OpenAPI (auto-collecté par utoipa-actix-web), sonde
//! `/health`, Swagger UI en dev (absente en production, constitution VIII),
//! export de `openapi.json`. Le worker outbox est branché par T019.

/// Surface HTTP admin du cycle CMD (file d'attente, annulation, issues).
pub mod admin_commandes_http;
/// Surface HTTP admin du cycle CRS (blocages, dépôt, caisse, indemnisations).
pub mod admin_coursier_http;
/// Surface HTTP admin du cycle DSP (alertes, pool, reprise manuelle).
pub mod admin_dispatch_http;
pub mod admin_prestataires_http;
pub mod admin_tarification_http;
pub mod adresses_http;
pub mod auth_http;
pub mod commandes_http;
pub mod comptes_http;
/// Surface HTTP coursier du cycle CMD (boucle d'arrêt, remise, échec).
pub mod course_http;
/// Surface réservée au dev — montée hors production seulement (voir le module).
pub mod dev_http;
/// Surface HTTP coursier du cycle DSP (disponibilité, position, offres).
pub mod coursier_http;
pub mod dispatch_http;
/// Mapping HTTP partagé des refus du domaine commandes (T014).
pub mod erreurs_commandes;
/// Mapping HTTP partagé des refus du domaine dispatch (cycle DSP 009, T021).
pub mod erreurs_dispatch;
pub mod health;
/// Impl RÉELLE du port `ProximiteRoutiere` au-dessus du moteur de routage (T020).
pub mod infra_dispatch;
pub mod infra_redis;
pub mod infra_s3;
pub mod prestataires_http;
pub mod qr_http;
pub mod signalements_http;
pub mod vendeur_http;
pub mod zones_http;

use std::sync::Arc;

use actix_web::{web, App, HttpResponse, HttpServer};
use comptes::{EnvoiSms, PgComptes, SmsTraces};
use utoipa::openapi::security::{HttpAuthScheme, HttpBuilder, SecurityScheme};
use utoipa::openapi::{InfoBuilder, OpenApi};
use utoipa_actix_web::AppExt;
use utoipa_swagger_ui::SwaggerUi;

/// Construit la spec OpenAPI à partir des handlers `#[utoipa::path]`
/// (auto-collectés par utoipa-actix-web). Source de vérité du contrat (TRX-01).
pub fn api_openapi() -> OpenApi {
    let (_, mut openapi) = App::new()
        .into_utoipa_app()
        .service(health::health)
        .service(zones_http::forcer_categorie)
        .service(zones_http::config)
        .service(auth_http::demander)
        .service(auth_http::verifier)
        .service(auth_http::inscrire)
        .service(auth_http::rafraichir)
        .service(auth_http::deconnexion)
        .service(auth_http::moi)
        .service(auth_http::mes_sessions)
        .service(auth_http::revoquer_session)
        .service(comptes_http::decider_role)
        .service(comptes_http::soumettre_dossier_coursier)
        .service(comptes_http::mon_dossier_coursier)
        .service(comptes_http::lister_dossiers_coursier)
        .service(comptes_http::consulter_dossier_coursier)
        .service(adresses_http::mes_adresses)
        .service(adresses_http::enregistrer_adresse)
        .service(adresses_http::modifier_adresse)
        .service(adresses_http::supprimer_adresse)
        .service(adresses_http::ecouter_repere_vocal)
        .service(adresses_http::remplacer_repere_vocal)
        .service(admin_prestataires_http::creer_prestataire)
        .service(admin_prestataires_http::lister_prestataires)
        .service(admin_prestataires_http::consulter_prestataire_admin)
        .service(admin_prestataires_http::modifier_prestataire)
        .service(admin_prestataires_http::ajouter_photo)
        .service(admin_prestataires_http::supprimer_photo)
        .service(admin_prestataires_http::deposer_charte)
        .service(admin_prestataires_http::definir_site)
        .service(admin_prestataires_http::agreer_prestataire)
        .service(admin_prestataires_http::rattacher_compte)
        .service(admin_prestataires_http::detacher_compte)
        .service(vendeur_http::mes_prestataires)
        .service(vendeur_http::mes_articles)
        .service(vendeur_http::creer_article)
        .service(vendeur_http::modifier_article)
        .service(vendeur_http::photo_article)
        .service(vendeur_http::retirer_article)
        .service(vendeur_http::remettre_article)
        .service(admin_prestataires_http::creer_article_admin)
        .service(admin_prestataires_http::modifier_article_admin)
        .service(admin_prestataires_http::photo_article_admin)
        .service(admin_prestataires_http::retirer_article_admin)
        .service(admin_prestataires_http::remettre_article_admin)
        .service(vendeur_http::ma_boutique)
        .service(vendeur_http::action_boutique)
        .service(vendeur_http::modifier_horaires)
        .service(admin_prestataires_http::action_boutique_admin)
        .service(admin_prestataires_http::suspendre_prestataire)
        .service(admin_prestataires_http::retablir_prestataire)
        .service(admin_prestataires_http::corriger_prestataire)
        .service(vendeur_http::basculer_disponibilite)
        .service(admin_prestataires_http::basculer_disponibilite_admin)
        .service(signalements_http::signaler_rupture)
        .service(prestataires_http::consulter_prestataire)
        .service(prestataires_http::resoudre_plaque)
        .service(qr_http::telecharger_plaque)
        .service(qr_http::collecter)
        .service(coursier_http::course_active)
        .service(coursier_http::journaliser_appel)
        .service(coursier_http::declarer_issue_appel)
        .service(coursier_http::enregistrer_presence)
        .service(coursier_http::deposer_photo_preuve)
        .service(coursier_http::etat_preuves)
        .service(coursier_http::ma_caisse)
        .service(coursier_http::ma_journee)
        .service(admin_coursier_http::remises_bloquees)
        .service(admin_coursier_http::debloquer_code)
        .service(admin_coursier_http::autoriser_depot)
        .service(admin_coursier_http::preuves_de_livraison)
        .service(admin_coursier_http::exposition_cash)
        .service(admin_coursier_http::file_indemnisations)
        .service(admin_coursier_http::valider_indemnisation)
        .service(admin_coursier_http::refuser_indemnisation)
        .service(admin_tarification_http::grille_de_zone)
        .service(admin_tarification_http::creer_brouillon)
        .service(admin_tarification_http::ecrire_regle)
        .service(admin_tarification_http::supprimer_regle)
        .service(admin_tarification_http::simuler)
        .service(admin_tarification_http::publier)
        .service(commandes_http::devis_panier)
        .service(commandes_http::creer_commande)
        .service(course_http::arret_en_route)
        .service(course_http::arret_arrive)
        .service(course_http::arret_indisponible)
        .service(course_http::declarer_rupture)
        .service(course_http::remise)
        .service(course_http::declarer_echec)
        .service(commandes_http::decider_substitution)
        .service(commandes_http::mes_commandes)
        .service(commandes_http::suivre_commande)
        .service(commandes_http::intention_appel)
        .service(commandes_http::annuler_commande)
        .service(admin_commandes_http::file_attente)
        .service(admin_commandes_http::annuler_commande_admin)
        .service(dispatch_http::basculer_disponibilite_coursier)
        .service(dispatch_http::lire_disponibilite)
        .service(dispatch_http::publier_position)
        .service(dispatch_http::offre_courante)
        .service(dispatch_http::accepter_offre)
        .service(dispatch_http::refuser_offre)
        .service(admin_dispatch_http::alertes_dispatch)
        .service(admin_dispatch_http::pool_dispatch)
        .service(admin_dispatch_http::reprendre_course_admin)
        .service(admin_commandes_http::enregistrer_issue)
        .split_for_parts();
    openapi.info = InfoBuilder::new()
        .title("Mefali API")
        .version("0.1.0")
        .build();
    // Jeton d'accès JWT (cycle CPT, research R5). Remplace le SecurityScheme
    // `adminToken` (X-Admin-Token) du cycle 002, supprimé avec sa garde.
    openapi
        .components
        .get_or_insert_with(Default::default)
        .add_security_scheme(
            "bearerAuth",
            SecurityScheme::Http(
                HttpBuilder::new()
                    .scheme(HttpAuthScheme::Bearer)
                    .bearer_format("JWT")
                    .build(),
            ),
        );
    openapi
}

/// Surfaces annexes au contrat :
/// - `/api-docs/openapi.json` : servi en dev ET en prod (contrat public) ;
/// - Swagger UI : seulement hors production (constitution VIII).
fn mount_docs(prod: bool, openapi: OpenApi) -> impl FnOnce(&mut web::ServiceConfig) {
    move |cfg: &mut web::ServiceConfig| {
        if prod {
            cfg.route(
                "/api-docs/openapi.json",
                web::get().to(move || {
                    let openapi = openapi.clone();
                    async move { HttpResponse::Ok().json(openapi) }
                }),
            );
        } else {
            cfg.service(
                SwaggerUi::new("/swagger-ui/{_:.*}").url("/api-docs/openapi.json", openapi.clone()),
            );
        }
    }
}

/// Surface réservée au DEV : `/dev/otp` relit le dernier code OTP tracé
/// (`dev_http`). Montée sous le MÊME `prod` que Swagger UI — en production, la
/// route n'est jamais enregistrée et le chemin rend 404.
///
/// Le gate porte sur un `bool`, comme [`mount_docs`] : testable sans toucher à
/// l'environnement du processus, que les tests parallèles partagent.
///
/// `traces` est `None` quand la configuration est absente (mode dégradé,
/// `/health` seul) : pas de journal, donc rien à relire.
fn mount_dev(
    prod: bool,
    traces: Option<Arc<SmsTraces>>,
) -> impl FnOnce(&mut web::ServiceConfig) {
    move |cfg: &mut web::ServiceConfig| {
        if let (false, Some(traces)) = (prod, traces) {
            cfg.app_data(web::Data::new(traces))
                .route("/dev/otp", web::get().to(dev_http::dernier_code));
        }
    }
}

/// Région S3 signée mais non routante côté Garage (`infra/garage/garage.toml`).
const REGION_S3: &str = "garage";

/// Intervalle du job de purge des repères vocaux (research R8).
///
/// Quotidien : la rétention se compte en MOIS (12 par défaut), purger plus
/// souvent ne minimiserait rien de plus et réveillerait la base pour rien.
const PURGE_INTERVALLE: std::time::Duration = std::time::Duration::from_secs(24 * 60 * 60);

/// Purge périodique des repères vocaux inutilisés (FR-022, research R8).
///
/// Même patron que `WorkerOutbox` : une tâche tokio dans le process existant.
/// Une erreur est journalisée et le passage suivant retente — un incident de
/// purge ne doit jamais faire tomber l'API.
async fn job_purge_reperes(depot: PgComptes) {
    let mut horloge = tokio::time::interval(PURGE_INTERVALLE);
    loop {
        horloge.tick().await;
        match depot.purger_reperes_vocaux().await {
            Ok(0) => {}
            Ok(n) => tracing::info!(purgees = n, "repères vocaux purgés (rétention de zone)"),
            Err(e) => tracing::error!(erreur = %e, "purge des repères vocaux échouée"),
        }
    }
}

/// Intervalle de balayage des propositions de remplacement ÉCHUES (R10).
///
/// La fenêtre de décision se compte en DIZAINES DE SECONDES (60 s par défaut) :
/// un balayage horaire laisserait le coursier planté devant un étal pendant une
/// heure. Dix secondes est le pas qui rend l'échéance vécue conforme à
/// l'échéance promise, sans transformer la base en horloge.
///
/// ⚠ Ce job n'est PAS la source de vérité de l'expiration : l'échéance est
/// PERSISTÉE et toute lecture la respecte déjà (`suivi`, `decider_substitution`).
/// Le job ne fait qu'écrire ce que la lecture savait déjà — une décision
/// d'argent ne dépend pas de la vie d'un processus.
const BALAYAGE_SUBSTITUTIONS: std::time::Duration = std::time::Duration::from_secs(10);

/// **PREMIER consommateur outbox réel du produit.**
///
/// `WorkerOutbox::new(pool, Vec::new())` tournait jusqu'ici avec zéro
/// consommateur : le trait `ConsommateurOutbox` était le point d'extension
/// prévu, et le dispatch est le premier à s'y brancher. Son intervalle par
/// défaut (1 s) donne une latence d'assignation d'environ une seconde après la
/// création — très en dessous des 2 min de SC-002.
///
/// ⚠ **Ne rend `Err` QUE sur une panne d'infrastructure récupérable.** Le worker
/// ne marque l'événement publié que si TOUS les consommateurs rendent `Ok` ; un
/// `Err` incrémente `tentatives` et l'événement est rejoué **indéfiniment**.
/// Toute issue MÉTIER — aucun éligible, bascule prépaiement, pool vide — est
/// donc un succès écrit en base : sinon une commande sans coursier bloquerait sa
/// propre ligne d'outbox pour toujours (research R1).
struct DispatchOutbox {
    depot: dispatch::PgDispatch,
}

#[async_trait::async_trait]
impl socle::ConsommateurOutbox for DispatchOutbox {
    fn nom(&self) -> &'static str {
        "dispatch"
    }

    async fn consommer(
        &self,
        evenement: &socle::EvenementPublie,
    ) -> Result<(), socle::ConsommationError> {
        // Indifférent au reste du journal : un consommateur reçoit TOUT, et ne
        // doit réagir qu'à ce qui le concerne (idempotent par construction).
        match evenement.type_evenement.as_str() {
            // Une commande prête, ou un prépaiement confirmé qui la rend
            // dispatchable à nouveau — la reprise se fait SANS le critère
            // d'avance, puisque le client a payé.
            "commande.prete_a_dispatcher" | "commande.paiement_confirme" => {
                match self
                    .depot
                    .dispatcher(evenement.entite_id, chrono::Utc::now())
                    .await
                {
                    Ok(decision) => {
                        tracing::info!(
                            commande = %evenement.entite_id,
                            decision = ?decision,
                            "pipeline de dispatch exécuté",
                        );
                        Ok(())
                    }
                    // Panne d'infrastructure : on laisse le worker rejouer.
                    Err(dispatch::ErreurDispatch::Sql(e)) => {
                        Err(socle::ConsommationError(format!("base de données : {e}")))
                    }
                    Err(dispatch::ErreurDispatch::Dependance(detail)) => {
                        Err(socle::ConsommationError(detail))
                    }
                    // Refus métier ou configuration : journalisé, JAMAIS rejoué
                    // — rejouer ne changerait rien et bloquerait la ligne.
                    Err(e) => {
                        tracing::warn!(
                            commande = %evenement.entite_id, erreur = %e,
                            "dispatch sans effet — l'événement reste consommé",
                        );
                        Ok(())
                    }
                }
            }
            _ => Ok(()),
        }
    }
}

/// Pas du tic de dispatch. Tout ce qui est TEMPOREL y passe : expiration
/// d'offre, broadcast, escalade, réassignation, reprise FIFO, élagage.
///
/// 5 s : une offre dure 40 s, et un compte à rebours résolu à la minute
/// laisserait le coursier suivant attendre pour rien. Comme
/// [`BALAYAGE_SUBSTITUTIONS`], ce job n'est PAS la source de vérité de
/// l'expiration — l'échéance est persistée et toute lecture la respecte déjà.
const TIC_DISPATCH: std::time::Duration = std::time::Duration::from_secs(5);

/// Le tic de dispatch, par zone active.
///
/// Une erreur est journalisée et retentée au passage suivant : un incident de
/// tic ne doit **jamais** faire tomber l'API.
async fn job_tic_dispatch(depot: dispatch::PgDispatch, pool: sqlx::PgPool) {
    let mut horloge = tokio::time::interval(TIC_DISPATCH);
    loop {
        horloge.tick().await;
        // Les zones qui ont de l'activité : celles où vit au moins une commande
        // non close. Balayer tout l'arbre coûterait une requête par ville pour
        // rien.
        let zones: Vec<uuid::Uuid> = match sqlx::query_scalar(
            "SELECT DISTINCT zone_id FROM commandes.commande
             WHERE etat IN ('nouvelle', 'en_attente_coursier', 'en_cours')",
        )
        .fetch_all(&pool)
        .await
        {
            Ok(z) => z,
            Err(e) => {
                tracing::error!(erreur = %e, "tic de dispatch : zones illisibles");
                continue;
            }
        };
        for zone in zones {
            if let Err(e) = depot.tic(zone, chrono::Utc::now()).await {
                tracing::error!(zone = %zone, erreur = %e, "tic de dispatch échoué");
            }
        }
    }
}

/// Résolution périodique des propositions de remplacement échues (FR-046).
///
/// À l'expiration on APPELLE, puis l'article est retiré et non facturé. Une
/// erreur est journalisée et le passage suivant retente : un incident de
/// balayage ne doit jamais faire tomber l'API.
async fn job_expirer_substitutions(depot: commandes::PgCommandes) {
    let mut horloge = tokio::time::interval(BALAYAGE_SUBSTITUTIONS);
    loop {
        horloge.tick().await;
        match depot.expirer_substitutions_echues(chrono::Utc::now()).await {
            Ok(v) if v.is_empty() => {}
            Ok(v) => tracing::info!(expirees = v.len(), "propositions de remplacement expirées"),
            Err(e) => tracing::error!(erreur = %e, "balayage des substitutions échoué"),
        }
    }
}

/// Purge périodique des photos de récupération expirées (QRC-02, constitution
/// VIII, research R8). Même patron que [`job_purge_reperes`] : une tâche tokio,
/// un échec journalisé et retenté au passage suivant.
async fn job_purge_photos_substitution(depot: commandes::PgCommandes) {
    let mut horloge = tokio::time::interval(PURGE_INTERVALLE);
    loop {
        horloge.tick().await;
        match depot.purger_photos_substitution().await {
            Ok(0) => {}
            Ok(n) => tracing::info!(purgees = n, "photos de substitution purgées (rétention de zone)"),
            Err(e) => tracing::error!(erreur = %e, "purge des photos de substitution échouée"),
        }
    }
}

/// Purge périodique des photos de récupération expirées (QRC-02, constitution
/// VIII, research R8).
async fn job_purge_photos_collecte(depot: qr::PgQr) {
    let mut horloge = tokio::time::interval(PURGE_INTERVALLE);
    loop {
        horloge.tick().await;
        match depot.purger_photos_collecte().await {
            Ok(0) => {}
            Ok(n) => tracing::info!(purgees = n, "photos de récupération purgées (rétention de zone)"),
            Err(e) => tracing::error!(erreur = %e, "purge des photos de récupération échouée"),
        }
    }
}

/// **Second consommateur réel du produit** (CRS-06, R9) — le livre de caisse.
///
/// Adaptateur seulement : toute la traduction événement → écriture vit dans le
/// crate `coursier`. C'est ce qui permet de la tester sans monter un worker, et
/// ce qui évite qu'une règle d'argent finisse dans la couche HTTP.
///
/// Trois types consommés, tout le reste ignoré — un consommateur reçoit TOUT le
/// journal (contrat `socle`).
struct CaisseOutbox {
    depot: coursier::PgCoursier,
}

#[async_trait::async_trait]
impl socle::ConsommateurOutbox for CaisseOutbox {
    fn nom(&self) -> &'static str {
        "caisse"
    }

    async fn consommer(
        &self,
        evenement: &socle::EvenementPublie,
    ) -> Result<(), socle::ConsommationError> {
        match self.depot.consommer_pour_caisse(evenement).await {
            Ok(()) => Ok(()),
            // Panne d'infrastructure : l'événement reste non publié et sera
            // rejoué. L'idempotence par `evenement_id` rend le rejeu inoffensif.
            Err(coursier::ErreurCoursier::Sql(e)) => {
                Err(socle::ConsommationError(format!("base de données : {e}")))
            }
            // Refus métier ou configuration : journalisé, JAMAIS rejoué —
            // rejouer ne changerait rien et bloquerait la ligne pour tout le
            // monde (patron `DispatchOutbox`).
            Err(e) => {
                tracing::warn!(
                    evenement = %evenement.id, type_evenement = %evenement.type_evenement,
                    erreur = %e, "caisse sans effet — l'événement reste consommé",
                );
                Ok(())
            }
        }
    }
}

/// Purge périodique des photos de **preuve d'échec** échues (CRS-05, FR-064).
///
/// Même patron que [`job_purge_photos_collecte`], à une différence près : la
/// LIGNE survit à la purge de ses octets. Un échec déclaré il y a un an ne doit
/// pas redevenir « non prouvé » le jour où la rétention expire — seule la photo
/// disparaît, la preuve reste datée.
async fn job_purge_photos_preuve(depot: coursier::PgCoursier) {
    let mut horloge = tokio::time::interval(PURGE_INTERVALLE);
    loop {
        horloge.tick().await;
        match depot.purger_photos_preuve().await {
            Ok(0) => {}
            Ok(n) => tracing::info!(purgees = n, "photos de preuve purgées (rétention de zone)"),
            Err(e) => tracing::error!(erreur = %e, "purge des photos de preuve échouée"),
        }
    }
}

/// Supprime du stockage objet une donnée personnelle que la transaction qui
/// vient d'être COMMITÉE a rendue orpheline (constitution VIII).
///
/// ⚠ À n'appeler qu'APRÈS `tx.commit()`. Un dépôt écrit toujours une clé neuve
/// et n'écrase jamais : une re-soumission de dossier, un repère vocal refait ou
/// un rejeu concurrent d'adresse laissent derrière eux des octets que plus
/// aucune ligne ne désigne. Supprimer AVANT le commit inverserait le risque —
/// un rollback ferait alors pointer une ligne vivante vers du vide.
///
/// Best-effort, exactement comme `purger_reperes_vocaux` (R8) : la base est
/// déjà juste. Un échec ici laisse un orphelin à rattraper, jamais une
/// incohérence — et ne doit surtout pas transformer en erreur une requête qui a
/// réussi.
pub(crate) async fn supprimer_objet_orphelin(depot: &PgComptes, cle: &str, quoi: &str) {
    if let Err(e) = depot.objets().supprimer(cle).await {
        tracing::warn!(
            cle = %cle,
            erreur = %e,
            "{quoi} déréférencé en base, objet non supprimé — à rattraper",
        );
    }
}

/// Démarre le serveur Actix (lie `0.0.0.0:8080`) et le worker outbox.
pub async fn run() -> std::io::Result<()> {
    // Gate UNIQUE des surfaces réservées au dev (Swagger UI, `/dev/otp`).
    // Défaut fermé, lu avant `Config::from_env` : voir `AppEnv::depuis_env`.
    let prod = socle::AppEnv::depuis_env().is_production();

    // Worker outbox + pool applicatif + ports du domaine comptes : démarrés si
    // la configuration est complète. Sans elle, le service sert `/health` seul
    // (sonde de vie, sans dépendance) ; les endpoints métier renvoient 500.
    //
    // Nuance de sécurité (cycle CPT) : une configuration ABSENTE dégrade
    // silencieusement, une configuration PRÉSENTE mais invalide (JWT_SECRET
    // trop court) échoue au démarrage — `socle::Config::from_env` la refuse.
    let mut comptes_opt: Option<PgComptes> = None;
    let mut prestataires_opt: Option<prestataires::PgPrestataires> = None;
    let mut qr_opt: Option<qr::PgQr> = None;
    let mut tarification_opt: Option<tarification::PgTarification> = None;
    let mut commandes_domaine_opt: Option<commandes::PgCommandes> = None;
    let mut dispatch_opt: Option<dispatch::PgDispatch> = None;
    let mut coursier_opt: Option<coursier::PgCoursier> = None;
    let mut traces_opt: Option<Arc<SmsTraces>> = None;
    let pool_opt = match socle::Config::from_env() {
        Ok(config) => match socle::connect_pg(&config.database_url).await {
            Ok(pool) => {
                // Migrations embarquées appliquées au démarrage (déploiement prod
                // autonome — pas de sqlx-cli dans l'image).
                if let Err(e) = sqlx::migrate!("../migrations").run(&pool).await {
                    return Err(std::io::Error::other(format!("migrations : {e}")));
                }
                eprintln!("migrations appliquées");

                let ephemere = infra_redis::RedisEphemere::nouveau(&config.redis_url)
                    .map_err(|e| std::io::Error::other(format!("Redis : {e}")))?;
                // Port PARTAGÉ entre comptes (pièces, repères vocaux) et
                // prestataires (photos, chartes) — un seul client S3.
                let objets: Arc<dyn socle::DepotObjets> = Arc::new(infra_s3::S3Objets::nouveau(
                    &config.s3_endpoint,
                    &config.s3_access_key,
                    &config.s3_secret_key,
                    &config.s3_bucket,
                    REGION_S3,
                ));
                // Le type CONCRET est retenu à côté du port : `EnvoiSms` ne sait
                // qu'envoyer, et `/dev/otp` doit RELIRE le journal. `Arc` partagé
                // — les deux poignées désignent le même journal, sinon la surface
                // dev lirait un journal toujours vide.
                let traces = match config.sms_mode {
                    // Le fournisseur réel arrive au cycle NTF, derrière ce même
                    // port (research R6) — ici le code part dans les logs.
                    socle::SmsMode::Traces => Arc::new(SmsTraces::new()),
                };
                let sms: Arc<dyn EnvoiSms> = traces.clone();
                traces_opt = Some(traces);
                eprintln!(
                    "ports comptes câblés (Redis, Garage, SMS={:?})",
                    config.sms_mode
                );
                // PgComptes EST la composition racine du domaine : pool + les
                // trois ports + le secret. Les handlers ne voient que lui.
                let depot = PgComptes::new(
                    pool.clone(),
                    Arc::new(ephemere),
                    sms,
                    objets.clone(),
                    Arc::from(config.jwt_secret.as_bytes()),
                );
                tokio::spawn(job_purge_reperes(depot.clone()));
                eprintln!("job de purge des repères vocaux démarré (quotidien)");
                // PgPrestataires — composition racine du domaine prestataires
                // (cycle 005) : réutilise le dépôt comptes (rôle vendeur au
                // rattachement, R11), le MÊME port objets, et le bouchon
                // CommandesActives — aucune commande active n'existe avant le
                // cycle CMD, donc aucun signalement coursier n'est recevable
                // (R5, exact et voulu).
                let presta = prestataires::PgPrestataires::new(
                    pool.clone(),
                    depot.clone(),
                    objets.clone(),
                    Arc::new(prestataires::AucuneCommandeActive),
                    Arc::from(config.plaque_secret.as_bytes()),
                );
                // TRF 007 — moteur de tarification. Client OSRM `/table` et
                // cache de tronçons Redis (24 h). Si OSRM n'est pas joignable au
                // DÉMARRAGE, on câble `RoutageIndisponible` : le service tarife
                // alors en dégradé vol d'oiseau × facteur de zone, journalisé —
                // il ne refuse JAMAIS un devis (constitution IV). Un OSRM qui
                // tombe en cours de route emprunte exactement le même chemin.
                let routage: Arc<dyn tarification::Routage> =
                    match tarification::RoutageOsrm::nouveau(&config.osrm_url) {
                        Ok(client) => Arc::new(client),
                        Err(e) => {
                            eprintln!("client OSRM non construit ({e}) — tarification en dégradé");
                            Arc::new(tarification::RoutageIndisponible)
                        }
                    };
                let cache_routage: Arc<dyn tarification::CacheRoutage> =
                    match infra_redis::RedisCacheRoutage::nouveau(&config.redis_url) {
                        Ok(cache) => Arc::new(cache),
                        // Un cache muet coûte un appel OSRM par course, rien de
                        // plus : jamais une raison de refuser de démarrer.
                        Err(e) => {
                            eprintln!("cache de routage indisponible ({e}) — sans cache");
                            Arc::new(tarification::CacheDesactive)
                        }
                    };
                // Les deux poignées sont RETENUES : le pipeline de dispatch les
                // réutilise pour sa matrice de proximité (research R5) — un
                // second client OSRM doublerait le cache et les connexions.
                let routage_dyn = routage.clone();
                let cache_routage_dyn = cache_routage.clone();
                let tarification = tarification::PgTarification::new(
                    pool.clone(),
                    routage,
                    cache_routage,
                );
                eprintln!("moteur de tarification câblé (OSRM {} ; cache Redis)", config.osrm_url);

                // CMD 008 — domaine commandes COMPLET, puis QRC 006 par-dessus.
                // Le dépôt commandes est câblé APRÈS la tarification : il en
                // consomme l'évaluation et l'optimisation d'arrêts pour figer
                // son devis (research R11). Les restrictions CPT-06 passent par
                // le dépôt comptes, qui satisfait le port (P3, R12) — aucune
                // requête de `commandes` n'écrit dans `comptes.compte`.
                let tarification_dyn = Arc::new(tarification.clone());
                // Position du coursier : LECTURE seule ce cycle — DSP-01
                // l'écrira. Redis coupé rend `None`, jamais une erreur : un
                // suivi doit rester lisible sans position (research R13).
                let positions: Arc<dyn commandes::PositionCoursier> = Arc::new(
                    infra_redis::RedisPositions::nouveau(&config.redis_url)
                        .map_err(|e| std::io::Error::other(format!("Redis positions : {e}")))?,
                );
                let depot_commandes = commandes::PgCommandes::new(
                    pool.clone(),
                    presta.clone(),
                    tarification_dyn.clone(),
                    tarification_dyn,
                    Arc::new(depot.clone()),
                    objets.clone(),
                    positions,
                    // Port PROVISOIRE : `PgCoursier` le remplace quelques lignes
                    // plus bas, dès qu'il existe. Les deux ne peuvent pas se
                    // construire l'un dans l'autre — `coursier` dépend de
                    // `commandes`, jamais l'inverse (constitution II).
                    Arc::new(commandes::PreuvesFixes::nouveau()),
                );
                // Le compteur d'essais du code dégradé passe par Redis
                // (éphémère, R7).
                let essais_qr: Arc<dyn qr::CompteurEssais> = Arc::new(
                    infra_redis::RedisEssais::nouveau(&config.redis_url)
                        .map_err(|e| std::io::Error::other(format!("Redis essais : {e}")))?,
                );
                qr_opt = Some(qr::PgQr::new(
                    pool.clone(),
                    depot_commandes.clone(),
                    presta.clone(),
                    objets.clone(),
                    essais_qr,
                ));
                tokio::spawn(job_purge_photos_collecte(qr_opt.clone().expect("PgQr câblé")));
                eprintln!("ports CMD et QRC câblés (PgCommandes, PgQr) ; job de purge des photos démarré");

                // CRS 010 — domaine coursier. Câblé APRÈS `qr` (dont il
                // consomme la plaque résolue) et AVANT le dispatch : aucune
                // arête entre les deux, `/moi/journee` les compose ICI.
                let depot_coursier = coursier::PgCoursier::new(
                    pool.clone(),
                    depot_commandes.clone(),
                    qr_opt.clone().expect("PgQr câblé"),
                    presta.clone(),
                    // Même client S3 que le reste : la photo de preuve suit le
                    // chemin de la photo de récupération du cycle 006.
                    objets,
                );
                // ⭐ LE branchement du cycle (T058) : le port `PreuvesEchec`,
                // conçu au cycle 008 pour être implémenté ailleurs, reçoit son
                // implémentation réelle. `PreuvesFixes` quitte la production —
                // à partir d'ici, un échec exige ses trois preuves mesurées, et
                // l'écran K4-1e lit exactement la même fonction que la garde.
                let depot_commandes =
                    depot_commandes.avec_preuves(Arc::new(depot_coursier.clone()));
                tokio::spawn(job_purge_photos_preuve(depot_coursier.clone()));
                eprintln!(
                    "domaine CRS câblé (PgCoursier ; preuves d'échec RÉELLES ; \
                     litiges AVI-04 non construits) ; job de purge des photos de preuve démarré"
                );
                // Poignée retenue pour le consommateur outbox, câblé plus bas
                // avec le worker (le dépôt lui-même part dans `web::Data`).
                let depot_coursier_pour_caisse = depot_coursier.clone();
                coursier_opt = Some(depot_coursier);

                tokio::spawn(job_expirer_substitutions(depot_commandes.clone()));
                tokio::spawn(job_purge_photos_substitution(depot_commandes.clone()));
                eprintln!("job d'expiration des substitutions démarré (toutes les 10 s)");

                // DSP 009 — pipeline de dispatch. Câblé APRÈS `commandes` (dont
                // il consomme le contrat offert) et après la tarification (dont
                // il consomme la matrice routière). Six collaborateurs, aucun
                // optionnel : une composition incomplète ne compilerait pas.
                //
                // Trois d'entre eux n'ont PAS d'implémentation réelle, et c'est
                // l'état exact du monde, pas un manque : la note (AVI), les
                // paires bloquées (CRS-07) et le transport des annonces
                // (NTF-01). C'est parce que `AnnoncesJournalisees` n'ouvre
                // aucune socket que l'app VA CHERCHER son offre (research R16).
                let pool_coursiers: Arc<dyn dispatch::PoolCoursiers> = Arc::new(
                    infra_redis::RedisPool::nouveau(&config.redis_url)
                        .map_err(|e| std::io::Error::other(format!("Redis pool : {e}")))?,
                );
                let verrous: Arc<dyn dispatch::VerrouOffre> = Arc::new(
                    infra_redis::RedisVerrouOffre::nouveau(&config.redis_url)
                        .map_err(|e| std::io::Error::other(format!("Redis verrous : {e}")))?,
                );
                let depot_dispatch = dispatch::PgDispatch::new(
                    pool.clone(),
                    Arc::new(depot_commandes.clone()),
                    Arc::new(depot.clone()),
                    pool_coursiers,
                    verrous,
                    Arc::new(infra_dispatch::ProximiteTarification::nouvelle(
                        tarification.clone(),
                        routage_dyn.clone(),
                        cache_routage_dyn.clone(),
                    )),
                    Arc::new(dispatch::NoteAbsente),
                    Arc::new(dispatch::AucunePaireBloquee),
                    Arc::new(dispatch::AnnoncesJournalisees),
                );
                eprintln!(
                    "pipeline DSP câblé (pool Redis, double verrou Lua, proximité routière ; \
                     note AVI, paires CRS-07 et transport NTF-01 non construits)"
                );
                // Le worker outbox démarre ICI, et pas plus tôt : il attendait
                // son premier consommateur réel (research R1).
                let worker = socle::WorkerOutbox::new(
                    pool.clone(),
                    vec![
                        Arc::new(DispatchOutbox {
                            depot: depot_dispatch.clone(),
                        }),
                        // CRS-06 — le SECOND consommateur réel du produit. Il
                        // alimente la caisse sans qu'aucune arête n'apparaisse
                        // entre `commandes` et `coursier` : l'outbox est
                        // précisément ce qui permet de réagir à un domaine sans
                        // en dépendre (constitution II, R9).
                        Arc::new(CaisseOutbox {
                            depot: depot_coursier_pour_caisse,
                        }),
                    ],
                );
                tokio::spawn(worker.run());
                tokio::spawn(job_tic_dispatch(depot_dispatch.clone(), pool.clone()));
                eprintln!(
                    "worker outbox démarré avec son premier consommateur (dispatch) ; \
                     tic de dispatch toutes les 5 s"
                );
                dispatch_opt = Some(depot_dispatch);

                commandes_domaine_opt = Some(depot_commandes);
                tarification_opt = Some(tarification);
                prestataires_opt = Some(presta);
                comptes_opt = Some(depot);
                Some(pool)
            }
            Err(e) => {
                eprintln!("base indisponible — worker outbox non démarré : {e}");
                None
            }
        },
        Err(e) => {
            eprintln!("configuration incomplète — worker outbox non démarré (/health seul) : {e}");
            None
        }
    };

    let addr = ("0.0.0.0", 8080);
    println!(
        "Mefali api — démarrage sur http://{}:{} (production={prod})",
        addr.0, addr.1
    );

    // Rate-limit /config par IP (research R4) : burst 30, recharge 1/100 ms.
    // Partagé entre workers (Arc interne) — un seul compteur par IP.
    let gouverneur = zones_http::config_governor(30, 100);

    HttpServer::new(move || {
        let (app, openapi) = App::new()
            .into_utoipa_app()
            .service(health::health)
            .service(zones_http::forcer_categorie)
            .service(zones_http::config)
            .service(auth_http::demander)
            .service(auth_http::verifier)
            .service(auth_http::inscrire)
            .service(auth_http::rafraichir)
            .service(auth_http::deconnexion)
            .service(auth_http::moi)
            .service(auth_http::mes_sessions)
            .service(auth_http::revoquer_session)
            .service(comptes_http::decider_role)
            // ⚠ `/admin/comptes/dossiers-coursier` AVANT
            // `/admin/comptes/{compte_id}/dossier-coursier` : Actix retient la
            // première route qui matche, et « dossiers-coursier » se lirait
            // sinon comme un `{compte_id}` — qui ne parse pas en UUID (404).
            .service(comptes_http::lister_dossiers_coursier)
            .service(comptes_http::consulter_dossier_coursier)
            .service(comptes_http::soumettre_dossier_coursier)
            .service(comptes_http::mon_dossier_coursier)
            .service(adresses_http::mes_adresses)
            .service(adresses_http::enregistrer_adresse)
            .service(adresses_http::modifier_adresse)
            .service(adresses_http::supprimer_adresse)
            .service(adresses_http::ecouter_repere_vocal)
            .service(adresses_http::remplacer_repere_vocal)
            .service(admin_prestataires_http::creer_prestataire)
        .service(admin_prestataires_http::lister_prestataires)
        .service(admin_prestataires_http::consulter_prestataire_admin)
        .service(admin_prestataires_http::modifier_prestataire)
        .service(admin_prestataires_http::ajouter_photo)
        .service(admin_prestataires_http::supprimer_photo)
        .service(admin_prestataires_http::deposer_charte)
        .service(admin_prestataires_http::definir_site)
        .service(admin_prestataires_http::agreer_prestataire)
        .service(admin_prestataires_http::rattacher_compte)
        .service(admin_prestataires_http::detacher_compte)
        .service(vendeur_http::mes_prestataires)
        .service(vendeur_http::mes_articles)
        .service(vendeur_http::creer_article)
        .service(vendeur_http::modifier_article)
        .service(vendeur_http::photo_article)
        .service(vendeur_http::retirer_article)
        .service(vendeur_http::remettre_article)
        .service(admin_prestataires_http::creer_article_admin)
        .service(admin_prestataires_http::modifier_article_admin)
        .service(admin_prestataires_http::photo_article_admin)
        .service(admin_prestataires_http::retirer_article_admin)
        .service(admin_prestataires_http::remettre_article_admin)
        .service(vendeur_http::ma_boutique)
        .service(vendeur_http::action_boutique)
        .service(vendeur_http::modifier_horaires)
        .service(admin_prestataires_http::action_boutique_admin)
        .service(admin_prestataires_http::suspendre_prestataire)
        .service(admin_prestataires_http::retablir_prestataire)
        .service(admin_prestataires_http::corriger_prestataire)
        .service(vendeur_http::basculer_disponibilite)
        .service(admin_prestataires_http::basculer_disponibilite_admin)
        .service(signalements_http::signaler_rupture)
        .service(prestataires_http::consulter_prestataire)
            .service(prestataires_http::resoudre_plaque)
            .service(qr_http::telecharger_plaque)
            .service(qr_http::collecter)
            .service(coursier_http::course_active)
            .service(coursier_http::journaliser_appel)
            .service(coursier_http::declarer_issue_appel)
            .service(coursier_http::enregistrer_presence)
            .service(coursier_http::deposer_photo_preuve)
            .service(coursier_http::etat_preuves)
            .service(coursier_http::ma_caisse)
            .service(coursier_http::ma_journee)
            .service(admin_coursier_http::remises_bloquees)
            .service(admin_coursier_http::debloquer_code)
            .service(admin_coursier_http::autoriser_depot)
            .service(admin_coursier_http::preuves_de_livraison)
            .service(admin_coursier_http::exposition_cash)
            .service(admin_coursier_http::file_indemnisations)
            .service(admin_coursier_http::valider_indemnisation)
            .service(admin_coursier_http::refuser_indemnisation)
            .service(admin_tarification_http::grille_de_zone)
            .service(admin_tarification_http::creer_brouillon)
            .service(admin_tarification_http::ecrire_regle)
            .service(admin_tarification_http::supprimer_regle)
            .service(admin_tarification_http::simuler)
            .service(admin_tarification_http::publier)
            .service(commandes_http::devis_panier)
            .service(commandes_http::creer_commande)
            .service(course_http::arret_en_route)
            .service(course_http::arret_arrive)
            .service(course_http::arret_indisponible)
            .service(course_http::declarer_rupture)
            .service(course_http::remise)
            .service(course_http::declarer_echec)
            .service(commandes_http::decider_substitution)
            .service(commandes_http::mes_commandes)
            .service(commandes_http::suivre_commande)
            .service(commandes_http::intention_appel)
            .service(commandes_http::annuler_commande)
            .service(admin_commandes_http::file_attente)
            .service(admin_commandes_http::annuler_commande_admin)
            .service(dispatch_http::basculer_disponibilite_coursier)
            .service(dispatch_http::lire_disponibilite)
            .service(dispatch_http::publier_position)
            .service(dispatch_http::offre_courante)
            .service(dispatch_http::accepter_offre)
            .service(dispatch_http::refuser_offre)
            .service(admin_dispatch_http::alertes_dispatch)
            .service(admin_dispatch_http::pool_dispatch)
            .service(admin_dispatch_http::reprendre_course_admin)
        .service(dispatch_http::offre_courante)
        .service(dispatch_http::accepter_offre)
        .service(dispatch_http::refuser_offre)
        .service(admin_dispatch_http::alertes_dispatch)
        .service(admin_dispatch_http::pool_dispatch)
        .service(admin_dispatch_http::reprendre_course_admin)
            .service(admin_commandes_http::enregistrer_issue)
            .split_for_parts();
        let mut app = app
            .configure(mount_docs(prod, openapi))
            // Corps JSON invalide → 422 ; paramètre `zone` invalide → 400 (clés i18n).
            .app_data(zones_http::config_json())
            .app_data(zones_http::config_query())
            // Rôle hors énumération dans le chemin → 404 (ressource inexistante).
            .app_data(comptes_http::config_path())
            // Corps multipart démesuré → 422 avant bufferisation (CPT-04/05).
            .app_data(comptes_http::config_multipart());
        if let Some(pool) = pool_opt.clone() {
            app = app.app_data(web::Data::new(pool));
        }
        if let Some(depot) = comptes_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = prestataires_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = qr_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = tarification_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = commandes_domaine_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = dispatch_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        if let Some(depot) = coursier_opt.clone() {
            app = app.app_data(web::Data::new(depot));
        }
        app.configure(mount_dev(prod, traces_opt.clone()))
            // Rate-limit par IP (politeness) sur toute la surface publique.
            .wrap(actix_governor::Governor::new(&gouverneur))
            // Corrélation par requête (request id) dans les logs JSON…
            .wrap(tracing_actix_web::TracingLogger::default())
            // …et capture des erreurs HTTP par Sentry (actif si SENTRY_DSN).
            .wrap(sentry_actix::Sentry::new())
    })
    .bind(addr)?
    .run()
    .await
}

/// Charge le jeu de démonstration en UNE transaction (idempotent, rollback si
/// interruption). Rejoue `backend/seeds/NN_*.sql` dans l'ordre lexicographique.
/// Renvoie le nombre de fichiers appliqués. data-model.md §3.
pub async fn charger_seeds(pool: &sqlx::PgPool) -> Result<usize, sqlx::Error> {
    let dir = std::env::var("SEED_DIR")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../seeds"));
    let mut fichiers: Vec<std::path::PathBuf> = std::fs::read_dir(&dir)
        .expect("dossier backend/seeds introuvable")
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.extension().is_some_and(|ext| ext == "sql"))
        .collect();
    fichiers.sort();

    let mut tx = pool.begin().await?;
    for fichier in &fichiers {
        let sql = std::fs::read_to_string(fichier).expect("lecture d'un fichier seed");
        // SQL issu de nos fichiers de seed commités (jamais d'entrée utilisateur).
        sqlx::raw_sql(sqlx::AssertSqlSafe(sql))
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok(fichiers.len())
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{http::StatusCode, test as atest};

    #[test]
    fn openapi_contient_health() {
        let openapi = api_openapi();
        assert_eq!(openapi.info.title, "Mefali API");
        assert!(openapi.paths.paths.contains_key("/health"));
    }

    /// Le CONTRAT n'exige pas de livraison sur une commande.
    ///
    /// La livraison est un composant 0..n du tronc (constitution II) et
    /// `SuiviCommande` la rend déjà optionnelle : l'exiger sur `Commande` était
    /// une contradiction du contrat avec lui-même. Ce test la ferme des deux
    /// côtés — la propriété reste DÉCRITE (optionnel n'est pas absent), et le
    /// reste du tronc reste obligatoire.
    #[test]
    fn le_contrat_n_exige_pas_de_livraison_sur_une_commande() {
        let spec = serde_json::to_value(api_openapi()).expect("la spec se sérialise");
        let commande = &spec["components"]["schemas"]["Commande"];
        let requis: Vec<&str> = commande["required"]
            .as_array()
            .expect("le schéma Commande porte une liste required")
            .iter()
            .map(|v| v.as_str().expect("une clé requise est textuelle"))
            .collect();

        assert!(
            !requis.contains(&"livraison"),
            "livraison ne doit plus être requise — required = {requis:?}"
        );
        assert!(
            commande["properties"].get("livraison").is_some(),
            "optionnel ne veut pas dire absent : la propriété reste décrite"
        );
        for cle in [
            "id",
            "etat",
            "montant_articles_unites",
            "total_unites",
            "devise",
            "paiement",
            "remise",
        ] {
            assert!(
                requis.contains(&cle),
                "{cle} appartient au tronc et doit rester requis"
            );
        }
    }

    #[actix_web::test]
    async fn health_repond_ok() {
        let app = atest::init_service({
            let (app, openapi) = App::new()
                .into_utoipa_app()
                .service(health::health)
                .split_for_parts();
            app.configure(mount_docs(false, openapi))
        })
        .await;

        let req = atest::TestRequest::get().uri("/health").to_request();
        let resp = atest::call_service(&app, req).await;
        assert!(resp.status().is_success());

        let body: serde_json::Value = atest::read_body_json(resp).await;
        assert_eq!(body["status"], "ok");
        assert!(body["version"].is_string());
    }

    #[actix_web::test]
    async fn swagger_presente_en_dev() {
        let app = atest::init_service({
            let (app, openapi) = App::new()
                .into_utoipa_app()
                .service(health::health)
                .split_for_parts();
            app.configure(mount_docs(false, openapi))
        })
        .await;

        let req = atest::TestRequest::get()
            .uri("/api-docs/openapi.json")
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn swagger_absente_en_production() {
        let app = atest::init_service({
            let (app, openapi) = App::new()
                .into_utoipa_app()
                .service(health::health)
                .split_for_parts();
            app.configure(mount_docs(true, openapi))
        })
        .await;

        // Swagger UI absente…
        let req = atest::TestRequest::get().uri("/swagger-ui/").to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::NOT_FOUND);

        // …mais le contrat openapi.json reste exposé.
        let req2 = atest::TestRequest::get()
            .uri("/api-docs/openapi.json")
            .to_request();
        let resp2 = atest::call_service(&app, req2).await;
        assert!(resp2.status().is_success());
    }

    /// Le garde-fou qui compte : `/dev/otp` rend un code OTP en clair à qui
    /// connaît un numéro. En production, la route ne doit pas exister.
    #[actix_web::test]
    async fn surface_dev_otp_absente_en_production() {
        let app = atest::init_service(
            App::new()
                .configure(mount_dev(true, Some(Arc::new(SmsTraces::new()))))
                .service(health::health),
        )
        .await;

        let req = atest::TestRequest::get()
            .uri("/dev/otp?telephone=%2B2250701020304&zone=00000000-0000-0000-0000-000000000000")
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_eq!(
            resp.status(),
            StatusCode::NOT_FOUND,
            "un journal PRÉSENT ne suffit pas : c'est `prod` qui décide",
        );
    }

    /// Contrôle négatif du test ci-dessus : hors production la route EXISTE
    /// bel et bien. Sans lui, `surface_dev_otp_absente_en_production` passerait
    /// même si la route avait disparu partout, y compris en dev.
    ///
    /// L'assertion porte sur « pas 404 » et rien d'autre : ce test répond à
    /// « la route est-elle montée ? », pas « que fait-elle ? ». Le handler
    /// replie toute erreur sur 400, donc le code de sortie exact ne prouverait
    /// rien de plus. Le chemin passant est joué en réel (quickstart).
    #[actix_web::test]
    async fn surface_dev_otp_montee_hors_production() {
        let depot = PgComptes::new(
            // Le pool EST touché — et c'est ce qui rend le 400 : `normaliser_e164`
            // lit l'indicatif de la ZONE avant de regarder le numéro
            // (`zones.parametre` → SELECT), et l'hôte « inutilise » ne résout pas.
            // `connect_lazy` n'ouvre rien à la construction, mais la première
            // requête, si.
            sqlx::PgPool::connect_lazy("postgres://inutilise/inutilise").unwrap(),
            Arc::new(comptes::MemoireEphemere::new()),
            Arc::new(SmsTraces::new()),
            Arc::new(comptes::MemoireObjets::new()),
            Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
        );
        let app = atest::init_service(
            App::new()
                .app_data(web::Data::new(depot))
                .configure(mount_dev(false, Some(Arc::new(SmsTraces::new())))),
        )
        .await;

        let req = atest::TestRequest::get()
            .uri("/dev/otp?telephone=%2B2250701020304&zone=00000000-0000-0000-0000-000000000000")
            .to_request();
        let resp = atest::call_service(&app, req).await;
        assert_ne!(
            resp.status(),
            StatusCode::NOT_FOUND,
            "hors production, la route doit être montée",
        );
    }

    /// T6 — seed sur base vierge puis re-seed → état identique, zéro doublon.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_idempotent(pool: sqlx::PgPool) {
        let n1 = charger_seeds(&pool).await.unwrap();
        assert!(n1 >= 1, "au moins le marqueur de démo");
        let compte1: i64 = sqlx::query_scalar("SELECT count(*) FROM demo.marqueur")
            .fetch_one(&pool)
            .await
            .unwrap();

        let n2 = charger_seeds(&pool).await.unwrap();
        let compte2: i64 = sqlx::query_scalar("SELECT count(*) FROM demo.marqueur")
            .fetch_one(&pool)
            .await
            .unwrap();

        assert_eq!(n1, n2);
        assert_eq!(compte1, 1);
        assert_eq!(compte2, 1, "re-seed → état identique, zéro doublon");
    }

    /// T009 — double seed du jeu Tiassalé → état strictement identique (SC-008).
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_zones_idempotent(pool: sqlx::PgPool) {
        type Etat = (
            i64,
            i64,
            i64,
            i64,
            i64,
            Option<serde_json::Value>,
            Option<serde_json::Value>,
        );
        async fn etat(pool: &sqlx::PgPool) -> Etat {
            async fn compter(pool: &sqlx::PgPool, sql: &'static str) -> i64 {
                sqlx::query_scalar(sql).fetch_one(pool).await.unwrap()
            }
            async fn valeur(pool: &sqlx::PgPool, cle: &str) -> Option<serde_json::Value> {
                sqlx::query_scalar("SELECT valeur FROM zones.parametre_zone WHERE cle = $1")
                    .bind(cle)
                    .fetch_optional(pool)
                    .await
                    .unwrap()
            }
            (
                compter(pool, "SELECT count(*) FROM zones.zone").await,
                compter(pool, "SELECT count(*) FROM zones.type_transport").await,
                compter(pool, "SELECT count(*) FROM zones.categorie").await,
                compter(pool, "SELECT count(*) FROM zones.activation_categorie").await,
                compter(pool, "SELECT count(*) FROM zones.parametre_zone").await,
                valeur(pool, "categorie.restauration.mixable").await,
                valeur(pool, "categorie.restauration.seuil_activation").await,
            )
        }

        charger_seeds(&pool).await.unwrap();
        let apres_un = etat(&pool).await;
        charger_seeds(&pool).await.unwrap();
        let apres_deux = etat(&pool).await;

        assert_eq!(
            apres_un, apres_deux,
            "double seed → état strictement identique"
        );
        assert_eq!(apres_un.0, 2, "CI + Tiassalé");
        assert_eq!(apres_un.1, 8, "8 types de transport");
        assert_eq!(apres_un.2, 6, "6 catégories");
        assert_eq!(apres_un.3, 6, "6 activations Tiassalé");
        // 8 (pays, cycle 002) + 4 (pays, cycle 003 : indicatif, rétention du
        // repère vocal, durée max de note vocale, version ARTCI) + 8 (pays,
        // cycle 005 : fuseau, conservation charte, 6 affichages de rupture)
        // + 3 (pays, cycle 006 : distance de scan, seuil photo, rétention photo
        // de collecte) + 13 (pays, cycle 008 : 6 « périssable » de catégorie,
        // longueur du repère écrit, essais du code, seuil d'historique, délai et
        // écart de substitution, rétention des photos, période de position)
        // + 7 (pays, cycle 009 : durée de vie du pool, compte à rebours d'offre
        // et son exclusivité, non-réponses franches, fenêtre d'acceptation,
        // valeur neutre, bruit GPS)
        // + 10 (ville, cycles 002/003) + 2 (ville, cycle 005 : seuil et fenêtre
        // du masquage automatique) + 12 (ville, cycle 007 : 2 bornes de marge,
        // arrondi, supplément pluie, 4 knobs de routage, 4 knobs d'effort —
        // `effort.plafond_eclatement_m` reste DORMANT) + 3 (ville, cycle 008 :
        // 2 plafonds cash et l'escalade d'attente coursier)
        // + 11 (ville, cycle 009 : rayon, grille d'avance, 4 poids, plafond
        // d'inactivité, 2 seuils de broadcast, 2 seuils de réassignation)
        // + 7 (pays, cycle 010 : 2 seuils d'appels de preuve, 3 seuils de
        // présence, rétention de la photo de preuve, période d'interrogation
        // d'offre en arrière-plan). SEPT et pas huit : le nombre d'essais du
        // code de remise EXISTE depuis le cycle 008 et est réutilisé tel quel —
        // deux clés pour un même seuil divergeraient au premier réglage
        // d'exploitation (research 010 R5, FR-106).
        // + 2 (ville, cycle 010 : `texte.nom_agence` et
        // `texte.telephone_agence`). DÉCOUVERTS en implémentant K4-1d : FR-043
        // exige d'afficher « le numéro de l'agence » sur l'écran de blocage, et
        // rien ne le fournissait. Ce sont des TEXTES d'affichage servis par la
        // liste blanche publique de `/config` — pas des seuils : ils ne
        // rejoignent donc pas les « sept paramètres » de research R17.
        assert_eq!(apres_un.4, 90, "50 (pays) + 40 (ville) paramètres");
        assert_eq!(
            apres_un.5,
            Some(serde_json::json!(false)),
            "restauration non mixable"
        );
        assert_eq!(
            apres_un.6,
            Some(serde_json::json!(8)),
            "seuil restauration 8"
        );
    }

    /// T016 (cycle 005) — double seed prestataires → état strictement
    /// identique (SC-012), AUCUN événement, agréés du seed prêts à être
    /// commandables (l'ouverture effective suit l'horloge — horaires
    /// 8 h — 19 h Abidjan, c'est voulu).
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_prestataires_idempotent(pool: sqlx::PgPool) {
        const TANTIE: &str = "01900000-0000-7000-8000-000000000501";
        const JETON_TANTIE: &str =
            "019000000000700080000000000005015eed5eed5eed5eed0123456789abcdef0123456789abcdef";

        async fn compter(pool: &sqlx::PgPool, sql: &'static str) -> i64 {
            sqlx::query_scalar(sql).fetch_one(pool).await.unwrap()
        }
        async fn etat(pool: &sqlx::PgPool) -> (i64, i64, i64, i64, i64, i64, i64) {
            (
                compter(pool, "SELECT count(*) FROM prestataires.prestataire").await,
                compter(pool, "SELECT count(*) FROM prestataires.vendeur").await,
                compter(pool, "SELECT count(*) FROM prestataires.site").await,
                compter(pool, "SELECT count(*) FROM prestataires.horaire_site").await,
                compter(pool, "SELECT count(*) FROM prestataires.charte_signee").await,
                compter(
                    pool,
                    "SELECT count(*) FROM prestataires.rattachement_compte",
                )
                .await,
                compter(
                    pool,
                    "SELECT count(*) FROM outbox.evenement WHERE entite_type IN \
                     ('prestataire','site','charte_signee','rattachement','article',\
                     'signalement_rupture')",
                )
                .await,
            )
        }

        charger_seeds(&pool).await.unwrap();
        let apres_un = etat(&pool).await;
        charger_seeds(&pool).await.unwrap();
        let apres_deux = etat(&pool).await;

        assert_eq!(
            apres_un, apres_deux,
            "double seed → état strictement identique"
        );
        assert_eq!(apres_un.0, 3, "Tantie Affoué, Kofi, prospect pharmacie");
        assert_eq!(apres_un.1, 3, "3 extensions vendeur");
        assert_eq!(apres_un.2, 3, "un site par prestataire (FR-019)");
        assert_eq!(apres_un.3, 18, "6 plages (lun–sam) × 3 sites");
        assert_eq!(apres_un.4, 3, "une charte par prestataire");
        assert_eq!(apres_un.5, 1, "seul le compte de Kofi est rattaché");
        assert_eq!(apres_un.6, 0, "les seeds n'émettent RIEN (FR-054)");

        // Commandabilité : agréé + catégorie POSÉE active (sans recalcul).
        let objets: std::sync::Arc<dyn socle::DepotObjets> =
            std::sync::Arc::new(socle::MemoireObjets::new());
        let depot = prestataires::PgPrestataires::new(
            pool.clone(),
            PgComptes::new(
                pool.clone(),
                std::sync::Arc::new(comptes::MemoireEphemere::new()),
                std::sync::Arc::new(SmsTraces::new()),
                objets.clone(),
                std::sync::Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
            ),
            objets.clone(),
            std::sync::Arc::new(prestataires::AucuneCommandeActive),
            std::sync::Arc::from(&b"secret-plaque-de-test-32-octets!"[..]),
        );
        let tantie: uuid::Uuid = TANTIE.parse().unwrap();
        let c = depot.commandabilite(tantie).await.unwrap();
        assert!(c.agree, "Tantie Affoué est agréée");
        assert!(c.categorie_active, "restauration posée active (FR-054)");
        let resolution = depot
            .resolution_plaque(JETON_TANTIE)
            .await
            .unwrap()
            .expect("jeton du seed résolu");
        assert!(resolution.valide);
        assert_eq!(resolution.prestataire_id, tantie);

        // Catalogues (seed 35) : 3 + 3 articles, promo de Kofi, savon en
        // rupture (grisé — servi indisponible).
        assert_eq!(
            compter(&pool, "SELECT count(*) FROM prestataires.article").await,
            6
        );
        assert_eq!(
            compter(
                &pool,
                "SELECT count(*) FROM prestataires.disponibilite_article WHERE NOT disponible",
            )
            .await,
            1
        );
        let kofi: uuid::Uuid = "01900000-0000-7000-8000-000000000502".parse().unwrap();
        // Les clés du seed sont des POINTEURS (les objets ne sont pas dans
        // Garage) ; le double mémoire, plus strict que S3, refuse de présigner
        // une clé absente — on dépose donc l'octet correspondant.
        objets
            .deposer(
                &format!("prestataires/fiches/{kofi}/seed-1"),
                vec![0xFF],
                "image/jpeg",
            )
            .await
            .unwrap();
        let fiche = depot
            .fiche_publique_de(kofi)
            .await
            .unwrap()
            .expect("fiche de Kofi servie");
        let alloco = fiche
            .articles
            .iter()
            .find(|a| a.nom == "Alloco")
            .expect("promo au catalogue");
        assert_eq!((alloco.prix_unites, alloco.prix_barre_unites), (800, Some(1000)));
        let savon = fiche
            .articles
            .iter()
            .find(|a| a.nom == "Savon de Marseille")
            .expect("rupture servie GRISÉE (mode seed)");
        assert!(!savon.disponible);
    }

    /// T009 — double seed du module comptes → état strictement identique
    /// (SC-008), et le premier admin est bien amorcé hors parcours applicatif.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_comptes_idempotent(pool: sqlx::PgPool) {
        const ADMIN: &str = "01900000-0000-7000-8000-000000000401";

        /// Comptes, attributions, et les colonnes qu'un `now()` mal placé dans
        /// le seed ferait dériver à chaque exécution.
        type Etat = (i64, i64, String, chrono::DateTime<chrono::Utc>);
        async fn etat(pool: &sqlx::PgPool) -> Etat {
            let comptes: i64 = sqlx::query_scalar("SELECT count(*) FROM comptes.compte")
                .fetch_one(pool)
                .await
                .unwrap();
            let attributions: i64 =
                sqlx::query_scalar("SELECT count(*) FROM comptes.attribution_role")
                    .fetch_one(pool)
                    .await
                    .unwrap();
            let (telephone, consentement_le): (String, chrono::DateTime<chrono::Utc>) =
                sqlx::query_as("SELECT telephone_e164, consentement_le FROM comptes.compte WHERE id = $1::uuid")
                    .bind(ADMIN)
                    .fetch_one(pool)
                    .await
                    .unwrap();
            (comptes, attributions, telephone, consentement_le)
        }

        charger_seeds(&pool).await.unwrap();
        let apres_un = etat(&pool).await;
        charger_seeds(&pool).await.unwrap();
        let apres_deux = etat(&pool).await;

        assert_eq!(
            apres_un, apres_deux,
            "double seed → état strictement identique (horodatages figés compris)"
        );
        // 2 comptes : le premier admin (seed 20) + Kofi (seed 30, cycle 005).
        assert_eq!(apres_un.0, 2, "premier admin + Kofi (vendeur seedé)");
        // 4 rôles : client + admin (admin), client + vendeur (Kofi).
        assert_eq!(apres_un.1, 4, "client+admin (401) et client+vendeur (402)");

        // FR-012 — c'est le seed, et lui seul, qui amorce la chaîne des admins.
        // Colonne QUALIFIÉE : tri par l'énum (client, coursier, vendeur, admin)
        // et non par le texte de la colonne de sortie — cf. depot.rs.
        let roles: Vec<String> = sqlx::query_scalar(
            "SELECT role::text FROM comptes.attribution_role
             WHERE compte_id = $1::uuid AND statut = 'valide'
             ORDER BY attribution_role.role",
        )
        .bind(ADMIN)
        .fetch_all(&pool)
        .await
        .unwrap();
        assert_eq!(
            roles,
            vec!["client", "admin"],
            "les deux rôles sont VALIDES"
        );

        // Aucun événement outbox : un chargement n'est pas une transition.
        let evenements: i64 = sqlx::query_scalar(
            "SELECT count(*) FROM outbox.evenement WHERE type_evenement LIKE 'compte.%'
                OR type_evenement LIKE 'role.%'",
        )
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(evenements, 0, "le seed n'émet aucun événement");
    }

    /// FR-024 — les paramètres du module sont posés au PAYS et hérités par
    /// Tiassalé : rien de tout cela n'a le droit d'être en dur dans le code.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_comptes_parametres_herites_par_tiassale(pool: sqlx::PgPool) {
        use zones::ConfigurationZones;
        charger_seeds(&pool).await.unwrap();

        let tiassale: uuid::Uuid = "01900000-0000-7000-8000-000000000002".parse().unwrap();
        let depot = zones::PgZones::new(pool.clone());

        for (cle, attendu) in [
            ("telephone.indicatif_defaut", serde_json::json!("+225")),
            (
                "adresse.retention_repere_vocal_jours",
                serde_json::json!(365),
            ),
            ("medias.note_vocale_duree_max_s", serde_json::json!(30)),
            ("consentement.artci_version", serde_json::json!("2026-07")),
        ] {
            assert_eq!(
                depot.parametre(tiassale, cle).await.unwrap(),
                Some(attendu),
                "« {cle} » doit être résolu à Tiassalé par héritage du pays"
            );
        }
    }

    /// Le numéro du premier admin doit être RÉELLEMENT utilisable : c'est par
    /// OTP sur ce numéro que l'admin obtient son jeton (quickstart SC-005). Un
    /// placeholder non normalisable rendrait l'admin inaccessible — sans qu'un
    /// seul test ne le signale.
    #[sqlx::test(migrations = "../migrations")]
    async fn seed_admin_a_un_numero_utilisable(pool: sqlx::PgPool) {
        charger_seeds(&pool).await.unwrap();
        let tiassale: uuid::Uuid = "01900000-0000-7000-8000-000000000002".parse().unwrap();
        let telephone: String = sqlx::query_scalar(
            "SELECT telephone_e164 FROM comptes.compte
             WHERE id = '01900000-0000-7000-8000-000000000401'::uuid",
        )
        .fetch_one(&pool)
        .await
        .unwrap();

        let normalise =
            comptes::otp::normaliser_e164(&zones::PgZones::new(pool.clone()), tiassale, &telephone)
                .await
                .expect("le numéro du premier admin doit passer la normalisation E.164");
        assert_eq!(normalise, telephone, "déjà en forme canonique");
    }
}
