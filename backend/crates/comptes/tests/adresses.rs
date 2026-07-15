//! Adresses enregistrées et purge du repère vocal (CPT-05).
//!
//! Le fil conducteur : le repère est ce qui permet de TROUVER Awa. Il doit
//! survivre intact à un aller-retour (SC-007), et disparaître seul après 12
//! mois sans usage (FR-022) — sans emporter l'adresse.

mod bac;

use bac::{Bac, SAISIE_LOCALE};
use comptes::adresse::{
    ModificationAdresse, NoteVocale, NouvelleAdresse, NOTE_VOCALE_TAILLE_MAX,
};
use comptes::ErreurComptes;
use sqlx::PgPool;
use uuid::Uuid;

/// Les octets EXACTS d'un repère parlé : « derrière la pharmacie, portail bleu ».
const OCTETS_NOTE: &[u8] = b"\x00\x00\x00\x1cftypM4A .....octets-de-la-note-vocale";

fn note() -> NoteVocale {
    NoteVocale {
        octets: OCTETS_NOTE.to_vec(),
        mime: "audio/mp4".to_owned(),
        duree_s: 12,
    }
}

fn nouvelle(libelle: &str) -> NouvelleAdresse {
    NouvelleAdresse {
        libelle: libelle.to_owned(),
        lat: 5.898,
        lng: -4.823,
        repere_texte: Some("Derrière la pharmacie, portail bleu".to_owned()),
        note_vocale: Some(note()),
        livraison_origine: None,
    }
}

async fn enregistrer(
    bac: &Bac,
    id: Uuid,
    compte: Uuid,
    nouvelle: &NouvelleAdresse,
) -> Result<comptes::Adresse, ErreurComptes> {
    let mut tx = bac.pool.begin().await.unwrap();
    let r = bac
        .depot
        .enregistrer_adresse(&mut tx, id, compte, nouvelle)
        .await;
    if r.is_ok() {
        tx.commit().await.unwrap();
    }
    r
}

/// US5 test indépendant — enregistrement, réutilisation à l'identique, gestion.
#[sqlx::test(migrations = "../../migrations")]
async fn cycle_complet_de_l_adresse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let id = Uuid::now_v7();

    // Enregistrement (scénario 1).
    let adresse = enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();
    assert_eq!(adresse.id, id, "l'id EST la clé d'idempotence du client (R14)");
    assert_eq!(adresse.libelle, "Maison");
    assert!(adresse.a_repere_vocal());
    assert_eq!(adresse.repere_vocal_duree_s, Some(12));

    // SC-007 — la note rejouée est identique à l'originale, octet pour octet.
    let cle = adresse.repere_vocal_cle_objet.clone().unwrap();
    assert!(cle.starts_with(&format!("comptes/reperes/{awa}/")));
    assert_eq!(
        bac.objets.lire(&cle).as_deref(),
        Some(OCTETS_NOTE),
        "SC-007 — le repère vocal est rendu tel quel : c'est ce qui permet au \
         coursier de trouver Awa"
    );

    // Minimisation ARTCI : l'événement ne porte NI le libellé, NI le GPS, NI
    // le repère — seulement des booléens de présence (T004).
    let evenements = bac.evenements("adresse.enregistree").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(evenements[0]["a_repere_texte"], true);
    assert_eq!(evenements[0]["a_repere_vocal"], true);
    assert_eq!(evenements[0]["compte"], serde_json::json!(awa));
    let brut = evenements[0].to_string();
    assert!(!brut.contains("Maison"), "aucun libellé dans l'événement");
    assert!(!brut.contains("5.898"), "aucune position dans l'événement");
    assert!(
        !brut.contains("pharmacie"),
        "aucun repère dans l'événement (minimisation ARTCI)"
    );

    // Réutilisation « en un geste » : tout est là, sans ressaisie (scénario 2).
    let liste = bac.depot.adresses(awa).await.unwrap();
    assert_eq!(liste.len(), 1);
    assert_eq!(liste[0].lat, 5.898);
    assert_eq!(liste[0].repere_texte.as_deref(), Some("Derrière la pharmacie, portail bleu"));

    // Renommage (scénario 4).
    let renommee = {
        let mut tx = bac.pool.begin().await.unwrap();
        let a = bac
            .depot
            .modifier_adresse(
                &mut tx,
                id,
                awa,
                &ModificationAdresse {
                    libelle: Some("Chez maman".to_owned()),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
        tx.commit().await.unwrap();
        a
    };
    assert_eq!(renommee.libelle, "Chez maman");
    let modifs = bac.evenements("adresse.modifiee").await;
    assert_eq!(modifs.len(), 1);
    assert_eq!(modifs[0]["champs"], serde_json::json!(["libelle"]));

    // Suppression SOFT (scénario 4).
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot.supprimer_adresse(&mut tx, id, awa).await.unwrap();
    tx.commit().await.unwrap();

    assert!(bac.depot.adresses(awa).await.unwrap().is_empty());
    assert_eq!(
        bac.compter("SELECT count(*) FROM comptes.adresse").await,
        1,
        "soft delete : la ligne reste, une commande passée peut la référencer"
    );
    assert_eq!(bac.evenements("adresse.supprimee").await.len(), 1);
}

/// R14 — le rejeu de la même clé ne crée PAS de doublon.
#[sqlx::test(migrations = "../../migrations")]
async fn rejeu_rend_l_adresse_existante_sans_doublon(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let id = Uuid::now_v7();

    let premiere = enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();
    // Le réseau a coupé : le client rejoue la MÊME clé.
    let rejeu = enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();

    assert_eq!(rejeu.id, premiere.id);
    assert_eq!(
        rejeu.repere_vocal_cle_objet, premiere.repere_vocal_cle_objet,
        "le rejeu ne redépose pas la note"
    );
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.adresse").await, 1);
    assert_eq!(bac.objets.nombre(), 1, "aucun octet déposé deux fois");
    assert_eq!(
        bac.evenements("adresse.enregistree").await.len(),
        1,
        "un rejeu n'est pas un enregistrement"
    );
}

/// FR-022 — purge à 12 mois SANS utilisation ; l'adresse SURVIT.
#[sqlx::test(migrations = "../../migrations")]
async fn purge_repere_vocal(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let vieille = Uuid::now_v7();
    let recente = Uuid::now_v7();

    enregistrer(&bac, vieille, awa, &nouvelle("Maison")).await.unwrap();
    enregistrer(&bac, recente, awa, &nouvelle("Bureau")).await.unwrap();
    let cle_vieille = bac
        .depot
        .adresse(vieille, awa)
        .await
        .unwrap()
        .repere_vocal_cle_objet
        .unwrap();

    // 366 jours sans utilisation : au-delà de la rétention de zone (365).
    sqlx::query("UPDATE comptes.adresse SET derniere_utilisation_le = now() - interval '366 days' WHERE id = $1")
        .bind(vieille)
        .execute(&bac.pool)
        .await
        .unwrap();

    assert_eq!(bac.depot.purger_reperes_vocaux().await.unwrap(), 1);

    // La vieille a perdu son repère…
    let purgee = bac.depot.adresse(vieille, awa).await.unwrap();
    assert!(!purgee.a_repere_vocal());
    assert!(purgee.repere_vocal_duree_s.is_none());
    assert_eq!(
        bac.objets.lire(&cle_vieille),
        None,
        "l'objet est supprimé du stockage, pas seulement déréférencé"
    );

    // …mais elle reste UTILISABLE (FR-022) : c'est tout l'enjeu.
    assert_eq!(purgee.libelle, "Maison");
    assert_eq!(purgee.lat, 5.898);
    assert!(bac.depot.adresses(awa).await.unwrap().iter().any(|a| a.id == vieille));

    // L'événement porte la rétention APPLIQUÉE (celle de la zone, pas 365 en dur).
    let purges = bac.evenements("adresse.repere_vocal_purge").await;
    assert_eq!(purges.len(), 1);
    assert_eq!(purges[0]["retention_jours"], 365);
    assert_eq!(purges[0]["compte"], serde_json::json!(awa));

    // La récente est intacte.
    assert!(bac.depot.adresse(recente, awa).await.unwrap().a_repere_vocal());

    // Idempotence du job : un second passage ne repurge rien.
    assert_eq!(bac.depot.purger_reperes_vocaux().await.unwrap(), 0);
    assert_eq!(bac.evenements("adresse.repere_vocal_purge").await.len(), 1);
}

/// FR-022 — une adresse UTILISÉE ne perd jamais son repère.
#[sqlx::test(migrations = "../../migrations")]
async fn adresse_utilisee_repousse_sa_purge(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let id = Uuid::now_v7();
    enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();

    sqlx::query("UPDATE comptes.adresse SET derniere_utilisation_le = now() - interval '366 days' WHERE id = $1")
        .bind(id)
        .execute(&bac.pool)
        .await
        .unwrap();

    // Awa recommande à cette adresse (ce que fera le cycle CMD).
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot.marquer_adresse_utilisee(&mut tx, id).await.unwrap();
    tx.commit().await.unwrap();

    assert_eq!(
        bac.depot.purger_reperes_vocaux().await.unwrap(),
        0,
        "la purge compte les mois SANS UTILISATION, pas l'âge de l'adresse"
    );
    assert!(bac.depot.adresse(id, awa).await.unwrap().a_repere_vocal());
}

/// La rétention est un paramètre de ZONE, pas une constante.
#[sqlx::test(migrations = "../../migrations")]
async fn retention_lue_dans_la_configuration_de_zone(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let id = Uuid::now_v7();
    enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();

    sqlx::query("UPDATE comptes.adresse SET derniere_utilisation_le = now() - interval '40 days' WHERE id = $1")
        .bind(id)
        .execute(&bac.pool)
        .await
        .unwrap();

    // À 365 jours (seed), 40 jours ne purgent rien.
    assert_eq!(bac.depot.purger_reperes_vocaux().await.unwrap(), 0);

    // La zone abaisse sa rétention à 30 jours : la MÊME adresse est purgée.
    let mut tx = bac.pool.begin().await.unwrap();
    zones::PgZones::new(bac.pool.clone())
        .definir_parametre(
            &mut tx,
            bac.pays,
            "adresse.retention_repere_vocal_jours",
            serde_json::json!(30),
            "test",
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert_eq!(bac.depot.purger_reperes_vocaux().await.unwrap(), 1);
    let purges = bac.evenements("adresse.repere_vocal_purge").await;
    assert_eq!(purges[0]["retention_jours"], 30, "la rétention appliquée est celle de la zone");
}

/// FR-022 — après purge, un nouveau repère peut être capté.
#[sqlx::test(migrations = "../../migrations")]
async fn repere_vocal_remplacable_apres_purge(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let id = Uuid::now_v7();
    enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();

    sqlx::query("UPDATE comptes.adresse SET derniere_utilisation_le = now() - interval '366 days' WHERE id = $1")
        .bind(id)
        .execute(&bac.pool)
        .await
        .unwrap();
    bac.depot.purger_reperes_vocaux().await.unwrap();
    assert!(!bac.depot.adresse(id, awa).await.unwrap().a_repere_vocal());

    let mut tx = bac.pool.begin().await.unwrap();
    let remplacee = bac
        .depot
        .remplacer_repere_vocal(
            &mut tx,
            id,
            awa,
            &NoteVocale {
                octets: b"nouvelle-note".to_vec(),
                mime: "audio/mp4".to_owned(),
                duree_s: 8,
            },
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert!(remplacee.a_repere_vocal());
    assert_eq!(remplacee.repere_vocal_duree_s, Some(8));
    assert_eq!(
        bac.objets
            .lire(&remplacee.repere_vocal_cle_objet.unwrap())
            .as_deref(),
        Some(&b"nouvelle-note"[..])
    );
    let modifs = bac.evenements("adresse.modifiee").await;
    assert_eq!(modifs[0]["champs"], serde_json::json!(["repere_vocal"]));
}

/// FR-019 — la durée max est un paramètre de ZONE (seed : 30 s).
#[sqlx::test(migrations = "../../migrations")]
async fn note_vocale_trop_longue_ou_trop_lourde_refusee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;

    let trop_longue = NouvelleAdresse {
        note_vocale: Some(NoteVocale {
            duree_s: 31,
            ..note()
        }),
        ..nouvelle("Maison")
    };
    assert!(matches!(
        enregistrer(&bac, Uuid::now_v7(), awa, &trop_longue).await,
        Err(ErreurComptes::MediaInvalide(champ)) if champ == "duree_s"
    ));

    let trop_lourde = NouvelleAdresse {
        note_vocale: Some(NoteVocale {
            octets: vec![0u8; NOTE_VOCALE_TAILLE_MAX + 1],
            ..note()
        }),
        ..nouvelle("Maison")
    };
    assert!(matches!(
        enregistrer(&bac, Uuid::now_v7(), awa, &trop_lourde).await,
        Err(ErreurComptes::ObjetTropVolumineux)
    ));

    let mauvais_type = NouvelleAdresse {
        note_vocale: Some(NoteVocale {
            mime: "application/zip".to_owned(),
            ..note()
        }),
        ..nouvelle("Maison")
    };
    assert!(matches!(
        enregistrer(&bac, Uuid::now_v7(), awa, &mauvais_type).await,
        Err(ErreurComptes::MediaInvalide(_))
    ));

    assert_eq!(bac.compter("SELECT count(*) FROM comptes.adresse").await, 0);
    assert_eq!(bac.objets.nombre(), 0);
}

/// FR-019 — l'enregistrement n'est jamais obligatoire, et un repère non plus :
/// une adresse peut n'avoir que du texte, ou rien (elle en redemandera un).
#[sqlx::test(migrations = "../../migrations")]
async fn adresse_sans_note_vocale_acceptee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;

    let texte_seul = NouvelleAdresse {
        note_vocale: None,
        ..nouvelle("Bureau")
    };
    let adresse = enregistrer(&bac, Uuid::now_v7(), awa, &texte_seul).await.unwrap();
    assert!(!adresse.a_repere_vocal());
    assert!(adresse.repere_texte.is_some());
    assert_eq!(bac.objets.nombre(), 0);

    let sans_rien = NouvelleAdresse {
        repere_texte: None,
        note_vocale: None,
        ..nouvelle("Chantier")
    };
    let nue = enregistrer(&bac, Uuid::now_v7(), awa, &sans_rien).await.unwrap();
    assert!(nue.repere_texte.is_none(), "pas de contrainte « au moins un repère »");
}

/// L'adresse d'autrui est INTROUVABLE — jamais interdite.
#[sqlx::test(migrations = "../../migrations")]
async fn propriete_stricte_des_adresses(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let kofi = bac.inscrire("0709080706").await;
    let id = Uuid::now_v7();
    enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();

    assert!(matches!(
        bac.depot.adresse(id, kofi).await,
        Err(ErreurComptes::AdresseInconnue(_))
    ));
    assert!(bac.depot.adresses(kofi).await.unwrap().is_empty());

    let mut tx = bac.pool.begin().await.unwrap();
    assert!(matches!(
        bac.depot
            .modifier_adresse(
                &mut tx,
                id,
                kofi,
                &ModificationAdresse {
                    libelle: Some("À moi".to_owned()),
                    ..Default::default()
                },
            )
            .await,
        Err(ErreurComptes::AdresseInconnue(_))
    ));
    drop(tx);

    let mut tx = bac.pool.begin().await.unwrap();
    assert!(matches!(
        bac.depot.supprimer_adresse(&mut tx, id, kofi).await,
        Err(ErreurComptes::AdresseInconnue(_))
    ));
    drop(tx);

    assert_eq!(
        bac.depot.adresse(id, awa).await.unwrap().libelle,
        "Maison",
        "l'adresse d'Awa est intacte"
    );
}

/// Le repère écrit s'efface explicitement — `Some(None)` ≠ `None`.
#[sqlx::test(migrations = "../../migrations")]
async fn repere_texte_effacable_et_distinct_de_non_touche(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let id = Uuid::now_v7();
    enregistrer(&bac, id, awa, &nouvelle("Maison")).await.unwrap();

    // Ne toucher qu'au libellé laisse le repère en place.
    let mut tx = bac.pool.begin().await.unwrap();
    let a = bac
        .depot
        .modifier_adresse(
            &mut tx,
            id,
            awa,
            &ModificationAdresse {
                libelle: Some("Chez moi".to_owned()),
                repere_texte: None,
            },
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(a.repere_texte.is_some(), "None = ne pas toucher");

    // `Some(None)` efface.
    let mut tx = bac.pool.begin().await.unwrap();
    let a = bac
        .depot
        .modifier_adresse(
            &mut tx,
            id,
            awa,
            &ModificationAdresse {
                libelle: None,
                repere_texte: Some(None),
            },
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert!(a.repere_texte.is_none(), "Some(None) = effacer");

    // Une modification VIDE n'émet pas d'événement pour un non-événement.
    let avant = bac.evenements("adresse.modifiee").await.len();
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_adresse(&mut tx, id, awa, &ModificationAdresse::default())
        .await
        .unwrap();
    tx.commit().await.unwrap();
    assert_eq!(bac.evenements("adresse.modifiee").await.len(), avant);
}

/// Constitution VI — un rollback ne laisse ni adresse ni événement.
#[sqlx::test(migrations = "../../migrations")]
async fn rollback_ne_laisse_ni_adresse_ni_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;

    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .enregistrer_adresse(&mut tx, Uuid::now_v7(), awa, &nouvelle("Maison"))
        .await
        .unwrap();
    tx.rollback().await.unwrap();

    assert_eq!(bac.compter("SELECT count(*) FROM comptes.adresse").await, 0);
    assert_eq!(bac.evenements("adresse.enregistree").await.len(), 0);
    // Seule trace : l'objet déposé, orphelin — aucun stockage objet n'est
    // transactionnel.
    assert_eq!(bac.objets.nombre(), 1);
}

/// Un compte inconnu n'enregistre rien.
#[sqlx::test(migrations = "../../migrations")]
async fn compte_inconnu_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    assert!(matches!(
        enregistrer(&bac, Uuid::now_v7(), Uuid::now_v7(), &nouvelle("Maison")).await,
        Err(ErreurComptes::CompteInconnu(_))
    ));
}
