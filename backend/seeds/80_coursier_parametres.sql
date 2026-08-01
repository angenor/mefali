-- Paramètres de zone du cycle CRS (010, research.md R17).
-- Rejouable et idempotent (ON CONFLICT … DO UPDATE) — patron des seeds
-- 002/003/005/006/007/008/009. Un seed n'émet AUCUN événement (ce n'est pas une
-- transition).
--
-- SEPT paramètres, pas huit. Le nombre d'essais du code de remise EXISTE déjà :
-- `commande.essais_code_livraison` = 3, seedé par le cycle 008 au niveau pays
-- (`60_commandes_parametres.sql`) et LU EN PRODUCTION par `valider_remise`. Ce
-- cycle le réutilise tel quel. En créer un second (`coursier.essais_…`) aurait
-- donné deux clés pour un même seuil : elles auraient divergé au premier réglage
-- d'exploitation, et la moitié du code aurait bloqué à 3 pendant que l'autre
-- bloquait à 5 (constitution I, FR-106).
--
-- ── Pourquoi TROIS rétentions de photo, et pourquoi ce n'est pas un doublon ──
--
--   `qr.retention_photo_collecte_jours`   (cycle 006) — photo de RÉCUPÉRATION
--       chez le vendeur : elle prouve ce que le coursier a pris.
--   `substitution.photo_retention_jours`  (cycle 008) — photo du REMPLACEMENT
--       proposé au client : elle sert une décision, et n'a plus d'objet une fois
--       la décision prise.
--   `coursier.retention_photo_preuve_jours` (ce cycle) — photo de PREUVE d'un
--       client absent : elle fonde une indemnisation et peut être opposée dans
--       un litige.
--
-- Trois natures de preuve, trois durées légitimement différentes, trois points
-- d'édition séparés. Les fusionner obligerait l'exploitation à garder la plus
-- longue des trois pour toutes — ou à perdre celle qui compte. Le patron « une
-- clé par usage » est celui des deux cycles précédents.
--
-- Durées : secondes. Distances : mètres. Aucun montant ici (le cycle n'en
-- paramètre aucun : les montants viennent du devis figé du cycle 007).

-- ── Niveau PAYS (Côte d'Ivoire) — règles qui ne dépendent pas du marché ────
--
-- Les sept sont NATIONAUX, et c'est un choix : « ce qui prouve qu'on a
-- vraiment essayé » (CRS-05) est une règle de preuve, pas un curseur de
-- marché. Deux appels espacés de trois minutes et dix minutes de présence
-- valent autant à Tiassalé qu'ailleurs — une ville qui abaisserait la barre
-- rendrait ses échecs moins opposables, pas ses coursiers plus efficaces.
-- L'arbre d'héritage laisse une ville les redéfinir si le terrain l'exige.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- CRS-05, FR-056 — appels au motif `client_absent` exigés par la preuve.
    -- Seul ce motif compte : un appel de suivi ne prouve pas une absence.
    ('01900000-0000-7000-8000-000000000001', 'coursier.preuve_appels_min',                 '2'),
    -- CRS-05, FR-056 — espacement minimal entre deux appels retenus. Sans lui,
    -- deux appels à dix secondes d'intervalle vaudraient une preuve : on aurait
    -- mesuré la vitesse du pouce, pas la patience du coursier.
    ('01900000-0000-7000-8000-000000000001', 'coursier.preuve_appels_espacement_s',      '180'),
    -- CRS-05, FR-056 — présence continue exigée sur le lieu de livraison.
    ('01900000-0000-7000-8000-000000000001', 'coursier.preuve_presence_s',               '600'),
    -- Rayon dans lequel un relevé compte comme « sur place ». Aligné sur
    -- `qr.distance_scan_max_m` = 100 m (« Récapitulatif des paramètres de
    -- zone » — Distance max de scan QR). Le Récapitulatif n'a pas de ligne
    -- dédiée à la présence : la valeur reprend la porte de proximité DÉJÀ en
    -- service, plutôt que d'inventer un second ordre de grandeur.
    ('01900000-0000-7000-8000-000000000001', 'coursier.preuve_presence_rayon_m',         '100'),
    -- R8 — intervalle au-delà duquel deux relevés consécutifs ne comptent plus
    -- comme une présence CONTINUE. C'est ce seuil qui distingue une attente
    -- d'un aller-retour : sans lui, deux relevés espacés de dix minutes
    -- vaudraient dix minutes de présence.
    ('01900000-0000-7000-8000-000000000001', 'coursier.preuve_presence_trou_max_s',      '120'),
    -- Rétention de la photo de preuve d'échec — voir l'en-tête sur les trois
    -- rétentions. Alignée sur `qr.retention_photo_collecte_jours` = 365 j
    -- (« Récapitulatif » — Rétention des photos de récupération).
    ('01900000-0000-7000-8000-000000000001', 'coursier.retention_photo_preuve_jours',    '365'),
    -- R13 — période d'interrogation d'offre EN ARRIÈRE-PLAN, par le service
    -- continu. Le premier plan reste à 2 s (constante d'UI du cycle 009) et les
    -- deux ne tournent JAMAIS en même temps : doubler le débit pendant les 40
    -- secondes de décision est exactement ce que le cycle 009 avait écarté.
    ('01900000-0000-7000-8000-000000000001', 'coursier.offre_interrogation_arriere_plan_s', '5')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── Niveau VILLE (Tiassalé) — le contact de l'agence ──────────────────────
--
-- DÉCOUVERT en implémentant K4-1d (T043). La maquette écrit « Appelez Mefali
-- Tiassalé — 07 07 55 12 12 » en action PRINCIPALE de l'écran de blocage, et
-- FR-043 l'exige nommément : « afficher le motif en langage clair ET le numéro
-- de l'agence ». Rien dans le dépôt ne fournissait ce numéro — l'écrire en dur
-- dans l'app aurait mis un numéro de téléphone dans un binaire de production,
-- changeable seulement par un passage store (constitution I).
--
-- Namespace `texte.*` et non `coursier.*`, à dessein : ce sont des TEXTES
-- d'affichage, servis par `/config` dans la liste blanche publique déjà en
-- place (cycle 002, ZON-04). Aucune plomberie nouvelle, aucun endpoint de plus,
-- et l'exploitation les édite par ADM-05 comme tous les autres.
--
-- Au niveau VILLE parce qu'une agence est locale : Tiassalé n'a pas le même
-- numéro que la ville suivante, et l'héritage sert exactement à cela.
--
-- Ils ne sont PAS comptés dans les « sept paramètres du cycle » de R17 : ceux-là
-- sont des seuils de preuve et d'offre. Ces deux-ci sont des libellés.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    ('01900000-0000-7000-8000-000000000002', 'texte.nom_agence',        '"Tiassalé"'),
    ('01900000-0000-7000-8000-000000000002', 'texte.telephone_agence',  '"+2250707551212"')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();
