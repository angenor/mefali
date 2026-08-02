//! `GET /courses/active` — le pré-provisionnement complet (cycle CRS 010, T015).
//!
//! Ce que ce fichier prouve, c'est la promesse de FR-011 et FR-028 : **une
//! seule lecture** doit suffire à faire fonctionner toute la course sans
//! réseau. Et son revers, qui compte autant : cette lecture ne doit servir
//! **aucun secret**, et ne rien servir du tout à un coursier qui n'est pas
//! celui de la course.

mod bac_coursier;

use bac_coursier::Bac;
use serde_json::Value;
use sqlx::PgPool;

/// La structure complète : arrêts ordonnés, lignes groupées PAR arrêt, client,
/// empreintes de remise. Tout ce que K3 et K4 affichent, en un appel.
#[sqlx::test(migrations = "../migrations")]
async fn la_course_est_servie_complete_en_une_lecture(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 200, "{corps}");

    assert_eq!(corps["livraison_id"], course.livraison.to_string());
    assert_eq!(corps["commande_id"], course.commande.to_string());
    assert_eq!(corps["etat"], "assignee");
    assert_eq!(corps["devise"], "XOF");

    // Trois arrêts, un par vendeur, chacun avec SES lignes — c'est le
    // regroupement qui fait la checklist de K3.
    let arrets = corps["arrets"].as_array().expect("arrêts");
    assert_eq!(arrets.len(), 3);
    for arret in arrets {
        let lignes = arret["lignes"].as_array().expect("lignes de l'arrêt");
        assert_eq!(
            lignes.len(),
            1,
            "chaque vendeur du bac porte une ligne : {arret}"
        );
        assert!(!lignes[0]["libelle"].as_str().unwrap().is_empty());
        assert!(lignes[0]["prix_unitaire_unites"].as_i64().unwrap() > 0);
        assert_eq!(lignes[0]["preference_substitution"], "appeler");
        assert_eq!(lignes[0]["statut"], "presente");
        // La plaque existe (les vendeurs du bac sont agréés) : les empreintes
        // rendent le scan possible hors ligne.
        assert!(!arret["empreinte_jeton"].as_str().unwrap().is_empty());
        assert!(!arret["empreinte_code"].as_str().unwrap().is_empty());
        assert_eq!(arret["distance_max_m"], 100);
        assert_eq!(arret["statut"], "a_collecter");
    }

    // Le montant de l'arrêt est celui des LIGNES : quantité 2 × prix unitaire.
    let attendu: i64 = 2 * bac.vendeurs[0].prix[0];
    assert_eq!(arrets[0]["montant_avance"].as_i64().unwrap(), attendu);

    // Le client, tel que Yao en a besoin devant la porte.
    let client = &corps["client"];
    assert_eq!(client["repere_texte"], "Près de la pharmacie Sainte-Marie");
    assert_eq!(client["depot_autorise"], false, "fermé par défaut (FR-039)");
    assert!(client["telephone"].as_str().unwrap().starts_with('+'));
    assert!(
        client["nom_usage"].is_null(),
        "aucune donnée nominative n'existe au MVP — le champ est absent, jamais fabriqué",
    );

    // La remise, pré-provisionnée.
    let remise = &corps["remise"];
    assert_eq!(remise["essais_consommes"], 0);
    assert_eq!(
        remise["essais_max"],
        bac_coursier::ESSAIS_CODE_LIVRAISON,
        "le seuil vient du paramètre du cycle 008, pas d'un nouveau (FR-106)",
    );
    assert_eq!(remise["code_bloque"], false);
    assert_eq!(remise["mode_paiement"], "cash");
    assert!(remise["montant_a_encaisser_unites"].as_i64().unwrap() > 0);
    // Les seuils de preuve voyagent avec : l'écran des preuves doit savoir
    // compter hors ligne (le serveur revérifie de toute façon, FR-060).
    assert_eq!(
        remise["preuves"]["presence_s"],
        bac_coursier::PREUVE_PRESENCE_S
    );
    assert_eq!(
        remise["preuves"]["appels_min"],
        bac_coursier::PREUVE_APPELS_MIN
    );
    assert_eq!(remise["preuves"]["photos_min"], 1);
}

/// FR-037, SC-015 — **aucun secret** ne sort. Ni le code à 4 chiffres, ni le
/// jeton de réception, ni le code de secours du vendeur : seulement leurs
/// empreintes.
///
/// L'assertion est faite sur le corps SÉRIALISÉ, pas sur les champs connus :
/// un champ ajouté par mégarde à un DTO passerait sous un contrôle champ par
/// champ, pas sous celui-ci.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_secret_ne_sort_de_la_course(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;

    let (statut, corps) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 200);
    let brut = corps.to_string();

    assert!(
        !brut.contains(&secrets.code),
        "le code à 4 chiffres du client ne doit JAMAIS traverser cette réponse",
    );
    assert!(
        !brut.contains(&secrets.jeton),
        "le jeton de réception ne doit JAMAIS traverser cette réponse",
    );
    // Les codes de secours des trois vendeurs non plus.
    let codes_secours: Vec<String> = sqlx::query_scalar(
        "SELECT code_secours FROM prestataires.prestataire WHERE code_secours IS NOT NULL",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert_eq!(codes_secours.len(), 3, "les 3 vendeurs ont leur plaque");
    for code in codes_secours {
        assert!(
            !brut.contains(&code),
            "le code de secours vendeur ne doit pas fuiter : {code}",
        );
    }
    // Et les noms de champ le disent : ce sont des EMPREINTES.
    assert!(brut.contains("empreinte_code"));
    assert!(brut.contains("empreinte_jeton"));
    assert!(!brut.contains("\"code_livraison\""));
    assert!(!brut.contains("\"jeton_reception\""));
}

/// Sans course, `204` — et un corps vide. Ce n'est pas une erreur : c'est une
/// journée qui commence.
#[sqlx::test(migrations = "../migrations")]
async fn sans_course_le_serveur_rend_204(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (statut, corps) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 204);
    assert_eq!(corps, Value::Null);
}

/// FR-006 — la course d'un autre coursier n'est pas servie. Le second coursier
/// du bac a un rôle VALIDE : ce qui est refusé ici est bien la **propriété**,
/// pas le rôle, et c'est la seule façon de le prouver.
#[sqlx::test(migrations = "../migrations")]
async fn un_autre_coursier_ne_voit_rien_de_la_course(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (statut, corps) = bac.get("/courses/active", &bac.jeton_autre_coursier).await;
    assert_eq!(
        statut, 204,
        "il n'a pas de course à lui — il ne voit pas celle du voisin : {corps}",
    );

    // Et pas seulement « rien » : rien de CETTE course.
    let brut = corps.to_string();
    assert!(!brut.contains(&course.livraison.to_string()));
    assert!(!brut.contains(&course.commande.to_string()));
}

/// Rôle coursier exigé : un client ne lit pas une course, même la sienne.
#[sqlx::test(migrations = "../migrations")]
async fn un_client_est_refuse_sur_le_role(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.course_prete().await;
    let (statut, _) = bac.get("/courses/active", &bac.jeton_client).await;
    assert_eq!(statut, 403);
}

/// La course suit la progression : un arrêt collecté reste SERVI, avec son
/// heure — c'est ce qui permet à K3-1b de l'afficher replié, « ✓ Collecté
/// 14:32 », plutôt que de le faire disparaître.
#[sqlx::test(migrations = "../migrations")]
async fn un_arret_collecte_reste_servi_avec_son_heure(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter(course.collectes[0]).await;

    let (statut, corps) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 200, "{corps}");
    let arrets = corps["arrets"].as_array().unwrap();
    assert_eq!(arrets.len(), 3, "l'arrêt collecté reste dans la course");

    let collecte = arrets
        .iter()
        .find(|a| a["arret_id"] == course.collectes[0].to_string())
        .expect("l'arrêt collecté est servi");
    assert_eq!(collecte["statut"], "collecte");
    assert!(
        !collecte["collecte_le"].is_null(),
        "son heure est servie — K3-1b l'affiche",
    );
    assert_eq!(corps["etat"], "en_collecte");
}

/// FR-013 / SC-002 — une ligne retirée fait baisser le montant de l'arrêt,
/// immédiatement. C'est le cœur de la checklist : Yao ne doit jamais avancer
/// l'argent d'un article qu'il n'a pas acheté.
#[sqlx::test(migrations = "../migrations")]
async fn une_ligne_retiree_fait_baisser_le_montant_de_l_arret(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    let (_, avant) = bac.get("/courses/active", &bac.jeton_coursier).await;
    let montant_avant = avant["arrets"][0]["montant_avance"].as_i64().unwrap();
    assert!(montant_avant > 0);

    let ligne: uuid::Uuid =
        sqlx::query_scalar("SELECT id FROM commandes.ligne_commande WHERE arret_id = $1 LIMIT 1")
            .bind(course.collectes[0])
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    sqlx::query("UPDATE commandes.ligne_commande SET statut = 'retiree' WHERE id = $1")
        .bind(ligne)
        .execute(&bac.pool)
        .await
        .unwrap();

    let (_, apres) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(
        apres["arrets"][0]["montant_avance"].as_i64().unwrap(),
        0,
        "toutes les lignes de cet arrêt sont retirées : il n'y a plus rien à payer",
    );
    assert_eq!(
        apres["arrets"][0]["lignes"][0]["statut"], "retiree",
        "la ligne reste VISIBLE, barrée — Yao doit savoir pourquoi il ne l'achète pas",
    );
}
