//! Le pipeline de dispatch — **un seul point de sortie**.
//!
//! [`DecisionPipeline`] énumère tout ce qu'un passage peut décider. Un seul type
//! de retour, donc un seul endroit où les événements s'écrivent et un seul à
//! tester. Un pipeline à sorties multiples finirait par en avoir une qui
//! n'émet rien, et personne ne le remarquerait avant la production.
//!
//! **Ce qui décide, dans l'ordre** :
//!
//! 1. filtrer le vivier (DSP-02) ;
//! 2. s'il est vide **et** que la capacité d'avance est le SEUL obstacle →
//!    bascule prépaiement (FR-026). Sinon → file d'attente FIFO ;
//! 3. classer les éligibles (DSP-03) ;
//! 4. offrir au mieux classé sous double verrou (DSP-04), ou basculer en
//!    broadcast quand la cascade s'essouffle (DSP-05).
//!
//! **La bascule prépaiement ne se déclenche que si l'argent est le seul
//! obstacle.** Un pool vide pour une autre raison part en file d'attente, où le
//! prépaiement ne changerait rien : avancer l'argent ne rapprocherait pas un
//! coursier de 5 km, et exiger un paiement pour rien ferait perdre la commande.

use chrono::{DateTime, Utc};
use commandes::MotifPrepaiementDispatch;
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use tarification::Point;
use uuid::Uuid;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::eligibilite::{DemandeEligibilite, Vivier};
use crate::modele::{Capacite, ErreurDispatch, ModeOffre, MotifEcart, Offre};
use crate::offre::IssueEmission;
use crate::ports::{Annonce, Canal};

/// Pourquoi le broadcast s'est ouvert (FR-058).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CauseBroadcast {
    /// Le nombre de candidats sollicités a atteint le seuil de zone.
    CandidatsEpuises,
    /// Le délai depuis le début du pipeline a été franchi.
    Delai,
}

impl CauseBroadcast {
    /// Représentation textuelle (payload d'événement).
    pub fn comme_str(self) -> &'static str {
        match self {
            CauseBroadcast::CandidatsEpuises => "candidats_epuises",
            CauseBroadcast::Delai => "delai",
        }
    }
}

/// Ce qu'un passage de pipeline a décidé — **le seul** type de sortie.
#[derive(Debug, Clone, PartialEq)]
pub enum DecisionPipeline {
    /// Une offre est partie au mieux classé.
    OffreEmise(Box<Offre>),
    /// Le broadcast s'est ouvert (DSP-05).
    BroadcastOuvert {
        /// Nombre de destinataires effectivement atteints.
        nb_destinataires: usize,
        /// Pourquoi la bascule a eu lieu.
        cause: CauseBroadcast,
    },
    /// La capacité d'avance était le seul obstacle : prépaiement exigé (FR-026).
    BasculePrepaiement {
        /// Montant que personne ne pouvait avancer (unités mineures).
        montant_a_avancer: i64,
        /// Plafond maximal constaté dans le vivier.
        plafond_max_constate: i64,
    },
    /// Aucun éligible pour une **autre** raison : file d'attente FIFO (CMD-10).
    MiseEnFile {
        /// Nombre de coursiers écartés, tous motifs confondus.
        nb_ecartes: usize,
    },
    /// Rien à faire : commande déjà tenue par une autre évaluation, déjà
    /// assignée, ou annulée entre-temps.
    RienAFaire,
}

impl PgDispatch {
    /// Un passage complet du pipeline sur une commande.
    ///
    /// ⚠ Ne rend `Err` que sur une panne d'INFRASTRUCTURE. Toute issue métier —
    /// aucun éligible, bascule prépaiement, pool vide — est un **succès** écrit
    /// en base : le consommateur outbox rejouerait indéfiniment un événement
    /// dont la consommation échoue, et une commande sans coursier bloquerait sa
    /// propre ligne pour toujours (research R1).
    pub async fn dispatcher(
        &self,
        commande: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<DecisionPipeline, ErreurDispatch> {
        let Some(contexte) = self.contexte_dispatch(commande).await? else {
            return Ok(DecisionPipeline::RienAFaire);
        };
        let config = self.config(contexte.zone).await?;

        let demande = DemandeEligibilite {
            commande,
            montant_a_avancer: contexte.montant_a_avancer,
            devise: contexte.devise.clone(),
            premiere_collecte: contexte.premiere_collecte,
            contreparties: contexte.contreparties.clone(),
            capacites_requises: contexte.capacites_requises.clone(),
            deja_sollicites: self.deja_sollicites(commande).await?,
        };
        let vivier = self.filtrer(&config, &demande).await?;
        self.emettre_evaluation_faite(&config, commande, &vivier, maintenant)
            .await?;

        if vivier.eligibles.is_empty() {
            return self
                .conclure_vivier_vide(&config, &contexte, &vivier, maintenant)
                .await;
        }

        let candidats = self
            .classer(&config, &vivier.eligibles, vivier.mesure, maintenant)
            .await?;

        // Bascule en broadcast sur conditions ALTERNATIVES (FR-058) : assez de
        // candidats sollicités, OU assez de temps écoulé. La seconde protège le
        // cas d'un vivier trop maigre pour épuiser le compteur.
        let nb_offres = self.nb_offres_emises(commande).await?;
        let age_pipeline_s = (maintenant - contexte.creee_le).num_seconds().max(0);
        let cause = if nb_offres >= config.broadcast_apres_candidats {
            Some(CauseBroadcast::CandidatsEpuises)
        } else if age_pipeline_s >= config.broadcast_apres_s {
            Some(CauseBroadcast::Delai)
        } else {
            None
        };
        if let Some(cause) = cause {
            return self
                .ouvrir_broadcast(&config, &contexte, &candidats, cause, maintenant)
                .await;
        }

        // CASCADE — au mieux classé. Un coursier déjà porteur fait passer au
        // SUIVANT sans attendre (FR-057) ; une commande déjà tenue fait
        // abandonner ce passage.
        for candidat in &candidats {
            match self
                .emettre_offre(
                    &config,
                    commande,
                    candidat.coursier,
                    ModeOffre::Cascade,
                    candidat.rang as i16,
                    candidat.score,
                    contexte.montant_a_avancer,
                    maintenant,
                )
                .await?
            {
                IssueEmission::Emise(offre) => return Ok(DecisionPipeline::OffreEmise(offre)),
                IssueEmission::CoursierIndisponible => continue,
                IssueEmission::CommandeDejaTenue => return Ok(DecisionPipeline::RienAFaire),
            }
        }

        // Tous les candidats portaient déjà une offre : rien n'est perdu, la
        // commande repart au tic suivant.
        Ok(DecisionPipeline::MiseEnFile {
            nb_ecartes: vivier.ecarts.len(),
        })
    }

    /// Vivier vide : prépaiement **seulement** si l'argent est le seul obstacle.
    async fn conclure_vivier_vide(
        &self,
        config: &ConfigDispatch,
        contexte: &ContexteDispatch,
        vivier: &Vivier,
        maintenant: DateTime<Utc>,
    ) -> Result<DecisionPipeline, ErreurDispatch> {
        let bloque_par_l_avance = vivier
            .ecarts
            .iter()
            .any(|e| e.motifs == [MotifEcart::CapaciteAvance]);

        if bloque_par_l_avance {
            // Le plafond le plus haut constaté : ce que la cliente doit savoir
            // pour comprendre pourquoi on lui demande de prépayer.
            let plafond_max = config.grille_avance.plafond_max();
            self.commandes
                .exiger_prepaiement(
                    contexte.commande,
                    MotifPrepaiementDispatch::CapaciteAvanceCoursier,
                    maintenant,
                )
                .await?;

            let mut tx = self.pool.begin().await?;
            ecrire_evenement(
                &mut tx,
                NouvelEvenement {
                    type_evenement: "dispatch.bascule_prepaiement",
                    entite_type: "commande",
                    entite_id: contexte.commande,
                    payload: json!({
                        "zone": config.zone,
                        "montant_a_avancer": contexte.montant_a_avancer,
                        "plafond_max_constate": plafond_max,
                        "devise": config.devise,
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
            tx.commit().await?;

            // La cliente est prévenue AVEC le motif : « aucun coursier ne peut
            // avancer ce montant, réglez d'avance et la course repart ».
            self.notifications
                .annoncer(
                    Annonce::nouvelle(
                        Canal::Client,
                        Some(contexte.client),
                        "dispatch.prepaiement.exige",
                    )
                    .pour_commande(contexte.commande)
                    .avec_variables(json!({
                        "montant_a_avancer": contexte.montant_a_avancer,
                        "plafond_max_constate": plafond_max,
                        "devise": config.devise,
                    })),
                )
                .await;

            return Ok(DecisionPipeline::BasculePrepaiement {
                montant_a_avancer: contexte.montant_a_avancer,
                plafond_max_constate: plafond_max,
            });
        }

        // Toute autre raison : file d'attente FIFO. La mécanique existe depuis
        // CMD-10 — aucune table nouvelle, aucun état inventé. Le prépaiement
        // n'est PAS proposé : il ne lèverait pas l'obstacle.
        if contexte.etat == "nouvelle" {
            self.commandes_mettre_en_attente(contexte.commande, maintenant)
                .await?;
        }
        Ok(DecisionPipeline::MiseEnFile {
            nb_ecartes: vivier.ecarts.len(),
        })
    }

    /// Ouvre le broadcast : tous les éligibles **réévalués à l'émission**.
    ///
    /// Le verrou de coursier s'applique à chaque destinataire : deux broadcasts
    /// concurrents se **sérialisent** au lieu de se disputer les écrans (FR-062).
    async fn ouvrir_broadcast(
        &self,
        config: &ConfigDispatch,
        contexte: &ContexteDispatch,
        candidats: &[crate::modele::Candidat],
        cause: CauseBroadcast,
        maintenant: DateTime<Utc>,
    ) -> Result<DecisionPipeline, ErreurDispatch> {
        let mut atteints = 0usize;
        for candidat in candidats {
            // Réévaluation à l'émission : un coursier devenu occupé entre le
            // début du pipeline et maintenant ne doit pas recevoir d'écran.
            if self
                .commandes
                .course_active(candidat.coursier)
                .await?
                .is_some()
            {
                continue;
            }
            match self
                .emettre_offre(
                    config,
                    contexte.commande,
                    candidat.coursier,
                    ModeOffre::Broadcast,
                    0,
                    candidat.score,
                    contexte.montant_a_avancer,
                    maintenant,
                )
                .await?
            {
                IssueEmission::Emise(_) => atteints += 1,
                // Déjà porteur d'une offre — la sienne ou celle d'un broadcast
                // concurrent : il verrait deux écrans. On passe au suivant, et
                // c'est ainsi que deux broadcasts se SÉRIALISENT (FR-062) au
                // lieu de se disputer les destinataires.
                IssueEmission::CoursierIndisponible => continue,
                // Ne peut plus survenir en broadcast (aucun verrou de commande
                // n'y est posé) ; on reste exhaustif plutôt que d'ignorer.
                IssueEmission::CommandeDejaTenue => continue,
            }
        }

        let mut tx = self.pool.begin().await?;
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.broadcast_ouvert",
                entite_type: "commande",
                entite_id: contexte.commande,
                payload: json!({
                    "zone": config.zone,
                    "nb_destinataires": atteints,
                    "cause": cause.comme_str(),
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;

        Ok(DecisionPipeline::BroadcastOuvert {
            nb_destinataires: atteints,
            cause,
        })
    }

    /// Agrégat d'un passage — le DÉTAIL par candidat va dans les logs, jamais
    /// dans l'outbox.
    async fn emettre_evaluation_faite(
        &self,
        config: &ConfigDispatch,
        commande: Uuid,
        vivier: &Vivier,
        maintenant: DateTime<Utc>,
    ) -> Result<(), ErreurDispatch> {
        let motifs: serde_json::Map<String, serde_json::Value> = MotifEcart::TOUS
            .iter()
            .filter_map(|m| {
                let n = vivier
                    .ecarts
                    .iter()
                    .filter(|e| e.motifs.contains(m))
                    .count();
                (n > 0).then(|| (m.comme_str().to_owned(), json!(n)))
            })
            .collect();

        let mut tx = self.pool.begin().await?;
        ecrire_evenement(
            &mut tx,
            NouvelEvenement {
                type_evenement: "dispatch.evaluation_faite",
                entite_type: "commande",
                entite_id: commande,
                payload: json!({
                    "zone": config.zone,
                    "nb_eligibles": vivier.eligibles.len(),
                    "nb_ecartes": vivier.ecarts.len(),
                    "motifs": motifs,
                    "degraded": vivier.degraded,
                    "mesure": vivier.mesure.comme_str(),
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;
        Ok(())
    }

    /// Met la commande en file d'attente par la mécanique CMD-10 existante.
    async fn commandes_mettre_en_attente(
        &self,
        commande: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<(), ErreurDispatch> {
        // La transition est GARDÉE : une commande qui n'est plus `nouvelle`
        // (annulée, déjà assignée) la refuse, et c'est un refus attendu — pas
        // une panne.
        match self
            .commandes
            .mettre_en_attente(commande, maintenant)
            .await
            .map_err(ErreurDispatch::from)
        {
            Ok(()) => Ok(()),
            Err(ErreurDispatch::DejaPrise) => Ok(()),
            Err(ErreurDispatch::Dependance(detail)) => {
                tracing::info!(commande = %commande, detail, "mise en attente sans effet");
                Ok(())
            }
            Err(e) => Err(e),
        }
    }

    /// Contexte d'une commande dispatchable, ou `None` si elle ne l'est plus.
    async fn contexte_dispatch(
        &self,
        commande: Uuid,
    ) -> Result<Option<ContexteDispatch>, ErreurDispatch> {
        let ligne = sqlx::query!(
            r#"SELECT c.zone_id, c.client_id, c.devise, c.cree_le,
                      c.etat::text AS "etat!",
                      (SELECT COALESCE(SUM(a.montant_avance), 0)::bigint
                         FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte')
                          AS "montant_a_avancer!",
                      (SELECT a.site_lat FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte'
                        ORDER BY s.ordre, a.ordre LIMIT 1) AS premiere_lat,
                      (SELECT a.site_lon FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         JOIN commandes.livraison l ON l.id = s.livraison_id
                        WHERE l.commande_id = c.id AND a.type_arret = 'collecte'
                        ORDER BY s.ordre, a.ordre LIMIT 1) AS premiere_lon
               FROM commandes.commande c
               WHERE c.id = $1"#,
            commande,
        )
        .fetch_optional(&self.pool)
        .await?;

        let Some(ligne) = ligne else {
            return Ok(None);
        };
        // Seules `nouvelle` et `en_attente_coursier` sont dispatchables : une
        // commande en cours, annulée ou en attente de paiement ne l'est pas, et
        // le dire ici évite quatre gardes plus bas.
        if !matches!(ligne.etat.as_str(), "nouvelle" | "en_attente_coursier") {
            return Ok(None);
        }
        let (Some(lat), Some(lon)) = (ligne.premiere_lat, ligne.premiere_lon) else {
            // Aucune collecte : rien à dispatcher (un vertical sans livraison).
            return Ok(None);
        };

        let contreparties = sqlx::query_scalar!(
            r#"SELECT a.prestataire_id AS "prestataire!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE l.commande_id = $1 AND a.prestataire_id IS NOT NULL"#,
            commande,
        )
        .fetch_all(&self.pool)
        .await?;
        let mut contreparties = contreparties;
        contreparties.push(ligne.client_id);

        let capacites_requises = self
            .commandes
            .capacites_requises(commande)
            .await?
            .into_iter()
            .map(|c| Capacite {
                famille: c.famille,
                valeur: c.valeur,
            })
            .collect();

        Ok(Some(ContexteDispatch {
            commande,
            zone: ligne.zone_id,
            client: ligne.client_id,
            etat: ligne.etat,
            devise: ligne.devise,
            creee_le: ligne.cree_le,
            montant_a_avancer: ligne.montant_a_avancer,
            premiere_collecte: Point { lat, lon },
            contreparties,
            capacites_requises,
        }))
    }
}

/// Ce que le pipeline a besoin de savoir d'une commande.
#[derive(Debug, Clone, PartialEq)]
struct ContexteDispatch {
    commande: Uuid,
    zone: Uuid,
    client: Uuid,
    etat: String,
    devise: String,
    creee_le: DateTime<Utc>,
    montant_a_avancer: i64,
    premiere_collecte: Point,
    contreparties: Vec<Uuid>,
    capacites_requises: Vec<Capacite>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn les_causes_de_broadcast_ont_leur_valeur_de_payload() {
        assert_eq!(CauseBroadcast::CandidatsEpuises.comme_str(), "candidats_epuises");
        assert_eq!(CauseBroadcast::Delai.comme_str(), "delai");
    }
}
