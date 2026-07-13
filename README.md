# Mefali

Plateforme de services de proximité (Côte d'Ivoire). Premier vertical MVP :
livraison restauration + courses chez vendeurs agréés, à Tiassalé.

Monorepo : backend Rust (Actix), apps Flutter (client + pro), web Nuxt 4,
infra docker-compose. Développeur solo. Langue du projet : français.

## Prérequis (poste de développement)

Versions figées le 2026-07-13 (voir `specs/001-socle-monorepo/research.md`) :

| Outil | Version | Installation |
|---|---|---|
| Docker Desktop | Engine 29 / Compose v2 | <https://docs.docker.com/desktop/> |
| Rust (rustup) | 1.97.0 (épinglé par `rust-toolchain.toml`) | <https://rustup.rs> — la bonne version s'installe automatiquement |
| sqlx-cli | 0.9.0 | `cargo install sqlx-cli@0.9.0 --no-default-features --features native-tls,postgres` (sans `--locked`) |
| Flutter (stable) | 3.44.6 / Dart 3.12.2 | <https://docs.flutter.dev/get-started/install> |
| Node LTS + pnpm | 24 LTS / 11.x | `corepack enable` (pnpm épinglé par `packageManager` dans `web/package.json`) |
| Java | ≥ 11 (JRE/JDK) | requis par openapi-generator CLI (génération du client Dart) |

## Démarrage rapide

```bash
# 1. Environnement de développement (Postgres, Redis, Garage, OSRM)
docker compose -f infra/docker-compose.yml up -d

# 2. Backend : migrations + build + tests
cd backend
cp ../infra/.env.example .env        # puis renseigner DATABASE_URL etc.
cargo sqlx migrate run
cargo build && cargo test

# 3. Apps Flutter
cd apps/packages/mefali_core && flutter test
cd ../../mefali_client && flutter test && flutter run
cd ../mefali_pro && flutter test

# 4. Web Nuxt
cd web && pnpm install --frozen-lockfile && pnpm dev
```

Validation complète : `specs/001-socle-monorepo/quickstart.md` (scénarios S1→S9).

## Structure

```text
backend/   workspace Rust : crates de domaine + crate socle + binaire api
apps/      Flutter : mefali_client, mefali_pro, packages/mefali_core (thème M3)
clients/   clients API GÉNÉRÉS (dart, ts) — ne jamais éditer à la main
web/        Nuxt 4 hybride (public SSR, /admin ssr:false)
infra/      docker-compose dev, provisionnement VPS, sauvegardes
scripts/    generate-clients.sh (openapi.json → clients)
specs/      cycles Spec-Kit (spécifications, plans, tâches)
docs/       cadrage produit, user stories, design (tokens)
```

## Sources de vérité

- Produit : `docs/cadrage-v5.md`, `docs/user-stories-v2.md`
- Principes : `.specify/memory/constitution.md`
- Design : `docs/design/tokens.md`
- Contrat API : `openapi.json` (généré par utoipa) → clients `clients/`
- Schéma : migrations sqlx `backend/migrations/`

## Commandes utiles

| Besoin | Commande |
|---|---|
| Régénérer le contrat + clients | `./scripts/generate-clients.sh` |
| Vérifier le cache sqlx | `cargo sqlx prepare --check` (dans `backend/`) |
| Recharger le jeu de démo | `cargo run -p api --bin seed` (dans `backend/`) |
| Exporter openapi.json | `cargo run -p api --bin export-openapi` (dans `backend/`) |
