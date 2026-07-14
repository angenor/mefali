//! Défi OTP : normalisation E.164, génération du code, garde-fous anti-abus et
//! envoi (CPT-01, FR-001..004 ; research R3, R4, R12).
//!
//! Ce module ne connaît ni Redis ni fournisseur SMS : il orchestre les ports.
//!
//! ## Ce qui protège réellement le code
//!
//! Un code à 6 chiffres n'a que 10⁶ combinaisons — le hachage HMAC ne le protège
//! PAS d'une force brute (il protège un dump du dépôt éphémère). La vraie
//! défense est le trio : TTL de 5 minutes + 3 essais décrémentés ATOMIQUEMENT +
//! plafond d'envois. Chacun est testé ici.

use std::str::FromStr;
use std::time::Duration;

use hmac::{Hmac, KeyInit, Mac};
use serde_json::json;
use sha2::Sha256;
use uuid::Uuid;
use zones::ConfigurationZones;

use crate::modele::ErreurComptes;
use crate::ports::{Compteur, DepotEphemere, EnvoiSms, IssueDefi};

type HmacSha256 = Hmac<Sha256>;

// ── Constantes PRODUIT ─────────────────────────────────────────────────────
//
// Volontairement PAS en configuration de zone (clarification spec, tasks.md
// Notes) : ce ne sont pas des réglages d'exploitation mais des propriétés de
// sécurité du parcours. Elles n'apparaissent pas au « Récapitulatif des
// paramètres de zone » du cadrage. Ce qui EST paramétrable — l'indicatif par
// défaut — est lu ci-dessous via ConfigurationZones (FR-024).

/// Longueur du code envoyé par SMS.
pub const OTP_LONGUEUR: usize = 6;
/// Durée de vie d'un défi (FR-002).
pub const OTP_TTL: Duration = Duration::from_secs(5 * 60);
/// Essais avant destruction du défi (FR-002).
pub const OTP_ESSAIS_MAX: u8 = 3;
/// SMS par heure et par numéro (FR-003).
pub const OTP_SMS_MAX_PAR_HEURE: u64 = 3;
/// Demandes d'OTP par heure et par IP — anti « SMS pumping » (research R12).
pub const OTP_DEMANDES_MAX_PAR_IP: u64 = 10;
/// Fenêtre FIXE commune aux deux plafonds.
pub const FENETRE_ANTI_ABUS: Duration = Duration::from_secs(60 * 60);

/// Clé i18n fr du SMS portant le code (constitution VII — jamais de texte ici).
pub const SMS_CODE_CLE: &str = "comptes.otp.sms_code";
/// Paramètre de zone donnant l'indicatif par défaut (FR-024, seed T009).
pub const CLE_INDICATIF_DEFAUT: &str = "telephone.indicatif_defaut";

/// Séparation de domaine : la clé HMAC des défis est DÉRIVÉE de `JWT_SECRET`,
/// jamais égale à lui. Le secret qui signe les sessions et celui qui empreinte
/// les codes ne doivent pas être le même matériel.
const DOMAINE_OTP: &[u8] = b"mefali:otp:defi:v1";

// ── Normalisation E.164 (research R4) ──────────────────────────────────────

/// Normalise une saisie (locale ou internationale) en E.164, avec l'indicatif
/// par défaut de la ZONE — jamais un `+225` en dur (FR-024).
///
/// La normalisation maison des numéros ivoiriens est un piège connu (la
/// renumérotation de 2021 a fait passer les mobiles à 10 chiffres) :
/// libphonenumber la connaît, nous non.
pub async fn normaliser_e164(
    zones: &dyn ConfigurationZones,
    zone: Uuid,
    saisie: &str,
) -> Result<String, ErreurComptes> {
    let indicatif = zones
        .parametre(zone, CLE_INDICATIF_DEFAUT)
        .await?
        .and_then(|v| v.as_str().map(str::to_owned))
        .ok_or_else(|| ErreurComptes::ConfigurationZoneInvalide {
            cle: CLE_INDICATIF_DEFAUT,
            raison: "absent de la chaîne d'héritage de la zone".to_owned(),
        })?;
    let region = region_par_indicatif(&indicatif)?;

    // Une saisie déjà internationale (`+225…`) est validée telle quelle ;
    // libphonenumber ignore alors la région indicative.
    let numero =
        phonenumber::parse(Some(region), saisie).map_err(|_| ErreurComptes::TelephoneInvalide)?;
    if !phonenumber::is_valid(&numero) {
        return Err(ErreurComptes::TelephoneInvalide);
    }
    Ok(phonenumber::format(&numero)
        .mode(phonenumber::Mode::E164)
        .to_string())
}

/// Traduit un indicatif (`"+225"`) en région libphonenumber (`CI`).
///
/// Un indicatif partagé par plusieurs pays (`+1` → US, CA, …) est REFUSÉ plutôt
/// que résolu au hasard : une saisie locale y serait ambiguë, et deviner
/// rattacherait silencieusement des comptes au mauvais pays. Une telle zone
/// devra porter une région explicite — problème d'un cycle qui aura ce besoin.
fn region_par_indicatif(indicatif: &str) -> Result<phonenumber::country::Id, ErreurComptes> {
    let invalide = |raison: String| ErreurComptes::ConfigurationZoneInvalide {
        cle: CLE_INDICATIF_DEFAUT,
        raison,
    };

    let code: u16 = indicatif
        .trim()
        .trim_start_matches('+')
        .parse()
        .map_err(|_| {
            invalide(format!(
                "« {indicatif} » n'est pas un indicatif (ex. « +225 »)"
            ))
        })?;

    let regions = phonenumber::metadata::DATABASE
        .region(&code)
        .ok_or_else(|| invalide(format!("indicatif +{code} inconnu de libphonenumber")))?;

    match regions.as_slice() {
        [seule] => phonenumber::country::Id::from_str(seule)
            .map_err(|_| invalide(format!("région « {seule} » non reconnue"))),
        [] => Err(invalide(format!("indicatif +{code} sans région"))),
        plusieurs => Err(invalide(format!(
            "indicatif +{code} partagé par {} pays ({}) — une saisie locale y serait ambiguë",
            plusieurs.len(),
            plusieurs.join(", ")
        ))),
    }
}

// ── Service OTP ────────────────────────────────────────────────────────────

/// Orchestration du défi OTP. Emprunte ses ports : `PgComptes` le construit à
/// la demande, sans dupliquer d'état.
pub struct ServiceOtp<'a> {
    ephemere: &'a dyn DepotEphemere,
    sms: &'a dyn EnvoiSms,
    zones: &'a dyn ConfigurationZones,
    secret: &'a [u8],
}

impl<'a> ServiceOtp<'a> {
    /// Construit le service à partir des ports et du secret (`JWT_SECRET`).
    pub fn new(
        ephemere: &'a dyn DepotEphemere,
        sms: &'a dyn EnvoiSms,
        zones: &'a dyn ConfigurationZones,
        secret: &'a [u8],
    ) -> Self {
        Self {
            ephemere,
            sms,
            zones,
            secret,
        }
    }

    /// Demande un code pour un numéro (FR-001..003).
    ///
    /// ⚠ L'appelant HTTP répond 202 NEUTRE aussi bien sur `Ok` que sur
    /// [`ErreurComptes::PlafondAtteint`] : sinon le plafond devient un oracle
    /// (« ce numéro a déjà reçu 3 SMS ») — SC-003, research R12.
    pub async fn demander(&self, zone: Uuid, saisie: &str, ip: &str) -> Result<(), ErreurComptes> {
        let e164 = normaliser_e164(self.zones, zone, saisie).await?;

        // Les plafonds sont évalués AVANT de toucher au défi. Sinon la 4e
        // demande — celle qu'on refuse — écraserait quand même le code
        // légitime en cours : un attaquant empêcherait n'importe qui de se
        // connecter en spammant son numéro.
        if self
            .ephemere
            .incrementer(Compteur::DemandesParIp(ip), FENETRE_ANTI_ABUS)
            .await?
            > OTP_DEMANDES_MAX_PAR_IP
        {
            return Err(ErreurComptes::PlafondAtteint);
        }
        if self
            .ephemere
            .incrementer(Compteur::SmsParNumero(&e164), FENETRE_ANTI_ABUS)
            .await?
            > OTP_SMS_MAX_PAR_HEURE
        {
            return Err(ErreurComptes::PlafondAtteint);
        }

        let code = generer_code();
        // Pose AVANT envoi : un SMS reçu dont le code n'existerait pas encore
        // serait pire qu'un défi posé dont le SMS échoue (l'utilisateur
        // redemande).
        self.ephemere
            .poser_defi(
                &e164,
                &self.empreinte(&e164, &code),
                OTP_ESSAIS_MAX,
                OTP_TTL,
            )
            .await?;
        self.sms
            .envoyer(&e164, SMS_CODE_CLE, &json!({ "code": code }))
            .await?;
        Ok(())
    }

    /// Vérifie un code et renvoie le numéro E.164 vérifié.
    ///
    /// Toutes les issues d'échec (code faux, expiré, essais épuisés, défi
    /// jamais posé) se replient sur [`ErreurComptes::DefiOtpInvalide`] : le
    /// domaine lui-même refuse de véhiculer la distinction (SC-003).
    pub async fn verifier(
        &self,
        zone: Uuid,
        saisie: &str,
        code: &str,
    ) -> Result<String, ErreurComptes> {
        let e164 = normaliser_e164(self.zones, zone, saisie).await?;
        match self
            .ephemere
            .consommer_essai(&e164, &self.empreinte(&e164, code))
            .await?
        {
            IssueDefi::Valide => Ok(e164),
            IssueDefi::Invalide { .. } | IssueDefi::Absent => Err(ErreurComptes::DefiOtpInvalide),
        }
    }

    /// Empreinte HMAC-SHA256 d'un code, LIÉE au numéro : un code capté pour un
    /// numéro ne vaut rien sur un autre.
    fn empreinte(&self, e164: &str, code: &str) -> Vec<u8> {
        let mut mac = <HmacSha256 as KeyInit>::new_from_slice(&cle_otp(self.secret))
            .expect("HMAC accepte une clé de n'importe quelle longueur");
        mac.update(e164.as_bytes());
        mac.update(b":");
        mac.update(code.as_bytes());
        mac.finalize().into_bytes().to_vec()
    }
}

/// Clé HMAC des défis, dérivée du secret de signature (séparation de domaine).
fn cle_otp(secret: &[u8]) -> Vec<u8> {
    let mut mac = <HmacSha256 as KeyInit>::new_from_slice(secret)
        .expect("HMAC accepte une clé de n'importe quelle longueur");
    mac.update(DOMAINE_OTP);
    mac.finalize().into_bytes().to_vec()
}

/// Code à 6 chiffres tiré d'un CSPRNG (`ThreadRng` = ChaCha12 amorcé par l'OS).
///
/// Le tirage porte sur `0..1_000_000` puis est formaté sur 6 chiffres : chaque
/// code, `000000` compris, a exactement la même probabilité. Tirer 6 chiffres
/// un par un donnerait le même résultat en plus fragile.
fn generer_code() -> String {
    let n: u32 = rand::random_range(0..1_000_000);
    format!("{n:0largeur$}", largeur = OTP_LONGUEUR)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ports::{HorlogeManuelle, MemoireEphemere, SmsTraces};
    use crate::test_zones::ZonesFixes;

    const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";
    const SAISIE_LOCALE: &str = "0701020304";
    const E164: &str = "+2250701020304";

    struct Bac {
        ephemere: MemoireEphemere,
        sms: SmsTraces,
        zones: ZonesFixes,
        horloge: HorlogeManuelle,
        zone: Uuid,
    }

    impl Bac {
        fn nouveau() -> Self {
            let horloge = HorlogeManuelle::new();
            Self {
                ephemere: MemoireEphemere::avec_horloge(horloge.clone()),
                sms: SmsTraces::new(),
                zones: ZonesFixes::tiassale(),
                horloge,
                zone: Uuid::now_v7(),
            }
        }

        fn service(&self) -> ServiceOtp<'_> {
            ServiceOtp::new(&self.ephemere, &self.sms, &self.zones, SECRET)
        }

        /// Code du dernier SMS envoyé (SMS_MODE=traces le retient — R6).
        fn dernier_code(&self) -> String {
            self.sms.envoyes().last().unwrap().params["code"]
                .as_str()
                .unwrap()
                .to_owned()
        }
    }

    /// R4 — une saisie LOCALE est normalisée avec l'indicatif de la zone.
    #[tokio::test]
    async fn saisie_locale_normalisee_avec_indicatif_de_zone() {
        let bac = Bac::nouveau();
        let e164 = normaliser_e164(&bac.zones, bac.zone, SAISIE_LOCALE)
            .await
            .unwrap();
        assert_eq!(e164, E164);
    }

    /// Une saisie DÉJÀ internationale passe telle quelle.
    #[tokio::test]
    async fn saisie_internationale_acceptee_telle_quelle() {
        let bac = Bac::nouveau();
        assert_eq!(
            normaliser_e164(&bac.zones, bac.zone, E164).await.unwrap(),
            E164
        );
    }

    /// Numéro non normalisable → refusé (422 neutre côté API).
    #[tokio::test]
    async fn numero_non_normalisable_refuse() {
        let bac = Bac::nouveau();
        for saisie in ["12", "pas-un-numero", "+225070102030405060708", ""] {
            assert!(
                matches!(
                    normaliser_e164(&bac.zones, bac.zone, saisie).await,
                    Err(ErreurComptes::TelephoneInvalide)
                ),
                "« {saisie} » aurait dû être refusé"
            );
        }
    }

    /// Indicatif absent de la zone → erreur de CONFIGURATION (500), surtout pas
    /// « numéro invalide » : le dev doit regarder le seed, pas l'app.
    #[tokio::test]
    async fn indicatif_absent_est_une_erreur_de_configuration() {
        let zones = ZonesFixes::vide();
        let erreur = normaliser_e164(&zones, Uuid::now_v7(), SAISIE_LOCALE)
            .await
            .unwrap_err();
        assert!(matches!(
            erreur,
            ErreurComptes::ConfigurationZoneInvalide { cle, .. } if cle == CLE_INDICATIF_DEFAUT
        ));
    }

    /// Un indicatif partagé (+1) est refusé explicitement, pas deviné.
    #[tokio::test]
    async fn indicatif_partage_refuse_explicitement() {
        let zones = ZonesFixes::avec_indicatif("+1");
        let erreur = normaliser_e164(&zones, Uuid::now_v7(), "5551234567")
            .await
            .unwrap_err();
        match erreur {
            ErreurComptes::ConfigurationZoneInvalide { raison, .. } => {
                assert!(raison.contains("partagé"), "raison inattendue : {raison}");
            }
            autre => panic!("attendu une erreur de configuration, reçu {autre:?}"),
        }
    }

    /// Parcours nominal : le code du SMS ouvre la vérification.
    #[tokio::test]
    async fn code_envoye_verifie_le_numero() {
        let bac = Bac::nouveau();
        bac.service()
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .unwrap();

        assert_eq!(bac.sms.nombre(), 1);
        assert_eq!(bac.sms.envoyes()[0].e164, E164, "SMS au numéro normalisé");
        assert_eq!(bac.sms.envoyes()[0].message_cle, SMS_CODE_CLE);
        let code = bac.dernier_code();
        assert_eq!(code.len(), OTP_LONGUEUR);
        assert!(code.chars().all(|c| c.is_ascii_digit()));

        let e164 = bac
            .service()
            .verifier(bac.zone, SAISIE_LOCALE, &code)
            .await
            .unwrap();
        assert_eq!(e164, E164);
    }

    /// SC-002 — au-delà de 5 minutes, le code ne vaut plus rien.
    #[tokio::test]
    async fn code_expire_apres_cinq_minutes() {
        let bac = Bac::nouveau();
        bac.service()
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .unwrap();
        let code = bac.dernier_code();

        bac.horloge.avancer(Duration::from_secs(301));
        assert!(matches!(
            bac.service().verifier(bac.zone, SAISIE_LOCALE, &code).await,
            Err(ErreurComptes::DefiOtpInvalide)
        ));
    }

    /// SC-002 — 3 essais faux détruisent le défi : la 4e saisie échoue MÊME
    /// avec le bon code.
    #[tokio::test]
    async fn quatrieme_saisie_refusee_apres_trois_essais() {
        let bac = Bac::nouveau();
        bac.service()
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .unwrap();
        let bon_code = bac.dernier_code();
        let faux = if bon_code == "000000" {
            "111111"
        } else {
            "000000"
        };

        for _ in 0..3 {
            assert!(matches!(
                bac.service().verifier(bac.zone, SAISIE_LOCALE, faux).await,
                Err(ErreurComptes::DefiOtpInvalide)
            ));
        }
        assert!(
            matches!(
                bac.service()
                    .verifier(bac.zone, SAISIE_LOCALE, &bon_code)
                    .await,
                Err(ErreurComptes::DefiOtpInvalide)
            ),
            "le bon code ne doit plus passer après 3 essais"
        );
    }

    /// FR-002 — une nouvelle demande invalide le code précédent.
    #[tokio::test]
    async fn nouvelle_demande_invalide_l_ancien_code() {
        let bac = Bac::nouveau();
        let service = bac.service();
        service
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .unwrap();
        let ancien = bac.dernier_code();
        service
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .unwrap();
        let nouveau = bac.dernier_code();

        assert!(matches!(
            service.verifier(bac.zone, SAISIE_LOCALE, &ancien).await,
            Err(ErreurComptes::DefiOtpInvalide)
        ));
        assert!(service
            .verifier(bac.zone, SAISIE_LOCALE, &nouveau)
            .await
            .is_ok());
    }

    /// FR-003 — le 4e SMS de l'heure n'est PAS envoyé (et le défi en cours
    /// survit : le refus ne doit pas devenir une arme contre le légitime).
    #[tokio::test]
    async fn quatrieme_sms_de_l_heure_non_envoye() {
        let bac = Bac::nouveau();
        let service = bac.service();
        for _ in 0..3 {
            service
                .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
                .await
                .unwrap();
        }
        let code_valide = bac.dernier_code();

        assert!(matches!(
            service.demander(bac.zone, SAISIE_LOCALE, "1.2.3.4").await,
            Err(ErreurComptes::PlafondAtteint)
        ));
        assert_eq!(bac.sms.nombre(), 3, "aucun 4e SMS");
        assert!(
            service
                .verifier(bac.zone, SAISIE_LOCALE, &code_valide)
                .await
                .is_ok(),
            "le code légitime en cours survit à la demande refusée"
        );
    }

    /// La fenêtre écoulée rouvre le quota.
    #[tokio::test]
    async fn plafond_sms_rouvre_apres_une_heure() {
        let bac = Bac::nouveau();
        for _ in 0..3 {
            bac.service()
                .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
                .await
                .unwrap();
        }
        bac.horloge.avancer(Duration::from_secs(3601));
        assert!(bac
            .service()
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .is_ok());
        assert_eq!(bac.sms.nombre(), 4);
    }

    /// R12 — anti « SMS pumping » : beaucoup de numéros, une seule IP.
    #[tokio::test]
    async fn plafond_par_ip_borne_le_pumping() {
        let bac = Bac::nouveau();
        let service = bac.service();
        // 10 numéros DIFFÉRENTS : le plafond par numéro ne joue jamais.
        for i in 0..10 {
            let numero = format!("070102{i:04}");
            service
                .demander(bac.zone, &numero, "9.9.9.9")
                .await
                .unwrap();
        }
        assert_eq!(bac.sms.nombre(), 10);

        assert!(
            matches!(
                service.demander(bac.zone, "0701029999", "9.9.9.9").await,
                Err(ErreurComptes::PlafondAtteint)
            ),
            "11e demande de la même IP refusée"
        );
        assert_eq!(bac.sms.nombre(), 10, "aucun SMS de plus");

        // Une AUTRE IP n'est pas punie pour autant.
        assert!(service
            .demander(bac.zone, "0701029999", "8.8.8.8")
            .await
            .is_ok());
    }

    /// Un code valide pour un numéro ne vaut rien sur un autre (empreinte liée
    /// au numéro).
    #[tokio::test]
    async fn code_lie_au_numero() {
        let bac = Bac::nouveau();
        let service = bac.service();
        service
            .demander(bac.zone, SAISIE_LOCALE, "1.2.3.4")
            .await
            .unwrap();
        let code = bac.dernier_code();
        service
            .demander(bac.zone, "0705060708", "1.2.3.4")
            .await
            .unwrap();

        assert!(matches!(
            service.verifier(bac.zone, "0705060708", &code).await,
            Err(ErreurComptes::DefiOtpInvalide)
        ));
    }

    /// Le code n'est jamais stocké en clair : l'empreinte dépend du secret.
    #[tokio::test]
    async fn empreinte_depend_du_secret() {
        let bac = Bac::nouveau();
        let a = ServiceOtp::new(&bac.ephemere, &bac.sms, &bac.zones, b"secret-a");
        let b = ServiceOtp::new(&bac.ephemere, &bac.sms, &bac.zones, b"secret-b");
        assert_ne!(a.empreinte(E164, "123456"), b.empreinte(E164, "123456"));
        assert_ne!(cle_otp(SECRET), SECRET.to_vec(), "clé DÉRIVÉE, pas copiée");
    }

    /// Le tirage couvre bien tout l'espace, zéros de tête compris.
    #[test]
    fn codes_generes_sur_six_chiffres() {
        for _ in 0..500 {
            let code = generer_code();
            assert_eq!(code.len(), OTP_LONGUEUR);
            assert!(code.chars().all(|c| c.is_ascii_digit()), "code = {code}");
        }
    }
}
