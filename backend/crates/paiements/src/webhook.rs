//! Traitement d'une notification de fournisseur — **le chemin qui décide si de
//! l'argent a été reçu**.
//!
//! C'est la surface la plus exposée du produit : elle n'a pas de porteur, elle
//! est joignable depuis Internet, et ce qu'elle accepte confirme une commande.
//! Sa garde est **cryptographique**, et l'ordre des opérations n'est pas
//! négociable :
//!
//! ```text
//!   1. verify_webhook        ← signature sur le corps BRUT, avant toute
//!                              désérialisation (research R6)
//!   2. enregistrer           ← INSERT sous contrainte d'unicité triple :
//!                              c'est LUI qui porte l'idempotence (R5)
//!   3. SELECT … FOR UPDATE   ← deux notifications concurrentes se sérialisent
//!   4. transition gardée     ← `reglee` est terminal (FR-034)
//!   5. événement + commit    ← dans la MÊME transaction que l'état
//!   6. confirmer la commande ← APRÈS, et jamais avant : voir ci-dessous
//! ```
//!
//! # Pourquoi la commande est confirmée **après** le commit du paiement
//!
//! `CommandesAPayer::confirmer_prepaiement` compose sa propre transaction
//! (contrat §2) : il y a donc deux commits, et l'ordre décide de ce qui casse
//! quand le second échoue.
//!
//! - **Paiement d'abord, commande ensuite** (le choix retenu) : si le second
//!   échoue, la transaction est `reglee` et la commande reste
//!   `en_attente_paiement`. Le balayage d'expiration ne la touchera pas — il ne
//!   sélectionne que les sessions `ouverte`. Rien n'est perdu, l'exploitation
//!   voit une commande à confirmer à la main.
//! - **Commande d'abord, paiement ensuite** : si le second échoue, la commande
//!   part au dispatch pendant que sa session reste `ouverte`… puis expire, et le
//!   chemin d'annulation annule une commande déjà en cours de livraison.
//!
//! Le premier ordre échoue en laissant de l'argent encaissé et une commande en
//! attente ; le second échoue en annulant une course commencée. Ce n'est pas un
//! choix esthétique.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;

use commandes::CommandesAPayer;

use crate::depot::PgPaiements;
use crate::fournisseur::{IssuePaiement, NotificationEntrante, PaymentProvider};
use crate::modele::{verifier_transition, ErreurPaiements, EtatTransaction, MoyenPaiement};

/// Ce que le traitement a fait de la notification.
///
/// Répondu `200` dans **tous** les cas : un fournisseur qui reçoit une erreur
/// retente en boucle, et une boucle de retentes sur une notification déjà
/// traitée est un incident de production à part entière (FR-022).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResultatWebhook {
    /// Vrai si la notification a produit un effet.
    pub traite: bool,
    /// Pourquoi elle n'en a pas produit — clé courte, jamais une phrase.
    pub motif: Option<&'static str>,
}

impl ResultatWebhook {
    /// Effet appliqué.
    pub fn traite() -> Self {
        Self {
            traite: true,
            motif: None,
        }
    }

    /// Aucun effet, pour la raison nommée.
    pub fn ignore(motif: &'static str) -> Self {
        Self {
            traite: false,
            motif: Some(motif),
        }
    }
}

/// Motifs d'absence d'effet — le seul endroit où ces chaînes sont écrites.
pub mod motifs {
    /// Notification déjà vue : même fournisseur, même référence, même charge.
    pub const REJEU: &str = "rejeu";
    /// Le fournisseur n'a pas encore tranché — **n'est pas un échec**.
    pub const EN_COURS: &str = "en_cours";
    /// Aucune transaction ne correspond à la référence annoncée.
    pub const ORPHELINE: &str = "orpheline";
    /// L'état de la transaction n'accepte pas cette issue.
    pub const ETAT_INCOMPATIBLE: &str = "etat_incompatible";
}

/// Traite une notification entrante, de bout en bout.
///
/// `Err(SignatureInvalide)` est le **seul** refus : tout le reste répond `200`
/// avec un motif, parce qu'un fournisseur ne sait pas quoi faire d'une erreur
/// autre que retenter.
pub async fn traiter_notification(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    fournisseur: &dyn PaymentProvider,
    entrante: NotificationEntrante<'_>,
) -> Result<ResultatWebhook, ErreurPaiements> {
    // ── 1. La signature, sur le corps BRUT, avant toute désérialisation ───
    let notification = fournisseur.verify_webhook(&entrante)?;
    let maintenant = entrante.recue_le;

    let Some(reference) = notification.reference_marchande else {
        // Orpheline : le durcissement d'US3 lui ouvrira un dossier. Ici, elle
        // n'a simplement aucune transaction à toucher.
        tracing::warn!(
            fournisseur = fournisseur.nom(),
            "notification sans référence marchande — aucune transaction visée",
        );
        return Ok(ResultatWebhook::ignore(motifs::ORPHELINE));
    };

    let mut tx = depot.pool().begin().await?;

    // ── 2. L'idempotence, portée par la CONTRAINTE ────────────────────────
    depot
        .enregistrer_notification(
            &mut tx,
            fournisseur.nom(),
            &notification.reference_fournisseur,
            &notification.empreinte_charge,
            Some(reference),
            true,
            notification.issue.comme_str(),
            Some(notification.montant_unites),
            Some(&notification.devise),
            maintenant,
        )
        .await?;

    // ── 3. La transaction, VERROUILLÉE ────────────────────────────────────
    let Some(transaction) = depot.transaction_verrouillee(&mut tx, reference).await? else {
        tx.commit().await?;
        return Ok(ResultatWebhook::ignore(motifs::ORPHELINE));
    };

    // `EnCours` n'est pas un échec : le traiter comme tel annulerait des
    // commandes payées. Il n'a simplement rien à changer.
    if notification.issue != IssuePaiement::Reussi {
        tx.commit().await?;
        return Ok(ResultatWebhook::ignore(motifs::EN_COURS));
    }

    // ── 4. La transition, gardée par la table fermée ──────────────────────
    if verifier_transition(transaction.etat, EtatTransaction::Reglee).is_err() {
        // Une seconde notification de succès sur une session déjà réglée est le
        // cas NORMAL d'un fournisseur qui retente : elle ne doit pas produire
        // d'erreur, seulement rester sans effet.
        tx.commit().await?;
        return Ok(ResultatWebhook::ignore(motifs::ETAT_INCOMPATIBLE));
    }

    let moyen = notification.moyen.unwrap_or(MoyenPaiement::Inconnu);
    depot
        .changer_etat_transaction(
            &mut tx,
            transaction.id,
            EtatTransaction::Reglee,
            Some(moyen),
            Some(&notification.reference_fournisseur),
            maintenant,
        )
        .await?;

    // ── 5. L'événement, dans la MÊME transaction que l'état ───────────────
    //
    // `delai_confirmation_s` est mesuré sur NOTRE horloge, pas sur le
    // `survenu_le` du fournisseur : c'est un indicateur de pilotage (MET-01),
    // et le faire dépendre de l'horloge d'un tiers le rendrait incomparable
    // d'un fournisseur à l'autre.
    let delai_confirmation_s = (maintenant - transaction.ouverte_le).num_seconds().max(0);
    socle::ecrire_evenement(
        &mut tx,
        NouvelEvenement {
            type_evenement: "paiement.confirme",
            entite_type: "transaction",
            entite_id: transaction.id,
            payload: json!({
                "commande": transaction.commande_id,
                "montant": transaction.montant_unites,
                "devise": transaction.devise,
                "moyen": moyen.comme_str(),
                "delai_confirmation_s": delai_confirmation_s,
            }),
            survenu_le: maintenant,
        },
    )
    .await?;
    tx.commit().await?;

    // ── 6. La commande, APRÈS — voir l'en-tête du module ──────────────────
    confirmer_la_commande(commandes, transaction.commande_id, maintenant).await?;

    Ok(ResultatWebhook::traite())
}

/// Confirme la commande, et **journalise fort** si elle résiste.
///
/// À ce point, l'argent est encaissé et la transaction est `reglee` : un échec
/// ici ne doit ni faire répondre une erreur au fournisseur (il retenterait, et
/// le rejeu serait avalé par l'idempotence sans jamais rattraper la commande),
/// ni passer inaperçu.
async fn confirmer_la_commande(
    commandes: &dyn CommandesAPayer,
    commande: uuid::Uuid,
    quand: DateTime<Utc>,
) -> Result<(), ErreurPaiements> {
    match commandes.confirmer_prepaiement(commande, quand).await {
        Ok(()) => Ok(()),
        Err(e) => {
            tracing::error!(
                commande = %commande,
                erreur = %e,
                "PAIEMENT ENCAISSÉ, COMMANDE NON CONFIRMÉE — la transaction est \
                 `reglee`, le balayage d'expiration ne la touchera pas, mais la \
                 commande reste en attente : intervention d'exploitation requise",
            );
            Err(e.into())
        }
    }
}

/// Instant de réception d'une notification — horloge **serveur**.
///
/// Exposé pour que la couche HTTP n'ait pas à décider elle-même d'où vient
/// « maintenant » : la tolérance d'horodatage de la signature en dépend, et une
/// seconde source d'heure aurait tôt fait de diverger de celle du dépôt.
pub fn recue_le(depot: &PgPaiements) -> DateTime<Utc> {
    depot.maintenant()
}
