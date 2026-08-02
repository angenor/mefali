//! US2 — « La commande fantôme n'existe pas » (PAY-02, FR-027 → FR-035).
//!
//! Ce que ces tests protègent tient en une phrase : **une session abandonnée
//! annule sa commande, sans frais — mais une session PAYÉE ne s'annule jamais,
//! même si sa notification s'est perdue.**
//!
//! Le second point est celui qui coûte : sans réconciliation, chaque webhook
//! perdu deviendrait un remboursement à faire à la main, par une story
//! (PAY-04) qui n'est pas construite.

mod bac_paiements;

use bac_paiements::Bac;
use paiements::IssuePaiement;

/// Ouvre une session par l'API et rend `(commande, transaction, montant)`.
async fn session_ouverte(bac: &Bac) -> (uuid::Uuid, uuid::Uuid, i64) {
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

/// Un passage de balayage, tel que le job le fait toutes les 10 s.
async fn balayer(bac: &Bac) -> paiements::BilanBalayage {
    paiements::balayer(
        &bac.paiements,
        &bac.cmd.commandes,
        bac.fournisseur.as_ref(),
    )
    .await
    .expect("le balayage aboutit")
}

/// FR-031 — l'annulation par expiration : **sans frais, sans part coursier**.
///
/// Rien n'a été acheté : aucun arrêt n'a pu être collecté sur une commande qui
/// n'est jamais partie au dispatch. Le test vérifie que le calcul du cycle 008
/// tombe juste tout seul, sans règle spéciale à maintenir (FR-032).
#[sqlx::test(migrations = "../migrations")]
async fn une_session_abandonnee_annule_sa_commande_sans_frais(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, _, montant) = session_ouverte(&bac).await;

    // Rien ne se passe tant que l'échéance n'est pas franchie.
    let bilan = balayer(&bac).await;
    assert_eq!(bilan.examinees, 0, "aucune session échue à cet instant");
    assert_eq!(bac.etat_commande(commande).await, "en_attente_paiement");

    bac.perimer_session(commande).await;
    let bilan = balayer(&bac).await;
    assert_eq!((bilan.examinees, bilan.expirees), (1, 1));
    assert_eq!(bilan.rattrapees, 0);

    assert_eq!(bac.etats_transactions(commande).await, vec!["expiree"]);
    assert_eq!(bac.etat_commande(commande).await, "annulee");

    // L'événement d'annulation dit ce qu'il faut dire à Awa : rien à payer.
    let annulations = bac.cmd.evenements("commande.annulee").await;
    assert_eq!(annulations.len(), 1);
    let annulation = &annulations[0];
    assert_eq!(annulation["par"], "systeme");
    assert_eq!(annulation["motif_cle"], commandes::MOTIF_ANNULATION_EXPIRATION);
    assert_eq!(annulation["sans_frais"], true);
    assert_eq!(annulation["part_coursier_due"], 0);

    // Et l'événement que NTF consommera (FR-033), écrit UNE fois.
    let expirations = bac.evenements("paiement.session_expiree").await;
    assert_eq!(expirations.len(), 1);
    assert_eq!(expirations[0]["commande"], commande.to_string());
    assert_eq!(expirations[0]["montant"], montant);
    assert!(
        expirations[0]["duree_s"].as_i64().is_some_and(|d| d >= 0),
        "la durée VÉCUE de la session, pas le paramètre de zone",
    );
}

/// Un second passage ne refait rien.
///
/// Le balayage tourne toutes les 10 secondes : s'il n'était pas idempotent, une
/// commande annulée le serait deux fois et l'événement de notification partirait
/// en boucle.
#[sqlx::test(migrations = "../migrations")]
async fn un_second_balayage_ne_refait_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, _, _) = session_ouverte(&bac).await;
    bac.perimer_session(commande).await;

    balayer(&bac).await;
    let second = balayer(&bac).await;

    assert_eq!(
        second.examinees, 0,
        "la session n'est plus `ouverte` : le balayage ne la revoit pas",
    );
    assert_eq!(bac.evenements("paiement.session_expiree").await.len(), 1);
    assert_eq!(bac.cmd.evenements("commande.annulee").await.len(), 1);
}

/// FR-034 — **une commande réglée à la 14ᵉ minute n'est pas annulée à la 16ᵉ.**
///
/// C'est le test qui protège l'argent d'Awa contre son propre balayage :
/// `reglee` est terminal, et la sélection des sessions échues ne prend que les
/// `ouverte`.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_reglee_avant_l_echeance_n_est_jamais_annulee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session_ouverte(&bac).await;

    // 14ᵉ minute : la notification arrive, la commande est confirmée.
    let (statut, corps) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(bac.etat_commande(commande).await, "nouvelle");

    // 16ᵉ minute : l'échéance est franchie. Le balayage passe.
    sqlx::query("UPDATE paiements.transaction SET expire_le = now() - interval '1 minute'")
        .execute(&bac.cmd.pool)
        .await
        .unwrap();
    let bilan = balayer(&bac).await;

    assert_eq!(
        bilan.examinees, 0,
        "une session `reglee` n'est PAS une session échue à traiter",
    );
    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
    assert_eq!(
        bac.etat_commande(commande).await,
        "nouvelle",
        "la commande payée reste dispatchable — l'échéance ne l'atteint plus",
    );
    assert!(bac.evenements("paiement.session_expiree").await.is_empty());
    assert!(bac.cmd.evenements("commande.annulee").await.is_empty());
}

/// FR-027 — **le webhook s'est perdu, le paiement a réussi.**
///
/// La réconciliation rattrape : la commande est confirmée au lieu d'être
/// annulée. Sans ce chemin, Awa aurait payé et perdu sa commande, et il
/// faudrait la rembourser à la main.
#[sqlx::test(migrations = "../migrations")]
async fn une_session_echue_mais_payee_est_rattrapee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, _, _) = session_ouverte(&bac).await;

    // Le fournisseur DIT que le paiement a réussi — la notification, elle,
    // n'est jamais arrivée.
    bac.fournisseur.issue_consultee(Some(IssuePaiement::Reussi));
    bac.perimer_session(commande).await;

    let bilan = balayer(&bac).await;
    assert_eq!((bilan.examinees, bilan.rattrapees), (1, 1));
    assert_eq!(bilan.expirees, 0);

    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
    assert_eq!(bac.etat_commande(commande).await, "nouvelle");
    assert_eq!(bac.etat_paiement(commande).await, "regle");
    assert!(
        bac.cmd.evenements("commande.annulee").await.is_empty(),
        "une commande PAYÉE ne s'annule pas, même échue",
    );
    assert_eq!(
        bac.evenements("paiement.confirme").await.len(),
        1,
        "rattraper vaut exactement notifier : même événement, même effet",
    );
}

/// Un fournisseur injoignable **n'annule rien**.
///
/// Une panne d'agrégateur de dix minutes annulerait sinon toutes les commandes
/// en cours de paiement, y compris celles qui viennent d'être réglées. La
/// session est reportée au passage suivant, et le passage suivant la retrouve.
#[sqlx::test(migrations = "../migrations")]
async fn un_fournisseur_injoignable_n_annule_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, _, _) = session_ouverte(&bac).await;
    bac.perimer_session(commande).await;

    bac.fournisseur
        .scenario(paiements::ScenarioSimule::Indisponible);
    let bilan = balayer(&bac).await;

    assert_eq!((bilan.examinees, bilan.reportees), (1, 1));
    assert_eq!(bilan.expirees, 0, "on n'annule JAMAIS à l'aveugle");
    assert_eq!(bac.etats_transactions(commande).await, vec!["ouverte"]);
    assert_eq!(bac.etat_commande(commande).await, "en_attente_paiement");

    // Le fournisseur revient : le passage suivant retrouve la session.
    bac.fournisseur.scenario(paiements::ScenarioSimule::Succes);
    let bilan = balayer(&bac).await;
    assert_eq!((bilan.examinees, bilan.expirees), (1, 1));
    assert_eq!(bac.etat_commande(commande).await, "annulee");
}

/// FR-035 — après l'échéance, l'ouverture est refusée `409 session_expiree`.
///
/// **Avant même que le balayage n'ait tourné** : c'est la lecture qui fait foi,
/// l'échéance est persistée (R7). Servir l'accès inviterait Awa à payer une
/// commande promise à l'annulation.
#[sqlx::test(migrations = "../migrations")]
async fn apres_l_echeance_l_ouverture_est_refusee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, _, _) = session_ouverte(&bac).await;
    let uri = format!("/commandes/{commande}/paiement");

    bac.perimer_session(commande).await;

    let (statut, corps) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "session_expiree");
    assert_eq!(corps["message_cle"], "paiement.erreur.session_expiree");

    // La lecture, elle, reste possible — et dit zéro seconde restante.
    let (statut, etat) = bac.get(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(statut, 200, "{etat}");
    assert_eq!(etat["restant_s"], 0);

    // Après le balayage, la session est close et le refus tient toujours.
    balayer(&bac).await;
    let (statut, corps) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(
        statut, 409,
        "la commande est annulée : elle n'attend plus rien — {corps}",
    );
}
