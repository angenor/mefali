//! US6 (DSP-06) — prévenir l'exploitation **et** la cliente.
//!
//! **SC-006** : exactement une alerte par commande, quel que soit le chemin.
//! Le marqueur d'idempotence est l'événement outbox lui-même — aucune colonne
//! parallèle ne peut s'en désynchroniser.
//!
//! Et l'escalade **n'arrête pas** la recherche : alerter sans continuer à
//! chercher reviendrait à abandonner la commande en le disant poliment.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::Canal;

/// Une commande sans preneur au-delà du seuil : **une** alerte d'exploitation,
/// **une** notification cliente, et l'annulation sans frais offerte.
#[sqlx::test(migrations = "../migrations")]
async fn une_alerte_et_une_annulation_sans_frais(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prete().await;
    bac.vieillir_commande(commande, 400).await;

    bac.tic().await;

    assert_eq!(
        bac.nb_evenements("commande.attente_coursier_escaladee")
            .await,
        1,
    );
    let payloads = bac.evenements("commande.attente_coursier_escaladee").await;
    assert_eq!(payloads[0]["seuil_s"], 300);
    assert!(payloads[0]["age_s"].as_i64().unwrap() >= 300);

    // L'exploitation est alertée.
    let vers_exploitation = bac.notifications.sur_canal(Canal::Exploitation);
    assert_eq!(vers_exploitation.len(), 1);
    assert_eq!(
        vers_exploitation[0].destinataire, None,
        "l'exploitation n'est personne en particulier",
    );

    // La cliente aussi — et son annonce OUVRE UN DROIT : annuler sans frais.
    let vers_client = bac.notifications.sur_canal(Canal::Client);
    assert_eq!(vers_client.len(), 1);
    assert!(
        vers_client[0].action_annulation_sans_frais,
        "attendre sans pouvoir renoncer n'est pas acceptable (FR-065)",
    );
    assert_eq!(vers_client[0].cle_i18n, "dispatch.escalade.client");
}

/// **SC-006** — rebalayer n'en ré-émet **aucune**. Une alerte répétée toutes
/// les 5 s noierait exactement ce qu'elle est censée signaler.
#[sqlx::test(migrations = "../migrations")]
async fn sc006_rebalayer_ne_reemet_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prete().await;
    bac.vieillir_commande(commande, 400).await;

    for _ in 0..5 {
        bac.tic().await;
    }

    assert_eq!(
        bac.nb_evenements("commande.attente_coursier_escaladee")
            .await,
        1,
        "cinq passages de tic, UNE alerte",
    );

    // La requête de contrôle du quickstart : aucun doublon, jamais.
    let doublons: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (
             SELECT entite_id FROM outbox.evenement
             WHERE type_evenement = 'commande.attente_coursier_escaladee'
             GROUP BY 1 HAVING count(*) > 1) t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(doublons, 0);
}

/// **Deux chemins d'arrivée, une alerte chacune** : la commande restée
/// `nouvelle` que le pipeline n'a pas placée (`pipeline`), et celle qui attend
/// dans la file (`file`).
#[sqlx::test(migrations = "../migrations")]
async fn les_deux_chemins_donnent_chacun_une_alerte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    // Chemin « pipeline » : jamais placée, encore `nouvelle`.
    let par_pipeline = bac.commande_prete().await;
    bac.vieillir_commande(par_pipeline, 400).await;

    // Chemin « file » : mise en attente faute d'éligible.
    let par_file = bac.commande_prete().await;
    bac.dispatcher(par_file).await;
    assert_eq!(bac.cmd.etat_commande(par_file).await, "en_attente_coursier");
    bac.vieillir_commande(par_file, 400).await;

    bac.tic().await;

    let payloads = bac.evenements("commande.attente_coursier_escaladee").await;
    assert_eq!(
        payloads.len(),
        2,
        "une alerte par commande, pas une de plus"
    );
    let chemins: Vec<&str> = payloads
        .iter()
        .map(|p| p["chemin"].as_str().unwrap())
        .collect();
    assert!(chemins.contains(&"pipeline"));
    assert!(chemins.contains(&"file"));
}

/// Une commande escaladée **reste assignable** : l'escalade prévient, elle
/// n'abandonne pas.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_escaladee_reste_assignable(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prete().await;
    bac.vieillir_commande(commande, 400).await;
    bac.tic().await;
    assert_eq!(
        bac.nb_evenements("commande.attente_coursier_escaladee")
            .await,
        1
    );

    // Un coursier arrive : la commande part quand même. À 400 s d'âge elle a
    // aussi dépassé le seuil de broadcast (120 s) — c'est donc un broadcast qui
    // s'ouvre, et c'est exactement ce qu'on veut d'une commande qui traîne.
    bac.dans_le_pool(0, 15_000).await;
    let decision = bac.dispatcher(commande).await;
    assert!(
        matches!(
            decision,
            dispatch::DecisionPipeline::OffreEmise(_)
                | dispatch::DecisionPipeline::BroadcastOuvert { .. }
        ),
        "escalader n'est pas abandonner : {decision:?}",
    );
    let offres: i64 =
        sqlx::query_scalar("SELECT count(*) FROM dispatch.offre WHERE commande_id = $1")
            .bind(commande)
            .fetch_one(&bac.cmd.pool)
            .await
            .unwrap();
    assert_eq!(offres, 1, "la course a bien été proposée après l'escalade");
}

/// L'endpoint admin rend les alertes, **les plus anciennes d'abord**, et il est
/// réservé au rôle `Admin`.
#[sqlx::test(migrations = "../migrations")]
async fn l_endpoint_admin_liste_les_alertes(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prete().await;
    bac.vieillir_commande(commande, 400).await;
    bac.tic().await;

    let (statut, corps) = bac
        .get("/admin/dispatch/alertes", &bac.cmd.jeton_admin)
        .await;
    assert_eq!(statut, 200, "{corps}");
    let escalades = corps["escalades"].as_array().unwrap();
    assert_eq!(escalades.len(), 1);
    assert_eq!(escalades[0]["commande_id"], commande.to_string());
    assert_eq!(escalades[0]["chemin"], "pipeline");
    assert_eq!(escalades[0]["seuil_s"], 300);

    // Un coursier n'y a pas accès.
    let (statut, _) = bac
        .get("/admin/dispatch/alertes", &bac.coursiers[0].jeton)
        .await;
    assert_eq!(statut, 403);
}
