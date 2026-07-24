-- Catalogue tarifaire VERSIONNÉ par zone (cycle TRF 007, data-model.md §1).
-- Schéma dédié (constitution II). Nouvelle migration — 0001..0006 intouchées
-- (constitution I).
--
-- Ce qui vit ICI vs en configuration de zone (research R1, plan « Complexity
-- Tracking ») : le catalogue est un objet VERSIONNÉ MULTI-LIGNES (brouillon →
-- en vigueur → historique, priorité, dates d'effet, garde de simulation) que le
-- store clé-valeur `zones.parametre_zone` ne modélise pas. Les paramètres
-- SCALAIRES (bornes de marge, pas d'arrondi, facteur dégradé, TTL de cache,
-- seeds d'effort, plafonds, drapeaux) restent, eux, en configuration de zone
-- héritée — jamais en dur, jamais ici (constitution I).
--
-- AUCUNE table de course n'est créée ni modifiée : l'évaluation prend la
-- GÉOMÉTRIE en entrée et ne lit pas la logistique (research R12).
CREATE SCHEMA IF NOT EXISTS tarification;

-- Cycle de vie d'une grille tarifaire (US1/US3, research R7).
CREATE TYPE tarification.etat_grille AS ENUM ('brouillon', 'en_vigueur', 'historique');

-- ── Grille : catalogue versionné par zone ──────────────────────────────────
CREATE TABLE tarification.grille (
    id                uuid PRIMARY KEY,                     -- UUIDv7
    zone_id           uuid NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    version           integer NOT NULL,
    etat              tarification.etat_grille NOT NULL DEFAULT 'brouillon',
    effet_le          timestamptz,                          -- entrée en vigueur (NULL tant que brouillon)
    simulee_le        timestamptz,                          -- dernière simulation réussie (garde R7)
    simulee_empreinte text,                                 -- empreinte du contenu simulé (réarmement FR-021)
    cree_le           timestamptz NOT NULL DEFAULT now(),
    UNIQUE (zone_id, version)
);

-- Au plus UNE grille en vigueur par zone (sélection déterministe, research R7).
CREATE UNIQUE INDEX grille_en_vigueur_unique
    ON tarification.grille (zone_id) WHERE etat = 'en_vigueur';

-- Au plus UN brouillon par zone à la fois (édition simple, développeur solo).
CREATE UNIQUE INDEX grille_brouillon_unique
    ON tarification.grille (zone_id) WHERE etat = 'brouillon';

-- ── Règle : conditions → sorties ───────────────────────────────────────────
-- Invariant monétaire DÉRIVÉ (jamais stocké) : prix_client_base =
-- part_coursier_base + marge. La composante km (`prix_par_km` au-delà de
-- `seuil_km_m`), la grille d'effort et le RELIQUAT D'ARRONDI abondent la PART
-- COURSIER ; la marge reste FIXE (clarification 2026-07-24, FR-016/FR-019).
-- `prix_plafond` borne le prix CLIENT.
CREATE TABLE tarification.regle (
    id                 uuid PRIMARY KEY,
    grille_id          uuid NOT NULL REFERENCES tarification.grille (id) ON DELETE CASCADE,
    -- ── Conditions ──────────────────────────────────────────────────────────
    transport_slug     text    NOT NULL,                    -- véhicule (réf. zones.type_transport)
    categorie_slug     text,                                -- NULL = toutes catégories
    distance_min_m     integer NOT NULL DEFAULT 0,          -- borne basse de la tranche (mètres ROUTIERS)
    distance_max_m     integer,                             -- borne haute (NULL = +∞)
    plage_debut_min    smallint,                            -- minutes depuis minuit (NULL = toute heure)
    plage_fin_min      smallint,
    jours_masque       smallint,                            -- bitmask lun..dim (NULL = tous les jours)
    point_relais_id    uuid,                                -- PROVISION : toujours NULL au MVP (constitution IX)
    -- ── Sorties (unités mineures) ───────────────────────────────────────────
    part_coursier_base bigint  NOT NULL CHECK (part_coursier_base >= 0),
    marge              bigint  NOT NULL CHECK (marge >= 0),  -- bornée par zone à l'écriture (FR-009)
    prix_par_km        bigint  NOT NULL DEFAULT 0 CHECK (prix_par_km >= 0),  -- abonde client ET coursier
    seuil_km_m         integer NOT NULL DEFAULT 0 CHECK (seuil_km_m >= 0),   -- km facturé au-delà
    prix_plafond       bigint CHECK (prix_plafond IS NULL OR prix_plafond >= 0),
    devise             text    NOT NULL,                     -- ISO 4217, = devise de la zone (FR-023)
    priorite           integer NOT NULL DEFAULT 0,           -- départage volontaire (research R5)
    actif              boolean NOT NULL DEFAULT true,
    cree_le            timestamptz NOT NULL DEFAULT now(),
    CHECK (distance_max_m IS NULL OR distance_max_m > distance_min_m),
    CHECK (plage_debut_min IS NULL OR (plage_debut_min >= 0 AND plage_debut_min < 1440)),
    CHECK (plage_fin_min IS NULL OR (plage_fin_min >= 0 AND plage_fin_min <= 1440)),
    -- Garde la PROVISION structurellement inutilisable (constitution IX,
    -- « prêt ≠ construit ») : la dimension existe au modèle, aucune ligne ne
    -- peut la renseigner tant qu'une migration ultérieure ne lève pas ce CHECK.
    CHECK (point_relais_id IS NULL)
);

CREATE INDEX regle_par_grille ON tarification.regle (grille_id) WHERE actif = true;

-- Cache de routage : Redis `tarif:route:v1:{a}:{b}` (TTL 24 h, research R3) —
-- PAS de table (éphémère reconstructible, constitution II).
