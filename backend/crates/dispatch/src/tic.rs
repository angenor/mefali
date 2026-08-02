//! Le tic — tout ce qui est **temporel**, résolu sur des échéances PERSISTÉES.
//!
//! Six étapes, dans l'ordre, par zone (contrat §4) :
//!
//! 1. expiration des offres échues → non-réponse (franche ou non) → candidat
//!    suivant ;
//! 2. reprise FIFO des commandes en attente (qui rouvre aussi le broadcast
//!    quand la cascade s'est essoufflée) ;
//! 3. escalade des commandes non assignées au seuil de zone (DSP-06) ;
//! 4. réassignations « sans mouvement » et « sans scan », garde d'argent
//!    comprise (DSP-07) ;
//! 5. élagage des fantômes de l'index de pool ;
//! 6. compte-rendu.
//!
//! **Le tic n'est PAS la source de vérité de l'expiration** (research R1, règle
//! héritée du cycle 008) : l'échéance est en base, et toute lecture la respecte
//! déjà — `GET /courses/offre-courante` refuse une offre échue même si le tic
//! n'est pas encore passé. Le tic ne fait qu'**écrire** ce que la lecture savait.
//!
//! **Chaque étape est idempotente et rend un compte.** Une erreur est
//! journalisée et retentée au passage suivant : un incident de tic ne doit
//! jamais faire tomber l'API.

use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::depot::PgDispatch;
use crate::modele::ErreurDispatch;

/// Ce qu'un passage de tic a fait — journalisé, et assertable en test.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct ResultatTic {
    /// Offres échues conclues en non-réponse.
    pub offres_expirees: usize,
    /// Commandes en attente re-poussées dans le pipeline.
    pub commandes_reprises: usize,
    /// Commandes escaladées vers l'exploitation (une seule fois chacune).
    pub escalades: usize,
    /// Courses reprises automatiquement (sans mouvement / sans scan).
    pub reassignations: usize,
    /// Courses bloquées escaladées faute de pouvoir être reprises (FR-075).
    pub courses_bloquees: usize,
    /// Fantômes retirés de l'index de pool.
    pub fantomes_elagues: usize,
}

impl PgDispatch {
    /// Un passage complet du tic sur une zone.
    ///
    /// Ne rend `Err` que sur une panne d'infrastructure : chaque étape absorbe
    /// ses propres refus métier et les journalise.
    pub async fn tic(
        &self,
        zone: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<ResultatTic, ErreurDispatch> {
        let config = self.config(zone).await?;
        let mut resultat = ResultatTic::default();

        // 1. Offres échues. Conclure AVANT de reprendre la file : un coursier
        //    qui vient d'expirer doit redevenir offrable dans le même passage,
        //    sans quoi la commande attendrait un tic de plus pour rien.
        for offre in self.offres_echues(maintenant).await? {
            if offre.zone != zone {
                continue;
            }
            match self.conclure_non_reponse(&offre, &config, maintenant).await {
                Ok(true) => resultat.offres_expirees += 1,
                Ok(false) => {}
                Err(e) => tracing::warn!(
                    offre = %offre.id, erreur = %e,
                    "expiration d'offre impossible — retentée au tic suivant",
                ),
            }
        }

        // 2. Reprise FIFO — la plus ancienne d'abord (CMD-10). C'est aussi le
        //    chemin par lequel une cascade essoufflée bascule en broadcast.
        for commande in self.commandes.en_attente_coursier(zone).await? {
            match self.dispatcher(commande.commande_id, maintenant).await {
                Ok(_) => resultat.commandes_reprises += 1,
                Err(e) => tracing::warn!(
                    commande = %commande.commande_id, erreur = %e,
                    "reprise impossible — retentée au tic suivant",
                ),
            }
        }

        // 3. Escalade (DSP-06). Idempotente par le `NOT EXISTS` sur l'outbox :
        //    exactement une alerte par commande, quel que soit le chemin.
        match self.escalader(zone, &config, maintenant).await {
            Ok(n) => resultat.escalades = n,
            Err(e) => tracing::warn!(zone = %zone, erreur = %e, "escalade impossible"),
        }

        // 4. Réassignations (DSP-07), garde d'argent comprise.
        match self
            .reprendre_courses_immobiles(zone, &config, maintenant)
            .await
        {
            Ok((reprises, bloquees)) => {
                resultat.reassignations = reprises;
                resultat.courses_bloquees = bloquees;
            }
            Err(e) => tracing::warn!(zone = %zone, erreur = %e, "réassignations impossibles"),
        }

        // 5. Élagage des fantômes — ce qui est élagué est COMPTÉ (aucun plafond
        //    silencieux : une fuite d'index doit se voir).
        match self.elaguer_pool(zone).await {
            Ok(n) => resultat.fantomes_elagues = n,
            Err(e) => tracing::warn!(zone = %zone, erreur = %e, "élagage impossible"),
        }

        if resultat != ResultatTic::default() {
            tracing::info!(
                zone = %zone,
                offres_expirees = resultat.offres_expirees,
                commandes_reprises = resultat.commandes_reprises,
                escalades = resultat.escalades,
                reassignations = resultat.reassignations,
                courses_bloquees = resultat.courses_bloquees,
                fantomes_elagues = resultat.fantomes_elagues,
                "tic de dispatch",
            );
        }
        Ok(resultat)
    }
}
