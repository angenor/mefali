//! T044 — purge des photos de récupération après la rétention de zone (VIII).

mod bac;
use bac::{Bac, SITE_LAT, SITE_LON};
use uuid::Uuid;

#[sqlx::test(migrations = "../../migrations")]
async fn photo_purgee_apres_retention(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (pharma, jeton, _c) = bac.prestataire_agree("Pharmacie", "pharmacie").await;
    let arrets = bac.simuler_course(&[(pharma, 2000)]).await;

    // Collecte avec photo (pharmacie = photo obligatoire).
    let mut demande = bac::demande_scan(arrets[0], &jeton, SITE_LAT, SITE_LON);
    demande.photo = Some(vec![0xFF, 0xD8, 0xFF, 0xE0]);
    demande.uuid_client = Uuid::now_v7();
    bac.qr.collecter(bac.coursier, demande).await.unwrap();

    let cle = format!("qr/collectes/{}.jpg", arrets[0]);
    assert!(bac.objets.lire(&cle).is_some(), "photo déposée");

    // Rétention 365 j : une purge immédiate ne supprime rien.
    assert_eq!(bac.qr.purger_photos_collecte().await.unwrap(), 0);
    assert!(bac.objets.lire(&cle).is_some());

    // Antidater la collecte au-delà de la rétention → purge.
    sqlx::query("UPDATE commandes.arret SET collecte_le = now() - interval '400 days' WHERE id = $1")
        .bind(arrets[0])
        .execute(&bac.pool)
        .await
        .unwrap();
    assert_eq!(bac.qr.purger_photos_collecte().await.unwrap(), 1);
    assert!(bac.objets.lire(&cle).is_none(), "photo supprimée");
    let photo_cle: Option<String> =
        sqlx::query_scalar("SELECT photo_cle FROM commandes.arret WHERE id = $1")
            .bind(arrets[0])
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert!(photo_cle.is_none(), "clé déréférencée en base");
}
