-- Cycle DSP 009 — STRUCTURES du schéma `dispatch` (specs/009 data-model.md §1).
--
-- Tout ce qui RÉFÉRENCE une valeur d'énum créée par 0010 vit ici : DEFAULT,
-- CHECK et index partiels. Deux fichiers = deux transactions = contrainte
-- PostgreSQL levée, sans artifice.
--
-- ⚠ Ce fichier ne touche QUE le schéma `dispatch`. Les extensions du schéma
-- `commandes` vivent dans `0012_commandes_capacites.sql`, qui porte le nom du
-- schéma qu'il modifie : une table `commandes` cachée dans un fichier nommé
-- `dispatch` rendrait l'histoire du schéma `commandes` introuvable sous son nom.
--
-- 0001..0009 sont INTOUCHÉES (constitution I).

-- ── 1. Offres ──────────────────────────────────────────────────────────────
--
-- Le REGISTRE des offres. Le verrou Redis est le dispositif de concurrence ;
-- cette table est la MÉMOIRE : elle porte l'échéance (donc le compte à rebours
-- survit à un redémarrage, research R1) et l'issue (donc le taux d'acceptation
-- et les non-réponses franches se calculent sans agrégat à resynchroniser, R11).
CREATE TABLE dispatch.offre (
    id                 uuid        PRIMARY KEY,          -- UUIDv7 = jeton du verrou
    commande_id        uuid        NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    coursier_id        uuid        NOT NULL REFERENCES comptes.compte (id)     ON DELETE RESTRICT,
    zone_id            uuid        NOT NULL REFERENCES zones.zone (id)         ON DELETE RESTRICT,
    mode               dispatch.mode_offre  NOT NULL,
    rang               smallint    NOT NULL,             -- rang dans la cascade (0 en broadcast)
    score              integer     NOT NULL,             -- entier (R6) — trace de la décision
    montant_a_avancer  bigint      NOT NULL CHECK (montant_a_avancer >= 0),
    devise             text        NOT NULL,             -- ISO 4217 de la zone
    emise_le           timestamptz NOT NULL DEFAULT now(),
    echeance_le        timestamptz NOT NULL,             -- PERSISTÉE (R1) — autorité du timer
    issue              dispatch.issue_offre NOT NULL DEFAULT 'en_vol',
    repondue_le        timestamptz,
    franche            boolean     NOT NULL DEFAULT false, -- non-réponse non pénalisée (FR-052)
    -- Idempotence de l'acceptation / du refus (constitution V) : un rejeu avec
    -- le même UUID client rend le MÊME corps, sans seconde affectation.
    reponse_uuid_client uuid,
    CHECK (echeance_le > emise_le),
    CHECK ((issue = 'en_vol') = (repondue_le IS NULL))
);

-- UNE seule offre en vol par commande, et UNE par coursier : les deux verrous
-- Redis (R3) ont ici leur filet Postgres. Un index UNIQUE partiel rend
-- l'invariant vrai même si Redis a disparu.
CREATE UNIQUE INDEX offre_en_vol_par_commande ON dispatch.offre (commande_id)
    WHERE issue = 'en_vol';
CREATE UNIQUE INDEX offre_en_vol_par_coursier ON dispatch.offre (coursier_id)
    WHERE issue = 'en_vol';

-- Échéances à résoudre par le tic (R1) : le plus urgent d'abord.
CREATE INDEX offre_echeances ON dispatch.offre (echeance_le)
    WHERE issue = 'en_vol';
-- Taux d'acceptation sur fenêtre + non-réponses du jour (FR-038, FR-052).
CREATE INDEX offre_par_coursier_date ON dispatch.offre (coursier_id, emise_le DESC);
-- Ne jamais re-solliciter pour la MÊME commande (FR-051, FR-074) — aucune
-- colonne dédiée : l'historique des offres EST la mémoire.
CREATE INDEX offre_par_commande ON dispatch.offre (commande_id, coursier_id);

-- ── 2. Plafond d'avance déclaré du jour ────────────────────────────────────
--
-- Journalier et jamais reporté (FR-011) : la clé primaire porte la DATE. Le
-- plafond RETENU est min(déclaré, grille par note) et n'est PAS stocké — il se
-- recalcule, parce que la note peut changer entre deux offres.
CREATE TABLE dispatch.plafond_jour (
    coursier_id     uuid   NOT NULL REFERENCES comptes.compte (id) ON DELETE CASCADE,
    jour            date   NOT NULL,                    -- jour civil de la zone
    plafond_unites  bigint NOT NULL CHECK (plafond_unites >= 0),
    devise          text   NOT NULL,
    declare_le      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (coursier_id, jour)
);

-- ── 3. Incidents de réassignation ──────────────────────────────────────────
--
-- Tracé (FR-073), lu plus tard par la caisse coursier (CRS-06) et les incidents
-- de dossier (ADM-04). PROVISION sans FK vers un litige : AVI n'existe pas.
CREATE TABLE dispatch.incident_reassignation (
    id                 uuid        PRIMARY KEY,
    commande_id        uuid        NOT NULL REFERENCES commandes.commande (id)  ON DELETE CASCADE,
    livraison_id       uuid        NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    coursier_retire_id uuid        NOT NULL REFERENCES comptes.compte (id)      ON DELETE RESTRICT,
    motif              dispatch.motif_reassignation NOT NULL,
    -- Reprise MANUELLE (POST /admin/dispatch/…/reprendre) : motif libre saisi
    -- par l'admin et son auteur. NULL = reprise automatique du tic.
    motif_admin        text,
    auteur_id          uuid        REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    constate_le        timestamptz NOT NULL DEFAULT now()
);
-- Pas de reprise en boucle pour le même motif (FR-076).
CREATE UNIQUE INDEX incident_unique_par_motif
    ON dispatch.incident_reassignation (livraison_id, coursier_retire_id, motif);

-- ── 4. Progression observée d'une course assignée ──────────────────────────
--
-- Redis ne garde que la DERNIÈRE position : il n'y a aucun historique pour dire
-- « il ne s'est pas rapproché depuis 5 minutes » (R13). Et la décision retire
-- une course à quelqu'un — elle ne peut pas dépendre d'un service éphémère.
CREATE TABLE dispatch.suivi_progression (
    livraison_id      uuid        PRIMARY KEY REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    -- Distance ROUTIÈRE au premier arrêt non résolu, en mètres ENTIERS.
    distance_m        bigint      NOT NULL CHECK (distance_m >= 0),
    -- Meilleure (plus petite) distance observée depuis la dernière remise à
    -- zéro : c'est CONTRE ELLE que le rapprochement se mesure, sinon un
    -- aller-retour passerait pour une progression.
    distance_min_m    bigint      NOT NULL CHECK (distance_min_m >= 0),
    observe_le        timestamptz NOT NULL,
    -- Horodatage du dernier rapprochement SIGNIFICATIF (≥ seuil de zone).
    progresse_le      timestamptz NOT NULL,
    degraded          boolean     NOT NULL DEFAULT false  -- constitution IV
);
CREATE INDEX suivi_progression_stagnation ON dispatch.suivi_progression (progresse_le);
