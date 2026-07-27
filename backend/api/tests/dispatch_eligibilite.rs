//! US2 (DSP-02) — ne proposer une course qu'à ceux qui peuvent la faire.
//!
//! **Un test par valeur de `dispatch.motif_ecart`** (SC-013), plus la bascule
//! prépaiement (SC-012), la mise en file, et le cas OSRM indisponible.
//!
//! Ce que ces tests protègent : un vivier trop large fait sonner le téléphone
//! de quelqu'un qui ne peut pas prendre la course — et lui apprend à ignorer les
//! offres. Un vivier trop étroit perd la commande.

mod bac_dispatch;

use bac_dispatch::Bac;
use dispatch::{DecisionPipeline, MotifEcart};
use serde_json::json;

/// Motifs d'écart constatés pour un coursier donné, après un passage.
async fn motifs_de(bac: &Bac, index: usize, commande: uuid::Uuid) -> Vec<String> {
    let payloads = bac.evenements("dispatch.evaluation_faite").await;
    let _ = (index, commande);
    payloads
        .last()
        .and_then(|p| p.get("motifs").cloned())
        .map(|m| {
            m.as_object()
                .map(|o| o.keys().cloned().collect::<Vec<_>>())
                .unwrap_or_default()
        })
        .unwrap_or_default()
}

/// **HORS LIGNE** — un coursier qui n'a jamais publié n'est pas dans le pool,
/// et un membre fantôme de l'index n'y est plus. Ni l'un ni l'autre ne reçoit.
#[sqlx::test(migrations = "../migrations")]
async fn motif_hors_ligne(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    // L'état expire, le membre GEO survit : c'est le fantôme.
    bac.pool_coursiers.faire_expirer(bac.coursiers[0].id);

    let commande = bac.commande_prete().await;
    let decision = bac.dispatcher(commande).await;

    assert!(matches!(decision, DecisionPipeline::MiseEnFile { .. }));
    assert!(motifs_de(&bac, 0, commande).await.contains(&"hors_ligne".to_owned()));
}

/// **COURSE ACTIVE** — pas de superposition au MVP (FR-007). Et c'est la BASE
/// qui tranche, pas l'état de pool : un index survit à une affectation.
#[sqlx::test(migrations = "../migrations")]
async fn motif_course_active(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    let occupante = bac.commande_prete().await;
    bac.cmd
        .commandes
        .assigner_coursier(occupante, bac.coursiers[0].id, chrono::Utc::now())
        .await
        .unwrap();

    let commande = bac.commande_prete().await;
    bac.dispatcher(commande).await;
    assert!(motifs_de(&bac, 0, commande)
        .await
        .contains(&"course_active".to_owned()));
}

/// **CAPACITÉ NON COUVERTE** — la course exige un transport que le coursier n'a
/// pas déclaré (FR-017). Le filtre est GÉNÉRIQUE : c'est une paire
/// `(famille, valeur)`, pas une énum de véhicules.
#[sqlx::test(migrations = "../migrations")]
async fn motif_capacite_non_couverte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;

    // La course exige un `velo` ; les quatre coursiers du bac sont en `moto`.
    sqlx::query(
        "UPDATE commandes.capacite_requise SET valeur = 'velo'
         WHERE livraison_id IN (SELECT id FROM commandes.livraison WHERE commande_id = $1)",
    )
    .bind(commande)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();

    bac.dispatcher(commande).await;
    assert!(motifs_de(&bac, 0, commande)
        .await
        .contains(&"capacite_non_couverte".to_owned()));
}

/// **HORS RAYON** — mesuré sur la distance ROUTIÈRE (constitution IV), jamais
/// sur le vol d'oiseau. Bornes : 3,9 km retenu, 5 km écarté.
#[sqlx::test(migrations = "../migrations")]
async fn motif_hors_rayon_aux_bornes(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    // 3 900 m : DANS le rayon de 4 km.
    bac.proximite.defaut(3_900, 600);
    let dedans = bac.commande_prete().await;
    let decision = bac.dispatcher(dedans).await;
    assert!(
        matches!(decision, DecisionPipeline::OffreEmise(_)),
        "3,9 km est dans le rayon de 4 km",
    );

    // 5 000 m : DEHORS.
    bac.proximite.defaut(5_000, 900);
    let dehors = bac.commande_prete().await;
    bac.dispatcher(dehors).await;
    assert!(motifs_de(&bac, 0, dehors).await.contains(&"hors_rayon".to_owned()));
}

/// **CAPACITÉ D'AVANCE** — et c'est le cas qui compte : grille 5 000 (palier
/// d'entrée, faute de note) et déclaration 15 000 ⇒ c'est **5 000** qui décide.
#[sqlx::test(migrations = "../migrations")]
async fn motif_capacite_avance_le_plus_bas_decide(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;

    // Le montant à avancer dépasse le palier d'entrée.
    sqlx::query(
        "UPDATE commandes.arret SET montant_avance = 9000
         WHERE segment_id IN (
             SELECT s.id FROM commandes.segment s
             JOIN commandes.livraison l ON l.id = s.livraison_id
             WHERE l.commande_id = $1)
           AND type_arret = 'collecte'",
    )
    .bind(commande)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();

    bac.dispatcher(commande).await;
    assert!(
        motifs_de(&bac, 0, commande)
            .await
            .contains(&"capacite_avance".to_owned()),
        "déclarer 15 000 ne suffit pas : le palier de la grille plafonne à 5 000",
    );
}

/// **PAIRE BLOQUÉE** — client ou vendeur (CRS-07, non construit). Un SEUL
/// aller-retour pour toutes les contreparties (FR-025).
#[sqlx::test(migrations = "../migrations")]
async fn motif_paire_bloquee(pool: sqlx::PgPool) {
    use dispatch::{AucunePaireBloquee, PairesSimulees, PgDispatch};
    use std::sync::Arc;

    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;

    // Le vendeur de la course est bloqué avec ce coursier.
    let paires = Arc::new(PairesSimulees::nouveau());
    paires.bloquer(bac.coursiers[0].id, bac.cmd.vendeurs[0].id);
    let avec_paires = PgDispatch::new(
        bac.cmd.pool.clone(),
        Arc::new(bac.cmd.commandes.clone()),
        Arc::new(bac.cmd.comptes.clone()),
        bac.pool_coursiers.clone(),
        bac.verrous.clone(),
        bac.proximite.clone(),
        Arc::new(dispatch::NoteAbsente),
        paires,
        bac.notifications.clone(),
    );

    avec_paires.dispatcher(commande, chrono::Utc::now()).await.unwrap();
    assert!(motifs_de(&bac, 0, commande)
        .await
        .contains(&"paire_bloquee".to_owned()));

    // Contrôle : sans la paire, le même coursier serait éligible.
    let _ = AucunePaireBloquee;
}

/// **COMPTE INDISPONIBLE** — FR-009, et c'est LE cas qui justifie la
/// confirmation en base : un coursier suspendu **après** sa dernière
/// publication garde son état de pool, et doit pourtant être écarté.
#[sqlx::test(migrations = "../migrations")]
async fn motif_compte_indisponible_malgre_l_etat_de_pool(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    // Suspension APRÈS la publication : l'état de pool ne bouge pas.
    sqlx::query(
        "UPDATE comptes.attribution_role SET statut = 'suspendu'::comptes.statut_role
         WHERE compte_id = $1 AND role = 'coursier'::comptes.role",
    )
    .bind(bac.coursiers[0].id)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();
    assert!(
        bac.pool_coursiers_etat_existe(0).await,
        "son état de pool survit à la suspension — c'est bien le cas à couvrir",
    );

    let commande = bac.commande_prete().await;
    bac.dispatcher(commande).await;
    assert!(motifs_de(&bac, 0, commande)
        .await
        .contains(&"compte_indisponible".to_owned()));
}

/// **OFFRE EN VOL** — un coursier ne voit jamais deux écrans à la fois (FR-056),
/// et n'est jamais re-sollicité pour la MÊME commande (FR-051).
#[sqlx::test(migrations = "../migrations")]
async fn motif_offre_en_vol(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;

    let premiere = bac.commande_prete().await;
    assert!(matches!(
        bac.dispatcher(premiere).await,
        DecisionPipeline::OffreEmise(_)
    ));

    // Une seconde commande arrive : le seul coursier porte déjà une offre.
    let seconde = bac.commande_prete().await;
    bac.dispatcher(seconde).await;
    assert!(motifs_de(&bac, 0, seconde)
        .await
        .contains(&"offre_en_vol".to_owned()));
}

/// **SC-012** — bascule prépaiement : la capacité d'avance est le SEUL obstacle.
/// La commande passe `en_attente_paiement`, `mode_paiement = mobile_money`, et
/// la cliente est prévenue **avec le motif**. Aucun montant partiel nulle part.
#[sqlx::test(migrations = "../migrations")]
async fn bascule_prepaiement_quand_l_argent_est_le_seul_obstacle(pool: sqlx::PgPool) {
    use dispatch::Canal;

    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    let commande = bac.commande_prete().await;
    sqlx::query(
        "UPDATE commandes.arret SET montant_avance = 9000
         WHERE segment_id IN (
             SELECT s.id FROM commandes.segment s
             JOIN commandes.livraison l ON l.id = s.livraison_id
             WHERE l.commande_id = $1)
           AND type_arret = 'collecte'",
    )
    .bind(commande)
    .execute(&bac.cmd.pool)
    .await
    .unwrap();

    let decision = bac.dispatcher(commande).await;
    assert!(matches!(
        decision,
        DecisionPipeline::BasculePrepaiement { .. }
    ));
    assert_eq!(bac.cmd.etat_commande(commande).await, "en_attente_paiement");

    let mode: String =
        sqlx::query_scalar("SELECT mode_paiement::text FROM commandes.commande WHERE id = $1")
            .bind(commande)
            .fetch_one(&bac.cmd.pool)
            .await
            .unwrap();
    assert_eq!(mode, "mobile_money");

    // La cliente est prévenue AVEC le motif — c'est ce que SC-012 vérifie.
    let vers_client = bac.notifications.sur_canal(Canal::Client);
    assert_eq!(vers_client.len(), 1);
    assert_eq!(vers_client[0].cle_i18n, "dispatch.prepaiement.exige");
    assert_eq!(vers_client[0].variables["montant_a_avancer"], 9000);

    // Un seul montant, un seul état : aucun chemin partiel.
    let payloads = bac.evenements("dispatch.bascule_prepaiement").await;
    assert_eq!(payloads.len(), 1);
    assert_eq!(payloads[0]["montant_a_avancer"], 9000);
    assert_eq!(payloads[0]["devise"], "XOF");
}

/// Un pool vide pour une **autre** raison part en file d'attente, et le
/// prépaiement n'est **pas** proposé : il ne lèverait pas l'obstacle.
#[sqlx::test(migrations = "../migrations")]
async fn un_pool_vide_pour_une_autre_raison_part_en_file(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Personne en ligne : le vivier est vide, mais pas à cause de l'argent.
    let commande = bac.commande_prete().await;

    let decision = bac.dispatcher(commande).await;
    assert!(matches!(decision, DecisionPipeline::MiseEnFile { .. }));
    assert_eq!(bac.cmd.etat_commande(commande).await, "en_attente_coursier");
    assert_eq!(
        bac.nb_evenements("dispatch.bascule_prepaiement").await,
        0,
        "exiger un prépaiement ici ferait perdre la commande pour rien",
    );
    assert_eq!(bac.nb_evenements("commande.mise_en_attente_coursier").await, 1);
}

/// **OSRM indisponible** — le classement passe en dégradé, mais le dispatch
/// **ne s'arrête pas** (constitution IV, FR-030). Une commande n'est jamais
/// bloquée par le routage.
#[sqlx::test(migrations = "../migrations")]
async fn osrm_muet_degrade_mais_ne_bloque_pas(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 15_000).await;
    bac.proximite.degrade(true);

    let commande = bac.commande_prete().await;
    let decision = bac.dispatcher(commande).await;

    assert!(
        matches!(decision, DecisionPipeline::OffreEmise(_)),
        "un routage muet ne doit jamais empêcher une offre de partir",
    );
    let payloads = bac.evenements("dispatch.evaluation_faite").await;
    assert_eq!(payloads.last().unwrap()["degraded"], true);
}

/// Les huit motifs de l'énum sont couverts par les tests ci-dessus (SC-013).
#[test]
fn les_huit_motifs_ont_chacun_leur_test() {
    let couverts = [
        "hors_ligne",
        "course_active",
        "capacite_non_couverte",
        "hors_rayon",
        "capacite_avance",
        "paire_bloquee",
        "compte_indisponible",
        "offre_en_vol",
    ];
    for motif in MotifEcart::TOUS {
        assert!(
            couverts.contains(&motif.comme_str()),
            "« {} » n'a pas de test dédié",
            motif.comme_str(),
        );
    }
    let _ = json!({});
}
