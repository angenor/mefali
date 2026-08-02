//! Le bac du cycle PAY tient debout — préalable de tous les tests suivants.
//!
//! Ce fichier ne teste aucune règle de paiement : il vérifie que le **terrain**
//! est celui qu'on croit. Un bac qui seedrait ses paramètres au mauvais niveau
//! d'héritage, ou qui créerait des commandes cash là où le test attend du
//! prépaiement, rendrait verts des tests qui ne prouvent rien — et ce genre de
//! faux vert ne se découvre qu'en production.

mod bac_paiements;

use bac_paiements::Bac;

/// Les 4 paramètres sont posés au PAYS et **hérités** par Tiassalé.
///
/// Le test lit la configuration depuis la VILLE, jamais depuis le pays : c'est
/// ainsi que la production la lit. Un seed posé directement sur la ville
/// passerait ce test et casserait en production, où l'héritage est le chemin.
#[sqlx::test(migrations = "../migrations")]
async fn les_quatre_parametres_sont_herites_par_la_ville(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let config = bac
        .paiements
        .config(bac.cmd.ville)
        .await
        .expect("la configuration de paiement se résout depuis la ville");

    assert_eq!(config.session_duree_s, bac_paiements::SESSION_DUREE_S);
    assert_eq!(
        config.reconciliation_avant_expiration_s,
        bac_paiements::RECONCILIATION_S
    );
    assert_eq!(
        config.creance_alerte_unites,
        bac_paiements::CREANCE_ALERTE_UNITES
    );
    assert!(
        config.moyens_actifs.is_empty(),
        "le coupe-circuit est au repos — FR-011 interdit de masquer un moyen",
    );
    assert_eq!(config.devise, "XOF", "la devise vient de la zone");
}

/// Une commande créée par `commande_prepayee` naît bien **en attente de
/// paiement**, parce qu'elle dépasse le plafond cash.
///
/// C'est la précondition de tout le cycle : si elle naissait `nouvelle`, tous
/// les tests de session s'ouvriraient sur une commande qui n'attend rien.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_prepayee_nait_en_attente_de_paiement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;

    assert_eq!(
        bac.etat_commande(commande).await,
        "en_attente_paiement",
        "au-dessus du plafond cash, la commande attend son paiement",
    );
    // ⚠ CORRECTION DE research R16, constatée en écrivant ce test.
    //
    // R16 affirme qu'« aucune ligne de code ne pose jamais `en_attente` ». C'est
    // FAUX pour le chemin de CRÉATION : `creation.rs` écrit déjà
    // `etat_paiement = 'en_attente'` quand le mode est `mobile_money`.
    //
    // Le trou existe bel et bien, mais il est ailleurs et plus étroit : c'est la
    // **bascule du dispatch** (`exiger_prepaiement`, DSP-09) qui l'oublie. Elle
    // passe `mode_paiement` à `mobile_money` et le tronc à
    // `en_attente_paiement`, sans jamais toucher `etat_paiement` — une commande
    // basculée reste donc à `'du'`, indiscernable d'une commande cash.
    //
    // C'est exactement ce que `marquer_paiement_en_attente` comble, et sa garde
    // `WHERE etat_paiement = 'du'` s'en trouve confirmée : sur ce chemin-ci elle
    // ne touche rien (la valeur est déjà bonne), sur celui de la bascule elle
    // corrige. Le test `la_bascule_du_dispatch_oublie_l_etat_de_paiement`
    // ci-dessous fige la découverte pour qu'elle ne se reperde pas.
    assert_eq!(
        bac.etat_paiement(commande).await,
        "en_attente",
        "à la CRÉATION, `en_attente` est déjà posé (contrairement à R16)",
    );
    assert!(
        bac.etats_transactions(commande).await.is_empty(),
        "aucune transaction avant l'appel explicite à l'ouverture (R2)",
    );
}

/// **Le vrai trou de R16**, isolé et figé.
///
/// La bascule prépaiement du dispatch (DSP-09, `exiger_prepaiement`) fait passer
/// une commande cash en `en_attente_paiement` quand aucun coursier ne peut
/// avancer les fonds. Elle change `mode_paiement` et l'état du tronc, mais
/// **pas** `etat_paiement` : la commande reste à `'du'`.
///
/// Conséquence concrète : une commande basculée est indiscernable d'une commande
/// cash pour toute lecture qui interroge `etat_paiement`. C'est ce que
/// `CommandesAPayer::marquer_paiement_en_attente` comble à l'ouverture de
/// session.
///
/// Le test constate l'état **avant** correction, puis vérifie que le port le
/// corrige. Si un jour `exiger_prepaiement` pose la valeur lui-même, la première
/// assertion tombera — et ce sera une bonne nouvelle à traiter, pas un bug.
#[sqlx::test(migrations = "../migrations")]
async fn la_bascule_du_dispatch_oublie_l_etat_de_paiement(pool: sqlx::PgPool) {
    use commandes::{CommandesADispatcher, CommandesAPayer};

    let bac = Bac::nouveau(pool).await;
    // Une commande CASH ordinaire — sous le plafond, donc née `nouvelle`.
    let vendeur = &bac.cmd.vendeurs[0];
    let commande = bac
        .cmd
        .creer_commande_api("marche", vec![vendeur.ligne(1)])
        .await;
    assert_eq!(bac.etat_paiement(commande).await, "du");

    // La bascule du dispatch : aucun coursier ne peut avancer.
    bac.cmd
        .commandes
        .exiger_prepaiement(
            commande,
            commandes::MotifPrepaiementDispatch::CapaciteAvanceCoursier,
            bac.paiements.maintenant(),
        )
        .await
        .expect("la bascule prépaiement");

    assert_eq!(
        bac.etat_commande(commande).await,
        "en_attente_paiement",
        "le tronc a bien basculé",
    );
    assert_eq!(
        bac.etat_paiement(commande).await,
        "du",
        "⚠ LE TROU — la bascule ne pose pas `en_attente` : la commande est \
         indiscernable d'une commande cash pour toute lecture d'`etat_paiement`",
    );

    // Le port le comble, et c'est là toute son utilité.
    bac.cmd
        .commandes
        .marquer_paiement_en_attente(commande, bac.paiements.maintenant())
        .await
        .unwrap();
    assert_eq!(
        bac.etat_paiement(commande).await,
        "en_attente",
        "R16 fermé — sur le chemin où il était réellement ouvert",
    );

    // Idempotent : un rappel de l'ouverture ne casse rien et ne régresse pas.
    bac.cmd
        .commandes
        .marquer_paiement_en_attente(commande, bac.paiements.maintenant())
        .await
        .unwrap();
    assert_eq!(bac.etat_paiement(commande).await, "en_attente");
}

/// « Porter l'horloge au-delà de l'échéance » produit bien l'état qu'une
/// session échue aurait — sans toucher au code de production.
#[sqlx::test(migrations = "../migrations")]
async fn perimer_une_session_la_rend_echue(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;

    // Session posée à la main : l'endpoint d'ouverture arrive en T019, et ce
    // test porte sur l'aide du bac, pas sur lui.
    let mut tx = bac.cmd.pool.begin().await.unwrap();
    let maintenant = bac.paiements.maintenant();
    bac.paiements
        .inserer_transaction(
            &mut tx,
            uuid::Uuid::now_v7(),
            commande,
            bac_paiements::AU_DESSUS_DU_PLAFOND,
            "XOF",
            "simule",
            None,
            None,
            maintenant,
            maintenant + Bac::duree_session(),
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let avant = bac
        .paiements
        .transaction_vivante(commande)
        .await
        .unwrap()
        .expect("une session vivante");
    assert!(
        !avant.echue(bac.paiements.maintenant()),
        "une session fraîche n'est pas échue",
    );
    assert!(avant.restant_s(bac.paiements.maintenant()) > 0);

    bac.perimer_session(commande).await;

    let apres = bac
        .paiements
        .transaction_vivante(commande)
        .await
        .unwrap()
        .expect("la session existe toujours : elle est échue, pas supprimée");
    assert!(
        apres.echue(bac.paiements.maintenant()),
        "l'échéance est franchie",
    );
    assert_eq!(
        apres.restant_s(bac.paiements.maintenant()),
        0,
        "le temps restant tombe à zéro, jamais sous zéro",
    );
    assert_eq!(
        apres.etat.comme_str(),
        "ouverte",
        "R7 — la LECTURE fait foi : la session est échue avant même que le \
         balayage ne l'ait matérialisée",
    );
}

/// L'index partiel `transaction_vivante_unique` refuse une **seconde** session
/// vivante sur la même commande.
///
/// C'est la base qui porte l'idempotence de l'ouverture (FR-015), et non un
/// `if` dans le handler : deux requêtes concurrentes passeraient toutes deux un
/// test préalable avant que l'une n'écrive.
#[sqlx::test(migrations = "../migrations")]
async fn deux_sessions_vivantes_sont_impossibles(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let maintenant = bac.paiements.maintenant();

    let poser = |id| {
        let paiements = bac.paiements.clone();
        let pool = bac.cmd.pool.clone();
        async move {
            let mut tx = pool.begin().await.unwrap();
            let r = paiements
                .inserer_transaction(
                    &mut tx,
                    id,
                    commande,
                    bac_paiements::AU_DESSUS_DU_PLAFOND,
                    "XOF",
                    "simule",
                    None,
                    None,
                    maintenant,
                    maintenant + Bac::duree_session(),
                )
                .await;
            if r.is_ok() {
                tx.commit().await.unwrap();
            }
            r
        }
    };

    poser(uuid::Uuid::now_v7())
        .await
        .expect("la première passe");
    let seconde = poser(uuid::Uuid::now_v7()).await;
    assert!(
        seconde.is_err(),
        "une SECONDE session vivante doit être refusée par la base — c'est \
         l'index partiel qui rend `POST /commandes/{{id}}/paiement` idempotent, \
         pas une vérification préalable qui perdrait la course",
    );
}
