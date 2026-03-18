---
title: 'Backend Integration Test Infrastructure'
slug: 'backend-integration-test-infrastructure'
created: '2026-03-18'
status: 'completed'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['sqlx 0.8 (#[sqlx::test])', 'actix_web::test', 'PostgreSQL 5433', 'Rust workspace']
files_to_modify:
  - 'server/crates/domain/Cargo.toml'
  - 'server/crates/domain/src/lib.rs'
  - 'server/crates/domain/src/test_fixtures.rs (new)'
  - 'server/crates/domain/src/orders/service.rs'
  - 'server/crates/api/Cargo.toml'
  - 'server/crates/api/src/test_helpers.rs (new)'
  - 'server/crates/api/src/main.rs'
  - 'server/crates/api/src/routes/orders.rs'
code_patterns:
  - '#[cfg(any(test, feature = "testing"))] pour double exposition: tests locaux + cross-crate'
  - '#[sqlx::test(migrations = "../../migrations")] avec 17 paires .up/.down'
  - 'Factory functions: create_test_user(pool) -> Result<User, AppError>'
  - 'test_app(pool) enregistre UNIQUEMENT les routes orders/merchants (pas auth/kyc)'
  - 'create_test_jwt(user_id, role) pour auth mock dans route tests'
  - 'Factory merchant: create + update_status(Open) car default DB = Closed'
  - 'Phone unique via AtomicU64 pour eviter ON CONFLICT silent'
test_patterns:
  - '#[sqlx::test] pour tests DB (domain crate)'
  - '#[actix_web::test] pour tests route (api crate)'
  - 'Factory -> service call -> assert (pattern service test)'
  - 'Factory -> TestRequest -> call_service -> assert response (pattern route test)'
adversarial_review:
  - 'F2 (High): fixed - merchant factory ajoute update_status(Open) apres creation'
  - 'F3 (High): fixed - test_app enregistre seulement les routes testees, pas toutes'
  - 'F4 (High): fixed - phone via AtomicU64 + doc ON CONFLICT'
  - 'F9 (Medium): fixed - #[cfg(any(test, feature = "testing"))] au lieu de #[cfg(feature = "testing")]'
  - 'F7 (Medium): fixed - signature create_user corrigee: name = Option<&str>'
  - 'F8 (Medium): fixed - test ownership clarifie: user_id = user.id du User lie au Merchant'
---

# Tech-Spec: Backend Integration Test Infrastructure

**Created:** 2026-03-18

## Overview

### Problem Statement

Le backend Rust mefali n'a aucune infrastructure de tests d'integration avec base de donnees. Les 176 tests existants sont tous des tests unitaires purs (serde roundtrip, validation, mock providers). Il est impossible de tester les fonctions service qui appellent PostgreSQL (`get_merchant_weekly_stats`, `create_order`, etc.) ni les routes HTTP avec un vrai pool de connexion. Cela a ete identifie lors de la code review de la story 3-7 (T4.2/T4.3 non implantables).

### Solution

Mettre en place `#[sqlx::test]` avec migrations automatiques + un module `test_fixtures` dans le crate domain (expose via `#[cfg(any(test, feature = "testing"))]`) fournissant des factory functions pour toutes les entites core. Ajouter un module `test_helpers` dans le crate api avec `test_app(pool)` pour les tests de routes HTTP. Valider en implementant les tests T4.2/T4.3 de la story 3-7.

### Scope

**In Scope:**
- Configuration `#[sqlx::test]` avec migrations auto (17 paires .up/.down)
- Feature flag `testing` sur le crate domain + double gate `#[cfg(any(test, feature = "testing"))]`
- Module `test_fixtures` dans domain : factories pour users, merchants, products, orders, order_items
- Module `test_helpers` dans api : `test_app(pool)`, `create_test_jwt()`
- Tests concrets : service `get_merchant_weekly_stats` (T4.2) + route `GET /merchants/me/stats/weekly` (T4.3)

**Out of Scope:**
- testcontainers / Docker PostgreSQL par test
- Integration CI/CD pipeline (sera une story dediee)
- Tests frontend Flutter
- Tests de performance / load testing
- Tests pour les modules payment_provider et notification (ont deja des mocks)
- Factory pour drivers/deliveries/wallets/disputes/sponsorships (ajoutees dans les epics correspondants)

## Context for Development

### Codebase Patterns

**Patterns existants (a suivre) :**
- `#[actix_web::test]` + `test::init_service()` + `test::TestRequest` + `test::call_service()` + `test::read_body_json()` (voir `authenticated_user.rs:70-229`)
- `test_config()` retourne un `AppConfig` minimal avec JWT secret de test (voir `authenticated_user.rs:78-95`)
- `create_test_jwt(user_id, role, expired)` genere un token JWT de test (voir `authenticated_user.rs:97-108`)
- `test_app()` retourne un `App` Actix configure pour tests (voir `authenticated_user.rs:117-129`)
- Toutes les fonctions repository sont `pub async fn` — pas de restriction de visibilite
- Migrations SQL dans `server/migrations/` (34 fichiers = 17 paires reversibles `.up.sql`/`.down.sql`, auto-embeddees via `sqlx::migrate!("../../migrations")`)

**sqlx setup :**
- Version 0.8, features: `runtime-tokio`, `tls-rustls`, `postgres`, `uuid`, `chrono`, `migrate`
- Pas de `.sqlx/` offline mode
- `DATABASE_URL=postgres://mefali:mefali@localhost:5433/mefali`
- `#[sqlx::test]` cree une DB temporaire par test, applique les migrations, cleanup auto

**Structs cles pour les factories :**
- `User { id, phone, name: Option<String>, role: UserRole, status: UserStatus, city_id, fcm_token, created_at, updated_at }`
- `Merchant { id, user_id, name, address, status: MerchantStatus (#[sqlx(rename = "availability_status")]), city_id, consecutive_no_response, photo_url, category, onboarding_step, created_by_agent_id, created_at, updated_at }`
- `Product { id, merchant_id, name, description, price: i64, stock: i32, initial_stock: i32, photo_url, is_available, created_at, updated_at }`
- `Order { id, customer_id, merchant_id, driver_id, status: OrderStatus, payment_type, payment_status, subtotal: i64, delivery_fee: i64, total: i64, ... }`
- `OrderItem { id, order_id, product_id, quantity: i32, unit_price: i64, created_at, product_name: Option<String> }`

**Fonctions repository exactes pour les factories :**
- `users::repository::create_user(pool: &PgPool, phone: &str, name: Option<&str>, role: UserRole, status: UserStatus) → Result<User, AppError>` — ATTENTION: `ON CONFLICT (phone) DO UPDATE SET updated_at = now()` retourne silencieusement le user existant si le phone est duplique (ne met PAS a jour role/name/status)
- `merchants::repository::create_merchant(pool: &PgPool, user_id: Id, agent_id: Id, payload: &CreateMerchantPayload) → Result<Merchant, AppError>` — cree un merchant en status `Closed` (default DB sur colonne `availability_status`)
- `merchants::repository::update_status(pool: &PgPool, merchant_id: Id, new_status: &MerchantStatus) → Result<Merchant, AppError>`
- `products::repository::create_product(pool: &PgPool, merchant_id: Id, payload: &CreateProductPayload) → Result<Product, AppError>`
- `orders::repository::create_order(executor: impl PgExecutor, customer_id, merchant_id, payment_type, subtotal, delivery_fee, total, delivery_address, delivery_lat, delivery_lng, city_id, notes) → Result<Order, AppError>`
- `orders::repository::create_order_item(executor: impl PgExecutor, order_id, product_id, quantity, unit_price) → Result<OrderItem, AppError>`
- `orders::repository::update_status(executor: impl PgExecutor, order_id, status) → Result<Order, AppError>`

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `server/crates/api/src/extractors/authenticated_user.rs:70-229` | Pattern complet actix_web::test (test_config, create_test_jwt, test_app) |
| `server/crates/api/src/routes/health.rs:14-33` | Test route minimal |
| `server/crates/api/src/main.rs:35-39` | Migrations auto `sqlx::migrate!("../../migrations")` |
| `server/crates/api/src/main.rs:59-74` | App setup prod (toutes les app_data) |
| `server/crates/domain/src/orders/service.rs:241-333` | `get_merchant_weekly_stats` a tester |
| `server/crates/api/src/routes/orders.rs:103-116` | Route `get_weekly_stats` a tester |
| `server/crates/domain/src/users/repository.rs` | `create_user()` — note ON CONFLICT |
| `server/crates/domain/src/merchants/repository.rs` | `create_merchant()` — note default Closed |
| `server/crates/domain/src/products/repository.rs` | `create_product()` |
| `server/crates/domain/src/orders/repository.rs` | `create_order()`, `create_order_item()`, `update_status()` |

### Technical Decisions

- **`#[sqlx::test]`** : cree une DB temporaire par test, applique les 17 paires de migrations (34 fichiers .up/.down), cleanup auto. Necessite `DATABASE_URL` pointant vers un serveur PostgreSQL actif (port 5433).
- **Double gate `#[cfg(any(test, feature = "testing"))]`** sur domain : expose `pub mod test_fixtures` quand (a) le crate est en mode test (`cargo test -p domain`) OU (b) le feature `testing` est active (depuis api `[dev-dependencies]`). Resout le probleme F9 : les deux crates ont acces aux fixtures.
- **Factories appellent les vrais repositories** : pas de mock, pas d'INSERT SQL brut. Garantit que les fixtures sont toujours coherentes avec le schema. Note : les factories sont NON-transactionnelles (chaque appel repository est independant) — acceptable pour les tests.
- **Factory merchant fait `create_merchant` puis `update_status(Open)`** : car le default DB est `Closed`. Sans cette etape, les tests qui creent des commandes echouent (le service rejette les commandes pour merchants fermes).
- **Phones uniques via `AtomicU64`** : genere `+22501000NNNNN` avec compteur croissant pour eviter les collisions phone et le comportement silencieux du `ON CONFLICT (phone)` dans `create_user`.
- **`test_app(pool)` enregistre UNIQUEMENT les routes merchant/orders** : pas `routes::configure` qui inclut auth (Redis), KYC (S3), etc. Enregistrer seulement les scopes `/api/v1/merchants` et `/api/v1/orders` pour eviter les panics sur `Data<Redis>` / `Data<S3>` absents.
- **Migrations path** : `#[sqlx::test(migrations = "../../migrations")]` — relatif au `Cargo.toml` du crate (meme chemin pour domain et api, structure `crates/<name>/`).

## Implementation Plan

### Tasks

- [x] **T1** : Ajouter feature flag `testing` au crate domain
  - File: `server/crates/domain/Cargo.toml`
  - Action: Ajouter section `[features]` avec `testing = []`
  - Notes: Pas de dependance supplementaire, juste un feature gate

- [x] **T2** : Creer le module `test_fixtures` dans domain
  - File: `server/crates/domain/src/test_fixtures.rs` (new)
  - Action: Creer les factory functions suivantes :
    - `create_test_user(pool: &PgPool) → Result<User, AppError>` — cree un user role `Client`, phone unique via `AtomicU64` (format `+22501000NNNNN`), `name: Some("Test User")`, status `Active`
    - `create_test_user_with_role(pool: &PgPool, role: UserRole) → Result<User, AppError>` — idem avec role parametre
    - `create_test_merchant(pool: &PgPool, user_id: Id) → Result<Merchant, AppError>` — (1) cree un user Agent via `create_test_user_with_role(pool, Agent)`, (2) cree merchant via `create_merchant(pool, user_id, agent.id, &payload)` avec name "Test Merchant", (3) **appelle `merchants::repository::update_status(pool, merchant.id, &MerchantStatus::Open)`** pour passer de Closed a Open
    - `create_test_product(pool: &PgPool, merchant_id: Id) → Result<Product, AppError>` — cree un produit "Test Product", price 100000 (1000 FCFA), stock 50
    - `create_test_product_with_price(pool: &PgPool, merchant_id: Id, name: &str, price: i64) → Result<Product, AppError>` — produit parametre
    - `create_test_delivered_order(pool: &PgPool, customer_id: Id, merchant_id: Id, items: &[(Id, i32, i64)]) → Result<Order, AppError>` — (1) cree order via `create_order(pool, ...)` en Pending, (2) cree chaque order_item via `create_order_item(pool, ...)`, (3) `update_status(pool, order.id, &OrderStatus::Delivered)`. Note : non-transactionnel, acceptable pour les tests.
  - Notes: Le compteur phone est un `static COUNTER: AtomicU64`. Imports necessaires : `use crate::{users, merchants, products, orders}; use crate::merchants::model::{CreateMerchantPayload, MerchantStatus}; use crate::products::model::CreateProductPayload; use crate::orders::model::{OrderStatus, PaymentType}; use common::error::AppError; use common::types::Id; use sqlx::PgPool; use std::sync::atomic::{AtomicU64, Ordering};`

- [x] **T3** : Enregistrer le module `test_fixtures` dans domain/lib.rs
  - File: `server/crates/domain/src/lib.rs`
  - Action: Ajouter `#[cfg(any(test, feature = "testing"))] pub mod test_fixtures;`
  - Notes: Le module est accessible quand (a) domain est en mode test ou (b) le feature `testing` est active depuis un autre crate

- [x] **T4** : Ajouter tests integration service `get_merchant_weekly_stats` (story 3-7 T4.2)
  - File: `server/crates/domain/src/orders/service.rs`
  - Action: Ajouter un bloc `#[cfg(test)] mod integration_tests` (apres le bloc `mod tests` existant) avec les tests suivants :
    - `test_weekly_stats_with_orders` : (1) `create_test_user_with_role(pool, Merchant)` → user_m, (2) `create_test_merchant(pool, user_m.id)` → merchant, (3) `create_test_user(pool)` → customer, (4) `create_test_product_with_price(pool, merchant.id, "Garba", 250000)` → p1, (5) `create_test_product_with_price(pool, merchant.id, "Alloco", 150000)` → p2, (6) 3x `create_test_delivered_order` avec items varies → (7) `get_merchant_weekly_stats(pool, user_m.id)` → assert `total_sales` = somme des totaux, `order_count` = 3, `product_breakdown` non vide et trie par revenu desc
    - `test_weekly_stats_empty_week` : cree merchant sans commandes → `get_merchant_weekly_stats` → assert `total_sales` = 0, `order_count` = 0, `product_breakdown` vide
    - `test_weekly_stats_ownership_check` : cree user_a (Merchant) + merchant_a + commandes, cree user_b (Merchant) + merchant_b sans commandes → `get_merchant_weekly_stats(pool, user_b.id)` → assert `total_sales` = 0 (user_b.id est le `User.id` du User lie a merchant_b, PAS le merchant_b.id)
  - Notes: `#[sqlx::test(migrations = "../../migrations")]` injecte `pool: PgPool`. Importer factories via `use crate::test_fixtures::*;`

- [x] **T5** : Creer le module `test_helpers` dans api
  - File: `server/crates/api/src/test_helpers.rs` (new)
  - Action: Creer les helpers suivants (marquer `#[cfg(test)]`) :
    - `test_config() → AppConfig` — copier le pattern de `authenticated_user.rs:78-95`
    - `create_test_jwt(user_id: Id, role: &str) → String` — copier le pattern de `authenticated_user.rs:97-108` (toujours valide, jamais expire)
    - `test_app(pool: PgPool) → App<impl ServiceFactory<...>>` — enregistrer UNIQUEMENT les scopes necessaires, PAS `routes::configure` complet :
      ```
      App::new()
          .app_data(web::Data::new(test_config()))
          .app_data(web::Data::new(pool))
          .service(
              web::scope("/api/v1")
                  .service(
                      web::scope("/orders")
                          .route("", web::post().to(orders::create_order))
                          .route("/{id}/accept", web::put().to(orders::accept_order))
                          .route("/{id}/reject", web::put().to(orders::reject_order))
                          .route("/{id}/ready", web::put().to(orders::mark_ready))
                  )
                  .service(
                      web::scope("/merchants")
                          .route("/me/orders", web::get().to(orders::get_merchant_orders))
                          .route("/me/stats/weekly", web::get().to(orders::get_weekly_stats))
                  )
          )
      ```
  - Notes: Ne PAS inclure auth, kyc, users, products routes car ils necessitent Redis/S3/SMS. Extensible : ajouter d'autres scopes quand leurs tests sont ecrits.

- [x] **T6** : Configurer les dev-dependencies dans api/Cargo.toml
  - File: `server/crates/api/Cargo.toml`
  - Action: Ajouter dans `[dev-dependencies]` : `domain = { path = "../domain", features = ["testing"] }` et `sqlx = { workspace = true }`
  - Notes: Le `[dev-dependencies]` active le feature `testing` sur domain uniquement pendant `cargo test -p api`. Le `domain` en `[dependencies]` normal reste sans feature.

- [x] **T7** : Enregistrer le module `test_helpers` dans api/main.rs
  - File: `server/crates/api/src/main.rs`
  - Action: Ajouter `#[cfg(test)] mod test_helpers;` en haut du fichier (apres les `mod` existants)
  - Notes: Accessible depuis les tests inline (`routes/orders.rs`) via `crate::test_helpers::*`

- [x] **T8** : Ajouter tests integration route `GET /merchants/me/stats/weekly` (story 3-7 T4.3)
  - File: `server/crates/api/src/routes/orders.rs`
  - Action: Ajouter un bloc `#[cfg(test)] mod integration_tests` (apres le bloc `mod tests` existant) avec :
    - `test_weekly_stats_200_ok` : (1) factories pour merchant + orders (via `domain::test_fixtures::*`), (2) `create_test_jwt(user_m.id, "merchant")`, (3) `test::init_service(crate::test_helpers::test_app(pool))`, (4) `TestRequest::get().uri("/api/v1/merchants/me/stats/weekly").insert_header(("Authorization", format!("Bearer {}", token)))` → assert status 200, body `data.current_week.total_sales > 0`, `data.product_breakdown` non vide
    - `test_weekly_stats_401_no_token` : meme TestRequest sans header Authorization → assert status 401
    - `test_weekly_stats_403_wrong_role` : JWT avec role `client` (pas merchant) → assert status 403
  - Notes: `#[sqlx::test(migrations = "../../migrations")]` injecte `pool: PgPool`. Les tests 401/403 n'ont pas besoin de factories DB.

### Acceptance Criteria

- [x] **AC1**: Given le crate domain en mode test, when `cargo test -p domain` est execute avec `DATABASE_URL` configure, then les tests `#[sqlx::test]` creent une DB temporaire, appliquent les 17 paires de migrations, et les factories creent des entites valides en DB
- [x] **AC2**: Given un merchant Open avec 3 commandes delivered cette semaine, when `get_merchant_weekly_stats(pool, user_m.id)` est appele (ou `user_m.id` est le `User.id` du user lie au merchant), then le resultat contient `total_sales` = somme des totaux des 3 commandes, `order_count` = 3, et `product_breakdown` trie par revenu decroissant
- [x] **AC3**: Given un merchant Open sans commande cette semaine, when `get_merchant_weekly_stats(pool, user_m.id)` est appele, then le resultat contient `total_sales` = 0, `order_count` = 0, `product_breakdown` = vec vide
- [x] **AC4**: Given le crate api avec `test_helpers::test_app(pool)`, when un `TestRequest` GET sur `/api/v1/merchants/me/stats/weekly` est envoye avec un JWT valide role `merchant`, then la reponse est 200 avec `{"data": {"current_week": {...}, "previous_week": {...}, "product_breakdown": [...]}}`
- [x] **AC5**: Given un request sans header Authorization, when GET `/api/v1/merchants/me/stats/weekly`, then la reponse est 401
- [x] **AC6**: Given un JWT avec role `client` (pas `merchant`), when GET `/api/v1/merchants/me/stats/weekly`, then la reponse est 403
- [x] **AC7**: Given l'implementation complete, when `cargo test --workspace` est execute, then tous les tests existants (176+) continuent de passer ET les 6 nouveaux tests integration passent

## Additional Context

### Dependencies

- `sqlx` 0.8 (deja present, feature `migrate` active) — pas de nouvelle dep
- `tokio` (deja present dans workspace)
- PostgreSQL local actif sur port 5433 requis pour `cargo test` (`docker compose up -d postgres`)
- Aucune dependance sur Redis, MinIO ou SMS pour ces tests

### Testing Strategy

- **Tests service (T4)** : `#[sqlx::test]` dans domain, factories creent les donnees, assertions sur les structs retournees
- **Tests route (T8)** : `#[sqlx::test]` fournit le pool, `test_app(pool)` configure l'App avec routes ciblees, `TestRequest` avec JWT mock, assertions sur status HTTP + body JSON
- **Regression** : `cargo test --workspace` doit passer sans regression (AC7)
- **Prerequis** : PostgreSQL doit tourner sur port 5433 (`docker compose up -d postgres`)

### Notes

- **Pre-mortem** : (1) Le chemin migrations `"../../migrations"` est relatif au `Cargo.toml` du crate, deja prouve par `sqlx::migrate!()` en production dans `main.rs:35`. (2) `create_user` a un `ON CONFLICT (phone)` silencieux — le `AtomicU64` garantit l'unicite dans un meme process de test, mais si les tests sont relances, la DB temp est recree donc pas de conflit.
- **Merchant default Closed** : Toujours appeler `update_status(Open)` apres `create_merchant` dans les factories. Oublier cette etape fait echouer silencieusement les tests qui creent des commandes.
- **Factories non-transactionnelles** : Chaque appel repository est independant (pas de `BEGIN/COMMIT`). Acceptable pour les tests car `#[sqlx::test]` rollback toute la DB a la fin.
- **Debloque** : story 3-7 T4.2/T4.3 directement. Pattern reutilisable pour toutes les futures stories.
- **Futures factories** : drivers, deliveries, wallets, disputes, sponsorships — a ajouter au fur et a mesure des epics 5-9.
