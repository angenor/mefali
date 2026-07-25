//! Pipeline de création d'une commande (data-model §4) — idempotent par clé
//! client, prix verrouillés, devis figé, code et QR remis immédiatement.
//!
//! **Ordre imposé** : les étapes 1 à 6 sont HORS transaction (dont l'appel
//! réseau OSRM — research R11), les étapes 7 à 18 sont dans UNE seule
//! transaction. Tenir une transaction ouverte pendant un appel HTTP externe
//! serait la meilleure façon de bloquer la base un jour de panne OSRM.

use crate::modele::ErreurCommandes;

/// Clés des paramètres de zone lus par la décision de paiement. Aucune valeur
/// n'est en dur : tout se règle en configuration de zone (constitution I).
mod cles {
    /// Plafond d'encaissement en espèces (unités mineures).
    pub const PLAFOND_CASH: &str = "commande.plafond_cash_unites";
    /// Plafond RÉDUIT, restauration d'un client sans historique.
    pub const PLAFOND_CASH_RESTAURATION_SANS_HISTORIQUE: &str =
        "commande.plafond_cash_restauration_sans_historique_unites";
    /// En deçà de ce nombre de commandes TERMINÉES, le client est « sans historique ».
    pub const HISTORIQUE_MIN: &str = "commande.historique_min_commandes_terminees";
}

/// Pourquoi le cash est refusé. Chaque motif a sa clé i18n : le client voit la
/// RAISON du grisage, jamais un bouton mort (maquette C3-3b).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifPrepaiement {
    /// Total au-dessus du plafond d'encaissement de la zone (FR-024).
    Plafond,
    /// Le compte porte `prepaiement_impose` (sanction CPT-06, FR-025).
    PrepaiementImpose,
    /// Restauration commandée par un client sans historique (FR-024).
    RestaurationSansHistorique,
}

impl MotifPrepaiement {
    /// Représentation textuelle (payload `commande.paiement_requis`).
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifPrepaiement::Plafond => "plafond",
            MotifPrepaiement::PrepaiementImpose => "prepaiement_impose",
            MotifPrepaiement::RestaurationSansHistorique => "restauration_sans_historique",
        }
    }

    /// Clé i18n fr affichée sous l'option cash grisée.
    pub fn message_cle(self) -> &'static str {
        match self {
            MotifPrepaiement::Plafond => "commande.cash.plafond_depasse",
            MotifPrepaiement::PrepaiementImpose => "commande.cash.prepaiement_impose",
            MotifPrepaiement::RestaurationSansHistorique => {
                "commande.cash.restauration_sans_historique"
            }
        }
    }
}

/// Décision d'encaissement, identique au panier et à la confirmation — le
/// client ne découvre jamais à la confirmation une règle qu'on ne lui a pas
/// montrée au panier.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DecisionPaiement {
    /// Le paiement en espèces est possible.
    pub cash_autorise: bool,
    /// Pourquoi il ne l'est pas (`None` s'il l'est).
    pub motif: Option<MotifPrepaiement>,
    /// Plafond APPLIQUÉ (celui qui a tranché), unités mineures.
    pub plafond_unites: i64,
}

impl DecisionPaiement {
    /// Clé i18n du motif, ou `None` si le cash est autorisé.
    pub fn message_cle(&self) -> Option<&'static str> {
        self.motif.map(MotifPrepaiement::message_cle)
    }
}

use uuid::Uuid;
use zones::ConfigurationZones;

use crate::depot::PgCommandes;

impl PgCommandes {
    /// Décide si le total peut être encaissé en espèces (FR-024/025).
    ///
    /// Trois refus possibles, dans cet ordre de priorité :
    /// 1. le compte porte `prepaiement_impose` — une sanction ne se contourne
    ///    pas en baissant son panier ;
    /// 2. la catégorie est la restauration ET le client est « sans historique »
    ///    (moins de `commande.historique_min_commandes_terminees` commandes
    ///    **terminées** — les annulées et les échouées ne comptent pas) : le
    ///    plafond RÉDUIT s'applique ;
    /// 3. le plafond ordinaire de la zone.
    ///
    /// Le plafond renvoyé est celui qui a effectivement tranché : c'est lui que
    /// l'écran affiche, pas une valeur théorique.
    pub async fn decision_paiement(
        &self,
        zone_id: Uuid,
        client_id: Uuid,
        categorie_slug: &str,
        total_unites: i64,
    ) -> Result<DecisionPaiement, ErreurCommandes> {
        let plafond_ordinaire = self.parametre_i64(zone_id, cles::PLAFOND_CASH).await?;

        // 1. Sanction de compte : rien ne la contourne.
        if self.restrictions.restrictions(client_id).await?.prepaiement_impose {
            return Ok(DecisionPaiement {
                cash_autorise: false,
                motif: Some(MotifPrepaiement::PrepaiementImpose),
                plafond_unites: 0,
            });
        }

        // 2. Plafond réduit de la restauration sans historique.
        let plafond = if categorie_slug == "restauration"
            && self.client_sans_historique(zone_id, client_id).await?
        {
            let reduit = self
                .parametre_i64(zone_id, cles::PLAFOND_CASH_RESTAURATION_SANS_HISTORIQUE)
                .await?;
            if total_unites > reduit {
                return Ok(DecisionPaiement {
                    cash_autorise: false,
                    motif: Some(MotifPrepaiement::RestaurationSansHistorique),
                    plafond_unites: reduit,
                });
            }
            reduit
        } else {
            plafond_ordinaire
        };

        // 3. Plafond ordinaire.
        if total_unites > plafond_ordinaire {
            return Ok(DecisionPaiement {
                cash_autorise: false,
                motif: Some(MotifPrepaiement::Plafond),
                plafond_unites: plafond_ordinaire,
            });
        }

        Ok(DecisionPaiement {
            cash_autorise: true,
            motif: None,
            plafond_unites: plafond,
        })
    }

    /// Vrai si le client compte MOINS de commandes terminées que le seuil de
    /// zone (FR-024). Les commandes annulées ou échouées ne comptent pas : on
    /// mesure une relation qui a abouti, pas un nombre de tentatives.
    pub(crate) async fn client_sans_historique(
        &self,
        zone_id: Uuid,
        client_id: Uuid,
    ) -> Result<bool, ErreurCommandes> {
        let seuil = self.parametre_i64(zone_id, cles::HISTORIQUE_MIN).await?;
        let terminees = sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM commandes.commande
               WHERE client_id = $1 AND etat = 'terminee'"#,
            client_id,
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(terminees < seuil)
    }

    /// Paramètre de zone entier, résolu par héritage. Une clé absente est une
    /// erreur de CONFIGURATION, pas un défaut silencieux : un plafond cash qui
    /// vaudrait 0 par accident bloquerait toutes les commandes en espèces.
    pub(crate) async fn parametre_i64(
        &self,
        zone_id: Uuid,
        cle: &str,
    ) -> Result<i64, ErreurCommandes> {
        self.zones
            .parametre(zone_id, cle)
            .await?
            .and_then(|v| v.as_i64())
            .ok_or_else(|| {
                ErreurCommandes::Dependance(format!(
                    "paramètre de zone « {cle} » absent ou non entier"
                ))
            })
    }

    /// Paramètre de zone booléen, résolu par héritage. `false` si absent —
    /// pour `perissable`, l'absence signifie « non périssable », qui est le
    /// défaut sûr : on renvoie la marchandise au vendeur plutôt que de la jeter.
    pub(crate) async fn parametre_bool(
        &self,
        zone_id: Uuid,
        cle: &str,
    ) -> Result<bool, ErreurCommandes> {
        Ok(self
            .zones
            .parametre(zone_id, cle)
            .await?
            .and_then(|v| v.as_bool())
            .unwrap_or(false))
    }
}
