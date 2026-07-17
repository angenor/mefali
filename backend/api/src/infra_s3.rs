//! Implémentation RÉELLE du port [`DepotObjets`] sur Garage via l'API S3
//! (research R7).
//!
//! Garage remplace MinIO depuis la décision du 2026-07-13 (cadrage §10.4) ;
//! son API S3 est consommée par `aws-sdk-s3` avec deux réglages non
//! négociables : `endpoint_url` (on ne parle pas à AWS) et `force_path_style`
//! (Garage n'expose pas de virtual-host par bucket en dev).
//!
//! Le bucket est PRIVÉ : les octets entrants passent par l'API (validation
//! taille/type/appartenance côté serveur) et les lectures sortent en URL
//! présignée à durée courte, émise derrière un endpoint authentifié.

use std::time::Duration;

use async_trait::async_trait;
use aws_sdk_s3::config::{BehaviorVersion, Credentials, Region};
use aws_sdk_s3::presigning::PresigningConfig;
use aws_sdk_s3::primitives::ByteStream;
use aws_sdk_s3::Client;
use chrono::Utc;

use comptes::{DepotObjets, ErreurObjets, UrlPresignee};

/// Fournisseur d'identifiants : les clés viennent du `.env` du VPS
/// (constitution VIII) — jamais de chaîne de credentials AWS implicite, qui
/// pourrait aller interroger un service de métadonnées inexistant.
const SOURCE_IDENTIFIANTS: &str = "mefali-env";

/// [`DepotObjets`] sur Garage (API S3).
pub struct S3Objets {
    client: Client,
    bucket: String,
}

impl S3Objets {
    /// Construit le client à partir de la configuration d'environnement.
    ///
    /// `region` : Garage l'exige signée mais ne l'utilise pas pour router —
    /// `garage` est la valeur de `infra/garage/garage.toml` (`s3_region`).
    pub fn nouveau(
        endpoint: &str,
        access_key: &str,
        secret_key: &str,
        bucket: &str,
        region: &str,
    ) -> Self {
        let identifiants =
            Credentials::new(access_key, secret_key, None, None, SOURCE_IDENTIFIANTS);
        let config = aws_sdk_s3::Config::builder()
            .behavior_version(BehaviorVersion::latest())
            .region(Region::new(region.to_owned()))
            .endpoint_url(endpoint)
            .credentials_provider(identifiants)
            // Garage sert http://endpoint/{bucket}/{cle}, pas
            // http://{bucket}.endpoint/{cle}.
            .force_path_style(true)
            .build();
        Self {
            client: Client::from_conf(config),
            bucket: bucket.to_owned(),
        }
    }
}

#[async_trait]
impl DepotObjets for S3Objets {
    async fn deposer(&self, cle: &str, octets: Vec<u8>, mime: &str) -> Result<(), ErreurObjets> {
        self.client
            .put_object()
            .bucket(&self.bucket)
            .key(cle)
            .body(ByteStream::from(octets))
            .content_type(mime)
            .send()
            .await
            .map_err(|e| ErreurObjets(format!("dépôt de {cle} : {e}")))?;
        Ok(())
    }

    async fn presigner_get(&self, cle: &str, ttl: Duration) -> Result<UrlPresignee, ErreurObjets> {
        let presignature = PresigningConfig::expires_in(ttl)
            .map_err(|e| ErreurObjets(format!("durée de présignature : {e}")))?;
        let requete = self
            .client
            .get_object()
            .bucket(&self.bucket)
            .key(cle)
            .presigned(presignature)
            .await
            .map_err(|e| ErreurObjets(format!("présignature de {cle} : {e}")))?;

        // La présignature est un calcul local : elle réussit même sur une clé
        // absente. C'est sans conséquence — le domaine ne présigne un repère
        // qu'après avoir constaté sa présence EN BASE (source de vérité), et un
        // repère purgé est déjà un 404 avant d'arriver ici (FR-022).
        Ok(UrlPresignee {
            url: requete.uri().to_owned(),
            expire_le: Utc::now()
                + chrono::Duration::from_std(ttl)
                    .map_err(|e| ErreurObjets(format!("durée : {e}")))?,
        })
    }

    async fn supprimer(&self, cle: &str) -> Result<(), ErreurObjets> {
        // S3 rend DELETE idempotent : supprimer une clé absente réussit — ce
        // qui est exactement ce dont le rattrapage de purge a besoin (R8).
        self.client
            .delete_object()
            .bucket(&self.bucket)
            .key(cle)
            .send()
            .await
            .map_err(|e| ErreurObjets(format!("suppression de {cle} : {e}")))?;
        Ok(())
    }
}
