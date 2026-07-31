//! US4 (CRS-05) — **prouver qu'on a vraiment essayé**.
//!
//! Ce fichier est le garde-fou d'une promesse coûteuse. « Le coursier ne perd
//! jamais » veut dire qu'un échec ouvre une indemnisation ; sans preuve, la
//! promesse deviendrait une invitation, et chaque échec déclaré coûterait de
//! l'argent à quelqu'un qui n'a rien fait de mal.
//!
//! Trois choses y sont tenues, et aucune n'est décorative :
//!
//! 1. **Les 7 combinaisons incomplètes sont refusées** (SC-007). Sept, parce
//!    que trois preuves font huit états et qu'une seule est acceptable. Un test
//!    qui n'en couvrirait qu'une ou deux laisserait passer les autres.
//! 2. **L'écran et le serveur lisent la MÊME fonction** (FR-059/FR-060) : ce
//!    que `GET /preuves` annonce est exactement ce que `POST /echec` exige. Un
//!    bouton actif dont la déclaration serait refusée serait pire qu'un bouton
//!    inactif — Yao aurait fait le travail pour rien.
//! 3. **`PreuvesFixes` n'est plus câblé** (T058). Le bac compose comme la
//!    production ; c'est le vrai calcul qui décide, ici comme là-bas. Le piège
//!    du cycle 009 — un double qui « ment » — est refermé par cette
//!    composition, pas par une note.

mod bac_coursier;

use bac_coursier::{
    Bac, Course, PREUVE_APPELS_ESPACEMENT_S, PREUVE_APPELS_MIN, PREUVE_PRESENCE_S,
    PREUVE_PRESENCE_TROU_MAX_S,
};
use chrono::Duration;
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

/// Une course arrivée chez le client, prête pour un échec.
async fn course_a_la_porte(bac: &Bac) -> Course {
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    course
}

/// Déclare l'échec « client injoignable, marchandise non périssable » (§7.5-1).
async fn declarer_echec(bac: &Bac, course: &Course) -> (u16, Value) {
    bac.post(
        &format!("/courses/{}/echec", course.livraison),
        &bac.jeton_coursier,
        json!({
            "uuid_client": Uuid::now_v7(),
            "type_issue": "refus_non_perissable",
            "motif_cle": "echec.client_injoignable",
        }),
    )
    .await
}

// ── SC-007 : les 7 combinaisons incomplètes ────────────────────────────────

/// **Le test central du module.** Trois preuves font huit combinaisons ; sept
/// sont incomplètes, et les sept doivent être refusées.
///
/// Le tableau est écrit en clair plutôt que généré : une combinaison oubliée se
/// verrait ici, alors qu'une boucle sur `0..7` masquerait laquelle manque.
#[sqlx::test(migrations = "../migrations")]
async fn les_sept_combinaisons_incompletes_sont_toutes_refusees(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    for (appels, presence, photo) in [
        (false, false, false),
        (false, false, true),
        (false, true, false),
        (false, true, true),
        (true, false, false),
        (true, false, true),
        (true, true, false),
    ] {
        let course = course_a_la_porte(&bac).await;
        if appels {
            bac.reunir_preuve_appels(course.livraison).await;
        }
        if presence {
            bac.reunir_preuve_presence(course.livraison).await;
        }
        if photo {
            bac.deposer_photo_preuve(course.livraison).await;
        }

        // L'écran dit la même chose que le serveur : les deux lisent la MÊME
        // fonction, et c'est ce qui empêche un bouton actif de mentir.
        let vu = bac.lire_preuves(course.livraison).await;
        assert_eq!(
            vu["reunies"], false,
            "({appels}, {presence}, {photo}) : l'écran croit les preuves réunies",
        );
        assert_eq!(
            vu["reunies_sur"].as_u64().unwrap(),
            u64::from(appels) + u64::from(presence) + u64::from(photo),
            "compteur « N sur 3 » faux pour ({appels}, {presence}, {photo})",
        );

        let (statut, corps) = declarer_echec(&bac, &course).await;
        assert_eq!(
            statut, 409,
            "échec ACCEPTÉ sans preuves ({appels}, {presence}, {photo}) : {corps}",
        );
        assert_eq!(corps["code"], "preuves_incompletes");
        // Aucun événement de basculement : rien n'a basculé.
        assert_eq!(bac.nb_evenements("preuves_echec.reunies").await, 0);
    }
}

/// La huitième combinaison — celle qui passe. Sans elle, le test précédent
/// serait satisfait par un serveur qui refuse TOUT échec.
#[sqlx::test(migrations = "../migrations")]
async fn les_trois_preuves_reunies_ouvrent_la_declaration(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    bac.reunir_les_trois_preuves(course.livraison).await;

    let vu = bac.lire_preuves(course.livraison).await;
    assert_eq!(vu["reunies"], true, "{vu}");
    assert_eq!(vu["reunies_sur"], 3);
    assert_eq!(vu["total"], 3);

    let (statut, corps) = declarer_echec(&bac, &course).await;
    assert_eq!(statut, 200, "échec refusé alors que tout est prouvé : {corps}");
}

// ── L'espacement des appels (SC-007) ───────────────────────────────────────

/// Deux appels à quelques secondes d'écart ne valent qu'une preuve. Sans cette
/// règle, un échec se déclarerait en composant deux fois le même numéro dans la
/// même minute — c'est-à-dire sans avoir attendu.
#[sqlx::test(migrations = "../migrations")]
async fn des_appels_trop_rapproches_ne_valent_qu_une_preuve(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    for _ in 0..PREUVE_APPELS_MIN {
        let (statut, _) = bac.appeler_client_absent(course.livraison).await;
        assert_eq!(statut, 201);
    }

    let vu = bac.lire_preuves(course.livraison).await;
    assert_eq!(vu["appels"]["faits"], 1, "les deux appels ont compté : {vu}");
    assert_eq!(vu["appels"]["espacement_ok"], false);
    assert_eq!(vu["appels"]["ok"], false);
    assert_eq!(
        vu["appels"]["motif_cle"], "coursier.preuve.appels_trop_rapproches",
        "l'écran doit dire « attends », pas « rappelle » : {vu}",
    );

    // Le temps passe : le second appel devient recevable.
    bac.reculer_appels(
        course.livraison,
        Duration::seconds(PREUVE_APPELS_ESPACEMENT_S + 10),
    )
    .await;
    let (statut, _) = bac.appeler_client_absent(course.livraison).await;
    assert_eq!(statut, 201);

    let vu = bac.lire_preuves(course.livraison).await;
    assert_eq!(vu["appels"]["faits"], 2, "{vu}");
    assert_eq!(vu["appels"]["ok"], true);
}

/// FR-035 — un appel de suivi ne prouve pas une absence. Trois appels de
/// courtoisie ne doivent pas ouvrir la déclaration d'échec.
#[sqlx::test(migrations = "../migrations")]
async fn les_appels_de_suivi_ne_prouvent_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    for motif in ["suivi", "substitution", "suivi"] {
        let (statut, corps) = bac
            .post(
                &format!("/courses/{}/appels", course.livraison),
                &bac.jeton_coursier,
                json!({
                    "uuid_client": Uuid::now_v7(), "vers": "client", "motif": motif,
                    "passe_le_local": chrono::Utc::now(),
                }),
            )
            .await;
        assert_eq!(statut, 201, "{corps}");
        assert_eq!(corps["compte_pour_preuve"], false);
        bac.reculer_appels(course.livraison, Duration::seconds(PREUVE_APPELS_ESPACEMENT_S + 10))
            .await;
    }

    let vu = bac.lire_preuves(course.livraison).await;
    assert_eq!(vu["appels"]["faits"], 0);
    assert_eq!(vu["appels"]["motif_cle"], "coursier.preuve.appels_aucun");
}

// ── La présence (R8) ───────────────────────────────────────────────────────

/// R8 — deux relevés espacés de plus que le trou de zone ne valent PAS la durée
/// qui les sépare. Sans cette règle, Yao poserait un relevé, partirait déjeuner,
/// en poserait un second et prouverait une heure de présence.
#[sqlx::test(migrations = "../migrations")]
async fn un_trou_de_presence_ne_compte_pas(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    // Deux relevés seulement, espacés de bien plus que le trou toléré.
    bac.poser_presence(
        course.livraison,
        2,
        Duration::seconds(PREUVE_PRESENCE_S * 2),
        10,
    )
    .await;

    let vu = bac.lire_preuves(course.livraison).await;
    assert_eq!(
        vu["presence"]["secondes"], 0,
        "un aller-retour a été compté comme une attente : {vu}",
    );
    assert_eq!(vu["presence"]["ok"], false);
    assert_eq!(vu["presence"]["requis"], PREUVE_PRESENCE_S);
}

/// Des relevés hors du rayon ne comptent pas — et l'écran dit lequel des deux
/// problèmes il a : « rapproche-toi », pas « attends encore ».
#[sqlx::test(migrations = "../migrations")]
async fn des_releves_hors_du_rayon_ne_comptent_pas(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let pas = Duration::seconds(PREUVE_PRESENCE_TROU_MAX_S / 2);
    let nb = PREUVE_PRESENCE_S / (PREUVE_PRESENCE_TROU_MAX_S / 2) + 1;
    bac.poser_presence(course.livraison, nb, pas, 5_000).await;

    let vu = bac.lire_preuves(course.livraison).await;
    assert_eq!(vu["presence"]["secondes"], 0, "{vu}");
    assert_eq!(
        vu["presence"]["motif_cle"], "coursier.preuve.presence_hors_rayon",
        "{vu}",
    );
}

/// Le lot de relevés passe par HTTP, et son rejeu rend le MÊME corps : la file
/// hors-ligne peut le renvoyer autant de fois qu'elle veut (constitution V).
#[sqlx::test(migrations = "../migrations")]
async fn un_lot_de_presence_rejoue_ne_double_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let lot = json!({ "releves": [
        { "uuid_client": Uuid::now_v7(), "distance_m": 12,
          "releve_le_local": chrono::Utc::now() - Duration::seconds(60) },
        { "uuid_client": Uuid::now_v7(), "distance_m": 15,
          "releve_le_local": chrono::Utc::now() },
    ]});

    let uri = format!("/courses/{}/presence", course.livraison);
    let (statut, premier) = bac.post(&uri, &bac.jeton_coursier, lot.clone()).await;
    assert_eq!(statut, 200, "{premier}");
    assert_eq!(premier["retenus"], 2);
    assert_eq!(premier["presence_s"], 60);
    assert_eq!(premier["requis_s"], PREUVE_PRESENCE_S);

    let (statut, second) = bac.post(&uri, &bac.jeton_coursier, lot).await;
    assert_eq!(statut, 200);
    assert_eq!(second, premier, "le rejeu du lot n'a pas rendu le même corps");
    assert_eq!(
        bac.compter("SELECT count(*) FROM coursier.releve_presence").await,
        2,
        "le rejeu a créé des doublons",
    );
}

/// ⚠ **Une distance, jamais une position** (R8, patron ARTCI du cycle 006).
/// Le schéma n'a aucune colonne de coordonnée, et cette assertion le fige :
/// une colonne ajoutée par mégarde ferait tomber ce test.
#[sqlx::test(migrations = "../migrations")]
async fn aucune_coordonnee_n_est_persistee_par_la_presence(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    bac.reunir_preuve_presence(course.livraison).await;

    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name::text FROM information_schema.columns
          WHERE table_schema = 'coursier' AND table_name = 'releve_presence'",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();

    for interdite in ["lat", "lon", "latitude", "longitude", "position", "point"] {
        assert!(
            !colonnes.iter().any(|c| c.contains(interdite)),
            "la table de présence porte une coordonnée ({interdite}) : {colonnes:?}",
        );
    }
}

// ── Le basculement et son événement (FR-057) ───────────────────────────────

/// `preuves_echec.reunies` marque un INSTANT : il est émis une fois, à la
/// troisième preuve, et pas une fois de plus à chaque lecture.
#[sqlx::test(migrations = "../migrations")]
async fn le_basculement_n_emet_qu_une_seule_fois(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    // L'arrivée chez le client est déclarée, puis reculée : c'est depuis elle
    // que se mesure le délai porté par l'événement.
    bac.arriver_chez_le_client(&course).await;
    bac.reculer_arrivee(course.remise, Duration::seconds(900)).await;

    bac.reunir_preuve_appels(course.livraison).await;
    bac.reunir_preuve_presence(course.livraison).await;
    assert_eq!(
        bac.nb_evenements("preuves_echec.reunies").await,
        0,
        "deux preuves sur trois ont suffi à faire basculer",
    );

    let (statut, _) = bac.deposer_photo_preuve(course.livraison).await;
    assert_eq!(statut, 201);
    assert_eq!(bac.nb_evenements("preuves_echec.reunies").await, 1);

    // Trois lectures et une preuve de plus : toujours un seul événement.
    bac.lire_preuves(course.livraison).await;
    bac.lire_preuves(course.livraison).await;
    bac.deposer_photo_preuve(course.livraison).await;
    assert_eq!(
        bac.nb_evenements("preuves_echec.reunies").await,
        1,
        "l'instant du basculement a été réécrit — plus aucun événement ne le marque",
    );

    let evenements = bac.evenements("preuves_echec.reunies").await;
    let payload = &evenements[0];
    assert_eq!(payload["appels_retenus"], PREUVE_APPELS_MIN);
    assert!(payload["presence_s"].as_i64().unwrap() >= PREUVE_PRESENCE_S);
    assert_eq!(payload["photos"], 1);
    assert!(
        payload["delai_depuis_arrivee_s"].as_i64().unwrap() >= 900,
        "le délai depuis l'arrivée SERVEUR n'est pas mesuré : {payload}",
    );
    // R19 — l'issue déclarée n'est PAS un critère, donc pas dans la charge utile.
    assert!(payload.get("issue").is_none(), "{payload}");
    assert!(payload.get("issues").is_none(), "{payload}");
}

// ── Les gardes (FR-006, SC-008) ────────────────────────────────────────────

/// Un autre coursier ne lit ni n'alimente les preuves d'une course qui n'est
/// pas la sienne — ni la présence, ni la photo, ni l'état.
#[sqlx::test(migrations = "../migrations")]
async fn un_autre_coursier_ne_touche_pas_aux_preuves(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let (statut, _) = bac
        .get(
            &format!("/courses/{}/preuves", course.livraison),
            &bac.jeton_autre_coursier,
        )
        .await;
    assert_eq!(statut, 403, "les preuves d'autrui sont lisibles");

    let (statut, _) = bac
        .post(
            &format!("/courses/{}/presence", course.livraison),
            &bac.jeton_autre_coursier,
            json!({ "releves": [
                { "uuid_client": Uuid::now_v7(), "distance_m": 5,
                  "releve_le_local": chrono::Utc::now() }
            ]}),
        )
        .await;
    assert_eq!(statut, 403, "un tiers a posé une présence");

    let (statut, _) = bac
        .post_multipart(
            &format!("/courses/{}/preuves/photo", course.livraison),
            &bac.jeton_autre_coursier,
            json!({ "uuid_client": Uuid::now_v7() }),
            true,
        )
        .await;
    assert_eq!(statut, 403, "un tiers a déposé une photo de preuve");
}

/// SC-008 — **une déclaration hors app est refusée**. Le client n'a pas de rôle
/// coursier ; c'est le rôle qui l'arrête, avant même les preuves.
#[sqlx::test(migrations = "../migrations")]
async fn une_declaration_hors_app_est_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    bac.reunir_les_trois_preuves(course.livraison).await;

    let (statut, _) = bac
        .post(
            &format!("/courses/{}/echec", course.livraison),
            &bac.jeton_client,
            json!({ "uuid_client": Uuid::now_v7(), "type_issue": "refus_non_perissable",
                    "motif_cle": "echec.client_injoignable" }),
        )
        .await;
    assert_eq!(statut, 403, "un client a déclaré un échec");

    // Et le coursier ASSIGNÉ, lui, passe : sans ce contrôle, le test précédent
    // serait satisfait par un serveur qui refuse tout le monde.
    let (statut, _) = declarer_echec(&bac, &course).await;
    assert_eq!(statut, 200);
}

/// Le rejeu d'une photo par la file ne compte pas une seconde preuve.
#[sqlx::test(migrations = "../migrations")]
async fn une_photo_rejouee_ne_compte_pas_deux_fois(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let uuid = Uuid::now_v7();
    let uri = format!("/courses/{}/preuves/photo", course.livraison);
    let (statut, premier) = bac
        .post_multipart(&uri, &bac.jeton_coursier, json!({ "uuid_client": uuid }), true)
        .await;
    assert_eq!(statut, 201, "{premier}");
    assert_eq!(premier["photos"], 1);
    assert_eq!(premier["rejeu"], false);

    let (statut, second) = bac
        .post_multipart(&uri, &bac.jeton_coursier, json!({ "uuid_client": uuid }), true)
        .await;
    assert_eq!(statut, 200);
    assert_eq!(second["photo_id"], premier["photo_id"]);
    assert_eq!(second["photos"], 1, "le rejeu a compté une seconde photo");
    assert_eq!(second["rejeu"], true);
}

// ── La lecture d'exploitation (FR-063) ─────────────────────────────────────

/// Les preuves sont **lisibles** par l'exploitation : appels avec heures et
/// issues, présence mesurée, photos présignées. Une preuve que personne ne peut
/// lire ne protège personne — surtout pas le coursier qu'elle devrait défendre.
#[sqlx::test(migrations = "../migrations")]
async fn l_exploitation_lit_le_dossier_complet(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    bac.reunir_les_trois_preuves(course.livraison).await;

    // Un appel de SUIVI en plus : le dossier doit le montrer aussi, même s'il
    // ne compte pas — ce qui n'a pas compté éclaire autant que le reste.
    bac.post(
        &format!("/courses/{}/appels", course.livraison),
        &bac.jeton_coursier,
        json!({ "uuid_client": Uuid::now_v7(), "vers": "client", "motif": "suivi",
                "issue": "repondu", "passe_le_local": chrono::Utc::now() }),
    )
    .await;

    let (statut, dossier) = bac
        .get(
            &format!("/admin/livraisons/{}/preuves", course.livraison),
            &bac.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{dossier}");

    let appels = dossier["appels"].as_array().unwrap();
    assert_eq!(appels.len(), PREUVE_APPELS_MIN as usize + 1);
    assert!(appels.iter().any(|a| a["motif"] == "suivi"));
    assert!(appels.iter().all(|a| a["passe_le"].is_string()));

    let photos = dossier["photos"].as_array().unwrap();
    assert_eq!(photos.len(), 1);
    assert!(photos[0]["url"].is_string(), "photo non présignée : {dossier}");
    assert!(photos[0]["purgee_le"].is_null());

    assert_eq!(dossier["etat"]["reunies"], true);
    assert!(dossier["reunies_le"].is_string(), "{dossier}");

    // ⚠ SC-015 — aucun numéro de téléphone dans le dossier. Le serveur n'en a
    // jamais journalisé, et cette assertion l'empêche d'en journaliser un jour.
    let brut = dossier.to_string();
    assert!(!brut.contains("+225"), "un numéro a fuité : {brut}");
}

/// Le dossier de preuves est réservé à l'exploitation — un coursier n'y accède
/// pas, même sur sa propre course : il a son propre endpoint, sans les URL.
#[sqlx::test(migrations = "../migrations")]
async fn le_dossier_d_exploitation_exige_le_role_admin(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let (statut, _) = bac
        .get(
            &format!("/admin/livraisons/{}/preuves", course.livraison),
            &bac.jeton_coursier,
        )
        .await;
    assert_eq!(statut, 403);
}
