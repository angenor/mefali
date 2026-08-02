//! US3 — « Une notification signée, comptée une seule fois » (SC-003, SC-004).
//!
//! Le cœur risqué du cycle. Ce fichier mesure trois choses, chiffrées :
//!
//! | Mesure | Attendu |
//! |---|---|
//! | rejeu ×10 d'une notification valide | **1** confirmation, **1** événement, **1** transition |
//! | 100 signatures invalides | **0** effet, **100** traces de refus |
//! | 2 notifications concurrentes | **1** seul effet |
//!
//! Tout passe par la route HTTP réelle, avec des corps **bruts** signés par le
//! double : un test qui laisserait `serde_json` re-sérialiser la charge ne
//! signerait pas les octets vérifiés.

mod bac_paiements;

use bac_paiements::Bac;
use paiements::{FournisseurSimule, IssuePaiement};

const URI_WEBHOOK: &str = "/paiements/notifications/simule";

/// Ouvre une session et rend `(commande, transaction, montant)`.
async fn session(bac: &Bac) -> (uuid::Uuid, uuid::Uuid, i64) {
    let commande = bac.commande_prepayee().await;
    let (statut, corps) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    (
        commande,
        corps["transaction_id"].as_str().unwrap().parse().unwrap(),
        corps["montant_unites"].as_i64().unwrap(),
    )
}

/// **SC-003 — rejeu ×10 → un seul effet.**
///
/// Un agrégateur retente jusqu'à recevoir `200`. Sans idempotence, dix
/// tentatives feraient dix confirmations : dix événements pour le dispatch, dix
/// lignes dans les métriques, et un rapprochement de comptes impossible.
#[sqlx::test(migrations = "../migrations")]
async fn dix_rejeus_ne_font_qu_une_confirmation(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    // LE MÊME corps, LA MÊME signature, dix fois — exactement ce qu'un
    // fournisseur qui retente envoie.
    let corps = Bac::corps_notification(transaction, montant, "XOF", IssuePaiement::Reussi);
    let entete = bac.entete_signature(&corps);

    let mut traites = 0;
    let mut rejeux = 0;
    for _ in 0..10 {
        let (statut, reponse) = bac
            .post_brut(URI_WEBHOOK, &corps, &[(entete.0, entete.1.clone())])
            .await;
        assert_eq!(statut, 200, "un rejeu n'est JAMAIS une erreur — {reponse}");
        if reponse["traite"] == true {
            traites += 1;
        } else {
            assert_eq!(reponse["motif"], "rejeu");
            rejeux += 1;
        }
    }

    assert_eq!((traites, rejeux), (1, 9));
    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
    assert_eq!(bac.evenements("paiement.confirme").await.len(), 1);
    assert_eq!(
        bac.cmd.evenements("commande.paiement_confirme").await.len(),
        1
    );
    assert_eq!(
        bac.notifications().await.len(),
        1,
        "la contrainte triple avale les neuf doublons",
    );
}

/// **SC-004 — 100 signatures invalides → 0 effet, 100 traces.**
///
/// Les corps sont **différents** les uns des autres : c'est ce que fait
/// quelqu'un qui sonde, et c'est ce qui produit cent traces. Cent tentatives
/// portant le MÊME corps n'en laisseraient qu'une, par la même contrainte
/// d'unicité — voulu, et c'est ce qui empêche d'inonder la table depuis
/// l'extérieur.
#[sqlx::test(migrations = "../migrations")]
async fn cent_signatures_invalides_n_ont_aucun_effet(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    // Un secret qui n'est pas le nôtre : le cas d'une fuite chez un tiers, ou
    // d'un environnement de recette pointant la production.
    let imposteur = FournisseurSimule::avec_secret(b"secret-QUI-N-EST-PAS-LE-NOTRE!!!".to_vec());

    for i in 0..100 {
        // Montant varié → corps varié → empreinte variée : cent tentatives
        // distinctes, comme un sondage réel.
        let corps = Bac::corps_notification(transaction, montant + i, "XOF", IssuePaiement::Reussi);
        let signature = imposteur.signer(&corps, chrono::Utc::now());
        let (statut, _) = bac
            .post_brut(
                URI_WEBHOOK,
                &corps,
                &[(paiements::fournisseur::simule::ENTETE_SIGNATURE, signature)],
            )
            .await;
        assert_eq!(statut, 401, "tentative {i}");
    }

    // ZÉRO effet.
    assert_eq!(bac.etats_transactions(commande).await, vec!["ouverte"]);
    assert_eq!(bac.etat_commande(commande).await, "en_attente_paiement");
    assert!(bac.evenements("paiement.confirme").await.is_empty());
    assert!(bac.dossiers().await.is_empty());

    // CENT traces, toutes marquées invalides.
    let notifications = bac.notifications().await;
    assert_eq!(notifications.len(), 100);
    assert!(
        notifications.iter().all(|(_, valide)| !*valide),
        "chaque trace porte `signature_valide = false`",
    );

    // Et la vraie notification passe encore : les refus n'ont rien cassé.
    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["traite"], true);
}

/// Deux notifications **concurrentes** → un seul effet.
///
/// C'est le cas que le `SELECT … FOR UPDATE` existe pour tenir : deux requêtes
/// passeraient toutes deux une vérification préalable « est-ce déjà réglé ? »
/// avant que l'une n'écrive.
#[sqlx::test(migrations = "../migrations")]
async fn deux_notifications_concurrentes_n_ont_qu_un_effet(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    // Deux charges DIFFÉRENTES portant le même succès : l'empreinte diffère,
    // donc la contrainte d'unicité ne les distingue pas comme un rejeu. Seul le
    // verrou de ligne et la table de transitions les départagent — c'est
    // exactement ce qu'on veut mesurer.
    let a = Bac::corps_notification(transaction, montant, "XOF", IssuePaiement::Reussi);
    tokio::time::sleep(std::time::Duration::from_millis(2)).await;
    let b = Bac::corps_notification(transaction, montant, "XOF", IssuePaiement::Reussi);
    assert_ne!(a, b, "les deux charges diffèrent par leur horodatage");

    let (ea, eb) = (bac.entete_signature(&a), bac.entete_signature(&b));
    let entetes_a = [(ea.0, ea.1)];
    let entetes_b = [(eb.0, eb.1)];
    let (ra, rb) = tokio::join!(
        bac.post_brut(URI_WEBHOOK, &a, &entetes_a),
        bac.post_brut(URI_WEBHOOK, &b, &entetes_b),
    );

    assert_eq!((ra.0, rb.0), (200, 200));
    let effets = [&ra.1, &rb.1]
        .iter()
        .filter(|r| r["traite"] == true)
        .count();
    assert_eq!(effets, 1, "un seul effet : {} / {}", ra.1, rb.1);

    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
    assert_eq!(bac.evenements("paiement.confirme").await.len(), 1);
    assert_eq!(
        bac.cmd.evenements("commande.paiement_confirme").await.len(),
        1
    );
}

/// FR-024 — **un montant divergent ne confirme RIEN** et ouvre un dossier.
#[sqlx::test(migrations = "../migrations")]
async fn un_montant_divergent_ouvre_un_dossier_sans_confirmer(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    let (statut, reponse) = bac
        .notifier(transaction, 1, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["traite"], false);
    assert_eq!(reponse["motif"], "divergence");

    assert_eq!(
        bac.etats_transactions(commande).await,
        vec!["ouverte"],
        "la session VIT encore : le client peut payer le bon montant",
    );
    assert_eq!(bac.etat_commande(commande).await, "en_attente_paiement");
    assert!(bac.evenements("paiement.confirme").await.is_empty());

    let dossiers = bac.dossiers().await;
    assert_eq!(dossiers.len(), 1);
    assert_eq!(dossiers[0].0, "montant_divergent");
    assert_eq!(dossiers[0].1, "paiement.dossier.montant_divergent");
    let ouverts = bac.evenements("paiement.dossier_ouvert").await;
    assert_eq!(ouverts.len(), 1);
    assert_eq!(ouverts[0]["montant_constate"], 1);
    assert_eq!(ouverts[0]["montant_attendu"], montant);

    // Le BON montant, ensuite, passe normalement.
    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["traite"], true);
    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
}

/// FR-024 — **une autre devise** ne confirme rien non plus.
///
/// 12 500 XOF et 12 500 EUR portent le même nombre. Sans ce contrôle, un
/// encaissement en euros vaudrait confirmation d'une commande en francs.
#[sqlx::test(migrations = "../migrations")]
async fn une_devise_divergente_ouvre_un_dossier(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    let (statut, reponse) = bac
        .notifier(transaction, montant, "EUR", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["motif"], "divergence");

    assert_eq!(bac.etats_transactions(commande).await, vec!["ouverte"]);
    assert_eq!(bac.dossiers().await[0].0, "devise_divergente");
}

/// FR-026 — **un refus n'est pas une fin** : la session vit, le client réessaie.
#[sqlx::test(migrations = "../migrations")]
async fn un_refus_d_operateur_laisse_reessayer(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Echoue)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["traite"], true);

    assert_eq!(bac.etats_transactions(commande).await, vec!["echouee"]);
    assert_eq!(
        bac.etat_commande(commande).await,
        "en_attente_paiement",
        "la commande reste en attente jusqu'à l'échéance",
    );
    let echecs = bac.evenements("paiement.echoue").await;
    assert_eq!(echecs.len(), 1);
    assert_eq!(echecs[0]["motif_cle"], "paiement.echec.refus_operateur");

    // La session est toujours servie au client, avec son accès.
    let (statut, etat) = bac
        .get(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{etat}");
    assert_eq!(etat["etat"], "echouee");
    assert!(
        etat["acces_paiement"].as_str().is_some(),
        "le client réessaie sur le MÊME accès (FR-026)",
    );
    assert!(etat["restant_s"].as_i64().unwrap() > 0);

    // …et le second essai réussit, sur la même session.
    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
    assert_eq!(bac.etat_commande(commande).await, "nouvelle");
}

/// `en_cours` n'est **pas** un échec : le traiter comme tel annulerait des
/// commandes payées.
#[sqlx::test(migrations = "../migrations")]
async fn en_cours_ne_change_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session(&bac).await;

    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::EnCours)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["traite"], false);
    assert_eq!(reponse["motif"], "en_cours");
    assert_eq!(bac.etats_transactions(commande).await, vec!["ouverte"]);
}

/// Une référence qui ne désigne aucune transaction ouvre un dossier
/// `transaction_orpheline` (FR-082) — l'argent est quelque part, il faut le voir.
#[sqlx::test(migrations = "../migrations")]
async fn une_notification_orpheline_ouvre_un_dossier(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let (statut, reponse) = bac
        .notifier(uuid::Uuid::now_v7(), 9_999, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(reponse["motif"], "orpheline");

    let dossiers = bac.dossiers().await;
    assert_eq!(dossiers.len(), 1);
    assert_eq!(dossiers[0].0, "transaction_orpheline");
}

/// Le segment `{fournisseur}` inconnu rend `404` — **avant** toute lecture du
/// corps : inutile de recevoir 64 Kio pour une route qui n'existe pas.
#[sqlx::test(migrations = "../migrations")]
async fn un_fournisseur_inconnu_rend_404(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let corps = Bac::corps_notification(uuid::Uuid::now_v7(), 1, "XOF", IssuePaiement::Reussi);
    let entete = bac.entete_signature(&corps);

    let (statut, _) = bac
        .post_brut(
            "/paiements/notifications/un-agregateur-inconnu",
            &corps,
            &[(entete.0, entete.1)],
        )
        .await;
    assert_eq!(statut, 404);
    assert!(
        bac.notifications().await.is_empty(),
        "rien n'est écrit pour une route qui n'existe pas",
    );
}

/// Un corps au-delà de 64 Kio est refusé — **avant** d'être bufferisé en
/// entier.
#[sqlx::test(migrations = "../migrations")]
async fn un_corps_demesure_est_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let enorme = vec![b'x'; api::paiements_webhook_http::CORPS_MAX_OCTETS + 1];
    let entete = bac.entete_signature(&enorme);

    let (statut, _) = bac
        .post_brut(URI_WEBHOOK, &enorme, &[(entete.0, entete.1)])
        .await;
    assert_eq!(statut, 413);
    assert!(bac.notifications().await.is_empty());
}
