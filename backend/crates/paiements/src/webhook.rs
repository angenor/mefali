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
//!   4. montant et devise     ← une divergence ne vaut PAS confirmation (FR-024)
//!   5. transition gardée     ← `reglee` est terminal (FR-034)
//!   6. événement + commit    ← dans la MÊME transaction que l'état
//!   7. confirmer la commande ← APRÈS, et jamais avant : voir ci-dessous
//! ```
//!
//! # Un seul refus : la signature
//!
//! Tout le reste répond `200` avec un motif. Un fournisseur ne sait rien faire
//! d'une erreur sinon **retenter**, et une boucle de retentes sur une
//! notification déjà traitée est un incident de production à part entière
//! (FR-022). Répondre `409` à une notification concurrente perdante coûterait
//! des milliers de requêtes pour un événement qui s'est bien passé.
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
use uuid::Uuid;

use commandes::CommandesAPayer;

use crate::depot::PgPaiements;
use crate::dossier::{self, Anomalie};
use crate::fournisseur::{
    empreinte, ErreurFournisseur, IssuePaiement, Notification, NotificationEntrante,
    PaymentProvider,
};
use crate::modele::{
    verifier_transition, ErreurPaiements, EtatTransaction, MoyenPaiement, Transaction, TypeDossier,
};

/// Référence portée par une notification dont la signature n'a pas été vérifiée.
///
/// La trace de refus est écrite **sans** lire le corps : on n'a donc aucune
/// référence de fournisseur à y mettre, et en inventer une depuis un contenu
/// non authentifié reviendrait à faire confiance à ce qu'on vient de rejeter.
pub const REFERENCE_NON_VERIFIEE: &str = "(signature invalide)";

/// Issue inscrite sur une notification refusée.
pub const ISSUE_REFUSEE: &str = "refusee";

/// Ce que le traitement a fait de la notification.
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
    /// Montant ou devise divergents : un dossier s'ouvre, rien n'est confirmé.
    pub const DIVERGENCE: &str = "divergence";
}

/// Clés i18n des motifs d'échec de paiement — jamais une phrase (FR-103).
pub mod motifs_echec {
    /// Refus d'opérateur : solde insuffisant, code faux, plafond atteint.
    pub const REFUS_OPERATEUR: &str = "paiement.echec.refus_operateur";
    /// Le payeur a renoncé de lui-même.
    pub const ANNULE_PAR_PAYEUR: &str = "paiement.echec.annule_par_payeur";
}

/// Traite une notification entrante, de bout en bout.
///
/// `Err(SignatureInvalide)` est le **seul** refus.
pub async fn traiter_notification(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    fournisseur: &dyn PaymentProvider,
    entrante: NotificationEntrante<'_>,
) -> Result<ResultatWebhook, ErreurPaiements> {
    let maintenant = entrante.recue_le;

    // ── 1. La signature, sur le corps BRUT, avant toute désérialisation ───
    let notification = match fournisseur.verify_webhook(&entrante) {
        Ok(notification) => notification,
        Err(ErreurFournisseur::SignatureInvalide) => {
            tracer_refus(depot, fournisseur, entrante.corps_brut, maintenant).await?;
            return Err(ErreurPaiements::SignatureInvalide);
        }
        // Charge illisible APRÈS signature valide : bug d'intégration, pas
        // attaque. La distinction compte — la première se corrige avec le
        // fournisseur, la seconde se surveille.
        Err(e) => {
            tracing::error!(
                fournisseur = fournisseur.nom(), erreur = %e,
                "notification signée mais illisible — intégration à corriger",
            );
            return Err(e.into());
        }
    };

    let mut tx = depot.pool().begin().await?;

    // ── 2. La transaction, VERROUILLÉE ────────────────────────────────────
    //
    // **Avant** l'enregistrement, pour deux raisons :
    //
    // 1. `notification_recue.transaction_id` porte une clé étrangère. Une
    //    référence qui ne désigne rien de chez nous ferait échouer l'insertion
    //    en `500` au lieu d'ouvrir le dossier `transaction_orpheline` que
    //    FR-082 demande. Il faut donc savoir si elle existe avant d'écrire.
    // 2. Le verrou sérialise deux notifications concurrentes **dès l'entrée**,
    //    au lieu de les laisser se croiser entre l'insertion et la lecture.
    //
    // L'idempotence n'y perd rien : elle est portée par la contrainte
    // d'unicité de l'insertion, pas par l'ordre des étapes.
    let transaction = match notification.reference_marchande {
        Some(reference) => depot.transaction_verrouillee(&mut tx, reference).await?,
        None => None,
    };

    // ── 3. L'idempotence, portée par la CONTRAINTE ────────────────────────
    //
    // `None` = la triple clé existe déjà. C'est un rejeu, donc **aucun effet**.
    // Une contrainte et non un `if` : deux notifications concurrentes
    // passeraient toutes deux un test « est-ce déjà réglé ? » avant que l'une
    // n'écrive. Elles ne passent pas toutes deux un `INSERT` sous unicité.
    let enregistree = depot
        .enregistrer_notification(
            &mut tx,
            fournisseur.nom(),
            &notification.reference_fournisseur,
            &notification.empreinte_charge,
            transaction.as_ref().map(|t| t.id),
            true,
            notification.issue.comme_str(),
            Some(notification.montant_unites),
            Some(&notification.devise),
            maintenant,
        )
        .await?;
    if enregistree.is_none() {
        tx.commit().await?;
        tracing::debug!(
            fournisseur = fournisseur.nom(),
            "notification déjà vue — aucun effet (FR-021)",
        );
        return Ok(ResultatWebhook::ignore(motifs::REJEU));
    }

    let Some(transaction) = transaction else {
        return orpheline(depot, tx, &notification, maintenant).await;
    };

    // ── 4. Montant et devise — une divergence ne CONFIRME rien (FR-024) ───
    //
    // Contrôlés seulement quand le fournisseur annonce un succès : un refus au
    // mauvais montant reste un refus, et ouvrir un dossier pour ça noierait la
    // file d'anomalies sous des non-événements.
    if notification.issue == IssuePaiement::Reussi {
        if let Some(divergence) = divergence(&transaction, &notification) {
            dossier::ouvrir(
                depot,
                &mut tx,
                divergence,
                Anomalie {
                    commande_id: Some(transaction.commande_id),
                    transaction_id: Some(transaction.id),
                    montant_constate: Some(notification.montant_unites),
                    montant_attendu: Some(transaction.montant_unites),
                    devise: Some(notification.devise.clone()),
                    ..Anomalie::default()
                },
                maintenant,
            )
            .await?;
            tx.commit().await?;
            // La transaction reste OUVERTE : le client peut encore payer le bon
            // montant, et l'échéance fera son travail sinon. Rien n'est
            // confirmé, rien n'est fermé.
            return Ok(ResultatWebhook::ignore(motifs::DIVERGENCE));
        }
    }

    let moyen = notification.moyen.unwrap_or(MoyenPaiement::Inconnu);

    match notification.issue {
        // `EnCours` n'est pas un échec : le traiter comme tel annulerait des
        // commandes payées.
        IssuePaiement::EnCours => {
            tx.commit().await?;
            Ok(ResultatWebhook::ignore(motifs::EN_COURS))
        }

        // ── 5a. Refus d'opérateur, ou renoncement du payeur (FR-026) ──────
        //
        // La session **vit encore** : le client réessaie sur le même accès tant
        // que l'échéance n'est pas franchie. La commande n'est pas touchée.
        IssuePaiement::Echoue | IssuePaiement::Annule => {
            let motif_cle = if notification.issue == IssuePaiement::Echoue {
                motifs_echec::REFUS_OPERATEUR
            } else {
                motifs_echec::ANNULE_PAR_PAYEUR
            };
            echouer(depot, tx, &transaction, moyen, motif_cle, maintenant).await
        }

        IssuePaiement::Reussi => {
            // ── 5b. Succès APRÈS l'expiration (R8, FR-036 → FR-038) ───────
            if transaction.etat == EtatTransaction::Expiree {
                return hors_delai(depot, tx, &transaction, moyen, &notification, maintenant).await;
            }

            // ── 5c. Chemin nominal ────────────────────────────────────────
            if verifier_transition(transaction.etat, EtatTransaction::Reglee).is_err() {
                // Une seconde notification de succès sur une session déjà
                // réglée est le cas NORMAL d'un fournisseur qui retente avec un
                // contenu légèrement différent : elle ne doit pas produire
                // d'erreur, seulement rester sans effet.
                tx.commit().await?;
                return Ok(ResultatWebhook::ignore(motifs::ETAT_INCOMPATIBLE));
            }
            confirmer_transaction(
                depot,
                commandes,
                tx,
                &transaction,
                moyen,
                Some(&notification.reference_fournisseur),
                maintenant,
            )
            .await?;
            Ok(ResultatWebhook::traite())
        }
    }
}

/// La divergence constatée, s'il y en a une.
///
/// La **devise** est comparée avant le montant : 12 500 XOF et 12 500 EUR ont
/// le même nombre et ne sont pas le même argent. Comparer les montants d'abord
/// laisserait passer le second cas.
fn divergence(transaction: &Transaction, notification: &Notification) -> Option<TypeDossier> {
    if !notification
        .devise
        .eq_ignore_ascii_case(&transaction.devise)
    {
        return Some(TypeDossier::DeviseDivergente);
    }
    if notification.montant_unites != transaction.montant_unites {
        return Some(TypeDossier::MontantDivergent);
    }
    None
}

/// Règle une transaction et confirme sa commande — le chemin **partagé**.
///
/// Deux sources y mènent : une notification signée de succès (ce module) et une
/// **réconciliation** qui rattrape un webhook perdu ([`crate::expiration`]).
/// Elles doivent produire exactement le même effet — état, événement, ordre des
/// commits —, sinon un paiement rattrapé ne vaudrait pas tout à fait un
/// paiement notifié, et l'écart ne se verrait qu'au rapprochement des comptes.
///
/// La transaction SQL est **reçue ouverte** et fermée ici : l'appelant y a déjà
/// verrouillé la ligne, et l'événement doit y entrer avec le changement d'état.
pub(crate) async fn confirmer_transaction(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    mut tx: sqlx::PgTransaction<'_>,
    transaction: &Transaction,
    moyen: MoyenPaiement,
    reference_fournisseur: Option<&str>,
    maintenant: DateTime<Utc>,
) -> Result<(), ErreurPaiements> {
    depot
        .changer_etat_transaction(
            &mut tx,
            transaction.id,
            EtatTransaction::Reglee,
            Some(moyen),
            reference_fournisseur,
            maintenant,
        )
        .await?;

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

    // La commande, APRÈS — voir l'en-tête du module.
    confirmer_la_commande(commandes, transaction.commande_id, maintenant).await
}

/// Refus d'opérateur : la session **survit**, la commande n'est pas touchée.
async fn echouer(
    depot: &PgPaiements,
    mut tx: sqlx::PgTransaction<'_>,
    transaction: &Transaction,
    moyen: MoyenPaiement,
    motif_cle: &str,
    maintenant: DateTime<Utc>,
) -> Result<ResultatWebhook, ErreurPaiements> {
    if verifier_transition(transaction.etat, EtatTransaction::Echouee).is_err() {
        tx.commit().await?;
        return Ok(ResultatWebhook::ignore(motifs::ETAT_INCOMPATIBLE));
    }

    depot
        .changer_etat_transaction(
            &mut tx,
            transaction.id,
            EtatTransaction::Echouee,
            Some(moyen),
            None,
            maintenant,
        )
        .await?;
    socle::ecrire_evenement(
        &mut tx,
        NouvelEvenement {
            type_evenement: "paiement.echoue",
            entite_type: "transaction",
            entite_id: transaction.id,
            payload: json!({
                "commande": transaction.commande_id,
                "motif_cle": motif_cle,
                "moyen": moyen.comme_str(),
            }),
            survenu_le: maintenant,
        },
    )
    .await?;
    tx.commit().await?;
    Ok(ResultatWebhook::traite())
}

/// Succès arrivé **après** l'échéance (R8, FR-036 → FR-038).
///
/// La commande n'est **pas** ressuscitée : elle est annulée depuis le balayage,
/// et un vendeur qui a rangé sa marchandise ne la ressort pas parce qu'un
/// paiement est arrivé en retard. Un dossier s'ouvre, un événement part pour
/// NTF, et le remboursement relève de PAY-04 — qui n'est pas construit.
async fn hors_delai(
    depot: &PgPaiements,
    mut tx: sqlx::PgTransaction<'_>,
    transaction: &Transaction,
    moyen: MoyenPaiement,
    notification: &Notification,
    maintenant: DateTime<Utc>,
) -> Result<ResultatWebhook, ErreurPaiements> {
    verifier_transition(transaction.etat, EtatTransaction::PayeeHorsDelai)?;

    depot
        .changer_etat_transaction(
            &mut tx,
            transaction.id,
            EtatTransaction::PayeeHorsDelai,
            Some(moyen),
            Some(&notification.reference_fournisseur),
            maintenant,
        )
        .await?;

    dossier::ouvrir(
        depot,
        &mut tx,
        TypeDossier::PaiementHorsDelai,
        Anomalie {
            commande_id: Some(transaction.commande_id),
            transaction_id: Some(transaction.id),
            montant_constate: Some(notification.montant_unites),
            montant_attendu: Some(transaction.montant_unites),
            devise: Some(transaction.devise.clone()),
            ..Anomalie::default()
        },
        maintenant,
    )
    .await?;

    // `retard_s` compte depuis l'ÉCHÉANCE, pas depuis l'ouverture : c'est de
    // combien le paiement a manqué le rendez-vous, et c'est ce chiffre que NTF
    // et l'exploitation regardent.
    let retard_s = (maintenant - transaction.expire_le).num_seconds().max(0);
    socle::ecrire_evenement(
        &mut tx,
        NouvelEvenement {
            type_evenement: "paiement.hors_delai",
            entite_type: "transaction",
            entite_id: transaction.id,
            payload: json!({
                "commande": transaction.commande_id,
                "montant": transaction.montant_unites,
                "devise": transaction.devise,
                "retard_s": retard_s,
            }),
            survenu_le: maintenant,
        },
    )
    .await?;
    tx.commit().await?;

    tracing::warn!(
        transaction = %transaction.id,
        commande = %transaction.commande_id,
        retard_s,
        "PAIEMENT HORS DÉLAI — la commande reste annulée, un dossier est ouvert \
         (le remboursement relève de PAY-04, non construit)",
    );
    Ok(ResultatWebhook::traite())
}

/// Notification qui ne désigne aucune transaction de chez nous (FR-082).
///
/// Ce n'est pas forcément une attaque : un environnement de recette pointant la
/// production, ou une référence d'un autre marchand, produisent le même effet.
/// Dans tous les cas l'argent est quelque part et il faut le voir.
async fn orpheline(
    depot: &PgPaiements,
    mut tx: sqlx::PgTransaction<'_>,
    notification: &Notification,
    maintenant: DateTime<Utc>,
) -> Result<ResultatWebhook, ErreurPaiements> {
    dossier::ouvrir(
        depot,
        &mut tx,
        TypeDossier::TransactionOrpheline,
        Anomalie {
            montant_constate: Some(notification.montant_unites),
            devise: Some(notification.devise.clone()),
            ..Anomalie::default()
        },
        maintenant,
    )
    .await?;
    tx.commit().await?;
    Ok(ResultatWebhook::ignore(motifs::ORPHELINE))
}

/// Écrit la trace d'un refus de signature (FR-020).
///
/// **Sans le corps**, et sans rien d'autre. Ce qui est écrit : le fournisseur
/// visé, l'empreinte de la charge, l'instant. Ce qui ne l'est jamais : le corps
/// reçu, la signature présentée — les journaux d'une surface publique ne sont
/// pas un endroit où déposer ce qu'un attaquant a envoyé.
///
/// L'empreinte entrant dans la clé d'unicité, cent tentatives portant le **même
/// corps** ne laissent qu'une ligne : c'est voulu, et c'est ce qui empêche
/// d'inonder la table depuis l'extérieur. Cent tentatives de corps différents —
/// le cas d'un attaquant qui sonde — en laissent cent.
async fn tracer_refus(
    depot: &PgPaiements,
    fournisseur: &dyn PaymentProvider,
    corps: &[u8],
    maintenant: DateTime<Utc>,
) -> Result<(), ErreurPaiements> {
    let mut tx = depot.pool().begin().await?;
    depot
        .enregistrer_notification(
            &mut tx,
            fournisseur.nom(),
            REFERENCE_NON_VERIFIEE,
            &empreinte(corps),
            None,
            false,
            ISSUE_REFUSEE,
            None,
            None,
            maintenant,
        )
        .await?;
    tx.commit().await?;

    tracing::warn!(
        fournisseur = fournisseur.nom(),
        octets = corps.len(),
        "notification REFUSÉE : signature absente, invalide ou périmée",
    );
    Ok(())
}

/// Confirme la commande, et **journalise fort** si elle résiste.
///
/// À ce point, l'argent est encaissé et la transaction est `reglee` : un échec
/// ici ne doit ni faire répondre une erreur au fournisseur (il retenterait, et
/// le rejeu serait avalé par l'idempotence sans jamais rattraper la commande),
/// ni passer inaperçu.
async fn confirmer_la_commande(
    commandes: &dyn CommandesAPayer,
    commande: Uuid,
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
pub fn recue_le(depot: &PgPaiements) -> DateTime<Utc> {
    depot.maintenant()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn transaction(devise: &str, montant: i64) -> Transaction {
        let ouverte = Utc::now();
        Transaction {
            id: Uuid::now_v7(),
            commande_id: Uuid::now_v7(),
            montant_unites: montant,
            devise: devise.to_owned(),
            etat: EtatTransaction::Ouverte,
            moyen: MoyenPaiement::Inconnu,
            fournisseur: "simule".to_owned(),
            reference_fournisseur: Some("ref".to_owned()),
            acces_paiement: None,
            ouverte_le: ouverte,
            expire_le: ouverte + chrono::Duration::seconds(900),
            issue_le: None,
        }
    }

    fn notification(devise: &str, montant: i64) -> Notification {
        Notification {
            reference_fournisseur: "ref".to_owned(),
            reference_marchande: None,
            issue: IssuePaiement::Reussi,
            montant_unites: montant,
            devise: devise.to_owned(),
            moyen: None,
            survenu_le: Utc::now(),
            empreinte_charge: "abc".to_owned(),
        }
    }

    /// Le cas nominal : mêmes chiffres, aucune divergence.
    #[test]
    fn aucune_divergence_sur_un_paiement_conforme() {
        assert!(divergence(&transaction("XOF", 12_500), &notification("XOF", 12_500)).is_none());
    }

    /// FR-024 — un montant différent n'est **pas** une confirmation.
    #[test]
    fn un_montant_different_est_une_divergence() {
        assert_eq!(
            divergence(&transaction("XOF", 12_500), &notification("XOF", 1)),
            Some(TypeDossier::MontantDivergent),
        );
        assert_eq!(
            divergence(&transaction("XOF", 12_500), &notification("XOF", 12_501)),
            Some(TypeDossier::MontantDivergent),
            "une unité mineure d'écart reste une divergence",
        );
    }

    /// **La devise d'abord.** 12 500 XOF et 12 500 EUR portent le même nombre
    /// et ne sont pas le même argent : comparer les montants en premier
    /// laisserait passer un encaissement en euros pour une commande en francs.
    #[test]
    fn la_devise_est_comparee_avant_le_montant() {
        assert_eq!(
            divergence(&transaction("XOF", 12_500), &notification("EUR", 12_500)),
            Some(TypeDossier::DeviseDivergente),
        );
    }

    /// La casse de la devise ne fait pas une divergence : ISO 4217 s'écrit en
    /// majuscules, mais un fournisseur qui renvoie « xof » n'a pas encaissé
    /// autre chose.
    #[test]
    fn la_casse_de_la_devise_ne_compte_pas() {
        assert!(divergence(&transaction("XOF", 12_500), &notification("xof", 12_500)).is_none());
    }

    /// Les motifs d'échec sont des CLÉS i18n, jamais des phrases.
    #[test]
    fn les_motifs_d_echec_sont_des_cles() {
        for cle in [
            motifs_echec::REFUS_OPERATEUR,
            motifs_echec::ANNULE_PAR_PAYEUR,
        ] {
            assert!(
                cle.starts_with("paiement.echec."),
                "clé mal préfixée : {cle}"
            );
            assert!(!cle.contains(' '), "une clé n'est pas une phrase : {cle}");
        }
    }

    /// Un résultat « ignoré » porte toujours son motif ; un résultat « traité »
    /// n'en porte jamais. C'est ce que l'app et le fournisseur lisent.
    #[test]
    fn un_resultat_ignore_porte_toujours_son_motif() {
        assert_eq!(ResultatWebhook::traite().motif, None);
        for motif in [
            motifs::REJEU,
            motifs::EN_COURS,
            motifs::ORPHELINE,
            motifs::ETAT_INCOMPATIBLE,
            motifs::DIVERGENCE,
        ] {
            let r = ResultatWebhook::ignore(motif);
            assert!(!r.traite);
            assert_eq!(r.motif, Some(motif));
        }
    }
}
