//! US2 (CRS-04) — **confirmer la livraison, même sans réseau**.
//!
//! Les trois voies de K4, l'idempotence du rejeu, la consolidation des essais
//! consommés hors ligne, le blocage au seuil de zone et sa levée par
//! l'exploitation. SC-005 et SC-006.
//!
//! Ce que ces tests protègent, en une phrase : **la validation locale n'engage
//! rien**. L'app décide que Yao peut partir ; le serveur, lui, revalide tout au
//! rejeu (FR-046). Un test qui laisserait passer une remise sur la seule foi de
//! l'appareil ferait de CRS-04 une invitation.

mod bac_coursier;

use bac_coursier::Bac;
use serde_json::json;
use uuid::Uuid;

/// Une course arrivée chez le client : les 3 collectes faites, la livraison
/// `en_livraison`. C'est le point de départ de toute remise.
async fn course_a_la_porte(bac: &Bac) -> bac_coursier::Course {
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    course
}

// ── Les trois voies (SC-005) ───────────────────────────────────────────────

/// Les **trois** voies closent la course. La maquette K4-1a les hiérarchise —
/// QR en action principale, code en secondaire, dépôt en lien discret — mais le
/// serveur les accepte toutes les trois de la même façon : il revalide.
#[sqlx::test(migrations = "../migrations")]
async fn les_trois_voies_closent_la_course(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    for voie in ["qr", "code", "depot"] {
        let course = course_a_la_porte(&bac).await;
        let secrets = bac.secrets_remise(course.commande).await;

        let demande = match voie {
            "qr" => json!({ "mode": "qr", "jeton": secrets.jeton }),
            "code" => json!({ "mode": "code", "code": secrets.code }),
            _ => {
                let (statut, _) = bac.ouvrir_depot(course.commande, true).await;
                assert_eq!(statut, 200, "T037 ouvre la voie dépôt");
                json!({ "mode": "depot", "depot_lat": 5.898, "depot_lon": -4.822 })
            }
        };
        let (statut, corps) = bac.remise(course.livraison, demande, voie == "depot").await;

        assert_eq!(statut, 200, "voie {voie} : {corps}");
        assert_eq!(corps["mode_remise"], voie);
        assert_eq!(corps["rejeu"], false);
        assert_eq!(bac.etat_livraison(course.livraison).await, "livree");
        assert_eq!(bac.etat_commande(course.commande).await, "terminee");
    }
}

/// **FR-048b / R18** — la voie dépôt voyage avec sa photo. C'est ce qui la rend
/// utilisable hors ligne : référencer un objet « déjà déposé » supposait le
/// réseau au moment précis où il manque.
#[sqlx::test(migrations = "../migrations")]
async fn le_depot_transporte_sa_photo_et_sa_position(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    bac.ouvrir_depot(course.commande, true).await;

    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "depot", "depot_lat": 5.898, "depot_lon": -4.822,
                    "hors_ligne": true }),
            true,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");

    let (cle, lat, lon): (Option<String>, Option<f64>, Option<f64>) = sqlx::query_as(
        "SELECT depot_photo_cle, depot_lat, depot_lon FROM commandes.livraison WHERE id = $1",
    )
    .bind(course.livraison)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    let cle = cle.expect("le serveur dépose la photo reçue et écrit sa clé");
    assert!(cle.contains(&course.livraison.to_string()));
    assert_eq!((lat, lon), (Some(5.898), Some(-4.822)));
    assert!(
        bac.objets.existe(&cle).await.unwrap(),
        "l'objet existe vraiment dans le stockage — pas seulement sa clé",
    );
}

/// Un dépôt **sans photo** ne prouve rien, et c'est justement la voie dont on
/// pourrait le plus facilement abuser (FR-048).
#[sqlx::test(migrations = "../migrations")]
async fn un_depot_sans_photo_est_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    bac.ouvrir_depot(course.commande, true).await;

    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "depot", "depot_lat": 5.898, "depot_lon": -4.822 }),
            false,
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(bac.etat_livraison(course.livraison).await, "en_livraison");
}

// ── Idempotence du rejeu (SC-006, R4) ──────────────────────────────────────

/// **R4** — la file rejoue jusqu'à acquittement. Trois envois du MÊME
/// `uuid_client` ⇒ une seule clôture, un seul `livraison.livree`.
#[sqlx::test(migrations = "../migrations")]
async fn le_rejeu_du_meme_uuid_ne_cloture_qu_une_fois(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    let secrets = bac.secrets_remise(course.commande).await;

    let uuid = Uuid::now_v7();
    let demande =
        json!({ "mode": "qr", "jeton": secrets.jeton, "uuid_client": uuid, "hors_ligne": true });

    for tour in 0..3 {
        let (statut, corps) = bac.remise(course.livraison, demande.clone(), false).await;
        assert_eq!(statut, 200, "tour {tour} : {corps}");
        assert_eq!(
            corps["rejeu"],
            tour > 0,
            "tour {tour} : seul le premier envoi écrit",
        );
    }

    assert_eq!(bac.nb_evenements("livraison.livree").await, 1);
    assert_eq!(bac.nb_evenements("commande.terminee").await, 1);
}

/// Un **autre** coursier ne clôt pas une course qui ne lui appartient plus, même
/// en rejouant un UUID qu'il avait bien émis (FR-006). C'est la dette relevée au
/// cycle 008 : la propriété se vérifie AUSSI au rejeu.
#[sqlx::test(migrations = "../migrations")]
async fn un_autre_coursier_ne_peut_pas_remettre(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    let secrets = bac.secrets_remise(course.commande).await;

    let (statut, corps) = bac
        .post_multipart(
            &format!("/courses/{}/remise", course.livraison),
            &bac.jeton_autre_coursier,
            json!({ "mode": "qr", "jeton": secrets.jeton, "uuid_client": Uuid::now_v7() }),
            false,
        )
        .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "non_proprietaire");
    assert_eq!(bac.etat_livraison(course.livraison).await, "en_livraison");
}

// ── Consolidation des essais et blocage (R5, FR-043 → FR-045) ──────────────

/// **FR-045** — le compteur retenu est le plus élevé des deux. Deux essais faux
/// devant la porte, sans réseau, puis un troisième au retour du réseau : le
/// seuil de zone est atteint. Aucun essai perdu, aucun inventé.
#[sqlx::test(migrations = "../migrations")]
async fn les_essais_hors_ligne_comptent_au_rejeu(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": "0000", "essais_hors_ligne": 2,
                    "hors_ligne": true }),
            false,
        )
        .await;
    assert_eq!(statut, 423, "{corps}");
    assert_eq!(corps["code"], "code_epuise");

    let (essais, bloque): (i16, Option<chrono::DateTime<chrono::Utc>>) =
        sqlx::query_as("SELECT essais_code, code_bloque_le FROM commandes.commande WHERE id = $1")
            .bind(course.commande)
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(essais, 3, "2 hors ligne + 1 ici");
    assert!(bloque.is_some(), "le blocage est un ÉTAT durable de la commande");

    // L'alerte d'exploitation part dans la MÊME transaction — et sans le code.
    let alertes = bac.evenements("remise.code_epuise").await;
    assert_eq!(alertes.len(), 1);
    assert!(
        !alertes[0].to_string().contains("0000"),
        "aucun code dans un événement : {}",
        alertes[0],
    );
}

/// **FR-043** — le blocage porte sur la **saisie par code**, pas sur le scan.
/// La maquette K4-1d le dit : « scan QR toujours proposé ». Le jeton est un aléa
/// long ; le plafond n'a jamais eu à le protéger.
#[sqlx::test(migrations = "../migrations")]
async fn le_qr_reste_ouvert_quand_le_code_est_bloque(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    let secrets = bac.secrets_remise(course.commande).await;

    for _ in 0..3 {
        bac.remise(
            course.livraison,
            json!({ "mode": "code", "code": "0000" }),
            false,
        )
        .await;
    }
    // Même le BON code est refusé : seule l'exploitation rouvre cette voie.
    let (statut, _) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 423);

    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "qr", "jeton": secrets.jeton }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "le scan reste la voie de secours : {corps}");
    assert_eq!(bac.etat_commande(course.commande).await, "terminee");
}

// ── Exploitation : blocages et dépôt (T036, T037) ──────────────────────────

/// **FR-044 / FR-055** — la commande bloquée remonte à l'exploitation, qui lève
/// le blocage avec un motif tracé. Le compteur retombe à zéro : sans cela, la
/// levée serait inopérante — le premier essai suivant rebloquerait la commande,
/// et l'exploitation croirait avoir agi.
#[sqlx::test(migrations = "../migrations")]
async fn le_blocage_remonte_a_l_exploitation_et_se_leve(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;
    let secrets = bac.secrets_remise(course.commande).await;
    for _ in 0..3 {
        bac.remise(
            course.livraison,
            json!({ "mode": "code", "code": "0000" }),
            false,
        )
        .await;
    }

    let (statut, corps) = bac.get("/admin/remises/bloquees", &bac.jeton_admin).await;
    assert_eq!(statut, 200, "{corps}");
    let remises = corps["remises"].as_array().unwrap();
    assert_eq!(remises.len(), 1, "{corps}");
    assert_eq!(remises[0]["commande_id"], json!(course.commande));
    assert_eq!(remises[0]["livraison_id"], json!(course.livraison));
    assert_eq!(remises[0]["essais_code"], 3);
    assert!(
        remises[0]["reference"].as_str().unwrap().starts_with('#'),
        "une référence courte, pour se parler au téléphone : {corps}",
    );

    // Un coursier ne lit pas cette file : c'est une surface d'exploitation.
    let (statut, _) = bac.get("/admin/remises/bloquees", &bac.jeton_coursier).await;
    assert_eq!(statut, 403);

    // Levée SANS motif : refusée. Retirer une protection se justifie.
    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/code/debloquer", course.commande),
            &bac.jeton_admin,
            json!({ "motif_cle": "  " }),
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "motif_requis");

    // Levée motivée : le code repasse.
    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/code/debloquer", course.commande),
            &bac.jeton_admin,
            json!({ "motif_cle": "remise.deblocage_client_a_retrouve_son_sms" }),
        )
        .await;
    assert_eq!(statut, 204, "{corps}");

    let evenements = bac.evenements("remise.code_debloque").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["essais_avant"], 3);
    assert_eq!(evenements[0]["acteur"], json!(bac.admin));
    assert!(
        !evenements[0].to_string().contains(&secrets.code),
        "aucun code dans un événement",
    );

    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "la levée rouvre vraiment la porte : {corps}");

    // La file est vide : le blocage levé n'y figure plus.
    let (_, corps) = bac.get("/admin/remises/bloquees", &bac.jeton_admin).await;
    assert!(corps["remises"].as_array().unwrap().is_empty());
}

/// Une levée « préventive » n'existe pas : un appel qui ne change rien ne doit
/// pas laisser l'exploitation croire qu'elle a agi.
#[sqlx::test(migrations = "../migrations")]
async fn lever_un_blocage_inexistant_est_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/code/debloquer", course.commande),
            &bac.jeton_admin,
            json!({ "motif_cle": "remise.deblocage_par_precaution" }),
        )
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "code_non_bloque");
    assert_eq!(bac.nb_evenements("remise.code_debloque").await, 0);
}

/// **FR-048 / FR-116** — la voie dépôt est FERMÉE par défaut, s'ouvre avec un
/// motif, et se **referme** de la même façon. La fermeture est une décision au
/// même titre que l'ouverture : c'est celle qu'on cherchera à reconstituer.
#[sqlx::test(migrations = "../migrations")]
async fn la_voie_depot_s_ouvre_et_se_referme_avec_sa_trace(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = course_a_la_porte(&bac).await;

    // Fermée par défaut : le serveur refuse.
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "depot", "depot_lat": 5.9, "depot_lon": -4.8 }),
            true,
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "depot_non_autorise");

    // Ouverture tracée.
    let (statut, corps) = bac.ouvrir_depot(course.commande, true).await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["depot_autorise"], true);

    // Refermeture — l'événement porte les DEUX sens.
    let (statut, corps) = bac.ouvrir_depot(course.commande, false).await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["depot_autorise"], false);

    let evenements = bac.evenements("depot.autorise").await;
    assert_eq!(evenements.len(), 2, "ouverture ET fermeture sont tracées");
    assert_eq!(evenements[0]["autorise"], true);
    assert_eq!(evenements[1]["autorise"], false);
    for e in &evenements {
        assert_eq!(e["acteur"], json!(bac.admin));
        assert!(e["motif_cle"].as_str().is_some_and(|m| !m.is_empty()));
    }

    // Et la porte est bien refermée.
    let (statut, _) = bac
        .remise(
            course.livraison,
            json!({ "mode": "depot", "depot_lat": 5.9, "depot_lon": -4.8 }),
            true,
        )
        .await;
    assert_eq!(statut, 422);

    // Un coursier n'ouvre pas sa propre voie de dépôt.
    let (statut, _) = bac
        .post(
            &format!("/admin/commandes/{}/depot", course.commande),
            &bac.jeton_coursier,
            json!({ "autorise": true, "motif_cle": "depot.je_le_veux" }),
        )
        .await;
    assert_eq!(statut, 403);
}
