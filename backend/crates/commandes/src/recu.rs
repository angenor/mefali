//! Reçus — **des lectures, jamais des tables** (research R15, PAY T058/T059).
//!
//! Deux reçus, un seul jeu de chiffres :
//!
//! - le **client** voit ce qu'il a commandé, ce qui en est sorti, les frais, la
//!   retenue le cas échéant, et ce qu'il lui reste à remettre au coursier ;
//! - le **vendeur** voit, pour un arrêt collecté, les trois montants qui font
//!   son versement : articles, retenue, net.
//!
//! # Pourquoi aucune table `recu`
//!
//! FR-072 : « aucun recalcul, aucune estimation ». Les montants sont **déjà**
//! figés et **déjà** écrits — prix verrouillés à la création, devis figé sur la
//! livraison, retenue posée au scan. Les recopier dans une table de reçus
//! créerait une troisième copie à maintenir cohérente, et la première divergence
//! serait invisible : deux écrans afficheraient deux vérités sans que rien
//! n'échoue. Une table ne se justifierait que pour un document légal horodaté et
//! immuable, ce que le MVP ne demande pas.
//!
//! # Les lignes retirées comptent pour zéro, et sont quand même là
//!
//! Une ligne retirée apparaît avec son statut, **hors des montants**. Le reçu
//! explique ainsi pourquoi le total a bougé, plutôt que de le faire bouger en
//! silence — c'est la différence entre « on m'a volé 500 F » et « l'igname
//! n'était plus disponible ».

use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::modele::ErreurCommandes;

/// Une ligne de commande, telle qu'un reçu la présente.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LigneRecu {
    /// Libellé de l'article — celui du catalogue au moment du figeage, ou celui
    /// du remplaçant si un remplacement a été accepté.
    pub libelle: String,
    /// Quantité commandée.
    pub quantite: i16,
    /// Prix unitaire **verrouillé** (unités mineures).
    pub prix_unitaire_unites: i64,
    /// `presente` | `remplacee` | `retiree`.
    pub statut: String,
    /// Sous-total de la ligne — `0` si elle est retirée.
    pub sous_total_unites: i64,
}

/// Reçu CLIENT d'une commande (contrats §1.3).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RecuCommande {
    /// Commande.
    pub commande_id: Uuid,
    /// Devise ISO 4217.
    pub devise: String,
    /// Lignes, retirées comprises.
    pub lignes: Vec<LigneRecu>,
    /// Somme des lignes VIVANTES.
    pub montant_articles_unites: i64,
    /// Frais de livraison effectivement facturés (`devis_prix_client`).
    pub frais_livraison_unites: i64,
    /// Part de frais prise en charge par le vendeur (VND-08), `0` sinon.
    pub retenue_vendeur_unites: i64,
    /// Total dû — celui que porte le tronc, déjà ajusté par les retraits.
    pub total_du_unites: i64,
    /// `cash` | `mobile_money`.
    pub mode_paiement: String,
    /// Moyen effectivement employé, `None` tant que le fournisseur ne l'a pas
    /// dit. Renseigné par la couche API depuis la transaction (FR-012).
    pub moyen: Option<String>,
    /// La commande est-elle déjà réglée ? (FR-073)
    pub deja_regle: bool,
    /// Ce qui reste à remettre au coursier — `0` sur une commande prépayée.
    pub montant_a_remettre_au_coursier_unites: i64,
}

/// Reçu VENDEUR d'un arrêt collecté (contrats §3.2).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RecuArret {
    /// Arrêt.
    pub arret_id: Uuid,
    /// Prestataire chez qui la collecte a eu lieu.
    pub prestataire_id: Uuid,
    /// Devise ISO 4217.
    pub devise: String,
    /// Instant du scan (horloge SERVEUR).
    pub collecte_le: Option<DateTime<Utc>>,
    /// Lignes de CET arrêt, retirées comprises.
    pub lignes: Vec<LigneRecu>,
    /// Articles bruts, avant retenue.
    pub montant_articles_unites: i64,
    /// Retenue appliquée au titre de la livraison offerte.
    pub retenue_livraison_offerte_unites: i64,
    /// Ce que le coursier a effectivement versé — `articles − retenue`.
    pub net_verse_unites: i64,
    /// Clé i18n du motif de retenue, `None` s'il n'y en a pas.
    pub motif_retenue_cle: Option<String>,
}

/// Clé i18n du motif de retenue — une clé, jamais une phrase.
pub const MOTIF_RETENUE_CLE: &str = "recu.retenue.livraison_offerte_vendeur";

impl PgCommandes {
    /// Reçu client, composé à la volée. **Garde de propriété incluse** : une
    /// commande qui n'appartient pas à l'appelant est `CommandeInconnue` — un
    /// `403` distinct apprendrait à un tiers qu'elle existe.
    pub async fn recu_commande(
        &self,
        commande_id: Uuid,
        appelant: Uuid,
    ) -> Result<RecuCommande, ErreurCommandes> {
        let entete = sqlx::query!(
            r#"SELECT c.client_id, c.devise, c.total_unites,
                      c.mode_paiement::text AS "mode_paiement!",
                      c.etat_paiement::text AS "etat_paiement!",
                      COALESCE(l.devis_prix_client, 0) AS "frais!",
                      COALESCE((l.devis_composantes->>'retenue_vendeur')::bigint, 0)
                          AS "retenue!"
                 FROM commandes.commande c
                 LEFT JOIN commandes.livraison l ON l.commande_id = c.id
                WHERE c.id = $1"#,
            commande_id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        if entete.client_id != appelant {
            return Err(ErreurCommandes::CommandeInconnue(commande_id));
        }

        let lignes = self.lignes_recu(commande_id, None).await?;
        let montant_articles_unites = lignes.iter().map(|l| l.sous_total_unites).sum();
        let deja_regle = entete.etat_paiement == "regle";
        // Une commande prépayée ne réclame RIEN au coursier (FR-057, R11). La
        // valeur ne se déduit pas du seul `deja_regle` : une commande cash dont
        // le paiement serait marqué réglé par un chemin futur devrait quand
        // même être encaissée si le mode le dit.
        let montant_a_remettre_au_coursier_unites = if entete.mode_paiement == "cash" {
            entete.total_unites
        } else {
            0
        };

        Ok(RecuCommande {
            commande_id,
            devise: entete.devise,
            lignes,
            montant_articles_unites,
            frais_livraison_unites: entete.frais,
            retenue_vendeur_unites: entete.retenue,
            total_du_unites: entete.total_unites,
            mode_paiement: entete.mode_paiement,
            moyen: None,
            deja_regle,
            montant_a_remettre_au_coursier_unites,
        })
    }

    /// Reçu vendeur d'un arrêt **collecté**. Rend `ArretInconnu` tant que le
    /// scan n'a pas eu lieu : il n'y a pas de versement à attester avant.
    ///
    /// La garde de propriété est celle de l'appelant (rattachement vendeur) :
    /// cette lecture rend le `prestataire_id`, la couche API le compare aux
    /// prestataires pilotés.
    pub async fn recu_arret(&self, arret_id: Uuid) -> Result<RecuArret, ErreurCommandes> {
        let arret = sqlx::query!(
            r#"SELECT a.prestataire_id, a.devise, a.collecte_le,
                      a.montant_articles_unites, a.retenue_appliquee_unites,
                      a.montant_avance, a.statut::text AS "statut!"
                 FROM commandes.arret a
                WHERE a.id = $1 AND a.type_arret = 'collecte'"#,
            arret_id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::ArretInconnu(arret_id))?;

        if arret.statut != "collecte" {
            return Err(ErreurCommandes::ArretInconnu(arret_id));
        }
        let prestataire_id = arret
            .prestataire_id
            .ok_or(ErreurCommandes::ArretInconnu(arret_id))?;

        Ok(RecuArret {
            arret_id,
            prestataire_id,
            devise: arret.devise,
            collecte_le: arret.collecte_le,
            lignes: self.lignes_recu_arret(arret_id).await?,
            montant_articles_unites: arret.montant_articles_unites,
            retenue_livraison_offerte_unites: arret.retenue_appliquee_unites,
            net_verse_unites: arret.montant_avance,
            motif_retenue_cle: (arret.retenue_appliquee_unites > 0)
                .then(|| MOTIF_RETENUE_CLE.to_owned()),
        })
    }

    /// Lignes d'une commande (ou d'un seul arrêt), prix VERROUILLÉS.
    async fn lignes_recu(
        &self,
        commande_id: Uuid,
        arret_id: Option<Uuid>,
    ) -> Result<Vec<LigneRecu>, ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT COALESCE(ar.nom, a.nom) AS "libelle!",
                      lc.quantite,
                      COALESCE(lc.remplace_prix_unites, pf.prix_unites) AS "prix!",
                      lc.statut::text AS "statut!"
                 FROM commandes.ligne_commande lc
                 JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
                 JOIN prestataires.article a ON a.id = lc.article_id
                 LEFT JOIN prestataires.article ar ON ar.id = lc.remplace_par_article_id
                WHERE lc.commande_id = $1
                  AND ($2::uuid IS NULL OR lc.arret_id = $2)
                ORDER BY lc.cree_le, lc.id"#,
            commande_id,
            arret_id,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(lignes
            .into_iter()
            .map(|l| LigneRecu {
                // Une ligne retirée compte pour ZÉRO — elle reste visible pour
                // expliquer l'écart, elle ne pèse plus sur le total.
                sous_total_unites: if l.statut == "retiree" {
                    0
                } else {
                    i64::from(l.quantite) * l.prix
                },
                libelle: l.libelle,
                quantite: l.quantite,
                prix_unitaire_unites: l.prix,
                statut: l.statut,
            })
            .collect())
    }

    /// Lignes d'un arrêt donné, sans passer par la commande.
    async fn lignes_recu_arret(&self, arret_id: Uuid) -> Result<Vec<LigneRecu>, ErreurCommandes> {
        let commande_id: Option<Uuid> = sqlx::query_scalar!(
            "SELECT commande_id FROM commandes.ligne_commande WHERE arret_id = $1 LIMIT 1",
            arret_id,
        )
        .fetch_optional(&self.pool)
        .await?;

        match commande_id {
            // Un arrêt dont toutes les lignes ont disparu n'a plus de reçu à
            // détailler ; ses trois montants restent exacts (0, 0, 0).
            None => Ok(Vec::new()),
            Some(commande) => self.lignes_recu(commande, Some(arret_id)).await,
        }
    }
}
