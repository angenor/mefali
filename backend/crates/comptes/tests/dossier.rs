//! Dossier coursier (CPT-04) — soumission, re-soumission et PORTE de mise en
//! ligne (SC-005).
//!
//! Le fil conducteur de ces tests est l'invariant SC-005 : aucun chemin, aucune
//! combinaison n'ouvre la porte à un coursier qui n'est pas `valide`.

mod bac;

use bac::{Bac, SAISIE_LOCALE};
use comptes::dossier::{IssueSoumission, PieceIdentite, SoumissionDossier, PIECE_TAILLE_MAX};
use comptes::{ActionRole, Comptes, ErreurComptes, Role, StatutRole};
use sqlx::PgPool;
use uuid::Uuid;

/// Un JPEG minimal — les octets ne sont jamais interprétés, seul leur MIME
/// déclaré et leur taille le sont.
fn piece() -> PieceIdentite {
    PieceIdentite {
        octets: b"octets-de-la-piece".to_vec(),
        mime: "image/jpeg".to_owned(),
    }
}

fn soumission(vehicules: &[&str]) -> SoumissionDossier {
    SoumissionDossier {
        piece: piece(),
        referent_nom: "K. Abou".to_owned(),
        // Saisie LOCALE : la normalisation E.164 doit s'appliquer au référent
        // comme au titulaire du compte, sinon le CHECK de la base la refuse.
        referent_telephone: "0705060708".to_owned(),
        vehicules: vehicules.iter().map(|s| (*s).to_owned()).collect(),
    }
}

/// Ouvre une tx, soumet, et ne commit que si ça a marché (patron `role.rs`).
async fn soumettre(
    bac: &Bac,
    compte: uuid::Uuid,
    soumission: &SoumissionDossier,
) -> Result<IssueSoumission, ErreurComptes> {
    let mut tx = bac.pool.begin().await.unwrap();
    let r = bac
        .depot
        .soumettre_dossier_coursier(&mut tx, compte, soumission)
        .await;
    if r.is_ok() {
        tx.commit().await.unwrap();
    }
    r
}

async fn decider(
    bac: &Bac,
    compte: uuid::Uuid,
    action: ActionRole,
    admin: uuid::Uuid,
    motif: Option<&str>,
) {
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .decider_role(&mut tx, compte, Role::Coursier, action, admin, motif)
        .await
        .unwrap();
    tx.commit().await.unwrap();
}

/// US4 test indépendant, de bout en bout : soumission → porte fermée → refus →
/// re-soumission → validation → porte OUVERTE → suspension → porte refermée.
#[sqlx::test(migrations = "../../migrations")]
async fn cycle_complet_du_dossier_et_de_la_porte(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;
    let admin = bac.inscrire("0700000001").await;

    // Soumission (scénario 1).
    let IssueSoumission::Soumis(dossier) = soumettre(&bac, yao, &soumission(&["moto"]))
        .await
        .unwrap()
    else {
        panic!("un premier dossier est une vraie soumission, pas un rejeu");
    };
    assert_eq!(dossier.statut, StatutRole::EnAttente);
    assert_eq!(
        dossier.referent_telephone_e164, "+2250705060708",
        "le téléphone du référent est normalisé comme celui du compte"
    );
    assert_eq!(dossier.vehicules.len(), 1);
    assert_eq!(dossier.vehicules[0].slug, "moto");
    assert!(dossier.vehicules[0].actif_zone);

    // La pièce est bien partie au stockage objet, sous la clé conventionnelle.
    assert!(dossier.piece_cle_objet.starts_with(&format!("comptes/pieces/{yao}/")));
    assert_eq!(
        bac.objets.lire(&dossier.piece_cle_objet).as_deref(),
        Some(&b"octets-de-la-piece"[..]),
        "la pièce déposée est celle qui a été soumise"
    );

    // SC-005 — « en attente » ne franchit pas la porte.
    assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());
    // FR-018 — les capacités sont exposées dès la déclaration (le dispatch
    // filtrera ; la porte, elle, reste fermée).
    let capacites = bac.depot.capacites_transport(yao).await.unwrap();
    assert_eq!(capacites.len(), 1);
    assert_eq!(capacites[0].slug, "moto");

    // Les DEUX événements de la transition, dans la même transaction (T004).
    assert_eq!(bac.evenements("role.demande").await.len(), 1);
    let soumis = bac.evenements("dossier_coursier.soumis").await;
    assert_eq!(soumis.len(), 1);
    assert_eq!(soumis[0]["vehicules"], serde_json::json!(["moto"]));
    assert_eq!(soumis[0]["re_soumission"], false);
    assert_eq!(soumis[0]["compte"], serde_json::json!(yao));

    // Refus motivé (FR-017) — la porte reste fermée.
    decider(&bac, yao, ActionRole::Refuser, admin, Some("pièce illisible")).await;
    assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());
    let refuse = bac.depot.dossier_coursier(yao).await.unwrap();
    assert_eq!(refuse.statut, StatutRole::Refuse);
    assert_eq!(refuse.motif.as_deref(), Some("pièce illisible"));

    // Re-soumission : nouvelle pièce, nouvelle flotte, drapeau levé.
    let IssueSoumission::Soumis(deuxieme) = soumettre(&bac, yao, &soumission(&["velo", "a_pied"]))
        .await
        .unwrap()
    else {
        panic!("après un refus, la soumission repart vraiment");
    };
    assert_eq!(deuxieme.statut, StatutRole::EnAttente);
    assert!(deuxieme.motif.is_none(), "le motif du refus est effacé");
    assert_ne!(
        deuxieme.piece_cle_objet, dossier.piece_cle_objet,
        "la nouvelle pièce ne réutilise pas la clé de l'ancienne"
    );
    let soumis = bac.evenements("dossier_coursier.soumis").await;
    assert_eq!(soumis.len(), 2);
    assert_eq!(
        soumis[1]["re_soumission"], true,
        "le drapeau de re-soumission distingue le deuxième dépôt"
    );

    // La flotte est REMPLACÉE, pas cumulée.
    let capacites = bac.depot.capacites_transport(yao).await.unwrap();
    let slugs: Vec<&str> = capacites.iter().map(|c| c.slug.as_str()).collect();
    assert_eq!(
        slugs,
        vec!["a_pied", "velo"],
        "les véhicules de la re-soumission remplacent les précédents (ordre du référentiel)"
    );

    // Validation → LA porte s'ouvre (scénario 3).
    decider(&bac, yao, ActionRole::Valider, admin, None).await;
    assert!(bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());

    // Suspension motivée → elle se referme dès la requête suivante (scénario 5).
    decider(&bac, yao, ActionRole::Suspendre, admin, Some("plaintes")).await;
    assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());

    // Rétablissement → elle se rouvre.
    decider(&bac, yao, ActionRole::Retablir, admin, None).await;
    assert!(bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());
}

/// FR-015 scénario 1 — un dossier incomplet n'est pas soumis, et ne laisse RIEN.
#[sqlx::test(migrations = "../../migrations")]
async fn dossier_incomplet_non_soumis(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    let incomplets = [
        (
            "aucun véhicule",
            SoumissionDossier {
                vehicules: vec![],
                ..soumission(&[])
            },
        ),
        (
            "référent sans nom",
            SoumissionDossier {
                referent_nom: "   ".to_owned(),
                ..soumission(&["moto"])
            },
        ),
        (
            "pièce vide",
            SoumissionDossier {
                piece: PieceIdentite {
                    octets: Vec::new(),
                    mime: "image/jpeg".to_owned(),
                },
                ..soumission(&["moto"])
            },
        ),
    ];

    for (cas, incomplet) in incomplets {
        assert!(
            matches!(
                soumettre(&bac, yao, &incomplet).await,
                Err(ErreurComptes::DossierIncomplet)
            ),
            "{cas} doit être refusé"
        );
    }

    assert_eq!(bac.compter("SELECT count(*) FROM comptes.dossier_coursier").await, 0);
    assert_eq!(
        bac.depot.attributions(yao).await.unwrap().len(),
        1,
        "seul le rôle client existe : aucune demande coursier n'a été ouverte"
    );
    assert_eq!(bac.objets.nombre(), 0, "aucun octet déposé pour rien");
    assert_eq!(bac.evenements("role.demande").await.len(), 0);
}

/// FR-015 scénario 6 — seuls les types ACTIFS de la zone sont déclarables.
#[sqlx::test(migrations = "../../migrations")]
async fn vehicule_hors_zone_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    // `camion` EXISTE au référentiel, mais n'est pas actif à Tiassalé.
    assert!(matches!(
        soumettre(&bac, yao, &soumission(&["camion"])).await,
        Err(ErreurComptes::VehiculeHorsZone(slug)) if slug == "camion"
    ));
    // Un slug inconnu du référentiel est le MÊME refus — le client n'apprend
    // rien du référentiel qu'il ne sache déjà par sa config de zone.
    assert!(matches!(
        soumettre(&bac, yao, &soumission(&["licorne"])).await,
        Err(ErreurComptes::VehiculeHorsZone(slug)) if slug == "licorne"
    ));
    // Un seul véhicule hors zone invalide TOUTE la soumission.
    assert!(matches!(
        soumettre(&bac, yao, &soumission(&["moto", "camion"])).await,
        Err(ErreurComptes::VehiculeHorsZone(_))
    ));

    assert_eq!(bac.objets.nombre(), 0, "rien n'est déposé pour un refus");
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.vehicule_declare").await, 0);
}

/// Edge case spec — un type DÉSACTIVÉ après déclaration reste déclaré, signalé.
#[sqlx::test(migrations = "../../migrations")]
async fn type_desactive_apres_declaration_conserve_mais_signale(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    soumettre(&bac, yao, &soumission(&["moto", "velo"]))
        .await
        .unwrap();

    // La ville retire la moto de ses transports actifs.
    bac.definir_transports_actifs(&["a_pied", "velo"]).await;

    let dossier = bac.depot.dossier_coursier(yao).await.unwrap();
    assert_eq!(
        dossier.vehicules.len(),
        2,
        "le véhicule déclaré est CONSERVÉ, pas effacé"
    );
    let moto = dossier.vehicules.iter().find(|v| v.slug == "moto").unwrap();
    let velo = dossier.vehicules.iter().find(|v| v.slug == "velo").unwrap();
    assert!(!moto.actif_zone, "il est signalé comme hors zone");
    assert!(velo.actif_zone);

    // …mais il n'est plus déclarable dans une NOUVELLE soumission.
    let admin = bac.inscrire("0700000001").await;
    decider(&bac, yao, ActionRole::Refuser, admin, Some("à revoir")).await;
    assert!(matches!(
        soumettre(&bac, yao, &soumission(&["moto"])).await,
        Err(ErreurComptes::VehiculeHorsZone(_))
    ));
}

/// R14 — le rejeu d'une soumission pendant `en_attente` ne change RIEN.
#[sqlx::test(migrations = "../../migrations")]
async fn rejeu_pendant_en_attente_est_idempotent(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    let IssueSoumission::Soumis(premier) = soumettre(&bac, yao, &soumission(&["moto"]))
        .await
        .unwrap()
    else {
        panic!("première soumission");
    };

    // Le réseau a coupé, le client rejoue.
    let IssueSoumission::DejaEnAttente(rejeu) = soumettre(&bac, yao, &soumission(&["velo"]))
        .await
        .unwrap()
    else {
        panic!("un rejeu pendant `en_attente` doit être reconnu comme tel");
    };

    assert_eq!(
        rejeu.piece_cle_objet, premier.piece_cle_objet,
        "le rejeu rend l'état COURANT : pas de nouvelle pièce"
    );
    assert_eq!(rejeu.soumis_le, premier.soumis_le);
    assert_eq!(bac.objets.nombre(), 1, "aucun octet déposé deux fois");
    assert_eq!(
        bac.evenements("dossier_coursier.soumis").await.len(),
        1,
        "un rejeu n'émet pas un deuxième événement"
    );
    assert_eq!(bac.evenements("role.demande").await.len(), 1);
}

/// R14 — le 409 reste réservé aux transitions VRAIMENT invalides.
#[sqlx::test(migrations = "../../migrations")]
async fn soumission_refusee_sur_dossier_valide_ou_suspendu(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;
    let admin = bac.inscrire("0700000001").await;

    soumettre(&bac, yao, &soumission(&["moto"])).await.unwrap();
    decider(&bac, yao, ActionRole::Valider, admin, None).await;

    assert!(
        matches!(
            soumettre(&bac, yao, &soumission(&["velo"])).await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ),
        "un coursier VALIDÉ ne re-soumet pas un dossier"
    );

    decider(&bac, yao, ActionRole::Suspendre, admin, Some("plaintes")).await;
    assert!(
        matches!(
            soumettre(&bac, yao, &soumission(&["velo"])).await,
            Err(ErreurComptes::TransitionInvalide { .. })
        ),
        "un coursier SUSPENDU ne se re-valide pas en re-soumettant"
    );

    // Et surtout : aucun de ces refus n'a déposé d'octets ni touché la flotte.
    assert_eq!(bac.objets.nombre(), 1);
    let capacites = bac.depot.capacites_transport(yao).await.unwrap();
    assert_eq!(capacites[0].slug, "moto");
}

/// La pièce est bornée en taille et en type (constantes produit).
#[sqlx::test(migrations = "../../migrations")]
async fn piece_trop_volumineuse_ou_de_type_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    let trop_grosse = SoumissionDossier {
        piece: PieceIdentite {
            octets: vec![0u8; PIECE_TAILLE_MAX + 1],
            mime: "image/jpeg".to_owned(),
        },
        ..soumission(&["moto"])
    };
    assert!(matches!(
        soumettre(&bac, yao, &trop_grosse).await,
        Err(ErreurComptes::ObjetTropVolumineux)
    ));

    let mauvais_type = SoumissionDossier {
        piece: PieceIdentite {
            octets: b"MZ".to_vec(),
            mime: "application/x-msdownload".to_owned(),
        },
        ..soumission(&["moto"])
    };
    assert!(matches!(
        soumettre(&bac, yao, &mauvais_type).await,
        Err(ErreurComptes::MediaInvalide(_))
    ));

    assert_eq!(bac.objets.nombre(), 0);
}

/// Le référent est normalisé, et un référent non normalisable est refusé —
/// AVANT que le CHECK de la base ne rende une erreur SQL brute.
#[sqlx::test(migrations = "../../migrations")]
async fn referent_non_normalisable_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    let mauvais = SoumissionDossier {
        referent_telephone: "pas-un-numero".to_owned(),
        ..soumission(&["moto"])
    };
    assert!(matches!(
        soumettre(&bac, yao, &mauvais).await,
        Err(ErreurComptes::TelephoneInvalide)
    ));
    assert_eq!(bac.objets.nombre(), 0);
}

/// Constitution VI — un rollback ne laisse ni dossier, ni rôle, ni événement.
#[sqlx::test(migrations = "../../migrations")]
async fn rollback_ne_laisse_ni_dossier_ni_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .soumettre_dossier_coursier(&mut tx, yao, &soumission(&["moto"]))
        .await
        .unwrap();
    tx.rollback().await.unwrap();

    assert_eq!(bac.compter("SELECT count(*) FROM comptes.dossier_coursier").await, 0);
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.vehicule_declare").await, 0);
    assert_eq!(bac.evenements("role.demande").await.len(), 0);
    assert_eq!(bac.evenements("dossier_coursier.soumis").await.len(), 0);
    assert!(!bac.depot.coursier_autorise_en_ligne(yao).await.unwrap());
    // Seule trace : l'objet déposé, orphelin et inoffensif — aucun stockage
    // objet n'est transactionnel, et l'ordre choisi garantit que le pire cas
    // est un octet perdu, jamais une ligne qui pointe dans le vide.
    assert_eq!(bac.objets.nombre(), 1);
}

/// Les doublons de saisie ne font pas exploser la contrainte UNIQUE.
#[sqlx::test(migrations = "../../migrations")]
async fn vehicule_declare_deux_fois_est_dedoublonne(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    let IssueSoumission::Soumis(dossier) = soumettre(&bac, yao, &soumission(&["moto", "moto"]))
        .await
        .unwrap()
    else {
        panic!("soumission");
    };
    assert_eq!(dossier.vehicules.len(), 1);
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.vehicule_declare").await, 1);
}

/// Un compte inconnu n'a pas de dossier à soumettre ni à lire.
#[sqlx::test(migrations = "../../migrations")]
async fn compte_ou_dossier_inconnu(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    assert!(matches!(
        soumettre(&bac, Uuid::now_v7(), &soumission(&["moto"])).await,
        Err(ErreurComptes::CompteInconnu(_))
    ));
    assert!(
        matches!(
            bac.depot.dossier_coursier(yao).await,
            Err(ErreurComptes::DossierInconnu(_))
        ),
        "un compte sans dossier n'en a pas un vide : il n'en a pas"
    );
}

/// FR-017 — la liste admin sert la revue, filtrable par statut.
#[sqlx::test(migrations = "../../migrations")]
async fn liste_admin_filtrable_par_statut(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;
    let ama = bac.inscrire("0709080706").await;
    let admin = bac.inscrire("0700000001").await;

    soumettre(&bac, yao, &soumission(&["moto"])).await.unwrap();
    soumettre(&bac, ama, &soumission(&["velo"])).await.unwrap();
    decider(&bac, ama, ActionRole::Valider, admin, None).await;

    let tous = bac.depot.dossiers_coursier(None).await.unwrap();
    assert_eq!(tous.len(), 2);

    let attente = bac
        .depot
        .dossiers_coursier(Some(StatutRole::EnAttente))
        .await
        .unwrap();
    assert_eq!(attente.len(), 1);
    assert_eq!(attente[0].dossier.compte_id, yao);
    assert_eq!(
        attente[0].telephone_e164, "+2250701020304",
        "l'admin doit pouvoir rappeler le coursier (FR-017)"
    );
    assert_eq!(attente[0].dossier.vehicules[0].slug, "moto");

    let valides = bac
        .depot
        .dossiers_coursier(Some(StatutRole::Valide))
        .await
        .unwrap();
    assert_eq!(valides.len(), 1);
    assert_eq!(valides[0].dossier.compte_id, ama);

    // Détail admin : mêmes données, par compte.
    let detail = bac.depot.dossier_coursier_admin(yao).await.unwrap();
    assert_eq!(detail.dossier.statut, StatutRole::EnAttente);
    assert_eq!(detail.telephone_e164, "+2250701020304");
}
