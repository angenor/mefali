//! Ouverture d'une session de prépaiement — **idempotente par la base**.
//!
//! C'est le premier chemin d'argent du cycle : une commande née
//! `en_attente_paiement` (au-dessus du plafond cash, ou basculée par le
//! dispatch) trouve ici un moyen d'être payée.
//!
//! # L'ordre des opérations, et pourquoi c'est celui-là
//!
//! ```text
//!   1. lire la commande        (total FIGÉ, propriétaire, état)
//!   2. garder                  (propriété, « attend-elle un paiement ? »)
//!   3. session vivante ?       → la RENVOYER telle quelle, sans rien rouvrir
//!   4. poser `en_attente`      (le trou que R16 laissait sur la bascule DSP)
//!   5. create_checkout         ← HORS de toute transaction SQL (research R2)
//!   6. INSERT + événement      ← dans la MÊME transaction (constitution VI)
//! ```
//!
//! **5 avant 6, et non l'inverse.** Un appel HTTP sortant à l'intérieur d'une
//! transaction SQL tiendrait un verrou pendant toute la latence d'un tiers : sur
//! un agrégateur lent, la base garderait des transactions ouvertes plusieurs
//! secondes, et la première rafale de commandes épuiserait le pool.
//!
//! **6 sous contrainte, et non sous `if`.** L'unicité d'une session vivante est
//! portée par l'index partiel `transaction_vivante_unique` (migration 0021).
//! Deux requêtes concurrentes passeraient toutes deux une vérification
//! préalable ; elles ne passent pas toutes deux un `INSERT`. Le perdant relit et
//! renvoie la session du gagnant — c'est exactement ce que FR-015 demande.
//!
//! # Ce qui se passe quand le fournisseur tombe
//!
//! Rien n'est écrit. Aucune ligne de transaction, aucun événement : la commande
//! reste **intacte**, exactement dans l'état où l'appelant l'a trouvée (FR-018).
//! C'est la conséquence directe de l'ordre ci-dessus — l'écriture vient après
//! l'appel réseau, donc un échec réseau n'a rien à défaire.

use chrono::{DateTime, Duration, Utc};
use serde_json::json;
use socle::NouvelEvenement;
use uuid::Uuid;

use commandes::{CommandeAPayer, CommandesAPayer};

use crate::config::ConfigPaiements;
use crate::depot::PgPaiements;
use crate::fournisseur::{DemandeCheckout, PaymentProvider};
use crate::modele::{ErreurPaiements, EtatTransaction, MoyenPaiement, Transaction};

/// Clé i18n de la description montrée au payeur sur la page du fournisseur.
///
/// Jamais une phrase en dur : le libellé est résolu côté affichage, et ce crate
/// ne connaît aucune langue (constitution VII).
pub const DESCRIPTION_CLE: &str = "paiement.description.commande";

/// Lien de retour après succès — **informatif, il ne crédite RIEN** (FR-025).
///
/// Le seul fait qui confirme un paiement est une notification signée, ou une
/// réconciliation auprès du fournisseur. Un client qui revient par ce lien voit
/// l'état que le serveur connaît, pas celui que le navigateur affirme.
pub fn retour_succes(commande: Uuid) -> String {
    format!("mefali://commandes/{commande}/paiement?issue=succes")
}

/// Lien de retour après renoncement. Même statut : informatif.
pub fn retour_annulation(commande: Uuid) -> String {
    format!("mefali://commandes/{commande}/paiement?issue=annulation")
}

/// Échéance d'une session, depuis `paiement.session_duree_s`.
///
/// Isolée pour être testable sans base : c'est la seule arithmétique de temps
/// du module, et elle décide de la durée de vie d'une commande.
pub fn echeance(ouverte_le: DateTime<Utc>, config: &ConfigPaiements) -> DateTime<Utc> {
    ouverte_le + Duration::seconds(config.session_duree_s)
}

/// Les deux gardes de l'ouverture, isolées pour être testables sans base.
///
/// **Propriété d'abord, état ensuite.** L'ordre importe : répondre
/// `paiement_non_requis` à quelqu'un qui n'est pas propriétaire lui apprendrait
/// que la commande existe et qu'elle est déjà réglée. La garde de propriété
/// passe donc en premier, et elle rend le même refus que la commande existe ou
/// non (FR-005).
pub fn garder_ouverture(
    commande: &CommandeAPayer,
    appelant: Uuid,
) -> Result<(), ErreurPaiements> {
    if commande.client_id != appelant {
        return Err(ErreurPaiements::CommandeNonProprietaire);
    }
    if !commande.attend_un_paiement() {
        return Err(ErreurPaiements::PaiementNonRequis);
    }
    if commande.total_unites <= 0 {
        // La contrainte `montant_unites > 0` le refuserait de toute façon ;
        // le dire ici rend le refus lisible plutôt qu'une erreur de base.
        return Err(ErreurPaiements::DemandeInvalide(
            "total de commande nul : rien à encaisser",
        ));
    }
    Ok(())
}

/// Ouvre **ou renvoie** la session de prépaiement d'une commande (FR-010,
/// FR-015).
///
/// Rappelée tant que la session vit, elle renvoie la **même** session sans rien
/// rouvrir chez le fournisseur : l'identifiant de commande *est* la clé
/// d'idempotence, comme au cycle 008 pour la création.
pub async fn ouvrir_session(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    fournisseur: &dyn PaymentProvider,
    commande_id: Uuid,
    appelant: Uuid,
) -> Result<Transaction, ErreurPaiements> {
    let commande = commandes.a_payer(commande_id).await?;
    garder_ouverture(&commande, appelant)?;

    // Une session vivante est rendue TELLE QUELLE. Aucun appel sortant, aucune
    // écriture : c'est ce qui rend le rappel gratuit, et donc sûr à retenter
    // depuis une app dont la connexion vacille.
    if let Some(vivante) = depot.transaction_vivante(commande_id).await? {
        return Ok(vivante);
    }

    let config = depot.config(commande.zone_id).await?;
    let maintenant = depot.maintenant();

    // Le trou de R16, comblé à l'endroit où il compte : une commande basculée
    // par le dispatch reste à `'du'` jusqu'ici, indiscernable d'une commande
    // cash pour toute lecture d'`etat_paiement`. L'appel est idempotent.
    commandes
        .marquer_paiement_en_attente(commande_id, maintenant)
        .await?;

    let transaction_id = Uuid::now_v7();
    let expire_le = echeance(maintenant, &config);

    // ── HORS transaction SQL (research R2) ────────────────────────────────
    let checkout = fournisseur
        .create_checkout(DemandeCheckout {
            reference_marchande: transaction_id,
            montant_unites: commande.total_unites,
            devise: commande.devise.clone(),
            description_cle: DESCRIPTION_CLE,
            retour_succes: retour_succes(commande_id),
            retour_annulation: retour_annulation(commande_id),
        })
        .await?;

    let mut tx = depot.pool().begin().await?;
    let insertion = depot
        .inserer_transaction(
            &mut tx,
            transaction_id,
            commande_id,
            commande.total_unites,
            &commande.devise,
            fournisseur.nom(),
            Some(&checkout.reference_fournisseur),
            Some(&checkout.acces_paiement),
            maintenant,
            expire_le,
        )
        .await;

    if let Err(erreur) = insertion {
        if !est_violation_unicite(&erreur) {
            return Err(erreur);
        }
        // Course perdue : une autre requête a ouvert la session entre notre
        // lecture et notre écriture. La base a tranché ; nous renvoyons SA
        // session plutôt que d'en imposer une seconde (FR-015).
        drop(tx);
        tracing::info!(
            commande = %commande_id,
            "ouverture concurrente : la session du gagnant est renvoyée",
        );
        return depot
            .transaction_vivante(commande_id)
            .await?
            .ok_or(ErreurPaiements::TransactionInconnue);
    }

    // ⚠ Ni `acces_paiement` ni la référence du fournisseur n'entrent dans la
    // charge utile : un événement outbox est relu, exporté, archivé — une URL
    // d'encaissement n'a rien à y faire (FR-006, FR-103).
    socle::ecrire_evenement(
        &mut tx,
        NouvelEvenement {
            type_evenement: "paiement.session_ouverte",
            entite_type: "transaction",
            entite_id: transaction_id,
            payload: json!({
                "commande": commande_id,
                "montant": commande.total_unites,
                "devise": commande.devise,
                "fournisseur": fournisseur.nom(),
                "expire_le": expire_le,
            }),
            survenu_le: maintenant,
        },
    )
    .await?;
    tx.commit().await?;

    Ok(Transaction {
        id: transaction_id,
        commande_id,
        montant_unites: commande.total_unites,
        devise: commande.devise,
        etat: EtatTransaction::Ouverte,
        moyen: MoyenPaiement::Inconnu,
        fournisseur: fournisseur.nom().to_owned(),
        reference_fournisseur: Some(checkout.reference_fournisseur),
        acces_paiement: Some(checkout.acces_paiement),
        ouverte_le: maintenant,
        expire_le,
        issue_le: None,
    })
}

/// État courant de la session d'une commande, pour la lecture du client.
///
/// Rend la **dernière** transaction quel que soit son état : après une
/// expiration, le client doit lire « expirée » plutôt qu'un `404` qui lui
/// laisserait croire qu'il n'a jamais rien tenté.
pub async fn lire_session(
    depot: &PgPaiements,
    commandes: &dyn CommandesAPayer,
    commande_id: Uuid,
    appelant: Uuid,
) -> Result<Transaction, ErreurPaiements> {
    let commande = commandes.a_payer(commande_id).await?;
    if commande.client_id != appelant {
        return Err(ErreurPaiements::CommandeNonProprietaire);
    }
    depot
        .derniere_transaction(commande_id)
        .await?
        // Aucune transaction = commande cash : il n'y a rien à lire, et c'est
        // un `404`, pas une erreur.
        .ok_or(ErreurPaiements::TransactionInconnue)
}

/// Vrai si l'erreur est la violation de `transaction_vivante_unique`.
///
/// Distinguer cette violation d'une autre panne SQL est ce qui sépare « une
/// autre requête a gagné la course, tout va bien » de « la base est en
/// difficulté » — deux situations qui ne se répondent pas de la même façon.
fn est_violation_unicite(erreur: &ErreurPaiements) -> bool {
    matches!(
        erreur,
        ErreurPaiements::Sql(sqlx::Error::Database(db)) if db.is_unique_violation()
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use commandes::{CommandesAPayerEnMemoire, EtatCommande, EtatPaiement, ModePaiement};

    fn config(duree_s: i64) -> ConfigPaiements {
        ConfigPaiements {
            zone: Uuid::now_v7(),
            devise: "XOF".to_owned(),
            session_duree_s: duree_s,
            reconciliation_avant_expiration_s: 60,
            creance_alerte_unites: 50_000,
            moyens_actifs: vec![],
        }
    }

    /// L'échéance vient du PARAMÈTRE DE ZONE, jamais d'une constante — sans
    /// quoi la faire bouger demanderait un déploiement (FR-100).
    #[test]
    fn l_echeance_suit_le_parametre_de_zone() {
        let ouverte = Utc::now();
        assert_eq!(
            echeance(ouverte, &config(900)) - ouverte,
            Duration::seconds(900),
        );
        assert_eq!(
            echeance(ouverte, &config(300)) - ouverte,
            Duration::seconds(300),
            "changer le paramètre change l'échéance, et rien d'autre",
        );
    }

    /// La garde de PROPRIÉTÉ passe avant celle d'état : répondre
    /// « déjà réglée » à un inconnu lui apprendrait que la commande existe.
    #[test]
    fn la_propriete_est_gardee_avant_l_etat() {
        let commandes = CommandesAPayerEnMemoire::nouveau();
        let client = Uuid::now_v7();
        let mut commande = commandes.ajouter_prepayable(Uuid::now_v7(), client, 12_500);
        commande.etat_paiement = EtatPaiement::Regle;

        let e = garder_ouverture(&commande, Uuid::now_v7()).unwrap_err();
        assert_eq!(
            e.message_cle(),
            Some("commande_interdite"),
            "un tiers reçoit le MÊME refus, réglée ou non",
        );
    }

    /// Les trois cas de `409 paiement_non_requis` (contrat §1.1).
    #[test]
    fn les_trois_cas_de_paiement_non_requis() {
        let commandes = CommandesAPayerEnMemoire::nouveau();
        let client = Uuid::now_v7();
        let nominale = commandes.ajouter_prepayable(Uuid::now_v7(), client, 12_500);
        garder_ouverture(&nominale, client).expect("le cas nominal passe");

        // 1. Commande CASH — elle ne passe par aucun fournisseur.
        let mut cash = nominale.clone();
        cash.mode_paiement = ModePaiement::Cash;
        assert_eq!(
            garder_ouverture(&cash, client).unwrap_err().message_cle(),
            Some("paiement_non_requis"),
        );

        // 2. Déjà réglée — on ne paie pas deux fois.
        let mut reglee = nominale.clone();
        reglee.etat_paiement = EtatPaiement::Regle;
        assert_eq!(
            garder_ouverture(&reglee, client).unwrap_err().message_cle(),
            Some("paiement_non_requis"),
        );

        // 3. Le tronc n'attend plus rien (annulée, ou déjà partie).
        let mut annulee = nominale.clone();
        annulee.etat = EtatCommande::Annulee;
        assert_eq!(
            garder_ouverture(&annulee, client).unwrap_err().message_cle(),
            Some("paiement_non_requis"),
        );
    }

    /// Un total nul est refusé comme une DEMANDE invalide, pas comme une panne
    /// de base : la contrainte `montant_unites > 0` le rejetterait, mais avec
    /// un 500 qui n'apprendrait rien à personne.
    #[test]
    fn un_total_nul_est_refuse_lisiblement() {
        let commandes = CommandesAPayerEnMemoire::nouveau();
        let client = Uuid::now_v7();
        let mut commande = commandes.ajouter_prepayable(Uuid::now_v7(), client, 12_500);
        commande.total_unites = 0;
        assert_eq!(
            garder_ouverture(&commande, client)
                .unwrap_err()
                .message_cle(),
            Some("demande_invalide"),
        );
    }

    /// Les liens de retour portent la commande et **rien d'autre** : ni jeton,
    /// ni référence de fournisseur. Ils sont informatifs (FR-025), donc leur
    /// contenu ne doit jamais devenir une preuve de paiement.
    #[test]
    fn les_liens_de_retour_ne_portent_aucun_secret() {
        let commande = Uuid::now_v7();
        for lien in [retour_succes(commande), retour_annulation(commande)] {
            assert!(lien.contains(&commande.to_string()));
            assert!(lien.starts_with("mefali://"), "deep link d'app, pas une URL web");
        }
        assert_ne!(retour_succes(commande), retour_annulation(commande));
    }
}
