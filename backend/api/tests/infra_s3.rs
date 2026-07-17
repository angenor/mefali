//! Tests d'intégration de `S3Objets` contre un VRAI Garage (T005).
//!
//! Ce que ces tests protègent : `force_path_style`, l'override d'endpoint, la
//! région signée et la présignature sont des réglages qui compilent
//! parfaitement en étant faux — ils ne se vérifient qu'en parlant à Garage.
//! Le test décisif est l'aller-retour d'octets PAR L'URL PRÉSIGNÉE : c'est la
//! capacité exacte sur laquelle repose SC-007 (« l'audio téléchargé est
//! identique à l'original ») et, plus tard, l'écoute côté coursier (cycle CRS).
//!
//! Prérequis : `docker compose -f infra/docker-compose.yml up -d garage` puis
//! `infra/garage/init.sh`, et les `S3_*` de `infra/.env.example` exportés.
//! Garage absent ou non configuré → tests SAUTÉS (jamais rouges).

use std::time::Duration;

use comptes::DepotObjets;
use uuid::Uuid;

use api::infra_s3::S3Objets;

/// Dépôt branché sur le Garage local, ou `None` si l'environnement S3 est
/// incomplet (test sauté).
async fn depot() -> Option<(S3Objets, String)> {
    let variables: Vec<String> = ["S3_ENDPOINT", "S3_ACCESS_KEY", "S3_SECRET_KEY", "S3_BUCKET"]
        .iter()
        .map(|v| std::env::var(v).unwrap_or_default())
        .collect();
    if variables.iter().any(String::is_empty) {
        eprintln!("test sauté — S3_ENDPOINT/ACCESS_KEY/SECRET_KEY/BUCKET non exportés");
        return None;
    }
    let endpoint = variables[0].clone();
    let depot = S3Objets::nouveau(
        &endpoint,
        &variables[1],
        &variables[2],
        &variables[3],
        "garage",
    );

    // Aller-retour réel : la construction du client ne prouve rien.
    let cle = format!("comptes/tests/{}", Uuid::now_v7());
    match depot
        .deposer(&cle, b"sonde".to_vec(), "application/octet-stream")
        .await
    {
        Ok(()) => {
            let _ = depot.supprimer(&cle).await;
            Some((depot, endpoint))
        }
        Err(e) => {
            eprintln!("test sauté — Garage injoignable ({endpoint}) : {e}");
            None
        }
    }
}

/// SC-007 — les octets déposés ressortent À L'IDENTIQUE par l'URL présignée.
/// Prouve d'un coup l'endpoint, `force_path_style`, la région et la signature.
#[tokio::test]
async fn octets_restitues_a_l_identique_par_url_presignee() {
    let Some((depot, _)) = depot().await else {
        return;
    };
    let cle = format!("comptes/reperes/{}/{}", Uuid::now_v7(), Uuid::now_v7());
    // Octets non-UTF8 : une corruption d'encodage se verrait ici.
    let original: Vec<u8> = (0u8..=255).cycle().take(4096).collect();

    depot
        .deposer(&cle, original.clone(), "audio/mp4")
        .await
        .unwrap();

    let presignee = depot
        .presigner_get(&cle, Duration::from_secs(600))
        .await
        .unwrap();
    let reponse = reqwest::get(&presignee.url).await.unwrap();
    assert!(
        reponse.status().is_success(),
        "URL présignée refusée par Garage : {}",
        reponse.status()
    );
    let telecharge = reponse.bytes().await.unwrap();

    assert_eq!(
        telecharge.as_ref(),
        original.as_slice(),
        "les octets doivent être identiques (SC-007)"
    );
    assert!(
        presignee.expire_le > chrono::Utc::now(),
        "l'expiration annoncée est dans le futur"
    );

    depot.supprimer(&cle).await.unwrap();
}

/// Le bucket est PRIVÉ : sans signature, aucun accès (constitution VIII). Une
/// régression sur ce point rendrait publiques les pièces d'identité.
#[tokio::test]
async fn objet_inaccessible_sans_signature() {
    let Some((depot, endpoint)) = depot().await else {
        return;
    };
    let bucket = std::env::var("S3_BUCKET").unwrap();
    let cle = format!("comptes/pieces/{}/{}", Uuid::now_v7(), Uuid::now_v7());
    depot
        .deposer(&cle, b"piece-identite".to_vec(), "image/jpeg")
        .await
        .unwrap();

    // Même URL, sans les paramètres de signature.
    let nue = format!("{}/{}/{}", endpoint.trim_end_matches('/'), bucket, cle);
    let reponse = reqwest::get(&nue).await.unwrap();
    assert!(
        reponse.status().is_client_error(),
        "un objet privé ne doit JAMAIS être lisible sans signature (statut {})",
        reponse.status()
    );

    depot.supprimer(&cle).await.unwrap();
}

/// R8 — la purge doit pouvoir rejouer : supprimer une clé absente réussit, et
/// l'objet supprimé n'est plus servi.
#[tokio::test]
async fn suppression_est_idempotente_et_effective() {
    let Some((depot, _)) = depot().await else {
        return;
    };
    let cle = format!("comptes/reperes/{}/{}", Uuid::now_v7(), Uuid::now_v7());

    depot
        .deposer(&cle, b"repere".to_vec(), "audio/mp4")
        .await
        .unwrap();
    depot.supprimer(&cle).await.unwrap();
    assert!(
        depot.supprimer(&cle).await.is_ok(),
        "supprimer une clé absente réussit (rattrapage de purge)"
    );

    let presignee = depot
        .presigner_get(&cle, Duration::from_secs(600))
        .await
        .unwrap();
    let reponse = reqwest::get(&presignee.url).await.unwrap();
    assert_eq!(
        reponse.status(),
        404,
        "l'objet purgé n'est plus servi, même avec une URL signée"
    );
}
