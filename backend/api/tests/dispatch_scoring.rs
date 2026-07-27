//! US3 (DSP-03) — le classement est juste, reproductible et auditable.
//!
//! **SC-007 est le test qui compte** : 20 dispatches sur 4 coursiers
//! comparables, chacun sollicité au moins 3 fois. Sans la composante
//! d'inactivité, le coursier le plus proche du centre prendrait tout — et les
//! trois autres désinstalleraient l'app.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::DecisionPipeline;
use std::collections::HashMap;
use uuid::Uuid;

/// Sollicitations par coursier, tous dispatches confondus.
async fn sollicitations(bac: &Bac) -> HashMap<Uuid, i64> {
    let lignes: Vec<(Uuid, i64)> = sqlx::query_as(
        "SELECT coursier_id, count(*) FROM dispatch.offre GROUP BY 1",
    )
    .fetch_all(&bac.cmd.pool)
    .await
    .unwrap();
    lignes.into_iter().collect()
}

/// **SC-007 — l'équité.** 20 dispatches, 4 coursiers de profils comparables :
/// chacun est sollicité au moins 3 fois.
///
/// Le mécanisme : chaque offre refusée fait remonter l'inactivité des autres,
/// et la composante d'inactivité les fait passer devant. C'est ce qui empêche
/// qu'un seul coursier accapare le flux.
#[sqlx::test(migrations = "../migrations")]
async fn sc007_vingt_dispatches_personne_n_est_oublie(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..4 {
        bac.dans_le_pool(i, 15_000).await;
    }

    for _ in 0..20 {
        let commande = bac.commande_prete().await;
        let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
            continue;
        };
        // Le destinataire refuse : la course repart au suivant, et son propre
        // compteur d'inactivité repart de zéro.
        bac.dispatch
            .refuser_offre(
                offre.id,
                offre.coursier,
                Uuid::now_v7(),
                chrono::Utc::now(),
            )
            .await
            .unwrap();
    }

    let par_coursier = sollicitations(&bac).await;
    assert_eq!(
        par_coursier.len(),
        4,
        "les QUATRE coursiers ont été sollicités, pas seulement le plus proche",
    );
    for c in &bac.coursiers {
        let n = par_coursier.get(&c.id).copied().unwrap_or(0);
        assert!(
            n >= 3,
            "coursier sollicité {n} fois sur 20 dispatches — l'équité de SC-007 \
             demande au moins 3",
        );
    }
}

/// Le classement suit la **proximité** quand tout le reste est égal : le plus
/// proche reçoit l'offre.
#[sqlx::test(migrations = "../migrations")]
async fn a_profils_egaux_le_plus_proche_recoit(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..3 {
        bac.dans_le_pool(i, 15_000).await;
    }
    // Le coursier 1 est nettement plus près (durées connues d'avance).
    bac.proximite.defaut(3_000, 900);
    bac.proximite.depuis(
        tarification::Point {
            lat: bac.coursiers[1].lat,
            lon: bac.coursiers[1].lon,
        },
        500,
        60,
    );

    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };
    assert_eq!(
        offre.coursier, bac.coursiers[1].id,
        "à profils égaux, la proximité décide",
    );
    assert_eq!(offre.rang, 0, "le mieux classé porte le rang 0");
}

/// **SC-008 sur les poids** : changer `dispatch.poids_proximite` en base change
/// l'ordre — **sans redéploiement**.
#[sqlx::test(migrations = "../migrations")]
async fn changer_les_poids_change_l_ordre_sans_redeployer(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..2 {
        bac.dans_le_pool(i, 15_000).await;
    }
    // Le coursier 0 est plus loin, mais il attend depuis plus longtemps :
    // sa dernière course remonte à 30 min, celle de l'autre à l'instant.
    bac.proximite.depuis(
        tarification::Point {
            lat: bac.coursiers[0].lat,
            lon: bac.coursiers[0].lon,
        },
        3_500,
        900,
    );
    bac.proximite.depuis(
        tarification::Point {
            lat: bac.coursiers[1].lat,
            lon: bac.coursiers[1].lon,
        },
        500,
        60,
    );

    // Tout à la proximité : le plus proche gagne.
    bac.poser_parametre(bac.cmd.ville, "dispatch.poids_proximite", serde_json::json!(100))
        .await;
    for cle in ["dispatch.poids_inactivite", "dispatch.poids_note", "dispatch.poids_acceptation"] {
        bac.poser_parametre(bac.cmd.ville, cle, serde_json::json!(0)).await;
    }
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("offre attendue");
    };
    assert_eq!(offre.coursier, bac.coursiers[1].id);
    bac.dispatch
        .refuser_offre(offre.id, offre.coursier, Uuid::now_v7(), chrono::Utc::now())
        .await
        .unwrap();

    // Tout à l'inactivité : c'est l'autre qui passe devant, **sans un seul
    // déploiement** — juste une ligne changée en base.
    bac.poser_parametre(bac.cmd.ville, "dispatch.poids_proximite", serde_json::json!(0))
        .await;
    bac.poser_parametre(
        bac.cmd.ville,
        "dispatch.poids_inactivite",
        serde_json::json!(100),
    )
    .await;
    // Le coursier 0 est dans le pool depuis plus longtemps que le 1.
    sqlx::query(
        "UPDATE commandes.livraison SET etat = 'livree', livree_le = now()
         WHERE coursier_id = $1",
    )
    .bind(bac.coursiers[1].id)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();

    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("offre attendue");
    };
    assert_eq!(
        offre.coursier, bac.coursiers[0].id,
        "poids changé en base ⇒ ordre changé, sans redéploiement (SC-008)",
    );
}

/// L'agrégat `dispatch.evaluation_faite` dit **sur quoi** la proximité a été
/// mesurée : durée quand OSRM répond, distance sinon (FR-035).
#[sqlx::test(migrations = "../migrations")]
async fn l_evaluation_dit_sur_quoi_la_proximite_a_ete_mesuree(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    let commande = bac.commande_prete().await;
    bac.dispatcher(commande).await;
    let payloads = bac.evenements("dispatch.evaluation_faite").await;
    assert_eq!(payloads.last().unwrap()["mesure"], "duree");
    assert_eq!(payloads.last().unwrap()["nb_eligibles"], 1);

    // Durées nulles (routage muet) : la distance devient la seule information.
    bac.proximite.defaut(1_200, 0);
    let commande = bac.commande_prete().await;
    bac.dispatcher(commande).await;
    let payloads = bac.evenements("dispatch.evaluation_faite").await;
    assert_eq!(payloads.last().unwrap()["mesure"], "distance");
}
