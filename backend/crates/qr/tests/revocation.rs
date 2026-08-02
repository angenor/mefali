//! QRC-03 — révocation observée au scan (SC-004) [constitution VII].

mod bac;
use bac::{demande_scan, Bac, SITE_LAT, SITE_LON};

#[sqlx::test(migrations = "../../migrations")]
async fn suspendu_refuse_puis_retabli_collectable(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, jeton, _c) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // Suspendu → prestataire_indisponible (validité dérivée).
    bac.suspendre(tantie).await;
    let e = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton, SITE_LAT, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("prestataire_indisponible"));
    assert_eq!(bac.statut_arret(arrets[0]).await, "a_collecter");
    // Refus définitif → arret.collecte_rejetee (motif jeton_revoque) une fois.
    let rej = bac.evenements("arret.collecte_rejetee").await;
    assert_eq!(rej.len(), 1);
    assert_eq!(rej[0]["motif"], "jeton_revoque");

    // Rétabli → la MÊME collecte réussit (jeton inchangé), nouveau uuid.
    bac.retablir(tantie).await;
    let r = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &jeton, SITE_LAT, SITE_LON),
        )
        .await
        .unwrap();
    assert!(r.en_livraison);
    assert_eq!(bac.statut_arret(arrets[0]).await, "collecte");
}

#[sqlx::test(migrations = "../../migrations")]
async fn jeton_forge_plaque_invalide(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _j, _c) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // Jeton jamais stocké (forgé) → plaque_invalide.
    let forge = "f0".repeat(40);
    let e = bac
        .qr
        .collecter(
            bac.coursier,
            demande_scan(arrets[0], &forge, SITE_LAT, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("plaque_invalide"));
}
