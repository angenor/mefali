//! US5 (cycle PAY 011, T056) — la retenue de la livraison offerte, au scan.
//!
//! Ce que le test mesure, et pourquoi chaque cas existe :
//!
//! - **avance nette** (FR-050) : le coursier sort de sa poche `articles −
//!   retenue`, jamais le brut. Un net faux ici, et la caisse compte de l'argent
//!   que personne n'a versé ;
//! - **aucune retenue en multi-vendeurs** (FR-051) : l'offre d'un vendeur ne
//!   couvre pas la course des autres — vérifié aux DEUX étages, la transmission
//!   au devis et l'application au scan ;
//! - **écrêtage** (FR-052) : une retenue supérieure aux articles donne une
//!   avance nulle, jamais négative, et laisse une trace ;
//! - **aucune commande antérieure retarifée** (FR-048) : changer l'offre après
//!   coup ne touche pas un devis déjà figé.
//!
//! Le drapeau de zone qui prime sur l'offre du vendeur est vérifié là où la
//! règle vit, contre le VRAI moteur :
//! `crates/tarification/tests/evaluation.rs::drapeau_de_zone_prime_sur_offre_vendeur`.
//! Le rejouer ici contre un double ne prouverait que la fidélité du double.

mod bac_commandes;

use bac_commandes::{Bac, DEVIS_PRIX_CLIENT};
use sqlx::PgPool;
use tarification::OffreLivraison;

/// Somme des lignes vivantes d'un arrêt — les articles bruts, tels que le
/// vendeur les facture.
async fn articles_de(bac: &Bac, arret: uuid::Uuid) -> i64 {
    sqlx::query_scalar(
        "SELECT COALESCE(SUM(lc.quantite * COALESCE(lc.remplace_prix_unites, pf.prix_unites))
                    FILTER (WHERE lc.statut <> 'retiree'), 0)::bigint
           FROM commandes.ligne_commande lc
           JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
          WHERE lc.arret_id = $1",
    )
    .bind(arret)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

/// FR-050 — mono-vendeur avec livraison offerte : l'avance est le NET, et les
/// trois montants sont tracés séparément (le reçu vendeur en dépend, FR-071).
#[sqlx::test(migrations = "../migrations")]
async fn avance_nette_de_la_retenue(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_vendeur(pool).await;
    let vendeur = &bac.vendeurs[0];
    bac.declarer_offre(vendeur.id, Some(OffreLivraison::Toujours))
        .await;

    let commande = bac
        .creer_commande_api("marche", vec![vendeur.ligne(10)])
        .await;
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.arrets_de(livraison).await;
    let arret = collectes[0];

    let articles = articles_de(&bac, arret).await;
    assert!(
        articles > DEVIS_PRIX_CLIENT,
        "le panier doit dépasser la retenue pour que le net reste positif"
    );

    bac.collecter(arret).await;

    let (montant_articles, retenue, avance, ecretee) = bac.montants_arret(arret).await;
    assert_eq!(montant_articles, articles, "les articles BRUTS sont tracés");
    assert_eq!(retenue, DEVIS_PRIX_CLIENT, "la retenue du devis figé");
    assert_eq!(avance, articles - DEVIS_PRIX_CLIENT, "l'avance est le NET");
    assert!(!ecretee);

    // L'événement porte les trois montants : c'est de lui que naissent le reçu
    // vendeur et le dossier d'écrêtage (contrats §6.1).
    let evenements = bac.evenements("arret.collecte").await;
    let dernier = evenements.last().unwrap();
    assert_eq!(dernier["montant_avance"], serde_json::json!(avance));
    assert_eq!(dernier["montant_articles"], serde_json::json!(articles));
    assert_eq!(
        dernier["retenue_appliquee"],
        serde_json::json!(DEVIS_PRIX_CLIENT)
    );
    assert_eq!(dernier["retenue_ecretee"], serde_json::json!(false));
}

/// FR-051 — panier MULTI-vendeurs : CMD ne lit même pas l'offre (à qui
/// s'appliquerait-elle ?), et le scan n'applique aucune retenue même si un
/// devis en portait une.
#[sqlx::test(migrations = "../migrations")]
async fn aucune_retenue_en_multi_vendeurs(pool: PgPool) {
    // Le double sert un devis PORTANT une retenue : si le scan l'appliquait
    // quand même, le test le verrait. C'est la ceinture, en plus des bretelles
    // que `tarification` pose déjà en refusant la retenue hors mono-vendeur.
    let bac = Bac::nouveau_livraison_offerte_par_vendeur(pool).await;
    for vendeur in &bac.vendeurs {
        bac.declarer_offre(vendeur.id, Some(OffreLivraison::Toujours))
            .await;
    }

    // Quantités modestes : le plafond cash de la zone (15 000) n'est pas le
    // sujet de ce test, et le franchir le ferait échouer pour la mauvaise
    // raison.
    let lignes: Vec<_> = bac.vendeurs.iter().map(|v| v.ligne(3)).collect();
    let commande = bac.creer_commande_api("marche", lignes).await;
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.arrets_de(livraison).await;

    // Étage 1 — la transmission : CMD n'a PAS lu l'offre, parce qu'il n'y a pas
    // de vendeur unique à interroger.
    let demande = bac
        .tarif
        .demandes_recues()
        .pop()
        .expect("le devis a été évalué");
    assert!(!demande.mono_vendeur);
    assert_eq!(
        demande.offre_livraison_vendeur, None,
        "aucune offre ne se transmet sur un panier multi-vendeurs"
    );

    // Étage 2 — l'application : trois arrêts de collecte, donc aucune retenue.
    for arret in &collectes {
        let articles = articles_de(&bac, *arret).await;
        bac.collecter(*arret).await;
        let (montant_articles, retenue, avance, ecretee) = bac.montants_arret(*arret).await;
        assert_eq!(montant_articles, articles);
        assert_eq!(retenue, 0, "aucune retenue sur un arrêt parmi plusieurs");
        assert_eq!(avance, articles, "l'avance reste le brut");
        assert!(!ecretee);
    }
}

/// FR-052 — retenue supérieure aux articles : l'avance tombe à zéro **sans
/// jamais devenir négative**, et le fait est tracé pour qu'un dossier s'ouvre.
///
/// Le cas se produit pour de vrai : le devis fige une retenue de 2 500 sur un
/// panier de 5 000, puis le coursier retire des lignes en rupture jusqu'à
/// descendre sous la retenue.
#[sqlx::test(migrations = "../migrations")]
async fn retenue_superieure_aux_articles_ecrete_a_zero(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_vendeur(pool).await;
    let vendeur_id = bac.vendeurs[0].id;
    bac.declarer_offre(vendeur_id, Some(OffreLivraison::Toujours))
        .await;

    // Article 0 à 500 F : 6 unités = 3 000 F, au-dessus de la retenue de 2 500.
    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(6)])
        .await;
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.arrets_de(livraison).await;
    let arret = collectes[0];

    // Le panier fond sous la retenue : la ligne unique est retirée en rupture.
    let lignes = bac.lignes_de(arret).await;
    bac.retirer_ligne(lignes[0]).await;
    assert_eq!(articles_de(&bac, arret).await, 0, "plus rien à acheter");

    bac.collecter(arret).await;

    let (montant_articles, retenue, avance, ecretee) = bac.montants_arret(arret).await;
    assert_eq!(montant_articles, 0);
    assert_eq!(retenue, 0, "on ne retient pas plus que ce qui existe");
    assert_eq!(avance, 0, "JAMAIS négative — le coursier ne finance rien");
    assert!(
        ecretee,
        "l'écrêtage est un FAIT tracé : c'est lui qui ouvrira le dossier (T057)"
    );

    let dernier = bac.evenements("arret.collecte").await.pop().unwrap();
    assert_eq!(dernier["retenue_ecretee"], serde_json::json!(true));
}

/// T057 — l'écrêtage ouvre son dossier par l'outbox, une seule fois, et un
/// arrêt sans écrêtage n'en ouvre aucun.
///
/// C'est la seule voie par laquelle `paiements` peut apprendre ce que
/// `commandes` a fait : la flèche inverse n'existe pas (research R14).
#[sqlx::test(migrations = "../migrations")]
async fn ecretage_ouvre_son_dossier_une_seule_fois(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_vendeur(pool).await;
    bac.declarer_offre(bac.vendeurs[0].id, Some(OffreLivraison::Toujours))
        .await;

    // Arrêt A — écrêté (toutes les lignes retirées).
    let ecrete = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(6)])
        .await;
    let livraison = bac
        .commandes
        .assigner_coursier(ecrete, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.arrets_de(livraison).await;
    let lignes = bac.lignes_de(collectes[0]).await;
    bac.retirer_ligne(lignes[0]).await;
    bac.collecter(collectes[0]).await;

    // Arrêt B — retenue ordinaire, pas d'écrêtage.
    let sain = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(10)])
        .await;
    let livraison_b = bac
        .commandes
        .assigner_coursier(sain, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes_b, _) = bac.arrets_de(livraison_b).await;
    bac.collecter(collectes_b[0]).await;

    bac.drainer_dossiers().await;

    let dossiers = bac.dossiers("retenue_ecretee").await;
    assert_eq!(dossiers.len(), 1, "un seul arrêt a été écrêté");
    let (commande_id, arret_id, constate, attendu) = dossiers[0];
    assert_eq!(commande_id, Some(ecrete));
    assert_eq!(arret_id, Some(collectes[0]));
    assert_eq!(constate, Some(0), "plus rien à payer au vendeur");
    assert_eq!(
        attendu,
        Some(0),
        "la retenue a été ramenée à ce qui existait"
    );

    // Le dossier a son événement — sans lui, l'exploitation ne serait prévenue
    // par rien (contrats §6).
    assert_eq!(bac.nb_evenements("paiement.dossier_ouvert").await, 1);

    // Rejeu du journal ENTIER : l'idempotence est une contrainte de base, pas
    // un `if` — et c'est ce second passage qui le prouve.
    bac.drainer_dossiers().await;
    assert_eq!(bac.dossiers("retenue_ecretee").await.len(), 1);
    assert_eq!(bac.nb_evenements("paiement.dossier_ouvert").await, 1);
}

/// FR-082 — PAY-04 n'est pas construit : le remboursement dû à un client dont
/// la commande prépayée est annulée doit au moins être **vu**.
#[sqlx::test(migrations = "../migrations")]
async fn annulation_d_une_prepayee_ouvre_un_dossier_de_remboursement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    let commande = bac
        .creer_commande_mode("marche", vec![bac.vendeurs[0].ligne(2)], "mobile_money")
        .await;
    bac.commandes
        .confirmer_prepaiement(commande, chrono::Utc::now())
        .await
        .expect("confirmation du prépaiement");

    let (statut, corps) = bac
        .post(
            &format!("/commandes/{commande}/annuler"),
            &bac.jeton_client,
            serde_json::json!({}),
        )
        .await;
    assert_eq!(statut, 200, "annulation : {corps}");
    assert_eq!(corps["remboursement_du"], true);

    bac.drainer_dossiers().await;

    let dossiers = bac.dossiers("remboursement_client_du").await;
    assert_eq!(dossiers.len(), 1, "le dû est vu, même sans PAY-04");
    assert_eq!(dossiers[0].0, Some(commande));

    // Une annulation SANS remboursement dû (commande cash) n'ouvre rien.
    let cash = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(2)])
        .await;
    let (statut, _) = bac
        .post(
            &format!("/commandes/{cash}/annuler"),
            &bac.jeton_client,
            serde_json::json!({}),
        )
        .await;
    assert_eq!(statut, 200);
    bac.drainer_dossiers().await;
    assert_eq!(
        bac.dossiers("remboursement_client_du").await.len(),
        1,
        "rien à rembourser sur une commande cash — aucun dossier de plus"
    );
}

/// FR-048 — déclarer une offre APRÈS coup ne retarife aucune commande : le
/// devis est figé à la création, et la retenue au scan le LIT.
#[sqlx::test(migrations = "../migrations")]
async fn aucune_commande_anterieure_n_est_retarifee(pool: PgPool) {
    // Bac ordinaire : le devis figé ne porte AUCUNE retenue.
    let bac = Bac::nouveau(pool).await;
    let vendeur_id = bac.vendeurs[0].id;

    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(4)])
        .await;
    let livraison = bac.livraison_de(commande).await;
    let composantes_avant = bac.composantes_devis(livraison).await;

    // Le vendeur déclare l'offre APRÈS la création.
    bac.declarer_offre(vendeur_id, Some(OffreLivraison::Toujours))
        .await;

    assert_eq!(
        bac.composantes_devis(livraison).await,
        composantes_avant,
        "le devis figé ne bouge pas — FR-048"
    );

    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, _) = bac.arrets_de(livraison).await;
    let articles = articles_de(&bac, collectes[0]).await;
    bac.collecter(collectes[0]).await;

    let (_, retenue, avance, _) = bac.montants_arret(collectes[0]).await;
    assert_eq!(retenue, 0, "l'offre déclarée après coup ne rétroagit pas");
    assert_eq!(avance, articles);
}

/// L'offre du vendeur est bien TRANSMISE au moteur quand le panier est
/// mono-vendeur — sans quoi le client paierait une livraison que le vendeur
/// offrait, et personne ne s'en apercevrait avant la facture.
#[sqlx::test(migrations = "../migrations")]
async fn offre_transmise_au_devis_en_mono_vendeur(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.declarer_offre(bac.vendeurs[0].id, Some(OffreLivraison::AuDela(5_000)))
        .await;

    bac.creer_commande_api("marche", vec![bac.vendeurs[0].ligne(2)])
        .await;

    let demande = bac.tarif.demandes_recues().pop().unwrap();
    assert!(demande.mono_vendeur);
    assert_eq!(
        demande.offre_livraison_vendeur,
        Some(OffreLivraison::AuDela(5_000)),
        "le type de tarification traverse tel quel (research R10)"
    );
    // C'est `tarification` qui décide si l'offre joue — CMD ne fait que la
    // transmettre avec le montant du panier.
    assert_eq!(demande.montant_panier, 1_000);
}
