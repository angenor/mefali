# Story 1.2: Initialize Rust Backend Workspace

Status: done

## Story

As a developer,
I want a Cargo workspace with 6 crates,
So that the backend is modular and testable.

## Acceptance Criteria

1. **Given** le répertoire `server/` **When** j'exécute `cargo build --workspace` **Then** les 6 crates compilent sans erreur **And** les dépendances inter-crates sont correctement résolues
2. **Given** le workspace compilé **When** j'exécute `cargo clippy --workspace` **Then** aucun warning n'est émis
3. **Given** le workspace compilé **When** j'exécute `cargo test --workspace` **Then** tous les tests passent (au minimum un test par crate)
4. **Given** le workspace **When** j'inspecte la structure **Then** l'organisation est feature-based (par domaine, pas par couche)

## Tasks / Subtasks

- [x] Task 1: Créer le Cargo workspace root (AC: #1)
  - [x] 1.1 Créer `server/Cargo.toml` workspace avec les 6 membres
  - [x] 1.2 Configurer les profils de compilation (dev/release)
  - [x] 1.3 Configurer les dépendances workspace partagées (versions centralisées)
- [x] Task 2: Créer le crate `common` (AC: #1, #4)
  - [x] 2.1 `server/crates/common/Cargo.toml` avec dépendances minimales
  - [x] 2.2 `server/crates/common/src/lib.rs` — barrel export
  - [x] 2.3 `server/crates/common/src/error.rs` — enum `AppError` implémentant `actix_web::ResponseError`
  - [x] 2.4 `server/crates/common/src/config.rs` — chargement config depuis variables d'environnement
  - [x] 2.5 `server/crates/common/src/types.rs` — types partagés (UUID, DateTime, pagination)
  - [x] 2.6 `server/crates/common/src/response.rs` — wrappers `ApiResponse<T>` et `ApiError`
- [x] Task 3: Créer le crate `infrastructure` (AC: #1, #4)
  - [x] 3.1 `server/crates/infrastructure/Cargo.toml` dépend de `common`
  - [x] 3.2 `server/crates/infrastructure/src/lib.rs` — barrel export
  - [x] 3.3 `server/crates/infrastructure/src/database/mod.rs` — pool PostgreSQL (SQLx)
  - [x] 3.4 `server/crates/infrastructure/src/redis/mod.rs` — client Redis
  - [x] 3.5 `server/crates/infrastructure/src/storage/mod.rs` — client MinIO (S3-compatible via aws-sdk-s3)
- [x] Task 4: Créer le crate `domain` (AC: #1, #4)
  - [x] 4.1 `server/crates/domain/Cargo.toml` dépend de `common`, `infrastructure`
  - [x] 4.2 `server/crates/domain/src/lib.rs` — barrel export
  - [x] 4.3 Créer les sous-modules domaine (structure vide avec mod.rs) :
    - `orders/`, `merchants/`, `deliveries/`, `wallets/`, `users/`, `disputes/`, `sponsorships/`
  - [x] 4.4 Chaque sous-module contient : `mod.rs`, `model.rs`, `service.rs`, `repository.rs` (squelettes)
- [x] Task 5: Créer le crate `payment_provider` (AC: #1, #4)
  - [x] 5.1 `server/crates/payment_provider/Cargo.toml` dépend de `common`
  - [x] 5.2 `server/crates/payment_provider/src/lib.rs` — barrel export
  - [x] 5.3 `server/crates/payment_provider/src/trait.rs` — trait `PaymentProvider` (async)
  - [x] 5.4 `server/crates/payment_provider/src/cinetpay.rs` — struct `CinetPayAdapter` (squelette, implémente le trait)
  - [x] 5.5 `server/crates/payment_provider/src/mock.rs` — struct `MockPaymentProvider` pour tests
- [x] Task 6: Créer le crate `notification` (AC: #1, #4)
  - [x] 6.1 `server/crates/notification/Cargo.toml` dépend de `common`
  - [x] 6.2 `server/crates/notification/src/lib.rs` — barrel export
  - [x] 6.3 `server/crates/notification/src/fcm.rs` — squelette push FCM
  - [x] 6.4 `server/crates/notification/src/sms/mod.rs` — trait `SmsProvider` + router dual-provider avec fallback
  - [x] 6.5 `server/crates/notification/src/deep_link.rs` — squelette encodage Base64 deep link SMS
- [x] Task 7: Créer le crate `api` (AC: #1, #4)
  - [x] 7.1 `server/crates/api/Cargo.toml` dépend de `common`, `domain`, `infrastructure`, `payment_provider`, `notification`
  - [x] 7.2 `server/crates/api/src/main.rs` — point d'entrée Actix Web avec injection web::Data<>
  - [x] 7.3 `server/crates/api/src/routes/mod.rs` — configuration des routes `/api/v1/`
  - [x] 7.4 `server/crates/api/src/routes/health.rs` — endpoint `/health` fonctionnel
  - [x] 7.5 `server/crates/api/src/middleware/mod.rs` — squelettes middleware (auth, logging, rate_limit)
  - [x] 7.6 `server/crates/api/src/extractors/mod.rs` — squelettes extracteurs custom Actix
- [x] Task 8: Créer le répertoire migrations (AC: #1)
  - [x] 8.1 `server/migrations/.gitkeep` — prêt pour Story 1.4
- [x] Task 9: Tests et validation (AC: #2, #3)
  - [x] 9.1 Au moins 1 test unitaire par crate (`#[cfg(test)]` inline)
  - [x] 9.2 `cargo build --workspace` compile sans erreur
  - [x] 9.3 `cargo clippy --workspace` passe sans warning
  - [x] 9.4 `cargo test --workspace` — tous les tests passent
- [x] Task 10: Configuration et documentation (AC: #1)
  - [x] 10.1 `server/.env.example` avec les variables d'environnement documentées
  - [x] 10.2 Rustfmt configuration (`server/rustfmt.toml`) si nécessaire

## Dev Notes

### Architecture obligatoire — 6 crates

```
server/
├── Cargo.toml              (workspace root)
├── .env.example
├── crates/
│   ├── api/                 # Handlers, routes Actix Web — point d'entrée binaire
│   ├── domain/              # Logique métier (feature-based : orders/, users/, wallets/...)
│   ├── infrastructure/      # DB (SQLx), Redis, MinIO (S3)
│   ├── payment_provider/    # Trait PaymentProvider + CinetPayAdapter + MockProvider
│   ├── notification/        # FCM push + SMS dual-provider avec fallback
│   └── common/              # Types partagés, AppError, config, response wrappers
└── migrations/              # SQLx migrations (vide, prêt pour Story 1.4)
```

### Conventions de nommage Rust

| Scope | Convention |
|-------|-----------|
| Structs, Enums, Traits | PascalCase |
| Fonctions, modules, fichiers | snake_case |
| Constantes | SCREAMING_SNAKE_CASE |
| Tables DB | snake_case pluriel |
| Colonnes DB | snake_case |
| Foreign keys | `{table_singulier}_id` |
| Index | `idx_{table}_{cols}` |
| API endpoints | `/api/v1/resource` snake_case |
| JSON fields | snake_case |

### Stack technique exacte

| Composant | Technologie | Notes |
|-----------|-------------|-------|
| Framework API | Actix Web 4.x stable | Async, haute performance |
| Database queries | SQLx | Async natif, compile-time checked |
| Database | PostgreSQL | Latest stable |
| Cache/Queues/PubSub | Redis | Sessions, rate-limit, WebSocket relay |
| Stockage fichiers | MinIO via aws-sdk-s3 | S3-compatible, self-hosted |
| Serialization | serde + serde_json | Standard Rust |
| UUID | uuid (v4) | Jamais d'auto-increment exposé |
| Dates | chrono | ISO 8601 UTC partout |
| Env config | dotenvy | Chargement .env |
| Logging | tracing + tracing-subscriber | Structured JSON logs |

### Pattern d'erreur obligatoire — AppError

```rust
// server/crates/common/src/error.rs
use actix_web::{HttpResponse, ResponseError};
use std::fmt;

#[derive(Debug)]
pub enum AppError {
    NotFound(String),
    BadRequest(String),
    Unauthorized(String),
    Forbidden(String),
    InternalError(String),
    DatabaseError(String),
    ExternalServiceError(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // Implémentation
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        // Retourne le format standard :
        // {"error": {"code": "NOT_FOUND", "message": "...", "details": null}}
    }
}
```

### Pattern de réponse API obligatoire

```rust
// server/crates/common/src/response.rs
use serde::Serialize;

#[derive(Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub data: T,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meta: Option<PaginationMeta>,
}

#[derive(Serialize)]
pub struct PaginationMeta {
    pub page: i64,
    pub per_page: i64,
    pub total: i64,
}

#[derive(Serialize)]
pub struct ApiErrorResponse {
    pub error: ApiErrorDetail,
}

#[derive(Serialize)]
pub struct ApiErrorDetail {
    pub code: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
}
```

### Pattern PaymentProvider — Abstraction obligatoire

```rust
// server/crates/payment_provider/src/trait.rs
use async_trait::async_trait;

#[async_trait]
pub trait PaymentProvider: Send + Sync {
    async fn initiate_payment(&self, request: PaymentRequest) -> Result<PaymentResponse, PaymentError>;
    async fn verify_payment(&self, transaction_id: &str) -> Result<PaymentStatus, PaymentError>;
    async fn initiate_withdrawal(&self, request: WithdrawalRequest) -> Result<WithdrawalResponse, PaymentError>;
}
```

CinetPay est derrière cette abstraction. Facilement remplaçable par un autre agrégateur de paiement (exigence projet).

### Pattern SMS — Dual-provider avec fallback

```rust
// server/crates/notification/src/sms/mod.rs
#[async_trait]
pub trait SmsProvider: Send + Sync {
    async fn send_sms(&self, to: &str, message: &str) -> Result<SmsResult, SmsError>;
}

// Router : tente le provider primaire, bascule sur le fallback en cas d'échec
```

### Injection de dépendances Actix Web

```rust
// server/crates/api/src/main.rs
// Utiliser web::Data<> pour injecter les dépendances partagées :
// - Pool DB (SQLx PgPool)
// - Client Redis
// - Client S3/MinIO
// - PaymentProvider (dyn trait)
// - Config applicative
```

### Organisation domain — Feature-based (PAS par couche)

Chaque domaine dans `crates/domain/src/` contient :
```
orders/
├── mod.rs          # re-exports
├── model.rs        # structs Order, OrderItem, OrderStatus (enum)
├── service.rs      # logique métier
└── repository.rs   # requêtes DB (SQLx)
```

7 sous-modules domaine : `orders`, `merchants`, `deliveries`, `wallets`, `users`, `disputes`, `sponsorships`

### Tests — Minimum requis

- Chaque crate : au moins 1 test `#[cfg(test)]` inline
- `common` : test de sérialisation ApiResponse/ApiError
- `payment_provider` : test avec MockPaymentProvider
- `api` : test endpoint `/health` retourne 200

### Variables d'environnement (.env.example)

```env
# Database
DATABASE_URL=postgres://mefali:mefali@localhost:5433/mefali

# Redis
REDIS_URL=redis://localhost:6380

# MinIO (S3-compatible)
MINIO_ENDPOINT=http://localhost:9000
MINIO_ACCESS_KEY=mefali
MINIO_SECRET_KEY=mefali_secret
MINIO_BUCKET=mefali-files

# API
API_HOST=0.0.0.0
API_PORT=8090

# JWT (pour stories futures)
JWT_SECRET=dev-secret-change-in-prod
JWT_ACCESS_EXPIRY=900
JWT_REFRESH_EXPIRY=604800

# Logging
RUST_LOG=info,api=debug
```

**Ports non-standard** : Les ports 8080/5432/6379 sont occupés sur la machine d'Angenor. Utiliser API_PORT=8090, PG_PORT=5433, REDIS_PORT=6380.

### Project Structure Notes

- Le répertoire `server/` est entièrement nouveau — rien n'existe encore
- Le monorepo Flutter (apps/, packages/) est déjà en place (Story 1.1 complétée)
- La structure finale du projet sera :
  ```
  mefali/
  ├── apps/            (Flutter — Story 1.1 ✅)
  ├── packages/        (Flutter — Story 1.1 ✅)
  ├── server/          (Rust — CETTE STORY)
  │   ├── Cargo.toml
  │   ├── crates/
  │   └── migrations/
  ├── docker-compose.yml  (Story 1.3)
  └── pubspec.yaml     (Flutter workspace root)
  ```

### Anti-patterns à éviter

1. **NE PAS** utiliser Diesel — le projet utilise SQLx (compile-time checked, async natif)
2. **NE PAS** organiser par couche (`models/`, `services/`, `repos/`) — organiser par feature/domaine
3. **NE PAS** exposer d'auto-increment — UUID v4 partout
4. **NE PAS** coder de logique métier — ce sont des squelettes structurels
5. **NE PAS** ajouter de dépendances non listées sans justification
6. **NE PAS** utiliser `unwrap()` dans le code de production — propager les erreurs avec `?` ou `AppError`
7. **NE PAS** hardcoder des valeurs de configuration — tout via variables d'environnement
8. **NE PAS** utiliser `println!` — utiliser `tracing` pour le logging structuré

### References

- [Source: _bmad-output/planning-artifacts/architecture.md] — Structure workspace, stack technique, patterns
- [Source: _bmad-output/planning-artifacts/epics.md#Epic-1] — Story requirements, AC, dépendances
- [Source: _bmad-output/planning-artifacts/prd.md] — NFR performance (p95 < 500ms), sécurité (TLS 1.2+, AES-256)
- [Source: _bmad-output/implementation-artifacts/1-1-initialize-flutter-monorepo.md] — Conventions établies, patterns du monorepo

### Previous Story Intelligence (Story 1.1)

**Leçons clés de Story 1.1 :**
- Vérifier les versions exactes disponibles (Flutter 3.41.2 spécifié mais 3.38.5 utilisé)
- Les fichiers `analysis_options.yaml` par package héritent de la racine
- Les tests squelettes doivent importer le package pour valider la résolution compile-time
- Le `.gitignore` doit être soigneusement configuré (root pubspec.lock tracked)
- Les corrections de code review doivent être appliquées immédiatement (font sizes, imports)

**Patterns établis à respecter :**
- Organisation feature-based (pas par couche)
- Barrel exports dans chaque module
- Tests minimaux mais fonctionnels dès le départ
- Conventions de nommage strictes (voir tableau ci-dessus)

### Git Intelligence

- Dernier commit : `e907976` — corrections post-review Story 1.1
- Le workspace Flutter est stable et opérationnel
- Le répertoire `server/` n'existe pas dans le repo actuel

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Build initial : 3 warnings (unused imports) corrigés — `std::fmt` dans error.rs, `Serialize` dans types.rs, `std::io` dans deep_link.rs
- `env::remove_var` unsafe en Rust 1.93 — test config réécrit sans manipulation d'env vars
- `tokio` ajouté en dev-dependency pour notification et payment_provider (tests async)

### Completion Notes List

- Workspace Cargo avec 6 crates compilé, 0 warning clippy, 30 tests passent
- AppError implémente ResponseError avec format JSON standard `{error: {code, message, details}}`
- ApiResponse<T> avec pagination optionnelle et skip_serializing_if
- PaymentProvider trait async avec CinetPayAdapter (squelette) et MockPaymentProvider (fonctionnel)
- SmsProvider trait avec SmsRouter dual-provider fallback (testé avec mocks)
- 7 sous-modules domaine feature-based avec model/service/repository squelettes
- Endpoint /api/v1/health fonctionnel avec test d'intégration Actix
- Deep link Base64 encode/decode pour SMS offline
- Versions workspace centralisées dans Cargo.toml racine
- .env.example avec ports alternatifs (8090/5433/6380)

### Change Log

- 2026-03-16: Implémentation complète Story 1.2 — Cargo workspace 6 crates, 30 tests, 0 warning
- 2026-03-16: Code review fixes — `cargo fmt`, `Order.total` f64→i64, `Wallet.balance` f64→i64, `Order.driver_id` → Option<Id>, config parse warnings via tracing

### File List

- server/Cargo.toml
- server/.env.example
- server/rustfmt.toml
- server/migrations/.gitkeep
- server/crates/common/Cargo.toml
- server/crates/common/src/lib.rs
- server/crates/common/src/error.rs
- server/crates/common/src/config.rs
- server/crates/common/src/types.rs
- server/crates/common/src/response.rs
- server/crates/infrastructure/Cargo.toml
- server/crates/infrastructure/src/lib.rs
- server/crates/infrastructure/src/database/mod.rs
- server/crates/infrastructure/src/redis/mod.rs
- server/crates/infrastructure/src/storage/mod.rs
- server/crates/domain/Cargo.toml
- server/crates/domain/src/lib.rs
- server/crates/domain/src/orders/mod.rs
- server/crates/domain/src/orders/model.rs
- server/crates/domain/src/orders/service.rs
- server/crates/domain/src/orders/repository.rs
- server/crates/domain/src/merchants/mod.rs
- server/crates/domain/src/merchants/model.rs
- server/crates/domain/src/merchants/service.rs
- server/crates/domain/src/merchants/repository.rs
- server/crates/domain/src/deliveries/mod.rs
- server/crates/domain/src/deliveries/model.rs
- server/crates/domain/src/deliveries/service.rs
- server/crates/domain/src/deliveries/repository.rs
- server/crates/domain/src/wallets/mod.rs
- server/crates/domain/src/wallets/model.rs
- server/crates/domain/src/wallets/service.rs
- server/crates/domain/src/wallets/repository.rs
- server/crates/domain/src/users/mod.rs
- server/crates/domain/src/users/model.rs
- server/crates/domain/src/users/service.rs
- server/crates/domain/src/users/repository.rs
- server/crates/domain/src/disputes/mod.rs
- server/crates/domain/src/disputes/model.rs
- server/crates/domain/src/disputes/service.rs
- server/crates/domain/src/disputes/repository.rs
- server/crates/domain/src/sponsorships/mod.rs
- server/crates/domain/src/sponsorships/model.rs
- server/crates/domain/src/sponsorships/service.rs
- server/crates/domain/src/sponsorships/repository.rs
- server/crates/payment_provider/Cargo.toml
- server/crates/payment_provider/src/lib.rs
- server/crates/payment_provider/src/provider.rs
- server/crates/payment_provider/src/cinetpay.rs
- server/crates/payment_provider/src/mock.rs
- server/crates/notification/Cargo.toml
- server/crates/notification/src/lib.rs
- server/crates/notification/src/fcm.rs
- server/crates/notification/src/sms/mod.rs
- server/crates/notification/src/deep_link.rs
- server/crates/api/Cargo.toml
- server/crates/api/src/main.rs
- server/crates/api/src/routes/mod.rs
- server/crates/api/src/routes/health.rs
- server/crates/api/src/middleware/mod.rs
- server/crates/api/src/extractors/mod.rs
