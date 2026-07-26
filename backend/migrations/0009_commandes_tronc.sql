-- Cycle CMD 008 — STRUCTURES (specs/008 data-model.md §2, research R2/R3/R4).
--
-- Tout ce qui RÉFÉRENCE une valeur d'énum ajoutée par 0008 vit ici : DEFAULT,
-- CHECK et index partiels. Deux fichiers = deux transactions = contrainte
-- PostgreSQL levée, sans artifice.
--
-- 0001..0007 sont INTOUCHÉES (constitution I) ; le socle 006 est ÉTENDU, jamais
-- réécrit.

-- ── 1. Tronc `commande` — extension de l'ancre du cycle 006 ────────────────
--
-- L'ancre de 0005 ne portait que `id` et `cree_le`. AUCUN champ logistique
-- n'est ajouté (constitution II, research R3) : le devis figé, le coursier,
-- l'ordre des arrêts et tous les états de collecte vivent sur
-- `livraison`/`segment`/`arret`.
--
-- Les colonnes NOT NULL sans DEFAULT sont ajoutées sur une table VIDE en dev
-- comme en prod (aucune commande n'a jamais été créée : le cycle 006 n'insérait
-- que dans ses tests, sur des bases éphémères).
ALTER TABLE commandes.commande
    -- ── Identité ───────────────────────────────────────────────────────────
    ADD COLUMN client_id    uuid NOT NULL REFERENCES comptes.compte (id)    ON DELETE RESTRICT,
    ADD COLUMN zone_id      uuid NOT NULL REFERENCES zones.zone (id)        ON DELETE RESTRICT,
    ADD COLUMN categorie_id uuid NOT NULL REFERENCES zones.categorie (id)   ON DELETE RESTRICT,
    -- ── Lieu de prestation (destination pour un vertical de livraison) ─────
    -- DÉNORMALISÉ depuis comptes.adresse : le carnet peut être renommé, purgé de
    -- son repère vocal ou supprimé sans jamais altérer une commande passée (R3).
    ADD COLUMN lieu_lat         double precision NOT NULL,
    ADD COLUMN lieu_lon         double precision NOT NULL,
    ADD COLUMN repere_texte     text,
    ADD COLUMN repere_vocal_cle text,           -- clé S3, copiée à la création
    ADD COLUMN adresse_id       uuid REFERENCES comptes.adresse (id) ON DELETE SET NULL,
    -- ── Montants (III) — les FRAIS vivent sur la livraison, pas ici ────────
    ADD COLUMN montant_articles_unites bigint NOT NULL CHECK (montant_articles_unites >= 0),
    ADD COLUMN total_unites            bigint NOT NULL CHECK (total_unites >= 0),
    ADD COLUMN devise                  text   NOT NULL,   -- ISO 4217 de la zone
    -- ── Paiement — un seul montant, jamais de chemin partiel (III) ─────────
    ADD COLUMN mode_paiement commandes.mode_paiement NOT NULL,
    ADD COLUMN etat_paiement commandes.etat_paiement NOT NULL DEFAULT 'du',
    -- ── État de TRÈS HAUT NIVEAU ───────────────────────────────────────────
    ADD COLUMN etat    commandes.etat_commande NOT NULL DEFAULT 'nouvelle',
    ADD COLUMN etat_le timestamptz NOT NULL DEFAULT now(),
    -- ── Secrets de CONFIRMATION D'EXÉCUTION, remis au client dès la création
    -- (R6). Sur le TRONC et non sur la livraison, malgré leur usage actuel à la
    -- remise : ce sont des secrets GÉNÉRIQUES de confirmation d'exécution d'une
    -- commande, que tout vertical réutilise tel quel (un artisan de phase N fait
    -- valider son intervention par le même code, sans aucune livraison). Les
    -- placer sur `livraison` rendrait la confirmation IMPOSSIBLE pour un vertical
    -- sans livraison — c'est-à-dire pour le cas que la constitution II protège.
    -- Ils ne portent aucune donnée logistique : ni coursier, ni arrêt, ni
    -- itinéraire, ni montant. Voir plan.md § Complexity Tracking.
    ADD COLUMN code_livraison       text NOT NULL,  -- 4 chiffres, lisible par le CLIENT seul
    ADD COLUMN code_livraison_hash  text NOT NULL,  -- empreinte salée → coursier (offline CRS-04)
    ADD COLUMN jeton_reception      text NOT NULL,  -- encodé dans le QR client
    ADD COLUMN jeton_reception_hash text NOT NULL,  -- empreinte salée → coursier
    ADD COLUMN essais_code smallint NOT NULL DEFAULT 0,   -- plafond = paramètre de zone
    -- ── Re-livraison après consigne (§7.5) : nouvelle commande LIÉE ────────
    ADD COLUMN relivraison_de uuid REFERENCES commandes.commande (id) ON DELETE SET NULL,
    -- Cohérence : une commande terminée a forcément été réglée (ou remboursée).
    ADD CONSTRAINT commande_terminee_payee
        CHECK (etat <> 'terminee' OR etat_paiement IN ('regle', 'rembourse'));

-- L'identifiant EST la clé d'idempotence du POST (patron cycle 003, R7) :
-- aucune colonne ni table supplémentaire n'est nécessaire.

-- File d'attente sans coursier : FIFO par âge, SANS table dédiée (CMD-10).
CREATE INDEX commande_attente_fifo ON commandes.commande (cree_le)
    WHERE etat = 'en_attente_coursier';

-- Suivi client : ses commandes, les plus récentes d'abord.
CREATE INDEX commande_par_client ON commandes.commande (client_id, cree_le DESC);

-- ── 2. Livraison — le devis FIGÉ et l'état logistique ──────────────────────
ALTER TABLE commandes.livraison
    -- Devis figé, copié du cycle 007 à la création, JAMAIS recalculé (R11) :
    -- ni à la substitution, ni au retrait, ni à la réassignation.
    ADD COLUMN devis_prix_client   bigint  NOT NULL DEFAULT 0 CHECK (devis_prix_client   >= 0),
    ADD COLUMN devis_part_coursier bigint  NOT NULL DEFAULT 0 CHECK (devis_part_coursier >= 0),
    ADD COLUMN devis_marge         bigint  NOT NULL DEFAULT 0 CHECK (devis_marge         >= 0),
    ADD COLUMN devis_devise        text    NOT NULL DEFAULT 'XOF',
    ADD COLUMN devis_distance_m    bigint  NOT NULL DEFAULT 0,
    ADD COLUMN devis_eta_s         bigint  NOT NULL DEFAULT 0,
    ADD COLUMN devis_degraded      boolean NOT NULL DEFAULT false,  -- constitution IV
    ADD COLUMN devis_composantes   jsonb   NOT NULL DEFAULT '{}',   -- détail d'effort (affichage)
    ADD COLUMN proposer_scission   boolean NOT NULL DEFAULT false,  -- informatif (décidé par TRF)
    -- ── Remise ─────────────────────────────────────────────────────────────
    ADD COLUMN livree_le       timestamptz,
    ADD COLUMN mode_remise     text,        -- 'qr' | 'code' | 'depot'
    ADD COLUMN depot_photo_cle text,        -- mode dépôt autorisé (§7.4-5)
    ADD COLUMN assignee_le     timestamptz;

-- Course active d'un coursier, tous états de TRAVAIL confondus. L'index partiel
-- `livraison_par_coursier` du cycle 006 (WHERE etat = 'en_collecte') reste
-- valide et n'est pas touché.
CREATE INDEX livraison_coursier_active ON commandes.livraison (coursier_id)
    WHERE etat IN ('assignee', 'en_collecte', 'en_livraison');

-- ── 3. Arrêt — type, boucle de collecte, remise ────────────────────────────
--
-- Sémantique ÉLARGIE de site_lat/site_lon (nommées au cycle 006 pour les seules
-- collectes) : position ATTENDUE de l'arrêt — le site du vendeur pour une
-- collecte, le lieu de prestation du client pour une remise. Les colonnes ne
-- sont PAS renommées : leur migration est appliquée (constitution I).
ALTER TABLE commandes.arret
    ADD COLUMN type_arret commandes.type_arret NOT NULL DEFAULT 'collecte',
    ADD COLUMN en_route_le timestamptz,
    ADD COLUMN arrive_le   timestamptz,     -- base de la prime d'attente (TRF-06)
    ADD COLUMN transition_uuid_client uuid, -- idempotence des transitions (V)
    -- La remise n'a pas de prestataire (R4).
    ALTER COLUMN prestataire_id DROP NOT NULL,
    ADD CONSTRAINT arret_prestataire_coherent CHECK (
        (type_arret = 'collecte' AND prestataire_id IS NOT NULL) OR
        (type_arret = 'remise'   AND prestataire_id IS NULL)
    ),
    -- Rien n'est avancé à la remise : le coursier y ENCAISSE, il n'achète pas.
    ADD CONSTRAINT arret_remise_sans_montant CHECK (
        type_arret = 'collecte' OR montant_avance = 0
    );

-- Un seul arrêt de remise par segment.
CREATE UNIQUE INDEX arret_remise_unique ON commandes.arret (segment_id)
    WHERE type_arret = 'remise';

-- ⚠ NON-RÉGRESSION (R4, P1) : `PgCommandes::gating_livraison` comptait
-- count(*) sur TOUS les arrêts du segment. Avec l'arrêt de remise — qui n'est
-- jamais 'collecte' — `resolus = total` ne serait JAMAIS vrai et la livraison ne
-- basculerait plus jamais EN_LIVRAISON. Les requêtes de comptage sont corrigées
-- pour filtrer `type_arret = 'collecte'` (T006, immédiatement après cette
-- migration).

-- ── 4. Lignes de commande ──────────────────────────────────────────────────
CREATE TABLE commandes.ligne_commande (
    id             uuid PRIMARY KEY,
    commande_id    uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    prestataire_id uuid NOT NULL REFERENCES prestataires.prestataire (id) ON DELETE RESTRICT,
    article_id     uuid NOT NULL REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    -- Prix VERROUILLÉ par prestataires::figer_prix dans la MÊME transaction (III).
    prix_fige_id   uuid NOT NULL REFERENCES prestataires.prix_fige (id) ON DELETE RESTRICT,
    quantite       smallint NOT NULL CHECK (quantite > 0),
    preference     commandes.preference_substitution NOT NULL DEFAULT 'appeler',
    statut         commandes.statut_ligne NOT NULL DEFAULT 'presente',
    -- Arrêt qui collecte cette ligne (toujours de type 'collecte').
    arret_id       uuid REFERENCES commandes.arret (id) ON DELETE SET NULL,
    -- Remplacement accepté (CMD-06) — TOUJOURS chez le même vendeur (FR-048).
    remplace_par_article_id uuid REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    remplace_prix_unites    bigint CHECK (remplace_prix_unites IS NULL OR remplace_prix_unites >= 0),
    cree_le        timestamptz NOT NULL DEFAULT now(),
    CHECK (statut <> 'remplacee' OR remplace_par_article_id IS NOT NULL)
);

CREATE INDEX ligne_par_commande ON commandes.ligne_commande (commande_id);
CREATE INDEX ligne_par_arret    ON commandes.ligne_commande (arret_id) WHERE statut = 'presente';

-- ── 5. Détails de vertical — `resto_details` derrière ServiceWorkflow ──────
-- Constitution II : AUCUN champ spécifique à un vertical dans le tronc.
CREATE TABLE commandes.resto_details (
    commande_id           uuid PRIMARY KEY REFERENCES commandes.commande (id) ON DELETE CASCADE,
    delai_preparation_min smallint,   -- copié du prestataire à la création
    -- ⚠ PROVISIONS (constitution IX) : hooks d'acceptation vendeur (VAP,
    -- tranche T4). COLONNES SEULES — aucune logique d'acceptation ni de timeout
    -- n'est écrite ce cycle. « Prêt ≠ construit ».
    acceptee_le           timestamptz,
    refus_motif_cle       text
);

-- ── 6. Substitutions ───────────────────────────────────────────────────────
CREATE TABLE commandes.substitution (
    id       uuid PRIMARY KEY,
    ligne_id uuid NOT NULL REFERENCES commandes.ligne_commande (id) ON DELETE CASCADE,
    arret_id uuid NOT NULL REFERENCES commandes.arret (id) ON DELETE CASCADE,
    -- Article proposé — la garde « même vendeur » est vérifiée à l'écriture (FR-048).
    article_propose_id  uuid   NOT NULL REFERENCES prestataires.article (id) ON DELETE RESTRICT,
    prix_propose_unites bigint NOT NULL CHECK (prix_propose_unites >= 0),
    photo_cle   text NOT NULL,                    -- clé S3 (rétention de zone)
    proposee_le timestamptz NOT NULL DEFAULT now(),
    -- Échéance PERSISTÉE (R10) : jamais un minuteur en mémoire — une décision
    -- d'argent ne dépend pas de la vie d'un processus.
    echeance    timestamptz NOT NULL,
    issue       commandes.issue_substitution NOT NULL DEFAULT 'en_attente',
    decidee_le  timestamptz,
    uuid_client uuid NOT NULL,                    -- idempotence de la proposition (V)
    UNIQUE (uuid_client)
);

-- Balayage du job d'expiration (R10).
CREATE INDEX substitution_echeance ON commandes.substitution (echeance)
    WHERE issue = 'en_attente';

-- ── 7. Issues d'échec — l'arbre §7.5 rendu TESTABLE ────────────────────────
CREATE TABLE commandes.issue_echec (
    id          uuid PRIMARY KEY,
    commande_id uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    arret_id    uuid REFERENCES commandes.arret (id) ON DELETE SET NULL,  -- NULL = à la remise
    type_issue  commandes.type_issue_echec NOT NULL,
    -- « Chaque issue journalise qui détient l'argent et la marchandise »
    -- (CMD-08) devient DEUX COLONNES, donc deux assertions de test — et non une
    -- phrase de documentation. Les deux axes sont INDÉPENDANTS (research R14).
    detenteur_argent      commandes.detenteur NOT NULL,
    detenteur_marchandise commandes.detenteur NOT NULL,
    montant_en_jeu_unites bigint NOT NULL DEFAULT 0 CHECK (montant_en_jeu_unites >= 0),
    devise      text NOT NULL,
    indemnisation_due boolean NOT NULL DEFAULT false,  -- → événement ; caisse = CRS-06
    litige_ouvert     boolean NOT NULL DEFAULT false,  -- → événement ; dossier = AVI-04
    sanction    commandes.sanction NOT NULL DEFAULT 'aucune',
    motif_cle   text NOT NULL,                         -- clé i18n fr, jamais de texte libre
    acteur      uuid NOT NULL REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    cree_le     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX issue_par_commande ON commandes.issue_echec (commande_id);
