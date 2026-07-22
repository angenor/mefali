//! US4 — Suspendre un prestataire coupe tout, immédiatement (VND-01).
//!
//! SC-002 (fiche retirée, non commandable, jeton invalide, actions vendeur
//! refusées — sans AUCUNE action distincte), SC-003 (rétablissement à jeton
//! et code CONSTANTS), FR-056 (correction à double recalcul), FR-008 (zéro
//! cascade sur le rôle).

mod bac;

use bac::Bac;
use comptes::Comptes;
use prestataires::{ErreurPrestataires, SourceBascule, StatutPrestataire};
use sqlx::PgPool;
use uuid::Uuid;

async fn agree_avec_compte(bac: &Bac) -> (Uuid, Uuid) {
    let id = bac.prospect_complet("Boutique Kofi", "boutique_superette").await;
    bac.agreer(id).await;
    let kofi = bac.creer_compte("+2250700000002").await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .rattacher_compte(&mut tx, id, kofi, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    (id, kofi)
}

/// SC-002 + SC-003 — la suspension coupe tout PAR DÉRIVATION ; le
/// rétablissement rend tout, à l'identique.
#[sqlx::test(migrations = "../../migrations")]
async fn suspension_coupe_tout_retablissement_a_l_identique(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (id, kofi) = agree_avec_compte(&bac).await;
    let avant = bac.depot.prestataire(id).await.unwrap();
    let jeton = avant.jeton_plaque.clone().unwrap();
    let code = avant.code_secours.clone().unwrap();
    assert!(bac.depot.fiche_publique_de(id).await.unwrap().is_some());
    assert!(bac.depot.exiger_pilotage(kofi, id).await.is_ok());

    // Suspension SANS motif : refusée (FR-010).
    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .suspendre(&mut tx, id, "  ", bac.admin)
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurPrestataires::MotifRequis));
    drop(tx);

    // Suspension motivée : TOUT tombe, sans action distincte.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .suspendre(&mut tx, id, "trois incidents graves", bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert!(
        bac.depot.fiche_publique_de(id).await.unwrap().is_none(),
        "fiche non servie — MÊME réponse qu'un id inconnu (FR-017)"
    );
    assert!(!bac.depot.commandabilite(id).await.unwrap().commandable());
    let resolution = bac.depot.resolution_plaque(&jeton).await.unwrap().unwrap();
    assert!(!resolution.valide, "jeton invalide PAR DÉRIVATION (FR-015)");
    assert!(
        matches!(
            bac.depot.exiger_pilotage(kofi, id).await.unwrap_err(),
            ErreurPrestataires::PrestataireNonAgree(_)
        ),
        "action vendeur refusée tant que dure la suspension"
    );
    assert_eq!(
        bac.comptes.roles_valides(kofi).await.unwrap(),
        vec![comptes::Role::Vendeur],
        "le rôle du compte n'a PAS bougé — aucune cascade (FR-008)"
    );
    let suspension = &bac.evenements("prestataire.suspendu").await[0];
    assert_eq!(suspension["motif"], serde_json::json!("trois incidents graves"));
    assert_eq!(suspension["acteur"], serde_json::json!(bac.admin));

    // Rétablissement : tout revient, MÊME plaque (SC-003).
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot.retablir(&mut tx, id, bac.admin).await.unwrap();
    tx.commit().await.unwrap();

    let apres = bac.depot.prestataire(id).await.unwrap();
    assert_eq!(apres.statut, StatutPrestataire::Agree);
    assert_eq!(apres.jeton_plaque.as_deref(), Some(jeton.as_str()));
    assert_eq!(apres.code_secours.as_deref(), Some(code.as_str()));
    assert!(bac.depot.resolution_plaque(&jeton).await.unwrap().unwrap().valide);
    assert!(bac.depot.fiche_publique_de(id).await.unwrap().is_some());
    assert!(bac.depot.exiger_pilotage(kofi, id).await.is_ok());
    assert_eq!(bac.evenements("prestataire.retabli").await.len(), 1);

    // Transitions interdites (FR-004) : suspendre un prospect, rétablir un agréé.
    let prospect = bac.creer_fiche("Prospect", "restauration").await;
    let mut tx = bac.pool.begin().await.unwrap();
    assert!(matches!(
        bac.depot.suspendre(&mut tx, prospect, "motif", bac.admin).await.unwrap_err(),
        ErreurPrestataires::TransitionInvalide { .. }
    ));
    assert!(matches!(
        bac.depot.retablir(&mut tx, id, bac.admin).await.unwrap_err(),
        ErreurPrestataires::TransitionInvalide { .. }
    ));
}

/// Edge case spec — la suspension repasse la catégorie SOUS le seuil : elle
/// RESTE active (le seuil ne joue qu'à la hausse).
#[sqlx::test(migrations = "../../migrations")]
async fn suspension_ne_desactive_jamais_la_categorie(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (id, _) = agree_avec_compte(&bac).await;
    assert!(bac.categorie_active(bac.categorie_boutique).await);

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .suspendre(&mut tx, id, "incident", bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert!(
        bac.categorie_active(bac.categorie_boutique).await,
        "0 agréé < seuil 1, mais la règle ne joue qu'à la hausse"
    );
    assert_eq!(
        bac.evenements("categorie.activation_changee").await.len(),
        1,
        "un seul basculement : celui de l'agrément — la suspension n'en émet pas"
    );
}

/// FR-056 — corriger catégorie et ville recalcule les DEUX couples dans la
/// même transaction, sans toucher plaque ni statut.
#[sqlx::test(migrations = "../../migrations")]
async fn correction_recalcule_les_deux_couples(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (id, _) = agree_avec_compte(&bac).await; // boutique_superette, activée
    let jeton = bac.depot.prestataire(id).await.unwrap().jeton_plaque.unwrap();

    // Correction vers restauration (seuil 2 — non atteint par ce seul agréé).
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .corriger(&mut tx, id, Some("restauration"), None, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let p = bac.depot.prestataire(id).await.unwrap();
    assert_eq!(p.categorie_slug, "restauration");
    assert_eq!(p.statut, StatutPrestataire::Agree, "ni suspension ni ré-agrément");
    assert_eq!(p.jeton_plaque.as_deref(), Some(jeton.as_str()), "plaque intacte");
    assert!(
        bac.categorie_active(bac.categorie_boutique).await,
        "l'ANCIENNE catégorie reste active — seuil à la hausse seulement"
    );
    assert!(
        !bac.categorie_active(bac.categorie_restauration).await,
        "1 agréé < seuil 2 : la nouvelle n'est pas activée"
    );
    let correction = &bac.evenements("prestataire.corrige").await[0];
    assert_eq!(correction["avant"]["categorie"], serde_json::json!("boutique_superette"));
    assert_eq!(correction["apres"]["categorie"], serde_json::json!("restauration"));

    // La fiche n'est plus servie (restauration inactive) mais reste
    // administrable — et re-corriger la ramène.
    assert!(bac.depot.fiche_publique_de(id).await.unwrap().is_none());

    // Correction vers une zone qui n'est pas une ville : refusée (FR-002).
    let mut tx = bac.pool.begin().await.unwrap();
    assert!(matches!(
        bac.depot
            .corriger(&mut tx, id, None, Some(bac.pays), bac.admin)
            .await
            .unwrap_err(),
        ErreurPrestataires::ZoneNonVille(_)
    ));
    drop(tx);

    // Sans changement : aucun événement de plus.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .corriger(&mut tx, id, Some("restauration"), None, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(bac.evenements("prestataire.corrige").await.len(), 1);

    // La bascule de disponibilité d'un article d'un SUSPENDU est aussi coupée
    // côté garde vendeur — vérifié par exiger_pilotage plus haut ; côté admin
    // elle reste possible (fiche administrable — edge case spec).
    let _ = SourceBascule::Admin;
}
