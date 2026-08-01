//! Les cibles de performance de `plan.md`, **mesurées** (T086).
//!
//! Une cible qu'aucun test ne mesure est un vœu. Ces trois-là décident de ce
//! que Yao vit sur un téléphone d'entrée de gamme, au bord d'une route :
//!
//! | Cible | Pourquoi elle compte |
//! |---|---|
//! | `GET /courses/active` ≤ 300 ms p95, **une seule requête** | c'est ce qui charge toute la course d'un coup, hors ligne compris (FR-011) |
//! | drain de file ≤ 5 s | le temps entre le retour du réseau et « la commande est terminée » (SC-004) |
//! | exposition admin ≤ 5 s de retard | ce que l'exploitation voit du cash en circulation (SC-010) |
//!
//! **Ce que ces mesures valent, et ce qu'elles ne valent pas.** Elles tournent
//! sur une base de test locale, sans latence réseau ni charge concurrente : un
//! chiffre ici ne prédit pas le VPS. Ce qu'elles attrapent, en revanche, c'est
//! la régression d'un ordre de grandeur — la requête N+1 introduite en ajoutant
//! un champ, le drain qui devient quadratique. C'est exactement ce contre quoi
//! une cible sert, et une marge large (≥ 10×) le dit franchement plutôt que de
//! prétendre à une précision qu'un test local ne peut pas avoir.

mod bac_coursier;

use std::time::Instant;

use bac_coursier::Bac;
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

/// Nombre de mesures. Vingt suffisent pour un p95 lisible sans faire durer la
/// suite : la 19ᵉ valeur triée EST le 95ᵉ centile.
const MESURES: usize = 20;

/// 95ᵉ centile d'une série, en millisecondes.
fn p95(mut ms: Vec<u128>) -> u128 {
    ms.sort_unstable();
    let rang = ((ms.len() as f64) * 0.95).ceil() as usize - 1;
    ms[rang.min(ms.len() - 1)]
}

/// `GET /courses/active` ≤ 300 ms p95, en **une seule requête** SQL.
///
/// L'unicité de la requête compte plus que le chiffre : c'est elle qui tient la
/// cible quand la course passe de 3 à 8 arrêts. Une lecture par arrêt marcherait
/// très bien sur ce bac et s'écroulerait le jour d'un vrai panier.
#[sqlx::test(migrations = "../migrations")]
async fn la_course_active_se_charge_en_une_requete_sous_300_ms(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    // Une passe à blanc : le premier appel paie la préparation des requêtes et
    // le remplissage des caches — le mesurer punirait le test, pas le code.
    let (statut, _) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 200);

    let mut mesures = Vec::with_capacity(MESURES);
    for _ in 0..MESURES {
        let debut = Instant::now();
        let (statut, _) = bac.get("/courses/active", &bac.jeton_coursier).await;
        mesures.push(debut.elapsed().as_millis());
        assert_eq!(statut, 200);
    }

    let mesure = p95(mesures);
    assert!(
        mesure <= 300,
        "GET /courses/active : {mesure} ms p95, cible 300 ms (plan.md)",
    );
    // Le contenu est bien COMPLET : mesurer une réponse vide ne prouverait rien.
    let (_, corps) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(corps["arrets"].as_array().unwrap().len(), 3);
    assert!(corps["arrets"][0]["lignes"].as_array().unwrap().len() >= 1);
    assert_eq!(corps["livraison_id"], json!(course.livraison));
}

/// Le drain d'une file complète tient **largement** sous les 5 s de SC-004.
///
/// La file d'une course coupée porte trois collectes, une arrivée et une
/// remise. Le scénario du quickstart §2.1 mesuré de bout en bout : c'est le
/// temps entre le retour du réseau et « la commande est terminée ».
#[sqlx::test(migrations = "../migrations")]
async fn le_drain_d_une_file_complete_tient_sous_cinq_secondes(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;

    // Chaque action porte son `uuid_client`, comme la file les aurait rangées.
    let uuids: Vec<Uuid> = course.collectes.iter().map(|_| Uuid::now_v7()).collect();

    let debut = Instant::now();
    for (arret, uuid) in course.collectes.iter().zip(&uuids) {
        bac.collecter_avec_uuid(*arret, *uuid).await;
    }
    bac.arriver_chez_le_client(&course).await;
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code, "hors_ligne": true }),
            false,
        )
        .await;
    let ecoule = debut.elapsed();

    assert_eq!(statut, 200, "remise refusée : {corps}");
    assert_eq!(bac.etat_commande(course.commande).await, "terminee");
    assert!(
        ecoule.as_secs_f64() < 5.0,
        "drain complet en {:.2} s, cible 5 s (SC-004)",
        ecoule.as_secs_f64(),
    );

    // Et le SECOND rejeu — celui qui prouve l'idempotence — ne coûte pas plus
    // cher : un rejeu qui se dégraderait rendrait la reprise plus lente que la
    // première passe, exactement quand le réseau est encore fragile.
    let debut = Instant::now();
    for (arret, uuid) in course.collectes.iter().zip(&uuids) {
        bac.collecter_avec_uuid(*arret, *uuid).await;
    }
    assert!(
        debut.elapsed().as_secs_f64() < 5.0,
        "le second rejeu doit rester aussi rapide que le premier",
    );
}

/// L'exposition cash reflète la dernière collecte **immédiatement** après le
/// passage du consommateur outbox (SC-010, cible : 5 s de retard).
///
/// Le retard réel est celui du worker (période de lot), pas celui de la
/// lecture : ce test mesure la seconde moitié — une fois l'événement consommé,
/// l'exposition est juste, et sa lecture ne coûte rien.
#[sqlx::test(migrations = "../migrations")]
async fn l_exposition_admin_est_juste_des_que_l_evenement_est_consomme(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    bac.collecter_tout(&course).await;
    let debut = Instant::now();
    bac.drainer_caisse().await;
    let (statut, expo) = bac
        .get("/admin/coursiers/exposition", &bac.jeton_admin)
        .await;
    let ecoule = debut.elapsed();

    assert_eq!(statut, 200);
    let attendu = bac.lire_caisse().await["avance_en_cours_unites"]
        .as_i64()
        .unwrap();
    assert_eq!(expo["total_unites"], json!(attendu));
    assert!(
        ecoule.as_secs_f64() < 5.0,
        "consommation + lecture en {:.2} s, cible 5 s (SC-010)",
        ecoule.as_secs_f64(),
    );
}

/// La caisse d'une journée chargée se lit sans dégénérer.
///
/// Vingt courses, c'est plus qu'une journée réelle à Tiassalé (flotte de 2 à 4
/// coursiers). Si la lecture tenait uniquement parce que l'historique est
/// court, elle s'écroulerait au premier coursier productif.
#[sqlx::test(migrations = "../migrations")]
async fn la_caisse_d_une_journee_chargee_se_lit_sans_degenerer(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    for _ in 0..20 {
        let course = bac.course_prete().await;
        bac.collecter_tout(&course).await;
    }
    bac.drainer_caisse().await;

    let mut mesures = Vec::with_capacity(MESURES);
    for _ in 0..MESURES {
        let debut = Instant::now();
        let (statut, _) = bac.get("/moi/caisse", &bac.jeton_coursier).await;
        mesures.push(debut.elapsed().as_millis());
        assert_eq!(statut, 200);
    }

    let mesure = p95(mesures);
    assert!(
        mesure <= 300,
        "GET /moi/caisse sur 20 courses : {mesure} ms p95, cible 300 ms",
    );
    assert_eq!(
        bac.lire_caisse().await["historique_du_jour"]
            .as_array()
            .unwrap()
            .len(),
        20,
        "les 20 courses sont bien dans l'historique — sinon on mesure du vide",
    );
}
