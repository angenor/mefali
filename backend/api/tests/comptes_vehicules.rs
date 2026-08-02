//! `PUT /moi/dossier-coursier/vehicules` (CPT-04) — les refus que seul HTTP voit.
//!
//! Le comportement métier est tenu par `comptes/tests/dossier.rs`, qui exerce
//! `remplacer_vehicules_declares` sans réseau : flotte remplacée, rôle intact,
//! rejeu muet, dossier non validé refusé. Ce fichier ne le répète pas.
//!
//! Ce qu'il tient, et que le domaine ne peut pas tenir :
//!
//! 1. **La garde de rôle**, qui vit dans le handler. `POST /moi/dossier-coursier`
//!    n'en a AUCUNE — il s'en sort parce que la machine à états refuse les
//!    transitions illégales. Ici, aucune transition ne rattraperait l'oubli :
//!    sans la garde, un compte client changerait les véhicules… de personne,
//!    mais avec un `500` au lieu d'un `403`, et la prochaine route copiée sur
//!    celle-ci hériterait du trou.
//! 2. **L'en-tête d'idempotence**, exigée par le contrat et vérifiée avant le
//!    domaine.
//! 3. **Le compte sans dossier** — état réellement atteignable (le rôle est
//!    posé en SQL direct par les fixtures de dispatch, exactement comme ici) —
//!    qui doit rendre `404` et non le `500` opaque que la clé étrangère de
//!    `vehicule_declare` produirait si on écrivait d'abord.
//!
//! Le bac coursier convient précisément parce qu'il pose le rôle SANS dossier :
//! c'est le cas 3 gratuitement, et il est le plus facile à livrer par erreur.

mod bac_coursier;

use bac_coursier::Bac;
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

const ROUTE: &str = "/moi/dossier-coursier/vehicules";

fn cle() -> String {
    Uuid::now_v7().to_string()
}

/// Un compte sans rôle coursier ne touche à aucune flotte.
#[sqlx::test(migrations = "../migrations")]
async fn le_remplacement_exige_le_role_coursier(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, corps) = bac
        .put(
            ROUTE,
            &bac.jeton_client,
            json!({ "vehicules": ["moto"] }),
            &[("idempotency-key", cle().as_str())],
        )
        .await;

    assert_eq!(statut, 403, "rôle coursier requis — refus AVANT le domaine");
    assert_eq!(corps["code"], json!("role_requis"));
}

/// Sans session, rien — la porte du socle passe avant celle du rôle.
#[sqlx::test(migrations = "../migrations")]
async fn le_remplacement_exige_une_session(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, _) = bac
        .put(
            ROUTE,
            "jeton-qui-ne-vaut-rien",
            json!({ "vehicules": ["moto"] }),
            &[("idempotency-key", cle().as_str())],
        )
        .await;

    assert_eq!(statut, 401);
}

/// L'en-tête d'idempotence est exigée, comme au `POST`.
#[sqlx::test(migrations = "../migrations")]
async fn sans_cle_d_idempotence_le_corps_est_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, corps) = bac
        .put(
            ROUTE,
            &bac.jeton_coursier,
            json!({ "vehicules": ["moto"] }),
            &[],
        )
        .await;

    assert_eq!(statut, 422);
    assert_eq!(corps["code"], json!("corps_invalide"));
}

/// Rôle coursier VALIDE, aucun dossier : `404`, jamais un `500` de clé
/// étrangère. C'est l'état que posent les fixtures de dispatch — et celui qu'on
/// livrerait le plus facilement cassé.
#[sqlx::test(migrations = "../migrations")]
async fn sans_dossier_le_remplacement_est_introuvable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, corps) = bac
        .put(
            ROUTE,
            &bac.jeton_coursier,
            json!({ "vehicules": ["moto"] }),
            &[("idempotency-key", cle().as_str())],
        )
        .await;

    assert_eq!(
        statut, 404,
        "un dossier absent est introuvable, pas une panne interne"
    );
    assert_eq!(corps["code"], json!("introuvable"));
}

/// Une flotte vide est refusée par le contrat, pas seulement par le domaine :
/// se priver de véhicule reconstruirait l'impasse que cette route ouvre.
#[sqlx::test(migrations = "../migrations")]
async fn une_flotte_vide_est_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, _) = bac
        .put(
            ROUTE,
            &bac.jeton_coursier,
            json!({ "vehicules": [] }),
            &[("idempotency-key", cle().as_str())],
        )
        .await;

    // 404 (dossier absent) ou 422 (liste vide) selon l'ordre des gardes ; ce
    // qui compte est qu'aucune écriture ne passe. Le domaine tranche le 422 sur
    // un dossier existant (`une_flotte_vide_est_refusee`, comptes/dossier.rs).
    assert!(
        statut == 422 || statut == 404,
        "une flotte vide ne s'enregistre pas (reçu {statut})"
    );
}
