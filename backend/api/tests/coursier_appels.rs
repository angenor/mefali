//! Appels journalisés via l'app (cycle CRS 010, T030/T032).
//!
//! Ce que ce fichier tient : l'idempotence de la file, la distinction des
//! motifs — **seul `client_absent` compte** pour la preuve —, l'issue déclarée
//! qui se corrige, et surtout l'absence totale de numéro dans l'événement émis.
//!
//! Le dernier point n'est pas décoratif : `appel.intention` existe depuis le
//! cycle 008 et prévoyait `de: coursier` sans que personne ne l'émette. Ce
//! cycle est le premier — et c'est exactement le moment où un numéro pourrait
//! s'y glisser.

mod bac_coursier;

use bac_coursier::Bac;
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

fn appel(uuid: Uuid, motif: &str) -> Value {
    json!({
        "uuid_client": uuid,
        "vers": "client",
        "motif": motif,
        "passe_le_local": chrono::Utc::now(),
    })
}

/// Un appel est journalisé, et il dit s'il compte pour la preuve.
#[sqlx::test(migrations = "../migrations")]
async fn un_appel_client_absent_compte_pour_la_preuve(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac
        .post(
            &format!("/courses/{}/appels", course.livraison),
            &bac.jeton_coursier,
            appel(Uuid::now_v7(), "client_absent"),
        )
        .await;
    assert_eq!(statut, 201, "{corps}");
    assert_eq!(corps["compte_pour_preuve"], true);

    // Un appel de SUIVI ne prouve rien : sans cette distinction, trois appels
    // de courtoisie suffiraient à déclarer un échec (FR-035).
    let (statut, corps) = bac
        .post(
            &format!("/courses/{}/appels", course.livraison),
            &bac.jeton_coursier,
            appel(Uuid::now_v7(), "suivi"),
        )
        .await;
    assert_eq!(statut, 201);
    assert_eq!(corps["compte_pour_preuve"], false);
}

/// Constitution V — le rejeu du MÊME `uuid_client` rend le même corps, sans
/// seconde ligne ni second événement.
#[sqlx::test(migrations = "../migrations")]
async fn le_rejeu_d_un_appel_n_ecrit_rien_de_plus(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let uuid = Uuid::now_v7();
    let uri = format!("/courses/{}/appels", course.livraison);

    let (premier, corps1) = bac
        .post(&uri, &bac.jeton_coursier, appel(uuid, "client_absent"))
        .await;
    assert_eq!(premier, 201);

    let (second, corps2) = bac
        .post(&uri, &bac.jeton_coursier, appel(uuid, "client_absent"))
        .await;
    assert_eq!(second, 200, "un rejeu n'est pas une création");
    assert_eq!(corps1["appel_id"], corps2["appel_id"], "le MÊME appel");

    assert_eq!(
        bac.compter("SELECT count(*) FROM coursier.appel_coursier")
            .await,
        1,
    );
    assert_eq!(
        bac.nb_evenements("appel.intention").await,
        1,
        "un rejeu n'émet rien",
    );
}

/// R19 — l'issue est DÉCLARÉE, et se corrige : Yao répond « sans réponse »,
/// puis le client rappelle.
#[sqlx::test(migrations = "../migrations")]
async fn l_issue_se_declare_puis_se_corrige(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let uuid = Uuid::now_v7();
    let uri = format!("/courses/{}/appels", course.livraison);

    let mut demande = appel(uuid, "client_absent");
    demande["issue"] = json!("sans_reponse");
    let (statut, _) = bac.post(&uri, &bac.jeton_coursier, demande).await;
    assert_eq!(statut, 201);
    assert_eq!(
        bac.compter("SELECT count(*) FROM coursier.appel_coursier WHERE issue = 'sans_reponse'")
            .await,
        1,
    );

    let (statut, corps) = bac
        .patch(
            &uri,
            &bac.jeton_coursier,
            json!({ "uuid_client": uuid, "issue": "repondu" }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(
        bac.compter("SELECT count(*) FROM coursier.appel_coursier WHERE issue = 'repondu'")
            .await,
        1,
    );
    // L'issue n'est pas une transition d'état : elle n'émet AUCUN événement.
    assert_eq!(bac.nb_evenements("appel.intention").await, 1);
}

/// FR-007, SC-015 — **aucun numéro** dans l'événement. Le serveur n'en a jamais
/// vu, et la table n'a aucune colonne pour en stocker un.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_numero_n_entre_dans_l_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.post(
        &format!("/courses/{}/appels", course.livraison),
        &bac.jeton_coursier,
        appel(Uuid::now_v7(), "client_absent"),
    )
    .await;

    let payloads = bac.evenements("appel.intention").await;
    assert_eq!(payloads.len(), 1);
    let brut = payloads[0].to_string();
    assert!(
        brut.contains("\"de\":\"coursier\""),
        "premier émetteur : {brut}"
    );
    assert!(brut.contains("client_absent"));
    assert!(
        !brut.contains("+225"),
        "aucun numéro ne doit entrer dans un événement : {brut}",
    );
    assert!(!brut.contains("telephone"), "{brut}");

    // La table elle-même n'a pas de colonne de numéro — la garde est
    // structurelle, pas conventionnelle.
    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name::text FROM information_schema.columns
          WHERE table_schema = 'coursier' AND table_name = 'appel_coursier'",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert!(!colonnes.iter().any(|c| c.contains("telephone")));
    assert!(!colonnes.iter().any(|c| c.contains("numero")));
}

/// FR-006 — un autre coursier ne journalise rien sur une course qui n'est pas
/// la sienne. Il a le RÔLE : ce qui est refusé, c'est la propriété.
#[sqlx::test(migrations = "../migrations")]
async fn un_autre_coursier_ne_journalise_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac
        .post(
            &format!("/courses/{}/appels", course.livraison),
            &bac.jeton_autre_coursier,
            appel(Uuid::now_v7(), "client_absent"),
        )
        .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "course_non_proprietaire");
    assert_eq!(
        bac.compter("SELECT count(*) FROM coursier.appel_coursier")
            .await,
        0,
    );
}

/// Un appel vendeur DIT lequel : sans prestataire, la demande est mal formée.
/// Sans cette garde, l'exploitation lirait « un appel vendeur » sans savoir
/// auquel des trois.
#[sqlx::test(migrations = "../migrations")]
async fn un_appel_vendeur_doit_dire_lequel(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let uri = format!("/courses/{}/appels", course.livraison);

    let (statut, corps) = bac
        .post(
            &uri,
            &bac.jeton_coursier,
            json!({
                "uuid_client": Uuid::now_v7(),
                "vers": "vendeur",
                "motif": "substitution",
                "passe_le_local": chrono::Utc::now(),
            }),
        )
        .await;
    assert_eq!(statut, 422, "{corps}");

    let (statut, _) = bac
        .post(
            &uri,
            &bac.jeton_coursier,
            json!({
                "uuid_client": Uuid::now_v7(),
                "vers": "vendeur",
                "prestataire_id": bac.vendeurs[0].id,
                "motif": "substitution",
                "passe_le_local": chrono::Utc::now(),
            }),
        )
        .await;
    assert_eq!(statut, 201);
}
