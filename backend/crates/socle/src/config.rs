//! Configuration d'environnement (data-model.md §4, FR-017).
//!
//! Chargée depuis les variables d'environnement (`.env` sur le VPS, hors Git ;
//! `infra/.env.example` documente le contrat). Aucun paramètre MÉTIER ici : ceux-là
//! iront en configuration de zone dès le cycle ZON (constitution I).

use serde::Deserialize;

/// Environnement d'exécution du backend.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AppEnv {
    /// Développement local (Swagger UI exposée).
    #[default]
    Dev,
    /// Production (Swagger UI absente — constitution VIII).
    Production,
}

impl AppEnv {
    /// `true` en production — protège les surfaces réservées au dev.
    pub fn is_production(self) -> bool {
        matches!(self, AppEnv::Production)
    }

    /// Lit `APP_ENV` dans l'environnement du processus, en défaut FERMÉ.
    ///
    /// Seul le littéral `dev` (espaces et casse ignorés) ouvre les surfaces
    /// réservées au développement ; TOUT le reste — variable absente, faute de
    /// frappe, `staging` — vaut production.
    ///
    /// ⚠ Le sens de la lecture est l'inverse de [`Config::app_env`], et c'est
    /// voulu. Ce point de décision est lu AVANT [`Config::from_env`], qui
    /// échoue quand la configuration est incomplète : un `.env` oublié ne doit
    /// pas ouvrir Swagger UI ni `/dev/otp` (qui rend un code OTP en clair) au
    /// premier venu. Un défaut ouvert ne coûte ici qu'un `APP_ENV=dev` à poser
    /// en développement ; un défaut fermé qui se trompe coûte des comptes.
    pub fn depuis_env() -> Self {
        Self::depuis_valeur(std::env::var("APP_ENV").ok().as_deref())
    }

    /// Cœur pur de [`AppEnv::depuis_env`] : `None` = variable absente.
    ///
    /// Séparé pour être testable sans muter l'environnement du processus, que
    /// les tests parallèles partagent — même raison que le `prod: bool` de
    /// `mount_docs` côté api.
    fn depuis_valeur(valeur: Option<&str>) -> Self {
        match valeur {
            Some(v) if v.trim().eq_ignore_ascii_case("dev") => AppEnv::Dev,
            _ => AppEnv::Production,
        }
    }
}

/// Fournisseur d'envoi de SMS sélectionné à l'exécution (cycle CPT, research R6).
///
/// Une seule valeur ce cycle : le choix de l'agrégateur réel (annexe B du
/// cadrage) n'est pas tranché et appartient au cycle NTF, qui ajoutera ici sa
/// variante. Énum plutôt que chaîne libre : une faute de frappe dans le `.env`
/// doit échouer au démarrage, pas envoyer les OTP dans le vide.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SmsMode {
    /// Journalise le message au lieu de l'envoyer (dev, tests, staging).
    #[default]
    Traces,
}

/// Contrat du `.env` consommé par le backend.
#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    /// Postgres — seule vérité durable.
    pub database_url: String,
    /// Redis — éphémère uniquement.
    pub redis_url: String,
    /// Garage (API S3) — endpoint.
    pub s3_endpoint: String,
    /// Garage — clé d'accès dédiée au backend.
    pub s3_access_key: String,
    /// Garage — secret dédié au backend.
    pub s3_secret_key: String,
    /// Garage — bucket applicatif.
    pub s3_bucket: String,
    /// OSRM — service de routage (consommé par les cycles suivants).
    pub osrm_url: String,
    /// Secret de signature des jetons d'accès HS256 (cycle CPT, research R1).
    /// Sert aussi à dériver la clé HMAC des défis OTP (R3). ≥ 32 octets —
    /// vérifié par [`Config::valider`].
    pub jwt_secret: String,
    /// Secret HMAC des jetons de plaque des prestataires (cycle VND, research
    /// R2). DISTINCT du secret JWT : un jeton de plaque est gravé sur une
    /// plaque physique et vit des années — sa clé tourne indépendamment des
    /// sessions. ≥ 32 octets — vérifié par [`Config::valider`].
    pub plaque_secret: String,
    /// Fournisseur d'envoi de SMS (cycle CPT, research R6).
    #[serde(default)]
    pub sms_mode: SmsMode,
    /// Sentry — vide en dev (désactivé).
    #[serde(default)]
    pub sentry_dsn: Option<String>,
    /// `dev` (défaut) ou `production`.
    ///
    /// ⚠ N'est PAS ce qui protège les surfaces réservées au dev : ce champ
    /// n'existe que si toute la configuration se désérialise, et son défaut est
    /// OUVERT (`dev`). Le gate lit [`AppEnv::depuis_env`], défaut FERMÉ, avant
    /// et indépendamment de [`Config::from_env`].
    #[serde(default)]
    pub app_env: AppEnv,
}

/// Longueur minimale du secret JWT — 256 bits, la taille de sortie de HS256
/// (research R1). En deçà, la signature est plus faible que l'algorithme.
const JWT_SECRET_OCTETS_MIN: usize = 32;

impl Config {
    /// Charge la configuration depuis l'environnement du processus.
    ///
    /// Toutes les variables non optionnelles doivent être présentes, sinon une
    /// erreur explicite est renvoyée au démarrage.
    pub fn from_env() -> Result<Self, config::ConfigError> {
        let config: Config = config::Config::builder()
            .add_source(config::Environment::default())
            .build()?
            .try_deserialize()?;
        config.valider()?;
        Ok(config)
    }

    /// Refuse une configuration présente mais dangereuse.
    ///
    /// Distinction voulue (constitution VIII) : une configuration ABSENTE fait
    /// tourner le service en mode dégradé (`/health` seul, patron du cycle 001).
    /// Une configuration PRÉSENTE mais trop faible échoue bruyamment — un
    /// secret de 8 octets ne doit jamais signer de session en silence.
    fn valider(&self) -> Result<(), config::ConfigError> {
        if self.jwt_secret.len() < JWT_SECRET_OCTETS_MIN {
            return Err(config::ConfigError::Message(format!(
                "JWT_SECRET fait {} octets — minimum {JWT_SECRET_OCTETS_MIN} (256 bits, HS256). \
                 Générer : openssl rand -hex 32",
                self.jwt_secret.len()
            )));
        }
        if self.plaque_secret.len() < JWT_SECRET_OCTETS_MIN {
            return Err(config::ConfigError::Message(format!(
                "PLAQUE_SECRET fait {} octets — minimum {JWT_SECRET_OCTETS_MIN} (256 bits, \
                 HMAC-SHA256). Générer : openssl rand -hex 32",
                self.plaque_secret.len()
            )));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config_avec_secret(secret: &str) -> Config {
        Config {
            database_url: "postgres://x".to_owned(),
            redis_url: "redis://x".to_owned(),
            s3_endpoint: "http://x".to_owned(),
            s3_access_key: "k".to_owned(),
            s3_secret_key: "s".to_owned(),
            s3_bucket: "b".to_owned(),
            osrm_url: "http://x".to_owned(),
            jwt_secret: secret.to_owned(),
            plaque_secret: "p".repeat(32),
            sms_mode: SmsMode::Traces,
            sentry_dsn: None,
            app_env: AppEnv::Dev,
        }
    }

    #[test]
    fn secret_jwt_trop_court_refuse() {
        let erreur = config_avec_secret("trop-court").valider().unwrap_err();
        assert!(erreur.to_string().contains("JWT_SECRET"));
    }

    #[test]
    fn secret_jwt_de_32_octets_accepte() {
        assert!(config_avec_secret(&"a".repeat(32)).valider().is_ok());
    }

    #[test]
    fn secret_plaque_trop_court_refuse() {
        let mut config = config_avec_secret(&"a".repeat(32));
        config.plaque_secret = "court".to_owned();
        let erreur = config.valider().unwrap_err();
        assert!(erreur.to_string().contains("PLAQUE_SECRET"));
    }

    #[test]
    fn seul_dev_explicite_ouvre_les_surfaces_de_dev() {
        for valeur in ["dev", "DEV", " dev ", "Dev"] {
            assert_eq!(
                AppEnv::depuis_valeur(Some(valeur)),
                AppEnv::Dev,
                "« {valeur} » désigne bien le développement",
            );
        }
    }

    #[test]
    fn app_env_absent_ou_inattendu_vaut_production() {
        // Le cas qui compte : sans `APP_ENV`, l'ancienne comparaison de chaîne
        // rendait `prod = false` et publiait Swagger UI — et publierait
        // aujourd'hui `/dev/otp`, qui rend un code OTP en clair.
        assert_eq!(AppEnv::depuis_valeur(None), AppEnv::Production);
        for valeur in ["production", "", "staging", "développement", "0"] {
            assert_eq!(
                AppEnv::depuis_valeur(Some(valeur)),
                AppEnv::Production,
                "« {valeur} » n'est pas `dev` — défaut fermé",
            );
        }
    }
}
