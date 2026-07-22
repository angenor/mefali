//! Fumée de la composition racine (T007) : le bac se monte, la ligne de
//! RÉFÉRENCE du plan « gratuit » existe (migration 0004, provision VND-07) et
//! la configuration du cycle se résout par héritage.

mod bac;

use bac::Bac;
use sqlx::PgPool;

#[sqlx::test(migrations = "../../migrations")]
async fn composition_et_plan_de_reference(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // Provision VND-07 : le plan « gratuit » est posé PAR LA MIGRATION (FK
    // NOT NULL de prestataire.plan_id) — présent même sans seed.
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.plan WHERE code = 'gratuit'")
            .await,
        1
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.plan_caracteristique")
            .await,
        0,
        "aucune caractéristique : tables seulement (FR-048)"
    );

    // Les clés du cycle se résolvent par héritage depuis la ville.
    let seuil = bac
        .depot
        .zones()
        .parametre(bac.ville, "rupture.masquage_seuil")
        .await
        .unwrap();
    assert_eq!(seuil, Some(serde_json::json!(2)));
    let affichage = bac
        .depot
        .zones()
        .parametre(bac.ville, "categorie.restauration.affichage_rupture")
        .await
        .unwrap();
    assert_eq!(affichage, Some(serde_json::json!("grise")), "hérité du pays");
}
