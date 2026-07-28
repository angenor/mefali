//! US1 (DSP-01) — être dans le pool tant qu'on donne signe de vie.
//!
//! Les **sept scénarios d'acceptation** de la story, joués sur l'app Actix
//! réelle : inscription complète, sortie par silence, retrait immédiat,
//! coursier en course, perte totale du pool, plafond plafonné par la grille,
//! plafond redemandé au nouveau jour.
//!
//! Aucune offre n'est encore construite : cette phase prouve seulement que le
//! vivier se peuple et se vide **honnêtement**.

mod bac_dispatch;

use bac_dispatch::{Bac, PALIER_ENTREE, POOL_TTL_S};
use serde_json::json;
use uuid::Uuid;

/// Scénario 1 — Yao se met en ligne, déclare son plafond, publie sa position :
/// il est interrogeable par zone et par rayon, avec son état complet.
#[sqlx::test(migrations = "../migrations")]
async fn inscription_complete_au_pool(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let yao = &bac.coursiers[0];

    // La mise en ligne seule ne suffit PAS : sans position, il n'est pas dans
    // le pool (contrat §1.1). L'intention et l'appartenance sont deux choses.
    let corps = bac.mettre_en_ligne(0, 8_000).await;
    assert_eq!(corps["en_ligne"], true);
    assert_eq!(corps["dans_le_pool"], false);
    assert_eq!(corps["capacites"][0]["valeur"], "moto");
    assert_eq!(corps["periode_position_s"], 30);

    let (statut, corps) = bac.publier_position(0).await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["dans_le_pool"], true);
    assert_eq!(corps["ttl_s"], POOL_TTL_S);
    assert_eq!(corps["prochaine_publication_s"], 30);

    // Interrogeable par rayon, avec un état complet.
    let dans_rayon = dispatch::PoolCoursiers::dans_rayon(
        bac.pool_coursiers.as_ref(),
        bac.cmd.ville,
        yao.lat,
        yao.lon,
        4_000,
    )
    .await
    .unwrap();
    assert_eq!(dans_rayon, vec![yao.id]);

    let (statut, corps) = bac.get("/moi/disponibilite", &yao.jeton).await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["dans_le_pool"], true);
    assert_eq!(corps["plafond_declare_unites"], 8_000);
}

/// Scénario 2 — **le silence EST l'information**. Un coursier qui cesse de
/// publier sort du pool et ne peut plus rien recevoir. Ce n'est pas un défaut à
/// compenser : c'est le seul moyen honnête de savoir qu'un téléphone a perdu le
/// réseau.
#[sqlx::test(migrations = "../migrations")]
async fn le_silence_fait_sortir_du_pool(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 8_000).await;
    let yao = &bac.coursiers[0];

    bac.pool_coursiers.faire_expirer(yao.id);

    let (statut, corps) = bac.get("/moi/disponibilite", &yao.jeton).await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(
        corps["dans_le_pool"], false,
        "sorti du pool — plus aucune offre ne peut lui parvenir",
    );
    assert_eq!(
        corps["en_ligne"], true,
        "son INTENTION tient : c'est le réseau qui a lâché, pas lui — et c'est \
         ce que son bandeau de reconnexion affiche",
    );

    // Et la publication suivante le réinscrit, sans qu'il ait rien à refaire.
    let (statut, _) = bac.publier_position(0).await;
    assert_eq!(statut, 200);
    let (_, corps) = bac.get("/moi/disponibilite", &yao.jeton).await;
    assert_eq!(corps["dans_le_pool"], true);
}

/// Scénario 3 — FR-005 : le retrait volontaire est **immédiat**. Attendre 90 s
/// après un « je passe hors ligne » ferait sonner le téléphone d'un coursier
/// qui a rangé sa moto.
#[sqlx::test(migrations = "../migrations")]
async fn le_retrait_volontaire_est_immediat(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 8_000).await;
    let yao = &bac.coursiers[0];

    let (statut, corps) = bac
        .put(
            "/moi/disponibilite",
            &yao.jeton,
            json!({ "en_ligne": false }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["en_ligne"], false);
    assert_eq!(corps["dans_le_pool"], false);

    // Une position arrivée APRÈS le passage hors ligne est IGNORÉE, pas
    // refusée : l'app peut être en retard d'un tic.
    let (statut, _) = bac.publier_position(0).await;
    assert_eq!(statut, 204, "position ignorée, sans erreur affichée à Yao");

    let (_, corps) = bac.get("/moi/disponibilite", &yao.jeton).await;
    assert_eq!(corps["dans_le_pool"], false);
}

/// Scénario 4 — un coursier avec une course active n'est pas offreable, et il
/// ne peut pas non plus se retirer : partir en course n'est pas sortir du pool,
/// c'est un abandon, et il appartient à CRS.
#[sqlx::test(migrations = "../migrations")]
async fn un_coursier_en_course_ne_peut_pas_se_retirer(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 8_000).await;
    let yao = &bac.coursiers[0];

    // Une commande lui est assignée par le contrat du cycle 008.
    let commande = bac
        .cmd
        .creer_commande_api("marche", vec![bac.cmd.vendeurs[0].ligne(1)])
        .await;
    bac.cmd
        .commandes
        .assigner_coursier(commande, yao.id, chrono::Utc::now())
        .await
        .unwrap();

    let (statut, corps) = bac
        .put(
            "/moi/disponibilite",
            &yao.jeton,
            json!({ "en_ligne": false }),
        )
        .await;
    assert_eq!(statut, 409, "{corps}");
    assert_eq!(corps["code"], "course_active");
    assert_eq!(corps["message_cle"], "dispatch.erreur.course_active");
}

/// Scénario 5 — **perte totale du pool** (SC-004). Aucune donnée métier n'y
/// vivait : rien n'est perdu, et le pool se reconstitue à la publication
/// suivante, sans aucune intervention.
#[sqlx::test(migrations = "../migrations")]
async fn la_perte_totale_du_pool_ne_perd_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    for i in 0..3 {
        bac.dans_le_pool(i, 8_000).await;
    }
    let commande = bac
        .cmd
        .creer_commande_api("marche", vec![bac.cmd.vendeurs[0].ligne(1)])
        .await;

    bac.pool_coursiers.vider();

    // La commande est intacte — rien de métier ne vivait dans l'index.
    assert_eq!(bac.cmd.etat_commande(commande).await, "nouvelle");
    // L'INTENTION d'être en ligne a survécu : elle est en Postgres, et c'est ce
    // qui permet à la publication suivante de reconstituer le pool.
    let (_, corps) = bac.get("/moi/disponibilite", &bac.coursiers[0].jeton).await;
    assert_eq!(corps["en_ligne"], true);
    assert_eq!(corps["dans_le_pool"], false);

    let (statut, _) = bac.publier_position(0).await;
    assert_eq!(statut, 200);
    let (_, corps) = bac.get("/moi/disponibilite", &bac.coursiers[0].jeton).await;
    assert_eq!(
        corps["dans_le_pool"], true,
        "reconstitué à la publication suivante, sans intervention",
    );
}

/// Scénario 6 — FR-010 : le plafond RETENU est `min(déclaré, palier)`, et Yao
/// voit **lequel** s'applique. Tant qu'AVI n'existe pas, tout le monde est au
/// palier d'entrée (research R7) : déclarer 15 000 ne donne pas 15 000.
#[sqlx::test(migrations = "../migrations")]
async fn le_plafond_retenu_est_le_plus_bas_des_deux(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let corps = bac.mettre_en_ligne(0, 15_000).await;
    assert_eq!(corps["plafond_declare_unites"], 15_000);
    assert_eq!(corps["plafond_retenu_unites"], PALIER_ENTREE);
    assert_eq!(corps["plafond_source"], "grille_note");
    assert_eq!(corps["palier_note_cle"], "dispatch.palier.entree");
    assert_eq!(corps["note_centiemes"], serde_json::Value::Null);
    assert_eq!(corps["devise"], "XOF");

    // Une déclaration PLUS BASSE que le palier s'applique telle quelle.
    let corps = bac.mettre_en_ligne(1, 3_000).await;
    assert_eq!(corps["plafond_retenu_unites"], 3_000);
    assert_eq!(corps["plafond_source"], "declaration");

    // L'événement porte les DEUX montants et son palier.
    let evenements = bac.evenements("coursier.plafond_jour_declare").await;
    assert_eq!(evenements.len(), 2);
    assert_eq!(evenements[0]["plafond_declare_unites"], 15_000);
    assert_eq!(evenements[0]["plafond_retenu_unites"], PALIER_ENTREE);
    assert_eq!(evenements[0]["palier_note"], "dispatch.palier.entree");
}

/// Scénario 7 (SC-003) — FR-011 : le plafond n'est **jamais reporté**. Un
/// nouveau jour rend `plafond_declare_unites: null`, et l'app le redemande.
/// Reporter silencieusement exposerait un coursier qui n'a plus l'argent.
#[sqlx::test(migrations = "../migrations")]
async fn le_plafond_n_est_jamais_reporte_au_lendemain(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.mettre_en_ligne(0, 8_000).await;
    let yao = &bac.coursiers[0];

    // La déclaration d'AUJOURD'HUI est bien là.
    let (_, corps) = bac.get("/moi/disponibilite", &yao.jeton).await;
    assert_eq!(corps["plafond_declare_unites"], 8_000);

    // On vieillit la ligne d'un jour : c'est exactement ce que fait le passage
    // de minuit.
    sqlx::query("UPDATE dispatch.plafond_jour SET jour = jour - 1 WHERE coursier_id = $1")
        .bind(yao.id)
        .execute(&bac.cmd.pool)
        .await
        .unwrap();

    let (_, corps) = bac.get("/moi/disponibilite", &yao.jeton).await;
    assert_eq!(
        corps["plafond_declare_unites"],
        serde_json::Value::Null,
        "nouveau jour, nouvelle déclaration — jamais de report tacite",
    );
    assert_eq!(
        corps["en_ligne"], false,
        "l'intention ne se reporte pas davantage : Yao redécide chaque matin",
    );
}

/// Un compte SANS rôle coursier validé n'entre nulle part — le pool est un
/// index, jamais une autorisation (FR-009).
#[sqlx::test(migrations = "../migrations")]
async fn un_compte_sans_role_coursier_est_refuse(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;

    let (statut, corps) = bac
        .put(
            "/moi/disponibilite",
            &bac.cmd.jeton_client,
            json!({ "en_ligne": true, "plafond_declare_unites": 5_000 }),
        )
        .await;
    assert_eq!(statut, 403, "{corps}");

    // Rôle coursier validé mais AUCUN véhicule déclaré : refusé aussi, et le
    // lui dire tout de suite vaut mieux qu'une attente muette.
    let (_, jeton) = bac
        .cmd
        .compte_avec_roles("+2250700009999", &["client", "coursier"])
        .await;
    let (statut, corps) = bac
        .put(
            "/moi/disponibilite",
            &jeton,
            json!({ "en_ligne": true, "plafond_declare_unites": 5_000 }),
        )
        .await;
    assert_eq!(statut, 422, "{corps}");
    assert_eq!(corps["code"], "capacite_non_declaree");
}

/// L'événement de disponibilité ne porte **aucune coordonnée** (FR-088) et
/// n'est émis qu'à la BASCULE — republier ne le ré-émet pas.
#[sqlx::test(migrations = "../migrations")]
async fn l_evenement_de_disponibilite_est_sobre_et_unique(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 8_000).await;

    // Deux publications de plus : aucune ne ré-émet.
    bac.publier_position(0).await;
    bac.publier_position(0).await;

    let evenements = bac.evenements("coursier.disponibilite_changee").await;
    assert_eq!(evenements.len(), 1, "un seul événement par bascule");
    let payload = &evenements[0];
    assert_eq!(payload["en_ligne"], true);
    assert_eq!(payload["motif"], "manuel");
    assert_eq!(payload["capacites"][0], "moto");
    let brut = payload.to_string();
    for interdit in ["lat", "lon", "latitude", "longitude"] {
        assert!(
            !brut.contains(interdit),
            "aucune coordonnée dans un événement (FR-088) : « {interdit} » trouvé",
        );
    }

    // La sortie émet le SIEN, une seule fois elle aussi.
    let jeton = bac.coursiers[0].jeton.clone();
    bac.put("/moi/disponibilite", &jeton, json!({ "en_ligne": false }))
        .await;
    bac.put("/moi/disponibilite", &jeton, json!({ "en_ligne": false }))
        .await;
    let evenements = bac.evenements("coursier.disponibilite_changee").await;
    assert_eq!(evenements.len(), 2, "sortir deux fois n'émet qu'une fois");
    assert_eq!(evenements[1]["en_ligne"], false);
}

/// `GET /admin/dispatch/pool` — la matière de la « carte des coursiers »
/// (FR-006), interrogée **par HTTP**, avec la seule `zone_id` du contrat §2.2.
///
/// Ce que ce test protège : l'endpoint doit être appelable avec ce que le
/// contrat annonce. Un paramètre exigé par l'extracteur mais absent du
/// `#[utoipa::path]` rendrait l'endpoint inatteignable depuis les clients
/// générés — un `400` que personne ne saurait corriger côté appelant.
#[sqlx::test(migrations = "../migrations")]
async fn la_carte_des_coursiers_se_lit_avec_la_seule_zone(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.dans_le_pool(0, 8_000).await;
    bac.dans_le_pool(1, 3_000).await;

    let (statut, corps) = bac
        .get(
            &format!("/admin/dispatch/pool?zone_id={}", bac.cmd.ville),
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    assert_eq!(corps["zone_id"], bac.cmd.ville.to_string());

    let coursiers = corps["coursiers"].as_array().unwrap();
    assert_eq!(coursiers.len(), 2, "les DEUX du pool, sans centre à fournir");
    let yao = coursiers
        .iter()
        .find(|c| c["coursier_id"] == bac.coursiers[0].id.to_string())
        .expect("Yao est dans la carte");
    assert_eq!(yao["capacites"][0], "moto");
    assert_eq!(
        yao["plafond_unites"], PALIER_ENTREE,
        "le plafond RETENU (palier d'entrée), pas les 8 000 déclarés : c'est ce \
         qu'il peut réellement avancer",
    );
    assert_eq!(yao["devise"], "XOF");
    assert!(
        yao["age_s"].as_i64().unwrap() >= 0,
        "l'exploitation doit savoir si elle regarde une position fraîche",
    );

    // Un FANTÔME de l'index (état expiré, membre survivant — research R2) est
    // omis : la carte ne montre que ce dont on connaît la position et l'âge.
    bac.pool_coursiers.faire_expirer(bac.coursiers[1].id);
    let (_, corps) = bac
        .get(
            &format!("/admin/dispatch/pool?zone_id={}", bac.cmd.ville),
            &bac.cmd.jeton_admin,
        )
        .await;
    assert_eq!(corps["coursiers"].as_array().unwrap().len(), 1);

    // La garde de rôle tient : un coursier ne lit pas les positions des autres.
    let (statut, _) = bac
        .get(
            &format!("/admin/dispatch/pool?zone_id={}", bac.cmd.ville),
            &bac.coursiers[0].jeton,
        )
        .await;
    assert_eq!(statut, 403, "seul l'admin voit les positions");
}

/// Une position rejouée avec le MÊME `uuid_client` ne double rien : elle
/// repousse simplement la durée de vie (constitution V).
#[sqlx::test(migrations = "../migrations")]
async fn une_position_rejouee_ne_double_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.mettre_en_ligne(0, 8_000).await;
    let yao = &bac.coursiers[0];
    let uuid_client = Uuid::now_v7();
    let corps = json!({
        "uuid_client": uuid_client,
        "horodatage_local": chrono::Utc::now(),
        "lat": yao.lat,
        "lon": yao.lon,
    });

    for _ in 0..3 {
        let (statut, _) = bac.post("/moi/position", &yao.jeton, corps.clone()).await;
        assert_eq!(statut, 200);
    }
    assert_eq!(
        bac.nb_evenements("coursier.disponibilite_changee").await,
        1,
        "trois publications, une seule entrée dans le pool",
    );
    assert_eq!(bac.pool_coursiers.taille(), 1);
}
