# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

mefali is an African marketplace & logistics super-app targeting Bouake, Cote d'Ivoire. It combines 4 Flutter mobile apps with a Rust backend, deployed on a single Hetzner VPS with Docker Compose.

## Architecture

**Monorepo with two workspaces:**

- **Flutter workspace** (Dart Pub Workspaces + Melos): 4 apps + 4 shared packages
- **Rust workspace** (`server/`): 6 crates in a hexagonal-ish layout

**Flutter apps** (`apps/`): `mefali_b2c` (customer), `mefali_b2b` (merchant ERP), `mefali_livreur` (driver), `mefali_admin` (web dashboard)

**Flutter shared packages** (`packages/`): `mefali_design` (Material 3 theme), `mefali_core` (models/enums), `mefali_api_client` (Dio + WebSocket + Riverpod providers), `mefali_offline` (Drift SQLite + sync queue)

**Rust crates** (`server/crates/`): `api` (Actix Web entry point), `domain` (business logic: orders, merchants, deliveries, wallets, users, disputes, sponsorships), `infrastructure` (DB/Redis/MinIO clients), `payment_provider` (PaymentProvider trait + CinetPay adapter), `notification` (FCM + SMS dual-provider), `common` (AppError, config, types)

**Infrastructure**: PostgreSQL, Redis, MinIO (S3-compatible file storage), Caddy (reverse proxy)

## Build & Dev Commands

### Flutter

```bash
melos bootstrap                     # Install deps for all packages
melos run analyze                   # dart analyze --fatal-infos on all packages
melos run test                      # flutter test on all packages
melos run format                    # dart format --set-exit-if-changed
```

### Rust (run from `server/`)

```bash
cargo build --workspace             # Build all crates
cargo test --workspace              # Run all tests
cargo clippy --workspace            # Lint
cargo fmt --all -- --check          # Format check
cargo run --bin api                 # Start API server (needs .env)
```

Copy `server/.env.example` to `server/.env` for local dev.

## Local Dev Ports

Ports 8080/5432/6379 are occupied on the dev machine. Use:

| Service    | Port |
|------------|------|
| API        | 8090 |
| PostgreSQL | 5433 |
| Redis      | 6380 |
| MinIO      | 9000 |

## Key Architectural Constraints

- **Payment provider must be swappable**: CinetPay is behind a `PaymentProvider` trait. Never hardcode CinetPay outside `server/crates/payment_provider/src/cinetpay.rs`.
- **MinIO for files, no CDN**: Africa lacks edge servers. Use MinIO (S3-compatible). Migration to AWS S3 should be transparent.
- **Offline-first for driver app**: `mefali_livreur` must work without connectivity. SMS fallback with Base64 deep links for critical commands.
- **Target devices**: Transsion (Tecno Spark, Infinix, Itel) with 2GB RAM. APK must stay under 30MB.

## Conventions

- **API format**: REST, `/api/v1/`, `snake_case` everywhere (JSON fields, DB columns, endpoints)
- **IDs**: UUID v4 for all entities
- **Response wrappers**: `{"data": ..., "meta": {...}}` for success, `{"error": {"code": "...", "message": "...", "details": ...}}` for errors
- **Dart linting**: `prefer_single_quotes`, `prefer_relative_imports`, `prefer_const_constructors`, `avoid_print`. Generated files (`*.g.dart`, `*.freezed.dart`) are excluded.
- **Flutter state**: Riverpod with `autoDispose` default, `family` for parameterized providers
- **Rust errors**: `thiserror` for domain errors, mapped to HTTP status in `api` crate
- **Auth**: Phone + SMS OTP only (no passwords). JWT with 15 min access / 7 day refresh tokens.

## Planning Docs

Full requirements and architecture decisions live in `_bmad-output/planning-artifacts/` (PRD, architecture, epics, UX spec). Sprint tracking is in `_bmad-output/implementation-artifacts/sprint-status.yaml`.
