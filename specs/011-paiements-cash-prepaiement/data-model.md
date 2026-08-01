# Data model — Cycle PAY 011 : paiements

**Feature** : `011-paiements-cash-prepaiement` | **Date** : 2026-08-01
**Entrée** : [spec.md](./spec.md), [research.md](./research.md)

Deux migrations, dans cet ordre imposé (research R21) :

| Fichier | Contenu | Pourquoi séparé |
|---|---|---|
| `0020_paiements_enums.sql` | schéma `paiements`, ses enums, `ALTER TYPE` sur les enums existants | PostgreSQL refuse d'employer une valeur d'enum dans la transaction qui l'ajoute |
| `0021_paiements_tables.sql` | tables, colonnes, index, contraintes | utilise les valeurs ajoutées ci-dessus |

Les migrations `0001..0019` sont **INTOUCHÉES** (constitution I).

---

## 1. Migration `0020_paiements_enums.sql`

### 1.1 Schéma et énumérations neuves

```sql
CREATE SCHEMA IF NOT EXISTS paiements;

-- Cycle de vie d'une transaction. Aucun état « partiellement payée » :
-- constitution III, et la spec en fait un invariant (FR-002).
CREATE TYPE paiements.etat_transaction AS ENUM (
    'ouverte',            -- session vivante, le client peut payer
    'reglee',             -- notification signée de succès, commande confirmée
    'echouee',            -- refus opérateur ; le client peut réessayer tant que la session vit
    'expiree',            -- échéance franchie sans succès → commande annulée
    'payee_hors_delai'    -- succès arrivé APRÈS l'expiration (R8) — dossier ouvert
);

-- Moyen effectivement utilisé, communiqué par le fournisseur (FR-012).
-- `inconnu` est l'état AVANT que le fournisseur ne le dise — jamais deviné.
-- `autre` recueille un moyen qu'un futur agrégateur nommerait sans que le
-- domaine ait à migrer (research R3).
CREATE TYPE paiements.moyen_paiement AS ENUM (
    'inconnu', 'wave', 'orange_money', 'mtn_momo', 'moov_money', 'carte', 'autre'
);

-- Anomalie d'argent qui doit être vue par un humain (FR-082).
CREATE TYPE paiements.type_dossier AS ENUM (
    'montant_divergent',       -- FR-024
    'devise_divergente',       -- FR-024
    'paiement_hors_delai',     -- FR-037
    'transaction_orpheline',   -- FR-082
    'retenue_ecretee',         -- FR-052
    'remboursement_client_du'  -- FR-082 — PAY-04 non construit
);

CREATE TYPE paiements.etat_dossier AS ENUM ('ouvert', 'clos');

-- VND-08, part minimale (research R10). Vit dans `prestataires` : c'est une
-- décision commerciale d'un vendeur, pas un objet de paiement.
CREATE TYPE prestataires.offre_livraison AS ENUM ('jamais', 'toujours', 'au_dela');

-- Nature d'une créance de coursier (research R12).
CREATE TYPE coursier.nature_creance AS ENUM (
    'avance_prepayee',  -- le client a prépayé : Mefali doit l'avance
    'part_course'       -- le coursier n'a encaissé aucun frais (prépayé, ou frais nuls)
);

CREATE TYPE coursier.etat_creance AS ENUM ('due', 'reglee');
```

### 1.2 Valeurs ajoutées aux énumérations existantes

```sql
-- Le livre de caisse gagne trois natures de MOUVEMENT RÉEL (research R13).
-- Aucune ne représente une créance : une créance n'est pas de l'argent en poche.
ALTER TYPE coursier.type_ecriture ADD VALUE IF NOT EXISTS 'frais_encaisses';
ALTER TYPE coursier.type_ecriture ADD VALUE IF NOT EXISTS 'reglement';
ALTER TYPE coursier.type_ecriture ADD VALUE IF NOT EXISTS 'reversement';
```

| Valeur | Signe | Montant | Écrite quand |
|---|---|---|---|
| `frais_encaisses` | **+** | `total_du_client − Σ avances` (research R13 — **pas** `devis_prix_client`) | remise **cash** validée |
| `reglement` | **+** | montant de la créance | l'exploitation marque une créance réglée |
| `reversement` | **−** | montant reversé | le coursier rend à Mefali la marge détenue (0 au MVP) |

---

## 2. Migration `0021_paiements_tables.sql`

### 2.1 `paiements.transaction` — un montant, une commande, jamais deux vivantes

```sql
CREATE TABLE paiements.transaction (
    id                    uuid PRIMARY KEY,                      -- UUIDv7
    commande_id           uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    -- TOTAL figé de la commande à l'ouverture. Une notification annonçant un
    -- autre montant ne vaut PAS confirmation (FR-024).
    montant_unites        bigint NOT NULL CHECK (montant_unites > 0),
    devise                text   NOT NULL,                       -- ISO 4217 de la zone
    etat                  paiements.etat_transaction NOT NULL DEFAULT 'ouverte',
    moyen                 paiements.moyen_paiement   NOT NULL DEFAULT 'inconnu',
    -- Frontière fournisseur : ces trois colonnes sont les SEULES à porter son
    -- vocabulaire, et aucune n'est lue par une règle métier (FR-003).
    fournisseur           text NOT NULL,                         -- 'agregateur' | 'simule' | …
    reference_fournisseur text,                                  -- connue après create_checkout
    acces_paiement        text,                                  -- URL de la page — JAMAIS en événement (FR-103)
    ouverte_le            timestamptz NOT NULL DEFAULT now(),    -- horloge SERVEUR
    expire_le             timestamptz NOT NULL,                  -- PERSISTÉE : la lecture fait foi (R7)
    issue_le              timestamptz,                           -- instant de l'issue définitive
    -- UNE SEULE session vivante par commande (FR-015). Index partiel plutôt que
    -- contrainte : une commande peut avoir une transaction expirée ET, plus
    -- tard, aucune autre — mais jamais deux ouvertes.
    CONSTRAINT transaction_issue_datee CHECK (
        (etat = 'ouverte' AND issue_le IS NULL) OR (etat <> 'ouverte' AND issue_le IS NOT NULL))
);

CREATE UNIQUE INDEX transaction_vivante_unique
    ON paiements.transaction (commande_id) WHERE etat = 'ouverte';
-- Balayage d'expiration (R7) : les sessions échues, les plus vieilles d'abord.
CREATE INDEX transaction_a_expirer ON paiements.transaction (expire_le)
    WHERE etat = 'ouverte';
-- Registre d'exploitation (FR-080) : filtres état / moyen / période.
CREATE INDEX transaction_registre ON paiements.transaction (etat, ouverte_le DESC);
CREATE INDEX transaction_par_moyen ON paiements.transaction (moyen, ouverte_le DESC);
-- Rapprochement dans les deux sens (FR-081).
CREATE INDEX transaction_par_commande ON paiements.transaction (commande_id);
```

### 2.2 `paiements.notification_recue` — l'idempotence est une contrainte, pas un `if`

```sql
CREATE TABLE paiements.notification_recue (
    id                    uuid PRIMARY KEY,                      -- UUIDv7
    fournisseur           text NOT NULL,
    reference_fournisseur text NOT NULL,
    -- Empreinte du CORPS BRUT. Sans elle, un passage `en_cours → réussi` du
    -- même identifiant serait avalé comme un doublon (research R5).
    empreinte_charge      text NOT NULL,
    transaction_id        uuid REFERENCES paiements.transaction (id) ON DELETE SET NULL,
    signature_valide      boolean NOT NULL,
    issue                 text NOT NULL,                         -- 'reussi'|'echoue'|'annule'|'en_cours'|'refusee'
    montant_annonce       bigint,
    devise_annoncee       text,
    recue_le              timestamptz NOT NULL DEFAULT now(),
    -- LE verrou d'idempotence (FR-021, FR-022). `ON CONFLICT DO NOTHING
    -- RETURNING id` : rien ne revient = rejeu = aucun effet.
    UNIQUE (fournisseur, reference_fournisseur, empreinte_charge)
);

-- Enquête d'exploitation sur une transaction contestée.
CREATE INDEX notification_par_transaction ON paiements.notification_recue (transaction_id, recue_le DESC);
-- Tentatives refusées : surveillance de sécurité (FR-020).
CREATE INDEX notification_refusees ON paiements.notification_recue (recue_le DESC)
    WHERE signature_valide = false;
```

⚠ **Aucune colonne ne stocke le corps brut ni la signature** : FR-006. Seule
l'empreinte est conservée, et elle ne permet pas de reconstituer un paiement.

### 2.3 `paiements.dossier` — l'anomalie qui doit être vue

```sql
CREATE TABLE paiements.dossier (
    id               uuid PRIMARY KEY,
    type_dossier     paiements.type_dossier NOT NULL,
    etat             paiements.etat_dossier NOT NULL DEFAULT 'ouvert',
    commande_id      uuid REFERENCES commandes.commande (id)     ON DELETE CASCADE,
    transaction_id   uuid REFERENCES paiements.transaction (id)  ON DELETE CASCADE,
    arret_id         uuid REFERENCES commandes.arret (id)        ON DELETE SET NULL,
    montant_constate bigint,
    montant_attendu  bigint,
    devise           text,
    motif_cle        text NOT NULL,                              -- clé i18n, jamais de texte libre
    -- Idempotence du consommateur outbox (patron `CaisseOutbox`, cycle 010).
    -- NULLABLE : un dossier né du webhook ne consomme aucun événement, et NULL
    -- n'entre pas dans un UNIQUE.
    evenement_id     uuid UNIQUE,
    ouvert_le        timestamptz NOT NULL DEFAULT now(),
    clos_par         uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    clos_le          timestamptz,
    clos_motif_cle   text,
    CONSTRAINT dossier_cloture_complete CHECK (
        (etat = 'ouvert' AND clos_par IS NULL AND clos_le IS NULL)
        OR (etat = 'clos' AND clos_par IS NOT NULL AND clos_le IS NOT NULL))
);

CREATE INDEX dossier_file ON paiements.dossier (etat, ouvert_le DESC);
CREATE INDEX dossier_par_commande ON paiements.dossier (commande_id);
```

### 2.4 `coursier.creance` — ce que Mefali doit, sans mentir sur la poche

```sql
CREATE TABLE coursier.creance (
    id             uuid PRIMARY KEY,
    coursier_id    uuid NOT NULL REFERENCES comptes.compte (id)     ON DELETE RESTRICT,
    commande_id    uuid NOT NULL REFERENCES commandes.commande (id) ON DELETE CASCADE,
    livraison_id   uuid NOT NULL REFERENCES commandes.livraison (id) ON DELETE CASCADE,
    nature         coursier.nature_creance NOT NULL,
    montant_unites bigint NOT NULL CHECK (montant_unites > 0),   -- entier, III
    devise         text   NOT NULL,
    etat           coursier.etat_creance NOT NULL DEFAULT 'due',
    -- Idempotence : un rejeu de `livraison.livree` par le worker outbox, ou une
    -- fin de course rejouée depuis la file hors-ligne, ne crée qu'une créance
    -- (FR-068, SC-008).
    evenement_id   uuid NOT NULL UNIQUE,
    -- L'écriture de caisse qui a matérialisé le versement (research R12).
    ecriture_id    uuid REFERENCES coursier.ecriture_caisse (id) ON DELETE RESTRICT,
    regle_par      uuid REFERENCES comptes.compte (id) ON DELETE RESTRICT,
    regle_le       timestamptz,
    cree_le        timestamptz NOT NULL DEFAULT now(),
    -- Une seule créance de chaque nature par livraison : la garantie
    -- structurelle que « soldé » ne se dit qu'une fois.
    UNIQUE (livraison_id, nature),
    CONSTRAINT creance_reglement_complet CHECK (
        (etat = 'due'    AND regle_par IS NULL AND regle_le IS NULL AND ecriture_id IS NULL)
        OR (etat = 'reglee' AND regle_par IS NOT NULL AND regle_le IS NOT NULL AND ecriture_id IS NOT NULL))
);

-- Position « dû par Mefali » du coursier (FR-060) et écran de caisse.
CREATE INDEX creance_par_coursier ON coursier.creance (coursier_id, etat, cree_le DESC);
-- File d'exploitation (FR-083) et seuil d'alerte (FR-065).
CREATE INDEX creance_dues ON coursier.creance (cree_le) WHERE etat = 'due';
```

### 2.5 `prestataires.prestataire` — VND-08 minimal

```sql
ALTER TABLE prestataires.prestataire
    ADD COLUMN offre_livraison prestataires.offre_livraison NOT NULL DEFAULT 'jamais',
    ADD COLUMN offre_livraison_seuil_unites bigint,
    -- Le seuil n'a de sens QUE pour `au_dela`, et il est alors obligatoire :
    -- une offre « à partir de rien » n'est pas une offre conditionnelle.
    ADD CONSTRAINT offre_livraison_seuil_coherent CHECK (
        (offre_livraison = 'au_dela' AND offre_livraison_seuil_unites IS NOT NULL
                                     AND offre_livraison_seuil_unites > 0)
        OR (offre_livraison <> 'au_dela' AND offre_livraison_seuil_unites IS NULL));
```

Défaut `'jamais'` : aucun vendeur existant ne change de comportement à la
migration (FR-046).

### 2.6 `commandes.arret` — la retenue appliquée, tracée là où elle s'est jouée

```sql
ALTER TABLE commandes.arret
    -- Montant des articles AVANT retenue, tel que constaté au scan. Sans lui,
    -- le reçu vendeur ne pourrait pas afficher les trois montants exigés par
    -- FR-071 (articles, retenue, net) — `montant_avance` est déjà le net.
    ADD COLUMN montant_articles_unites bigint NOT NULL DEFAULT 0
        CHECK (montant_articles_unites >= 0),
    ADD COLUMN retenue_appliquee_unites bigint NOT NULL DEFAULT 0
        CHECK (retenue_appliquee_unites >= 0),
    -- La retenue dépassait les articles : avance écrêtée à zéro, dossier ouvert
    -- (FR-052). Booléen et non montant : l'écart se recalcule, le fait non.
    ADD COLUMN retenue_ecretee boolean NOT NULL DEFAULT false,
    -- Invariant d'argent, tenu par la BASE et pas par une convention.
    ADD CONSTRAINT arret_avance_coherente CHECK (
        montant_avance = GREATEST(montant_articles_unites - retenue_appliquee_unites, 0));
```

---

## 3. Ce qui NE change pas, et pourquoi c'est important

| Objet | Statut | Raison |
|---|---|---|
| `coursier.ecriture_caisse` (structure) | **inchangée** | seules des valeurs d'enum s'ajoutent ; l'immuabilité (trigger `refuser_mutation_ecriture`) et `evenement_id UNIQUE` valent telles quelles pour les nouvelles natures |
| `commandes.commande.etat_paiement` | **inchangé** | `'en_attente'` existe depuis 0008 ; ce cycle le **pose** enfin (research R16) |
| `commandes.commande.total_unites` | **inchangé** | déjà ajusté par les retraits et les arrêts indisponibles (`substitution.rs:75`) — FR-055 est acquis |
| `commandes.livraison.devis_*` | **inchangé** | `devis_prix_client`, `devis_part_coursier`, `devis_marge` et `devis_composantes.retenue_vendeur` portent déjà tout ce dont R9 et R13 ont besoin |
| Migrations `0001..0019` | **intouchées** | constitution I |

---

## 4. États et transitions introduits

### 4.1 Transaction de paiement

```text
                    ┌──────────────► reglee            (notification signée « réussi »)
                    │
   (ouverture) ──► ouverte ────────► echouee           (refus opérateur — réessai permis)
                    │  ▲                 │
                    │  └─────────────────┘             (le client réessaie, la session vit)
                    │
                    └──────────────► expiree           (échéance, après réconciliation)
                                        │
                                        └────────────► payee_hors_delai   (succès tardif, R8)
```

Gardes :

- `ouverte → reglee` exige signature valide **et** montant **et** devise identiques
  au figé (FR-024) ; écrit `commandes::confirmer_prepaiement` dans la **même**
  transaction SQL.
- `ouverte → expiree` n'a lieu qu'après un `consulter` sans succès (R7).
- `reglee` est **terminal** : aucune transition n'en sort (FR-034).
- `expiree → payee_hors_delai` ne touche **pas** la commande (FR-036).

### 4.2 Créance de coursier

```text
   (livraison.livree, commande prépayée ou frais nuls) ──► due ──► reglee
                              automatique                   marquage exploitation
                                                            + écriture `reglement`
```

`due → reglee` est la **seule** transition, et elle écrit son mouvement de caisse
dans la même transaction. Aucun retour en arrière : une créance réglée à tort se
corrige par une écriture **inverse** au livre (FR-064).

### 4.3 Dossier d'exploitation

```text
   ouvert ──► clos     (motif obligatoire, auteur et instant conservés)
```

---

## 5. Écritures de caisse par état de commande — la table de vérité de SC-006

Notations : `A` = Σ avances de la livraison, `PC` = `devis_prix_client`,
`P` = `devis_part_coursier`, `M` = `devis_marge` (0 au MVP), `R` = retenue
vendeur. Les deux formules de référence (research R13) :

```text
frais_encaisses = total_du_client − A
part_course     = max(devis_part_coursier − max(frais_encaisses − M, 0), 0)
```

| État | Écritures au livre | Créances | Solde livre | Dû par Mefali |
|---|---|---|---|---|
| créée / en attente de paiement | — | — | 0 | 0 |
| prépayée (réglée, non assignée) | — | — | 0 | 0 |
| assignée | — | — | 0 | 0 |
| partiellement collectée | `avance` ×n | — | −A | 0 |
| **livrée, cash ordinaire** | `avance` ×n, `remboursement` +A, `frais_encaisses` +PC | — | +P+M | 0 |
| **livrée, cash + retenue VND-08** (PC = 0, R = P+M) | `avance` ×n (nettes de R), `remboursement` +A, `frais_encaisses` +R | — | +P+M | 0 |
| **livrée, cash + promo Mefali** (PC = 0, pas de retenue) | `avance` ×n, `remboursement` +A, `frais_encaisses` +0 | `part_course` P | 0 | P |
| **livrée, prépayée** | `avance` ×n | `avance_prepayee` A, `part_course` P | −A | A + P |
| annulée avant achat | — | — | 0 | 0 |
| annulée après achat | `avance` ×n | (via `indemnisation.due`, cycle 010) | −A | indemnisation |
| échouée après achat | `avance` ×n | (via `indemnisation.due`) | −A | indemnisation |
| expirée | — | — | 0 | 0 |

Lecture de contrôle : après règlement des créances, **les quatre chemins de
livraison convergent sur `+P` de gain pour Yao** — cash ordinaire `+P+M` dont `M`
est détenu pour Mefali, cash avec retenue idem, promo `0 + P`, prépayé
`−A + (A+P)`. C'est la vérification que SC-006 demande, état par état, et le test
`coursier_positions` la parcourt ligne à ligne.

⚠ Le cas **cash + retenue** est celui qui invalide la formule naïve
`frais_encaisses = devis_prix_client` : le prix client y vaut 0, mais Yao a bien
`R` de plus dans sa poche puisqu'il a payé le vendeur `articles − R` et encaissé
`articles`. Un livre qui porterait 0 mentirait exactement là où la retenue existe
pour qu'il dise vrai.

---

## 6. Rétention et conformité

- `paiements.notification_recue` : conservée **12 mois** (même règle que
  l'outbox), purgée par le job de purge quotidien existant. Elle ne contient ni
  corps, ni signature, ni donnée nominative.
- `paiements.transaction.acces_paiement` : **effacée** (mise à `NULL`) dès que la
  transaction quitte `ouverte`. Une URL de paiement encore vivante dans une base
  est une surface d'attaque sans usage (FR-006).
- Aucune donnée de carte, aucun numéro de compte mobile money n'est reçu, stocké
  ni journalisé : le produit ne voit que le **moyen** utilisé, jamais l'identifiant
  du payeur (minimisation ARTCI, constitution VIII).
