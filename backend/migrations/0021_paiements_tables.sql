-- Cycle PAY 011 — tables, colonnes, index et contraintes (specs/011 data-model.md §2).
--
-- Employe les valeurs d'enum ajoutees par 0020 : ce fichier ne peut donc PAS
-- fusionner avec elle (research R21). Les migrations 0001..0019 sont INTOUCHEES
-- (constitution I).
--
-- Tous les montants sont des `bigint` en UNITES MINEURES, accompagnes d'un code
-- ISO 4217 (constitution III). Aucun flottant n'entre dans ce fichier.

-- == 1. paiements.transaction ==============================================
--
-- Un montant, une commande, jamais deux sessions vivantes.

CREATE TABLE paiements.transaction (
    id                    uuid PRIMARY KEY,                      -- UUIDv7
    commande_id           uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    -- TOTAL FIGE de la commande a l'ouverture. Une notification annoncant un
    -- autre montant ne vaut PAS confirmation : elle ouvre un dossier (FR-024).
    -- C'est cette colonne, et non le total courant de la commande, qui fait foi
    -- au moment de la comparaison -- sinon un retrait de ligne posterieur
    -- transformerait un paiement honnete en divergence.
    montant_unites        bigint NOT NULL CHECK (montant_unites > 0),
    devise                text   NOT NULL,
    etat                  paiements.etat_transaction NOT NULL DEFAULT 'ouverte',
    moyen                 paiements.moyen_paiement   NOT NULL DEFAULT 'inconnu',
    -- ---- FRONTIERE FOURNISSEUR ----
    -- Ces trois colonnes sont les SEULES de tout le schema a porter le
    -- vocabulaire d'un fournisseur, et AUCUNE n'est lue par une regle metier
    -- (FR-003). Un changement d'agregateur ne touche qu'elles.
    fournisseur           text NOT NULL,                         -- 'simule' | 'agregateur' -- jamais une marque
    reference_fournisseur text,                                  -- connue apres create_checkout
    -- URL de la page de paiement. JAMAIS journalisee, JAMAIS mise en evenement
    -- (FR-006, FR-103), et EFFACEE des que la transaction quitte 'ouverte' :
    -- une URL d'encaissement encore vivante en base est une surface d'attaque
    -- sans usage (data-model §6).
    acces_paiement        text,
    ouverte_le            timestamptz NOT NULL DEFAULT now(),    -- horloge SERVEUR, jamais celle de l'app
    -- PERSISTEE : la lecture fait foi, le job ne fait que materialiser (R7).
    expire_le             timestamptz NOT NULL,
    issue_le              timestamptz,
    CONSTRAINT transaction_issue_datee CHECK (
        (etat = 'ouverte' AND issue_le IS NULL)
        OR (etat <> 'ouverte' AND issue_le IS NOT NULL))
);

-- UNE SEULE session vivante par commande (FR-015). Index partiel plutot que
-- contrainte d'unicite simple : une commande peut porter une transaction expiree
-- ET, plus tard, aucune autre -- mais jamais deux ouvertes en meme temps. C'est
-- cet index qui rend `POST /commandes/{id}/paiement` idempotent par la BASE et
-- non par un `if` qui perdrait la course.
CREATE UNIQUE INDEX transaction_vivante_unique
    ON paiements.transaction (commande_id) WHERE etat = 'ouverte';

-- Balayage d'expiration (R7) : les sessions echues, les plus vieilles d'abord.
CREATE INDEX transaction_a_expirer ON paiements.transaction (expire_le)
    WHERE etat = 'ouverte';

-- Registre d'exploitation (FR-080) : filtres etat / moyen / periode.
CREATE INDEX transaction_registre   ON paiements.transaction (etat, ouverte_le DESC);
CREATE INDEX transaction_par_moyen  ON paiements.transaction (moyen, ouverte_le DESC);
-- Rapprochement dans les deux sens (FR-081).
CREATE INDEX transaction_par_commande ON paiements.transaction (commande_id);

-- == 2. paiements.notification_recue =======================================
--
-- L'idempotence est une CONTRAINTE, pas un `if` (research R5). Deux
-- notifications concurrentes passeraient toutes deux un test « est-ce deja
-- regle ? » avant que l'une n'ecrive ; elles ne passent pas toutes deux un
-- INSERT sous contrainte d'unicite.

CREATE TABLE paiements.notification_recue (
    id                    uuid PRIMARY KEY,                      -- UUIDv7
    fournisseur           text NOT NULL,
    reference_fournisseur text NOT NULL,
    -- Empreinte du CORPS BRUT. Sans elle, un passage `en_cours` -> `reussi`
    -- portant la MEME reference serait avale comme un doublon -- et la seconde
    -- notification, celle qui porte le succes, serait perdue (research R5,
    -- confirme au Post-Design Constitution Re-Check du plan).
    empreinte_charge      text NOT NULL,
    transaction_id        uuid REFERENCES paiements.transaction (id) ON DELETE SET NULL,
    signature_valide      boolean NOT NULL,
    issue                 text NOT NULL,   -- 'reussi'|'echoue'|'annule'|'en_cours'|'refusee'
    montant_annonce       bigint,
    devise_annoncee       text,
    recue_le              timestamptz NOT NULL DEFAULT now(),
    -- LE verrou d'idempotence (FR-021, FR-022) :
    --   INSERT ... ON CONFLICT DO NOTHING RETURNING id
    -- Rien ne revient = rejeu = aucun effet, reponse 200 sans erreur (un
    -- fournisseur qui recoit une erreur retente en boucle).
    UNIQUE (fournisseur, reference_fournisseur, empreinte_charge)
);

-- Enquete d'exploitation sur une transaction contestee.
CREATE INDEX notification_par_transaction
    ON paiements.notification_recue (transaction_id, recue_le DESC);
-- Tentatives refusees : surveillance de securite (FR-020).
CREATE INDEX notification_refusees ON paiements.notification_recue (recue_le DESC)
    WHERE signature_valide = false;

COMMENT ON TABLE paiements.notification_recue IS
    'AUCUNE colonne ne stocke le corps brut ni la signature (FR-006). Seule '
    'l''empreinte est conservee, et elle ne permet pas de reconstituer un '
    'paiement. Retention 12 mois, purgee par le job de purge quotidien.';

-- == 3. paiements.dossier ==================================================
--
-- L'anomalie d'argent qui doit etre VUE. Un dossier n'est pas un log : un log se
-- perd dans le volume, un dossier a un etat et se clot avec un motif (R14).

CREATE TABLE paiements.dossier (
    id               uuid PRIMARY KEY,
    type_dossier     paiements.type_dossier NOT NULL,
    etat             paiements.etat_dossier NOT NULL DEFAULT 'ouvert',
    commande_id      uuid REFERENCES commandes.commande (id)    ON DELETE CASCADE,
    transaction_id   uuid REFERENCES paiements.transaction (id) ON DELETE CASCADE,
    arret_id         uuid REFERENCES commandes.arret (id)       ON DELETE SET NULL,
    montant_constate bigint,
    montant_attendu  bigint,
    devise           text,
    motif_cle        text NOT NULL,      -- cle i18n fr, JAMAIS de texte libre
    -- Idempotence du consommateur outbox (patron `CaisseOutbox`, cycle 010).
    -- NULLABLE a dessein : un dossier ne du webhook ne consomme aucun evenement,
    -- et NULL n'entre pas dans un UNIQUE -- plusieurs dossiers de webhook
    -- coexistent donc sans se bloquer.
    evenement_id     uuid UNIQUE,
    ouvert_le        timestamptz NOT NULL DEFAULT now(),
    clos_par         uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    clos_le          timestamptz,
    clos_motif_cle   text,
    CONSTRAINT dossier_cloture_complete CHECK (
        (etat = 'ouvert' AND clos_par IS NULL AND clos_le IS NULL AND clos_motif_cle IS NULL)
        OR (etat = 'clos' AND clos_par IS NOT NULL AND clos_le IS NOT NULL AND clos_motif_cle IS NOT NULL))
);

CREATE INDEX dossier_file        ON paiements.dossier (etat, ouvert_le DESC);
CREATE INDEX dossier_par_commande ON paiements.dossier (commande_id);

-- == 4. coursier.creance ===================================================
--
-- Ce que Mefali doit, SANS mentir sur la poche (research R12). Elle vit dans le
-- schema `coursier` parce qu'elle est de la caisse -- et hors du livre de
-- tresorerie parce qu'une creance n'est pas de l'argent en poche.

CREATE TABLE coursier.creance (
    id             uuid PRIMARY KEY,
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id)      ON DELETE RESTRICT,
    commande_id    uuid NOT NULL REFERENCES commandes.commande (id)  ON DELETE CASCADE,
    livraison_id   uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    nature         coursier.nature_creance NOT NULL,
    montant_unites bigint NOT NULL CHECK (montant_unites > 0),
    devise         text   NOT NULL,
    etat           coursier.etat_creance NOT NULL DEFAULT 'due',
    -- Idempotence : un rejeu de `livraison.livree` par le worker outbox, ou une
    -- fin de course rejouee depuis la file hors-ligne, ne cree qu'UNE creance
    -- (FR-068, SC-008).
    evenement_id   uuid NOT NULL UNIQUE,
    -- L'ecriture de caisse qui a materialise le versement (research R12) : le
    -- reglement ecrit la creance ET son mouvement dans la MEME transaction.
    ecriture_id    uuid REFERENCES coursier.ecriture_caisse (id) ON DELETE RESTRICT,
    regle_par      uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    regle_le       timestamptz,
    cree_le        timestamptz NOT NULL DEFAULT now(),
    -- Une seule creance de chaque nature par livraison : la garantie
    -- STRUCTURELLE que « solde » ne se dit qu'une fois.
    UNIQUE (livraison_id, nature),
    -- Un reglement est complet ou n'existe pas. Aucun retour arriere : une
    -- creance reglee a tort se corrige par une ecriture INVERSE au livre
    -- (FR-064), jamais par un UPDATE qui remettrait `due`.
    CONSTRAINT creance_reglement_complet CHECK (
        (etat = 'due'
            AND regle_par IS NULL AND regle_le IS NULL AND ecriture_id IS NULL)
        OR (etat = 'reglee'
            AND regle_par IS NOT NULL AND regle_le IS NOT NULL AND ecriture_id IS NOT NULL))
);

-- Position « du par Mefali » du coursier (FR-060) et ecran de caisse.
CREATE INDEX creance_par_coursier ON coursier.creance (coursier_id, etat, cree_le DESC);
-- File d'exploitation (FR-083) et seuil d'alerte (FR-065).
CREATE INDEX creance_dues ON coursier.creance (cree_le) WHERE etat = 'due';

-- == 5. prestataires.prestataire -- VND-08 minimal =========================
--
-- Debordement BORNE et justifie (plan.md, Complexity Tracking ligne 2) : sans
-- ces deux colonnes, la retenue de PAY-01 ne se declencherait JAMAIS en
-- production et un critere P0 serait livre non verifiable. Le badge client, le
-- merchandising et le tri restent a VND-08 (FR-049, FR-114).

ALTER TABLE prestataires.prestataire
    -- Defaut 'jamais' : aucun vendeur existant ne change de comportement a la
    -- migration (FR-046).
    ADD COLUMN offre_livraison prestataires.offre_livraison NOT NULL DEFAULT 'jamais',
    ADD COLUMN offre_livraison_seuil_unites bigint,
    -- Le seuil n'a de sens QUE pour 'au_dela', et il y est alors OBLIGATOIRE :
    -- une offre « a partir de rien » n'est pas une offre conditionnelle, c'est
    -- 'toujours' ecrit de travers.
    ADD CONSTRAINT offre_livraison_seuil_coherent CHECK (
        (offre_livraison = 'au_dela'
            AND offre_livraison_seuil_unites IS NOT NULL
            AND offre_livraison_seuil_unites > 0)
        OR (offre_livraison <> 'au_dela'
            AND offre_livraison_seuil_unites IS NULL));

-- == 6. commandes.arret -- la retenue, tracee la ou elle s'est jouee =======

ALTER TABLE commandes.arret
    -- Montant des articles AVANT retenue, tel que constate AU SCAN. Sans lui,
    -- le recu vendeur ne pourrait pas afficher les trois montants exiges par
    -- FR-071 (articles, retenue, net) : `montant_avance` est deja le NET.
    ADD COLUMN montant_articles_unites bigint NOT NULL DEFAULT 0
        CHECK (montant_articles_unites >= 0),
    ADD COLUMN retenue_appliquee_unites bigint NOT NULL DEFAULT 0
        CHECK (retenue_appliquee_unites >= 0),
    -- La retenue depassait les articles : avance ecretee a zero, dossier ouvert
    -- (FR-052). Booleen et non montant : l'ecart se recalcule, le FAIT non.
    ADD COLUMN retenue_ecretee boolean NOT NULL DEFAULT false;

-- ---- Reprise des lignes EXISTANTES, avant de poser l'invariant ----
--
-- Les arrets deja collectes portent un `montant_avance` > 0 alors que les trois
-- colonnes ci-dessus valent 0 par defaut : la contrainte suivante les
-- rejetterait toutes. Aucune retenue n'a jamais ete appliquee avant ce cycle
-- (la colonne n'existait pas), donc pour tout arret existant :
--     articles = montant_avance,  retenue = 0,  ecretee = false
-- C'est une reprise de donnees EXACTE, pas une approximation.
UPDATE commandes.arret SET montant_articles_unites = montant_avance
    WHERE montant_avance <> 0;

-- Invariant d'argent tenu par la BASE, et non par une convention de code : le
-- net verse au vendeur est toujours « articles moins retenue », ecrete a zero.
-- Une avance NEGATIVE ferait financer la course par le vendeur via le coursier,
-- ce que la constitution interdit (research R9).
ALTER TABLE commandes.arret
    ADD CONSTRAINT arret_avance_coherente CHECK (
        montant_avance = GREATEST(montant_articles_unites - retenue_appliquee_unites, 0));
