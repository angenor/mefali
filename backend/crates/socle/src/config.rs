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

/// Fournisseur de paiement sélectionné à l'exécution (cycle PAY, research R4).
///
/// **Aucune marque d'agrégateur ici, et jamais.** Le cadrage §10.7 dit le choix
/// non tranché ; `agregateur` désigne le client HTTP *paramétré*, qui se branche
/// sur celui qui sera retenu par configuration seule (FR-003, FR-042).
///
/// Énum plutôt que chaîne libre, pour la raison exacte de [`SmsMode`] : une
/// faute de frappe dans le `.env` doit échouer au démarrage, pas encaisser dans
/// le vide.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PaiementFournisseur {
    /// Double pilotable — dev, tests, staging. **Défaut** : un environnement
    /// mal configuré simule, il n'appelle pas un tiers au hasard.
    #[default]
    Simule,
    /// Client HTTP paramétré vers l'agrégateur retenu (production).
    Agregateur,
}

impl PaiementFournisseur {
    /// Identifiant stable, employé comme segment d'URL du webhook et stocké sur
    /// la transaction. **Jamais interprété par une règle métier** (FR-003).
    pub fn comme_str(self) -> &'static str {
        match self {
            PaiementFournisseur::Simule => "simule",
            PaiementFournisseur::Agregateur => "agregateur",
        }
    }
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
    /// Fournisseur de paiement câblé (cycle PAY, research R4). Défaut `simule`.
    #[serde(default)]
    pub paiement_fournisseur: PaiementFournisseur,
    /// URL de base de l'agrégateur — **requise** en mode `agregateur`.
    #[serde(default)]
    pub paiement_base_url: Option<String>,
    /// Clé d'API de l'agrégateur — **requise** en mode `agregateur`.
    #[serde(default)]
    pub paiement_cle_api: Option<String>,
    /// Secret HMAC de vérification des notifications entrantes (cycle PAY,
    /// research R6). ≥ 32 octets — vérifié par [`Config::valider`].
    ///
    /// DISTINCT des deux autres secrets, et ce n'est pas de la coquetterie : il
    /// est **partagé avec un tiers**. Le mutualiser avec `jwt_secret`
    /// donnerait à l'agrégateur de quoi forger des jetons de session ; avec
    /// `plaque_secret`, de quoi forger des plaques de vendeur.
    #[serde(default)]
    pub paiement_webhook_secret: Option<String>,
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
        self.valider_paiement()?;
        Ok(())
    }

    /// Gardes du cycle PAY (FR-045) : **en mode `agregateur`, une configuration
    /// incomplète refuse le démarrage.**
    ///
    /// ## Pourquoi échouer au démarrage plutôt qu'au premier paiement
    ///
    /// Les trois manques que cette fonction attrape ne produisent pas une
    /// erreur visible : ils produisent une chaîne d'argent **silencieusement
    /// cassée**.
    ///
    /// - Sans `PAIEMENT_BASE_URL` ou `PAIEMENT_CLE_API`, chaque ouverture de
    ///   session rend `502` : les clients voient « réessayez », personne ne voit
    ///   la cause, et les commandes au-dessus du plafond cash redeviennent
    ///   impossibles — le trou même que ce cycle existe pour combler.
    /// - Sans `PAIEMENT_WEBHOOK_SECRET`, c'est pire : l'API **encaisse** (les
    ///   sessions s'ouvrent) mais **ne confirme jamais**, faute de pouvoir
    ///   vérifier une signature. De l'argent part du compte du client vers une
    ///   commande qui expirera. Un secret trop court est le même défaut avec un
    ///   faux sentiment de sécurité : plus faible que HMAC-SHA256 lui-même.
    ///
    /// En mode `simule`, rien n'est exigé : le double ne joint personne et
    /// signe avec son propre secret de test.
    fn valider_paiement(&self) -> Result<(), config::ConfigError> {
        if self.paiement_fournisseur != PaiementFournisseur::Agregateur {
            return Ok(());
        }
        let requis = |champ: &str, valeur: &Option<String>| {
            if valeur.as_deref().is_none_or(str::is_empty) {
                Err(config::ConfigError::Message(format!(
                    "PAIEMENT_FOURNISSEUR=agregateur exige {champ} : sans elle, \
                     l'API ouvrirait des sessions qu'elle ne pourrait jamais \
                     confirmer",
                )))
            } else {
                Ok(())
            }
        };
        requis("PAIEMENT_BASE_URL", &self.paiement_base_url)?;
        requis("PAIEMENT_CLE_API", &self.paiement_cle_api)?;

        let secret = self.paiement_webhook_secret.as_deref().unwrap_or_default();
        if secret.len() < JWT_SECRET_OCTETS_MIN {
            return Err(config::ConfigError::Message(format!(
                "PAIEMENT_WEBHOOK_SECRET fait {} octets — minimum \
                 {JWT_SECRET_OCTETS_MIN} (256 bits, HMAC-SHA256). Sans lui, \
                 aucune notification ne peut être vérifiée : les clients \
                 paieraient et leurs commandes expireraient. \
                 Générer : openssl rand -hex 32",
                secret.len(),
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
            paiement_fournisseur: PaiementFournisseur::Simule,
            paiement_base_url: None,
            paiement_cle_api: None,
            paiement_webhook_secret: None,
            sentry_dsn: None,
            app_env: AppEnv::Dev,
        }
    }

    /// Une configuration `agregateur` COMPLÈTE, dont chaque test retire une
    /// pièce. Partir du valide et casser une chose à la fois isole ce qui est
    /// vraiment exigé — partir de l'invalide ne prouverait que le premier refus.
    fn config_agregateur_complete() -> Config {
        let mut config = config_avec_secret(&"a".repeat(32));
        config.paiement_fournisseur = PaiementFournisseur::Agregateur;
        config.paiement_base_url = Some("https://exemple.invalid".to_owned());
        config.paiement_cle_api = Some("cle".to_owned());
        config.paiement_webhook_secret = Some("w".repeat(32));
        config
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

    // ── Cycle PAY 011 (FR-045) — les trois configurations invalides ───────

    /// Le défaut ne demande rien : un environnement de dev sans variable
    /// `PAIEMENT_*` démarre et simule. C'est ce qui rend le mode `simule`
    /// utilisable comme défaut sûr.
    #[test]
    fn le_mode_simule_n_exige_aucune_variable_de_paiement() {
        let config = config_avec_secret(&"a".repeat(32));
        assert_eq!(config.paiement_fournisseur, PaiementFournisseur::Simule);
        assert!(config.valider().is_ok());
    }

    /// La configuration complète passe — sans ce test, les trois suivants
    /// pourraient tous passer pour une raison qui n'est pas celle qu'ils
    /// nomment.
    #[test]
    fn le_mode_agregateur_complet_demarre() {
        assert!(config_agregateur_complete().valider().is_ok());
    }

    /// Sans URL de base, chaque ouverture de session rendrait `502` et les
    /// commandes au-dessus du plafond cash redeviendraient impossibles.
    #[test]
    fn agregateur_sans_base_url_refuse_le_demarrage() {
        let mut config = config_agregateur_complete();
        config.paiement_base_url = None;
        let erreur = config.valider().unwrap_err();
        assert!(erreur.to_string().contains("PAIEMENT_BASE_URL"));

        // Une chaîne VIDE est un manque, pas une valeur : un `.env` avec
        // `PAIEMENT_BASE_URL=` doit échouer comme une variable absente.
        config.paiement_base_url = Some(String::new());
        assert!(
            config.valider().is_err(),
            "une valeur vide vaut une absence"
        );
    }

    /// Sans clé d'API, le fournisseur refuse chaque appel : même effet, même
    /// invisibilité.
    #[test]
    fn agregateur_sans_cle_api_refuse_le_demarrage() {
        let mut config = config_agregateur_complete();
        config.paiement_cle_api = None;
        let erreur = config.valider().unwrap_err();
        assert!(erreur.to_string().contains("PAIEMENT_CLE_API"));
    }

    /// Le cas le plus grave : l'API encaisserait sans jamais pouvoir confirmer.
    #[test]
    fn agregateur_sans_secret_de_webhook_refuse_le_demarrage() {
        let mut config = config_agregateur_complete();
        config.paiement_webhook_secret = None;
        let erreur = config.valider().unwrap_err();
        assert!(erreur.to_string().contains("PAIEMENT_WEBHOOK_SECRET"));

        // Un secret court est le même défaut, avec un faux sentiment de
        // sécurité : plus faible que l'algorithme qu'il alimente.
        config.paiement_webhook_secret = Some("trop-court".to_owned());
        let erreur = config.valider().unwrap_err();
        assert!(erreur.to_string().contains("PAIEMENT_WEBHOOK_SECRET"));

        config.paiement_webhook_secret = Some("w".repeat(32));
        assert!(config.valider().is_ok(), "32 octets exactement suffisent");
    }

    /// Le segment d'URL du webhook est l'identifiant stable du fournisseur — et
    /// aucune marque d'agrégateur n'y apparaît (FR-003).
    #[test]
    fn l_identifiant_de_fournisseur_ne_nomme_aucune_marque() {
        assert_eq!(PaiementFournisseur::Simule.comme_str(), "simule");
        assert_eq!(PaiementFournisseur::Agregateur.comme_str(), "agregateur");
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
