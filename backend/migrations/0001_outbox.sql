-- Journal d'événements métier — outbox transactionnel (TRX-02, data-model.md §1).
-- Schéma dédié (constitution II : un schéma par module).
CREATE SCHEMA IF NOT EXISTS outbox;

CREATE TABLE outbox.evenement (
    -- UUIDv7 (ordre temporel), généré côté backend.
    id              uuid        PRIMARY KEY,
    -- Clé de la taxonomie (docs/taxonomie-evenements.md), ex. commande.creee.
    type_evenement  text        NOT NULL,
    -- Entité concernée par la transition.
    entite_type     text        NOT NULL,
    entite_id       uuid        NOT NULL,
    -- Contenu (inclut les propriétés standard : zone, catégorie, rôle, version d'app).
    payload         jsonb       NOT NULL,
    -- Horodatage MÉTIER de la transition.
    survenu_le      timestamptz NOT NULL,
    -- Horodatage d'insertion.
    cree_le         timestamptz NOT NULL DEFAULT now(),
    -- NULL = en attente de publication.
    publie_le       timestamptz,
    -- Compteur d'essais du worker + dernière erreur de publication.
    tentatives      integer     NOT NULL DEFAULT 0,
    derniere_erreur text
);

-- File des événements en attente : index partiel sur publie_le IS NULL.
CREATE INDEX idx_evenement_en_attente
    ON outbox.evenement (cree_le)
    WHERE publie_le IS NULL;
