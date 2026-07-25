//! Tests d'intégration de `RedisEphemere` contre un VRAI Redis (T005).
//!
//! Pourquoi ne pas se contenter de `MemoireEphemere` : les scripts Lua ne sont
//! ni compilés ni typés par `cargo build` — une faute de syntaxe, une clé
//! oubliée ou un `EXPIRE` manquant ne se voit qu'à l'exécution. Ces tests
//! vérifient donc que l'implémentation réelle tient les MÊMES promesses que le
//! double mémoire (`comptes::ports::tests`) : c'est ce qui autorise tout le
//! reste de la suite à se fier au double.
//!
//! Redis absent → les tests se SAUTENT (message explicite) : le `cargo test`
//! d'une machine sans infra ne doit pas échouer sur une dépendance externe,
//! comme OSRM au cycle 001.

use std::time::Duration;

use comptes::{Appareil, Compteur, DepotEphemere, IssueDefi, JetonInscription, Plateforme};
use uuid::Uuid;

use api::infra_redis::RedisEphemere;

const TTL_DEFI: Duration = Duration::from_secs(300);
const TTL_FENETRE: Duration = Duration::from_secs(3600);

/// Dépôt branché sur le Redis de `infra/docker-compose.yml`, ou `None` s'il est
/// injoignable (test sauté).
async fn depot() -> Option<RedisEphemere> {
    let url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_owned());
    let depot = match RedisEphemere::nouveau(&url) {
        Ok(d) => d,
        Err(e) => {
            eprintln!("test sauté — Redis inconfigurable ({url}) : {e}");
            return None;
        }
    };
    // Un aller-retour réel : le pool est paresseux, `nouveau` ne prouve rien.
    match depot
        .incrementer(Compteur::DemandesParIp("sonde"), TTL_FENETRE)
        .await
    {
        Ok(_) => Some(depot),
        Err(e) => {
            eprintln!("test sauté — Redis injoignable ({url}) : {e}");
            None
        }
    }
}

/// Numéro unique par test : les clés Redis sont partagées entre exécutions.
fn numero_unique() -> String {
    format!("+225{:012}", Uuid::now_v7().as_u128() % 1_000_000_000_000)
}

#[tokio::test]
async fn defi_valide_est_consomme_une_seule_fois() {
    let Some(depot) = depot().await else { return };
    let e164 = numero_unique();

    depot
        .poser_defi(&e164, b"empreinte", 3, TTL_DEFI)
        .await
        .unwrap();
    assert_eq!(
        depot.consommer_essai(&e164, b"empreinte").await.unwrap(),
        IssueDefi::Valide
    );
    assert_eq!(
        depot.consommer_essai(&e164, b"empreinte").await.unwrap(),
        IssueDefi::Absent,
        "un code validé n'est pas rejouable"
    );
}

/// FR-002 — la nouvelle demande écrase le défi ET ses essais résiduels.
#[tokio::test]
async fn nouvelle_demande_ecrase_le_defi_precedent() {
    let Some(depot) = depot().await else { return };
    let e164 = numero_unique();

    depot
        .poser_defi(&e164, b"ancien", 3, TTL_DEFI)
        .await
        .unwrap();
    depot.consommer_essai(&e164, b"faux").await.unwrap(); // essais : 3 → 2
    depot
        .poser_defi(&e164, b"nouveau", 3, TTL_DEFI)
        .await
        .unwrap();

    assert_eq!(
        depot.consommer_essai(&e164, b"ancien").await.unwrap(),
        IssueDefi::Invalide { essais_restants: 2 },
        "le compteur d'essais est reparti de 3 — aucun résidu de l'ancien défi"
    );
    assert_eq!(
        depot.consommer_essai(&e164, b"nouveau").await.unwrap(),
        IssueDefi::Valide
    );
}

/// SC-002 — 3 essais, puis le défi meurt : même le BON code est refusé.
#[tokio::test]
async fn essais_epuises_detruisent_le_defi() {
    let Some(depot) = depot().await else { return };
    let e164 = numero_unique();

    depot.poser_defi(&e164, b"bon", 3, TTL_DEFI).await.unwrap();
    assert_eq!(
        depot.consommer_essai(&e164, b"faux").await.unwrap(),
        IssueDefi::Invalide { essais_restants: 2 }
    );
    assert_eq!(
        depot.consommer_essai(&e164, b"faux").await.unwrap(),
        IssueDefi::Invalide { essais_restants: 1 }
    );
    assert_eq!(
        depot.consommer_essai(&e164, b"faux").await.unwrap(),
        IssueDefi::Absent,
        "3e essai faux → défi détruit"
    );
    assert_eq!(
        depot.consommer_essai(&e164, b"bon").await.unwrap(),
        IssueDefi::Absent,
        "4e saisie : même le bon code ne passe plus"
    );
}

/// Le TTL est réellement posé — sans `EXPIRE`, le défi vivrait pour toujours et
/// la promesse « 5 minutes » (SC-002) serait fausse en production seulement.
#[tokio::test]
async fn defi_expire_reellement() {
    let Some(depot) = depot().await else { return };
    let e164 = numero_unique();

    depot
        .poser_defi(&e164, b"bon", 3, Duration::from_secs(1))
        .await
        .unwrap();
    tokio::time::sleep(Duration::from_millis(1_200)).await;

    assert_eq!(
        depot.consommer_essai(&e164, b"bon").await.unwrap(),
        IssueDefi::Absent,
        "TTL écoulé → défi absent (EXPIRE bien appliqué)"
    );
}

/// Fenêtre FIXE : les incréments ne prolongent pas le TTL.
#[tokio::test]
async fn compteur_incremente_et_conserve_sa_fenetre() {
    let Some(depot) = depot().await else { return };
    let e164 = numero_unique();

    for attendu in 1..=4 {
        let n = depot
            .incrementer(Compteur::SmsParNumero(&e164), Duration::from_secs(2))
            .await
            .unwrap();
        assert_eq!(n, attendu);
    }

    tokio::time::sleep(Duration::from_millis(2_200)).await;
    assert_eq!(
        depot
            .incrementer(Compteur::SmsParNumero(&e164), Duration::from_secs(2))
            .await
            .unwrap(),
        1,
        "la fenêtre écoulée repart à 1 (le TTL n'a pas glissé)"
    );
}

/// R3 — GETDEL : un jeton d'inscription ne sert qu'une fois, et son contenu
/// (dont l'appareil capté à la vérification — analyze C1) revient intact.
#[tokio::test]
async fn jeton_inscription_est_a_usage_unique() {
    let Some(depot) = depot().await else { return };
    let jeton = Uuid::now_v7().to_string();
    let contenu = JetonInscription {
        telephone_e164: numero_unique(),
        zone: Uuid::now_v7(),
        appareil: Appareil {
            nom: "Pixel de test".to_owned(),
            plateforme: Plateforme::Android,
        },
    };

    depot
        .poser_jeton_inscription(&jeton, &contenu, Duration::from_secs(600))
        .await
        .unwrap();

    assert_eq!(
        depot.consommer_jeton_inscription(&jeton).await.unwrap(),
        Some(contenu),
        "aller-retour JSON sans perte"
    );
    assert_eq!(
        depot.consommer_jeton_inscription(&jeton).await.unwrap(),
        None,
        "second usage refusé"
    );
}

/// Un jeton jamais posé ne ressuscite pas (401 neutre côté API).
#[tokio::test]
async fn jeton_inconnu_renvoie_none() {
    let Some(depot) = depot().await else { return };
    assert_eq!(
        depot
            .consommer_jeton_inscription(&Uuid::now_v7().to_string())
            .await
            .unwrap(),
        None
    );
}

// ── Cache de routage (cycle TRF 007, T015) ─────────────────────────────────

/// Cache branché sur le Redis local, ou `None` s'il est injoignable (sauté).
async fn cache_routage() -> Option<api::infra_redis::RedisCacheRoutage> {
    use tarification::CacheRoutage;
    let url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_owned());
    let cache = api::infra_redis::RedisCacheRoutage::nouveau(&url).ok()?;
    // Sonde : un pool se crée sans jamais toucher au serveur, il faut donc une
    // vraie commande pour savoir si Redis répond.
    cache.lire(&["tarif:route:v1:sonde".to_owned()]).await.ok()?;
    Some(cache)
}

/// Le cache RÉEL tient la même promesse que `CacheMemoire` : ce qui est écrit se
/// relit à l'identique, ce qui n'a jamais été écrit rend `None`.
///
/// Ce que le double mémoire ne peut PAS prouver : que la sérialisation
/// `distance:duree` survit à un aller-retour Redis, et qu'un `MGET` de clés
/// mêlant présentes et absentes garde l'ORDRE — sans quoi la matrice serait
/// reconstruite avec des tronçons permutés, donc un prix faux.
#[tokio::test]
async fn cache_routage_aller_retour_et_ordre() {
    use tarification::{CacheRoutage, Troncon};
    let Some(cache) = cache_routage().await else {
        eprintln!("Redis injoignable — test du cache de routage sauté");
        return;
    };

    let marque = Uuid::now_v7();
    let cle_a = format!("tarif:route:v1:test-{marque}-a");
    let cle_b = format!("tarif:route:v1:test-{marque}-b");
    let absente = format!("tarif:route:v1:test-{marque}-absente");
    let a = Troncon {
        distance_m: 1_234,
        duree_s: 321,
    };
    let b = Troncon {
        distance_m: 42,
        duree_s: 7,
    };

    cache
        .ecrire(&[(cle_a.clone(), a), (cle_b.clone(), b)], 60)
        .await
        .unwrap();

    let lus = cache
        .lire(&[cle_b.clone(), absente.clone(), cle_a.clone()])
        .await
        .unwrap();
    assert_eq!(
        lus,
        vec![Some(b), None, Some(a)],
        "l'ordre des clés demandées est préservé, trous compris"
    );

    // Une valeur corrompue est traitée comme ABSENTE : un cache abîmé coûte un
    // appel de routage, jamais un prix faux.
    let mut conn = deadpool_redis::Config::from_url(
        std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_owned()),
    )
    .create_pool(Some(deadpool_redis::Runtime::Tokio1))
    .unwrap()
    .get()
    .await
    .unwrap();
    redis::cmd("SET")
        .arg(&cle_a)
        .arg("pas-un-troncon")
        .query_async::<()>(&mut conn)
        .await
        .unwrap();
    assert_eq!(cache.lire(std::slice::from_ref(&cle_a)).await.unwrap(), vec![None]);

    // Ménage.
    redis::cmd("DEL")
        .arg(&cle_a)
        .arg(&cle_b)
        .query_async::<()>(&mut conn)
        .await
        .unwrap();
}
