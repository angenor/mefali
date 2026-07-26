//! US1 (CMD-01) — devis de panier multi-vendeurs : regroupement, sous-totaux,
//! règle de mixage, proposition de scission, et **absence totale d'effet de
//! bord** sur le chemin nominal (point obligatoire P4).

mod bac_commandes;

use actix_web::{test as atest, App};
use bac_commandes::{Bac, DEVIS_PRIX_CLIENT};
use serde_json::Value;

/// `POST /paniers/devis` avec le jeton fourni.
async fn devis(bac: &Bac, jeton: &str, corps: Value) -> (u16, Value) {
    let app = atest::init_service(App::new().configure(bac.configurer())).await;
    let req = atest::TestRequest::post()
        .uri("/paniers/devis")
        .insert_header(("authorization", format!("Bearer {jeton}")))
        .set_json(corps)
        .to_request();
    let resp = atest::call_service(&app, req).await;
    let statut = resp.status().as_u16();
    (statut, atest::read_body_json(resp).await)
}

/// 12 articles chez 3 vendeurs : regroupement, sous-totaux, récapitulatif, et
/// préférence par défaut « m'appeler » (SC-001, maquette C3-3a).
#[sqlx::test(migrations = "../migrations")]
async fn regroupement_sous_totaux_et_preference_par_defaut(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // 4 articles chez chacun des 3 vendeurs = 12 articles.
    let lignes: Vec<Value> = bac
        .vendeurs
        .iter()
        .flat_map(|v| [v.ligne_de(0, 2), v.ligne_de(1, 2)])
        .collect();

    let (statut, corps) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", lignes),
    )
    .await;
    assert_eq!(statut, 200);

    let groupes = corps["groupes"].as_array().unwrap();
    assert_eq!(groupes.len(), 3, "un groupe par vendeur (C3-3a)");

    // Les groupes suivent l'ordre de COMPOSITION du client, pas un tri serveur.
    for (i, v) in bac.vendeurs.iter().enumerate() {
        assert_eq!(groupes[i]["prestataire_id"], v.id.to_string());
        assert_eq!(groupes[i]["nom"], v.nom);
        assert_eq!(groupes[i]["nb_articles"], 4);
        // Sous-total = prix₀×2 + prix₁×2, en ENTIERS d'unités mineures (III).
        let attendu = v.prix[0] * 2 + v.prix[1] * 2;
        assert_eq!(groupes[i]["sous_total_unites"], attendu);
        for ligne in groupes[i]["lignes"].as_array().unwrap() {
            assert_eq!(
                ligne["preference"], "appeler",
                "défaut produit : « m'appeler » (CMD-01)",
            );
        }
    }

    let montant_articles: i64 = bac
        .vendeurs
        .iter()
        .map(|v| v.prix[0] * 2 + v.prix[1] * 2)
        .sum();
    assert_eq!(corps["montant_articles_unites"], montant_articles);
    assert_eq!(
        corps["total_unites"],
        montant_articles + DEVIS_PRIX_CLIENT,
        "total = articles + prix client du devis",
    );
    assert_eq!(corps["devise"], "XOF");
    // Le récapitulatif « Articles / Livraison / Effort » a de quoi s'afficher.
    assert!(corps["devis"]["composantes"].is_object());
    assert_eq!(corps["devis"]["prix_client_unites"], DEVIS_PRIX_CLIENT);
    assert!(corps["scission"].is_null(), "rien à proposer ici");
}

/// **P4** — le chemin nominal du devis n'écrit RIEN : aucune commande, aucune
/// ligne, aucun événement outbox. C'est ce qui rend le panier gratuit à
/// recalculer autant de fois que le client modifie son contenu.
#[sqlx::test(migrations = "../migrations")]
async fn devis_nominal_sans_aucun_effet_de_bord(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let evenements_avant = bac.total_evenements().await;

    let lignes = vec![bac.vendeurs[0].ligne(2), bac.vendeurs[1].ligne(1)];
    let (statut, _) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", lignes),
    )
    .await;
    assert_eq!(statut, 200);

    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        0,
        "aucune commande créée par un devis",
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.ligne_commande")
            .await,
        0,
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.livraison").await,
        0,
    );
    assert_eq!(
        bac.total_evenements().await,
        evenements_avant,
        "P4 : le devis nominal n'émet AUCUN événement outbox",
    );
}

/// Restauration mêlée à plusieurs vendeurs → refus de mixage et proposition de
/// scission CHIFFRÉE (FR-009/FR-010, maquette C3-3d). Aucune commande créée.
#[sqlx::test(migrations = "../migrations")]
async fn categorie_non_mixable_propose_une_scission_chiffree(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Deux « vendeurs » dans une catégorie NON mixable : le maquis + un étal.
    // La catégorie soumise est `restauration`, non mixable dans la zone.
    let lignes = vec![bac.resto.ligne(1), bac.vendeurs[0].ligne(2)];

    let (statut, corps) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("restauration", lignes),
    )
    .await;
    assert_eq!(statut, 200, "le devis RÉPOND — c'est la création qui refuse");

    let scission = &corps["scission"];
    assert_eq!(scission["cause"], "categorie_non_mixable");
    assert_eq!(
        scission["message_cle"], "panier.scission.categorie_non_mixable",
        "clé i18n, jamais une phrase en dur (constitution VII)",
    );
    let proposees = scission["commandes_proposees"].as_array().unwrap();
    assert_eq!(proposees.len(), 2, "une commande par vendeur");
    // Prévisualisation CHIFFRÉE : la somme retombe sur le panier d'origine.
    let somme: i64 = proposees
        .iter()
        .map(|c| c["total_articles_unites"].as_i64().unwrap())
        .sum();
    assert_eq!(somme, corps["montant_articles_unites"].as_i64().unwrap());

    // FR-010 — le serveur PROPOSE, il ne scinde jamais d'office.
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        0,
        "aucune commande créée sans une seconde requête explicite du client",
    );

    // Métrique SC-006.
    let evenements = bac.evenements("panier.scission_proposee").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["cause"], "categorie_non_mixable");
    assert_eq!(evenements[0]["nb_commandes"], 2);
    assert_eq!(evenements[0]["categorie"], "restauration");
}

/// Le plafond d'éclatement de la zone (drapeau `proposer_scission` du devis)
/// produit le MÊME bloc, avec sa propre cause — une seule surface (R9).
#[sqlx::test(migrations = "../migrations")]
async fn plafond_eclatement_produit_le_meme_bloc(pool: sqlx::PgPool) {
    let mut bac = Bac::nouveau(pool).await;
    // Le moteur tarifaire lève `proposer_scission` : on rebranche le double.
    let tarif = std::sync::Arc::new(
        commandes::TarifFixe::simple(DEVIS_PRIX_CLIENT, DEVIS_PRIX_CLIENT, 0)
            .avec_proposer_scission(true),
    );
    bac.commandes = commandes::PgCommandes::new(
        bac.pool.clone(),
        bac.prestataires.clone(),
        tarif.clone(),
        tarif,
        bac.restrictions.clone(),
        std::sync::Arc::new(socle::MemoireObjets::new()),
        bac.positions.clone(),
    );

    let lignes: Vec<Value> = bac.vendeurs.iter().map(|v| v.ligne(1)).collect();
    let (statut, corps) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", lignes),
    )
    .await;
    assert_eq!(statut, 200);

    let scission = &corps["scission"];
    assert_eq!(scission["cause"], "plafond_eclatement");
    assert_eq!(
        scission["message_cle"], "panier.scission.plafond_eclatement",
    );
    assert_eq!(
        scission["commandes_proposees"].as_array().unwrap().len(),
        2,
        "deux tournées plus courtes",
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        0,
    );
}

/// **VND-08** — `mono_vendeur` est la condition NÉCESSAIRE de l'offre de
/// livraison vendeur (FR-014). Le devis doit la transmettre au moteur : un
/// panier à un vendeur et un panier à trois ne posent pas la même question.
#[sqlx::test(migrations = "../migrations")]
async fn mono_vendeur_transmis_au_moteur_tarifaire(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let (statut_mono, mono) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", vec![bac.vendeurs[0].ligne(2)]),
    )
    .await;
    assert_eq!(statut_mono, 200);
    assert_eq!(
        mono["groupes"].as_array().unwrap().len(),
        1,
        "un seul vendeur",
    );
    assert_eq!(
        mono["devis"]["ordre_arrets"].as_array().unwrap().len(),
        1,
        "un seul point de retrait soumis au moteur",
    );

    let lignes: Vec<Value> = bac.vendeurs.iter().map(|v| v.ligne(1)).collect();
    let (statut_multi, multi) =
        devis(&bac, &bac.jeton_client, bac.demande_devis("marche", lignes)).await;
    assert_eq!(statut_multi, 200);
    assert_eq!(
        multi["devis"]["ordre_arrets"].as_array().unwrap().len(),
        3,
        "trois points de retrait — le moteur reçoit bien la géométrie complète",
    );
}

/// Panier vide, quantité nulle, vendeur fermé, article inconnu : chaque refus
/// porte sa clé i18n et son statut (contrat §1.2).
#[sqlx::test(migrations = "../migrations")]
async fn refus_portent_leur_cle_i18n(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Le montage du bac (agréments, catalogues) a ses propres événements : on
    // mesure le DELTA, pas un total absolu.
    let evenements_avant = bac.total_evenements().await;

    // Panier vide → 422 panier_invalide.
    let (statut, corps) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", vec![]),
    )
    .await;
    assert_eq!(statut, 422);
    assert_eq!(corps["code"], "panier_invalide");
    assert_eq!(corps["message_cle"], "commande.erreur.panier_invalide");

    // Article inconnu chez un vendeur ouvert → 409 article_indisponible.
    let ligne = serde_json::json!({
        "prestataire_id": bac.vendeurs[0].id,
        "article_id": uuid::Uuid::now_v7(),
        "quantite": 1,
    });
    let (statut, corps) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", vec![ligne]),
    )
    .await;
    assert_eq!(statut, 409);
    assert_eq!(corps["code"], "article_indisponible");

    // Vendeur inconnu → 409 vendeur_indisponible.
    let ligne = serde_json::json!({
        "prestataire_id": uuid::Uuid::now_v7(),
        "article_id": bac.vendeurs[0].articles[0],
        "quantite": 1,
    });
    let (statut, corps) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", vec![ligne]),
    )
    .await;
    assert_eq!(statut, 409);
    assert_eq!(corps["code"], "vendeur_indisponible");

    // Aucun de ces refus n'a rien écrit.
    assert_eq!(
        bac.total_evenements().await,
        evenements_avant,
        "un refus de devis n'émet aucun événement",
    );
}

/// Le devis est réservé aux clients authentifiés : sans jeton, 401.
#[sqlx::test(migrations = "../migrations")]
async fn devis_ferme_sans_session(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = atest::init_service(App::new().configure(bac.configurer())).await;
    let req = atest::TestRequest::post()
        .uri("/paniers/devis")
        .set_json(bac.demande_devis("marche", vec![bac.vendeurs[0].ligne(1)]))
        .to_request();
    let resp = atest::call_service(&app, req).await;
    assert_eq!(resp.status().as_u16(), 401);
}

/// Le plafond cash de la zone décide de l'affichage (maquette C3-3b) : sous le
/// plafond le cash est proposé, au-dessus il est refusé AVEC SA RAISON.
#[sqlx::test(migrations = "../migrations")]
async fn plafond_cash_et_sa_raison(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let (_, petit) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;
    assert_eq!(petit["paiement"]["cash_autorise"], true);
    assert!(petit["paiement"]["motif_cle"].is_null());

    // Quantité massive → total très au-dessus du plafond de zone.
    let (_, gros) = devis(
        &bac,
        &bac.jeton_client,
        bac.demande_devis("marche", vec![bac.vendeurs[0].ligne(100)]),
    )
    .await;
    assert_eq!(gros["paiement"]["cash_autorise"], false);
    assert_eq!(
        gros["paiement"]["motif_cle"], "commande.cash.plafond_depasse",
        "le client voit POURQUOI le cash est grisé, jamais un bouton mort",
    );
    assert_eq!(gros["paiement"]["plafond_unites"], bac_commandes::PLAFOND_CASH);
}
