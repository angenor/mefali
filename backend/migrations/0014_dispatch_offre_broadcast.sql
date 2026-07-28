-- Cycle DSP 009 — l'unicité d'offre en vol par commande ne vaut que pour la
-- CASCADE (T055/T056, découvert au test de broadcast).
--
-- ── Le défaut corrigé ─────────────────────────────────────────────────────
--
-- `0011_dispatch_tables.sql` posait `offre_en_vol_par_commande` sans condition
-- de mode. Or DSP-05 est *précisément* le fait d'offrir la même course à
-- PLUSIEURS coursiers en même temps : l'index rendait le broadcast impossible —
-- le second destinataire était refusé par la base, et « demander à tout le
-- monde » se réduisait à « demander à une personne de plus ».
--
-- ── Ce qui reste garanti, et par quoi ─────────────────────────────────────
--
-- L'invariant qui compte n'est pas « une offre par commande » : c'est **un
-- coursier par commande**. Il est tenu par Postgres, ailleurs et mieux :
-- `assigner_coursier_tx` fait `SELECT … FOR UPDATE` puis `verifier_transition`
-- sur une table de transitions FERMÉE qui ne contient pas `en_cours → en_cours`.
-- Deux acceptations concurrentes se sérialisent, la seconde est annulée avec
-- toute sa transaction (research R4) — et cela vaut **même sans Redis**.
--
-- L'index par COURSIER, lui, ne bouge pas : personne ne doit voir deux écrans à
-- la fois, en cascade comme en broadcast (FR-056, FR-062).
--
-- 0001..0013 sont INTOUCHÉES (constitution I).

DROP INDEX dispatch.offre_en_vol_par_commande;

-- En CASCADE, l'unicité par commande reste le filet Postgres du verrou Redis :
-- une cascade offre à un seul coursier à la fois, par construction.
CREATE UNIQUE INDEX offre_en_vol_par_commande_cascade ON dispatch.offre (commande_id)
    WHERE issue = 'en_vol' AND mode = 'cascade';
