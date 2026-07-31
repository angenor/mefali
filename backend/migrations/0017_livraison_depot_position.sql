-- Cycle CRS 010 — position du dépôt convenu (FR-048).
--
-- Migration DÉCOUVERTE en cours d'implémentation, conformément à la règle 2 des
-- tâches du cycle : 0015 et 0016 sont APPLIQUÉES, donc intouchables
-- (constitution I) ; le besoin s'ajoute ici.
--
-- Ce qui manquait : le cadrage §7.4-5 exige « photo **+ géolocalisation** » pour
-- le mode dépôt, et le contrat de remise multipart (R18) porte bien
-- `depot_lat` / `depot_lon` — mais 0009 n'avait posé que `depot_photo_cle`. Sans
-- ces deux colonnes, la moitié de la preuve de dépôt se perdait à la réception.
--
-- Pourquoi sur `livraison` et pas sur `commande` : le dépôt est un fait de la
-- REMISE (composant logistique), au même titre que `depot_photo_cle` et
-- `mode_remise`. Le tronc `commande` ne porte aucun champ logistique
-- (constitution II) ; il porte l'AUTORISATION (`depot_autorise`, migration 0016),
-- qui est une décision d'exploitation, pas un fait de terrain.
--
-- Aucune coordonnée du CLIENT n'est dupliquée ici : c'est la position du
-- COURSIER au moment où il dépose, c'est-à-dire la preuve elle-même.
ALTER TABLE commandes.livraison
    ADD COLUMN depot_lat double precision,
    ADD COLUMN depot_lon double precision;

COMMENT ON COLUMN commandes.livraison.depot_lat IS
    'Latitude du coursier au dépôt convenu (FR-048). Preuve de remise, servie à l''exploitation uniquement.';
COMMENT ON COLUMN commandes.livraison.depot_lon IS
    'Longitude du coursier au dépôt convenu (FR-048). Preuve de remise, servie à l''exploitation uniquement.';

-- Les deux vont ENSEMBLE ou pas du tout : une demi-position ne prouve rien.
ALTER TABLE commandes.livraison
    ADD CONSTRAINT depot_position_complete CHECK (
        (depot_lat IS NULL) = (depot_lon IS NULL));
