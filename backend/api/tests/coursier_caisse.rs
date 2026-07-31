//! US5 (CRS-06) — **la caisse**, et ce qu'elle ne doit jamais faire.
//!
//! Yao sort de l'argent de sa poche à chaque arrêt et le récupère chez le
//! client. Entre les deux, il porte le risque. Un livre qui ment une fois ne se
//! rattrape pas : il n'y a pas de « petit écart » quand c'est l'argent de
//! quelqu'un qui roule toute la journée.
//!
//! Ce que ce fichier tient, et contre quelle erreur précise :
//!
//! 1. **Trois avances, un remboursement, solde à zéro** (SC-009) — le compte
//!    exact d'une course cash de trois arrêts. C'est aussi le point 6 de
//!    `quickstart.md` §2.1, laissé ouvert par `coursier_reconciliation.rs` tant
//!    que la caisse n'existait pas.
//! 2. **Une commande prépayée ne se solde PAS** (R10, FR-117) — aucun cash n'a
//!    changé de main : écrire un remboursement fictif ferait mentir un solde
//!    d'argent réel. L'avance reste ouverte, et la caisse **le dit**.
//! 3. **Le livre est immuable** (FR-073) — aucun `UPDATE`, aucun `DELETE` ; une
//!    correction est une écriture inverse. Corriger en place effacerait la trace
//!    de l'erreur en même temps que l'erreur, et c'est justement cette trace qui
//!    permet de répondre à un coursier qui conteste.
//! 4. **Un rejeu d'outbox ne double rien** — le worker livre AU MOINS une fois
//!    (contrat `socle`) ; sans idempotence par `evenement_id`, chaque relivraison
//!    rembourserait une seconde fois.
//! 5. **L'écart au plafond est signalé** (FR-078) — une avance en cours au-delà
//!    de ce que Yao a déclaré pouvoir porter n'est jamais normale.
//!
//! **Pourquoi `drainer_caisse` plutôt que le worker** : les écritures naissent
//! d'événements outbox. Monter le worker ferait dépendre chaque assertion d'un
//! ordonnancement asynchrone — un test de comptabilité qui attend une seconde de
//! plus n'est pas un test, c'est un pari. Le bac appelle `consommer_pour_caisse`,
//! qui est **exactement** ce que l'adaptateur `CaisseOutbox` appelle en
//! production.

mod bac_coursier;

use bac_coursier::{Bac, Course, DEVIS_PART_COURSIER, PALIER_AVANCE};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

/// Somme des montants avancés aux arrêts d'une course, lue sur les arrêts
/// eux-mêmes : c'est la seule référence indépendante du livre de caisse.
///
/// L'asserter contre une constante écrite à la main donnerait un test qui passe
/// même si la tarification change — et qui ne prouverait plus rien.
async fn avance_attendue(bac: &Bac, course: &Course) -> i64 {
    sqlx::query_scalar::<_, i64>(
        "SELECT COALESCE(SUM(montant_avance), 0)::bigint FROM commandes.arret
          WHERE id = ANY($1)",
    )
    .bind(&course.collectes)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

/// Confirme la remise par le code du client — la course se termine.
async fn confirmer_remise(bac: &Bac, course: &Course) {
    bac.arriver_chez_le_client(course).await;
    let secrets = bac.secrets_remise(course.commande).await;
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "remise refusée : {corps}");
}

// ── SC-009 : le compte exact d'une course cash ─────────────────────────────

/// **Le test central du module** — et le point 6 de `quickstart.md` §2.1, resté
/// ouvert au cycle précédent parce que la caisse n'existait pas encore.
///
/// Trois arrêts collectés → trois avances. Une remise encaissée en espèces → un
/// remboursement, exactement de la somme portée. Solde : zéro, au franc près.
#[sqlx::test(migrations = "../migrations")]
async fn trois_avances_un_remboursement_solde_a_zero(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let attendu = avance_attendue(&bac, &course).await;
    assert!(attendu > 0, "une course de 3 vendeurs avance de l'argent");

    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    // Pendant la course : l'argent est SORTI, et la caisse le montre.
    let caisse = bac.lire_caisse().await;
    assert_eq!(caisse["avance_en_cours_unites"], json!(attendu));
    assert_eq!(caisse["courses_concernees"], json!(1));
    assert_eq!(
        bac.ecritures_caisse(bac.coursier)
            .await
            .iter()
            .filter(|(t, _)| t == "avance")
            .count(),
        3,
        "une avance par arrêt collecté",
    );

    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    // Après encaissement : retour à zéro. Un centime d'écart ici, et Yao
    // paierait la différence tous les jours sans jamais pouvoir le prouver.
    let caisse = bac.lire_caisse().await;
    assert_eq!(caisse["avance_en_cours_unites"], json!(0));
    assert_eq!(caisse["courses_concernees"], json!(0));

    let ecritures = bac.ecritures_caisse(bac.coursier).await;
    let avances: i64 = ecritures
        .iter()
        .filter(|(t, _)| t == "avance")
        .map(|(_, m)| *m)
        .sum();
    let remboursements: Vec<i64> = ecritures
        .iter()
        .filter(|(t, _)| t == "remboursement")
        .map(|(_, m)| *m)
        .collect();
    assert_eq!(avances, -attendu, "les avances SORTENT (signe négatif)");
    assert_eq!(
        remboursements,
        vec![attendu],
        "un SEUL remboursement, exactement l'opposé des avances",
    );
    assert_eq!(avances + remboursements.iter().sum::<i64>(), 0);
}

/// L'historique du jour porte **trois chiffres** par course (FR-069, K5-1a).
///
/// Deux suffiraient à faire un total juste et un écran inutilisable : c'est
/// l'écart entre les trois qui permet de contester une ligne.
#[sqlx::test(migrations = "../migrations")]
async fn l_historique_du_jour_porte_les_trois_chiffres(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let attendu = avance_attendue(&bac, &course).await;

    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    let caisse = bac.lire_caisse().await;
    let lignes = caisse["historique_du_jour"].as_array().unwrap();
    assert_eq!(lignes.len(), 1, "une course, une ligne");
    let l = &lignes[0];
    assert_eq!(l["avance_unites"], json!(attendu));
    assert_eq!(l["rembourse_unites"], json!(attendu));
    assert_eq!(l["gain_unites"], json!(DEVIS_PART_COURSIER));
    assert_eq!(l["terminee"], json!(true));
    assert_eq!(l["en_attente_reglement"], json!(false));
    // La référence est DÉRIVÉE de l'identifiant, jamais stockée — mais elle
    // doit être là : c'est ce que Yao lit au téléphone à l'agence.
    assert!(
        l["reference"].as_str().is_some_and(|r| r.starts_with('#')),
        "référence lisible attendue, vu {l}",
    );
}

// ── R10 / FR-117 : la commande prépayée ────────────────────────────────────

/// Une commande **prépayée** livrée ne solde PAS l'avance (R10, FR-117).
///
/// Aucun cash n'a changé de main à la livraison : écrire un remboursement
/// ferait disparaître de l'écran un argent que Yao porte toujours. L'avance
/// reste ouverte et **annoncée comme telle** — le remboursement viendra de PAY
/// (tranche T3), pas d'une écriture inventée ici.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_prepayee_laisse_l_avance_ouverte(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    let attendu = avance_attendue(&bac, &course).await;

    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    let caisse = bac.lire_caisse().await;
    assert_eq!(
        caisse["avance_en_cours_unites"],
        json!(attendu),
        "le solde ne ment pas : l'argent est toujours dehors",
    );
    assert_eq!(
        caisse["avances_en_attente_reglement_unites"],
        json!(attendu),
        "et il est ANNONCÉ comme non soldable en espèces",
    );
    assert!(
        bac.ecritures_caisse(bac.coursier)
            .await
            .iter()
            .all(|(t, _)| t == "avance"),
        "aucun remboursement fictif n'est écrit",
    );
    let l = &caisse["historique_du_jour"][0];
    assert_eq!(l["en_attente_reglement"], json!(true));
    assert_eq!(l["rembourse_unites"], json!(0));
}

// ── FR-073 : le livre est immuable ─────────────────────────────────────────

/// Aucune écriture ne se modifie ni ne s'efface (FR-073).
///
/// La garde est une **contrainte de base**, pas une convention de code : une
/// convention se contourne par la prochaine requête écrite à la hâte.
#[sqlx::test(migrations = "../migrations")]
async fn une_ecriture_de_caisse_ne_se_modifie_ni_ne_s_efface(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    let id: Uuid =
        sqlx::query_scalar("SELECT id FROM coursier.ecriture_caisse WHERE coursier_id = $1 LIMIT 1")
            .bind(bac.coursier)
            .fetch_one(&bac.pool)
            .await
            .unwrap();

    let modification = sqlx::query("UPDATE coursier.ecriture_caisse SET montant_unites = 1 WHERE id = $1")
        .bind(id)
        .execute(&bac.pool)
        .await;
    assert!(
        modification.is_err(),
        "un UPDATE doit être REFUSÉ par la base, pas seulement évité par le code",
    );

    let suppression = sqlx::query("DELETE FROM coursier.ecriture_caisse WHERE id = $1")
        .bind(id)
        .execute(&bac.pool)
        .await;
    assert!(suppression.is_err(), "un DELETE doit être REFUSÉ par la base");
}

/// Un lot d'outbox rejoué n'écrit rien de plus.
///
/// Le worker livre **au moins** une fois : sans l'unicité par `evenement_id`,
/// chaque relivraison rembourserait une seconde fois — et le solde deviendrait
/// positif, c'est-à-dire que Mefali devrait de l'argent à personne.
#[sqlx::test(migrations = "../migrations")]
async fn un_lot_d_outbox_rejoue_ne_double_aucune_ecriture(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;

    bac.drainer_caisse().await;
    let apres_un_drain = bac.ecritures_caisse(bac.coursier).await;

    // Deux fois de plus : le worker peut relivrer autant qu'il veut.
    bac.drainer_caisse().await;
    bac.drainer_caisse().await;
    assert_eq!(
        bac.ecritures_caisse(bac.coursier).await,
        apres_un_drain,
        "trois drains, un seul livre",
    );
    assert_eq!(bac.lire_caisse().await["avance_en_cours_unites"], json!(0));
}

// ── FR-078 : l'écart au plafond ────────────────────────────────────────────

/// Une avance en cours au-delà du plafond déclaré est **signalée** (FR-078).
///
/// Un écart n'est jamais normal : il veut dire qu'une course a été acceptée sur
/// un plafond périmé, ou qu'un remboursement manque. Le taire laisserait Yao
/// découvrir le blocage au moment d'accepter la course suivante.
#[sqlx::test(migrations = "../migrations")]
async fn un_ecart_au_plafond_du_jour_est_signale(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let attendu = avance_attendue(&bac, &course).await;

    // Plafond déclaré JUSTE en dessous de ce que la course engage.
    sqlx::query(
        "INSERT INTO dispatch.plafond_jour (coursier_id, jour, plafond_unites, devise)
         VALUES ($1, current_date, $2, 'XOF')",
    )
    .bind(bac.coursier)
    .bind(attendu - 1)
    .execute(&bac.pool)
    .await
    .unwrap();

    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    assert_eq!(
        bac.lire_caisse().await["ecart_plafond"],
        json!(true),
        "l'écart se voit, il ne se tait pas",
    );
}

/// Sous le plafond, aucun signalement — sinon l'alerte deviendrait du bruit.
#[sqlx::test(migrations = "../migrations")]
async fn sous_le_plafond_aucun_ecart_n_est_signale(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let attendu = avance_attendue(&bac, &course).await;

    sqlx::query(
        "INSERT INTO dispatch.plafond_jour (coursier_id, jour, plafond_unites, devise)
         VALUES ($1, current_date, $2, 'XOF')",
    )
    .bind(bac.coursier)
    .bind(attendu + 1_000)
    .execute(&bac.pool)
    .await
    .unwrap();

    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    assert_eq!(bac.lire_caisse().await["ecart_plafond"], json!(false));
}

// ── Garde de propriété et de rôle ──────────────────────────────────────────

/// La caisse d'un coursier n'est **que** la sienne (constitution VIII).
///
/// La garde n'est pas un filtre d'affichage : aucun identifiant n'entre par la
/// requête. Un second coursier lit sa propre caisse, vide — jamais celle du
/// premier.
#[sqlx::test(migrations = "../migrations")]
async fn un_autre_coursier_ne_voit_jamais_la_caisse_du_premier(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    let (statut, corps) = bac.get("/moi/caisse", &bac.jeton_autre_coursier).await;
    assert_eq!(statut, 200);
    assert_eq!(corps["avance_en_cours_unites"], json!(0));
    assert!(corps["historique_du_jour"].as_array().unwrap().is_empty());
}

/// Un compte sans rôle coursier est refusé — rôle **et** propriété.
#[sqlx::test(migrations = "../migrations")]
async fn la_caisse_exige_le_role_coursier(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, _) = bac.get("/moi/caisse", &bac.jeton_client).await;
    assert_eq!(statut, 403);
}

// ── SC-015 : aucun secret n'échappe ────────────────────────────────────────

/// La caisse ne laisse fuir ni code, ni jeton, ni numéro (SC-015, FR-037).
///
/// Elle sert des montants et des références — jamais un secret de remise, même
/// indirectement par une charge utile d'événement `caisse.mouvement`.
#[sqlx::test(migrations = "../migrations")]
async fn la_caisse_ne_sert_aucun_secret(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;
    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    let corps = bac.lire_caisse().await.to_string();
    assert!(!corps.contains(&secrets.code), "le code à 4 chiffres a fui");
    assert!(!corps.contains(&secrets.jeton), "le jeton de réception a fui");
    assert!(!corps.contains("+225"), "un numéro a fui");

    for payload in bac.evenements("caisse.mouvement").await {
        let p = payload.to_string();
        assert!(!p.contains(&secrets.code), "code dans caisse.mouvement");
        assert!(!p.contains(&secrets.jeton), "jeton dans caisse.mouvement");
        assert!(!p.contains("+225"), "numéro dans caisse.mouvement");
    }
}

/// Chaque écriture porte son événement, dans la même transaction (VI).
///
/// Un mouvement d'argent sans son événement serait invisible des métriques ; un
/// événement sans mouvement ferait compter de l'argent qui n'existe pas.
#[sqlx::test(migrations = "../migrations")]
async fn chaque_ecriture_porte_son_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    let ecritures = bac.ecritures_caisse(bac.coursier).await.len() as i64;
    assert_eq!(
        bac.nb_evenements("caisse.mouvement").await,
        ecritures,
        "autant d'événements que d'écritures, ni plus ni moins",
    );
}

// ── T077 / FR-092 : le jour civil de la zone ───────────────────────────────

/// L'historique est borné au **jour civil de la zone** (FR-092, SC-013).
///
/// Une écriture d'hier ne remonte pas dans la journée d'aujourd'hui : les gains
/// repartent de zéro, sans report. Le **livre**, lui, n'oublie rien — et une
/// avance d'hier restée ouverte compte toujours dans le solde, parce que
/// l'argent, lui, n'a pas changé de jour.
///
/// ⚠ L'écriture d'hier est **insérée** telle quelle : la reculer par `UPDATE`
/// est impossible, et c'est voulu — le trigger d'immuabilité le refuse
/// (FR-073, prouvé par le test précédent).
#[sqlx::test(migrations = "../migrations")]
async fn l_historique_ne_remonte_pas_la_journee_d_hier(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;
    assert_eq!(
        bac.lire_caisse().await["historique_du_jour"]
            .as_array()
            .unwrap()
            .len(),
        1,
        "la course du jour est bien là",
    );

    // Une course d'HIER : mêmes commande et livraison, écritures datées de la
    // veille — le rapprochement avance ↔ remboursement reste vrai, seul le jour
    // change.
    for (type_ecriture, montant) in [("avance", -4_000_i64), ("remboursement", 4_000)] {
        sqlx::query(
            "INSERT INTO coursier.ecriture_caisse
                 (id, coursier_id, type, montant_unites, devise, commande_id,
                  livraison_id, ecrit_le)
             VALUES ($1, $2, $3::text::coursier.type_ecriture, $4, 'XOF', $5, $6,
                     now() - interval '1 day')",
        )
        .bind(Uuid::now_v7())
        .bind(bac.coursier)
        .bind(type_ecriture)
        .bind(montant)
        .bind(course.commande)
        .bind(course.livraison)
        .execute(&bac.pool)
        .await
        .unwrap();
    }

    let caisse = bac.lire_caisse().await;
    assert_eq!(
        caisse["historique_du_jour"].as_array().unwrap().len(),
        1,
        "toujours UNE ligne : la journée d'hier ne remonte pas ({caisse})",
    );
    assert_eq!(
        bac.ecritures_caisse(bac.coursier).await.len(),
        6,
        "le livre, lui, garde tout : 3 avances + 1 remboursement + les 2 d'hier",
    );
}

// ── SC-011 : l'indemnisation, de la demande à la validation ────────────────

/// Une indemnisation naît **demandée** de l'arbre des échecs (FR-071).
///
/// Le cycle 008 émettait déjà `indemnisation.due` sans consommateur : c'est ce
/// contrat qui est enfin honoré.
///
/// L'issue choisie est **le faux billet** (§7.5-6) : le client est parti avec la
/// marchandise, le coursier avec du papier — le cas où « le coursier ne perd
/// jamais » se joue vraiment. Un `refus_non_perissable` ne serait pas
/// indemnisable (tout se retourne au vendeur, personne n'est lésé).
#[sqlx::test(migrations = "../migrations")]
async fn un_echec_indemnisable_fait_naitre_une_indemnisation_demandee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.arriver_chez_le_client(&course).await;
    bac.reunir_les_trois_preuves(course.livraison).await;

    let (statut, corps) = bac
        .post(
            &format!("/courses/{}/echec", course.livraison),
            &bac.jeton_coursier,
            json!({
                "uuid_client": Uuid::now_v7(),
                "type_issue": "faux_billet",
                "motif_cle": "echec.faux_billet",
            }),
        )
        .await;
    assert_eq!(statut, 200, "déclaration d'échec refusée : {corps}");

    bac.drainer_caisse().await;

    let caisse = bac.lire_caisse().await;
    let indemnisations = caisse["indemnisations"].as_array().unwrap();
    assert_eq!(indemnisations.len(), 1, "une indemnisation attendue : {caisse}");
    assert_eq!(indemnisations[0]["etat"], json!("demandee"));
    assert!(
        indemnisations[0]["montant_unites"].as_i64().unwrap() > 0,
        "une indemnisation à zéro ne serait pas une indemnisation",
    );
    // AVI-04 n'est pas construit : le litige reste vide, il n'est pas inventé.
    assert_eq!(indemnisations[0]["litige_id"], Value::Null);
}

// ── US6 (T074) : `GET /moi/journee`, composé dans le handler ────────────────
//
// Le bandeau de K1 mélange deux domaines : les gains et les avances viennent de
// `coursier`, le plafond retenu et le taux d'acceptation de `dispatch`. Aucune
// arête ne relie les deux crates (contrat §2) — la composition se fait dans le
// handler, et c'est **ici** qu'elle s'exerce : un test de crate ne peut pas la
// voir, par construction.

/// SC-013 — le bandeau égale la somme des parts coursier des courses livrées,
/// **au franc près**.
#[sqlx::test(migrations = "../migrations")]
async fn la_journee_somme_les_parts_coursier_des_courses_livrees(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // Avant la première course : rien, mais un plafond déjà lisible — sinon
    // K1 n'aurait rien à afficher à un coursier qui prend son service.
    let (statut, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(statut, 200, "journée refusée : {j}");
    assert_eq!(j["courses_livrees"], json!(0));
    assert_eq!(j["gains_unites"], json!(0));
    assert_eq!(j["plafond_retenu_unites"], json!(PALIER_AVANCE));
    assert_eq!(j["reste_disponible_unites"], json!(PALIER_AVANCE));
    assert_eq!(j["devise"], json!("XOF"));

    for _ in 0..2 {
        let course = bac.course_prete().await;
        bac.collecter_tout(&course).await;
        confirmer_remise(&bac, &course).await;
    }
    bac.drainer_caisse().await;

    let (_, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(j["courses_livrees"], json!(2));
    assert_eq!(
        j["gains_unites"],
        json!(2 * DEVIS_PART_COURSIER),
        "la part coursier vient du devis FIGÉ, jamais d'un recalcul",
    );
    // Les deux courses sont encaissées : plus rien dehors.
    assert_eq!(j["avances_en_cours_unites"], json!(0));
    assert_eq!(j["reste_disponible_unites"], json!(PALIER_AVANCE));
}

/// FR-095 — le « reste disponible » diminue d'exactement ce qui est engagé.
///
/// C'est ce nombre qui dit à Yao s'il peut accepter la course suivante. Le
/// laisser à sa valeur nominale pendant qu'une avance court lui ferait accepter
/// une course qu'il ne peut pas payer.
#[sqlx::test(migrations = "../migrations")]
async fn le_reste_disponible_diminue_de_l_avance_engagee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let avance = avance_attendue(&bac, &course).await;

    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    let (_, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(j["avances_en_cours_unites"], json!(avance));
    assert_eq!(
        j["reste_disponible_unites"],
        json!(PALIER_AVANCE - avance),
        "plafond retenu MOINS ce qui est déjà dehors",
    );
    // Pas encore livrée : aucun gain compté. Un gain compté à la collecte
    // paierait Yao pour une course qu'il n'a pas finie.
    assert_eq!(j["courses_livrees"], json!(0));
    assert_eq!(j["gains_unites"], json!(0));
}

/// Le reste disponible ne descend **jamais** sous zéro.
///
/// Un « reste » négatif ne veut rien dire à l'écran. L'écart, lui, n'est pas
/// tu : la caisse le signale comme incident (FR-078), et c'est le bon endroit.
#[sqlx::test(migrations = "../migrations")]
async fn le_reste_disponible_ne_descend_jamais_sous_zero(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let avance = avance_attendue(&bac, &course).await;

    // Plafond déclaré SOUS l'avance engagée — la situation d'incident.
    sqlx::query(
        "INSERT INTO dispatch.plafond_jour (coursier_id, jour, plafond_unites, devise)
         VALUES ($1, current_date, $2, 'XOF')",
    )
    .bind(bac.coursier)
    .bind(avance - 500)
    .execute(&bac.pool)
    .await
    .unwrap();

    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    let (_, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(j["reste_disponible_unites"], json!(0));
    assert_eq!(
        bac.lire_caisse().await["ecart_plafond"],
        json!(true),
        "l'écart est signalé là où il a un sens",
    );
}

/// FR-094 — **aucune note** tant qu'AVI n'existe pas, et un taux d'acceptation
/// `null` tant qu'aucune offre décidable n'a été émise.
///
/// Le cycle 009 avait tranché : l'absence vaut mieux qu'un chiffre inventé. Un
/// `0 %` ferait croire à Yao qu'il refuse tout, alors qu'on ne lui a encore
/// rien proposé.
#[sqlx::test(migrations = "../migrations")]
async fn ni_note_inventee_ni_taux_par_defaut(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(j["note_centiemes"], Value::Null);
    assert_eq!(j["taux_acceptation_pourcent"], Value::Null);
}

/// FR-092 — les gains repartent de zéro au changement de jour civil.
#[sqlx::test(migrations = "../migrations")]
async fn les_gains_ne_reportent_pas_d_un_jour_sur_l_autre(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    let (_, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(j["courses_livrees"], json!(1));

    // La remise recule d'un jour : c'est `livree_le` qui borne les gains.
    sqlx::query("UPDATE commandes.livraison SET livree_le = livree_le - interval '1 day'")
        .execute(&bac.pool)
        .await
        .unwrap();

    let (_, j) = bac.get("/moi/journee", &bac.jeton_coursier).await;
    assert_eq!(j["courses_livrees"], json!(0), "sans report : {j}");
    assert_eq!(j["gains_unites"], json!(0));
}

/// La journée est sous rôle coursier, comme la caisse.
#[sqlx::test(migrations = "../migrations")]
async fn la_journee_exige_le_role_coursier(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, _) = bac.get("/moi/journee", &bac.jeton_client).await;
    assert_eq!(statut, 403);
}
