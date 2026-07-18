//! US1 — Agréer un prestataire et lui donner son identité de plaque (VND-01).
//!
//! Chaque transition vérifie SON événement (SC-009) et la minimisation de son
//! payload (SC-011) ; la neutralité de la consultation et l'absence de
//! contact/GPS sont prouvées au niveau du TYPE servi (SC-013).

mod bac;

use bac::Bac;
use comptes::Comptes;
use prestataires::ErreurPrestataires;
use sqlx::PgPool;

/// FR-005 — l'agrément est refusé tant que la fiche est incomplète, avec des
/// manques EXPLICITES, et le statut reste prospect (US1 scénario 3).
#[sqlx::test(migrations = "../../migrations")]
async fn agrement_incomplet_refuse_avec_manques(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = bac.creer_fiche("Étal Tantie Affoué", "restauration").await;

    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac.depot.agreer(&mut tx, id, bac.admin).await.unwrap_err();
    drop(tx);
    let ErreurPrestataires::AgrementIncomplet { manques } = erreur else {
        panic!("attendu AgrementIncomplet, obtenu {erreur:?}");
    };
    assert_eq!(
        manques,
        vec!["photo", "charte_signee", "site"],
        "tous les manques sont remontés d'un coup"
    );

    let p = bac.depot.prestataire(id).await.unwrap();
    assert_eq!(p.statut.comme_str(), "prospect", "le statut n'a pas bougé");
    assert!(p.jeton_plaque.is_none(), "aucune plaque sans agrément");
    assert_eq!(
        bac.evenements("prestataire.agree").await.len(),
        0,
        "un refus n'émet AUCUN événement d'agrément"
    );
}

/// SC-001 — agrément complet SANS AUCUN compte rattaché : consultable et
/// commandable immédiatement, plaque résolue (US1, cas nominal Tantie Affoué).
#[sqlx::test(migrations = "../../migrations")]
async fn agrement_complet_sans_compte(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    // boutique_superette : seuil 1 — un seul agrément active la catégorie.
    let id = bac.prospect_complet("Boutique Kofi", "boutique_superette").await;
    let p = bac.agreer(id).await;

    // Plaque : jeton 80 hex + code 4 chiffres, posés à CET agrément (FR-013).
    let jeton = p.jeton_plaque.expect("jeton posé à l'agrément");
    let code = p.code_secours.expect("code posé à l'agrément");
    assert_eq!(jeton.len(), 80);
    assert!(code.len() == 4 && code.chars().all(|c| c.is_ascii_digit()));

    // Résolution : valide (FR-016) ; jeton forgé : inconnu.
    let resolution = bac.depot.resolution_plaque(&jeton).await.unwrap().unwrap();
    assert_eq!(resolution.prestataire_id, id);
    assert!(resolution.valide);
    assert!(bac.depot.resolution_plaque("f0".repeat(40).as_str()).await.unwrap().is_none());

    // Commandable (FR-028) : agréé ∧ catégorie activée (seuil 1 franchi —
    // SC-010) ∧ boutique ouverte (statut initial + horaires... si le test
    // tourne un dimanche ou hors 8 h — 19 h Abidjan, l'état effectif est
    // fermé : on vérifie la décomposition, pas l'instant).
    let c = bac.depot.commandabilite(id).await.unwrap();
    assert!(c.agree);
    assert!(c.categorie_active, "seuil 1 franchi par CET agrément (SC-010)");
    assert!(bac.categorie_active(bac.categorie_boutique).await);

    // Fiche publique SERVIE (catalogue encore vide), sans compte rattaché.
    let fiche = bac.depot.fiche_publique_de(id).await.unwrap().expect("servie");
    assert_eq!(fiche.nom, "Boutique Kofi");
    assert!(fiche.articles.is_empty());
    assert_eq!(fiche.photos.len(), 1);

    // SC-013 structurel : le JSON public ne porte NI contact NI coordonnées.
    let json = serde_json::to_string(&fiche).unwrap();
    assert!(!json.contains("contact"), "aucun contact téléphonique");
    assert!(!json.contains("position_"), "aucune coordonnée de site");
    assert!(!json.contains("jeton"), "aucune donnée d'exploitation");

    // SC-009/SC-011 — l'événement d'agrément, minimisé (pas de nom).
    let agrements = bac.evenements("prestataire.agree").await;
    assert_eq!(agrements.len(), 1);
    assert_eq!(agrements[0]["plaque_creee"], serde_json::json!(true));
    assert_eq!(agrements[0]["acteur"], serde_json::json!(bac.admin));
    assert!(agrements[0].get("nom").is_none(), "payload sans nom (FR-052)");
}

/// SC-010 / edge case spec — sous le seuil, la fiche n'est NI servie NI
/// commandable ; le franchissement active la catégorie dans la même opération.
#[sqlx::test(migrations = "../../migrations")]
async fn franchissement_du_seuil_active_la_categorie(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    // restauration : seuil 2 (bac).
    let premier = bac.prospect_complet("Maquis 1", "restauration").await;
    bac.agreer(premier).await;

    assert!(
        !bac.categorie_active(bac.categorie_restauration).await,
        "1 agréé < seuil 2 : catégorie inactive"
    );
    let c = bac.depot.commandabilite(premier).await.unwrap();
    assert!(c.agree && !c.categorie_active && !c.commandable());
    assert!(
        bac.depot.fiche_publique_de(premier).await.unwrap().is_none(),
        "catégorie inactive → fiche NON servie (edge case spec)"
    );

    let second = bac.prospect_complet("Maquis 2", "restauration").await;
    bac.agreer(second).await;
    assert!(
        bac.categorie_active(bac.categorie_restauration).await,
        "2 agréés = seuil : activation sans action manuelle (SC-010)"
    );
    assert!(bac.depot.fiche_publique_de(premier).await.unwrap().is_some());
    let activations = bac.evenements("categorie.activation_changee").await;
    assert_eq!(activations.len(), 1, "émis au SEUL franchissement");
    assert_eq!(activations[0]["origine"], serde_json::json!("seuil"));
    assert_eq!(activations[0]["nb_vendeurs"], serde_json::json!(2));
}

/// FR-002 / analyse G1 — une zone qui n'est pas une ville est refusée.
#[sqlx::test(migrations = "../../migrations")]
async fn creation_sur_zone_non_ville_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .creer_prestataire(
            &mut tx,
            &prestataires::NouveauPrestataire {
                nom: "Hors ville".to_owned(),
                categorie_slug: "restauration".to_owned(),
                ville_id: bac.pays, // un PAYS, pas une ville
                contact_telephone: "+2250700000010".to_owned(),
                delai_preparation_min: 10,
            },
            bac.admin,
        )
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurPrestataires::ZoneNonVille(_)));
}

/// FR-007 (analyse A1) + FR-008 + US1 scénario 6 — rattachement : rôle vendeur
/// attribué et idempotent, refusé hors agrément, détachement sans cascade.
#[sqlx::test(migrations = "../../migrations")]
async fn rattachement_attribue_le_role_et_reste_idempotent(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let kofi = bac.creer_compte("+2250700000002").await;

    // A1 — rattacher un PROSPECT est refusé, aucun rôle attribué.
    let prospect = bac.creer_fiche("Prospect", "boutique_superette").await;
    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .rattacher_compte(&mut tx, prospect, kofi, bac.admin)
        .await
        .unwrap_err();
    drop(tx);
    assert!(matches!(erreur, ErreurPrestataires::PrestataireNonAgree(_)));
    assert!(bac.comptes.roles_valides(kofi).await.unwrap().is_empty());

    // Agréé : le rattachement attribue le rôle vendeur — l'agrément VAUT
    // validation, aucune demande in-app (US1 scénario 6).
    let boutique = bac.prospect_complet("Boutique Kofi", "boutique_superette").await;
    bac.agreer(boutique).await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .rattacher_compte(&mut tx, boutique, kofi, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(
        bac.comptes.roles_valides(kofi).await.unwrap(),
        vec![comptes::Role::Vendeur]
    );
    let crees = bac.evenements("rattachement.cree").await;
    assert_eq!(crees.len(), 1);
    assert_eq!(crees[0]["role_attribue"], serde_json::json!(true));
    assert!(bac.depot.exiger_pilotage(kofi, boutique).await.is_ok());

    // REJEU : rien n'échoue, rien n'est rejoué (FR-007).
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .rattacher_compte(&mut tx, boutique, kofi, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(bac.evenements("rattachement.cree").await.len(), 1);
    assert_eq!(bac.evenements("role.attribue").await.len(), 1);

    // Second prestataire, MÊME compte : rattaché sans rejouer l'attribution.
    let second = bac.prospect_complet("Boutique 2", "boutique_superette").await;
    bac.agreer(second).await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .rattacher_compte(&mut tx, second, kofi, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    let crees = bac.evenements("rattachement.cree").await;
    assert_eq!(crees.len(), 2);
    assert_eq!(crees[1]["role_attribue"], serde_json::json!(false));
    assert_eq!(
        bac.depot.pilotables(kofi).await.unwrap(),
        vec![boutique, second],
        "plus ancien rattachement d'abord"
    );

    // Détachement : le rôle du compte NE BOUGE PAS (FR-008, aucune cascade).
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .detacher_compte(&mut tx, second, kofi, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(
        bac.comptes.roles_valides(kofi).await.unwrap(),
        vec![comptes::Role::Vendeur],
        "le rôle survit au détachement"
    );
    // …mais le rôle seul n'autorise RIEN sur ce prestataire (edge case spec).
    assert!(matches!(
        bac.depot.exiger_pilotage(kofi, second).await.unwrap_err(),
        ErreurPrestataires::NonRattache { .. }
    ));
}

/// FR-052 — la modification de fiche n'émet que des NOMS de champs.
#[sqlx::test(migrations = "../../migrations")]
async fn modification_emet_les_noms_de_champs_seulement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = bac.creer_fiche("Avant", "restauration").await;

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_prestataire(
            &mut tx,
            id,
            &prestataires::ModificationPrestataire {
                nom: Some("Après".to_owned()),
                contact_telephone: None,
                delai_preparation_min: Some(25),
            },
            bac.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let modifications = bac.evenements("prestataire.modifie").await;
    assert_eq!(modifications.len(), 1);
    assert_eq!(
        modifications[0]["champs"],
        serde_json::json!(["nom", "delai_preparation"])
    );
    assert!(
        !modifications[0].to_string().contains("Après"),
        "les VALEURS ne partent jamais dans le payload (FR-052)"
    );
}
