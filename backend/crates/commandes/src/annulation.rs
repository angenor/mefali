//! Annulations (CMD-07) : sans frais avant tout achat, règles d'échec au-delà.
//!
//! La frontière est **un fait, pas un délai** : tant qu'aucun arrêt n'a été
//! collecté, personne n'a avancé d'argent — l'annulation ne coûte rien à
//! personne, et il n'y a donc rien à facturer (FR-052). Dès le premier arrêt
//! collecté, le coursier a payé de sa poche chez un vendeur : sa part est due,
//! et l'annulation bascule sur les règles d'échec (CMD-08).
//!
//! Choisir un fait plutôt qu'un chronomètre évite la seule discussion qui
//! n'aurait pas de réponse — « il était où à 14 h 32 ? ». La base sait ce qui a
//! été collecté ; elle ne saura jamais arbitrer une minute.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::NouvelEvenement;
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::etats::Acteur;
use crate::modele::{ErreurCommandes, EtatCommande, EtatLivraison, EtatPaiement};

/// Qui annule. L'acteur décide de ce qui est EXIGÉ : un admin doit motiver son
/// geste (FR-054), un client n'a pas à se justifier.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuteurAnnulation {
    /// Le client propriétaire.
    Client,
    /// Un administrateur — **motif obligatoire**, journalisé.
    Admin,
    /// Le système, sans acteur humain (cycle PAY 011, FR-031).
    ///
    /// La taxonomie déclarait cette valeur (`par: client | admin | systeme`)
    /// depuis le cycle 008 et **aucune ligne de code ne l'écrivait** : rien
    /// n'annulait automatiquement. L'expiration d'une session de paiement est
    /// le premier cas — et elle **réutilise ce chemin**, sans seconde règle
    /// d'annulation (FR-032). Une seconde règle aurait divergé de la première
    /// au premier correctif, et l'une des deux aurait cessé de rembourser.
    ///
    /// Son motif est **toujours fourni** par l'appelant : un geste sans humain
    /// doit dire pourquoi encore plus clairement qu'un geste humain, puisque
    /// personne ne pourra l'expliquer après coup.
    Systeme,
}

impl AuteurAnnulation {
    /// Valeur journalisée dans le payload `commande.annulee`.
    pub fn comme_str(self) -> &'static str {
        match self {
            AuteurAnnulation::Client => "client",
            AuteurAnnulation::Admin => "admin",
            AuteurAnnulation::Systeme => "systeme",
        }
    }

    /// Acteur de la machine à états.
    fn acteur(self) -> Acteur {
        match self {
            AuteurAnnulation::Client => Acteur::Client,
            AuteurAnnulation::Admin => Acteur::Admin,
            AuteurAnnulation::Systeme => Acteur::Systeme,
        }
    }
}

/// Ce qu'une annulation a produit — de quoi expliquer au client, et de quoi
/// alimenter la caisse quand CRS-06 existera.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AnnulationFaite {
    /// Commande annulée.
    pub commande_id: Uuid,
    /// Vrai si rien n'avait encore été acheté (FR-052).
    pub sans_frais: bool,
    /// Part due au coursier (unités mineures) — 0 si sans frais.
    pub part_coursier_due: i64,
    /// Montant déjà avancé par le coursier chez les vendeurs.
    pub montant_avance: i64,
    /// Vrai si la commande était prépayée : un remboursement est DÛ.
    pub remboursement_du: bool,
    /// Devise ISO 4217.
    pub devise: String,
}

impl PgCommandes {
    /// Annule une commande (CMD-07).
    ///
    /// Trois refus possibles, tous portés par la table de transitions plutôt
    /// que par des `if` empilés :
    /// - un état **terminal** (livrée, déjà annulée, échouée) n'a aucune
    ///   transition sortante — `409` ;
    /// - un **non-propriétaire** ne voit pas la commande — `404`, jamais `403` :
    ///   un identifiant deviné ne doit rien révéler ;
    /// - un **admin sans motif** est refusé — `422` (FR-054).
    ///
    /// La livraison suit le tronc dans la MÊME transaction : laisser une
    /// livraison `en_collecte` sous une commande `annulee` produirait une
    /// course fantôme dans l'app du coursier.
    pub async fn annuler_commande(
        &self,
        commande_id: Uuid,
        auteur: AuteurAnnulation,
        acteur_id: Uuid,
        motif_cle: Option<&str>,
        maintenant: DateTime<Utc>,
    ) -> Result<AnnulationFaite, ErreurCommandes> {
        // FR-054 — un admin qui annule la commande de quelqu'un doit dire
        // pourquoi. Le motif est une CLÉ i18n, jamais du texte libre : il sera
        // lu par le client, dans sa langue.
        //
        // `Systeme` est traité comme `Admin` : un geste sans humain doit dire
        // pourquoi encore plus clairement qu'un geste humain, puisque personne
        // ne pourra l'expliquer après coup.
        let motif_cle = match (auteur, motif_cle) {
            (AuteurAnnulation::Admin | AuteurAnnulation::Systeme, None) => {
                return Err(ErreurCommandes::MotifRequis)
            }
            (AuteurAnnulation::Admin | AuteurAnnulation::Systeme, Some(m))
                if m.trim().is_empty() =>
            {
                return Err(ErreurCommandes::MotifRequis)
            }
            (_, Some(m)) => m.to_owned(),
            (AuteurAnnulation::Client, None) => "commande.annulation.client".to_owned(),
        };

        let mut tx = self.pool.begin().await?;

        let commande = sqlx::query!(
            r#"SELECT c.client_id, c.devise,
                      c.etat_paiement::text AS "etat_paiement!",
                      l.id AS "livraison_id?", l.etat::text AS "livraison_etat?",
                      l.devis_part_coursier AS "devis_part_coursier?"
               FROM commandes.commande c
               LEFT JOIN commandes.livraison l ON l.commande_id = c.id
               WHERE c.id = $1"#,
            commande_id,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        // Le client n'annule que SA commande. L'admin, lui, agit sur toutes —
        // c'est son rôle, et c'est pour cela que son motif est exigé.
        if auteur == AuteurAnnulation::Client && commande.client_id != acteur_id {
            return Err(ErreurCommandes::CommandeInconnue(commande_id));
        }

        // La frontière : un arrêt COLLECTÉ = de l'argent avancé chez un vendeur.
        let avance = sqlx::query!(
            r#"SELECT count(*) AS "collectes!",
                      COALESCE(SUM(a.montant_avance), 0)::bigint AS "montant!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE l.commande_id = $1 AND a.statut = 'collecte'"#,
            commande_id,
        )
        .fetch_one(&mut *tx)
        .await?;

        let sans_frais = avance.collectes == 0;
        // « Le coursier ne perd jamais » (cadrage §7.5) : dès qu'il a acheté,
        // sa part de devis est due, quel que soit celui qui annule. Le devis
        // est celui FIGÉ à la création — il n'est pas recalculé ici non plus.
        let part_coursier_due = if sans_frais {
            0
        } else {
            commande.devis_part_coursier.unwrap_or(0)
        };
        let remboursement_du = commande.etat_paiement == EtatPaiement::Regle.comme_str();

        // 1. Le composant logistique d'abord — sinon une course fantôme
        //    resterait dans l'app du coursier.
        if let (Some(livraison_id), Some(etat)) =
            (commande.livraison_id, commande.livraison_etat.as_deref())
        {
            // Une livraison déjà LIVRÉE, échouée ou annulée n'a pas de
            // transition vers `annulee` : la garde le dira.
            if matches!(etat, "assignee" | "en_collecte" | "en_livraison") {
                self.transition_livraison(
                    &mut tx,
                    livraison_id,
                    EtatLivraison::Annulee,
                    auteur.acteur(),
                    maintenant,
                    None,
                )
                .await?;
            }
        }

        // 2. Puis le tronc, sous la garde de la table fermée.
        self.transition_commande(
            &mut tx,
            commande_id,
            EtatCommande::Annulee,
            auteur.acteur(),
            maintenant,
            Some(NouvelEvenement {
                type_evenement: "commande.annulee",
                entite_type: "commande",
                entite_id: commande_id,
                payload: json!({
                    "par": auteur.comme_str(),
                    "motif_cle": motif_cle,
                    "sans_frais": sans_frais,
                    "part_coursier_due": part_coursier_due,
                    "remboursement_du": remboursement_du,
                    "devise": commande.devise,
                    "acteur": acteur_id,
                }),
                survenu_le: maintenant,
            }),
        )
        .await?;

        // 3. Le remboursement d'une commande PRÉPAYÉE. `rembourse` est un état
        //    de paiement, pas un mouvement de caisse : l'écriture comptable
        //    appartient à PAY, qui s'y branchera par l'événement.
        if remboursement_du {
            sqlx::query!(
                "UPDATE commandes.commande SET etat_paiement = 'rembourse' WHERE id = $1",
                commande_id,
            )
            .execute(&mut *tx)
            .await?;
        }

        // 4. Une part due au coursier est une INDEMNISATION : même contrat que
        //    l'arbre §7.5, donc même événement — CRS-06 n'aura qu'un seul
        //    consommateur à écrire, pas deux.
        if part_coursier_due > 0 {
            socle::ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "indemnisation.due",
                    entite_type: "commande",
                    entite_id: commande_id,
                    payload: json!({
                        "commande": commande_id,
                        "coursier": null,
                        "montant": part_coursier_due,
                        "devise": commande.devise,
                        "motif": "annulation_apres_achat",
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
        }

        tx.commit().await?;

        Ok(AnnulationFaite {
            commande_id,
            sans_frais,
            part_coursier_due,
            montant_avance: avance.montant,
            remboursement_du,
            devise: commande.devise,
        })
    }
}
