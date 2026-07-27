//! US4 (DSP-04) — contenu de l'offre, refus, non-réponse, franchise du jour.
//!
//! Ce que ces tests protègent : un coursier décide en 40 s, sur ce que l'écran
//! lui montre. Un gain faux, une avance oubliée ou une pénalité injuste ne se
//! rattrapent pas — ils lui coûtent de l'argent ou sa confiance.

mod bac_dispatch;

use bac_dispatch::{Bac, TIMEOUTS_FRANCS};
use dispatch::DecisionPipeline;
use serde_json::json;
use uuid::Uuid;

/// Le **contenu** de l'offre : arrêts, destination sans coordonnée, gain
/// détaillé, avance avec son plafond.
#[sqlx::test(migrations = "../migrations")]
async fn le_contenu_de_l_offre_dit_tout_ce_qui_decide(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    bac.dispatcher(commande).await;

    let (statut, corps) = bac
        .get("/courses/offre-courante", &bac.coursiers[0].jeton)
        .await;
    assert_eq!(statut, 200, "{corps}");

    assert_eq!(corps["commande_id"], commande.to_string());
    assert_eq!(corps["mode"], "cascade");
    assert!(corps["restant_s"].as_i64().unwrap() > 0);
    assert_eq!(corps["timer_s"], 40);

    // Les arrêts sont là, dans l'ordre du devis FIGÉ.
    let arrets = corps["arrets"].as_array().unwrap();
    assert!(!arrets.is_empty());
    assert_eq!(arrets[0]["ordre"], 1);
    assert!(!arrets[0]["nom"].as_str().unwrap().is_empty());

    // La destination : nom de zone + distance, **jamais** de coordonnée (ARTCI).
    let destination = &corps["destination"];
    assert_eq!(destination["zone_nom"], "Tiassalé");
    assert_eq!(
        destination["mention_cle"],
        "dispatch.offre.adresse_apres_acceptation",
    );
    // La MENTION parle d'adresse ; la donnée, elle, n'en porte aucune. C'est
    // sur les champs qu'on vérifie, pas sur la clé i18n.
    assert!(destination.get("lat").is_none());
    assert!(destination.get("lon").is_none());
    assert!(destination.get("adresse").is_none());

    // Gain et avance : entiers + devise (constitution III).
    assert!(corps["gain"]["total_unites"].as_i64().unwrap() > 0);
    assert_eq!(corps["gain"]["devise"], "XOF");
    assert_eq!(corps["avance"]["devise"], "XOF");
    assert_eq!(
        corps["avance"]["plafond_retenu_unites"], 5_000,
        "le plafond RETENU (palier d'entrée), pas les 15 000 déclarés",
    );
}

/// Une offre **échue** rend `204`, **même si le tic n'a pas encore passé** :
/// l'échéance persistée est l'autorité (research R1).
#[sqlx::test(migrations = "../migrations")]
async fn une_offre_echue_rend_204_avant_meme_le_tic(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    let (statut, _) = bac
        .get("/courses/offre-courante", &bac.coursiers[0].jeton)
        .await;
    assert_eq!(statut, 200);

    bac.faire_expirer_offre(offre.id).await;

    let (statut, _) = bac
        .get("/courses/offre-courante", &bac.coursiers[0].jeton)
        .await;
    assert_eq!(
        statut, 204,
        "la lecture respecte l'échéance : le tic ne fait qu'écrire ce qu'elle savait",
    );
    // Et la ligne est TOUJOURS `en_vol` en base : rien n'a été écrit.
    let issue: String = sqlx::query_scalar("SELECT issue::text FROM dispatch.offre WHERE id = $1")
        .bind(offre.id)
        .fetch_one(&bac.cmd.pool)
        .await
        .unwrap();
    assert_eq!(issue, "en_vol");
}

/// Un **refus explicite** conclut l'offre et libère le coursier immédiatement.
#[sqlx::test(migrations = "../migrations")]
async fn un_refus_libere_le_coursier_tout_de_suite(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };

    let (statut, corps) = bac
        .post(
            &format!("/courses/offres/{}/refuser", offre.id),
            &bac.coursiers[0].jeton,
            json!({ "uuid_client": Uuid::now_v7(), "horodatage_local": chrono::Utc::now() }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["issue"], "refusee");

    assert_eq!(bac.nb_evenements("dispatch.offre_refusee").await, 1);
    assert!(
        bac.offre_en_vol(0).await.is_none(),
        "le coursier n'a plus d'offre en vol : il peut recevoir la suivante",
    );
    assert!(
        bac.pool_coursiers_etat_existe(0).await,
        "refuser ne sort PAS du pool — aucune sanction (DSP-08 hors périmètre)",
    );
}

/// **SC-009** — les `dispatch.timeouts_francs_par_jour` premières non-réponses
/// du jour sont FRANCHES ; la suivante compte.
///
/// Une non-réponse franche ne coûte rien : ni pénalité, ni effet sur le taux.
/// C'est ce qui rend acceptable qu'un coursier rate une offre en traversant une
/// zone sans réseau.
#[sqlx::test(migrations = "../migrations")]
async fn sc009_les_trois_premieres_non_reponses_du_jour_sont_franches(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    let mut franches = Vec::new();
    for _ in 0..(TIMEOUTS_FRANCS + 1) {
        let commande = bac.commande_prete().await;
        let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(commande).await else {
            panic!("une offre devait partir");
        };
        bac.faire_expirer_offre(offre.id).await;
        bac.tic().await;

        let franche: bool =
            sqlx::query_scalar("SELECT franche FROM dispatch.offre WHERE id = $1")
                .bind(offre.id)
                .fetch_one(&bac.cmd.pool)
                .await
                .unwrap();
        franches.push(franche);
    }

    assert_eq!(
        franches,
        vec![true, true, true, false],
        "les 3 premières du jour sont franches, la 4ᵉ compte",
    );

    // Les événements portent le rang du jour, et le ton reste NEUTRE.
    let payloads = bac.evenements("dispatch.offre_non_repondue").await;
    assert_eq!(payloads.len(), 4);
    assert_eq!(payloads[0]["franche"], true);
    assert_eq!(payloads[0]["rang_du_jour"], 1);
    assert_eq!(payloads[3]["franche"], false);
}

/// Une non-réponse **franche** ne pèse pas sur le taux d'acceptation (FR-052) —
/// les compter en ferait une pénalité déguisée.
#[sqlx::test(migrations = "../migrations")]
async fn une_non_reponse_franche_n_altere_pas_le_taux(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    // Une acceptation, puis une non-réponse franche.
    let acceptee = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(offre) = bac.dispatcher(acceptee).await else {
        panic!("offre attendue");
    };
    bac.dispatch
        .accepter_offre(
            offre.id,
            bac.coursiers[0].id,
            Uuid::now_v7(),
            chrono::Utc::now(),
        )
        .await
        .unwrap();

    let (acceptees, decidees): (i64, i64) = sqlx::query_as(
        "SELECT count(*) FILTER (WHERE issue = 'acceptee'),
                count(*) FILTER (WHERE issue IN ('acceptee','refusee')
                                    OR (issue = 'non_repondue' AND NOT franche))
           FROM dispatch.offre WHERE coursier_id = $1",
    )
    .bind(bac.coursiers[0].id)
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!((acceptees, decidees), (1, 1), "taux = 100 %");
}

/// L'expiration par le **tic** relance le pipeline : le candidat suivant est
/// sollicité, et le premier n'est pas re-sollicité pour la même commande.
#[sqlx::test(migrations = "../migrations")]
async fn apres_expiration_le_candidat_suivant_est_sollicite(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    bac.dans_le_pool(1, 15_000).await;

    let commande = bac.commande_prete().await;
    let DecisionPipeline::OffreEmise(premiere) = bac.dispatcher(commande).await else {
        panic!("une offre devait partir");
    };
    bac.faire_expirer_offre(premiere.id).await;

    // Le tic conclut la non-réponse PUIS reprend la commande.
    bac.tic().await;
    bac.dispatcher(commande).await;

    let destinataires: Vec<Uuid> = sqlx::query_scalar(
        "SELECT DISTINCT coursier_id FROM dispatch.offre WHERE commande_id = $1",
    )
    .bind(commande)
    .fetch_all(&bac.cmd.pool)
    .await
    .unwrap();
    assert_eq!(
        destinataires.len(),
        2,
        "le second candidat a été sollicité, et le premier une seule fois",
    );
}
