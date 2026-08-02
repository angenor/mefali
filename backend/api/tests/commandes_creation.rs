//! US3 (CMD-03) — création de commande : structure imposée, prix verrouillés,
//! devis figé, code et QR, idempotence, plafonds cash, et **SC-005** (aucun
//! règlement fractionné possible).
//!
//! L'adresse et son repère (US2) ont leur propre suite,
//! `commandes_adresse.rs` : ce sont deux critères d'acceptation distincts, et
//! les mélanger rendait la suite de création illisible.

mod bac_commandes;

use actix_web::{test as atest, App};
use bac_commandes::{Bac, DEVIS_PRIX_CLIENT, PLAFOND_CASH_RESTAURATION};
use serde_json::{json, Value};
use uuid::Uuid;

/// `POST /commandes` avec une clé d'idempotence donnée.
async fn creer(bac: &Bac, jeton: &str, cle: Uuid, corps: Value) -> (u16, Value) {
    let app = atest::init_service(App::new().configure(bac.configurer())).await;
    let req = atest::TestRequest::post()
        .uri("/commandes")
        .insert_header(("authorization", format!("Bearer {jeton}")))
        .insert_header(("idempotency-key", cle.to_string()))
        .set_json(corps)
        .to_request();
    let resp = atest::call_service(&app, req).await;
    let statut = resp.status().as_u16();
    (statut, atest::read_body_json(resp).await)
}

/// Corps de création nominal : 3 vendeurs, repère écrit assez long, cash.
fn demande(bac: &Bac, lignes: Vec<Value>) -> Value {
    json!({
        "zone_id": bac.ville,
        "categorie_slug": "marche",
        "transport_slug": "moto",
        "lieu": { "lat": 5.9050, "lon": -4.8300 },
        "repere_texte": "Près de la pharmacie Sainte-Marie",
        "lignes": lignes,
        "mode_paiement": "cash",
    })
}

/// La structure IMPOSÉE : tronc sans champ logistique, 1 livraison, 1 segment,
/// 3 collectes dans l'ordre optimisé + 1 remise, chaque ligne rattachée.
#[sqlx::test(migrations = "../migrations")]
async fn structure_produite_tronc_livraison_segment_arrets(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let lignes: Vec<Value> = bac.vendeurs.iter().map(|v| v.ligne(2)).collect();

    let (statut, corps) = creer(
        &bac,
        &bac.jeton_client,
        Uuid::now_v7(),
        demande(&bac, lignes),
    )
    .await;
    assert_eq!(statut, 201);
    assert_eq!(corps["etat"], "nouvelle");

    let commande_id: Uuid = corps["id"].as_str().unwrap().parse().unwrap();
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        1,
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.livraison")
            .await,
        1,
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.segment").await,
        1,
    );

    // 3 collectes + 1 remise = 4 arrêts.
    let (collectes, remises): (i64, i64) = sqlx::query_as(
        "SELECT count(*) FILTER (WHERE type_arret = 'collecte'),
                count(*) FILTER (WHERE type_arret = 'remise')
         FROM commandes.arret",
    )
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!((collectes, remises), (3, 1));
    assert_eq!(corps["livraison"]["nb_arrets"], 4);

    // La REMISE est le DERNIER arrêt, sans prestataire ni montant avancé.
    let (ordre, presta, montant): (i16, Option<Uuid>, i64) = sqlx::query_as(
        "SELECT ordre, prestataire_id, montant_avance FROM commandes.arret
         WHERE type_arret = 'remise'",
    )
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(ordre, 3, "la remise passe après les 3 collectes");
    assert!(presta.is_none(), "une remise n'a pas de vendeur");
    assert_eq!(
        montant, 0,
        "le coursier encaisse à la remise, il n'avance pas"
    );

    // Chaque ligne est rattachée à SON arrêt de collecte.
    let orphelines: i64 =
        sqlx::query_scalar("SELECT count(*) FROM commandes.ligne_commande WHERE arret_id IS NULL")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(orphelines, 0);

    // Constitution II — AUCUNE colonne logistique sur le tronc.
    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name FROM information_schema.columns
         WHERE table_schema = 'commandes' AND table_name = 'commande'",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    for interdite in [
        "coursier_id",
        "devis_prix_client",
        "devis_part_coursier",
        "distance_m",
        "segment_id",
        "livraison_id",
    ] {
        assert!(
            !colonnes.iter().any(|c| c == interdite),
            "« {interdite} » est LOGISTIQUE : elle n'a rien à faire sur le tronc",
        );
    }

    // Les trois événements de création, dans la même transaction.
    assert_eq!(bac.evenements("commande.creee").await.len(), 1);
    assert_eq!(bac.evenements("livraison.creee").await.len(), 1);
    let pretes = bac.evenements("commande.prete_a_dispatcher").await;
    assert_eq!(
        pretes.len(),
        1,
        "contrat SANS consommateur, émis quand même"
    );
    assert_eq!(pretes[0]["nb_arrets"], 4);
    let _ = commande_id;
}

/// Les prix sont VERROUILLÉS à la création : modifier le catalogue ensuite ne
/// change plus rien à la commande (constitution III).
#[sqlx::test(migrations = "../migrations")]
async fn prix_verrouilles_et_devis_fige(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let vendeur = &bac.vendeurs[0];
    let (statut, corps) = creer(
        &bac,
        &bac.jeton_client,
        Uuid::now_v7(),
        demande(&bac, vec![vendeur.ligne(2)]),
    )
    .await;
    assert_eq!(statut, 201);
    let montant_initial = corps["montant_articles_unites"].as_i64().unwrap();
    assert_eq!(montant_initial, vendeur.prix[0] * 2);

    // Le vendeur double son prix APRÈS la commande.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.prestataires
        .modifier_article(
            &mut tx,
            vendeur.id,
            vendeur.articles[0],
            &prestataires::ModificationArticle {
                prix_unites: Some(vendeur.prix[0] * 2),
                ..Default::default()
            },
            prestataires::SourceBascule::Admin,
            bac.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    // Le prix FIGÉ n'a pas bougé d'un franc.
    let fige: i64 = sqlx::query_scalar(
        "SELECT pf.prix_unites FROM commandes.ligne_commande l
         JOIN prestataires.prix_fige pf ON pf.id = l.prix_fige_id",
    )
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(fige, vendeur.prix[0], "le prix verrouillé est invariant");

    // Le devis figé est COPIÉ sur la livraison, pas référencé.
    let (prix_client, part): (i64, i64) =
        sqlx::query_as("SELECT devis_prix_client, devis_part_coursier FROM commandes.livraison")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(prix_client, DEVIS_PRIX_CLIENT);
    assert_eq!(part, bac_commandes::DEVIS_PART_COURSIER);
}

/// **SC-010** — même `Idempotency-Key` deux fois → une seule commande,
/// réponses identiques, aucun second événement.
#[sqlx::test(migrations = "../migrations")]
async fn idempotence_de_creation(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let cle = Uuid::now_v7();
    let corps_demande = demande(&bac, vec![bac.vendeurs[0].ligne(1)]);

    let (statut1, corps1) = creer(&bac, &bac.jeton_client, cle, corps_demande.clone()).await;
    assert_eq!(statut1, 201);
    let (statut2, corps2) = creer(&bac, &bac.jeton_client, cle, corps_demande).await;
    assert_eq!(statut2, 200, "un rejeu n'est pas une création");

    assert_eq!(corps1["id"], corps2["id"]);
    assert_eq!(corps1["total_unites"], corps2["total_unites"]);
    assert_eq!(
        corps1["remise"]["code_livraison"], corps2["remise"]["code_livraison"],
        "le code remis au client ne change pas au rejeu",
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        1,
        "une seule commande",
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.ligne_commande")
            .await,
        1,
        "aucune ligne dupliquée",
    );
    assert_eq!(
        bac.evenements("commande.creee").await.len(),
        1,
        "aucun second événement au rejeu",
    );
}

/// **R6** — le rejeu ne sert ses SECRETS qu'au propriétaire.
///
/// L'`Idempotency-Key` EST l'identifiant de la commande : un compte `Client` qui
/// en connaît un peut le rejouer. Sans contrôle de propriété, il recevait un
/// `200` portant `code_livraison` et `jeton_reception` — les deux valeurs qui
/// font remettre la marchandise, réservées au client propriétaire.
///
/// **404, jamais 403** : dire « ce n'est pas la vôtre » confirmerait que la
/// commande existe, ce qui est déjà une fuite. Même règle que
/// `GET /commandes/{id}` (`commandes_suivi.rs`).
#[sqlx::test(migrations = "../migrations")]
async fn le_rejeu_ne_sert_ses_secrets_qu_au_proprietaire(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let cle = Uuid::now_v7();

    let (statut, corps) = creer(
        &bac,
        &bac.jeton_client,
        cle,
        demande(&bac, vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;
    assert_eq!(statut, 201);
    let code = corps["remise"]["code_livraison"]
        .as_str()
        .unwrap()
        .to_owned();
    let jeton = corps["remise"]["jeton_reception"]
        .as_str()
        .unwrap()
        .to_owned();

    // L'intrus rejoue la clé de la commande d'autrui, avec son propre panier.
    let (statut, corps) = creer(
        &bac,
        &bac.jeton_intrus,
        cle,
        demande(&bac, vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;

    assert_eq!(statut, 404, "{corps}");
    assert_eq!(corps["code"], "commande_inconnue");
    assert!(
        !corps.to_string().contains(&code),
        "le CODE de remise ne doit pas fuiter : {corps}",
    );
    assert!(
        !corps.to_string().contains(&jeton),
        "le JETON de réception ne doit pas fuiter : {corps}",
    );
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        1,
        "le refus ne crée rien non plus",
    );

    // Et le propriétaire, lui, rejoue toujours : le contrôle n'a pas cassé R7.
    let (statut, corps) = creer(
        &bac,
        &bac.jeton_client,
        cle,
        demande(&bac, vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["remise"]["code_livraison"], code);
}

/// La clé d'idempotence est OBLIGATOIRE : sans elle, pas de création.
#[sqlx::test(migrations = "../migrations")]
async fn cle_idempotence_obligatoire(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let app = atest::init_service(App::new().configure(bac.configurer())).await;
    let req = atest::TestRequest::post()
        .uri("/commandes")
        .insert_header(("authorization", format!("Bearer {}", bac.jeton_client)))
        .set_json(demande(&bac, vec![bac.vendeurs[0].ligne(1)]))
        .to_request();
    let resp = atest::call_service(&app, req).await;
    assert_eq!(resp.status().as_u16(), 422);
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        0,
    );
}

/// Compte BLOQUÉ (FR-026) : refus AVANT tout verrouillage de prix.
#[sqlx::test(migrations = "../migrations")]
async fn compte_bloque_refuse_avant_tout(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.restrictions.definir(
        bac.client,
        commandes::Restrictions {
            prepaiement_impose: false,
            bloque: true,
        },
    );

    let (statut, refus) = creer(
        &bac,
        &bac.jeton_client,
        Uuid::now_v7(),
        demande(&bac, vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;
    assert_eq!(statut, 403);
    assert_eq!(refus["code"], "compte_bloque");
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.prix_fige")
            .await,
        0,
        "aucun prix verrouillé : le refus arrive AVANT",
    );
}

/// Vendeur fermé entre le devis et la confirmation → refus avant verrouillage.
#[sqlx::test(migrations = "../migrations")]
async fn vendeur_ferme_refuse_avant_verrouillage(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.prestataires
        .suspendre(&mut tx, bac.vendeurs[0].id, "contrôle", bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let (statut, refus) = creer(
        &bac,
        &bac.jeton_client,
        Uuid::now_v7(),
        demande(&bac, vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;
    assert_eq!(statut, 409);
    assert_eq!(refus["code"], "vendeur_indisponible");
    assert_eq!(
        bac.compter("SELECT count(*) FROM prestataires.prix_fige")
            .await,
        0,
    );
}

/// Plafonds cash (FR-024) : au-dessus du plafond, le cash est refusé ; le
/// prépaiement passe et la commande naît `en_attente_paiement`.
#[sqlx::test(migrations = "../migrations")]
async fn plafond_cash_bascule_en_prepaiement(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Quantité massive → très au-dessus du plafond de zone.
    let lignes = vec![bac.vendeurs[0].ligne(100)];

    let (statut, refus) = creer(
        &bac,
        &bac.jeton_client,
        Uuid::now_v7(),
        demande(&bac, lignes.clone()),
    )
    .await;
    assert_eq!(statut, 409);
    assert_eq!(refus["code"], "cash_indisponible");

    let mut corps = demande(&bac, lignes);
    corps["mode_paiement"] = json!("mobile_money");
    let (statut, cree) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 201);
    assert_eq!(cree["etat"], "en_attente_paiement");
    assert_eq!(cree["paiement"]["etat"], "en_attente");

    let requis = bac.evenements("commande.paiement_requis").await;
    assert_eq!(requis.len(), 1);
    assert_eq!(requis[0]["motif"], "plafond");
    assert!(
        bac.evenements("commande.prete_a_dispatcher")
            .await
            .is_empty(),
        "rien ne part au dispatch tant que le prépaiement n'est pas réglé",
    );
}

/// **FR-024** — le plafond RÉDUIT s'applique à la 1ʳᵉ commande de restauration,
/// puis se lève une fois une commande TERMINÉE au compteur.
#[sqlx::test(migrations = "../migrations")]
async fn plafond_reduit_restauration_puis_leve_apres_une_commande_terminee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    // Le maquis coûte 2 000 l'unité : 3 unités = 6 000, au-dessus du plafond
    // réduit (5 000) mais sous le plafond ordinaire (15 000).
    let mut corps = json!({
        "zone_id": bac.ville,
        "categorie_slug": "restauration",
        "transport_slug": "moto",
        "lieu": { "lat": 5.9050, "lon": -4.8300 },
        "repere_texte": "Près de la pharmacie Sainte-Marie",
        "lignes": [bac.resto.ligne(3)],
        "mode_paiement": "cash",
    });
    assert!(bac.resto.prix[0] * 3 > PLAFOND_CASH_RESTAURATION);

    let (statut, refus) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps.clone()).await;
    assert_eq!(statut, 409, "client sans historique : plafond réduit");
    assert_eq!(refus["code"], "cash_indisponible");

    // Une commande TERMINÉE au compteur lève le plafond réduit. (Les commandes
    // annulées ou échouées ne comptent pas — on mesure une relation aboutie.)
    sqlx::query(
        "INSERT INTO commandes.commande
             (id, client_id, zone_id, categorie_id, lieu_lat, lieu_lon,
              montant_articles_unites, total_unites, devise, mode_paiement,
              etat_paiement, etat, code_livraison, code_livraison_hash,
              jeton_reception, jeton_reception_hash)
         VALUES ($1, $2, $3, $4, 5.9, -4.8, 1000, 1000, 'XOF', 'cash',
                 'regle', 'terminee', '0000', 'h', 'j', 'h')",
    )
    .bind(Uuid::now_v7())
    .bind(bac.client)
    .bind(bac.ville)
    .bind(bac.categorie_marche)
    .execute(&bac.pool)
    .await
    .unwrap();

    corps["lignes"] = json!([bac.resto.ligne(3)]);
    let (statut, _) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 201, "le plafond ordinaire s'applique désormais");
}

/// **SC-005** — aucune surface n'accepte un règlement fractionné.
///
/// La garde est STRUCTURELLE : il n'existe qu'un `total_unites`, et le contrat
/// n'expose aucun paramètre de fraction. Ce test l'exerce des deux côtés — un
/// champ de montant partiel est ignoré, et l'appoint annoncé EST le total.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_reglement_fractionne_possible(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let mut corps = demande(&bac, vec![bac.vendeurs[0].ligne(2)]);
    // Tentative : glisser un montant partiel dans la demande.
    corps["montant_partiel_unites"] = json!(100);
    corps["acompte_unites"] = json!(100);

    let (statut, cree) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 201);

    let total = cree["total_unites"].as_i64().unwrap();
    assert_eq!(
        cree["paiement"]["appoint_exact_unites"].as_i64().unwrap(),
        total,
        "le SEUL montant encaissable est le total (constitution III)",
    );

    // Et en base : un seul montant, aucune trace d'un règlement partiel.
    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name FROM information_schema.columns
         WHERE table_schema = 'commandes' AND table_name = 'commande'",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    for interdite in [
        "acompte_unites",
        "montant_partiel_unites",
        "reste_du_unites",
    ] {
        assert!(
            !colonnes.iter().any(|c| c == interdite),
            "aucun chemin de paiement partiel ne doit exister : « {interdite} »",
        );
    }
    let etat_paiement: String =
        sqlx::query_scalar("SELECT etat_paiement::text FROM commandes.commande")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(
        etat_paiement, "du",
        "l'état de paiement est binaire : dû ou réglé, jamais « partiellement »",
    );
}

/// La restauration reste MONO-VENDEUR : la garde du vertical refuse le panier
/// multi-vendeurs AVANT toute écriture (constitution II).
#[sqlx::test(migrations = "../migrations")]
async fn restauration_multi_vendeurs_refusee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let corps = json!({
        "zone_id": bac.ville,
        "categorie_slug": "restauration",
        "transport_slug": "moto",
        "lieu": { "lat": 5.9050, "lon": -4.8300 },
        "repere_texte": "Près de la pharmacie Sainte-Marie",
        "lignes": [bac.resto.ligne(1), bac.vendeurs[0].ligne(1)],
        "mode_paiement": "cash",
    });
    let (statut, refus) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 409);
    assert_eq!(refus["code"], "categorie_non_mixable");
    assert_eq!(
        bac.compter("SELECT count(*) FROM commandes.commande").await,
        0,
    );
}

/// Le code et le jeton de remise sont générés et rendus au client — et leurs
/// EMPREINTES sont stockées pour le pré-provisionnement coursier (R6).
#[sqlx::test(migrations = "../migrations")]
async fn secrets_de_remise_rendus_au_client_et_empreintes_stockees(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let cle = Uuid::now_v7();
    let (statut, corps) = creer(
        &bac,
        &bac.jeton_client,
        cle,
        demande(&bac, vec![bac.vendeurs[0].ligne(1)]),
    )
    .await;
    assert_eq!(statut, 201);

    let code = corps["remise"]["code_livraison"].as_str().unwrap();
    let jeton = corps["remise"]["jeton_reception"].as_str().unwrap();
    assert_eq!(code.len(), 4, "code à 4 chiffres");
    assert!(code.chars().all(|c| c.is_ascii_digit()));
    assert!(jeton.len() >= 32, "jeton long, non devinable");

    let (code_hash, jeton_hash): (String, String) =
        sqlx::query_as("SELECT code_livraison_hash, jeton_reception_hash FROM commandes.commande")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    // Le coursier ne reçoit QUE ces empreintes — jamais le code (R6).
    assert_eq!(code_hash, socle::empreinte_code(cle, code));
    assert_eq!(jeton_hash, socle::empreinte_jeton(jeton));
    assert_ne!(code_hash, code, "l'empreinte n'est pas le secret");
}
