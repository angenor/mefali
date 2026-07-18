//! Ports du domaine comptes — la frontière avec l'infrastructure
//! (research R3, R6, R7 ; data-model §5).
//!
//! Le crate `comptes` est un domaine PUR : il ne connaît ni Redis, ni Garage,
//! ni fournisseur SMS, seulement ces trois traits (constitution II). Les impls
//! RÉELLES vivent dans la couche `api` (composition racine) ; les impls mémoire
//! livrées ici rendent tout le parcours OTP testable sans réseau — expiration
//! comprise, grâce à l'horloge injectable.
//!
//! [`SmsTraces`] n'est pas qu'un double de test : c'est l'implémentation
//! sélectionnée par `SMS_MODE=traces` en dev/staging (R6), qui journalise le
//! code au lieu de l'envoyer. Le fournisseur réel arrive au cycle NTF, derrière
//! ce même port — sans toucher au domaine ni aux handlers.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use crate::modele::{Appareil, ErreurEphemere, ErreurSms};

// ── Port 1 : dépôt éphémère (Redis — research R3) ──────────────────────────

/// Issue d'UNE tentative de vérification d'un défi OTP.
///
/// ⚠ La couche `api` doit replier `Invalide` ET `Absent` sur la MÊME réponse
/// 401 neutre (SC-003) : cette distinction sert les tests et les journaux, pas
/// le client — sinon elle devient un oracle (« ce numéro a un défi en cours »).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IssueDefi {
    /// Code correct — le défi est CONSOMMÉ (non rejouable).
    Valide,
    /// Code faux — le défi survit, avec `essais_restants` tentatives.
    Invalide {
        /// Tentatives encore possibles avant destruction du défi.
        essais_restants: u8,
    },
    /// Aucun défi : jamais posé, expiré, déjà consommé, ou essais épuisés.
    Absent,
}

/// Compteur anti-abus. Le domaine nomme l'intention, l'adaptateur choisit la
/// clé Redis (`otp:sms:{e164}` / `otp:ip:{ip}` — data-model §3) : le layout du
/// stockage ne fuit pas dans le domaine.
#[derive(Debug, Clone, Copy)]
pub enum Compteur<'a> {
    /// SMS envoyés à un numéro dans la fenêtre courante (plafond 3/h — FR-003).
    SmsParNumero(&'a str),
    /// Demandes d'OTP émises par une IP (plafond 10/h — research R12).
    DemandesParIp(&'a str),
}

/// Contenu du jeton d'inscription, émis après une vérification OTP réussie sur
/// un numéro INCONNU, à usage unique (research R3).
///
/// Porte l'appareil capté à la vérification : `/auth/inscription` crée la
/// session sans le redemander (`session.appareil_*` est NOT NULL — analyze C1).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct JetonInscription {
    /// Numéro vérifié, normalisé E.164.
    pub telephone_e164: String,
    /// Zone déclarée par l'app (research R13).
    pub zone: Uuid,
    /// Appareil qui a passé la vérification.
    pub appareil: Appareil,
}

/// Stockage éphémère RECONSTRUCTIBLE : sa perte coûte une re-demande de code,
/// rien d'autre (constitution II — Postgres reste la seule vérité durable).
#[async_trait]
pub trait DepotEphemere: Send + Sync {
    /// Pose (ou ÉCRASE) le défi d'un numéro : toute nouvelle demande invalide
    /// le code précédent (FR-002). `empreinte` = HMAC-SHA256 du code — un dump
    /// du dépôt n'expose aucun code en clair (research R3).
    async fn poser_defi(
        &self,
        e164: &str,
        empreinte: &[u8],
        essais: u8,
        ttl: Duration,
    ) -> Result<(), ErreurEphemere>;

    /// Consomme UNE tentative, de façon ATOMIQUE (vérifier-et-décrémenter) :
    /// code correct → défi détruit + [`IssueDefi::Valide`] ; code faux →
    /// décrément, et destruction du défi quand les essais tombent à zéro.
    /// L'atomicité est ce qui rend le plafond de 3 essais infranchissable en
    /// concurrence — c'est la vraie protection d'un code à 10⁶ combinaisons.
    async fn consommer_essai(
        &self,
        e164: &str,
        empreinte: &[u8],
    ) -> Result<IssueDefi, ErreurEphemere>;

    /// Incrémente un compteur à fenêtre FIXE et renvoie sa nouvelle valeur. Le
    /// TTL n'est posé qu'à la création (sinon la fenêtre glisserait sans fin et
    /// le plafond deviendrait inatteignable).
    async fn incrementer(
        &self,
        compteur: Compteur<'_>,
        ttl: Duration,
    ) -> Result<u64, ErreurEphemere>;

    /// Enregistre un jeton d'inscription à durée de vie courte (10 min).
    async fn poser_jeton_inscription(
        &self,
        jeton: &str,
        contenu: &JetonInscription,
        ttl: Duration,
    ) -> Result<(), ErreurEphemere>;

    /// Lit ET détruit le jeton en une opération atomique — usage unique
    /// garanti même sur rejeu concurrent (research R3).
    async fn consommer_jeton_inscription(
        &self,
        jeton: &str,
    ) -> Result<Option<JetonInscription>, ErreurEphemere>;
}

// ── Port 2 : envoi de SMS (research R6) ────────────────────────────────────

/// Envoi d'un SMS. Le fournisseur réel (agrégateur local — annexe B du cadrage,
/// décision NON tranchée) appartient au cycle NTF : CPT ne le préempte pas.
///
/// Le message est une CLÉ i18n fr + ses paramètres, jamais un texte en dur
/// (constitution VII) : le rendu appartient à l'expéditeur.
#[async_trait]
pub trait EnvoiSms: Send + Sync {
    /// Envoie `message_cle` (rendue avec `params`) au numéro E.164.
    async fn envoyer(&self, e164: &str, message_cle: &str, params: &Value)
        -> Result<(), ErreurSms>;
}

// ── Port 3 : stockage objet — REPRIS par socle (cycle 005, research R1) ────

/// Types du port objets, désormais définis par `socle` : le stockage objet est
/// une capacité technique transverse (les prestataires y déposent photos et
/// chartes). Ré-exportés ici — l'API publique du crate n'a pas bougé.
pub use socle::{DepotObjets, MemoireObjets, UrlPresignee};

// ── Horloge injectable (tests d'expiration sans attente) ───────────────────

/// Horloge manipulable : rend testables les TTL (défi 5 min, jeton 10 min,
/// fenêtre d'une heure) sans `sleep`. Consommée par [`MemoireEphemere`].
#[derive(Debug, Clone)]
pub struct HorlogeManuelle {
    maintenant: Arc<Mutex<DateTime<Utc>>>,
}

impl HorlogeManuelle {
    /// Démarre l'horloge à l'instant courant.
    pub fn new() -> Self {
        Self::depuis(Utc::now())
    }

    /// Démarre l'horloge à un instant choisi (tests déterministes).
    pub fn depuis(depart: DateTime<Utc>) -> Self {
        Self {
            maintenant: Arc::new(Mutex::new(depart)),
        }
    }

    /// Instant courant de cette horloge.
    pub fn maintenant(&self) -> DateTime<Utc> {
        *self.maintenant.lock().expect("horloge non empoisonnée")
    }

    /// Avance l'horloge — la seule façon de franchir un TTL dans les tests.
    pub fn avancer(&self, duree: Duration) {
        let delta = chrono::Duration::from_std(duree).expect("durée représentable");
        let mut instant = self.maintenant.lock().expect("horloge non empoisonnée");
        *instant += delta;
    }
}

impl Default for HorlogeManuelle {
    fn default() -> Self {
        Self::new()
    }
}

// ── Impl mémoire du dépôt éphémère ─────────────────────────────────────────

struct DefiStocke {
    empreinte: Vec<u8>,
    essais_restants: u8,
    expire_le: DateTime<Utc>,
}

struct CompteurStocke {
    valeur: u64,
    expire_le: DateTime<Utc>,
}

struct JetonStocke {
    contenu: JetonInscription,
    expire_le: DateTime<Utc>,
}

/// [`DepotEphemere`] en mémoire, à horloge injectable — reproduit la sémantique
/// Redis (écrasement du défi, décrément atomique, fenêtre fixe, GETDEL) pour
/// tester expiration et plafonds sans Redis ni attente réelle (research R3).
pub struct MemoireEphemere {
    horloge: HorlogeManuelle,
    defis: Mutex<HashMap<String, DefiStocke>>,
    compteurs: Mutex<HashMap<String, CompteurStocke>>,
    jetons: Mutex<HashMap<String, JetonStocke>>,
}

impl MemoireEphemere {
    /// Dépôt vide, horloge démarrée maintenant.
    pub fn new() -> Self {
        Self::avec_horloge(HorlogeManuelle::new())
    }

    /// Dépôt vide branché sur une horloge partagée (que le test fait avancer).
    pub fn avec_horloge(horloge: HorlogeManuelle) -> Self {
        Self {
            horloge,
            defis: Mutex::new(HashMap::new()),
            compteurs: Mutex::new(HashMap::new()),
            jetons: Mutex::new(HashMap::new()),
        }
    }

    /// Horloge de ce dépôt — `avancer()` pour franchir un TTL.
    pub fn horloge(&self) -> HorlogeManuelle {
        self.horloge.clone()
    }

    /// Clé du compteur, alignée sur data-model §3.
    fn cle_compteur(compteur: Compteur<'_>) -> String {
        match compteur {
            Compteur::SmsParNumero(e164) => format!("otp:sms:{e164}"),
            Compteur::DemandesParIp(ip) => format!("otp:ip:{ip}"),
        }
    }
}

impl Default for MemoireEphemere {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl DepotEphemere for MemoireEphemere {
    async fn poser_defi(
        &self,
        e164: &str,
        empreinte: &[u8],
        essais: u8,
        ttl: Duration,
    ) -> Result<(), ErreurEphemere> {
        let expire_le = self.horloge.maintenant() + chrono::Duration::from_std(ttl).expect("ttl");
        // Insert ÉCRASANT : la nouvelle demande invalide l'ancien code (FR-002).
        self.defis.lock().expect("défis").insert(
            e164.to_owned(),
            DefiStocke {
                empreinte: empreinte.to_vec(),
                essais_restants: essais,
                expire_le,
            },
        );
        Ok(())
    }

    async fn consommer_essai(
        &self,
        e164: &str,
        empreinte: &[u8],
    ) -> Result<IssueDefi, ErreurEphemere> {
        let maintenant = self.horloge.maintenant();
        let mut defis = self.defis.lock().expect("défis");

        let Some(defi) = defis.get_mut(e164) else {
            return Ok(IssueDefi::Absent);
        };
        if defi.expire_le <= maintenant {
            defis.remove(e164);
            return Ok(IssueDefi::Absent);
        }
        if egalite_temps_constant(&defi.empreinte, empreinte) {
            defis.remove(e164); // consommé — non rejouable
            return Ok(IssueDefi::Valide);
        }
        defi.essais_restants = defi.essais_restants.saturating_sub(1);
        let restants = defi.essais_restants;
        if restants == 0 {
            // Essais épuisés : le défi meurt — même le bon code ne passe plus.
            defis.remove(e164);
            return Ok(IssueDefi::Absent);
        }
        Ok(IssueDefi::Invalide {
            essais_restants: restants,
        })
    }

    async fn incrementer(
        &self,
        compteur: Compteur<'_>,
        ttl: Duration,
    ) -> Result<u64, ErreurEphemere> {
        let cle = Self::cle_compteur(compteur);
        let maintenant = self.horloge.maintenant();
        let mut compteurs = self.compteurs.lock().expect("compteurs");

        let expire = maintenant + chrono::Duration::from_std(ttl).expect("ttl");
        match compteurs.get_mut(&cle) {
            // Fenêtre FIXE : le TTL n'est jamais prolongé par un incrément.
            Some(c) if c.expire_le > maintenant => {
                c.valeur += 1;
                Ok(c.valeur)
            }
            _ => {
                compteurs.insert(
                    cle,
                    CompteurStocke {
                        valeur: 1,
                        expire_le: expire,
                    },
                );
                Ok(1)
            }
        }
    }

    async fn poser_jeton_inscription(
        &self,
        jeton: &str,
        contenu: &JetonInscription,
        ttl: Duration,
    ) -> Result<(), ErreurEphemere> {
        let expire_le = self.horloge.maintenant() + chrono::Duration::from_std(ttl).expect("ttl");
        self.jetons.lock().expect("jetons").insert(
            jeton.to_owned(),
            JetonStocke {
                contenu: contenu.clone(),
                expire_le,
            },
        );
        Ok(())
    }

    async fn consommer_jeton_inscription(
        &self,
        jeton: &str,
    ) -> Result<Option<JetonInscription>, ErreurEphemere> {
        let maintenant = self.horloge.maintenant();
        let mut jetons = self.jetons.lock().expect("jetons");
        // GETDEL : retiré quoi qu'il arrive → usage unique, même expiré.
        match jetons.remove(jeton) {
            Some(j) if j.expire_le > maintenant => Ok(Some(j.contenu)),
            _ => Ok(None),
        }
    }
}

/// Égalité d'octets à temps constant sur des empreintes de longueur fixe
/// (HMAC-SHA256). Une divergence de longueur sort tôt : elle ne révèle rien.
fn egalite_temps_constant(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (x, y) in a.iter().zip(b.iter()) {
        diff |= x ^ y;
    }
    diff == 0
}

// ── Impl « traces » de l'envoi de SMS (dev/staging ET tests — research R6) ──

/// Un SMS tel qu'il aurait été envoyé.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SmsEnvoye {
    /// Destinataire E.164.
    pub e164: String,
    /// Clé i18n fr du message.
    pub message_cle: String,
    /// Paramètres de rendu (dont le code OTP).
    pub params: Value,
}

/// [`EnvoiSms`] qui JOURNALISE au lieu d'envoyer (`SMS_MODE=traces`) et retient
/// les messages pour les tests.
///
/// En dev/staging, le code OTP apparaît dans les logs de l'API — c'est le but
/// (le quickstart le lit là). En production, `SMS_MODE` sélectionnera l'impl du
/// cycle NTF : aucun code ne doit finir dans un journal de production.
#[derive(Debug, Default)]
pub struct SmsTraces {
    envoyes: Mutex<Vec<SmsEnvoye>>,
}

impl SmsTraces {
    /// Nouvel expéditeur, journal vide.
    pub fn new() -> Self {
        Self::default()
    }

    /// Messages envoyés jusqu'ici, dans l'ordre.
    pub fn envoyes(&self) -> Vec<SmsEnvoye> {
        self.envoyes.lock().expect("journal SMS").clone()
    }

    /// Nombre de messages envoyés — assertion la plus courante des tests de
    /// plafond (« le 4ᵉ SMS de l'heure n'est PAS envoyé »).
    pub fn nombre(&self) -> usize {
        self.envoyes.lock().expect("journal SMS").len()
    }
}

#[async_trait]
impl EnvoiSms for SmsTraces {
    async fn envoyer(
        &self,
        e164: &str,
        message_cle: &str,
        params: &Value,
    ) -> Result<(), ErreurSms> {
        tracing::info!(
            destinataire = e164,
            message_cle,
            params = %params,
            "SMS_MODE=traces — SMS journalisé, pas envoyé"
        );
        self.envoyes.lock().expect("journal SMS").push(SmsEnvoye {
            e164: e164.to_owned(),
            message_cle: message_cle.to_owned(),
            params: params.clone(),
        });
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::modele::Plateforme;

    const TTL_DEFI: Duration = Duration::from_secs(300);
    const TTL_FENETRE: Duration = Duration::from_secs(3600);
    const E164: &str = "+2250701020304";

    /// Les doubles mémoire sont la base de TOUS les tests OTP (T006) : si leur
    /// sémantique diverge de Redis, ces tests-là ne prouvent plus rien. On la
    /// vérifie donc ici, directement.

    #[tokio::test]
    async fn defi_valide_est_consomme_une_seule_fois() {
        let depot = MemoireEphemere::new();
        depot
            .poser_defi(E164, b"empreinte", 3, TTL_DEFI)
            .await
            .unwrap();

        assert_eq!(
            depot.consommer_essai(E164, b"empreinte").await.unwrap(),
            IssueDefi::Valide
        );
        assert_eq!(
            depot.consommer_essai(E164, b"empreinte").await.unwrap(),
            IssueDefi::Absent,
            "un code validé n'est pas rejouable"
        );
    }

    /// FR-002 — toute nouvelle demande écrase le défi : l'ancien code ne passe plus.
    #[tokio::test]
    async fn nouvelle_demande_ecrase_le_defi_precedent() {
        let depot = MemoireEphemere::new();
        depot
            .poser_defi(E164, b"ancien", 3, TTL_DEFI)
            .await
            .unwrap();
        depot
            .poser_defi(E164, b"nouveau", 3, TTL_DEFI)
            .await
            .unwrap();

        assert_eq!(
            depot.consommer_essai(E164, b"ancien").await.unwrap(),
            IssueDefi::Invalide { essais_restants: 2 },
            "l'ancien code ne vaut plus rien"
        );
        assert_eq!(
            depot.consommer_essai(E164, b"nouveau").await.unwrap(),
            IssueDefi::Valide
        );
    }

    /// SC-002 — 3 essais, puis le défi meurt : même le BON code est refusé.
    #[tokio::test]
    async fn essais_epuises_detruisent_le_defi() {
        let depot = MemoireEphemere::new();
        depot.poser_defi(E164, b"bon", 3, TTL_DEFI).await.unwrap();

        assert_eq!(
            depot.consommer_essai(E164, b"faux").await.unwrap(),
            IssueDefi::Invalide { essais_restants: 2 }
        );
        assert_eq!(
            depot.consommer_essai(E164, b"faux").await.unwrap(),
            IssueDefi::Invalide { essais_restants: 1 }
        );
        assert_eq!(
            depot.consommer_essai(E164, b"faux").await.unwrap(),
            IssueDefi::Absent,
            "3e essai faux → défi détruit"
        );
        assert_eq!(
            depot.consommer_essai(E164, b"bon").await.unwrap(),
            IssueDefi::Absent,
            "4e saisie : même le bon code ne passe plus"
        );
    }

    /// SC-002 — au-delà de 5 minutes, le défi n'existe plus (horloge avancée,
    /// aucune attente réelle).
    #[tokio::test]
    async fn defi_expire_apres_son_ttl() {
        let horloge = HorlogeManuelle::new();
        let depot = MemoireEphemere::avec_horloge(horloge.clone());
        depot.poser_defi(E164, b"bon", 3, TTL_DEFI).await.unwrap();

        horloge.avancer(Duration::from_secs(299));
        assert_eq!(
            depot.consommer_essai(E164, b"bon").await.unwrap(),
            IssueDefi::Valide,
            "avant 5 min : encore valable"
        );

        depot.poser_defi(E164, b"bon", 3, TTL_DEFI).await.unwrap();
        horloge.avancer(Duration::from_secs(301));
        assert_eq!(
            depot.consommer_essai(E164, b"bon").await.unwrap(),
            IssueDefi::Absent,
            "après 5 min : expiré"
        );
    }

    /// La fenêtre est FIXE : incrémenter ne prolonge pas le TTL, sinon un
    /// numéro sollicité en continu ne verrait jamais sa fenêtre se rouvrir.
    #[tokio::test]
    async fn compteur_a_fenetre_fixe_puis_repart_a_un() {
        let horloge = HorlogeManuelle::new();
        let depot = MemoireEphemere::avec_horloge(horloge.clone());

        for attendu in 1..=3 {
            let n = depot
                .incrementer(Compteur::SmsParNumero(E164), TTL_FENETRE)
                .await
                .unwrap();
            assert_eq!(n, attendu);
            horloge.avancer(Duration::from_secs(600));
        }

        // 30 min écoulées : toujours la même fenêtre.
        assert_eq!(
            depot
                .incrementer(Compteur::SmsParNumero(E164), TTL_FENETRE)
                .await
                .unwrap(),
            4
        );

        // Au-delà de l'heure : nouvelle fenêtre.
        horloge.avancer(Duration::from_secs(3600));
        assert_eq!(
            depot
                .incrementer(Compteur::SmsParNumero(E164), TTL_FENETRE)
                .await
                .unwrap(),
            1,
            "la fenêtre écoulée repart à 1"
        );
    }

    /// Les compteurs SMS et IP ne se mélangent pas (clés distinctes — §3).
    #[tokio::test]
    async fn compteurs_sms_et_ip_sont_independants() {
        let depot = MemoireEphemere::new();
        depot
            .incrementer(Compteur::SmsParNumero(E164), TTL_FENETRE)
            .await
            .unwrap();
        assert_eq!(
            depot
                .incrementer(Compteur::DemandesParIp("1.2.3.4"), TTL_FENETRE)
                .await
                .unwrap(),
            1
        );
    }

    fn jeton_test() -> JetonInscription {
        JetonInscription {
            telephone_e164: E164.to_owned(),
            zone: Uuid::nil(),
            appareil: Appareil {
                nom: "Pixel de test".to_owned(),
                plateforme: Plateforme::Android,
            },
        }
    }

    /// R3 — usage unique (GETDEL) : un jeton d'inscription ne sert qu'une fois.
    #[tokio::test]
    async fn jeton_inscription_est_a_usage_unique() {
        let depot = MemoireEphemere::new();
        let contenu = jeton_test();
        depot
            .poser_jeton_inscription("j1", &contenu, Duration::from_secs(600))
            .await
            .unwrap();

        assert_eq!(
            depot.consommer_jeton_inscription("j1").await.unwrap(),
            Some(contenu),
            "l'appareil capté à la vérification est restitué (analyze C1)"
        );
        assert_eq!(
            depot.consommer_jeton_inscription("j1").await.unwrap(),
            None,
            "second usage refusé"
        );
    }

    #[tokio::test]
    async fn jeton_inscription_expire_apres_dix_minutes() {
        let horloge = HorlogeManuelle::new();
        let depot = MemoireEphemere::avec_horloge(horloge.clone());
        depot
            .poser_jeton_inscription("j1", &jeton_test(), Duration::from_secs(600))
            .await
            .unwrap();

        horloge.avancer(Duration::from_secs(601));
        assert_eq!(depot.consommer_jeton_inscription("j1").await.unwrap(), None);
    }

    /// R6 — SmsTraces retient ce qu'il journalise : c'est ce qui rend testable
    /// « le 4e SMS de l'heure n'est PAS envoyé » (T006).
    #[tokio::test]
    async fn sms_traces_retient_les_messages() {
        let sms = SmsTraces::new();
        sms.envoyer(
            E164,
            "comptes.otp.sms",
            &serde_json::json!({ "code": "123456" }),
        )
        .await
        .unwrap();

        assert_eq!(sms.nombre(), 1);
        let envoye = &sms.envoyes()[0];
        assert_eq!(envoye.e164, E164);
        assert_eq!(envoye.message_cle, "comptes.otp.sms");
        assert_eq!(envoye.params["code"], "123456");
    }
}
