//! Types de transport (ZON-03) : activation par la configuration héritée
//! (`transport.actifs`), validation des slugs, extensibilité par données.
//!
//!   cargo test -p zones --test transport   (DATABASE_URL requis)
//!
//! Le référentiel réel (8 types) et les 3 actifs de Tiassalé issus du seed sont
//! vérifiés par le test /config (T015) ; ici on prouve la mécanique sur des
//! données locales.

use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

use zones::{ConfigurationZones, ErreurZones, PgZones, TypeZone};

/// CI (pays) > Tiassalé (ville) + référentiel local {a_pied, velo, moto, voiture}.
async fn setup(pool: &PgPool) -> (PgZones, Uuid, Uuid) {
    let z = PgZones::new(pool.clone());
    let mut tx = pool.begin().await.unwrap();
    let pays = z.creer_zone(&mut tx, None, TypeZone::Pays, "CI").await.unwrap().id;
    let ville = z
        .creer_zone(&mut tx, Some(pays), TypeZone::Ville, "Tiassalé")
        .await
        .unwrap()
        .id;
    for (i, slug) in ["a_pied", "velo", "moto", "voiture"].iter().enumerate() {
        sqlx::query("INSERT INTO zones.type_transport (id, slug, nom_cle, ordre) VALUES ($1, $2, $3, $4)")
            .bind(Uuid::now_v7())
            .bind(slug)
            .bind(format!("transport.{slug}.nom"))
            .bind((i + 1) as i16)
            .execute(&mut *tx)
            .await
            .unwrap();
    }
    tx.commit().await.unwrap();
    (z, pays, ville)
}

/// Activation posée sur un parent héritée par la descendante ; surcharge locale
/// en bloc prioritaire.
#[sqlx::test(migrations = "../../migrations")]
async fn heritage_et_surcharge_en_bloc(pool: PgPool) {
    let (z, pays, ville) = setup(&pool).await;

    // Activés au niveau PAYS → hérités par la ville.
    let mut tx = pool.begin().await.unwrap();
    z.definir_parametre(&mut tx, pays, "transport.actifs", json!(["a_pied", "velo", "moto"]), "seed")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(
        z.transports_actifs(ville).await.unwrap(),
        vec!["a_pied", "velo", "moto"],
        "héritage depuis le pays"
    );

    // Surcharge locale de la ville = remplacement EN BLOC.
    let mut tx = pool.begin().await.unwrap();
    z.definir_parametre(&mut tx, ville, "transport.actifs", json!(["voiture"]), "seed")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(z.transports_actifs(ville).await.unwrap(), vec!["voiture"], "surcharge en bloc");
    assert_eq!(
        z.transports_actifs(pays).await.unwrap(),
        vec!["a_pied", "velo", "moto"],
        "parent inchangé"
    );
}

/// Slug absent du référentiel → refusé à l'écriture (ValeurInvalide).
#[sqlx::test(migrations = "../../migrations")]
async fn slug_inconnu_refuse(pool: PgPool) {
    let (z, pays, _ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    let err = z
        .definir_parametre(&mut tx, pays, "transport.actifs", json!(["a_pied", "fusee"]), "seed")
        .await
        .unwrap_err();
    assert!(matches!(err, ErreurZones::ValeurInvalide { .. }));
}

/// Ajout d'un 9e type = simple INSERT (aucune modification structurelle), puis
/// immédiatement utilisable dans la configuration.
#[sqlx::test(migrations = "../../migrations")]
async fn neuvieme_type_insert_seul(pool: PgPool) {
    let (z, _pays, ville) = setup(&pool).await;
    let mut tx = pool.begin().await.unwrap();
    sqlx::query("INSERT INTO zones.type_transport (id, slug, nom_cle, ordre) VALUES ($1, 'drone', 'transport.drone.nom', 9)")
        .bind(Uuid::now_v7())
        .execute(&mut *tx)
        .await
        .unwrap();
    z.definir_parametre(&mut tx, ville, "transport.actifs", json!(["drone"]), "seed")
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(z.transports_actifs(ville).await.unwrap(), vec!["drone"]);
}
