//! QRC-02 — transition `marquer_arret_collecte` : bascule + gating EN_LIVRAISON
//! (avec arrêt `indisponible` compté résolu) + idempotence [constitution VII].
//!
//! Le socle logistique référence `prestataires.prestataire` et `comptes.compte`
//! (FK) : on insère le minimum en SQL direct (zones → catégorie → prestataire →
//! compte), sans passer par le domaine prestataires (hors périmètre du crate).

use chrono::Utc;
use commandes::{ModeCollecte, PgCommandes};
use uuid::Uuid;

/// Sème les FK minimales et une course (livraison → segment → arrêts).
/// Renvoie `(coursier, livraison, [arrets])`.
async fn semer(pool: &sqlx::PgPool, montants: &[i64]) -> (Uuid, Uuid, Vec<Uuid>) {
    let pays = Uuid::now_v7();
    let ville = Uuid::now_v7();
    let categorie = Uuid::now_v7();
    let prestataire = Uuid::now_v7();
    let coursier = Uuid::now_v7();
    let commande = Uuid::now_v7();
    let livraison = Uuid::now_v7();
    let segment = Uuid::now_v7();

    sqlx::query("INSERT INTO zones.zone (id, type, nom) VALUES ($1, 'pays', 'CI')")
        .bind(pays).execute(pool).await.unwrap();
    sqlx::query("INSERT INTO zones.zone (id, parent_id, type, nom) VALUES ($1, $2, 'ville', 'Tiassalé')")
        .bind(ville).bind(pays).execute(pool).await.unwrap();
    sqlx::query(
        "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
         VALUES ($1, 'restauration', 'c.nom', 'restauration')",
    ).bind(categorie).execute(pool).await.unwrap();
    sqlx::query(
        "INSERT INTO prestataires.prestataire
            (id, nom, categorie_id, ville_id, contact_telephone, delai_preparation_min, plan_id)
         VALUES ($1, 'P', $2, $3, '+225', 20, '00000000-0000-4000-8000-000000000001')",
    ).bind(prestataire).bind(categorie).bind(ville).execute(pool).await.unwrap();
    sqlx::query(
        "INSERT INTO comptes.compte (id, telephone_e164, zone_id, consentement_version, consentement_le)
         VALUES ($1, '+2250700000002', $2, '2026-07', now())",
    ).bind(coursier).bind(ville).execute(pool).await.unwrap();

    sqlx::query("INSERT INTO commandes.commande (id) VALUES ($1)")
        .bind(commande).execute(pool).await.unwrap();
    sqlx::query("INSERT INTO commandes.livraison (id, commande_id, coursier_id) VALUES ($1, $2, $3)")
        .bind(livraison).bind(commande).bind(coursier).execute(pool).await.unwrap();
    sqlx::query("INSERT INTO commandes.segment (id, livraison_id, ordre) VALUES ($1, $2, 0)")
        .bind(segment).bind(livraison).execute(pool).await.unwrap();

    let mut arrets = Vec::new();
    for (i, m) in montants.iter().enumerate() {
        let arret = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO commandes.arret
                (id, segment_id, prestataire_id, ordre, site_lat, site_lon, montant_avance, devise)
             VALUES ($1, $2, $3, $4, 5.898, -4.823, $5, 'XOF')",
        ).bind(arret).bind(segment).bind(prestataire).bind(i as i16).bind(m)
            .execute(pool).await.unwrap();
        arrets.push(arret);
    }
    (coursier, livraison, arrets)
}

#[sqlx::test(migrations = "../../migrations")]
async fn transition_et_gating_avec_indisponible(pool: sqlx::PgPool) {
    let (coursier, livraison, arrets) = semer(&pool, &[2000, 1500]).await;
    let depot = PgCommandes::new(pool.clone());

    // Un arrêt posé indisponible (façon CMD-06) — compté résolu (FR-018).
    sqlx::query("UPDATE commandes.arret SET statut = 'indisponible' WHERE id = $1")
        .bind(arrets[1]).execute(&pool).await.unwrap();

    // Collecter le dernier arrêt non résolu → bascule EN_LIVRAISON.
    let mut tx = pool.begin().await.unwrap();
    let p = depot
        .marquer_arret_collecte(
            &mut tx, arrets[0], Uuid::now_v7(), ModeCollecte::ScanQr, None, 12, Utc::now(), coursier,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(p.en_livraison);
    assert_eq!(p.nb_arrets, 2);
    assert_eq!(p.nb_collectes, 1);

    let etat: String = sqlx::query_scalar("SELECT etat::text FROM commandes.livraison WHERE id = $1")
        .bind(livraison).fetch_one(&pool).await.unwrap();
    assert_eq!(etat, "en_livraison");

    // arret.collecte + livraison.mise_en_livraison émis.
    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement
         WHERE type_evenement IN ('arret.collecte','livraison.mise_en_livraison')",
    ).fetch_one(&pool).await.unwrap();
    assert_eq!(n, 2);
}

#[sqlx::test(migrations = "../../migrations")]
async fn idempotence_meme_uuid(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000]).await;
    let depot = PgCommandes::new(pool.clone());
    let uuid = Uuid::now_v7();

    for _ in 0..2 {
        let mut tx = pool.begin().await.unwrap();
        depot
            .marquer_arret_collecte(
                &mut tx, arrets[0], uuid, ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
    }
    // Rejeu du même uuid → une seule écriture d'événement.
    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement = 'arret.collecte'",
    ).fetch_one(&pool).await.unwrap();
    assert_eq!(n, 1, "aucune double collecte");
}
