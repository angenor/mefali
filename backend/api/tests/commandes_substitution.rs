//! US7 (CMD-06) — gérer un article manquant sans casser la commande.
//!
//! Ce que ces tests protègent, dans l'ordre d'importance :
//!
//! 1. **Le devis de livraison ne bouge JAMAIS** (FR-050). C'est l'assertion la
//!    plus importante du cycle côté argent : le double [`TarifFixe`] rend un
//!    devis connu d'avance, donc l'invariance se vérifie au FCFA près, avant et
//!    après chaque substitution.
//! 2. Les **trois préférences** produisent bien trois comportements distincts.
//! 3. Les **deux gardes** de la proposition : même vendeur, écart de prix borné.
//! 4. L'**expiration** appelle, puis retire — et ne facture rien.

mod bac_commandes;

use bac_commandes::{Bac, Course, DEVIS_PRIX_CLIENT};
use serde_json::{json, Value};
use uuid::Uuid;

/// Multipart `POST /courses/{livraison}/substitutions`.
async fn declarer(
    bac: &Bac,
    jeton: &str,
    livraison: Uuid,
    demande: Value,
    avec_photo: bool,
) -> (u16, Value) {
    let app = actix_web::test::init_service(
        actix_web::App::new().configure(bac.configurer()),
    )
    .await;
    let frontiere = "----mefali-test";
    let mut corps = format!(
        "--{frontiere}\r\nContent-Disposition: form-data; name=\"demande\"\r\n\r\n{demande}\r\n"
    );
    if avec_photo {
        corps.push_str(&format!(
            "--{frontiere}\r\nContent-Disposition: form-data; name=\"photo\"; \
             filename=\"p.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n\u{FFFD}\u{FFFD}\u{FFFD}\r\n"
        ));
    }
    corps.push_str(&format!("--{frontiere}--\r\n"));

    let req = actix_web::test::TestRequest::post()
        .uri(&format!("/courses/{livraison}/substitutions"))
        .insert_header(("authorization", format!("Bearer {jeton}")))
        .insert_header((
            "content-type",
            format!("multipart/form-data; boundary={frontiere}"),
        ))
        .set_payload(corps)
        .to_request();
    let resp = actix_web::test::call_service(&app, req).await;
    let statut = resp.status().as_u16();
    (statut, actix_web::test::read_body_json(resp).await)
}

/// Les lignes d'une commande, avec leur statut et leur préférence.
async fn lignes(bac: &Bac, commande: Uuid) -> Vec<(Uuid, String, String, Uuid)> {
    sqlx::query_as(
        "SELECT lc.id, lc.statut::text, lc.preference::text, lc.prestataire_id
         FROM commandes.ligne_commande lc
         WHERE lc.commande_id = $1 ORDER BY lc.cree_le",
    )
    .bind(commande)
    .fetch_all(&bac.pool)
    .await
    .unwrap()
}

/// Devis figé de la course — il ne doit JAMAIS changer (FR-050).
async fn devis(bac: &Bac, livraison: Uuid) -> (i64, i64) {
    sqlx::query_as(
        "SELECT devis_prix_client, devis_part_coursier FROM commandes.livraison WHERE id = $1",
    )
    .bind(livraison)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

/// Montants du tronc.
async fn montants(bac: &Bac, commande: Uuid) -> (i64, i64) {
    sqlx::query_as(
        "SELECT montant_articles_unites, total_unites FROM commandes.commande WHERE id = $1",
    )
    .bind(commande)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

/// Une course dont chaque ligne porte une préférence explicite.
async fn course_avec_preferences(bac: &Bac) -> Course {
    let lignes = vec![
        bac.vendeurs[0].ligne_avec_preference(0, 2, "retirer"),
        bac.vendeurs[1].ligne_avec_preference(0, 2, "appeler"),
        bac.vendeurs[2].ligne_avec_preference(0, 2, "remplacer"),
    ];
    let commande = bac.creer_commande_api("marche", lignes).await;
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, remise) = bac.arrets_de(livraison).await;
    Course {
        commande,
        livraison,
        collectes,
        remise,
    }
}

/// **FR-045 (1/3)** — « retirer » : l'article sort, le montant est révisé, et
/// **les frais ne bougent pas**.
#[sqlx::test(migrations = "../migrations")]
async fn preference_retirer_sort_l_article_sans_toucher_aux_frais(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let avant_devis = devis(&bac, course.livraison).await;
    let (articles_avant, total_avant) = montants(&bac, course.commande).await;

    let ligne = lignes(&bac, course.commande).await[0].0;
    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({ "ligne_id": ligne, "uuid_client": Uuid::now_v7() }),
        false,
    )
    .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["issue"], "ligne_retiree");

    // 2 × 500 = 1 000 sortis du montant des articles.
    let montant_retire = corps["montant_retire"].as_i64().unwrap();
    assert_eq!(montant_retire, 1_000);
    let (articles_apres, total_apres) = montants(&bac, course.commande).await;
    assert_eq!(articles_apres, articles_avant - montant_retire);
    assert_eq!(total_apres, total_avant - montant_retire);

    // ⚠ L'ASSERTION DU CYCLE : le devis figé est identique au FCFA près.
    assert_eq!(
        devis(&bac, course.livraison).await,
        avant_devis,
        "FR-050 — ni les frais de déplacement ni l'effort ne bougent",
    );
    assert_eq!(corps["total_unites"], total_apres);

    // Le motif du retrait dit POURQUOI, pas seulement QUE.
    let evenements = bac.evenements("ligne.retiree").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["motif"], "preference");
    assert_eq!(evenements[0]["montant_retire"], 1_000);
}

/// **FR-045 (2/3)** — « m'appeler » : l'appel est JOURNALISÉ, et la résolution
/// saisie est appliquée.
#[sqlx::test(migrations = "../migrations")]
async fn preference_appeler_journalise_l_appel_puis_applique_la_resolution(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let ligne = lignes(&bac, course.commande).await[1].0;

    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "retirer",
        }),
        false,
    )
    .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["issue"], "ligne_retiree");

    let appels = bac.evenements("appel.intention").await;
    assert_eq!(appels.len(), 1, "l'appel est journalisé (FR-045)");
    assert_eq!(appels[0]["de"], "coursier");
    assert_eq!(appels[0]["vers"], "client");
    assert_eq!(appels[0]["motif"], "substitution");
    // Aucun numéro n'entre dans le journal (minimisation ARTCI).
    let telephone: String =
        sqlx::query_scalar("SELECT telephone_e164 FROM comptes.compte WHERE id = $1")
            .bind(bac.client)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert!(!appels[0].to_string().contains(&telephone));
}

/// **FR-045 (3/3)** — « remplacer » : proposition avec photo et prix, fenêtre de
/// décision, puis acceptation au prix PROPOSÉ.
#[sqlx::test(migrations = "../migrations")]
async fn preference_remplacer_ouvre_une_proposition_puis_acceptee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let avant_devis = devis(&bac, course.livraison).await;
    let ligne = lignes(&bac, course.commande).await[2].0;
    // Boutique Yao : article 0 à 700, article 1 à 250. Le remplacement doit
    // rester chez le MÊME vendeur et dans ±20 % — 770 = +10 %.
    let remplacant = bac.vendeurs[2].articles[0];

    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": remplacant,
            "prix_propose_unites": 770,
        }),
        true,
    )
    .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["issue"], "proposition_ouverte");
    assert_eq!(corps["ecart_pourcent"], 10);
    assert_eq!(corps["reste_s"], 60, "la fenêtre de 60 s du produit");

    let substitution: Uuid = corps["substitution_id"].as_str().unwrap().parse().unwrap();
    let proposees = bac.evenements("substitution.proposee").await;
    assert_eq!(proposees.len(), 1);
    assert_eq!(proposees[0]["echeance_s"], 60);

    // Le client voit la proposition dans son suivi, avec son compte à rebours.
    let (_, suivi) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(suivi["substitution_en_attente"]["id"], substitution.to_string());
    assert!(suivi["substitution_en_attente"]["reste_s"].as_i64().unwrap() > 0);

    // Acceptation : la ligne devient `remplacee` au prix proposé.
    let (statut, corps) = bac
        .post(
            &format!(
                "/commandes/{}/substitutions/{substitution}/decision",
                course.commande
            ),
            &bac.jeton_client,
            json!({ "accepte": true }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["issue"], "acceptee");
    assert_eq!(
        corps["devis_prix_client_unites"], DEVIS_PRIX_CLIENT,
        "FR-050 — le devis servi au client est le devis FIGÉ",
    );
    assert_eq!(
        devis(&bac, course.livraison).await,
        avant_devis,
        "FR-050 — le devis en base n'a pas bougé non plus",
    );

    let statut_ligne = &lignes(&bac, course.commande).await[2].1;
    assert_eq!(statut_ligne, "remplacee");
    assert_eq!(bac.nb_evenements("substitution.decidee").await, 1);
}

/// **FR-045** — refus : l'article est retiré, et rien n'est payé pour lui.
#[sqlx::test(migrations = "../migrations")]
async fn un_remplacement_refuse_retire_l_article_non_facture(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let ligne = lignes(&bac, course.commande).await[2].0;
    let (_, total_avant) = montants(&bac, course.commande).await;

    let (_, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": bac.vendeurs[2].articles[0],
            "prix_propose_unites": 770,
        }),
        true,
    )
    .await;
    let substitution = corps["substitution_id"].as_str().unwrap();

    let (statut, corps) = bac
        .post(
            &format!(
                "/commandes/{}/substitutions/{substitution}/decision",
                course.commande
            ),
            &bac.jeton_client,
            json!({ "accepte": false }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["issue"], "refusee");

    assert_eq!(lignes(&bac, course.commande).await[2].1, "retiree");
    let (_, total_apres) = montants(&bac, course.commande).await;
    assert_eq!(total_apres, total_avant - 1_400, "2 × 700 non facturés");
    let retirees = bac.evenements("ligne.retiree").await;
    assert_eq!(retirees[0]["motif"], "refus");
}

/// **FR-047 / FR-048** — les deux gardes de la proposition.
#[sqlx::test(migrations = "../migrations")]
async fn autre_vendeur_refuse_et_ecart_de_prix_borne(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let ligne = lignes(&bac, course.commande).await[2].0;

    // Un article d'un AUTRE vendeur : refusé quel que soit son prix (FR-048).
    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": bac.vendeurs[0].articles[0],
            "prix_propose_unites": 700,
        }),
        true,
    )
    .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "substitution_autre_vendeur");

    // +25 % : au-delà du plafond de zone (20 %) → refusé (FR-047).
    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": bac.vendeurs[2].articles[0],
            "prix_propose_unites": 875,
        }),
        true,
    )
    .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "substitution_ecart_prix");

    // +20 % PILE : accepté — la borne est inclusive.
    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": bac.vendeurs[2].articles[0],
            "prix_propose_unites": 840,
        }),
        true,
    )
    .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["ecart_pourcent"], 20);

    // Aucun refus n'a laissé de trace : un refus n'est pas une transition.
    assert_eq!(bac.nb_evenements("substitution.proposee").await, 1);
}

/// **FR-046** — expiration : on APPELLE, puis l'article est retiré et non
/// facturé. Et la décision arrivée trop tard est refusée.
#[sqlx::test(migrations = "../migrations")]
async fn expiration_appelle_puis_retire_sans_facturer(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let avant_devis = devis(&bac, course.livraison).await;
    let ligne = lignes(&bac, course.commande).await[2].0;
    let (_, total_avant) = montants(&bac, course.commande).await;

    let (_, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": bac.vendeurs[2].articles[0],
            "prix_propose_unites": 770,
        }),
        true,
    )
    .await;
    let substitution: Uuid = corps["substitution_id"].as_str().unwrap().parse().unwrap();

    // L'échéance est PERSISTÉE : on la fait passer, sans attendre 60 s.
    sqlx::query("UPDATE commandes.substitution SET echeance = now() - interval '1 second' WHERE id = $1")
        .bind(substitution)
        .execute(&bac.pool)
        .await
        .unwrap();

    // Le suivi ne sert plus la proposition comme « en attente » : la résolution
    // se fait à la LECTURE, avant même le balayage (research R10).
    let (_, suivi) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert!(suivi["substitution_en_attente"].is_null());

    // Une décision arrivée trop tard est refusée.
    let (statut, corps) = bac
        .post(
            &format!(
                "/commandes/{}/substitutions/{substitution}/decision",
                course.commande
            ),
            &bac.jeton_client,
            json!({ "accepte": true }),
        )
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "substitution_expiree");

    // Le balayage : appel, puis retrait NON FACTURÉ.
    let expirees = bac
        .commandes
        .expirer_substitutions_echues(chrono::Utc::now())
        .await
        .unwrap();
    assert_eq!(expirees, vec![substitution]);

    let appels = bac.evenements("appel.intention").await;
    assert_eq!(appels.len(), 1);
    assert_eq!(appels[0]["motif"], "expiration");
    assert_eq!(appels[0]["de"], "systeme");

    assert_eq!(lignes(&bac, course.commande).await[2].1, "retiree");
    let (_, total_apres) = montants(&bac, course.commande).await;
    assert_eq!(total_apres, total_avant - 1_400, "rien à payer pour lui");
    assert_eq!(
        devis(&bac, course.livraison).await,
        avant_devis,
        "FR-050 — même à l'expiration, les frais ne bougent pas",
    );

    // Second balayage : rien de neuf (l'index partiel ne porte que `en_attente`).
    assert!(bac
        .commandes
        .expirer_substitutions_echues(chrono::Utc::now())
        .await
        .unwrap()
        .is_empty());
    assert_eq!(bac.nb_evenements("substitution.decidee").await, 1);
}

/// **FR-051** — arrêt entièrement indisponible : compté RÉSOLU, avance nulle,
/// lignes retirées, frais inchangés.
#[sqlx::test(migrations = "../migrations")]
async fn arret_entierement_indisponible(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let avant_devis = devis(&bac, course.livraison).await;
    let (_, total_avant) = montants(&bac, course.commande).await;

    let (statut, corps) = bac
        .action_coursier(
            course.livraison,
            course.collectes[0],
            "indisponible",
            Uuid::now_v7(),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["statut"], "indisponible");
    assert_eq!(
        corps["collectes_resolues"], 1,
        "un arrêt indisponible est RÉSOLU (FR-051) : le coursier n'y revient pas",
    );
    assert_eq!(
        corps["collectes_faites"], 0,
        "…mais rien n'y a été COLLECTÉ — le compteur d'achats ne ment pas",
    );

    let avance: i64 = sqlx::query_scalar(
        "SELECT montant_avance FROM commandes.arret WHERE id = $1",
    )
    .bind(course.collectes[0])
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(avance, 0, "rien acheté, rien avancé");

    let retirees = bac.evenements("ligne.retiree").await;
    assert_eq!(retirees.len(), 1);
    assert_eq!(retirees[0]["motif"], "arret_indisponible");

    let (_, total_apres) = montants(&bac, course.commande).await;
    assert!(total_apres < total_avant, "les articles non achetés sortent");
    assert_eq!(
        devis(&bac, course.livraison).await,
        avant_devis,
        "FR-050 — l'effort promis au coursier reste dû",
    );
}

/// Une ligne déjà résolue ne se re-résout pas, et un rejeu du même
/// `uuid_client` rend la proposition existante (constitution V).
#[sqlx::test(migrations = "../migrations")]
async fn rejeu_et_double_resolution(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let ligne = lignes(&bac, course.commande).await[2].0;
    let uuid = Uuid::now_v7();
    let demande = json!({
        "ligne_id": ligne,
        "uuid_client": uuid,
        "resolution": "remplacer",
        "article_propose_id": bac.vendeurs[2].articles[0],
        "prix_propose_unites": 770,
    });

    let (_, premier) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        demande.clone(),
        true,
    )
    .await;
    let (statut, second) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        demande,
        true,
    )
    .await;
    assert_eq!(statut, 200);
    assert_eq!(
        second["substitution_id"], premier["substitution_id"],
        "le rejeu rend la proposition EXISTANTE",
    );
    assert_eq!(
        bac.nb_evenements("substitution.proposee").await,
        1,
        "aucune seconde proposition, aucun second événement",
    );

    // Une ligne déjà retirée ne se retire pas deux fois : le montant sortirait
    // du total une seconde fois.
    let ligne_retiree = lignes(&bac, course.commande).await[0].0;
    declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({ "ligne_id": ligne_retiree, "uuid_client": Uuid::now_v7() }),
        false,
    )
    .await;
    let (statut, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({ "ligne_id": ligne_retiree, "uuid_client": Uuid::now_v7() }),
        false,
    )
    .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "etat_incompatible");
}

/// La propriété : ni un autre coursier ne déclare la rupture, ni un autre
/// client ne décide de la proposition.
#[sqlx::test(migrations = "../migrations")]
async fn propriete_gardee_des_deux_cotes(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_avec_preferences(&bac).await;
    let ligne = lignes(&bac, course.commande).await[2].0;

    let (_, jeton_autre) = bac
        .compte_avec_roles("+2250700000077", &["client", "coursier"])
        .await;
    let (statut, corps) = declarer(
        &bac,
        &jeton_autre,
        course.livraison,
        json!({ "ligne_id": ligne, "uuid_client": Uuid::now_v7() }),
        false,
    )
    .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "non_proprietaire");

    let (_, corps) = declarer(
        &bac,
        &bac.jeton_coursier,
        course.livraison,
        json!({
            "ligne_id": ligne,
            "uuid_client": Uuid::now_v7(),
            "resolution": "remplacer",
            "article_propose_id": bac.vendeurs[2].articles[0],
            "prix_propose_unites": 770,
        }),
        true,
    )
    .await;
    let substitution = corps["substitution_id"].as_str().unwrap();

    let (statut, corps) = bac
        .post(
            &format!(
                "/commandes/{}/substitutions/{substitution}/decision",
                course.commande
            ),
            &bac.jeton_intrus,
            json!({ "accepte": true }),
        )
        .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "non_proprietaire");
}
