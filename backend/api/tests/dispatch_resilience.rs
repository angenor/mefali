//! **SC-004** — perdre le pool ne perd rien.
//!
//! Rien de métier ne vit dans l'index éphémère : les commandes, les offres et
//! leurs échéances sont en Postgres. Un vidage complet coûte au pire une offre
//! en vol, que le tic redétecte par son échéance persistée.
//!
//! Plus le **fantôme** de l'index (T067/T068) : un membre qui survit à son état
//! ne reçoit RIEN entre l'expiration et l'élagage — et ce qui est élagué est
//! **compté**, jamais silencieusement absorbé.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::{DecisionPipeline, PoolCoursiers};

/// **SC-004** — vidage complet du pool en pleine cascade.
#[sqlx::test(migrations = "../migrations")]
async fn sc004_le_vidage_du_pool_ne_perd_aucune_commande(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..3 {
        bac.dans_le_pool(i, 15_000).await;
    }

    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    // Tout l'index disparaît — l'équivalent d'un `FLUSHDB`.
    bac.pool_coursiers.vider();

    // Rien de métier n'a bougé : la commande et l'offre sont intactes.
    assert_eq!(bac.cmd.etat_commande(commande).await, "nouvelle");
    let issue: String = sqlx::query_scalar("SELECT issue::text FROM dispatch.offre WHERE id = $1")
        .bind(offre.id)
        .fetch_one(&bac.cmd.pool)
        .await
        .unwrap();
    assert_eq!(issue, "en_vol", "l'offre vit en Postgres, pas dans l'index");

    // L'offre en vol est toujours lisible par son destinataire : son échéance
    // est persistée, elle ne dépendait pas de l'index.
    let (statut, corps) = bac
        .get("/courses/offre-courante", &bac.coursiers[0].jeton)
        .await;
    assert!(statut == 200 || statut == 204, "{corps}");

    // Aucune double affectation n'a pu se produire.
    let doublons: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
             SELECT commande_id FROM commandes.livraison WHERE coursier_id IS NOT NULL
             GROUP BY 1 HAVING count(DISTINCT coursier_id) > 1) t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(doublons, 0);

    // Et le pool se reconstitue à la publication suivante, SANS intervention.
    assert_eq!(bac.pool_coursiers.taille(), 0);
    bac.publier_position(0).await;
    assert_eq!(bac.pool_coursiers.taille(), 1);
}

/// L'offre en vol dont le destinataire a disparu du pool est **redétectée par
/// son échéance** et conclue par le tic — jamais oubliée.
#[sqlx::test(migrations = "../migrations")]
async fn une_offre_en_vol_survit_au_vidage_et_le_tic_la_conclut(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("offre attendue");
    };

    bac.pool_coursiers.vider();
    bac.faire_expirer_offre(offre.id).await;

    let resultat = bac.tic().await;
    assert_eq!(
        resultat.offres_expirees, 1,
        "le tic relit les échéances PERSISTÉES — l'index n'y est pour rien",
    );
    let issue: String = sqlx::query_scalar("SELECT issue::text FROM dispatch.offre WHERE id = $1")
        .bind(offre.id)
        .fetch_one(&bac.cmd.pool)
        .await
        .unwrap();
    assert_eq!(issue, "non_repondue");
}

/// **Le fantôme** — un membre de l'index sans état ne reçoit RIEN, puis il est
/// élagué, et l'élagage est **compté**.
#[sqlx::test(migrations = "../migrations")]
async fn un_fantome_de_l_index_ne_recoit_rien_puis_est_elague(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    // L'état expire, le membre survit : c'est exactement le fantôme de Redis.
    bac.pool_coursiers.faire_expirer(bac.coursiers[0].id);
    assert!(
        !bac.pool_coursiers_etat_existe(0).await,
        "plus d'état — donc plus d'appartenance au pool",
    );
    let membres = PoolCoursiers::dans_rayon(
        bac.pool_coursiers.as_ref(),
        bac.cmd.ville,
        bac.coursiers[0].lat,
        bac.coursiers[0].lon,
        4_000,
    )
    .await
    .unwrap();
    assert_eq!(membres.len(), 1, "le membre est encore dans l'index");

    // Entre les deux, il ne reçoit RIEN.
    let commande = bac.commande_prete().await;
    let decision = bac.dispatcher(commande).await;
    assert!(
        matches!(decision, DecisionPipeline::MiseEnFile { .. }),
        "un fantôme n'est pas un coursier : {decision:?}",
    );

    // Le tic l'élague, et le COMPTE — un plafond silencieux ferait passer une
    // fuite d'index pour un fonctionnement normal.
    let resultat = bac.tic().await;
    assert_eq!(resultat.fantomes_elagues, 1);

    let membres = PoolCoursiers::dans_rayon(
        bac.pool_coursiers.as_ref(),
        bac.cmd.ville,
        bac.coursiers[0].lat,
        bac.coursiers[0].lon,
        4_000,
    )
    .await
    .unwrap();
    assert!(membres.is_empty());
}
