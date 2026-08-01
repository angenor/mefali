//! **La frontière réversible** (PAY-05).
//!
//! Rien de ce qui est propre à un agrégateur ne franchit cette ligne : ni son
//! nom, ni son vocabulaire, ni ses codes d'état, ni la forme de ses montants, ni
//! son algorithme de signature. Tout ce que le domaine voit, ce sont les types
//! neutres définis ici — que **nous** possédons.
//!
//! `scripts/verifier-frontiere-paiement.sh` le vérifie mécaniquement en CI
//! (T079, SC-010, FR-003). Une frontière qu'on se contente d'affirmer se
//! franchit au premier correctif pressé.
//!
//! # Le sens de lecture
//!
//! ```text
//!            ┌───────────────── frontière ─────────────────┐
//!            │                                             │
//!   domaine  │  DemandeCheckout  ──create_checkout──▶       │  HTTP sortant
//!  (session, │  Checkout         ◀─────────────────         │  vers l'agrégateur
//!   webhook, │                                             │
//!  expiration)│ NotificationEntrante ──verify_webhook──▶     │  corps brut + en-têtes
//!            │  Notification     ◀─────────────────         │  reçus du tiers
//!            └─────────────────────────────────────────────┘
//! ```
//!
//! # Trois écarts assumés par rapport au contrat de conception
//!
//! 1. **`entetes` n'est pas un `HeaderMap`.** Le contrat écrivait
//!    `&'a HeaderMap`, mais il en existe deux incompatibles dans l'arbre —
//!    celui d'`actix-http` (entrant) et celui du crate `http` que tire
//!    `reqwest`. En choisir un ferait entrer une couche de transport dans un
//!    crate de domaine. [`EntetesNotification`] est un porteur minimal que la
//!    couche HTTP remplit, et que les tests remplissent à la main sans monter
//!    de serveur.
//!
//! 2. **`MoyenPaiement::Autre` ne porte pas le libellé du fournisseur.**
//!    Voir [`crate::modele::MoyenPaiement`] : le libellé est un vocabulaire
//!    propriétaire, et il n'existe aucune colonne pour l'accueillir. Il est
//!    journalisé en `debug` **ici**, où le diagnostic d'intégration en a besoin
//!    et où il ne franchit rien.
//!
//! 3. **`verify_webhook` est synchrone**, comme le contrat l'exigeait — et le
//!    rappel mérite d'être écrit : une signature se vérifie en mémoire. La
//!    rendre `async` inviterait un jour un appel réseau dans un chemin qui doit
//!    rester instantané, et ce chemin est celui qui décide si de l'argent a été
//!    reçu.

use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::modele::MoyenPaiement;

pub mod signature;
pub mod simule;

pub use signature::{empreinte, SignatureHmac, TOLERANCE_HORODATAGE};
pub use simule::{FournisseurSimule, ScenarioSimule};

// ── 1. Le trait ───────────────────────────────────────────────────────────

/// Ce qu'un fournisseur de paiement doit savoir faire, et rien de plus.
///
/// Quatre opérations. Trois sont nommées par PAY-05 ; [`consulter`] s'y ajoute
/// parce que R7 en dépend — c'est une opération de **lecture**, pas un
/// quatrième chemin d'argent.
///
/// [`consulter`]: PaymentProvider::consulter
#[async_trait::async_trait]
pub trait PaymentProvider: Send + Sync {
    /// Identifiant **stable** de l'implémentation.
    ///
    /// Employé comme segment d'URL du webhook et stocké sur la transaction.
    /// **Jamais interprété par une règle métier** (FR-003) : aucune branche du
    /// domaine ne dit « si le fournisseur est X, alors… ».
    fn nom(&self) -> &'static str;

    /// Ouvre un encaissement de la **totalité** du montant dû (FR-002, FR-010).
    ///
    /// Il n'existe aucun chemin partiel : ni ici, ni dans le schéma, ni dans la
    /// machine à états (constitution III).
    async fn create_checkout(&self, demande: DemandeCheckout)
        -> Result<Checkout, ErreurFournisseur>;

    /// Vérifie la signature d'une notification et la traduit.
    ///
    /// **Synchrone** : aucune I/O ne doit s'introduire dans ce chemin (R3).
    /// Reçoit le **corps brut** — la signature se vérifie dessus, avant toute
    /// désérialisation (R6).
    fn verify_webhook(
        &self,
        entrante: &NotificationEntrante<'_>,
    ) -> Result<Notification, ErreurFournisseur>;

    /// PAY-04 (P1) — **définie, jamais appelée par ce cycle** (FR-041, FR-111).
    ///
    /// Elle existe pour honorer PAY-05 : un fournisseur interchangeable doit
    /// exposer le remboursement, sans quoi la bascule buterait dessus le jour
    /// où PAY-04 sera construit. Un test vérifie qu'**aucun chemin de code du
    /// produit ne l'invoque** — l'appeler ici construirait la story qu'on a
    /// explicitement exclue.
    async fn refund(
        &self,
        demande: DemandeRemboursement,
    ) -> Result<Remboursement, ErreurFournisseur>;

    /// Réconciliation **avant** annulation (FR-027, R7).
    ///
    /// Un webhook perdu en transit ne doit coûter ni la commande ni l'argent du
    /// client. Sans cet appel, chaque notification perdue deviendrait un litige.
    async fn consulter(&self, reference: &str) -> Result<Notification, ErreurFournisseur>;
}

// ── 2. Types d'échange — neutres, et à nous ───────────────────────────────

/// Demande d'ouverture d'encaissement.
#[derive(Debug, Clone)]
pub struct DemandeCheckout {
    /// Notre côté de la clé : **c'est l'identifiant de la transaction**.
    ///
    /// Le rapprochement se fait donc dans les deux sens sans table de
    /// correspondance (FR-081).
    pub reference_marchande: Uuid,
    /// **Entier**, en unités mineures (constitution III). Aucun flottant
    /// n'entre ni ne sort de cette frontière, y compris sur le fil.
    pub montant_unites: i64,
    /// Code ISO 4217 de la zone.
    pub devise: String,
    /// Clé i18n de la description montrée au payeur — jamais une phrase en dur.
    pub description_cle: &'static str,
    /// Lien de retour après succès. **Informatif : il ne crédite RIEN**
    /// (FR-025). Le seul fait qui confirme un paiement est une notification
    /// signée, ou une réconciliation.
    pub retour_succes: String,
    /// Lien de retour après annulation. Même statut : informatif.
    pub retour_annulation: String,
}

/// Encaissement ouvert chez le fournisseur.
#[derive(Debug, Clone)]
pub struct Checkout {
    /// Référence côté fournisseur — stockée pour rapprocher, jamais pour
    /// décider.
    pub reference_fournisseur: String,
    /// URL de la page de paiement.
    ///
    /// ⚠ **Jamais journalisée, jamais mise en événement** (FR-006, FR-103), et
    /// effacée en base dès que la transaction quitte `ouverte`.
    pub acces_paiement: String,
    /// Échéance annoncée par le fournisseur, s'il en annonce une.
    ///
    /// **La nôtre prime si elle est plus courte** : c'est notre échéance qui
    /// est persistée et qui fait foi (R7). Celle-ci n'est qu'une information —
    /// se fier à l'échéance d'un tiers reviendrait à lui laisser décider quand
    /// une commande d'Awa meurt.
    pub expire_le: Option<DateTime<Utc>>,
}

/// En-têtes d'une notification entrante.
///
/// Porteur **minimal** et neutre : ni `actix-http`, ni `http`. La couche HTTP le
/// remplit depuis sa requête ; les tests le construisent à la main.
///
/// La recherche est **insensible à la casse**, comme l'exige HTTP : un
/// fournisseur qui écrit `X-Signature` un jour et `x-signature` le lendemain ne
/// doit pas faire échouer une vérification pour cette raison.
#[derive(Debug, Clone, Default)]
pub struct EntetesNotification {
    entetes: Vec<(String, String)>,
}

impl EntetesNotification {
    /// Construit depuis une suite de paires `(nom, valeur)`.
    pub fn depuis<I, N, V>(paires: I) -> Self
    where
        I: IntoIterator<Item = (N, V)>,
        N: AsRef<str>,
        V: AsRef<str>,
    {
        Self {
            entetes: paires
                .into_iter()
                .map(|(n, v)| (n.as_ref().to_ascii_lowercase(), v.as_ref().to_owned()))
                .collect(),
        }
    }

    /// Valeur du premier en-tête portant ce nom, casse ignorée.
    pub fn get(&self, nom: &str) -> Option<&str> {
        let nom = nom.to_ascii_lowercase();
        self.entetes
            .iter()
            .find(|(n, _)| *n == nom)
            .map(|(_, v)| v.as_str())
    }
}

/// Une notification telle qu'elle arrive : **brute**, non désérialisée.
#[derive(Debug, Clone, Copy)]
pub struct NotificationEntrante<'a> {
    /// Corps **brut**. La signature se vérifie dessus (R6) — désérialiser avant
    /// de vérifier reviendrait à faire confiance à la structure d'un inconnu.
    pub corps_brut: &'a [u8],
    /// En-têtes de la requête, où vit la signature.
    pub entetes: &'a EntetesNotification,
    /// Instant de réception, **horloge serveur**. Sert la tolérance
    /// d'horodatage : une signature capturée sur le réseau et rejouée trois
    /// heures plus tard est refusée.
    pub recue_le: DateTime<Utc>,
}

/// Une notification vérifiée et traduite en vocabulaire du domaine.
#[derive(Debug, Clone)]
pub struct Notification {
    pub reference_fournisseur: String,
    /// Notre transaction, si le fournisseur nous la renvoie. `None` sur une
    /// notification **orpheline** — qui ouvre un dossier plutôt que de
    /// disparaître (FR-082).
    pub reference_marchande: Option<Uuid>,
    pub issue: IssuePaiement,
    /// **Entier**, unités mineures. Comparé au montant figé de la transaction :
    /// une divergence ne vaut **pas** confirmation (FR-024).
    pub montant_unites: i64,
    pub devise: String,
    /// `None` tant que le fournisseur ne l'a pas dit — jamais deviné (FR-012).
    pub moyen: Option<MoyenPaiement>,
    pub survenu_le: DateTime<Utc>,
    /// Empreinte du **corps brut** — la clé d'idempotence (R5).
    ///
    /// Elle entre dans la contrainte d'unicité avec le fournisseur et sa
    /// référence, parce qu'un fournisseur peut légitimement renvoyer la **même**
    /// référence avec un contenu différent (`en_cours` → `réussi`). Sans elle,
    /// la seconde notification — celle qui porte le succès — serait avalée
    /// comme un doublon.
    pub empreinte_charge: String,
}

/// Issue d'un paiement, dans **notre** vocabulaire.
///
/// Quatre valeurs, et aucune ne dit « partiellement payé » : la constitution III
/// l'interdit, et la traduction depuis un fournisseur qui aurait cette notion
/// doit trancher, pas la propager.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IssuePaiement {
    /// Le payeur a payé, le fournisseur le confirme.
    Reussi,
    /// Refus opérateur. La session **vit encore** : réessai permis (FR-026).
    Echoue,
    /// Le payeur a renoncé.
    Annule,
    /// Le fournisseur n'a pas encore d'issue. **N'est pas un échec** : traiter
    /// `EnCours` comme un refus annulerait des commandes payées.
    EnCours,
}

impl IssuePaiement {
    /// Libellé stocké dans `notification_recue.issue`.
    pub fn comme_str(self) -> &'static str {
        match self {
            IssuePaiement::Reussi => "reussi",
            IssuePaiement::Echoue => "echoue",
            IssuePaiement::Annule => "annule",
            IssuePaiement::EnCours => "en_cours",
        }
    }
}

/// PAY-04 — demande de remboursement. **Aucun appelant dans ce cycle.**
#[derive(Debug, Clone)]
pub struct DemandeRemboursement {
    pub reference_fournisseur: String,
    pub montant_unites: i64,
    pub devise: String,
    pub motif_cle: &'static str,
}

/// PAY-04 — remboursement accepté. **Aucun appelant dans ce cycle.**
#[derive(Debug, Clone)]
pub struct Remboursement {
    pub reference_remboursement: String,
    pub montant_unites: i64,
    pub devise: String,
}

/// Ce qui peut mal se passer **du côté du fournisseur**.
///
/// Aucune de ces variantes ne porte un code d'état propriétaire : le client HTTP
/// traduit `502`, `TIMEOUT`, `ERR_4021` et le reste vers ces cinq cas, et le
/// domaine ne voit que ceux-ci.
#[derive(Debug, thiserror::Error)]
pub enum ErreurFournisseur {
    /// Signature absente, invalide, forgée ou périmée (FR-020).
    #[error("signature invalide")]
    SignatureInvalide,
    /// Corps illisible ou champ obligatoire absent, **après** signature valide.
    #[error("charge illisible : {0}")]
    ChargeIllisible(String),
    /// Injoignable, en panne, ou hors délai → `502`, la commande reste
    /// **intacte** (FR-018).
    #[error("fournisseur indisponible : {0}")]
    Indisponible(String),
    /// Le fournisseur a compris et a dit non (montant hors bornes, compte
    /// marchand suspendu…).
    #[error("refusé par le fournisseur : {0}")]
    RefuseParFournisseur(String),
    /// `refund` d'un fournisseur qui n'expose pas de remboursement par API.
    #[error("opération non supportée par ce fournisseur")]
    NonSupporte,
}

/// Traduction **unique** des pannes de fournisseur vers le domaine.
///
/// Quatre des cinq variantes deviennent `FournisseurIndisponible`, donc `502` :
/// du point de vue d'Awa, « le fournisseur a refusé notre demande d'ouverture »
/// et « le fournisseur n'a pas répondu » sont le même événement — sa commande
/// est intacte et elle peut réessayer (FR-018). Les distinguer dans la réponse
/// n'aiderait qu'un attaquant à cartographier notre intégration ; le détail
/// reste dans le message, donc dans les journaux.
///
/// `SignatureInvalide` est la seule à garder son identité : elle ne dit rien du
/// fournisseur, elle dit que **l'appelant** n'est pas celui qu'il prétend être,
/// et elle rend `401`.
impl From<ErreurFournisseur> for crate::modele::ErreurPaiements {
    fn from(erreur: ErreurFournisseur) -> Self {
        use crate::modele::ErreurPaiements;
        match erreur {
            ErreurFournisseur::SignatureInvalide => ErreurPaiements::SignatureInvalide,
            autre => ErreurPaiements::FournisseurIndisponible(autre.to_string()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// HTTP dit les noms d'en-tête insensibles à la casse. Un fournisseur qui
    /// change `X-Signature` en `x-signature` entre deux versions ne doit pas
    /// faire échouer une vérification pour cette raison — et ce genre de
    /// changement arrive.
    #[test]
    fn les_entetes_ignorent_la_casse() {
        let e = EntetesNotification::depuis([("X-Signature", "abc"), ("Content-Type", "json")]);
        assert_eq!(e.get("x-signature"), Some("abc"));
        assert_eq!(e.get("X-SIGNATURE"), Some("abc"));
        assert_eq!(e.get("X-Signature"), Some("abc"));
        assert_eq!(e.get("absent"), None);
    }

    /// Les libellés d'issue sont ceux écrits en base : les changer casserait la
    /// lecture des notifications déjà reçues.
    #[test]
    fn les_libelles_d_issue_sont_stables() {
        assert_eq!(IssuePaiement::Reussi.comme_str(), "reussi");
        assert_eq!(IssuePaiement::Echoue.comme_str(), "echoue");
        assert_eq!(IssuePaiement::Annule.comme_str(), "annule");
        assert_eq!(IssuePaiement::EnCours.comme_str(), "en_cours");
    }
}
