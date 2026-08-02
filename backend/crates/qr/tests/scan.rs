//! QRC-02 — collecte par scan (SC-002/003/005/008) [constitution VII].

mod bac;
use bac::{demande_scan, Bac, SITE_LAT, SITE_LON};
use uuid::Uuid;

#[sqlx::test(migrations = "../../migrations")]
async fn scan_dans_le_rayon_collecte_et_evenement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, jeton, _code) = bac.prestataire_agree("Tantie Affoué", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // Scan à ~30 m → COLLECTÉ.
    let r = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton, SITE_LAT + 0.00027, SITE_LON),
        )
        .await
        .expect("collecte dans le rayon");
    assert!(r.en_livraison, "arrêt unique → livraison EN_LIVRAISON");
    assert_eq!(bac.statut_arret(arrets[0]).await, "collecte");

    // Horodatage serveur posé + événement arret.collecte sans lat/lng brut.
    let collecte_le: Option<chrono::DateTime<chrono::Utc>> =
        sqlx::query_scalar("SELECT collecte_le FROM commandes.arret WHERE id = $1")
            .bind(arrets[0])
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert!(collecte_le.is_some(), "horodatage serveur renseigné");

    let ev = bac.evenements("arret.collecte").await;
    assert_eq!(ev.len(), 1);
    assert_eq!(ev[0]["mode"], "scan_qr");
    assert_eq!(ev[0]["gps_ok"], true);
    assert!(
        ev[0].get("site_lat").is_none() && ev[0].get("lat").is_none(),
        "ARTCI : pas de GPS brut"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn scan_hors_rayon_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, jeton, _c) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // ~300 m au nord → hors_zone (SC-007).
    let e = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton, SITE_LAT + 0.0027, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("hors_zone"));
    assert_eq!(
        bac.statut_arret(arrets[0]).await,
        "a_collecter",
        "0 collecte à distance"
    );
    // Refus définitif → événement arret.collecte_rejetee une fois.
    assert_eq!(bac.evenements("arret.collecte_rejetee").await.len(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn mauvais_vendeur_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _jt, _ct) = bac.prestataire_agree("Tantie", "restauration").await;
    let (_kofi, jeton_kofi, _ck) = bac.prestataire_agree("Kofi", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // Jeton de Kofi sur l'arrêt de Tantie → plaque_invalide (SC-003).
    let e = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton_kofi, SITE_LAT, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("plaque_invalide"));
    assert_eq!(bac.statut_arret(arrets[0]).await, "a_collecter");
}

#[sqlx::test(migrations = "../../migrations")]
async fn gating_en_livraison_avec_arret_indisponible(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, jeton, _c) = bac.prestataire_agree("Tantie", "restauration").await;
    let (kofi, _jk, _ck) = bac.prestataire_agree("Kofi", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000), (kofi, 1500)]).await;

    // Kofi indisponible (façon CMD-06) → compté résolu au gating (FR-018).
    bac.poser_indisponible(arrets[1]).await;

    // Collecter Tantie (dernier arrêt résolu) → EN_LIVRAISON.
    let r = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton, SITE_LAT, SITE_LON),
        )
        .await
        .unwrap();
    assert!(
        r.en_livraison,
        "tous les arrêts résolus (1 collecté + 1 indisponible)"
    );
    assert_eq!(bac.evenements("livraison.mise_en_livraison").await.len(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn rejeu_idempotent(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, jeton, _c) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    let mut demande = demande_scan(arrets[0], &jeton, SITE_LAT, SITE_LON);
    demande.uuid_client = Uuid::now_v7();
    let u = demande.uuid_client;
    let r1 = bac
        .qr
        .collecter(bac.coursier, demande.clone())
        .await
        .unwrap();

    // Rejeu du MÊME uuid_client → succès identique, aucun nouvel événement.
    let mut rejeu = demande;
    rejeu.uuid_client = u;
    let r2 = bac.qr.collecter(bac.coursier, rejeu).await.unwrap();
    assert_eq!(r1, r2);
    assert_eq!(
        bac.evenements("arret.collecte").await.len(),
        1,
        "aucune double collecte"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn photo_obligatoire_pharmacie_sans_photo_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (pharma, jeton, _c) = bac.prestataire_agree("Pharmacie", "pharmacie").await;
    let arrets = bac.simuler_course(&[(pharma, 2000)]).await;

    // Politique pharmacie = obligatoire, pas de photo → photo_requise.
    let e = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton, SITE_LAT, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("photo_requise"));
}
