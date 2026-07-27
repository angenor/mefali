//! US5 (DSP-05) — quand la cascade s'essouffle, demander à tout le monde.
//!
//! Trois attentes de 40 s deviennent une seule course. Ce que ces tests
//! protègent : le broadcast ne doit ni doubler les écrans d'un coursier, ni
//! arrêter la recherche quand personne ne prend.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::{CauseBroadcast, DecisionPipeline};
use uuid::Uuid;

/// **Candidats épuisés** — après `dispatch.broadcast_apres_candidats` offres,
/// la bascule s'ouvre.
#[sqlx::test(migrations = "../migrations")]
async fn le_broadcast_s_ouvre_apres_les_candidats(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..4 {
        bac.dans_le_pool(i, 15_000).await;
    }
    let commande = bac.commande_prete().await;

    // Trois cascades refusées d'affilée.
    for _ in 0..3 {
        let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
            panic!("une cascade devait partir");
        };
        assert_eq!(offre.mode.comme_str(), "cascade");
        bac.dispatch
            .refuser_offre(offre.id, offre.coursier, Uuid::now_v7(), chrono::Utc::now())
            .await
            .unwrap();
    }

    let decision = bac.dispatcher(commande).await;
    let DecisionPipeline::BroadcastOuvert {
        nb_destinataires,
        cause,
    } = decision
    else {
        panic!("le broadcast devait s'ouvrir : {decision:?}");
    };
    assert_eq!(cause, CauseBroadcast::CandidatsEpuises);
    assert!(nb_destinataires >= 1);

    let payloads = bac.evenements("dispatch.broadcast_ouvert").await;
    assert_eq!(payloads.len(), 1);
    assert_eq!(payloads[0]["cause"], "candidats_epuises");
}

/// **Délai** — la seconde condition, ALTERNATIVE (FR-058). Elle protège le cas
/// d'un vivier trop maigre pour épuiser le compteur de candidats : sans elle,
/// une commande avec un seul coursier n'atteindrait jamais le broadcast.
#[sqlx::test(migrations = "../migrations")]
async fn le_broadcast_s_ouvre_aussi_par_le_delai(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    bac.dans_le_pool(1, 15_000).await;

    let commande = bac.commande_prete().await;
    // La commande vieillit au-delà de `broadcast_apres_s` (120 s) sans qu'aucun
    // candidat n'ait été épuisé.
    bac.vieillir_commande(commande, 200).await;

    let decision = bac.dispatcher(commande).await;
    let DecisionPipeline::BroadcastOuvert { cause, .. } = decision else {
        panic!("le broadcast devait s'ouvrir par le délai : {decision:?}");
    };
    assert_eq!(cause, CauseBroadcast::Delai);
}

/// **Premier accepteur** — les autres reçoivent « déjà prise », sans pénalité,
/// et restent dans le pool.
#[sqlx::test(migrations = "../migrations")]
async fn en_broadcast_le_premier_accepteur_gagne(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..3 {
        bac.dans_le_pool(i, 15_000).await;
    }
    let commande = bac.commande_prete().await;
    bac.vieillir_commande(commande, 200).await;

    let DecisionPipeline::BroadcastOuvert { nb_destinataires, .. } =
        bac.dispatcher(commande).await
    else {
        panic!("broadcast attendu");
    };
    assert!(nb_destinataires >= 2, "plusieurs coursiers ont un écran");

    // Le premier accepte ; les autres se voient refuser, sans pénalité.
    let offres: Vec<(Uuid, Uuid)> = sqlx::query_as(
        "SELECT id, coursier_id FROM dispatch.offre
         WHERE commande_id = $1 AND issue = 'en_vol' ORDER BY emise_le",
    )
    .bind(commande)
    .fetch_all(&bac.cmd.pool)
    .await
    .unwrap();

    let (premiere, gagnant) = offres[0];
    bac.dispatch
        .accepter_offre(premiere, gagnant, Uuid::now_v7(), chrono::Utc::now())
        .await
        .expect("le premier accepteur gagne");

    for (offre, perdant) in offres.iter().skip(1) {
        let e = bac
            .dispatch
            .accepter_offre(*offre, *perdant, Uuid::now_v7(), chrono::Utc::now())
            .await
            .expect_err("la course est prise");
        assert_eq!(e.message_cle(), Some("deja_prise"));
    }
    assert_eq!(bac.nb_evenements("dispatch.offre_refusee").await, 0);
    assert_eq!(bac.nb_evenements("commande.assignee").await, 1);
}

/// **FR-062 — deux broadcasts concurrents se SÉRIALISENT.** Le verrou de
/// coursier s'applique à chaque destinataire : personne ne voit deux écrans.
#[sqlx::test(migrations = "../migrations")]
async fn deux_broadcasts_concurrents_se_serialisent(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..3 {
        bac.dans_le_pool(i, 15_000).await;
    }
    let une = bac.commande_prete().await;
    let deux = bac.commande_prete().await;
    bac.vieillir_commande(une, 200).await;
    bac.vieillir_commande(deux, 200).await;

    let d1 = bac.dispatcher(une).await;
    let d2 = bac.dispatcher(deux).await;

    assert!(matches!(d1, DecisionPipeline::BroadcastOuvert { .. }));
    // Le second broadcast n'atteint personne : tous les coursiers portent déjà
    // un écran du premier.
    if let DecisionPipeline::BroadcastOuvert { nb_destinataires, .. } = d2 {
        assert_eq!(
            nb_destinataires, 0,
            "aucun coursier ne doit voir deux écrans à la fois (FR-062)",
        );
    }

    let doublons: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
             SELECT coursier_id FROM dispatch.offre WHERE issue = 'en_vol'
             GROUP BY 1 HAVING count(*) > 1) t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(doublons, 0);
}

/// Un coursier devenu **occupé** entre le début du pipeline et l'émission ne
/// reçoit pas d'écran : l'éligibilité est réévaluée à l'émission.
#[sqlx::test(migrations = "../migrations")]
async fn un_coursier_devenu_occupe_ne_recoit_pas_de_broadcast(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..3 {
        bac.dans_le_pool(i, 15_000).await;
    }
    // Le coursier 0 part sur une autre course.
    let occupante = bac.commande_prete().await;
    bac.cmd
        .commandes
        .assigner_coursier(occupante, bac.coursiers[0].id, chrono::Utc::now())
        .await
        .unwrap();

    let commande = bac.commande_prete().await;
    bac.vieillir_commande(commande, 200).await;
    bac.dispatcher(commande).await;

    let destinataires: Vec<Uuid> =
        sqlx::query_scalar("SELECT coursier_id FROM dispatch.offre WHERE commande_id = $1")
            .bind(commande)
            .fetch_all(&bac.cmd.pool)
            .await
            .unwrap();
    assert!(!destinataires.contains(&bac.coursiers[0].id));
}

/// Un broadcast **sans preneur** n'arrête pas le pipeline : la commande reste
/// dispatchable, et l'escalade continue de courir.
#[sqlx::test(migrations = "../migrations")]
async fn un_broadcast_sans_preneur_n_arrete_pas_la_recherche(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    // Au-delà du seuil d'escalade de la zone (300 s), pas seulement du seuil de
    // broadcast (120 s) : ce sont deux paramètres distincts.
    bac.vieillir_commande(commande, 400).await;

    bac.dispatcher(commande).await;
    // Personne n'accepte : les offres expirent.
    let offres: Vec<Uuid> = sqlx::query_scalar(
        "SELECT id FROM dispatch.offre WHERE commande_id = $1 AND issue = 'en_vol'",
    )
    .bind(commande)
    .fetch_all(&bac.cmd.pool)
    .await
    .unwrap();
    for offre in offres {
        bac.faire_expirer_offre(offre).await;
    }
    bac.tic().await;

    assert_ne!(
        bac.cmd.etat_commande(commande).await,
        "annulee",
        "un broadcast sans preneur ne perd pas la commande",
    );
    assert!(
        bac.nb_evenements("commande.attente_coursier_escaladee").await >= 1,
        "le compte d'escalade continue de courir",
    );
}
