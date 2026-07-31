-- Cycle CRS 010 — mémoire du BASCULEMENT des trois preuves d'échec (FR-057).
--
-- Migration DÉCOUVERTE à l'implémentation d'US4 (règle 2 des tâches du cycle :
-- 0015..0018 sont appliquées, on n'y touche pas).
--
-- ── Pourquoi une table plutôt qu'un calcul ────────────────────────────────
--
-- `preuves_echec.reunies` est un événement de **transition** : il dit l'instant
-- où un échec est devenu déclarable, et c'est cet instant que l'exploitation
-- lira pour mesurer « combien de temps Yao a réellement essayé ». Or l'état des
-- trois preuves est un CALCUL sur trois tables (appels, relevés, photos) : il
-- redevient vrai à chaque lecture. Sans mémoire, chaque `GET /preuves` après le
-- basculement ré-émettrait l'événement — un flux d'événements identiques dont
-- aucun ne marquerait le moment réel.
--
-- La clé primaire sur `livraison_id` fait tout le travail : `INSERT … ON
-- CONFLICT DO NOTHING` n'insère qu'une fois, et « 0 ligne insérée » est
-- exactement le signal « déjà émis, ne pas ré-émettre ». L'idempotence est une
-- contrainte de base, pas une convention de code (patron 0018).
--
-- ⚠ La table ne porte AUCUN critère : elle n'est pas une seconde vérité sur les
-- preuves, seulement la trace de l'instant. Les preuves elles-mêmes restent
-- recalculées depuis leurs trois sources à chaque lecture (FR-060) — un seuil de
-- zone que l'exploitation resserre s'applique donc immédiatement, y compris à
-- une livraison déjà basculée.
CREATE TABLE coursier.preuves_reunies (
    livraison_id uuid PRIMARY KEY REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    -- Horodatage SERVEUR du basculement (constitution V) : c'est lui qui fonde
    -- l'indemnisation, jamais l'horloge de l'appareil.
    reunies_le   timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE coursier.preuves_reunies IS
    'Instant où les trois preuves d''échec se sont réunies pour une livraison. Rend l''émission de preuves_echec.reunies exactement-une-fois (FR-057) ; ne porte aucun critère.';
