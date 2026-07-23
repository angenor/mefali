-- Paramètres de zone du cycle QRC (006, data-model.md §3).
-- Idempotent (ON CONFLICT / UPDATE inconditionnel) — patron des seeds 002/005.
-- Un seed n'émet AUCUN événement (ce n'est pas une transition).
--
-- Note d'alignement : la politique photo PAR CATÉGORIE est portée par la colonne
-- existante `zones.categorie.politique_photo` (schéma 002), pas par un paramètre
-- de zone — une seule source de vérité (constitution I). Le data-model la
-- désignait « categorie.<code>.politique_photo » ; on retient la colonne, que la
-- résolution R4 (niveau 2) lit directement.

-- ── Paramètres au niveau PAYS (Côte d'Ivoire) — hérités par Tiassalé ───────
-- distance_scan_max_m : rayon de la porte de présence anti-fraude (QRC-02, R3).
-- photo_seuil_montant : montant (unités mineures XOF) au-delà duquel la photo de
--   récupération devient obligatoire quelle que soit la politique de catégorie
--   (QRC-02, R4) — éditable en ADM.
-- retention_photo_collecte_jours : rétention des photos de récupération avant
--   purge (VIII, patron du repère vocal R8).
INSERT INTO zones.parametre_zone (zone_id, cle, valeur) VALUES
    ('01900000-0000-7000-8000-000000000001', 'qr.distance_scan_max_m',            '100'),
    ('01900000-0000-7000-8000-000000000001', 'qr.photo_seuil_montant',            '10000'),
    ('01900000-0000-7000-8000-000000000001', 'qr.retention_photo_collecte_jours', '365')
ON CONFLICT (zone_id, cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_le = now();

-- ── Politique photo PAR CATÉGORIE (colonne zones.categorie) ────────────────
-- restauration = facultative (défaut du schéma, laissé tel quel) ;
-- pharmacie = obligatoire (cadrage §4 l.83 — médicaments : preuve exigée).
UPDATE zones.categorie
    SET politique_photo = 'obligatoire', modifie_le = now()
    WHERE slug = 'pharmacie';
