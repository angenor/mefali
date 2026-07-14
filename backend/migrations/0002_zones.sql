-- Arbre de zones et configuration héritée (cycle 002, data-model.md §1–2).
-- Schéma dédié (constitution II : un schéma par module). Nouvelle migration —
-- 0001 intouchée (constitution I).
CREATE SCHEMA IF NOT EXISTS zones;

-- ── 1. Types énumérés ──────────────────────────────────────────────────────

-- Profondeur variable, aucun ordre imposé (spec, Assumptions). village/quartier
-- = PROVISION : présents dans le type, sans écran ni logique dédiée (principe IX).
CREATE TYPE zones.type_zone AS ENUM
    ('pays', 'region', 'ville', 'commune', 'village', 'quartier');

-- Politique photo à la récupération (ZON-02, cadrage §4).
CREATE TYPE zones.politique_photo AS ENUM
    ('obligatoire', 'facultative', 'desactivee');

-- Forçage admin d'une catégorie à trois états (clarification spec).
CREATE TYPE zones.forcage_categorie AS ENUM
    ('automatique', 'force_actif', 'force_inactif');

-- ── 2. Tables ──────────────────────────────────────────────────────────────

-- L'arbre (FR-001..004). parent_id NULL = racine ; RESTRICT partout (une zone
-- avec enfants ou références ne se supprime pas — edge case spec).
CREATE TABLE zones.zone (
    id         uuid           PRIMARY KEY,
    parent_id  uuid           REFERENCES zones.zone (id) ON DELETE RESTRICT,
    type       zones.type_zone NOT NULL,
    nom        text           NOT NULL,
    cree_le    timestamptz    NOT NULL DEFAULT now(),
    modifie_le timestamptz    NOT NULL DEFAULT now()
);
CREATE INDEX idx_zone_parent ON zones.zone (parent_id);

-- Anti-cycle (FR-002) : défense en profondeur. La validation applicative de
-- PgZones renvoie une erreur explicite AVANT d'arriver ici ; ce trigger garantit
-- l'invariant même en écriture SQL directe (seeds, ADM T3, corrections manuelles).
CREATE FUNCTION zones.zone_sans_cycle() RETURNS trigger
    LANGUAGE plpgsql AS $$
DECLARE
    ancetre uuid := NEW.parent_id;
BEGIN
    WHILE ancetre IS NOT NULL LOOP
        IF ancetre = NEW.id THEN
            RAISE EXCEPTION 'cycle de zones : % ne peut être son propre ancêtre', NEW.id
                USING ERRCODE = 'ZC001';
        END IF;
        SELECT parent_id INTO ancetre FROM zones.zone WHERE id = ancetre;
    END LOOP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER zone_sans_cycle
    BEFORE INSERT OR UPDATE OF parent_id ON zones.zone
    FOR EACH ROW EXECUTE FUNCTION zones.zone_sans_cycle();

-- Configuration locale PARTIELLE (FR-005, FR-009, FR-011 ; research R1).
-- Une ligne = un paramètre défini sur une zone. Présence de la ligne = « défini »
-- (y compris false/""/0) ; absence de ligne = « explicitement absent ». Clés
-- namespacées (registre data-model §4) — nouveaux namespaces sans migration.
CREATE TABLE zones.parametre_zone (
    zone_id    uuid        NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    cle        text        NOT NULL,
    valeur     jsonb       NOT NULL,
    modifie_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (zone_id, cle)
);

-- Référentiel extensible des types de transport (FR-017). L'ACTIVATION par zone
-- n'est pas ici : c'est le paramètre hérité `transport.actifs` (research R1).
CREATE TABLE zones.type_transport (
    id      uuid     PRIMARY KEY,
    slug    text     NOT NULL UNIQUE,
    nom_cle text     NOT NULL,   -- clé i18n fr (transport.<slug>.nom) — jamais de chaîne UI
    ordre   smallint NOT NULL    -- tri d'affichage (à pied → camion)
);

-- Catégories = enregistrements de configuration (FR-012). seuil_activation et
-- mixable NE SONT PAS des colonnes : ce sont des paramètres de zone hérités
-- (categorie.<slug>.seuil_activation / .mixable) — une seule source de vérité (R1).
CREATE TABLE zones.categorie (
    id               uuid                  PRIMARY KEY,
    slug             text                  NOT NULL UNIQUE,
    nom_cle          text                  NOT NULL,   -- clé i18n fr (categorie.<slug>.nom)
    champs_fiche     jsonb                 NOT NULL DEFAULT '[]',
    politique_photo  zones.politique_photo NOT NULL DEFAULT 'facultative',
    workflow_vendeur text                  NOT NULL,   -- clé opaque ce cycle (CMD/VND)
    vehicule_minimal uuid                  REFERENCES zones.type_transport (id) ON DELETE RESTRICT,
    cree_le          timestamptz           NOT NULL DEFAULT now(),
    modifie_le       timestamptz           NOT NULL DEFAULT now()
);

-- État d'activation par ville (FR-013..016 ; research R6). `actif` (effectif) est
-- une colonne GÉNÉRÉE : une seule définition de l'état effectif, jamais dérivée
-- à la main. Le forçage l'emporte sur la règle du seuil (actif_auto).
CREATE TABLE zones.activation_categorie (
    id           uuid                    PRIMARY KEY,
    zone_id      uuid                    NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    categorie_id uuid                    NOT NULL REFERENCES zones.categorie (id) ON DELETE RESTRICT,
    forcage      zones.forcage_categorie NOT NULL DEFAULT 'automatique',
    actif_auto   boolean                 NOT NULL DEFAULT false,  -- dernier état calculé par le seuil
    actif        boolean GENERATED ALWAYS AS (
        CASE forcage
            WHEN 'force_actif'::zones.forcage_categorie   THEN true
            WHEN 'force_inactif'::zones.forcage_categorie THEN false
            ELSE actif_auto
        END
    ) STORED,
    modifie_le   timestamptz             NOT NULL DEFAULT now(),
    UNIQUE (zone_id, categorie_id)
);
