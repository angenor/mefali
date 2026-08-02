//! US2 (TRF-02) — devis figé sur itinéraire routier multi-arrêts.
//!
//! Couvre SC-002/003/004/012, les drapeaux de zone, VND-08 mono vs multi,
//! l'imputation de l'arrondi et l'ordre optimisé (SC-009, exercé dès l'MVP sans
//! attendre US6). Aucune socket : doubles de routage + géométries simulées.

mod bac;

use std::sync::Arc;

use bac::{instant, point_a, Bac, RoutageFixe};
use tarification::{
    CacheMemoire, EvaluationTarifaire, OffreLivraison, OptimisationArrets, SourceGrille,
};

use sqlx::PgPool;

/// SC-002 / SC-012 — le devis repose sur l'itinéraire à waypoints, et
/// l'invariant `prix_client = part_coursier + marge` tient.
#[sqlx::test(migrations = "../../migrations")]
async fn devis_route_et_invariant(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    // 3 retraits à 300/600/900 m du client (à 0) : l'itinéraire optimal part du
    // plus éloigné et redescend — 900→600→300→0 = 900 m.
    let routage = Arc::new(RoutageFixe::depuis_positions(&[300, 600, 900, 0]));
    let moteur = bac.moteur(routage.clone(), Arc::new(CacheMemoire::nouveau()));

    let devis = moteur
        .evaluer(bac.demande("moto", 3), SourceGrille::EnVigueur)
        .await
        .expect("un devis");

    assert_eq!(devis.distance_m, 900, "distance de l'itinéraire, pas à vol d'oiseau");
    assert!(!devis.degraded, "routage nominal → jamais marqué dégradé");
    assert_eq!(devis.devise, "XOF");
    // Moto : base 200 (150 + 50), 900 m < seuil 2 km → aucun km facturé.
    assert_eq!(devis.composantes.base, 200);
    assert_eq!(devis.composantes.km, 0);
    assert_eq!(devis.prix_client, 200);
    assert_eq!(devis.part_coursier, 150);
    assert_eq!(devis.marge, 50);
    assert_eq!(devis.invariant_verifie(), Some(true));
    assert_eq!(routage.appels(), 1, "UNE requête de matrice par course");
}

/// La composante kilométrique se calcule au-delà du seuil, et le plafond borne
/// le prix client (FR-026 : moto 200 + 50/km, plafond 500).
#[sqlx::test(migrations = "../../migrations")]
async fn kilometrage_au_dela_du_seuil_et_plafond(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // 4 km : 200 + 50 × (4 − 2) = 300.
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let devis = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 300);
    assert_eq!(devis.composantes.km, 100);
    assert_eq!(devis.part_coursier, 250, "le km abonde la PART COURSIER");
    assert_eq!(devis.marge, 50, "la marge reste fixe");
    assert_eq!(devis.invariant_verifie(), Some(true));

    // 20 km : 200 + 50 × 18 = 1100, plafonné à 500.
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[20_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let devis = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 500, "plafond du prix client");
    assert_eq!(devis.part_coursier, 450);
    assert_eq!(devis.marge, 50);
}

/// SC-004 — une course déjà routée dans la fenêtre du cache ne rappelle PAS le
/// routage.
#[sqlx::test(migrations = "../../migrations")]
async fn cache_de_routage_evite_le_second_appel(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let routage = Arc::new(RoutageFixe::depuis_positions(&[300, 600, 0]));
    let cache = Arc::new(CacheMemoire::nouveau());
    let moteur = bac.moteur(routage.clone(), cache.clone());

    let un = moteur
        .evaluer(bac.demande("moto", 2), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(routage.appels(), 1);

    let deux = moteur
        .evaluer(bac.demande("moto", 2), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(routage.appels(), 1, "2ᵉ devis servi par le cache");
    assert_eq!(un, deux, "et rigoureusement identique");

    // TTL écoulé → le routage est de nouveau interrogé.
    cache.vider();
    moteur
        .evaluer(bac.demande("moto", 2), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(routage.appels(), 2);
}

/// SC-003 — routage indisponible : le devis ABOUTIT, marqué `degraded`, en vol
/// d'oiseau × 1,4, avec l'événement `routage.degrade`. Jamais un blocage.
#[sqlx::test(migrations = "../../migrations")]
async fn degrade_aboutit_et_se_journalise(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur_degrade();

    // Un seul retrait à 3 000 m du client : 3 000 × 1,4 = 4 200 m routiers.
    let mut demande = bac.demande("moto", 1);
    demande.retraits = vec![point_a(3_000.0)];
    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .expect("le routage ne bloque JAMAIS une commande");

    assert!(devis.degraded, "devis marqué approximatif");
    assert!(
        (4_150..=4_250).contains(&devis.distance_m),
        "vol d'oiseau × 1,4 attendu, obtenu {} m",
        devis.distance_m
    );
    // ≈ 4,2 km : 200 de base + ~109 de kilométrage, arrondi au pas de 25 → 325.
    // Les bornes portent sur les RELATIONS, pas sur un mètre près : la distance
    // orthodromique exacte dépend du modèle de sphère, l'imputation non.
    assert_eq!(devis.prix_client, 325);
    assert_eq!(devis.prix_client % 25, 0, "prix client au pas de la zone");
    assert!(devis.composantes.arrondi > 0, "reliquat d'arrondi non nul");
    assert_eq!(
        devis.composantes.base + devis.composantes.km + devis.composantes.arrondi,
        devis.prix_client,
        "le prix client se décompose exactement",
    );
    assert_eq!(devis.part_coursier, 275, "le reliquat d'arrondi va au coursier");
    assert_eq!(devis.marge, 50, "la marge est INCHANGÉE par l'arrondi");
    assert_eq!(devis.invariant_verifie(), Some(true));

    let evenements = bac.evenements("routage.degrade").await;
    assert_eq!(evenements.len(), 1, "le repli est journalisé");
    let payload = &evenements[0];
    assert_eq!(payload["facteur"], serde_json::json!(1.4));
    assert_eq!(payload["transport"], serde_json::json!("moto"));
    assert_eq!(payload["nb_points"], serde_json::json!(2));
    assert!(payload["distance_m"].is_number());
    // Minimisation ARTCI : AUCUNE coordonnée brute dans le journal.
    let texte = payload.to_string();
    assert!(!texte.contains("lat"), "aucune latitude dans le payload");
    assert!(!texte.contains("lon"), "aucune longitude dans le payload");
}

/// FR-017 — drapeaux de zone : prix client 0, marge 0, part coursier CONSERVÉE
/// et journalisée.
#[sqlx::test(migrations = "../../migrations")]
async fn drapeaux_de_lancement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    // Gratuité des commissions seule : marge 0 ⇒ prix client = part coursier.
    bac.poser_drapeau("gratuite_commissions", true).await;
    let devis = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.marge, 0);
    assert_eq!(devis.part_coursier, 250);
    assert_eq!(devis.prix_client, 250, "prix client = part coursier");
    assert_eq!(devis.invariant_verifie(), Some(true));

    // Livraison offerte Mefali en plus : prix client 0, part coursier intacte.
    bac.poser_drapeau("livraison_offerte_mefali", true).await;
    let devis = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 0);
    assert_eq!(devis.marge, 0);
    assert_eq!(devis.part_coursier, 250, "le coursier ne perd jamais");
    assert_eq!(
        devis.invariant_verifie(),
        None,
        "invariant NON APPLICABLE sur un prix forcé à 0"
    );
}

/// FR-016 — la pluie est un supplément de zone, et le reliquat d'arrondi
/// abonde la part coursier.
#[sqlx::test(migrations = "../../migrations")]
async fn supplement_pluie_et_arrondi(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    let sans_pluie = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(sans_pluie.composantes.supplements, 0);

    bac.poser_drapeau("pluie", true).await;
    let avec_pluie = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(avec_pluie.composantes.supplements, 100);
    assert_eq!(avec_pluie.prix_client, sans_pluie.prix_client + 100);
    assert_eq!(
        avec_pluie.part_coursier,
        sans_pluie.part_coursier + 100,
        "le supplément abonde le coursier, pas la marge"
    );
    assert_eq!(avec_pluie.marge, sans_pluie.marge);

    // Un pas d'arrondi de 100 rend le reliquat visible et vérifiable.
    bac.poser_drapeau("pluie", false).await;
    bac.poser_parametre("tarification.arrondi_pas", serde_json::json!(100))
        .await;
    let arrondi = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(arrondi.prix_client, 300, "300 est déjà un multiple de 100");
    assert_eq!(arrondi.composantes.arrondi, 0);
}

/// FR-018 — VND-08 s'applique en MONO-vendeur seulement, et laisse la part
/// coursier intacte.
#[sqlx::test(migrations = "../../migrations")]
async fn vnd08_mono_vendeur_seulement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    let mut mono = bac.demande("moto", 1);
    mono.mono_vendeur = true;
    mono.offre_livraison_vendeur = Some(OffreLivraison::Toujours);
    let devis = moteur.evaluer(mono, SourceGrille::EnVigueur).await.unwrap();
    assert_eq!(devis.prix_client, 0, "le vendeur prend la livraison en charge");
    assert_eq!(devis.part_coursier, 250, "part coursier INCHANGÉE");
    assert_eq!(devis.composantes.retenue_vendeur, 300, "montant pris en charge");

    // Panier MULTI-vendeurs : l'offre d'un vendeur ne couvre pas la course.
    let mut multi = bac.demande("moto", 2);
    multi.mono_vendeur = false;
    multi.offre_livraison_vendeur = Some(OffreLivraison::Toujours);
    let moteur_multi = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 2_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let devis = moteur_multi
        .evaluer(multi, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert!(devis.prix_client > 0, "VND-08 ignoré en multi-vendeurs");
    assert_eq!(devis.composantes.retenue_vendeur, 0);

    // Offre à seuil : sous le seuil, elle ne joue pas.
    let mut sous_seuil = bac.demande("moto", 1);
    sous_seuil.mono_vendeur = true;
    sous_seuil.offre_livraison_vendeur = Some(OffreLivraison::AuDela(5_000));
    sous_seuil.montant_panier = 4_999;
    let devis = moteur
        .evaluer(sous_seuil, SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.prix_client, 300, "sous le seuil du vendeur");

    let mut au_seuil = bac.demande("moto", 1);
    au_seuil.mono_vendeur = true;
    au_seuil.offre_livraison_vendeur = Some(OffreLivraison::AuDela(5_000));
    au_seuil.montant_panier = 5_000;
    let devis = moteur.evaluer(au_seuil, SourceGrille::EnVigueur).await.unwrap();
    assert_eq!(devis.prix_client, 0, "au seuil, l'offre joue");
}

/// FR-047 (cycle PAY 011, T056) — **le drapeau de zone prime sur l'offre du
/// vendeur**, et il ne lui laisse rien à financer.
///
/// L'ordre du §8 (VND-08 APRÈS les drapeaux du §7) fait tout le travail : quand
/// Mefali offre déjà la livraison, `prix_client` vaut 0 avant que l'offre du
/// vendeur ne soit consultée, donc `retenue_vendeur` reste nulle. Sans ce test,
/// « le drapeau prime » resterait une propriété d'ordre des lignes, vraie par
/// accident — et un jour réordonnée.
#[sqlx::test(migrations = "../../migrations")]
async fn drapeau_de_zone_prime_sur_offre_vendeur(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    bac.poser_drapeau("livraison_offerte_mefali", true).await;
    let mut demande = bac.demande("moto", 1);
    demande.mono_vendeur = true;
    demande.offre_livraison_vendeur = Some(OffreLivraison::Toujours);

    let devis = moteur
        .evaluer(demande, SourceGrille::EnVigueur)
        .await
        .unwrap();

    assert_eq!(devis.prix_client, 0, "Mefali offre déjà la livraison");
    assert_eq!(
        devis.composantes.retenue_vendeur, 0,
        "le vendeur ne finance RIEN quand la zone a déjà tout offert"
    );
    assert_eq!(devis.part_coursier, 250, "part coursier intacte");
}

/// SC-009 — l'ordre retenu est la meilleure permutation, déterministe, et il
/// est exposé à DSP/CMD par le trait `OptimisationArrets`.
#[sqlx::test(migrations = "../../migrations")]
async fn ordre_optimise_expose_et_deterministe(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Retraits à 300, 900, 600 m ; client à 0. Le meilleur ordre visite le plus
    // éloigné d'abord : 900 → 600 → 300 → client = 900 m (contre 1 500 m dans
    // l'ordre soumis).
    let routage = Arc::new(RoutageFixe::depuis_positions(&[300, 900, 600, 0]));
    let moteur = bac.moteur(routage, Arc::new(CacheMemoire::nouveau()));

    let devis = moteur
        .evaluer(bac.demande("moto", 3), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.ordre, vec![1, 2, 0], "meilleure permutation");
    assert_eq!(devis.distance_m, 900);

    // Même résultat par le trait exposé aux cycles suivants.
    let retraits = [point_a(300.0), point_a(900.0), point_a(600.0)];
    let itineraire = moteur
        .optimiser(bac.ville, &retraits, point_a(0.0))
        .await
        .unwrap();
    assert_eq!(itineraire.ordre, vec![1, 2, 0]);
    assert_eq!(itineraire.distance_m, 900);
    assert!(itineraire.exhaustif, "3 retraits → exhaustif");
    assert_eq!(itineraire.troncons.len(), 3);

    // Rejouable à l'identique.
    let bis = moteur
        .optimiser(bac.ville, &retraits, point_a(0.0))
        .await
        .unwrap();
    assert_eq!(itineraire, bis);
}

/// FR-032 — le plafond d'éclatement est DORMANT par défaut ; posé, il fait
/// PROPOSER une scission (TRF ne scinde pas).
#[sqlx::test(migrations = "../../migrations")]
async fn plafond_d_eclatement_dormant_par_defaut(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Retraits à 5 000 et 1 000 m, client à 0 : trajet 5 000 → 1 000 → 0 =
    // 5 000 m ; direct 5 000 → 0 = 5 000 m ; détour = 0. Prenons plutôt un
    // retrait AU-DELÀ du client pour créer un vrai détour.
    let routage = Arc::new(RoutageFixe::depuis_positions(&[3_000, -2_000, 0]));
    let moteur = bac.moteur(routage, Arc::new(CacheMemoire::nouveau()));

    let devis = moteur
        .evaluer(bac.demande("moto", 2), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert!(
        !devis.proposer_scission,
        "sans seuil de zone, jamais de proposition de scission"
    );

    bac.poser_parametre("effort.plafond_eclatement_m", serde_json::json!(1_000))
        .await;
    let devis = moteur
        .evaluer(bac.demande("moto", 2), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert!(devis.proposer_scission, "détour au-delà du seuil de la zone");
}

/// Edge case FR-010 — aucune règle applicable : refus explicite, jamais un prix
/// arbitraire.
#[sqlx::test(migrations = "../../migrations")]
async fn aucune_regle_applicable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[1_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    // `tricycle_cargo` n'a aucune règle dans la grille.
    let erreur = moteur
        .evaluer(bac.demande("tricycle_cargo", 1), SourceGrille::EnVigueur)
        .await
        .unwrap_err();
    assert_eq!(erreur.message_cle(), Some("aucune_regle"));

    // Le vélo est borné à 2 km : au-delà, plus aucune règle vélo.
    let moteur_loin = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[5_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let erreur = moteur_loin
        .evaluer(bac.demande("velo", 1), SourceGrille::EnVigueur)
        .await
        .unwrap_err();
    assert_eq!(erreur.message_cle(), Some("aucune_regle"));
}

/// Une évaluation NOMINALE n'écrit aucun événement : pas de `devis.calcule`
/// (volume élevé, valeur métrique nulle — research R10).
#[sqlx::test(migrations = "../../migrations")]
async fn evaluation_nominale_muette(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let avant = bac.nb_evenements().await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[1_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(bac.nb_evenements().await, avant);
}

/// Une grille publiée à effet FUTUR ne tarife pas encore (FR-010).
#[sqlx::test(migrations = "../../migrations")]
async fn grille_a_effet_futur_ne_tarife_pas(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    sqlx::query("UPDATE tarification.grille SET effet_le = $1 WHERE id = $2")
        .bind(instant("2099-01-01T00:00:00Z"))
        .bind(bac.grille)
        .execute(&bac.pool)
        .await
        .unwrap();

    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[1_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let erreur = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap_err();
    assert_eq!(erreur.message_cle(), Some("aucune_grille_en_vigueur"));
}
