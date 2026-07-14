-- Comptes, sessions, rôles, dossier coursier et adresses (cycle 003,
-- data-model.md §1–2). Schéma dédié (constitution II : un schéma par module).
-- NOUVELLE migration — 0001/0002 intouchées (constitution I).
--
-- Rien d'éphémère ici : défis OTP, compteurs SMS/IP et jetons d'inscription
-- vivent en Redis (reconstructibles — data-model §3, research R3). Postgres
-- reste la seule vérité durable.
CREATE SCHEMA IF NOT EXISTS comptes;

-- ── 1. Types énumérés ──────────────────────────────────────────────────────

-- Rôles CUMULABLES : un compte en porte 1..n (FR-010), jamais « un seul rôle ».
CREATE TYPE comptes.role AS ENUM ('client', 'coursier', 'vendeur', 'admin');

-- UNE SEULE machine à états pour toutes les attributions (research R9) : le
-- « statut du dossier coursier » (FR-016) EST le statut de l'attribution
-- `coursier` — aucune duplication à synchroniser.
CREATE TYPE comptes.statut_role AS ENUM ('en_attente', 'valide', 'refuse', 'suspendu');

-- ── 2. Tables ──────────────────────────────────────────────────────────────

-- Identité Mefali = un numéro vérifié, rien d'autre (clarification « numéro
-- seul » : aucune donnée nominative au MVP — minimisation ARTCI).
CREATE TABLE comptes.compte (
    id                    uuid        PRIMARY KEY,
    -- Format E.164 garanti par le schéma ; la normalisation (indicatif par
    -- défaut de la zone) est faite en amont par le domaine (research R4).
    telephone_e164        text        NOT NULL UNIQUE
                                      CHECK (telephone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    -- Rattachement structurel (indicatif, paramètres, devise à terme — R13).
    zone_id               uuid        NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    -- Consentement ARTCI bloquant : NOT NULL = aucun compte sans consentement
    -- horodaté (FR-006, SC-008 garanti par le schéma, pas par du code).
    consentement_version  text        NOT NULL,
    consentement_le       timestamptz NOT NULL,
    -- PROVISIONS CPT-06 (« prêt ≠ construit », constitution IX) : colonnes
    -- SEULEMENT — aucune logique ne les lit, aucune UI ne les expose ce cycle.
    prepaiement_impose    boolean     NOT NULL DEFAULT false,
    bloque                boolean     NOT NULL DEFAULT false,
    cree_le               timestamptz NOT NULL DEFAULT now(),
    -- Mise à jour à chaque vérification OTP réussie.
    derniere_connexion_le timestamptz
);

-- Une session = un appareil. N'expire JAMAIS d'elle-même (clarification) : la
-- sécurité d'un téléphone perdu repose sur la déconnexion à distance (US2).
CREATE TABLE comptes.session (
    id                     uuid        PRIMARY KEY,  -- = claim `sid` du JWT
    compte_id              uuid        NOT NULL REFERENCES comptes.compte (id) ON DELETE CASCADE,
    -- Refresh opaque 256 bits stocké HACHÉ (SHA-256) : un dump n'expose aucun
    -- jeton rejouable. La rotation fait glisser le hash courant vers precedent —
    -- un jeton présenté sur `precedent` = réutilisation → session révoquée (R2).
    refresh_hash           bytea       NOT NULL UNIQUE,
    refresh_precedent_hash bytea       UNIQUE,
    appareil_nom           text        NOT NULL,
    appareil_plateforme    text        NOT NULL CHECK (appareil_plateforme IN ('android', 'ios')),
    cree_le                timestamptz NOT NULL DEFAULT now(),
    derniere_activite_le   timestamptz NOT NULL DEFAULT now(),
    revoquee_le            timestamptz   -- NULL = active
);

-- Liste des appareils actifs d'un compte (GET /moi/sessions).
CREATE INDEX idx_session_compte_active ON comptes.session (compte_id)
    WHERE revoquee_le IS NULL;

-- L'UNIQUE machine à états (research R9). Porte aussi le journal des décisions
-- admin (qui / quand / motif — FR-014), doublé par les événements outbox
-- `role.*` : aucune table d'audit parallèle (patron du cycle 002).
CREATE TABLE comptes.attribution_role (
    compte_id  uuid                 NOT NULL REFERENCES comptes.compte (id) ON DELETE CASCADE,
    role       comptes.role         NOT NULL,
    statut     comptes.statut_role  NOT NULL,
    motif      text,                -- motif de la dernière décision (FR-014, FR-017)
    -- Admin décideur ; NULL = automatique (le rôle client, posé à l'inscription).
    -- RESTRICT : supprimer un admin ne doit pas transformer ses décisions en
    -- « automatique » — ce qui corromprait la sémantique du journal (FR-014).
    decide_par uuid                 REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    decide_le  timestamptz,
    demande_le timestamptz          NOT NULL DEFAULT now(),
    PRIMARY KEY (compte_id, role),
    -- Le rôle client est toujours valide ce cycle (immuable — research R9).
    CHECK (role <> 'client'::comptes.role OR statut = 'valide'::comptes.statut_role)
);

-- Revue admin des demandes par statut (GET /admin/comptes/dossiers-coursier).
CREATE INDEX idx_attribution_role_statut ON comptes.attribution_role (role, statut);

-- CONTENU du dossier uniquement — le STATUT vit sur attribution_role
-- (compte_id, 'coursier') : une seule source de vérité (research R9). 1:1 avec
-- le compte ; `soumis_le` est réécrit à chaque re-soumission après refus.
CREATE TABLE comptes.dossier_coursier (
    compte_id               uuid        PRIMARY KEY
                                        REFERENCES comptes.compte (id) ON DELETE CASCADE,
    -- Clé S3 `comptes/pieces/{compte_id}/{uuidv7}` — bucket privé, lecture par
    -- URL présignée derrière un endpoint admin (research R7).
    piece_cle_objet         text        NOT NULL,
    -- Type MIME validé à l'upload (jpeg/png/webp/pdf) — data-model §2.
    piece_mime              text        NOT NULL,
    -- Référent local : la « caution morale » du cadrage §7.1.
    referent_nom            text        NOT NULL,
    referent_telephone_e164 text        NOT NULL
                                        CHECK (referent_telephone_e164 ~ '^\+[1-9][0-9]{6,14}$'),
    soumis_le               timestamptz NOT NULL DEFAULT now()
);

-- Véhicules déclarés, pris dans le référentiel ZON-03. L'appartenance aux types
-- ACTIFS de la zone est validée à la SOUMISSION (FR-015), pas par contrainte :
-- un type désactivé ensuite reste déclaré et signalé (edge case de la spec).
CREATE TABLE comptes.vehicule_declare (
    id                uuid PRIMARY KEY,
    compte_id         uuid NOT NULL
                      REFERENCES comptes.dossier_coursier (compte_id) ON DELETE CASCADE,
    type_transport_id uuid NOT NULL
                      REFERENCES zones.type_transport (id) ON DELETE RESTRICT,
    UNIQUE (compte_id, type_transport_id)
);

-- Adresses enregistrées avec repère (texte et/ou vocal). Pas de CHECK « au
-- moins un repère » : une adresse purgée reste utilisable et redemande un
-- repère à la prochaine utilisation (FR-022).
CREATE TABLE comptes.adresse (
    id                      uuid             PRIMARY KEY,  -- = Idempotency-Key du POST (R14)
    compte_id               uuid             NOT NULL
                                             REFERENCES comptes.compte (id) ON DELETE CASCADE,
    libelle                 text             NOT NULL,  -- contenu utilisateur, PAS une clé i18n
    -- Pin GPS (§8.2) — pas de PostGIS ce cycle ; aucune distance calculée ici.
    lat                     double precision NOT NULL,
    lng                     double precision NOT NULL,
    repere_texte            text,
    -- Clé S3 `comptes/reperes/{compte_id}/{uuidv7}` ; NULL après purge (R8).
    repere_vocal_cle_objet  text,
    -- ≤ paramètre de zone `medias.note_vocale_duree_max_s` (jamais en dur).
    repere_vocal_duree_s    smallint,
    zone_id                 uuid             NOT NULL
                                             REFERENCES zones.zone (id) ON DELETE RESTRICT,
    -- PROVISION, volontairement SANS FK : la table livraison naît aux cycles
    -- CMD/CRS. Le tronc commande ne contient aucun champ logistique et rien ici
    -- ne suppose que commande = livraison (constitution II).
    livraison_origine       uuid,
    cree_le                 timestamptz      NOT NULL DEFAULT now(),
    -- Base de la purge (rétention = paramètre de zone) ; avancée par
    -- `marquer_adresse_utilisee`, que le cycle CMD appellera.
    derniere_utilisation_le timestamptz      NOT NULL DEFAULT now(),
    -- Soft delete : les livraisons passées ne sont pas affectées (FR-021).
    supprimee_le            timestamptz
);

-- Liste des adresses d'un compte (GET /moi/adresses).
CREATE INDEX idx_adresse_compte_active ON comptes.adresse (compte_id)
    WHERE supprimee_le IS NULL;

-- Balayage du job de purge quotidien (R8) : seules les adresses vivantes
-- portant encore un repère vocal sont candidates.
CREATE INDEX idx_adresse_purge_repere ON comptes.adresse (derniere_utilisation_le)
    WHERE repere_vocal_cle_objet IS NOT NULL AND supprimee_le IS NULL;
