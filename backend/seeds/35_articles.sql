-- Seed des catalogues (cycle 005, specs/005 data-model §9, research R15).
-- Rejouable : UUID FIXES + ON CONFLICT partout, AUCUN événement (FR-054).
-- Montants : ENTIERS en unités mineures, devise XOF de la zone (constitution
-- III). La promotion de Kofi (800 barré 1 000) et son article en rupture
-- exercent la maquette V2 et la consultation (grisé — FR-042).

-- ── Catalogue de Tantie Affoué (prestataire …501, site …511) ───────────────
INSERT INTO prestataires.article
    (id, vendeur_id, nom, prix_unites, devise, prix_barre_unites, categorie_interne) VALUES
    ('01900000-0000-7000-8000-000000000541', '01900000-0000-7000-8000-000000000501',
     'Attiéké poisson', 1500, 'XOF', NULL, 'Plats'),
    ('01900000-0000-7000-8000-000000000542', '01900000-0000-7000-8000-000000000501',
     'Garba', 1000, 'XOF', NULL, 'Plats'),
    ('01900000-0000-7000-8000-000000000543', '01900000-0000-7000-8000-000000000501',
     'Jus de bissap 50 cl', 500, 'XOF', NULL, 'Boissons')
ON CONFLICT (id) DO UPDATE SET
    vendeur_id = EXCLUDED.vendeur_id, nom = EXCLUDED.nom,
    prix_unites = EXCLUDED.prix_unites, devise = EXCLUDED.devise,
    prix_barre_unites = EXCLUDED.prix_barre_unites,
    categorie_interne = EXCLUDED.categorie_interne, modifie_le = now();

-- ── Catalogue de Kofi (prestataire …502, site …512) ────────────────────────
INSERT INTO prestataires.article
    (id, vendeur_id, nom, prix_unites, devise, prix_barre_unites, categorie_interne) VALUES
    ('01900000-0000-7000-8000-000000000551', '01900000-0000-7000-8000-000000000502',
     'Alloco', 800, 'XOF', 1000, 'Plats'),          -- PROMO : 800, barré 1 000
    ('01900000-0000-7000-8000-000000000552', '01900000-0000-7000-8000-000000000502',
     'Riz parfumé 5 kg', 4500, 'XOF', NULL, 'Épicerie'),
    ('01900000-0000-7000-8000-000000000553', '01900000-0000-7000-8000-000000000502',
     'Savon de Marseille', 600, 'XOF', NULL, 'Hygiène')  -- EN RUPTURE (source vendeur)
ON CONFLICT (id) DO UPDATE SET
    vendeur_id = EXCLUDED.vendeur_id, nom = EXCLUDED.nom,
    prix_unites = EXCLUDED.prix_unites, devise = EXCLUDED.devise,
    prix_barre_unites = EXCLUDED.prix_barre_unites,
    categorie_interne = EXCLUDED.categorie_interne, modifie_le = now();

-- ── Disponibilités PAR SITE (FR-018) ───────────────────────────────────────
-- Tout disponible, sauf le savon : rupture posée par le vendeur (horodatage
-- FIGÉ — un now() ferait diverger le double seed).
INSERT INTO prestataires.disponibilite_article (article_id, site_id, disponible, source, bascule_par, bascule_le) VALUES
    ('01900000-0000-7000-8000-000000000541', '01900000-0000-7000-8000-000000000511', true,  NULL, NULL, NULL),
    ('01900000-0000-7000-8000-000000000542', '01900000-0000-7000-8000-000000000511', true,  NULL, NULL, NULL),
    ('01900000-0000-7000-8000-000000000543', '01900000-0000-7000-8000-000000000511', true,  NULL, NULL, NULL),
    ('01900000-0000-7000-8000-000000000551', '01900000-0000-7000-8000-000000000512', true,  NULL, NULL, NULL),
    ('01900000-0000-7000-8000-000000000552', '01900000-0000-7000-8000-000000000512', true,  NULL, NULL, NULL),
    ('01900000-0000-7000-8000-000000000553', '01900000-0000-7000-8000-000000000512', false, 'vendeur',
     '01900000-0000-7000-8000-000000000402', '2026-07-18T09:00:00Z')
ON CONFLICT (article_id, site_id) DO UPDATE SET
    disponible = EXCLUDED.disponible, source = EXCLUDED.source,
    bascule_par = EXCLUDED.bascule_par, bascule_le = EXCLUDED.bascule_le;
