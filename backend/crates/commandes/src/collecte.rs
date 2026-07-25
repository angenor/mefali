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

        let resultat = match demande.action {
            ActionArret::EnRoute => {
                self.marquer_arret_en_route(
                    &mut tx,
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
                    &mut tx,
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
                    &mut tx,
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

        tx.commit().await?;
        Ok(resultat)
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

        // Le PREMIER départ ouvre la collecte (data-model §3.2). La condition
        // porte sur l'état de la livraison, jamais sur « est-ce le premier
        // arrêt ? » : une course reprise après réassignation n'a pas d'arrêt
        // d'ordre 0 disponible, et se serait bloquée.
        let livraison_etat = if ctx.livraison_etat == EtatLivraison::Assignee {
            self.transition_livraison(
                tx,
                ctx.livraison_id,
                EtatLivraison::EnCollecte,
                Acteur::Coursier,
                horodatage_serveur,
                Some(NouvelEvenement {
                    type_evenement: "livraison.mise_en_collecte",
                    entite_type: "livraison",
                    entite_id: ctx.livraison_id,
                    payload: json!({
                        "commande": ctx.commande_id,
                        "arret": arret_id,
                        "acteur": coursier,
                    }),
                    survenu_le: horodatage_serveur,
                }),
            )
            .await?
        } else {
            ctx.livraison_etat
        };

        self.resultat_transition(tx, &ctx, StatutArret::EnRoute, livraison_etat, false)
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

        // Un arrêt indisponible peut être le DERNIER à résoudre : le gating doit
        // tourner ici aussi, sinon une course dont le dernier étal a fermé
        // n'atteindrait jamais la remise.
        let progression = self
            .gating_livraison(
                tx,
                ctx.livraison_id,
                ctx.commande_id,
                coursier,
                horodatage_serveur,
                ctx.livraison_etat == EtatLivraison::EnCollecte,
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
                ctx.livraison_etat
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
