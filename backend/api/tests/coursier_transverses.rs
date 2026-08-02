//! Les invariants **transverses** du cycle CRS 010 — ceux qu'aucune story ne
//! possède, et que personne ne vérifierait donc en relisant une story.
//!
//! Trois, et chacun protège une promesse que tout le reste du produit tient
//! pour acquise :
//!
//! 1. **Aucun secret n'échappe** (SC-015). Le code à 4 chiffres, le jeton de
//!    réception, le code de secours vendeur et les deux numéros de téléphone ne
//!    doivent apparaître **ni** dans une charge utile d'événement, **ni** dans
//!    une réponse d'API — le pré-provisionnement ne sert que des empreintes
//!    (FR-037). Vérifié par **balayage automatique** plutôt que par relecture :
//!    une relecture manque le champ ajouté le mois prochain.
//! 2. **Aucune distance de routage n'est recalculée** (FR-009). Ce cycle
//!    affiche celles du devis figé (cycle 007) et produit une seule distance
//!    propre — la **proximité** de la présence, géodésique et arrondie, du même
//!    type que la porte de scan du cycle 006. Appeler OSRM ici ferait bouger un
//!    devis déjà annoncé au client.
//! 3. **L'horodatage serveur fait foi** sur tout ce qui fonde de l'argent
//!    (FR-010) : l'arrivée chez le client, les relevés de présence, la remise.
//!    L'appareil propose, le serveur écrit — une horloge de téléphone en avance
//!    de vingt minutes fabriquerait une preuve de présence en une seconde.

mod bac_coursier;

use bac_coursier::Bac;
use chrono::{Duration, Utc};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

/// Parcourt une valeur JSON et rend `true` si l'aiguille apparaît **quelque
/// part** — clé, valeur, ou au fond d'un tableau imbriqué.
///
/// Écrit à la main plutôt qu'en cherchant dans `to_string()` : une chaîne
/// sérialisée échapperait les accents et manquerait un secret qui en contient.
fn contient(valeur: &Value, aiguille: &str) -> bool {
    match valeur {
        Value::String(s) => s.contains(aiguille),
        Value::Array(a) => a.iter().any(|v| contient(v, aiguille)),
        Value::Object(o) => o
            .iter()
            .any(|(k, v)| k.contains(aiguille) || contient(v, aiguille)),
        _ => false,
    }
}

// ── 1. SC-015 : aucun secret n'échappe ─────────────────────────────────────

/// Balaye **toutes** les charges utiles d'événements et **toutes** les réponses
/// d'API du parcours complet d'une course, à la recherche des cinq secrets.
///
/// Le parcours est mené jusqu'au bout — collectes, appels, présence, photo,
/// remise — pour que le balayage porte sur ce qu'une vraie course produit, pas
/// sur un échantillon choisi.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_secret_n_echappe_du_parcours_complet(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;

    // Le code de secours de la plaque du premier vendeur — troisième secret.
    let code_vendeur: Option<String> =
        sqlx::query_scalar("SELECT code_secours FROM prestataires.prestataire WHERE id = $1")
            .bind(bac.vendeurs[0].id)
            .fetch_optional(&bac.pool)
            .await
            .unwrap();

    // Le parcours complet, par la voie HTTP.
    let mut reponses: Vec<Value> = Vec::new();
    reponses.push(bac.get("/courses/active", &bac.jeton_coursier).await.1);
    bac.collecter_tout(&course).await;
    bac.arriver_chez_le_client(&course).await;
    reponses.push(bac.appeler_client_absent(course.livraison).await.1);
    reponses.push(
        bac.post(
            &format!("/courses/{}/presence", course.livraison),
            &bac.jeton_coursier,
            json!({ "releves": [
                { "uuid_client": Uuid::now_v7(), "distance_m": 12,
                  "releve_le_local": Utc::now() }
            ]}),
        )
        .await
        .1,
    );
    reponses.push(bac.deposer_photo_preuve(course.livraison).await.1);
    reponses.push(bac.lire_preuves(course.livraison).await);
    reponses.push(
        bac.remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await
        .1,
    );
    bac.drainer_caisse().await;
    reponses.push(bac.lire_caisse().await);
    reponses.push(bac.get("/moi/journee", &bac.jeton_coursier).await.1);
    reponses.push(
        bac.get("/admin/coursiers/exposition", &bac.jeton_admin)
            .await
            .1,
    );
    reponses.push(
        bac.get(
            &format!("/admin/livraisons/{}/preuves", course.livraison),
            &bac.jeton_admin,
        )
        .await
        .1,
    );

    // Les cinq aiguilles. Les numéros SONT servis au coursier assigné (R6,
    // élargissement documenté) : c'est le seul endroit, et il est exclu du
    // balayage des réponses — jamais de celui des ÉVÉNEMENTS.
    let aiguilles_partout = [
        secrets.code.as_str(),
        secrets.jeton.as_str(),
        code_vendeur.as_deref().unwrap_or("§aucun-code-vendeur§"),
    ];

    for (i, reponse) in reponses.iter().enumerate() {
        for aiguille in aiguilles_partout {
            assert!(
                !contient(reponse, aiguille),
                "secret « {aiguille} » trouvé dans la réponse n°{i} : {reponse}",
            );
        }
    }

    // Les ÉVÉNEMENTS, eux, ne portent AUCUN des cinq — numéros compris.
    let evenements = bac.tous_evenements().await;
    assert!(
        !evenements.is_empty(),
        "un parcours complet écrit des événements — sinon ce test ne balaye rien",
    );
    for (type_evenement, payload) in &evenements {
        for aiguille in aiguilles_partout {
            assert!(
                !contient(payload, aiguille),
                "secret « {aiguille} » dans `{type_evenement}` : {payload}",
            );
        }
        for prefixe in ["+225", "0700000"] {
            assert!(
                !contient(payload, prefixe),
                "numéro de téléphone dans `{type_evenement}` : {payload}",
            );
        }
    }
}

/// Le pré-provisionnement sert des **empreintes**, jamais les secrets (FR-037).
///
/// C'est ce qui rend la validation locale possible sans que l'appareil ne
/// détienne rien de réutilisable : une empreinte volée ne remet aucune course.
#[sqlx::test(migrations = "../migrations")]
async fn la_course_active_ne_sert_que_des_empreintes(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;

    let (_, corps) = bac.get("/courses/active", &bac.jeton_coursier).await;
    let remise = &corps["remise"];

    assert!(
        remise["empreinte_code"]
            .as_str()
            .is_some_and(|e| !e.is_empty()),
        "l'empreinte du code est INDISPENSABLE à la validation hors ligne",
    );
    assert_ne!(remise["empreinte_code"], json!(secrets.code));
    assert_ne!(remise["empreinte_jeton"], json!(secrets.jeton));
    assert_eq!(remise.get("code"), None, "aucun champ `code` n'existe");
    assert_eq!(remise.get("jeton"), None, "aucun champ `jeton` n'existe");
}

// ── 2. FR-009 : aucune distance de routage recalculée ──────────────────────

/// Ce cycle **n'écrit aucune distance de routage** (FR-009).
///
/// La seule distance qu'il produit est une **proximité** — coursier ↔ point de
/// livraison, géodésique et arrondie, du même type que la porte de scan du
/// cycle 006. Recalculer un itinéraire ici ferait bouger un devis déjà annoncé
/// au client, après coup et sans qu'il l'ait accepté.
#[sqlx::test(migrations = "../migrations")]
async fn le_cycle_n_ecrit_aucune_distance_de_routage(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    // La distance du DEVIS, figée à la création (cycle 007) et portée par le
    // tronc. C'est elle qui a fondé le prix annoncé au client.
    async fn devis(bac: &Bac, livraison: Uuid) -> (i64, i64, i64) {
        sqlx::query_as::<_, (i64, i64, i64)>(
            "SELECT devis_distance_m, devis_eta_s, devis_prix_client
               FROM commandes.livraison WHERE id = $1",
        )
        .bind(livraison)
        .fetch_one(&bac.pool)
        .await
        .unwrap()
    }
    let avant = devis(&bac, course.livraison).await;

    bac.collecter_tout(&course).await;
    bac.arriver_chez_le_client(&course).await;
    bac.reunir_preuve_presence(course.livraison).await;

    assert_eq!(
        avant,
        devis(&bac, course.livraison).await,
        "la distance du devis est FIGÉE : ce cycle l'affiche, il ne la \
         recalcule pas — la modifier ferait bouger un prix déjà accepté",
    );

    // La proximité de présence, elle, existe — et n'est qu'une distance
    // arrondie, jamais un couple de coordonnées (R8, minimisation ARTCI).
    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name::text FROM information_schema.columns
          WHERE table_schema = 'coursier' AND table_name = 'releve_presence'",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert!(colonnes.iter().any(|c| c == "distance_m"));
    for interdite in ["lat", "lon", "latitude", "longitude"] {
        assert!(
            !colonnes.iter().any(|c| c == interdite),
            "`{interdite}` ne doit PAS exister : une position brute persistée \
             est exactement ce que la minimisation interdit",
        );
    }
}

// ── 3. FR-010 : l'horodatage serveur fait foi ──────────────────────────────

/// Une horloge d'appareil **en avance** ne fabrique pas de preuve de présence.
///
/// C'est le scénario d'abus le plus simple du cycle : régler son téléphone
/// vingt minutes en avance et déclarer avoir attendu. Le serveur écrit son
/// propre horodatage ; celui de l'appareil est **observé**, jamais retenu.
#[sqlx::test(migrations = "../migrations")]
async fn une_horloge_d_appareil_en_avance_ne_fabrique_aucune_presence(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.arriver_chez_le_client(&course).await;

    // Deux relevés prétendument espacés de vingt minutes… envoyés à l'instant.
    let futur = Utc::now() + Duration::minutes(20);
    let (statut, corps) = bac
        .post(
            &format!("/courses/{}/presence", course.livraison),
            &bac.jeton_coursier,
            json!({ "releves": [
                { "uuid_client": Uuid::now_v7(), "distance_m": 10,
                  "releve_le_local": Utc::now() },
                { "uuid_client": Uuid::now_v7(), "distance_m": 10,
                  "releve_le_local": futur },
            ]}),
        )
        .await;
    assert_eq!(statut, 200, "lot de présence refusé : {corps}");

    assert!(
        corps["presence_s"].as_i64().unwrap_or(i64::MAX) < 60,
        "vingt minutes annoncées par l'appareil ne valent PAS vingt minutes \
         mesurées : {corps}",
    );

    // Et en base, l'horodatage retenu est celui du SERVEUR.
    let ecarts: Vec<i64> = sqlx::query_scalar(
        "SELECT EXTRACT(EPOCH FROM (releve_le - now()))::bigint
           FROM coursier.releve_presence WHERE livraison_id = $1",
    )
    .bind(course.livraison)
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    for ecart in ecarts {
        assert!(
            ecart.abs() < 60,
            "un relevé horodaté à {ecart} s de maintenant : l'horloge de \
             l'appareil a été retenue",
        );
    }
}

/// L'arrivée chez le client est horodatée **par le serveur** (FR-010, FR-052).
///
/// C'est de cet instant que part le délai d'un échec : le laisser à l'appareil
/// permettrait de déclarer une absence dès qu'on se gare.
#[sqlx::test(migrations = "../migrations")]
async fn l_arrivee_chez_le_client_est_horodatee_par_le_serveur(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;

    // L'appareil prétend être arrivé il y a une heure.
    let passe = Utc::now() - Duration::hours(1);
    for action in ["en-route", "arrive"] {
        let (statut, corps) = bac
            .post(
                &format!(
                    "/courses/{}/arrets/{}/{action}",
                    course.livraison, course.remise
                ),
                &bac.jeton_coursier,
                json!({ "uuid_client": Uuid::now_v7(), "horodatage_local": passe }),
            )
            .await;
        assert_eq!(statut, 200, "transition {action} refusée : {corps}");
    }

    let ecart: i64 = sqlx::query_scalar(
        "SELECT EXTRACT(EPOCH FROM (now() - arrive_le))::bigint
           FROM commandes.arret WHERE id = $1",
    )
    .bind(course.remise)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert!(
        ecart.abs() < 60,
        "l'arrivée a été horodatée à {ecart} s : l'appareil a été cru",
    );
}

/// La remise est horodatée par le serveur, même déclarée **hors ligne**.
///
/// Une remise rejouée porte l'instant local de sa confirmation — utile pour
/// l'exploitation — mais c'est l'horodatage serveur qui fait foi : sinon une
/// livraison pourrait être datée d'avant sa collecte.
#[sqlx::test(migrations = "../migrations")]
async fn la_remise_hors_ligne_reste_horodatee_par_le_serveur(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.arriver_chez_le_client(&course).await;
    let secrets = bac.secrets_remise(course.commande).await;

    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({
                "mode": "code",
                "code": secrets.code,
                "hors_ligne": true,
                "confirme_le_local": Utc::now() - Duration::hours(3),
            }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "remise hors ligne refusée : {corps}");

    let ecart: i64 = sqlx::query_scalar(
        "SELECT EXTRACT(EPOCH FROM (now() - livree_le))::bigint
           FROM commandes.livraison WHERE id = $1",
    )
    .bind(course.livraison)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert!(
        ecart.abs() < 60,
        "la livraison a été datée d'il y a {ecart} s : l'appareil a été cru",
    );
}
