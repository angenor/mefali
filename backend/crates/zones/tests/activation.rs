//! Tests d'intégration des TRANSITIONS d'activation (data-model §3 — OBLIGATOIRES,
//! constitution VII). Base éphémère par test.
//!
//!   cargo test -p zones --test activation   (DATABASE_URL requis)

use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

use zones::{Forcage, PgZones, TypeZone};

/// Ville avec la catégorie `marche` (seuil 3 posé à la ville). Renvoie (dépôt, ville).
async fn setup(pool: &PgPool) -> (PgZones, Uuid) {
    let z = PgZones::new(pool.clone());
    let mut tx = pool.begin().await.unwrap();
    let ville = z
        .creer_zone(&mut tx, None, TypeZone::Ville, "V")
        .await
        .unwrap()
        .id;
    sqlx::query(
        "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
         VALUES ($1, 'marche', 'categorie.marche.nom', 'marche_etals')",
    )
    .bind(Uuid::now_v7())
    .execute(&mut *tx)
    .await
    .unwrap();
    z.definir_parametre(&mut tx, ville, "categorie.marche.seuil_activation", json!(3), "seed")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    (z, ville)
}

async fn actif_optionnel(pool: &PgPool, ville: Uuid, slug: &str) -> Option<bool> {
    sqlx::query_scalar(
        "SELECT a.actif FROM zones.activation_categorie a
         JOIN zones.categorie c ON c.id = a.categorie_id
         WHERE a.zone_id = $1 AND c.slug = $2",
    )
    .bind(ville)
    .bind(slug)
    .fetch_optional(pool)
    .await
    .unwrap()
}

async fn actif(pool: &PgPool, ville: Uuid, slug: &str) -> bool {
    actif_optionnel(pool, ville, slug)
        .await
        .expect("ligne d'activation présente")
}

async fn compter(pool: &PgPool, type_ev: &str) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM outbox.evenement WHERE type_evenement = $1")
        .bind(type_ev)
        .fetch_one(pool)
        .await
        .unwrap()
}

async fn dernier_payload(pool: &PgPool, type_ev: &str) -> Value {
    sqlx::query_scalar(
        "SELECT payload FROM outbox.evenement WHERE type_evenement = $1
         ORDER BY cree_le DESC LIMIT 1",
    )
    .bind(type_ev)
    .fetch_one(pool)
    .await
    .unwrap()
}

/// Seuil−1 → rien ; franchissement du seuil → activation + événement conforme.
#[sqlx::test(migrations = "../../migrations")]
async fn franchissement_du_seuil(pool: PgPool) {
    let (z, ville) = setup(&pool).await;

    // Seuil − 1 (2 vendeurs) → aucune activation, aucun événement.
    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "marche", 2).await.unwrap();
    tx.commit().await.unwrap();
    assert_eq!(actif_optionnel(&pool, ville, "marche").await, Some(false));
    assert_eq!(compter(&pool, "categorie.activation_changee").await, 0);

    // Seuil atteint (3) → activation + événement.
    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "marche", 3).await.unwrap();
    tx.commit().await.unwrap();
    assert!(actif(&pool, ville, "marche").await);
    assert_eq!(compter(&pool, "categorie.activation_changee").await, 1);

    let p = dernier_payload(&pool, "categorie.activation_changee").await;
    assert_eq!(p["origine"], "seuil");
    assert_eq!(p["avant"], json!(false));
    assert_eq!(p["apres"], json!(true));
    assert_eq!(p["nb_vendeurs"], json!(3));
    assert_eq!(p["seuil"], json!(3));
    assert_eq!(p["categorie"], "marche");
}

/// Repli du nombre de vendeurs sous le seuil → reste active (FR-015).
#[sqlx::test(migrations = "../../migrations")]
async fn repli_sous_le_seuil_reste_active(pool: PgPool) {
    let (z, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "marche", 3).await.unwrap();
    tx.commit().await.unwrap();
    assert!(actif(&pool, ville, "marche").await);
    let evenements = compter(&pool, "categorie.activation_changee").await;

    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "marche", 1).await.unwrap();
    tx.commit().await.unwrap();
    assert!(actif(&pool, ville, "marche").await, "aucune désactivation automatique");
    assert_eq!(
        compter(&pool, "categorie.activation_changee").await,
        evenements,
        "aucun nouvel événement"
    );
}

/// Forcé actif SOUS le seuil → actif ; deux événements émis.
#[sqlx::test(migrations = "../../migrations")]
async fn force_actif_sous_le_seuil(pool: PgPool) {
    let (z, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    let etat = z
        .forcer_categorie(&mut tx, ville, "marche", Forcage::ForceActif, "admin")
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert!(etat.actif);
    assert_eq!(etat.forcage, Forcage::ForceActif);
    assert!(actif(&pool, ville, "marche").await);
    assert_eq!(compter(&pool, "categorie.forcage_change").await, 1);
    assert_eq!(compter(&pool, "categorie.activation_changee").await, 1, "false→true");

    let p = dernier_payload(&pool, "categorie.forcage_change").await;
    assert_eq!(p["avant"], "automatique");
    assert_eq!(p["apres"], "force_actif");
    assert_eq!(p["acteur"], "admin");
}

/// Forcé inactif AU-DESSUS du seuil → inactif (le forçage l'emporte).
#[sqlx::test(migrations = "../../migrations")]
async fn force_inactif_au_dessus_du_seuil(pool: PgPool) {
    let (z, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "marche", 5).await.unwrap();
    tx.commit().await.unwrap();
    assert!(actif(&pool, ville, "marche").await);

    let mut tx = pool.begin().await.unwrap();
    let etat = z
        .forcer_categorie(&mut tx, ville, "marche", Forcage::ForceInactif, "admin")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(!etat.actif, "forcé inactif l'emporte au-dessus du seuil");
    assert!(!actif(&pool, ville, "marche").await);

    let p = dernier_payload(&pool, "categorie.activation_changee").await;
    assert_eq!(p["avant"], json!(true));
    assert_eq!(p["apres"], json!(false));
    assert_eq!(p["origine"], "forcage");
}

/// Retour à `automatique` → réapplique la règle du seuil à l'état courant.
#[sqlx::test(migrations = "../../migrations")]
async fn retour_automatique_reapplique_la_regle(pool: PgPool) {
    let (z, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "marche", 3).await.unwrap(); // actif_auto = true
    z.forcer_categorie(&mut tx, ville, "marche", Forcage::ForceInactif, "admin").await.unwrap();
    tx.commit().await.unwrap();
    assert!(!actif(&pool, ville, "marche").await);

    let mut tx = pool.begin().await.unwrap();
    let etat = z
        .forcer_categorie(&mut tx, ville, "marche", Forcage::Automatique, "admin")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(etat.actif, "automatique réapplique actif_auto (resté true)");
}

/// Seuil non défini → aucune activation automatique, mais forçage possible.
#[sqlx::test(migrations = "../../migrations")]
async fn seuil_absent_inerte_mais_forcable(pool: PgPool) {
    let z = PgZones::new(pool.clone());
    let mut tx = pool.begin().await.unwrap();
    let ville = z.creer_zone(&mut tx, None, TypeZone::Ville, "V").await.unwrap().id;
    sqlx::query(
        "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
         VALUES ($1, 'gaz', 'categorie.gaz.nom', 'echange_contenant')",
    )
    .bind(Uuid::now_v7())
    .execute(&mut *tx)
    .await
    .unwrap();
    tx.commit().await.unwrap();

    // Sans seuil résolu, la règle est inerte : aucune ligne, aucun événement.
    let mut tx = pool.begin().await.unwrap();
    z.recalculer_activation(&mut tx, ville, "gaz", 100).await.unwrap();
    tx.commit().await.unwrap();
    assert_eq!(actif_optionnel(&pool, ville, "gaz").await, None);
    assert_eq!(compter(&pool, "categorie.activation_changee").await, 0);

    // Le forçage reste possible.
    let mut tx = pool.begin().await.unwrap();
    let etat = z
        .forcer_categorie(&mut tx, ville, "gaz", Forcage::ForceActif, "admin")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(etat.actif);
}

/// Slug de catégorie inconnu → erreur explicite (recalcul et forçage).
#[sqlx::test(migrations = "../../migrations")]
async fn categorie_inconnue(pool: PgPool) {
    let (z, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    // Seuil résolu mais slug absent du référentiel : posé en SQL brut, car
    // definir_parametre refuserait (à juste titre) un slug de catégorie inconnu.
    sqlx::query(
        "INSERT INTO zones.parametre_zone (zone_id, cle, valeur)
         VALUES ($1, 'categorie.fantome.seuil_activation', '1')",
    )
    .bind(ville)
    .execute(&mut *tx)
    .await
    .unwrap();
    let err = z.recalculer_activation(&mut tx, ville, "fantome", 5).await.unwrap_err();
    assert!(matches!(err, zones::ErreurZones::CategorieInconnue(_)));
    let err = z
        .forcer_categorie(&mut tx, ville, "fantome", Forcage::ForceActif, "admin")
        .await
        .unwrap_err();
    assert!(matches!(err, zones::ErreurZones::CategorieInconnue(_)));
}

/// Rollback → aucun événement d'activation (atomicité, constitution VI).
#[sqlx::test(migrations = "../../migrations")]
async fn rollback_aucun_evenement(pool: PgPool) {
    let (z, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    z.forcer_categorie(&mut tx, ville, "marche", Forcage::ForceActif, "admin").await.unwrap();
    tx.rollback().await.unwrap();
    assert_eq!(compter(&pool, "categorie.forcage_change").await, 0);
    assert_eq!(compter(&pool, "categorie.activation_changee").await, 0);
}
