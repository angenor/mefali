-- Seed Tiassalé (FR-022..026, data-model §6). Rejouable : UUID FIXES +
-- ON CONFLICT partout → une ré-exécution converge vers le même état (SC-008).
-- Aucun événement outbox (chargement initial, pas une transition — research R9).
--
-- L'héritage est STRUCTUREL : la devise et le drapeau « mixable » (nature de
-- catégorie) sont posés au niveau PAYS ; drapeaux de lancement, seuils
-- d'activation et transports actifs (spécifiques à la ville) au niveau VILLE.
-- SC-003 vérifie la résolution complète à Tiassalé en une consultation.

-- ── Zones : Côte d'Ivoire (pays) > Tiassalé (ville) ────────────────────────
INSERT INTO zones.zone (id, parent_id, type, nom) VALUES
    ('01900000-0000-7000-8000-000000000001', NULL, 'pays', 'Côte d''Ivoire')
ON CONFLICT (id) DO UPDATE SET
    parent_id = EXCLUDED.parent_id, type = EXCLUDED.type, nom = EXCLUDED.nom, modifie_le = now();

INSERT INTO zones.zone (id, parent_id, type, nom) VALUES
    ('01900000-0000-7000-8000-000000000002',
     '01900000-0000-7000-8000-000000000001', 'ville', 'Tiassalé')
ON CONFLICT (id) DO UPDATE SET
    parent_id = EXCLUDED.parent_id, type = EXCLUDED.type, nom = EXCLUDED.nom, modifie_le = now();

-- ── Référentiel des types de transport (8, ordre à pied → camion) ──────────
INSERT INTO zones.type_transport (id, slug, nom_cle, ordre) VALUES
    ('01900000-0000-7000-8000-000000000201', 'a_pied',         'transport.a_pied.nom',         1),
    ('01900000-0000-7000-8000-000000000202', 'velo',           'transport.velo.nom',           2),
    ('01900000-0000-7000-8000-000000000203', 'moto',           'transport.moto.nom',           3),
    ('01900000-0000-7000-8000-000000000204', 'tricycle_taxi',  'transport.tricycle_taxi.nom',  4),
    ('01900000-0000-7000-8000-000000000205', 'tricycle_cargo', 'transport.tricycle_cargo.nom', 5),
    ('01900000-0000-7000-8000-000000000206', 'voiture',        'transport.voiture.nom',        6),
    ('01900000-0000-7000-8000-000000000207', 'camionnette',    'transport.camionnette.nom',    7),
    ('01900000-0000-7000-8000-000000000208', 'camion',         'transport.camion.nom',         8)
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug, nom_cle = EXCLUDED.nom_cle, ordre = EXCLUDED.ordre;

-- ── Catégories (6 ; workflow/photo/véhicule minimal — data-model §6) ───────
-- politique_photo = facultative (défaut sûr, éditable en ADM — cadrage §4).
-- gaz → véhicule minimal moto ; quincaillerie/autres → NULL (véhicule calculé
-- par la commande). seuil_activation et mixable NE SONT PAS ici (paramètres
-- hérités — R1).
INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur, vehicule_minimal) VALUES
    ('01900000-0000-7000-8000-000000000101', 'restauration',       'categorie.restauration.nom',       'restauration',      NULL),
    ('01900000-0000-7000-8000-000000000102', 'boutique_superette', 'categorie.boutique_superette.nom', 'coursier_acheteur', NULL),
    ('01900000-0000-7000-8000-000000000103', 'marche',             'categorie.marche.nom',             'marche_etals',      NULL),
    ('01900000-0000-7000-8000-000000000104', 'pharmacie',          'categorie.pharmacie.nom',          'coursier_acheteur', NULL),
    ('01900000-0000-7000-8000-000000000105', 'gaz',                'categorie.gaz.nom',                'echange_contenant', '01900000-0000-7000-8000-000000000203'),
    ('01900000-0000-7000-8000-000000000106', 'quincaillerie',      'categorie.quincaillerie.nom',      'coursier_acheteur', NULL)
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug, nom_cle = EXCLUDED.nom_cle,
    workflow_vendeur = EXCLUDED.workflow_vendeur, vehicule_minimal = EXCLUDED.vehicule_minimal,
    modifie_le = now();

-- ── Paramètres au niveau PAYS (hérités par la ville) ───────────────────────
-- Devise XOF 0 décimale (montants entiers en unités mineures — principe III).
-- Mixable au panier : restauration non ; les 5 « courses » oui (CMD-01).
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    ('01900000-0000-7000-8000-000000000001', 'devise.code',      '"XOF"'),
    ('01900000-0000-7000-8000-000000000001', 'devise.decimales', '0'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.restauration.mixable',       'false'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.boutique_superette.mixable', 'true'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.marche.mixable',             'true'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.pharmacie.mixable',          'true'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.gaz.mixable',                'true'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.quincaillerie.mixable',      'true')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── Paramètres au niveau VILLE (Tiassalé) ──────────────────────────────────
-- Drapeaux de lancement, transports actifs, seuils d'activation « par ville ».
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    ('01900000-0000-7000-8000-000000000002', 'drapeau.livraison_offerte_mefali', 'true'),
    ('01900000-0000-7000-8000-000000000002', 'drapeau.gratuite_commissions',     'true'),
    ('01900000-0000-7000-8000-000000000002', 'drapeau.pluie',                    'false'),
    ('01900000-0000-7000-8000-000000000002', 'transport.actifs',                 '["a_pied", "velo", "moto"]'),
    ('01900000-0000-7000-8000-000000000002', 'categorie.restauration.seuil_activation',       '8'),
    ('01900000-0000-7000-8000-000000000002', 'categorie.boutique_superette.seuil_activation', '3'),
    ('01900000-0000-7000-8000-000000000002', 'categorie.marche.seuil_activation',             '3'),
    ('01900000-0000-7000-8000-000000000002', 'categorie.pharmacie.seuil_activation',          '1'),
    ('01900000-0000-7000-8000-000000000002', 'categorie.gaz.seuil_activation',                '2'),
    ('01900000-0000-7000-8000-000000000002', 'categorie.quincaillerie.seuil_activation',      '2')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── État d'activation par ville (6 lignes Tiassalé) ────────────────────────
-- forcage=automatique, actif_auto=false : l'état découle de la règle du seuil
-- appliquée aux vendeurs agréés (aucun au cycle ZON → tout inactif). DO NOTHING
-- pour NE PAS écraser l'état runtime posé par les cycles suivants (VND).
INSERT INTO zones.activation_categorie (id, zone_id, categorie_id) VALUES
    ('01900000-0000-7000-8000-000000000301', '01900000-0000-7000-8000-000000000002', '01900000-0000-7000-8000-000000000101'),
    ('01900000-0000-7000-8000-000000000302', '01900000-0000-7000-8000-000000000002', '01900000-0000-7000-8000-000000000102'),
    ('01900000-0000-7000-8000-000000000303', '01900000-0000-7000-8000-000000000002', '01900000-0000-7000-8000-000000000103'),
    ('01900000-0000-7000-8000-000000000304', '01900000-0000-7000-8000-000000000002', '01900000-0000-7000-8000-000000000104'),
    ('01900000-0000-7000-8000-000000000305', '01900000-0000-7000-8000-000000000002', '01900000-0000-7000-8000-000000000105'),
    ('01900000-0000-7000-8000-000000000306', '01900000-0000-7000-8000-000000000002', '01900000-0000-7000-8000-000000000106')
ON CONFLICT (zone_id, categorie_id) DO NOTHING;
