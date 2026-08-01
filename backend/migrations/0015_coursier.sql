-- Cycle CRS 010 — schéma `coursier` (specs/010 data-model.md §1).
--
-- Schéma NEUF, propriété exclusive du crate `coursier`. Aucune table d'ici
-- n'est lue par `commandes`, `qr` ou `dispatch` : le sens des dépendances est
-- `coursier ──▶ commandes`, jamais l'inverse (constitution II).
--
-- ⚠ Un SEUL fichier, contrairement au découpage 0008/0009 et 0010/0011. La
-- raison de ce découpage était `ALTER TYPE … ADD VALUE`, que PostgreSQL
-- interdit d'utiliser dans la transaction qui l'ajoute. Ici, les quatre types
-- sont CRÉÉS (`CREATE TYPE … AS ENUM`) : leurs valeurs sont utilisables dans la
-- même transaction, DEFAULT et CHECK compris.
--
-- 0001..0014 sont INTOUCHÉES (constitution I).

CREATE SCHEMA IF NOT EXISTS coursier;

-- ── 1. Énumérations ────────────────────────────────────────────────────────

-- Nature d'une écriture au livre de caisse. `correction` est une écriture
-- INVERSE — jamais un UPDATE (FR-073) : le livre est append-only.
CREATE TYPE coursier.type_ecriture AS ENUM (
    'avance',          -- argent sorti de la poche du coursier à un arrêt
    'remboursement',   -- encaissé chez le client (cash UNIQUEMENT, R10)
    'indemnisation',   -- validée par l'exploitation
    'correction'       -- écriture inverse d'une écriture erronée
);

-- Cycle de vie d'une indemnisation (data-model §5). `demandee` naît de la
-- consommation de `indemnisation.due` (cycle 008) ; seule la validation écrit
-- au livre de caisse.
CREATE TYPE coursier.etat_indemnisation AS ENUM ('demandee', 'validee', 'refusee');

-- Motif d'un appel passé VIA l'app. `client_absent` est le SEUL motif compté
-- par la preuve d'échec (FR-035) — un appel de suivi ne prouve rien.
CREATE TYPE coursier.motif_appel AS ENUM ('suivi', 'substitution', 'client_absent');

-- Issue DÉCLARÉE par le coursier (R19) : le serveur ne peut pas l'observer,
-- l'appel part du téléphone. Affichée sur K4-1e (FR-036), JAMAIS critère de
-- preuve — un coursier qui déclarerait « sans réponse » à tort ne gagne rien.
CREATE TYPE coursier.issue_appel AS ENUM ('inconnue', 'sans_reponse', 'repondu');

-- ── 2. Indemnisations ──────────────────────────────────────────────────────
--
-- Créée AVANT `ecriture_caisse` : celle-ci la référence.
--
-- `litige_id` est NULLABLE et sans clé étrangère : AVI-04 n'est pas construit
-- (R16). Le port `LitigesOuverts` et son double `AucunLitige` portent cette
-- absence côté code ; poser une FK vers une table qui n'existe pas rendrait la
-- migration infaisable, et l'inventer serait construire hors périmètre (IX).
CREATE TABLE coursier.indemnisation (
    id             uuid PRIMARY KEY,                     -- UUIDv7
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id)     ON DELETE RESTRICT,
    commande_id    uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    -- L'issue de l'arbre §7.5 (cycle 008) qui a décidé l'indemnisation.
    issue_echec_id uuid NOT NULL REFERENCES commandes.issue_echec (id) ON DELETE CASCADE,
    litige_id      uuid,                                 -- AVI-04 non construit (R16)
    montant_unites bigint NOT NULL CHECK (montant_unites > 0),  -- entier, III
    devise         text   NOT NULL,                      -- ISO 4217 de la zone
    etat           coursier.etat_indemnisation NOT NULL DEFAULT 'demandee',
    motif_cle      text   NOT NULL,                      -- clé i18n fr, jamais de texte libre
    -- Idempotence du consommateur outbox : `indemnisation.due` rejoué par le
    -- worker ne crée qu'une demande (R9, contrat `socle`).
    evenement_id   uuid   NOT NULL UNIQUE,
    decide_par     uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    decide_le      timestamptz,
    decision_motif_cle text,
    cree_le        timestamptz NOT NULL DEFAULT now(),
    -- Une décision se tient d'un bloc : qui, quand. Un refus exige en plus son
    -- motif (FR-072) — l'exploitation ne refuse jamais en silence.
    CONSTRAINT indemnisation_decision_complete CHECK (
        (etat = 'demandee' AND decide_par IS NULL AND decide_le IS NULL)
        OR (etat <> 'demandee' AND decide_par IS NOT NULL AND decide_le IS NOT NULL)),
    CONSTRAINT indemnisation_refus_motive CHECK (
        etat <> 'refusee' OR decision_motif_cle IS NOT NULL)
);

-- File d'exploitation (`GET /admin/indemnisations`, filtrable par état).
CREATE INDEX indemnisation_par_etat ON coursier.indemnisation (etat, cree_le DESC);
-- Caisse du coursier (`GET /moi/caisse`).
CREATE INDEX indemnisation_par_coursier ON coursier.indemnisation (coursier_id, cree_le DESC);

-- ── 3. Le livre de caisse — append-only ────────────────────────────────────
--
-- FR-070 : une écriture par mouvement. FR-073 : aucun UPDATE, aucun DELETE —
-- une révocation AJOUTE une ligne `correction` de montant opposé et renseigne
-- `annule_par` sur l'originale (seule mise à jour tolérée, sur une colonne qui
-- ne porte pas d'argent). Le solde d'avances en cours est une SOMME, jamais une
-- table : une table de solde serait une seconde vérité à réconcilier
-- (data-model §1.3).
CREATE TABLE coursier.ecriture_caisse (
    id             uuid PRIMARY KEY,                     -- UUIDv7
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    type           coursier.type_ecriture NOT NULL,
    -- SIGNÉ : négatif = argent sorti de la poche du coursier (avance),
    -- positif = argent qui y rentre (remboursement, indemnisation).
    montant_unites bigint NOT NULL CHECK (montant_unites <> 0),
    devise         text   NOT NULL,
    commande_id    uuid REFERENCES commandes.commande (id) ON DELETE CASCADE,
    livraison_id   uuid REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    arret_id       uuid REFERENCES commandes.arret (id)     ON DELETE SET NULL,
    indemnisation_id uuid REFERENCES coursier.indemnisation (id) ON DELETE RESTRICT,
    -- Idempotence du consommateur outbox (R9) : un lot rejoué par le worker
    -- n'écrit qu'une fois. NULLABLE parce qu'une correction d'exploitation ne
    -- naît d'aucun événement consommé — et NULL n'entre pas dans un UNIQUE.
    evenement_id   uuid UNIQUE,
    -- Pointe l'écriture `correction` qui annule celle-ci.
    annule_par     uuid REFERENCES coursier.ecriture_caisse (id) ON DELETE SET NULL,
    ecrit_le       timestamptz NOT NULL DEFAULT now()     -- horodatage SERVEUR (V)
);

-- Historique du jour (FR-069) — le plus récent d'abord.
CREATE INDEX ecriture_par_coursier_date ON coursier.ecriture_caisse (coursier_id, ecrit_le DESC);
-- Solde d'avances ouvertes (FR-067) et exposition admin (FR-075).
CREATE INDEX ecriture_avances ON coursier.ecriture_caisse (coursier_id, livraison_id)
    WHERE type = 'avance';
-- Rapprochement avance ↔ remboursement d'une même livraison.
CREATE INDEX ecriture_par_livraison ON coursier.ecriture_caisse (livraison_id);

-- Le livre est APPEND-ONLY, et c'est la base qui le tient — pas une convention.
-- Seule `annule_par` (qui ne porte pas d'argent) peut être posée après coup, et
-- seulement si elle était nulle : une correction ne se réécrit pas non plus.
CREATE OR REPLACE FUNCTION coursier.refuser_mutation_ecriture() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'coursier.caisse.ecriture_immuable'
            USING HINT = 'une correction est une écriture INVERSE, jamais un DELETE (FR-073)';
    END IF;
    IF NEW.id <> OLD.id
       OR NEW.coursier_id <> OLD.coursier_id
       OR NEW.type <> OLD.type
       OR NEW.montant_unites <> OLD.montant_unites
       OR NEW.devise <> OLD.devise
       OR NEW.ecrit_le <> OLD.ecrit_le
       OR NEW.commande_id IS DISTINCT FROM OLD.commande_id
       OR NEW.livraison_id IS DISTINCT FROM OLD.livraison_id
       OR NEW.arret_id IS DISTINCT FROM OLD.arret_id
       OR NEW.indemnisation_id IS DISTINCT FROM OLD.indemnisation_id
       OR NEW.evenement_id IS DISTINCT FROM OLD.evenement_id
       OR OLD.annule_par IS NOT NULL THEN
        RAISE EXCEPTION 'coursier.caisse.ecriture_immuable'
            USING HINT = 'seule annule_par, encore nulle, peut être posée (FR-073)';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER ecriture_caisse_immuable
    BEFORE UPDATE OR DELETE ON coursier.ecriture_caisse
    FOR EACH ROW EXECUTE FUNCTION coursier.refuser_mutation_ecriture();

-- ── 4. Appels passés via l'app ─────────────────────────────────────────────
--
-- AUCUN numéro de téléphone n'est stocké (R6) : l'appel part du téléphone, le
-- serveur n'en journalise que l'intention, la direction, le motif et l'issue
-- déclarée.
CREATE TABLE coursier.appel_coursier (
    id             uuid PRIMARY KEY,                     -- UUIDv7
    livraison_id   uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id)      ON DELETE RESTRICT,
    vers           text NOT NULL CHECK (vers IN ('client', 'vendeur')),
    prestataire_id uuid REFERENCES prestataires.prestataire (id) ON DELETE SET NULL,
    motif          coursier.motif_appel NOT NULL,
    issue          coursier.issue_appel NOT NULL DEFAULT 'inconnue',
    -- Idempotence de la file hors-ligne (constitution V).
    uuid_client    uuid NOT NULL UNIQUE,
    passe_le       timestamptz NOT NULL DEFAULT now(),   -- horodatage SERVEUR (fait foi)
    passe_le_local timestamptz NOT NULL,                 -- horodatage appareil — observation
    -- Un appel vendeur DIT lequel ; un appel client n'a pas de prestataire.
    CONSTRAINT appel_prestataire_coherent CHECK (
        (vers = 'vendeur') OR prestataire_id IS NULL)
);

-- LA requête de la preuve d'échec : nombre d'appels et espacement (FR-056).
CREATE INDEX appel_par_livraison ON coursier.appel_coursier (livraison_id, passe_le);

-- ── 5. Relevés de présence ─────────────────────────────────────────────────
--
-- ARTCI : une DISTANCE arrondie, jamais un couple lat/lon (R8) — patron
-- `distance_scan_m` du cycle 006. Ce que le serveur doit savoir, c'est « le
-- coursier était-il à moins de N mètres », pas « où ».
CREATE TABLE coursier.releve_presence (
    id               uuid PRIMARY KEY,                   -- UUIDv7
    livraison_id     uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    distance_m       integer NOT NULL CHECK (distance_m >= 0),
    releve_le        timestamptz NOT NULL DEFAULT now(), -- réception SERVEUR
    releve_le_local  timestamptz NOT NULL,               -- échantillon sur l'appareil
    uuid_client      uuid NOT NULL UNIQUE                -- idempotence des lots rejoués
);

-- La durée se calcule sur l'ordre LOCAL — celui de la réalité vécue par Yao —
-- tout en restant vérifiable côté serveur (data-model §1.6).
CREATE INDEX releve_par_livraison ON coursier.releve_presence (livraison_id, releve_le_local);

-- ── 6. Photos de preuve d'échec ────────────────────────────────────────────
--
-- La photo va dans Garage (`socle::DepotObjets`), sa clé ici. Purgée par un job
-- périodique sur le patron `job_purge_photos_collecte` du cycle 006, à la
-- rétention de zone `coursier.retention_photo_preuve_jours` (365 j par défaut).
CREATE TABLE coursier.preuve_photo (
    id           uuid PRIMARY KEY,                       -- UUIDv7
    livraison_id uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    cle_objet    text NOT NULL,                          -- clé Garage
    prise_le     timestamptz NOT NULL DEFAULT now(),
    uuid_client  uuid NOT NULL UNIQUE,                   -- idempotence de la file
    purgee_le    timestamptz                             -- job de rétention
);

CREATE INDEX preuve_photo_par_livraison ON coursier.preuve_photo (livraison_id, prise_le);
-- Balayage du job de purge : les plus anciennes non purgées d'abord.
CREATE INDEX preuve_photo_a_purger ON coursier.preuve_photo (prise_le)
    WHERE purgee_le IS NULL;
