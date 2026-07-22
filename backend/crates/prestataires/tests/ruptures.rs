//! US5 — Signaler une rupture par trois chemins (VND-04).
//!
//! SC-008 : trois sources tracées, précondition de commande active (port
//! simulé), rejeu idempotent, masquage à 2 coursiers DISTINCTS / 7 jours,
//! levée vendeur puis RE-masquage immédiat, verrou admin, sortie de fenêtre
//! (UPDATE SQL de `recu_le` — patron du cycle 003), article retiré non
//! signalable.

mod bac;

use bac::Bac;
use chrono::Utc;
use prestataires::{ErreurPrestataires, NouvelArticle, SourceBascule};
use sqlx::PgPool;
use uuid::Uuid;

async fn vendeur_avec_article(bac: &Bac) -> (Uuid, Uuid) {
    let vendeur = bac.prospect_complet("Boutique Kofi", "boutique_superette").await;
    bac.agreer(vendeur).await;
    let mut tx = bac.pool.begin().await.unwrap();
    let article = bac
        .depot
        .creer_article(
            &mut tx,
            vendeur,
            &NouvelArticle {
                nom: "Garba".to_owned(),
                prix_unites: 1000,
                prix_barre_unites: None,
                categorie_interne: None,
            },
            SourceBascule::Admin,
            bac.admin,
        )
        .await
        .unwrap()
        .id;
    tx.commit().await.unwrap();
    (vendeur, article)
}

async fn disponible(bac: &Bac, vendeur: Uuid, article: Uuid) -> bool {
    bac.depot
        .articles_du_vendeur(vendeur)
        .await
        .unwrap()
        .into_iter()
        .find(|a| a.id == article)
        .unwrap()
        .disponible
}

async fn signaler(
    bac: &Bac,
    id: Uuid,
    article: Uuid,
    coursier: Uuid,
) -> Result<prestataires::SignalementRecu, ErreurPrestataires> {
    let mut tx = bac.pool.begin().await.unwrap();
    let issue = bac
        .depot
        .signaler_rupture(&mut tx, id, article, coursier, Utc::now())
        .await;
    if issue.is_ok() {
        tx.commit().await.unwrap();
    }
    issue
}

/// FR-037 — bascule vendeur puis admin : source ET auteur tracés, chaque
/// bascule émet son événement (FR-043) ; rejeu sans changement = rien.
#[sqlx::test(migrations = "../../migrations")]
async fn bascules_vendeur_et_admin_tracees(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (vendeur, article) = vendeur_avec_article(&bac).await;
    let kofi = bac.creer_compte("+2250700000002").await;

    let mut tx = bac.pool.begin().await.unwrap();
    let bascule = bac
        .depot
        .basculer_disponibilite(&mut tx, vendeur, article, false, SourceBascule::Vendeur, kofi)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(!bascule.disponible);
    assert_eq!(bascule.source_derniere_bascule, Some(SourceBascule::Vendeur));

    // Rejeu sans changement d'état : aucune écriture, aucun événement.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, false, SourceBascule::Vendeur, kofi)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    let ruptures = bac.evenements("article.mis_en_rupture").await;
    assert_eq!(ruptures.len(), 1);
    assert_eq!(ruptures[0]["source"], serde_json::json!("vendeur"));
    assert_eq!(ruptures[0]["automatique"], serde_json::json!(false));
    assert_eq!(ruptures[0]["acteur"], serde_json::json!(kofi));

    // Remise en vente par le vendeur (bascule non admin) : autorisée.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, true, SourceBascule::Vendeur, kofi)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    let retours = bac.evenements("article.remis_en_vente").await;
    assert_eq!(retours.len(), 1, "consommé par VND-09 (T4)");
}

/// FR-041 — une rupture posée par l'ADMIN n'est levée que par l'admin.
#[sqlx::test(migrations = "../../migrations")]
async fn rupture_admin_verrouillee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (vendeur, article) = vendeur_avec_article(&bac).await;
    let kofi = bac.creer_compte("+2250700000002").await;

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, false, SourceBascule::Admin, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let mut tx = bac.pool.begin().await.unwrap();
    let refus = bac
        .depot
        .basculer_disponibilite(&mut tx, vendeur, article, true, SourceBascule::Vendeur, kofi)
        .await
        .unwrap_err();
    assert!(matches!(refus, ErreurPrestataires::RuptureAdmin));
    drop(tx);

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, true, SourceBascule::Admin, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(disponible(&bac, vendeur, article).await);
}

/// SC-008 — le cœur de VND-04 : éligibilité, comptage par coursiers
/// DISTINCTS, masquage automatique, levée, re-masquage, fenêtre.
#[sqlx::test(migrations = "../../migrations")]
async fn masquage_automatique_de_bout_en_bout(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (vendeur, article) = vendeur_avec_article(&bac).await;
    let yao = bac.creer_compte("+2250700000021").await;
    let ali = bac.creer_compte("+2250700000022").await;
    let sans_commande = bac.creer_compte("+2250700000023").await;

    // Coursier SANS commande active : refusé, compté nulle part (FR-038).
    let refus = signaler(&bac, Uuid::now_v7(), article, sans_commande)
        .await
        .unwrap_err();
    assert!(matches!(refus, ErreurPrestataires::SignalementInterdit));
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.signalement_rupture").await,
        0
    );

    // Éligibilité posée par le déclencheur simulé (port — R5).
    bac.commandes.autoriser(yao, article);
    bac.commandes.autoriser(ali, article);

    // 1er signalement : compté, pas de masquage (seuil 2).
    let premier_id = Uuid::now_v7();
    let premier = signaler(&bac, premier_id, article, yao).await.unwrap();
    assert!(!premier.masquage_automatique);
    assert!(disponible(&bac, vendeur, article).await);

    // REJEU du même identifiant : même issue, rien recompté (FR-039).
    let rejeu = signaler(&bac, premier_id, article, yao).await.unwrap();
    assert!(rejeu.rejeu);
    // Second signalement du MÊME coursier : compté pour UN (edge case).
    signaler(&bac, Uuid::now_v7(), article, yao).await.unwrap();
    assert!(disponible(&bac, vendeur, article).await, "1 coursier distinct < 2");
    assert_eq!(bac.evenements("signalement_rupture.recu").await.len(), 2);

    // 2e coursier DISTINCT : masquage automatique (FR-040).
    let second = signaler(&bac, Uuid::now_v7(), article, ali).await.unwrap();
    assert!(second.masquage_automatique);
    assert!(!disponible(&bac, vendeur, article).await);
    let auto = bac.evenements("article.mis_en_rupture").await;
    assert_eq!(auto.len(), 1);
    assert_eq!(auto[0]["source"], serde_json::json!("coursier"));
    assert_eq!(auto[0]["automatique"], serde_json::json!(true));
    assert!(auto[0]["acteur"].is_null(), "masquage automatique : pas d'acteur");

    // Le vendeur PEUT lever le masquage automatique (FR-041)…
    let kofi = bac.creer_compte("+2250700000002").await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, true, SourceBascule::Vendeur, kofi)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(disponible(&bac, vendeur, article).await);

    // …mais la fenêtre porte encore le seuil : le signalement éligible
    // SUIVANT re-masque immédiatement (déjà en rupture ? non — remis).
    bac.commandes.autoriser(yao, article);
    let troisieme = signaler(&bac, Uuid::now_v7(), article, yao).await.unwrap();
    assert!(
        troisieme.masquage_automatique,
        "les signalements reçus RESTENT comptés dans leur fenêtre"
    );
    assert!(!disponible(&bac, vendeur, article).await);

    // Signalement sur un article DÉJÀ en rupture : compté, sans bascule.
    let quatrieme = signaler(&bac, Uuid::now_v7(), article, ali).await.unwrap();
    assert!(quatrieme.deja_en_rupture && !quatrieme.masquage_automatique);

    // SORTIE DE FENÊTRE : vieillir tous les signalements (> 7 jours), remettre
    // en vente — un signalement seul ne masque plus (FR-040).
    sqlx::query(
        "UPDATE prestataires.signalement_rupture
         SET recu_le = now() - interval '8 days'",
    )
    .execute(&bac.pool)
    .await
    .unwrap();
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, true, SourceBascule::Vendeur, kofi)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    let seul = signaler(&bac, Uuid::now_v7(), article, ali).await.unwrap();
    assert!(
        !seul.masquage_automatique,
        "les signalements sortis de la fenêtre ne comptent plus"
    );
    assert!(disponible(&bac, vendeur, article).await);
}

/// FR-055 — un article RETIRÉ n'est ni basculable ni signalable.
#[sqlx::test(migrations = "../../migrations")]
async fn article_retire_ni_basculable_ni_signalable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (vendeur, article) = vendeur_avec_article(&bac).await;
    let yao = bac.creer_compte("+2250700000021").await;
    bac.commandes.autoriser(yao, article);

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .retirer_article(&mut tx, vendeur, article, SourceBascule::Vendeur, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let mut tx = bac.pool.begin().await.unwrap();
    assert!(matches!(
        bac.depot
            .basculer_disponibilite(&mut tx, vendeur, article, false, SourceBascule::Vendeur, bac.admin)
            .await
            .unwrap_err(),
        ErreurPrestataires::ArticleRetire(_)
    ));
    drop(tx);
    assert!(matches!(
        signaler(&bac, Uuid::now_v7(), article, yao).await.unwrap_err(),
        ErreurPrestataires::ArticleRetire(_)
    ));
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.signalement_rupture").await,
        0
    );
}

/// Article créé AVANT le site (l'Admin saisit le catalogue pendant la visite
/// terrain) : la bascule ne peut pas aboutir puisqu'aucune ligne de
/// disponibilité n'existe encore. Elle doit être REFUSÉE et n'émettre AUCUN
/// événement — sans quoi l'appel répondrait 200 sans rien écrire et chaque
/// rejeu gonflerait l'outbox d'une transition qui n'a pas eu lieu (SC-009 :
/// les indicateurs du module se calculent à partir de ces événements).
/// Une fois le site posé, l'article est rattrapé et redevient basculable.
#[sqlx::test(migrations = "../../migrations")]
async fn bascule_refusee_tant_que_le_site_manque(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = bac.creer_fiche("Étal sans site", "restauration").await;
    let mut tx = bac.pool.begin().await.unwrap();
    let article = bac
        .depot
        .creer_article(
            &mut tx,
            vendeur,
            &NouvelArticle {
                nom: "Attiéké".to_owned(),
                prix_unites: 1500,
                prix_barre_unites: None,
                categorie_interne: None,
            },
            SourceBascule::Admin,
            bac.admin,
        )
        .await
        .unwrap()
        .id;
    tx.commit().await.unwrap();
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.disponibilite_article").await,
        0,
        "sans site, aucune ligne de disponibilité n'est garnie"
    );

    // Deux tentatives : la seconde prouve qu'un rejeu n'accumule rien non plus.
    for _ in 0..2 {
        let mut tx = bac.pool.begin().await.unwrap();
        assert!(matches!(
            bac.depot
                .basculer_disponibilite(&mut tx, vendeur, article, false, SourceBascule::Admin, bac.admin)
                .await
                .unwrap_err(),
            ErreurPrestataires::SiteInconnu(_)
        ));
        drop(tx);
    }
    assert_eq!(
        bac.evenements("article.mis_en_rupture").await.len(),
        0,
        "aucun événement ne doit être émis quand aucune ligne n'a bougé"
    );

    // Le site apparaît : les articles déjà saisis reçoivent leur disponibilité.
    bac.completer_fiche(vendeur).await;
    assert!(disponible(&bac, vendeur, article).await);

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .basculer_disponibilite(&mut tx, vendeur, article, false, SourceBascule::Admin, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(!disponible(&bac, vendeur, article).await);
    assert_eq!(bac.evenements("article.mis_en_rupture").await.len(), 1);
}
