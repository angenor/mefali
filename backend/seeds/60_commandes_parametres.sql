-- Paramètres de zone du cycle CMD (008, data-model.md §6).
-- Rejouable et idempotent (ON CONFLICT … DO UPDATE) — patron des seeds
-- 002/003/005/006/007. Un seed n'émet AUCUN événement (ce n'est pas une
-- transition).
--
-- Constitution I : tout paramètre métier « paramétrable » vit ICI, jamais en dur
-- dans le code. `categorie.<slug>.mixable` est DÉJÀ seedé au cycle 002 et n'est
-- pas redéclaré (une seule source de vérité).
--
-- Montants : entiers en unités mineures XOF (0 décimale — constitution III).

-- ── Niveau PAYS (Côte d'Ivoire) — hérité par toutes les villes ─────────────
-- Ce qui est une règle NATIONALE : la nature périssable d'une catégorie de
-- service, la longueur minimale d'un repère écrit, le nombre d'essais du code de
-- remise, les délais et plafonds de substitution, la rétention des photos, la
-- période de rafraîchissement de la position, et la définition de
-- « client sans historique ».
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- FR-059, research R15 — le PÉRISSABLE est un attribut de CATÉGORIE, jamais
    -- d'article : un vendeur ne peut pas le falsifier pour éviter un retour.
    -- Seule la restauration l'est au MVP ; l'arbre §7.5 s'en sert pour trancher
    -- entre « retour au vendeur » et « litige + indemnisation + sanction ».
    ('01900000-0000-7000-8000-000000000001', 'categorie.restauration.perissable',       'true'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.boutique_superette.perissable', 'false'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.marche.perissable',             'false'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.pharmacie.perissable',          'false'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.gaz.perissable',                'false'),
    ('01900000-0000-7000-8000-000000000001', 'categorie.quincaillerie.perissable',      'false'),
    -- FR-018 — longueur minimale d'un repère ÉCRIT. En deçà, seule une note
    -- vocale rend l'adresse acceptable : « près du marché » ne trouve personne.
    ('01900000-0000-7000-8000-000000000001', 'commande.repere_texte_min_caracteres',    '10'),
    -- CRS-04 — essais du code de remise avant blocage + alerte admin.
    ('01900000-0000-7000-8000-000000000001', 'commande.essais_code_livraison',          '3'),
    -- FR-024 — en deçà de ce nombre de commandes TERMINÉES, un client est
    -- « sans historique » et le plafond cash réduit de la restauration
    -- s'applique. Les commandes annulées ou échouées ne comptent pas.
    ('01900000-0000-7000-8000-000000000001', 'commande.historique_min_commandes_terminees', '1'),
    -- FR-045 — fenêtre de décision d'un remplacement proposé. L'échéance est
    -- PERSISTÉE (research R10) : jamais un minuteur en mémoire.
    ('01900000-0000-7000-8000-000000000001', 'substitution.delai_validation_s',         '60'),
    -- FR-047 — écart de prix maximal toléré sur un remplacement (pourcentage
    -- entier). Au-delà, la proposition est refusée à l'écriture.
    ('01900000-0000-7000-8000-000000000001', 'substitution.ecart_prix_max_pourcent',    '20'),
    -- Constitution VIII — rétention des photos de remplacement, même patron que
    -- les photos de collecte (cycle 006) et les repères vocaux (cycle 003).
    ('01900000-0000-7000-8000-000000000001', 'substitution.photo_retention_jours',      '365'),
    -- FR-040 — période de rafraîchissement de la position du coursier. L'app
    -- affiche TOUJOURS l'âge de la position : elle n'en invente jamais une.
    ('01900000-0000-7000-8000-000000000001', 'suivi.position_periode_s',                '30')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── Niveau VILLE (Tiassalé) — choix de MARCHÉ, pas des constantes nationales ─
-- Les plafonds d'encaissement en espèces et le seuil d'escalade de la file
-- d'attente dépendent du pouvoir d'achat local et de la densité de coursiers :
-- une autre ville aura les siens.
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- FR-024 — au-delà, le cash est refusé et le prépaiement s'impose : c'est
    -- l'exposition maximale acceptée sur l'avance d'un coursier.
    ('01900000-0000-7000-8000-000000000002', 'commande.plafond_cash_unites',            '15000'),
    -- FR-024 — plafond RÉDUIT de la restauration pour un client sans historique :
    -- le plat préparé est périssable, un faux refus est une perte sèche.
    ('01900000-0000-7000-8000-000000000002',
     'commande.plafond_cash_restauration_sans_historique_unites',                       '5000'),
    -- FR-038 — au-delà de cette attente sans coursier, la commande est escaladée
    -- (le client est prévenu, l'exploitation alertée).
    ('01900000-0000-7000-8000-000000000002', 'commande.escalade_attente_coursier_s',    '300')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();
