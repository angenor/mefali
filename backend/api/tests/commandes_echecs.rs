//! US9 (CMD-08) — l'arbre §7.5, ligne par ligne, et la remise.
//!
//! **SC-003** : un test par ligne du tableau du cadrage §7.5. Chacun assert
//! l'issue, **le détenteur de l'argent**, **le détenteur de la marchandise** et
//! les événements émis. Les deux détenteurs sont des axes INDÉPENDANTS
//! (research R14) : le coursier peut garder les courses pendant que Mefali
//! porte la dette, et un modèle à une seule colonne serait faux.
//!
//! Le tableau compte 10 lignes ; le refus de reprise du vendeur en est la
//! sous-branche que CMD-08 nomme explicitement — d'où **11 cas pour 10 lignes**.
//!
//! La table de décision elle-même est testée sans base dans
//! `commandes::echec` ; ici, c'est le chemin RÉEL qui est exercé — preuves,
//! écritures, événements, sanctions et transitions comprises.

mod bac_commandes;

use bac_commandes::{Bac, Course, DEVIS_PART_COURSIER};
use commandes::RestrictionsCompte;
use serde_json::{json, Value};
use uuid::Uuid;

/// Une course prête à échouer : arrêts collectés, course en livraison, preuves
/// réunies (le double `PreuvesFixes` tient le rôle de CRS-05).
async fn course_en_livraison(bac: &Bac, categorie: &str) -> Course {
    course_en_livraison_mode(bac, categorie, "cash").await
}

/// Variante avec le mode de paiement — nécessaire dès qu'un compte porte
/// `prepaiement_impose` : le cash lui est alors REFUSÉ, ce qui est justement
/// l'effet recherché de la sanction (FR-025).
async fn course_en_livraison_mode(bac: &Bac, categorie: &str, mode: &str) -> Course {
    let lignes = if categorie == "restauration" {
        vec![bac.resto.ligne(1)]
    } else {
        bac.vendeurs.iter().map(|v| v.ligne(1)).collect()
    };
    let commande = bac.creer_commande_mode(categorie, lignes, mode).await;
    if mode == "mobile_money" {
        // Rien ne part avant le règlement : le prépaiement doit être confirmé
        // pour que la commande redevienne dispatchable.
        bac.commandes
            .confirmer_prepaiement(commande, chrono::Utc::now())
            .await
            .unwrap();
    }
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, remise) = bac.arrets_de(livraison).await;
    for arret in &collectes {
        bac.collecter(*arret).await;
    }
    bac.preuves.definir(livraison, true);
    Course {
        commande,
        livraison,
        collectes,
        remise,
    }
}

/// `POST /courses/{livraison}/echec`.
async fn declarer_echec(bac: &Bac, course: &Course, type_issue: &str) -> (u16, Value) {
    bac.post(
        &format!("/courses/{}/echec", course.livraison),
        &bac.jeton_coursier,
        json!({
            "type_issue": type_issue,
            "motif_cle": "echec.motif.client_injoignable",
        }),
    )
    .await
}

/// L'issue écrite en base — la vérité, pas seulement la réponse HTTP.
async fn issue_en_base(bac: &Bac, commande: Uuid) -> (String, String, String, bool, bool, String) {
    sqlx::query_as(
        "SELECT type_issue::text, detenteur_argent::text, detenteur_marchandise::text,
                litige_ouvert, indemnisation_due, sanction::text
         FROM commandes.issue_echec WHERE commande_id = $1 ORDER BY cree_le DESC LIMIT 1",
    )
    .bind(commande)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

// ── SC-003 — les 11 cas du tableau §7.5 ───────────────────────────────────

/// §7.5-1 — client refuse, marchandise NON périssable : retour au vendeur.
/// Personne n'est lésé : ni litige, ni indemnisation.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_1_refus_non_perissable(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "refus_non_perissable").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "vendeur");
    assert_eq!(corps["detenteur_marchandise"], "vendeur");
    assert_eq!(corps["litige_ouvert"], false);
    assert_eq!(corps["indemnisation_due"], false);
    assert_eq!(corps["sanction"], "aucune");

    let (_, argent, marchandise, litige, indemn, sanction) =
        issue_en_base(&bac, course.commande).await;
    assert_eq!((argent.as_str(), marchandise.as_str()), ("vendeur", "vendeur"));
    assert!(!litige && !indemn);
    assert_eq!(sanction, "aucune");

    assert_eq!(bac.nb_evenements("echec.issue_enregistree").await, 1);
    assert_eq!(bac.nb_evenements("litige.ouvert").await, 0);
    assert_eq!(bac.nb_evenements("indemnisation.due").await, 0);
    // Les deux niveaux passent ÉCHOUÉ.
    assert_eq!(bac.etat_commande(course.commande).await, "echouee");
    assert_eq!(bac.etat_livraison(course.livraison).await, "echouee");
}

/// §7.5-2 — le vendeur refuse la reprise : le coursier garde ce qu'il a PAYÉ.
/// Mefali porte la dette, tout de suite.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_2_refus_reprise_vendeur(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "refus_reprise_vendeur").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "mefali");
    assert_eq!(corps["detenteur_marchandise"], "coursier");
    assert_eq!(corps["litige_ouvert"], true);
    assert_eq!(corps["indemnisation_due"], true);

    assert_eq!(bac.nb_evenements("litige.ouvert").await, 1);
    let indemnisations = bac.evenements("indemnisation.due").await;
    assert_eq!(indemnisations.len(), 1);
    // Ce qu'il a avancé chez les vendeurs PLUS sa course : il a payé, et il a
    // roulé. Les deux lui sont dus.
    let montant = indemnisations[0]["montant"].as_i64().unwrap();
    assert!(
        montant > DEVIS_PART_COURSIER,
        "l'indemnisation couvre l'avance ET la part de devis",
    );
    assert_eq!(indemnisations[0]["coursier"], bac.coursier.to_string());
}

/// §7.5-3 — PÉRISSABLE : rien ne se retourne. Indemnisation ET sanction client.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_3_refus_perissable_sanctionne(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "restauration").await;

    let (statut, corps) = declarer_echec(&bac, &course, "refus_perissable").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "mefali");
    assert_eq!(corps["detenteur_marchandise"], "coursier");
    assert_eq!(
        corps["sanction"], "prepaiement_impose",
        "1ᵉʳ refus périssable → prépaiement imposé",
    );

    // La sanction est posée par le crate `comptes`, via le port (P3, R12).
    let posees = bac.restrictions.posees();
    assert_eq!(posees.len(), 1);
    assert_eq!(posees[0].0, bac.client);
    assert!(bac.restrictions.restrictions(bac.client).await.unwrap().prepaiement_impose);
}

/// §7.5-3 (suite) — **2ᵉ refus périssable → compte BLOQUÉ**. Le rang se lit des
/// restrictions déjà posées, il ne se compte pas à part.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_3_second_refus_bloque_le_compte(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let premiere = course_en_livraison(&bac, "restauration").await;
    let (_, corps) = declarer_echec(&bac, &premiere, "refus_perissable").await;
    assert_eq!(corps["sanction"], "prepaiement_impose");

    // La sanction MORD immédiatement : le cash est refusé au compte sanctionné
    // (FR-025). C'est la démonstration que `prepaiement_impose` n'est pas une
    // simple étiquette — il change ce que le client peut faire.
    let (statut, corps) = bac
        .post_creation("restauration", vec![bac.resto.ligne(1)], "cash")
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "cash_indisponible");

    let seconde = course_en_livraison_mode(&bac, "restauration", "mobile_money").await;
    let (statut, corps) = declarer_echec(&bac, &seconde, "refus_perissable").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["sanction"], "bloque", "2ᵉ refus → compte bloqué");

    assert!(bac.restrictions.restrictions(bac.client).await.unwrap().bloque);
    let sanctions = bac.evenements("sanction.posee").await;
    assert_eq!(sanctions.len(), 0, "le double n'écrit pas dans l'outbox");
    assert_eq!(bac.restrictions.posees().len(), 2);
}

/// §7.5-4 — contestation du montant : **aucune négociation**, l'issue suit la
/// NATURE de la marchandise. Deux commandes, deux natures, deux issues.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_4_contestation_suit_la_nature(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let courses = course_en_livraison(&bac, "marche").await;
    let (_, corps) = declarer_echec(&bac, &courses, "contestation_montant").await;
    assert_eq!(corps["detenteur_argent"], "vendeur");
    assert_eq!(corps["sanction"], "aucune");

    let resto = course_en_livraison(&bac, "restauration").await;
    let (_, corps) = declarer_echec(&bac, &resto, "contestation_montant").await;
    assert_eq!(
        corps["detenteur_argent"], "mefali",
        "un plat chaud contesté suit les règles du périssable",
    );
    assert_eq!(corps["sanction"], "prepaiement_impose");
}

/// §7.5-5 — sans appoint : mobile money de la TOTALITÉ, sinon refus. Aucun
/// paiement partiel n'existe, donc l'issue est celle du refus.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_5_sans_appoint(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "sans_appoint").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "vendeur");
    assert_eq!(corps["detenteur_marchandise"], "vendeur");

    // SC-005 — aucun règlement fractionné n'a pu être écrit : le total reste
    // l'unique montant, et la commande est ÉCHOUÉE, pas « partiellement payée ».
    let paiement: String =
        sqlx::query_scalar("SELECT etat_paiement::text FROM commandes.commande WHERE id = $1")
            .bind(course.commande)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(paiement, "du", "ni réglé, ni fractionné : dû");
}

/// §7.5-6 — faux billet : le client est parti avec la marchandise, le coursier
/// avec du papier. **Les deux détenteurs diffèrent** — la preuve que le modèle
/// à deux axes était nécessaire.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_6_faux_billet(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "faux_billet").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "mefali");
    assert_eq!(corps["detenteur_marchandise"], "client");
    assert_ne!(
        corps["detenteur_argent"], corps["detenteur_marchandise"],
        "R14 — les deux axes sont INDÉPENDANTS",
    );
    assert_eq!(corps["indemnisation_due"], true);
}

/// §7.5-7 — non-conformité : faute VENDEUR, reprise et remboursement.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_7_non_conformite(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "non_conformite").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "vendeur");
    assert_eq!(corps["detenteur_marchandise"], "vendeur");
    assert_eq!(corps["litige_ouvert"], true, "le litige est contre le VENDEUR");
    assert_eq!(
        corps["indemnisation_due"], false,
        "le coursier n'a rien perdu : c'est le vendeur qui reprend",
    );
}

/// §7.5-8 — casse en transport : franchise coursier + fonds d'incidents.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_8_casse_transport(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "casse_transport").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "mefali");
    assert_eq!(
        corps["detenteur_marchandise"], "coursier",
        "cassée, mais chez lui",
    );
    assert_eq!(corps["indemnisation_due"], true);
}

/// §7.5-9 — annulation après achat : mêmes règles que le refus.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_9_annulation_apres_achat(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "restauration").await;

    let (statut, corps) = declarer_echec(&bac, &course, "annulation_apres_achat").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "mefali");
    assert_eq!(corps["detenteur_marchandise"], "coursier");
    assert_eq!(corps["indemnisation_due"], true);
}

/// §7.5-10 — client injoignable ET vendeur fermé : **consigne** et
/// **re-livraison** sous forme de commande LIÉE, portant son propre devis.
#[sqlx::test(migrations = "../migrations")]
async fn ligne_10_consigne_et_relivraison_liee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "vendeur_ferme_consigne").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_marchandise"], "consigne");
    assert_eq!(corps["detenteur_argent"], "mefali");

    let relivraison: Uuid = corps["relivraison_id"].as_str().unwrap().parse().unwrap();
    let (liee_a, etat, livraisons): (Option<Uuid>, String, i64) = sqlx::query_as(
        "SELECT c.relivraison_de, c.etat::text,
                (SELECT count(*) FROM commandes.livraison l WHERE l.commande_id = c.id)
         FROM commandes.commande c WHERE c.id = $1",
    )
    .bind(relivraison)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(liee_a, Some(course.commande), "commande LIÉE à l'originale");
    assert_eq!(etat, "nouvelle", "elle repart au début du cycle");
    assert_eq!(
        livraisons, 0,
        "aucune livraison : son devis sera évalué à sa planification, sur sa \
         géométrie réelle — le départ est la consigne, plus les vendeurs",
    );
    // Un SECOND segment aurait partagé le devis de la première course : la
    // re-livraison est un déplacement de PLUS, à facturer comme tel.
    let segments: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM commandes.segment s
         JOIN commandes.livraison l ON l.id = s.livraison_id
         WHERE l.commande_id = $1",
    )
    .bind(course.commande)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(segments, 1, "jamais un second segment (CMD-09 hors périmètre)");
}

/// §7.5-11 — suspicion de faux refus : l'indemnisation est CONDITIONNÉE aux
/// preuves. « Le coursier ne perd jamais » ne veut pas dire « on paie sans
/// regarder ».
#[sqlx::test(migrations = "../migrations")]
async fn ligne_11_suspicion_faux_refus(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = declarer_echec(&bac, &course, "suspicion_faux_refus").await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_marchandise"], "coursier");
    assert_eq!(corps["litige_ouvert"], true);
    // Les preuves sont réunies (le double les a posées) : l'indemnisation suit.
    assert_eq!(corps["indemnisation_due"], true);
    assert_eq!(corps["detenteur_argent"], "mefali");
}

// ── T062 — refus sans preuves, remise, code épuisé ────────────────────────

/// **FR-056** — un échec déclaré SANS PREUVES est refusé. C'est ce qui empêche
/// la promesse « le coursier ne perd jamais » de devenir une invitation.
#[sqlx::test(migrations = "../migrations")]
async fn echec_sans_preuves_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;
    // `PreuvesFixes` refuse par DÉFAUT : on lui retire ce que la fixture avait
    // posé, exactement comme un coursier qui n'a ni appelé ni photographié.
    bac.preuves.definir(course.livraison, false);

    let (statut, corps) = declarer_echec(&bac, &course, "refus_non_perissable").await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "preuves_incompletes");

    // RIEN n'a été écrit : ni issue, ni événement, ni transition.
    let issues: i64 = sqlx::query_scalar("SELECT count(*) FROM commandes.issue_echec")
        .fetch_one(&bac.pool)
        .await
        .unwrap();
    assert_eq!(issues, 0);
    assert_eq!(bac.nb_evenements("echec.issue_enregistree").await, 0);
    assert_eq!(bac.etat_commande(course.commande).await, "en_cours");
}

/// La remise par **QR**, par **code**, et en **dépôt** — les trois modes du
/// contrat §2, chacun clôturant la course.
#[sqlx::test(migrations = "../migrations")]
async fn remise_par_qr_par_code_et_en_depot(pool: sqlx::PgPool) {
    // UN bac, trois courses : chaque `#[sqlx::test]` n'a qu'une base, et deux
    // bacs sur la même base se disputeraient les slugs de catégorie.
    let bac = Bac::nouveau(pool).await;
    for (rang, (mode, cle)) in [("qr", "jeton"), ("code", "code"), ("depot", "photo_cle")]
        .into_iter()
        .enumerate()
    {
        let course = course_en_livraison(&bac, "marche").await;

        // Le client seul connaît ses secrets ; le test les relit comme lui.
        let (code, jeton): (String, String) = sqlx::query_as(
            "SELECT code_livraison, jeton_reception FROM commandes.commande WHERE id = $1",
        )
        .bind(course.commande)
        .fetch_one(&bac.pool)
        .await
        .unwrap();

        let valeur = match cle {
            "jeton" => jeton,
            "code" => code,
            _ => "commandes/depots/photo".to_owned(),
        };
        let (statut, corps) = bac
            .post(
                &format!("/courses/{}/remise", course.livraison),
                &bac.jeton_coursier,
                json!({ "mode": mode, cle: valeur }),
            )
            .await;
        assert_eq!(statut, 200, "mode {mode} : {corps}");
        assert_eq!(corps["mode_remise"], mode);

        assert_eq!(bac.etat_livraison(course.livraison).await, "livree");
        assert_eq!(bac.etat_commande(course.commande).await, "terminee");
        let paiement: String = sqlx::query_scalar(
            "SELECT etat_paiement::text FROM commandes.commande WHERE id = $1",
        )
        .bind(course.commande)
        .fetch_one(&bac.pool)
        .await
        .unwrap();
        assert_eq!(paiement, "regle", "un seul montant, encaissé en une fois");
        // Une remise de plus à chaque tour : les trois modes closent bien.
        assert_eq!(bac.nb_evenements("livraison.livree").await, rang as i64 + 1);
        assert_eq!(bac.nb_evenements("commande.terminee").await, rang as i64 + 1);
    }
}

/// **Trois codes faux → verrouillage** (`423`). Quatre chiffres se devinent en
/// quelques minutes sans plafond ; avec lui, la fenêtre se referme avant.
#[sqlx::test(migrations = "../migrations")]
async fn trois_codes_faux_verrouillent_la_remise(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;
    let uri = format!("/courses/{}/remise", course.livraison);

    // Deux erreurs : refusées, mais la porte reste ouverte.
    for essai in 1..=2 {
        let (statut, corps) = bac
            .post(&uri, &bac.jeton_coursier, json!({ "mode": "code", "code": "0000" }))
            .await;
        assert_eq!(statut, 409, "essai {essai} : {corps}");
        assert_eq!(corps["code"], "remise_incorrecte");
    }

    // La troisième VERROUILLE.
    let (statut, corps) = bac
        .post(&uri, &bac.jeton_coursier, json!({ "mode": "code", "code": "0000" }))
        .await;
    assert_eq!(statut, 423, "{corps}");
    assert_eq!(corps["code"], "code_epuise");

    // Le verrou ALERTE : une commande bloquée à la porte du client exige un
    // humain, et un humain ne s'abonne pas à un `tracing::warn!`. L'événement
    // ne porte JAMAIS le code — le publier le sortirait du seul canal qui doit
    // le porter (R6).
    let alerte: serde_json::Value = sqlx::query_scalar(
        "SELECT payload FROM outbox.evenement
         WHERE type_evenement = 'remise.code_epuise' AND entite_id = $1",
    )
    .bind(course.commande)
    .fetch_one(&bac.pool)
    .await
    .expect("l'épuisement du code doit émettre remise.code_epuise");
    assert_eq!(alerte["essais"], 3);
    assert_eq!(alerte["livraison"], json!(course.livraison));
    assert!(
        !alerte.to_string().contains("code_livraison"),
        "aucun code de remise dans un événement : {alerte}"
    );

    // Et le BON code ne rouvre pas la porte : seule une intervention admin le
    // peut. Sinon le plafond ne protégerait de rien.
    let vrai_code: String =
        sqlx::query_scalar("SELECT code_livraison FROM commandes.commande WHERE id = $1")
            .bind(course.commande)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    let (statut, _) = bac
        .post(
            &uri,
            &bac.jeton_coursier,
            json!({ "mode": "code", "code": vrai_code }),
        )
        .await;
    assert_eq!(statut, 423);
    assert_eq!(bac.etat_commande(course.commande).await, "en_cours");
}

/// Le QR ne se devine pas : un jeton faux est refusé **sans** consommer
/// d'essai de code — les deux compteurs n'ont pas la même raison d'être.
#[sqlx::test(migrations = "../migrations")]
async fn un_jeton_faux_ne_consomme_pas_d_essai_de_code(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    for _ in 0..5 {
        let (statut, _) = bac
            .post(
                &format!("/courses/{}/remise", course.livraison),
                &bac.jeton_coursier,
                json!({ "mode": "qr", "jeton": "jeton-invente" }),
            )
            .await;
        assert_eq!(statut, 409);
    }
    let essais: i16 = sqlx::query_scalar("SELECT essais_code FROM commandes.commande WHERE id = $1")
        .bind(course.commande)
        .fetch_one(&bac.pool)
        .await
        .unwrap();
    assert_eq!(essais, 0, "le plafond protège le CODE, pas le jeton");
}

/// `litige.ouvert` et `indemnisation.due` sont émis **sans consommateur** ce
/// cycle : ce sont les contrats qu'AVI-04 et CRS-06 brancheront sans toucher
/// à CMD. Ce test vérifie leur FORME, puisque rien ne les lit encore.
#[sqlx::test(migrations = "../migrations")]
async fn les_contrats_sans_consommateur_portent_leur_charge(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;
    declarer_echec(&bac, &course, "casse_transport").await;

    let litiges = bac.evenements("litige.ouvert").await;
    assert_eq!(litiges.len(), 1);
    assert_eq!(litiges[0]["commande"], course.commande.to_string());
    assert_eq!(litiges[0]["type_issue"], "casse_transport");

    let indemnisations = bac.evenements("indemnisation.due").await;
    assert_eq!(indemnisations.len(), 1);
    assert_eq!(indemnisations[0]["coursier"], bac.coursier.to_string());
    assert_eq!(indemnisations[0]["devise"], "XOF");
    assert!(indemnisations[0]["montant"].as_i64().unwrap() > 0);

    // Minimisation ARTCI : aucune coordonnée brute dans les payloads.
    for payload in [&litiges[0], &indemnisations[0]] {
        let texte = payload.to_string();
        assert!(!texte.contains("lat"), "aucune coordonnée : {texte}");
        assert!(!texte.contains("lon"), "aucune coordonnée : {texte}");
    }
}

/// La surface ADMIN enregistre la MÊME issue que la surface coursier : ce que
/// le support tranche au téléphone doit produire exactement les mêmes deux
/// détenteurs qu'une déclaration terrain.
#[sqlx::test(migrations = "../migrations")]
async fn l_admin_enregistre_la_meme_issue(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_en_livraison(&bac, "marche").await;

    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/issues", course.commande),
            &bac.jeton_admin,
            json!({
                "type_issue": "refus_reprise_vendeur",
                "motif_cle": "echec.motif.vendeur_refuse",
            }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["detenteur_argent"], "mefali");
    assert_eq!(corps["detenteur_marchandise"], "coursier");

    // Et un client n'y a pas accès.
    let (statut, _) = bac
        .post(
            &format!("/admin/commandes/{}/issues", course.commande),
            &bac.jeton_client,
            json!({ "type_issue": "faux_billet", "motif_cle": "x" }),
        )
        .await;
    assert_eq!(statut, 403);
}
