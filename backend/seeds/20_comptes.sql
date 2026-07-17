-- Seed du module comptes (cycle 003, data-model §6). Rejouable : UUID FIXES +
-- ON CONFLICT partout → une ré-exécution converge vers le même état (SC-008).
-- Aucun événement outbox (chargement initial, pas une transition — patron 002).
--
-- Deux apports :
--   1. le PREMIER ADMIN, créé hors parcours applicatif (spec, edge case
--      « Premier admin » : aucun chemin d'auto-attribution du rôle admin
--      n'existe — c'est ce seed, et lui seul, qui amorce la chaîne FR-012) ;
--   2. les PARAMÈTRES de zone du module, posés au niveau PAYS et hérités par
--      Tiassalé (mécanisme ZON-01) : ce sont eux qui rendent « paramétrable »
--      ce que FR-024 exige de ne jamais mettre en dur.

-- ── Paramètres au niveau PAYS (Côte d'Ivoire), hérités par Tiassalé ────────
-- Posés au PAYS et non à la ville : l'indicatif, la durée d'une note vocale et
-- la rétention d'un repère sont des propriétés nationales/réglementaires, pas
-- des réglages de ville — une nouvelle ville de CI les hérite sans une ligne.
--
-- Les constantes OTP (6 chiffres, 5 min, 3 essais, 3 SMS/h) ne sont PAS ici :
-- ce sont des constantes produit, absentes du « Récapitulatif des paramètres de
-- zone » (spec, Assumptions) — elles vivent dans `crates/comptes/src/otp.rs`.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- Indicatif appliqué aux saisies LOCALES sans indicatif (FR-001, R4).
    ('01900000-0000-7000-8000-000000000001', 'telephone.indicatif_defaut',           '"+225"'),
    -- Purge du repère vocal après 12 mois SANS UTILISATION de l'adresse
    -- (FR-022, clarification 2026-07-14 — minimisation ARTCI).
    ('01900000-0000-7000-8000-000000000001', 'adresse.retention_repere_vocal_jours', '365'),
    -- Durée maximale d'une note vocale de repère (FR-019, cadrage §8.2).
    ('01900000-0000-7000-8000-000000000001', 'medias.note_vocale_duree_max_s',       '30'),
    -- Version du texte ARTCI servie aux apps par la config distante (ZON-04) et
    -- renvoyée telle quelle à l'inscription (FR-006).
    ('01900000-0000-7000-8000-000000000001', 'consentement.artci_version',           '"2026-07"')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── Premier admin ──────────────────────────────────────────────────────────
-- Numéro d'exploitation PLACEHOLDER : à remplacer par le numéro réel du
-- fondateur avant la mise en service (c'est par OTP sur ce numéro que l'admin
-- obtient son jeton). Format E.164 valide et rattaché à Tiassalé.
--
-- consentement_le est FIGÉ (pas de now()) : avec now(), chaque re-seed
-- réécrirait l'horodatage et le double seed ne convergerait plus (SC-008).
INSERT INTO comptes.compte (id, telephone_e164, zone_id, consentement_version, consentement_le) VALUES
    ('01900000-0000-7000-8000-000000000401',
     '+2250700000001',
     '01900000-0000-7000-8000-000000000002',
     '2026-07',
     '2026-07-14T00:00:00Z')
ON CONFLICT (id) DO UPDATE SET
    telephone_e164       = EXCLUDED.telephone_e164,
    zone_id              = EXCLUDED.zone_id,
    consentement_version = EXCLUDED.consentement_version,
    consentement_le      = EXCLUDED.consentement_le;

-- Rôles du premier admin : client (comme tout compte) + admin. decide_par NULL
-- = décision non applicative (seed), cohérent avec « NULL = automatique ».
-- demande_le FIGÉ pour la même raison que consentement_le.
INSERT INTO comptes.attribution_role (compte_id, role, statut, decide_par, decide_le, demande_le) VALUES
    ('01900000-0000-7000-8000-000000000401', 'client', 'valide', NULL, NULL, '2026-07-14T00:00:00Z'),
    ('01900000-0000-7000-8000-000000000401', 'admin',  'valide', NULL, NULL, '2026-07-14T00:00:00Z')
ON CONFLICT (compte_id, role) DO UPDATE SET
    statut     = EXCLUDED.statut,
    decide_par = EXCLUDED.decide_par,
    decide_le  = EXCLUDED.decide_le,
    demande_le = EXCLUDED.demande_le;
