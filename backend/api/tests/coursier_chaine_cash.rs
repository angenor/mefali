//! US4 — « Ce que Yao sort de sa poche, au franc près » (PAY-01, FR-054 →
//! FR-057).
//!
//! Le cycle 010 avait livré la moitié de la chaîne : les avances et leur
//! remboursement. Il manquait les **frais encaissés** — ce que Yao gagne
//! réellement sur la course — et la correction du montant réclamé sur une
//! commande prépayée.
//!
//! Ce fichier déroule une course cash **abîmée par la vraie vie** : deux
//! arrêts, une ligne retirée à la collecte, un arrêt entièrement indisponible.
//! Puis il compare le livre, ligne à ligne, avec le cash réellement manipulé.
//!
//! **Pourquoi `drainer_caisse` plutôt que le worker** : les écritures naissent
//! d'événements outbox. Monter le worker ferait dépendre chaque assertion d'un
//! ordonnancement asynchrone — un test de comptabilité qui attend une seconde
//! de plus n'est pas un test, c'est un pari.

mod bac_coursier;

use bac_coursier::{Bac, Course};
use serde_json::{json, Value};
use sqlx::PgPool;

/// Somme des montants avancés aux arrêts, lue sur les **arrêts eux-mêmes**.
///
/// C'est la seule référence indépendante du livre : l'asserter contre une
/// constante écrite à la main donnerait un test qui passe même si la
/// tarification change, et qui ne prouverait plus rien.
async fn avances_portees(bac: &Bac, course: &Course) -> i64 {
    sqlx::query_scalar::<_, i64>(
        "SELECT COALESCE(SUM(montant_avance), 0)::bigint FROM commandes.arret
          WHERE id = ANY($1)",
    )
    .bind(&course.collectes)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

/// Total **dû par le client**, tel que la commande le porte après ajustements.
async fn total_du(bac: &Bac, course: &Course) -> i64 {
    sqlx::query_scalar::<_, i64>("SELECT total_unites FROM commandes.commande WHERE id = $1")
        .bind(course.commande)
        .fetch_one(&bac.pool)
        .await
        .unwrap()
}

/// Somme des écritures d'un type donné.
fn somme(ecritures: &[(String, i64)], type_ecriture: &str) -> i64 {
    ecritures
        .iter()
        .filter(|(t, _)| t == type_ecriture)
        .map(|(_, m)| *m)
        .sum()
}

/// Confirme la remise par le code du client — la course se termine.
async fn confirmer_remise(bac: &Bac, course: &Course) {
    bac.arriver_chez_le_client(course).await;
    let secrets = bac.secrets_remise(course.commande).await;
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "remise refusée : {corps}");
}

/// **Le test central d'US4.** Une course cash abîmée, et le livre qui dit vrai.
///
/// Déroulé : deux arrêts de collecte, une ligne retirée au premier, le second
/// entièrement indisponible, puis la remise en espèces.
///
/// Ce qu'on vérifie :
/// - le livre porte **une avance par arrêt collecté**, `remboursement` et
///   `frais_encaisses` — et rien d'autre ;
/// - `remboursement` égale exactement la somme des avances (solde à zéro sur
///   ce qui a été sorti de la poche) ;
/// - `frais_encaisses` égale `total dû recalculé − Σ avances` ;
/// - la somme des trois est le **gain réel** de la course.
#[sqlx::test(migrations = "../migrations")]
async fn le_livre_dit_ce_que_yao_a_vraiment_en_poche(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    assert!(
        course.collectes.len() >= 2,
        "le bac compose une course à {} arrêts — le scénario en exige 2",
        course.collectes.len(),
    );

    // ── Une ligne RETIRÉE, par le chemin réel de la rupture ───────────────
    //
    // Le vendeur n'a plus l'article : le coursier déclare la rupture, et la
    // résolution est « retirer ». Le total dû ET l'avance baissent ensemble,
    // donc les frais encaissés ne bougent pas — c'est ce que le test unitaire
    // `un_retrait_de_ligne_ne_change_pas_les_frais` fige, déroulé ici sur une
    // vraie base.
    //
    // L'appel passe par le DOMAINE et non par la route : celle-ci est
    // multipart (photo de l'étal), ses gardes sont couvertes par le cycle 008,
    // et ce test-ci porte sur l'argent, pas sur le contrôle d'accès.
    let ligne_retiree: uuid::Uuid = sqlx::query_scalar(
        "SELECT id FROM commandes.ligne_commande
          WHERE arret_id = $1 AND statut = 'presente' LIMIT 1",
    )
    .bind(course.collectes[0])
    .fetch_one(&bac.pool)
    .await
    .expect("le premier arrêt porte au moins une ligne");

    let total_avant = total_du(&bac, &course).await;
    bac.commandes
        .declarer_rupture(
            bac.coursier,
            commandes::DemandeRupture {
                ligne_id: ligne_retiree,
                uuid_client: uuid::Uuid::now_v7(),
                resolution: Some(commandes::ResolutionRupture::Retirer),
            },
            chrono::Utc::now(),
        )
        .await
        .expect("le retrait d'une ligne en rupture");
    assert!(
        total_du(&bac, &course).await < total_avant,
        "retirer une ligne baisse le total dû — sinon Awa paierait un article \
         qu'elle n'a pas reçu",
    );

    bac.collecter(course.collectes[0]).await;

    // ── Un arrêt INDISPONIBLE — le vendeur est fermé, rien n'est acheté ────
    let (statut, corps) = bac
        .post(
            &format!(
                "/courses/{}/arrets/{}/indisponible",
                course.livraison, course.collectes[1],
            ),
            &bac.jeton_coursier,
            json!({
                "uuid_client": uuid::Uuid::now_v7(),
                // `horodatage_local` est OBLIGATOIRE dans le contrat : c'est
                // une observation, mais son absence rend la demande invalide.
                "horodatage_local": chrono::Utc::now(),
                "motif": "vendeur_ferme",
            }),
        )
        .await;
    assert_eq!(statut, 200, "arrêt indisponible refusé : {corps}");

    // Les autres arrêts éventuels sont collectés pour que la course avance.
    for arret in course.collectes.iter().skip(2) {
        bac.collecter(*arret).await;
    }

    confirmer_remise(&bac, &course).await;
    bac.drainer_caisse().await;

    // ── Le livre, ligne à ligne ───────────────────────────────────────────
    let ecritures = bac.ecritures_caisse(bac.coursier).await;
    let avances = avances_portees(&bac, &course).await;
    let du = total_du(&bac, &course).await;

    assert!(avances > 0, "au moins un arrêt a été collecté et payé");
    assert_eq!(
        somme(&ecritures, "avance"),
        -avances,
        "les avances sortent de la poche : signe NÉGATIF, montant exact",
    );
    assert_eq!(
        somme(&ecritures, "remboursement"),
        avances,
        "le remboursement rend EXACTEMENT ce qui a été avancé",
    );
    assert_eq!(
        somme(&ecritures, "frais_encaisses"),
        du - avances,
        "les frais encaissés valent « total dû recalculé − Σ avances » — et \
         non `devis_prix_client`, qui mentirait dès que la retenue joue (R13)",
    );

    // Un arrêt indisponible ne coûte RIEN : il n'a pas d'écriture à lui.
    let nb_avances = ecritures.iter().filter(|(t, _)| t == "avance").count();
    let collectes_reelles: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM commandes.arret
          WHERE id = ANY($1) AND statut = 'collecte' AND montant_avance <> 0",
    )
    .bind(&course.collectes)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert_eq!(nb_avances as i64, collectes_reelles);

    // ── Le gain réel de la course ─────────────────────────────────────────
    let solde: i64 = ecritures.iter().map(|(_, m)| *m).sum();
    assert_eq!(
        solde,
        du - avances,
        "après la course, Yao a en poche exactement ce qu'il a encaissé en \
         plus de ce qu'il a sorti",
    );
}

/// FR-057, FR-093 — **une commande prépayée ne réclame plus rien.**
///
/// C'est le défaut le plus visible du code livré : `montant_a_encaisser`
/// valait `total_unites` quel que soit le mode, et l'app coursier réclamait à
/// Awa un montant qu'elle avait déjà réglé.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_prepayee_ne_reclame_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&course).await;

    let (statut, active): (u16, Value) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 200, "{active}");
    assert_eq!(active["remise"]["mode_paiement"], "mobile_money");
    assert_eq!(
        active["remise"]["montant_a_encaisser_unites"], 0,
        "RIEN à encaisser : la commande est déjà réglée (FR-057)",
    );

    // Et le total de la commande, lui, n'a pas bougé : c'est bien le montant
    // À ENCAISSER qui vaut zéro, pas la commande qui serait gratuite.
    assert!(total_du(&bac, &course).await > 0);
}

/// Le pendant cash : une commande en espèces réclame bien son total.
///
/// Sans ce test, mettre `0` partout ferait passer le précédent — et ne
/// réclamer jamais rien à personne.
#[sqlx::test(migrations = "../migrations")]
async fn une_commande_cash_reclame_son_total(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;

    let (statut, active): (u16, Value) = bac.get("/courses/active", &bac.jeton_coursier).await;
    assert_eq!(statut, 200, "{active}");
    assert_eq!(active["remise"]["mode_paiement"], "cash");
    assert_eq!(
        active["remise"]["montant_a_encaisser_unites"].as_i64().unwrap(),
        total_du(&bac, &course).await,
    );
}

/// R11 — `commande.terminee` sépare **le dû** de **l'encaissé**.
///
/// Les confondre faisait compter chaque prépaiement deux fois : une fois à la
/// confirmation du paiement, une fois à la livraison.
#[sqlx::test(migrations = "../migrations")]
async fn commande_terminee_separe_le_du_de_l_encaisse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // Cash : les deux chiffres coïncident.
    let cash = bac.course_prete().await;
    bac.collecter_tout(&cash).await;
    confirmer_remise(&bac, &cash).await;

    // Prépayée : l'encaissé vaut ZÉRO, le dû ne bouge pas.
    let prepayee = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&prepayee).await;
    confirmer_remise(&bac, &prepayee).await;

    let evenements: Vec<(uuid::Uuid, Value)> = sqlx::query_as(
        "SELECT entite_id, payload FROM outbox.evenement
          WHERE type_evenement = 'commande.terminee' ORDER BY survenu_le",
    )
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert_eq!(evenements.len(), 2);

    for (commande, charge) in evenements {
        let du = charge["total_du"].as_i64().expect("total_du est présent");
        let encaisse = charge["total_encaisse"].as_i64().unwrap();
        assert!(du > 0, "une commande vaut toujours quelque chose");
        if commande == cash.commande {
            assert_eq!(charge["mode_paiement"], "cash");
            assert_eq!(encaisse, du, "en espèces, tout est encaissé à la remise");
        } else {
            assert_eq!(charge["mode_paiement"], "mobile_money");
            assert_eq!(
                encaisse, 0,
                "prépayée : RIEN n'a changé de mains à la remise — l'argent \
                 est arrivé bien avant, par le fournisseur",
            );
        }
    }
}

/// Un rejeu de la fin de course ne double **ni** le remboursement **ni** les
/// frais.
///
/// Le worker outbox livre au moins une fois (contrat `socle`). Les deux
/// écritures naissent du MÊME événement : sans identifiant dérivé, la seconde
/// serait avalée comme un doublon de la première — et sans idempotence du tout,
/// chaque relivraison paierait Yao deux fois.
#[sqlx::test(migrations = "../migrations")]
async fn un_rejeu_ne_double_ni_le_remboursement_ni_les_frais(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    confirmer_remise(&bac, &course).await;

    bac.drainer_caisse().await;
    let apres_un_tour = bac.ecritures_caisse(bac.coursier).await;
    bac.drainer_caisse().await;
    bac.drainer_caisse().await;
    let apres_trois_tours = bac.ecritures_caisse(bac.coursier).await;

    assert_eq!(
        apres_un_tour, apres_trois_tours,
        "trois passages du worker écrivent exactement ce qu'un seul écrit",
    );
    assert_eq!(
        apres_un_tour
            .iter()
            .filter(|(t, _)| t == "frais_encaisses")
            .count(),
        1,
    );
}
