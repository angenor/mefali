//! Tests d'intégration EXHAUSTIFS de la résolution héritée (FR-008, SC-001,
//! SC-006 — OBLIGATOIRES, constitution VII). Base éphémère par test.
//!
//!   cargo test -p zones --test resolution   (DATABASE_URL requis)
//!
//! Arbre de test à 3 niveaux P (pays) > V (ville) > Q (quartier) couvrant la
//! matrice de surcharge : aucune, partielle (niveau intermédiaire), totale,
//! niveau intermédiaire transparent, absence explicite, valeur false/"" définie,
//! devise héritée/irrésolvable, paramètre fictif de bout en bout, re-parentage.

use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

use zones::{ConfigurationZones, Devise, ErreurZones, PgZones, TypeZone};

/// P > V > Q avec surcharges partielles à chaque niveau. Renvoie (dépôt, p, v, q).
async fn creer_arbre(pool: &PgPool) -> (PgZones, Uuid, Uuid, Uuid) {
    let z = PgZones::new(pool.clone());
    let mut tx = pool.begin().await.unwrap();
    let p = z
        .creer_zone(&mut tx, None, TypeZone::Pays, "P")
        .await
        .unwrap()
        .id;
    let v = z
        .creer_zone(&mut tx, Some(p), TypeZone::Ville, "V")
        .await
        .unwrap()
        .id;
    let q = z
        .creer_zone(&mut tx, Some(v), TypeZone::Quartier, "Q")
        .await
        .unwrap()
        .id;

    // Niveau pays : devise + trois textes (dont deux seront surchargés plus bas).
    z.definir_parametre(&mut tx, p, "devise.code", json!("XOF"), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, p, "devise.decimales", json!(0), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, p, "texte.sans", json!("P"), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, p, "texte.partiel", json!("P"), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, p, "texte.total", json!("P"), "seed")
        .await
        .unwrap();

    // Niveau ville : surcharge partielle + totale.
    z.definir_parametre(&mut tx, v, "texte.partiel", json!("V"), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, v, "texte.total", json!("V"), "seed")
        .await
        .unwrap();

    // Niveau quartier : surcharge totale + valeurs "vides" définies + fictif.
    z.definir_parametre(&mut tx, q, "texte.total", json!("Q"), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, q, "drapeau.actif", json!(false), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, q, "texte.vide", json!(""), "seed")
        .await
        .unwrap();
    z.definir_parametre(&mut tx, q, "dispatch.rayon_km", json!(3), "seed")
        .await
        .unwrap();

    tx.commit().await.unwrap();
    (z, p, v, q)
}

/// SC-001 — matrice complète résolue à la feuille : chaque paramètre vaut la
/// valeur de l'ancêtre le plus proche, ou une absence explicite.
#[sqlx::test(migrations = "../../migrations")]
async fn matrice_surcharge_feuille(pool: PgPool) {
    let (z, p, v, q) = creer_arbre(&pool).await;
    let cfg = z.configuration_effective(q).await.unwrap();

    // Aucune surcharge → valeur du pays, niveau intermédiaire transparent.
    assert_eq!(cfg.valeur("texte.sans"), Some(&json!("P")));
    assert_eq!(cfg.provenance("texte.sans"), Some(p));

    // Surcharge partielle → ancêtre le plus proche (ville).
    assert_eq!(cfg.valeur("texte.partiel"), Some(&json!("V")));
    assert_eq!(cfg.provenance("texte.partiel"), Some(v));

    // Surcharge totale → zone elle-même.
    assert_eq!(cfg.valeur("texte.total"), Some(&json!("Q")));
    assert_eq!(cfg.provenance("texte.total"), Some(q));

    // Absent partout → absence EXPLICITE (jamais de valeur inventée).
    assert_eq!(cfg.valeur("texte.absent"), None);
    assert_eq!(z.parametre(q, "texte.absent").await.unwrap(), None);

    // Défini à false ≠ absent (FR-009).
    assert_eq!(cfg.valeur("drapeau.actif"), Some(&json!(false)));
    assert_eq!(z.drapeau(q, "actif").await.unwrap(), Some(false));
    assert_eq!(z.drapeau(q, "inexistant").await.unwrap(), None);

    // Défini à "" ≠ absent (FR-009).
    assert_eq!(cfg.valeur("texte.vide"), Some(&json!("")));
    assert_eq!(z.parametre(q, "texte.vide").await.unwrap(), Some(json!("")));
}

/// Niveau intermédiaire (ville) : ne voit pas la feuille ; transparent pour les
/// clés qu'il ne définit pas.
#[sqlx::test(migrations = "../../migrations")]
async fn niveau_intermediaire(pool: PgPool) {
    let (z, p, v, _q) = creer_arbre(&pool).await;
    let cfg = z.configuration_effective(v).await.unwrap();

    assert_eq!(cfg.valeur("texte.sans"), Some(&json!("P")));
    assert_eq!(cfg.provenance("texte.sans"), Some(p), "hérité du pays");
    assert_eq!(
        cfg.valeur("texte.total"),
        Some(&json!("V")),
        "ne voit pas Q"
    );
    assert_eq!(cfg.valeur("drapeau.actif"), None, "défini sur Q seulement");
}

/// FR-010 — devise héritée résolue ; chaîne sans devise = erreur ; zone inconnue.
#[sqlx::test(migrations = "../../migrations")]
async fn devise_et_zone_inconnue(pool: PgPool) {
    let (z, _p, _v, q) = creer_arbre(&pool).await;
    assert_eq!(
        z.devise(q).await.unwrap(),
        Devise {
            code: "XOF".to_owned(),
            decimales: 0
        }
    );

    let mut tx = pool.begin().await.unwrap();
    let orphelin = z
        .creer_zone(&mut tx, None, TypeZone::Pays, "Nulle-part")
        .await
        .unwrap()
        .id;
    tx.commit().await.unwrap();
    assert!(matches!(
        z.devise(orphelin).await.unwrap_err(),
        ErreurZones::DeviseIrresolvable(_)
    ));

    assert!(matches!(
        z.configuration_effective(Uuid::now_v7()).await.unwrap_err(),
        ErreurZones::ZoneInconnue(_)
    ));
}

/// SC-006 — un paramètre entièrement NOUVEAU (namespace jamais prévu) se pose et
/// se résout par héritage sans aucune modification du mécanisme.
#[sqlx::test(migrations = "../../migrations")]
async fn parametre_fictif_bout_en_bout(pool: PgPool) {
    let (z, p, _v, q) = creer_arbre(&pool).await;

    // Déjà posé sur Q dans l'arbre de test (résolution locale).
    assert_eq!(
        z.parametre(q, "dispatch.rayon_km").await.unwrap(),
        Some(json!(3))
    );

    // Posé sur le pays → hérité par la feuille, avec provenance.
    let mut tx = pool.begin().await.unwrap();
    z.definir_parametre(&mut tx, p, "tarification.tva_pourmille", json!(180), "seed")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(
        z.parametre(q, "tarification.tva_pourmille").await.unwrap(),
        Some(json!(180))
    );
    let cfg = z.configuration_effective(q).await.unwrap();
    assert_eq!(cfg.provenance("tarification.tva_pourmille"), Some(p));
}

/// Re-parentage → la résolution change à la consultation suivante (edge case spec).
#[sqlx::test(migrations = "../../migrations")]
async fn reparentage_change_resolution(pool: PgPool) {
    let (z, p, v, q) = creer_arbre(&pool).await;

    // Avant : Q → V → P ; texte.partiel vient de la ville.
    assert_eq!(
        z.parametre(q, "texte.partiel").await.unwrap(),
        Some(json!("V"))
    );

    // Re-parenter Q directement sous P (retire V de la chaîne).
    let mut tx = pool.begin().await.unwrap();
    z.reparenter(&mut tx, q, Some(p)).await.unwrap();
    tx.commit().await.unwrap();

    // Après : Q → P ; texte.partiel vient désormais du pays.
    assert_eq!(
        z.parametre(q, "texte.partiel").await.unwrap(),
        Some(json!("P"))
    );
    let _ = v;
}
