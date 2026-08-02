-- Cycle PAY 011 — énumérations du paiement (specs/011 data-model.md §1).
--
-- ── POURQUOI CE FICHIER EST SÉPARÉ DE 0021 ────────────────────────────────
--
-- PostgreSQL REFUSE d'employer une valeur d'énumération dans la transaction qui
-- vient de l'ajouter (`ALTER TYPE … ADD VALUE`). Les trois valeurs ajoutées à
-- `coursier.type_ecriture` plus bas seraient donc inutilisables par un DEFAULT,
-- un CHECK ou un INSERT de 0021 si tout tenait dans un seul fichier. Le
-- découpage 0008/0009 et 0010/0011 existe pour cette raison exacte, et le cycle
-- 010 l'a documenté en tête de `0015_coursier.sql` (research R21).
--
-- Les types CRÉÉS ici (`CREATE TYPE … AS ENUM`) n'ont pas cette contrainte —
-- mais les regrouper avec les `ALTER TYPE` garde la règle lisible : « 0020
-- déclare les vocabulaires, 0021 s'en sert ».
--
-- Les migrations 0001..0019 sont INTOUCHÉES (constitution I).

CREATE SCHEMA IF NOT EXISTS paiements;

-- ── 1. Énumérations du schéma `paiements` ─────────────────────────────────

-- Cycle de vie d'une transaction de prépaiement.
--
-- ⚠ AUCUN état « partiellement payée », et ce n'est pas un oubli : la
-- constitution III interdit tout chemin de paiement partiel, et la spec en fait
-- un invariant (FR-002). Une transaction couvre la TOTALITÉ du montant dû ou
-- n'existe pas. Ajouter un jour une valeur ici serait ouvrir ce chemin par la
-- porte du schéma.
CREATE TYPE paiements.etat_transaction AS ENUM (
    'ouverte',            -- session vivante, le client peut payer
    'reglee',             -- notification signée de succès, commande confirmée — TERMINAL (FR-034)
    'echouee',            -- refus opérateur ; réessai permis tant que la session vit (FR-026)
    'expiree',            -- échéance franchie sans succès → commande annulée
    'payee_hors_delai'    -- succès arrivé APRÈS l'expiration (R8) — dossier ouvert, commande INTOUCHÉE
);

-- Moyen effectivement utilisé, tel que le fournisseur le communique (FR-012).
--
-- `inconnu` est l'état AVANT que le fournisseur ne le dise — jamais deviné,
-- jamais déduit du montant ni de la zone. `autre` recueille un moyen qu'un futur
-- agrégateur nommerait sans que le domaine ait à migrer son enum (research R3) :
-- les cinq moyens nommés restent typés pour l'analyse, l'inconnu ne casse rien.
CREATE TYPE paiements.moyen_paiement AS ENUM (
    'inconnu', 'wave', 'orange_money', 'mtn_momo', 'moov_money', 'carte', 'autre'
);

-- Anomalie d'argent qui doit être VUE par un humain (FR-082). Un dossier n'est
-- pas un log : un log se perd dans le volume, un dossier a un état et se clôt.
CREATE TYPE paiements.type_dossier AS ENUM (
    'montant_divergent',       -- FR-024 — la notification annonce un autre montant que le figé
    'devise_divergente',       -- FR-024
    'paiement_hors_delai',     -- FR-037 — succès arrivé après l'annulation (R8)
    'transaction_orpheline',   -- FR-082 — référence sans commande rattachable
    'retenue_ecretee',         -- FR-052 — la retenue dépassait les articles
    'remboursement_client_du'  -- FR-082 — PAY-04 non construit : le dû est VU, pas versé
);

CREATE TYPE paiements.etat_dossier AS ENUM ('ouvert', 'clos');

-- ── 2. Énumération du schéma `prestataires` (VND-08, part minimale) ───────
--
-- Vit dans `prestataires` et non dans `paiements` : offrir la livraison est une
-- décision COMMERCIALE d'un vendeur, pas un objet de paiement (research R10).
CREATE TYPE prestataires.offre_livraison AS ENUM (
    'jamais',    -- défaut — aucun vendeur existant ne change de comportement (FR-046)
    'toujours',
    'au_dela'    -- au-delà d'un seuil de panier, obligatoire et > 0 (CHECK en 0021)
);

-- ── 3. Énumérations du schéma `coursier` (créances) ───────────────────────
--
-- Une créance n'est PAS de l'argent en poche : elle a sa table, pas une écriture
-- au livre de trésorerie (research R12). Le livre suit ce que Yao a réellement,
-- et le cycle 010 a défendu cet invariant explicitement.
CREATE TYPE coursier.nature_creance AS ENUM (
    'avance_prepayee',  -- le client a prépayé : Mefali doit au coursier l'avance qu'il a sortie
    'part_course'       -- le coursier n'a encaissé aucun frais (prépayé, ou frais nuls par promo)
);

CREATE TYPE coursier.etat_creance AS ENUM ('due', 'reglee');

-- ── 4. Valeurs ajoutées à une énumération EXISTANTE ───────────────────────
--
-- C'est CE bloc qui impose le découpage en deux migrations. Les trois valeurs
-- sont des natures de MOUVEMENT RÉEL de trésorerie (research R13) — aucune ne
-- représente une créance, sans quoi le solde de caisse cesserait de dire ce que
-- Yao a dans la poche, et l'écran dont c'est la seule raison d'être mentirait.
--
--   frais_encaisses  (+)  total_du_client − Σ avances   à la remise CASH validée
--                         ⚠ PAS `devis_prix_client` : faux dès que la retenue
--                         VND-08 joue, où le prix client vaut 0 alors que le
--                         coursier a bien encaissé sa part (data-model §5).
--   reglement        (+)  montant de la créance         quand l'exploitation verse
--   reversement      (−)  montant reversé               quand le coursier rend la
--                         marge détenue pour Mefali (0 au MVP, marge nulle)
ALTER TYPE coursier.type_ecriture ADD VALUE IF NOT EXISTS 'frais_encaisses';
ALTER TYPE coursier.type_ecriture ADD VALUE IF NOT EXISTS 'reglement';
ALTER TYPE coursier.type_ecriture ADD VALUE IF NOT EXISTS 'reversement';
