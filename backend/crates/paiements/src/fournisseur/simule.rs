//! Double **pilotable** de fournisseur (FR-044).
//!
//! Il n'imite aucun agrégateur réel : il implémente le contrat, et rien d'autre.
//! C'est ce qui permet d'exercer toute la chaîne d'argent — ouverture,
//! confirmation, refus, rejeu, divergence, expiration, réconciliation — **sans
//! réseau**, donc dans une suite de tests qui tourne en CI.
//!
//! # Ce qu'il prouve, et ce qu'il ne prouve pas
//!
//! Il prouve que le **domaine** est correct : que le rejeu n'a qu'un effet, que
//! `reglee` est terminal, qu'un montant divergent ouvre un dossier.
//!
//! Il **ne prouve rien** sur le contact avec un fournisseur réel : ni le format
//! exact d'une signature, ni l'encodage d'un montant sur le fil, ni ce qu'un
//! agrégateur renvoie quand il est en surcharge. `FournisseurAlternatif` (T078)
//! ajoute une seconde forme pour mesurer la réversibilité, mais deux doubles ne
//! font toujours pas une preuve de contact avec le réel — c'est une réserve
//! explicite du cycle, pas un oubli.
//!
//! # Le signataire de test
//!
//! [`FournisseurSimule::signer`] produit une signature que
//! [`PaymentProvider::verify_webhook`] accepte. C'est **la même fonction** que
//! le bac d'API emploie pour forger ses notifications : un test qui signerait
//! autrement que le vérificateur ne testerait que sa propre arithmétique.

use std::sync::{Arc, Mutex};

use chrono::{DateTime, Utc};
use uuid::Uuid;

use super::signature::SignatureHmac;
use super::{
    Checkout, DemandeCheckout, DemandeRemboursement, ErreurFournisseur, IssuePaiement,
    Notification, NotificationEntrante, PaymentProvider, Remboursement,
};
use crate::modele::MoyenPaiement;

/// Nom du champ d'en-tête où le double attend sa signature.
pub const ENTETE_SIGNATURE: &str = "x-mefali-signature";

pub use super::signature::{empreinte, TOLERANCE_HORODATAGE};

/// Ce que le double doit faire au prochain appel.
///
/// Un scénario par **défaut de la vraie vie** qu'il faut savoir traverser — pas
/// un scénario par branche de code, ce qui reviendrait à tester le double.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub enum ScenarioSimule {
    /// Ouverture normale, puis notification de succès conforme.
    #[default]
    Succes,
    /// Refus d'opérateur (solde insuffisant, code faux).
    Echec,
    /// Le fournisseur n'a pas encore tranché — **n'est pas un échec**.
    EnCours,
    /// Le payeur a renoncé.
    Annule,
    /// La signature produite ne correspond pas au corps : simule une forgerie.
    SignatureInvalide,
    /// La notification annonce un montant différent du figé (FR-024).
    MontantDivergent(i64),
    /// La notification annonce une autre devise (FR-024).
    DeviseDivergente(String),
    /// Le fournisseur est injoignable → `502`, commande **intacte** (FR-018).
    Indisponible,
    /// Le fournisseur répond, mais lentement. Sert à vérifier qu'aucun appel
    /// sortant ne se fait à l'intérieur d'une transaction SQL (R2).
    Latence(std::time::Duration),
}

/// Double de fournisseur, pilotable à chaud.
///
/// `Clone` partage l'état : un test peut garder une poignée et changer le
/// scénario pendant que l'application en tient une autre.
#[derive(Clone)]
pub struct FournisseurSimule {
    /// **La même** primitive que celle du client HTTP de production
    /// (`signature.rs`) : un second vérificateur aurait fait tester la sécurité
    /// du double plutôt que celle du chemin réel.
    signature: SignatureHmac,
    etat: Arc<Mutex<Etat>>,
}

#[derive(Default)]
struct Etat {
    scenario: ScenarioSimule,
    /// Ce que `consulter` répondra — piloté séparément du scénario d'ouverture,
    /// parce que R7 a besoin des deux cas : « le webhook s'est perdu mais le
    /// paiement a réussi » et « rien n'est arrivé ».
    issue_consultee: Option<IssuePaiement>,
    /// Moyen annoncé, quand il l'est.
    moyen: Option<MoyenPaiement>,
    /// Ouvertures effectuées — sert à prouver l'idempotence : rappeler
    /// `POST /commandes/{id}/paiement` ne doit PAS rouvrir chez le fournisseur.
    ouvertures: usize,
    /// Remboursements demandés. Doit rester à **zéro** sur toute la suite :
    /// c'est la mesure de FR-041 (« définie, jamais appelée »).
    remboursements: usize,
}

impl FournisseurSimule {
    /// Double avec un secret de test.
    pub fn nouveau() -> Self {
        Self::avec_secret(b"secret-de-webhook-de-test-32-oct".to_vec())
    }

    /// Double avec un secret choisi — sert à prouver qu'une signature d'un
    /// **autre** secret est refusée.
    pub fn avec_secret(secret: Vec<u8>) -> Self {
        Self {
            signature: SignatureHmac::nouveau(secret, ENTETE_SIGNATURE),
            etat: Arc::new(Mutex::new(Etat::default())),
        }
    }

    /// Pilote le scénario du prochain appel.
    pub fn scenario(&self, scenario: ScenarioSimule) {
        self.etat.lock().unwrap().scenario = scenario;
    }

    /// Pilote la réponse de [`PaymentProvider::consulter`].
    pub fn issue_consultee(&self, issue: Option<IssuePaiement>) {
        self.etat.lock().unwrap().issue_consultee = issue;
    }

    /// Pilote le moyen annoncé.
    pub fn moyen(&self, moyen: Option<MoyenPaiement>) {
        self.etat.lock().unwrap().moyen = moyen;
    }

    /// Nombre d'ouvertures effectuées chez le « fournisseur ».
    pub fn ouvertures(&self) -> usize {
        self.etat.lock().unwrap().ouvertures
    }

    /// Nombre de remboursements demandés. **Doit rester nul** (FR-041).
    pub fn remboursements(&self) -> usize {
        self.etat.lock().unwrap().remboursements
    }

    /// Signe un corps brut comme le ferait le fournisseur.
    ///
    /// Format : `t=<horodatage unix>,v1=<hex(HMAC-SHA256(secret, "t.corps"))>`.
    /// L'horodatage entre dans le message signé — sinon il serait modifiable
    /// sans invalider la signature, et la tolérance ne servirait à rien.
    pub fn signer(&self, corps: &[u8], quand: DateTime<Utc>) -> String {
        self.signature.signer(corps, quand)
    }

    /// Forge le corps d'une notification, tel que le double le comprend.
    ///
    /// Exposé parce que le **bac d'API** en a besoin : un test qui fabriquerait
    /// son corps autrement que le double ne le lit ne prouverait rien sur le
    /// chemin réel.
    pub fn corps_notification(
        reference_marchande: Uuid,
        montant_unites: i64,
        devise: &str,
        issue: IssuePaiement,
    ) -> Vec<u8> {
        serde_json::to_vec(&serde_json::json!({
            "reference_fournisseur": format!("sim-{reference_marchande}"),
            "reference_marchande": reference_marchande,
            "issue": issue.comme_str(),
            "montant_unites": montant_unites,
            "devise": devise,
            "survenu_le": Utc::now().to_rfc3339(),
        }))
        .expect("charge de test sérialisable")
    }

}

impl Default for FournisseurSimule {
    fn default() -> Self {
        Self::nouveau()
    }
}

#[async_trait::async_trait]
impl PaymentProvider for FournisseurSimule {
    fn nom(&self) -> &'static str {
        "simule"
    }

    async fn create_checkout(
        &self,
        demande: DemandeCheckout,
    ) -> Result<Checkout, ErreurFournisseur> {
        let scenario = {
            let mut etat = self.etat.lock().unwrap();
            etat.ouvertures += 1;
            etat.scenario.clone()
        };

        match scenario {
            ScenarioSimule::Indisponible => {
                return Err(ErreurFournisseur::Indisponible(
                    "double piloté en panne".to_owned(),
                ))
            }
            ScenarioSimule::Latence(d) => tokio::time::sleep(d).await,
            _ => {}
        }

        Ok(Checkout {
            reference_fournisseur: format!("sim-{}", demande.reference_marchande),
            acces_paiement: format!(
                "https://paiement.invalid/sim/{}",
                demande.reference_marchande
            ),
            // Le double n'annonce AUCUNE échéance : c'est la nôtre qui fait foi
            // (R7). Un double qui en annoncerait une masquerait le fait que le
            // produit ne doit pas s'y fier.
            expire_le: None,
        })
    }

    fn verify_webhook(
        &self,
        entrante: &NotificationEntrante<'_>,
    ) -> Result<Notification, ErreurFournisseur> {
        self.signature.verifier_entetes(
            entrante.entetes,
            entrante.corps_brut,
            entrante.recue_le,
        )?;

        // ── La signature seulement MAINTENANT vérifiée, on désérialise ────
        let charge: serde_json::Value = serde_json::from_slice(entrante.corps_brut)
            .map_err(|e| ErreurFournisseur::ChargeIllisible(e.to_string()))?;

        let champ = |nom: &str| -> Result<&serde_json::Value, ErreurFournisseur> {
            charge
                .get(nom)
                .ok_or_else(|| ErreurFournisseur::ChargeIllisible(format!("champ absent : {nom}")))
        };

        let issue = match champ("issue")?.as_str() {
            Some("reussi") => IssuePaiement::Reussi,
            Some("echoue") => IssuePaiement::Echoue,
            Some("annule") => IssuePaiement::Annule,
            Some("en_cours") => IssuePaiement::EnCours,
            autre => {
                return Err(ErreurFournisseur::ChargeIllisible(format!(
                    "issue inconnue : {autre:?}"
                )))
            }
        };

        let moyen = charge.get("moyen").and_then(|v| v.as_str()).map(|m| {
            traduire_moyen(m).unwrap_or_else(|| {
                // Le libellé BRUT du fournisseur est journalisé ICI, où le
                // diagnostic d'intégration en a besoin — et il ne franchit pas
                // la frontière (FR-003).
                tracing::debug!(moyen_brut = m, "moyen inconnu du domaine → `autre`");
                MoyenPaiement::Autre
            })
        });

        Ok(Notification {
            reference_fournisseur: champ("reference_fournisseur")?
                .as_str()
                .unwrap_or_default()
                .to_owned(),
            reference_marchande: charge
                .get("reference_marchande")
                .and_then(|v| v.as_str())
                .and_then(|s| Uuid::parse_str(s).ok()),
            issue,
            montant_unites: champ("montant_unites")?.as_i64().ok_or_else(|| {
                ErreurFournisseur::ChargeIllisible("montant non entier".to_owned())
            })?,
            devise: champ("devise")?.as_str().unwrap_or_default().to_owned(),
            moyen,
            survenu_le: charge
                .get("survenu_le")
                .and_then(|v| v.as_str())
                .and_then(|s| DateTime::parse_from_rfc3339(s).ok())
                .map(|d| d.with_timezone(&Utc))
                .unwrap_or(entrante.recue_le),
            empreinte_charge: empreinte(entrante.corps_brut),
        })
    }

    async fn refund(
        &self,
        _demande: DemandeRemboursement,
    ) -> Result<Remboursement, ErreurFournisseur> {
        // Comptabilisé pour que `refund_n_est_jamais_appelee` puisse le
        // constater. La méthode est implémentée — pas laissée en `todo!()` —
        // parce que PAY-05 exige qu'un fournisseur de remplacement l'expose ;
        // ce qui est interdit, c'est de l'APPELER depuis le produit (FR-041).
        self.etat.lock().unwrap().remboursements += 1;
        Err(ErreurFournisseur::NonSupporte)
    }

    async fn consulter(&self, reference: &str) -> Result<Notification, ErreurFournisseur> {
        let (issue, moyen) = {
            let etat = self.etat.lock().unwrap();
            match etat.scenario {
                ScenarioSimule::Indisponible => {
                    return Err(ErreurFournisseur::Indisponible(
                        "double piloté en panne".to_owned(),
                    ))
                }
                _ => (
                    // Par défaut, « rien n'est arrivé » : c'est le cas nominal
                    // d'une session abandonnée, et le plus fréquent.
                    etat.issue_consultee.unwrap_or(IssuePaiement::EnCours),
                    etat.moyen,
                ),
            }
        };

        Ok(Notification {
            reference_fournisseur: reference.to_owned(),
            reference_marchande: reference
                .strip_prefix("sim-")
                .and_then(|s| Uuid::parse_str(s).ok()),
            issue,
            // La réconciliation confirme une issue ; le montant et la devise
            // sont revérifiés par l'appelant contre le figé de la transaction,
            // exactement comme pour une notification entrante.
            montant_unites: 0,
            devise: String::new(),
            moyen,
            survenu_le: Utc::now(),
            empreinte_charge: empreinte(reference.as_bytes()),
        })
    }
}

/// Traduit un libellé de moyen vers le vocabulaire du domaine.
///
/// `None` = inconnu de nous : l'appelant le mappe sur `Autre` **et journalise le
/// libellé brut**, qui reste confiné à ce module.
fn traduire_moyen(brut: &str) -> Option<MoyenPaiement> {
    Some(match brut {
        "wave" => MoyenPaiement::Wave,
        "orange_money" => MoyenPaiement::OrangeMoney,
        "mtn_momo" => MoyenPaiement::MtnMomo,
        "moov_money" => MoyenPaiement::MoovMoney,
        "carte" => MoyenPaiement::Carte,
        _ => return None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Duration;

    fn demande() -> DemandeCheckout {
        DemandeCheckout {
            reference_marchande: Uuid::now_v7(),
            montant_unites: 12_500,
            devise: "XOF".to_owned(),
            description_cle: "paiement.description.commande",
            retour_succes: "mefali://paiement/succes".to_owned(),
            retour_annulation: "mefali://paiement/annulation".to_owned(),
        }
    }

    fn entrantes(signature: &str) -> super::super::EntetesNotification {
        super::super::EntetesNotification::depuis([(ENTETE_SIGNATURE, signature)])
    }

    #[tokio::test]
    async fn ouverture_nominale() {
        let f = FournisseurSimule::nouveau();
        let d = demande();
        let reference = d.reference_marchande;
        let c = f.create_checkout(d).await.unwrap();
        assert_eq!(c.reference_fournisseur, format!("sim-{reference}"));
        assert!(c.acces_paiement.starts_with("https://"));
        assert_eq!(
            c.expire_le, None,
            "le double n'annonce aucune échéance : la nôtre fait foi (R7)",
        );
        assert_eq!(f.ouvertures(), 1);
    }

    #[tokio::test]
    async fn indisponible_ne_laisse_rien_derriere() {
        let f = FournisseurSimule::nouveau();
        f.scenario(ScenarioSimule::Indisponible);
        let e = f.create_checkout(demande()).await.unwrap_err();
        assert!(matches!(e, ErreurFournisseur::Indisponible(_)));
    }

    #[tokio::test]
    async fn la_latence_est_traversee_sans_bloquer() {
        let f = FournisseurSimule::nouveau();
        f.scenario(ScenarioSimule::Latence(std::time::Duration::from_millis(
            20,
        )));
        assert!(f.create_checkout(demande()).await.is_ok());
    }

    /// Le chemin nominal du webhook : signé par le double, accepté par le
    /// double. Le test vaut surtout comme référence des trois suivants.
    #[test]
    fn notification_signee_acceptee() {
        let f = FournisseurSimule::nouveau();
        let reference = Uuid::now_v7();
        let corps =
            FournisseurSimule::corps_notification(reference, 12_500, "XOF", IssuePaiement::Reussi);
        let maintenant = Utc::now();
        let entetes = entrantes(&f.signer(&corps, maintenant));

        let n = f
            .verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: maintenant,
            })
            .unwrap();

        assert_eq!(n.issue, IssuePaiement::Reussi);
        assert_eq!(n.montant_unites, 12_500);
        assert_eq!(n.devise, "XOF");
        assert_eq!(n.reference_marchande, Some(reference));
        assert!(!n.empreinte_charge.is_empty());
    }

    /// Signature ABSENTE : refusée avant toute désérialisation (R6).
    #[test]
    fn signature_absente_refusee() {
        let f = FournisseurSimule::nouveau();
        let corps = FournisseurSimule::corps_notification(
            Uuid::now_v7(),
            12_500,
            "XOF",
            IssuePaiement::Reussi,
        );
        let entetes = super::super::EntetesNotification::default();
        let e = f
            .verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: Utc::now(),
            })
            .unwrap_err();
        assert!(matches!(e, ErreurFournisseur::SignatureInvalide));
    }

    /// Signature TRONQUÉE — le cas d'une troncature en transit.
    #[test]
    fn signature_tronquee_refusee() {
        let f = FournisseurSimule::nouveau();
        let corps = FournisseurSimule::corps_notification(
            Uuid::now_v7(),
            12_500,
            "XOF",
            IssuePaiement::Reussi,
        );
        let maintenant = Utc::now();
        let complete = f.signer(&corps, maintenant);
        let tronquee = &complete[..complete.len() - 8];
        let entetes = entrantes(tronquee);
        assert!(matches!(
            f.verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: maintenant,
            })
            .unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Signature valide, mais d'un AUTRE secret. C'est le cas d'une fuite de
    /// secret chez un tiers, ou d'un environnement mal configuré qui pointe la
    /// production avec un secret de recette.
    #[test]
    fn signature_d_un_autre_secret_refusee() {
        let vrai = FournisseurSimule::avec_secret(b"secret-A-de-32-octets-exactement!".to_vec());
        let faux = FournisseurSimule::avec_secret(b"secret-B-de-32-octets-exactement!".to_vec());
        let corps = FournisseurSimule::corps_notification(
            Uuid::now_v7(),
            12_500,
            "XOF",
            IssuePaiement::Reussi,
        );
        let maintenant = Utc::now();
        let entetes = entrantes(&faux.signer(&corps, maintenant));
        assert!(matches!(
            vrai.verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: maintenant,
            })
            .unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Signature AUTHENTIQUE mais PÉRIMÉE : une capture réseau rejouée trois
    /// heures plus tard. C'est ce que la tolérance d'horodatage existe pour
    /// refuser (R6).
    #[test]
    fn signature_perimee_refusee() {
        let f = FournisseurSimule::nouveau();
        let corps = FournisseurSimule::corps_notification(
            Uuid::now_v7(),
            12_500,
            "XOF",
            IssuePaiement::Reussi,
        );
        let il_y_a_longtemps = Utc::now() - Duration::hours(3);
        let entetes = entrantes(&f.signer(&corps, il_y_a_longtemps));
        assert!(matches!(
            f.verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: Utc::now(),
            })
            .unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Une signature du FUTUR est aussi suspecte qu'une périmée : elle trahit
    /// une horloge faussée, ou une forgerie qui cherche à rester valide.
    #[test]
    fn signature_du_futur_refusee() {
        let f = FournisseurSimule::nouveau();
        let corps = FournisseurSimule::corps_notification(
            Uuid::now_v7(),
            12_500,
            "XOF",
            IssuePaiement::Reussi,
        );
        let dans_longtemps = Utc::now() + Duration::hours(3);
        let entetes = entrantes(&f.signer(&corps, dans_longtemps));
        assert!(matches!(
            f.verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: Utc::now(),
            })
            .unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Le CORPS modifié après signature : c'est l'attaque que la signature sur
    /// le corps BRUT existe pour arrêter — changer 12 500 en 1.
    #[test]
    fn corps_modifie_apres_signature_refuse() {
        let f = FournisseurSimule::nouveau();
        let reference = Uuid::now_v7();
        let corps =
            FournisseurSimule::corps_notification(reference, 12_500, "XOF", IssuePaiement::Reussi);
        let maintenant = Utc::now();
        let signature = f.signer(&corps, maintenant);

        let corps_falsifie =
            FournisseurSimule::corps_notification(reference, 1, "XOF", IssuePaiement::Reussi);
        let entetes = entrantes(&signature);
        assert!(matches!(
            f.verify_webhook(&NotificationEntrante {
                corps_brut: &corps_falsifie,
                entetes: &entetes,
                recue_le: maintenant,
            })
            .unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Les quatre issues traversent la traduction sans se mélanger.
    #[test]
    fn les_quatre_issues_sont_traduites() {
        let f = FournisseurSimule::nouveau();
        for issue in [
            IssuePaiement::Reussi,
            IssuePaiement::Echoue,
            IssuePaiement::Annule,
            IssuePaiement::EnCours,
        ] {
            let corps =
                FournisseurSimule::corps_notification(Uuid::now_v7(), 12_500, "XOF", issue);
            let maintenant = Utc::now();
            let entetes = entrantes(&f.signer(&corps, maintenant));
            let n = f
                .verify_webhook(&NotificationEntrante {
                    corps_brut: &corps,
                    entetes: &entetes,
                    recue_le: maintenant,
                })
                .unwrap();
            assert_eq!(n.issue, issue);
        }
    }

    /// L'empreinte distingue deux charges différentes portant la MÊME
    /// référence : c'est exactement le cas `en_cours` → `reussi` que R5 décrit,
    /// et sans cette distinction la seconde notification — celle qui porte le
    /// succès — serait avalée comme un doublon.
    #[test]
    fn l_empreinte_distingue_en_cours_de_reussi() {
        let reference = Uuid::now_v7();
        let a = FournisseurSimule::corps_notification(
            reference,
            12_500,
            "XOF",
            IssuePaiement::EnCours,
        );
        let b =
            FournisseurSimule::corps_notification(reference, 12_500, "XOF", IssuePaiement::Reussi);
        assert_ne!(empreinte(&a), empreinte(&b));
        assert_eq!(empreinte(&a), empreinte(&a), "l'empreinte est stable");
    }

    /// Un moyen inconnu du domaine tombe sur `Autre` sans faire échouer la
    /// notification : un agrégateur qui ajoute un moyen ne doit pas bloquer des
    /// paiements en attendant une migration d'enum (R3).
    #[test]
    fn un_moyen_inconnu_ne_fait_pas_echouer_la_notification() {
        let f = FournisseurSimule::nouveau();
        let corps = serde_json::to_vec(&serde_json::json!({
            "reference_fournisseur": "sim-x",
            "issue": "reussi",
            "montant_unites": 12_500,
            "devise": "XOF",
            "moyen": "un_moyen_de_2030",
        }))
        .unwrap();
        let maintenant = Utc::now();
        let entetes = entrantes(&f.signer(&corps, maintenant));
        let n = f
            .verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: maintenant,
            })
            .unwrap();
        assert_eq!(n.moyen, Some(MoyenPaiement::Autre));
    }

    /// Les cinq moyens nommés restent typés — sans quoi l'analyse par moyen
    /// (FR-012) verrait « autre » partout.
    #[test]
    fn les_cinq_moyens_nommes_sont_traduits() {
        for (brut, attendu) in [
            ("wave", MoyenPaiement::Wave),
            ("orange_money", MoyenPaiement::OrangeMoney),
            ("mtn_momo", MoyenPaiement::MtnMomo),
            ("moov_money", MoyenPaiement::MoovMoney),
            ("carte", MoyenPaiement::Carte),
        ] {
            assert_eq!(traduire_moyen(brut), Some(attendu));
        }
        assert_eq!(traduire_moyen("inconnu_de_nous"), None);
    }

    /// R7 — la réconciliation sait dire « réussi » quand le webhook s'est
    /// perdu, et « rien encore » par défaut.
    #[tokio::test]
    async fn la_reconciliation_est_pilotable() {
        let f = FournisseurSimule::nouveau();
        assert_eq!(
            f.consulter("sim-x").await.unwrap().issue,
            IssuePaiement::EnCours,
            "par défaut, rien n'est arrivé — le cas d'une session abandonnée",
        );

        f.issue_consultee(Some(IssuePaiement::Reussi));
        assert_eq!(
            f.consulter("sim-x").await.unwrap().issue,
            IssuePaiement::Reussi,
            "le webhook s'est perdu mais le paiement a réussi (FR-027)",
        );
    }

    /// Un corps illisible, APRÈS signature valide, est une erreur de charge —
    /// pas une signature invalide. La distinction compte : la première est un
    /// bug d'intégration, la seconde une tentative d'attaque.
    #[test]
    fn corps_illisible_apres_signature_valide() {
        let f = FournisseurSimule::nouveau();
        let corps = b"ceci n'est pas du json".to_vec();
        let maintenant = Utc::now();
        let entetes = entrantes(&f.signer(&corps, maintenant));
        assert!(matches!(
            f.verify_webhook(&NotificationEntrante {
                corps_brut: &corps,
                entetes: &entetes,
                recue_le: maintenant,
            })
            .unwrap_err(),
            ErreurFournisseur::ChargeIllisible(_),
        ));
    }
}
