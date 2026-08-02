//! Vérification HMAC-SHA256 d'une notification — **la seule garde du webhook**.
//!
//! Cette route n'a pas de porteur : elle est joignable depuis Internet, et ce
//! qu'elle accepte confirme une commande. Tout ce qui la protège tient ici.
//!
//! # Les quatre règles, et ce que chacune arrête
//!
//! 1. **La signature porte sur le corps BRUT** (research R6). Vérifier après
//!    désérialisation reviendrait à faire confiance à la structure d'un inconnu,
//!    et à signer une re-sérialisation plutôt que les octets reçus — un espace
//!    en plus et la vérification échouerait sur une notification honnête.
//! 2. **L'horodatage entre dans le message signé.** Sinon il serait modifiable
//!    sans invalider la signature, et la tolérance ne servirait à rien.
//! 3. **La fenêtre est bilatérale** (±5 min). Une signature du futur est aussi
//!    suspecte qu'une périmée : elle trahit une horloge faussée, ou une forgerie
//!    qui cherche à rester valide longtemps.
//! 4. **La comparaison est en temps constant** (`subtle`). L'égalité de Rust
//!    s'arrête au premier octet différent : le temps de réponse fuite alors la
//!    position de l'erreur, et un attaquant reconstruit la signature octet par
//!    octet.
//!
//! # Pourquoi ce module est partagé
//!
//! Le double ([`super::simule`]) et le client HTTP ([`super::agregateur`])
//! emploient **la même** implémentation. Deux vérificateurs auraient divergé, et
//! la suite de tests aurait alors validé la sécurité du double plutôt que celle
//! du chemin de production.
//!
//! Un agrégateur réel imposera sa propre convention — nom d'en-tête, format,
//! ordre des champs. C'est exactement ce que [`SignatureHmac`] paramètre. La
//! primitive, elle, ne change pas.

use std::sync::Arc;

use chrono::{DateTime, Duration, Utc};
use hmac::{Hmac, KeyInit, Mac};
use sha2::{Digest, Sha256};
use subtle::ConstantTimeEq;

use super::{EntetesNotification, ErreurFournisseur};

/// Tolérance d'horodatage de la signature (R6).
///
/// Ferme la fenêtre de rejeu d'une capture réseau : une notification signée il
/// y a trois heures et rejouée maintenant est refusée, **même si sa signature
/// est authentique**.
pub const TOLERANCE_HORODATAGE: Duration = Duration::minutes(5);

/// Longueur minimale d'un secret de webhook, en octets (FR-045).
///
/// `socle::Config::valider` refuse le démarrage en dessous ; la constante vit
/// ici parce que c'est ici que le secret sert.
pub const SECRET_MIN_OCTETS: usize = 32;

/// Signataire et vérificateur HMAC-SHA256 d'un fournisseur.
///
/// Format du champ : `t=<horodatage unix>,v1=<hex(HMAC-SHA256(secret, "t.corps"))>`.
#[derive(Clone)]
pub struct SignatureHmac {
    secret: Arc<Vec<u8>>,
    entete: String,
}

impl SignatureHmac {
    /// Construit un signataire sur un secret et le nom d'en-tête d'un
    /// fournisseur.
    pub fn nouveau(secret: Vec<u8>, entete: impl Into<String>) -> Self {
        Self {
            secret: Arc::new(secret),
            entete: entete.into(),
        }
    }

    /// Nom de l'en-tête où la signature est attendue.
    pub fn entete(&self) -> &str {
        &self.entete
    }

    /// Vrai si le secret atteint la longueur minimale (FR-045).
    ///
    /// N'est **pas** appliqué à la construction : le double de test emploie
    /// délibérément des secrets courts pour exercer des refus, et refuser ici
    /// rendrait ces tests inécrivables. La garde de production est au
    /// démarrage, dans `socle::Config::valider`, où elle empêche l'API de
    /// démarrer plutôt que d'échouer à la première notification.
    pub fn secret_suffisant(&self) -> bool {
        self.secret.len() >= SECRET_MIN_OCTETS
    }

    /// Signe un corps brut, comme le ferait le fournisseur.
    pub fn signer(&self, corps: &[u8], quand: DateTime<Utc>) -> String {
        let t = quand.timestamp();
        let signature = self.empreinte(&t.to_string(), corps);
        format!("t={t},v1={}", hex(&signature))
    }

    /// Vérifie une signature déjà extraite de son en-tête.
    pub fn verifier(
        &self,
        corps: &[u8],
        signature: &str,
        recue_le: DateTime<Utc>,
    ) -> Result<(), ErreurFournisseur> {
        let (t, v1) = decouper(signature).ok_or(ErreurFournisseur::SignatureInvalide)?;
        let horodatage = t
            .parse::<i64>()
            .ok()
            .and_then(|s| DateTime::from_timestamp(s, 0))
            .ok_or(ErreurFournisseur::SignatureInvalide)?;

        if (recue_le - horodatage).abs() > TOLERANCE_HORODATAGE {
            return Err(ErreurFournisseur::SignatureInvalide);
        }

        let attendue = hex(&self.empreinte(t, corps));
        if attendue.as_bytes().ct_eq(v1.as_bytes()).into() {
            Ok(())
        } else {
            Err(ErreurFournisseur::SignatureInvalide)
        }
    }

    /// Extrait la signature des en-têtes et la vérifie.
    ///
    /// Une signature **absente** rend le même refus qu'une signature fausse :
    /// distinguer les deux dans la réponse renseignerait un attaquant sur ce
    /// qu'il lui manque.
    pub fn verifier_entetes(
        &self,
        entetes: &EntetesNotification,
        corps: &[u8],
        recue_le: DateTime<Utc>,
    ) -> Result<(), ErreurFournisseur> {
        let signature = entetes
            .get(&self.entete)
            .ok_or(ErreurFournisseur::SignatureInvalide)?;
        self.verifier(corps, signature, recue_le)
    }

    fn empreinte(&self, t: &str, corps: &[u8]) -> Vec<u8> {
        let mut mac = Hmac::<Sha256>::new_from_slice(&self.secret)
            .expect("HMAC-SHA256 accepte une clé de toute longueur");
        mac.update(t.as_bytes());
        mac.update(b".");
        mac.update(corps);
        mac.finalize().into_bytes().to_vec()
    }
}

/// Empreinte SHA-256 hexadécimale du corps brut — clé d'idempotence (R5).
pub fn empreinte(corps: &[u8]) -> String {
    hex(&Sha256::digest(corps))
}

/// Hexadécimal minuscule.
pub fn hex(octets: &[u8]) -> String {
    use std::fmt::Write;
    octets.iter().fold(String::new(), |mut s, o| {
        let _ = write!(s, "{o:02x}");
        s
    })
}

/// Découpe `t=…,v1=…` en ses deux parties.
fn decouper(signature: &str) -> Option<(&str, &str)> {
    let mut t = None;
    let mut v1 = None;
    for partie in signature.split(',') {
        match partie.split_once('=') {
            Some(("t", v)) => t = Some(v),
            Some(("v1", v)) => v1 = Some(v),
            _ => {}
        }
    }
    Some((t?, v1?))
}

#[cfg(test)]
mod tests {
    use super::*;

    const ENTETE: &str = "x-signature-de-test";

    fn signataire() -> SignatureHmac {
        SignatureHmac::nouveau(b"secret-de-webhook-de-test-32-oct".to_vec(), ENTETE)
    }

    fn corps() -> Vec<u8> {
        br#"{"issue":"reussi","montant_unites":12500}"#.to_vec()
    }

    #[test]
    fn une_signature_authentique_est_acceptee() {
        let s = signataire();
        let maintenant = Utc::now();
        s.verifier(&corps(), &s.signer(&corps(), maintenant), maintenant)
            .expect("le chemin nominal");
    }

    /// Signature **ABSENTE** — refusée comme une signature fausse. Distinguer
    /// les deux renseignerait un attaquant sur ce qu'il lui manque.
    #[test]
    fn signature_absente_refusee() {
        let s = signataire();
        let vides = EntetesNotification::default();
        assert!(matches!(
            s.verifier_entetes(&vides, &corps(), Utc::now()).unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Signature **TRONQUÉE** — le cas d'une troncature en transit, ou d'une
    /// forgerie partielle.
    #[test]
    fn signature_tronquee_refusee() {
        let s = signataire();
        let maintenant = Utc::now();
        let complete = s.signer(&corps(), maintenant);
        for tronquee in [
            &complete[..complete.len() - 8],
            &complete[..complete.len() - 1],
            "t=1,v1=",
            "v1=abc",
            "n'importe quoi",
        ] {
            assert!(
                s.verifier(&corps(), tronquee, maintenant).is_err(),
                "« {tronquee} » ne doit pas passer",
            );
        }
    }

    /// Signature valide, mais d'un **AUTRE secret** : fuite chez un tiers, ou
    /// environnement de recette pointant la production.
    #[test]
    fn signature_d_un_autre_secret_refusee() {
        let vrai = signataire();
        let faux = SignatureHmac::nouveau(b"secret-B-de-32-octets-exactement!".to_vec(), ENTETE);
        let maintenant = Utc::now();
        assert!(matches!(
            vrai.verifier(&corps(), &faux.signer(&corps(), maintenant), maintenant)
                .unwrap_err(),
            ErreurFournisseur::SignatureInvalide,
        ));
    }

    /// Signature **AUTHENTIQUE mais PÉRIMÉE** : une capture réseau rejouée
    /// trois heures plus tard.
    #[test]
    fn signature_perimee_refusee() {
        let s = signataire();
        let vieille = s.signer(&corps(), Utc::now() - Duration::hours(3));
        assert!(s.verifier(&corps(), &vieille, Utc::now()).is_err());
    }

    /// Une signature du **FUTUR** est aussi suspecte qu'une périmée.
    #[test]
    fn signature_du_futur_refusee() {
        let s = signataire();
        let future = s.signer(&corps(), Utc::now() + Duration::hours(3));
        assert!(s.verifier(&corps(), &future, Utc::now()).is_err());
    }

    /// Les BORDS de la fenêtre, des deux côtés — c'est là que les erreurs de
    /// comparaison se logent.
    #[test]
    fn les_bords_de_la_fenetre() {
        let s = signataire();
        // Horloge posée sur une seconde PLEINE : `signer` tronque l'horodatage
        // à la seconde, et une fraction résiduelle décalerait le bord exact.
        // Le test mesure la fenêtre, pas l'arrondi de `Utc::now()`.
        let maintenant = DateTime::from_timestamp(Utc::now().timestamp(), 0).unwrap();
        for ecart in [
            TOLERANCE_HORODATAGE,
            -TOLERANCE_HORODATAGE,
            TOLERANCE_HORODATAGE - Duration::seconds(1),
        ] {
            let signature = s.signer(&corps(), maintenant + ecart);
            assert!(
                s.verifier(&corps(), &signature, maintenant).is_ok(),
                "écart de {ecart} accepté",
            );
        }
        for ecart in [
            TOLERANCE_HORODATAGE + Duration::seconds(1),
            -TOLERANCE_HORODATAGE - Duration::seconds(1),
        ] {
            let signature = s.signer(&corps(), maintenant + ecart);
            assert!(
                s.verifier(&corps(), &signature, maintenant).is_err(),
                "écart de {ecart} refusé",
            );
        }
    }

    /// Le **CORPS modifié après signature** : l'attaque que la signature sur le
    /// corps BRUT existe pour arrêter — changer 12 500 en 1.
    #[test]
    fn corps_modifie_apres_signature_refuse() {
        let s = signataire();
        let maintenant = Utc::now();
        let signature = s.signer(&corps(), maintenant);
        let falsifie = br#"{"issue":"reussi","montant_unites":1}"#.to_vec();
        assert!(s.verifier(&falsifie, &signature, maintenant).is_err());
    }

    /// L'HORODATAGE modifié sans resigner : il entre dans le message signé,
    /// donc le déplacer casse la signature. Sans cette propriété, la tolérance
    /// ne servirait à rien — il suffirait de rafraîchir `t`.
    #[test]
    fn horodatage_deplace_sans_resigner_refuse() {
        let s = signataire();
        let vieux = Utc::now() - Duration::hours(3);
        let signature = s.signer(&corps(), vieux);
        let (_, v1) = decouper(&signature).unwrap();
        let rafraichie = format!("t={},v1={v1}", Utc::now().timestamp());
        assert!(s.verifier(&corps(), &rafraichie, Utc::now()).is_err());
    }

    /// FR-045 — la longueur du secret est mesurable. La garde de production est
    /// au démarrage ; ce test fige la mesure dont elle dépend.
    #[test]
    fn la_longueur_du_secret_est_mesurable() {
        assert!(signataire().secret_suffisant());
        assert!(!SignatureHmac::nouveau(b"trop-court".to_vec(), ENTETE).secret_suffisant());
    }

    /// L'empreinte distingue deux charges différentes portant la MÊME référence
    /// — le cas `en_cours` → `reussi` de R5.
    #[test]
    fn l_empreinte_distingue_deux_charges() {
        let a = br#"{"issue":"en_cours"}"#;
        let b = br#"{"issue":"reussi"}"#;
        assert_ne!(empreinte(a), empreinte(b));
        assert_eq!(empreinte(a), empreinte(a), "l'empreinte est stable");
    }
}
