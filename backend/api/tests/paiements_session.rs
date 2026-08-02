//! US1 — « Payer d'avance sans quitter le parcours » (PAY-01, PAY-02).
//!
//! Tout passe par une **requête HTTP réelle** : les gardes de rôle et de
//! propriété n'existent que dans la couche HTTP, et un test qui appellerait le
//! domaine ne prouverait rien sur elles. La leçon a été payée deux fois, aux
//! cycles 009 et 010.

mod bac_paiements;

use bac_paiements::Bac;
use paiements::IssuePaiement;

/// Le parcours nominal, de bout en bout.
///
/// Une commande au-dessus du plafond cash naît `en_attente_paiement` ; son
/// ouverture rend un accès de paiement, une échéance **persistée** et un temps
/// restant calculé côté serveur.
#[sqlx::test(migrations = "../migrations")]
async fn le_parcours_nominal_ouvre_une_session(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;

    let (statut, corps) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;

    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["etat"], "ouverte");
    assert_eq!(corps["devise"], "XOF");
    assert!(
        corps["acces_paiement"]
            .as_str()
            .is_some_and(|u| !u.is_empty()),
        "une session vivante sert l'accès à ouvrir dans le navigateur système",
    );
    assert_eq!(
        corps["moyen"], "inconnu",
        "le moyen n'est JAMAIS deviné : il vient du fournisseur (FR-012)",
    );

    // Le temps restant vient du SERVEUR, pas de l'horloge de l'app (FR-017).
    let restant = corps["restant_s"].as_i64().expect("restant_s entier");
    assert!(
        restant > bac_paiements::SESSION_DUREE_S - 60 && restant <= bac_paiements::SESSION_DUREE_S,
        "restant_s ≈ la durée seedée ({}), lu {restant}",
        bac_paiements::SESSION_DUREE_S,
    );

    // L'échéance est PERSISTÉE, et calculée depuis le paramètre de zone.
    let echeance = bac
        .echeance(commande)
        .await
        .expect("une échéance persistée");
    let ouverture = echeance - Bac::duree_session();
    assert!(
        (chrono::Utc::now() - ouverture).num_seconds().abs() < 60,
        "l'échéance vaut ouverture + `paiement.session_duree_s`",
    );

    // Le trou de R16 est comblé sur les deux chemins de création.
    assert_eq!(bac.etat_paiement(commande).await, "en_attente");
    assert_eq!(bac.etat_commande(commande).await, "en_attente_paiement");

    // Un événement, et un seul. Sans `acces_paiement` dedans (FR-103).
    let evenements = bac.evenements("paiement.session_ouverte").await;
    assert_eq!(evenements.len(), 1);
    let charge = &evenements[0];
    assert_eq!(charge["commande"], commande.to_string());
    assert_eq!(charge["fournisseur"], "simule");
    assert!(
        !charge.to_string().contains("acces_paiement"),
        "l'accès de paiement n'entre JAMAIS dans un événement (FR-006, FR-103)",
    );
}

/// FR-015 — **l'idempotence**. Deux `POST` → une session, une ouverture chez le
/// fournisseur, un événement.
///
/// C'est le cas d'Awa qui tape deux fois sur le bouton, ou dont la connexion
/// vacille et dont l'app rejoue. Rouvrir chez le fournisseur créerait deux
/// encaissements pour une commande.
#[sqlx::test(migrations = "../migrations")]
async fn deux_ouvertures_ne_font_qu_une_session(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let uri = format!("/commandes/{commande}/paiement");

    let (s1, c1) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    let (s2, c2) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;

    assert_eq!((s1, s2), (200, 200), "{c1} / {c2}");
    assert_eq!(
        c1["transaction_id"], c2["transaction_id"],
        "la MÊME session est renvoyée, pas une seconde",
    );
    assert_eq!(
        bac.etats_transactions(commande).await,
        vec!["ouverte".to_owned()],
        "une seule ligne de transaction",
    );
    assert_eq!(
        bac.fournisseur.ouvertures(),
        1,
        "le fournisseur n'est appelé QU'UNE fois — un second appel ouvrirait \
         un second encaissement pour une seule commande",
    );
    assert_eq!(bac.evenements("paiement.session_ouverte").await.len(), 1);
}

/// FR-005 — la garde de **propriété**, dans la couche HTTP.
///
/// Un autre client authentifié, avec un rôle valide, ne peut pas ouvrir la
/// session d'une commande qui n'est pas la sienne.
#[sqlx::test(migrations = "../migrations")]
async fn un_autre_client_ne_peut_ni_ouvrir_ni_lire(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let uri = format!("/commandes/{commande}/paiement");

    let (statut, corps) = bac.post_vide(&uri, &bac.cmd.jeton_intrus).await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "commande_interdite");
    assert!(
        bac.etats_transactions(commande).await.is_empty(),
        "un refus n'écrit rien",
    );

    // La lecture est gardée de la même façon — sinon l'intrus lirait le montant.
    bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    let (statut, corps) = bac.get(&uri, &bac.cmd.jeton_intrus).await;
    assert_eq!(statut, 403, "{corps}");
}

/// `409 paiement_non_requis` — une commande payée en espèces ne passe par aucun
/// fournisseur.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_cash_ne_s_ouvre_pas_au_paiement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = &bac.cmd.vendeurs[0];
    let commande = bac
        .cmd
        .creer_commande_api("marche", vec![vendeur.ligne(1)])
        .await;

    let uri = format!("/commandes/{commande}/paiement");
    let (statut, corps) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "paiement_non_requis");

    // Et sa lecture rend 404 : il n'y a rien à lire, ce n'est pas une erreur.
    let (statut, corps) = bac.get(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(statut, 404, "{corps}");
    assert_eq!(corps["code"], "transaction_inconnue");
}

/// FR-018 — un fournisseur injoignable rend `502` et **ne laisse rien
/// derrière**.
///
/// C'est la garantie qui permet de réessayer : si l'échec laissait une ligne de
/// transaction, la commande serait bloquée par sa propre tentative ratée.
#[sqlx::test(migrations = "../migrations")]
async fn un_fournisseur_indisponible_laisse_la_commande_intacte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let uri = format!("/commandes/{commande}/paiement");

    bac.fournisseur
        .scenario(paiements::ScenarioSimule::Indisponible);
    let (statut, corps) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(statut, 502, "{corps}");
    assert_eq!(corps["code"], "fournisseur_indisponible");

    assert!(
        bac.etats_transactions(commande).await.is_empty(),
        "AUCUNE ligne de transaction : l'écriture vient après l'appel réseau",
    );
    assert!(bac.evenements("paiement.session_ouverte").await.is_empty());
    assert_eq!(bac.etat_commande(commande).await, "en_attente_paiement");

    // Le fournisseur revient : la même commande s'ouvre normalement.
    bac.fournisseur.scenario(paiements::ScenarioSimule::Succes);
    let (statut, corps) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    assert_eq!(statut, 200, "{corps}");
}

/// FR-023 — la confirmation rend la commande au dispatch.
///
/// `commande.paiement_confirme` est consommé par le pipeline de dispatch depuis
/// le cycle 009 : ce test **vérifie** que la chaîne se referme, il ne câble
/// rien. Ce qu'il prouve, c'est que la commande redevient `nouvelle` et
/// **réapparaît dans la file d'attente de coursier** — sans quoi Awa aurait
/// payé une commande que personne ne viendrait chercher.
#[sqlx::test(migrations = "../migrations")]
async fn la_confirmation_rend_la_commande_au_dispatch(pool: sqlx::PgPool) {
    use commandes::CommandesADispatcher;

    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;

    assert!(
        bac.cmd
            .commandes
            .affecter(commande, bac.cmd.coursier)
            .await
            .is_err(),
        "tant qu'elle n'est pas payée, la commande n'est PAS affectable",
    );

    let (_, session) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    let transaction: uuid::Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();

    let (statut, corps) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["traite"], true);

    assert_eq!(bac.etats_transactions(commande).await, vec!["reglee"]);
    assert_eq!(bac.etat_commande(commande).await, "nouvelle");
    assert_eq!(bac.etat_paiement(commande).await, "regle");

    let evenements = bac.evenements("paiement.confirme").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["commande"], commande.to_string());
    assert!(
        evenements[0]["delai_confirmation_s"].as_i64().is_some(),
        "le délai de confirmation alimente MET-01",
    );
    assert_eq!(
        bac.cmd.nb_evenements("commande.paiement_confirme").await,
        1,
        "l'événement que le pipeline de dispatch consomme depuis le cycle 009",
    );

    // Et seulement ALORS l'affectation devient possible : c'est ce que le
    // pipeline de dispatch fait en consommant l'événement ci-dessus. Le
    // vérifier par la transition plutôt qu'en montant `PgDispatch` garde le bac
    // du cycle PAY indépendant du cycle 009 — dont les propres tests couvrent
    // le consommateur.
    bac.cmd
        .commandes
        .affecter(commande, bac.cmd.coursier)
        .await
        .expect("payée, la commande redevient affectable");
    assert_eq!(bac.etat_commande(commande).await, "en_cours");

    // L'accès de paiement disparaît de la lecture ET de la base.
    let (_, etat) = bac
        .get(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(etat["etat"], "reglee");
    assert!(etat["acces_paiement"].is_null());
    assert_eq!(etat["restant_s"], 0);
}
