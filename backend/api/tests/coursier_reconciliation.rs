//! ⭐ **LE TEST QUI FAIT FOI DU MODULE** — US3 (CRS-04/05), FR-089, SC-004.
//!
//! Le scénario de `quickstart.md` §2.1, dans l'ordre exact : le réseau tombe
//! entre le dernier scan et la remise, la file accumule, le réseau revient, la
//! file se rejoue — **une fois, puis une seconde fois**.
//!
//! Ce qu'il protège tient en une phrase : **rien ne se perd, rien ne double**.
//! Sans lui, chacune des deux moitiés de la promesse pourrait se casser sans
//! qu'on s'en aperçoive avant le terrain :
//!
//! - « rien ne se perd » — une collecte faite hors ligne est une avance
//!   RÉELLEMENT sortie de la poche de Yao ; la perdre, c'est la lui faire payer ;
//! - « rien ne double » — deux clôtures d'une même course, c'est deux
//!   `commande.terminee`, deux encaissements comptés, et une caisse qui ment.
//!
//! La seconde moitié du fichier couvre le cas qu'on n'a pas le droit d'oublier
//! (SC-016) : la course a été **réassignée** pendant la coupure. Les actions du
//! porteur d'avant sont refusées — et **tracées**, parce que derrière elles il y
//! a une avance engagée par quelqu'un qui n'est plus assigné.

mod bac_coursier;

use bac_coursier::Bac;
use serde_json::{json, Value};
use uuid::Uuid;

/// Une action de la file, telle que l'app l'aurait enfilée : un endpoint, un
/// corps, et surtout un `uuid_client` STABLE — c'est lui qui rend le rejeu
/// inoffensif.
struct ActionEnFile {
    endpoint: String,
    demande: Value,
    /// L'action voyage-t-elle en `multipart/form-data` ?
    ///
    /// **Toutes les actions ne sont pas multipart, et c'est le contrat qui le
    /// dit** : seules celles qui peuvent porter une photo le sont (collecte,
    /// substitution, remise, preuve). Les transitions d'arrêt attendent du JSON.
    /// Une file qui enverrait tout de la même façon casserait la moitié des
    /// endpoints — bug attrapé par ce test.
    multipart: bool,
}

impl ActionEnFile {
    fn json(endpoint: String, mut demande: Value, uuid_client: Uuid) -> Self {
        demande["uuid_client"] = json!(uuid_client);
        Self {
            endpoint,
            demande,
            multipart: false,
        }
    }

    fn multipart(endpoint: String, mut demande: Value, uuid_client: Uuid) -> Self {
        demande["uuid_client"] = json!(uuid_client);
        Self {
            endpoint,
            demande,
            multipart: true,
        }
    }
}

/// Rejoue la file dans l'ordre de création — exactement ce que fait
/// `_drainerFile` côté app.
async fn rejouer(bac: &Bac, file: &[ActionEnFile]) -> Vec<(u16, Value)> {
    let mut issues = Vec::new();
    for action in file {
        let issue = if action.multipart {
            bac.post_multipart(
                &action.endpoint,
                &bac.jeton_coursier,
                action.demande.clone(),
                false,
            )
            .await
        } else {
            bac.post(
                &action.endpoint,
                &bac.jeton_coursier,
                action.demande.clone(),
            )
            .await
        };
        issues.push(issue);
    }
    issues
}

// ── §2.1 — le scénario obligatoire ─────────────────────────────────────────

/// **FR-089 / SC-004** — réseau coupé entre le dernier scan et la remise, puis
/// rétabli : cardinalité **1 / 1 / 1**, et un second rejeu qui ne fait rien.
#[sqlx::test(migrations = "../migrations")]
async fn le_reseau_coupe_entre_le_scan_et_la_remise_ne_double_rien(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;

    // ── 1 & 2. Les deux premiers arrêts, EN LIGNE ─────────────────────────
    for arret in course.collectes.iter().take(2) {
        bac.collecter(*arret).await;
    }
    assert_eq!(bac.nb_evenements("arret.collecte").await, 2);

    // ── 3 & 4. Le réseau tombe. Yao continue : il scanne le 3ᵉ arrêt, arrive
    //    chez le client, et confirme la remise par code. RIEN ne part.
    //
    //    Les `uuid_client` sont fixés MAINTENANT, au moment de l'action —
    //    c'est le point exact où l'idempotence se joue : les générer au rejeu
    //    en produirait un nouveau à chaque tentative, et chaque tentative
    //    compterait.
    let uuid_collecte = Uuid::now_v7();
    let uuid_en_route = Uuid::now_v7();
    let uuid_arrive = Uuid::now_v7();
    let uuid_remise = Uuid::now_v7();
    let dernier_arret = *course.collectes.last().unwrap();

    let file = vec![
        // « Je suis arrivé chez le client » vise l'arrêt de REMISE, pas le
        // dernier vendeur : celui-là vient d'être collecté, et
        // `collecte → arrive` n'existe pas dans la table fermée des transitions.
        //
        // Et il faut les DEUX transitions : `arrive` n'est atteignable que
        // depuis `en_route` (data-model §3.3). L'app enfile donc les deux à la
        // bascule vers le client — c'est ce que fait `_arriverChezClient`.
        ActionEnFile::json(
            format!(
                "/courses/{}/arrets/{}/en-route",
                course.livraison, course.remise
            ),
            json!({ "horodatage_local": "2026-07-28T14:45:00Z" }),
            uuid_en_route,
        ),
        ActionEnFile::json(
            format!(
                "/courses/{}/arrets/{}/arrive",
                course.livraison, course.remise
            ),
            json!({ "horodatage_local": "2026-07-28T14:50:00Z" }),
            uuid_arrive,
        ),
        ActionEnFile::multipart(
            format!("/courses/{}/remise", course.livraison),
            json!({
                "mode": "code",
                "code": secrets.code,
                "hors_ligne": true,
                "confirme_le_local": "2026-07-28T14:56:03Z",
            }),
            uuid_remise,
        ),
    ];

    // Le scan lui-même passe par le domaine (le bac ne monte pas la plaque),
    // mais avec le MÊME `uuid_client` que la file rejouerait.
    bac.collecter_avec_uuid(dernier_arret, uuid_collecte).await;

    // ── 5. Le réseau revient : la file se rejoue, dans l'ordre ────────────
    // (le scan a déjà abouti au moment du drain ; il se rejoue lui aussi)
    bac.collecter_avec_uuid(dernier_arret, uuid_collecte).await;
    for (statut, corps) in rejouer(&bac, &file).await {
        assert!(
            (200..300).contains(&statut),
            "le rejeu d'une action valide aboutit : {statut} {corps}",
        );
    }

    // ── 6. Cardinalité 1 / 1 / 1 ─────────────────────────────────────────
    assert_eq!(
        bac.nb_evenements("arret.collecte").await,
        3,
        "trois arrêts, trois collectes — la troisième ne compte qu'une fois",
    );
    assert_eq!(bac.nb_evenements("livraison.livree").await, 1);
    assert_eq!(bac.nb_evenements("commande.terminee").await, 1);
    assert_eq!(bac.etat_commande(course.commande).await, "terminee");
    assert_eq!(bac.etat_livraison(course.livraison).await, "livree");

    let remises: i64 =
        sqlx::query_scalar("SELECT count(*) FROM commandes.livraison WHERE livree_le IS NOT NULL")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(remises, 1);

    // ── 7. Un SECOND rejeu complet : aucun effet ─────────────────────────
    // C'est le cas réel : le drain se relance au retour du réseau, et l'app
    // n'a pas encore eu le temps de retirer les actions acquittées.
    let evenements_avant = bac.tous_evenements().await.len();
    bac.collecter_avec_uuid(dernier_arret, uuid_collecte).await;
    for (statut, corps) in rejouer(&bac, &file).await {
        assert!(
            (200..300).contains(&statut),
            "un rejeu idempotent reste un succès : {statut} {corps}",
        );
    }
    assert_eq!(
        bac.tous_evenements().await.len(),
        evenements_avant,
        "un second rejeu n'écrit AUCUN événement de plus",
    );
    assert_eq!(bac.nb_evenements("livraison.livree").await, 1);
    assert_eq!(bac.nb_evenements("commande.terminee").await, 1);
}

/// L'ordre de rejeu est celui de la **création**, pas celui du hasard.
///
/// « Arrivé » avant « en route » se ferait refuser par la table fermée des
/// transitions : une file qui perdrait l'ordre produirait des refus définitifs
/// sur des actions parfaitement légitimes, et Yao verrait des « actions
/// refusées » pour avoir eu du réseau au mauvais moment.
#[sqlx::test(migrations = "../migrations")]
async fn la_file_se_rejoue_dans_l_ordre_de_creation(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let arret = course.collectes[0];

    let file = vec![
        ActionEnFile::json(
            format!("/courses/{}/arrets/{arret}/en-route", course.livraison),
            json!({ "horodatage_local": "2026-07-28T14:00:00Z" }),
            Uuid::now_v7(),
        ),
        ActionEnFile::json(
            format!("/courses/{}/arrets/{arret}/arrive", course.livraison),
            json!({ "horodatage_local": "2026-07-28T14:10:00Z" }),
            Uuid::now_v7(),
        ),
    ];

    for (statut, corps) in rejouer(&bac, &file).await {
        assert_eq!(statut, 200, "{corps}");
    }
    assert_eq!(bac.statut_arret(arret).await, "arrive");
    assert_eq!(bac.nb_evenements("arret.en_route").await, 1);
    assert_eq!(bac.nb_evenements("arret.arrive").await, 1);
}

// ── SC-016 — la course a changé de porteur pendant la coupure ──────────────

/// **FR-006 / FR-088 / SC-016** — une action rejouée par un coursier
/// **désassigné** est refusée et **tracée**.
///
/// C'est le cas le plus coûteux du cycle : Yao a réellement collecté et avancé
/// de l'argent, mais l'exploitation a réassigné la course pendant qu'il était
/// sous un pont. Appliquer ses actions ferait avancer une course qui ne lui
/// appartient plus ; les jeter en silence effacerait son avance. Le serveur les
/// refuse **et** émet `coursier.action_reconciliee` — c'est ce qui ouvre le
/// litige plutôt que de le rendre invisible.
#[sqlx::test(migrations = "../migrations")]
async fn une_course_reassignee_refuse_et_trace_les_actions_de_l_ancien_porteur(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;
    let arret = course.collectes[0];

    // Yao collecte le premier arrêt — l'avance est SORTIE de sa poche.
    bac.collecter(arret).await;

    // Pendant la coupure, l'exploitation réassigne la course.
    sqlx::query("UPDATE commandes.livraison SET coursier_id = $2 WHERE id = $1")
        .bind(course.livraison)
        .bind(bac.autre_coursier)
        .execute(&bac.pool)
        .await
        .unwrap();

    // Le réseau revient. La file de Yao se vide — dans le vide.
    let file = vec![
        ActionEnFile::json(
            format!(
                "/courses/{}/arrets/{}/arrive",
                course.livraison, course.collectes[1]
            ),
            json!({ "horodatage_local": "2026-07-28T14:50:00Z" }),
            Uuid::now_v7(),
        ),
        ActionEnFile::multipart(
            format!("/courses/{}/remise", course.livraison),
            json!({ "mode": "code", "code": secrets.code, "hors_ligne": true }),
            Uuid::now_v7(),
        ),
    ];
    for (statut, corps) in rejouer(&bac, &file).await {
        assert_eq!(statut, 403, "{corps}");
        assert_eq!(corps["code"], "non_proprietaire");
    }

    // RIEN n'a bougé : la course n'est ni avancée, ni close.
    assert_eq!(bac.etat_livraison(course.livraison).await, "en_collecte");
    assert_eq!(bac.nb_evenements("livraison.livree").await, 0);

    // Mais la trace existe — une par action refusée, avec son type.
    let traces = bac.evenements("coursier.action_reconciliee").await;
    assert_eq!(traces.len(), 2, "une trace par action refusée : {traces:?}");
    let actions: Vec<&str> = traces
        .iter()
        .map(|t| t["action"].as_str().unwrap())
        .collect();
    assert!(actions.contains(&"transition"), "{actions:?}");
    assert!(actions.contains(&"remise"), "{actions:?}");
    for t in &traces {
        assert_eq!(t["issue"], "refusee_definitivement");
        assert_eq!(t["coursier"], json!(bac.coursier));
        // Aucun secret dans un événement d'opérations (SC-015).
        assert!(
            !t.to_string().contains(&secrets.code),
            "aucun code de remise dans une trace : {t}",
        );
    }

    // Et l'avance ENGAGÉE reste visible : l'arrêt collecté n'a pas été défait.
    // C'est ce qui permet au litige d'exister au lieu de disparaître (SC-016).
    assert_eq!(bac.statut_arret(arret).await, "collecte");
    assert_eq!(bac.nb_evenements("arret.collecte").await, 1);
}

/// Un échec déclaré par un coursier désassigné est refusé lui aussi — et l'arbre
/// §7.5 ne se déroule pas. Sans cette garde, une file périmée sanctionnerait un
/// client et déclencherait une indemnisation sur une course qui appartient
/// désormais à quelqu'un d'autre.
#[sqlx::test(migrations = "../migrations")]
async fn un_echec_rejoue_par_un_coursier_desassigne_ne_deroule_pas_l_arbre(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    // Preuves RÉELLES depuis T058 : `PreuvesFixes` n'est plus câblé, ici pas
    // plus qu'en production. Un échec se prépare donc comme sur le terrain.
    bac.reunir_les_trois_preuves(course.livraison).await;

    sqlx::query("UPDATE commandes.livraison SET coursier_id = $2 WHERE id = $1")
        .bind(course.livraison)
        .bind(bac.autre_coursier)
        .execute(&bac.pool)
        .await
        .unwrap();

    let (statut, corps) = bac
        .post(
            &format!("/courses/{}/echec", course.livraison),
            &bac.jeton_coursier,
            json!({
                "uuid_client": Uuid::now_v7(),
                "type_issue": "refus_perissable",
                "motif_cle": "echec.motif.client_injoignable",
            }),
        )
        .await;
    assert_eq!(statut, 403, "{corps}");
    assert_eq!(corps["code"], "non_proprietaire");

    let issues: i64 = sqlx::query_scalar("SELECT count(*) FROM commandes.issue_echec")
        .fetch_one(&bac.pool)
        .await
        .unwrap();
    assert_eq!(issues, 0, "l'arbre §7.5 ne s'est pas déroulé");
    assert_eq!(bac.nb_evenements("indemnisation.due").await, 0);
    assert_eq!(bac.nb_evenements("litige.ouvert").await, 0);

    let traces = bac.evenements("coursier.action_reconciliee").await;
    assert_eq!(traces.len(), 1);
    assert_eq!(traces[0]["action"], "echec");
}

/// **R4** — le rejeu d'un échec par son propriétaire ne déroule l'arbre qu'une
/// fois : une seule issue, une seule sanction, une seule indemnisation.
#[sqlx::test(migrations = "../migrations")]
async fn le_rejeu_d_un_echec_ne_deroule_l_arbre_qu_une_fois(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    // Preuves RÉELLES depuis T058 : `PreuvesFixes` n'est plus câblé, ici pas
    // plus qu'en production. Un échec se prépare donc comme sur le terrain.
    bac.reunir_les_trois_preuves(course.livraison).await;

    let uuid = Uuid::now_v7();
    let demande = json!({
        "uuid_client": uuid,
        "type_issue": "refus_perissable",
        "motif_cle": "echec.motif.client_injoignable",
    });
    let uri = format!("/courses/{}/echec", course.livraison);

    let (statut, premier) = bac.post(&uri, &bac.jeton_coursier, demande.clone()).await;
    assert_eq!(statut, 200, "{premier}");

    for tour in 1..=2 {
        let (statut, corps) = bac.post(&uri, &bac.jeton_coursier, demande.clone()).await;
        assert_eq!(statut, 200, "rejeu {tour} : {corps}");
        assert_eq!(
            corps["issue_id"], premier["issue_id"],
            "rejeu {tour} : la MÊME issue, pas une nouvelle",
        );
    }

    let issues: i64 = sqlx::query_scalar("SELECT count(*) FROM commandes.issue_echec")
        .fetch_one(&bac.pool)
        .await
        .unwrap();
    assert_eq!(issues, 1, "une issue pour un incident");
    assert_eq!(bac.nb_evenements("echec.issue_enregistree").await, 1);
    assert_eq!(bac.nb_evenements("indemnisation.due").await, 1);
    assert_eq!(bac.nb_evenements("litige.ouvert").await, 1);
}
