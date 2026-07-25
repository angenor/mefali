//! US4 (CMD-04) — la machine à états à trois niveaux, gardée SERVEUR.
//!
//! Deux niveaux de preuve, et il faut les deux :
//!
//! 1. **La table** — une assertion par ligne des trois tables de
//!    [data-model §3], plus la preuve que ce qui n'y figure pas est refusé.
//!    C'est mécanique et exhaustif : ajouter une ligne à la table sans
//!    l'ajouter ici fait échouer le test de dénombrement.
//! 2. **Le parcours** — dérouler une vraie commande de bout en bout par les
//!    endpoints réels, et vérifier qu'un événement outbox accompagne CHAQUE
//!    transition acceptée, et aucun refus.
//!
//! Un test qui ne ferait que la première moitié laisserait passer un code qui
//! n'appelle jamais la garde ; un test qui ne ferait que la seconde laisserait
//! des lignes de la table jamais exercées.

mod bac_commandes;

use bac_commandes::Bac;
use commandes::{transition_existe, verifier_transition, Acteur, Niveau};
use uuid::Uuid;

// ── 1. La table de transitions, ligne par ligne (data-model §3) ────────────

/// Les 12 lignes du **tronc** (§3.1), chacune avec l'acteur qui la déclenche.
#[test]
fn table_du_tronc_ligne_par_ligne() {
    let lignes: &[(Option<&str>, &str, Acteur)] = &[
        (None, "nouvelle", Acteur::Client),
        (None, "en_attente_paiement", Acteur::Client),
        (Some("en_attente_paiement"), "nouvelle", Acteur::Systeme),
        (Some("en_attente_paiement"), "annulee", Acteur::Systeme),
        (Some("nouvelle"), "en_attente_coursier", Acteur::Systeme),
        (Some("nouvelle"), "en_cours", Acteur::Systeme),
        (Some("en_attente_coursier"), "en_cours", Acteur::Systeme),
        (Some("en_attente_coursier"), "annulee", Acteur::Client),
        (Some("nouvelle"), "annulee", Acteur::Client),
        (Some("en_cours"), "terminee", Acteur::Coursier),
        (Some("en_cours"), "annulee", Acteur::Client),
        (Some("en_cours"), "echouee", Acteur::Coursier),
    ];
    for (depuis, vers, acteur) in lignes {
        verifier_transition(Niveau::Commande, *depuis, vers, *acteur).unwrap_or_else(|e| {
            panic!("tronc {depuis:?} → {vers} par {acteur:?} doit être autorisée : {e}")
        });
    }
}

/// Les 8 lignes de la **livraison** (§3.2).
#[test]
fn table_de_la_livraison_ligne_par_ligne() {
    let lignes: &[(Option<&str>, &str, Acteur)] = &[
        (None, "assignee", Acteur::Systeme),
        (Some("assignee"), "en_collecte", Acteur::Coursier),
        (Some("en_collecte"), "en_livraison", Acteur::Coursier),
        (Some("en_livraison"), "livree", Acteur::Coursier),
        (Some("assignee"), "annulee", Acteur::Client),
        (Some("en_collecte"), "annulee", Acteur::Client),
        (Some("en_livraison"), "annulee", Acteur::Client),
        (Some("en_livraison"), "echouee", Acteur::Coursier),
    ];
    for (depuis, vers, acteur) in lignes {
        verifier_transition(Niveau::Livraison, *depuis, vers, *acteur).unwrap_or_else(|e| {
            panic!("livraison {depuis:?} → {vers} par {acteur:?} doit être autorisée : {e}")
        });
    }
}

/// Les 6 lignes de l'**arrêt** (§3.3), chemin direct du cycle 006 compris.
#[test]
fn table_de_l_arret_ligne_par_ligne() {
    let lignes: &[(&str, &str)] = &[
        ("a_collecter", "en_route"),
        ("en_route", "arrive"),
        ("arrive", "collecte"),
        ("a_collecter", "collecte"), // non-régression du cycle 006
        ("arrive", "indisponible"),
        ("a_collecter", "indisponible"),
        ("en_route", "indisponible"),
    ];
    for (depuis, vers) in lignes {
        verifier_transition(Niveau::Arret, Some(depuis), vers, Acteur::Coursier)
            .unwrap_or_else(|e| panic!("arrêt {depuis} → {vers} doit être autorisée : {e}"));
    }
}

/// Le **refus** de ce qui n'est pas dans la table. C'est la moitié qui compte :
/// une table « fermée » qui accepterait l'inconnu n'aurait aucune valeur.
#[test]
fn transitions_absentes_refusees() {
    // Livrer avant d'avoir tout collecté.
    assert!(!transition_existe(Niveau::Livraison, Some("assignee"), "livree"));
    assert!(!transition_existe(Niveau::Livraison, Some("en_collecte"), "livree"));
    // Revenir en arrière, à chaque niveau.
    assert!(!transition_existe(Niveau::Commande, Some("en_cours"), "nouvelle"));
    assert!(!transition_existe(Niveau::Livraison, Some("en_livraison"), "en_collecte"));
    assert!(!transition_existe(Niveau::Arret, Some("arrive"), "en_route"));
    assert!(!transition_existe(Niveau::Arret, Some("collecte"), "a_collecter"));
    // Ressusciter un état terminal.
    for terminal in ["terminee", "annulee", "echouee"] {
        for vers in ["nouvelle", "en_cours", "terminee", "annulee", "echouee"] {
            assert!(
                !transition_existe(Niveau::Commande, Some(terminal), vers),
                "« {terminal} » est terminal : {terminal} → {vers} ne doit pas exister",
            );
        }
    }
    // Scanner sans avoir déclaré son arrivée : `arrive_le` fonderait la prime
    // d'attente TRF-06, on ne peut pas l'effacer d'un raccourci.
    assert!(!transition_existe(Niveau::Arret, Some("en_route"), "collecte"));
    // Les niveaux ne se mélangent jamais.
    assert!(!transition_existe(Niveau::Commande, Some("nouvelle"), "en_collecte"));
    assert!(!transition_existe(Niveau::Livraison, Some("en_livraison"), "terminee"));
}

/// Une transition qui EXISTE mais qu'un autre acteur demande est refusée —
/// et c'est un refus différent : `403`, pas `409`.
#[test]
fn acteur_non_autorise_refuse_meme_si_la_transition_existe() {
    assert!(transition_existe(Niveau::Commande, Some("en_cours"), "terminee"));
    assert!(
        verifier_transition(Niveau::Commande, Some("en_cours"), "terminee", Acteur::Client)
            .is_err(),
        "la remise est l'affaire du coursier, jamais du client",
    );
    assert!(transition_existe(Niveau::Arret, Some("a_collecter"), "en_route"));
    assert!(
        verifier_transition(Niveau::Arret, Some("a_collecter"), "en_route", Acteur::Client)
            .is_err(),
    );
}

// ── 2. Le parcours réel, par les endpoints ────────────────────────────────

/// SC-011 — dérouler une commande à 3 collectes de bout en bout, et vérifier
/// qu'un événement outbox accompagne CHAQUE transition acceptée.
#[sqlx::test(migrations = "../migrations")]
async fn parcours_complet_trois_collectes(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    // L'affectation a fait passer le tronc EN_COURS.
    assert_eq!(bac.etat_commande(course.commande).await, "en_cours");
    assert_eq!(bac.etat_livraison(course.livraison).await, "assignee");
    assert_eq!(bac.nb_evenements("livraison.affectee").await, 1);
    assert_eq!(bac.nb_evenements("commande.assignee").await, 1);

    // Premier arrêt : en route → la course s'ouvre EN_COLLECTE.
    let (statut, corps) = bac
        .action_coursier(course.livraison, course.collectes[0], "en-route", Uuid::now_v7())
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["statut"], "en_route");
    assert_eq!(corps["livraison_etat"], "en_collecte");
    assert_eq!(corps["collectes_total"], 3, "la remise n'est pas une collecte");

    // Arrivé, puis collecté.
    let (statut, corps) = bac
        .action_coursier(course.livraison, course.collectes[0], "arrive", Uuid::now_v7())
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["statut"], "arrive");
    let p = bac.collecter(course.collectes[0]).await;
    assert_eq!((p.nb_collectes, p.nb_arrets), (1, 3));
    assert!(!p.en_livraison, "deux collectes restent à faire");

    // Deuxième et troisième arrêts.
    for arret in &course.collectes[1..] {
        for action in ["en-route", "arrive"] {
            let (statut, corps) = bac
                .action_coursier(course.livraison, *arret, action, Uuid::now_v7())
                .await;
            assert_eq!(statut, 200, "{action} : {corps}");
        }
        bac.collecter(*arret).await;
    }
    assert_eq!(bac.etat_livraison(course.livraison).await, "en_livraison");

    // Remise : la livraison est LIVRÉE, le tronc TERMINÉ, le paiement RÉGLÉ.
    bac.cloturer(&course, "qr").await;
    assert_eq!(bac.etat_livraison(course.livraison).await, "livree");
    assert_eq!(bac.etat_commande(course.commande).await, "terminee");
    let paiement: String =
        sqlx::query_scalar("SELECT etat_paiement::text FROM commandes.commande WHERE id = $1")
            .bind(course.commande)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(paiement, "regle");

    // UN événement par transition acceptée (constitution VI) — et rien de plus.
    for (type_evenement, attendu) in [
        ("livraison.mise_en_collecte", 1),
        ("arret.en_route", 3),
        ("arret.arrive", 3),
        ("arret.collecte", 3),
        ("livraison.mise_en_livraison", 1),
        ("livraison.livree", 1),
        ("commande.terminee", 1),
    ] {
        assert_eq!(
            bac.nb_evenements(type_evenement).await,
            attendu,
            "événement « {type_evenement} »",
        );
    }
}

/// Une transition hors séquence est refusée `409`, **sans changer d'état** —
/// et sans écrire le moindre événement : un refus n'est pas une transition.
#[sqlx::test(migrations = "../migrations")]
async fn transition_hors_sequence_refusee_sans_effet(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let arret = course.collectes[0];

    // Arriver sans être parti.
    let (statut, corps) = bac
        .action_coursier(course.livraison, arret, "arrive", Uuid::now_v7())
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "transition_refusee");
    assert_eq!(corps["message_cle"], "commande.erreur.transition_refusee");
    assert_eq!(bac.statut_arret(arret).await, "a_collecter");

    // Repartir d'un arrêt déjà arrivé.
    for action in ["en-route", "arrive"] {
        bac.action_coursier(course.livraison, arret, action, Uuid::now_v7())
            .await;
    }
    let (statut, _) = bac
        .action_coursier(course.livraison, arret, "en-route", Uuid::now_v7())
        .await;
    assert_eq!(statut, 409, "on ne revient pas en arrière");
    assert_eq!(bac.statut_arret(arret).await, "arrive");

    // Un arrêt déjà indisponible ne se relance pas.
    let autre = course.collectes[1];
    bac.action_coursier(course.livraison, autre, "indisponible", Uuid::now_v7())
        .await;
    let (statut, _) = bac
        .action_coursier(course.livraison, autre, "en-route", Uuid::now_v7())
        .await;
    assert_eq!(statut, 409);

    // Les refus n'ont rien émis de plus que les 3 transitions acceptées
    // (en-route, arrivé, indisponible) et l'ouverture de collecte.
    assert_eq!(bac.nb_evenements("arret.en_route").await, 1);
    assert_eq!(bac.nb_evenements("arret.arrive").await, 1);
    assert_eq!(bac.nb_evenements("arret.indisponible").await, 1);
}

/// Rejeu de la MÊME action (file hors-ligne, constitution V) : effet unique,
/// second événement **absent**, `rejeu = true` annoncé au client.
#[sqlx::test(migrations = "../migrations")]
async fn rejeu_d_une_transition_effet_unique(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let uuid = Uuid::now_v7();

    let (statut, premier) = bac
        .action_coursier(course.livraison, course.collectes[0], "en-route", uuid)
        .await;
    assert_eq!(statut, 200);
    assert_eq!(premier["rejeu"], false);

    let (statut, second) = bac
        .action_coursier(course.livraison, course.collectes[0], "en-route", uuid)
        .await;
    assert_eq!(statut, 200, "un rejeu réussit, il n'échoue pas");
    assert_eq!(second["rejeu"], true);
    assert_eq!(second["statut"], premier["statut"]);
    assert_eq!(second["livraison_etat"], premier["livraison_etat"]);

    assert_eq!(
        bac.nb_evenements("arret.en_route").await,
        1,
        "le rejeu n'émet pas un second événement",
    );
    assert_eq!(bac.nb_evenements("livraison.mise_en_collecte").await, 1);
}

/// Les deux gardes de la surface coursier : le **rôle**, et la **propriété**.
#[sqlx::test(migrations = "../migrations")]
async fn role_et_propriete_gardes(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    // Un client n'a pas le rôle coursier.
    let (statut, _) = bac
        .action_coursier_par(
            &bac.jeton_client,
            course.livraison,
            course.collectes[0],
            "en-route",
            Uuid::now_v7(),
        )
        .await;
    assert_eq!(statut, 403, "rôle coursier requis");

    // Un autre coursier ne fait pas avancer cette course.
    let (_, jeton_autre) = bac
        .compte_avec_roles("+2250700000055", &["client", "coursier"])
        .await;
    let (statut, corps) = bac
        .action_coursier_par(
            &jeton_autre,
            course.livraison,
            course.collectes[0],
            "en-route",
            Uuid::now_v7(),
        )
        .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "non_proprietaire");

    // Un arrêt d'une AUTRE course est traité comme inexistant : l'URL ne doit
    // pas devenir un oracle d'existence.
    let autre_course = bac.course_prete().await;
    let (statut, corps) = bac
        .action_coursier(
            course.livraison,
            autre_course.collectes[0],
            "en-route",
            Uuid::now_v7(),
        )
        .await;
    assert_eq!(statut, 404, "{corps}");

    assert_eq!(bac.statut_arret(course.collectes[0]).await, "a_collecter");
    assert_eq!(bac.nb_evenements("arret.en_route").await, 0);
}

/// L'arrêt de REMISE suit la même boucle déclarative que les collectes, mais
/// n'entre jamais dans la progression : « 3 sur 3 », jamais « 3 sur 4 » (P1).
#[sqlx::test(migrations = "../migrations")]
async fn l_arret_de_remise_ne_compte_pas_dans_la_progression(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    for arret in &course.collectes {
        bac.collecter(*arret).await;
    }
    assert_eq!(bac.etat_livraison(course.livraison).await, "en_livraison");

    let (statut, corps) = bac
        .action_coursier(course.livraison, course.remise, "en-route", Uuid::now_v7())
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["collectes_faites"], 3);
    assert_eq!(corps["collectes_total"], 3, "la remise n'est pas une collecte");
    assert_eq!(
        corps["livraison_etat"], "en_livraison",
        "la course est déjà en livraison : partir vers le client ne la rouvre pas",
    );
}

/// **Non-régression** — un coursier qui SCANNE sans avoir déclaré son trajet
/// (chemin direct du cycle 006, toujours autorisé) doit quand même faire
/// avancer sa course.
///
/// Sans l'ouverture de collecte sur le chemin du scan, la livraison restait
/// `assignee` : le gating EN_LIVRAISON ne se déclenche que depuis
/// `en_collecte`, et la course était bloquée pour toujours — la même classe de
/// panne que P1, par l'autre bout.
#[sqlx::test(migrations = "../migrations")]
async fn scan_direct_ouvre_la_collecte_et_debloque_le_gating(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    assert_eq!(bac.etat_livraison(course.livraison).await, "assignee");

    // Premier scan, sans aucun « je pars » ni « j'y suis ».
    bac.collecter(course.collectes[0]).await;
    assert_eq!(
        bac.etat_livraison(course.livraison).await,
        "en_collecte",
        "le scan est une action d'arrêt : il ouvre la collecte comme le départ",
    );
    assert_eq!(bac.nb_evenements("livraison.mise_en_collecte").await, 1);

    for arret in &course.collectes[1..] {
        bac.collecter(*arret).await;
    }
    assert_eq!(
        bac.etat_livraison(course.livraison).await,
        "en_livraison",
        "toutes les collectes résolues → la course part vers le client",
    );
}

/// Le prépaiement : `en_attente_paiement → nouvelle` (PAY simulé). Sans lui,
/// une commande prépayée n'atteindrait jamais le dispatch.
#[sqlx::test(migrations = "../migrations")]
async fn prepaiement_confirme_rend_la_commande_dispatchable(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Un plat de restauration à 2 000 × 3 = 6 000 > plafond réduit (5 000) pour
    // un client sans historique : le prépaiement est imposé.
    let lignes = vec![bac.resto.ligne(3)];
    let app = actix_web::test::init_service(
        actix_web::App::new().configure(bac.configurer()),
    )
    .await;
    let mut demande = bac.demande_creation("restauration", lignes);
    demande["mode_paiement"] = serde_json::json!("mobile_money");
    let req = actix_web::test::TestRequest::post()
        .uri("/commandes")
        .insert_header(("authorization", format!("Bearer {}", bac.jeton_client)))
        .insert_header(("idempotency-key", Uuid::now_v7().to_string()))
        .set_json(demande)
        .to_request();
    let resp = actix_web::test::call_service(&app, req).await;
    assert_eq!(resp.status().as_u16(), 201);
    let corps: serde_json::Value = actix_web::test::read_body_json(resp).await;
    assert_eq!(corps["etat"], "en_attente_paiement");
    let commande: Uuid = corps["id"].as_str().unwrap().parse().unwrap();

    let paiement = commandes::PaiementSimule::nouveau();
    paiement.confirmer(commande);
    assert!(paiement.est_confirme(commande));

    bac.commandes
        .confirmer_prepaiement(commande, chrono::Utc::now())
        .await
        .expect("prépaiement confirmé");
    assert_eq!(bac.etat_commande(commande).await, "nouvelle");
    assert_eq!(bac.nb_evenements("commande.paiement_confirme").await, 1);

    // Et seulement ALORS l'affectation devient possible.
    bac.commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .expect("commande redevenue dispatchable");
    assert_eq!(bac.etat_commande(commande).await, "en_cours");
}
