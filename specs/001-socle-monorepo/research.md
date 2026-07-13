# Research — 001-socle-monorepo

Phase 0 du plan. Versions vérifiées le **2026-07-13** (constitution X : dernières
stables, vérifiées à l'initialisation, puis FIGÉES par lockfiles ; revue
mensuelle). Sources : crates.io, pub.dev, registre npm, releases GitHub,
sites officiels — vérification web du jour.

## R1 — Toolchain & backend Rust

| Brique | Version figée | Note |
|---|---|---|
| Rust stable | 1.97.0 (2026-07-09) | `rust-toolchain.toml` |
| actix-web | 4.14.0 | |
| sqlx / sqlx-cli | 0.9.0 | **Breaking vs 0.8** : MSRV 1.94 ; `cargo sqlx prepare` au nouveau format « un fichier par requête » ; `sqlx.toml` (préférences de crates, table de migrations) ; installer sqlx-cli SANS `--locked` (Cargo.lock retiré du dépôt, migré vers l'org transact-rs) |
| utoipa | 5.5.0 | pile cohérente vérifiée avec les deux suivants |
| utoipa-actix-web | 0.1.2 | maintenu (monorepo juhaku/utoipa) ; contraintes `utoipa ^5` + `actix-web ^4` couvrent nos versions |
| utoipa-swagger-ui | 9.0.2 | feature `actix-web` |
| tokio | 1.52.3 | |
| tracing / tracing-subscriber / tracing-actix-web | 0.1.44 / 0.3.23 / 0.7.22 | corrélation par requête (request id) |
| sentry + sentry-actix | 0.48.4 (lockstep obligatoire) | plan Sentry Developer gratuit : 5 000 errors/mois, 1 utilisateur — suffisant |
| serde / serde_json | 1.0.228 / 1.0.150 | |
| uuid | 1.23.5 | feature `v7` (outbox : ordre temporel) |
| chrono | 0.4.45 | **Décision** : chrono plutôt que time (écosystème, serde) ; forcer `preferred-crates` dans `sqlx.toml` car les macros sqlx 0.9 peuvent choisir `time` si les deux features sont actives transitivement |
| redis + deadpool-redis | 1.3.0 + 0.23.0 | redis-rs a passé le cap 1.0 en 2026 (API breaking vs 0.x — ignorer les vieux exemples) ; deadpool-redis 0.23 exige `redis ^1.0.3` |
| aws-sdk-s3 | 1.138.0 | vers Garage : `.force_path_style(true)` + checksums `when_required` (les protections d'intégrité par défaut du SDK AWS cassent les S3 tiers non à jour) |
| config | 0.15.25 | retenu vs figment (dormant depuis 2024) |
| cargo-chef | 0.1.77 | layer-caching du build Docker backend |

## R2 — Apps Flutter

| Brique | Version figée | Note |
|---|---|---|
| Flutter stable / Dart | 3.44.6 / 3.12.2 (2026-07-09) | version épinglée (fichier de version + CI) |
| Inter | v4.1 (.ttf, licence SIL OFL 1.1) | zip officiel rsms/inter — embarquée, jamais chargée au runtime (DESIGN §10) |
| material_symbols_icons | 4.2951.0 | **Décision** : package pub.dev (constantes `Symbols.*`, tree-shaking des glyphes) plutôt qu'embarquement manuel de la police variable ~4 Mo ; variante Rounded par défaut |
| flutter_lints | 6.0.0 | |
| dio | 5.10.0 | transport du client généré |
| intl | 0.20.3 | clés i18n fr |
| Shorebird CLI | 1.6.112 — produit actif, standard OTA Flutter ; Free 5 000 patch installs/mois | **HORS PÉRIMÈTRE (TRX-06, T4)** — emplacement seulement, version notée pour référence |
| riverpod 3 / go_router / drift | 3.3.2 / 17.3.0 / 2.34.1 | **Différés** : aucun état ni navigation ni file offline nécessaires ce cycle (écran de démarrage) ; versions notées pour les cycles CPT/CRS ; drift = choix pressenti de la file d'actions offline |

## R3 — Génération des clients (TRX-01)

- **Décision Dart** : openapi-generator CLI **7.23.0** (JAR, Java ≥ 11),
  générateur **`dart-dio`**.
  Rationale : générateur Dart le plus complet/maintenu, cohérent avec dio.
  Alternatives : générateur `dart` basique (limité), wrapper pub.dev
  openapi_generator (couche en plus sans gain en CI).
- **Décision TypeScript** : **openapi-typescript 7.13.0 + openapi-fetch 0.17.0**
  (module Nuxt `nuxt-open-fetch`).
  Rationale : sortie = un fichier de types sans code runtime ni horodatage —
  diff octet-à-octet déterministe, exactement ce qu'exige le contrôle CI
  (SC-003/004) ; DX Nuxt native ($fetch/useFetch typés, SSR-friendly).
  Alternatives : openapi-generator typescript-fetch (verbeux, sensible à la
  version du JAR), @hey-api/openapi-ts (riche mais pré-1.0, sortie instable
  entre versions).
- TRX-01 impose openapi-generator pour Dart ; l'outil TS est libre — conforme.
- Déterminisme Dart : config générateur sans horodatage
  (`hideGenerationTimestamp: true`) — condition du contrôle de diff.

## R4 — Web Nuxt

| Brique | Version figée | Note |
|---|---|---|
| Nuxt | 4.4.8 — Nuxt 4 est bien la majeure stable (pas de Nuxt 5) | hybride : routes publiques SSR, `/admin/**` ssr:false (`routeRules`) |
| Vue / TypeScript | 3.5.39 / **5.9.3** | **Écart assumé** : research initial visait TS 7.0.2 (compilateur natif) mais il casse `@typescript-eslint` 8.63 et `vue-tsc` 2.x → repli sur la dernière 5.x supportée par l'écosystème lint/typecheck |
| Node LTS / pnpm | 24.18.0 (« Krypton ») / 11.12.0 | `packageManager` dans package.json |
| **Tailwind CSS** | **4.3.2** (v4) via `@tailwindcss/vite` (moteur natif `@tailwindcss/oxide`) | **Décision (2026-07-13, demandée)** : framework CSS utilitaire du web, **branché sur les design tokens** (`@theme` référence `app/assets/tokens.css`, source unique) — génère `bg-primary`, `rounded-card`, `text-display`… Ce n'est pas une bibliothèque de composants ; le choix Nuxt UI/PrimeVue reste différé |
| Pinia + @pinia/nuxt | 3.0.4 + 0.11.3 | |
| @nuxtjs/i18n | 10.4.1 | fr dès la première page (constitution VII) |
| vitest / @nuxt/eslint | 4.1.10 / 1.16.0 (ESLint 10.7.0) | |
| Nuxt UI 4.9.0 / PrimeVue 4.5.5 | — | **Différé au cycle ADM/WEB** (cadrage §10.5 laisse le choix ouvert) ; non installés ce cycle |

## R5 — Infra conteneurs

| Brique | Version figée | Note |
|---|---|---|
| PostgreSQL | 18.4 → image `postgres:18.4` | PG 19 encore en beta |
| Redis | 8.8.0 → image `redis:8.8.0-alpine` | tri-licence dont AGPLv3 depuis Redis 8 : usage auto-hébergé libre ; Valkey inutile ici |
| **Garage** | **v2.3.0** (Deuxfleurs, AGPL-3.0), image épinglée **par digest** | **Décision (2026-07-13, validée)** : remplace MinIO — dépôt archivé le 2026-04-25, console amputée depuis mai 2025, plus de patchs sécurité, dernière image sept. 2025. Mono-nœud : `replication_mode = 1`, layout assigné explicitement au démarrage (script d'init dans `infra/`), buckets créés au provisioning, clé d'accès dédiée par usage (backend / job de backup). POC de validation limité aux endpoints S3 dont on dépend : put/get, multipart, **URLs présignées** (upload photos par les apps → décharge le backend). AGPL sans objet (usage non modifié, non redistribué). Alternatives : MinIO épinglé (risque sécurité), SeaweedFS 4.39 (plus lourd que nécessaire). Docs mises à jour (cadrage §10.4/§10/§10.10, user-stories, CLAUDE.md) ; **amendement constitution II & X à passer via /speckit.constitution** |
| OSRM | v26.7.3 → `ghcr.io/project-osrm/osrm-backend:v26.7.3` | extrait Geofabrik `africa/ivory-coast-latest.osm.pbf` (~80 Mo, maj quotidienne) ; pipeline extract (profil car) → partition → customize → `osrm-routed --algorithm mld` |
| Docker Engine / Compose | 29.6.1 / v5.3.1 | |

## R6 — CI/CD GitHub Actions

- Runner : épingler **`ubuntu-24.04`** (= ubuntu-latest actuel ; 26.04 en preview).
- Actions épinglées : checkout@v7, cache@v6, dtolnay/rust-toolchain@stable,
  subosito/flutter-action@v2 (2.23.0), pnpm/action-setup@v6,
  dorny/paths-filter@v4, appleboy/ssh-action@v1 (1.2.5),
  docker/build-push-action@v7, docker/login-action@v4.
- **GHCR** : gratuit pour les images privées d'un compte personnel (préavis
  promis avant toute facturation) — registre retenu pour l'image backend.
- Filtrage par chemins : `paths:` natif par workflow ; contrat détaillé dans
  `contracts/ci-cd.md`.

## R7 — Sauvegardes (TRX-04)

- **Destination** : **Backblaze B2** (clarifié : bucket S3 tiers).
  Rationale : 10 Go gratuits puis ~0,007 $/Go sans minimum, egress gratuit 3×
  le stockage, API S3. Alternatives : Scaleway (free tier supprimé), Wasabi
  (plancher 1 To/90 j — disqualifié).
- **Chiffrement** : **age v1.3.1** (`pg_dump | age -r <clé publique>`) — zéro
  trousseau, scriptable, post-quantique depuis 1.3. GPG rejeté (complexité
  sans gain). La clé PRIVÉE age est conservée HORS du VPS (gestionnaire de
  mots de passe + copie hors-ligne) — documenté avec la procédure de
  restauration.
- **Sync stockage objet** : job **rclone** S3→S3 (Garage → B2).
  **Immutabilité/versioning portés par le bucket externe (object lock B2),
  jamais par Garage.**
- Rétention : 30 jours glissants (clarifié) — règle de cycle de vie côté B2 +
  rotation dans le script.

## R8 — Observabilité (TRX-03)

- Logs : tracing JSON structuré + request id (tracing-actix-web), stdout →
  `docker logs` (pas d'agrégateur ce cycle).
- Erreurs : Sentry SaaS, plan Developer gratuit (5 000 errors/mois).
- **Sonde uptime** : aucun service unique gratuit ne fait ≤ 1 min avec
  alerting complet. **Décision** : **cron-job.org** (check 1×/min, alerte
  email échec/rétablissement) = détecteur < 2 min, doublé de
  **Better Stack free** (3 min, alertes email + push mobile, status page).
  Alternative : UptimeRobot free (5 min) — trop lent pour le critère 2 min.

## R9 — Divers

- Java ≥ 11 requis sur les postes/CI pour openapi-generator CLI.
- `docs/taxonomie-evenements.md` : créé ce cycle (squelette + propriétés
  standard §10.9) — résout le TODO de la constitution.
- tokens.md : vérifié le 2026-07-13 — complet (hex, échelle typo 5 niveaux,
  espacements 8px, rayons, élévation, cibles tactiles) ; FR-001 = revue de
  conformité formelle en première tâche, pas de complément attendu depuis
  docs/design/html/.
