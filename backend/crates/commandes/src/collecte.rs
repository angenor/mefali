//! Boucle de collecte par arrêt (en route, arrivé, indisponible) et remise.
//!
//! Le cycle QRC 006 n'avait posé qu'une transition d'arrêt :
//! `à_collecter → collecté` ([`crate::depot::PgCommandes::marquer_arret_collecte`]).
//! CMD 008 intercale la boucle DÉCLARATIVE du coursier — « je pars », « je suis
//! arrivé » — sans jamais retirer le chemin direct (data-model §3.3).
//!
//! Trois invariants tiennent tout le module :
//!
//! 1. **Garde unique** — aucune transition n'est écrite sans être passée par
//!    [`crate::etats::verifier_transition`]. Une transition absente de la table
//!    fermée est refusée, jamais « oubliée ».
//! 2. **Horodatage SERVEUR** — `en_route_le` et `arrive_le` sont posés par la
//!    base, jamais par l'horloge de l'appareil : `arrive_le` fonde la prime
//!    d'attente (TRF-06), c'est-à-dire de l'argent. L'horodatage local du
//!    coursier reste une donnée d'observation, transportée dans l'événement.
//! 3. **Idempotence par `transition_uuid_client`** — la file hors-ligne du
//!    coursier rejoue ses actions (constitution V). Un rejeu du même UUID rend
//!    l'état courant sans réécrire ni ré-émettre.

use chrono::{DateTime, Utc};
use serde_json::json;
use socle::{ecrire_evenement, NouvelEvenement};
use uuid::Uuid;

use crate::depot::PgCommandes;
use crate::etats::{verifier_transition, Acteur, Niveau};
use crate::modele::{ErreurCommandes, EtatLivraison, ProgressionCollecte, StatutArret, TypeArret};

/// Contexte d'un arrêt verrouillé en vue d'une transition.
///
/// Une seule lecture `FOR UPDATE` sert la garde de propriété, la garde d'état,
/// l'idempotence et le payload de l'événement : la ligne ne peut pas changer
/// entre la décision et l'écriture.
pub(crate) struct ContexteArret {
    /// Arrêt concerné.
    pub arret_id: Uuid,
    /// Segment porteur.
    pub segment_id: Uuid,
    /// Livraison porteuse.
    pub livraison_id: Uuid,
    /// Commande ancre.
    pub commande_id: Uuid,
    /// Statut courant de l'arrêt.
    pub statut: StatutArret,
    /// Collecte chez un vendeur, ou remise au client.
    pub type_arret: TypeArret,
    /// Rang de l'arrêt dans le segment (itinéraire optimisé).
    pub ordre: i16,
    /// Vendeur visé (`None` sur l'arrêt de remise).
    pub prestataire_id: Option<Uuid>,
    /// UUID de la DERNIÈRE transition déclarative acceptée (idempotence).
    pub transition_uuid_client: Option<Uuid>,
    /// Instant serveur du départ déclaré.
    pub en_route_le: Option<DateTime<Utc>>,
    /// État courant de la livraison.
    pub livraison_etat: EtatLivraison,
}

/// Résultat d'une transition d'arrêt, tel que la surface coursier le rend.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransitionArret {
    /// Arrêt concerné.
    pub arret_id: Uuid,
    /// Statut APRÈS la transition (ou statut courant, au rejeu).
    pub statut: StatutArret,
    /// Livraison porteuse.
    pub livraison_id: Uuid,
    /// Commande ancre.
    pub commande_id: Uuid,
    /// État de la livraison après l'éventuelle bascule.
    pub livraison_etat: EtatLivraison,
    /// Progression de COLLECTE de la livraison (la remise n'en est pas une).
    pub progression: ProgressionCollecte,
    /// Vrai si l'appel était un rejeu du même `uuid_client` : aucune écriture,
    /// aucun événement.
    pub rejeu: bool,
}

impl PgCommandes {
    /// Charge et VERROUILLE un arrêt en vue d'une transition, en vérifiant que
    /// la livraison porteuse est bien assignée à l'appelant.
    ///
    /// Deux refus distincts, et c'est voulu : un arrêt qui n'existe pas rend
    /// `404`, un arrêt qui existe mais appartient à la course d'un autre rend
    /// `403`. Confondre les deux ferait d'un identifiant deviné un oracle
    /// d'existence — ou, à l'inverse, masquerait une erreur d'affectation
    /// derrière un « inconnu » trompeur pour le support.
    pub(crate) async fn charger_arret_du_coursier(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        coursier: Uuid,
    ) -> Result<ContexteArret, ErreurCommandes> {
        let ligne = sqlx::query!(
            r#"SELECT a.id, a.segment_id, a.statut::text AS "statut!",
                      a.type_arret::text AS "type_arret!", a.ordre,
                      a.prestataire_id, a.transition_uuid_client, a.en_route_le,
                      s.livraison_id, l.commande_id, l.coursier_id,
                      l.etat::text AS "livraison_etat!"
               FROM commandes.arret a
               JOIN commandes.segment s ON s.id = a.segment_id
               JOIN commandes.livraison l ON l.id = s.livraison_id
               WHERE a.id = $1
               FOR UPDATE OF a"#,
            arret_id,
        )
        .fetch_optional(&mut **tx)
        .await?
        .ok_or(ErreurCommandes::ArretInconnu(arret_id))?;

        if ligne.coursier_id != Some(coursier) {
            return Err(ErreurCommandes::NonProprietaire);
        }

        Ok(ContexteArret {
            arret_id: ligne.id,
            segment_id: ligne.segment_id,
            livraison_id: ligne.livraison_id,
            commande_id: ligne.commande_id,
            statut: ligne.statut.parse()?,
            type_arret: ligne.type_arret.parse()?,
            ordre: ligne.ordre,
            prestataire_id: ligne.prestataire_id,
            transition_uuid_client: ligne.transition_uuid_client,
            en_route_le: ligne.en_route_le,
            livraison_etat: ligne.livraison_etat.parse()?,
        })
    }

    /// `à_collecter → en_route` — le coursier déclare partir vers l'arrêt.
    ///
    /// Idempotent par `uuid_client` (file hors-ligne, constitution V).
    pub async fn marquer_arret_en_route(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        coursier: Uuid,
        uuid_client: Uuid,
        horodatage_local: DateTime<Utc>,
        horodatage_serveur: DateTime<Utc>,
    ) -> Result<TransitionArret, ErreurCommandes> {
        let ctx = self.charger_arret_du_coursier(tx, arret_id, coursier).await?;

        if let Some(rejeu) = self.rejeu_transition(tx, &ctx, uuid_client).await? {
            return Ok(rejeu);
        }

        verifier_transition(
            Niveau::Arret,
            Some(ctx.statut.comme_str()),
            StatutArret::EnRoute.comme_str(),
            Acteur::Coursier,
        )?;

        sqlx::query!(
            "UPDATE commandes.arret
                SET statut = 'en_route', en_route_le = $2, transition_uuid_client = $3
              WHERE id = $1",
            arret_id,
            horodatage_serveur,
            uuid_client,
        )
        .execute(&mut **tx)
        .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "arret.en_route",
                entite_type: "arret",
                entite_id: arret_id,
                payload: json!({
                    "commande": ctx.commande_id,
                    "livraison": ctx.livraison_id,
                    "segment": ctx.segment_id,
                    "type_arret": ctx.type_arret.comme_str(),
                    "ordre": ctx.ordre,
                    "prestataire": ctx.prestataire_id,
                    // Observation seulement : c'est l'horodatage SERVEUR qui
                    // fait foi (dérive d'horloge, mode hors ligne).
                    "derive_horloge_s": (horodatage_serveur - horodatage_local).num_seconds(),
                    "acteur": coursier,
                }),
                survenu_le: horodatage_serveur,
            },
        )
        .await?;

        self.resultat_transition(tx, &ctx, StatutArret::EnRoute, ctx.livraison_etat, false)
            .await
    }

    /// `en_route → arrivé` — arrivée géolocalisée. `arrive_le` fonde la **prime
    /// d'attente** TRF-06 : c'est le début de l'attente facturable, et c'est
    /// pour cela que `en_route → collecte` n'existe pas dans la table fermée
    /// (data-model §3.3) — sauter l'arrivée reviendrait à effacer une créance
    /// du coursier.
    pub async fn marquer_arret_arrive(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        coursier: Uuid,
        uuid_client: Uuid,
        horodatage_local: DateTime<Utc>,
        horodatage_serveur: DateTime<Utc>,
    ) -> Result<TransitionArret, ErreurCommandes> {
        let ctx = self.charger_arret_du_coursier(tx, arret_id, coursier).await?;

        if let Some(rejeu) = self.rejeu_transition(tx, &ctx, uuid_client).await? {
            return Ok(rejeu);
        }

        verifier_transition(
            Niveau::Arret,
            Some(ctx.statut.comme_str()),
            StatutArret::Arrive.comme_str(),
            Acteur::Coursier,
        )?;

        sqlx::query!(
            "UPDATE commandes.arret
                SET statut = 'arrive', arrive_le = $2, transition_uuid_client = $3
              WHERE id = $1",
            arret_id,
            horodatage_serveur,
            uuid_client,
        )
        .execute(&mut **tx)
        .await?;

        // Durée du trajet déclaré : `arret.en_route` → `arret.arrive`. L'attente
        // FACTURABLE, elle, démarre à `arrive_le` et se ferme au scan — c'est
        // `tarification::Attente { arrivee, scan }` qui la calcule.
        let attente_depuis_s = ctx
            .en_route_le
            .map(|depart| (horodatage_serveur - depart).num_seconds().max(0));

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "arret.arrive",
                entite_type: "arret",
                entite_id: arret_id,
                payload: json!({
                    "commande": ctx.commande_id,
                    "livraison": ctx.livraison_id,
                    "segment": ctx.segment_id,
                    "type_arret": ctx.type_arret.comme_str(),
                    "ordre": ctx.ordre,
                    "prestataire": ctx.prestataire_id,
                    "attente_depuis_s": attente_depuis_s,
                    "derive_horloge_s": (horodatage_serveur - horodatage_local).num_seconds(),
                    "acteur": coursier,
                }),
                survenu_le: horodatage_serveur,
            },
        )
        .await?;

        self.resultat_transition(tx, &ctx, StatutArret::Arrive, ctx.livraison_etat, false)
            .await
    }

    /// Rejeu du MÊME `uuid_client` : l'état courant, sans écriture ni événement.
    ///
    /// La file hors-ligne du coursier renvoie ses actions jusqu'à acquittement
    /// (constitution V) ; deux `en-route` du même UUID ne doivent produire
    /// qu'un seul horodatage et un seul événement.
    async fn rejeu_transition(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ctx: &ContexteArret,
        uuid_client: Uuid,
    ) -> Result<Option<TransitionArret>, ErreurCommandes> {
        if ctx.transition_uuid_client != Some(uuid_client) {
            return Ok(None);
        }
        let resultat = self
            .resultat_transition(tx, ctx, ctx.statut, ctx.livraison_etat, true)
            .await?;
        Ok(Some(resultat))
    }

    /// Assemble le résultat d'une transition avec la progression de collecte
    /// courante (lecture seule).
    async fn resultat_transition(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        ctx: &ContexteArret,
        statut: StatutArret,
        livraison_etat: EtatLivraison,
        rejeu: bool,
    ) -> Result<TransitionArret, ErreurCommandes> {
        let progression = self
            .progression(tx, ctx.livraison_id, livraison_etat == EtatLivraison::EnLivraison)
            .await?;
        Ok(TransitionArret {
            arret_id: ctx.arret_id,
            statut,
            livraison_id: ctx.livraison_id,
            commande_id: ctx.commande_id,
            livraison_etat,
            progression,
            rejeu,
        })
    }
}
