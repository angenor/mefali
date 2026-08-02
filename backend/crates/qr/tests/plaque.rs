//! QRC-01 — PDF de plaque (SC-001) [constitution VII].

mod bac;
use bac::Bac;
use uuid::Uuid;

#[sqlx::test(migrations = "../../migrations")]
async fn plaque_generee_deposee_et_evenement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _j, _c) = bac.prestataire_agree("Tantie Affoué", "restauration").await;

    let url = bac
        .qr
        .plaque_pdf(tantie, bac.admin)
        .await
        .expect("plaque générée");
    assert!(url.url.starts_with("memoire://qr/plaques/"));

    // L'objet existe et contient un PDF.
    let octets = bac
        .objets
        .lire(&format!("qr/plaques/{tantie}.pdf"))
        .expect("PDF déposé dans le dépôt d'objets");
    assert!(octets.starts_with(b"%PDF"), "magic PDF présent");

    // Événement plaque.generee émis (première génération : regeneration=false).
    let ev = bac.evenements("plaque.generee").await;
    assert_eq!(ev.len(), 1);
    assert_eq!(ev[0]["format"], "pdf");
    assert_eq!(ev[0]["regeneration"], false);
}

#[sqlx::test(migrations = "../../migrations")]
async fn regeneration_marquee_et_stable(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (tantie, _j, _c) = bac.prestataire_agree("Tantie", "restauration").await;

    let ctx1 = bac
        .prestataires
        .contexte_plaque(tantie)
        .await
        .unwrap()
        .unwrap();
    bac.qr.plaque_pdf(tantie, bac.admin).await.unwrap();
    bac.qr.plaque_pdf(tantie, bac.admin).await.unwrap();
    let ctx2 = bac
        .prestataires
        .contexte_plaque(tantie)
        .await
        .unwrap()
        .unwrap();

    // Identité de plaque STABLE à la régénération (SC-001) : jeton et code
    // inchangés (le PDF encode le même QR ; seules d'éventuelles métadonnées
    // PDF — date/ID — peuvent varier, sans porter de contenu).
    assert_eq!(ctx1.jeton_plaque, ctx2.jeton_plaque, "jeton stable");
    assert_eq!(ctx1.code_secours, ctx2.code_secours, "code stable");
    let octets = bac
        .objets
        .lire(&format!("qr/plaques/{tantie}.pdf"))
        .unwrap();
    assert!(octets.starts_with(b"%PDF"));
    let ev = bac.evenements("plaque.generee").await;
    assert_eq!(ev.len(), 2);
    assert_eq!(
        ev[1]["regeneration"], true,
        "2e génération marquée régénération"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn prospect_sans_plaque_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Prestataire jamais agréé → pas d'identité de plaque (FR-011).
    let e = bac
        .qr
        .plaque_pdf(Uuid::now_v7(), bac.admin)
        .await
        .unwrap_err();
    assert_eq!(e.message_cle(), Some("plaque_absente"));
}
