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

use chrono::{DateTime, TimeZone, Utc};
use commandes::{ErreurCommandes, PositionCoursier, PositionDatee};
use comptes::{Compteur, DepotEphemere, ErreurEphemere, IssueDefi, JetonInscription};
use dispatch::{
    Capacite, ErreurDispatch, InscriptionPool, PoolCoursiers, PoseVerrou, VerrouOffre,
};
use qr::{CompteurEssais, ErreurCompteur};
use tarification::{CacheRoutage, ErreurCache, Troncon};
use uuid::Uuid;

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

// ── Compteur d'essais du code dégradé (QRC-04, port `qr::CompteurEssais`) ────

/// TTL du compteur d'essais par arrêt : borne les tentatives EN LIGNE et au
/// rejeu, puis se reconstruit (éphémère, constitution II — research R7).
const ESSAIS_TTL_S: i64 = 30 * 60;

/// Compteur d'essais du code de secours sur Redis : `INCR qr:essais:{arret_id}`
/// avec pose du TTL à la création (backstop en ligne du plafond de 3).
pub struct RedisEssais {
    pool: Pool,
}

impl RedisEssais {
    /// Construit le compteur à partir de l'URL Redis (`REDIS_URL`).
    pub fn nouveau(redis_url: &str) -> Result<Self, ErreurCompteur> {
        let pool = ConfigRedis::from_url(redis_url)
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| ErreurCompteur(format!("pool Redis : {e}")))?;
        Ok(Self { pool })
    }
}

#[async_trait]
impl CompteurEssais for RedisEssais {
    async fn incrementer_essai(&self, arret_id: Uuid) -> Result<i64, ErreurCompteur> {
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurCompteur(format!("connexion Redis : {e}")))?;
        // Même patron que l'incrément à fenêtre fixe des compteurs OTP : le TTL
        // n'est posé qu'à la création (le 1er essai), jamais glissé ensuite.
        let n: i64 = redis::Script::new(LUA_INCREMENTER_FENETRE_FIXE)
            .key(format!("qr:essais:{arret_id}"))
            .arg(ESSAIS_TTL_S)
            .invoke_async(&mut conn)
            .await
            .map_err(|e| ErreurCompteur(format!("incrément des essais : {e}")))?;
        Ok(n.max(0))
    }
}

// ── Cache de routage par tronçon (cycle TRF 007, port `tarification::CacheRoutage`) ──

/// Cache des tronçons routiers sur Redis (research R3).
///
/// STRICTEMENT éphémère et reconstructible (constitution II) : perdre ces clés
/// coûte un appel OSRM, rien de plus. Une panne du cache n'échoue donc jamais un
/// devis — le domaine journalise et interroge le routage.
///
/// Layout : `tarif:route:v1:{lat_a},{lon_a}:{lat_b},{lon_b}` → `"{distance_m}:{duree_s}"`,
/// TTL posé par la zone (`routage.cache_ttl_h`, 24 h par défaut). Clés
/// composées par le domaine (`tarification::routage::cle_troncon`) : la
/// précision de l'arrondi est un paramètre de zone, pas une décision d'infra.
pub struct RedisCacheRoutage {
    pool: Pool,
}

impl RedisCacheRoutage {
    /// Construit le cache à partir de l'URL Redis (`REDIS_URL`).
    pub fn nouveau(redis_url: &str) -> Result<Self, ErreurCache> {
        let pool = ConfigRedis::from_url(redis_url)
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| ErreurCache(format!("pool Redis : {e}")))?;
        Ok(Self { pool })
    }

    /// Sérialisation compacte d'un tronçon (deux entiers, jamais un flottant).
    fn encoder(t: Troncon) -> String {
        format!("{}:{}", t.distance_m, t.duree_s)
    }

    /// Relit un tronçon ; toute valeur illisible est traitée comme ABSENTE — un
    /// cache corrompu doit coûter un appel de routage, jamais un prix faux.
    fn decoder(brut: &str) -> Option<Troncon> {
        let (d, t) = brut.split_once(':')?;
        Some(Troncon {
            distance_m: d.parse().ok()?,
            duree_s: t.parse().ok()?,
        })
    }
}

#[async_trait]
impl CacheRoutage for RedisCacheRoutage {
    async fn lire(&self, cles: &[String]) -> Result<Vec<Option<Troncon>>, ErreurCache> {
        if cles.is_empty() {
            return Ok(Vec::new());
        }
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurCache(format!("connexion Redis : {e}")))?;
        // MGET : UN aller-retour pour toute la matrice. Un appel par paire
        // ferait N² allers-retours et coûterait plus cher que le routage lui-même.
        let brut: Vec<Option<String>> = redis::cmd("MGET")
            .arg(cles)
            .query_async(&mut conn)
            .await
            .map_err(|e| ErreurCache(format!("lecture des tronçons : {e}")))?;
        Ok(brut
            .into_iter()
            .map(|v| v.as_deref().and_then(Self::decoder))
            .collect())
    }

    async fn ecrire(&self, entrees: &[(String, Troncon)], ttl_s: u64) -> Result<(), ErreurCache> {
        if entrees.is_empty() {
            return Ok(());
        }
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurCache(format!("connexion Redis : {e}")))?;
        // Pipeline (pas MSET) : chaque clé doit porter SON expiration. Un MSET
        // écrirait des tronçons éternels — le TTL de 24 h est ce qui garantit
        // qu'un changement de voirie finit par être repris.
        let mut pipe = redis::pipe();
        for (cle, troncon) in entrees {
            pipe.cmd("SET")
                .arg(cle)
                .arg(Self::encoder(*troncon))
                .arg("EX")
                .arg(ttl_s.max(1))
                .ignore();
        }
        pipe.query_async::<()>(&mut conn)
            .await
            .map_err(|e| ErreurCache(format!("écriture des tronçons : {e}")))
    }
}

/// Dernière position d'un coursier (port [`PositionCoursier`], research R13).
///
/// Layout : `coursier:pos:{uuid}` → `"{lat}:{lon}:{epoch_s}"`, avec un TTL posé
/// par **DSP-01** au moment de l'écriture. Ce cycle ne fait que LIRE : la
/// production de positions appartient au cycle dispatch, et jusqu'à lui la
/// lecture rend simplement `None` — ce qui est exact, pas dégradé.
///
/// ⚠ Trois choses, toutes délibérées :
/// - l'**âge** est calculé ici et voyage avec la position : une position sans
///   âge serait pire que pas de position, l'app la croirait fraîche (FR-040) ;
/// - **aucune erreur** ne sort de la lecture — Redis coupé, clé absente, valeur
///   illisible rendent tous `None`. Un suivi doit rester lisible sans position ;
/// - **aucune coordonnée n'est journalisée** (minimisation ARTCI) : les
///   messages d'erreur ne portent que la nature de la panne.
pub struct RedisPositions {
    pool: Pool,
}

impl RedisPositions {
    /// Construit le lecteur de positions à partir de l'URL Redis.
    pub fn nouveau(redis_url: &str) -> Result<Self, ErreurCommandes> {
        let pool = ConfigRedis::from_url(redis_url)
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| ErreurCommandes::Dependance(format!("pool Redis positions : {e}")))?;
        Ok(Self { pool })
    }

    /// Clé de la dernière position d'un coursier.
    fn cle(coursier: Uuid) -> String {
        format!("coursier:pos:{coursier}")
    }

    /// `lat:lon:epoch_s` → position datée. Toute valeur illisible est traitée
    /// comme ABSENTE : afficher une position fausse serait pire que n'en
    /// afficher aucune.
    fn decoder(brut: &str, maintenant: DateTime<Utc>) -> Option<PositionDatee> {
        let mut parts = brut.split(':');
        let lat: f64 = parts.next()?.parse().ok()?;
        let lon: f64 = parts.next()?.parse().ok()?;
        let epoch_s: i64 = parts.next()?.parse().ok()?;
        let releve_le = Utc.timestamp_opt(epoch_s, 0).single()?;
        Some(PositionDatee {
            lat,
            lon,
            releve_le,
            age_s: (maintenant - releve_le).num_seconds().max(0),
        })
    }
}

#[async_trait]
impl PositionCoursier for RedisPositions {
    async fn derniere(&self, coursier: Uuid) -> Result<Option<PositionDatee>, ErreurCommandes> {
        let Ok(mut conn) = self.pool.get().await else {
            // Redis indisponible : le suivi continue SANS position (R13).
            tracing::warn!("Redis indisponible — suivi servi sans position");
            return Ok(None);
        };
        let brut: Option<String> = match redis::cmd("GET")
            .arg(Self::cle(coursier))
            .query_async(&mut conn)
            .await
        {
            Ok(v) => v,
            Err(_) => {
                tracing::warn!("lecture de position impossible — suivi servi sans position");
                return Ok(None);
            }
        };
        Ok(brut.as_deref().and_then(|b| Self::decoder(b, Utc::now())))
    }
}

#[cfg(test)]
mod tests_positions {
    use super::*;

    #[test]
    fn une_position_illisible_est_traitee_comme_absente() {
        let maintenant = Utc::now();
        for brut in ["", "abc", "5.9", "5.9:-4.8", "5.9:-4.8:pas-un-entier"] {
            assert!(
                RedisPositions::decoder(brut, maintenant).is_none(),
                "« {brut} » ne doit pas produire de position : mieux vaut aucune \
                 position qu'une position fausse",
            );
        }
    }

    #[test]
    fn l_age_voyage_avec_la_position() {
        let maintenant = Utc.timestamp_opt(1_800_000_120, 0).single().unwrap();
        let p = RedisPositions::decoder("5.898:-4.823:1800000000", maintenant)
            .expect("position bien formée");
        assert_eq!(p.age_s, 120, "l'app doit pouvoir dire « il y a 2 min »");
        assert_eq!((p.lat, p.lon), (5.898, -4.823));
    }

    /// Une horloge qui recule ne doit pas produire un âge NÉGATIF — l'app
    /// afficherait « il y a -3 s », ce qui ne veut rien dire.
    #[test]
    fn un_age_negatif_est_replie_a_zero() {
        let maintenant = Utc.timestamp_opt(1_800_000_000, 0).single().unwrap();
        let p = RedisPositions::decoder("5.898:-4.823:1800000100", maintenant).unwrap();
        assert_eq!(p.age_s, 0);
    }
}

// ══════════════════════════════════════════════════════════════════════════
// Cycle DSP 009 — le pool temps réel et le double verrou d'offre
// ══════════════════════════════════════════════════════════════════════════

/// Pose ATOMIQUE des deux verrous d'offre — **les deux, ou aucun** (FR-056).
///
/// Pourquoi un script plutôt que deux `SET NX EX` successifs : entre les deux,
/// il existe une fenêtre où le coursier est verrouillé pour une commande qui
/// n'a pas obtenu son propre verrou. Ce coursier serait alors invisible pour
/// toutes les autres commandes pendant 45 s, sans qu'aucune offre ne lui soit
/// jamais parvenue. `MULTI/EXEC` ne sait pas décider en fonction du résultat de
/// la première commande ; Lua, si.
///
/// Trois retours, parce que les deux refus ne conduisent pas au même
/// comportement (FR-057) : `1` obtenu, `0` coursier déjà porteur (→ candidat
/// suivant), `-1` commande déjà offerte (→ abandonner ce passage).
const LUA_POSER_DOUBLE_VERROU: &str = r#"
if redis.call('SET', KEYS[1], ARGV[1], 'NX', 'EX', ARGV[2]) then
  if redis.call('SET', KEYS[2], ARGV[1], 'NX', 'EX', ARGV[2]) then
    return 1
  end
  redis.call('DEL', KEYS[1])
  return 0
end
return -1
"#;

/// Libération conditionnée au JETON : on ne libère jamais un verrou qu'on ne
/// détient pas.
///
/// Sans cette comparaison, une offre échue puis reprise par un autre passage se
/// ferait effacer ses verrous sous les pieds par la conclusion tardive de la
/// première — et deux coursiers pourraient recevoir la même course.
const LUA_LIBERER_DOUBLE_VERROU: &str = r#"
local liberes = 0
if redis.call('GET', KEYS[1]) == ARGV[1] then
  redis.call('DEL', KEYS[1])
  liberes = liberes + 1
end
if redis.call('GET', KEYS[2]) == ARGV[1] then
  redis.call('DEL', KEYS[2])
  liberes = liberes + 1
end
return liberes
"#;

/// Le pool temps réel des coursiers (port [`PoolCoursiers`], data-model §2).
///
/// **Trois clés par publication**, et le découpage n'est pas cosmétique :
///
/// | Clé | Type | Pourquoi elle existe |
/// |---|---|---|
/// | `coursier:pos:{id}` | string `lat:lon:epoch_s` | format du cycle 008, **inchangé** — [`RedisPositions`] le lit pour le suivi client ; le changer casserait CMD-05 |
/// | `dispatch:etat:{id}` | hash | c'est LUI qui définit « être dans le pool » : son TTL est le heartbeat manquant de DSP-01 |
/// | `dispatch:pool:{zone}` | GEO (zset) | pré-filtre géographique — Redis n'expire pas par membre, d'où l'élagage |
///
/// **Aucune erreur de lecture ne remonte** : Redis muet dégrade, il ne casse
/// pas. Une écriture, elle, remonte son échec — publier sans l'écrire ferait
/// croire au coursier qu'il est en ligne alors qu'aucune offre ne viendra.
pub struct RedisPool {
    pool: Pool,
}

impl RedisPool {
    /// Construit le pool à partir de l'URL Redis.
    pub fn nouveau(redis_url: &str) -> Result<Self, ErreurDispatch> {
        let pool = ConfigRedis::from_url(redis_url)
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| ErreurDispatch::Dependance(format!("pool Redis dispatch : {e}")))?;
        Ok(Self { pool })
    }

    /// Clé de position — **format du cycle 008**, jamais modifié.
    fn cle_position(coursier: Uuid) -> String {
        format!("coursier:pos:{coursier}")
    }

    /// Clé de l'état de pool. Son existence EST l'appartenance au pool.
    fn cle_etat(coursier: Uuid) -> String {
        format!("dispatch:etat:{coursier}")
    }

    /// Clé de l'index géographique d'une zone.
    fn cle_index(zone: Uuid) -> String {
        format!("dispatch:pool:{zone}")
    }

    /// Capacités sérialisées en CSV `famille:valeur` — un hash Redis ne porte
    /// que des chaînes, et une liste de deux champs se relit sans ambiguïté.
    fn encoder_capacites(capacites: &[Capacite]) -> String {
        capacites
            .iter()
            .map(|c| format!("{}:{}", c.famille, c.valeur))
            .collect::<Vec<_>>()
            .join(",")
    }

    /// Décodage tolérant : une entrée mal formée est IGNORÉE plutôt que de faire
    /// échouer toute la lecture — une capacité perdue écarte un coursier, une
    /// lecture qui échoue les écarte tous.
    fn decoder_capacites(brut: &str) -> Vec<Capacite> {
        brut.split(',')
            .filter(|s| !s.is_empty())
            .filter_map(|s| {
                let (famille, valeur) = s.split_once(':')?;
                Some(Capacite {
                    famille: famille.to_owned(),
                    valeur: valeur.to_owned(),
                })
            })
            .collect()
    }
}

#[async_trait]
impl PoolCoursiers for RedisPool {
    async fn publier(&self, i: &InscriptionPool, ttl: Duration) -> Result<(), ErreurDispatch> {
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("Redis indisponible : {e}")))?;
        let ttl_s = ttl.as_secs().max(1);
        let maintenant = Utc::now().timestamp();

        let mut pipe = redis::pipe();
        // 1. Position au format historique (lu par le suivi client).
        pipe.cmd("SET")
            .arg(Self::cle_position(i.coursier))
            .arg(format!("{}:{}:{maintenant}", i.lat, i.lon))
            .arg("EX")
            .arg(ttl_s)
            .ignore();
        // 2. État de pool — les champs que l'éligibilité pré-filtre.
        pipe.cmd("HSET")
            .arg(Self::cle_etat(i.coursier))
            .arg("zone")
            .arg(i.zone.to_string())
            .arg("en_ligne")
            .arg(i.en_ligne as i64)
            .arg("capacites")
            .arg(Self::encoder_capacites(&i.capacites))
            .arg("note_centiemes")
            .arg(i.note_centiemes.map(|n| n.to_string()).unwrap_or_default())
            .arg("plafond_unites")
            .arg(i.plafond_unites)
            .arg("devise")
            .arg(&i.devise)
            .arg("course_active")
            .arg(i.course_active.map(|c| c.to_string()).unwrap_or_default())
            .arg("lat")
            .arg(i.lat.to_string())
            .arg("lon")
            .arg(i.lon.to_string())
            .arg("publie_le")
            .arg(maintenant)
            .ignore();
        pipe.cmd("EXPIRE")
            .arg(Self::cle_etat(i.coursier))
            .arg(ttl_s)
            .ignore();
        // 3. Index géographique — sans expiration par membre (limite de Redis).
        pipe.cmd("GEOADD")
            .arg(Self::cle_index(i.zone))
            .arg(i.lon)
            .arg(i.lat)
            .arg(i.coursier.to_string())
            .ignore();

        pipe.query_async::<()>(&mut conn)
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("publication au pool : {e}")))
    }

    async fn retirer(&self, coursier: Uuid, zone: Uuid) -> Result<(), ErreurDispatch> {
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("Redis indisponible : {e}")))?;
        let mut pipe = redis::pipe();
        pipe.cmd("DEL").arg(Self::cle_etat(coursier)).ignore();
        pipe.cmd("DEL").arg(Self::cle_position(coursier)).ignore();
        pipe.cmd("ZREM")
            .arg(Self::cle_index(zone))
            .arg(coursier.to_string())
            .ignore();
        pipe.query_async::<()>(&mut conn)
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("retrait du pool : {e}")))
    }

    async fn dans_rayon(
        &self,
        zone: Uuid,
        lat: f64,
        lon: f64,
        rayon_m: i64,
    ) -> Result<Vec<Uuid>, ErreurDispatch> {
        let Ok(mut conn) = self.pool.get().await else {
            tracing::warn!("Redis indisponible — pré-filtre géographique vide");
            return Ok(Vec::new());
        };
        let membres: Vec<String> = match redis::cmd("GEOSEARCH")
            .arg(Self::cle_index(zone))
            .arg("FROMLONLAT")
            .arg(lon)
            .arg(lat)
            .arg("BYRADIUS")
            .arg(rayon_m.max(0))
            .arg("m")
            .arg("ASC")
            .query_async(&mut conn)
            .await
        {
            Ok(v) => v,
            Err(e) => {
                tracing::warn!(erreur = %e, "pré-filtre géographique impossible");
                return Ok(Vec::new());
            }
        };
        Ok(membres.iter().filter_map(|m| m.parse().ok()).collect())
    }

    async fn etat(&self, coursier: Uuid) -> Result<Option<InscriptionPool>, ErreurDispatch> {
        let Ok(mut conn) = self.pool.get().await else {
            tracing::warn!("Redis indisponible — état de pool inconnu");
            return Ok(None);
        };
        let champs: std::collections::HashMap<String, String> = match redis::cmd("HGETALL")
            .arg(Self::cle_etat(coursier))
            .query_async(&mut conn)
            .await
        {
            Ok(v) => v,
            Err(e) => {
                tracing::warn!(erreur = %e, "lecture d'état de pool impossible");
                return Ok(None);
            }
        };
        if champs.is_empty() {
            // Sorti du pool : ce n'est JAMAIS une erreur, c'est l'information.
            return Ok(None);
        }
        // Un état illisible est traité comme ABSENT : mieux vaut ne pas offrir
        // que d'offrir sur une donnée fausse.
        let lire = |cle: &str| champs.get(cle).map(String::as_str).unwrap_or_default();
        let Ok(zone) = lire("zone").parse::<Uuid>() else {
            tracing::warn!("état de pool illisible (zone) — traité comme absent");
            return Ok(None);
        };
        let (Ok(lat), Ok(lon)) = (lire("lat").parse::<f64>(), lire("lon").parse::<f64>()) else {
            tracing::warn!("état de pool illisible (position) — traité comme absent");
            return Ok(None);
        };
        let publie_le = lire("publie_le").parse::<i64>().unwrap_or_default();
        Ok(Some(InscriptionPool {
            coursier,
            zone,
            lat,
            lon,
            en_ligne: lire("en_ligne") == "1",
            capacites: Self::decoder_capacites(lire("capacites")),
            note_centiemes: lire("note_centiemes").parse().ok(),
            plafond_unites: lire("plafond_unites").parse().unwrap_or_default(),
            devise: lire("devise").to_owned(),
            course_active: lire("course_active").parse().ok(),
            age_s: (Utc::now().timestamp() - publie_le).max(0),
        }))
    }

    async fn elaguer(&self, zone: Uuid) -> Result<usize, ErreurDispatch> {
        let Ok(mut conn) = self.pool.get().await else {
            return Ok(0);
        };
        let membres: Vec<String> = match redis::cmd("ZRANGE")
            .arg(Self::cle_index(zone))
            .arg(0)
            .arg(-1)
            .query_async(&mut conn)
            .await
        {
            Ok(v) => v,
            Err(e) => {
                tracing::warn!(erreur = %e, "élagage impossible — index inchangé");
                return Ok(0);
            }
        };
        let mut fantomes = Vec::new();
        for membre in membres {
            let existe: i64 = redis::cmd("EXISTS")
                .arg(format!("dispatch:etat:{membre}"))
                .query_async(&mut conn)
                .await
                .unwrap_or(1);
            if existe == 0 {
                fantomes.push(membre);
            }
        }
        if fantomes.is_empty() {
            return Ok(0);
        }
        let mut cmd = redis::cmd("ZREM");
        cmd.arg(Self::cle_index(zone));
        for f in &fantomes {
            cmd.arg(f);
        }
        let retires: i64 = cmd.query_async(&mut conn).await.unwrap_or(0);
        Ok(retires.max(0) as usize)
    }
}

/// Le double verrou d'offre (port [`VerrouOffre`], research R3).
///
/// Le verrou n'est PAS le registre : la ligne `dispatch.offre` en Postgres porte
/// l'échéance, le destinataire et l'issue. Perdre Redis perd au pire **une offre
/// en vol**, que le tic redétecte par son échéance persistée.
pub struct RedisVerrouOffre {
    pool: Pool,
}

impl RedisVerrouOffre {
    /// Construit le porteur de verrous à partir de l'URL Redis.
    pub fn nouveau(redis_url: &str) -> Result<Self, ErreurDispatch> {
        let pool = ConfigRedis::from_url(redis_url)
            .create_pool(Some(Runtime::Tokio1))
            .map_err(|e| ErreurDispatch::Dependance(format!("pool Redis verrous : {e}")))?;
        Ok(Self { pool })
    }

    /// Clé du verrou de commande.
    fn cle_commande(commande: Uuid) -> String {
        format!("dispatch:offre:cmd:{commande}")
    }

    /// Clé du verrou de coursier.
    fn cle_coursier(coursier: Uuid) -> String {
        format!("dispatch:offre:crs:{coursier}")
    }
}

#[async_trait]
impl VerrouOffre for RedisVerrouOffre {
    async fn poser(
        &self,
        commande: Uuid,
        coursier: Uuid,
        jeton: Uuid,
        ttl: Duration,
    ) -> Result<PoseVerrou, ErreurDispatch> {
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("Redis indisponible : {e}")))?;
        let code: i64 = redis::Script::new(LUA_POSER_DOUBLE_VERROU)
            .key(Self::cle_commande(commande))
            .key(Self::cle_coursier(coursier))
            .arg(jeton.to_string())
            .arg(ttl.as_secs().max(1))
            .invoke_async(&mut conn)
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("pose du double verrou : {e}")))?;
        Ok(match code {
            1 => PoseVerrou::Obtenu,
            0 => PoseVerrou::CoursierDejaPorteur,
            _ => PoseVerrou::CommandeDejaOfferte,
        })
    }

    async fn liberer(
        &self,
        commande: Uuid,
        coursier: Uuid,
        jeton: Uuid,
    ) -> Result<(), ErreurDispatch> {
        let mut conn = self
            .pool
            .get()
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("Redis indisponible : {e}")))?;
        redis::Script::new(LUA_LIBERER_DOUBLE_VERROU)
            .key(Self::cle_commande(commande))
            .key(Self::cle_coursier(coursier))
            .arg(jeton.to_string())
            .invoke_async::<i64>(&mut conn)
            .await
            .map_err(|e| ErreurDispatch::Dependance(format!("libération du verrou : {e}")))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests_pool {
    use super::*;

    /// L'encodage des capacités fait l'aller-retour, et une entrée mal formée
    /// est ignorée plutôt que de faire échouer la lecture entière : une capacité
    /// perdue écarte UN coursier, une lecture qui échoue les écarte TOUS.
    #[test]
    fn les_capacites_font_l_aller_retour_et_tolerent_le_bruit() {
        let capacites = vec![Capacite::transport("moto"), Capacite::transport("velo")];
        let brut = RedisPool::encoder_capacites(&capacites);
        assert_eq!(brut, "transport:moto,transport:velo");
        assert_eq!(RedisPool::decoder_capacites(&brut), capacites);

        assert!(RedisPool::decoder_capacites("").is_empty());
        assert_eq!(
            RedisPool::decoder_capacites("transport:moto,pas-une-paire,transport:velo"),
            capacites,
            "l'entrée mal formée est ignorée, les autres survivent",
        );
    }

    /// La clé de position garde le format du cycle 008 : `RedisPositions` la
    /// lit, et le suivi client en dépend.
    #[test]
    fn la_cle_de_position_reste_celle_du_cycle_008() {
        let coursier = Uuid::now_v7();
        assert_eq!(
            RedisPool::cle_position(coursier),
            format!("coursier:pos:{coursier}"),
        );
    }
}
