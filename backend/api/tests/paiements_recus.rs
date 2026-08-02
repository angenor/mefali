//! US5 (cycle PAY 011, T060) — les deux reçus disent **la même chose**.
//!
//! SC-009 et FR-073. Ce que le test mesure :
//!
//! 1. le reçu client et le reçu vendeur portent les mêmes trois montants,
//!    **au franc près** — articles, retenue, net ;
//! 2. une commande prépayée porte `deja_regle: true` et
//!    `montant_a_remettre_au_coursier = 0` : le coursier n'a rien à réclamer ;
//! 3. les `403` croisés — un client ne lit pas le reçu d'un autre, un vendeur
//!    ne lit pas l'arrêt d'un prestataire qu'il ne pilote pas.
//!
//! # Pourquoi deux montants identiques méritent un test
//!
//! Parce qu'ils sont composés par deux chemins différents, depuis deux
//! surfaces différentes, pour deux publics différents. Rien dans le code ne
//! garantit structurellement qu'ils coïncident — sauf ce test. Le jour où l'un
//! des deux se met à recalculer au lieu de relire, c'est lui qui le dira.

mod bac_paiements;

use bac_paiements::{Bac, DEVIS_PRIX_CLIENT};
use sqlx::PgPool;
use tarification::OffreLivraison;
use uuid::Uuid;

/// SC-009 — les deux reçus, les mêmes chiffres.
#[sqlx::test(migrations = "../migrations")]
async fn les_deux_recus_portent_les_memes_montants(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_vendeur(pool).await;
    let vendeur = &bac.cmd.vendeurs[0];
    let vendeur_id = vendeur.id;
    let mut tx = bac.cmd.pool.begin().await.unwrap();
    bac.cmd
        .prestataires
        .definir_offre_livraison(
            &mut tx,
            vendeur_id,
            Some(OffreLivraison::Toujours),
            bac.cmd.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let (_, jeton_vendeur) = bac.compte_vendeur(vendeur_id, "+2250700000011").await;

    let commande = bac
        .cmd
        .creer_commande_api("marche", vec![vendeur.ligne(10)])
        .await;
    let livraison = bac
        .cmd
        .commandes
        .assigner_coursier(commande, bac.cmd.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.cmd.arrets_de(livraison).await;
    bac.cmd.collecter(collectes[0]).await;

    let (statut, client) = bac
        .get(
            &format!("/commandes/{commande}/recu"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "reçu client : {client}");

    let (statut, vendeur_recu) = bac
        .get(
            &format!("/vendeur/arrets/{}/recu", collectes[0]),
            &jeton_vendeur,
        )
        .await;
    assert_eq!(statut, 200, "reçu vendeur : {vendeur_recu}");

    // Les trois montants, des deux côtés.
    assert_eq!(
        client["montant_articles_unites"], vendeur_recu["montant_articles_unites"],
        "les articles bruts",
    );
    assert_eq!(
        client["retenue_vendeur_unites"], vendeur_recu["retenue_livraison_offerte_unites"],
        "la retenue — même chiffre, deux noms selon le lecteur",
    );
    assert_eq!(
        client["retenue_vendeur_unites"],
        serde_json::json!(DEVIS_PRIX_CLIENT),
        "et c'est bien la retenue du devis figé",
    );
    assert_eq!(
        vendeur_recu["net_verse_unites"].as_i64().unwrap(),
        vendeur_recu["montant_articles_unites"].as_i64().unwrap()
            - vendeur_recu["retenue_livraison_offerte_unites"]
                .as_i64()
                .unwrap(),
        "net = articles − retenue, et pas autre chose",
    );

    // La retenue porte son motif en CLÉ, jamais en phrase.
    assert_eq!(
        vendeur_recu["motif_retenue_cle"],
        serde_json::json!("recu.retenue.livraison_offerte_vendeur"),
    );

    // Une commande cash : le client doit remettre le total au coursier, et les
    // frais facturés sont nuls puisque le vendeur les a pris en charge.
    assert_eq!(client["mode_paiement"], "cash");
    assert_eq!(client["deja_regle"], false);
    assert_eq!(
        client["montant_a_remettre_au_coursier_unites"],
        client["total_du_unites"],
    );
    assert_eq!(client["frais_livraison_unites"], serde_json::json!(0));
}

/// FR-073 — une commande prépayée ne réclame **rien** au coursier.
#[sqlx::test(migrations = "../migrations")]
async fn recu_d_une_prepayee_ne_reclame_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;

    // Avant la confirmation : rien n'est réglé.
    let (statut, avant) = bac
        .get(
            &format!("/commandes/{commande}/recu"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{avant}");
    assert_eq!(avant["deja_regle"], false);
    assert_eq!(avant["mode_paiement"], "mobile_money");
    assert_eq!(
        avant["montant_a_remettre_au_coursier_unites"],
        serde_json::json!(0),
        "prépayée : le coursier n'encaisse rien, même avant confirmation \
         (FR-057) — il ne collecte pas encore, mais l'écran ne doit jamais \
         afficher un montant à réclamer",
    );
    assert_eq!(avant["moyen"], serde_json::Value::Null, "pas encore dit");

    // Session ouverte puis confirmée par une notification signée.
    let (statut, session) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{session}");
    let transaction: Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();
    let (statut, _) = bac
        .notifier_moyen(
            transaction,
            montant,
            "XOF",
            paiements::IssuePaiement::Reussi,
            Some("wave"),
        )
        .await;
    assert_eq!(statut, 200);

    let (statut, apres) = bac
        .get(
            &format!("/commandes/{commande}/recu"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{apres}");
    assert_eq!(apres["deja_regle"], true, "FR-073");
    assert_eq!(
        apres["montant_a_remettre_au_coursier_unites"],
        serde_json::json!(0),
    );
    assert_eq!(
        apres["total_du_unites"], avant["total_du_unites"],
        "confirmer un paiement ne change pas le total dû",
    );
    // Le moyen n'est plus `null` : le fournisseur l'a dit (FR-012). Il ne
    // l'était pas avant, parce que rien ne le devine.
    assert_eq!(
        apres["moyen"],
        serde_json::json!("wave"),
        "le moyen est renseigné dès que le fournisseur l'annonce, jamais deviné",
    );
}

/// SC-009 — les `403` croisés. Un reçu est une pièce d'argent : il ne se lit
/// pas par-dessus l'épaule du voisin.
#[sqlx::test(migrations = "../migrations")]
async fn refus_croises_sur_les_deux_recus(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur_id = bac.cmd.vendeurs[0].id;
    let autre_vendeur_id = bac.cmd.vendeurs[1].id;
    let (_, jeton_vendeur) = bac.compte_vendeur(vendeur_id, "+2250700000011").await;
    let (_, jeton_autre) = bac.compte_vendeur(autre_vendeur_id, "+2250700000012").await;

    let commande = bac
        .cmd
        .creer_commande_api("marche", vec![bac.cmd.vendeurs[0].ligne(2)])
        .await;
    let livraison = bac
        .cmd
        .commandes
        .assigner_coursier(commande, bac.cmd.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.cmd.arrets_de(livraison).await;

    // Le reçu vendeur n'existe pas avant le scan : il n'y a pas de versement à
    // attester.
    let (statut, _) = bac
        .get(
            &format!("/vendeur/arrets/{}/recu", collectes[0]),
            &jeton_vendeur,
        )
        .await;
    assert_eq!(statut, 404, "pas encore collecté");

    bac.cmd.collecter(collectes[0]).await;

    // Le vendeur de l'arrêt le lit.
    let (statut, _) = bac
        .get(
            &format!("/vendeur/arrets/{}/recu", collectes[0]),
            &jeton_vendeur,
        )
        .await;
    assert_eq!(statut, 200);

    // Un AUTRE vendeur, rattaché à un autre prestataire, ne le lit pas.
    let (statut, corps) = bac
        .get(
            &format!("/vendeur/arrets/{}/recu", collectes[0]),
            &jeton_autre,
        )
        .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "prestataire_non_rattache");

    // Un autre CLIENT ne lit pas le reçu de cette commande — et reçoit `404`,
    // pas `403` : lui répondre « interdit » lui apprendrait que la commande
    // existe.
    let (statut, corps) = bac
        .get(
            &format!("/commandes/{commande}/recu"),
            &bac.cmd.jeton_intrus,
        )
        .await;
    assert_eq!(statut, 404, "{corps}");
}

/// FR-072 — une ligne retirée reste au reçu, avec son statut, et pèse **zéro**.
/// Le reçu explique l'écart au lieu de le faire disparaître.
#[sqlx::test(migrations = "../migrations")]
async fn les_lignes_retirees_expliquent_l_ecart(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac
        .cmd
        .creer_commande_api(
            "marche",
            vec![
                bac.cmd.vendeurs[0].ligne(2),
                bac.cmd.vendeurs[0].ligne_de(1, 3),
            ],
        )
        .await;
    let livraison = bac
        .cmd
        .commandes
        .assigner_coursier(commande, bac.cmd.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.cmd.arrets_de(livraison).await;
    let lignes = bac.cmd.lignes_de(collectes[0]).await;
    bac.cmd.retirer_ligne(lignes[0]).await;

    let (statut, recu) = bac
        .get(
            &format!("/commandes/{commande}/recu"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{recu}");

    let lignes_recu = recu["lignes"].as_array().unwrap();
    assert_eq!(lignes_recu.len(), 2, "la ligne retirée reste VISIBLE");
    let retiree = lignes_recu
        .iter()
        .find(|l| l["statut"] == "retiree")
        .expect("la ligne retirée porte son statut");
    assert_eq!(
        retiree["sous_total_unites"],
        serde_json::json!(0),
        "elle ne pèse plus rien",
    );
    assert!(
        retiree["prix_unitaire"].as_i64().unwrap() > 0,
        "son prix reste affiché : c'est ce qui rend l'écart lisible",
    );

    let vivante = lignes_recu
        .iter()
        .find(|l| l["statut"] == "presente")
        .unwrap();
    assert_eq!(
        recu["montant_articles_unites"], vivante["sous_total_unites"],
        "seules les lignes vivantes comptent",
    );
}
