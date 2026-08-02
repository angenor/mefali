//! Les invariants TRANSVERSES du cycle : paramètres, minimisation, garde de
//! configuration.
//!
//! - **SC-008** : les 18 paramètres existent, et changer une valeur change le
//!   comportement **sans redéploiement** ;
//! - **SC-011** : aucune coordonnée, aucun numéro dans les événements du
//!   module — vérifié par **parcours automatique** des charges utiles, ce qui
//!   est plus fiable qu'une relecture ;
//! - **SC-005** : une configuration incohérente est refusée au CHARGEMENT.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::{ConfigDispatch, DecisionPipeline};
use serde_json::{json, Value};

/// **SC-008** — l'inventaire : les 18 clés du cycle sont résolues pour la zone.
#[sqlx::test(migrations = "../migrations")]
async fn sc008_les_dix_huit_parametres_sont_resolus(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let config = bac.config().await;

    // Les 7 du PAYS, hérités par la ville.
    assert_eq!(config.pool_ttl_s, 90);
    assert_eq!(config.timer_offre_s, 40);
    assert_eq!(config.verrou_offre_s, 45);
    assert_eq!(config.timeouts_francs_par_jour, 3);
    assert_eq!(config.acceptation_fenetre_jours, 7);
    assert_eq!(config.note_composante_neutre_millimes, 500);
    assert_eq!(config.reassignation_deplacement_min_m, 150);
    // Les 11 de la VILLE.
    assert_eq!(config.rayon_m, 4_000);
    assert_eq!(config.grille_avance.paliers.len(), 3);
    assert_eq!(config.poids.somme(), 100);
    assert_eq!(config.inactivite_plafond_s, 1_800);
    assert_eq!(config.broadcast_apres_candidats, 3);
    assert_eq!(config.broadcast_apres_s, 120);
    assert_eq!(config.reassignation_sans_mouvement_s, 300);
    assert_eq!(config.reassignation_sans_scan_marge_s, 600);
    // Les 3 RÉUTILISÉS, jamais redéclarés.
    assert_eq!(config.position_periode_s, 30);
    assert_eq!(config.escalade_attente_s, 300);
    assert_eq!(config.devise, "XOF");

    // Contrôle d'inventaire du quickstart.
    let n: i64 =
        sqlx::query_scalar("SELECT count(*) FROM zones.parametre_zone WHERE cle LIKE 'dispatch.%'")
            .fetch_one(&bac.cmd.pool)
            .await
            .unwrap();
    assert_eq!(n, 18, "18 paramètres créés par le cycle, ni plus ni moins");
}

/// **SC-008 en action** — changer `dispatch.rayon_m` en base change le vivier,
/// sans redéploiement.
#[sqlx::test(migrations = "../migrations")]
async fn sc008_changer_le_rayon_change_le_vivier(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    bac.proximite.defaut(3_000, 600);

    // Rayon 4 km : le coursier est dedans.
    let commande = bac.commande_prete().await;
    assert!(matches!(
        bac.dispatcher(commande).await,
        DecisionPipeline::OffreEmise(_)
    ));

    // Rayon réduit à 1 km : le même coursier sort du vivier.
    bac.poser_parametre(bac.cmd.ville, "dispatch.rayon_m", json!(1_000))
        .await;
    let commande = bac.commande_prete().await;
    assert!(
        matches!(
            bac.dispatcher(commande).await,
            DecisionPipeline::MiseEnFile { .. }
        ),
        "un paramètre changé en base agit au dispatch suivant",
    );
}

/// **SC-011** — parcours AUTOMATIQUE des charges utiles : aucune clé interdite.
///
/// Plus fiable qu'une relecture : un champ ajouté demain sans y penser fait
/// échouer ce test.
#[sqlx::test(migrations = "../migrations")]
async fn sc011_aucune_coordonnee_ni_numero_dans_les_evenements(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Un parcours large : mise en ligne, offre, acceptation, escalade, reprise.
    for i in 0..2 {
        bac.dans_le_pool(i, 15_000).await;
    }
    let commande = bac.commande_prete().await;
    if let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await {
        bac.dispatch
            .accepter_offre(
                offre.id,
                offre.coursier,
                uuid::Uuid::now_v7(),
                chrono::Utc::now(),
            )
            .await
            .unwrap();
    }
    let attente = bac.commande_prete().await;
    bac.vieillir_commande(attente, 400).await;
    bac.tic().await;

    let evenements: Vec<(String, Value)> = sqlx::query_as(
        "SELECT type_evenement, payload FROM outbox.evenement
         WHERE type_evenement LIKE 'dispatch.%' OR type_evenement LIKE 'coursier.%'",
    )
    .fetch_all(&bac.cmd.pool)
    .await
    .unwrap();
    assert!(
        !evenements.is_empty(),
        "le parcours doit produire des événements"
    );

    const INTERDITS: [&str; 6] = [
        "lat",
        "lon",
        "latitude",
        "longitude",
        "telephone",
        "adresse",
    ];
    for (type_evenement, payload) in &evenements {
        let mut cles = Vec::new();
        collecter_cles(payload, &mut cles);
        for cle in &cles {
            assert!(
                !INTERDITS.contains(&cle.as_str()),
                "« {type_evenement} » porte la clé interdite « {cle} » (FR-088, SC-011)",
            );
        }
        // Et aucun numéro E.164 en valeur, quelle que soit la clé.
        assert!(
            !payload.to_string().contains("+225"),
            "« {type_evenement} » porte un numéro de téléphone",
        );
    }
}

/// Collecte récursivement toutes les clés d'un JSON.
fn collecter_cles(valeur: &Value, dans: &mut Vec<String>) {
    match valeur {
        Value::Object(map) => {
            for (cle, v) in map {
                dans.push(cle.clone());
                collecter_cles(v, dans);
            }
        }
        Value::Array(items) => items.iter().for_each(|v| collecter_cles(v, dans)),
        _ => {}
    }
}

/// **SC-005** — une configuration incohérente est refusée **au chargement**,
/// pas découverte en production.
///
/// Un verrou plus court que le compte à rebours ne produit pas d'erreur : il
/// produit un dispatch bancal qui offre deux fois la même course à la seconde
/// 41. Un dispatch bancal se remarque des semaines plus tard.
#[sqlx::test(migrations = "../migrations")]
async fn sc005_une_configuration_incoherente_est_refusee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    // 1. Verrou ≤ timer.
    bac.poser_parametre(bac.cmd.pays, "dispatch.verrou_offre_s", json!(30))
        .await;
    let e = ConfigDispatch::charger(&zones::PgZones::new(bac.cmd.pool.clone()), bac.cmd.ville)
        .await
        .expect_err("verrou plus court que le timer");
    assert!(e.to_string().contains("dispatch.verrou_offre_s"), "{e}");
    bac.poser_parametre(bac.cmd.pays, "dispatch.verrou_offre_s", json!(45))
        .await;

    // 2. Somme des poids ≠ 100.
    bac.poser_parametre(bac.cmd.ville, "dispatch.poids_note", json!(35))
        .await;
    let e = ConfigDispatch::charger(&zones::PgZones::new(bac.cmd.pool.clone()), bac.cmd.ville)
        .await
        .expect_err("somme de poids invalide");
    assert!(e.to_string().contains("115"), "{e}");
    bac.poser_parametre(bac.cmd.ville, "dispatch.poids_note", json!(20))
        .await;

    // 3. Paramètre ABSENT : erreur de configuration, jamais un défaut
    //    silencieux — un rayon à 0 n'écarterait pas un coursier, il les
    //    écarterait tous.
    sqlx::query("DELETE FROM zones.parametre_zone WHERE cle = 'dispatch.rayon_m'")
        .execute(&bac.cmd.pool)
        .await
        .unwrap();
    let e = ConfigDispatch::charger(&zones::PgZones::new(bac.cmd.pool.clone()), bac.cmd.ville)
        .await
        .expect_err("paramètre absent");
    assert!(e.to_string().contains("dispatch.rayon_m"), "{e}");
}
