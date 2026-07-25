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
/// Renvoie `(coursier, livraison, [arrets de COLLECTE])`.
///
/// `avec_remise` ajoute l'arrêt de REMISE que le cycle CMD 008 impose en fin de
/// segment (cadrage §7.2). Il n'est PAS renvoyé dans la liste : ce n'est pas une
/// collecte, et aucun appelant n'a à le collecter.
///
/// ⚠ Le tronc `commande` a reçu ses colonnes métier en migration `0009` : la
/// fixture les renseigne désormais. Ce sont les FIXTURES qui changent, jamais
/// les assertions du cycle 006 (critère (a) du point obligatoire P1).
async fn semer(pool: &sqlx::PgPool, montants: &[i64], avec_remise: bool) -> (Uuid, Uuid, Vec<Uuid>) {
    let pays = Uuid::now_v7();
    let ville = Uuid::now_v7();
    let categorie = Uuid::now_v7();
    let prestataire = Uuid::now_v7();
    let coursier = Uuid::now_v7();
    let client = Uuid::now_v7();
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
    sqlx::query(
        "INSERT INTO comptes.compte (id, telephone_e164, zone_id, consentement_version, consentement_le)
         VALUES ($1, '+2250700000003', $2, '2026-07', now())",
    ).bind(client).bind(ville).execute(pool).await.unwrap();

    let total: i64 = montants.iter().sum();
    sqlx::query(
        "INSERT INTO commandes.commande
            (id, client_id, zone_id, categorie_id, lieu_lat, lieu_lon, repere_texte,
             montant_articles_unites, total_unites, devise, mode_paiement,
             code_livraison, code_livraison_hash, jeton_reception, jeton_reception_hash)
         VALUES ($1, $2, $3, $4, 5.900, -4.820, 'Près de la pharmacie',
                 $5, $5, 'XOF', 'cash', '7341', 'h-code', 'jeton', 'h-jeton')",
    ).bind(commande).bind(client).bind(ville).bind(categorie).bind(total)
        .execute(pool).await.unwrap();
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
    if avec_remise {
        // Arrêt de REMISE : aucun prestataire, aucun montant avancé (contraintes
        // `arret_prestataire_coherent` et `arret_remise_sans_montant`).
        sqlx::query(
            "INSERT INTO commandes.arret
                (id, segment_id, ordre, type_arret, site_lat, site_lon, montant_avance, devise)
             VALUES ($1, $2, $3, 'remise', 5.900, -4.820, 0, 'XOF')",
        ).bind(Uuid::now_v7()).bind(segment).bind(montants.len() as i16)
            .execute(pool).await.unwrap();
    }
    (coursier, livraison, arrets)
}

#[sqlx::test(migrations = "../../migrations")]
async fn transition_et_gating_avec_indisponible(pool: sqlx::PgPool) {
    let (coursier, livraison, arrets) = semer(&pool, &[2000, 1500], false).await;
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

/// **P1 — critères (b) et (c)** du cycle CMD 008 (plan §Points obligatoires).
///
/// Une livraison à **2 collectes + 1 remise** doit basculer EN_LIVRAISON dès
/// que ses **2 collectes** sont résolues, et annoncer « 2 sur 2 » — jamais
/// « 2 sur 3 ». Sans la correction du gating, `resolus = total` n'est jamais
/// vrai (l'arrêt de remise n'est jamais `collecte`) : la commande resterait
/// bloquée en collecte pour TOUJOURS, sans qu'aucun test du cycle 006 ne le
/// signale — c'est la régression la plus dangereuse du cycle.
#[sqlx::test(migrations = "../../migrations")]
async fn gating_ignore_l_arret_de_remise(pool: sqlx::PgPool) {
    let (coursier, livraison, collectes) = semer(&pool, &[2000, 1500], true).await;
    let depot = PgCommandes::new(pool.clone());

    // Le segment porte bien 3 arrêts, dont 1 de remise.
    let (total, remises): (i64, i64) = sqlx::query_as(
        "SELECT count(*), count(*) FILTER (WHERE a.type_arret = 'remise')
         FROM commandes.arret a JOIN commandes.segment s ON s.id = a.segment_id
         WHERE s.livraison_id = $1",
    )
    .bind(livraison)
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!((total, remises), (3, 1));

    // 1ʳᵉ collecte → pas de bascule, progression « 1 sur 2 ».
    let mut tx = pool.begin().await.unwrap();
    let p1 = depot
        .marquer_arret_collecte(
            &mut tx, collectes[0], Uuid::now_v7(), ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(!p1.en_livraison, "une collecte reste à faire");
    assert_eq!((p1.nb_collectes, p1.nb_arrets), (1, 2));

    // 2ᵉ (et dernière) collecte → bascule, progression « 2 sur 2 ».
    let mut tx = pool.begin().await.unwrap();
    let p2 = depot
        .marquer_arret_collecte(
            &mut tx, collectes[1], Uuid::now_v7(), ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(
        p2.en_livraison,
        "toutes les COLLECTES sont résolues — l'arrêt de remise ne doit pas retenir la bascule",
    );
    assert_eq!(
        (p2.nb_collectes, p2.nb_arrets),
        (2, 2),
        "« 2 sur 2 » — la remise n'est pas une collecte (critère (c))",
    );

    let etat: String = sqlx::query_scalar("SELECT etat::text FROM commandes.livraison WHERE id = $1")
        .bind(livraison).fetch_one(&pool).await.unwrap();
    assert_eq!(etat, "en_livraison");

    // L'arrêt de remise, lui, est toujours à faire : la remise reste à venir.
    let remise_statut: String = sqlx::query_scalar(
        "SELECT a.statut::text FROM commandes.arret a
         JOIN commandes.segment s ON s.id = a.segment_id
         WHERE s.livraison_id = $1 AND a.type_arret = 'remise'",
    )
    .bind(livraison)
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(remise_statut, "a_collecter");
}

#[sqlx::test(migrations = "../../migrations")]
async fn idempotence_meme_uuid(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000], false).await;
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
