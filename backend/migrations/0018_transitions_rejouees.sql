-- Cycle CRS 010 — mémoire des transitions d'arrêt déjà appliquées (FR-089).
--
-- Migration DÉCOUVERTE par le test qui fait foi du module (règle 2 des tâches du
-- cycle : 0015..0017 sont appliquées, on n'y touche pas).
--
-- ── Ce qui n'allait pas ────────────────────────────────────────────────────
--
-- Le cycle 008 rendait une transition idempotente en comparant l'`uuid_client`
-- reçu au DERNIER accepté (`arret.transition_uuid_client`). Une seule mémoire,
-- donc une seule transition : rejouer `en-route` après qu'`arrive` a été
-- accepté ne trouvait plus son UUID et retombait sur la table fermée, qui
-- refusait `arrive → en_route` (409).
--
-- Or c'est EXACTEMENT ce que fait une file hors-ligne : elle rejoue un LOT dans
-- l'ordre, et elle le rejoue en entier tant qu'elle n'a pas pu retirer ses
-- actions acquittées (réseau qui retombe entre deux acquittements). Le second
-- drain de FR-089 échouait donc sur des actions parfaitement légitimes, et l'app
-- les aurait classées « refus définitif » — c'est-à-dire affiché à Yao qu'une
-- action réussie avait été rejetée.
--
-- ── La correction ─────────────────────────────────────────────────────────
--
-- Une ligne par transition ACCEPTÉE. Le rejeu de n'importe quel UUID connu rend
-- l'état courant, sans écriture ni événement — quel que soit son rang dans le
-- lot. C'est la lecture littérale de la constitution V (« un rejeu du même
-- identifiant rend le même résultat »), là où le cycle 008 n'en tenait que le
-- dernier.
--
-- `arret.transition_uuid_client` RESTE en place : il porte la dernière
-- transition et sert le payload des événements. On ne réécrit pas 0009.
CREATE TABLE commandes.transition_arret_rejouee (
    uuid_client uuid PRIMARY KEY,
    arret_id    uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE CASCADE,
    -- `en_route` | `arrive` | `indisponible` — journalisé pour l'exploitation.
    action      text NOT NULL,
    applique_le timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE commandes.transition_arret_rejouee IS
    'Transitions d''arrêt déjà appliquées, par uuid_client. Rend le rejeu d''un LOT idempotent (FR-089), pas seulement celui de la dernière action.';

-- Le rejeu se fait arrêt par arrêt, dans l''ordre du lot.
CREATE INDEX transition_rejouee_arret ON commandes.transition_arret_rejouee (arret_id, applique_le);
