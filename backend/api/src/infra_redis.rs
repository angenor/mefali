//! Implémentation RÉELLE du port [`DepotEphemere`] sur Redis (research R3).
//!
//! Vit dans la couche `api` — la composition racine connaît l'infrastructure,
//! le crate `comptes` ne connaît que son trait (constitution II).
//!
//! Redis est ici STRICTEMENT éphémère et reconstructible : perdre ces clés
//! coûte une re-demande de code, rien de plus. Aucune vérité durable n'y
//! transite (Postgres reste seul dépositaire).
//!
//! Layout des clés — data-model §3 :
//! | `otp:defi:{e164}` | hash `{empreinte, essais}` | 300 s |
//! | `otp:sms:{e164}`  | compteur                   | 3600 s |
//! | `otp:ip:{ip}`     | compteur                   | 3600 s |
//! | `insc:{jeton}`    | JSON du jeton d'inscription | 600 s |

use std::time::Duration;

use async_trait::async_trait;
use deadpool_redis::{Config as ConfigRedis, Pool, Runtime};

use comptes::{Compteur, DepotEphemere, ErreurEphemere, IssueDefi, JetonInscription};

/// Codes de retour des scripts Lua — le contrat entre le script et Rust.
const CODE_ABSENT: i64 = 0;
const CODE_VALIDE: i64 = 1;
const CODE_INVALIDE: i64 = 2;

/// Vérifier-et-décrémenter ATOMIQUE d'un défi OTP.
///
/// Pourquoi un script : entre un `GET` et un `DECR` faits séparément, N
/// requêtes concurrentes consommeraient toutes le même « essai restant » et le
/// plafond de 3 tentatives s'effondrerait. Redis exécute un script sans
/// entrelacement — le plafond devient infranchissable.
///
/// L'expiration n'est pas gérée ici : une clé au TTL écoulé est simplement
/// absente pour `HMGET`, ce qui donne le même `CODE_ABSENT` neutre.
///
/// La comparaison d'empreintes n'est pas à temps constant (Lua `==`). Sans
/// portée pratique : l'attaquant dispose de 3 essais sur un secret à 10⁶
/// combinaisons — la protection vient du plafond, pas du temps de comparaison
/// (research R3).
const LUA_CONSOMMER_ESSAI: &str = r#"
local defi = redis.call('HMGET', KEYS[1], 'empreinte', 'essais')
if not defi[1] then
  return {0, 0}
end
if defi[1] == ARGV[1] then
  redis.call('DEL', KEYS[1])
  return {1, 0}
end
local restants = redis.call('HINCRBY', KEYS[1], 'essais', -1)
if restants <= 0 then
  redis.call('DEL', KEYS[1])
  return {0, 0}
end
return {2, restants}
"#;

/// Incrément à fenêtre FIXE : le TTL n'est posé qu'à la création du compteur.
///
/// Un `EXPIRE` à chaque incrément ferait glisser la fenêtre indéfiniment : un
/// numéro sollicité toutes les 50 minutes ne verrait jamais son quota se
/// rouvrir, et un attaquant régulier ne l'atteindrait jamais. La fenêtre fixe
/// d'une heure suffit au sens produit « 3 SMS/h » (research R3).
const LUA_INCREMENTER_FENETRE_FIXE: &str = r#"
local n = redis.call('INCR', KEYS[1])
if n == 1 then
  redis.call('EXPIRE', KEYS[1], ARGV[1])
end
return n
"#;

/// [`DepotEphemere`] sur Redis via un pool deadpool.
pub struct RedisEphemere {
    pool: Pool,
}

impl RedisEphemere {
    /// Construit le dépôt à partir de l'URL Redis (`REDIS_URL`).
    pub fn nouveau(redis_url: &str) -> Result<Self, ErreurEphemere> {
        let pool = ConfigRedis::from_url(redis_url)
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| ErreurEphemere(format!("pool Redis : {e}")))?;
        Ok(Self { pool })
    }

    /// Connexion du pool.
    async fn conn(&self) -> Result<deadpool_redis::Connection, ErreurEphemere> {
        self.pool
            .get()
            .await
            .map_err(|e| ErreurEphemere(format!("connexion Redis : {e}")))
    }

    /// Clé du compteur — data-model §3.
    fn cle_compteur(compteur: Compteur<'_>) -> String {
        match compteur {
            Compteur::SmsParNumero(e164) => format!("otp:sms:{e164}"),
            Compteur::DemandesParIp(ip) => format!("otp:ip:{ip}"),
        }
    }

    /// Clé du défi — data-model §3.
    fn cle_defi(e164: &str) -> String {
        format!("otp:defi:{e164}")
    }

    /// Clé du jeton d'inscription — data-model §3.
    fn cle_jeton(jeton: &str) -> String {
        format!("insc:{jeton}")
    }
}

#[async_trait]
impl DepotEphemere for RedisEphemere {
    async fn poser_defi(
        &self,
        e164: &str,
        empreinte: &[u8],
        essais: u8,
        ttl: Duration,
    ) -> Result<(), ErreurEphemere> {
        let mut conn = self.conn().await?;
        let cle = Self::cle_defi(e164);
        // MULTI/EXEC : le DEL préalable garantit qu'aucun essai résiduel de
        // l'ancien défi ne survit à l'écrasement (FR-002).
        redis::pipe()
            .atomic()
            .del(&cle)
            .ignore()
            .hset(&cle, "empreinte", empreinte)
            .ignore()
            .hset(&cle, "essais", essais)
            .ignore()
            .expire(&cle, ttl.as_secs() as i64)
            .ignore()
            .query_async::<()>(&mut conn)
            .await
            .map_err(|e| ErreurEphemere(format!("pose du défi : {e}")))
    }

    async fn consommer_essai(
        &self,
        e164: &str,
        empreinte: &[u8],
    ) -> Result<IssueDefi, ErreurEphemere> {
        let mut conn = self.conn().await?;
        let (code, restants): (i64, i64) = redis::Script::new(LUA_CONSOMMER_ESSAI)
            .key(Self::cle_defi(e164))
            .arg(empreinte)
            .invoke_async(&mut conn)
            .await
            .map_err(|e| ErreurEphemere(format!("consommation d'essai : {e}")))?;

        Ok(match code {
            CODE_VALIDE => IssueDefi::Valide,
            CODE_INVALIDE => IssueDefi::Invalide {
                essais_restants: restants.clamp(0, u8::MAX as i64) as u8,
            },
            CODE_ABSENT => IssueDefi::Absent,
            // Le script et ce match forment un contrat : une dérive doit se
            // voir. On se replie sur l'issue la plus SÛRE (aucun défi → 401
            // neutre) plutôt que d'ouvrir une session sur un code inconnu.
            autre => {
                tracing::error!(code = autre, "script OTP : code de retour inattendu");
                IssueDefi::Absent
            }
        })
    }

    async fn incrementer(
        &self,
        compteur: Compteur<'_>,
        ttl: Duration,
    ) -> Result<u64, ErreurEphemere> {
        let mut conn = self.conn().await?;
        let n: i64 = redis::Script::new(LUA_INCREMENTER_FENETRE_FIXE)
            .key(Self::cle_compteur(compteur))
            .arg(ttl.as_secs() as i64)
            .invoke_async(&mut conn)
            .await
            .map_err(|e| ErreurEphemere(format!("incrément du compteur : {e}")))?;
        Ok(n.max(0) as u64)
    }

    async fn poser_jeton_inscription(
        &self,
        jeton: &str,
        contenu: &JetonInscription,
        ttl: Duration,
    ) -> Result<(), ErreurEphemere> {
        let mut conn = self.conn().await?;
        let charge = serde_json::to_string(contenu)
            .map_err(|e| ErreurEphemere(format!("sérialisation du jeton : {e}")))?;
        redis::cmd("SET")
            .arg(Self::cle_jeton(jeton))
            .arg(charge)
            .arg("EX")
            .arg(ttl.as_secs())
            .query_async::<()>(&mut conn)
            .await
            .map_err(|e| ErreurEphemere(format!("pose du jeton : {e}")))
    }

    async fn consommer_jeton_inscription(
        &self,
        jeton: &str,
    ) -> Result<Option<JetonInscription>, ErreurEphemere> {
        let mut conn = self.conn().await?;
        // GETDEL : lire et détruire en UNE commande — deux rejeux concurrents
        // de /auth/inscription ne peuvent pas créer deux comptes.
        let charge: Option<String> = redis::cmd("GETDEL")
            .arg(Self::cle_jeton(jeton))
            .query_async(&mut conn)
            .await
            .map_err(|e| ErreurEphemere(format!("consommation du jeton : {e}")))?;

        charge
            .map(|c| {
                serde_json::from_str(&c)
                    .map_err(|e| ErreurEphemere(format!("désérialisation du jeton : {e}")))
            })
            .transpose()
    }
}
