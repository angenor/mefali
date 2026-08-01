//! US6 (cycle PAY 011, T069) — les créances naissent seules, se règlent une
//! fois, et laissent leur trace au livre.
//!
//! Quatre propriétés, et chacune répond à une façon précise de perdre de
//! l'argent :
//!
//! 1. **La créance naît sans intervention humaine** (FR-063, clarification Q2).
//!    Un produit qui demanderait à un humain de créer la dette qu'il doit
//!    ensuite payer aurait exactement le biais qu'on veut éviter.
//! 2. **Un rejeu de la fin de course ne crée aucune créance de plus** (FR-068,
//!    SC-008). Le worker outbox livre AU MOINS une fois, et la file hors-ligne
//!    du coursier rejoue aussi : sans idempotence, chaque relivraison doublerait
//!    la dette.
//! 3. **Le règlement écrit au livre**, dans la même transaction que la bascule
//!    d'état (research R12). Une créance marquée réglée sans mouvement de
//!    caisse serait un versement invisible.
//! 4. **Un second règlement est refusé** (`409`, FR-064). Le marquage n'est pas
//!    une bascule : une erreur se corrige par une écriture INVERSE, jamais en
//!    repassant `reglee → due`. Un livre qu'on peut rembobiner ne prouve plus
//!    rien.

mod bac_coursier;

use bac_coursier::{Bac, Course, DEVIS_PART_COURSIER};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

/// Confirme la remise, puis draine la caisse — le chemin nominal de fin de
/// course.
async fn livrer(bac: &Bac, course: &Course) {
    bac.arriver_chez_le_client(course).await;
    let secrets = bac.secrets_remise(course.commande).await;
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "remise refusée : {corps}");
    bac.drainer_caisse().await;
}

/// SC-008 — la créance naît **sans intervention humaine**, et un rejeu de la
/// fin de course n'en crée aucune de plus.
#[sqlx::test(migrations = "../migrations")]
async fn les_creances_naissent_seules_et_le_rejeu_ne_double_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&course).await;

    // Avant la livraison : aucune créance. La commande est prépayée depuis le
    // départ, mais rien n'est dû tant que la course n'est pas faite.
    assert!(
        bac.creances(bac.coursier).await.is_empty(),
        "une créance avant la livraison serait une dette née de rien",
    );

    livrer(&bac, &course).await;

    let creances = bac.creances(bac.coursier).await;
    assert_eq!(creances.len(), 2, "l'avance ET la part, sans qu'on demande");
    assert_eq!(
        bac.nb_evenements("caisse.creance_ouverte").await,
        2,
        "chaque créance émet son événement — sans quoi NTF et les métriques \
         ne sauraient rien",
    );

    // ── Le rejeu : le worker relivre, la file hors-ligne aussi ────────────
    //
    // `drainer_caisse` rejoue le journal ENTIER, exactement comme un lot
    // d'outbox retenté. L'idempotence est portée par `evenement_id UNIQUE` et
    // par `(livraison, nature) UNIQUE` — deux contraintes de base, pas deux
    // `if` lus avant l'écriture.
    bac.drainer_caisse().await;
    bac.drainer_caisse().await;

    assert_eq!(
        bac.creances(bac.coursier).await.len(),
        2,
        "trois passages, deux créances — l'idempotence est structurelle",
    );
    assert_eq!(bac.nb_evenements("caisse.creance_ouverte").await, 2);
}

/// FR-067, R12 — le règlement écrit son mouvement au livre, et le solde remonte
/// **du montant exact**.
#[sqlx::test(migrations = "../migrations")]
async fn le_reglement_ecrit_au_livre_et_remonte_le_solde(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_mefali(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    livrer(&bac, &course).await;

    let solde_avant = bac.solde_livre(bac.coursier).await;
    assert_eq!(solde_avant, 0, "promotion Mefali : rien n'a été encaissé");
    assert_eq!(bac.du_par_mefali(bac.coursier).await, DEVIS_PART_COURSIER);

    let creance = sqlx::query_scalar::<_, Uuid>(
        "SELECT id FROM coursier.creance WHERE coursier_id = $1 AND etat = 'due'",
    )
    .bind(bac.coursier)
    .fetch_one(&bac.pool)
    .await
    .unwrap();

    let (statut, corps) = bac
        .post(
            &format!("/admin/creances/{creance}/regler"),
            &bac.jeton_admin,
            json!({ "motif_cle": "creance.reglement.virement_agence" }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["etat"], "reglee");

    // L'écriture est au livre, avec sa nature.
    let reglements: Vec<(String, i64)> = sqlx::query_as(
        "SELECT type::text, montant_unites FROM coursier.ecriture_caisse
          WHERE coursier_id = $1 AND type = 'reglement'",
    )
    .bind(bac.coursier)
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert_eq!(reglements.len(), 1, "un règlement, une écriture");
    assert_eq!(reglements[0].1, DEVIS_PART_COURSIER, "au franc près");

    assert_eq!(
        bac.solde_livre(bac.coursier).await,
        solde_avant + DEVIS_PART_COURSIER,
        "le solde remonte exactement du montant versé",
    );
    assert_eq!(bac.du_par_mefali(bac.coursier).await, 0, "plus rien n'est dû");
    assert_eq!(
        bac.nb_evenements("caisse.creance_reglee").await,
        1,
        "le versement laisse sa trace dans le journal",
    );
}

/// FR-064 — un **second** règlement est refusé. Le marquage n'est pas une
/// bascule.
#[sqlx::test(migrations = "../migrations")]
async fn un_second_reglement_est_refuse(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_mefali(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    livrer(&bac, &course).await;

    let creance = sqlx::query_scalar::<_, Uuid>(
        "SELECT id FROM coursier.creance WHERE coursier_id = $1 AND etat = 'due'",
    )
    .bind(bac.coursier)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    let corps_reglement = json!({ "motif_cle": "creance.reglement.virement_agence" });

    let (statut, _) = bac
        .post(
            &format!("/admin/creances/{creance}/regler"),
            &bac.jeton_admin,
            corps_reglement.clone(),
        )
        .await;
    assert_eq!(statut, 200);

    let (statut, corps) = bac
        .post(
            &format!("/admin/creances/{creance}/regler"),
            &bac.jeton_admin,
            corps_reglement,
        )
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "creance_deja_reglee");

    // Et surtout : AUCUNE seconde écriture au livre. C'est le point qui compte
    // — un `409` qui aurait quand même versé serait pire qu'un `200`.
    let nb: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM coursier.ecriture_caisse
          WHERE coursier_id = $1 AND type = 'reglement'",
    )
    .bind(bac.coursier)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(nb, 1, "le refus n'a rien versé");
    assert_eq!(bac.nb_evenements("caisse.creance_reglee").await, 1);
}

/// Le motif de règlement est **obligatoire** : « réglée » sans dire comment ne
/// répond pas à la première question posée quand un coursier conteste.
#[sqlx::test(migrations = "../migrations")]
async fn un_reglement_sans_motif_est_refuse(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_mefali(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    livrer(&bac, &course).await;

    let creance = sqlx::query_scalar::<_, Uuid>(
        "SELECT id FROM coursier.creance WHERE coursier_id = $1 AND etat = 'due'",
    )
    .bind(bac.coursier)
    .fetch_one(&bac.pool)
    .await
    .unwrap();

    let (statut, corps) = bac
        .post(
            &format!("/admin/creances/{creance}/regler"),
            &bac.jeton_admin,
            json!({ "motif_cle": "   " }),
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "motif_requis");
    assert_eq!(
        bac.du_par_mefali(bac.coursier).await,
        DEVIS_PART_COURSIER,
        "la créance reste due",
    );
}

/// La caisse du coursier porte ses créances et son total dû — c'est là que Yao
/// les voit (FR-094).
#[sqlx::test(migrations = "../migrations")]
async fn la_caisse_du_coursier_porte_ses_creances(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&course).await;
    livrer(&bac, &course).await;

    let caisse = bac.lire_caisse().await;
    let creances = caisse["creances"].as_array().expect("bloc créances");
    assert_eq!(creances.len(), 2);
    assert!(
        creances.iter().all(|c| c["etat"] == "due"),
        "aucune n'est réglée : personne ne les a versées",
    );

    let positions = &caisse["positions"];
    let du = positions["du_par_mefali_unites"].as_i64().unwrap();
    let somme: i64 = creances
        .iter()
        .map(|c| c["montant_unites"].as_i64().unwrap())
        .sum();
    assert_eq!(
        du, somme,
        "la position « Mefali me doit » EST la somme des créances dues — pas \
         un chiffre stocké à côté qui pourrait diverger",
    );
    assert_eq!(
        positions["detenu_pour_mefali_unites"], 0,
        "marge nulle au MVP",
    );
}

/// FR-083 — la file d'exploitation liste les créances avec leur total dû, et
/// refuse un filtre mal orthographié plutôt que de rendre `500`.
#[sqlx::test(migrations = "../migrations")]
async fn la_file_d_exploitation_liste_et_totalise(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&course).await;
    livrer(&bac, &course).await;

    let (statut, corps) = bac.get("/admin/creances?etat=due", &bac.jeton_admin).await;
    assert_eq!(statut, 200, "{corps}");
    let creances = corps["creances"].as_array().unwrap();
    assert_eq!(creances.len(), 2);
    let total: i64 = creances
        .iter()
        .map(|c| c["montant_unites"].as_i64().unwrap())
        .sum();
    assert_eq!(corps["total_du_unites"], total, "le total EST la somme");

    // Un filtre inconnu est une demande invalide, pas une panne.
    let (statut, corps) = bac
        .get("/admin/creances?etat=peut-etre", &bac.jeton_admin)
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "valeur_inconnue");

    // Un rôle non admin ne lit pas la file.
    let (statut, _) = bac.get("/admin/creances", &bac.jeton_coursier).await;
    assert_eq!(statut, 403);
}
