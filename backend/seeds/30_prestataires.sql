-- Seed du module prestataires (cycle 005, specs/005 data-model §9, research
-- R15). Rejouable : UUID FIXES + ON CONFLICT partout → une ré-exécution
-- converge vers le même état (SC-012). AUCUN événement outbox (chargement
-- initial, pas une transition — FR-054, patron des cycles 002/003).
--
-- Trois prestataires de Tiassalé :
--   1. « Étal Tantie Affoué » (restauration, AGRÉÉE, AUCUN compte rattaché —
--      le cas nominal : pas d'app, pilotée par l'Admin) ;
--   2. « Boutique Kofi » (boutique_superette, AGRÉÉE, compte Kofi rattaché
--      avec le rôle vendeur — c'est lui qu'on ouvre dans Mefali Pro) ;
--   3. « Pharmacie du Marché » (pharmacie, PROSPECT complet — prêt à agréer à
--      la main : le seuil pharmacie est 1, l'agrément active la catégorie et
--      le rend commandable dans la même opération, quickstart §3.1).
--
-- L'état d'activation est POSÉ DIRECTEMENT (actif_auto), sans passer par le
-- recalcul de FR-009 (FR-054) : c'est ce qui rend les agréés du seed
-- commandables pendant leurs horaires, alors que 1 agréé n'atteint pas les
-- seuils réels (8 et 3). Les clés S3 des photos/chartes sont des POINTEURS de
-- démonstration : les objets n'existent pas dans Garage (une URL présignée
-- rendra 404 au GET) — l'agrément et la consultation n'exigent que les lignes.
-- Les jetons de plaque sont FIGÉS au format attendu (80 hex) mais non signés :
-- la résolution est une recherche exacte, la signature ne sert qu'au cycle QRC.

-- ── Compte Kofi (vendeur équipé) ───────────────────────────────────────────
INSERT INTO comptes.compte (id, telephone_e164, zone_id, consentement_version, consentement_le) VALUES
    ('01900000-0000-7000-8000-000000000402',
     '+2250700000002',
     '01900000-0000-7000-8000-000000000002',
     '2026-07',
     '2026-07-18T00:00:00Z')
ON CONFLICT (id) DO UPDATE SET
    telephone_e164       = EXCLUDED.telephone_e164,
    zone_id              = EXCLUDED.zone_id,
    consentement_version = EXCLUDED.consentement_version,
    consentement_le      = EXCLUDED.consentement_le;

-- Rôles de Kofi : client (comme tout compte) + vendeur (l'agrément vaut
-- validation — §5.1). decide_par = premier admin, horodatages FIGÉS.
INSERT INTO comptes.attribution_role (compte_id, role, statut, decide_par, decide_le, demande_le) VALUES
    ('01900000-0000-7000-8000-000000000402', 'client',  'valide', NULL, NULL, '2026-07-18T00:00:00Z'),
    ('01900000-0000-7000-8000-000000000402', 'vendeur', 'valide',
     '01900000-0000-7000-8000-000000000401', '2026-07-18T08:00:00Z', '2026-07-18T08:00:00Z')
ON CONFLICT (compte_id, role) DO UPDATE SET
    statut     = EXCLUDED.statut,
    decide_par = EXCLUDED.decide_par,
    decide_le  = EXCLUDED.decide_le,
    demande_le = EXCLUDED.demande_le;

-- ── Prestataires ───────────────────────────────────────────────────────────
INSERT INTO prestataires.prestataire
    (id, nom, categorie_id, ville_id, contact_telephone, delai_preparation_min,
     statut, statut_decide_par, statut_decide_le, statut_motif,
     jeton_plaque, code_secours, plan_id) VALUES
    ('01900000-0000-7000-8000-000000000501', 'Étal Tantie Affoué',
     '01900000-0000-7000-8000-000000000101',  -- restauration
     '01900000-0000-7000-8000-000000000002', '+2250700000011', 20,
     'agree', '01900000-0000-7000-8000-000000000401', '2026-07-18T08:00:00Z', NULL,
     '019000000000700080000000000005015eed5eed5eed5eed0123456789abcdef0123456789abcdef',
     '4217', '00000000-0000-4000-8000-000000000001'),
    ('01900000-0000-7000-8000-000000000502', 'Boutique Kofi',
     '01900000-0000-7000-8000-000000000102',  -- boutique_superette
     '01900000-0000-7000-8000-000000000002', '+2250700000002', 10,
     'agree', '01900000-0000-7000-8000-000000000401', '2026-07-18T08:30:00Z', NULL,
     '019000000000700080000000000005025eed5eed5eed5eedfedcba9876543210fedcba9876543210',
     '8080', '00000000-0000-4000-8000-000000000001'),
    ('01900000-0000-7000-8000-000000000503', 'Pharmacie du Marché',
     '01900000-0000-7000-8000-000000000104',  -- pharmacie (seuil 1)
     '01900000-0000-7000-8000-000000000002', '+2250700000013', 5,
     'prospect', NULL, NULL, NULL,
     NULL, NULL, '00000000-0000-4000-8000-000000000001')
ON CONFLICT (id) DO UPDATE SET
    nom = EXCLUDED.nom, categorie_id = EXCLUDED.categorie_id,
    ville_id = EXCLUDED.ville_id, contact_telephone = EXCLUDED.contact_telephone,
    delai_preparation_min = EXCLUDED.delai_preparation_min,
    statut = EXCLUDED.statut, statut_decide_par = EXCLUDED.statut_decide_par,
    statut_decide_le = EXCLUDED.statut_decide_le, statut_motif = EXCLUDED.statut_motif,
    jeton_plaque = EXCLUDED.jeton_plaque, code_secours = EXCLUDED.code_secours,
    plan_id = EXCLUDED.plan_id, modifie_le = now();

-- Extension vendeur : toutes les catégories du MVP vendent (data-model §3.7).
INSERT INTO prestataires.vendeur (prestataire_id) VALUES
    ('01900000-0000-7000-8000-000000000501'),
    ('01900000-0000-7000-8000-000000000502'),
    ('01900000-0000-7000-8000-000000000503')
ON CONFLICT (prestataire_id) DO NOTHING;

-- ── Sites (un par prestataire — FR-019) et horaires 8 h — 19 h lun–sam ─────
INSERT INTO prestataires.site
    (id, prestataire_id, position_lat, position_lng, statut_boutique) VALUES
    ('01900000-0000-7000-8000-000000000511', '01900000-0000-7000-8000-000000000501', 5.8983, -4.8232, 'ouvert'),
    ('01900000-0000-7000-8000-000000000512', '01900000-0000-7000-8000-000000000502', 5.8991, -4.8225, 'ouvert'),
    ('01900000-0000-7000-8000-000000000513', '01900000-0000-7000-8000-000000000503', 5.8975, -4.8240, 'ouvert')
ON CONFLICT (id) DO UPDATE SET
    prestataire_id = EXCLUDED.prestataire_id,
    position_lat = EXCLUDED.position_lat, position_lng = EXCLUDED.position_lng,
    statut_boutique = EXCLUDED.statut_boutique;

INSERT INTO prestataires.horaire_site (site_id, jour, debut, fin)
SELECT s.id, j.jour, TIME '08:00', TIME '19:00'
FROM (VALUES ('01900000-0000-7000-8000-000000000511'::uuid),
             ('01900000-0000-7000-8000-000000000512'::uuid),
             ('01900000-0000-7000-8000-000000000513'::uuid)) AS s(id),
     generate_series(0, 5) AS j(jour)
ON CONFLICT (site_id, jour, debut) DO UPDATE SET fin = EXCLUDED.fin;

-- ── Photos de fiche et chartes signées (pointeurs de démonstration) ────────
INSERT INTO prestataires.photo_prestataire (id, prestataire_id, cle_objet, position) VALUES
    ('01900000-0000-7000-8000-000000000521', '01900000-0000-7000-8000-000000000501',
     'prestataires/fiches/01900000-0000-7000-8000-000000000501/seed-1', 0),
    ('01900000-0000-7000-8000-000000000522', '01900000-0000-7000-8000-000000000502',
     'prestataires/fiches/01900000-0000-7000-8000-000000000502/seed-1', 0),
    ('01900000-0000-7000-8000-000000000523', '01900000-0000-7000-8000-000000000503',
     'prestataires/fiches/01900000-0000-7000-8000-000000000503/seed-1', 0)
ON CONFLICT (id) DO UPDATE SET
    prestataire_id = EXCLUDED.prestataire_id,
    cle_objet = EXCLUDED.cle_objet, position = EXCLUDED.position;

INSERT INTO prestataires.charte_signee
    (id, prestataire_id, cle_objet, version_charte, signee_le, deposee_le) VALUES
    ('01900000-0000-7000-8000-000000000531', '01900000-0000-7000-8000-000000000501',
     'prestataires/chartes/01900000-0000-7000-8000-000000000501/seed-1', '2026-07',
     '2026-07-15', '2026-07-15T10:00:00Z'),
    ('01900000-0000-7000-8000-000000000532', '01900000-0000-7000-8000-000000000502',
     'prestataires/chartes/01900000-0000-7000-8000-000000000502/seed-1', '2026-07',
     '2026-07-16', '2026-07-16T10:00:00Z'),
    ('01900000-0000-7000-8000-000000000533', '01900000-0000-7000-8000-000000000503',
     'prestataires/chartes/01900000-0000-7000-8000-000000000503/seed-1', '2026-07',
     '2026-07-17', '2026-07-17T10:00:00Z')
ON CONFLICT (id) DO UPDATE SET
    prestataire_id = EXCLUDED.prestataire_id, cle_objet = EXCLUDED.cle_objet,
    version_charte = EXCLUDED.version_charte, signee_le = EXCLUDED.signee_le,
    deposee_le = EXCLUDED.deposee_le;

-- ── Rattachement : le compte de Kofi pilote « Boutique Kofi » ──────────────
INSERT INTO prestataires.rattachement_compte
    (prestataire_id, compte_id, rattache_par, rattache_le) VALUES
    ('01900000-0000-7000-8000-000000000502', '01900000-0000-7000-8000-000000000402',
     '01900000-0000-7000-8000-000000000401', '2026-07-18T08:30:00Z')
ON CONFLICT (prestataire_id, compte_id) DO UPDATE SET
    rattache_par = EXCLUDED.rattache_par, rattache_le = EXCLUDED.rattache_le;

-- ── Activation POSÉE directement (FR-054 — jamais via le recalcul) ─────────
-- restauration et boutique_superette actives à Tiassalé : les agréés du seed
-- sont commandables pendant leurs horaires (SC-012). pharmacie N'EST PAS
-- activée : son prospect n'est pas agréé — c'est l'agrément manuel du
-- quickstart §3.1 qui la fera basculer (seuil 1). Le forçage n'est jamais
-- touché (monotone à la hausse, précédent cycle 002).
INSERT INTO zones.activation_categorie (id, zone_id, categorie_id, actif_auto) VALUES
    ('01900000-0000-7000-8000-000000000301', '01900000-0000-7000-8000-000000000002',
     '01900000-0000-7000-8000-000000000101', true),
    ('01900000-0000-7000-8000-000000000302', '01900000-0000-7000-8000-000000000002',
     '01900000-0000-7000-8000-000000000102', true)
ON CONFLICT (zone_id, categorie_id) DO UPDATE SET actif_auto = true, modifie_le = now();
