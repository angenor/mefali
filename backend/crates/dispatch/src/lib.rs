//! Crate `dispatch` — Affectation par capacités requises (jamais par type de véhicule).
//!
//! Le cycle DSP 009 remplit le crate posé vide au socle. Il livre le **pipeline
//! complet** — pool temps réel, éligibilité par capacités, classement pondéré,
//! offre en cascade sous double verrou, broadcast, escalade, réassignation.
//!
//! | Module | Rôle |
//! |---|---|
//! | [`modele`] | types purs du domaine, erreurs et leurs clés i18n |
//! | [`ports`] | traits offerts (pool, verrou) et consommés (comptes, note, paires, proximité, notifications) |
//! | [`config`] | les 18 paramètres de zone, avec leurs gardes de chargement |
//! | [`pool`] | inscription, retrait, élagage — l'index éphémère derrière son port |
//! | [`plafond`] | plafond d'avance déclaré du jour et plafond RETENU |
//! | [`eligibilite`] | les 8 critères d'écart, la liste des motifs par coursier |
//! | [`scoring`] | 4 composantes en millièmes, poids en centièmes, entiers de bout en bout |
//! | [`offre`] | émission sous double verrou, contenu, conclusion, non-réponse |
//! | [`pipeline`] | un SEUL point de sortie : [`pipeline::DecisionPipeline`] |
//! | [`reprise`] | réassignation sans mouvement / sans scan, garde d'argent |
//! | [`tic`] | ce que le job périodique exécute, par zone, idempotent |
//! | [`depot`] | `PgDispatch` — racine de composition du domaine |
//!
//! Conventions du dépôt : **lectures sur pool**, **écritures sur
//! `&mut PgTransaction`** avec l'événement outbox dans la MÊME transaction
//! (constitution VI). Montants en entiers d'unités mineures + devise ISO 4217
//! (constitution III) ; scores et distances en **entiers** (research R6).
//!
//! ⚠ Aucune dépendance inverse : `commandes` ne dépend jamais de `dispatch`
//! (research R19).

pub mod config;
pub mod depot;
pub mod eligibilite;
pub mod modele;
pub mod offre;
pub mod pipeline;
pub mod plafond;
pub mod pool;
pub mod ports;
pub mod reprise;
pub mod scoring;
pub mod tic;
