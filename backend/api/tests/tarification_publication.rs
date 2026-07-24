//! US3 (TRF-03) — simulateur obligatoire et garde de publication (SC-005).
//!
//! La promesse tenue ici : **aucune grille fausse ne peut atteindre la
//! production**. Simuler puis éditer ne suffit pas ; une borne resserrée après
//! coup bloque ; et le simulateur, lui, ne laisse AUCUNE trace.

mod bac;

use actix_web::{http::StatusCode, test, App};
use bac::{course_simulee, regle_moto, Bac};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

macro_rules! poster {
    ($app:expr, $bac:expr, $uri:expr) => {
        test::call_service(
            &$app,
            test::TestRequest::post()
                .uri(&$uri)
                .insert_header(("authorization", format!("Bearer {}", $bac.jeton_admin)))
                .to_request(),
        )
        .await
    };
    ($app:expr, $bac:expr, $uri:expr, $corps:expr) => {
        test::call_service(
            &$app,
            test::TestRequest::post()
                .uri(&$uri)
                .insert_header(("authorization", format!("Bearer {}", $bac.jeton_admin)))
                .set_json($corps)
                .to_request(),
        )
        .await
    };
}

macro_rules! brouillon {
    ($app:expr, $bac:expr) => {{
        let r = poster!(
            $app,
            $bac,
            format!("/admin/tarification/zones/{}/brouillon", $bac.ville)
        );
        assert_eq!(r.status(), StatusCode::OK);
        let corps: Value = test::read_body_json(r).await;
        corps["id"].as_str().unwrap().parse::<Uuid>().unwrap()
    }};
}

macro_rules! ecrire_regle {
    ($app:expr, $bac:expr, $grille:expr, $regle:expr, $corps:expr) => {
        test::call_service(
            &$app,
            test::TestRequest::put()
                .uri(&format!(
                    "/admin/tarification/brouillon/{}/regles/{}",
                    $grille, $regle
                ))
                .insert_header(("authorization", format!("Bearer {}", $bac.jeton_admin)))
                .set_json($corps)
                .to_request(),
        )
        .await
    };
}

/// Brouillon prêt à simuler : une règle moto bien formée.
macro_rules! brouillon_garni {
    ($app:expr, $bac:expr) => {{
        let grille = brouillon!($app, $bac);
        let r = ecrire_regle!($app, $bac, grille, Uuid::now_v7(), regle_moto(50));
        assert_eq!(r.status(), StatusCode::OK);
        grille
    }};
}

/// SC-005 (1) — publier sans avoir simulé est REFUSÉ.
#[sqlx::test(migrations = "../migrations")]
async fn publication_sans_simulation_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon_garni!(app, bac);

    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("simulation_requise"));
    assert_eq!(
        corps["message_cle"],
        json!("tarification.erreur.simulation_requise")
    );
    assert_eq!(bac.etat_grille(grille).await, "brouillon", "rien n'a bougé");
    assert!(bac.evenements("grille.publiee").await.is_empty());
}

/// SC-005 (3) — éditer APRÈS avoir simulé RÉARME la garde : ce qui est publié
/// doit être exactement ce qui a été simulé.
#[sqlx::test(migrations = "../migrations")]
async fn edition_post_simulation_rearme_la_garde(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon_garni!(app, bac);

    let simulation = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/simuler"),
        course_simulee()
    );
    assert_eq!(simulation.status(), StatusCode::OK);

    // La grille est désormais publiable…
    let vue = test::call_service(
        &app,
        test::TestRequest::get()
            .uri(&format!("/admin/tarification/zones/{}/grille", bac.ville))
            .insert_header(("authorization", format!("Bearer {}", bac.jeton_admin)))
            .to_request(),
    )
    .await;
    let corps: Value = test::read_body_json(vue).await;
    assert_eq!(corps["brouillon"]["simulee"], json!(true));

    // …mais une SEULE édition suffit à la refermer.
    let regle_id: Uuid = corps["brouillon"]["regles"][0]["id"]
        .as_str()
        .unwrap()
        .parse()
        .unwrap();
    ecrire_regle!(app, bac, grille, regle_id, regle_moto(60));

    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("simulation_requise"));

    // Supprimer une règle réarme aussi (le contenu a changé).
    poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/simuler"),
        course_simulee()
    );
    test::call_service(
        &app,
        test::TestRequest::delete()
            .uri(&format!(
                "/admin/tarification/brouillon/{grille}/regles/{regle_id}"
            ))
            .insert_header(("authorization", format!("Bearer {}", bac.jeton_admin)))
            .to_request(),
    )
    .await;
    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::CONFLICT, "suppression = édition");
}

/// SC-005 (2) — une règle hors bornes bloque la publication, même simulée.
///
/// Le seul chemin qui y mène : resserrer les bornes de la zone APRÈS l'écriture.
/// L'écriture directe d'une règle hors bornes étant refusée (US1), c'est bien ce
/// cas-là que la garde de publication doit rattraper.
#[sqlx::test(migrations = "../migrations")]
async fn regle_hors_bornes_bloque_la_publication(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon_garni!(app, bac);

    poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/simuler"),
        course_simulee()
    );

    // Marge de la règle : 50. On resserre les bornes à 25–40.
    bac.poser_parametre("tarification.marge.max", json!(40)).await;

    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("regle_hors_bornes"));
    assert_eq!(bac.etat_grille(grille).await, "brouillon");

    // Bornes rétablies → la publication passe (la simulation reste valide : le
    // CONTENU du brouillon n'a pas changé).
    bac.poser_parametre("tarification.marge.max", json!(100)).await;
    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::OK);
}

/// SC-005 (3, fin) — publication réussie : en vigueur, ancienne archivée,
/// événement `grille.publiee`.
#[sqlx::test(migrations = "../migrations")]
async fn publication_archive_et_journalise(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;

    // Première publication.
    let v1 = brouillon_garni!(app, bac);
    poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v1}/simuler"),
        course_simulee()
    );
    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v1}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::OK);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["etat"], json!("en_vigueur"));
    assert!(corps["effet_le"].is_string(), "date d'entrée en vigueur posée");
    assert_eq!(bac.etat_grille(v1).await, "en_vigueur");

    // Seconde publication : la première passe à l'historique.
    let v2 = brouillon!(app, bac);
    assert_ne!(v2, v1);
    poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v2}/simuler"),
        course_simulee()
    );
    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v2}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::OK);
    assert_eq!(bac.etat_grille(v1).await, "historique", "version conservée");
    assert_eq!(bac.etat_grille(v2).await, "en_vigueur");
    assert_eq!(
        bac.compter(
            "SELECT count(*) FROM tarification.grille WHERE etat = 'en_vigueur'"
        )
        .await,
        1,
        "au plus UNE grille en vigueur par zone"
    );

    let evenements = bac.evenements("grille.publiee").await;
    assert_eq!(evenements.len(), 2);
    assert_eq!(evenements[0]["version"], json!(1));
    assert_eq!(evenements[0]["version_precedente"], Value::Null);
    assert_eq!(evenements[1]["version"], json!(2));
    assert_eq!(
        evenements[1]["version_precedente"],
        json!(1),
        "l'archivage est tracé"
    );
    assert_eq!(evenements[1]["acteur"], json!(bac.admin.to_string()));
    assert_eq!(evenements[1]["nb_regles"], json!(1));

    // Republier une grille DÉJÀ en vigueur est refusé.
    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v2}/publier")
    );
    assert_eq!(reponse.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("pas_un_brouillon"));
}

/// SC-005 — le simulateur rend le DÉTAIL COMPLET et ne laisse AUCUNE trace :
/// ni événement outbox, ni changement de la grille en vigueur.
#[sqlx::test(migrations = "../migrations")]
async fn simulateur_detaille_et_sans_effet_de_bord(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;

    // Une grille en vigueur, pour prouver qu'elle ne bouge pas.
    let v1 = brouillon_garni!(app, bac);
    poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v1}/simuler"),
        course_simulee()
    );
    poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v1}/publier")
    );
    let evenements_avant = bac
        .compter("SELECT count(*) FROM outbox.evenement")
        .await;

    // Un brouillon au tarif différent, simulé plusieurs fois.
    let v2 = brouillon!(app, bac);
    let regle_v2: Uuid = {
        let vue = test::call_service(
            &app,
            test::TestRequest::get()
                .uri(&format!("/admin/tarification/zones/{}/grille", bac.ville))
                .insert_header(("authorization", format!("Bearer {}", bac.jeton_admin)))
                .to_request(),
        )
        .await;
        let corps: Value = test::read_body_json(vue).await;
        corps["brouillon"]["regles"][0]["id"]
            .as_str()
            .unwrap()
            .parse()
            .unwrap()
    };
    let mut chere = regle_moto(50);
    chere["part_coursier_base"] = json!(400);
    ecrire_regle!(app, bac, v2, regle_v2, chere);

    let reponse = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{v2}/simuler"),
        course_simulee()
    );
    assert_eq!(reponse.status(), StatusCode::OK);
    let corps: Value = test::read_body_json(reponse).await;

    // Détail COMPLET (FR-020).
    assert!(corps["itineraire"]["distance_m"].as_i64().unwrap() > 0);
    assert_eq!(
        corps["itineraire"]["degraded"],
        json!(true),
        "le bac n'a aucun routage : dégradé, et le simulateur le DIT"
    );
    assert!(corps["regle_retenue"]["regle_id"].is_string());
    assert_eq!(corps["composantes"]["base"], json!(450));
    assert!(corps["devis"]["prix_client"].as_i64().unwrap() >= 450);
    assert_eq!(corps["devis"]["devise"], json!("XOF"));
    assert_eq!(corps["drapeaux"]["livraison_offerte_mefali"], json!(false));

    // AUCUNE trace : ni événement (pas même `routage.degrade`, pourtant émis en
    // production sur ce chemin), ni bascule de la grille en vigueur.
    assert_eq!(
        bac.compter("SELECT count(*) FROM outbox.evenement").await,
        evenements_avant,
        "un dry run d'admin ne peuple pas les métriques"
    );
    assert!(bac.evenements("routage.degrade").await.is_empty());
    assert_eq!(bac.etat_grille(v1).await, "en_vigueur");
    assert_eq!(bac.etat_grille(v2).await, "brouillon");
}

/// Simuler une grille qui ne peut rien tarifer échoue — et, ce faisant, rend un
/// brouillon vide INPUBLIABLE (la garde de simulation ne peut être satisfaite).
#[sqlx::test(migrations = "../migrations")]
async fn brouillon_vide_inpubliable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);

    let simulation = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/simuler"),
        course_simulee()
    );
    assert_eq!(simulation.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let corps: Value = test::read_body_json(simulation).await;
    assert_eq!(corps["code"], json!("aucune_regle"));

    let publication = poster!(
        app,
        bac,
        format!("/admin/tarification/brouillon/{grille}/publier")
    );
    assert_eq!(publication.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(publication).await;
    assert_eq!(corps["code"], json!("simulation_requise"));
}

/// Simuler et publier sont fermés au rôle non-admin (FR-005).
#[sqlx::test(migrations = "../migrations")]
async fn simuler_et_publier_reserves_a_l_admin(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon_garni!(app, bac);

    for uri in [
        format!("/admin/tarification/brouillon/{grille}/simuler"),
        format!("/admin/tarification/brouillon/{grille}/publier"),
    ] {
        let client = test::call_service(
            &app,
            test::TestRequest::post()
                .uri(&uri)
                .insert_header(("authorization", format!("Bearer {}", bac.jeton_client)))
                .set_json(course_simulee())
                .to_request(),
        )
        .await;
        assert_eq!(client.status(), StatusCode::FORBIDDEN, "{uri}");

        let anonyme = test::call_service(
            &app,
            test::TestRequest::post()
                .uri(&uri)
                .set_json(course_simulee())
                .to_request(),
        )
        .await;
        assert_eq!(anonyme.status(), StatusCode::UNAUTHORIZED, "{uri}");
    }
    assert_eq!(bac.etat_grille(grille).await, "brouillon");
}
