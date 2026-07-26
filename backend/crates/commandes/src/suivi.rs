//! Vue de suivi client (CMD-05) : état en clé i18n, progression par arrêt,
//! position datée.
//!
//! Trois principes que ce module fait tenir :
//!
//! 1. **Aucune chaîne utilisateur ici** — l'état est rendu en clé i18n
//!    (`suivi.etat.*`), jamais en phrase. Le serveur dit *quel* état, l'app dit
//!    *comment on le formule* (constitution VII).
//! 2. **La remise n'est pas une collecte** — la progression compte les seules
//!    collectes : « 2 sur 3 », jamais « 2 sur 4 » (P1, research R4).
//! 3. **La position vient TOUJOURS avec son âge** — sans lui, l'app afficherait
//!    une position vieille de dix minutes comme si elle était vraie (FR-040,
//!    maquette C4-4d). Son absence n'est jamais une erreur (research R13).

use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::modele::{ErreurCommandes, EtatCommande, EtatLivraison};
use crate::ports::PositionDatee;

/// Clé i18n de l'état affiché — le stepper de la maquette C4-4a.
///
/// Le tronc seul ne suffit pas : `en_cours` couvre aussi bien « le coursier
/// fait vos courses » que « il arrive chez vous ». C'est la LIVRAISON qui
/// tranche entre les deux, et c'est exactement la raison d'être des trois
/// niveaux (constitution II).
pub fn etat_cle(etat: EtatCommande, livraison: Option<EtatLivraison>) -> &'static str {
    match etat {
        EtatCommande::Nouvelle => "suivi.etat.commande_recue",
        EtatCommande::EnAttentePaiement => "suivi.etat.paiement_attendu",
        EtatCommande::EnAttenteCoursier => "suivi.etat.recherche_coursier",
        EtatCommande::EnCours => match livraison {
            Some(EtatLivraison::EnLivraison) => "suivi.etat.en_route_vers_vous",
            _ => "suivi.etat.collecte_en_cours",
        },
        EtatCommande::Terminee => "suivi.etat.livree",
        EtatCommande::Annulee => "suivi.etat.annulee",
        EtatCommande::Echouee => "suivi.etat.echouee",
    }
}

/// L'arrêt où en est le coursier — celui que l'écran nomme.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ArretCourant {
    /// Arrêt concerné.
    pub arret_id: Uuid,
    /// Nom du vendeur (`None` sur l'arrêt de remise).
    pub prestataire_nom: Option<String>,
    /// Rang dans l'itinéraire.
    pub ordre: i16,
    /// Statut de l'arrêt.
    pub statut: String,
}

/// Secrets de remise — servis au **propriétaire seul** (research R6).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SecretsRemiseSuivi {
    /// Code à 4 chiffres.
    pub code_livraison: String,
    /// Jeton encodé dans le QR de réception.
    pub jeton_reception: String,
}

/// Une proposition de remplacement encore ouverte (CMD-06, maquette C4-4c).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SubstitutionEnAttente {
    /// Proposition.
    pub substitution_id: Uuid,
    /// Ligne concernée.
    pub ligne_id: Uuid,
    /// Nom de l'article proposé.
    pub article_nom: String,
    /// Prix proposé (unités mineures).
    pub prix_unites: i64,
    /// Prix de la ligne d'origine (unités mineures).
    pub ancien_prix_unites: i64,
    /// Clé de la photo déposée par le coursier.
    pub photo_cle: String,
    /// Secondes restantes avant l'échéance.
    pub reste_s: i64,
}

/// Vue de suivi complète d'une commande (contrat §1.3).
#[derive(Debug, Clone, PartialEq)]
pub struct VueSuivi {
    /// Commande.
    pub commande_id: Uuid,
    /// État de très haut niveau.
    pub etat: EtatCommande,
    /// Clé i18n de l'état affiché.
    pub etat_cle: &'static str,
    /// Instant du dernier changement d'état.
    pub etat_le: DateTime<Utc>,
    /// Total à payer (unités mineures) — révisé si des articles ont sauté.
    pub total_unites: i64,
    /// Montant des articles seuls.
    pub montant_articles_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Livraison, si la commande en a une (composant 0..n).
    pub livraison_id: Option<Uuid>,
    /// État logistique.
    pub livraison_etat: Option<EtatLivraison>,
    /// Collectes déjà RÉSOLUES (collectées ou indisponibles).
    pub collectes_faites: i64,
    /// Nombre total de COLLECTES — la remise n'en est pas une.
    pub collectes_total: i64,
    /// Arrêt courant, celui que l'écran nomme.
    pub arret_courant: Option<ArretCourant>,
    /// Coursier affecté.
    pub coursier_id: Option<Uuid>,
    /// Dernière position connue du coursier, AVEC son âge.
    pub position: Option<PositionDatee>,
    /// Code et jeton — **propriétaire seul**.
    pub remise: SecretsRemiseSuivi,
    /// Proposition de remplacement en attente de décision.
    pub substitution_en_attente: Option<SubstitutionEnAttente>,
}

/// Une commande dans la liste `GET /moi/commandes`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommandeResumee {
    /// Commande.
    pub commande_id: Uuid,
    /// État de très haut niveau.
    pub etat: EtatCommande,
    /// Clé i18n de l'état affiché.
    pub etat_cle: &'static str,
    /// Création.
    pub cree_le: DateTime<Utc>,
    /// Total à payer.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Nombre de vendeurs de la commande.
    pub nb_vendeurs: i64,
}

impl PgCommandes {
    /// Vue de suivi d'une commande, pour son **propriétaire**.
    ///
    /// La propriété est dans le `WHERE`, pas dans un `if` après coup : une
    /// commande d'un autre compte est indiscernable d'une commande inexistante,
    /// et c'est voulu — un identifiant deviné ne doit rien révéler.
    pub async fn suivi(
        &self,
        commande_id: Uuid,
        client_id: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<VueSuivi, ErreurCommandes> {
        let c = sqlx::query!(
            r#"SELECT c.etat::text AS "etat!", c.etat_le, c.total_unites,
                      c.montant_articles_unites, c.devise,
                      c.code_livraison, c.jeton_reception,
                      l.id AS "livraison_id?", l.etat::text AS "livraison_etat?",
                      l.coursier_id
               FROM commandes.commande c
               LEFT JOIN commandes.livraison l ON l.commande_id = c.id
               WHERE c.id = $1 AND c.client_id = $2"#,
            commande_id,
            client_id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::CommandeInconnue(commande_id))?;

        let etat: EtatCommande = c.etat.parse()?;
        let livraison_etat = c
            .livraison_etat
            .as_deref()
            .map(str::parse::<EtatLivraison>)
            .transpose()?;

        let (collectes_faites, collectes_total, arret_courant) = match c.livraison_id {
            Some(livraison_id) => self.progression_suivi(livraison_id).await?,
            None => (0, 0, None),
        };

        // Redis absent ou position expirée → `None`, JAMAIS une erreur : un
        // suivi doit rester lisible sans position (research R13).
        let position = match c.coursier_id {
            Some(coursier) => self.positions.derniere(coursier).await.unwrap_or(None),
            None => None,
        };

        Ok(VueSuivi {
            commande_id,
            etat,
            etat_cle: etat_cle(etat, livraison_etat),
            etat_le: c.etat_le,
            total_unites: c.total_unites,
            montant_articles_unites: c.montant_articles_unites,
            devise: c.devise,
            livraison_id: c.livraison_id,
            livraison_etat,
            collectes_faites,
            collectes_total,
            arret_courant,
            coursier_id: c.coursier_id,
            position,
            remise: SecretsRemiseSuivi {
                code_livraison: c.code_livraison,
                jeton_reception: c.jeton_reception,
            },
            substitution_en_attente: self
                .substitution_en_attente(commande_id, maintenant)
                .await?,
        })
    }

    /// Progression d'une livraison : `(collectes résolues, total, arrêt courant)`.
    ///
    /// « Résolue » = collectée **ou** indisponible : un étal fermé ne laisse pas
    /// la barre bloquée à jamais (FR-018). L'arrêt courant est le premier non
    /// résolu — quand toutes les collectes le sont, c'est la remise.
    async fn progression_suivi(
        &self,
        livraison_id: Uuid,
    ) -> Result<(i64, i64, Option<ArretCourant>), ErreurCommandes> {
        let comptes = sqlx::query!(
            r#"SELECT count(*) AS "total!",
                      count(*) FILTER (WHERE a.statut IN ('collecte','indisponible'))
                          AS "resolues!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               WHERE s.livraison_id = $1 AND a.type_arret = 'collecte'"#,
            livraison_id,
        )
        .fetch_one(&self.pool)
        .await?;

        let courant = sqlx::query!(
            r#"SELECT a.id, a.ordre, a.statut::text AS "statut!", p.nom AS "nom?"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               LEFT JOIN prestataires.prestataire p ON p.id = a.prestataire_id
               WHERE s.livraison_id = $1
                 AND a.statut NOT IN ('collecte','indisponible')
               ORDER BY s.ordre, a.ordre
               LIMIT 1"#,
            livraison_id,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok((
            comptes.resolues,
            comptes.total,
            courant.map(|a| ArretCourant {
                arret_id: a.id,
                prestataire_nom: a.nom,
                ordre: a.ordre,
                statut: a.statut,
            }),
        ))
    }

    /// Proposition de remplacement encore ouverte, s'il y en a une.
    ///
    /// Une proposition ÉCHUE n'est jamais servie comme « en attente » : la
    /// résolution se fait à la LECTURE (research R10), sans quoi le client
    /// verrait un compte à rebours à zéro qu'il pourrait encore cliquer.
    async fn substitution_en_attente(
        &self,
        commande_id: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<Option<SubstitutionEnAttente>, ErreurCommandes> {
        let ligne = sqlx::query!(
            r#"SELECT sub.id, sub.ligne_id, sub.prix_propose_unites, sub.photo_cle,
                      sub.echeance, art.nom AS "article_nom!",
                      (lc.quantite * pf.prix_unites) AS "ancien_prix!"
               FROM commandes.substitution sub
               JOIN commandes.ligne_commande lc ON lc.id = sub.ligne_id
               JOIN prestataires.prix_fige pf ON pf.id = lc.prix_fige_id
               JOIN prestataires.article art ON art.id = sub.article_propose_id
               WHERE lc.commande_id = $1
                 AND sub.issue = 'en_attente'
                 AND sub.echeance > $2
               ORDER BY sub.proposee_le
               LIMIT 1"#,
            commande_id,
            maintenant,
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(ligne.map(|s| SubstitutionEnAttente {
            substitution_id: s.id,
            ligne_id: s.ligne_id,
            article_nom: s.article_nom,
            prix_unites: s.prix_propose_unites,
            ancien_prix_unites: s.ancien_prix,
            photo_cle: s.photo_cle,
            reste_s: (s.echeance - maintenant).num_seconds().max(0),
        }))
    }

    /// Les commandes du compte, **les plus récentes d'abord** (index
    /// `commande_par_client`).
    pub async fn mes_commandes(
        &self,
        client_id: Uuid,
    ) -> Result<Vec<CommandeResumee>, ErreurCommandes> {
        let lignes = sqlx::query!(
            r#"SELECT c.id, c.etat::text AS "etat!", c.cree_le, c.total_unites, c.devise,
                      l.etat::text AS "livraison_etat?",
                      (SELECT count(DISTINCT lc.prestataire_id)
                         FROM commandes.ligne_commande lc
                        WHERE lc.commande_id = c.id) AS "nb_vendeurs!"
               FROM commandes.commande c
               LEFT JOIN commandes.livraison l ON l.commande_id = c.id
               WHERE c.client_id = $1
               ORDER BY c.cree_le DESC"#,
            client_id,
        )
        .fetch_all(&self.pool)
        .await?;

        lignes
            .into_iter()
            .map(|l| {
                let etat: EtatCommande = l.etat.parse()?;
                let livraison_etat = l
                    .livraison_etat
                    .as_deref()
                    .map(str::parse::<EtatLivraison>)
                    .transpose()?;
                Ok(CommandeResumee {
                    commande_id: l.id,
                    etat,
                    etat_cle: etat_cle(etat, livraison_etat),
                    cree_le: l.cree_le,
                    total_unites: l.total_unites,
                    devise: l.devise,
                    nb_vendeurs: l.nb_vendeurs,
                })
            })
            .collect()
    }

    /// Journalise une **intention d'appel** (FR-041) — jamais un numéro.
    ///
    /// L'appel part du téléphone : le serveur n'en voit rien. Ce qu'il
    /// journalise, c'est qu'un client a eu BESOIN d'appeler — une métrique de
    /// friction, pas une trace de communication (minimisation ARTCI).
    pub async fn journaliser_appel(
        &self,
        commande_id: Uuid,
        client_id: Uuid,
        motif: &str,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        let existe = sqlx::query_scalar!(
            r#"SELECT EXISTS (
                   SELECT 1 FROM commandes.commande
                   WHERE id = $1 AND client_id = $2
               ) AS "existe!""#,
            commande_id,
            client_id,
        )
        .fetch_one(&self.pool)
        .await?;
        if !existe {
            return Err(ErreurCommandes::CommandeInconnue(commande_id));
        }

        let mut tx = self.pool.begin().await?;
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "appel.intention",
                entite_type: "commande",
                entite_id: commande_id,
                payload: serde_json::json!({
                    "de": "client",
                    "vers": "coursier",
                    "motif": motif,
                }),
                survenu_le: horodatage,
            },
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn l_etat_affiche_depend_des_deux_niveaux() {
        // `en_cours` ne suffit pas : c'est la LIVRAISON qui distingue « il fait
        // vos courses » de « il arrive chez vous ».
        assert_eq!(
            etat_cle(EtatCommande::EnCours, Some(EtatLivraison::EnCollecte)),
            "suivi.etat.collecte_en_cours",
        );
        assert_eq!(
            etat_cle(EtatCommande::EnCours, Some(EtatLivraison::EnLivraison)),
            "suivi.etat.en_route_vers_vous",
        );
        // Une commande sans livraison (vertical futur) reste lisible.
        assert_eq!(
            etat_cle(EtatCommande::EnCours, None),
            "suivi.etat.collecte_en_cours",
        );
    }

    #[test]
    fn chaque_etat_du_tronc_a_sa_cle_i18n() {
        for etat in [
            EtatCommande::Nouvelle,
            EtatCommande::EnAttentePaiement,
            EtatCommande::EnAttenteCoursier,
            EtatCommande::EnCours,
            EtatCommande::Terminee,
            EtatCommande::Annulee,
            EtatCommande::Echouee,
        ] {
            let cle = etat_cle(etat, None);
            assert!(
                cle.starts_with("suivi.etat."),
                "« {} » doit rendre une clé i18n, jamais une phrase",
                etat.comme_str(),
            );
        }
    }
}
