-- Cycle CMD 008 — TYPES SEULS (specs/008 data-model.md §1, research R2).
--
-- ⚠ Ce fichier ne contient QUE des types : aucune table, aucune colonne, aucun
-- index, aucune contrainte. PostgreSQL interdit d'UTILISER une valeur d'énum
-- dans la transaction qui l'ajoute (« unsafe use of new value of enum type »),
-- et sqlx exécute chaque fichier de migration dans UNE transaction. Les
-- structures qui référencent ces valeurs — DEFAULT, CHECK, index partiels —
-- vivent donc dans `0009_commandes_tronc.sql`, exécuté dans une transaction
-- suivante. Un fichier unique échouerait au DÉPLOIEMENT, pas au développement.
--
-- 0001..0007 sont INTOUCHÉES (constitution I).

-- ── Extensions des énums du socle 006 ──────────────────────────────────────

-- Boucle de collecte par arrêt (cadrage §7.2) : le socle ne posait que
-- 'a_collecter' → 'collecte'. CMD intercale les deux états de la boucle, dans
-- l'ordre du parcours réel (BEFORE 'collecte' garde l'énum lisible en tri).
ALTER TYPE commandes.statut_arret ADD VALUE IF NOT EXISTS 'en_route' BEFORE 'collecte';
ALTER TYPE commandes.statut_arret ADD VALUE IF NOT EXISTS 'arrive'   BEFORE 'collecte';

-- États logistiques complets de la livraison. Le socle 006 n'avait que les deux
-- états de la fenêtre QRC ('en_collecte', 'en_livraison') ; CMD ajoute
-- l'affectation en amont et les trois sorties en aval.
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'assignee' BEFORE 'en_collecte';
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'livree';
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'echouee';
ALTER TYPE commandes.etat_livraison ADD VALUE IF NOT EXISTS 'annulee';

-- ── Types neufs (créables ici, utilisables dès 0009) ───────────────────────

-- États de TRÈS HAUT NIVEAU du tronc (constitution II — aucun état logistique
-- ici : la collecte et la remise vivent sur la livraison et ses arrêts).
CREATE TYPE commandes.etat_commande AS ENUM (
    'nouvelle', 'en_attente_paiement', 'en_attente_coursier',
    'en_cours', 'terminee', 'annulee', 'echouee'
);

-- Nature de l'arrêt (cadrage §7.2 : 1..n collectes + 1 remise).
CREATE TYPE commandes.type_arret AS ENUM ('collecte', 'remise');

-- Préférence de substitution par article (CMD-01, défaut « m'appeler »).
CREATE TYPE commandes.preference_substitution AS ENUM ('remplacer', 'appeler', 'retirer');

-- Cycle de vie d'une ligne de commande.
CREATE TYPE commandes.statut_ligne AS ENUM ('presente', 'remplacee', 'retiree');

-- Issue d'une proposition de remplacement (CMD-06 + maquette C4-4c).
CREATE TYPE commandes.issue_substitution AS ENUM (
    'en_attente', 'acceptee', 'refusee', 'expiree_appel', 'retiree'
);

-- Paiement (constitution III — jamais de chemin partiel : un seul montant,
-- un seul état).
CREATE TYPE commandes.mode_paiement AS ENUM ('cash', 'mobile_money');
CREATE TYPE commandes.etat_paiement  AS ENUM ('du', 'en_attente', 'regle', 'rembourse');

-- Les 10 lignes du tableau des cas limites (cadrage §7.5) + la sous-branche
-- « refus de reprise vendeur » que CMD-08 nomme explicitement.
CREATE TYPE commandes.type_issue_echec AS ENUM (
    'refus_non_perissable', 'refus_reprise_vendeur', 'refus_perissable',
    'contestation_montant', 'sans_appoint', 'faux_billet',
    'non_conformite', 'casse_transport', 'annulation_apres_achat',
    'vendeur_ferme_consigne', 'suspicion_faux_refus'
);

-- Qui détient l'argent / la marchandise à l'issue (CMD-08). DEUX AXES
-- INDÉPENDANTS (research R14) : le coursier peut détenir la marchandise
-- pendant que Mefali détient la dette.
CREATE TYPE commandes.detenteur AS ENUM ('client', 'coursier', 'vendeur', 'mefali', 'consigne');

-- Sanction posée sur le compte client (CPT-06 — les colonnes existent déjà
-- dans le schéma `comptes`, l'écriture reste dans SON crate, research R12).
CREATE TYPE commandes.sanction AS ENUM ('aucune', 'prepaiement_impose', 'bloque');
