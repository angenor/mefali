//! US6 (TRF-06) — grille d'effort et optimisation d'ordre, de bout en bout.
//!
//! Couvre SC-007 (100 % coursier), SC-008 (le marché), SC-009 (ordre optimisé
//! exposé) et SC-010 (promo : effort journalisé NON facturé). Le fil rouge :
//! **l'effort abonde la part coursier, jamais la marge**, et il est calculé sur
//! les tronçons ROUTIERS de l'itinéraire optimisé — jamais sur un vol d'oiseau.

mod bac;

use std::sync::Arc;

use bac::{instant, point_a, Bac, RoutageFixe};
use chrono::Duration;
use serde_json::json;
use sqlx::PgPool;
use tarification::{
    Attente, CacheMemoire, DemandeDevis, EvaluationTarifaire, OptimisationArrets, SourceGrille,
};

/// Pose les barèmes d'effort du seed Tiassalé sur la zone du bac.
async fn barèmes_effort(bac: &Bac) {
    bac.poser_parametre(
        "effort.paliers_articles",
        json!([[6, 10, 50], [11, 20, 100], [21, null, 150]]),
    )
    .await;
    bac.poser_parametre(
        "effort.prime_attente",
        json!({"seuil_min": 15, "montant": 100, "par": "course"}),
    )
    .await;
    bac.poser_parametre(
        "effort.supplement_arret_m",
        json!([[0, 100, 25], [100, 1000, 50], [1000, null, 100]]),
    )
    .await;
}

/// Attente de `minutes` à un arrêt.
fn attente(minutes: i64) -> Attente {
    let arrivee = instant("2026-07-22T12:00:00Z");
    Attente {
        arrivee,
        scan: arrivee + Duration::minutes(minutes),
    }
}

/// SC-008 — marché : 12 articles chez 3 étals voisins = 2 × 25 + 100, et la
/// composante déplacement reste sur les km RÉELS.
#[sqlx::test(migrations = "../../migrations")]
async fn marche_douze_articles_trois_etals_voisins(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    barèmes_effort(&bac).await;

    // 3 étals à 40 et 80 m l'un de l'autre, client à 500 m du dernier.
    // Positions : 540, 580, 620 ; client à 40 → ordre optimal 620→580→540→40,
    // jambes 40, 40 puis 500 vers le client. Distance totale : 580 m.
    let routage = Arc::new(RoutageFixe::depuis_positions(&[540, 580, 620, 40]));
    let moteur = bac.moteur(routage, Arc::new(CacheMemoire::nouveau()));

    let mut demande = bac.demande("moto", 3);
    demande.nb_articles = 12;
    demande.retraits = vec![point_a(540.0), point_a(580.0), point_a(620.0)];
    demande.client = point_a(40.0);

    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();

    let c = devis.composantes;
    assert_eq!(
        c.effort_arrets, 50,
        "2 arrêts supplémentaires × 25 (< 100 m)"
    );
    assert_eq!(c.effort_paliers, 100, "palier 11–20 articles");
    assert_eq!(c.effort_attente, 0, "aucune attente tracée");
    assert_eq!(c.effort_total(), 150);
    // Déplacement sur les km RÉELS : 580 m < seuil 2 km → aucun kilométrage.
    assert_eq!(devis.distance_m, 580);
    assert_eq!(
        c.km, 0,
        "le supplément d'arrêt ne remplace jamais la distance"
    );
    assert_eq!(c.base, 200);
    // 200 + 150 = 350, déjà multiple de 25.
    assert_eq!(devis.prix_client, 350);
    assert_eq!(devis.marge, 50, "la marge est INCHANGÉE par l'effort");
    assert_eq!(devis.part_coursier, 300, "150 de base + 150 d'effort");
}

/// SC-007 — 100 % de l'effort au coursier : à effort près, seule la part
/// coursier bouge.
#[sqlx::test(migrations = "../../migrations")]
async fn effort_integralement_au_coursier(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[600, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    let mut sans_effort = bac.demande("moto", 1);
    sans_effort.nb_articles = 3;
    let avant = moteur
        .evaluer(sans_effort, SourceGrille::EnVigueur)
        .await
        .unwrap();

    barèmes_effort(&bac).await;
    let mut avec_effort = bac.demande("moto", 1);
    avec_effort.nb_articles = 25; // palier 21+ → 150
    let apres = moteur
        .evaluer(avec_effort, SourceGrille::EnVigueur)
        .await
        .unwrap();

    assert_eq!(apres.composantes.effort_paliers, 150);
    assert_eq!(apres.marge, avant.marge, "la marge ne bouge PAS");
    assert_eq!(
        apres.part_coursier - avant.part_coursier,
        150,
        "tout l'effort va au coursier"
    );
    assert_eq!(apres.prix_client - avant.prix_client, 150);
    assert_eq!(apres.invariant_verifie(), Some(true));
}

/// Clarification 2026-07-24 — la prime d'attente tombe UNE SEULE FOIS par
/// course, même avec deux arrêts lents.
#[sqlx::test(migrations = "../../migrations")]
async fn prime_attente_une_fois_par_course(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    barèmes_effort(&bac).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[300, 600, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    let course_avec = |attentes: Vec<Attente>| DemandeDevis {
        attentes,
        ..bac.demande("moto", 2)
    };

    let sans = moteur
        .evaluer(course_avec(vec![]), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(sans.composantes.effort_attente, 0);

    let un_lent = moteur
        .evaluer(course_avec(vec![attente(20)]), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(un_lent.composantes.effort_attente, 100);

    let deux_lents = moteur
        .evaluer(
            course_avec(vec![attente(20), attente(45)]),
            SourceGrille::EnVigueur,
        )
        .await
        .unwrap();
    assert_eq!(
        deux_lents.composantes.effort_attente, 100,
        "+100 au total, surtout pas 2 × 100"
    );
    assert_eq!(deux_lents.prix_client, un_lent.prix_client);
}

/// SC-010 — pendant la promo, l'effort est CALCULÉ, JOURNALISÉ, mais NON
/// facturé ; à la bascule il devient facturé sans changement de code.
#[sqlx::test(migrations = "../../migrations")]
async fn promo_effort_journalise_non_facture(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    barèmes_effort(&bac).await;
    bac.poser_drapeau("livraison_offerte_mefali", true).await;

    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[600, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let mut demande = bac.demande("moto", 1);
    demande.nb_articles = 12;

    let devis = moteur
        .evaluer(demande.clone(), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 0, "livraison offerte");
    assert_eq!(devis.composantes.effort_paliers, 100, "effort CALCULÉ");
    assert_eq!(devis.part_coursier, 250, "et dû au coursier : 150 + 100");

    let evenements = bac.evenements("effort.calcule").await;
    assert_eq!(evenements.len(), 1, "effort journalisé");
    let payload = &evenements[0];
    assert_eq!(payload["facture"], json!(false), "NON facturé");
    assert_eq!(payload["montant_effort"], json!(100));
    assert_eq!(payload["paliers"], json!(100));
    assert_eq!(payload["nb_articles"], json!(12));
    assert_eq!(payload["devise"], json!("XOF"));
    // Minimisation ARTCI : aucune coordonnée dans le journal.
    let texte = payload.to_string();
    assert!(!texte.contains("lat") && !texte.contains("lon"));

    // Bascule : drapeau OFF → le MÊME effort est facturé, sans une ligne de
    // code changée (c'est un paramètre de zone).
    bac.poser_drapeau("livraison_offerte_mefali", false).await;
    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(
        devis.prix_client, 300,
        "200 de base + 100 d'effort, facturés"
    );
    assert_eq!(devis.part_coursier, 250, "part coursier identique");
    assert_eq!(
        bac.evenements("effort.calcule").await.len(),
        1,
        "un effort FACTURÉ ne se journalise pas ici — il vivra au paiement"
    );
}

/// SC-009 — l'ordre exposé à DSP/CMD est le meilleur, déterministe, et l'effort
/// se calcule sur les tronçons de CET ordre.
#[sqlx::test(migrations = "../../migrations")]
async fn ordre_optimise_nourrit_l_effort(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    barèmes_effort(&bac).await;

    // Retraits à 2 000, 100 et 1 050 m ; client à 0. Le meilleur ordre descend :
    // 2000 → 1050 → 100 → 0. Jambes entre arrêts : 950 m (→ 50) et 950 m (→ 50).
    let retraits = [point_a(2_000.0), point_a(100.0), point_a(1_050.0)];
    let routage = Arc::new(RoutageFixe::depuis_positions(&[2_000, 100, 1_050, 0]));
    let moteur = bac.moteur(routage, Arc::new(CacheMemoire::nouveau()));

    let itineraire = moteur
        .optimiser(bac.ville, &retraits, point_a(0.0))
        .await
        .unwrap();
    assert_eq!(
        itineraire.ordre,
        vec![0, 2, 1],
        "du plus loin au plus proche"
    );
    assert_eq!(itineraire.distance_m, 2_000);
    assert!(itineraire.exhaustif);
    assert_eq!(
        itineraire.troncons_entre_arrets().len(),
        2,
        "3 retraits ⇒ 2 arrêts supplémentaires"
    );

    let mut demande = bac.demande("moto", 3);
    demande.retraits = retraits.to_vec();
    demande.client = point_a(0.0);
    demande.nb_articles = 2;
    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.ordre, itineraire.ordre, "le devis suit CET ordre");
    assert_eq!(
        devis.composantes.effort_arrets, 100,
        "2 × 50 (jambes de 950 m, tranche 100 m–1 km)"
    );
    assert_eq!(
        devis.composantes.effort_paliers, 0,
        "2 articles → aucun palier"
    );
}

/// FR-032 — au-delà du plafond d'éclatement de la zone, le devis PROPOSE une
/// scission (TRF ne scinde pas : c'est CMD qui proposera au client).
#[sqlx::test(migrations = "../../migrations")]
async fn plafond_d_eclatement_propose_la_scission(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    barèmes_effort(&bac).await;

    // Un retrait à 3 km au nord, l'autre à 2 km au sud, client au centre :
    // détour important par rapport au trajet direct.
    let retraits = [point_a(3_000.0), point_a(-2_000.0)];
    let routage = Arc::new(RoutageFixe::depuis_positions(&[3_000, -2_000, 0]));
    let moteur = bac.moteur(routage, Arc::new(CacheMemoire::nouveau()));
    let mut demande = bac.demande("moto", 2);
    demande.retraits = retraits.to_vec();
    demande.client = point_a(0.0);

    let devis = moteur
        .evaluer(demande.clone(), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert!(!devis.proposer_scission, "seuil non seedé ⇒ jamais proposé");

    bac.poser_parametre("effort.plafond_eclatement_m", json!(1_500))
        .await;
    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert!(devis.proposer_scission, "détour au-delà du plafond de zone");
}

/// Le plafond des suppléments d'arrêt borne le total (paramètre de zone).
#[sqlx::test(migrations = "../../migrations")]
async fn plafond_des_supplements_d_arret(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    barèmes_effort(&bac).await;

    // 4 retraits espacés de plus d'1 km ⇒ 3 × 100 = 300 de suppléments.
    let retraits = [
        point_a(9_000.0),
        point_a(6_000.0),
        point_a(3_000.0),
        point_a(12_000.0),
    ];
    let routage = Arc::new(RoutageFixe::depuis_positions(&[
        9_000, 6_000, 3_000, 12_000, 0,
    ]));
    let moteur = bac.moteur(routage, Arc::new(CacheMemoire::nouveau()));
    let mut demande = bac.demande("moto", 4);
    demande.retraits = retraits.to_vec();
    demande.client = point_a(0.0);

    let devis = moteur
        .evaluer(demande.clone(), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.composantes.effort_arrets, 300, "3 × 100");

    bac.poser_parametre("effort.plafond_supplements_arret", json!(150))
        .await;
    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.composantes.effort_arrets, 150, "total plafonné");
}

/// Sans barème d'effort en configuration de zone, l'effort vaut 0 — jamais une
/// valeur devinée (constitution I).
#[sqlx::test(migrations = "../../migrations")]
async fn sans_bareme_de_zone_aucun_effort(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[300, 600, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let mut demande = bac.demande("moto", 2);
    demande.nb_articles = 30;
    demande.attentes = vec![attente(60)];

    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.composantes.effort_total(), 0);
    assert!(bac.evenements("effort.calcule").await.is_empty());
}
