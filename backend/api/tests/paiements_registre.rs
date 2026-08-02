//! US6 (cycle PAY 011, T073) — le registre d'exploitation et la file des
//! anomalies.
//!
//! SC-011 : le rapprochement se lit **dans les deux sens**. Partant d'une
//! commande, on retrouve la transaction et sa référence chez le fournisseur ;
//! partant d'une référence, on retrouve la commande. Sans ça, réconcilier un
//! relevé d'agrégateur se ferait à la main, ligne à ligne — c'est-à-dire jamais.
//!
//! FR-082 : les familles d'anomalies sont **visibles avec leur motif**. Un
//! dossier n'est pas un log : il a un état, un motif en clé i18n, et il se clôt
//! avec un auteur. Un log se perd dans le volume et personne ne le referme.

mod bac_paiements;

use bac_paiements::Bac;
use sqlx::PgPool;
use uuid::Uuid;

/// SC-011 — le rapprochement **dans les deux sens**.
#[sqlx::test(migrations = "../migrations")]
async fn le_rapprochement_se_lit_dans_les_deux_sens(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
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

    // ── Sens 1 : de la COMMANDE vers la référence fournisseur ─────────────
    let (statut, corps) = bac
        .get(
            &format!("/admin/paiements/transactions?commande_id={commande}"),
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let lignes = corps["transactions"].as_array().unwrap();
    assert_eq!(lignes.len(), 1);
    let ligne = &lignes[0];
    assert_eq!(ligne["commande_id"], serde_json::json!(commande));
    assert_eq!(ligne["etat"], "reglee");
    assert_eq!(ligne["moyen"], "wave");
    assert!(
        ligne["reference_fournisseur"].is_string(),
        "sans référence fournisseur, un relevé d'agrégateur ne se rapproche \
         pas — c'est exactement ce que FR-081 demande",
    );
    assert_eq!(
        ligne["orpheline"], false,
        "la commande vivante attend bien ce paiement",
    );
    assert_eq!(
        corps["total_regle_unites"], montant,
        "le total ne compte que les transactions RÉGLÉES",
    );

    // ── Sens 2 : de l'ÉTAT vers la commande ───────────────────────────────
    let (statut, corps) = bac
        .get(
            "/admin/paiements/transactions?etat=reglee",
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let lignes = corps["transactions"].as_array().unwrap();
    assert!(
        lignes
            .iter()
            .any(|l| l["commande_id"] == serde_json::json!(commande)),
        "partant du registre, on retrouve la commande",
    );

    // Un filtre par moyen répond aussi — la répartition par moyen (MET) en
    // dépend.
    let (statut, corps) = bac
        .get(
            "/admin/paiements/transactions?moyen=orange_money",
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert!(
        corps["transactions"].as_array().unwrap().is_empty(),
        "aucun paiement Orange Money dans ce bac",
    );
}

/// FR-082 — une transaction payée **hors délai** est marquée `orpheline` : de
/// l'argent encaissé qu'aucune commande vivante n'attend.
#[sqlx::test(migrations = "../migrations")]
async fn un_paiement_hors_delai_est_marque_orphelin(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let (_, session) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    let transaction: Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();

    // L'échéance est franchie, le balayage annule la commande.
    bac.perimer_session(commande).await;
    bac.balayer().await;

    // Le paiement arrive quand même. Il ne ressuscite RIEN (R8) — mais il ne
    // disparaît pas non plus.
    let (statut, _) = bac
        .notifier(
            transaction,
            montant,
            "XOF",
            paiements::IssuePaiement::Reussi,
        )
        .await;
    assert_eq!(statut, 200);

    let (statut, corps) = bac
        .get(
            &format!("/admin/paiements/transactions?commande_id={commande}"),
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let ligne = &corps["transactions"].as_array().unwrap()[0];
    assert_eq!(ligne["etat"], "payee_hors_delai");
    assert_eq!(
        ligne["orpheline"], true,
        "c'est ce drapeau qui met la ligne sous les yeux de l'exploitation",
    );
    assert_eq!(
        corps["total_regle_unites"], 0,
        "un paiement hors délai n'est pas un encaissement RÉGLÉ : le compter \
         ferait croire à une recette qui n'a servi à personne",
    );
}

/// FR-082 — la file des dossiers montre les anomalies avec leur **motif en clé
/// i18n**, et se filtre par type.
#[sqlx::test(migrations = "../migrations")]
async fn la_file_des_dossiers_montre_les_anomalies_avec_leur_motif(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // Anomalie 1 — montant divergent : la notification annonce autre chose.
    let commande = bac.commande_prepayee().await;
    let (_, session) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    let transaction: Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();
    let (statut, _) = bac
        .notifier(
            transaction,
            montant + 500,
            "XOF",
            paiements::IssuePaiement::Reussi,
        )
        .await;
    assert_eq!(statut, 200);

    let (statut, corps) = bac
        .get(
            "/admin/paiements/dossiers?etat=ouvert",
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let dossiers = corps["dossiers"].as_array().unwrap();
    assert_eq!(dossiers.len(), 1);
    let dossier = &dossiers[0];
    assert_eq!(dossier["type"], "montant_divergent");
    assert_eq!(dossier["etat"], "ouvert");
    assert_eq!(
        dossier["motif_cle"], "paiement.dossier.montant_divergent",
        "une CLÉ, jamais une phrase : la colonne reste comparable et filtrable",
    );
    assert_eq!(dossier["montant_constate"], montant + 500);
    assert_eq!(dossier["montant_attendu"], montant);
    assert_eq!(dossier["commande_id"], serde_json::json!(commande));

    // Le filtre par type répond.
    let (statut, corps) = bac
        .get(
            "/admin/paiements/dossiers?type=devise_divergente",
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert!(corps["dossiers"].as_array().unwrap().is_empty());
}

/// La clôture est motivée, tracée, et **ne se répète pas**.
#[sqlx::test(migrations = "../migrations")]
async fn un_dossier_se_clot_une_fois_avec_son_motif(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let (_, session) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    let transaction: Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();
    bac.notifier(
        transaction,
        montant,
        "USD",
        paiements::IssuePaiement::Reussi,
    )
    .await;

    let (_, corps) = bac
        .get("/admin/paiements/dossiers", &bac.cmd.jeton_admin)
        .await;
    let dossier_id = corps["dossiers"].as_array().unwrap()[0]["id"]
        .as_str()
        .unwrap()
        .to_owned();

    let corps_cloture =
        serde_json::json!({ "motif_cle": "paiement.dossier.clos.rembourse_hors_produit" });
    let (statut, corps) = bac
        .post(
            &format!("/admin/paiements/dossiers/{dossier_id}/clore"),
            &bac.cmd.jeton_admin,
            corps_cloture.clone(),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["etat"], "clos");
    assert!(corps["clos_le"].is_string(), "l'instant est conservé");
    assert_eq!(
        corps["clos_motif_cle"],
        "paiement.dossier.clos.rembourse_hors_produit",
    );

    // Un second appel est refusé : rouvrir effacerait la trace de ce qui a été
    // décidé.
    let (statut, corps) = bac
        .post(
            &format!("/admin/paiements/dossiers/{dossier_id}/clore"),
            &bac.cmd.jeton_admin,
            corps_cloture,
        )
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "dossier_deja_clos");

    // Sans motif : refusé.
    let (_, corps) = bac
        .get(
            "/admin/paiements/dossiers?etat=ouvert",
            &bac.cmd.jeton_admin,
        )
        .await;
    assert!(
        corps["dossiers"].as_array().unwrap().is_empty(),
        "le dossier clos ne traîne plus dans la file des ouverts",
    );
}

/// Un dossier inconnu rend `404`, pas `409` : deux gestes différents pour
/// l'exploitation.
#[sqlx::test(migrations = "../migrations")]
async fn un_dossier_inconnu_se_distingue_d_un_dossier_clos(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, corps) = bac
        .post(
            &format!("/admin/paiements/dossiers/{}/clore", Uuid::now_v7()),
            &bac.cmd.jeton_admin,
            serde_json::json!({ "motif_cle": "paiement.dossier.clos.verifie" }),
        )
        .await;
    assert_eq!(statut, 404, "{corps}");
    assert_eq!(corps["code"], "dossier_inconnu");
}

/// `403` pour un rôle non admin — sur les DEUX surfaces d'exploitation.
#[sqlx::test(migrations = "../migrations")]
async fn les_surfaces_d_exploitation_exigent_le_role_admin(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    for uri in ["/admin/paiements/transactions", "/admin/paiements/dossiers"] {
        let (statut, corps) = bac.get(uri, &bac.cmd.jeton_client).await;
        assert_eq!(statut, 403, "{uri} : {corps}");
    }

    let (statut, _) = bac
        .post(
            &format!("/admin/paiements/dossiers/{}/clore", Uuid::now_v7()),
            &bac.cmd.jeton_client,
            serde_json::json!({ "motif_cle": "x" }),
        )
        .await;
    assert_eq!(statut, 403, "la clôture aussi");
}
