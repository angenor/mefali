# Implementation Plan: Socle technique du monorepo Mefali

**Branch**: `001-socle-monorepo` | **Date**: 2026-07-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-socle-monorepo/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Créer le socle du monorepo : workspace Rust (12 crates de domaine vides +
crate technique `socle` + binaire `api`), trait `ServiceWorkflow`, outbox
transactionnelle, contrat OpenAPI généré (`/health` documenté) avec clients
Dart/TS régénérés et contrôlés en CI, deux apps Flutter consommant le thème
Material 3 construit depuis `docs/design/tokens.md` via `mefali_core`, Nuxt 4
hybride, infra docker-compose (Postgres, Redis, Garage, OSRM + extrait OSM CI),
CI GitHub Actions filtrée par chemins, VPS de production minimal déployé par
GitHub Action sur `main`, sauvegardes chiffrées vers Backblaze B2, seeds
rechargeables en une commande. Toutes les versions vérifiées le 2026-07-13 et
figées ([research.md](./research.md)).

## Technical Context

**Language/Version**: Rust 1.97.0 (backend) ; Dart 3.12.2 / Flutter 3.44.6 (apps) ; TypeScript 7.0.2 / Node 24 LTS (web)

**Primary Dependencies**: actix-web 4.14, sqlx 0.9 (Postgres), utoipa 5.5 (+ utoipa-actix-web 0.1.2, utoipa-swagger-ui 9.0.2), tokio 1.52, tracing + sentry 0.48.4 ; Nuxt 4.4.8, Pinia 3, @nuxtjs/i18n 10 ; openapi-generator 7.23.0 (`dart-dio`), openapi-typescript 7.13 + openapi-fetch (TS) — détail complet et justifications dans [research.md](./research.md)

**Storage**: PostgreSQL 18.4 (seule vérité durable) ; Redis 8.8 (éphémère uniquement) ; Garage v2.3.0 (objet, API S3 — remplace MinIO, décision validée 2026-07-13) ; Backblaze B2 (sauvegardes externalisées, object lock)

**Testing**: cargo test (unitaires + intégration sqlx sur Postgres réel) ; flutter test (widget/thème) ; vitest ; contrôles CI (diff clients, sqlx prepare --check)

**Target Platform**: dev macOS/Linux (docker compose) ; production = 1 VPS Linux (docker compose, image via GHCR), seul environnement jusqu'à la bêta

**Project Type**: monorepo — web service Rust + 2 apps mobiles Flutter + web Nuxt + infra

**Performance Goals**: env dev complet < 30 min (SC-001) ; seed < 5 min (SC-008) ; merge sur main → prod < 15 min (SC-011) ; `/health` sondé chaque minute, alerte < 2 min (SC-006)

**Constraints**: RPO ≤ 24 h, rétention 30 j (SC-007) ; génération de clients octet-à-octet déterministe (SC-003) ; zéro secret dans le dépôt ; lot VPS+déploiement ≤ 2 jours de tâches sinon dégradation (clarification 2026-07-13)

**Scale/Scope**: développeur solo ; socle sans trafic utilisateur ce cycle ; dimensionné pour Tiassalé au MVP (< 1 000 utilisateurs, 1 VPS)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Portes dérivées de `.specify/memory/constitution.md` (v1.0.0) — vérifiées
avant Phase 0 et re-vérifiées après la conception (Phase 1) :

- [x] **I. Sources de vérité** : `openapi.json` généré par utoipa, clients
  régénérés par script (`scripts/generate-clients.sh`), CI en échec sur diff
  (contracts/ci-cd.md) ; une seule NOUVELLE migration (outbox) ; aucun
  paramètre métier introduit (rien à mettre en zone ce cycle).
- [x] **II. Architecture** : 12 crates de domaine créés vides + crate
  technique `socle` (justifié en Complexity Tracking) ; `ServiceWorkflow`
  défini dans `commandes` sans rien de logistique ni d'implémentation
  (contracts/service-workflow.md) ; Redis absent du code ce cycle (provisionné
  seulement) ; Postgres seule vérité durable ; Garage accédé via API S3
  uniquement.
- [x] **III. Argent** : aucun montant manipulé ce cycle ; le contrat
  `AjustementTarif` (squelette) fixe déjà entiers en unités mineures + ISO 4217.
- [x] **IV. Distances** : aucun calcul de distance ce cycle ; OSRM provisionné
  (dev + prod) ; l'indisponibilité d'OSRM ne bloque ni build ni tests (edge
  case spec).
- [x] **V. Offline & idempotence** : aucune action coursier ce cycle ;
  emplacement de la file offline réservé dans `mefali_core` (structure seule).
- [x] **VI. Événements** : outbox transactionnelle livrée (data-model.md §1,
  contracts/outbox.md) ; `docs/taxonomie-evenements.md` créé (squelette +
  propriétés standard §10.9) — résout le TODO de la constitution ; seul
  événement émis : `socle.ping` (test).
- [x] **VII. Qualité** : tests d'intégration sur TOUTES les transitions du
  cycle de vie outbox ; `cargo sqlx prepare --check` en CI ; chaînes
  utilisateur des écrans/pages minimales en clés i18n fr dès ce cycle.
- [x] **VIII. Sécurité** : `/health` volontairement non authentifié (sonde) —
  justifié en Complexity Tracking ; Swagger UI absente/protégée en production
  (`APP_ENV`) ; aucun autre endpoint ; secrets hors Git (.env VPS + GitHub
  Secrets) ; sauvegardes chiffrées (age), clé privée hors VPS.
- [x] **IX. Périmètre** : le socle conditionne la fiabilité des livraisons
  (CI anti-dérive, outbox, sauvegardes, observabilité) ; AUCUNE UI métier ;
  provisions = emplacements/dossiers seulement (TRX-06/07, composants
  mefali_core, file offline).
- [x] **X. Versions** : recherche du 2026-07-13 ([research.md](./research.md)) ;
  tout figé par lockfiles (Cargo.lock, pubspec.lock ×3, pnpm-lock.yaml,
  rust-toolchain.toml, version Flutter épinglée, images Docker par tag/digest).
  ⚠ La constitution nomme encore MinIO (principes II et X) : amendement PATCH
  via `/speckit.constitution` à passer — signalé, hors du pouvoir de ce plan.
- [x] **XI. Design** : `MefaliTheme` construit depuis `docs/design/tokens.md`
  (vérifié complet le 2026-07-13 — R9) : `ColorScheme.fromSeed(#F97316)`
  ajusté aux tokens, TextTheme Inter (embarquée v4.1), Material Symbols
  Rounded (package, tree-shaking), rayons/espacements des tokens ; aucune
  transposition DOM/CSS ; conventions `.adaptive` encodées dans `mefali_core`.

## Project Structure

### Documentation (this feature)

```text
specs/001-socle-monorepo/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — versions figées + décisions (fait)
├── data-model.md        # Phase 1 — outbox, seeds, config, composants (fait)
├── quickstart.md        # Phase 1 — 9 scénarios de validation S1–S9 (fait)
├── contracts/
│   ├── openapi-health.yaml    # contrat attendu du /health généré
│   ├── outbox.md              # API d'écriture + worker + consommateurs
│   ├── service-workflow.md    # trait ServiceWorkflow (signature provisoire)
│   └── ci-cd.md               # jobs, filtres par chemins, deploy
└── tasks.md             # Phase 2 (/speckit-tasks — pas créé par ce plan)
```

### Source Code (repository root)

```text
rust-toolchain.toml            # Rust 1.97.0 figé
openapi.json                   # GÉNÉRÉ (utoipa) — commité, ≥ /health
scripts/
└── generate-clients.sh        # openapi.json → clients/dart + clients/ts (déterministe)

backend/
├── Cargo.toml                 # workspace (13 crates + api)
├── sqlx.toml                  # preferred-crates = chrono ; config sqlx 0.9
├── migrations/
│   └── 0001_outbox.sql        # schéma outbox + table evenement + index partiel
├── seeds/
│   ├── 00_demo_marker.sql     # structure seeds (contenu ajouté par cycles T1)
│   └── README.md
├── crates/
│   ├── socle/                 # config, pool PG, tracing+Sentry, outbox (écriture,
│   │                          # worker, trait consommateur), types santé
│   ├── commandes/             # trait ServiceWorkflow + EtatCommande (squelettes)
│   └── {zones,comptes,prestataires,qr,tarification,dispatch,
│        coursier,paiements,notifications,avis,metriques}/   # lib.rs vides compilables
└── api/                       # binaire actix : /health, openapi, swagger (dev),
                               # worker outbox ; binaire seed

apps/
├── packages/mefali_core/      # MefaliTheme (M3 depuis tokens.md), tokens.dart,
│   ├── assets/fonts/          # Inter v4.1 .ttf (OFL)
│   └── lib/src/{theme,components/,offline/}   # components/ & offline/ = emplacements vides
├── mefali_client/             # app cliente — écran de démarrage thémé, i18n fr
└── mefali_pro/                # app pro — écran de démarrage thémé, i18n fr

clients/
├── dart/                      # GÉNÉRÉ (openapi-generator 7.23.0, dart-dio)
└── ts/                        # GÉNÉRÉ (openapi-typescript + openapi-fetch)

web/                           # Nuxt 4.4.8 hybride
├── nuxt.config.ts             # routeRules : /admin/** ssr:false ; i18n fr
├── app/assets/tokens.css      # variables CSS depuis docs/design/tokens.md
└── app/pages/{index.vue, admin/index.vue}   # pages minimales

infra/
├── docker-compose.yml         # dev : postgres:18.4, redis:8.8.0-alpine,
│                              # garage (digest épinglé, init layout+buckets), osrm v26.7.3
├── garage/                    # garage.toml (replication_mode=1) + script init
├── osrm/                      # téléchargement extrait Geofabrik CI + préparation MLD
├── vps/                       # provisionnement VPS + compose.prod.yml (+ caddy TLS)
├── backups/                   # backup.sh (pg_dump|age→B2, rclone Garage→B2,
│   │                          # rotation 30 j), restore-test.sh, README (clé age, restauration)
├── shorebird/README.md        # EMPLACEMENT TRX-06 (T4) — vide
├── artci/README.md            # EMPLACEMENT TRX-07 (P1) — vide
└── .env.example               # contrat data-model.md §4, sans valeurs

.github/workflows/
├── backend.yml                # fmt, clippy, test, sqlx prepare --check
├── contrat-clients.yml        # régénération + git diff --exit-code
├── apps.yml                   # analyze + test (core, client, pro)
├── web.yml                    # lint, typecheck, build, test
└── deploy.yml                 # main : image → GHCR → SSH VPS → compose up

docs/taxonomie-evenements.md   # créé : squelette + propriétés standard (§10.9)
```

**Structure Decision** : tout le monorepo est touché — c'est le cycle qui le
crée. Les chemins ci-dessus sont exhaustifs pour ce cycle ; les crates de
domaine restent vides (constitution IX), `socle` est le seul crate avec de la
logique, `api` le seul binaire. Les emplacements TRX-06/07, `components/` et
`offline/` de mefali_core sont des répertoires réservés sans code.

## Livrables détaillés (demandés en entrée de plan)

### Migrations à créer

| Fichier | Contenu |
|---|---|
| `backend/migrations/0001_outbox.sql` | `CREATE SCHEMA outbox` ; table `outbox.evenement` (data-model.md §1) ; index partiel sur `publie_le IS NULL` |

(Aucune autre table : les entités métier appartiennent aux cycles ZON/CPT/…)

### Endpoints (annotations utoipa)

| Méthode/Chemin | Annotation | Auth | Réponse |
|---|---|---|---|
| `GET /health` | `#[utoipa::path]`, schéma `HealthResponse` (`ToSchema`) | non (sonde) | `200 {status:"ok", version}` — contracts/openapi-health.yaml |
| `GET /api-docs/openapi.json` | servi par utoipa-actix-web | dev : libre ; prod : exposé (contrat public) | spec générée |
| `GET /swagger-ui/` | utoipa-swagger-ui | dev seulement (`APP_ENV=production` → absent) | UI |

### Structures & traits exposés aux autres crates

| Crate | Élément | Contrat |
|---|---|---|
| `socle` | `Config` (from env), `init_telemetry()` (tracing + Sentry), `PgPool` helper | — |
| `socle` | `ecrire_evenement(&mut PgTransaction, NouvelEvenement) -> Result<Uuid>` | contracts/outbox.md — prend une TRANSACTION, jamais un pool |
| `socle` | `trait ConsommateurOutbox`, `WorkerOutbox`, `EvenementPublie` | contracts/outbox.md — at-least-once, idempotence par `id` |
| `socle` | `HealthResponse` | contracts/openapi-health.yaml |
| `commandes` | `trait ServiceWorkflow`, `EtatCommande`, `EtatIntermediaire`, `ContexteWorkflow`, `AjustementTarif`, `WorkflowError` (squelettes) | contracts/service-workflow.md — signature provisoire, stabilisée au cycle CMD |

### Événements outbox & métriques émis

- Aucun événement produit (aucun parcours utilisateur ce cycle).
- `socle.ping` : type technique utilisé par les tests d'intégration.
- `docs/taxonomie-evenements.md` créé : conventions de nommage
  (`<entite>.<action>`), propriétés standard (zone, catégorie, rôle, version
  d'app — cadrage §10.9), registre vide.

### Écrans / widgets concernés

| Où | Livrable |
|---|---|
| `mefali_core` | `MefaliTheme.light` : ColorScheme depuis les 14 tokens couleur, TextTheme Inter (display 700 40/1.1 → caption 500 13/1.4), rayons (carte 16, bouton 12, chip plein), grille 8px, cibles ≥ 48 dp, bouton primaire 56 px ; `tokens.dart` (constantes commentées vers tokens.md) ; polices Inter + Material Symbols Rounded ; pas de mode sombre (tokens : MVP clair uniquement) |
| `mefali_client`, `mefali_pro` | Écran de démarrage : logo/nom thémé prouvant thème + police + icônes ; textes en clés i18n fr ; `MaterialApp` branché sur `MefaliTheme` |
| `web/` | `tokens.css` (variables depuis tokens.md), page publique `/` SSR minimale et `/admin` ssr:false minimale, i18n fr — sans bibliothèque UI (choix Nuxt UI/PrimeVue différé au cycle ADM/WEB) |

### Tests d'intégration (constitution VII)

| # | Test | Cible |
|---|---|---|
| T1 | Commit de transaction → événement outbox présent ; rollback → absent | `socle` (Postgres réel) |
| T2 | Worker publie → `publie_le` renseigné ; rejeu du même événement → zéro double effet (consommateur test) | `socle` |
| T3 | Échec de consommateur → `tentatives`++ , `derniere_erreur` renseignée, reprise au lot suivant | `socle` |
| T4 | `GET /health` → 200 + schéma exact ; `openapi.json` généré contient `/health` | `api` |
| T5 | `generate-clients.sh` exécuté 2× → `git diff` vide (déterminisme) | CI + local |
| T6 | Seed sur base vierge puis re-seed → état identique, zéro doublon | binaire `seed` |
| T7 | `flutter test` : `MefaliTheme` reflète tokens.md (primaire #F97316, Inter, rayons 16/12) ; golden de l'écran de démarrage | `mefali_core`, apps |
| T8 | `backup.sh` puis `restore-test.sh` sur Postgres jetable → restauration complète verte | `infra/backups` |
| T9 | Swagger UI absente quand `APP_ENV=production` | `api` |

### Lot VPS + déploiement (garde-fou ≤ 2 jours)

Contenu : script de provisionnement (paquets, Docker, user deploy, UFW),
`compose.prod.yml` (backend GHCR + postgres + redis + garage + osrm + caddy),
Caddy pour TLS automatique (image officielle épinglée par digest à
l'implémentation), `deploy.yml` (build → GHCR → appleboy/ssh-action : pull +
`compose up -d`), chargement des seeds, enregistrement sonde cron-job.org +
Better Stack. Estimation : ~1,5 jour → lot maintenu ; réévalué au découpage
`/speckit-tasks` — si > 2 jours, dégradation prévue par la spec (FR-018 sort
du cycle).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Crate `socle` : 13e crate hors de la liste des 12 domaines (constitution II) | Config, pool, télémétrie, outbox et santé sont transverses : chaque crate de domaine en dépendra dès T1 | Les loger dans `api` inverserait la dépendance (les crates de domaine ne peuvent pas dépendre du binaire) ; les dupliquer dans 12 crates viole DRY et la cohérence de l'outbox |
| `GET /health` non authentifié (constitution VIII « chaque endpoint protégé par rôle ») | La sonde uptime externe (cron-job.org / Better Stack) ne gère pas de secret proprement ; TRX-03 exige la sonde | Réponse limitée à `{status, version}` — aucune donnée sensible ; un jeton dans l'URL de sonde serait un secret de plus à gérer pour une surface nulle |
| Constitution II & X nomment encore MinIO alors que Garage est acté | Décision produit validée le 2026-07-13 (MinIO archivé sans patchs) ; docs produit déjà mises à jour | Éditer la constitution hors `/speckit.constitution` est interdit par la gouvernance — amendement PATCH à passer juste après ce plan |
