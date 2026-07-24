//! US5 (TRF-04) — intégrité monétaire par zone (SC-011, FR-023/FR-024/FR-025).
//!
//! Trois promesses, vérifiables une par une : tout montant est un **entier en
//! unités mineures** assorti du **code ISO 4217 de la zone** ; une règle en
//! devise étrangère est **refusée** ; une opération qui mêlerait deux devises
//! est **rejetée, jamais convertie** — le MVP n'a aucune logique de change.

mod bac;

use std::sync::Arc;

use bac::{Bac, RoutageFixe};
use sqlx::PgPool;
use tarification::{
    regle::{verifier_devises_homogenes, Criteres},
    CacheMemoire, EvaluationTarifaire, RegleUpsert, SourceGrille,
};
use uuid::Uuid;

fn upsert_moto(devise: &str) -> RegleUpsert {
    RegleUpsert {
        transport_slug: "moto".to_owned(),
        categorie_slug: None,
        distance_min_m: 0,
        distance_max_m: None,
        plage_debut_min: None,
        plage_fin_min: None,
        jours_masque: None,
        part_coursier_base: 150,
        marge: 50,
        prix_par_km: 50,
        seuil_km_m: 2_000,
        prix_plafond: Some(500),
        devise: devise.to_owned(),
        priorite: 0,
        actif: true,
    }
}

/// SC-011 (1) — la devise vient de la ZONE, les montants sont des entiers en
/// unités mineures, et XOF n'a AUCUNE décimale.
#[sqlx::test(migrations = "../../migrations")]
async fn montants_entiers_en_devise_de_zone(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );

    let devise = moteur.devise(bac.ville).await.unwrap();
    assert_eq!(devise.code, "XOF");
    assert_eq!(devise.decimales, 0, "XOF est sans décimale (FR-023)");

    let devis = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.devise, devise.code, "le devis hérite de la zone");
    // Le typage EST la garantie : i64 partout, aucun flottant ne peut porter un
    // montant (constitution III). On vérifie ici que la somme se reconstitue
    // exactement — un centime perdu signalerait un calcul flottant caché.
    let c = devis.composantes;
    assert_eq!(c.base + c.km + c.supplements + c.arrondi, devis.prix_client);
    assert_eq!(devis.prix_client, devis.part_coursier + devis.marge);
}

/// SC-011 (2) — une règle en devise étrangère n'entre jamais en base.
#[sqlx::test(migrations = "../../migrations")]
async fn regle_en_devise_etrangere_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur_degrade();

    let mut tx = bac.pool.begin().await.unwrap();
    let brouillon = moteur
        .obtenir_ou_creer_brouillon(&mut tx, bac.ville)
        .await
        .unwrap();
    let erreur = moteur
        .ecrire_regle(&mut tx, brouillon.id, Uuid::now_v7(), &upsert_moto("EUR"))
        .await
        .unwrap_err();
    assert_eq!(erreur.message_cle(), Some("devise_incoherente"));
    // La règle XOF, elle, passe : c'est bien la DEVISE qui est refusée.
    moteur
        .ecrire_regle(&mut tx, brouillon.id, Uuid::now_v7(), &upsert_moto("XOF"))
        .await
        .expect("la devise de la zone est acceptée");
    tx.commit().await.unwrap();
}

/// SC-011 (3) — une opération qui MÊLERAIT deux devises est rejetée, jamais
/// convertie, même si la règle est arrivée en base par une autre porte (devise
/// de zone éditée après coup).
#[sqlx::test(migrations = "../../migrations")]
async fn melange_de_devises_rejete_jamais_converti(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // On force une règle EUR dans la grille en vigueur, comme si la zone était
    // passée de EUR à XOF après coup. Aucune conversion ne doit s'inventer.
    sqlx::query("UPDATE tarification.regle SET devise = 'EUR' WHERE transport_slug = 'moto'")
        .execute(&bac.pool)
        .await
        .unwrap();

    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[4_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let erreur = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap_err();
    assert_eq!(
        erreur.message_cle(),
        Some("devise_incoherente"),
        "rejet explicite — surtout pas un montant converti"
    );

    // La garde de catalogue voit le mélange avant même d'évaluer.
    let grille = moteur.grille(bac.grille).await.unwrap();
    assert!(verifier_devises_homogenes(&grille.regles, "XOF").is_err());

    // Les autres véhicules, restés en XOF, tarifent normalement : le refus est
    // ciblé sur la règle fautive, il ne casse pas toute la zone.
    let moteur_velo = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[1_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let devis = moteur_velo
        .evaluer(bac.demande("velo", 1), SourceGrille::EnVigueur)
        .await
        .unwrap();
    assert_eq!(devis.devise, "XOF");
    assert_eq!(devis.prix_client, 150);
}

/// Sans devise résolue dans la chaîne d'héritage, on REFUSE de tarifer plutôt
/// que de supposer XOF : le modèle doit rester portable hors zone CFA (FR-025).
#[sqlx::test(migrations = "../../migrations")]
async fn zone_sans_devise_refuse_de_tarifer(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    sqlx::query("DELETE FROM zones.parametre_zone WHERE cle LIKE 'devise.%'")
        .execute(&bac.pool)
        .await
        .unwrap();

    let moteur = bac.moteur(
        Arc::new(RoutageFixe::depuis_positions(&[1_000, 0])),
        Arc::new(CacheMemoire::nouveau()),
    );
    let erreur = moteur
        .evaluer(bac.demande("moto", 1), SourceGrille::EnVigueur)
        .await
        .unwrap_err();
    assert!(
        erreur.to_string().contains("devise"),
        "l'absence de devise doit se dire, obtenu : {erreur}"
    );
}

/// La devise ne joue AUCUN rôle dans la sélection de règle : elle est une
/// propriété de la zone, pas un critère d'appariement.
#[sqlx::test(migrations = "../../migrations")]
async fn devise_n_est_pas_un_critere_de_selection(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let moteur = bac.moteur_degrade();
    let grille = moteur.grille(bac.grille).await.unwrap();

    let choisie = tarification::regle::selectionner(
        &grille.regles,
        &Criteres {
            transport_slug: "moto",
            categorie_slug: None,
            distance_m: 3_000,
            instant: bac::instant("2026-07-22T19:30:00Z"),
            fuseau: chrono_tz::Africa::Abidjan,
        },
    )
    .expect("une règle moto");
    assert_eq!(choisie.devise, "XOF");
}
