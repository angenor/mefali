//! US4 (TRF-05) — grille de départ Tiassalé, vérifiée au FCFA près (SC-006).
//!
//! Le seed n'est pas un décor : c'est ce que paieront les premiers clients de
//! Tiassalé. Chaque montant du cadrage est donc contrôlé ici sur le VRAI fichier
//! `backend/seeds/50_tarification_tiassale.sql`, pas sur une grille de test.

mod bac;

use std::sync::Arc;

use bac::{charger_seeds, instant, point_a, RoutageFixe, SEEDS_TARIFICATION, TIASSALE};
use serde_json::{json, Value};
use sqlx::PgPool;
use tarification::{CacheMemoire, DemandeDevis, EvaluationTarifaire, PgTarification, SourceGrille};
use uuid::Uuid;

/// Ville de Tiassalé telle que seedée.
fn tiassale() -> Uuid {
    TIASSALE.parse().unwrap()
}

/// Course d'un retrait à `distance_m` du client, en `transport`.
fn course(transport: &str) -> DemandeDevis {
    DemandeDevis {
        zone_id: tiassale(),
        transport_slug: transport.to_owned(),
        retraits: vec![point_a(1_000.0)],
        client: point_a(0.0),
        nb_articles: 1,
        instant: instant("2026-07-24T12:00:00Z"),
        categorie_slug: None,
        attentes: Vec::new(),
        montant_panier: 0,
        offre_livraison_vendeur: None,
        mono_vendeur: false,
    }
}

/// Moteur dont le routage rend EXACTEMENT `distance_m` entre le retrait et le
/// client — c'est ce qui rend les montants vérifiables au FCFA près.
fn moteur(pool: &PgPool, distance_m: i64) -> PgTarification {
    PgTarification::new(
        pool.clone(),
        Arc::new(RoutageFixe::depuis_positions(&[distance_m, 0])),
        Arc::new(CacheMemoire::nouveau()),
    )
}

/// Éteint les drapeaux de lancement pour ISOLER la grille (quickstart SC-006).
async fn eteindre_drapeaux(pool: &PgPool) {
    sqlx::query(
        "UPDATE zones.parametre_zone SET valeur = 'false'
         WHERE cle IN ('drapeau.livraison_offerte_mefali', 'drapeau.gratuite_commissions')",
    )
    .execute(pool)
    .await
    .unwrap();
}

/// SC-006 (1) — chaque montant du cadrage, au FCFA près, drapeaux éteints.
#[sqlx::test(migrations = "../../migrations")]
async fn montants_tiassale_au_fcfa_pres(pool: PgPool) {
    charger_seeds(&pool, SEEDS_TARIFICATION).await;
    eteindre_drapeaux(&pool).await;

    // À pied : 100 jusqu'à 800 m inclus.
    let devis = moteur(&pool, 600)
        .evaluer(course("a_pied"), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 100, "à pied, 600 m");
    assert_eq!(devis.part_coursier, 50);
    assert_eq!(devis.marge, 50);
    assert_eq!(devis.devise, "XOF");

    // Vélo : 150 jusqu'à 2 km inclus.
    let devis = moteur(&pool, 1_500)
        .evaluer(course("velo"), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 150, "vélo, 1,5 km");
    assert_eq!(devis.part_coursier, 100);

    // Moto : 200 + 50 × (4 − 2) = 300.
    let devis = moteur(&pool, 4_000)
        .evaluer(course("moto"), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 300, "moto, 4 km");
    assert_eq!(devis.part_coursier, 250);
    assert_eq!(devis.marge, 50);

    // Moto 20 km : 200 + 50 × 18 = 1 100, PLAFONNÉ à 500.
    let devis = moteur(&pool, 20_000)
        .evaluer(course("moto"), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 500, "plafond moto");
    assert_eq!(
        devis.part_coursier, 450,
        "le coursier garde tout sauf la marge"
    );

    // Pluie : +100 (drapeau de zone, OFF par défaut au seed).
    sqlx::query("UPDATE zones.parametre_zone SET valeur = 'true' WHERE cle = 'drapeau.pluie'")
        .execute(&pool)
        .await
        .unwrap();
    let devis = moteur(&pool, 4_000)
        .evaluer(course("moto"), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 400, "moto 4 km sous la pluie");
    assert_eq!(devis.composantes.supplements, 100);
    assert_eq!(devis.marge, 50, "la pluie n'enrichit pas la marge");
}

/// SC-006 (2) — drapeaux de lancement ON : prix client 0, marge 0, part
/// coursier CALCULÉE et journalisée (elle sera payée au fixe hors moteur).
#[sqlx::test(migrations = "../../migrations")]
async fn drapeaux_de_lancement_du_seed(pool: PgPool) {
    charger_seeds(&pool, SEEDS_TARIFICATION).await;

    // Le seed 10 pose déjà les deux drapeaux à `true` pour Tiassalé : c'est
    // l'état RÉEL du lancement, on ne le fabrique pas.
    for cle in [
        "drapeau.livraison_offerte_mefali",
        "drapeau.gratuite_commissions",
    ] {
        let valeur: Value =
            sqlx::query_scalar("SELECT valeur FROM zones.parametre_zone WHERE cle = $1")
                .bind(cle)
                .fetch_one(&pool)
                .await
                .unwrap();
        assert_eq!(valeur, json!(true), "{cle} est ON au lancement");
    }

    let devis = moteur(&pool, 4_000)
        .evaluer(course("moto"), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 0, "livraison offerte");
    assert_eq!(devis.marge, 0, "gratuité des commissions");
    assert_eq!(
        devis.part_coursier, 250,
        "part coursier CALCULÉE quand même"
    );
    assert_eq!(
        devis.invariant_verifie(),
        None,
        "invariant non applicable sur un prix forcé à 0"
    );
}

/// SC-006 (3) / FR-027 — rejouer le seed converge vers le MÊME état : aucune
/// règle dupliquée, aucun montant qui dérive, aucun événement.
#[sqlx::test(migrations = "../../migrations")]
async fn seed_idempotent(pool: PgPool) {
    type Etat = (i64, i64, i64, Option<i64>, Option<Value>);
    async fn etat(pool: &PgPool) -> Etat {
        let compter = |sql: &'static str| async move {
            sqlx::query_scalar::<_, i64>(sql)
                .fetch_one(pool)
                .await
                .unwrap()
        };
        (
            compter("SELECT count(*) FROM tarification.grille").await,
            compter("SELECT count(*) FROM tarification.regle").await,
            compter("SELECT count(*) FROM outbox.evenement").await,
            sqlx::query_scalar(
                "SELECT marge FROM tarification.regle WHERE transport_slug = 'moto'",
            )
            .fetch_optional(pool)
            .await
            .unwrap(),
            sqlx::query_scalar(
                "SELECT valeur FROM zones.parametre_zone WHERE cle = 'effort.paliers_articles'",
            )
            .fetch_optional(pool)
            .await
            .unwrap(),
        )
    }

    charger_seeds(&pool, SEEDS_TARIFICATION).await;
    let apres_un = etat(&pool).await;
    charger_seeds(&pool, SEEDS_TARIFICATION).await;
    let apres_deux = etat(&pool).await;

    assert_eq!(apres_un, apres_deux, "double seed → état identique");
    assert_eq!(apres_un.0, 1, "une seule grille");
    assert_eq!(apres_un.1, 3, "à pied, vélo, moto");
    assert_eq!(apres_un.2, 0, "un chargement n'est pas une transition");
    assert_eq!(apres_un.3, Some(50), "marge régulière 50, dans les bornes");
}

/// Les knobs du seed sont bien HÉRITÉS et lus par le moteur : aucun de ces
/// nombres n'a le droit d'être en dur dans le code (constitution I).
#[sqlx::test(migrations = "../../migrations")]
async fn knobs_seedes_et_herites(pool: PgPool) {
    charger_seeds(&pool, SEEDS_TARIFICATION).await;
    let moteur = moteur(&pool, 4_000);

    let knobs = moteur.knobs(tiassale()).await.unwrap();
    assert_eq!(knobs.devise.code, "XOF");
    assert_eq!(knobs.devise.decimales, 0, "hérité du PAYS");
    assert_eq!(knobs.bornes_marge.min, 25);
    assert_eq!(knobs.bornes_marge.max, 100);
    assert_eq!(knobs.arrondi_pas, 25);
    assert_eq!(knobs.supplement_pluie, 100);
    assert_eq!(knobs.facteur_degrade, 1.4);
    assert_eq!(knobs.cache.ttl_s, 24 * 3_600);
    assert_eq!(knobs.cache.decimales, 4);
    assert_eq!(knobs.fuseau, chrono_tz::Africa::Abidjan, "hérité du PAYS");
    assert_eq!(
        knobs.plafond_eclatement_m, None,
        "plafond d'éclatement DORMANT : à calibrer en promo (Annexe B)"
    );
}

/// La grille seedée est bien celle qui TARIFE : état en vigueur, effet passé,
/// et une seule par zone (index unique partiel).
#[sqlx::test(migrations = "../../migrations")]
async fn grille_seedee_en_vigueur(pool: PgPool) {
    charger_seeds(&pool, SEEDS_TARIFICATION).await;
    let moteur = moteur(&pool, 1_000);

    let grille = moteur
        .grille_en_vigueur(tiassale())
        .await
        .unwrap()
        .expect("Tiassalé tarife dès le premier jour");
    assert_eq!(grille.version, 1);
    assert!(grille.effet_le.is_some());
    assert_eq!(grille.regles.len(), 3);
    assert!(
        grille.regles.iter().all(|r| r.devise == "XOF" && r.actif),
        "toutes les règles sont actives et en XOF"
    );
    assert!(
        grille.regles.iter().all(|r| r.point_relais_id.is_none()),
        "la provision point relais reste vide"
    );
    assert!(moteur.brouillon(tiassale()).await.unwrap().is_none());
}
