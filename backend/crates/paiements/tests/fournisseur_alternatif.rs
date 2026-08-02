//! US7 (cycle PAY 011, T078) — **l'instrument de mesure de SC-010**.
//!
//! « Le fournisseur est interchangeable » est une affirmation tant qu'un seul
//! fournisseur existe. Ce fichier en fait une **mesure** : un second double,
//! qui ne partage avec le premier ni son vocabulaire, ni son en-tête de
//! signature, ni sa forme de charge utile, ni ses codes d'état — et à travers
//! lequel le domaine se comporte exactement pareil.
//!
//! # Ce qui diffère, délibérément
//!
//! | | `FournisseurSimule` | `FournisseurAlternatif` |
//! |---|---|---|
//! | en-tête de signature | `x-mefali-signature` | `Alt-Auth-Digest` |
//! | statut « réussi » | `reussi` | `TXN_OK` |
//! | nom du champ de montant | `montant_unites` | `amt` (en **centimes**) |
//! | référence marchande | `reference_marchande` | `merchant_ref` |
//! | échéance annoncée | aucune | +30 min |
//! | codes d'erreur | variantes du domaine | `E_4021`, `E_5003` |
//!
//! Un seul de ces écarts suffirait à casser un domaine qui aurait laissé fuir
//! le vocabulaire d'un fournisseur. Ils sont ici tous ensemble.
//!
//! # Ce que ce test NE prouve pas
//!
//! Il prouve que la **forme** de l'abstraction tient. Il ne prouve rien du
//! contact avec un agrégateur réel — aucun sandbox n'est disponible, le choix
//! n'étant pas fait (cadrage §10.7). Réserve consignée en T086.

use std::sync::{Arc, Mutex};

use chrono::{DateTime, Duration, Utc};
use paiements::fournisseur::signature::{empreinte, SignatureHmac};
use paiements::{
    Checkout, DemandeCheckout, DemandeRemboursement, EntetesNotification, ErreurFournisseur,
    IssuePaiement, MoyenPaiement, Notification, NotificationEntrante, PaymentProvider,
    Remboursement,
};
use uuid::Uuid;

/// En-tête de signature de l'alternatif — **différent** de celui du premier
/// double, et en casse mixte pour vérifier au passage que la recherche
/// d'en-tête reste insensible à la casse.
const ENTETE_ALT: &str = "Alt-Auth-Digest";

/// Le secret de l'alternatif — différent lui aussi. Un domaine qui aurait
/// figé le secret du premier double échouerait ici.
const SECRET_ALT: &[u8] = b"un-tout-autre-secret-de-32-octets";

/// Un **second** fournisseur, incompatible avec le premier en tout point.
#[derive(Clone)]
pub struct FournisseurAlternatif {
    signature: SignatureHmac,
    remboursements: Arc<Mutex<usize>>,
}

impl Default for FournisseurAlternatif {
    fn default() -> Self {
        Self::nouveau()
    }
}

impl FournisseurAlternatif {
    pub fn nouveau() -> Self {
        Self {
            signature: SignatureHmac::nouveau(SECRET_ALT.to_vec(), ENTETE_ALT),
            remboursements: Arc::new(Mutex::new(0)),
        }
    }

    /// Forge une notification **dans SON vocabulaire** : `TXN_OK`, `amt`,
    /// `merchant_ref`. Rien de commun avec le premier double.
    pub fn corps(reference_marchande: Uuid, montant: i64, devise: &str, statut: &str) -> Vec<u8> {
        serde_json::to_vec(&serde_json::json!({
            "txn_id": format!("ALT-{reference_marchande}"),
            "merchant_ref": reference_marchande.to_string(),
            "state": statut,
            "amt": montant,
            "ccy": devise,
            "channel": "WAVE_CI",
            "ts": Utc::now().to_rfc3339(),
        }))
        .unwrap()
    }

    /// En-tête de signature prêt à poser sur une requête.
    pub fn entete(&self, corps: &[u8], quand: DateTime<Utc>) -> (String, String) {
        (ENTETE_ALT.to_owned(), self.signature.signer(corps, quand))
    }

    /// Remboursements demandés — **doit rester nul** (FR-041).
    pub fn remboursements(&self) -> usize {
        *self.remboursements.lock().unwrap()
    }
}

#[async_trait::async_trait]
impl PaymentProvider for FournisseurAlternatif {
    fn nom(&self) -> &'static str {
        "alternatif"
    }

    async fn create_checkout(
        &self,
        demande: DemandeCheckout,
    ) -> Result<Checkout, ErreurFournisseur> {
        Ok(Checkout {
            // Forme de référence différente, préfixe différent.
            reference_fournisseur: format!("ALT-{}", demande.reference_marchande),
            acces_paiement: format!("https://alt.invalid/pay?r={}", demande.reference_marchande),
            // Ce fournisseur-ci ANNONCE une échéance — et c'est le point :
            // la nôtre doit primer (R7). Un domaine qui adopterait celle du
            // tiers changerait de comportement entre les deux doubles.
            expire_le: Some(Utc::now() + Duration::minutes(30)),
        })
    }

    fn verify_webhook(
        &self,
        entrante: &NotificationEntrante<'_>,
    ) -> Result<Notification, ErreurFournisseur> {
        let brute = entrante
            .entetes
            .get(ENTETE_ALT)
            .ok_or(ErreurFournisseur::SignatureInvalide)?;
        self.signature
            .verifier(entrante.corps_brut, brute, entrante.recue_le)?;

        let charge: serde_json::Value = serde_json::from_slice(entrante.corps_brut)
            .map_err(|e| ErreurFournisseur::ChargeIllisible(e.to_string()))?;

        // Vocabulaire propre — et un statut inconnu échoue plutôt que d'être
        // deviné, exactement comme dans le client de production.
        let issue = match charge["state"].as_str().unwrap_or_default() {
            "TXN_OK" => IssuePaiement::Reussi,
            "TXN_KO" | "E_4021" => IssuePaiement::Echoue,
            "TXN_ABORT" => IssuePaiement::Annule,
            "TXN_WAIT" => IssuePaiement::EnCours,
            autre => {
                return Err(ErreurFournisseur::ChargeIllisible(format!(
                    "state inconnu : {autre}"
                )))
            }
        };

        Ok(Notification {
            reference_fournisseur: charge["txn_id"].as_str().unwrap_or_default().to_owned(),
            reference_marchande: charge["merchant_ref"].as_str().and_then(|s| s.parse().ok()),
            issue,
            montant_unites: charge["amt"]
                .as_i64()
                .ok_or_else(|| ErreurFournisseur::ChargeIllisible("amt absent".to_owned()))?,
            devise: charge["ccy"].as_str().unwrap_or_default().to_owned(),
            // Libellé de canal propre à ce fournisseur : `WAVE_CI` et non
            // `wave`. La traduction vit ICI, pas dans le domaine.
            moyen: match charge["channel"].as_str().unwrap_or_default() {
                "WAVE_CI" => Some(MoyenPaiement::Wave),
                "OM_CI" => Some(MoyenPaiement::OrangeMoney),
                "" => None,
                _ => Some(MoyenPaiement::Autre),
            },
            survenu_le: charge["ts"]
                .as_str()
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
        *self.remboursements.lock().unwrap() += 1;
        // Ce fournisseur-ci ne rembourse pas par API : la variante existe pour
        // ça, et le domaine doit la traverser sans broncher (FR-041).
        Err(ErreurFournisseur::NonSupporte)
    }

    async fn consulter(&self, reference: &str) -> Result<Notification, ErreurFournisseur> {
        Ok(Notification {
            reference_fournisseur: reference.to_owned(),
            reference_marchande: None,
            issue: IssuePaiement::EnCours,
            montant_unites: 0,
            devise: "XOF".to_owned(),
            moyen: None,
            survenu_le: Utc::now(),
            empreinte_charge: empreinte(reference.as_bytes()),
        })
    }
}

// ── Les mesures ───────────────────────────────────────────────────────────

/// SC-010 — le domaine lit une notification du **second** fournisseur sans
/// qu'une seule ligne de règle métier ne change.
#[tokio::test]
async fn le_domaine_traverse_un_second_vocabulaire() {
    let alt = FournisseurAlternatif::nouveau();
    let reference = Uuid::now_v7();
    let corps = FournisseurAlternatif::corps(reference, 12_500, "XOF", "TXN_OK");
    let maintenant = Utc::now();
    let (nom, valeur) = alt.entete(&corps, maintenant);
    let entetes = EntetesNotification::depuis([(nom.as_str(), valeur.as_str())]);

    let notification = alt
        .verify_webhook(&NotificationEntrante {
            corps_brut: &corps,
            entetes: &entetes,
            recue_le: maintenant,
        })
        .expect("le second vocabulaire se traduit");

    // Ce que le DOMAINE voit est identique à ce qu'il verrait du premier
    // double : les mêmes types, les mêmes valeurs.
    assert_eq!(notification.issue, IssuePaiement::Reussi);
    assert_eq!(notification.reference_marchande, Some(reference));
    assert_eq!(notification.montant_unites, 12_500);
    assert_eq!(notification.devise, "XOF");
    assert_eq!(notification.moyen, Some(MoyenPaiement::Wave));
    assert!(notification.reference_fournisseur.starts_with("ALT-"));
}

/// Les deux fournisseurs produisent des `Notification` **structurellement
/// identiques** sur le même fait métier. C'est la définition opérationnelle de
/// « interchangeable ».
#[tokio::test]
async fn les_deux_fournisseurs_rendent_la_meme_forme() {
    let reference = Uuid::now_v7();
    let maintenant = Utc::now();

    // Premier double.
    let simule = paiements::FournisseurSimule::nouveau();
    let corps_simule = paiements::FournisseurSimule::corps_notification_moyen(
        reference,
        12_500,
        "XOF",
        IssuePaiement::Reussi,
        Some("wave"),
    );
    let signature = simule.signer(&corps_simule, maintenant);
    let entetes_simule = EntetesNotification::depuis([(
        paiements::fournisseur::simule::ENTETE_SIGNATURE,
        signature.as_str(),
    )]);
    let n1 = simule
        .verify_webhook(&NotificationEntrante {
            corps_brut: &corps_simule,
            entetes: &entetes_simule,
            recue_le: maintenant,
        })
        .unwrap();

    // Second double, tout autre.
    let alt = FournisseurAlternatif::nouveau();
    let corps_alt = FournisseurAlternatif::corps(reference, 12_500, "XOF", "TXN_OK");
    let (nom, valeur) = alt.entete(&corps_alt, maintenant);
    let entetes_alt = EntetesNotification::depuis([(nom.as_str(), valeur.as_str())]);
    let n2 = alt
        .verify_webhook(&NotificationEntrante {
            corps_brut: &corps_alt,
            entetes: &entetes_alt,
            recue_le: maintenant,
        })
        .unwrap();

    // Tout ce dont le domaine décide est identique.
    assert_eq!(n1.issue, n2.issue);
    assert_eq!(n1.reference_marchande, n2.reference_marchande);
    assert_eq!(n1.montant_unites, n2.montant_unites);
    assert_eq!(n1.devise, n2.devise);
    assert_eq!(n1.moyen, n2.moyen);

    // Ce qui diffère est EXACTEMENT ce qui doit différer : la référence du
    // fournisseur, et l'empreinte du corps (deux corps différents).
    assert_ne!(n1.reference_fournisseur, n2.reference_fournisseur);
    assert_ne!(n1.empreinte_charge, n2.empreinte_charge);
}

/// La signature de l'un ne vaut **rien** chez l'autre : chacun a son secret et
/// son en-tête. Un domaine qui aurait figé l'un des deux le montrerait ici.
#[tokio::test]
async fn une_signature_de_l_autre_fournisseur_est_refusee() {
    let simule = paiements::FournisseurSimule::nouveau();
    let alt = FournisseurAlternatif::nouveau();
    let maintenant = Utc::now();
    let corps = FournisseurAlternatif::corps(Uuid::now_v7(), 1_000, "XOF", "TXN_OK");

    // Signature du PREMIER, posée sous l'en-tête du SECOND.
    let signature_simule = simule.signer(&corps, maintenant);
    let entetes = EntetesNotification::depuis([(ENTETE_ALT, signature_simule.as_str())]);
    let erreur = alt
        .verify_webhook(&NotificationEntrante {
            corps_brut: &corps,
            entetes: &entetes,
            recue_le: maintenant,
        })
        .unwrap_err();
    assert!(matches!(erreur, ErreurFournisseur::SignatureInvalide));

    // Et l'en-tête du premier ne dit rien au second, même signé par lui : le
    // second ne le lit pas.
    let (_, valeur_alt) = alt.entete(&corps, maintenant);
    let entetes = EntetesNotification::depuis([(
        paiements::fournisseur::simule::ENTETE_SIGNATURE,
        valeur_alt.as_str(),
    )]);
    let erreur = alt
        .verify_webhook(&NotificationEntrante {
            corps_brut: &corps,
            entetes: &entetes,
            recue_le: maintenant,
        })
        .unwrap_err();
    assert!(matches!(erreur, ErreurFournisseur::SignatureInvalide));
}

/// R7 — **notre** échéance prime, même quand le fournisseur en annonce une.
///
/// L'alternatif annonce 30 minutes ; c'est précisément ce que le premier double
/// n'annonce pas. Un domaine qui adopterait celle du tiers changerait de
/// comportement entre les deux — et laisserait un agrégateur décider quand une
/// commande d'Awa meurt.
#[tokio::test]
async fn l_echeance_annoncee_par_le_fournisseur_reste_informative() {
    let alt = FournisseurAlternatif::nouveau();
    let checkout = alt
        .create_checkout(DemandeCheckout {
            reference_marchande: Uuid::now_v7(),
            montant_unites: 12_500,
            devise: "XOF".to_owned(),
            description_cle: "paiement.description.commande",
            retour_succes: "mefali://x".to_owned(),
            retour_annulation: "mefali://x?a".to_owned(),
        })
        .await
        .unwrap();

    assert!(
        checkout.expire_le.is_some(),
        "ce fournisseur-ci ANNONCE une échéance — c'est le point du test",
    );
    // Rien dans le type ne l'impose au domaine : `session.rs` calcule la
    // sienne depuis `paiement.session_duree_s` et la persiste (R7). Le champ
    // reste une information, et le test suivant du cycle
    // (`paiements_session.rs`) mesure que l'échéance persistée vient bien du
    // paramètre de zone.
}

/// FR-041 — `refund` reste **non appelée**, y compris chez un fournisseur qui
/// ne la supporte pas. Un domaine qui l'invoquerait dans un chemin d'erreur se
/// verrait ici.
#[tokio::test]
async fn refund_reste_non_appelee_chez_l_alternatif() {
    let alt = FournisseurAlternatif::nouveau();
    assert_eq!(alt.remboursements(), 0);

    // L'appel direct existe, et rend `NonSupporte` — le domaine doit pouvoir
    // le traverser le jour où PAY-04 arrive.
    let erreur = alt
        .refund(DemandeRemboursement {
            reference_fournisseur: "ALT-1".to_owned(),
            montant_unites: 1_000,
            devise: "XOF".to_owned(),
            motif_cle: "paiement.remboursement.hors_delai",
        })
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurFournisseur::NonSupporte));
    assert_eq!(
        alt.remboursements(),
        1,
        "l'appel DIRECT du test compte — c'est le seul du dépôt, et \
         `refund_jamais_appelee.rs` le vérifie mécaniquement sur les sources",
    );
}

/// Un statut inconnu du second fournisseur échoue aussi — la règle « ne jamais
/// deviner » n'est pas propre à une implémentation.
#[tokio::test]
async fn un_statut_inconnu_echoue_chez_les_deux() {
    let alt = FournisseurAlternatif::nouveau();
    let maintenant = Utc::now();
    let corps = FournisseurAlternatif::corps(Uuid::now_v7(), 1_000, "XOF", "TXN_QUELQUE_CHOSE");
    let (nom, valeur) = alt.entete(&corps, maintenant);
    let entetes = EntetesNotification::depuis([(nom.as_str(), valeur.as_str())]);

    let erreur = alt
        .verify_webhook(&NotificationEntrante {
            corps_brut: &corps,
            entetes: &entetes,
            recue_le: maintenant,
        })
        .unwrap_err();
    assert!(
        matches!(erreur, ErreurFournisseur::ChargeIllisible(_)),
        "deviner un statut ferait traiter un succès comme une attente, et la \
         session expirerait sur une commande payée",
    );
}
