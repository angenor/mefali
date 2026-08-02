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
    let IssueSoumission::Soumis {
        dossier,
        piece_orpheline,
    } = soumettre(&bac, yao, &soumission(&["moto"])).await.unwrap()
    else {
        panic!("un premier dossier est une vraie soumission, pas un rejeu");
    };
    assert!(
        piece_orpheline.is_none(),
        "une première soumission ne déréférence aucune pièce"
    );
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
    let IssueSoumission::Soumis {
        dossier: deuxieme,
        piece_orpheline,
    } = soumettre(&bac, yao, &soumission(&["velo", "a_pied"]))
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
    // …et parce qu'elle ne la réutilise pas, l'ancienne pièce n'est plus
    // référencée par rien : le domaine la remonte pour que l'appelant la
    // supprime après commit (constitution VIII). Le domaine, lui, ne l'a PAS
    // supprimée — il ne possède pas la transaction.
    assert_eq!(
        piece_orpheline.as_deref(),
        Some(dossier.piece_cle_objet.as_str()),
        "la pièce déréférencée est remontée à l'appelant"
    );
    assert!(
        bac.objets.lire(&dossier.piece_cle_objet).is_some(),
        "le domaine ne supprime rien lui-même : c'est le handler, après commit"
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

    let IssueSoumission::Soumis { dossier: premier, .. } =
        soumettre(&bac, yao, &soumission(&["moto"])).await.unwrap()
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

/// R14 sous VRAIE concurrence — deux `POST /moi/dossier-coursier` réellement
/// simultanés du même compte (chacun dans SA transaction) ne produisent qu'UNE
/// soumission : le verrou consultatif par compte les sérialise, la perdante
/// re-lit `en_attente` et retombe sur `DejaEnAttente`.
///
/// L'issue est DÉTERMINISTE (une seule gagne) même si l'ordonnancement, lui, ne
/// l'est pas. Honnêteté du garde-fou : SANS le verrou, ce test peut passer par
/// CHANCE (les deux appels ne se chevauchent pas toujours) ; AVEC le verrou il
/// passe TOUJOURS — c'est ce qui en fait une régression détectable.
#[sqlx::test(migrations = "../../migrations")]
async fn deux_soumissions_concurrentes_une_seule_gagne(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    // Les deux soumissions partent EN MÊME TEMPS (le pool de test tient
    // plusieurs connexions) : c'est la course R14, pas un rejeu séquentiel.
    let (moto, velo) = (soumission(&["moto"]), soumission(&["velo"]));
    let (a, b) = tokio::join!(
        soumettre(&bac, yao, &moto),
        soumettre(&bac, yao, &velo),
    );

    // Exactement une `Soumis`, exactement une `DejaEnAttente` — peu importe
    // laquelle des deux a gagné la course.
    let (soumis, deja) =
        [a.unwrap(), b.unwrap()]
            .iter()
            .fold((0, 0), |(s, d), issue| match issue {
                IssueSoumission::Soumis { .. } => (s + 1, d),
                IssueSoumission::DejaEnAttente(_) => (s, d + 1),
            });
    assert_eq!(soumis, 1, "une seule soumission gagne la course");
    assert_eq!(deja, 1, "l'autre retombe sur le rejeu idempotent");

    // UN seul de chaque événement : le double `role.demande` /
    // `dossier_coursier.soumis` était précisément le défaut à fermer.
    assert_eq!(bac.evenements("role.demande").await.len(), 1);
    assert_eq!(bac.evenements("dossier_coursier.soumis").await.len(), 1);

    // ZÉRO pièce orpheline : la perdante ressort AVANT le dépôt, un seul octet
    // a donc été déposé.
    assert_eq!(
        bac.objets.nombre(),
        1,
        "la soumission perdante n'a déposé aucune pièce orpheline"
    );
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

    let IssueSoumission::Soumis { dossier, .. } =
        soumettre(&bac, yao, &soumission(&["moto", "moto"])).await.unwrap()
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

// ── Changer de véhicule sans repasser par l'admin (CPT-04) ─────────────────
//
// Le défaut que ces tests ferment a été trouvé sur appareil : un coursier au
// rôle VALIDÉ mais sans véhicule ne peut pas passer en ligne, et la seule
// surface de déclaration — le formulaire d'inscription — lui est devenue
// inatteignable. Il ne peut plus travailler, et rien ne l'en sort.

/// Ouvre une tx, remplace, et ne commit que si ça a marché.
async fn remplacer(
    bac: &Bac,
    compte: uuid::Uuid,
    slugs: &[&str],
) -> Result<comptes::IssueVehicules, ErreurComptes> {
    let owned: Vec<String> = slugs.iter().map(|s| (*s).to_owned()).collect();
    let mut tx = bac.pool.begin().await.unwrap();
    let r = bac
        .depot
        .remplacer_vehicules_declares(&mut tx, compte, &owned)
        .await;
    if r.is_ok() {
        tx.commit().await.unwrap();
    }
    r
}

/// Prépare un coursier au rôle VALIDÉ, avec la flotte donnée.
async fn coursier_valide(bac: &Bac, telephone: &str, flotte: &[&str]) -> uuid::Uuid {
    let compte = bac.inscrire(telephone).await;
    let admin = bac.inscrire("0700000009").await;
    soumettre(bac, compte, &soumission(flotte)).await.unwrap();
    decider(bac, compte, ActionRole::Valider, admin, None).await;
    compte
}

/// LE test du correctif : la flotte change, le rôle ne bouge pas, la porte
/// reste ouverte — aucune revue admin n'est déclenchée.
#[sqlx::test(migrations = "../../migrations")]
async fn un_coursier_valide_change_ses_vehicules_sans_revue_admin(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = coursier_valide(&bac, SAISIE_LOCALE, &["moto"]).await;

    assert!(
        bac.depot.coursier_autorise_en_ligne(yao).await.unwrap(),
        "prérequis : la porte est ouverte avant le geste"
    );

    let comptes::IssueVehicules::Modifiee(dossier) = remplacer(&bac, yao, &["velo"]).await.unwrap()
    else {
        panic!("changer de moto pour un vélo est une modification");
    };

    assert_eq!(dossier.vehicules.len(), 1);
    assert_eq!(dossier.vehicules[0].slug, "velo");
    assert_eq!(
        dossier.statut,
        StatutRole::Valide,
        "le rôle a été validé sur la pièce d'identité, pas sur le véhicule : \
         il ne retombe PAS en attente"
    );
    assert!(
        bac.depot.coursier_autorise_en_ligne(yao).await.unwrap(),
        "la porte reste ouverte — sinon le blocage est seulement déplacé"
    );

    // FR-018 — le dispatch voit la nouvelle flotte, pas l'ancienne.
    let capacites = bac.depot.capacites_transport(yao).await.unwrap();
    assert_eq!(capacites.len(), 1);
    assert_eq!(capacites[0].slug, "velo");

    // Le changement est TRACÉ : il déplace l'éligibilité au dispatch.
    let traces = bac.evenements("dossier_coursier.vehicules_modifies").await;
    assert_eq!(traces.len(), 1);
    assert_eq!(traces[0]["vehicules"], serde_json::json!(["velo"]));
    assert_eq!(
        traces[0]["avant"],
        serde_json::json!(["moto"]),
        "la table ne garde aucun historique : l'événement est la seule trace \
         de ce qui a été remplacé"
    );
    assert_eq!(traces[0]["compte"], serde_json::json!(yao));

    // Et surtout : AUCUN événement de re-soumission ni de transition de rôle.
    assert_eq!(
        bac.evenements("dossier_coursier.soumis").await.len(),
        1,
        "un seul dépôt de dossier — celui de l'inscription"
    );
    assert!(
        bac.evenements("role.demande").await.len() == 1,
        "changer de véhicule ne redemande pas le rôle"
    );
}

/// Rejeu réseau : la même flotte deux fois n'écrit rien et n'émet rien.
#[sqlx::test(migrations = "../../migrations")]
async fn une_flotte_identique_ne_laisse_aucune_trace(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = coursier_valide(&bac, SAISIE_LOCALE, &["moto"]).await;

    remplacer(&bac, yao, &["velo"]).await.unwrap();
    let issue = remplacer(&bac, yao, &["velo"]).await.unwrap();

    assert!(
        matches!(issue, comptes::IssueVehicules::Inchangee(_)),
        "redéclarer la même flotte n'est pas un changement"
    );
    assert_eq!(
        bac.evenements("dossier_coursier.vehicules_modifies")
            .await
            .len(),
        1,
        "un rejeu ne doit pas produire une seconde trace d'un changement qui \
         n'a eu lieu qu'une fois"
    );
}

/// L'ordre de saisie ne fait pas un changement — « moto, vélo » vaut
/// « vélo, moto », et « moto, moto » vaut « moto ».
#[sqlx::test(migrations = "../../migrations")]
async fn l_ordre_et_les_doublons_ne_font_pas_un_changement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = coursier_valide(&bac, SAISIE_LOCALE, &["moto"]).await;

    remplacer(&bac, yao, &["moto", "velo"]).await.unwrap();
    let issue = remplacer(&bac, yao, &["velo", "moto", "moto"])
        .await
        .unwrap();

    assert!(
        matches!(issue, comptes::IssueVehicules::Inchangee(_)),
        "même ensemble de véhicules, écrit autrement"
    );
    assert_eq!(
        bac.evenements("dossier_coursier.vehicules_modifies")
            .await
            .len(),
        1
    );
}

/// SC-005 — un dossier qui n'est pas `valide` ne touche pas à sa flotte. Sans
/// cette garde, un coursier refusé se redonnerait des capacités.
#[sqlx::test(migrations = "../../migrations")]
async fn un_dossier_non_valide_ne_change_pas_ses_vehicules(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let admin = bac.inscrire("0700000009").await;
    let yao = bac.inscrire(SAISIE_LOCALE).await;

    // En attente.
    soumettre(&bac, yao, &soumission(&["moto"])).await.unwrap();
    assert!(matches!(
        remplacer(&bac, yao, &["velo"]).await,
        Err(ErreurComptes::TransitionInvalide { .. })
    ));

    // Refusé.
    decider(&bac, yao, ActionRole::Refuser, admin, Some("illisible")).await;
    assert!(matches!(
        remplacer(&bac, yao, &["velo"]).await,
        Err(ErreurComptes::TransitionInvalide { .. })
    ));

    // Suspendu — le cas qui compte : le rôle a existé, il est retiré.
    soumettre(&bac, yao, &soumission(&["moto"])).await.unwrap();
    decider(&bac, yao, ActionRole::Valider, admin, None).await;
    decider(&bac, yao, ActionRole::Suspendre, admin, Some("plaintes")).await;
    assert!(matches!(
        remplacer(&bac, yao, &["velo"]).await,
        Err(ErreurComptes::TransitionInvalide { .. })
    ));

    // La flotte n'a pas bougé d'un pouce, et rien n'a été tracé.
    let dossier = bac.depot.dossier_coursier(yao).await.unwrap();
    assert_eq!(dossier.vehicules[0].slug, "moto");
    assert!(bac
        .evenements("dossier_coursier.vehicules_modifies")
        .await
        .is_empty());
}

/// Un compte sans dossier : 404, et non le `500` opaque que la clé étrangère
/// produirait si on écrivait d'abord.
#[sqlx::test(migrations = "../../migrations")]
async fn sans_dossier_le_remplacement_est_introuvable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let sans_dossier = coursier_valide(&bac, SAISIE_LOCALE, &["moto"]).await;

    // Rôle coursier VALIDE, dossier absent. L'état s'atteint par les fixtures
    // qui posent le rôle en SQL direct (`bac_dispatch`), et par une purge de
    // données personnelles. C'est précisément là que la clé étrangère de
    // `vehicule_declare` rendrait un `INSERT` sans dossier en `500` opaque.
    sqlx::query!(
        "DELETE FROM comptes.dossier_coursier WHERE compte_id = $1",
        sans_dossier
    )
    .execute(&bac.pool)
    .await
    .unwrap();

    assert!(matches!(
        remplacer(&bac, sans_dossier, &["moto"]).await,
        Err(ErreurComptes::DossierInconnu(_))
    ));
}

/// Une flotte vide reconstruirait l'impasse que cette route existe pour ouvrir.
#[sqlx::test(migrations = "../../migrations")]
async fn une_flotte_vide_est_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = coursier_valide(&bac, SAISIE_LOCALE, &["moto"]).await;

    assert!(matches!(
        remplacer(&bac, yao, &[]).await,
        Err(ErreurComptes::DossierIncomplet)
    ));
    assert_eq!(
        bac.depot
            .capacites_transport(yao)
            .await
            .unwrap()
            .len(),
        1,
        "le refus ne laisse pas la flotte à moitié effacée"
    );
}

/// Le référentiel de zone fait foi ici comme à la soumission (FR-015).
#[sqlx::test(migrations = "../../migrations")]
async fn un_vehicule_hors_zone_est_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.seeder_transports().await;
    let yao = coursier_valide(&bac, SAISIE_LOCALE, &["moto"]).await;

    assert!(matches!(
        remplacer(&bac, yao, &["helicoptere"]).await,
        Err(ErreurComptes::VehiculeHorsZone(_))
    ));
    assert_eq!(bac.depot.capacites_transport(yao).await.unwrap()[0].slug, "moto");
}
