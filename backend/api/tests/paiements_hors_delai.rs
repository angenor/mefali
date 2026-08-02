//! US3 — le **succès tardif** (FR-036 → FR-038, research R8).
//!
//! Une notification de succès arrive **après** que l'échéance a annulé la
//! commande. Trois règles s'appliquent, et elles se tiennent ensemble :
//!
//! 1. la commande n'est **pas** ressuscitée — un vendeur qui a rangé sa
//!    marchandise ne la ressort pas parce qu'un paiement est arrivé en retard ;
//! 2. la transaction passe à `payee_hors_delai`, un état **terminal** : elle ne
//!    peut plus ni régler, ni expirer, ni échouer ;
//! 3. un **dossier** s'ouvre, et un événement part pour NTF. Le remboursement
//!    relève de PAY-04, qui n'est pas construit : ce que le produit garantit
//!    ici, c'est que l'argent est **vu**.

mod bac_paiements;

use bac_paiements::Bac;
use paiements::IssuePaiement;

/// Ouvre une session, la fait expirer, et rend `(commande, transaction, montant)`.
async fn session_expiree(bac: &Bac) -> (uuid::Uuid, uuid::Uuid, i64) {
    let commande = bac.commande_prepayee().await;
    let (statut, corps) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let transaction = corps["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = corps["montant_unites"].as_i64().unwrap();

    bac.perimer_session(commande).await;
    paiements::balayer(&bac.paiements, &bac.cmd.commandes, bac.fournisseur.as_ref())
        .await
        .expect("le balayage annule la commande");
    assert_eq!(bac.etat_commande(commande).await, "annulee");

    (commande, transaction, montant)
}

/// Le scénario complet : payé trop tard.
#[sqlx::test(migrations = "../migrations")]
async fn un_succes_tardif_ouvre_un_dossier_sans_ressusciter_la_commande(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session_expiree(&bac).await;

    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(
        reponse["traite"], true,
        "la notification a bien produit un effet : le dossier",
    );

    assert_eq!(
        bac.etats_transactions(commande).await,
        vec!["payee_hors_delai"],
    );
    assert_eq!(
        bac.etat_commande(commande).await,
        "annulee",
        "la commande n'est PAS ressuscitée (R8)",
    );
    assert!(
        bac.evenements("paiement.confirme").await.is_empty(),
        "aucune confirmation : rien ne repart au dispatch",
    );

    // Le dossier, et son événement.
    let dossiers = bac.dossiers().await;
    assert!(
        dossiers
            .iter()
            .any(|(t, m)| t == "paiement_hors_delai" && m == "paiement.dossier.paiement_hors_delai"),
        "dossiers = {dossiers:?}",
    );

    // L'événement que NTF consommera (FR-038), écrit UNE fois.
    let hors_delai = bac.evenements("paiement.hors_delai").await;
    assert_eq!(hors_delai.len(), 1);
    assert_eq!(hors_delai[0]["commande"], commande.to_string());
    assert_eq!(hors_delai[0]["montant"], montant);
    assert!(
        hors_delai[0]["retard_s"].as_i64().is_some_and(|r| r >= 0),
        "le retard se compte depuis l'ÉCHÉANCE, jamais négatif",
    );
}

/// Le fournisseur retente son succès tardif : **un seul** dossier, **un seul**
/// événement.
///
/// Sans idempotence, chaque retente ajouterait un dossier à traiter à la main —
/// et la file d'anomalies deviendrait le bruit qu'elle existe pour éviter.
#[sqlx::test(migrations = "../migrations")]
async fn le_hors_delai_ne_se_compte_qu_une_fois(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session_expiree(&bac).await;

    // Le MÊME corps trois fois : le rejeu est avalé par la contrainte.
    let corps = Bac::corps_notification(transaction, montant, "XOF", IssuePaiement::Reussi);
    let entete = bac.entete_signature(&corps);
    for _ in 0..3 {
        let (statut, _) = bac
            .post_brut(
                "/paiements/notifications/simule",
                &corps,
                &[(entete.0, entete.1.clone())],
            )
            .await;
        assert_eq!(statut, 200);
    }

    assert_eq!(bac.evenements("paiement.hors_delai").await.len(), 1);
    assert_eq!(
        bac.dossiers()
            .await
            .iter()
            .filter(|(t, _)| t == "paiement_hors_delai")
            .count(),
        1,
    );
    assert_eq!(
        bac.etats_transactions(commande).await,
        vec!["payee_hors_delai"]
    );
}

/// `payee_hors_delai` est **terminal** : plus rien n'en sort.
///
/// Une notification de succès portant une charge DIFFÉRENTE (donc pas un rejeu)
/// ne doit pas rouvrir la transaction — c'est la table fermée qui le garantit,
/// et ce test le vérifie de l'extérieur.
#[sqlx::test(migrations = "../migrations")]
async fn payee_hors_delai_ne_se_rouvre_pas(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session_expiree(&bac).await;

    bac.notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    // Une SECONDE charge, distincte de la première par son horodatage.
    tokio::time::sleep(std::time::Duration::from_millis(2)).await;
    let (statut, reponse) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;

    assert_eq!(statut, 200, "{reponse}");
    assert_eq!(
        reponse["traite"], false,
        "la transition est refusée par la table fermée",
    );
    assert_eq!(
        bac.etats_transactions(commande).await,
        vec!["payee_hors_delai"]
    );
    assert_eq!(bac.etat_commande(commande).await, "annulee");
    assert_eq!(
        bac.evenements("paiement.hors_delai").await.len(),
        1,
        "un second événement ferait notifier Awa deux fois du même retard",
    );
}

/// Le client lit son état : « expirée », et **aucun accès de paiement**.
#[sqlx::test(migrations = "../migrations")]
async fn le_client_lit_un_etat_sans_acces(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, transaction, montant) = session_expiree(&bac).await;
    bac.notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;

    let (statut, etat) = bac
        .get(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{etat}");
    assert_eq!(etat["etat"], "payee_hors_delai");
    assert!(etat["acces_paiement"].is_null());
    assert_eq!(etat["restant_s"], 0);
}
