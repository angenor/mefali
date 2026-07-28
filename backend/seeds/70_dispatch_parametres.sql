-- Paramètres de zone du cycle DSP (009, data-model.md §4).
-- Rejouable et idempotent (ON CONFLICT … DO UPDATE) — patron des seeds
-- 002/003/005/006/007/008. Un seed n'émet AUCUN événement (ce n'est pas une
-- transition).
--
-- Constitution I : les 18 paramètres du pipeline vivent ICI, jamais en dur.
-- TROIS paramètres existants sont RÉUTILISÉS et ne sont pas redéclarés — une
-- seule source de vérité (data-model §4) :
--   `suivi.position_periode_s`             (cycle 008, pays)  → période de publication ;
--   `commande.escalade_attente_coursier_s` (cycle 008, ville) → seuil d'escalade DSP-06 ;
--   `transport.actifs`                     (cycle 002, ville) → référentiel des capacités.
--
-- Montants : entiers en unités mineures XOF (0 décimale — constitution III).
-- Scores : composantes en millièmes, poids en centièmes (research R6).

-- ── Niveau PAYS (Côte d'Ivoire) — règles qui ne dépendent pas du marché ────
-- Ce qui est une règle NATIONALE : la durée de vie d'une inscription au pool,
-- le temps de décision humain devant une offre, l'exclusivité qui doit le
-- couvrir, la politique d'équité sur les non-réponses, la fenêtre de mesure du
-- taux d'acceptation, la définition de « note neutre » et le bruit GPS.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- FR-003 — trois périodes de position manquées (3 × suivi.position_periode_s).
    -- C'est ce TTL qui fait sortir du pool un coursier muet : le silence EST
    -- l'information (DSP-01).
    ('01900000-0000-7000-8000-000000000001', 'dispatch.pool_ttl_s',                      '90'),
    -- FR-033 — temps de décision devant une offre. Humain, pas un choix de ville.
    ('01900000-0000-7000-8000-000000000001', 'dispatch.timer_offre_s',                   '40'),
    -- FR-045 — DOIT rester > dispatch.timer_offre_s, vérifié au CHARGEMENT des
    -- paramètres (SC-005) : un verrou plus court que le compte à rebours
    -- laisserait deux coursiers sur la même offre à la seconde 41.
    ('01900000-0000-7000-8000-000000000001', 'dispatch.verrou_offre_s',                  '45'),
    -- FR-052 — non-réponses FRANCHES du jour : ni pénalité, ni effet sur le taux
    -- d'acceptation. Politique d'équité nationale.
    ('01900000-0000-7000-8000-000000000001', 'dispatch.timeouts_francs_par_jour',        '3'),
    -- FR-038 — fenêtre de mesure du taux d'acceptation (jours).
    ('01900000-0000-7000-8000-000000000001', 'dispatch.acceptation_fenetre_jours',       '7'),
    -- FR-037 — valeur NEUTRE (millièmes) de la composante quand la donnée
    -- manque : note absente tant qu'AVI n'existe pas (research R7), ou aucune
    -- offre sur la fenêtre. « Neutre » est une définition, pas un curseur.
    ('01900000-0000-7000-8000-000000000001', 'dispatch.note_composante_neutre_millimes', '500'),
    -- FR-071 — rapprochement minimal (mètres) qui compte comme un mouvement.
    -- Bruit GPS = physique, non négociable par ville.
    ('01900000-0000-7000-8000-000000000001', 'dispatch.reassignation_deplacement_min_m', '150')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── Niveau VILLE (Tiassalé) — choix de MARCHÉ ─────────────────────────────
-- Le rayon, la grille d'avance, les quatre poids du classement, le plafond
-- d'inactivité et les seuils de bascule dépendent de la densité de coursiers et
-- du pouvoir d'achat local : une autre ville aura les siens.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- FR-021 — rayon d'éligibilité, mesuré en distance ROUTIÈRE autour du
    -- premier arrêt de collecte (« Récapitulatif des paramètres de zone »).
    ('01900000-0000-7000-8000-000000000002', 'dispatch.rayon_m',                         '4000'),
    -- FR-023 — grille des plafonds d'avance par note (ADM-04). UN SEUL
    -- paramètre, comme `transport.actifs` : un seul point d'édition. Paliers
    -- lus dans l'ordre, `note_max_centiemes: null` = palier haut. Note absente
    -- (AVI non construit) ⇒ palier d'ENTRÉE (research R7).
    ('01900000-0000-7000-8000-000000000002', 'dispatch.grille_avance_par_note',
     '[{"note_max_centiemes":400,"plafond_unites":5000},{"note_max_centiemes":450,"plafond_unites":10000},{"note_max_centiemes":null,"plafond_unites":15000}]'),
    -- FR-034 — les QUATRE poids du classement, en centièmes. Leur somme DOIT
    -- valoir 100, vérifiée au chargement (SC-005).
    ('01900000-0000-7000-8000-000000000002', 'dispatch.poids_proximite',                 '40'),
    ('01900000-0000-7000-8000-000000000002', 'dispatch.poids_inactivite',                '30'),
    ('01900000-0000-7000-8000-000000000002', 'dispatch.poids_note',                      '20'),
    ('01900000-0000-7000-8000-000000000002', 'dispatch.poids_acceptation',               '10'),
    -- FR-036 — au-delà de cette inactivité, la composante est à son maximum.
    -- C'est elle qui empêche qu'un coursier ne reçoive jamais rien (SC-007).
    ('01900000-0000-7000-8000-000000000002', 'dispatch.inactivite_plafond_s',            '1800'),
    -- FR-058 — bascule en broadcast sur conditions ALTERNATIVES (« Récapitulatif
    -- des paramètres de zone ») : candidats épuisés OU délai écoulé.
    ('01900000-0000-7000-8000-000000000002', 'dispatch.broadcast_apres_candidats',       '3'),
    ('01900000-0000-7000-8000-000000000002', 'dispatch.broadcast_apres_s',               '120'),
    -- FR-071 — « Réassignation sans mouvement : 5 min » (Récapitulatif).
    ('01900000-0000-7000-8000-000000000002', 'dispatch.reassignation_sans_mouvement_s',  '300'),
    -- FR-072 — « sans scan : préparation annoncée + 10 min » (Récapitulatif).
    ('01900000-0000-7000-8000-000000000002', 'dispatch.reassignation_sans_scan_marge_s', '600')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();
