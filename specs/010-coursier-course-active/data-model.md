# Data model — cycle CRS 010 (app coursier)

Deux migrations, un schéma neuf, quatre tables locales de plus côté appareil.
Rien d'existant n'est modifié en place : les migrations **appliquées** (0001 à
0014) ne sont jamais touchées (constitution I).

---

## 1. Migration `0015_coursier.sql` — le schéma `coursier`

Schéma neuf, propriété exclusive du crate `coursier`. Aucune table de ce schéma
n'est lue par `commandes`, `qr` ou `dispatch`.

### 1.1 Énumérations

```sql
CREATE TYPE coursier.type_ecriture AS ENUM (
    'avance',                  -- argent sorti de la poche de Yao à un arrêt
    'remboursement',           -- encaissé chez le client (cash uniquement, R10)
    'indemnisation',           -- validée par l'exploitation
    'correction'               -- écriture INVERSE — jamais un UPDATE (FR-073)
);

CREATE TYPE coursier.etat_indemnisation AS ENUM (
    'demandee', 'validee', 'refusee'
);

CREATE TYPE coursier.motif_appel AS ENUM (
    'suivi',            -- appel ordinaire pendant la course
    'substitution',     -- article indisponible, préférence « m'appeler »
    'client_absent'     -- SEUL motif compté par la preuve d'échec (FR-035)
);

-- Issue DÉCLARÉE par le coursier (R19) : le serveur ne peut pas l'observer,
-- l'appel part du téléphone. Affichée sur K4-1e, jamais critère de preuve.
CREATE TYPE coursier.issue_appel AS ENUM (
    'inconnue', 'sans_reponse', 'repondu'
);
```

### 1.2 `coursier.ecriture_caisse` — le livre, append-only

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` PK | UUIDv7 |
| `coursier_id` | `uuid` → `comptes.compte` | |
| `type` | `coursier.type_ecriture` | |
| `montant_unites` | `bigint` | **signé** : `+` entrée pour le coursier, `−` sortie |
| `devise` | `text` | ISO 4217 de la zone |
| `commande_id` | `uuid` → `commandes.commande` | nullable (correction manuelle) |
| `livraison_id` | `uuid` | nullable |
| `arret_id` | `uuid` | nullable — renseigné pour une avance |
| `indemnisation_id` | `uuid` → `coursier.indemnisation` | nullable |
| `evenement_id` | `uuid` **UNIQUE** | idempotence du consommateur outbox (R9) |
| `annule_par` | `uuid` → self | nullable — pointe l'écriture **inverse** |
| `ecrit_le` | `timestamptz` | horodatage **serveur** |

Index : `(coursier_id, ecrit_le DESC)` pour l'historique du jour ;
`(coursier_id) WHERE type = 'avance'` pour le solde d'avances ouvertes.

**Invariants** — tenus par des contraintes, pas par des conventions :

- `UNIQUE (evenement_id)` : un événement rejoué par le worker n'écrit qu'une fois.
- Aucun `UPDATE` ni `DELETE` : une révocation ajoute une ligne `correction` de
  montant opposé et renseigne `annule_par` sur l'originale (seule écriture de
  mise à jour tolérée, sur une colonne qui ne porte pas d'argent).
- `CHECK (montant_unites <> 0)`.

### 1.3 Le montant avancé en cours — une somme, jamais une table

Pas de table de solde : le « montant avancé en cours » (FR-067) est une **somme** sur
`ecriture_caisse` (avances non compensées par un remboursement sur la même
livraison). Une table de solde serait une seconde vérité à réconcilier ; la somme
est exacte par construction.

Une commande **prépayée** n'ayant jamais de remboursement (R10), son avance reste
dans cette somme, avec le drapeau `en_attente_reglement` calculé depuis
`commande.mode_paiement` — ce que la caisse affiche explicitement (FR-117).

### 1.4 `coursier.indemnisation`

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` PK | |
| `coursier_id` | `uuid` → `comptes.compte` | |
| `commande_id` | `uuid` → `commandes.commande` | |
| `issue_echec_id` | `uuid` | l'issue de l'arbre §7.5 qui l'a décidée |
| `litige_id` | `uuid` | **nullable** — AVI-04 non construit (R16) |
| `montant_unites` | `bigint` `CHECK (> 0)` | |
| `devise` | `text` | |
| `etat` | `coursier.etat_indemnisation` | défaut `demandee` |
| `motif_cle` | `text` | clé i18n |
| `evenement_id` | `uuid` **UNIQUE** | idempotence (consommation de `indemnisation.due`) |
| `decide_par` | `uuid` → `comptes.compte` | nullable — admin |
| `decide_le` | `timestamptz` | nullable |
| `decision_motif_cle` | `text` | nullable |
| `cree_le` | `timestamptz` | |

### 1.5 `coursier.appel_coursier`

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` PK | |
| `livraison_id` | `uuid` → `commandes.livraison` | |
| `coursier_id` | `uuid` | |
| `vers` | `text` | `client` \| `vendeur` |
| `prestataire_id` | `uuid` | nullable — renseigné si `vers = vendeur` |
| `motif` | `coursier.motif_appel` | |
| `issue` | `coursier.issue_appel` | défaut `inconnue` — **déclarée** par le coursier (R19), affichée sur K4-1e (FR-036) |
| `uuid_client` | `uuid` **UNIQUE** | idempotence de la file (V) |
| `passe_le` | `timestamptz` | horodatage **serveur** |
| `passe_le_local` | `timestamptz` | horodatage de l'appareil — observation |

**Aucun numéro de téléphone n'est stocké** (R6). Index `(livraison_id, passe_le)`
— c'est la requête de la preuve (nombre + espacement).

### 1.6 `coursier.releve_presence`

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` PK | |
| `livraison_id` | `uuid` → `commandes.livraison` | |
| `distance_m` | `integer` | **distance arrondie** au point de livraison — jamais de lat/lon (R8) |
| `releve_le` | `timestamptz` | horodatage **serveur** de réception |
| `releve_le_local` | `timestamptz` | horodatage de l'échantillon sur l'appareil |
| `uuid_client` | `uuid` **UNIQUE** | idempotence (lots rejoués) |

Index `(livraison_id, releve_le_local)` : la durée se calcule sur l'ordre local,
qui est celui de la réalité vécue par Yao, tout en restant vérifiable côté
serveur.

### 1.7 `coursier.preuve_photo`

| Colonne | Type | Note |
|---|---|---|
| `id` | `uuid` PK | |
| `livraison_id` | `uuid` → `commandes.livraison` | |
| `cle_objet` | `text` | clé Garage |
| `prise_le` | `timestamptz` | |
| `uuid_client` | `uuid` **UNIQUE** | |
| `purgee_le` | `timestamptz` | nullable — job de rétention (patron cycle 006) |

---

## 2. Migration `0016_commandes_remise_depot.sql` — ce que `commandes` gagne

Colonnes ajoutées à des tables **existantes** — aucune ne porte de logistique :
elles décrivent la **remise au client**, que le cycle 008 porte déjà sur la
commande (`code_livraison`, `essais_code`, `mode_remise`, `depot_photo_cle`).

```sql
ALTER TABLE commandes.commande
    -- Dépôt autorisé (clarification 2026-07-28) — FERMÉ par défaut.
    ADD COLUMN depot_autorise      boolean NOT NULL DEFAULT false,
    ADD COLUMN depot_autorise_le   timestamptz,
    ADD COLUMN depot_autorise_par  uuid REFERENCES comptes.compte (id),
    ADD COLUMN depot_motif_cle     text,
    -- Blocage du code de remise (FR-043/FR-044/FR-055).
    ADD COLUMN code_bloque_le      timestamptz,
    ADD COLUMN code_debloque_le    timestamptz,
    ADD COLUMN code_debloque_par   uuid REFERENCES comptes.compte (id),
    ADD COLUMN code_deblocage_motif_cle text;

ALTER TABLE commandes.livraison
    -- Idempotence de la remise — le manque du cycle 008 (R4).
    ADD COLUMN remise_uuid_client  uuid UNIQUE,
    -- Remise validée hors ligne ? (journalisée, jamais décisive)
    ADD COLUMN remise_hors_ligne   boolean NOT NULL DEFAULT false;

ALTER TABLE commandes.issue_echec
    ADD COLUMN issue_uuid_client   uuid UNIQUE;   -- idempotence de l'échec (R4)

-- Le dépôt ne peut être ouvert sans trace : les quatre colonnes vont ensemble.
ALTER TABLE commandes.commande
    ADD CONSTRAINT depot_trace_complete CHECK (
        depot_autorise = false
        OR (depot_autorise_le IS NOT NULL AND depot_autorise_par IS NOT NULL
            AND depot_motif_cle IS NOT NULL));

-- Le commentaire de la migration 0004 (« servi UNIQUEMENT à l'admin ») décrivait
-- l'état d'alors. Le coursier ASSIGNÉ le reçoit désormais dans son
-- pré-provisionnement pour appeler le vendeur hors ligne (R6) — la règle qui
-- tient toujours est celle de SC-013 du cycle 005 : aucune consultation NON
-- AUTHENTIFIÉE ne révèle un contact. On ne réécrit pas 0004 (constitution I),
-- on corrige le commentaire ici.
COMMENT ON COLUMN prestataires.prestataire.contact_telephone IS
    'Contact du vendeur. Servi à l''admin et au coursier ASSIGNÉ (CRS-03) ; jamais
     à une consultation non authentifiée, jamais journalisé.';
```

**Règle de lecture** : la voie « dépôt » n'est proposée par l'app que si
`depot_autorise = true`, et le serveur **refuse** une remise en mode `depot` sur
une commande où il vaut `false` (FR-048) — la garde est des deux côtés.

---

## 3. Contenu du pré-provisionnement (`GET /courses/active`)

Structure **servie**, pas stockée telle quelle côté serveur : composée à la
lecture depuis `commandes` (course, arrêts, lignes, client, secrets hachés),
`prestataires` (nom, position, téléphone du vendeur) et `qr` (empreinte de
plaque, code de secours haché, politique photo résolue).

```text
CourseActive
├── livraison_id, commande_id, etat, devise
├── arrets[]                         (ordre optimisé)
│   ├── arret_id, prestataire_id, nom, site_lat/lon, distance_precedent_m
│   ├── empreinte_jeton, empreinte_code      ← plaque (cycle 006)
│   ├── montant_avance, photo_exigee, distance_max_m
│   ├── statut, collecte_le, en_route_le, arrive_le
│   ├── telephone_vendeur                    ← appel hors ligne, jamais journalisé
│   └── lignes[]                             ← ⭐ NOUVEAU (K3)
│       └── ligne_id, libelle, quantite, prix_unitaire_unites,
│          preference_substitution, statut
├── client                                   ← ⭐ NOUVEAU (K3-1c, K4)
│   ├── nom_usage, telephone
│   ├── repere_texte, repere_vocal_url (présignée), repere_vocal_duree_s
│   ├── lieu_lat, lieu_lon
│   └── depot_autorise
└── remise                                   ← ⭐ NOUVEAU (K4)
    ├── empreinte_code, empreinte_jeton       ← déjà en base (R3)
    ├── essais_consommes, essais_max, code_bloque
    ├── montant_a_encaisser_unites, mode_paiement
    └── preuves { appels_min, espacement_s, presence_s, rayon_m, photos_min }
```

**Minimisation** : cette structure ne sort **qu'après assignation** (FR-104) et
n'est servie qu'au coursier assigné. La note vocale est une **URL présignée** de
courte durée, que l'app télécharge immédiatement pour la jouer hors ligne
(FR-024) — même patron que le repère d'adresse du cycle 008.

---

## 4. Base locale (drift, `mefali_core`) — `schemaVersion` + 1

Quatre tables s'ajoutent aux quatre existantes (`actions_en_attente`,
`arrets_preprovisionnes`, `brouillons_panier`, `commandes_cache`). Migration
**additive** : aucune table existante n'est modifiée, aucune donnée en vol n'est
perdue au passage de version.

| Table | Rôle | Effacée quand |
|---|---|---|
| `course_cache` | client, repère (texte + **fichier audio local**), empreintes de remise, montant à encaisser, drapeau de dépôt, **numéro de téléphone** | à la clôture de la course (R6) |
| `lignes_checklist` | une ligne par article : libellé, quantité, prix, préférence, **coche locale**, statut | à la clôture de la course |
| `essais_remise` | compteur d'essais faux consommés hors ligne, par livraison | après consolidation serveur |
| `releves_presence_locaux` | échantillons de présence en attente d'envoi | après rejeu accepté |

`arrets_preprovisionnes` (cycle 006) est **conservée telle quelle** et gagne les
champs manquants par jointure logique avec `course_cache` — pas de refonte : la
file en vol au moment de la mise à jour continue de fonctionner.

---

## 5. États et transitions introduits

Ce cycle **n'ajoute aucune ligne** à la table de transitions fermée du cycle 008.
Les seuls états neufs sont locaux à ses propres entités :

```text
indemnisation :  demandee ──validée par admin──▶ validee
                     └─────refusée par admin───▶ refusee     (motif obligatoire)

code de remise :  ouvert ──N essais faux──▶ bloqué ──levée admin──▶ ouvert
                                                (motif obligatoire, tracé)

dépôt :           fermé ──ouverture admin (motif)──▶ ouvert
```

Chacune de ces transitions écrit son événement outbox dans la même transaction
(constitution VI) — voir `contracts/ports-coursier.md` §3.

---

## 6. Rétention et purge

| Donnée | Rétention | Mécanisme |
|---|---|---|
| Photo de preuve d'échec | `coursier.retention_photo_preuve_jours` (365) | job périodique, patron `job_purge_photos_collecte` du cycle 006 |
| Relevés de présence | même durée que la photo | purge par le même job (ils ne valent que comme preuve) |
| Numéro de téléphone en cache local | durée de la course | effacé à la clôture, côté appareil |
| Écritures de caisse | **jamais purgées** | ce sont des écritures d'argent |
