//! Tests d'intégration de TOUTES les transitions de la machine à états des
//! sessions (data-model §4 — OBLIGATOIRES, constitution VII ; CPT-02, T011).
//!
//!   cargo test -p comptes --test sessions   (DATABASE_URL requis)

mod bac;

use bac::{Bac, SAISIE_LOCALE};
use comptes::{ErreurComptes, OrigineRevocation};
use sqlx::PgPool;

/// ∅ → active : chaque appareil obtient SA session (FR-007).
#[sqlx::test(migrations = "../../migrations")]
async fn appareils_ont_des_sessions_independantes(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    let b = bac.ouvrir_session(SAISIE_LOCALE, "Nokia de secours").await;

    let actives = bac.depot.sessions_actives(compte).await.unwrap();
    assert_eq!(actives.len(), 2);
    assert!(actives.iter().any(|s| s.appareil.nom == "Nokia de secours"));
    assert!(actives.iter().all(|s| s.active()));

    // Révoquer B ne touche pas A (US2 scénario 3).
    bac.depot.deconnecter(b.session, compte).await.unwrap();
    let actives = bac.depot.sessions_actives(compte).await.unwrap();
    assert_eq!(actives.len(), 1);
    assert_ne!(actives[0].id, b.session);
}

/// Rotation : le refresh change à chaque usage, l'ancien meurt (R2).
#[sqlx::test(migrations = "../../migrations")]
async fn rotation_delivre_de_nouveaux_jetons(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    let tournes = bac
        .depot
        .tourner_refresh(&a.rafraichissement)
        .await
        .unwrap();
    assert_ne!(tournes.rafraichissement, a.rafraichissement);
    assert!(!tournes.acces.is_empty());

    // Le nouveau tourne à son tour : la chaîne se poursuit indéfiniment.
    let encore = bac
        .depot
        .tourner_refresh(&tournes.rafraichissement)
        .await
        .unwrap();
    assert_ne!(encore.rafraichissement, tournes.rafraichissement);

    // Aucun événement : une rotation n'est pas une transition (data-model §4).
    assert_eq!(bac.evenements("session.revoquee").await.len(), 0);
}

/// US2 scénario 2 — AUCUNE expiration d'inactivité : une session vieille de
/// deux ans se rafraîchit encore (clarification du 2026-07-14).
#[sqlx::test(migrations = "../../migrations")]
async fn session_ne_s_eteint_jamais_d_elle_meme(pool: PgPool) {
    let bac = Bac::nouveau(pool.clone()).await;
    bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    sqlx::query(
        "UPDATE comptes.session SET cree_le = now() - interval '2 years',
                                    derniere_activite_le = now() - interval '2 years'
         WHERE id = $1",
    )
    .bind(a.session)
    .execute(&pool)
    .await
    .unwrap();

    assert!(
        bac.depot.tourner_refresh(&a.rafraichissement).await.is_ok(),
        "seule une révocation éteint une session, jamais le temps"
    );
}

/// R2 — le cœur de la détection de vol : un jeton DÉJÀ TOURNÉ qui revient fait
/// tomber la session entière.
#[sqlx::test(migrations = "../../migrations")]
async fn reutilisation_du_refresh_revoque_la_session(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    // Le légitime tourne — puis un voleur rejoue l'ancien jeton.
    let tournes = bac
        .depot
        .tourner_refresh(&a.rafraichissement)
        .await
        .unwrap();
    let rejeu = bac.depot.tourner_refresh(&a.rafraichissement).await;
    assert!(matches!(rejeu, Err(ErreurComptes::RefreshInvalide)));

    // La session ENTIÈRE tombe : même le jeton fraîchement tourné ne vaut plus
    // rien. Les deux porteurs repassent par l'OTP — seul le légitime a le
    // téléphone.
    assert!(matches!(
        bac.depot.tourner_refresh(&tournes.rafraichissement).await,
        Err(ErreurComptes::RefreshInvalide)
    ));

    // Ce qui tombe, c'est la CHAÎNE compromise — pas tous les appareils du
    // compte. La session ouverte à l'inscription, elle, n'a rien à se
    // reprocher : la punir transformerait un vol sur un appareil en
    // déconnexion générale.
    let actives = bac.depot.sessions_actives(compte).await.unwrap();
    assert!(
        !actives.iter().any(|s| s.id == a.session),
        "la session dont le refresh a été rejoué est révoquée"
    );
    assert_eq!(
        actives.len(),
        1,
        "l'autre appareil du compte reste connecté"
    );

    let evenements = bac.evenements("session.revoquee").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(
        evenements[0]["origine"],
        OrigineRevocation::ReutilisationDetectee.comme_str()
    );
    assert_eq!(
        evenements[0]["revoquee_par"],
        serde_json::Value::Null,
        "détection automatique — personne ne l'a demandée"
    );
}

/// active → révoquée (locale) : la déconnexion coupe le renouvellement.
#[sqlx::test(migrations = "../../migrations")]
async fn deconnexion_locale_revoque_et_journalise(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    bac.depot.deconnecter(a.session, compte).await.unwrap();

    assert!(matches!(
        bac.depot.tourner_refresh(&a.rafraichissement).await,
        Err(ErreurComptes::RefreshInvalide)
    ));
    let evenements = bac.evenements("session.revoquee").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(
        evenements[0]["origine"],
        OrigineRevocation::Locale.comme_str()
    );
    assert_eq!(evenements[0]["compte"], serde_json::json!(compte));
}

/// SC-004 — déconnexion à distance : B perd l'accès, A n'est pas affecté.
#[sqlx::test(migrations = "../../migrations")]
async fn deconnexion_a_distance_ne_touche_que_la_cible(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel de poche").await;
    let b = bac.ouvrir_session(SAISIE_LOCALE, "Téléphone perdu").await;

    // A révoque B à distance.
    bac.depot
        .revoquer_appareil(compte, b.session, compte)
        .await
        .unwrap();

    assert!(
        matches!(
            bac.depot.tourner_refresh(&b.rafraichissement).await,
            Err(ErreurComptes::RefreshInvalide)
        ),
        "B perd l'accès à son prochain renouvellement"
    );
    assert!(
        bac.depot.tourner_refresh(&a.rafraichissement).await.is_ok(),
        "A n'est pas affecté"
    );

    let evenements = bac.evenements("session.revoquee").await;
    assert_eq!(evenements.len(), 1);
    assert_eq!(
        evenements[0]["origine"],
        OrigineRevocation::ADistance.comme_str()
    );
    assert_eq!(evenements[0]["revoquee_par"], serde_json::json!(compte));
}

/// La propriété est vérifiée : on ne déconnecte pas l'appareil d'autrui.
#[sqlx::test(migrations = "../../migrations")]
async fn revocation_a_distance_refusee_sur_la_session_d_autrui(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    bac.inscrire(SAISIE_LOCALE).await;
    let awa = bac.ouvrir_session(SAISIE_LOCALE, "Pixel d'Awa").await;

    let yao_compte = bac.inscrire("0705060708").await;

    // Yao tente de révoquer la session d'Awa.
    let tentative = bac
        .depot
        .revoquer_appareil(yao_compte, awa.session, yao_compte)
        .await;
    assert!(matches!(tentative, Err(ErreurComptes::SessionInconnue(_))));

    assert!(
        bac.depot
            .tourner_refresh(&awa.rafraichissement)
            .await
            .is_ok(),
        "la session d'Awa est intacte"
    );
    assert_eq!(bac.evenements("session.revoquee").await.len(), 0);
}

/// La révocation est IDEMPOTENTE : se déconnecter deux fois n'est pas une
/// erreur, et n'émet qu'UN événement (sinon les métriques doubleraient).
#[sqlx::test(migrations = "../../migrations")]
async fn revocation_est_idempotente(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    bac.depot.deconnecter(a.session, compte).await.unwrap();
    bac.depot.deconnecter(a.session, compte).await.unwrap();

    assert_eq!(bac.evenements("session.revoquee").await.len(), 1);
}

/// Un refresh inventé ne révèle rien et ne révoque rien.
#[sqlx::test(migrations = "../../migrations")]
async fn refresh_inconnu_refuse_sans_effet(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    assert!(matches!(
        bac.depot.tourner_refresh("jeton-invente").await,
        Err(ErreurComptes::RefreshInvalide)
    ));
    assert_eq!(bac.depot.sessions_actives(compte).await.unwrap().len(), 2);
    assert_eq!(bac.evenements("session.revoquee").await.len(), 0);
}

/// `derniere_activite_le` avance au rafraîchissement (FR-008) : c'est ce qui
/// rend la liste des appareils lisible (« dernier usage »).
#[sqlx::test(migrations = "../../migrations")]
async fn rotation_avance_la_derniere_activite(pool: PgPool) {
    let bac = Bac::nouveau(pool.clone()).await;
    let compte = bac.inscrire(SAISIE_LOCALE).await;
    let a = bac.ouvrir_session(SAISIE_LOCALE, "Pixel").await;

    sqlx::query(
        "UPDATE comptes.session SET derniere_activite_le = now() - interval '1 day'
         WHERE id = $1",
    )
    .bind(a.session)
    .execute(&pool)
    .await
    .unwrap();
    let avant = bac.depot.sessions_actives(compte).await.unwrap()[0].derniere_activite_le;

    bac.depot
        .tourner_refresh(&a.rafraichissement)
        .await
        .unwrap();

    let apres = bac.depot.sessions_actives(compte).await.unwrap()[0].derniere_activite_le;
    assert!(apres > avant);
}
