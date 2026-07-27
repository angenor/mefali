//! Tests d'intégration du pool et des verrous d'offre contre un VRAI Redis
//! (T018, T019).
//!
//! Pourquoi ne pas se contenter de `MemoirePool` et `VerrouMemoire` : les
//! scripts Lua ne sont ni compilés ni typés par `cargo build` — une faute de
//! syntaxe, une clé oubliée, un `EXPIRE` manquant ou un rollback absent ne se
//! voient qu'à l'exécution. Ces tests vérifient que l'implémentation réelle
//! tient les MÊMES promesses que les doubles : c'est ce qui autorise tout le
//! reste de la suite à se fier à eux.
//!
//! Redis absent → les tests se SAUTENT avec un message explicite : le
//! `cargo test` d'une machine sans infra ne doit pas échouer sur une dépendance
//! externe (patron `infra_redis.rs` du cycle 003).

use std::sync::Arc;
use std::time::Duration;

use dispatch::{Capacite, InscriptionPool, PoolCoursiers, PoseVerrou, VerrouOffre};
use uuid::Uuid;

use api::infra_redis::{RedisPool, RedisVerrouOffre};

/// Position de référence : le centre de Tiassalé.
const TIASSALE: (f64, f64) = (5.8960, -4.8210);

fn url() -> String {
    std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_owned())
}

/// Pool branché sur le Redis de `infra/docker-compose.yml`, ou `None` s'il est
/// injoignable (test sauté).
async fn pool() -> Option<RedisPool> {
    let url = url();
    let pool = match RedisPool::nouveau(&url) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("test sauté — Redis inconfigurable ({url}) : {e}");
            return None;
        }
    };
    // Un aller-retour réel : le pool est paresseux, `nouveau` ne prouve rien.
    match pool.elaguer(Uuid::now_v7()).await {
        Ok(_) => Some(pool),
        Err(e) => {
            eprintln!("test sauté — Redis injoignable ({url}) : {e}");
            None
        }
    }
}

async fn verrous() -> Option<RedisVerrouOffre> {
    let url = url();
    let v = RedisVerrouOffre::nouveau(&url).ok()?;
    match v
        .liberer(Uuid::now_v7(), Uuid::now_v7(), Uuid::now_v7())
        .await
    {
        Ok(()) => Some(v),
        Err(e) => {
            eprintln!("test sauté — Redis injoignable ({url}) : {e}");
            None
        }
    }
}

fn inscription(coursier: Uuid, zone: Uuid, lat: f64, lon: f64) -> InscriptionPool {
    InscriptionPool {
        coursier,
        zone,
        lat,
        lon,
        en_ligne: true,
        capacites: vec![Capacite::transport("moto")],
        note_centiemes: None,
        plafond_unites: 10_000,
        devise: "XOF".to_owned(),
        course_active: None,
        age_s: 0,
    }
}

// ── Pool (T018) ────────────────────────────────────────────────────────────

/// Publier écrit les TROIS clés et rend un état complet — dont la position au
/// format du cycle 008, que le suivi client lit.
#[tokio::test]
async fn publier_ecrit_les_trois_cles_et_relit_l_etat() {
    let Some(pool) = pool().await else { return };
    let (zone, coursier) = (Uuid::now_v7(), Uuid::now_v7());
    let i = inscription(coursier, zone, TIASSALE.0, TIASSALE.1);

    pool.publier(&i, Duration::from_secs(90)).await.unwrap();

    let relu = pool.etat(coursier).await.unwrap().expect("dans le pool");
    assert_eq!(relu.zone, zone);
    assert!(relu.en_ligne);
    assert_eq!(relu.capacites, vec![Capacite::transport("moto")]);
    assert_eq!(relu.plafond_unites, 10_000);
    assert_eq!(relu.devise, "XOF");
    assert_eq!(relu.note_centiemes, None, "aucune note tant qu'AVI n'existe pas");
    assert!(relu.age_s < 5, "l'âge est calculé à la lecture");

    // L'index géographique répond au pré-filtre.
    let dedans = pool
        .dans_rayon(zone, TIASSALE.0, TIASSALE.1, 4_000)
        .await
        .unwrap();
    assert!(dedans.contains(&coursier));

    pool.retirer(coursier, zone).await.unwrap();
}

/// FR-005 — le retrait est IMMÉDIAT : le coursier sort du pool sans attendre
/// l'expiration, et ne peut plus rien recevoir.
#[tokio::test]
async fn retirer_sort_du_pool_immediatement() {
    let Some(pool) = pool().await else { return };
    let (zone, coursier) = (Uuid::now_v7(), Uuid::now_v7());
    pool.publier(
        &inscription(coursier, zone, TIASSALE.0, TIASSALE.1),
        Duration::from_secs(90),
    )
    .await
    .unwrap();
    assert!(pool.etat(coursier).await.unwrap().is_some());

    pool.retirer(coursier, zone).await.unwrap();

    assert!(pool.etat(coursier).await.unwrap().is_none());
    assert!(!pool
        .dans_rayon(zone, TIASSALE.0, TIASSALE.1, 4_000)
        .await
        .unwrap()
        .contains(&coursier));
}

/// SC-003 — le TTL de l'état EST le heartbeat de DSP-01. Un coursier qui cesse
/// de publier sort du pool tout seul ; son membre GEO lui survit (Redis n'expire
/// pas par membre de zset), et c'est ce fantôme que l'élagage retire.
///
/// ⚠ Entre les deux, le fantôme ne reçoit RIEN : `etat` rend `None`, et c'est
/// l'état qui décide de l'éligibilité, jamais l'index.
#[tokio::test]
async fn un_muet_sort_du_pool_et_son_fantome_est_elague() {
    let Some(pool) = pool().await else { return };
    let (zone, coursier) = (Uuid::now_v7(), Uuid::now_v7());
    // TTL d'une seconde : le silence est reproductible sans attendre 90 s.
    pool.publier(
        &inscription(coursier, zone, TIASSALE.0, TIASSALE.1),
        Duration::from_secs(1),
    )
    .await
    .unwrap();
    tokio::time::sleep(Duration::from_millis(1_400)).await;

    assert!(
        pool.etat(coursier).await.unwrap().is_none(),
        "l'état a expiré : le coursier est sorti du pool",
    );
    assert!(
        pool.dans_rayon(zone, TIASSALE.0, TIASSALE.1, 4_000)
            .await
            .unwrap()
            .contains(&coursier),
        "le membre GEO survit — c'est exactement le fantôme à élaguer",
    );
    assert_eq!(pool.elaguer(zone).await.unwrap(), 1);
    assert!(pool
        .dans_rayon(zone, TIASSALE.0, TIASSALE.1, 4_000)
        .await
        .unwrap()
        .is_empty());
}

/// Le pré-filtre géographique écarte ce qui est certainement hors rayon. Il
/// MINORE la route (vol d'oiseau), donc il ne peut pas écarter à tort.
#[tokio::test]
async fn le_prefiltre_geographique_borne_le_vivier() {
    let Some(pool) = pool().await else { return };
    let (zone, proche, loin) = (Uuid::now_v7(), Uuid::now_v7(), Uuid::now_v7());
    pool.publier(
        &inscription(proche, zone, TIASSALE.0, TIASSALE.1),
        Duration::from_secs(90),
    )
    .await
    .unwrap();
    // ≈ 11 km au nord — hors du rayon de 4 km de Tiassalé.
    pool.publier(
        &inscription(loin, zone, TIASSALE.0 + 0.1, TIASSALE.1),
        Duration::from_secs(90),
    )
    .await
    .unwrap();

    let dedans = pool
        .dans_rayon(zone, TIASSALE.0, TIASSALE.1, 4_000)
        .await
        .unwrap();
    assert!(dedans.contains(&proche));
    assert!(!dedans.contains(&loin));

    pool.retirer(proche, zone).await.unwrap();
    pool.retirer(loin, zone).await.unwrap();
}

/// Une URL Redis injoignable ne fait pas tomber une LECTURE : le pré-filtre rend
/// une liste vide et l'état `None`. Redis muet dégrade, il ne casse pas.
#[tokio::test]
async fn redis_injoignable_degrade_les_lectures_sans_erreur() {
    // Port fermé volontairement — aucune infra requise pour ce test.
    let pool = RedisPool::nouveau("redis://127.0.0.1:6399").expect("URL valide");
    assert!(pool
        .dans_rayon(Uuid::now_v7(), TIASSALE.0, TIASSALE.1, 4_000)
        .await
        .unwrap()
        .is_empty());
    assert!(pool.etat(Uuid::now_v7()).await.unwrap().is_none());
    assert_eq!(pool.elaguer(Uuid::now_v7()).await.unwrap(), 0);
}

// ── Double verrou (T019) ───────────────────────────────────────────────────

/// FR-056 — pose concurrente sur la MÊME commande : un seul obtient, l'autre
/// reçoit `CommandeDejaOfferte` (et doit abandonner son passage).
#[tokio::test]
async fn pose_concurrente_sur_la_meme_commande() {
    let Some(verrous) = verrous().await else { return };
    let commande = Uuid::now_v7();
    let (a, b) = (Uuid::now_v7(), Uuid::now_v7());
    let (jeton_a, jeton_b) = (Uuid::now_v7(), Uuid::now_v7());
    let ttl = Duration::from_secs(45);

    assert_eq!(
        verrous.poser(commande, a, jeton_a, ttl).await.unwrap(),
        PoseVerrou::Obtenu,
    );
    assert_eq!(
        verrous.poser(commande, b, jeton_b, ttl).await.unwrap(),
        PoseVerrou::CommandeDejaOfferte,
    );

    verrous.liberer(commande, a, jeton_a).await.unwrap();
}

/// FR-057 — pose concurrente sur le MÊME coursier : la seconde commande reçoit
/// `CoursierDejaPorteur` et passe au candidat suivant. SC-014 en dépend.
#[tokio::test]
async fn pose_concurrente_sur_le_meme_coursier() {
    let Some(verrous) = verrous().await else { return };
    let coursier = Uuid::now_v7();
    let (cmd_a, cmd_b) = (Uuid::now_v7(), Uuid::now_v7());
    let (jeton_a, jeton_b) = (Uuid::now_v7(), Uuid::now_v7());
    let ttl = Duration::from_secs(45);

    assert_eq!(
        verrous.poser(cmd_a, coursier, jeton_a, ttl).await.unwrap(),
        PoseVerrou::Obtenu,
    );
    assert_eq!(
        verrous.poser(cmd_b, coursier, jeton_b, ttl).await.unwrap(),
        PoseVerrou::CoursierDejaPorteur,
    );

    verrous.liberer(cmd_a, coursier, jeton_a).await.unwrap();
}

/// **Le rollback**, et c'est ce que Lua achète. Quand le second verrou échoue,
/// le premier est relâché : sans cela, `cmd_b` resterait verrouillée 45 s pour
/// une offre qui n'a jamais existé, et personne ne pourrait la prendre.
#[tokio::test]
async fn le_premier_verrou_est_relache_quand_le_second_echoue() {
    let Some(verrous) = verrous().await else { return };
    let coursier = Uuid::now_v7();
    let (cmd_a, cmd_b) = (Uuid::now_v7(), Uuid::now_v7());
    let jeton_a = Uuid::now_v7();
    let ttl = Duration::from_secs(45);

    verrous.poser(cmd_a, coursier, jeton_a, ttl).await.unwrap();
    // Échoue sur le coursier — mais `cmd_b` ne doit PAS rester verrouillée.
    assert_eq!(
        verrous
            .poser(cmd_b, coursier, Uuid::now_v7(), ttl)
            .await
            .unwrap(),
        PoseVerrou::CoursierDejaPorteur,
    );

    // Un autre coursier peut prendre `cmd_b` : la preuve du rollback.
    let autre = Uuid::now_v7();
    let jeton_c = Uuid::now_v7();
    assert_eq!(
        verrous.poser(cmd_b, autre, jeton_c, ttl).await.unwrap(),
        PoseVerrou::Obtenu,
        "le verrou de cmd_b a bien été rollbacké par le script",
    );

    verrous.liberer(cmd_a, coursier, jeton_a).await.unwrap();
    verrous.liberer(cmd_b, autre, jeton_c).await.unwrap();
}

/// On ne libère jamais un verrou qu'on ne détient pas : une conclusion tardive
/// ne doit pas effacer les verrous d'une offre reprise entre-temps.
#[tokio::test]
async fn liberer_avec_un_mauvais_jeton_ne_libere_rien() {
    let Some(verrous) = verrous().await else { return };
    let (commande, coursier) = (Uuid::now_v7(), Uuid::now_v7());
    let jeton = Uuid::now_v7();
    let ttl = Duration::from_secs(45);
    verrous.poser(commande, coursier, jeton, ttl).await.unwrap();

    verrous
        .liberer(commande, coursier, Uuid::now_v7())
        .await
        .unwrap();

    assert_eq!(
        verrous
            .poser(commande, Uuid::now_v7(), Uuid::now_v7(), ttl)
            .await
            .unwrap(),
        PoseVerrou::CommandeDejaOfferte,
        "le verrou tient encore : le mauvais jeton n'a rien libéré",
    );
    verrous.liberer(commande, coursier, jeton).await.unwrap();
}

/// N tâches tokio posent le verrou de la MÊME commande en parallèle sur le vrai
/// Redis : exactement UNE obtient. C'est le comportement dont SC-001 dépend au
/// niveau de l'exclusivité (la garantie Postgres, elle, est testée à part).
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn n_poses_paralleles_une_seule_gagne() {
    let Some(verrous) = verrous().await else { return };
    let verrous = Arc::new(verrous);
    let commande = Uuid::now_v7();
    const N: usize = 8;

    let mut taches = Vec::new();
    for _ in 0..N {
        let v = Arc::clone(&verrous);
        let coursier = Uuid::now_v7();
        let jeton = Uuid::now_v7();
        taches.push(tokio::spawn(async move {
            let issue = v
                .poser(commande, coursier, jeton, Duration::from_secs(45))
                .await
                .unwrap();
            (issue, coursier, jeton)
        }));
    }

    let mut gagnants = Vec::new();
    for t in taches {
        let (issue, coursier, jeton) = t.await.unwrap();
        if issue == PoseVerrou::Obtenu {
            gagnants.push((coursier, jeton));
        } else {
            assert_eq!(issue, PoseVerrou::CommandeDejaOfferte);
        }
    }
    assert_eq!(gagnants.len(), 1, "exactement un preneur, jamais deux");

    let (coursier, jeton) = gagnants[0];
    verrous.liberer(commande, coursier, jeton).await.unwrap();
}
