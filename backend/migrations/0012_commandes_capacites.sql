-- Cycle DSP 009 — extensions du schéma `commandes` (specs/009 data-model.md §1,
-- research R9).
--
-- Fichier séparé de `0011_dispatch_tables.sql` et nommé d'après le schéma qu'il
-- touche : le nom d'une migration doit dire QUEL schéma elle modifie, sinon
-- l'histoire du schéma `commandes` devient introuvable sous son nom.
--
-- Ces objets sont ÉCRITS par le crate `commandes` (constitution II :
-- l'appartenance des schémas ne bouge pas) et LUS par `dispatch` à travers le
-- port `CommandesADispatcher`.
--
-- 0001..0009 sont INTOUCHÉES (constitution I).

-- ── 1. Capacités requises d'une course ─────────────────────────────────────
--
-- Sur la LIVRAISON, jamais sur le tronc (constitution II — « le tronc ne
-- contient AUCUN champ logistique » ; quel véhicule il faut EST logistique).
-- Table (famille, valeur) et non colonne : FR-018 exige que l'ajout d'une
-- famille (qualification d'artisan, phase N) ne coûte ni migration ni réécriture
-- du filtre.
CREATE TABLE commandes.capacite_requise (
    livraison_id uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    famille      text NOT NULL,   -- MVP : 'transport'
    valeur       text NOT NULL,   -- MVP : slug de zones.type_transport
    PRIMARY KEY (livraison_id, famille, valeur)
);

-- ── 2. Base de la composante d'INACTIVITÉ (FR-036) ─────────────────────────
--
-- Dernière course LIVRÉE d'un coursier. L'index partiel
-- `livraison_coursier_active` du cycle 008 ne sert pas ici — il filtre les états
-- de TRAVAIL ('assignee', 'en_collecte', 'en_livraison'), pas 'livree'.
CREATE INDEX livraison_coursier_livree ON commandes.livraison (coursier_id, livree_le DESC)
    WHERE etat = 'livree';

-- ── 3. Rétro-remplissage ───────────────────────────────────────────────────
--
-- La capacité requise des livraisons existantes est copiée depuis la charge
-- utile déjà écrite de `commande.prete_a_dispatcher`
-- (`payload->>'transport_requis'`, cycle 008) : les commandes créées avant ce
-- cycle restent dispatchables, et rien n'est perdu ni deviné.
INSERT INTO commandes.capacite_requise (livraison_id, famille, valeur)
SELECT l.id, 'transport', e.payload ->> 'transport_requis'
  FROM commandes.livraison l
  JOIN outbox.evenement e
    ON e.entite_id = l.commande_id
   AND e.type_evenement = 'commande.prete_a_dispatcher'
 WHERE e.payload ->> 'transport_requis' IS NOT NULL
ON CONFLICT DO NOTHING;
