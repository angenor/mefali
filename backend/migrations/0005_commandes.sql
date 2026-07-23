-- Socle logistique minimal (cycle QRC 006, data-model.md §1).
-- Schéma dédié (constitution II : un schéma par module). Nouvelle migration —
-- 0001..0004 intouchées (constitution I).
--
-- Socle MINIMAL que CMD étendra (par de NOUVELLES migrations, jamais celle-ci) :
-- aucune logique de création/cash/substitution/dispatch ici. QRC ne POSE que
-- la transition d'arrêt 'collecte' et la bascule EN_LIVRAISON.
CREATE SCHEMA IF NOT EXISTS commandes;

-- ── 1. Types énumérés ──────────────────────────────────────────────────────

-- Machine à états de l'arrêt (cadrage §7.2). QRC ne POSE que 'collecte' ;
-- 'indisponible' viendra de CMD-06 (substitution) — présent dès le socle pour
-- que le gating EN_LIVRAISON le compte comme résolu (spec FR-018).
CREATE TYPE commandes.statut_arret AS ENUM ('a_collecter', 'collecte', 'indisponible');

-- Méthode de collecte (unifie scan et dégradé — cadrage §7.2).
CREATE TYPE commandes.mode_collecte AS ENUM ('scan_qr', 'code_secours');

-- État logistique de la livraison (constitution II — PAS sur le tronc commande).
CREATE TYPE commandes.etat_livraison AS ENUM ('en_collecte', 'en_livraison');

-- ── 2. Tables ──────────────────────────────────────────────────────────────

-- Ancre du tronc (constitution II — AUCUN champ logistique). CMD ajoutera
-- identité, montants, paiement, états de haut niveau par migrations ultérieures.
CREATE TABLE commandes.commande (
    id      uuid PRIMARY KEY,
    cree_le timestamptz NOT NULL DEFAULT now()
);

-- Composant OPTIONNEL (0..n) rattaché à la commande. Le MVP en crée une.
-- coursier_id est POSÉ par DSP (affectation) — NULL tant que non assignée ;
-- simulé dans les tests QRC (research R10).
CREATE TABLE commandes.livraison (
    id          uuid PRIMARY KEY,
    commande_id uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    coursier_id uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    etat        commandes.etat_livraison NOT NULL DEFAULT 'en_collecte',
    etat_le     timestamptz NOT NULL DEFAULT now(),
    cree_le     timestamptz NOT NULL DEFAULT now()
);
-- Lecture de la course active d'un coursier (précondition QRC-02, R10).
CREATE INDEX livraison_par_coursier ON commandes.livraison (coursier_id)
    WHERE etat = 'en_collecte';

-- Segment (niveau transporteur — MVP : 1 segment coursier).
CREATE TABLE commandes.segment (
    id           uuid PRIMARY KEY,
    livraison_id uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    ordre        smallint NOT NULL,
    UNIQUE (livraison_id, ordre)
);

-- Arrêt : maillon documenté (user-stories §CMD ; cadrage §7.3). Position et
-- montant DÉNORMALISÉS depuis le site (stabilité + pré-provisionnement offline).
CREATE TABLE commandes.arret (
    id              uuid PRIMARY KEY,
    segment_id      uuid NOT NULL REFERENCES commandes.segment (id) ON DELETE CASCADE,
    prestataire_id  uuid NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    ordre           smallint NOT NULL,
    -- Position ATTENDUE du site (proximité de scan, R3). Position du VENDEUR,
    -- pas une donnée personnelle.
    site_lat        double precision NOT NULL,
    site_lon        double precision NOT NULL,
    -- Montant avancé par le coursier à cet arrêt (III). Soumis au seuil photo.
    montant_avance  bigint NOT NULL CHECK (montant_avance >= 0),
    devise          text   NOT NULL,                       -- ISO 4217 (XOF)
    statut          commandes.statut_arret NOT NULL DEFAULT 'a_collecter',
    -- Journal de la collecte (renseigné à la bascule 'collecte').
    collecte_le     timestamptz,                           -- horodatage SERVEUR
    mode_collecte   commandes.mode_collecte,
    photo_cle       text,                                  -- clé Garage, si photo
    distance_scan_m integer,                               -- arrondi (ARTCI, pas de GPS brut)
    collecte_uuid_client uuid,                             -- idempotence (V)
    UNIQUE (segment_id, ordre)
);

-- Arrêts encore à collecter chez un prestataire (précondition QRC-02).
CREATE INDEX arret_par_prestataire ON commandes.arret (prestataire_id)
    WHERE statut = 'a_collecter';
