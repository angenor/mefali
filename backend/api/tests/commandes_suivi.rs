//! US6 (CMD-05) — suivre sa commande, en langage clair.
//!
//! Quatre exigences, chacune parce qu'elle a une conséquence visible :
//!
//! - la **progression** compte les collectes et rien d'autre : « 2 sur 3 »,
//!   jamais « 2 sur 4 » — un client qui voit un arrêt de plus croit qu'on lui
//!   cache une course (P1) ;
//! - la **position** vient toujours avec son ÂGE, et son absence n'est jamais
//!   une erreur : un Redis coupé ne doit pas casser un suivi (research R13) ;
//! - l'état est une **clé i18n**, jamais une phrase (constitution VII) ;
//! - la **propriété** est vérifiée : le code de remise ne sort que pour son
//!   propriétaire (research R6).

mod bac_commandes;

use bac_commandes::Bac;
use commandes::PositionDatee;
use serde_json::json;
use uuid::Uuid;

/// Progression correcte : la remise n'est JAMAIS comptée comme une collecte, et
/// l'arrêt courant porte le nom du vendeur.
#[sqlx::test(migrations = "../migrations")]
async fn progression_par_arret_sans_compter_la_remise(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["etat"], "en_cours");
    assert_eq!(corps["etat_cle"], "suivi.etat.collecte_en_cours");
    assert_eq!(corps["progression"]["collectes_faites"], 0);
    assert_eq!(
        corps["progression"]["collectes_total"], 3,
        "3 collectes — l'arrêt de remise n'en est pas une",
    );
    // L'arrêt courant est nommé : « chez Étal Adjoua », pas « arrêt n° 1 ».
    let nom = corps["progression"]["arret_courant"]["prestataire_nom"]
        .as_str()
        .expect("le vendeur de l'arrêt courant est nommé");
    assert!(bac.vendeurs.iter().any(|v| v.nom == nom), "nom inconnu : {nom}");

    // Deux collectes faites → « 2 sur 3 ».
    bac.collecter(course.collectes[0]).await;
    bac.collecter(course.collectes[1]).await;
    let (_, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(corps["progression"]["collectes_faites"], 2);
    assert_eq!(corps["progression"]["collectes_total"], 3);

    // Tout collecté → la course part vers le client, l'état change de mot.
    bac.collecter(course.collectes[2]).await;
    let (_, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(corps["progression"]["collectes_faites"], 3);
    assert_eq!(corps["etat_cle"], "suivi.etat.en_route_vers_vous");
    assert_eq!(
        corps["progression"]["arret_courant"]["prestataire_nom"],
        serde_json::Value::Null,
        "l'arrêt courant est la REMISE : elle n'a pas de vendeur",
    );
}

/// Un arrêt INDISPONIBLE est compté comme résolu : la barre de progression ne
/// reste pas bloquée parce qu'un étal a fermé (FR-018).
#[sqlx::test(migrations = "../migrations")]
async fn un_arret_indisponible_compte_comme_resolu(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    bac.collecter(course.collectes[0]).await;
    bac.action_coursier(course.livraison, course.collectes[1], "indisponible", Uuid::now_v7())
        .await;

    let (_, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(
        corps["progression"]["collectes_faites"], 2,
        "l'étal fermé est RÉSOLU : la progression avance quand même",
    );
    assert_eq!(corps["progression"]["collectes_total"], 3);
}

/// La position vient **avec son âge** — sans lui, l'app afficherait une
/// position vieille de dix minutes comme si elle était vraie.
#[sqlx::test(migrations = "../migrations")]
async fn position_servie_avec_son_age(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    bac.positions.definir(
        bac.coursier,
        PositionDatee {
            lat: 5.899,
            lon: -4.821,
            releve_le: chrono::Utc::now(),
            age_s: 12,
        },
    );

    let (_, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(corps["position"]["age_s"], 12);
    assert_eq!(corps["position"]["lat"], 5.899);
    assert_eq!(corps["coursier"]["id"], bac.coursier.to_string());
    assert_eq!(corps["coursier"]["appel_possible"], true);
    // Rien n'est inventé : ni prénom (CPT n'en stocke pas), ni note (AVI
    // n'existe pas). Un champ vide est plus honnête qu'un champ faux.
    assert!(corps["coursier"]["prenom"].is_null());
    assert!(corps["coursier"]["note"].is_null());
}

/// **Absence de position → champ nul, jamais une erreur** (research R13) : un
/// Redis coupé ne doit pas casser un suivi.
#[sqlx::test(migrations = "../migrations")]
async fn absence_de_position_ne_casse_pas_le_suivi(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    // Aucun `definir` : le double n'a aucune position, comme un TTL expiré.

    let (statut, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(statut, 200, "un suivi sans position reste un suivi");
    assert!(corps["position"].is_null());
    assert_eq!(corps["progression"]["collectes_total"], 3);

    // Retirer une position déjà posée revient au même (expiration du TTL).
    bac.positions.definir(
        bac.coursier,
        PositionDatee {
            lat: 5.899,
            lon: -4.821,
            releve_le: chrono::Utc::now(),
            age_s: 5,
        },
    );
    bac.positions.retirer(bac.coursier);
    let (statut, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(statut, 200);
    assert!(corps["position"].is_null());
}

/// Le code et le QR de remise ne sortent que pour le **propriétaire** : un
/// autre compte ne distingue même pas la commande d'une commande inexistante.
#[sqlx::test(migrations = "../migrations")]
async fn secrets_de_remise_reserves_au_proprietaire(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_client)
        .await;
    assert_eq!(statut, 200);
    let code = corps["remise"]["code_livraison"].as_str().unwrap();
    assert_eq!(code.len(), 4, "code à 4 chiffres");
    assert!(code.chars().all(|c| c.is_ascii_digit()));
    assert!(!corps["remise"]["jeton_reception"].as_str().unwrap().is_empty());

    // L'intrus ne voit RIEN — 404, pas 403 : un identifiant deviné ne doit pas
    // devenir un oracle d'existence.
    let (statut, corps) = bac
        .get(&format!("/commandes/{}", course.commande), &bac.jeton_intrus)
        .await;
    assert_eq!(statut, 404, "{corps}");
    assert_eq!(corps["code"], "commande_inconnue");
    assert!(
        !corps.to_string().contains(code),
        "aucun secret ne fuit dans un refus",
    );
}

/// `GET /moi/commandes` — les commandes du compte, les plus récentes d'abord,
/// et **celles-là seulement**.
#[sqlx::test(migrations = "../migrations")]
async fn mes_commandes_les_plus_recentes_d_abord(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let premiere = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(1)])
        .await;
    let seconde = bac
        .creer_commande_api(
            "marche",
            bac.vendeurs.iter().map(|v| v.ligne(1)).collect(),
        )
        .await;

    let (statut, corps) = bac.get("/moi/commandes", &bac.jeton_client).await;
    assert_eq!(statut, 200, "{corps}");
    let liste = corps["commandes"].as_array().unwrap();
    assert_eq!(liste.len(), 2);
    assert_eq!(liste[0]["id"], seconde.to_string(), "la plus récente d'abord");
    assert_eq!(liste[0]["nb_vendeurs"], 3);
    assert_eq!(liste[1]["id"], premiere.to_string());
    assert_eq!(liste[1]["nb_vendeurs"], 1);
    assert_eq!(liste[0]["etat_cle"], "suivi.etat.commande_recue");

    // Un autre compte a sa propre liste, vide.
    let (statut, corps) = bac.get("/moi/commandes", &bac.jeton_intrus).await;
    assert_eq!(statut, 200);
    assert!(corps["commandes"].as_array().unwrap().is_empty());
}

/// L'intention d'appel est journalisée — **sans aucun numéro** (ARTCI).
#[sqlx::test(migrations = "../migrations")]
async fn intention_d_appel_journalisee_sans_numero(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, _) = bac
        .post(
            &format!("/commandes/{}/appel", course.commande),
            &bac.jeton_client,
            json!({ "motif": "suivi" }),
        )
        .await;
    assert_eq!(statut, 204);

    let evenements = bac.evenements("appel.intention").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["de"], "client");
    assert_eq!(evenements[0]["vers"], "coursier");
    assert_eq!(evenements[0]["motif"], "suivi");

    // Le numéro du client existe en base ; il ne doit pas être dans le payload.
    let telephone: String =
        sqlx::query_scalar("SELECT telephone_e164 FROM comptes.compte WHERE id = $1")
            .bind(bac.client)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert!(
        !evenements[0].to_string().contains(&telephone),
        "aucun numéro n'entre dans `appel.intention` (minimisation ARTCI)",
    );

    // Un non-propriétaire ne peut rien journaliser.
    let (statut, _) = bac
        .post(
            &format!("/commandes/{}/appel", course.commande),
            &bac.jeton_intrus,
            json!({}),
        )
        .await;
    assert_eq!(statut, 404);
    assert_eq!(bac.nb_evenements("appel.intention").await, 1);
}

/// L'état affiché suit les DEUX niveaux, et une commande en attente de coursier
/// le dit clairement (maquette C4-4b).
#[sqlx::test(migrations = "../migrations")]
async fn l_etat_affiche_est_une_cle_i18n_a_chaque_etape(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(1)])
        .await;

    let etat_cle = |corps: &serde_json::Value| corps["etat_cle"].as_str().unwrap().to_owned();

    let (_, corps) = bac
        .get(&format!("/commandes/{commande}"), &bac.jeton_client)
        .await;
    assert_eq!(etat_cle(&corps), "suivi.etat.commande_recue");

    bac.commandes
        .mettre_en_attente_coursier(commande, chrono::Utc::now())
        .await
        .unwrap();
    let (_, corps) = bac
        .get(&format!("/commandes/{commande}"), &bac.jeton_client)
        .await;
    assert_eq!(etat_cle(&corps), "suivi.etat.recherche_coursier");

    bac.commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (_, corps) = bac
        .get(&format!("/commandes/{commande}"), &bac.jeton_client)
        .await;
    assert_eq!(etat_cle(&corps), "suivi.etat.collecte_en_cours");

    // Aucune de ces valeurs n'est une phrase : le serveur ne formule rien.
    assert!(etat_cle(&corps).starts_with("suivi.etat."));
}
