//! QRC-04 — mode dégradé (code de secours) + incident (SC-006) [constitution VII].

mod bac;
use bac::{demande_code, Bac, SITE_LAT, SITE_LON};

#[sqlx::test(migrations = "../../migrations")]
async fn bon_code_dans_le_rayon_collecte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _j, code) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    let r = bac
        .qr
        .collecter(
            bac.coursier,
            demande_code(arrets[0], &code, SITE_LAT, SITE_LON),
        )
        .await
        .expect("bon code, dans le rayon");
    assert!(r.en_livraison);
    let ev = bac.evenements("arret.collecte").await;
    assert_eq!(ev[0]["mode"], "code_secours");
    // Incident « plaque à remplacer » créé une fois (dès le passage dégradé).
    assert_eq!(
        bac.compter("SELECT count(*) FROM qr.incident_plaque").await,
        1
    );
    assert_eq!(bac.evenements("plaque.remplacement_requis").await.len(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn trois_essais_reels_puis_epuise_incident_une_fois(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _j, _code) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // « 3 essais max » (FR-020) : les tentatives 1, 2 ET 3 comparent le code
    // (3× code_incorrect) ; l'incident est créé UNE seule fois au 1er passage.
    for faux in ["0000", "0001", "0002"] {
        let e = bac
            .qr
            .collecter(
                bac.coursier,
                demande_code(arrets[0], faux, SITE_LAT, SITE_LON),
            )
            .await
            .unwrap_err();
        assert_eq!(e.message_cle(), Some("code_incorrect"), "essai « {faux} »");
    }
    assert_eq!(
        bac.compter("SELECT count(*) FROM qr.incident_plaque").await,
        1
    );
    assert_eq!(bac.evenements("plaque.remplacement_requis").await.len(), 1);

    // Au-DELÀ du 3ᵉ essai → épuisé (backstop), toujours un seul incident.
    let e4 = bac
        .qr
        .collecter(
            bac.coursier,
            demande_code(arrets[0], "0003", SITE_LAT, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e4.message_cle(), Some("code_epuise"));
    assert_eq!(
        bac.compter("SELECT count(*) FROM qr.incident_plaque").await,
        1
    );
    assert_eq!(bac.evenements("plaque.remplacement_requis").await.len(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn bon_code_hors_rayon_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _j, code) = bac.prestataire_agree("Tantie", "restauration").await;
    let arrets = bac.simuler_course(&[(tantie, 2000)]).await;

    // Bon code mais ~300 m → hors_zone (FR-022). La proximité est vérifiée
    // AVANT le mode : aucun essai consommé, aucun incident créé (le coursier
    // n'est pas sur place).
    let e = bac
        .qr
        .collecter(
            bac.coursier,
            demande_code(arrets[0], &code, SITE_LAT + 0.0027, SITE_LON),
        )
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("hors_zone"));
    assert_eq!(bac.statut_arret(arrets[0]).await, "a_collecter");
    assert_eq!(
        bac.compter("SELECT count(*) FROM qr.incident_plaque").await,
        0,
        "hors zone → aucun incident (pas sur place)"
    );
}
