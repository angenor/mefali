//! US5 (CRS-06) — les surfaces d'**exploitation** de la caisse.
//!
//! Aucun écran Nuxt ce cycle (ADM-02/04/07 les habilleront) : ces endpoints
//! sont exercés par API, comme le cycle 009 l'a fait pour ses propres surfaces.
//! Un contrat qu'aucun test n'exerce n'est pas un contrat, c'est une intention.
//!
//! Ce que ce fichier tient :
//!
//! 1. **L'exposition égale la somme des avances** (FR-075, SC-010) — c'est le
//!    nombre qui dit combien d'argent de Mefali circule dans des poches. Une
//!    dérive qui ne s'y verrait pas ne se verrait qu'au comptage du soir.
//! 2. **Valider une indemnisation écrit au livre** (FR-072, SC-011) — dans la
//!    MÊME transaction que le changement d'état. Une validation sans son
//!    écriture laisserait Yao avec une promesse et rien dans sa caisse.
//! 3. **Refuser exige un motif** (FR-072) — un refus sans raison rend la
//!    promesse d'indemnisation invérifiable, donc sans valeur.
//! 4. **Une décision ne se reprend pas** — la seconde tentative est refusée en
//!    `409`, sinon deux validations paieraient deux fois.
//! 5. **Tout est sous rôle admin** (constitution VIII).

mod bac_coursier;

use bac_coursier::{Bac, Course};
use serde_json::{json, Value};
use sqlx::PgPool;
use uuid::Uuid;

/// Mène une course jusqu'à un échec **indemnisable** et rend l'indemnisation
/// « demandée » qui en naît.
///
/// Le faux billet (§7.5-6) : le client est parti avec la marchandise, le
/// coursier avec du papier. C'est le cas où « le coursier ne perd jamais » se
/// joue vraiment.
async fn indemnisation_demandee(bac: &Bac) -> (Course, Uuid, i64) {
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

    let (statut, file) = bac.get("/admin/indemnisations", &bac.jeton_admin).await;
    assert_eq!(statut, 200, "file des indemnisations : {file}");
    let i = &file["indemnisations"][0];
    let id: Uuid = i["id"]
        .as_str()
        .expect("une indemnisation attendue")
        .parse()
        .unwrap();
    (course, id, i["montant_unites"].as_i64().unwrap())
}

// ── FR-075 / SC-010 : l'exposition cash ────────────────────────────────────

/// L'exposition totale **égale** la somme des avances non soldées (SC-010).
///
/// Elle est lue sur le livre, pas sur un compteur tenu à part : un second
/// nombre à resynchroniser finirait par diverger, et personne ne saurait lequel
/// croire.
#[sqlx::test(migrations = "../migrations")]
async fn l_exposition_egale_la_somme_des_avances_en_cours(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    let attendu = bac.lire_caisse().await["avance_en_cours_unites"]
        .as_i64()
        .unwrap();
    assert!(attendu > 0);

    let (statut, expo) = bac
        .get("/admin/coursiers/exposition", &bac.jeton_admin)
        .await;
    assert_eq!(statut, 200, "exposition refusée : {expo}");
    assert_eq!(expo["total_unites"], json!(attendu));
    assert_eq!(expo["devise"], json!("XOF"));

    let lignes = expo["par_coursier"].as_array().unwrap();
    assert_eq!(lignes.len(), 1, "un seul coursier engagé");
    assert_eq!(lignes[0]["coursier_id"], json!(bac.coursier));
    assert_eq!(lignes[0]["avance_unites"], json!(attendu));
    assert_eq!(lignes[0]["courses"], json!(1));
}

/// Une course encaissée **sort** de l'exposition : l'argent est rentré.
///
/// Une exposition qui ne redescendrait jamais deviendrait un chiffre décoratif,
/// et le jour où il faut s'inquiéter, personne ne le remarquerait.
#[sqlx::test(migrations = "../migrations")]
async fn une_course_encaissee_sort_de_l_exposition(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    bac.arriver_chez_le_client(&course).await;
    let secrets = bac.secrets_remise(course.commande).await;
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "remise refusée : {corps}");
    bac.drainer_caisse().await;

    let (_, expo) = bac
        .get("/admin/coursiers/exposition", &bac.jeton_admin)
        .await;
    assert_eq!(expo["total_unites"], json!(0));
    assert!(
        expo["par_coursier"].as_array().unwrap().is_empty(),
        "un coursier à zéro n'encombre pas la liste",
    );
}

// ── FR-072 / SC-011 : valider et refuser ───────────────────────────────────

/// Valider écrit **l'argent au livre**, dans la même transaction (FR-072).
#[sqlx::test(migrations = "../migrations")]
async fn valider_une_indemnisation_porte_l_argent_au_livre(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, id, montant) = indemnisation_demandee(&bac).await;

    let avant = bac.ecritures_caisse(bac.coursier).await.len();
    let (statut, corps) = bac
        .post(
            &format!("/admin/indemnisations/{id}/valider"),
            &bac.jeton_admin,
            json!({}),
        )
        .await;
    assert_eq!(statut, 200, "validation refusée : {corps}");
    assert_eq!(corps["etat"], json!("validee"));
    assert!(
        corps["ecriture_id"].as_str().is_some(),
        "une validation SANS écriture serait une promesse vide : {corps}",
    );

    let ecritures = bac.ecritures_caisse(bac.coursier).await;
    assert_eq!(ecritures.len(), avant + 1, "une écriture, une seule");
    let derniere = ecritures.last().unwrap();
    assert_eq!(derniere.0, "indemnisation");
    assert_eq!(
        derniere.1, montant,
        "signe POSITIF : l'argent entre dans la poche de Yao",
    );

    // SC-011 — et Yao le voit dans SA caisse, sans redémarrer quoi que ce soit.
    let caisse = bac.lire_caisse().await;
    assert_eq!(caisse["indemnisations"][0]["etat"], json!("validee"));
}

/// Refuser **n'écrit rien**, mais laisse la raison lisible (FR-072).
#[sqlx::test(migrations = "../migrations")]
async fn refuser_une_indemnisation_n_ecrit_rien_mais_dit_pourquoi(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, id, _) = indemnisation_demandee(&bac).await;

    let avant = bac.ecritures_caisse(bac.coursier).await.len();
    let (statut, corps) = bac
        .post(
            &format!("/admin/indemnisations/{id}/refuser"),
            &bac.jeton_admin,
            json!({ "motif_cle": "indemnisation.refus.preuves_insuffisantes" }),
        )
        .await;
    assert_eq!(statut, 200, "refus motivé refusé : {corps}");
    assert_eq!(corps["etat"], json!("refusee"));
    assert_eq!(corps["ecriture_id"], Value::Null);
    assert_eq!(
        bac.ecritures_caisse(bac.coursier).await.len(),
        avant,
        "rien n'entre, rien ne sort",
    );

    let caisse = bac.lire_caisse().await;
    let i = &caisse["indemnisations"][0];
    assert_eq!(i["etat"], json!("refusee"));
    assert_eq!(
        i["decision_motif_cle"],
        json!("indemnisation.refus.preuves_insuffisantes"),
        "Yao doit pouvoir LIRE la raison",
    );
}

/// Un refus **sans motif** est refusé en `422`.
///
/// Sans cette garde, un refus muet serait indistinguable d'une erreur, et la
/// promesse d'indemnisation deviendrait invérifiable.
#[sqlx::test(migrations = "../migrations")]
async fn un_refus_sans_motif_est_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, id, _) = indemnisation_demandee(&bac).await;

    let (statut, _) = bac
        .post(
            &format!("/admin/indemnisations/{id}/refuser"),
            &bac.jeton_admin,
            json!({}),
        )
        .await;
    assert_eq!(statut, 422);
    assert_eq!(
        bac.lire_caisse().await["indemnisations"][0]["etat"],
        json!("demandee"),
        "l'indemnisation reste en attente d'une VRAIE décision",
    );
}

/// Une indemnisation déjà décidée ne se re-décide pas (`409`).
///
/// Deux validations paieraient deux fois la même chose — et sur un livre
/// append-only, la seconde ne s'effacerait pas.
#[sqlx::test(migrations = "../migrations")]
async fn une_indemnisation_deja_decidee_ne_se_redecide_pas(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, id, _) = indemnisation_demandee(&bac).await;

    let (statut, _) = bac
        .post(
            &format!("/admin/indemnisations/{id}/valider"),
            &bac.jeton_admin,
            json!({}),
        )
        .await;
    assert_eq!(statut, 200);
    let apres_une_validation = bac.ecritures_caisse(bac.coursier).await.len();

    for (chemin, corps) in [
        ("valider", json!({})),
        (
            "refuser",
            json!({ "motif_cle": "indemnisation.refus.erreur" }),
        ),
    ] {
        let (statut, _) = bac
            .post(
                &format!("/admin/indemnisations/{id}/{chemin}"),
                &bac.jeton_admin,
                corps,
            )
            .await;
        assert_eq!(statut, 409, "seconde décision `{chemin}` acceptée à tort");
    }
    assert_eq!(
        bac.ecritures_caisse(bac.coursier).await.len(),
        apres_une_validation,
        "aucune seconde écriture",
    );
}

/// La file se filtre par état — c'est ce dont l'exploitation a besoin pour
/// travailler sur les seules demandes en attente.
#[sqlx::test(migrations = "../migrations")]
async fn la_file_des_indemnisations_se_filtre_par_etat(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, id, _) = indemnisation_demandee(&bac).await;

    let (_, file) = bac
        .get("/admin/indemnisations?etat=demandee", &bac.jeton_admin)
        .await;
    assert_eq!(file["indemnisations"].as_array().unwrap().len(), 1);

    let (_, file) = bac
        .get("/admin/indemnisations?etat=validee", &bac.jeton_admin)
        .await;
    assert!(file["indemnisations"].as_array().unwrap().is_empty());

    bac.post(
        &format!("/admin/indemnisations/{id}/valider"),
        &bac.jeton_admin,
        json!({}),
    )
    .await;

    let (_, file) = bac
        .get("/admin/indemnisations?etat=validee", &bac.jeton_admin)
        .await;
    assert_eq!(file["indemnisations"].as_array().unwrap().len(), 1);

    // Un état inconnu ne rend pas une liste vide trompeuse : il est REFUSÉ.
    let (statut, _) = bac
        .get("/admin/indemnisations?etat=peut-etre", &bac.jeton_admin)
        .await;
    assert_eq!(statut, 422);
}

// ── Constitution VIII : rôle admin sur toute la surface ────────────────────

/// Aucune de ces surfaces n'est accessible sans le rôle admin.
///
/// Le coursier est le bon cobaye : il a un rôle valide et un intérêt direct à
/// valider ses propres indemnisations. C'est précisément ce que la garde
/// empêche.
#[sqlx::test(migrations = "../migrations")]
async fn toutes_les_surfaces_d_exploitation_exigent_le_role_admin(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let (_, id, _) = indemnisation_demandee(&bac).await;

    for uri in ["/admin/coursiers/exposition", "/admin/indemnisations"] {
        let (statut, _) = bac.get(uri, &bac.jeton_coursier).await;
        assert_eq!(statut, 403, "lecture `{uri}` autorisée à tort");
    }
    for chemin in ["valider", "refuser"] {
        let (statut, _) = bac
            .post(
                &format!("/admin/indemnisations/{id}/{chemin}"),
                &bac.jeton_coursier,
                json!({ "motif_cle": "indemnisation.refus.erreur" }),
            )
            .await;
        assert_eq!(statut, 403, "décision `{chemin}` autorisée à tort");
    }
    assert_eq!(
        bac.lire_caisse().await["indemnisations"][0]["etat"],
        json!("demandee"),
        "un coursier ne valide jamais sa propre indemnisation",
    );
}

/// L'exposition ne laisse échapper **aucun secret** (SC-015).
#[sqlx::test(migrations = "../migrations")]
async fn l_exposition_ne_sert_aucun_secret(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    let secrets = bac.secrets_remise(course.commande).await;
    bac.collecter_tout(&course).await;
    bac.drainer_caisse().await;

    let (_, expo) = bac
        .get("/admin/coursiers/exposition", &bac.jeton_admin)
        .await;
    let corps = expo.to_string();
    assert!(!corps.contains(&secrets.code));
    assert!(!corps.contains(&secrets.jeton));
    assert!(!corps.contains("+225"));
}
