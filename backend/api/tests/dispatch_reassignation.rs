//! US7 (DSP-07) — reprendre l'immobile, épargner celui qui roule, **et ne
//! jamais retirer une course dont le coursier a déjà payé un vendeur**.
//!
//! Les quatre cas du quickstart, dans l'ordre. Le quatrième est celui qui
//! protège l'argent de Yao : il doit échouer bruyamment si quelqu'un relâche la
//! garde.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::DecisionPipeline;
use serde_json::json;
use uuid::Uuid;

/// Assigne une course à un coursier et rend `(commande, livraison)`.
async fn course_assignee(bac: &Bac, index: usize) -> (Uuid, Uuid) {
    bac.dans_le_pool(index, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };
    let faite = bac
        .dispatch
        .accepter_offre(
            offre.id,
            bac.coursiers[index].id,
            Uuid::now_v7(),
            chrono::Utc::now(),
        )
        .await
        .expect("acceptation");
    (commande, faite.livraison)
}

/// **Cas 1** — coursier immobile au-delà du délai : repris, incident tracé,
/// re-proposé.
#[sqlx::test(migrations = "../migrations")]
async fn un_coursier_immobile_est_repris(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, livraison) = course_assignee(&bac, 0).await;

    // Il publie sa position, puis ne bouge plus.
    bac.publier_position(0).await;
    bac.vieillir_progression(livraison, 400).await;

    let resultat = bac.tic().await;
    assert_eq!(resultat.reassignations, 1);

    assert_eq!(bac.cmd.etat_commande(commande).await, "en_attente_coursier");
    let coursier: Option<Uuid> =
        sqlx::query_scalar("SELECT coursier_id FROM commandes.livraison WHERE id = $1")
            .bind(livraison)
            .fetch_one(&bac.cmd.pool)
            .await
            .unwrap();
    assert_eq!(coursier, None);

    // L'incident est TRACÉ, avec son motif.
    let motif: String = sqlx::query_scalar(
        "SELECT motif::text FROM dispatch.incident_reassignation WHERE livraison_id = $1",
    )
    .bind(livraison)
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(motif, "sans_mouvement");

    // Les DEUX parties sont prévenues (FR-073).
    assert!(bac.notifications.contient_cle("dispatch.reassignation.coursier"));
    assert!(bac.notifications.contient_cle("dispatch.reassignation.client"));

    let payloads = bac.evenements("dispatch.reassignation").await;
    assert_eq!(payloads[0]["acteur"], "systeme");
    assert_eq!(payloads[0]["motif"], "sans_mouvement");
}

/// **Cas 2 — SC-015** : un coursier qui SE RAPPROCHE n'est **pas** repris.
///
/// C'est la moitié qui compte : reprendre quelqu'un qui roule lui retirerait
/// une course qu'il était en train d'honorer.
#[sqlx::test(migrations = "../migrations")]
async fn sc015_un_coursier_qui_se_rapproche_n_est_pas_repris(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, livraison) = course_assignee(&bac, 0).await;

    // Première observation : loin.
    bac.proximite.defaut(2_000, 400);
    bac.publier_position(0).await;
    bac.vieillir_progression(livraison, 400).await;

    // Il se rapproche de 1 500 m — bien au-delà du seuil de 150 m.
    bac.proximite.defaut(500, 100);
    bac.publier_position(0).await;

    let resultat = bac.tic().await;
    assert_eq!(
        resultat.reassignations, 0,
        "un coursier qui progresse garde sa course (SC-015)",
    );
    assert_eq!(bac.cmd.etat_commande(commande).await, "en_cours");
}

/// **Cas 3 — FR-078** : un coursier qui a CESSÉ de publier est repris.
/// L'absence de position compte comme absence de mouvement : un téléphone
/// éteint n'est pas un coursier en route.
#[sqlx::test(migrations = "../migrations")]
async fn un_coursier_qui_ne_publie_plus_est_repris(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, livraison) = course_assignee(&bac, 0).await;

    // Aucune observation de progression n'est jamais arrivée ; l'affectation
    // vieillit.
    bac.vieillir_assignation(livraison, 400).await;

    let resultat = bac.tic().await;
    assert_eq!(resultat.reassignations, 1);
}

/// **Cas 4 — FR-075, la garde d'argent.** Un arrêt collecté ⇒ **jamais** de
/// reprise automatique. Le coursier a engagé ses fonds propres.
#[sqlx::test(migrations = "../migrations")]
async fn sc010_un_arret_collecte_interdit_toute_reprise_automatique(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (commande, livraison) = course_assignee(&bac, 0).await;

    // Un arrêt est collecté : de l'argent a été avancé.
    sqlx::query(
        "UPDATE commandes.arret SET statut = 'collecte', collecte_le = now()
         WHERE segment_id IN (SELECT id FROM commandes.segment WHERE livraison_id = $1)
           AND type_arret = 'collecte'",
    )
    .bind(livraison)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();

    bac.vieillir_assignation(livraison, 4_000).await;
    let resultat = bac.tic().await;

    assert_eq!(
        resultat.reassignations, 0,
        "l'automatisme ne retire JAMAIS une marchandise payée (FR-075)",
    );
    assert_eq!(resultat.courses_bloquees, 1);
    assert_eq!(bac.cmd.etat_commande(commande).await, "en_cours");
    assert_eq!(
        bac.nb_evenements("dispatch.course_bloquee_escaladee").await,
        1,
    );

    // L'exploitation est alertée — et elle seule peut trancher.
    assert!(bac.notifications.contient_cle("dispatch.course_bloquee"));
    let payloads = bac.evenements("dispatch.course_bloquee_escaladee").await;
    assert!(payloads[0]["nb_arrets_collectes"].as_i64().unwrap() > 0);

    // Rebalayer ne ré-émet rien : l'alerte ne doit pas noyer l'exploitation.
    bac.tic().await;
    assert_eq!(
        bac.nb_evenements("dispatch.course_bloquee_escaladee").await,
        1,
    );

    // La reprise MANUELLE, elle, est possible — motif obligatoire.
    let (statut, corps) = bac
        .post(
            &format!("/admin/dispatch/courses/{livraison}/reprendre"),
            &bac.cmd.jeton_admin,
            json!({ "motif": "coursier injoignable depuis 20 min, marchandise au local" }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["etat_commande"], "en_attente_coursier");
    assert_eq!(bac.cmd.etat_commande(commande).await, "en_attente_coursier");

    let payloads = bac.evenements("dispatch.reassignation").await;
    assert_eq!(payloads.last().unwrap()["acteur"], "admin");
}

/// **Pas de reprise en boucle** (FR-076) : l'index UNIQUE par motif tient. Sans
/// lui, un rebalayage retirerait la course au coursier suivant toutes les cinq
/// minutes.
#[sqlx::test(migrations = "../migrations")]
async fn le_rebalayage_ne_reprend_pas_en_boucle(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, livraison) = course_assignee(&bac, 0).await;
    bac.vieillir_assignation(livraison, 4_000).await;

    assert_eq!(bac.tic().await.reassignations, 1);
    // La commande est réassignée au même coursier (seul du pool), et le tic
    // repasse : aucun second retrait pour le même motif.
    let incidents: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM dispatch.incident_reassignation WHERE livraison_id = $1",
    )
    .bind(livraison)
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(incidents, 1);
}

/// **SC-010** — une réassignation ne recalcule **jamais** le devis figé
/// (FR-077). Le prix promis au client et la part du coursier ne bougent pas.
#[sqlx::test(migrations = "../migrations")]
async fn une_reassignation_ne_touche_pas_au_devis_fige(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, livraison) = course_assignee(&bac, 0).await;

    let avant: (i64, i64) = sqlx::query_as(
        "SELECT devis_prix_client, devis_part_coursier FROM commandes.livraison WHERE id = $1",
    )
    .bind(livraison)
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();

    bac.vieillir_assignation(livraison, 4_000).await;
    bac.tic().await;

    let apres: (i64, i64) = sqlx::query_as(
        "SELECT devis_prix_client, devis_part_coursier FROM commandes.livraison WHERE id = $1",
    )
    .bind(livraison)
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(avant, apres, "le devis figé ne se recalcule jamais (FR-077)");
}

/// La reprise manuelle **refuse** quand aucun arrêt n'est collecté : dans ce
/// cas l'automatisme suffit, et une action manuelle masquerait un défaut de
/// pipeline.
#[sqlx::test(migrations = "../migrations")]
async fn la_reprise_manuelle_refuse_sans_arret_collecte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, livraison) = course_assignee(&bac, 0).await;

    let (statut, corps) = bac
        .post(
            &format!("/admin/dispatch/courses/{livraison}/reprendre"),
            &bac.cmd.jeton_admin,
            json!({ "motif": "au cas où" }),
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "reprise_inutile");
}

/// Le **motif est obligatoire** : une reprise sans raison journalisée n'est pas
/// auditable.
#[sqlx::test(migrations = "../migrations")]
async fn la_reprise_manuelle_exige_un_motif(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, livraison) = course_assignee(&bac, 0).await;
    sqlx::query(
        "UPDATE commandes.arret SET statut = 'collecte', collecte_le = now()
         WHERE segment_id IN (SELECT id FROM commandes.segment WHERE livraison_id = $1)
           AND type_arret = 'collecte'",
    )
    .bind(livraison)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();

    let (statut, corps) = bac
        .post(
            &format!("/admin/dispatch/courses/{livraison}/reprendre"),
            &bac.cmd.jeton_admin,
            json!({ "motif": "   " }),
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "motif_requis");

    // Et le rôle est gardé : un coursier ne reprend pas les courses.
    let (statut, _) = bac
        .post(
            &format!("/admin/dispatch/courses/{livraison}/reprendre"),
            &bac.coursiers[0].jeton,
            json!({ "motif": "je veux cette course" }),
        )
        .await;
    assert_eq!(statut, 403);

}
