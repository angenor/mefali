---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
workflow_completed: true
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/ux-design-specification.md'
  - '_bmad-output/planning-artifacts/product-brief-mefali-2026-03-15.md'
  - '_bmad-output/planning-artifacts/research/market-everything-app-research-2026-03-15.md'
workflowType: 'architecture'
project_name: 'mefali'
user_name: 'Angenor'
date: '2026-03-16'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**59 FRs en 8 domaines :**

| Domaine | FRs | Implications architecturales |
|---------|-----|----------------------------|
| Compte & Auth (7) | FR1-FR7 | Auth multi-type (5 rôles), KYC avec stockage documents |
| Catalogue & Commerce (10) | FR8-FR17 | CRUD produits avec images, commandes temps réel, 4 états vendeur auto-pause |
| Livraison & Logistique (11) | FR18-FR28 | GPS tracking temps réel, SMS fallback offline, assignation proximité, sync queue |
| Paiements & Wallet (9) | FR29-FR37 | Escrow lifecycle, wallet interne, agrégateur abstrait (swappable), réconciliation |
| Communication (5) | FR38-FR42 | Push (FCM), SMS dual gateway, appels directs, deep links |
| ERP / B2B (4) | FR43-FR46 | Dashboard analytics, alertes stock, historique transactions |
| Admin & Ops (9) | FR47-FR55 | Onboarding guidé, KYC validation, litiges timeline, config zones/pricing par ville |
| Parrainage (3) | FR56-FR58 | Arbre parrainage (max 3), responsabilité partagée |

**30 NFRs → drivers architecturaux :**

| Catégorie | NFRs clés | Impact |
|-----------|----------|-------|
| Performance | API p95 < 500ms, cold start < 3s, APK < 30MB | Backend Rust performant, Flutter optimisé |
| Security | TLS 1.2+, AES-256 KYC, token rotation, audit logs | Chiffrement at rest, auth service, APDP |
| Scalability | 500 → 5 000 concurrents, partitionnement ville | DB partitionable, services stateless |
| Reliability | 99% uptime, paiement < 5 min, 0 perte offline | Queue sync persistante, dual SMS, retry |
| Integration | Payment swappable, SMS dual, Maps, FCM | Adapter pattern chaque intégration |

### Scale & Complexity

| Indicateur | Évaluation |
|-----------|-----------|
| **Complexité** | **HIGH** |
| Domaine | Full-stack mobile + backend + intégrations |
| Apps clientes | 4 (Flutter monorepo) |
| Types utilisateurs | 5 (client, marchand, livreur, agent, admin) |
| Real-time | GPS tracking 10s, push notifications |
| Transactions financières | Escrow, wallet interne, réconciliation |
| Offline | Architecture primaire (livreurs) |
| Intégrations | 4 (payment, SMS, Maps, FCM) |

### Technical Constraints & Dependencies

| Contrainte | Impact |
|-----------|--------|
| Flutter monorepo, 4 apps | Packages partagés : `mefali_design`, `mefali_core`, `mefali_api_client` |
| Actix Web (Rust) | API haute performance |
| PostgreSQL + Redis | DB principale + cache/queues/sessions |
| Smartphones 2GB RAM | APK < 30MB, images compressées, pas de background heavy |
| Réseau 3G instable | Offline-first, SMS fallback, sync opportuniste |
| Agrégateur paiement swappable | PaymentProvider interface, adapter pattern |
| 4 devs, 3 mois | Monolithe modulaire, pas de microservices |

### Cross-Cutting Concerns

| Concern | Composants affectés |
|---------|-------------------|
| Authentication multi-type (5 rôles) | Toutes apps + API |
| Offline sync (queue persistante) | Livreur (critique), B2B (important) |
| Payment lifecycle (escrow abstrait) | API + B2C/B2B/Livreur |
| Notification routing (push → SMS fallback) | Toutes apps + backend |
| Audit logging (APDP) | API + Admin |
| City configuration (zones, pricing) | API + Admin + Apps |
| Image pipeline (upload → WebP → CDN) | API + B2B + B2C |

## Starter Template Evaluation

### Primary Technology Domain

**Dual-domain : Mobile (Flutter) + Backend (Rust)**

### Technical Stack

| Aspect | Choix | Version |
|--------|-------|---------|
| Frontend | Flutter (Dart) | 3.41.2 stable |
| Monorepo | Melos + Pub Workspaces | Dart ≥ 3.10 |
| Backend API | Actix Web (Rust) | 4.x stable |
| Base de données | PostgreSQL | Latest stable |
| Cache/Queues | Redis | Latest stable |
| Deployment | VPS Hetzner (~30€/mois) | — |

### Starter 1 : Flutter Monorepo (Melos)

**Structure :**

```
mefali/
├── melos.yaml
├── pubspec.yaml
├── apps/
│   ├── mefali_b2c/
│   ├── mefali_b2b/
│   ├── mefali_livreur/
│   └── mefali_admin/
├── packages/
│   ├── mefali_design/          ← Thème, composants custom
│   ├── mefali_core/            ← Models, services, logique métier
│   ├── mefali_api_client/      ← Client HTTP, auth, retry
│   └── mefali_offline/         ← Sync, cache, queue
└── server/
```

### Starter 2 : Actix Web Backend (Cargo Workspace)

**Structure :**

```
server/
├── Cargo.toml
├── crates/
│   ├── api/                    ← Handlers, routes Actix Web
│   ├── domain/                 ← Logique métier (orders, users, wallet)
│   ├── infrastructure/         ← DB, Redis, intégrations
│   ├── payment_provider/       ← Interface + adapters (CinetPay, future...)
│   ├── notification/           ← Push (FCM) + SMS (dual provider)
│   └── common/                 ← Types partagés, erreurs, config
├── migrations/
└── .env
```

### Decisions Made by Starters

| Décision | Flutter (Melos) | Rust (Cargo Workspace) |
|----------|----------------|----------------------|
| Structure | apps/ + packages/ | crates/ modulaire |
| Dépendances | Pub + Melos bootstrap | Cargo workspace members |
| Code partagé | packages/mefali_* | crates/common, domain |
| Tests | `melos run test` | `cargo test --workspace` |
| Linting | `melos run analyze` | `cargo clippy --workspace` |

**Note :** L'initialisation monorepo = première story d'implémentation.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical (bloquent l'implémentation) :**
- Data layer : PostgreSQL + SQLx + Drift
- Auth : JWT multi-rôle avec OTP
- Real-time : WebSocket (GPS tracking) avec reconnexion auto
- Payment : Interface abstraite + CinetPay adapter (swappable)
- State management : Riverpod
- File storage : MinIO (S3-compatible, self-hosted)

**Important (shaping) :** API REST + versioning, offline sync Drift + queue, notification FCM + SMS dual, image pipeline WebP + MinIO

**Deferred (post-MVP) :** FastAPI Python (IA), microservices split, GraphQL, CDN, migration S3

---

### Data Architecture

| Décision | Choix | Rationale |
|----------|-------|-----------|
| Base de données | PostgreSQL | Relationnel, ACID, partitionnable par ville |
| ORM/Query (Rust) | SQLx | Async natif, compile-time checked queries |
| Migrations | SQLx migrations | Intégré, versionnées, réversibles |
| Cache | Redis | Sessions, rate limiting, queues, PubSub WebSocket |
| Local storage (Flutter) | **Drift (SQLite)** | SQL typé compile-safe, données relationnelles ERP |
| File storage | **MinIO** (S3-compatible) | Self-hosted, API S3 → migration S3 transparente quand nécessaire |
| Modèle de données | Normalisé, partitionné par ville | Prépare expansion multi-villes |

**Schéma DB — entités principales :**

```
users (id, role, phone, name, city_id, created_at)
merchants (id, user_id, name, address, status_4states, city_id)
products (id, merchant_id, name, price, stock, photo_url)
orders (id, customer_id, merchant_id, driver_id, status, payment_type, total, city_id)
order_items (id, order_id, product_id, quantity, price)
wallets (id, user_id, balance, updated_at)
wallet_transactions (id, wallet_id, amount, type, reference, created_at)
deliveries (id, order_id, driver_id, status, lat, lng, updated_at)
disputes (id, order_id, reporter_id, status, resolution, created_at)
sponsorships (id, sponsor_id, sponsored_id, status, created_at)
city_config (id, city_name, delivery_multiplier, zones_geojson)
kyc_documents (id, user_id, type, encrypted_path, verified_by, status)
```

---

### Authentication & Security

| Décision | Choix | Rationale |
|----------|-------|-----------|
| Méthode auth | JWT (access 15 min + refresh 7 jours, rotation) | Stateless, scalable |
| Multi-rôle | Claim `role` dans JWT (client/marchand/livreur/agent/admin) | 1 endpoint auth |
| Inscription | Phone + SMS OTP uniquement | 0 email, 0 mot de passe |
| KYC storage | MinIO bucket séparé, chiffré AES-256 | Documents APDP sensibles |
| Rate limiting | Redis-based, par IP + par user | Protection abus |
| TLS | 1.2+ sur toutes les API | NFR8 |
| Audit logs | Actions admin/agent loguées avec timestamp | APDP — NFR13 |

---

### API & Communication Patterns

| Décision | Choix | Rationale |
|----------|-------|-----------|
| Style API | REST (JSON) | Simple, Flutter HTTP natif |
| Versioning | URL prefix `/api/v1/` | Coexistence versions |
| Error format | `{error, code, message, details}` | Parseable Flutter, loggable |
| Real-time GPS | **WebSocket** + reconnexion expo backoff | Updates instantanées tracking |
| WebSocket backend | Actix WebSocket + Redis PubSub | Channel par `delivery:{order_id}` |
| Push | FCM | Standard Flutter, gratuit |
| SMS | Dual provider + failover automatique | NFR28 — 0 commande perdue |

**WebSocket architecture :**
```
Client Flutter ←→ WebSocket (Actix) ←→ Redis PubSub
                                        ↑
                              Driver publie position /10s
                              channel "delivery:{order_id}"
```

---

### Frontend Architecture (Flutter)

| Décision | Choix | Rationale |
|----------|-------|-----------|
| State management | **Riverpod** | Moderne, compile-safe, bon pour monorepo |
| Navigation | go_router | Déclaratif, deep links, auth guard |
| Local DB | **Drift (SQLite)** | SQL typé, données relationnelles ERP |
| HTTP client | Dio | Interceptors auth, retry, logging |
| Image cache | cached_network_image | Cache disque, placeholder, WebP |
| Offline sync | Custom : Drift queue → sync service → API | Queue persistante SQLite |
| Maps | google_maps_flutter | Cache offline tuiles |
| Push | firebase_messaging | Standard FCM |
| WebSocket | web_socket_channel | Natif Dart, compatible Riverpod |

**Offline sync pattern :**
```
Action → Drift (local) → SyncQueue table
                              ↓
               Connectivity change detected
                              ↓
               SyncService → POST API
                              ↓
               Success → mark synced | Failure → retry
```

---

### Infrastructure & Deployment

| Décision | Choix | Rationale |
|----------|-------|-----------|
| Serveur | VPS Hetzner (~30€/mois) | Bon rapport qualité/prix |
| Containerisation | Docker Compose | Simple pour MVP, 1 serveur |
| Reverse proxy | Caddy | HTTPS auto (Let's Encrypt), HTTP/2 |
| File storage | **MinIO** (Docker service) | S3-compatible, self-hosted, migration S3 transparente |
| CI/CD | GitHub Actions | Gratuit, workflows Flutter + Rust |
| Monitoring MVP | Health checks + structured logs JSON | Minimum viable |
| Backups | pg_dump quotidien → MinIO bucket externe | NFR25 — rétention 30 jours |
| SSL | Let's Encrypt via Caddy | Gratuit, auto-renouvelé |

**Docker Compose MVP (ports configurables via .env) :**

```yaml
services:
  api:        # Actix Web — container:8080 → host:${API_PORT:-8090}
  postgres:   # PostgreSQL — container:5432 → host:${PG_PORT:-5433}
  redis:      # Redis — container:6379 → host:${REDIS_PORT:-6380}
  minio:      # MinIO — container:9000 → host:${MINIO_PORT:-9000}
  caddy:      # Reverse proxy — ports 80/443
```

> Les ports host sont configurables via `.env` (8080/5432/6379 occupés sur la machine dev d'Angenor). Les ports container restent standard.

---

### Decision Impact — Séquence d'implémentation

1. Setup monorepo (Melos + Cargo workspace)
2. Docker Compose (Caddy + PostgreSQL + Redis + MinIO)
3. Auth service (JWT + OTP) — débloque toutes les apps
4. Models de données + migrations SQLx
5. API REST core (CRUD merchants, products, orders)
6. Package mefali_api_client (Dio + Riverpod)
7. Package mefali_offline (Drift + SyncQueue)
8. Package mefali_design (thème + composants custom)
9. Apps en parallèle (4 devs)

**Dépendances cross-composants :**

| Composant | Dépend de |
|-----------|----------|
| Toutes apps Flutter | mefali_core, mefali_api_client, mefali_design |
| Offline sync | Drift (mefali_offline) + API (mefali_api_client) |
| GPS tracking | WebSocket server (Actix) + Redis PubSub |
| Paiements | PaymentProvider interface + adapter |
| Notifications | FCM + SMS gateway (API) |
| Images | MinIO (S3 API) + cached_network_image |

## Implementation Patterns & Consistency Rules

### Naming Patterns

**Database :** snake_case pluriel (tables), snake_case (colonnes), `{table_singulier}_id` (FK), `idx_{table}_{cols}` (index)

**API REST :** snake_case partout — endpoints (`/api/v1/merchants`), JSON fields (`user_id`), query params (`?city_id=1`)

**Rust :** PascalCase (structs), snake_case (fonctions, modules, fichiers), SCREAMING_SNAKE (constantes)

**Dart/Flutter :** PascalCase (classes/widgets), camelCase (variables/fonctions), snake_case (fichiers, packages). Riverpod providers = camelCase + `Provider` suffix.

**Dart ↔ API :** `@JsonSerializable(fieldRename: FieldRename.snake)` — Dart reçoit snake_case, mappe en camelCase interne automatiquement.

### Structure Patterns

**Organisation par feature/domaine (jamais par type) :**

```
# Rust: crates/domain/src/orders/
mod.rs, model.rs, service.rs, repository.rs

# Flutter: packages/mefali_core/lib/orders/
order_model.dart, order_service.dart, order_provider.dart
```

**Tests :** Rust = `#[cfg(test)]` inline (unit) + `tests/` (integration). Flutter = `test/` co-localisé par package.

### Format Patterns

**API Response :**
```json
{"data": {...}, "meta": {"page": 1, "total": 42}}  // succès
{"error": {"code": "ORDER_NOT_FOUND", "message": "...", "details": null}}  // erreur
```

**Règles :** IDs = UUID v4 (pas d'auto-increment exposé). Dates = ISO 8601 UTC. Pagination = `?page=1&per_page=20`. Nulls omis du JSON.

### Communication Patterns

**Riverpod :** `autoDispose` par défaut. `family` pour providers paramétrés. Pas de providers mutables sans `StateNotifier`. Erreurs via `AsyncValue.when()`.

**WebSocket events :** `{"event": "delivery.location_update", "data": {...}}` — naming `{domain}.{action}` snake_case.

### Process Patterns

**Error handling :** Flutter = `ApiException(code, message)` + Riverpod `AsyncValue`. Rust = enum `AppError` implémentant `ResponseError`.

**Loading :** Skeleton screens (jamais spinner seul). `AsyncValue.loading` de Riverpod.

**Retry :** API = 3 retries expo backoff (1s, 2s, 4s). WebSocket = expo backoff max 30s. Payment = 0 retry auto (idempotency key, retry manuel).

**Validation :** Double validation obligatoire (frontend inline + backend toujours).

### Enforcement

**Agents IA DOIVENT :** snake_case JSON/DB/API, organisation par feature, wrapper `{data}/{error}`, autoDispose Riverpod, UUID uniquement, double validation, ISO 8601 UTC, fichiers snake_case.

## Project Structure & Boundaries

### Complete Directory Structure

```
mefali/
├── .github/workflows/              # CI/CD
│   ├── flutter_ci.yml
│   └── rust_ci.yml
├── .env.example
├── docker-compose.yml              # Dev (ports configurables)
├── docker-compose.prod.yml
├── melos.yaml
├── pubspec.yaml
│
├── apps/
│   ├── mefali_b2c/lib/features/    # Auth, Home, Restaurant, Order, Profile
│   ├── mefali_b2b/lib/features/    # Auth, Orders, Catalog, Dashboard, Settings
│   ├── mefali_livreur/lib/features/# Auth, Delivery, Wallet, Map, Profile
│   └── mefali_admin/lib/features/  # Auth, Dashboard, Merchants, Drivers, Disputes, Config
│
├── packages/
│   ├── mefali_design/lib/          # theme/ + components/ (10 custom)
│   ├── mefali_core/lib/            # models/ + enums/ + utils/
│   ├── mefali_api_client/lib/      # dio_client + websocket + endpoints/ + providers/
│   └── mefali_offline/lib/         # database/ (Drift) + sync/ + connectivity/
│
└── server/
    ├── crates/
    │   ├── api/src/                 # routes/ + middleware/ + extractors/
    │   ├── domain/src/              # orders/ merchants/ deliveries/ wallets/ users/ disputes/ sponsorships/
    │   ├── infrastructure/src/      # database/ + redis/ + storage/ (MinIO)
    │   ├── payment_provider/src/    # trait.rs + cinetpay.rs + mock.rs
    │   ├── notification/src/        # fcm.rs + sms/ (dual provider) + deep_link.rs
    │   └── common/src/              # error.rs + config.rs + types.rs + response.rs
    └── migrations/                  # 001-009 SQLx migrations
```

### Requirements to Structure Mapping

| FR Domain | Flutter | Rust |
|-----------|---------|------|
| Auth (FR1-7) | `apps/*/features/auth/` | `crates/api/routes/auth.rs` + `crates/domain/users/` |
| Catalogue (FR8-17) | `mefali_b2b/catalog/` + `mefali_b2c/restaurant/` | `crates/domain/merchants/` + `orders/` |
| Livraison (FR18-28) | `mefali_livreur/delivery/` + `mefali_offline/sync/` | `crates/domain/deliveries/` + `routes/websocket.rs` |
| Paiements (FR29-37) | `*/wallet/` + `mefali_api_client/wallets_api.dart` | `crates/domain/wallets/` + `crates/payment_provider/` |
| Communication (FR38-42) | `mefali_api_client/websocket_client.dart` | `crates/notification/` |
| ERP (FR43-46) | `mefali_b2b/dashboard/` | `crates/domain/merchants/` (analytics) |
| Admin (FR47-55) | `mefali_admin/features/` | `crates/api/routes/admin.rs` + `crates/domain/disputes/` |
| Parrainage (FR56-58) | `mefali_livreur/profile/` | `crates/domain/sponsorships/` |

### Integration Boundaries

**Payment Provider (swappable) :** `trait PaymentProvider` → `CinetPayAdapter` (MVP) → futur adapters sans toucher au code métier

**SMS Gateway (dual failover) :** `trait SmsProvider` → primary + fallback → router tente primary puis bascule

**Offline Sync :** Drift SyncQueue locale → SyncService POST quand connecté → last-write-wins avec timestamp serveur

## Architecture Validation Results

### Coherence ✅

- Flutter 3.41 + Riverpod + Drift + Dio + go_router — compatibles ✅
- Actix Web 4.x + SQLx + Redis — cohérent, async natif ✅
- WebSocket chaîne complète (Actix → Redis PubSub → Flutter) ✅
- MinIO S3-compatible → Rust aws-sdk-s3 → Flutter cached_network_image ✅
- snake_case unifié DB → API → JSON → Dart ✅
- Adapter pattern cohérent : Payment, SMS, Storage ✅
- **0 contradiction détectée**

### Requirements Coverage ✅

- 59/59 FRs mappés à des composants architecturaux
- 30/30 NFRs couverts (performance Rust, security JWT/AES, scalability partitioning, reliability offline/dual SMS)

### Gap Analysis

**Critical : 0**

**Minor (non-bloquants, résolvables en implémentation) :**
1. Escrow state machine (enum `EscrowStatus`) à formaliser dans domain/wallets
2. Logging strategy à préciser (niveaux, rotation, rétention)
3. WebSocket reconnect pattern à implémenter dans websocket_client.dart

### Architecture Readiness

| Critère | Score |
|---------|-------|
| Décisions complètes | ✅ 100% |
| Patterns de consistance | ✅ Complet |
| Structure projet avec mapping FR | ✅ Complet |
| Intégrations abstraites swappable | ✅ Payment + SMS + Storage |
| Offline-first documenté | ✅ Drift + SyncQueue |
| **Prêt pour implémentation** | **✅ Oui** |
