//! US5 (CMD-10) — attendre un coursier sans rester dans le noir.
//!
//! La promesse produit est simple : **aucune commande n'est perdue faute de
//! coursier**. Elle se prouve en quatre points — la mise en attente est un état
//! ANNONCÉ, la file est FIFO par âge, la reprise est automatique et identique
//! au chemin nominal, et l'attente trop longue est escaladée une fois.
//!
//! Le dispatch n'existe pas encore : `AffectationSimulee` porte la décision
//! « quel coursier » et délègue l'écriture au vrai dépôt (research R16). Vider
//! son vivier, c'est exactement le cas « aucun coursier éligible ».

mod bac_commandes;

use actix_web::{test as atest, App};
use bac_commandes::Bac;
use commandes::{AffectationSimulee, CommandesADispatcher};
use serde_json::Value;
use uuid::Uuid;

/// `GET /admin/commandes/attente` — la file telle que DSP la lira.
async fn file_admin(bac: &Bac, jeton: &str) -> (u16, Value) {
    let app = atest::init_service(App::new().configure(bac.configurer())).await;
    let req = atest::TestRequest::get()
        .uri(&format!("/admin/commandes/attente?zone_id={}", bac.ville))
        .insert_header(("authorization", format!("Bearer {jeton}")))
        .to_request();
    let resp = atest::call_service(&app, req).await;
    let statut = resp.status().as_u16();
    (statut, atest::read_body_json(resp).await)
}

/// Vieillit artificiellement une commande — l'âge est le seul critère de la
/// file, et on ne peut pas attendre 5 minutes dans un test.
async fn vieillir(bac: &Bac, commande: Uuid, secondes: i64) {
    sqlx::query(
        "UPDATE commandes.commande SET cree_le = now() - make_interval(secs => $2) WHERE id = $1",
    )
    .bind(commande)
    .bind(secondes as f64)
    .execute(&bac.pool)
    .await
    .unwrap();
}

/// Aucun coursier éligible → état d'attente ANNONCÉ, avec son événement.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_coursier_eligible_met_en_attente(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let lignes: Vec<Value> = bac.vendeurs.iter().map(|v| v.ligne(1)).collect();
    let commande = bac.creer_commande_api("marche", lignes).await;

    // Le vivier de la zone est VIDE : c'est le cas « aucun coursier éligible ».
    let dispatch = AffectationSimulee::nouveau();
    let affecte = dispatch
        .affecter_via(&bac.commandes, bac.ville, commande)
        .await
        .unwrap();
    assert!(affecte.is_none(), "aucun coursier dans le vivier");

    bac.commandes
        .mettre_en_attente_coursier(commande, chrono::Utc::now())
        .await
        .unwrap();

    assert_eq!(bac.etat_commande(commande).await, "en_attente_coursier");
    assert_eq!(
        bac.nb_evenements("commande.mise_en_attente_coursier").await,
        1
    );
    let payload = &bac.evenements("commande.mise_en_attente_coursier").await[0];
    assert_eq!(payload["motif"], "aucun_coursier_eligible");
    assert_eq!(payload["zone"], bac.ville.to_string());
}

/// **Ordre FIFO** sur trois commandes d'âges différents : la plus ancienne
/// d'abord, quels que soient le montant et le nombre d'arrêts.
#[sqlx::test(migrations = "../migrations")]
async fn file_fifo_par_age(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    // Trois commandes, créées dans l'ordre 0, 1, 2 puis vieillies à l'envers :
    // c'est l'ÂGE qui doit trancher, pas l'ordre d'insertion ni l'identifiant.
    let mut commandes = Vec::new();
    for v in &bac.vendeurs {
        commandes.push(bac.creer_commande_api("marche", vec![v.ligne(1)]).await);
    }
    vieillir(&bac, commandes[0], 30).await;
    vieillir(&bac, commandes[1], 300).await;
    vieillir(&bac, commandes[2], 120).await;

    for c in &commandes {
        bac.commandes
            .mettre_en_attente_coursier(*c, chrono::Utc::now())
            .await
            .unwrap();
    }

    let file = bac.commandes.en_attente_coursier(bac.ville).await.unwrap();
    let ordre: Vec<Uuid> = file.iter().map(|c| c.commande_id).collect();
    assert_eq!(
        ordre,
        vec![commandes[1], commandes[2], commandes[0]],
        "la plus ANCIENNE d'abord — 300 s, puis 120 s, puis 30 s",
    );
    assert!(file[0].age_s >= 300);

    // Le contrat porte de quoi décider de l'éligibilité, et rien de plus.
    assert_eq!(file[0].nb_collectes, 1);
    assert!(file[0].montant_a_avancer > 0);
    assert_eq!(file[0].devise, "XOF");
    assert!(file[0].premiere_collecte_lat.is_some());

    // La même file, servie par l'endpoint admin.
    let (statut, corps) = file_admin(&bac, &bac.jeton_admin).await;
    assert_eq!(statut, 200, "{corps}");
    let servis: Vec<String> = corps["commandes"]
        .as_array()
        .unwrap()
        .iter()
        .map(|c| c["commande_id"].as_str().unwrap().to_owned())
        .collect();
    assert_eq!(
        servis,
        ordre.iter().map(|u| u.to_string()).collect::<Vec<_>>(),
        "l'endpoint sert exactement l'ordre du domaine",
    );
}

/// La reprise est **automatique** et emprunte le MÊME chemin qu'une commande
/// neuve : c'est la table de transitions qui autorise les deux origines.
#[sqlx::test(migrations = "../migrations")]
async fn reprise_automatique_de_la_plus_ancienne(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let mut commandes = Vec::new();
    for v in &bac.vendeurs {
        commandes.push(bac.creer_commande_api("marche", vec![v.ligne(1)]).await);
    }
    vieillir(&bac, commandes[0], 60).await;
    vieillir(&bac, commandes[1], 600).await;
    vieillir(&bac, commandes[2], 200).await;
    for c in &commandes {
        bac.commandes
            .mettre_en_attente_coursier(*c, chrono::Utc::now())
            .await
            .unwrap();
    }

    // Un coursier redevient éligible.
    let dispatch = AffectationSimulee::nouveau();
    dispatch.ajouter_coursier(bac.ville, bac.coursier);

    let plus_ancienne = bac.commandes.en_attente_coursier(bac.ville).await.unwrap()[0].commande_id;
    assert_eq!(plus_ancienne, commandes[1]);
    let affecte = dispatch
        .affecter_via(&bac.commandes, bac.ville, plus_ancienne)
        .await
        .unwrap();
    assert_eq!(affecte, Some(bac.coursier));

    assert_eq!(bac.etat_commande(commandes[1]).await, "en_cours");
    assert_eq!(
        bac.commandes
            .en_attente_coursier(bac.ville)
            .await
            .unwrap()
            .len(),
        2,
        "les deux autres restent en file",
    );

    // L'événement d'affectation dit qu'il s'agit d'une REPRISE.
    let payload = &bac.evenements("commande.assignee").await[0];
    assert_eq!(payload["depuis_attente"], true);
    assert_eq!(bac.nb_evenements("livraison.affectee").await, 1);
}

/// Annulation **sans frais** depuis l'attente (maquette C4-4b) : la transition
/// `en_attente_coursier → annulee` est ouverte au client par la table.
#[sqlx::test(migrations = "../migrations")]
async fn annulation_sans_frais_depuis_l_attente(pool: sqlx::PgPool) {
    use commandes::{transition_existe, verifier_transition, Acteur, Niveau};

    let bac = Bac::nouveau(pool).await;
    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(1)])
        .await;
    bac.commandes
        .mettre_en_attente_coursier(commande, chrono::Utc::now())
        .await
        .unwrap();

    // Le client peut annuler, le coursier non : la sortie de file est une
    // décision du client (ou de l'admin), jamais de qui exécute.
    assert!(transition_existe(
        Niveau::Commande,
        Some("en_attente_coursier"),
        "annulee"
    ));
    verifier_transition(
        Niveau::Commande,
        Some("en_attente_coursier"),
        "annulee",
        Acteur::Client,
    )
    .expect("annulation sans frais depuis l'attente");
    assert!(verifier_transition(
        Niveau::Commande,
        Some("en_attente_coursier"),
        "annulee",
        Acteur::Coursier,
    )
    .is_err());

    // Aucun arrêt n'a été collecté : rien n'a été acheté, donc rien n'est dû.
    let collectes: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM commandes.arret a
         JOIN commandes.segment s ON s.id = a.segment_id
         JOIN commandes.livraison l ON l.id = s.livraison_id
         WHERE l.commande_id = $1 AND a.statut = 'collecte'",
    )
    .bind(commande)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(collectes, 0, "annulation SANS FRAIS : rien n'a été acheté");
}

/// L'escalade au franchissement du seuil de zone — **une seule fois** par
/// commande, sans quoi le balayage périodique noierait l'alerte.
#[sqlx::test(migrations = "../migrations")]
async fn escalade_au_seuil_et_une_seule_fois(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let jeune = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(1)])
        .await;
    let vieille = bac
        .creer_commande_api("marche", vec![bac.vendeurs[1].ligne(1)])
        .await;
    // Seuil du bac : `commande.escalade_attente_coursier_s` = 300 s.
    vieillir(&bac, jeune, 100).await;
    vieillir(&bac, vieille, 400).await;
    for c in [jeune, vieille] {
        bac.commandes
            .mettre_en_attente_coursier(c, chrono::Utc::now())
            .await
            .unwrap();
    }

    let escaladees = bac
        .commandes
        .escalader_attentes(bac.ville, chrono::Utc::now())
        .await
        .unwrap();
    assert_eq!(
        escaladees,
        vec![vieille],
        "seule celle qui a franchi le seuil"
    );

    let payload = &bac.evenements("commande.attente_coursier_escaladee").await[0];
    assert_eq!(payload["seuil_s"], 300);
    assert!(payload["age_s"].as_i64().unwrap() >= 400);

    // Second balayage : rien de neuf, aucun second événement.
    let encore = bac
        .commandes
        .escalader_attentes(bac.ville, chrono::Utc::now())
        .await
        .unwrap();
    assert!(encore.is_empty(), "l'escalade ne se répète pas");
    assert_eq!(
        bac.nb_evenements("commande.attente_coursier_escaladee")
            .await,
        1
    );
}

/// La file est réservée à l'admin — et une commande déjà prise en charge n'y
/// figure pas.
#[sqlx::test(migrations = "../migrations")]
async fn file_reservee_a_l_admin_et_ne_liste_que_l_attente(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    assert_eq!(bac.etat_commande(course.commande).await, "en_cours");

    let (statut, _) = file_admin(&bac, &bac.jeton_client).await;
    assert_eq!(statut, 403, "rôle admin requis");

    let (statut, corps) = file_admin(&bac, &bac.jeton_admin).await;
    assert_eq!(statut, 200);
    assert!(
        corps["commandes"].as_array().unwrap().is_empty(),
        "une commande assignée n'attend plus personne",
    );
}
