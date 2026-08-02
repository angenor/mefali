-- Paramètres de zone du cycle PAY (011, research.md R18).
-- Rejouable et idempotent (ON CONFLICT … DO UPDATE) — patron des seeds
-- 002/003/005/006/007/008/009/010. Un seed n'émet AUCUN événement : ce n'est pas
-- une transition (taxonomie, « ce qui n'émet PAS »).
--
-- QUATRE paramètres, tous au niveau PAYS. Aucun n'est un curseur de marché :
-- une durée de session, une fenêtre de réconciliation, un seuil d'alerte
-- d'exposition et un coupe-circuit d'exploitation valent autant à Tiassalé
-- qu'ailleurs. L'arbre d'héritage laisse une ville les redéfinir si le terrain
-- l'exige — c'est exactement ce à quoi il sert.
--
-- Aucun de ces quatre n'est en dur dans le code (constitution I, FR-100). Une
-- constante Rust pour les 15 minutes aurait été plus courte à écrire et fausse
-- au premier lancement : la durée de session est précisément le genre de valeur
-- qu'un démarrage fait bouger, et la faire bouger ne doit pas demander un
-- déploiement.

INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    -- FR-030 — durée de vie d'une session de prépaiement, en secondes.
    -- 15 minutes : assez pour ouvrir son application de mobile money, saisir un
    -- code et revenir ; assez court pour qu'un panier abandonné ne bloque ni le
    -- dispatch ni la préparation du vendeur.
    ('01900000-0000-7000-8000-000000000001', 'paiement.session_duree_s',                   '900'),

    -- R7, FR-027 — avant d'annuler une session échue, le balayage interroge le
    -- fournisseur. Cette clé borne l'âge à partir duquel il vaut la peine de le
    -- faire. Sans cette réconciliation, chaque notification perdue en transit
    -- deviendrait un litige client : de l'argent débité, une commande annulée.
    ('01900000-0000-7000-8000-000000000001', 'paiement.reconciliation_avant_expiration_s',  '60'),

    -- FR-065 — seuil d'alerte d'exploitation sur l'exposition en créances d'un
    -- coursier, en unités mineures (50 000 F CFA). Au-delà, Mefali doit à Yao
    -- plus qu'il n'est raisonnable de lui faire porter : c'est un signal de
    -- règlement, pas un blocage.
    ('01900000-0000-7000-8000-000000000001', 'paiement.creance_alerte_unites',           '50000'),

    -- ── Le paramètre qui mérite un mot ────────────────────────────────────
    --
    -- VIDE PAR DÉFAUT, et vide signifie « tous les moyens sont actifs ».
    -- FR-011 INTERDIT de masquer un moyen de paiement au client : ce n'est donc
    -- pas un filtre produit, et il ne doit jamais en devenir un.
    --
    -- Il n'existe que comme COUPE-CIRCUIT D'EXPLOITATION : quand un moyen tombe
    -- chez l'agrégateur, on veut cesser de le proposer en minutes, sans
    -- déploiement, plutôt que de laisser des clients échouer un par un. Sa
    -- présence non vide est journalisée précisément pour qu'elle reste
    -- exceptionnelle et visible.
    ('01900000-0000-7000-8000-000000000001', 'paiement.moyens_actifs',                      '[]')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();
