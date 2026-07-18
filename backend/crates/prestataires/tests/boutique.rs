//! US3 — Ouvrir, fermer et mettre la boutique en pause (VND-03).
//!
//! SC-004 (hors horaires = fermé, non commandable), SC-007 (la lecture qui
//! suit une bascule rend TOUJOURS le nouvel état), FR-033/FR-036 (gestes
//! décidés → événements ; échéances → RIEN), FR-035 (rappel non bloquant).
//!
//! Déterminisme : les cas « dans les horaires » utilisent des horaires
//! CONTINUS (00:00–23:59 ×7), les cas « hors horaires » une semaine SANS
//! plage — l'horloge du test ne compte jamais. Les échéances se franchissent
//! par UPDATE SQL des colonnes (patron du cycle 003 pour la purge).

mod bac;

use bac::Bac;
use prestataires::modele::{HorairesSemaine, Plage};
use prestataires::{ActionBoutique, ErreurPrestataires, SourceBascule, StatutBoutique};
use sqlx::PgPool;
use uuid::Uuid;

fn horaires_continus() -> HorairesSemaine {
    let mut horaires = HorairesSemaine::default();
    for jour in 0..7 {
        horaires.jours[jour].push(Plage {
            debut: chrono::NaiveTime::from_hms_opt(0, 0, 0).unwrap(),
            fin: chrono::NaiveTime::from_hms_opt(23, 59, 0).unwrap(),
        });
    }
    horaires
}

/// Vendeur agréé (catégorie active, seuil 1), horaires continus.
async fn vendeur_pret(bac: &Bac) -> Uuid {
    let id = bac.prospect_complet("Boutique Kofi", "boutique_superette").await;
    bac.agreer(id).await;
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_horaires(&mut tx, id, &horaires_continus(), SourceBascule::Admin, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
    id
}

async fn geste(bac: &Bac, id: Uuid, action: ActionBoutique, source: SourceBascule) {
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .changer_statut_boutique(&mut tx, id, action, source, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();
}

/// SC-007 + FR-036 — chaque geste bascule l'état IMMÉDIATEMENT et émet SON
/// événement, source et auteur compris.
#[sqlx::test(migrations = "../../migrations")]
async fn chaque_geste_emet_son_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    geste(&bac, id, ActionBoutique::Fermer, SourceBascule::Vendeur).await;
    let boutique = bac.depot.boutique_vendeur(id).await.unwrap();
    assert_eq!(boutique.statut, StatutBoutique::Ferme);
    assert!(!boutique.effectif.ouvert, "aucune lecture ne rend l'état précédent");
    assert!(
        !bac.depot.commandabilite(id).await.unwrap().commandable(),
        "boutique fermée → non commandable (SC-004)"
    );

    geste(&bac, id, ActionBoutique::Ouvrir, SourceBascule::Admin).await;
    assert!(bac.depot.boutique_vendeur(id).await.unwrap().effectif.ouvert);

    let evenements = bac.evenements("site.statut_boutique_change").await;
    assert_eq!(evenements.len(), 2);
    assert_eq!(evenements[0]["avant"], serde_json::json!("ouvert"));
    assert_eq!(evenements[0]["apres"], serde_json::json!("ferme"));
    assert_eq!(evenements[0]["source"], serde_json::json!("vendeur"));
    assert_eq!(evenements[1]["source"], serde_json::json!("admin"));
    assert_eq!(evenements[1]["acteur"], serde_json::json!(bac.admin));
}

/// FR-033 — la pause ferme immédiatement, annonce sa réouverture, et ROUVRE
/// TOUTE SEULE à l'échéance : aucune écriture, AUCUN événement (research R3).
#[sqlx::test(migrations = "../../migrations")]
async fn pause_temporisee_rouvre_sans_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    geste(
        &bac,
        id,
        ActionBoutique::MettreEnPause { duree_minutes: 60 },
        SourceBascule::Vendeur,
    )
    .await;
    let en_pause = bac.depot.boutique_vendeur(id).await.unwrap();
    assert_eq!(en_pause.statut, StatutBoutique::EnPause);
    assert!(!en_pause.effectif.ouvert);
    assert_eq!(
        en_pause.effectif.reouverture_estimee, en_pause.pause_fin,
        "l'heure de réouverture est ANNONCÉE (échéance dans les horaires)"
    );
    let evenements = bac.evenements("site.statut_boutique_change").await;
    assert_eq!(evenements.len(), 1);
    assert!(
        evenements[0]["pause_fin"].is_string(),
        "l'événement PORTE l'échéance — c'est lui qui rend la durée reconstituable"
    );

    // Échéance franchie : la COLONNE ne bouge pas, l'état effectif si.
    sqlx::query("UPDATE prestataires.site SET pause_fin = now() - interval '1 minute'")
        .execute(&bac.pool)
        .await
        .unwrap();
    let apres = bac.depot.boutique_vendeur(id).await.unwrap();
    assert_eq!(apres.statut, StatutBoutique::EnPause, "colonne intacte");
    assert!(apres.effectif.ouvert, "rouverte toute seule");
    assert_eq!(
        bac.evenements("site.statut_boutique_change").await.len(),
        1,
        "l'échéance n'émet AUCUN événement (FR-036)"
    );
}

/// FR-033/FR-030 — prolongation depuis l'échéance, fermeture pour la journée
/// qui cesse au lendemain SANS action ni événement.
#[sqlx::test(migrations = "../../migrations")]
async fn prolongation_puis_fermeture_pour_la_journee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    geste(
        &bac,
        id,
        ActionBoutique::MettreEnPause { duree_minutes: 30 },
        SourceBascule::Vendeur,
    )
    .await;
    let echeance_initiale = bac.depot.boutique_vendeur(id).await.unwrap().pause_fin.unwrap();
    geste(
        &bac,
        id,
        ActionBoutique::ProlongerPause { duree_minutes: 30 },
        SourceBascule::Vendeur,
    )
    .await;
    let prolongee = bac.depot.boutique_vendeur(id).await.unwrap().pause_fin.unwrap();
    assert!(
        prolongee > echeance_initiale,
        "l'échéance est repoussée depuis l'échéance en cours"
    );

    geste(&bac, id, ActionBoutique::FermerPourLaJournee, SourceBascule::Vendeur).await;
    let journee = bac.depot.boutique_vendeur(id).await.unwrap();
    assert_eq!(journee.statut, StatutBoutique::FermeJournee);
    assert!(!journee.effectif.ouvert);

    // Lendemain : la journée couverte est passée — rouvert, sans écriture.
    sqlx::query(
        "UPDATE prestataires.site SET ferme_journee_le = current_date - interval '1 day'",
    )
    .execute(&bac.pool)
    .await
    .unwrap();
    let lendemain = bac.depot.boutique_vendeur(id).await.unwrap();
    assert!(lendemain.effectif.ouvert, "sans que le vendeur ait à revenir rouvrir");
    assert_eq!(
        bac.evenements("site.statut_boutique_change").await.len(),
        3,
        "pause + prolongation + journée — RIEN pour les échéances"
    );
}

/// Gardes des gestes : durée requise, prolongation sans pause.
#[sqlx::test(migrations = "../../migrations")]
async fn gestes_invalides_refuses(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .changer_statut_boutique(
            &mut tx,
            id,
            ActionBoutique::MettreEnPause { duree_minutes: 0 },
            SourceBascule::Vendeur,
            bac.admin,
        )
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurPrestataires::DureeRequise));
    drop(tx);

    let mut tx = bac.pool.begin().await.unwrap();
    let erreur = bac
        .depot
        .changer_statut_boutique(
            &mut tx,
            id,
            ActionBoutique::ProlongerPause { duree_minutes: 30 },
            SourceBascule::Vendeur,
            bac.admin,
        )
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurPrestataires::ProlongationSansPause));
}

/// FR-032/SC-004 — hors horaires, FERMÉ quel que soit l'interrupteur ; le
/// catalogue reste consultable en lecture seule (FR-029).
#[sqlx::test(migrations = "../../migrations")]
async fn hors_horaires_ferme_et_catalogue_en_lecture_seule(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    // Semaine SANS plage : toujours hors horaires, interrupteur sur OUVERT.
    let mut tx = bac.pool.begin().await.unwrap();
    bac.depot
        .modifier_horaires(
            &mut tx,
            id,
            &HorairesSemaine::default(),
            SourceBascule::Admin,
            bac.admin,
        )
        .await
        .unwrap();
    tx.commit().await.unwrap();

    let boutique = bac.depot.boutique_vendeur(id).await.unwrap();
    assert_eq!(boutique.statut, StatutBoutique::Ouvert, "l'interrupteur dit ouvert");
    assert!(!boutique.effectif.ouvert, "hors horaires : FERMÉ quand même");
    let c = bac.depot.commandabilite(id).await.unwrap();
    assert!(c.agree && c.categorie_active && !c.boutique_ouverte && !c.commandable());

    // FR-029 — fiche servie, catalogue en lecture seule, non commandable.
    let fiche = bac.depot.fiche_publique_de(id).await.unwrap().unwrap();
    assert!(!fiche.commandable);
    assert!(!fiche.boutique.ouvert);
}

/// FR-035 (R4) — rappel non bloquant : fermé MANUEL dans les horaires ;
/// « je reste fermé aujourd'hui » (→ journée) l'éteint sans état de plus.
#[sqlx::test(migrations = "../../migrations")]
async fn rappel_ouverture_puis_extinction_par_la_journee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    assert!(!bac.depot.boutique_vendeur(id).await.unwrap().rappel_ouverture);

    geste(&bac, id, ActionBoutique::Fermer, SourceBascule::Vendeur).await;
    assert!(
        bac.depot.boutique_vendeur(id).await.unwrap().rappel_ouverture,
        "fermé manuel pendant les horaires habituels → rappel"
    );

    geste(&bac, id, ActionBoutique::FermerPourLaJournee, SourceBascule::Vendeur).await;
    assert!(
        !bac.depot.boutique_vendeur(id).await.unwrap().rappel_ouverture,
        "« je reste fermé aujourd'hui » : le rappel ne réapparaît plus (FR-035)"
    );
}

/// FR-034 — les nouveaux horaires s'appliquent immédiatement, émettent leur
/// événement, et une pause EN COURS continue de courir (edge case spec).
#[sqlx::test(migrations = "../../migrations")]
async fn horaires_immediats_et_pause_intacte(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let id = vendeur_pret(&bac).await;

    geste(
        &bac,
        id,
        ActionBoutique::MettreEnPause { duree_minutes: 60 },
        SourceBascule::Vendeur,
    )
    .await;
    let echeance = bac.depot.boutique_vendeur(id).await.unwrap().pause_fin;

    let avant = bac.evenements("site.horaires_modifies").await.len();
    let mut tx = bac.pool.begin().await.unwrap();
    let mut nouveaux = HorairesSemaine::default();
    nouveaux.jours[0].push(Plage {
        debut: chrono::NaiveTime::from_hms_opt(9, 0, 0).unwrap(),
        fin: chrono::NaiveTime::from_hms_opt(18, 0, 0).unwrap(),
    });
    bac.depot
        .modifier_horaires(&mut tx, id, &nouveaux, SourceBascule::Vendeur, bac.admin)
        .await
        .unwrap();
    tx.commit().await.unwrap();

    assert_eq!(
        bac.evenements("site.horaires_modifies").await.len(),
        avant + 1,
        "modification décidée → événement (FR-036)"
    );
    let boutique = bac.depot.boutique_vendeur(id).await.unwrap();
    assert_eq!(boutique.horaires, nouveaux, "effet immédiat");
    assert_eq!(boutique.pause_fin, echeance, "la pause continue de courir");
    assert_eq!(boutique.statut, StatutBoutique::EnPause);
}
