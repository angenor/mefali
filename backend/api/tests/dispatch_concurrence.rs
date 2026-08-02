//! **Le test qui porte le cycle** — SC-001 et SC-014.
//!
//! Trois volets, et le second est le plus important :
//!
//! - **(A)** N tâches acceptent la même offre en parallèle sur l'app RÉELLE →
//!   exactement un `200`, N−1 `409 deja_prise`, aucune pénalité ;
//! - **(B)** `affecter` appelé deux fois en parallèle **sans Redis du tout** →
//!   une seule affectation, la seconde refusée par la table de transitions
//!   fermée. C'est ce volet qui prouve que la garantie n'est pas **louée** à un
//!   service éphémère : Redis peut disparaître, la double acceptation reste
//!   impossible ;
//! - **(C)** deux commandes prêtes au même instant, **un seul** coursier
//!   éligible → il reçoit UNE offre, la seconde commande passe à son candidat
//!   suivant (SC-014).
//!
//! Plus les trois requêtes de contrôle du quickstart, qui vérifient les
//! invariants **en base**, indépendamment du chemin emprunté.

mod bac_dispatch;

use std::sync::Arc;

use bac_dispatch::Bac;
use dispatch::DecisionPipeline;
use serde_json::json;
use uuid::Uuid;

/// **(A) — N acceptations parallèles**, sur de vraies tâches tokio
/// multi-thread, contre la vraie base.
///
/// ⚠ L'app Actix de test n'est pas `Send` (son routeur est un `Rc`) : la
/// concurrence s'exerce donc sur le DOMAINE, qui est exactement l'endroit où la
/// garantie vit. Le passage HTTP, lui, est vérifié juste après — ce qu'il
/// apporte de plus est la **traduction** du refus, pas la sérialisation.
#[sqlx::test(migrations = "../migrations")]
async fn a_n_acceptations_paralleles_un_seul_gagnant(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    // Le MÊME coursier tape N fois avec des UUID client DIFFÉRENTS : ce n'est
    // pas un rejeu idempotent, ce sont N décisions concurrentes.
    const N: usize = 8;
    let depot = Arc::new(bac.dispatch.clone());
    let mut taches = Vec::new();
    for _ in 0..N {
        let depot = Arc::clone(&depot);
        let (offre_id, coursier) = (offre.id, bac.coursiers[0].id);
        taches.push(tokio::spawn(async move {
            depot
                .accepter_offre(offre_id, coursier, Uuid::now_v7(), chrono::Utc::now())
                .await
        }));
    }

    let mut succes = 0;
    let mut deja_prises = 0;
    for t in taches {
        match t.await.unwrap() {
            Ok(_) => succes += 1,
            Err(dispatch::ErreurDispatch::DejaPrise) => deja_prises += 1,
            Err(dispatch::ErreurDispatch::CourseActive) => deja_prises += 1,
            Err(e) => panic!("refus inattendu : {e}"),
        }
    }
    assert_eq!(succes, 1, "exactement une acceptation aboutit");
    assert_eq!(deja_prises, N - 1);

    // AUCUNE pénalité : « déjà prise » n'est pas un refus, et le coursier reste
    // dans le pool (FR-049).
    assert_eq!(bac.nb_evenements("dispatch.offre_refusee").await, 0);
    assert!(
        bac.pool_coursiers_etat_existe(0).await,
        "un perdant reste dans le pool — il n'a rien fait de mal",
    );
    assert_eq!(bac.nb_evenements("dispatch.offre_acceptee").await, 1);
    assert_eq!(bac.nb_evenements("commande.assignee").await, 1);
}

/// (A bis) — la **traduction HTTP** du refus : `409 deja_prise`, sur l'app
/// réelle. C'est ce que l'app affiche en K2-1b, ton neutre.
#[sqlx::test(migrations = "../migrations")]
async fn a_bis_la_seconde_acceptation_rend_409_deja_prise(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    bac.dans_le_pool(1, 15_000).await;

    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };
    let gagnant = bac
        .coursiers
        .iter()
        .position(|c| c.id == offre.coursier)
        .expect("le destinataire est l'un des coursiers du bac");

    let uri = format!("/courses/offres/{}/accepter", offre.id);
    let (s1, c1) = bac
        .post(
            &uri,
            &bac.coursiers[gagnant].jeton,
            json!({ "uuid_client": Uuid::now_v7(), "horodatage_local": chrono::Utc::now() }),
        )
        .await;
    assert_eq!(s1, 200, "{c1}");

    // Le même coursier retente avec un AUTRE uuid : ce n'est plus un rejeu.
    let (s2, c2) = bac
        .post(
            &uri,
            &bac.coursiers[gagnant].jeton,
            json!({ "uuid_client": Uuid::now_v7(), "horodatage_local": chrono::Utc::now() }),
        )
        .await;
    assert_eq!(s2, 409, "{c2}");
    assert_eq!(c2["code"], "deja_prise");
    assert_eq!(c2["message_cle"], "dispatch.erreur.deja_prise");
}

/// **(B) — SANS REDIS DU TOUT.** Deux `affecter` en parallèle : la table de
/// transitions fermée et le `SELECT … FOR UPDATE` suffisent seuls.
///
/// Ce test n'utilise ni pool, ni verrou, ni offre : il attaque directement le
/// contrat de `commandes`. S'il passait grâce à Redis, il ne prouverait rien.
#[sqlx::test(migrations = "../migrations")]
async fn b_deux_affectations_paralleles_sans_redis(pool: sqlx::PgPool) {
    use commandes::CommandesADispatcher;

    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prete().await;
    let depot = Arc::new(bac.cmd.commandes.clone());

    let (a, b) = (bac.coursiers[0].id, bac.coursiers[1].id);
    let (d1, d2) = (Arc::clone(&depot), Arc::clone(&depot));
    let t1 = tokio::spawn(async move { d1.affecter(commande, a).await });
    let t2 = tokio::spawn(async move { d2.affecter(commande, b).await });
    let (r1, r2) = (t1.await.unwrap(), t2.await.unwrap());

    let succes = [r1.is_ok(), r2.is_ok()].iter().filter(|x| **x).count();
    assert_eq!(
        succes, 1,
        "la table de transitions FERMÉE suffit seule — Redis n'est pas dans le chemin",
    );

    let coursiers: Vec<Option<Uuid>> =
        sqlx::query_scalar("SELECT coursier_id FROM commandes.livraison WHERE commande_id = $1")
            .bind(commande)
            .fetch_all(&bac.cmd.pool)
            .await
            .unwrap();
    assert_eq!(coursiers.len(), 1);
    assert!(coursiers[0].is_some());
    assert_eq!(bac.cmd.etat_commande(commande).await, "en_cours");
    assert_eq!(
        bac.nb_evenements("commande.assignee").await,
        1,
        "un refus n'est pas une transition : il n'écrit aucun événement",
    );
}

/// **(C) — SC-014** : deux commandes prêtes au même instant, un seul coursier
/// éligible. Il reçoit UNE offre ; la seconde commande ne peut pas lui en
/// envoyer une deuxième, et passe à son candidat suivant (ici : personne).
#[sqlx::test(migrations = "../migrations")]
async fn c_un_seul_coursier_deux_commandes_une_seule_offre(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    let une = bac.commande_prete().await;
    let deux = bac.commande_prete().await;

    let d1 = bac.dispatcher(une).await;
    let d2 = bac.dispatcher(deux).await;

    assert!(matches!(d1, DecisionPipeline::OffreEmise(_)));
    assert!(
        matches!(d2, DecisionPipeline::MiseEnFile { .. }),
        "le seul coursier porte déjà une offre : la seconde commande attend",
    );

    // L'invariant, lu EN BASE : jamais deux offres en vol pour un coursier.
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

/// Les **trois requêtes de contrôle du quickstart**, après un parcours complet.
///
/// Elles vérifient les invariants en base, indépendamment du chemin : c'est ce
/// qui reste vrai même si le code du pipeline change demain.
#[sqlx::test(migrations = "../migrations")]
async fn les_invariants_de_concurrence_tiennent_en_base(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..4 {
        bac.dans_le_pool(i, 15_000).await;
    }
    for _ in 0..4 {
        let commande = bac.commande_prete().await;
        bac.dispatcher(commande).await;
    }

    // 1. Jamais deux offres en vol sur la même commande.
    let par_commande: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
             SELECT commande_id FROM dispatch.offre WHERE issue = 'en_vol'
             GROUP BY 1 HAVING count(*) > 1) t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(par_commande, 0);

    // 2. Jamais deux offres en vol pour le même coursier.
    let par_coursier: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
             SELECT coursier_id FROM dispatch.offre WHERE issue = 'en_vol'
             GROUP BY 1 HAVING count(*) > 1) t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(par_coursier, 0);

    // 3. Jamais deux coursiers sur une commande.
    let deux_coursiers: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
             SELECT commande_id FROM commandes.livraison WHERE coursier_id IS NOT NULL
             GROUP BY 1 HAVING count(DISTINCT coursier_id) > 1) t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(deux_coursiers, 0);
}

/// **SC-002** — le délai d'assignation, mesuré sur l'ÉVÉNEMENT et non au
/// chronomètre : c'est `livraison.affectee.delai_assignation_s` qui fait foi.
#[sqlx::test(migrations = "../migrations")]
async fn sc002_le_delai_d_assignation_se_lit_sur_l_evenement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    let (statut, corps) = bac
        .post(
            &format!("/courses/offres/{}/accepter", offre.id),
            &bac.coursiers[0].jeton,
            json!({ "uuid_client": Uuid::now_v7(), "horodatage_local": chrono::Utc::now() }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");

    let payloads = bac.evenements("livraison.affectee").await;
    let delai = payloads[0]["delai_assignation_s"].as_i64().unwrap();
    assert!(
        delai < 120,
        "assignation en {delai} s — le seuil de SC-002 est de 2 min",
    );
}

/// Le **rejeu** d'une acceptation rend le même corps, sans seconde affectation
/// ni second événement (FR-054).
#[sqlx::test(migrations = "../migrations")]
async fn le_rejeu_d_une_acceptation_ne_double_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    let uuid_client = Uuid::now_v7();
    let corps_demande =
        json!({ "uuid_client": uuid_client, "horodatage_local": chrono::Utc::now() });
    let uri = format!("/courses/offres/{}/accepter", offre.id);

    let (s1, c1) = bac
        .post(&uri, &bac.coursiers[0].jeton, corps_demande.clone())
        .await;
    let (s2, c2) = bac.post(&uri, &bac.coursiers[0].jeton, corps_demande).await;

    assert_eq!(s1, 200, "{c1}");
    assert_eq!(s2, 200, "{c2}");
    assert_eq!(c1["livraison_id"], c2["livraison_id"], "le MÊME corps");
    assert_eq!(c2["rejeu"], true);
    assert_eq!(bac.nb_evenements("dispatch.offre_acceptee").await, 1);
    assert_eq!(bac.nb_evenements("commande.assignee").await, 1);
}

/// Une offre **d'un autre coursier** n'existe pas : `404`, jamais `403`.
///
/// Un `403` apprendrait à ce coursier qu'une course circule sans lui.
#[sqlx::test(migrations = "../migrations")]
async fn l_offre_d_un_autre_rend_404(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    let (statut, corps) = bac
        .post(
            &format!("/courses/offres/{}/accepter", offre.id),
            &bac.coursiers[1].jeton,
            json!({ "uuid_client": Uuid::now_v7(), "horodatage_local": chrono::Utc::now() }),
        )
        .await;
    assert_eq!(statut, 404, "{corps}");
    assert_eq!(corps["message_cle"], "dispatch.erreur.offre_inconnue");
}
