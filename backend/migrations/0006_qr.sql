-- Traçabilité QR : incident de plaque + registre d'idempotence des collectes
-- (cycle QRC 006, data-model.md §2). Schéma dédié (constitution II). Nouvelle
-- migration — 0001..0005 intouchées (constitution I).
CREATE SCHEMA IF NOT EXISTS qr;

-- Override PRESTATAIRE de la politique photo (research R4, niveau 1 de la
-- hiérarchie prestataire > catégorie > seuil de montant). NULL = pas d'override,
-- on retombe sur la politique de catégorie (`zones.categorie.politique_photo`).
-- Ajout au schéma prestataires par NOUVELLE migration (constitution I).
ALTER TABLE prestataires.prestataire
    ADD COLUMN politique_photo_collecte text
    CHECK (politique_photo_collecte IN ('obligatoire', 'facultative', 'desactivee'));

-- Incident « plaque à remplacer » (QRC-04) — créé au passage en mode dégradé,
-- UNE fois par arrêt (clarification Q2). Rattaché au prestataire + contexte.
CREATE TABLE qr.incident_plaque (
    id             uuid PRIMARY KEY,
    prestataire_id uuid NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    arret_id       uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE RESTRICT,
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    origine        text NOT NULL DEFAULT 'qr_illisible',
    statut         text NOT NULL DEFAULT 'ouvert',         -- ouvert|resolu (résolution = ADM)
    cree_le        timestamptz NOT NULL DEFAULT now(),
    UNIQUE (arret_id)                                      -- dédup « une fois par arrêt »
);

-- Registre d'idempotence des actions de collecte (V — rejeu idempotent).
-- Mémorise l'ISSUE de chaque uuid_client pour ne ré-émettre aucun événement au
-- rejeu (ni COLLECTÉ ni rejet métier).
CREATE TABLE qr.action_traitee (
    uuid_client uuid PRIMARY KEY,
    arret_id    uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE CASCADE,
    resultat    text NOT NULL,                             -- collecte|rejet:<motif>
    traite_le   timestamptz NOT NULL DEFAULT now()
);

-- Compteur d'essais du code dégradé : Redis `qr:essais:{arret_id}` (INCR + TTL,
-- backstop en ligne, research R7) — PAS de table (éphémère, constitution II).
