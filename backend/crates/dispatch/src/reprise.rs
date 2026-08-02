//! Reprendre une course qui n'avance pas (DSP-07) — et **épargner celui qui
//! roule**.
//!
//! Deux critères, distincts et nommés (research R13) :
//!
//! - **sans mouvement** — le coursier ne s'est pas rapproché du premier arrêt
//!   non résolu d'au moins `dispatch.reassignation_deplacement_min_m` depuis
//!   `dispatch.reassignation_sans_mouvement_s`. L'**absence** de position
//!   récente compte comme absence de mouvement (FR-078) : un téléphone éteint
//!   n'est pas un coursier en route ;
//! - **sans scan** — aucun arrêt collecté au-delà de l'affectation, plus le
//!   délai de préparation annoncé, plus `dispatch.reassignation_sans_scan_marge_s`.
//!
//! **La garde d'argent** (FR-075) prime sur les deux : dès qu'un arrêt est
//! collecté, aucune reprise automatique n'est possible. Le coursier a engagé ses
//! fonds propres, et « le coursier ne perd jamais » (cadrage §7.5) interdit
//! qu'un automatisme lui retire une marchandise payée. Le cas part en escalade
//! vers l'exploitation, qui tranche avec un motif.
//!
//! **Pourquoi persister la distance.** L'index éphémère ne garde que la
//! DERNIÈRE position : il n'y a aucun historique pour dire « il ne s'est pas
//! rapproché depuis 5 minutes ». Et la décision retire une course à quelqu'un —
//! elle ne peut pas dépendre d'un service reconstructible.

use chrono::{DateTime, Utc};
use tarification::Point;
use uuid::Uuid;

use serde_json::json;

use crate::config::ConfigDispatch;
use crate::depot::PgDispatch;
use crate::modele::{ErreurDispatch, MotifReassignation, Reprise};
use crate::ports::{Annonce, Canal};

/// Ce qu'une observation de position a constaté sur une course assignée.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Progression {
    /// Distance routière au premier arrêt non résolu (mètres entiers).
    pub distance_m: i64,
    /// Meilleure distance observée depuis la dernière remise à zéro.
    pub distance_min_m: i64,
    /// Vrai si ce passage a constaté un rapprochement SIGNIFICATIF.
    pub a_progresse: bool,
    /// Vrai si la mesure vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
}

impl PgDispatch {
    /// Enregistre la progression d'une course assignée à chaque position reçue.
    ///
    /// Le rapprochement se mesure contre la **meilleure distance déjà
    /// observée**, jamais contre la précédente : sinon un aller-retour de
    /// 200 m passerait pour une progression toutes les cinq minutes, et un
    /// coursier immobile ne serait jamais repris.
    ///
    /// Ne rend jamais d'erreur de routage : la proximité dégrade (research R5).
    pub async fn observer_progression(
        &self,
        livraison: Uuid,
        lat: f64,
        lon: f64,
        config: &ConfigDispatch,
        horodatage: DateTime<Utc>,
    ) -> Result<Option<Progression>, ErreurDispatch> {
        let etat = self.commandes.etat_progression(livraison).await?;
        let (Some(cible_lat), Some(cible_lon)) = (etat.premier_arret_lat, etat.premier_arret_lon)
        else {
            // Plus aucun arrêt à résoudre : il n'y a rien vers quoi progresser.
            return Ok(None);
        };

        let trajets = self
            .proximite
            .vers_point(
                config.zone,
                &[Point { lat, lon }],
                Point {
                    lat: cible_lat,
                    lon: cible_lon,
                },
            )
            .await;
        let Some(trajet) = trajets.trajets.first() else {
            return Ok(None);
        };
        let distance_m = trajet.distance_m.max(0);

        let precedent = sqlx::query!(
            "SELECT distance_min_m, progresse_le FROM dispatch.suivi_progression
             WHERE livraison_id = $1",
            livraison,
        )
        .fetch_optional(&self.pool)
        .await?;

        let (distance_min_m, a_progresse, progresse_le) = match precedent {
            None => (distance_m, true, horodatage),
            Some(p) => {
                let gain = p.distance_min_m - distance_m;
                if gain >= config.reassignation_deplacement_min_m {
                    (distance_m, true, horodatage)
                } else {
                    (p.distance_min_m.min(distance_m), false, p.progresse_le)
                }
            }
        };

        sqlx::query!(
            "INSERT INTO dispatch.suivi_progression
                 (livraison_id, distance_m, distance_min_m, observe_le, progresse_le, degraded)
             VALUES ($1, $2, $3, $4, $5, $6)
             ON CONFLICT (livraison_id)
             DO UPDATE SET distance_m = EXCLUDED.distance_m,
                           distance_min_m = EXCLUDED.distance_min_m,
                           observe_le = EXCLUDED.observe_le,
                           progresse_le = EXCLUDED.progresse_le,
                           degraded = EXCLUDED.degraded",
            livraison,
            distance_m,
            distance_min_m,
            horodatage,
            progresse_le,
            trajets.degraded,
        )
        .execute(&self.pool)
        .await?;

        Ok(Some(Progression {
            distance_m,
            distance_min_m,
            a_progresse,
            degraded: trajets.degraded,
        }))
    }

    /// Oublie le suivi d'une livraison — appelé quand elle change de coursier,
    /// pour que le nouveau ne soit pas jugé sur le trajet du précédent.
    pub async fn oublier_progression(&self, livraison: Uuid) -> Result<(), ErreurDispatch> {
        sqlx::query!(
            "DELETE FROM dispatch.suivi_progression WHERE livraison_id = $1",
            livraison,
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }
}

// ══════════════════════════════════════════════════════════════════════════
// Escalade (DSP-06) et reprise automatique (DSP-07)
// ══════════════════════════════════════════════════════════════════════════

impl PgDispatch {
    /// Escalade les commandes non assignées au seuil de zone, et prévient les
    /// **deux** destinataires (FR-064, FR-065).
    ///
    /// L'exploitation reçoit l'alerte ; la cliente reçoit une annonce qui **ouvre
    /// un droit** — l'annulation sans frais. Et l'escalade **n'arrête pas** la
    /// recherche : une commande escaladée reste assignable, sans quoi alerter
    /// reviendrait à abandonner.
    pub async fn escalader(
        &self,
        zone: Uuid,
        config: &ConfigDispatch,
        maintenant: DateTime<Utc>,
    ) -> Result<usize, ErreurDispatch> {
        let escaladees = self.commandes.escalader_attentes(zone, maintenant).await?;
        for commande in &escaladees {
            let client = sqlx::query_scalar!(
                "SELECT client_id FROM commandes.commande WHERE id = $1",
                commande,
            )
            .fetch_optional(&self.pool)
            .await?;

            self.notifications
                .annoncer(
                    Annonce::nouvelle(Canal::Exploitation, None, "dispatch.escalade.exploitation")
                        .pour_commande(*commande)
                        .avec_variables(json!({
                            "zone": zone,
                            "seuil_s": config.escalade_attente_s,
                        })),
                )
                .await;

            if let Some(client) = client {
                self.notifications
                    .annoncer(
                        Annonce::nouvelle(Canal::Client, Some(client), "dispatch.escalade.client")
                            .pour_commande(*commande)
                            .avec_variables(json!({ "seuil_s": config.escalade_attente_s }))
                            // Le droit ouvert : annuler sans frais. C'est ce qui
                            // rend l'attente supportable — la cliente décide.
                            .avec_annulation_sans_frais(),
                    )
                    .await;
            }
        }
        Ok(escaladees.len())
    }

    /// Reprend les courses qui n'avancent pas, et **épargne celles qui roulent**.
    ///
    /// Rend `(reprises, bloquées)` : les secondes sont celles dont un arrêt est
    /// déjà collecté — l'automatisme s'y refuse par construction (FR-075), et
    /// seule une décision humaine motivée peut trancher.
    pub async fn reprendre_courses_immobiles(
        &self,
        zone: Uuid,
        config: &ConfigDispatch,
        maintenant: DateTime<Utc>,
    ) -> Result<(usize, usize), ErreurDispatch> {
        let candidates = sqlx::query!(
            r#"SELECT l.id AS livraison_id, l.commande_id, l.coursier_id AS "coursier!",
                      l.assignee_le,
                      sp.distance_m, sp.progresse_le,
                      EXTRACT(EPOCH FROM ($2::timestamptz - l.assignee_le))::bigint
                          AS "age_assignation_s?"
               FROM commandes.livraison l
               JOIN commandes.commande c ON c.id = l.commande_id
               LEFT JOIN dispatch.suivi_progression sp ON sp.livraison_id = l.id
               WHERE c.zone_id = $1
                 AND l.coursier_id IS NOT NULL
                 AND l.etat IN ('assignee', 'en_collecte')"#,
            zone,
            maintenant,
        )
        .fetch_all(&self.pool)
        .await?;

        let mut reprises = 0usize;
        let mut bloquees = 0usize;
        for c in candidates {
            let etat = self.commandes.etat_progression(c.livraison_id).await?;

            // Le critère « sans mouvement » : aucun rapprochement significatif
            // depuis la fenêtre de zone. L'ABSENCE d'observation compte comme
            // absence de mouvement (FR-078) — un téléphone éteint n'est pas un
            // coursier en route.
            let stagnation_s = match c.progresse_le {
                Some(progresse) => (maintenant - progresse).num_seconds().max(0),
                None => c.age_assignation_s.unwrap_or(0),
            };
            let sans_mouvement = stagnation_s >= config.reassignation_sans_mouvement_s;

            // Le critère « sans scan » : aucun arrêt collecté au-delà de
            // l'affectation + la marge de zone. Distinct du premier : un
            // coursier peut rouler sans jamais scanner (mauvais vendeur), et un
            // autre être immobile chez un vendeur qui prépare.
            let sans_scan = etat.nb_arrets_collectes == 0
                && c.age_assignation_s.unwrap_or(0) >= config.reassignation_sans_scan_marge_s;

            if !sans_mouvement && !sans_scan {
                continue;
            }

            // ── LA GARDE D'ARGENT (FR-075) ────────────────────────────────
            // Dès qu'un arrêt est collecté, le coursier a engagé ses fonds
            // propres. « Le coursier ne perd jamais » (cadrage §7.5) interdit
            // qu'un automatisme lui retire une marchandise payée : le cas part
            // en escalade, et l'exploitation tranche avec un motif.
            if etat.nb_arrets_collectes > 0 {
                if self
                    .escalader_course_bloquee(
                        c.livraison_id,
                        c.commande_id,
                        c.coursier,
                        if sans_mouvement {
                            MotifReassignation::SansMouvement
                        } else {
                            MotifReassignation::SansScan
                        },
                        etat.nb_arrets_collectes,
                        maintenant,
                    )
                    .await?
                {
                    bloquees += 1;
                }
                continue;
            }

            let motif = if sans_mouvement {
                MotifReassignation::SansMouvement
            } else {
                MotifReassignation::SansScan
            };
            if self
                .reprendre(
                    Reprise {
                        livraison: c.livraison_id,
                        commande: c.commande_id,
                        coursier_retire: c.coursier,
                        motif,
                        distance_m: c.distance_m.unwrap_or(0),
                        stagnation_s,
                    },
                    maintenant,
                )
                .await?
            {
                reprises += 1;
            }
        }
        Ok((reprises, bloquees))
    }

    /// Exécute une reprise : retrait, incident tracé, événement, notifications.
    ///
    /// Rend `false` si l'incident existait déjà pour ce **motif** : l'index
    /// UNIQUE `(livraison, coursier, motif)` interdit la reprise en boucle
    /// (FR-076) — sans lui, un rebalayage retirerait la course au coursier
    /// suivant toutes les cinq minutes.
    ///
    /// ⚠ Le devis figé n'est **jamais** recalculé (FR-077) : rien ici ne touche
    /// aux montants de la livraison.
    pub async fn reprendre(
        &self,
        reprise: Reprise,
        maintenant: DateTime<Utc>,
    ) -> Result<bool, ErreurDispatch> {
        let mut tx = self.pool.begin().await?;
        let incident = sqlx::query_scalar!(
            "INSERT INTO dispatch.incident_reassignation
                 (id, commande_id, livraison_id, coursier_retire_id, motif, constate_le)
             VALUES ($1, $2, $3, $4, $5::text::dispatch.motif_reassignation, $6)
             ON CONFLICT (livraison_id, coursier_retire_id, motif) DO NOTHING
             RETURNING id",
            Uuid::now_v7(),
            reprise.commande,
            reprise.livraison,
            reprise.coursier_retire,
            reprise.motif.comme_str(),
            maintenant,
        )
        .fetch_optional(&mut *tx)
        .await?;
        if incident.is_none() {
            tx.rollback().await?;
            return Ok(false);
        }
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "dispatch.reassignation",
                entite_type: "livraison",
                entite_id: reprise.livraison,
                payload: json!({
                    "commande": reprise.commande,
                    "coursier_retire": reprise.coursier_retire,
                    "motif": reprise.motif.comme_str(),
                    "distance_m": reprise.distance_m,
                    "stagnation_s": reprise.stagnation_s,
                    "acteur": "systeme",
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;

        // Le retrait passe par le contrat de `commandes` — sa transition est
        // gardée, et son événement voyage dans SA transaction.
        self.commandes
            .retirer_coursier(reprise.livraison, maintenant)
            .await?;
        // Le suivi du coursier retiré est oublié : le suivant ne doit pas être
        // jugé sur le trajet du précédent.
        self.oublier_progression(reprise.livraison).await?;

        // Les DEUX parties sont prévenues (FR-073).
        self.notifications
            .annoncer(
                Annonce::nouvelle(
                    Canal::CoursierHautePriorite,
                    Some(reprise.coursier_retire),
                    "dispatch.reassignation.coursier",
                )
                .pour_commande(reprise.commande)
                .avec_variables(json!({ "motif": reprise.motif.comme_str() })),
            )
            .await;
        if let Some(client) = sqlx::query_scalar!(
            "SELECT client_id FROM commandes.commande WHERE id = $1",
            reprise.commande,
        )
        .fetch_optional(&self.pool)
        .await?
        {
            self.notifications
                .annoncer(
                    Annonce::nouvelle(Canal::Client, Some(client), "dispatch.reassignation.client")
                        .pour_commande(reprise.commande),
                )
                .await;
        }
        Ok(true)
    }

    /// Escalade une course bloquée dont un arrêt est déjà collecté.
    ///
    /// Une seule fois par (livraison, motif) : la ligne d'incident sert de
    /// marqueur, exactement comme pour une reprise — un rebalayage ne doit pas
    /// noyer l'exploitation sous la même alerte.
    async fn escalader_course_bloquee(
        &self,
        livraison: Uuid,
        commande: Uuid,
        coursier: Uuid,
        motif: MotifReassignation,
        nb_arrets_collectes: i64,
        maintenant: DateTime<Utc>,
    ) -> Result<bool, ErreurDispatch> {
        let deja = sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM outbox.evenement
               WHERE type_evenement = 'dispatch.course_bloquee_escaladee'
                 AND entite_id = $1"#,
            livraison,
        )
        .fetch_one(&self.pool)
        .await?;
        if deja > 0 {
            return Ok(false);
        }

        let mut tx = self.pool.begin().await?;
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "dispatch.course_bloquee_escaladee",
                entite_type: "livraison",
                entite_id: livraison,
                payload: json!({
                    "commande": commande,
                    "coursier": coursier,
                    "motif": motif.comme_str(),
                    "nb_arrets_collectes": nb_arrets_collectes,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;

        self.notifications
            .annoncer(
                Annonce::nouvelle(Canal::Exploitation, None, "dispatch.course_bloquee")
                    .pour_commande(commande)
                    .avec_variables(json!({
                        "motif": motif.comme_str(),
                        "nb_arrets_collectes": nb_arrets_collectes,
                    })),
            )
            .await;
        Ok(true)
    }

    /// Reprise MANUELLE par un admin — **la seule** voie pour une course dont un
    /// arrêt est collecté (contrat §2.2).
    ///
    /// `422` si aucun arrêt n'est collecté : l'automatisme suffit alors, et une
    /// action manuelle masquerait un défaut de pipeline.
    ///
    /// N'écrit ni caisse ni litige : la caisse (CRS-06) et le litige (AVI-04)
    /// appartiennent à leurs cycles.
    pub async fn reprendre_manuellement(
        &self,
        livraison: Uuid,
        auteur: Uuid,
        motif_admin: &str,
        maintenant: DateTime<Utc>,
    ) -> Result<Uuid, ErreurDispatch> {
        let motif_admin = motif_admin.trim();
        if motif_admin.is_empty() {
            return Err(ErreurDispatch::MotifRequis);
        }
        let etat = self.commandes.etat_progression(livraison).await?;
        if etat.nb_arrets_collectes == 0 {
            return Err(ErreurDispatch::RepriseInutile);
        }
        let Some(coursier) = etat.coursier_id else {
            return Err(ErreurDispatch::RepriseInutile);
        };

        let incident_id = Uuid::now_v7();
        let mut tx = self.pool.begin().await?;
        sqlx::query!(
            "INSERT INTO dispatch.incident_reassignation
                 (id, commande_id, livraison_id, coursier_retire_id, motif,
                  motif_admin, auteur_id, constate_le)
             VALUES ($1, $2, $3, $4, 'sans_mouvement', $5, $6, $7)
             ON CONFLICT (livraison_id, coursier_retire_id, motif)
             DO UPDATE SET motif_admin = EXCLUDED.motif_admin,
                           auteur_id = EXCLUDED.auteur_id,
                           constate_le = EXCLUDED.constate_le",
            incident_id,
            etat.commande_id,
            livraison,
            coursier,
            motif_admin,
            auteur,
            maintenant,
        )
        .execute(&mut *tx)
        .await?;
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "dispatch.reassignation",
                entite_type: "livraison",
                entite_id: livraison,
                payload: json!({
                    "commande": etat.commande_id,
                    "coursier_retire": coursier,
                    "motif": MotifReassignation::SansMouvement.comme_str(),
                    "distance_m": 0,
                    "stagnation_s": 0,
                    "acteur": "admin",
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        tx.commit().await?;

        self.commandes
            .retirer_coursier(livraison, maintenant)
            .await?;
        self.oublier_progression(livraison).await?;
        Ok(incident_id)
    }
}

/// Une commande escaladée, telle que l'exploitation la lit.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EscaladeVue {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Zone de la commande.
    pub zone_id: Uuid,
    /// Ancienneté au moment de l'escalade (secondes).
    pub age_s: i64,
    /// Seuil de zone franchi (secondes).
    pub seuil_s: i64,
    /// `file` | `pipeline`.
    pub chemin: String,
    /// Offres déjà émises pour cette commande.
    pub nb_offres_emises: i64,
    /// État courant du tronc.
    pub etat: String,
}

/// Une course assignée qui n'avance pas.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CourseBloqueeVue {
    /// Commande concernée.
    pub commande_id: Uuid,
    /// Livraison concernée.
    pub livraison_id: Uuid,
    /// Coursier assigné.
    pub coursier_id: Option<Uuid>,
    /// `sans_mouvement` | `sans_scan`.
    pub motif: String,
    /// Stagnation constatée (secondes).
    pub stagnation_s: i64,
    /// Arrêts déjà collectés.
    pub nb_arrets_collectes: i64,
    /// Faux dès qu'un arrêt est collecté (FR-075).
    pub reprise_automatique_possible: bool,
}

/// Le tableau d'alertes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Alertes {
    /// Escalades, **les plus anciennes d'abord**.
    pub escalades: Vec<EscaladeVue>,
    /// Courses bloquées.
    pub courses_bloquees: Vec<CourseBloqueeVue>,
}

impl PgDispatch {
    /// Ce qui demande un humain : escalades et courses bloquées.
    ///
    /// Les escalades se lisent sur l'**outbox** — l'événement déjà écrit EST la
    /// trace, et aucune table parallèle ne peut s'en désynchroniser (FR-066).
    pub async fn alertes(&self) -> Result<Alertes, ErreurDispatch> {
        let escalades = sqlx::query!(
            r#"SELECT e.entite_id AS "commande_id!", e.payload, c.etat::text AS "etat!",
                      c.zone_id,
                      (SELECT count(*) FROM dispatch.offre o WHERE o.commande_id = e.entite_id)
                          AS "nb_offres!"
               FROM outbox.evenement e
               JOIN commandes.commande c ON c.id = e.entite_id
               WHERE e.type_evenement = 'commande.attente_coursier_escaladee'
                 AND c.etat IN ('nouvelle', 'en_attente_coursier')
               ORDER BY e.survenu_le"#,
        )
        .fetch_all(&self.pool)
        .await?;

        // L'événement d'escalade est OBLIGATOIRE ici : une course bloquée qui
        // n'a pas encore été escaladée n'a rien à faire dans un tableau
        // d'alertes — c'est le tic qui décide quand elle y entre. D'où un JOIN
        // interne, et non un `LEFT JOIN … WHERE e.id IS NOT NULL` qui disait la
        // même chose en laissant croire au lecteur que l'événement était
        // facultatif.
        //
        // Le `LEFT JOIN` sur `suivi_progression`, lui, est bien nécessaire : une
        // course assignée dont aucune position n'est encore arrivée n'a pas de
        // suivi, et sa stagnation se compte alors depuis l'affectation.
        let bloquees = sqlx::query!(
            r#"SELECT l.id AS livraison_id, l.commande_id, l.coursier_id,
                      e.payload,
                      (SELECT count(*) FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                        WHERE s.livraison_id = l.id
                          AND a.type_arret = 'collecte' AND a.statut = 'collecte')
                          AS "nb_collectes!",
                      EXTRACT(EPOCH FROM (now() - COALESCE(sp.progresse_le, l.assignee_le)))::bigint
                          AS "stagnation_s?"
               FROM commandes.livraison l
               JOIN outbox.evenement e
                 ON e.type_evenement = 'dispatch.course_bloquee_escaladee'
                AND e.entite_id = l.id
               LEFT JOIN dispatch.suivi_progression sp ON sp.livraison_id = l.id
               WHERE l.coursier_id IS NOT NULL
                 AND l.etat IN ('assignee', 'en_collecte')
               ORDER BY l.assignee_le"#,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(Alertes {
            escalades: escalades
                .into_iter()
                .map(|e| EscaladeVue {
                    commande_id: e.commande_id,
                    zone_id: e.zone_id,
                    age_s: e.payload.get("age_s").and_then(|v| v.as_i64()).unwrap_or(0),
                    seuil_s: e
                        .payload
                        .get("seuil_s")
                        .and_then(|v| v.as_i64())
                        .unwrap_or(0),
                    chemin: e
                        .payload
                        .get("chemin")
                        .and_then(|v| v.as_str())
                        .unwrap_or("file")
                        .to_owned(),
                    nb_offres_emises: e.nb_offres,
                    etat: e.etat,
                })
                .collect(),
            courses_bloquees: bloquees
                .into_iter()
                .map(|b| CourseBloqueeVue {
                    commande_id: b.commande_id,
                    livraison_id: b.livraison_id,
                    coursier_id: b.coursier_id,
                    motif: b
                        .payload
                        .get("motif")
                        .and_then(|v| v.as_str())
                        .unwrap_or("sans_mouvement")
                        .to_owned(),
                    stagnation_s: b.stagnation_s.unwrap_or(0),
                    nb_arrets_collectes: b.nb_collectes,
                    // Dès qu'un arrêt est collecté, l'automatisme s'interdit
                    // d'agir : c'est l'argent du coursier qui est en jeu.
                    reprise_automatique_possible: b.nb_collectes == 0,
                })
                .collect(),
        })
    }

    /// État de progression d'une livraison — relayé pour la surface admin.
    pub async fn etat_progression(
        &self,
        livraison: Uuid,
    ) -> Result<commandes::EtatProgression, ErreurDispatch> {
        Ok(self.commandes.etat_progression(livraison).await?)
    }
}
