//! Jetons de session : accès JWT court + refresh opaque révocable
//! (CPT-02, research R1/R2).
//!
//! ## Pourquoi deux jetons de natures différentes
//!
//! L'accès est un JWT : vérifiable sans toucher la base, donc bon marché sur le
//! chemin chaud — mais irrévocable par nature, d'où sa durée de 15 minutes.
//! Le refresh est OPAQUE et stocké haché : révocable instantanément par un
//! simple lookup indexé. Chacun fait ce que l'autre ne sait pas faire.
//!
//! ## Pourquoi aucun rôle dans le JWT
//!
//! La spec exige qu'une suspension prenne effet à la requête SUIVANTE (US3
//! scénario 6). Un jeton porteur de rôles resterait valide 15 minutes après la
//! suspension. Les rôles sont donc lus en base à chaque requête (R5) — un
//! SELECT indexé, le prix de la conformité.

use std::time::Duration;

use chrono::Utc;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sha2::{Digest, Sha256};
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgComptes;
use crate::modele::{Appareil, ErreurComptes, OrigineRevocation, Session};

/// Durée de vie du jeton d'accès (research R1). Borne l'effet d'une révocation
/// à distance — c'est elle que mesure SC-004 (« au plus tard 15 minutes »).
pub const ACCES_TTL: Duration = Duration::from_secs(15 * 60);

/// Durée de vie du jeton d'inscription post-OTP (research R3).
pub const JETON_INSCRIPTION_TTL: Duration = Duration::from_secs(10 * 60);

/// Entropie du refresh opaque — 256 bits (research R2).
const REFRESH_OCTETS: usize = 32;

/// Entropie du jeton d'inscription — 128 bits, à vie courte et usage unique.
const JETON_INSCRIPTION_OCTETS: usize = 16;

/// Algorithme de signature (research R1) : un seul émetteur, un seul
/// vérificateur — l'asymétrique n'apporterait rien.
const ALGO: Algorithm = Algorithm::HS256;

/// Claims du jeton d'accès. Volontairement minimal : identité + session +
/// bornes temporelles, aucun rôle (voir l'en-tête du module).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Claims {
    /// Compte porteur.
    pub sub: Uuid,
    /// Session — permet de refuser un jeton dont la session a été révoquée.
    pub sid: Uuid,
    /// Émission (epoch secondes).
    pub iat: i64,
    /// Expiration (epoch secondes).
    pub exp: i64,
}

/// Paire de jetons remise à un appareil.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Jetons {
    /// JWT HS256 de 15 minutes.
    pub acces: String,
    /// Refresh opaque — tourne à chaque usage (R2).
    pub rafraichissement: String,
}

/// D'où vient une session — porté par le payload de `session.creee`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OrigineSession {
    /// Numéro déjà connu : la vérification OTP a ouvert la session.
    VerificationOtp,
    /// Numéro inconnu : la session naît avec le compte.
    Inscription,
}

impl OrigineSession {
    /// Valeur portée par le payload de l'événement.
    pub fn comme_str(self) -> &'static str {
        match self {
            OrigineSession::VerificationOtp => "verification_otp",
            OrigineSession::Inscription => "inscription",
        }
    }
}

/// Émet un jeton d'accès pour un couple (compte, session).
pub fn emettre_acces(secret: &[u8], compte: Uuid, session: Uuid) -> Result<String, ErreurComptes> {
    let maintenant = Utc::now().timestamp();
    let claims = Claims {
        sub: compte,
        sid: session,
        iat: maintenant,
        exp: maintenant + ACCES_TTL.as_secs() as i64,
    };
    encode(
        &Header::new(ALGO),
        &claims,
        &EncodingKey::from_secret(secret),
    )
    .map_err(|e| ErreurComptes::Jeton(format!("émission : {e}")))
}

/// Vérifie signature et expiration d'un jeton d'accès.
///
/// N'établit RIEN sur la session : un jeton parfaitement signé peut porter une
/// session révoquée. L'extracteur `Auth` de la couche `api` complète par une
/// vérification en base à chaque requête (research R5).
pub fn verifier_acces(secret: &[u8], jeton: &str) -> Result<Claims, ErreurComptes> {
    // `Validation::new` impose l'algorithme ET exige `exp` : un jeton `alg:none`
    // ou sans expiration est rejeté d'office.
    let validation = Validation::new(ALGO);
    decode::<Claims>(jeton, &DecodingKey::from_secret(secret), &validation)
        .map(|donnees| donnees.claims)
        .map_err(|e| ErreurComptes::Jeton(format!("vérification : {e}")))
}

/// Tire un refresh opaque de 256 bits (CSPRNG).
pub fn generer_refresh() -> String {
    let mut octets = [0u8; REFRESH_OCTETS];
    rand::fill(&mut octets);
    hex(&octets)
}

/// Tire un jeton d'inscription de 128 bits (CSPRNG).
pub fn generer_jeton_inscription() -> String {
    let mut octets = [0u8; JETON_INSCRIPTION_OCTETS];
    rand::fill(&mut octets);
    hex(&octets)
}

/// Empreinte SHA-256 d'un refresh — c'est elle, et jamais le jeton, qui est
/// stockée : un dump de la base ne donne aucun jeton rejouable.
///
/// SHA-256 nu (pas d'argon2) est ici le bon choix : le jeton est un aléa de 256
/// bits, pas un mot de passe — il n'y a rien à deviner par dictionnaire, et le
/// lookup doit rester un index O(1).
pub fn hacher_refresh(jeton: &str) -> Vec<u8> {
    let mut hacheur = Sha256::new();
    hacheur.update(jeton.as_bytes());
    hacheur.finalize().to_vec()
}

// ── Cycle de vie des sessions en base (CPT-02, T011) ───────────────────────

impl PgComptes {
    /// Échange un refresh contre une nouvelle paire (rotation systématique, R2).
    ///
    /// ## La détection de réutilisation
    ///
    /// Un jeton déjà tourné qui revient signale que DEUX porteurs détiennent la
    /// même chaîne : le légitime et un voleur. Impossible de savoir lequel se
    /// présente — on révoque donc la session ENTIÈRE, et les deux repassent par
    /// l'OTP. Seul le légitime a le téléphone.
    ///
    /// Un client qui rejoue un rafraîchissement (timeout réseau) tombera dans
    /// ce filet et perdra sa session : c'est le prix assumé de R2, pas un bug.
    /// La parade est côté client — ne jamais rejouer un refresh à l'aveugle.
    pub async fn tourner_refresh(&self, jeton: &str) -> Result<Jetons, ErreurComptes> {
        let presente = hacher_refresh(jeton);
        let nouveau = generer_refresh();
        let mut tx = self.pool.begin().await?;

        // Rotation en UNE instruction : la clause `WHERE refresh_hash = $1`
        // n'est vraie qu'une fois. Deux rotations concurrentes du même jeton ne
        // peuvent donc pas réussir toutes les deux — la perdante tombera sur la
        // détection de réutilisation ci-dessous, ce qui est le comportement voulu.
        let tournee = sqlx::query!(
            r#"UPDATE comptes.session
               SET refresh_precedent_hash = refresh_hash,
                   refresh_hash = $2,
                   derniere_activite_le = now()
               WHERE refresh_hash = $1 AND revoquee_le IS NULL
               RETURNING id, compte_id"#,
            &presente,
            hacher_refresh(&nouveau),
        )
        .fetch_optional(&mut *tx)
        .await?;

        if let Some(session) = tournee {
            // AUCUN événement : une rotation n'est pas une transition d'état
            // (data-model §4). Seule la révocation en émet un.
            tx.commit().await?;
            let acces = emettre_acces(&self.secret, session.compte_id, session.id)?;
            return Ok(Jetons {
                acces,
                rafraichissement: nouveau,
            });
        }

        // Rien n'a tourné : soit le jeton a DÉJÀ été tourné (réutilisation),
        // soit il est inconnu ou sa session est révoquée.
        let precedente = sqlx::query!(
            r#"SELECT id, compte_id, revoquee_le
               FROM comptes.session WHERE refresh_precedent_hash = $1"#,
            &presente,
        )
        .fetch_optional(&mut *tx)
        .await?;

        if let Some(session) = precedente {
            if session.revoquee_le.is_none() {
                self.revoquer_dans_tx(
                    &mut tx,
                    session.id,
                    session.compte_id,
                    OrigineRevocation::ReutilisationDetectee,
                    None,
                )
                .await?;
                tx.commit().await?;
                tracing::warn!(
                    session = %session.id,
                    "refresh déjà tourné rejoué — session révoquée (vol présumé)"
                );
                return Err(ErreurComptes::RefreshInvalide);
            }
        }
        tx.rollback().await?;
        Err(ErreurComptes::RefreshInvalide)
    }

    /// Révoque une session et émet `session.revoquee`. Renvoie `false` si elle
    /// était déjà révoquée ou inconnue — la révocation est IDEMPOTENTE : se
    /// déconnecter deux fois n'est pas une erreur.
    pub(crate) async fn revoquer_dans_tx(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        session: Uuid,
        compte: Uuid,
        origine: OrigineRevocation,
        revoquee_par: Option<Uuid>,
    ) -> Result<bool, ErreurComptes> {
        let maintenant = Utc::now();
        let touchee = sqlx::query!(
            r#"UPDATE comptes.session SET revoquee_le = $2
               WHERE id = $1 AND revoquee_le IS NULL
               RETURNING compte_id"#,
            session,
            maintenant,
        )
        .fetch_optional(&mut **tx)
        .await?;
        if touchee.is_none() {
            return Ok(false);
        }

        let zone = sqlx::query_scalar!("SELECT zone_id FROM comptes.compte WHERE id = $1", compte,)
            .fetch_one(&mut **tx)
            .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "session.revoquee",
                entite_type: "session",
                entite_id: session,
                payload: json!({
                    "zone": zone,
                    "compte": compte,
                    "origine": origine.comme_str(),
                    "revoquee_par": revoquee_par,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        Ok(true)
    }

    /// Déconnexion LOCALE : l'appareil révoque sa propre session.
    pub async fn deconnecter(&self, session: Uuid, compte: Uuid) -> Result<(), ErreurComptes> {
        let mut tx = self.pool.begin().await?;
        self.revoquer_dans_tx(
            &mut tx,
            session,
            compte,
            OrigineRevocation::Locale,
            Some(compte),
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }

    /// Déconnexion À DISTANCE d'un appareil (US2, SC-004).
    ///
    /// La propriété est vérifiée dans la MÊME requête que la révocation : sans
    /// ce `AND compte_id = $2`, n'importe quel compte authentifié pourrait
    /// déconnecter l'appareil de n'importe qui.
    pub async fn revoquer_appareil(
        &self,
        compte: Uuid,
        session: Uuid,
        demandee_par: Uuid,
    ) -> Result<(), ErreurComptes> {
        let mut tx = self.pool.begin().await?;
        let appartient = sqlx::query_scalar!(
            r#"SELECT EXISTS(
                 SELECT 1 FROM comptes.session WHERE id = $1 AND compte_id = $2
               )"#,
            session,
            compte,
        )
        .fetch_one(&mut *tx)
        .await?;
        if appartient != Some(true) {
            return Err(ErreurComptes::SessionInconnue(session));
        }

        self.revoquer_dans_tx(
            &mut tx,
            session,
            compte,
            OrigineRevocation::ADistance,
            Some(demandee_par),
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }

    /// Appareils actifs du compte (FR-008), du plus récemment actif au plus ancien.
    pub async fn sessions_actives(&self, compte: Uuid) -> Result<Vec<Session>, ErreurComptes> {
        let lignes = sqlx::query!(
            r#"SELECT id, compte_id, appareil_nom, appareil_plateforme,
                      cree_le, derniere_activite_le, revoquee_le
               FROM comptes.session
               WHERE compte_id = $1 AND revoquee_le IS NULL
               ORDER BY derniere_activite_le DESC"#,
            compte,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                Ok(Session {
                    id: l.id,
                    compte_id: l.compte_id,
                    appareil: Appareil {
                        nom: l.appareil_nom,
                        // La colonne porte un CHECK IN ('android','ios') : une
                        // valeur hors énum signale une base corrompue.
                        plateforme: l.appareil_plateforme.parse().map_err(|e: String| {
                            ErreurComptes::Jeton(format!("plateforme en base : {e}"))
                        })?,
                    },
                    cree_le: l.cree_le,
                    derniere_activite_le: l.derniere_activite_le,
                    revoquee_le: l.revoquee_le,
                })
            })
            .collect()
    }

    /// Session ACTIVE par identifiant — base de l'extracteur `Auth` (R5).
    pub async fn session_active(&self, session: Uuid) -> Result<Session, ErreurComptes> {
        self.sessions_actives_par_id(session)
            .await?
            .ok_or(ErreurComptes::SessionInconnue(session))
    }

    async fn sessions_actives_par_id(
        &self,
        session: Uuid,
    ) -> Result<Option<Session>, ErreurComptes> {
        let ligne = sqlx::query!(
            r#"SELECT id, compte_id, appareil_nom, appareil_plateforme,
                      cree_le, derniere_activite_le, revoquee_le
               FROM comptes.session WHERE id = $1 AND revoquee_le IS NULL"#,
            session,
        )
        .fetch_optional(&self.pool)
        .await?;

        ligne
            .map(|l| {
                Ok(Session {
                    id: l.id,
                    compte_id: l.compte_id,
                    appareil: Appareil {
                        nom: l.appareil_nom,
                        plateforme: l.appareil_plateforme.parse().map_err(|e: String| {
                            ErreurComptes::Jeton(format!("plateforme en base : {e}"))
                        })?,
                    },
                    cree_le: l.cree_le,
                    derniere_activite_le: l.derniere_activite_le,
                    revoquee_le: l.revoquee_le,
                })
            })
            .transpose()
    }
}

/// Encodage hexadécimal minuscule.
fn hex(octets: &[u8]) -> String {
    use std::fmt::Write;
    octets.iter().fold(String::new(), |mut sortie, o| {
        let _ = write!(sortie, "{o:02x}");
        sortie
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

    #[test]
    fn acces_emis_puis_verifie_porte_compte_et_session() {
        let compte = Uuid::now_v7();
        let session = Uuid::now_v7();
        let jeton = emettre_acces(SECRET, compte, session).unwrap();

        let claims = verifier_acces(SECRET, &jeton).unwrap();
        assert_eq!(claims.sub, compte);
        assert_eq!(claims.sid, session);
        assert_eq!(
            claims.exp - claims.iat,
            ACCES_TTL.as_secs() as i64,
            "durée de vie = 15 min (SC-004)"
        );
    }

    /// R1 — aucun rôle dans le jeton : la suspension doit valoir dès la requête
    /// suivante, un jeton porteur de rôles la retarderait de 15 minutes.
    #[test]
    fn acces_ne_contient_aucun_role() {
        let jeton = emettre_acces(SECRET, Uuid::now_v7(), Uuid::now_v7()).unwrap();
        let charge = jeton.split('.').nth(1).expect("payload du JWT");
        let decode = |s: &str| {
            use base64_url_decode::decode;
            decode(s)
        };
        let brut = String::from_utf8(decode(charge)).unwrap();
        for interdit in ["role", "client", "coursier", "vendeur", "admin"] {
            assert!(
                !brut.contains(interdit),
                "le jeton ne doit pas porter « {interdit} » : {brut}"
            );
        }
    }

    #[test]
    fn jeton_signe_d_un_autre_secret_refuse() {
        let jeton = emettre_acces(SECRET, Uuid::now_v7(), Uuid::now_v7()).unwrap();
        assert!(verifier_acces(b"un-tout-autre-secret-de-32-octets", &jeton).is_err());
    }

    #[test]
    fn jeton_altere_refuse() {
        let jeton = emettre_acces(SECRET, Uuid::now_v7(), Uuid::now_v7()).unwrap();
        let mut altere = jeton.clone();
        altere.push('x');
        assert!(verifier_acces(SECRET, &altere).is_err());
        assert!(verifier_acces(SECRET, "pas.un.jwt").is_err());
        assert!(verifier_acces(SECRET, "").is_err());
    }

    /// `alg: none` — l'attaque classique sur les JWT. `Validation::new(HS256)`
    /// impose l'algorithme, le jeton non signé est rejeté.
    #[test]
    fn jeton_sans_signature_refuse() {
        // {"alg":"none","typ":"JWT"} . {claims} . (signature vide)
        let entete = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0";
        let claims = "eyJzdWIiOiIwMTkwMDAwMC0wMDAwLTcwMDAtODAwMC0wMDAwMDAwMDAwMDEiLCJzaWQiOiIwMTkwMDAwMC0wMDAwLTcwMDAtODAwMC0wMDAwMDAwMDAwMDIiLCJpYXQiOjAsImV4cCI6OTk5OTk5OTk5OX0";
        assert!(verifier_acces(SECRET, &format!("{entete}.{claims}.")).is_err());
    }

    #[test]
    fn refresh_est_aleatoire_et_hache_de_facon_stable() {
        let a = generer_refresh();
        let b = generer_refresh();
        assert_ne!(a, b, "deux tirages diffèrent");
        assert_eq!(a.len(), REFRESH_OCTETS * 2, "256 bits en hexadécimal");

        assert_eq!(hacher_refresh(&a), hacher_refresh(&a), "hachage stable");
        assert_ne!(hacher_refresh(&a), hacher_refresh(&b));
        assert_eq!(hacher_refresh(&a).len(), 32, "SHA-256");
        assert!(
            !hacher_refresh(&a).starts_with(a.as_bytes()),
            "le hash ne contient pas le jeton"
        );
    }

    #[test]
    fn jeton_inscription_est_aleatoire() {
        let a = generer_jeton_inscription();
        assert_ne!(a, generer_jeton_inscription());
        assert_eq!(a.len(), JETON_INSCRIPTION_OCTETS * 2);
    }

    /// Décodage base64url minimal — le test ne doit pas dépendre d'un crate de
    /// plus juste pour lire un payload de JWT.
    mod base64_url_decode {
        const ALPHABET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

        pub fn decode(entree: &str) -> Vec<u8> {
            let mut tampon = 0u32;
            let mut bits = 0u32;
            let mut sortie = Vec::new();
            for c in entree.bytes() {
                let Some(valeur) = ALPHABET.iter().position(|a| *a == c) else {
                    continue;
                };
                tampon = (tampon << 6) | valeur as u32;
                bits += 6;
                if bits >= 8 {
                    bits -= 8;
                    sortie.push((tampon >> bits) as u8);
                }
            }
            sortie
        }
    }
}
