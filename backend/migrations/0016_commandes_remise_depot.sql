-- Cycle CRS 010 — ce que `commandes` gagne (specs/010 data-model.md §2).
--
-- Aucune de ces colonnes ne porte de LOGISTIQUE (constitution II) : elles
-- décrivent la REMISE AU CLIENT, que le cycle 008 porte déjà sur la commande
-- (`code_livraison`, `essais_code`, `mode_remise`, `depot_photo_cle`), et
-- l'IDEMPOTENCE des deux actions qui n'en avaient pas (R4).
--
-- 0001..0015 sont INTOUCHÉES (constitution I) : ce fichier n'ajoute que des
-- colonnes, une contrainte et un commentaire.

-- ── 1. Dépôt autorisé — FERMÉ par défaut ───────────────────────────────────
--
-- Clarification du 2026-07-28 : la troisième voie de remise n'est pas un droit
-- du coursier. Elle s'ouvre commande par commande, par l'exploitation, avec sa
-- trace. Un défaut à `true` aurait rendu le dépôt possible partout sans que
-- personne ne l'ait décidé (FR-039, FR-048, FR-116).
ALTER TABLE commandes.commande
    ADD COLUMN depot_autorise      boolean NOT NULL DEFAULT false,
    ADD COLUMN depot_autorise_le   timestamptz,
    ADD COLUMN depot_autorise_par  uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    ADD COLUMN depot_motif_cle     text,
    -- ── Blocage du code de remise (FR-043, FR-044, FR-055) ─────────────────
    -- Le blocage est un ÉTAT DURABLE de la commande, pas un compteur Redis :
    -- un coursier qui réinstalle l'app ne doit pas repartir à zéro (R5).
    ADD COLUMN code_bloque_le      timestamptz,
    ADD COLUMN code_debloque_le    timestamptz,
    ADD COLUMN code_debloque_par   uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    ADD COLUMN code_deblocage_motif_cle text;

-- Le dépôt ne s'ouvre pas sans trace : les quatre colonnes vont ENSEMBLE. Sans
-- cette contrainte, « ouvert par personne, sans motif » serait un état
-- représentable — et c'est exactement l'état qu'une exploitation invoquerait
-- après coup pour ne pas répondre de sa décision.
ALTER TABLE commandes.commande
    ADD CONSTRAINT depot_trace_complete CHECK (
        depot_autorise = false
        OR (depot_autorise_le IS NOT NULL
            AND depot_autorise_par IS NOT NULL
            AND depot_motif_cle IS NOT NULL));

-- Une levée de blocage se motive, elle aussi (FR-055).
ALTER TABLE commandes.commande
    ADD CONSTRAINT deblocage_trace_complete CHECK (
        code_debloque_le IS NULL
        OR (code_debloque_par IS NOT NULL AND code_deblocage_motif_cle IS NOT NULL));

-- Alerte d'exploitation `GET /admin/remises/bloquees` (FR-044) : les commandes
-- dont le code est épuisé et le blocage non levé, les plus anciennes d'abord.
CREATE INDEX commande_code_bloque ON commandes.commande (code_bloque_le)
    WHERE code_bloque_le IS NOT NULL AND code_debloque_le IS NULL;

-- ── 2. Idempotence de la remise — le manque du cycle 008 (R4) ──────────────
--
-- La constitution V l'exige pour TOUTE action coursier, et le test obligatoire
-- du module (FR-089) est impossible sans : couper le réseau entre le scan et la
-- livraison, c'est précisément rejouer une remise.
ALTER TABLE commandes.livraison
    ADD COLUMN remise_uuid_client uuid UNIQUE,
    -- Validée hors ligne ? Journalisé, JAMAIS décisif : le serveur revalide au
    -- rejeu (FR-046, R7). C'est ce qui rend le risque du code à 4 chiffres
    -- traçable au lieu d'invisible.
    ADD COLUMN remise_hors_ligne  boolean NOT NULL DEFAULT false;

-- ── 3. Idempotence de l'échec (R4) ─────────────────────────────────────────
ALTER TABLE commandes.issue_echec
    ADD COLUMN issue_uuid_client uuid UNIQUE;

-- ── 4. Le commentaire de 0004 décrivait l'état d'ALORS ─────────────────────
--
-- « servi UNIQUEMENT à l'admin » était vrai au cycle 005. Le coursier ASSIGNÉ
-- reçoit désormais le contact du vendeur dans son pré-provisionnement, pour
-- pouvoir appeler HORS LIGNE (R6). La règle qui tient toujours est celle de
-- SC-013 du cycle 005 : aucune consultation NON AUTHENTIFIÉE ne révèle un
-- contact — et elle reste intacte. On ne réécrit pas 0004 (constitution I), on
-- corrige le commentaire ici.
COMMENT ON COLUMN prestataires.prestataire.contact_telephone IS
    'Contact du vendeur. Servi à l''admin et au coursier ASSIGNÉ (CRS-03) ; jamais à une consultation non authentifiée, jamais journalisé.';
