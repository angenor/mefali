-- Grille de départ Tiassalé et knobs tarifaires (cycle TRF 007, data-model §2).
-- Rejouable : UUID FIXES + ON CONFLICT partout → une ré-exécution converge vers
-- le même état (FR-027, SC-006). Aucun événement outbox (un chargement n'est pas
-- une transition — patron des seeds 002/003/005/006).
--
-- Séparé des migrations (constitution I) : le SCHÉMA est figé par
-- `0007_tarification.sql`, les VALEURS vivent ici et s'éditent ensuite comme
-- n'importe quelle grille (brouillon → simulation → publication).

-- ── Knobs de zone (configuration héritée — constitution I) ─────────────────
-- Tout paramètre scalaire du moteur est ICI, jamais en dur dans le code : les
-- bornes de marge, le pas d'arrondi, le facteur de dégradé, le TTL du cache et
-- toute la grille d'effort s'éditent sans déploiement.
--
-- Niveau VILLE (Tiassalé) : ces valeurs sont des choix de MARCHÉ, pas des
-- constantes nationales — une autre ville aura les siennes.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- TRF-01 — bornes de la marge Mefali. La marge 0 du LANCEMENT ne vient
    -- jamais d'une règle (elle serait refusée) mais du drapeau
    -- `gratuite_commissions` déjà seedé (research R4).
    ('01900000-0000-7000-8000-000000000002', 'tarification.marge.min',            '25'),
    ('01900000-0000-7000-8000-000000000002', 'tarification.marge.max',            '100'),
    -- TRF-02 — arrondi du prix client au FCFA supérieur ; le reliquat abonde la
    -- PART COURSIER, jamais la marge (FR-016).
    ('01900000-0000-7000-8000-000000000002', 'tarification.arrondi_pas',          '25'),
    -- Supplément appliqué quand le drapeau `pluie` est ON (Récapitulatif).
    ('01900000-0000-7000-8000-000000000002', 'tarification.supplement_pluie',     '100'),
    -- TRF-02 — routage. `facteur_degrade` = sinuosité approchée du réseau quand
    -- OSRM est injoignable (Récapitulatif « ×1,4 ») ; `vitesse_degradee_kmh`
    -- n'estime QUE l'ETA affichée, elle ne touche aucun montant.
    ('01900000-0000-7000-8000-000000000002', 'routage.facteur_degrade',           '1.4'),
    ('01900000-0000-7000-8000-000000000002', 'routage.vitesse_degradee_kmh',      '20'),
    ('01900000-0000-7000-8000-000000000002', 'routage.cache_ttl_h',               '24'),
    -- ~11 m à 4 décimales : deux départs voisins partagent le même tronçon caché.
    ('01900000-0000-7000-8000-000000000002', 'routage.arrondi_cle_decimales',     '4'),
    -- TRF-06 — grille d'effort, 100 % reversée à la part coursier (SC-007).
    -- Paliers d'articles [min, max|null, montant] : 1–5 → 0 (absent du barème).
    ('01900000-0000-7000-8000-000000000002', 'effort.paliers_articles',
     '[[6, 10, 50], [11, 20, 100], [21, null, 150]]'),
    -- Prime d'attente : +100 UNE SEULE FOIS par course, quel que soit le nombre
    -- d'arrêts lents (clarification du 2026-07-24).
    ('01900000-0000-7000-8000-000000000002', 'effort.prime_attente',
     '{"seuil_min": 15, "montant": 100, "par": "course"}'),
    -- Supplément par arrêt supplémentaire [min_m, max_m|null, montant], classé
    -- sur le TRONÇON ROUTIER au précédent arrêt — jamais un vol d'oiseau (FR-029).
    ('01900000-0000-7000-8000-000000000002', 'effort.supplement_arret_m',
     '[[0, 100, 25], [100, 1000, 50], [1000, null, 100]]'),
    -- Plafond optionnel du total des suppléments d'arrêt : `null` = aucun.
    -- Seedé explicitement pour que la console d'administration (ADM) le découvre.
    ('01900000-0000-7000-8000-000000000002', 'effort.plafond_supplements_arret',  'null')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ⚠ `effort.plafond_eclatement_m` n'est VOLONTAIREMENT pas seedé (data-model §2
-- « dormant ») : le seuil de détour au-delà duquel proposer une scission reste à
-- calibrer pendant la promo (Annexe B). Absent ⇒ `proposer_scission` est
-- toujours faux — le moteur ne propose jamais au hasard.

-- ── Grille EN VIGUEUR de Tiassalé (version 1) ─────────────────────────────
-- Montants au FCFA près (FR-026) : à pied 100 (≤ 800 m), vélo 150 (≤ 2 km),
-- moto 200 + 50/km au-delà de 2 km, plafond 500.
INSERT INTO tarification.grille (id, zone_id, version, etat, effet_le) VALUES
    ('01900000-0000-7000-8000-000000000701',
     '01900000-0000-7000-8000-000000000002', 1, 'en_vigueur', '2026-07-24T00:00:00Z')
ON CONFLICT (id) DO UPDATE SET
    zone_id = EXCLUDED.zone_id, version = EXCLUDED.version,
    etat = EXCLUDED.etat, effet_le = EXCLUDED.effet_le;

-- `marge = 50` PARTOUT : la valeur régulière, dans les bornes 25–100. Le prix
-- client de base est DÉRIVÉ (part_coursier_base + marge), jamais stocké.
INSERT INTO tarification.regle
    (id, grille_id, transport_slug, distance_min_m, distance_max_m,
     part_coursier_base, marge, prix_par_km, seuil_km_m, prix_plafond, devise, priorite, actif)
VALUES
    -- À pied : 50 + 50 = 100, jusqu'à 800 m inclus.
    ('01900000-0000-7000-8000-000000000711',
     '01900000-0000-7000-8000-000000000701', 'a_pied', 0,  800,  50, 50,  0,     0, NULL, 'XOF', 0, true),
    -- Vélo : 100 + 50 = 150, jusqu'à 2 km inclus.
    ('01900000-0000-7000-8000-000000000712',
     '01900000-0000-7000-8000-000000000701', 'velo',   0, 2000, 100, 50,  0,     0, NULL, 'XOF', 0, true),
    -- Moto : 150 + 50 = 200, puis 50/km au-delà de 2 km, prix client plafonné
    -- à 500 (au-delà, le coursier reste payé 450 — la marge, elle, ne bouge pas).
    ('01900000-0000-7000-8000-000000000713',
     '01900000-0000-7000-8000-000000000701', 'moto',   0, NULL, 150, 50, 50, 2000,  500, 'XOF', 0, true)
ON CONFLICT (id) DO UPDATE SET
    grille_id = EXCLUDED.grille_id, transport_slug = EXCLUDED.transport_slug,
    distance_min_m = EXCLUDED.distance_min_m, distance_max_m = EXCLUDED.distance_max_m,
    part_coursier_base = EXCLUDED.part_coursier_base, marge = EXCLUDED.marge,
    prix_par_km = EXCLUDED.prix_par_km, seuil_km_m = EXCLUDED.seuil_km_m,
    prix_plafond = EXCLUDED.prix_plafond, devise = EXCLUDED.devise,
    priorite = EXCLUDED.priorite, actif = EXCLUDED.actif;
