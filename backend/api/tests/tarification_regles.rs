//! US1 (TRF-01) — modèle de règles à marge bornée, par la surface HTTP réelle.
//!
//! Ce qui est prouvé ici et nulle part ailleurs : la **garde de borne de marge**
//! rendue en `409` avec ses bornes, la **garde de devise**, le **rôle admin**
//! exigé (401/403), le **brouillon idempotent** cloné de la grille en vigueur,
//! la **provision point relais** structurellement inutilisable, et la
//! **sélection déterministe et rejouable** sur des règles relues en base.

mod bac;

use actix_web::{http::StatusCode, test, App};
use bac::{regle_moto, Bac, MARGE_MAX, MARGE_MIN};
use serde_json::{json, Value};
use sqlx::PgPool;
use tarification::regle::{selectionner, Criteres};
use uuid::Uuid;

/// Requête `PUT` d'une règle, authentifiée par le jeton fourni.
macro_rules! put_regle {
    ($app:expr, $jeton:expr, $grille:expr, $regle:expr, $corps:expr) => {
        test::call_service(
            &$app,
            test::TestRequest::put()
                .uri(&format!(
                    "/admin/tarification/brouillon/{}/regles/{}",
                    $grille, $regle
                ))
                .insert_header(("authorization", format!("Bearer {}", $jeton)))
                .set_json($corps)
                .to_request(),
        )
        .await
    };
}

/// Crée (ou rend) le brouillon d'une zone et rend son identifiant.
///
/// Macro et non fonction : le type d'un service Actix monté par `init_service`
/// n'est pas nommable sans traîner `actix_http` en dépendance directe.
macro_rules! brouillon {
    ($app:expr, $bac:expr) => {
        brouillon!($app, $bac, $bac.ville)
    };
    ($app:expr, $bac:expr, $zone:expr) => {{
        let reponse = test::call_service(
            &$app,
            test::TestRequest::post()
                .uri(&format!("/admin/tarification/zones/{}/brouillon", $zone))
                .insert_header(("authorization", format!("Bearer {}", $bac.jeton_admin)))
                .to_request(),
        )
        .await;
        assert_eq!(reponse.status(), StatusCode::OK);
        let corps: Value = test::read_body_json(reponse).await;
        corps["id"].as_str().unwrap().parse::<Uuid>().unwrap()
    }};
}

/// SC-001 — une marge hors bornes est REFUSÉE, avec les bornes dans le corps ;
/// les bornes elles-mêmes sont INCLUSES.
#[sqlx::test(migrations = "../migrations")]
async fn marge_hors_bornes_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);

    let reponse = put_regle!(app, bac.jeton_admin, grille, Uuid::now_v7(), regle_moto(110));
    assert_eq!(reponse.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("marge_hors_bornes"));
    assert_eq!(
        corps["message_cle"],
        json!("tarification.erreur.marge_hors_bornes"),
        "clé i18n fr, jamais un message en dur (FR-001)"
    );
    assert_eq!(corps["min"], json!(MARGE_MIN));
    assert_eq!(corps["max"], json!(MARGE_MAX));
    assert_eq!(corps["valeur"], json!(110));

    // Rien n'est entré en base : une règle hors bornes ne peut pas alimenter un
    // brouillon publiable (SC-001).
    assert_eq!(bac.compter("SELECT count(*) FROM tarification.regle").await, 0);

    // Les DEUX bornes sont incluses.
    for marge in [MARGE_MIN, MARGE_MAX] {
        let reponse = put_regle!(
            app,
            bac.jeton_admin,
            grille,
            Uuid::now_v7(),
            regle_moto(marge)
        );
        assert_eq!(reponse.status(), StatusCode::OK, "marge {marge} acceptée");
    }
    // La marge 0 du LANCEMENT ne vient JAMAIS d'une règle (research R4) : elle
    // est produite par le drapeau `gratuite_commissions` à l'évaluation.
    let reponse = put_regle!(app, bac.jeton_admin, grille, Uuid::now_v7(), regle_moto(0));
    assert_eq!(reponse.status(), StatusCode::CONFLICT, "marge 0 refusée en règle");
}

/// FR-023/FR-025 — une règle en devise étrangère est REJETÉE, jamais convertie.
#[sqlx::test(migrations = "../migrations")]
async fn devise_etrangere_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);

    let mut corps_regle = regle_moto(50);
    corps_regle["devise"] = json!("EUR");
    let reponse = put_regle!(app, bac.jeton_admin, grille, Uuid::now_v7(), corps_regle);
    assert_eq!(reponse.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("devise_incoherente"));
    assert_eq!(corps["attendue"], json!("XOF"));
    assert_eq!(corps["fournie"], json!("EUR"));
    assert_eq!(bac.compter("SELECT count(*) FROM tarification.regle").await, 0);
}

/// FR-005 — la surface d'administration est FERMÉE : 401 sans jeton, 403 pour
/// un compte sans le rôle admin.
#[sqlx::test(migrations = "../migrations")]
async fn role_admin_exige(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);

    let chemins = [
        format!("/admin/tarification/zones/{}/grille", bac.ville),
        format!("/admin/tarification/zones/{}/brouillon", bac.ville),
        format!(
            "/admin/tarification/brouillon/{grille}/regles/{}",
            Uuid::now_v7()
        ),
    ];
    for chemin in &chemins {
        // Sans jeton du tout.
        let anonyme = test::call_service(
            &app,
            test::TestRequest::get().uri(chemin).to_request(),
        )
        .await;
        assert!(
            matches!(
                anonyme.status(),
                StatusCode::UNAUTHORIZED | StatusCode::METHOD_NOT_ALLOWED | StatusCode::NOT_FOUND
            ),
            "{chemin} sans jeton → jamais 200 (obtenu {})",
            anonyme.status()
        );
    }

    // Un CLIENT authentifié : 403, pas 401 — le jeton est bon, le rôle non.
    let lecture = test::call_service(
        &app,
        test::TestRequest::get()
            .uri(&format!("/admin/tarification/zones/{}/grille", bac.ville))
            .insert_header(("authorization", format!("Bearer {}", bac.jeton_client)))
            .to_request(),
    )
    .await;
    assert_eq!(lecture.status(), StatusCode::FORBIDDEN);

    let ecriture = put_regle!(
        app,
        bac.jeton_client,
        grille,
        Uuid::now_v7(),
        regle_moto(50)
    );
    assert_eq!(ecriture.status(), StatusCode::FORBIDDEN);
    assert_eq!(bac.compter("SELECT count(*) FROM tarification.regle").await, 0);

    // Et sans jeton, l'écriture est un 401 franc.
    let anonyme = test::call_service(
        &app,
        test::TestRequest::put()
            .uri(&format!(
                "/admin/tarification/brouillon/{grille}/regles/{}",
                Uuid::now_v7()
            ))
            .set_json(regle_moto(50))
            .to_request(),
    )
    .await;
    assert_eq!(anonyme.status(), StatusCode::UNAUTHORIZED);
}

/// FR-012 — le brouillon est idempotent, il CLONE la grille en vigueur, et son
/// édition ne touche pas la tarification en cours.
#[sqlx::test(migrations = "../migrations")]
async fn brouillon_idempotent_et_clone(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;

    let premier = brouillon!(app, bac);
    let second = brouillon!(app, bac);
    assert_eq!(premier, second, "second appel → MÊME brouillon");
    assert_eq!(
        bac.compter("SELECT count(*) FROM tarification.grille").await,
        1,
        "aucune grille en double"
    );

    // Une règle dans le brouillon, puis on force la grille en vigueur (la
    // publication réelle arrive en US3) et on redemande un brouillon.
    put_regle!(app, bac.jeton_admin, premier, Uuid::now_v7(), regle_moto(50));
    sqlx::query("UPDATE tarification.grille SET etat = 'en_vigueur', effet_le = now() WHERE id = $1")
        .bind(premier)
        .execute(&bac.pool)
        .await
        .unwrap();

    let clone = brouillon!(app, bac);
    assert_ne!(clone, premier, "nouveau brouillon");
    let regles_clonees: i64 =
        sqlx::query_scalar("SELECT count(*) FROM tarification.regle WHERE grille_id = $1")
            .bind(clone)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(regles_clonees, 1, "le brouillon part du tarif RÉEL");

    // Éditer le brouillon ne change RIEN à la grille en vigueur (FR-012).
    let regle_du_clone: Uuid =
        sqlx::query_scalar("SELECT id FROM tarification.regle WHERE grille_id = $1")
            .bind(clone)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    let mut modifiee = regle_moto(100);
    modifiee["part_coursier_base"] = json!(999);
    put_regle!(app, bac.jeton_admin, clone, regle_du_clone, modifiee);
    let marge_en_vigueur: i64 =
        sqlx::query_scalar("SELECT marge FROM tarification.regle WHERE grille_id = $1")
            .bind(premier)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(marge_en_vigueur, 50, "la grille en vigueur est intacte");

    // Écrire DANS une grille en vigueur est refusé (409) : la tarification en
    // cours ne se modifie pas sous les pieds des clients.
    let refus = put_regle!(app, bac.jeton_admin, premier, Uuid::now_v7(), regle_moto(50));
    assert_eq!(refus.status(), StatusCode::CONFLICT);
    let corps: Value = test::read_body_json(refus).await;
    assert_eq!(corps["code"], json!("pas_un_brouillon"));
}

/// Constitution IX — la dimension **point relais** existe au modèle et reste
/// structurellement inutilisable : aucun champ d'API ne la porte, et la base
/// refuse de la renseigner.
#[sqlx::test(migrations = "../migrations")]
async fn point_relais_reste_une_provision(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);
    put_regle!(app, bac.jeton_admin, grille, Uuid::now_v7(), regle_moto(50));

    let renseignes: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM tarification.regle WHERE point_relais_id IS NOT NULL",
    )
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(renseignes, 0);

    // Même en SQL direct : le CHECK de la migration 0007 tient la provision.
    let force = sqlx::query("UPDATE tarification.regle SET point_relais_id = $1")
        .bind(Uuid::now_v7())
        .execute(&bac.pool)
        .await;
    assert!(force.is_err(), "le CHECK refuse de renseigner la provision");
}

/// FR-010 — la sélection est **déterministe et rejouable** sur des règles
/// relues en base : deux lectures successives rendent la MÊME règle.
#[sqlx::test(migrations = "../migrations")]
async fn selection_deterministe_et_rejouable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);

    // Trois règles moto qui matchent toutes une course de 3 km :
    //  - générale, priorité FORTE ;
    //  - tranche large, priorité nulle ;
    //  - catégorisée « restauration », priorité nulle → la plus SPÉCIFIQUE.
    let mut generale = regle_moto(50);
    generale["priorite"] = json!(100);
    let mut large = regle_moto(50);
    large["distance_max_m"] = json!(20_000);
    let mut categorisee = regle_moto(50);
    categorisee["categorie_slug"] = json!("restauration");
    categorisee["distance_max_m"] = json!(20_000);

    let id_categorisee = Uuid::now_v7();
    for (id, corps) in [
        (Uuid::now_v7(), generale),
        (Uuid::now_v7(), large),
        (id_categorisee, categorisee),
    ] {
        let r = put_regle!(app, bac.jeton_admin, grille, id, corps);
        assert_eq!(r.status(), StatusCode::OK);
    }

    let criteres = |instant: &str| Criteres {
        transport_slug: "moto",
        categorie_slug: Some("restauration"),
        distance_m: 3_000,
        instant: instant.parse().unwrap(),
        fuseau: chrono_tz::Africa::Abidjan,
    };

    let premiere = bac.tarification.grille(grille).await.unwrap();
    let choix_un = selectionner(&premiere.regles, &criteres("2026-07-22T19:30:00Z"))
        .expect("une règle applicable");
    assert_eq!(
        choix_un.id, id_categorisee,
        "la plus SPÉCIFIQUE gagne, même face à une priorité 100"
    );

    // Rejeu : relecture indépendante, mêmes entrées → même règle (SC-009 pour
    // la sélection ; un devis doit être reproductible à l'identique).
    let seconde = bac.tarification.grille(grille).await.unwrap();
    let choix_deux = selectionner(&seconde.regles, &criteres("2026-07-22T19:30:00Z")).unwrap();
    assert_eq!(choix_un.id, choix_deux.id, "sélection rejouable");

    // Une course SANS catégorie ne peut pas capter la règle catégorisée : c'est
    // alors la tranche la plus étroite qui l'emporte sur la générale ouverte.
    let mut sans_categorie = criteres("2026-07-22T19:30:00Z");
    sans_categorie.categorie_slug = None;
    let choix_trois = selectionner(&seconde.regles, &sans_categorie).unwrap();
    assert_ne!(choix_trois.id, id_categorisee);
    assert_eq!(choix_trois.distance_max_m, Some(20_000), "tranche bornée");
}

/// Une règle d'une AUTRE grille n'est pas déplacée en silence : 404.
#[sqlx::test(migrations = "../migrations")]
async fn regle_d_une_autre_grille_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);

    let regle = Uuid::now_v7();
    assert_eq!(
        put_regle!(app, bac.jeton_admin, grille, regle, regle_moto(50)).status(),
        StatusCode::OK
    );

    // Un autre brouillon, sur une autre zone.
    let autre_zone = {
        let z = zones::PgZones::new(bac.pool.clone());
        let mut tx = bac.pool.begin().await.unwrap();
        let zone = z
            .creer_zone(&mut tx, Some(bac.pays), zones::TypeZone::Ville, "Sikensi")
            .await
            .unwrap()
            .id;
        tx.commit().await.unwrap();
        zone
    };
    let reponse = test::call_service(
        &app,
        test::TestRequest::post()
            .uri(&format!("/admin/tarification/zones/{autre_zone}/brouillon"))
            .insert_header(("authorization", format!("Bearer {}", bac.jeton_admin)))
            .to_request(),
    )
    .await;
    let corps: Value = test::read_body_json(reponse).await;
    let autre_grille: Uuid = corps["id"].as_str().unwrap().parse().unwrap();

    let reponse = put_regle!(app, bac.jeton_admin, autre_grille, regle, regle_moto(50));
    assert_eq!(reponse.status(), StatusCode::NOT_FOUND);
    let corps: Value = test::read_body_json(reponse).await;
    assert_eq!(corps["code"], json!("regle_inconnue"));
}

/// Éditer un brouillon n'écrit AUCUN événement outbox : le brouillon n'a aucun
/// effet tarifaire, ce n'est pas une transition (research R10).
#[sqlx::test(migrations = "../migrations")]
async fn edition_de_brouillon_muette(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = test::init_service(App::new().configure(bac.configurer())).await;
    let grille = brouillon!(app, bac);
    let regle = Uuid::now_v7();
    put_regle!(app, bac.jeton_admin, grille, regle, regle_moto(50));
    put_regle!(app, bac.jeton_admin, grille, regle, regle_moto(60));
    test::call_service(
        &app,
        test::TestRequest::delete()
            .uri(&format!(
                "/admin/tarification/brouillon/{grille}/regles/{regle}"
            ))
            .insert_header(("authorization", format!("Bearer {}", bac.jeton_admin)))
            .to_request(),
    )
    .await;

    let evenements: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement LIKE 'grille.%'
            OR type_evenement LIKE 'routage.%' OR type_evenement LIKE 'effort.%'",
    )
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(evenements, 0);
}
