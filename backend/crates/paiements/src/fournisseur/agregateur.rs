//! Client HTTP **paramétré** vers l'agrégateur de paiement (T076, FR-042).
//!
//! # Ce que ce module est, et ce qu'il n'est pas
//!
//! Il n'implémente **aucun** agrégateur nommé : le cadrage §10.7 dit le choix
//! non fait. Il implémente le contrat HTTP le plus courant chez les agrégateurs
//! mobile money d'Afrique de l'Ouest — `POST` JSON d'ouverture, `GET` JSON de
//! consultation, notification signée en HMAC — avec ce qui varie entre eux
//! **en configuration** : URL de base, clé d'API, secret de signature, nom de
//! l'en-tête.
//!
//! Brancher l'agrégateur retenu, c'est donc : ajuster les trois variables
//! d'environnement, et — si son vocabulaire diffère — les traductions de
//! [`traduire_issue`] et [`traduire_moyen`]. **Rien d'autre.** Aucune règle
//! métier ne bouge : `verifier-frontiere-paiement.sh` le vérifie en CI.
//!
//! # Pourquoi le poser avant de connaître l'agrégateur
//!
//! Parce que c'est ici que les surprises d'intégration apparaissent — format de
//! signature, encodage du montant, forme des codes d'erreur. Les faire
//! apparaître maintenant, sur un contrat qu'on maîtrise, coûte moins cher que
//! de les découvrir en production avec un fournisseur qu'on découvre en même
//! temps (research R4).
//!
//! ⚠ **Réserve honnête** : ce client n'a jamais parlé à un vrai agrégateur.
//! Ses tests l'exercent contre un serveur bouchon. La leçon du cycle 010 vaut
//! ici mot pour mot — 9 défauts invisibles de 758 tests attendaient la première
//! exécution réelle.
//!
//! # Les montants restent des ENTIERS sur le fil
//!
//! `montant_unites` part tel quel, en unités mineures (constitution III).
//! Aucun flottant n'entre ni ne sort de cette frontière : un agrégateur qui
//! exigerait des décimales imposerait une conversion, et c'est exactement le
//! genre de conversion qui perd un franc par-ci par-là jusqu'à ce que le
//! rapprochement de fin de mois ne tombe plus juste.

use std::time::Duration as DureeStd;

use chrono::{DateTime, Utc};
use serde_json::Value;

use super::signature::{empreinte, SignatureHmac};
use super::{
    Checkout, DemandeCheckout, DemandeRemboursement, ErreurFournisseur, IssuePaiement,
    Notification, NotificationEntrante, PaymentProvider, Remboursement,
};
use crate::modele::MoyenPaiement;

/// Délai d'attente d'un appel sortant.
///
/// **10 s** : au-delà, la cliente a déjà quitté l'écran. Mieux vaut un `502`
/// franc — sa commande reste intacte et elle peut réessayer (FR-018) — qu'une
/// requête qui traîne et un utilisateur qui recharge trois fois.
const DELAI_APPEL: DureeStd = DureeStd::from_secs(10);

/// Délai d'établissement de connexion, plus court que le délai total : un hôte
/// injoignable se constate vite, et insister ne le rend pas joignable.
const DELAI_CONNEXION: DureeStd = DureeStd::from_secs(3);

/// Nombre de reprises sur une panne **transitoire**.
///
/// Volontairement bas, et volontairement limité aux erreurs `5xx` et aux
/// délais dépassés : réessayer une ouverture d'encaissement que le fournisseur
/// a peut-être déjà acceptée créerait deux sessions pour une commande. La
/// référence marchande (= notre identifiant de transaction) protège du
/// doublon **côté fournisseur** chez la plupart, mais on ne peut pas en
/// dépendre avant de savoir lequel.
const REPRISES_MAX: u32 = 1;

/// Client HTTP paramétré vers un agrégateur.
pub struct AgregateurHttp {
    http: reqwest::Client,
    base_url: String,
    cle_api: String,
    signature: SignatureHmac,
}

impl AgregateurHttp {
    /// Construit le client.
    ///
    /// `entete_signature` est le nom de l'en-tête où l'agrégateur place sa
    /// signature — il varie d'un fournisseur à l'autre, et c'est précisément le
    /// genre de détail qui ne doit jamais entrer en dur dans le code.
    pub fn nouveau(
        base_url: impl Into<String>,
        cle_api: impl Into<String>,
        secret_webhook: Vec<u8>,
        entete_signature: impl Into<String>,
    ) -> Result<Self, ErreurFournisseur> {
        let http = reqwest::Client::builder()
            .timeout(DELAI_APPEL)
            .connect_timeout(DELAI_CONNEXION)
            .build()
            .map_err(|e| ErreurFournisseur::Indisponible(format!("client HTTP : {e}")))?;

        Ok(Self {
            http,
            base_url: base_url.into().trim_end_matches('/').to_owned(),
            cle_api: cle_api.into(),
            signature: SignatureHmac::nouveau(secret_webhook, entete_signature),
        })
    }

    /// Le signataire — exposé pour que les tests puissent forger une
    /// notification valide sans réimplémenter l'algorithme. Deux
    /// implémentations auraient divergé, et la suite aurait validé la sécurité
    /// du test plutôt que celle du produit.
    pub fn signature(&self) -> &SignatureHmac {
        &self.signature
    }

    /// Envoie une requête et rend son corps JSON, avec reprise sur panne
    /// transitoire.
    async fn appeler(
        &self,
        methode: reqwest::Method,
        chemin: &str,
        corps: Option<Value>,
    ) -> Result<Value, ErreurFournisseur> {
        let url = format!("{}{chemin}", self.base_url);
        let mut derniere = None;

        for essai in 0..=REPRISES_MAX {
            let mut requete = self
                .http
                .request(methode.clone(), &url)
                .bearer_auth(&self.cle_api);
            if let Some(corps) = &corps {
                requete = requete.json(corps);
            }

            match requete.send().await {
                Ok(reponse) => {
                    let statut = reponse.status();
                    // Le corps est lu même en erreur : c'est là que vit le
                    // message du fournisseur, et un diagnostic sans message ne
                    // sert à personne à 3 h du matin.
                    let texte = reponse.text().await.unwrap_or_default();

                    if statut.is_success() {
                        return serde_json::from_str(&texte).map_err(|e| {
                            ErreurFournisseur::ChargeIllisible(format!(
                                "réponse non JSON ({statut}) : {e}"
                            ))
                        });
                    }
                    // ── Traduction des codes d'état, la SEULE de tout le
                    //    produit (FR-003). Aucun code propriétaire ne franchit
                    //    cette ligne : le domaine ne voit que les cinq
                    //    variantes d'`ErreurFournisseur`.
                    if statut.is_server_error() && essai < REPRISES_MAX {
                        derniere = Some(ErreurFournisseur::Indisponible(format!(
                            "{statut} : {texte}"
                        )));
                        continue;
                    }
                    return Err(if statut.is_server_error() {
                        ErreurFournisseur::Indisponible(format!("{statut} : {texte}"))
                    } else {
                        // 4xx : le fournisseur a COMPRIS et a dit non. Le
                        // distinguer d'une panne compte — l'un se réessaie,
                        // l'autre jamais.
                        ErreurFournisseur::RefuseParFournisseur(format!("{statut} : {texte}"))
                    });
                }
                Err(e) if (e.is_timeout() || e.is_connect()) && essai < REPRISES_MAX => {
                    derniere = Some(ErreurFournisseur::Indisponible(e.to_string()));
                    continue;
                }
                Err(e) => return Err(ErreurFournisseur::Indisponible(e.to_string())),
            }
        }

        Err(derniere.unwrap_or_else(|| {
            ErreurFournisseur::Indisponible("aucune réponse après reprise".to_owned())
        }))
    }
}

#[async_trait::async_trait]
impl PaymentProvider for AgregateurHttp {
    fn nom(&self) -> &'static str {
        // Volontairement générique : c'est un segment d'URL de webhook et une
        // colonne de rapprochement, jamais une branche de règle métier
        // (FR-003). Le nommer d'après l'agrégateur retenu ferait entrer son
        // nom dans la base et dans les URL publiques.
        "agregateur"
    }

    async fn create_checkout(
        &self,
        demande: DemandeCheckout,
    ) -> Result<Checkout, ErreurFournisseur> {
        let corps = serde_json::json!({
            // Notre identifiant de transaction : le rapprochement se fait dans
            // les deux sens sans table de correspondance (FR-081).
            "reference_marchande": demande.reference_marchande,
            // ENTIER, unités mineures — jamais un flottant sur le fil.
            "montant": demande.montant_unites,
            "devise": demande.devise,
            "description": demande.description_cle,
            "retour_succes": demande.retour_succes,
            "retour_annulation": demande.retour_annulation,
        });

        let reponse = self
            .appeler(reqwest::Method::POST, "/checkouts", Some(corps))
            .await?;

        Ok(Checkout {
            reference_fournisseur: champ_texte(&reponse, "reference")?,
            acces_paiement: champ_texte(&reponse, "url_paiement")?,
            // L'échéance du fournisseur est INFORMATIVE : c'est la nôtre qui
            // est persistée et qui fait foi (R7). Se fier à la sienne
            // reviendrait à lui laisser décider quand une commande meurt.
            expire_le: reponse
                .get("expire_le")
                .and_then(Value::as_str)
                .and_then(|s| DateTime::parse_from_rfc3339(s).ok())
                .map(|d| d.with_timezone(&Utc)),
        })
    }

    fn verify_webhook(
        &self,
        entrante: &NotificationEntrante<'_>,
    ) -> Result<Notification, ErreurFournisseur> {
        // 1. La signature D'ABORD, sur le corps BRUT (R6). Désérialiser avant
        //    de vérifier reviendrait à faire confiance à la structure d'un
        //    inconnu.
        let brute = entrante
            .entetes
            .get(self.signature.entete())
            .ok_or(ErreurFournisseur::SignatureInvalide)?;
        self.signature
            .verifier(entrante.corps_brut, brute, entrante.recue_le)?;

        // 2. Seulement ensuite, la lecture.
        let charge: Value = serde_json::from_slice(entrante.corps_brut)
            .map_err(|e| ErreurFournisseur::ChargeIllisible(e.to_string()))?;

        let issue = traduire_issue(&champ_texte(&charge, "statut")?)?;
        let moyen = charge
            .get("moyen")
            .and_then(Value::as_str)
            .map(traduire_moyen);

        Ok(Notification {
            reference_fournisseur: champ_texte(&charge, "reference")?,
            // Une référence marchande absente ou illisible n'est PAS une
            // erreur : c'est une notification orpheline, qui ouvre un dossier
            // plutôt que de disparaître (FR-082).
            reference_marchande: charge
                .get("reference_marchande")
                .and_then(Value::as_str)
                .and_then(|s| s.parse().ok()),
            issue,
            montant_unites: charge
                .get("montant")
                .and_then(Value::as_i64)
                .ok_or_else(|| ErreurFournisseur::ChargeIllisible("montant absent".to_owned()))?,
            devise: champ_texte(&charge, "devise")?,
            moyen,
            survenu_le: charge
                .get("survenu_le")
                .and_then(Value::as_str)
                .and_then(|s| DateTime::parse_from_rfc3339(s).ok())
                .map(|d| d.with_timezone(&Utc))
                .unwrap_or(entrante.recue_le),
            empreinte_charge: empreinte(entrante.corps_brut),
        })
    }

    /// PAY-04 — **définie, jamais appelée par ce cycle** (FR-041, FR-111).
    ///
    /// Le code existe pour que la bascule d'agrégateur ne bute pas dessus le
    /// jour où PAY-04 sera construit. `tests/refund_jamais_appelee.rs` vérifie
    /// qu'aucun chemin du produit ne l'invoque.
    async fn refund(
        &self,
        demande: DemandeRemboursement,
    ) -> Result<Remboursement, ErreurFournisseur> {
        let corps = serde_json::json!({
            "reference": demande.reference_fournisseur,
            "montant": demande.montant_unites,
            "devise": demande.devise,
            "motif": demande.motif_cle,
        });
        let reponse = self
            .appeler(reqwest::Method::POST, "/remboursements", Some(corps))
            .await?;

        Ok(Remboursement {
            reference_remboursement: champ_texte(&reponse, "reference")?,
            montant_unites: reponse
                .get("montant")
                .and_then(Value::as_i64)
                .ok_or_else(|| ErreurFournisseur::ChargeIllisible("montant absent".to_owned()))?,
            devise: champ_texte(&reponse, "devise")?,
        })
    }

    async fn consulter(&self, reference: &str) -> Result<Notification, ErreurFournisseur> {
        let reponse = self
            .appeler(
                reqwest::Method::GET,
                &format!("/checkouts/{reference}"),
                None,
            )
            .await?;

        let issue = traduire_issue(&champ_texte(&reponse, "statut")?)?;
        Ok(Notification {
            reference_fournisseur: champ_texte(&reponse, "reference")?,
            reference_marchande: reponse
                .get("reference_marchande")
                .and_then(Value::as_str)
                .and_then(|s| s.parse().ok()),
            issue,
            montant_unites: reponse.get("montant").and_then(Value::as_i64).unwrap_or(0),
            devise: reponse
                .get("devise")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_owned(),
            moyen: reponse
                .get("moyen")
                .and_then(Value::as_str)
                .map(traduire_moyen),
            survenu_le: Utc::now(),
            // Une consultation n'est pas une notification reçue : son
            // empreinte porte la RÉFÉRENCE, pas un corps. Employer l'empreinte
            // du corps ferait entrer en collision deux consultations
            // successives — dont l'une porterait le succès.
            empreinte_charge: empreinte(reference.as_bytes()),
        })
    }
}

/// Lit un champ texte obligatoire.
fn champ_texte(valeur: &Value, cle: &str) -> Result<String, ErreurFournisseur> {
    valeur
        .get(cle)
        .and_then(Value::as_str)
        .map(str::to_owned)
        .ok_or_else(|| ErreurFournisseur::ChargeIllisible(format!("champ « {cle} » absent")))
}

/// Traduit le statut de l'agrégateur vers **notre** vocabulaire.
///
/// C'est le point d'ajustement n°1 d'une bascule : un autre agrégateur dira
/// `SUCCESS`, `COMPLETED` ou `04`. La liste s'allonge ici, et **nulle part
/// ailleurs** — le domaine ne voit que `IssuePaiement`.
///
/// ⚠ Un statut **inconnu** rend `ChargeIllisible` plutôt que `EnCours` : le
/// deviner ferait traiter un succès comme une attente, donc annuler une
/// commande payée à l'expiration. Un refus bruyant vaut mieux qu'un silence
/// qui coûte de l'argent.
fn traduire_issue(brut: &str) -> Result<IssuePaiement, ErreurFournisseur> {
    match brut.to_ascii_lowercase().as_str() {
        "reussi" | "succes" | "success" | "completed" | "paid" => Ok(IssuePaiement::Reussi),
        "echoue" | "echec" | "failed" | "declined" => Ok(IssuePaiement::Echoue),
        "annule" | "cancelled" | "canceled" => Ok(IssuePaiement::Annule),
        "en_cours" | "pending" | "processing" | "initiated" => Ok(IssuePaiement::EnCours),
        autre => Err(ErreurFournisseur::ChargeIllisible(format!(
            "statut inconnu : {autre}"
        ))),
    }
}

/// Traduit le moyen annoncé. Un moyen inconnu tombe sur `Autre` **sans faire
/// échouer** la notification : un agrégateur qui ajoute un moyen ne doit pas
/// bloquer des paiements réussis.
///
/// Le libellé brut est journalisé en `debug` — ici, où le diagnostic
/// d'intégration en a besoin et où il ne franchit aucune frontière (FR-003).
fn traduire_moyen(brut: &str) -> MoyenPaiement {
    match brut.to_ascii_lowercase().as_str() {
        "wave" => MoyenPaiement::Wave,
        "orange_money" | "orange" | "om" => MoyenPaiement::OrangeMoney,
        "mtn_momo" | "mtn" | "momo" => MoyenPaiement::MtnMomo,
        "moov_money" | "moov" => MoyenPaiement::MoovMoney,
        "carte" | "card" | "visa" | "mastercard" => MoyenPaiement::Carte,
        autre => {
            tracing::debug!(moyen_brut = autre, "moyen inconnu du domaine → `autre`");
            MoyenPaiement::Autre
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Le vocabulaire de l'agrégateur se traduit, et le nôtre reste stable.
    #[test]
    fn les_statuts_se_traduisent_vers_notre_vocabulaire() {
        for (brut, attendu) in [
            ("SUCCESS", IssuePaiement::Reussi),
            ("paid", IssuePaiement::Reussi),
            ("FAILED", IssuePaiement::Echoue),
            ("cancelled", IssuePaiement::Annule),
            ("PENDING", IssuePaiement::EnCours),
        ] {
            assert_eq!(traduire_issue(brut).unwrap(), attendu, "statut « {brut} »");
        }
    }

    /// Un statut inconnu ÉCHOUE — il ne devient pas `EnCours`.
    ///
    /// Le deviner ferait traiter un succès comme une attente, et la session
    /// expirerait sur une commande payée. Le refus bruyant ouvre un dossier ;
    /// le silence coûte de l'argent.
    #[test]
    fn un_statut_inconnu_echoue_plutot_que_d_etre_devine() {
        let echec = traduire_issue("SOMETHING_NEW");
        assert!(matches!(echec, Err(ErreurFournisseur::ChargeIllisible(_))));
    }

    /// Un moyen inconnu ne fait PAS échouer : un agrégateur qui ajoute un
    /// moyen ne doit pas bloquer des paiements réussis.
    #[test]
    fn un_moyen_inconnu_tombe_sur_autre_sans_echouer() {
        assert_eq!(traduire_moyen("un_moyen_de_2030"), MoyenPaiement::Autre);
        assert_eq!(traduire_moyen("WAVE"), MoyenPaiement::Wave);
        assert_eq!(traduire_moyen("om"), MoyenPaiement::OrangeMoney);
    }

    /// Le nom est **générique** : c'est un segment d'URL et une colonne de
    /// rapprochement, jamais une branche de règle métier (FR-003).
    #[test]
    fn le_nom_ne_designe_aucun_agregateur() {
        let client = AgregateurHttp::nouveau(
            "https://exemple.invalid",
            "cle",
            b"secret-de-test-de-32-octets-mini".to_vec(),
            "x-signature",
        )
        .unwrap();
        assert_eq!(PaymentProvider::nom(&client), "agregateur");
    }

    /// Une base d'URL avec barre oblique finale ne produit pas `//checkouts` —
    /// le genre de détail qui donne un `404` inexplicable à 3 h du matin.
    #[test]
    fn la_barre_oblique_finale_est_normalisee() {
        let client = AgregateurHttp::nouveau(
            "https://exemple.invalid/",
            "cle",
            b"secret-de-test-de-32-octets-mini".to_vec(),
            "x-signature",
        )
        .unwrap();
        assert_eq!(client.base_url, "https://exemple.invalid");
    }

    /// Un champ obligatoire absent est signalé **par son nom** : un
    /// `ChargeIllisible` sans le nom du champ ne se diagnostique pas.
    #[test]
    fn un_champ_absent_est_nomme() {
        let erreur = champ_texte(&serde_json::json!({}), "reference").unwrap_err();
        assert!(erreur.to_string().contains("reference"));
    }
}
