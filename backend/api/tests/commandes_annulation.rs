//! US8 (CMD-07) — annuler proprement, sans que personne ne perde.
//!
//! La frontière est **un fait, pas un délai** : tant qu'aucun arrêt n'a été
//! collecté, personne n'a avancé d'argent — il n'y a rien à facturer. Dès le
//! premier achat, la part du coursier est due, quel que soit celui qui annule.
//!
//! Choisir un fait plutôt qu'un chronomètre évite la seule discussion qui
//! n'aurait pas de réponse : « il était où à 14 h 32 ? ». La base sait ce qui a
//! été collecté ; elle ne saura jamais arbitrer une minute.

mod bac_commandes;

use bac_commandes::{Bac, DEVIS_PART_COURSIER};
use commandes::CommandesADispatcher;
use serde_json::json;

/// **FR-052** — annulation SANS FRAIS tant que rien n'a été acheté.
#[sqlx::test(migrations = "../migrations")]
async fn sans_frais_avant_toute_collecte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac
        .post(
            &format!("/commandes/{}/annuler", course.commande),
            &bac.jeton_client,
            json!({}),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["sans_frais"], true);
    assert_eq!(corps["part_coursier_due"], 0);
    assert_eq!(corps["montant_avance"], 0);

    assert_eq!(bac.etat_commande(course.commande).await, "annulee");
    // La livraison suit le tronc : laisser une course `assignee` sous une
    // commande annulée laisserait un fantôme dans l'app du coursier.
    assert_eq!(bac.etat_livraison(course.livraison).await, "annulee");

    let evenements = bac.evenements("commande.annulee").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["par"], "client");
    assert_eq!(evenements[0]["sans_frais"], true);
    assert_eq!(evenements[0]["part_coursier_due"], 0);
    assert_eq!(
        bac.nb_evenements("indemnisation.due").await,
        0,
        "rien n'a été acheté : personne n'a rien à se faire rembourser",
    );
}

/// **CMD-08** — après une collecte, la part du coursier est DUE : il a payé de
/// sa poche chez un vendeur, et « le coursier ne perd jamais ».
#[sqlx::test(migrations = "../migrations")]
async fn apres_collecte_la_part_coursier_est_due(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter(course.collectes[0]).await;

    let (statut, corps) = bac
        .post(
            &format!("/commandes/{}/annuler", course.commande),
            &bac.jeton_client,
            json!({}),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["sans_frais"], false);
    assert_eq!(
        corps["part_coursier_due"], DEVIS_PART_COURSIER,
        "la part due est celle du devis FIGÉ, jamais un recalcul",
    );
    assert!(
        corps["montant_avance"].as_i64().unwrap() > 0,
        "le coursier a bien avancé de l'argent chez le vendeur",
    );

    // L'indemnisation emprunte le MÊME contrat que l'arbre §7.5 : CRS-06
    // n'aura qu'un seul consommateur à écrire, pas deux.
    let indemnisations = bac.evenements("indemnisation.due").await;
    assert_eq!(indemnisations.len(), 1);
    assert_eq!(indemnisations[0]["montant"], DEVIS_PART_COURSIER);
    assert_eq!(indemnisations[0]["motif"], "annulation_apres_achat");

    let evenements = bac.evenements("commande.annulee").await;
    assert_eq!(evenements[0]["sans_frais"], false);
    assert_eq!(evenements[0]["part_coursier_due"], DEVIS_PART_COURSIER);
}

/// **FR-054** — un admin qui annule la commande de quelqu'un DOIT motiver son
/// geste. Le motif est une clé i18n, jamais du texte libre.
#[sqlx::test(migrations = "../migrations")]
async fn admin_sans_motif_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    for corps_demande in [json!({}), json!({ "motif_cle": "   " })] {
        let (statut, corps) = bac
            .post(
                &format!("/admin/commandes/{}/annuler", course.commande),
                &bac.jeton_admin,
                corps_demande,
            )
            .await;
        assert_eq!(statut, 422, "{corps}");
        assert_eq!(corps["code"], "motif_requis");
    }
    assert_eq!(
        bac.etat_commande(course.commande).await,
        "en_cours",
        "un refus n'est pas une transition",
    );
    assert_eq!(bac.nb_evenements("commande.annulee").await, 0);

    // Avec son motif, l'annulation passe — et le motif voyage dans l'événement,
    // parce que c'est le client qui le lira.
    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/annuler", course.commande),
            &bac.jeton_admin,
            json!({ "motif_cle": "commande.annulation.vendeur_injoignable" }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let evenements = bac.evenements("commande.annulee").await;
    assert_eq!(evenements[0]["par"], "admin");
    assert_eq!(
        evenements[0]["motif_cle"],
        "commande.annulation.vendeur_injoignable",
    );
}

/// Une commande LIVRÉE ne s'annule pas : `terminee` est terminal, aucune
/// transition n'en part (table fermée, data-model §3.1).
#[sqlx::test(migrations = "../migrations")]
async fn commande_livree_ne_s_annule_pas(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    for arret in &course.collectes {
        bac.collecter(*arret).await;
    }
    bac.cloturer(&course, "qr").await;
    assert_eq!(bac.etat_commande(course.commande).await, "terminee");

    for (jeton, uri) in [
        (&bac.jeton_client, format!("/commandes/{}/annuler", course.commande)),
        (
            &bac.jeton_admin,
            format!("/admin/commandes/{}/annuler", course.commande),
        ),
    ] {
        let (statut, corps) = bac
            .post(&uri, jeton, json!({ "motif_cle": "commande.annulation.admin" }))
            .await;
        assert_eq!(statut, 409, "{corps}");
        assert_eq!(corps["code"], "transition_refusee");
    }
    assert_eq!(bac.etat_commande(course.commande).await, "terminee");
    assert_eq!(bac.nb_evenements("commande.annulee").await, 0);
}

/// Une commande PRÉPAYÉE annulée doit son remboursement — `rembourse` est un
/// état de paiement, pas un mouvement de caisse : l'écriture comptable
/// appartient à PAY, qui s'y branchera par l'événement.
#[sqlx::test(migrations = "../migrations")]
async fn commande_prepayee_annulee_doit_un_remboursement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Mobile money : la commande naît `en_attente_paiement`.
    let commande = bac
        .creer_commande_mode("marche", vec![bac.vendeurs[0].ligne(1)], "mobile_money")
        .await;
    // Prépaiement confirmé (PAY simulé) : le paiement passe `regle`.
    bac.commandes
        .confirmer_prepaiement(commande, chrono::Utc::now())
        .await
        .unwrap();

    let (statut, corps) = bac
        .post(
            &format!("/commandes/{commande}/annuler"),
            &bac.jeton_client,
            json!({}),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["remboursement_du"], true);

    let paiement: String =
        sqlx::query_scalar("SELECT etat_paiement::text FROM commandes.commande WHERE id = $1")
            .bind(commande)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(paiement, "rembourse");
    assert_eq!(
        bac.evenements("commande.annulee").await[0]["remboursement_du"],
        true,
    );
}

/// La propriété : un client n'annule que SA commande, et ne distingue pas une
/// commande d'autrui d'une commande inexistante.
#[sqlx::test(migrations = "../migrations")]
async fn un_client_n_annule_que_sa_commande(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac
        .post(
            &format!("/commandes/{}/annuler", course.commande),
            &bac.jeton_intrus,
            json!({}),
        )
        .await;
    assert_eq!(statut, 404, "{corps}");
    assert_eq!(corps["code"], "commande_inconnue");
    assert_eq!(bac.etat_commande(course.commande).await, "en_cours");

    // L'admin, lui, agit sur toutes — c'est son rôle, et c'est pour cela que
    // son motif est exigé.
    let (statut, _) = bac
        .post(
            &format!("/admin/commandes/{}/annuler", course.commande),
            &bac.jeton_client,
            json!({ "motif_cle": "commande.annulation.admin" }),
        )
        .await;
    assert_eq!(statut, 403, "rôle admin requis");
}

/// L'annulation depuis l'ATTENTE de coursier est sans frais (maquette C4-4b) :
/// aucune course n'a démarré, donc rien n'a été acheté.
#[sqlx::test(migrations = "../migrations")]
async fn annulation_depuis_l_attente_est_sans_frais(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(1)])
        .await;
    bac.commandes
        .mettre_en_attente_coursier(commande, chrono::Utc::now())
        .await
        .unwrap();

    let (statut, corps) = bac
        .post(
            &format!("/commandes/{commande}/annuler"),
            &bac.jeton_client,
            json!({}),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["sans_frais"], true);
    assert_eq!(bac.etat_commande(commande).await, "annulee");

    // Et elle sort de la file : une commande annulée n'attend plus personne.
    assert!(bac
        .commandes
        .en_attente_coursier(bac.ville)
        .await
        .unwrap()
        .is_empty());
}

/// Une commande annulée ne se ré-annule pas : `annulee` est terminal.
#[sqlx::test(migrations = "../migrations")]
async fn double_annulation_refusee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let uri = format!("/commandes/{}/annuler", course.commande);

    let (statut, _) = bac.post(&uri, &bac.jeton_client, json!({})).await;
    assert_eq!(statut, 200);
    let (statut, corps) = bac.post(&uri, &bac.jeton_client, json!({})).await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(
        bac.nb_evenements("commande.annulee").await,
        1,
        "une seule annulation, un seul événement",
    );
}
