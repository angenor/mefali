-- Cycle DSP 009 — l'INTENTION d'être en ligne, découverte à la surface HTTP
-- (T025). Nouvelle migration, jamais une retouche de 0010/0011/0012
-- (constitution I, règle 2 de tasks.md).
--
-- ── Pourquoi cette colonne existe ─────────────────────────────────────────
--
-- « Être dans le pool » = l'état Redis du coursier existe, et cet état n'est
-- écrit qu'à la PUBLICATION D'UNE POSITION. Le contrat distingue pourtant deux
-- choses (contrats/dispatch-openapi.md §1.1) :
--
--   `en_ligne: true`      — Yao a basculé l'interrupteur ;
--   `dans_le_pool: false` — aucune position n'est encore arrivée.
--
-- Sans persistance, ces deux faits se confondraient : `GET /moi/disponibilite`
-- après un redémarrage d'app rendrait « hors ligne » à un coursier qui roule.
--
-- ── Pourquoi PAS en Redis ─────────────────────────────────────────────────
--
-- Redis est éphémère et RECONSTRUCTIBLE (constitution II). Une intention perdue
-- au `FLUSHDB` ferait ignorer (`204`) toutes les publications suivantes : le
-- pool ne se reconstituerait JAMAIS tout seul, et SC-004 tomberait — alors que
-- c'est précisément l'invariant que ce cycle doit tenir.
--
-- ── Pourquoi sur `plafond_jour` plutôt qu'une table de plus ───────────────
--
-- C'est la MÊME déclaration, faite dans le même geste sur l'écran K1
-- (« Passer en ligne — plafond 10 000 FCFA »), et elle a la même durée de vie :
-- le jour civil, jamais reporté (FR-011). Une seconde table à clé
-- `(coursier, jour)` serait une jointure de plus pour la même ligne de vie.

ALTER TABLE dispatch.plafond_jour
    -- Intention déclarée. `false` ⇒ aucune offre, quelle que soit la position
    -- publiée (une position arrivée après un « hors ligne » est IGNORÉE, pas
    -- refusée : l'app peut être en retard d'un tic).
    ADD COLUMN en_ligne   boolean NOT NULL DEFAULT false,
    -- Horodatage SERVEUR de la dernière bascule — trace d'exploitation.
    ADD COLUMN bascule_le timestamptz;

-- Coursiers en ligne d'un jour donné : matière de `GET /admin/dispatch/pool` et
-- du balayage du tic.
CREATE INDEX plafond_jour_en_ligne ON dispatch.plafond_jour (jour)
    WHERE en_ligne;
