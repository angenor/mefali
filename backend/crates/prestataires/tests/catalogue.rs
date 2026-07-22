//! US2 — Tenir le catalogue et ses prix (VND-02).
//!
//! SC-005 (montant figé invariant), SC-006 (prix barré strictement supérieur,
//! refusé par l'API ET par le schéma), FR-055 (retrait réversible), R8
//! (grisé/masqué appliqué et servi par la consultation).

mod bac;

use bac::Bac;
use prestataires::modele::{AffichageRupture, HorairesSemaine, Plage};
use prestataires::{ErreurPrestataires, ModificationArticle, NouvelArticle, SourceBascule};
use sqlx::PgPool;
use uuid::Uuid;
use zones::PgZones;

/// Boutique TOUJOURS ouverte (00:00–23:59 ×7) : les assertions de
/// commandabilité ne dépendent pas de l'heure du test.
fn horaires_continus() -> HorairesSemaine {
    let mut horaires = HorairesSemaine::default();
    for jour in 0..7 {
        horaires.jours[jour].push(Plage {
            debut: chrono::NaiveTime::from_hms_opt(0, 0, 0).unwrap(),
            fin: chrono::NaiveTime::from_hms_opt(23, 59, 0).unwrap(),
        });
    }
    horaires
}

/// Un vendeur agréé, catégorie active (seuil 1), boutique toujours ouverte.
async fn vendeur_pret(bac: &Bac) -> Uuid {
    let id = bac.prospect_complet("Boutique Kofi", "boutique_superette").await;
    bac.agreer(id).await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_horaires(&mut tx, id, &horaires_continus(), SourceBascule::Admin, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    id
}

async fn creer(bac: &Bac, vendeur: Uuid, nom: &str, prix: i64, barre: Option<i64>) -> Uuid {
    let mut tx = bac.pool.begin().await.unwrap();
    let article = bac
        .depot
        .creer_article(
            &mut tx,
            vendeur,
            &NouvelArticle {
                nom: nom.to_owned(),
                prix_unites: prix,
                prix_barre_unites: barre,
                categorie_interne: None,
            },
            SourceBascule::Admin,
            bac.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    article.id
}

/// SC-006 — prix barré ≤ prix refusé par l'API ET par le CHECK du schéma ;
/// une modification qui l'invaliderait ÉCHOUE (jamais de retrait silencieux).
#[sqlx::test(migrations = "../../migrations")]
async fn prix_barre_strictement_superieur(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = vendeur_pret(&bac).await;

    // API : égal et inférieur refusés (US2 scénario 3).
    for barre in [800, 700] {
        let mut tx = bac.pool.begin().await.unwrap();
        let erreur = bac
            .depot
            .creer_article(
                &mut tx,
                vendeur,
                &NouvelArticle {
                    nom: "alloco".to_owned(),
                    prix_unites: 800,
                    prix_barre_unites: Some(barre),
                    categorie_interne: None,
                },
                SourceBascule::Vendeur,
                bac.admin,
            )
            .await
            .unwrap_err();
        assert!(matches!(erreur, ErreurPrestataires::PrixBarreInvalide));
    }

    // SCHÉMA : le CHECK refuse tout chemin d'écriture, même SQL direct.
    let contrainte = sqlx::query(
        "INSERT INTO prestataires.article (id, vendeur_id, nom, prix_unites, devise, prix_barre_unites)
         VALUES ($1, $2, 'triche', 800, 'XOF', 800)",
    )
    .bind(Uuid::now_v7())
    .bind(vendeur)
    .execute(&bac.pool)
    .await
    .unwrap_err();
    assert!(
        contrainte.to_string().contains("prix_barre_strictement_superieur"),
        "le CHECK porte FR-023 au niveau du schéma : {contrainte}"
    );

    // Valide : 800 barré 1 000 → promotion exposée, devise DE LA ZONE (R13).
    let article = creer(&bac, vendeur, "alloco", 800, Some(1_000)).await;
    let fiche = bac.depot.fiche_publique_de(vendeur).await.unwrap().unwrap();
    let publie = fiche.articles.iter().find(|a| a.id == article).unwrap();
    assert_eq!(publie.prix_unites, 800);
    assert_eq!(publie.prix_barre_unites, Some(1_000));
    assert_eq!(publie.devise, "XOF", "posée par le serveur, jamais par le client");

    // Edge case spec — baisser le prix SOUS le barré reste valide…
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_article(
            &mut tx,
            vendeur,
            article,
            &ModificationArticle {
                prix_unites: Some(700),
                ..Default::default()
            },
            SourceBascule::Vendeur,
            bac.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    // …le porter À ÉGALITÉ échoue, la promotion n'est PAS retirée en silence.
    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .modifier_article(
            &mut tx,
            vendeur,
            article,
            &ModificationArticle {
                prix_unites: Some(1_000),
                ..Default::default()
            },
            SourceBascule::Vendeur,
            bac.admin,
        )
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurPrestataires::PrixBarreInvalide));
    drop(tx);
    let inchange = bac.depot.articles_du_vendeur(vendeur).await.unwrap();
    assert_eq!(inchange[0].prix_unites, 700, "l'échec n'a rien écrit");
    assert_eq!(inchange[0].prix_barre_unites, Some(1_000));
}

/// SC-005 — un montant figé ne varie JAMAIS, quelle que soit la suite des
/// modifications de prix (déclencheur simulé du cycle CMD — R6).
#[sqlx::test(migrations = "../../migrations")]
async fn prix_fige_invariant(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = vendeur_pret(&bac).await;
    let article = creer(&bac, vendeur, "attiéké poisson", 1_500, None).await;

    // Verrouillage — la commande d'Awa, simulée par appel direct (R6).
    let mut tx = bac.pool.begin().await.unwrap();
    let fige = bac.depot.figer_prix(&mut tx, vendeur, article).await.unwrap();
    tx.commit().await.unwrap();
    assert_eq!(fige.prix_unites, 1_500);

    // La promotion arrive APRÈS : le montant figé ne bouge pas.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_article(
            &mut tx,
            vendeur,
            article,
            &ModificationArticle {
                prix_unites: Some(1_200),
                prix_barre_unites: Some(Some(1_500)),
                ..Default::default()
            },
            SourceBascule::Vendeur,
            bac.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let relu = bac.depot.prix_fige(fige.id).await.unwrap();
    assert_eq!(relu.prix_unites, 1_500, "le montant figé n'a pas bougé (SC-005)");
    assert_eq!(relu.devise, "XOF");

    // Un verrouillage SUIVANT prend le nouveau prix (FR-024).
    let mut tx = bac.pool.begin().await.unwrap();
    let suivant = bac.depot.figer_prix(&mut tx, vendeur, article).await.unwrap();
    tx.commit().await.unwrap();
    assert_eq!(suivant.prix_unites, 1_200);
}

/// FR-055 — retrait RÉVERSIBLE : plus servi ni commandable, la ligne subsiste,
/// remise sans ressaisie, chaque bascule émet son événement.
#[sqlx::test(migrations = "../../migrations")]
async fn retrait_reversible_du_catalogue(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = vendeur_pret(&bac).await;
    let article = creer(&bac, vendeur, "garba", 1_000, None).await;

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .retirer_article(&mut tx, vendeur, article, SourceBascule::Vendeur, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    // Plus servi, plus commandable, la LIGNE subsiste.
    let fiche = bac.depot.fiche_publique_de(vendeur).await.unwrap().unwrap();
    assert!(fiche.articles.iter().all(|a| a.id != article), "absent du public");
    assert!(
        bac.depot
            .articles_commandables_de(vendeur)
            .await
            .unwrap()
            .iter()
            .all(|a| a.id != article),
        "non commandable (SC-004)"
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.article").await,
        1,
        "la ligne subsiste (commandes passées, agrégats)"
    );
    // Un article retiré n'est pas modifiable (remise d'abord).
    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .modifier_article(
            &mut tx,
            vendeur,
            article,
            &ModificationArticle {
                prix_unites: Some(900),
                ..Default::default()
            },
            SourceBascule::Vendeur,
            bac.admin,
        )
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurPrestataires::ArticleRetire(_)));
    drop(tx);

    // Rejeu du retrait : sans effet, sans second événement.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .retirer_article(&mut tx, vendeur, article, SourceBascule::Vendeur, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(bac.evenements("article.retire_du_catalogue").await.len(), 1);

    // Remise SANS ressaisie : il revient tel qu'il était.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .remettre_article(&mut tx, vendeur, article, SourceBascule::Admin, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    let fiche = bac.depot.fiche_publique_de(vendeur).await.unwrap().unwrap();
    let revenu = fiche.articles.iter().find(|a| a.id == article).unwrap();
    assert_eq!(revenu.prix_unites, 1_000);
    assert!(revenu.disponible);
    assert_eq!(bac.evenements("article.remis_au_catalogue").await.len(), 1);
}

/// FR-042/FR-050 (R8) — le mode de la catégorie est APPLIQUÉ et SERVI :
/// `grise` sert l'article indisponible, `masque` l'omet.
#[sqlx::test(migrations = "../../migrations")]
async fn rupture_grisee_ou_masquee_selon_la_categorie(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = vendeur_pret(&bac).await;
    let en_vente = creer(&bac, vendeur, "riz sauce graine", 2_000, None).await;
    let en_rupture = creer(&bac, vendeur, "garba", 1_000, None).await;
    // La bascule de disponibilité arrive avec US5 — l'état est posé en SQL.
    sqlx::query("UPDATE prestataires.disponibilite_article SET disponible = false WHERE article_id = $1")
        .bind(en_rupture)
        .execute(&bac.pool)
        .await
        .unwrap();

    // Mode `grise` (seed) : servi, indisponible, non commandable.
    let fiche = bac.depot.fiche_publique_de(vendeur).await.unwrap().unwrap();
    assert_eq!(fiche.affichage_rupture, AffichageRupture::Grise);
    assert_eq!(fiche.articles.len(), 2);
    let grise = fiche.articles.iter().find(|a| a.id == en_rupture).unwrap();
    assert!(!grise.disponible);
    let commandables = bac.depot.articles_commandables_de(vendeur).await.unwrap();
    assert!(commandables.iter().any(|a| a.id == en_vente));
    assert!(commandables.iter().all(|a| a.id != en_rupture), "SC-004");

    // Mode `masque` : ABSENT de la consultation.
    let z = PgZones::new(bac.pool.clone());
    let mut tx = bac.pool.begin().await.unwrap();
    z.definir_parametre(
        &mut tx,
        bac.pays,
        "categorie.boutique_superette.affichage_rupture",
        serde_json::json!("masque"),
        "test",
    )
    .await
    .unwrap();
    tx.commit().await.unwrap();

    let fiche = bac.depot.fiche_publique_de(vendeur).await.unwrap().unwrap();
    assert_eq!(fiche.affichage_rupture, AffichageRupture::Masque);
    assert_eq!(fiche.articles.len(), 1, "l'article en rupture est ABSENT");
    assert_eq!(fiche.articles[0].id, en_vente);
}
