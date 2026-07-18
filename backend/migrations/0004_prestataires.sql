-- Prestataires agréés et catalogue vendeur (cycle 005,
-- specs/005-prestataires-catalogue-vendeur/data-model.md §2–3).
-- Schéma dédié (constitution II : un schéma par module). Nouvelle migration —
-- 0001..0003 intouchées (constitution I).
--
-- Le PRESTATAIRE est l'entité générale (agrément, charte, plaque, sites,
-- plan) ; le VENDEUR est son extension MVP (catalogue, stock). Un artisan de
-- phase N sera un autre type SANS migration : il n'aura simplement pas de
-- ligne `vendeur` (cadrage §11.13).
CREATE SCHEMA IF NOT EXISTS prestataires;

-- ── 1. Types énumérés ──────────────────────────────────────────────────────

-- Cycle de vie (FR-004). Transitions autorisées : prospect→agree,
-- agree→suspendu, suspendu→agree — gardées par la table de transitions du
-- crate ; l'énum fige seulement le vocabulaire.
CREATE TYPE prestataires.statut_prestataire AS ENUM
    ('prospect', 'agree', 'suspendu');

-- Statut DÉCLARÉ de boutique (FR-030). L'état EFFECTIF n'est jamais stocké :
-- il se déduit à la lecture (horaires, échéances — FR-032, research R3).
CREATE TYPE prestataires.statut_boutique AS ENUM
    ('ouvert', 'ferme', 'ferme_journee', 'en_pause');

-- Les trois sources d'une bascule de disponibilité (VND-04, FR-037).
CREATE TYPE prestataires.source_bascule AS ENUM
    ('vendeur', 'coursier', 'admin');

-- ── 2. Plans — PROVISION VND-07 (tables uniquement, principe IX) ───────────

-- Aucune UI, aucune logique ne lit ni n'écrit ces tables au MVP (FR-048).
CREATE TABLE prestataires.plan (
    id      uuid        PRIMARY KEY,
    code    text        NOT NULL UNIQUE,
    nom_cle text        NOT NULL,   -- clé i18n fr (plan.<code>.nom)
    cree_le timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE prestataires.plan_caracteristique (
    plan_id uuid  NOT NULL REFERENCES prestataires.plan (id) ON DELETE CASCADE,
    cle     text  NOT NULL,
    valeur  jsonb NOT NULL,
    PRIMARY KEY (plan_id, cle)
);

-- Ligne de RÉFÉRENCE, pas un seed : `prestataire.plan_id` est NOT NULL, le
-- plan « Gratuit » doit donc exister partout où le schéma existe (bases de
-- test sqlx comprises, qui n'appliquent que les migrations).
INSERT INTO prestataires.plan (id, code, nom_cle)
VALUES ('00000000-0000-4000-8000-000000000001', 'gratuit', 'plan.gratuit.nom');

-- ── 3. Prestataire ─────────────────────────────────────────────────────────

-- Fiche + cycle de vie + identité de plaque (FR-002, FR-004, FR-013).
-- Journal de la DERNIÈRE décision dans les colonnes statut_* ; l'historique
-- complet vit dans les événements outbox (patron attribution_role, cycle 003).
CREATE TABLE prestataires.prestataire (
    id                    uuid        PRIMARY KEY,
    nom                   text        NOT NULL,
    categorie_id          uuid        NOT NULL REFERENCES zones.categorie (id) ON DELETE RESTRICT,
    -- Type `ville` exigé — vérifié par le crate à la création et à la
    -- correction (FR-002) : seule granularité que l'activation sait lire.
    ville_id              uuid        NOT NULL REFERENCES zones.zone (id) ON DELETE RESTRICT,
    contact_telephone     text        NOT NULL,   -- servi UNIQUEMENT à l'admin (SC-013)
    delai_preparation_min integer     NOT NULL CHECK (delai_preparation_min >= 0),
    statut                prestataires.statut_prestataire NOT NULL DEFAULT 'prospect',
    statut_decide_par     uuid        REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    statut_decide_le      timestamptz,
    statut_motif          text,       -- REQUIS pour la suspension (FR-010)
    -- Identité de plaque : posée au PREMIER agrément, STABLE ensuite — la
    -- suspension n'y touche pas (FR-013..015, SC-003). Le code de secours
    -- n'est PAS unique, à aucune échelle (FR-014).
    jeton_plaque          text        UNIQUE,
    code_secours          text        CHECK (code_secours ~ '^[0-9]{4}$'),
    plan_id               uuid        NOT NULL REFERENCES prestataires.plan (id) ON DELETE RESTRICT,
    cree_le               timestamptz NOT NULL DEFAULT now(),
    modifie_le            timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT plaque_complete CHECK ((jeton_plaque IS NULL) = (code_secours IS NULL))
);

-- Comptage des agréés par couple catégorie/ville — l'entrée du recalcul
-- d'activation ZON-03 (FR-009, FR-056, research R7).
CREATE INDEX idx_prestataire_comptage
    ON prestataires.prestataire (ville_id, categorie_id)
    WHERE statut = 'agree'::prestataires.statut_prestataire;

-- Photos de fiche (FR-025). Clé S3 toujours NEUVE au dépôt ; l'objet
-- déréférencé est supprimé APRÈS commit (patron du cycle 003) — purge portée
-- par l'objet, aucune purge périodique (FR-026).
CREATE TABLE prestataires.photo_prestataire (
    id             uuid        PRIMARY KEY,
    prestataire_id uuid        NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE CASCADE,
    cle_objet      text        NOT NULL,   -- prestataires/fiches/{prestataire_id}/{uuidv7}
    position       integer     NOT NULL DEFAULT 0,
    cree_le        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_photo_prestataire ON prestataires.photo_prestataire (prestataire_id, position);

-- Charte signée scannée (FR-003). 0..n par prestataire — une re-signature
-- n'écrase jamais ; l'agrément exige AU MOINS une ligne. Pièce contractuelle :
-- RESTRICT, conservée pendant la relation puis la durée de zone
-- `charte.conservation_post_relation_annees` (FR-026 — aucune purge à bâtir).
CREATE TABLE prestataires.charte_signee (
    id             uuid        PRIMARY KEY,
    prestataire_id uuid        NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    cle_objet      text        NOT NULL,   -- prestataires/chartes/{prestataire_id}/{uuidv7}
    version_charte text        NOT NULL,   -- version en vigueur À LA SIGNATURE (jamais recomparée)
    signee_le      date        NOT NULL,
    deposee_le     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_charte_prestataire ON prestataires.charte_signee (prestataire_id);

-- ── 4. Sites et horaires (FR-018..019, VND-06 en provision) ────────────────

-- 1..n sites par prestataire dans le MODÈLE ; exactement UN créé au MVP,
-- aucune sélection de site proposée nulle part (FR-019, principe IX). GPS,
-- horaires, statut de boutique et disponibilité des articles vivent ICI,
-- jamais sur le prestataire (FR-018).
CREATE TABLE prestataires.site (
    id                uuid        PRIMARY KEY,
    prestataire_id    uuid        NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE CASCADE,
    position_lat      double precision NOT NULL,   -- jamais servi en public (SC-013)
    position_lng      double precision NOT NULL,
    statut_boutique   prestataires.statut_boutique NOT NULL DEFAULT 'ouvert',
    pause_fin         timestamptz,   -- échéance quand statut = en_pause (jamais réécrite à l'échéance)
    ferme_journee_le  date,          -- date LOCALE couverte quand statut = ferme_journee
    statut_change_par uuid        REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    statut_change_le  timestamptz,
    cree_le           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pause_coherente
        CHECK (statut_boutique <> 'en_pause'::prestataires.statut_boutique OR pause_fin IS NOT NULL),
    CONSTRAINT journee_coherente
        CHECK (statut_boutique <> 'ferme_journee'::prestataires.statut_boutique OR ferme_journee_le IS NOT NULL)
);
CREATE INDEX idx_site_prestataire ON prestataires.site (prestataire_id);

-- Horaires hebdomadaires à plages multiples ; jour sans ligne = jour de
-- fermeture (FR-031). jour : 0 = lundi … 6 = dimanche, heures interprétées
-- dans le fuseau de la zone (`zone.fuseau_horaire`, research R8).
CREATE TABLE prestataires.horaire_site (
    site_id uuid     NOT NULL REFERENCES prestataires.site (id) ON DELETE CASCADE,
    jour    smallint NOT NULL CHECK (jour BETWEEN 0 AND 6),
    debut   time     NOT NULL,
    fin     time     NOT NULL,
    PRIMARY KEY (site_id, jour, debut),
    CHECK (debut < fin)
);

-- ── 5. Rattachements compte ↔ prestataire (FR-006..008) ────────────────────

-- Lien optionnel et multiple dans les DEUX sens. N'est accepté que sur un
-- prestataire AGRÉÉ (FR-007, analyse A1) — gardé par le crate. Les capacités
-- vendeur DÉRIVENT de `rattachement EXISTS ∧ statut = agree` : rien n'est
-- stocké, rien à cascader (FR-008).
CREATE TABLE prestataires.rattachement_compte (
    prestataire_id uuid        NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE CASCADE,
    compte_id      uuid        NOT NULL REFERENCES comptes.compte (id) ON DELETE CASCADE,
    rattache_par   uuid        NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    rattache_le    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (prestataire_id, compte_id)
);
CREATE INDEX idx_rattachement_compte ON prestataires.rattachement_compte (compte_id);

-- ── 6. Extension vendeur et catalogue (FR-001, FR-020..023, FR-055) ────────

-- La SPÉCIALISATION vendeur : présence de la ligne = le prestataire vend.
-- Un prestataire de phase N (plombier) n'en aura pas — et aucune règle du
-- tronc n'en suppose une (constitution II, research R14).
CREATE TABLE prestataires.vendeur (
    prestataire_id uuid PRIMARY KEY REFERENCES prestataires.prestataire (id) ON DELETE CASCADE
);

-- Article du catalogue. Montants : ENTIERS en unités mineures + devise ISO
-- 4217 posée par le serveur depuis la zone — JAMAIS de flottant (constitution
-- III, R13). Le CHECK porte FR-023 au niveau du schéma : un prix barré ≤ prix
-- est refusé par TOUT chemin d'écriture (SC-006).
CREATE TABLE prestataires.article (
    id                uuid        PRIMARY KEY,
    vendeur_id        uuid        NOT NULL REFERENCES prestataires.vendeur (prestataire_id) ON DELETE CASCADE,
    nom               text        NOT NULL,
    prix_unites       bigint      NOT NULL CHECK (prix_unites >= 0),
    devise            text        NOT NULL,
    prix_barre_unites bigint,
    photo_cle         text,       -- prestataires/articles/{article_id}/{uuidv7}
    categorie_interne text,       -- étiquette LIBRE d'affichage (FR-021), lue par aucune règle
    retire_le         timestamptz,   -- retrait RÉVERSIBLE (FR-055) ; NULL = au catalogue
    cree_le           timestamptz NOT NULL DEFAULT now(),
    modifie_le        timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT prix_barre_strictement_superieur
        CHECK (prix_barre_unites IS NULL OR prix_barre_unites > prix_unites)
);
CREATE INDEX idx_article_catalogue ON prestataires.article (vendeur_id) WHERE retire_le IS NULL;

-- Disponibilité PAR SITE (FR-018, FR-037). `source`/`bascule_par` tracent la
-- dernière bascule ; `source = admin ∧ NOT disponible` verrouille la remise en
-- vente à l'Admin seul (FR-041). `bascule_par` NULL = masquage automatique.
CREATE TABLE prestataires.disponibilite_article (
    article_id  uuid        NOT NULL REFERENCES prestataires.article (id) ON DELETE CASCADE,
    site_id     uuid        NOT NULL REFERENCES prestataires.site (id) ON DELETE CASCADE,
    disponible  boolean     NOT NULL DEFAULT true,
    source      prestataires.source_bascule,
    bascule_par uuid        REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    bascule_le  timestamptz,
    PRIMARY KEY (article_id, site_id)
);

-- ── 7. Signalements de rupture (FR-037..041) ───────────────────────────────

-- `id` = UUID généré CÔTÉ CLIENT (Idempotency-Key) : le rejeu fait
-- `ON CONFLICT (id) DO NOTHING` — un même identifiant ne compte jamais deux
-- fois (FR-039, constitution V). La fenêtre glissante compte sur `recu_le`
-- (horodatage SERVEUR) des coursiers DISTINCTS (FR-040, research R10).
CREATE TABLE prestataires.signalement_rupture (
    id                 uuid        PRIMARY KEY,
    article_id         uuid        NOT NULL REFERENCES prestataires.article (id) ON DELETE CASCADE,
    site_id            uuid        NOT NULL REFERENCES prestataires.site (id) ON DELETE CASCADE,
    coursier_compte_id uuid        NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    -- PROVISION sans FK : la commande qui rend le coursier éligible (cycle
    -- CMD) — patron `livraison_origine` du cycle 003.
    commande_id        uuid,
    horodatage_local   timestamptz NOT NULL,   -- horloge de l'appareil (file hors-ligne)
    recu_le            timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_signalement_fenetre ON prestataires.signalement_rupture (article_id, recu_le);

-- ── 8. Prix figés (FR-024, CMD-03 à venir) ─────────────────────────────────

-- Écrit UNIQUEMENT par `PgPrestataires::figer_prix` (research R6) ; AUCUN
-- UPDATE n'existe sur cette table — un montant figé ne bouge jamais (SC-005).
CREATE TABLE prestataires.prix_fige (
    id                uuid        PRIMARY KEY,
    article_id        uuid        NOT NULL REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    prix_unites       bigint      NOT NULL CHECK (prix_unites >= 0),
    devise            text        NOT NULL,
    prix_barre_unites bigint,     -- informatif, copié tel quel
    -- PROVISION sans FK : la commande qui verrouille (cycle CMD).
    reference_externe uuid,
    fige_le           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_prix_fige_article ON prestataires.prix_fige (article_id);
