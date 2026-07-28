-- Cycle DSP 009 — TYPES SEULS (specs/009 data-model.md §1).
--
-- ⚠ Ce fichier ne contient QUE le schéma et ses types : aucune table, aucune
-- colonne, aucun index, aucune contrainte. PostgreSQL interdit d'UTILISER une
-- valeur d'énum dans la transaction qui l'ajoute, et sqlx exécute chaque fichier
-- de migration dans UNE transaction. Les structures qui référencent ces valeurs
-- — DEFAULT, CHECK, index partiels — vivent dans `0011_dispatch_tables.sql`,
-- exécuté dans une transaction suivante. Un fichier unique échouerait au
-- DÉPLOIEMENT, pas au développement (leçon du cycle 008).
--
-- 0001..0009 sont INTOUCHÉES (constitution I).

CREATE SCHEMA IF NOT EXISTS dispatch;

-- Mode d'émission d'une offre : cascade au mieux classé (DSP-04) puis, quand
-- elle s'essouffle, broadcast à tous les éligibles (DSP-05).
CREATE TYPE dispatch.mode_offre AS ENUM ('cascade', 'broadcast');

-- Issue d'une offre. `deja_prise` n'est PAS un refus : aucune pénalité, et le
-- coursier reste dans le pool (FR-049).
CREATE TYPE dispatch.issue_offre AS ENUM (
    'en_vol', 'acceptee', 'refusee', 'non_repondue', 'deja_prise', 'annulee'
);

-- Motif d'écart d'éligibilité — un par critère de DSP-02, pour que chaque motif
-- ait son test (SC-013) et que la bascule prépaiement soit décidable (FR-026 :
-- « la capacité d'avance est le SEUL critère bloquant »).
CREATE TYPE dispatch.motif_ecart AS ENUM (
    'hors_ligne', 'course_active', 'capacite_non_couverte', 'hors_rayon',
    'capacite_avance', 'paire_bloquee', 'compte_indisponible', 'offre_en_vol'
);

-- Motif de reprise automatique (DSP-07) — deux CRITÈRES distincts (research
-- R13) : le géographique (« sans mouvement ») et celui d'état (« sans scan »).
CREATE TYPE dispatch.motif_reassignation AS ENUM ('sans_mouvement', 'sans_scan');
