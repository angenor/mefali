//! VND-08 minimal (cycle 011, PAY T052) — l'offre de livraison déclarée par un
//! vendeur, lue telle que `tarification` la consomme (research R10).
//!
//! Les trois valeurs de l'énumération, plus le fait qu'un défaut de migration
//! ne change RIEN pour les vendeurs existants (FR-046) : une fiche jamais
//! touchée rend `None`.
//!
//! ⚠ Le test écrit l'offre en SQL direct : le geste métier (endpoint et
//! événement) est la tâche T053 — ici on mesure la LECTURE, seule.

mod bac;

use bac::Bac;
use sqlx::PgPool;
use tarification::OffreLivraison;
use uuid::Uuid;

/// Pose l'offre en SQL direct (le setter métier arrive en T053).
async fn poser(bac: &Bac, prestataire: Uuid, offre: &str, seuil: Option<i64>) {
    sqlx::query(
        "UPDATE prestataires.prestataire
         SET offre_livraison = $2::prestataires.offre_livraison,
             offre_livraison_seuil_unites = $3
         WHERE id = $1",
    )
    .bind(prestataire)
    .bind(offre)
    .bind(seuil)
    .execute(&bac.pool)
    .await
    .unwrap();
}

/// FR-046 — le défaut de migration est `jamais`, et `jamais` ne se distingue
/// pas de « le vendeur n'a jamais rien déclaré » : les deux rendent `None`.
#[sqlx::test(migrations = "../../migrations")]
async fn defaut_de_migration_ne_change_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = bac.creer_fiche("Chez Affoué", "restauration").await;

    assert_eq!(bac.depot.offre_livraison(vendeur).await.unwrap(), None);
}

/// `toujours` — l'offre joue quel que soit le panier.
#[sqlx::test(migrations = "../../migrations")]
async fn toujours_traverse_tel_quel(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = bac.creer_fiche("Chez Affoué", "restauration").await;
    poser(&bac, vendeur, "toujours", None).await;

    let offre = bac.depot.offre_livraison(vendeur).await.unwrap();

    assert_eq!(offre, Some(OffreLivraison::Toujours));
    // Le type traverse tel quel : c'est `tarification` qui décide si l'offre
    // joue, pas ce crate.
    assert!(offre.unwrap().joue(0));
}

/// `au_dela` — le seuil déclaré est celui que le moteur tarifaire compare.
#[sqlx::test(migrations = "../../migrations")]
async fn au_dela_porte_son_seuil(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = bac.creer_fiche("Chez Affoué", "restauration").await;
    poser(&bac, vendeur, "au_dela", Some(5_000)).await;

    let offre = bac.depot.offre_livraison(vendeur).await.unwrap();

    assert_eq!(offre, Some(OffreLivraison::AuDela(5_000)));
    assert!(!offre.unwrap().joue(4_999));
    assert!(offre.unwrap().joue(5_000));
}

/// La base REFUSE `au_dela` sans seuil (`offre_livraison_seuil_coherent`) : la
/// lecture n'a donc pas à inventer de défaut. C'est le `CHECK` qui rend le cas
/// impossible, pas une convention de code.
#[sqlx::test(migrations = "../../migrations")]
async fn au_dela_sans_seuil_est_refuse_par_la_base(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = bac.creer_fiche("Chez Affoué", "restauration").await;

    let echec = sqlx::query(
        "UPDATE prestataires.prestataire
         SET offre_livraison = 'au_dela', offre_livraison_seuil_unites = NULL
         WHERE id = $1",
    )
    .bind(vendeur)
    .execute(&bac.pool)
    .await;

    assert!(echec.is_err(), "le CHECK doit refuser un seuil manquant");
}

/// Un identifiant inconnu n'est pas « pas d'offre » : c'est une erreur.
#[sqlx::test(migrations = "../../migrations")]
async fn prestataire_inconnu_est_une_erreur(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    let echec = bac.depot.offre_livraison(Uuid::now_v7()).await;

    assert!(matches!(
        echec,
        Err(prestataires::ErreurPrestataires::PrestataireInconnu(_))
    ));
}
