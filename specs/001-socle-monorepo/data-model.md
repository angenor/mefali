# Data Model — 001-socle-monorepo

Cycle socle : une seule migration métier (l'outbox). Les entités métier (zones,
comptes, vendeurs…) relèvent des cycles suivants — leurs crates sont créés
vides. Ce document définit les structures durables ou contractuelles du cycle.

## 1. Événement outbox (TRX-02, FR-013)

Propriété du crate `socle` (infrastructure transverse). Schéma Postgres dédié
`outbox` (constitution II : un schéma par module).

### Table `outbox.evenement`

| Colonne | Type | Contraintes | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | UUIDv7 (ordre temporel, généré côté backend) |
| `type_evenement` | `text` | NOT NULL | Clé de la taxonomie (`docs/taxonomie-evenements.md`), ex. `commande.creee` ; ce cycle n'émet que le type technique de test `socle.ping` |
| `entite_type` | `text` | NOT NULL | Type de l'entité concernée (ex. `commande`) |
| `entite_id` | `uuid` | NOT NULL | Identifiant de l'entité |
| `payload` | `jsonb` | NOT NULL | Contenu de l'événement ; inclut les propriétés standard (zone, catégorie, rôle, version d'app — cadrage §10.9) quand elles existent |
| `survenu_le` | `timestamptz` | NOT NULL | Horodatage métier de la transition |
| `cree_le` | `timestamptz` | NOT NULL DEFAULT now() | Horodatage d'insertion |
| `publie_le` | `timestamptz` | NULL | NULL = en attente de publication |
| `tentatives` | `int` | NOT NULL DEFAULT 0 | Compteur d'essais du worker |
| `derniere_erreur` | `text` | NULL | Dernière erreur de publication |

Index : partiel sur les événements en attente
`CREATE INDEX ... ON outbox.evenement (cree_le) WHERE publie_le IS NULL;`

### Invariants

- **Écriture atomique** : l'insertion se fait dans la MÊME transaction SQL que
  la transition d'état qui la provoque (constitution VI). L'API d'écriture ne
  prend donc jamais de pool — toujours une transaction ouverte
  (voir `contracts/outbox.md`).
- **Livraison at-least-once** : le worker lit par lots
  (`FOR UPDATE SKIP LOCKED`), publie, puis marque `publie_le`. Un crash entre
  publication et marquage produit une redélivrance — les consommateurs sont
  idempotents (dédoublonnage par `id`).
- **Aucune suppression** au MVP : le journal est aussi la matière première des
  métriques (constitution VI — aucun KPI manuel). La purge/archivage est une
  décision ultérieure.

### Cycle de vie

```
inséré (publie_le NULL) ──worker──▶ publié (publie_le NOT NULL)
        │ échec de publication
        ▼
   tentatives++, derniere_erreur ; re-tenté au prochain lot (backoff simple)
```

Test d'intégration obligatoire (constitution VII) sur chaque flèche :
commit → présent ; rollback → absent ; publication → marqué ; rejeu → sans
double effet ; échec → re-tenté.

## 2. Trait `ServiceWorkflow` (FR-003)

Défini dans `backend/crates/commandes`, AUCUNE implémentation ce cycle.
Signature provisoire — stabilisée au cycle CMD ; voir
`contracts/service-workflow.md`. Le tronc commande ne connaît que les états de
très haut niveau (créée / en cours / terminée / annulée / litige, cadrage
§11.11) ; tout état intermédiaire appartient au vertical derrière ce trait.

## 3. Jeu de démonstration — seeds (TRX-05, FR-016)

Versionnés À PART des migrations (constitution I) : `backend/seeds/`.

| Élément | Description |
|---|---|
| `backend/seeds/NN_<module>.sql` | Fichiers SQL ordonnés par dépendance (NN = ordre de chargement) ; un fichier par module ; contenu ajouté par chaque cycle de T1 (zones par ZON, vendeurs par VND…) |
| Runner | Commande unique (binaire `seed` du workspace) : ouvre UNE transaction, remet à zéro les tables seedées puis rejoue les fichiers dans l'ordre — idempotent par construction, interruption sans effet (rollback) |
| Ce cycle | Structure + runner + fichier `00_demo_marker.sql` (marqueur de jeu de démo) ; le contenu Tiassalé/vendeurs/articles arrive avec les schémas des cycles suivants (assumption de la spec) |

## 4. Configuration d'environnement (FR-017)

Contrat du `.env` (sur le VPS, hors Git ; `infra/.env.example` commité sans
valeur sensible) :

| Variable | Usage | Consommateur |
|---|---|---|
| `DATABASE_URL` | Postgres | backend, sqlx-cli, seed |
| `REDIS_URL` | Redis | backend |
| `S3_ENDPOINT`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_BUCKET` | Garage (API S3) — clé d'accès dédiée au backend | backend |
| `OSRM_URL` | Routage | backend (cycles suivants) |
| `SENTRY_DSN` | Erreurs | backend (vide en dev = désactivé) |
| `APP_ENV` | `dev` / `production` | backend (protège Swagger UI hors dev) |
| `BACKUP_S3_ENDPOINT`, `BACKUP_S3_*`, `BACKUP_AGE_RECIPIENT` | Externalisation des sauvegardes : bucket tiers (object lock/immutabilité côté bucket externe, jamais côté Garage), clé Garage dédiée au job de backup, clé publique age | scripts `infra/backups/` (rclone S3→S3) |

Tout paramètre MÉTIER reste hors `.env` : il ira en configuration de zone
(constitution I) dès le cycle ZON.

## 5. Composants du monorepo (FR-002)

Inventaire de référence — ce que chaque composant expose au reste du repo :

| Composant | Expose | Consomme |
|---|---|---|
| `backend/crates/socle` | Config, pool Postgres, init tracing/Sentry, écriture + worker outbox, types santé | `.env`, Postgres, Redis |
| `backend/crates/{zones,comptes,prestataires,qr,tarification,commandes,dispatch,coursier,paiements,notifications,avis,metriques}` | Vides (lib.rs compilable) ; `commandes` expose en plus le trait `ServiceWorkflow` | `socle` (autorisé, pas requis ce cycle) |
| `backend/api` | Binaire Actix : `/health`, `/api-docs/openapi.json`, Swagger UI, worker outbox ; binaire `seed` | tous les crates |
| `apps/packages/mefali_core` | `MefaliTheme` (ThemeData M3 depuis tokens), polices Inter + Material Symbols Rounded embarquées, constantes `tokens.dart` | `docs/design/tokens.md` (source des valeurs) |
| `apps/mefali_client`, `apps/mefali_pro` | Écran de démarrage thémé (preuve du thème) | `mefali_core`, `clients/dart` |
| `clients/dart`, `clients/ts` | Clients API GÉNÉRÉS | `openapi.json` |
| `web/` | Nuxt 4 hybride : page publique SSR minimale, `/admin` ssr:false minimal | `clients/ts` |
| `infra/` | docker-compose dev, provisionnement VPS, scripts backups, `.env.example` | — |
| `.github/workflows/` | CI filtrée par chemins + déploiement sur `main` | tout le repo |

Hors périmètre de ce cycle dans `mefali_core` : composants canoniques (`MfCard`,
`MfChip`…) et file d'actions offline — livrés par les cycles qui les
consomment ; seuls les emplacements (dossiers) sont créés (constitution IX).
