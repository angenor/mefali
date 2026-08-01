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

/// Motif d'un arrêt entièrement indisponible (taxonomie `arret.indisponible`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifIndisponible {
    /// Le coursier constate le vendeur fermé — avant ou pendant le trajet.
    VendeurFerme,
    /// Toutes les lignes de l'arrêt ont été retirées ou refusées (CMD-06).
    ToutesLignesRetirees,
}

impl MotifIndisponible {
    /// Valeur journalisée dans le payload de l'événement.
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifIndisponible::VendeurFerme => "vendeur_ferme",
            MotifIndisponible::ToutesLignesRetirees => "toutes_lignes_retirees",
        }
    }
}

impl std::str::FromStr for MotifIndisponible {
    type Err = ErreurCommandes;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "vendeur_ferme" => Ok(MotifIndisponible::VendeurFerme),
            "toutes_lignes_retirees" => Ok(MotifIndisponible::ToutesLignesRetirees),
            autre => Err(ErreurCommandes::StatutInconnu(autre.to_owned())),
        }
    }
}

/// Motif porté par `ligne.retiree` quand c'est l'ARRÊT qui est indisponible —
/// à distinguer d'un retrait décidé par la préférence du client (T047).
pub(crate) const MOTIF_LIGNE_ARRET_INDISPONIBLE: &str = "arret_indisponible";

/// Action déclarative du coursier sur un arrêt (surface `course_http`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActionArret {
    /// « Je pars vers cet arrêt. »
    EnRoute,
    /// « J'y suis. » — pose `arrive_le`, base de la prime d'attente TRF-06.
    Arrive,
    /// « Rien à prendre ici. » — vendeur fermé, ou plus une ligne à collecter.
    Indisponible(MotifIndisponible),
}

/// Demande de transition d'arrêt, telle qu'elle arrive de l'app coursier.
///
/// `uuid_client` et `horodatage_local` sont **obligatoires** (constitution V) :
/// le premier rend l'action rejouable sans doublon, le second dit ce que
/// l'appareil croyait — la base, elle, n'écrit que son propre horodatage.
#[derive(Debug, Clone, Copy)]
pub struct DemandeTransitionArret {
    /// Livraison de l'URL — doit être celle qui porte l'arrêt.
    pub livraison_id: Uuid,
    /// Arrêt visé.
    pub arret_id: Uuid,
    /// Ce que le coursier déclare.
    pub action: ActionArret,
    /// Clé d'idempotence de la file hors-ligne.
    pub uuid_client: Uuid,
    /// Horodatage de l'appareil (observation).
    pub horodatage_local: DateTime<Utc>,
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
    /// Point d'entrée UNIQUE des trois transitions déclaratives du coursier.
    ///
    /// Ouvre la transaction, vérifie que l'arrêt appartient bien à la livraison
    /// de l'URL, puis délègue. Une seule porte pour trois endpoints : la
    /// surface HTTP ne manipule jamais de transaction, et les trois actions ne
    /// peuvent pas diverger sur les gardes.
    pub async fn transiter_arret(
        &self,
        coursier: Uuid,
        demande: DemandeTransitionArret,
    ) -> Result<TransitionArret, ErreurCommandes> {
        let horodatage_serveur = Utc::now();
        let mut tx = self.pool.begin().await?;

        // L'arrêt doit être CELUI de la livraison nommée dans l'URL — sans quoi
        // `/courses/{a}/arrets/{x}` ferait avancer la course d'un autre.
        let appartient = sqlx::query_scalar!(
            "SELECT EXISTS (
                 SELECT 1 FROM commandes.arret a
                 JOIN commandes.segment s ON s.id = a.segment_id
                 WHERE a.id = $1 AND s.livraison_id = $2
             ) AS \"existe!\"",
            demande.arret_id,
            demande.livraison_id,
        )
        .fetch_one(&mut *tx)
        .await?;
        if !appartient {
            return Err(ErreurCommandes::ArretInconnu(demande.arret_id));
        }

        let resultat = match self.transiter_sous_verrou(&mut tx, coursier, &demande, horodatage_serveur).await {
            Ok(resultat) => resultat,
            // ── Refus de PROPRIÉTÉ au rejeu (FR-006, FR-088) ─────────────
            // La course a changé de porteur pendant la coupure. On abandonne la
            // transaction (rien n'a été écrit) et on TRACE : l'exploitation doit
            // voir passer ce cas — derrière lui, il y a une avance engagée par
            // quelqu'un qui n'est plus assigné (SC-016).
            Err(ErreurCommandes::NonProprietaire) => {
                drop(tx);
                self.tracer_refus_de_transition(demande.livraison_id, coursier, horodatage_serveur)
                    .await?;
                return Err(ErreurCommandes::NonProprietaire);
            }
            Err(autre) => return Err(autre),
        };

        tx.commit().await?;
        Ok(resultat)
    }

    /// Le corps de [`Self::transiter_arret`], sous verrou — séparé pour que la
    /// garde de propriété puisse être interceptée sans dupliquer les trois bras.
    async fn transiter_sous_verrou(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        coursier: Uuid,
        demande: &DemandeTransitionArret,
        horodatage_serveur: DateTime<Utc>,
    ) -> Result<TransitionArret, ErreurCommandes> {
        // ── Rejeu d'une transition DÉJÀ appliquée, quel que soit son rang ──
        // La file rejoue un LOT dans l'ordre, et le rejoue en entier tant
        // qu'elle n'a pas pu retirer ses actions acquittées. Comparer au seul
        // DERNIER `uuid_client` (cycle 008) faisait échouer le rejeu d'un
        // « en-route » suivi d'un « arrivé » — sur la table fermée, donc en
        // 409, donc classé « refus définitif » par l'app : Yao aurait vu une
        // action réussie affichée comme rejetée (FR-089).
        let ctx = self
            .charger_arret_du_coursier(tx, demande.arret_id, coursier)
            .await?;
        let deja = sqlx::query_scalar!(
            "SELECT EXISTS (
                 SELECT 1 FROM commandes.transition_arret_rejouee WHERE uuid_client = $1
             ) AS \"existe!\"",
            demande.uuid_client,
        )
        .fetch_one(&mut **tx)
        .await?;
        if deja {
            return self
                .resultat_transition(tx, &ctx, ctx.statut, ctx.livraison_etat, true)
                .await;
        }

        let resultat = match demande.action {
            ActionArret::EnRoute => {
                self.marquer_arret_en_route(
                    tx,
                    demande.arret_id,
                    coursier,
                    demande.uuid_client,
                    demande.horodatage_local,
                    horodatage_serveur,
                )
                .await?
            }
            ActionArret::Arrive => {
                self.marquer_arret_arrive(
                    tx,
                    demande.arret_id,
                    coursier,
                    demande.uuid_client,
                    demande.horodatage_local,
                    horodatage_serveur,
                )
                .await?
            }
            ActionArret::Indisponible(motif) => {
                self.marquer_arret_indisponible(
                    tx,
                    demande.arret_id,
                    coursier,
                    demande.uuid_client,
                    motif,
                    demande.horodatage_local,
                    horodatage_serveur,
                )
                .await?
            }
        };

        // Mémorise l'UUID accepté — dans la MÊME transaction que la transition :
        // une transition écrite dont l'UUID ne serait pas mémorisé se rejouerait
        // et se ferait refuser.
        sqlx::query!(
            "INSERT INTO commandes.transition_arret_rejouee (uuid_client, arret_id, action)
             VALUES ($1, $2, $3) ON CONFLICT (uuid_client) DO NOTHING",
            demande.uuid_client,
            demande.arret_id,
            match demande.action {
                ActionArret::EnRoute => "en_route",
                ActionArret::Arrive => "arrive",
                ActionArret::Indisponible(_) => "indisponible",
            },
        )
        .execute(&mut **tx)
        .await?;

        Ok(resultat)
    }

    /// Trace le refus d'une transition d'arrêt au rejeu (FR-088).
    async fn tracer_refus_de_transition(
        &self,
        livraison_id: Uuid,
        coursier: Uuid,
        maintenant: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        let commande_id = sqlx::query_scalar!(
            "SELECT commande_id FROM commandes.livraison WHERE id = $1",
            livraison_id,
        )
        .fetch_optional(&self.pool)
        .await?;
        let Some(commande_id) = commande_id else {
            return Ok(());
        };
        self.tracer_action_refusee(
            livraison_id,
            commande_id,
            coursier,
            "transition",
            maintenant,
        )
        .await
    }

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

        let livraison_etat = self
            .ouvrir_collecte_si_besoin(
                tx,
                ctx.livraison_id,
                ctx.commande_id,
                arret_id,
                ctx.livraison_etat,
                coursier,
                horodatage_serveur,
            )
            .await?;

        self.resultat_transition(tx, &ctx, StatutArret::EnRoute, livraison_etat, false)
            .await
    }

    /// Ouvre la collecte d'une course encore `assignee` (data-model §3.2).
    ///
    /// Appelée par **TOUTE** première action sur un arrêt — départ déclaré,
    /// scan direct du cycle 006, ou constat d'indisponibilité. Ne la brancher
    /// que sur le départ déclaré laisserait la course d'un coursier qui scanne
    /// sans déclarer son trajet bloquée en `assignee` pour toujours : le gating
    /// EN_LIVRAISON ne se déclenche que depuis `en_collecte`, et le chemin
    /// direct `à_collecter → collecte` est explicitement autorisé.
    ///
    /// La condition porte sur l'ÉTAT de la livraison, jamais sur « est-ce
    /// l'arrêt d'ordre 0 ? » : une course reprise après réassignation n'a plus
    /// forcément son premier arrêt disponible.
    #[allow(clippy::too_many_arguments)]
    pub(crate) async fn ouvrir_collecte_si_besoin(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        commande_id: Uuid,
        arret_id: Uuid,
        etat_courant: EtatLivraison,
        coursier: Uuid,
        horodatage_serveur: DateTime<Utc>,
    ) -> Result<EtatLivraison, ErreurCommandes> {
        if etat_courant != EtatLivraison::Assignee {
            return Ok(etat_courant);
        }
        self.transition_livraison(
            tx,
            livraison_id,
            EtatLivraison::EnCollecte,
            Acteur::Coursier,
            horodatage_serveur,
            Some(NouvelEvenement {
                type_evenement: "livraison.mise_en_collecte",
                entite_type: "livraison",
                entite_id: livraison_id,
                payload: json!({
                    "commande": commande_id,
                    "arret": arret_id,
                    "acteur": coursier,
                }),
                survenu_le: horodatage_serveur,
            }),
        )
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

    /// Arrêt **entièrement indisponible** (FR-051) : vendeur fermé constaté, ou
    /// toutes les lignes de l'arrêt retirées.
    ///
    /// Trois conséquences, indissociables :
    /// 1. l'arrêt est **RÉSOLU** pour le gating (`StatutArret::est_resolu`) —
    ///    une course ne reste pas coincée parce qu'un étal a fermé ;
    /// 2. le **montant avancé tombe à zéro** — le coursier n'a rien acheté, il
    ///    ne doit rien avancer, et l'avance nulle est ce qui le prouve ;
    /// 3. les lignes de l'arrêt sont **retirées** et le montant de la commande
    ///    révisé — le client ne paie pas ce qui n'a pas été acheté. Le devis de
    ///    livraison, lui, ne bouge pas (FR-050).
    // Huit paramètres : `tx` + l'arrêt + le coursier + l'uuid d'idempotence
    // + le motif + les DEUX horodatages (local déclaré, serveur constaté — la
    // constitution exige qu'ils restent distincts). Même arbitrage que
    // `marquer_arret_collecte` juste au-dessus.
    #[allow(clippy::too_many_arguments)]
    pub async fn marquer_arret_indisponible(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        arret_id: Uuid,
        coursier: Uuid,
        uuid_client: Uuid,
        motif: MotifIndisponible,
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
            StatutArret::Indisponible.comme_str(),
            Acteur::Coursier,
        )?;

        sqlx::query!(
            "UPDATE commandes.arret
                SET statut = 'indisponible', montant_avance = 0,
                    transition_uuid_client = $2
              WHERE id = $1",
            arret_id,
            uuid_client,
        )
        .execute(&mut **tx)
        .await?;

        let (nb_lignes_retirees, montant_retire) = self
            .retirer_lignes_de_l_arret(
                tx,
                arret_id,
                ctx.commande_id,
                MOTIF_LIGNE_ARRET_INDISPONIBLE,
                horodatage_serveur,
            )
            .await?;

        ecrire_evenement(
            tx,
            NouvelEvenement {
                type_evenement: "arret.indisponible",
                entite_type: "arret",
                entite_id: arret_id,
                payload: json!({
                    "commande": ctx.commande_id,
                    "livraison": ctx.livraison_id,
                    "segment": ctx.segment_id,
                    "ordre": ctx.ordre,
                    "prestataire": ctx.prestataire_id,
                    "nb_lignes_retirees": nb_lignes_retirees,
                    "montant_retire": montant_retire,
                    "motif": motif.comme_str(),
                    "derive_horloge_s": (horodatage_serveur - horodatage_local).num_seconds(),
                    "acteur": coursier,
                }),
                survenu_le: horodatage_serveur,
            },
        )
        .await?;

        // Un constat d'indisponibilité peut être la PREMIÈRE action de la
        // course (étal fermé avant même d'y aller) comme la DERNIÈRE : il faut
        // donc et l'ouverture de collecte, et le gating.
        let livraison_etat = self
            .ouvrir_collecte_si_besoin(
                tx,
                ctx.livraison_id,
                ctx.commande_id,
                arret_id,
                ctx.livraison_etat,
                coursier,
                horodatage_serveur,
            )
            .await?;
        let progression = self
            .gating_livraison(
                tx,
                ctx.livraison_id,
                ctx.commande_id,
                coursier,
                horodatage_serveur,
                livraison_etat == EtatLivraison::EnCollecte,
            )
            .await?;

        Ok(TransitionArret {
            arret_id,
            statut: StatutArret::Indisponible,
            livraison_id: ctx.livraison_id,
            commande_id: ctx.commande_id,
            livraison_etat: if progression.en_livraison {
                EtatLivraison::EnLivraison
            } else {
                livraison_etat
            },
            progression,
            rejeu: false,
        })
    }

    /// Clôt la course : la livraison passe `livree`, le tronc `terminee`, dans
    /// la MÊME transaction et sous la garde des deux niveaux.
    ///
    /// ⚠ **Cette méthode ne VÉRIFIE rien** : elle écrit la fin d'une remise déjà
    /// prouvée. La preuve — jeton QR, code de secours ou dépôt photographié,
    /// avec son compteur d'essais — est posée par T058, qui appelle ceci en
    /// dernier. Séparer les deux garde la machine à états lisible et empêche
    /// qu'une future modalité de remise réinvente ses propres transitions.
    ///
    /// Le paiement passe `regle` : la contrainte `commande_terminee_payee`
    /// l'exige, et c'est la traduction en base de « un seul montant, encaissé
    /// en une fois » (constitution III).
    // Huit paramètres : `tx` + la livraison + la commande + le mode de remise
    // + le nombre d'essais du code + le coursier + l'horodatage. Tous sont
    // écrits en base par cette clôture. Même arbitrage que
    // `marquer_arret_collecte`.
    #[allow(clippy::too_many_arguments)]
    pub async fn cloturer_livraison_prouvee(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        livraison_id: Uuid,
        commande_id: Uuid,
        mode_remise: &str,
        essais_code: i16,
        coursier: Uuid,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        self.transition_livraison(
            tx,
            livraison_id,
            EtatLivraison::Livree,
            Acteur::Coursier,
            horodatage,
            Some(NouvelEvenement {
                type_evenement: "livraison.livree",
                entite_type: "livraison",
                entite_id: livraison_id,
                payload: json!({
                    "commande": commande_id,
                    "mode_remise": mode_remise,
                    "essais_code": essais_code,
                    "acteur": coursier,
                }),
                survenu_le: horodatage,
            }),
        )
        .await?;

        sqlx::query!(
            "UPDATE commandes.livraison SET livree_le = $2, mode_remise = $3 WHERE id = $1",
            livraison_id,
            horodatage,
            mode_remise,
        )
        .execute(&mut **tx)
        .await?;

        let commande = sqlx::query!(
            r#"SELECT cree_le, total_unites, devise,
                      etat_paiement::text AS "etat_paiement!"
               FROM commandes.commande WHERE id = $1"#,
            commande_id,
        )
        .fetch_one(&mut **tx)
        .await?;

        // Un remboursement déjà prononcé n'est pas écrasé par l'encaissement.
        if commande.etat_paiement != "rembourse" {
            sqlx::query!(
                "UPDATE commandes.commande SET etat_paiement = 'regle' WHERE id = $1",
                commande_id,
            )
            .execute(&mut **tx)
            .await?;
        }

        self.transition_commande(
            tx,
            commande_id,
            crate::modele::EtatCommande::Terminee,
            Acteur::Coursier,
            horodatage,
            Some(NouvelEvenement {
                type_evenement: "commande.terminee",
                entite_type: "commande",
                entite_id: commande_id,
                payload: json!({
                    "mode_remise": mode_remise,
                    "duree_totale_s": (horodatage - commande.cree_le).num_seconds().max(0),
                    "total_encaisse": commande.total_unites,
                    "devise": commande.devise,
                }),
                survenu_le: horodatage,
            }),
        )
        .await?;

        Ok(())
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

// ── Remise (US9 / T058) ────────────────────────────────────────────────────

/// Comment le coursier prouve la remise (contrat §2).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PreuveRemise {
    /// Jeton lu dans le QR de réception du client.
    Qr(String),
    /// Code à 4 chiffres dicté par le client (mode dégradé).
    Code(String),
    /// Dépôt convenu : photo sur place, aucun secret à présenter (§7.4-5).
    ///
    /// La photo voyage **avec** la demande (R18) — c'est ce qui rend cette
    /// troisième voie utilisable hors ligne : référencer un objet « déjà
    /// déposé » supposait le réseau au moment précis où il manque.
    Depot {
        /// Octets de la photo prise sur place, à déposer à la réception.
        photo: Option<Vec<u8>>,
        /// Type MIME de la photo.
        mime: String,
        /// Clé d'un objet **déjà** déposé — accepté pour ne casser aucun
        /// appelant du cycle 008 ; l'app coursier ne l'utilise jamais (R18).
        photo_cle: Option<String>,
    },
}

impl PreuveRemise {
    /// Valeur journalisée dans `mode_remise` et dans les événements.
    pub fn mode(&self) -> &'static str {
        match self {
            PreuveRemise::Qr(_) => "qr",
            PreuveRemise::Code(_) => "code",
            PreuveRemise::Depot { .. } => "depot",
        }
    }
}

/// Résultat d'une remise validée.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RemiseFaite {
    /// Commande close.
    pub commande_id: Uuid,
    /// Livraison close.
    pub livraison_id: Uuid,
    /// Mode retenu.
    pub mode_remise: String,
    /// Nombre d'essais de code consommés.
    pub essais_code: i16,
    /// Rejeu du MÊME `uuid_client` : rien n'a été réécrit ni ré-émis (R4).
    pub rejeu: bool,
}

/// Demande de remise reçue de la file hors-ligne du coursier (contrat §2).
///
/// Trois champs de plus qu'au cycle 008, et chacun répare un manque nommé :
///
/// - `uuid_client` rend l'action **idempotente** (R4) — sans lui, le test qui
///   fait foi du module (FR-089) est impossible : couper le réseau entre le scan
///   et la livraison, c'est précisément rejouer une remise ;
/// - `essais_hors_ligne` transporte les essais **faux** consommés sans réseau,
///   que l'app compte localement et n'envoie **pas un par un** (R5) ;
/// - `hors_ligne` journalise le fait que la validation a eu lieu sur l'appareil
///   — journalisé, **jamais décisif** : le serveur revalide ici même (FR-046).
// Pas d'`Eq` : la position du dépôt est un couple de `f64`, et deux positions
// « égales » au bit près ne veulent rien dire de plus qu'un `PartialEq`.
#[derive(Debug, Clone, PartialEq)]
pub struct DemandeRemise {
    /// Identifiant d'action de la file — l'idempotence tient dessus.
    pub uuid_client: Uuid,
    /// Preuve présentée : jeton QR, code dicté, ou dépôt photographié.
    pub preuve: PreuveRemise,
    /// Essais faux consommés HORS LIGNE, à consolider avec le compteur serveur.
    pub essais_hors_ligne: i16,
    /// La validation a-t-elle eu lieu sans réseau ?
    pub hors_ligne: bool,
    /// Position du dépôt (mode `depot` uniquement) — arrondie, jamais un tracé.
    pub depot_lat: Option<f64>,
    /// Voir [`DemandeRemise::depot_lat`].
    pub depot_lon: Option<f64>,
}

impl DemandeRemise {
    /// Demande minimale : une preuve, un identifiant d'action, rien d'autre.
    pub fn nouvelle(uuid_client: Uuid, preuve: PreuveRemise) -> Self {
        Self {
            uuid_client,
            preuve,
            essais_hors_ligne: 0,
            hors_ligne: false,
            depot_lat: None,
            depot_lon: None,
        }
    }
}

impl PgCommandes {
    /// Valide la remise et clôt la course (CMD-08, contrat §2).
    ///
    /// ⚠ **Le coursier ne reçoit JAMAIS le code** (research R6) : il en reçoit
    /// l'empreinte au pré-provisionnement, et c'est le client qui le lui dicte.
    /// La comparaison a donc lieu ici, côté serveur, sur la valeur stockée.
    ///
    /// Le compteur d'essais est **par commande** et persistant : trois erreurs
    /// et le code est verrouillé (`423`) jusqu'à intervention admin. Sans
    /// plafond, quatre chiffres se devinent en quelques minutes ; avec lui, la
    /// fenêtre se referme avant.
    pub async fn valider_remise(
        &self,
        livraison_id: Uuid,
        coursier: Uuid,
        demande: DemandeRemise,
        horodatage: DateTime<Utc>,
    ) -> Result<RemiseFaite, ErreurCommandes> {
        // Une seule transaction, ouverte AVANT la lecture et verrouillant les
        // deux lignes : sans elle, deux rejeux simultanés de la file (réseau qui
        // revient pendant un drain) liraient tous deux « pas encore remise » et
        // écriraient deux fois. L'unicité de `remise_uuid_client` rattraperait
        // le doublon par une erreur SQL, ce qui est un filet, pas une garantie.
        let mut tx = self.pool.begin().await?;
        let contexte = sqlx::query!(
            r#"SELECT l.commande_id, l.coursier_id, l.etat::text AS "etat!",
                      l.remise_uuid_client, l.mode_remise,
                      c.code_livraison, c.jeton_reception, c.essais_code, c.zone_id,
                      c.depot_autorise,
                      (c.code_bloque_le IS NOT NULL
                       AND (c.code_debloque_le IS NULL
                            OR c.code_debloque_le < c.code_bloque_le)) AS "code_bloque!"
               FROM commandes.livraison l
               JOIN commandes.commande c ON c.id = l.commande_id
               WHERE l.id = $1
               FOR UPDATE OF l, c"#,
            livraison_id,
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(ErreurCommandes::LivraisonInconnue(livraison_id))?;

        // La propriété d'ABORD, y compris au rejeu (FR-006) : une course
        // réassignée pendant une coupure ne se laisse pas clore par son ancien
        // porteur, même s'il rejoue un UUID qu'il avait bien émis.
        if contexte.coursier_id != Some(coursier) {
            // La transaction est abandonnée (rien n'a été écrit) ; la trace part
            // dans la sienne — c'est un événement d'OPÉRATIONS, il ne partage
            // pas le sort d'une mutation qui n'a pas eu lieu (FR-088).
            drop(tx);
            self.tracer_action_refusee(
                livraison_id,
                contexte.commande_id,
                coursier,
                "remise",
                horodatage,
            )
            .await?;
            return Err(ErreurCommandes::NonProprietaire);
        }

        // ── Rejeu du MÊME uuid_client : l'état courant, rien de plus (R4) ──
        // Ni écriture, ni événement, ni second `commande.terminee`. C'est la
        // moitié serveur du test qui fait foi (FR-089).
        if contexte.remise_uuid_client == Some(demande.uuid_client) {
            return Ok(RemiseFaite {
                commande_id: contexte.commande_id,
                livraison_id,
                mode_remise: contexte
                    .mode_remise
                    .unwrap_or_else(|| demande.preuve.mode().to_owned()),
                essais_code: contexte.essais_code,
                rejeu: true,
            });
        }

        // ── Garde serveur du dépôt (FR-048, T034) ─────────────────────────
        // L'app ne propose la voie dépôt que si le drapeau est ouvert ; la garde
        // est des DEUX côtés parce qu'une file hors ligne peut avoir été remplie
        // avant que l'exploitation ne referme le drapeau — et parce qu'un client
        // HTTP n'est pas notre app.
        if matches!(demande.preuve, PreuveRemise::Depot { .. }) && !contexte.depot_autorise {
            return Err(ErreurCommandes::DepotNonAutorise);
        }

        let essais_max = self
            .parametre_i64(contexte.zone_id, "commande.essais_code_livraison")
            .await? as i16;

        // ── Consolidation des essais : max(serveur, hors ligne) (R5) ───────
        // Les essais faux consommés sans réseau ne voyagent pas un par un ; ils
        // arrivent AVEC la demande. Le `max` est la seule règle qui ne perd
        // jamais un essai et n'en invente jamais : un compteur purement local se
        // remet à zéro à la réinstallation, un compteur purement serveur ne voit
        // rien de ce qui s'est passé devant la porte.
        let mut essais_code = contexte.essais_code.max(demande.essais_hors_ligne.max(0));
        let mut bloque = contexte.code_bloque;
        if essais_code > contexte.essais_code {
            self.consigner_essais(
                &mut tx,
                contexte.commande_id,
                livraison_id,
                coursier,
                essais_code,
                essais_max,
                bloque,
                horodatage,
            )
            .await?;
            bloque = bloque || essais_code >= essais_max;
        }

        match &demande.preuve {
            // Le QR ne se devine pas : pas de compteur d'essais dessus, et —
            // FR-043 — il reste la voie ouverte quand le code est bloqué. Le
            // cycle 008 verrouillait les TROIS voies ; la maquette K4-1d montre
            // « scan QR toujours proposé » à côté du blocage.
            PreuveRemise::Qr(jeton) if *jeton != contexte.jeton_reception => {
                tx.commit().await?;
                return Err(ErreurCommandes::RemiseIncorrecte);
            }
            PreuveRemise::Code(_) if bloque => {
                tx.commit().await?;
                return Err(ErreurCommandes::CodeEpuise);
            }
            PreuveRemise::Code(code) if *code != contexte.code_livraison => {
                essais_code += 1;
                self.consigner_essais(
                    &mut tx,
                    contexte.commande_id,
                    livraison_id,
                    coursier,
                    essais_code,
                    essais_max,
                    bloque,
                    horodatage,
                )
                .await?;
                let epuise = essais_code >= essais_max;
                tx.commit().await?;

                if epuise {
                    return Err(ErreurCommandes::CodeEpuise);
                }
                return Err(ErreurCommandes::RemiseIncorrecte);
            }
            _ => {}
        }

        if let PreuveRemise::Depot {
            photo,
            mime,
            photo_cle,
        } = &demande.preuve
        {
            // La photo prise sur place l'emporte sur une clé fournie : c'est la
            // preuve du terrain, l'autre n'est qu'un chemin de compatibilité.
            let cle = match photo {
                Some(octets) => {
                    let cle = format!("commandes/depots/{livraison_id}");
                    self.objets
                        .deposer(&cle, octets.clone(), mime)
                        .await
                        .map_err(|e| ErreurCommandes::Dependance(e.to_string()))?;
                    cle
                }
                None => photo_cle
                    .clone()
                    // FR-048 : « photo sur place ET position ». Un dépôt sans
                    // photo ne prouve rien — et c'est justement la voie dont on
                    // pourrait le plus facilement abuser.
                    .ok_or_else(|| {
                        ErreurCommandes::PanierInvalide(
                            "un dépôt exige une photo sur place".to_owned(),
                        )
                    })?,
            };
            sqlx::query!(
                "UPDATE commandes.livraison
                 SET depot_photo_cle = $2, depot_lat = $3, depot_lon = $4
                 WHERE id = $1",
                livraison_id,
                cle,
                demande.depot_lat,
                demande.depot_lon,
            )
            .execute(&mut *tx)
            .await?;
        }

        // L'idempotence et la trace du hors-ligne AVANT la clôture : si la
        // clôture échoue, la transaction entière tombe et l'UUID reste libre.
        sqlx::query!(
            "UPDATE commandes.livraison
             SET remise_uuid_client = $2, remise_hors_ligne = $3
             WHERE id = $1",
            livraison_id,
            demande.uuid_client,
            demande.hors_ligne,
        )
        .execute(&mut *tx)
        .await?;

        self.cloturer_livraison_prouvee(
            &mut tx,
            livraison_id,
            contexte.commande_id,
            demande.preuve.mode(),
            essais_code,
            coursier,
            horodatage,
        )
        .await?;
        tx.commit().await?;

        Ok(RemiseFaite {
            commande_id: contexte.commande_id,
            livraison_id,
            mode_remise: demande.preuve.mode().to_owned(),
            essais_code,
            rejeu: false,
        })
    }

    /// Écrit le compteur d'essais, et pose le blocage DURABLE au seuil.
    ///
    /// L'alerte d'exploitation part dans la MÊME transaction que le compteur qui
    /// l'a déclenchée (FR-044) : un verrou sans alerte laisserait la commande
    /// bloquée à la porte du client sans que personne ne le sache — et un humain
    /// ne s'abonne pas à un `tracing::warn!`.
    ///
    /// Le blocage est un **état de la commande** (`code_bloque_le`), pas un
    /// compteur volatil : un coursier qui réinstalle l'app ne repart pas à zéro
    /// (R5).
    #[allow(clippy::too_many_arguments)]
    async fn consigner_essais(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        commande_id: Uuid,
        livraison_id: Uuid,
        coursier: Uuid,
        essais: i16,
        essais_max: i16,
        deja_bloque: bool,
        horodatage: DateTime<Utc>,
    ) -> Result<(), ErreurCommandes> {
        let bloque_maintenant = !deja_bloque && essais >= essais_max;
        sqlx::query!(
            "UPDATE commandes.commande
             SET essais_code = $2,
                 code_bloque_le = CASE WHEN $3 THEN $4 ELSE code_bloque_le END
             WHERE id = $1",
            commande_id,
            essais,
            bloque_maintenant,
            horodatage,
        )
        .execute(&mut **tx)
        .await?;

        if bloque_maintenant {
            ecrire_evenement(
                tx,
                NouvelEvenement {
                    type_evenement: "remise.code_epuise",
                    entite_type: "commande",
                    entite_id: commande_id,
                    payload: json!({
                        "livraison": livraison_id,
                        "essais": essais,
                        "acteur": coursier,
                    }),
                    survenu_le: horodatage,
                },
            )
            .await?;
            tracing::warn!(
                commande = %commande_id,
                essais,
                "code de remise ÉPUISÉ — intervention admin requise",
            );
        }
        Ok(())
    }
}
