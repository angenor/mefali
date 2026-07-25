//! QRC-02 — transition `marquer_arret_collecte` : bascule + gating EN_LIVRAISON
//! (avec arrêt `indisponible` compté résolu) + idempotence [constitution VII].
//!
//! Le socle logistique référence `prestataires.prestataire` et `comptes.compte`
//! (FK) : on insère le minimum en SQL direct (zones → catégorie → prestataire →
//! compte), sans passer par le domaine prestataires (hors périmètre du crate).

use std::sync::Arc;

use chrono::Utc;
use commandes::{ModeCollecte, PgCommandes, RestrictionsSimulees, TarifFixe};
use uuid::Uuid;

/// Compose le dépôt du domaine pour les tests du SOCLE (cycle 006).
///
/// Ces tests n'exercent ni tarif, ni catalogue, ni restriction : les
/// collaborateurs sont réels (prestataires) ou des doubles (`TarifFixe`,
/// `RestrictionsSimulees`), ce qui garde la fixture courte sans rendre aucun
/// champ optionnel dans le dépôt.
fn depot(pool: &sqlx::PgPool) -> PgCommandes {
    let objets: Arc<dyn socle::DepotObjets> = Arc::new(socle::MemoireObjets::new());
    let comptes = comptes::PgComptes::new(
        pool.clone(),
        Arc::new(comptes::MemoireEphemere::new()),
        Arc::new(comptes::SmsTraces::new()),
        objets.clone(),
        Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
    );
    let presta = prestataires::PgPrestataires::new(
        pool.clone(),
        comptes,
        objets.clone(),
        Arc::new(prestataires::AucuneCommandeActive),
        Arc::from(&b"secret-plaque-de-test-32-octets!"[..]),
    );
    let tarif = Arc::new(TarifFixe::simple(2_500, 2_500, 0));
    PgCommandes::new(
        pool.clone(),
        presta,
        tarif.clone(),
        tarif,
        Arc::new(RestrictionsSimulees::nouveau()),
        objets,
    )
}

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
    let depot = depot(&pool);

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
    let depot = depot(&pool);

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

/// **T033 (CMD-04)** — boucle déclarative du coursier : `à_collecter →
/// en_route → arrivé`, horodatée par le SERVEUR, puis le scan du cycle 006
/// par-dessus. `arrive_le` fonde la prime d'attente TRF-06.
#[sqlx::test(migrations = "../../migrations")]
async fn boucle_en_route_puis_arrive_puis_collecte(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000], true).await;
    let depot = depot(&pool);
    let arret = arrets[0];

    let mut tx = pool.begin().await.unwrap();
    let r = depot
        .marquer_arret_en_route(&mut tx, arret, coursier, Uuid::now_v7(), Utc::now(), Utc::now())
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(r.statut.comme_str(), "en_route");
    assert!(!r.rejeu);

    let mut tx = pool.begin().await.unwrap();
    let r = depot
        .marquer_arret_arrive(&mut tx, arret, coursier, Uuid::now_v7(), Utc::now(), Utc::now())
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(r.statut.comme_str(), "arrive");

    // Les DEUX horodatages serveur sont posés — sans `arrive_le`, la prime
    // d'attente TRF-06 n'aurait aucune borne de départ.
    let (en_route_le, arrive_le): (Option<chrono::DateTime<Utc>>, Option<chrono::DateTime<Utc>>) =
        sqlx::query_as("SELECT en_route_le, arrive_le FROM commandes.arret WHERE id = $1")
            .bind(arret)
            .fetch_one(&pool)
            .await
            .unwrap();
    assert!(en_route_le.is_some() && arrive_le.is_some());
    assert!(arrive_le >= en_route_le, "on arrive après être parti");

    // `arrivé → collecté` : chemin NOMINAL de la boucle CMD-04.
    let mut tx = pool.begin().await.unwrap();
    depot
        .marquer_arret_collecte(
            &mut tx, arret, Uuid::now_v7(), ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    // Un événement par transition acceptée (constitution VI).
    for (type_evenement, attendu) in [("arret.en_route", 1), ("arret.arrive", 1), ("arret.collecte", 1)] {
        let n: i64 = sqlx::query_scalar(
            "SELECT count(*) FROM outbox.evenement WHERE type_evenement = $1",
        )
        .bind(type_evenement)
        .fetch_one(&pool)
        .await
        .unwrap();
        assert_eq!(n, attendu, "événement « {type_evenement} »");
    }
}

/// **T033** — rejeu du MÊME `uuid_client` : l'état est rendu, rien n'est
/// réécrit, aucun second événement. C'est la file hors-ligne du coursier qui
/// rejoue (constitution V).
#[sqlx::test(migrations = "../../migrations")]
async fn transition_idempotente_par_uuid_client(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000], true).await;
    let depot = depot(&pool);
    let uuid = Uuid::now_v7();

    let mut horodatages = Vec::new();
    for _ in 0..2 {
        let mut tx = pool.begin().await.unwrap();
        let r = depot
            .marquer_arret_en_route(&mut tx, arrets[0], coursier, uuid, Utc::now(), Utc::now())
            .await
            .unwrap();
        tx.commit().await.unwrap();
        assert_eq!(r.statut.comme_str(), "en_route");
        horodatages.push(
            sqlx::query_scalar::<_, Option<chrono::DateTime<Utc>>>(
                "SELECT en_route_le FROM commandes.arret WHERE id = $1",
            )
            .bind(arrets[0])
            .fetch_one(&pool)
            .await
            .unwrap(),
        );
    }
    assert_eq!(horodatages[0], horodatages[1], "le rejeu ne réécrit rien");

    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement = 'arret.en_route'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(n, 1, "un seul événement pour deux envois du même uuid");
}

/// **T033** — les refus. La garde est la table FERMÉE : « arriver » sans être
/// parti n'y figure pas, et un arrêt d'une AUTRE course n'appartient pas à
/// l'appelant.
#[sqlx::test(migrations = "../../migrations")]
async fn transitions_hors_sequence_et_hors_course_refusees(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000], true).await;
    let depot = depot(&pool);

    // `à_collecter → arrivé` : absent de la table (data-model §3.3).
    let mut tx = pool.begin().await.unwrap();
    let e = depot
        .marquer_arret_arrive(&mut tx, arrets[0], coursier, Uuid::now_v7(), Utc::now(), Utc::now())
        .await
        .unwrap_err();
    tx.rollback().await.unwrap();
    assert_eq!(e.message_cle(), Some("transition_refusee"));

    // Un AUTRE coursier ne peut pas faire avancer cette course.
    let mut tx = pool.begin().await.unwrap();
    let e = depot
        .marquer_arret_en_route(
            &mut tx, arrets[0], Uuid::now_v7(), Uuid::now_v7(), Utc::now(), Utc::now(),
        )
        .await
        .unwrap_err();
    tx.rollback().await.unwrap();
    assert_eq!(e.message_cle(), Some("non_proprietaire"));

    // Aucun état n'a bougé, aucun événement n'a été écrit.
    let statut: String = sqlx::query_scalar("SELECT statut::text FROM commandes.arret WHERE id = $1")
        .bind(arrets[0])
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(statut, "a_collecter");
    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement LIKE 'arret.%'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(n, 0, "un refus n'émet rien");
}

/// **T033 / décision de conception** — `en_route → collecte` est REFUSÉ : le
/// coursier qui a déclaré partir doit déclarer son arrivée avant de scanner,
/// sans quoi `arrive_le` manquerait et la prime d'attente TRF-06 serait perdue.
/// Le chemin DIRECT `à_collecter → collecte` du cycle 006, lui, reste ouvert.
#[sqlx::test(migrations = "../../migrations")]
async fn scanner_sans_declarer_son_arrivee_est_refuse(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000, 1500], true).await;
    let depot = depot(&pool);

    let mut tx = pool.begin().await.unwrap();
    depot
        .marquer_arret_en_route(&mut tx, arrets[0], coursier, Uuid::now_v7(), Utc::now(), Utc::now())
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let mut tx = pool.begin().await.unwrap();
    let e = depot
        .marquer_arret_collecte(
            &mut tx, arrets[0], Uuid::now_v7(), ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
        )
        .await
        .unwrap_err();
    tx.rollback().await.unwrap();
    assert_eq!(e.message_cle(), Some("etat_incompatible"));

    // Non-régression du cycle 006 : sans déclaration de trajet, le scan passe.
    let mut tx = pool.begin().await.unwrap();
    depot
        .marquer_arret_collecte(
            &mut tx, arrets[1], Uuid::now_v7(), ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
        )
        .await
        .expect("chemin direct du cycle 006 conservé");
    tx.commit().await.unwrap();
}

/// **T034 (CMD-04)** — le PREMIER départ ouvre la collecte : la livraison passe
/// `assignee → en_collecte`, sous garde, avec son événement.
#[sqlx::test(migrations = "../../migrations")]
async fn premier_depart_ouvre_la_collecte(pool: sqlx::PgPool) {
    let (coursier, livraison, arrets) = semer(&pool, &[2000, 1500], true).await;
    let depot = depot(&pool);
    sqlx::query("UPDATE commandes.livraison SET etat = 'assignee' WHERE id = $1")
        .bind(livraison).execute(&pool).await.unwrap();

    let mut tx = pool.begin().await.unwrap();
    let r = depot
        .marquer_arret_en_route(&mut tx, arrets[0], coursier, Uuid::now_v7(), Utc::now(), Utc::now())
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(r.livraison_etat.comme_str(), "en_collecte");

    // Le SECOND départ ne rouvre rien : la garde refuserait `en_collecte →
    // en_collecte`, et le code ne la sollicite même pas.
    let mut tx = pool.begin().await.unwrap();
    let r = depot
        .marquer_arret_en_route(&mut tx, arrets[1], coursier, Uuid::now_v7(), Utc::now(), Utc::now())
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(r.livraison_etat.comme_str(), "en_collecte");

    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement = 'livraison.mise_en_collecte'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(n, 1, "une seule ouverture de collecte par course");
}

/// **T034** — arrêt entièrement indisponible : RÉSOLU au gating, **montant
/// avancé remis à zéro** (le coursier n'a rien acheté), et la course avance
/// jusqu'à la remise même si c'est le dernier étal qui a fermé.
#[sqlx::test(migrations = "../../migrations")]
async fn arret_indisponible_resout_et_annule_l_avance(pool: sqlx::PgPool) {
    let (coursier, livraison, arrets) = semer(&pool, &[2000, 1500], true).await;
    let depot = depot(&pool);

    let mut tx = pool.begin().await.unwrap();
    depot
        .marquer_arret_collecte(
            &mut tx, arrets[0], Uuid::now_v7(), ModeCollecte::ScanQr, None, 10, Utc::now(), coursier,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    // Le vendeur du dernier arrêt a fermé.
    let mut tx = pool.begin().await.unwrap();
    let r = depot
        .marquer_arret_indisponible(
            &mut tx,
            arrets[1],
            coursier,
            Uuid::now_v7(),
            commandes::MotifIndisponible::VendeurFerme,
            Utc::now(),
            Utc::now(),
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert_eq!(r.statut.comme_str(), "indisponible");
    assert!(
        r.progression.en_livraison,
        "un arrêt indisponible est RÉSOLU : la course continue vers le client",
    );
    assert_eq!(r.livraison_etat.comme_str(), "en_livraison");

    let (statut, avance): (String, i64) = sqlx::query_as(
        "SELECT statut::text, montant_avance FROM commandes.arret WHERE id = $1",
    )
    .bind(arrets[1])
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(statut, "indisponible");
    assert_eq!(avance, 0, "rien acheté, rien avancé");

    let etat: String = sqlx::query_scalar("SELECT etat::text FROM commandes.livraison WHERE id = $1")
        .bind(livraison).fetch_one(&pool).await.unwrap();
    assert_eq!(etat, "en_livraison");

    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement = 'arret.indisponible'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(n, 1);
}

/// **T034** — un arrêt indisponible constaté AVANT le trajet est accepté
/// (`à_collecter → indisponible`), et le rejeu du même uuid reste sans effet.
#[sqlx::test(migrations = "../../migrations")]
async fn indisponible_avant_le_trajet_et_idempotent(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000, 1500], true).await;
    let depot = depot(&pool);
    let uuid = Uuid::now_v7();

    for _ in 0..2 {
        let mut tx = pool.begin().await.unwrap();
        let r = depot
            .marquer_arret_indisponible(
                &mut tx,
                arrets[0],
                coursier,
                uuid,
                commandes::MotifIndisponible::VendeurFerme,
                Utc::now(),
                Utc::now(),
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        assert_eq!(r.statut.comme_str(), "indisponible");
    }

    let n: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM outbox.evenement WHERE type_evenement = 'arret.indisponible'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(n, 1, "le rejeu n'émet pas un second événement");
}

#[sqlx::test(migrations = "../../migrations")]
async fn idempotence_meme_uuid(pool: sqlx::PgPool) {
    let (coursier, _l, arrets) = semer(&pool, &[2000], false).await;
    let depot = depot(&pool);
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
