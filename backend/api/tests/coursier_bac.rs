//! Le bac d'essai du cycle CRS se tient debout — cycle 010, T006.
//!
//! Ce fichier ne teste aucune règle métier : il teste le **bac lui-même**. Un
//! bac qui monte à moitié fait échouer les tests des tâches suivantes pour de
//! mauvaises raisons, et on cherche le défaut dans le domaine pendant des
//! heures. Trois choses seulement, mais celles dont tout le reste dépend : les
//! paramètres se résolvent, la course type existe avec ses trois arrêts, et les
//! deux coursiers sont bien deux comptes distincts au rôle valide.

mod bac_coursier;

use bac_coursier::Bac;
use coursier::{cles_config, ConfigCoursier};
use sqlx::PgPool;
use zones::PgZones;

/// Les 7 paramètres du cycle **et** le seuil d'essais du cycle 008 se résolvent
/// par héritage pays → ville, et la configuration passe ses gardes.
#[sqlx::test(migrations = "../migrations")]
async fn les_parametres_du_cycle_se_resolvent(pool: PgPool) {
    let bac = Bac::nouveau(pool.clone()).await;
    let zones = PgZones::new(pool);

    let config = ConfigCoursier::charger(&zones, bac.ville)
        .await
        .expect("les 7 paramètres du cycle sont seedés par le bac");

    assert_eq!(config.devise, "XOF");
    assert_eq!(config.preuve_appels_min, bac_coursier::PREUVE_APPELS_MIN);
    assert_eq!(config.preuve_presence_s, bac_coursier::PREUVE_PRESENCE_S);
    assert_eq!(
        config.preuve_presence_trou_max_s,
        bac_coursier::PREUVE_PRESENCE_TROU_MAX_S
    );
    // Le seuil d'essais vient du cycle 008 et n'est PAS redéclaré (R5, FR-106).
    assert_eq!(
        config.essais_code_livraison,
        bac_coursier::ESSAIS_CODE_LIVRAISON,
    );
    assert!(!cles_config::TOUTES.contains(&cles_config::ESSAIS_CODE_LIVRAISON));
}

/// La course type : trois collectes ordonnées, un arrêt de remise, une
/// livraison assignée au coursier du bac. Et ses secrets sont lisibles en base
/// — sans quoi aucun test de remise ne pourrait confirmer quoi que ce soit.
#[sqlx::test(migrations = "../migrations")]
async fn la_course_type_a_trois_arrets_et_ses_secrets(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    assert_eq!(course.collectes.len(), 3, "un arrêt par vendeur");
    assert_ne!(course.remise, course.collectes[0]);
    assert_eq!(bac.etat_livraison(course.livraison).await, "assignee");
    assert_eq!(bac.etat_commande(course.commande).await, "en_cours");

    let secrets = bac.secrets_remise(course.commande).await;
    assert_eq!(secrets.code.len(), 4, "code à 4 chiffres du client");
    assert!(!secrets.jeton.is_empty());
}

/// Les deux coursiers sont bien DEUX comptes. C'est la précondition de toutes
/// les gardes de propriété du cycle : prouver un refus avec un compte sans rôle
/// prouverait le refus de RÔLE, qui est un autre chemin.
#[sqlx::test(migrations = "../migrations")]
async fn le_bac_porte_deux_coursiers_distincts(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    assert_ne!(bac.coursier, bac.autre_coursier);
    assert_ne!(bac.jeton_coursier, bac.jeton_autre_coursier);

    let roles: Vec<String> = sqlx::query_scalar(
        "SELECT role::text FROM comptes.attribution_role
          WHERE compte_id = $1 AND statut = 'valide' ORDER BY role::text",
    )
    .bind(bac.autre_coursier)
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert!(roles.iter().any(|r| r == "coursier"));
}
