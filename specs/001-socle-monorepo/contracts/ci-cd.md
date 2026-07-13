# Contrat — CI/CD (`.github/workflows/`)

Interface du socle vis-à-vis de tous les cycles suivants : ce qui casse le
build et ce qui part en production. FR-009, FR-011, FR-018 ; SC-004, SC-010,
SC-011.

## Déclencheurs et filtrage par chemins (FR-009)

`on: push` (main) et `on: pull_request`. Jobs conditionnés par chemins
(filtre natif `paths:` par workflow, ou `dorny/paths-filter` si un workflow
unique s'impose) :

| Job | Chemins déclencheurs | Contenu |
|---|---|---|
| `backend` | `backend/**`, `openapi.json`, workflows | `cargo fmt --check`, `clippy -D warnings`, `cargo test`, vérif `cargo sqlx prepare` (`--check`) avec Postgres de service |
| `contrat-clients` | `backend/**`, `openapi.json`, `clients/**`, workflows | Regénère `openapi.json` depuis le binaire + clients Dart/TS, puis `git diff --exit-code` — **tout diff = échec** (SC-004) |
| `apps` | `apps/**`, `clients/dart/**`, workflows | `flutter analyze`, `flutter test` (mefali_core, mefali_client, mefali_pro) |
| `web` | `web/**`, `clients/ts/**`, workflows | lint, typecheck, `pnpm build`, tests |
| `deploy` | `main` uniquement, après succès des jobs déclenchés | Build image Docker backend → push GHCR → SSH VPS : pull + `docker compose up -d` (FR-018) |

## Règles contractuelles

1. **Le contrôle de dérive ne peut pas être court-circuité** : `contrat-clients`
   écoute à la fois `backend/**` ET `clients/**` — un changement de l'un sans
   l'autre échoue (edge case de la spec : le filtrage ne masque jamais ce
   contrôle).
2. **Génération déterministe** : la génération des clients est reproductible
   (deux exécutions successives = zéro diff) — horodatages et métadonnées de
   génération neutralisés dans la config openapi-generator, sinon le contrôle
   produit des faux positifs.
3. **Zéro secret dans le dépôt** (US7) : secrets de déploiement en GitHub
   Secrets (clé SSH, hôte) ; secrets applicatifs dans le `.env` du VPS.
4. **`deploy` ne tourne que sur `main`** et seulement si les jobs CI déclenchés
   sont verts ; visible en prod < 15 min (SC-011). Pas de staging, pas de
   blue-green (clarification 2026-07-13).
5. **Toolchains figées** : les versions installées en CI proviennent des mêmes
   sources que le dev (rust-toolchain.toml, `.fvmrc`/version Flutter épinglée,
   `packageManager` pnpm) — jamais de « latest » flottant en CI.

## Sortie de production attendue

Après merge sur `main` : GHCR contient l'image taguée du commit ; le VPS sert
cette image ; `GET /health` répond `200 {status:"ok", version}` ; Swagger UI
absente/protégée (`APP_ENV=production`).
