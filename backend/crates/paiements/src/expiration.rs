//! Balayage des sessions échues — **réconcilier, puis annuler** (FR-027, R7).
//!
//! Une commande qui attend un paiement qui n'arrivera jamais pollue tout : le
//! dispatch la voit, les métriques la comptent, le vendeur la prépare
//! peut-être. Ce module la referme.
//!
//! # Pourquoi on demande au fournisseur AVANT d'annuler
//!
//! Un webhook se perd. Il se perd pour des raisons banales — un déploiement au
//! mauvais moment, une coupure de trois secondes chez l'hébergeur, un
//! agrégateur qui retente trop tard. Si l'échéance annulait sans demander,
//! **chaque webhook perdu deviendrait un litige** : Awa aurait payé, sa
//! commande serait annulée, et il faudrait la rembourser à la main par une
//! story (PAY-04) qui n'est pas construite.
//!
//! Le coût est un appel HTTP par session échue. Le bénéfice est de ne pas
//! transformer une panne réseau en dette d'argent.
//!
//! # Le job matérialise, il n'est pas la source de vérité
//!
//! `expire_le` est **persistée** : toute lecture la respecte immédiatement,
//! sans attendre le balayage (R7). Une session échue est donc refusée par
//! `POST /commandes/{id}/paiement` même si sa ligne porte encore `ouverte`
//! parce que le job n'a pas encore tourné. Le job ne fait qu'écrire ce que la
//! lecture savait déjà.
//!
//! # Deux commits, et l'ordre qui les sépare
//!
//! Marquer la transaction `expiree` vient **avant** l'annulation de la
//! commande, pour une raison de concurrence : entre les deux, une notification
//! de succès tardive trouve une transaction `expiree` et emprunte le chemin
//! `payee_hors_delai` (R8), qui ouvre un dossier sans ressusciter la commande.
//! Dans l'ordre inverse, elle trouverait une transaction encore `ouverte` et
//! tenterait de confirmer une commande déjà annulée.
//!
//! Le prix de ce choix est nommé sans détour : si l'annulation échoue **après**
//! le commit de l'expiration, la commande reste `en_attente_paiement` avec une
//! transaction `expiree`, et le balayage suivant ne la reverra pas — il ne
//! sélectionne que les sessions `ouverte`. Ce cas est journalisé en `error`
//! avec la mention « intervention requise », comme le chemin symétrique du
//! webhook. C'est une réserve explicite du cycle, pas un oubli.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;

use commandes::CommandesAPayer;

use crate::depot::PgPaiements;
use crate::fournisseur::{IssuePaiement, PaymentProvider};
use crate::modele::{
    verifier_transition, ErreurPaiements, EtatTransaction, MoyenPaiement, Transaction,
};

/// Nombre maximal de sessions traitées par passage.
///
/// Borner le lot évite qu'un rattrapage après incident — mille sessions échues
/// d'un coup — tienne une connexion et mille appels sortants dans le même tour.
/// Le tour suivant reprend là où celui-ci s'est arrêté : l'index partiel les
/// rend les plus vieilles d'abord.
pub const LOT_MAX: i64 = 50;

/// Ce qu'un passage de balayage a fait.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct BilanBalayage {
    /// Sessions échues examinées.
    pub examinees: usize,
    /// Sessions annulées, faute de paiement.
    pub expirees: usize,
    /// Sessions **rattrapées** : le fournisseur a confirmé un paiement dont la
    /// notification s'était perdue. Chacune est une commande sauvée et un
    /// remboursement évité (FR-027).
    pub rattrapees: usize,
    /// Sessions laissées en l'état : le fournisseur n'a pas pu être interrogé.
    /// Elles seront reprises au tour suivant — **jamais annulées à l'aveugle**.
    pub reportees: usize,
}

/// Un passage de balayage.
///
/// Ne rend `Err` que sur une panne de lecture initiale : l'échec d'**une**
/// session ne doit pas empêcher les suivantes d'être traitées, sinon une seule
/// commande abîmée bloquerait la file entière.
pub async fn balayer(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    fournisseur: &dyn PaymentProvider,
) -> Result<BilanBalayage, ErreurPaiements> {
    let maintenant = depot.maintenant();
    let echues = depot.sessions_echues(maintenant, LOT_MAX).await?;

    let mut bilan = BilanBalayage {
        examinees: echues.len(),
        ..BilanBalayage::default()
    };

    for session in echues {
        match traiter_session(depot, commandes, fournisseur, &session, maintenant).await {
            Ok(Issue::Expiree) => bilan.expirees += 1,
            Ok(Issue::Rattrapee) => bilan.rattrapees += 1,
            Ok(Issue::Reportee) => bilan.reportees += 1,
            Err(e) => {
                bilan.reportees += 1;
                tracing::error!(
                    transaction = %session.id,
                    commande = %session.commande_id,
                    erreur = %e,
                    "session échue non traitée — reprise au prochain passage",
                );
            }
        }
    }

    Ok(bilan)
}

/// Ce qu'une session échue est devenue.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Issue {
    /// Annulée, sans frais.
    Expiree,
    /// Confirmée : le fournisseur avait bien encaissé.
    Rattrapee,
    /// Laissée `ouverte` — le fournisseur n'a pas répondu.
    Reportee,
}

async fn traiter_session(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    fournisseur: &dyn PaymentProvider,
    session: &Transaction,
    maintenant: DateTime<Utc>,
) -> Result<Issue, ErreurPaiements> {
    // ── 1. Demander au fournisseur (FR-027) ───────────────────────────────
    if let Some(rattrapee) =
        reconcilier(depot, commandes, fournisseur, session, maintenant).await?
    {
        return Ok(rattrapee);
    }

    // ── 2. Marquer la session expirée, et l'événement avec elle ───────────
    let mut tx = depot.pool().begin().await?;
    let Some(verrouillee) = depot.transaction_verrouillee(&mut tx, session.id).await? else {
        return Ok(Issue::Reportee);
    };
    // Sous le verrou, l'état a pu changer : une notification est arrivée entre
    // la sélection et maintenant. La table fermée tranche, et son refus est ici
    // une bonne nouvelle — il n'y a plus rien à expirer.
    if verifier_transition(verrouillee.etat, EtatTransaction::Expiree).is_err() {
        return Ok(Issue::Reportee);
    }

    depot
        .changer_etat_transaction(
            &mut tx,
            session.id,
            EtatTransaction::Expiree,
            None,
            None,
            maintenant,
        )
        .await?;

    // `duree_s` est la durée RÉELLEMENT vécue par la session, pas le paramètre
    // de zone : le balayage passe toutes les 10 s, l'écart se voit, et un
    // indicateur qui recopie sa propre consigne ne mesure rien.
    let duree_s = (maintenant - session.ouverte_le).num_seconds().max(0);
    socle::ecrire_evenement(
        &mut tx,
        NouvelEvenement {
            type_evenement: "paiement.session_expiree",
            entite_type: "transaction",
            entite_id: session.id,
            payload: json!({
                "commande": session.commande_id,
                "montant": session.montant_unites,
                "devise": session.devise,
                "duree_s": duree_s,
            }),
            survenu_le: maintenant,
        },
    )
    .await?;
    tx.commit().await?;

    // ── 3. Annuler la commande — chemin EXISTANT, motif tracé (FR-032) ────
    if let Err(e) = commandes
        .annuler_pour_expiration(session.commande_id, maintenant)
        .await
    {
        tracing::error!(
            commande = %session.commande_id,
            transaction = %session.id,
            erreur = %e,
            "SESSION EXPIRÉE, COMMANDE NON ANNULÉE — le balayage ne la reverra \
             pas (il ne sélectionne que les sessions ouvertes) : intervention \
             d'exploitation requise",
        );
        return Err(e.into());
    }

    Ok(Issue::Expiree)
}

/// Interroge le fournisseur et **confirme** si le paiement a eu lieu.
///
/// Rend `Some(Issue)` quand la session ne doit pas être annulée, `None` quand
/// le balayage peut poursuivre.
///
/// Un fournisseur injoignable rend `Some(Reportee)` : **on n'annule jamais à
/// l'aveugle**. Une panne d'agrégateur de dix minutes annulerait sinon toutes
/// les commandes en cours de paiement, y compris celles qui viennent d'être
/// réglées — c'est exactement l'incident qu'on refuse de fabriquer.
async fn reconcilier(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    fournisseur: &dyn PaymentProvider,
    session: &Transaction,
    maintenant: DateTime<Utc>,
) -> Result<Option<Issue>, ErreurPaiements> {
    let config = match config_de(depot, commandes, session).await {
        Ok(config) => config,
        // Sans configuration lisible, on ne sait pas si la réconciliation est
        // due : ne rien faire est le seul choix qui ne coûte pas d'argent.
        Err(e) => {
            tracing::warn!(
                commande = %session.commande_id, erreur = %e,
                "configuration de paiement illisible — session reportée",
            );
            return Ok(Some(Issue::Reportee));
        }
    };

    let age_s = (maintenant - session.ouverte_le).num_seconds().max(0);
    if !reconciliation_due(age_s, config) {
        // La session est échue mais trop jeune pour mériter un appel sortant :
        // le paramètre de zone existe pour arbitrer ce coût (R18).
        return Ok(None);
    }

    let Some(reference) = session.reference_fournisseur.as_deref() else {
        // Aucune référence : le `create_checkout` n'a jamais abouti. Il n'y a
        // rien à demander, et rien n'a pu être encaissé.
        return Ok(None);
    };

    let constat = match fournisseur.consulter(reference).await {
        Ok(constat) => constat,
        Err(e) => {
            tracing::warn!(
                transaction = %session.id, erreur = %e,
                "fournisseur injoignable — session NON annulée, reprise au \
                 prochain passage (FR-027)",
            );
            return Ok(Some(Issue::Reportee));
        }
    };

    if constat.issue != IssuePaiement::Reussi {
        return Ok(None);
    }

    // Le webhook s'était perdu : la commande est sauvée. On emprunte le chemin
    // de confirmation PARTAGÉ, pour que rattraper vaille exactement notifier.
    let mut tx = depot.pool().begin().await?;
    let Some(verrouillee) = depot.transaction_verrouillee(&mut tx, session.id).await? else {
        return Ok(Some(Issue::Reportee));
    };
    if verifier_transition(verrouillee.etat, EtatTransaction::Reglee).is_err() {
        return Ok(Some(Issue::Reportee));
    }

    tracing::info!(
        transaction = %session.id,
        commande = %session.commande_id,
        "paiement RATTRAPÉ par réconciliation — la notification s'était perdue",
    );
    crate::webhook::confirmer_transaction(
        depot,
        commandes,
        tx,
        &verrouillee,
        constat.moyen.unwrap_or(MoyenPaiement::Inconnu),
        Some(reference),
        maintenant,
    )
    .await?;

    Ok(Some(Issue::Rattrapee))
}

/// Vrai si une session de cet âge mérite un appel sortant avant d'être annulée.
///
/// Isolé pour être testable sans base ni réseau : c'est la seule arithmétique
/// de ce module, et elle arbitre un coût — un appel HTTP par session échue —
/// contre un risque : annuler une commande payée.
pub fn reconciliation_due(age_s: i64, fenetre_s: i64) -> bool {
    age_s >= fenetre_s
}

/// Âge à partir duquel la réconciliation est due, pour la zone de la commande.
async fn config_de(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    session: &Transaction,
) -> Result<i64, ErreurPaiements> {
    let commande = commandes.a_payer(session.commande_id).await?;
    Ok(depot
        .config(commande.zone_id)
        .await?
        .reconciliation_avant_expiration_s)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// La fenêtre de réconciliation est **inclusive** : une session dont l'âge
    /// atteint exactement le seuil est interrogée.
    ///
    /// Le sens du test est celui du risque : se tromper vers le bas coûte un
    /// appel HTTP, se tromper vers le haut coûte une commande payée annulée.
    /// L'inclusion penche donc du bon côté.
    #[test]
    fn la_fenetre_de_reconciliation_est_inclusive() {
        assert!(!reconciliation_due(59, 60), "trop jeune : aucun appel");
        assert!(reconciliation_due(60, 60), "au seuil : on demande");
        assert!(reconciliation_due(900, 60));
    }

    /// Une fenêtre à zéro fait interroger le fournisseur pour **toute** session
    /// échue — la configuration la plus prudente, et une valeur légale (la
    /// garde de `ConfigPaiements` n'interdit que le négatif).
    #[test]
    fn une_fenetre_nulle_interroge_toujours() {
        assert!(reconciliation_due(0, 0));
    }

    /// Le lot est borné : un rattrapage après incident ne tient pas mille
    /// appels sortants dans le même tour.
    #[test]
    fn le_lot_est_borne() {
        assert!(LOT_MAX > 0 && LOT_MAX <= 100, "lot = {LOT_MAX}");
    }

    /// Un bilan neuf ne prétend rien avoir fait — la trace du job en dépend.
    #[test]
    fn un_bilan_neuf_est_vide() {
        let b = BilanBalayage::default();
        assert_eq!((b.examinees, b.expirees, b.rattrapees, b.reportees), (0, 0, 0, 0));
    }
}
