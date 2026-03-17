# Story 1.4: Database Schema & Migrations

Status: done

---

## Story

En tant que **developpeur**,
Je veux **des migrations SQLx pour toutes les tables principales**,
Afin que **la base de donnees soit prete pour le developpement des fonctionnalites**.

## Criteres d'Acceptation

1. **AC1**: `sqlx migrate run` execute toutes les migrations avec succes sur une PostgreSQL vierge (base `mefali`)
2. **AC2**: Toutes les tables ont des cles primaires UUID v4 et des cles etrangeres correctes avec `ON DELETE` appropries
3. **AC3**: Les 12 tables du schema architecture sont creees : `users`, `merchants`, `products`, `orders`, `order_items`, `wallets`, `wallet_transactions`, `deliveries`, `disputes`, `sponsorships`, `city_config`, `kyc_documents`
4. **AC4**: Les enums PostgreSQL correspondent aux enums Rust existants dans `domain/` (user_role, vendor_status, order_status, payment_type, payment_status, delivery_status, wallet_transaction_type, dispute_type, dispute_status, sponsorship_status, kyc_status)
5. **AC5**: Les index sont crees sur toutes les colonnes de filtrage frequentes (FK, status, phone)
6. **AC6**: `cargo test --workspace` passe sans regression (30 tests existants)
7. **AC7**: `cargo build --workspace` compile sans erreur
8. **AC8**: Les migrations sont reversibles — chaque fichier `up.sql` a un `down.sql` correspondant

## Taches / Sous-taches

- [x] **T1** Creer les fichiers de migration SQLx dans `server/migrations/` (AC: #1, #3, #4)
  - [x] T1.1 Migration 001: enums PostgreSQL (tous les types enumeres)
  - [x] T1.2 Migration 002: `city_config` (aucune dependance FK)
  - [x] T1.3 Migration 003: `users` (FK → city_config)
  - [x] T1.4 Migration 004: `merchants` (FK → users, city_config)
  - [x] T1.5 Migration 005: `products` (FK → merchants)
  - [x] T1.6 Migration 006: `wallets` (FK → users)
  - [x] T1.7 Migration 007: `orders` (FK → users, merchants, city_config)
  - [x] T1.8 Migration 008: `order_items` (FK → orders, products)
  - [x] T1.9 Migration 009: `wallet_transactions` (FK → wallets)
  - [x] T1.10 Migration 010: `deliveries` (FK → orders, users)
  - [x] T1.11 Migration 011: `disputes` (FK → orders, users)
  - [x] T1.12 Migration 012: `sponsorships` (FK → users)
  - [x] T1.13 Migration 013: `kyc_documents` (FK → users)
- [x] **T2** Creer les index de performance (AC: #5)
  - [x] T2.1 Index dans chaque migration de table (co-localises)
- [x] **T3** Ajouter le code de migration au demarrage de l'API (AC: #1)
  - [x] T3.1 `sqlx::migrate!()` dans `api/src/main.rs` apres creation du pool
- [x] **T4** Verifier la compilation et les tests (AC: #6, #7)
  - [x] T4.1 `cargo build --workspace`
  - [x] T4.2 `cargo test --workspace`
  - [x] T4.3 `cargo clippy --workspace`
- [x] **T5** Tester le cycle de migration (AC: #1, #8)
  - [x] T5.1 Demarrer PostgreSQL (via Docker ou local port 5433)
  - [x] T5.2 `sqlx migrate run` → succes
  - [x] T5.3 Verifier les tables avec `\dt` dans psql
  - [x] T5.4 Verifier les enums avec `\dT+`

## Dev Notes

### Schema complet — 12 tables + enums

**Convention absolue : `snake_case` partout** (tables, colonnes, enums, valeurs). Montants en BIGINT (FCFA entier, pas de centimes). Toutes les dates en `TIMESTAMPTZ` UTC. IDs = UUID v4.

#### Enums PostgreSQL

Mapper exactement les enums Rust de `domain/src/*/model.rs` :

| Enum PG | Valeurs | Source Rust |
|---------|---------|-------------|
| `user_role` | client, merchant, driver, agent, admin | `domain/users/model.rs::UserRole` |
| `user_status` | active, pending_kyc, suspended, deactivated | — (a ajouter) |
| `vendor_status` | open, overwhelmed, auto_paused, closed | `domain/merchants/model.rs` |
| `order_status` | pending, confirmed, preparing, ready, collected, in_transit, delivered, cancelled | `domain/orders/model.rs::OrderStatus` |
| `payment_type` | cod, mobile_money | — (a creer) |
| `payment_status` | pending, escrow_held, released, refunded | — (a creer) |
| `delivery_status` | pending, assigned, picked_up, in_transit, delivered, failed, client_absent | `domain/deliveries/model.rs` + `client_absent` |
| `wallet_transaction_type` | credit, debit, withdrawal, refund | `domain/wallets/model.rs` |
| `dispute_type` | incomplete, quality, wrong_order, other | — (a creer, FR54) |
| `dispute_status` | open, in_progress, resolved, closed | `domain/disputes/model.rs` |
| `sponsorship_status` | active, suspended, terminated | `domain/sponsorships/model.rs` |
| `kyc_document_type` | cni, permis | — (a creer) |
| `kyc_status` | pending, verified, rejected | — (a creer) |

**Important** : Ajouter `client_absent` a `delivery_status` — present dans le PRD (FR24, protocole client absent) mais absent de l'enum Rust actuelle. Signaler au dev agent de mettre a jour le modele Rust en consequence.

#### Table par table — schema detaille

**`city_config`** (pas de FK, cree en premier)

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| city_name | VARCHAR(100) | NOT NULL UNIQUE |
| delivery_multiplier | NUMERIC(5,2) | NOT NULL DEFAULT 1.00 |
| zones_geojson | JSONB | NULLABLE |
| is_active | BOOLEAN | NOT NULL DEFAULT TRUE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

**`users`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| phone | VARCHAR(20) | NOT NULL UNIQUE |
| name | VARCHAR(100) | NULLABLE |
| role | user_role | NOT NULL |
| status | user_status | NOT NULL DEFAULT 'active' |
| city_id | UUID | FK → city_config(id) NULLABLE |
| fcm_token | TEXT | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_users_phone` (UNIQUE implicite), `idx_users_city_id`, `idx_users_role`

**`merchants`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| user_id | UUID | NOT NULL UNIQUE FK → users(id) ON DELETE CASCADE |
| name | VARCHAR(200) | NOT NULL |
| address | TEXT | NULLABLE |
| availability_status | vendor_status | NOT NULL DEFAULT 'closed' |
| city_id | UUID | FK → city_config(id) NULLABLE |
| consecutive_no_response | INT | NOT NULL DEFAULT 0 |
| photo_url | TEXT | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_merchants_city_id`, `idx_merchants_availability_status`

**`products`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| merchant_id | UUID | NOT NULL FK → merchants(id) ON DELETE CASCADE |
| name | VARCHAR(200) | NOT NULL |
| description | TEXT | NULLABLE |
| price | BIGINT | NOT NULL CHECK (price >= 0) |
| stock | INT | NOT NULL DEFAULT 0 CHECK (stock >= 0) |
| initial_stock | INT | NOT NULL DEFAULT 0 |
| photo_url | TEXT | NULLABLE |
| is_available | BOOLEAN | NOT NULL DEFAULT TRUE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_products_merchant_id`

**`orders`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| customer_id | UUID | NOT NULL FK → users(id) |
| merchant_id | UUID | NOT NULL FK → merchants(id) |
| driver_id | UUID | FK → users(id) NULLABLE |
| status | order_status | NOT NULL DEFAULT 'pending' |
| payment_type | payment_type | NOT NULL |
| payment_status | payment_status | NOT NULL DEFAULT 'pending' |
| subtotal | BIGINT | NOT NULL CHECK (subtotal >= 0) |
| delivery_fee | BIGINT | NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0) |
| total | BIGINT | NOT NULL CHECK (total >= 0) |
| delivery_address | TEXT | NULLABLE |
| delivery_lat | DOUBLE PRECISION | NULLABLE |
| delivery_lng | DOUBLE PRECISION | NULLABLE |
| city_id | UUID | FK → city_config(id) NULLABLE |
| notes | TEXT | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_orders_customer_id`, `idx_orders_merchant_id`, `idx_orders_driver_id`, `idx_orders_status`, `idx_orders_city_id`, `idx_orders_created_at`

**`order_items`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| order_id | UUID | NOT NULL FK → orders(id) ON DELETE CASCADE |
| product_id | UUID | NOT NULL FK → products(id) |
| quantity | INT | NOT NULL CHECK (quantity > 0) |
| unit_price | BIGINT | NOT NULL CHECK (unit_price >= 0) |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_order_items_order_id`

**`wallets`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| user_id | UUID | NOT NULL UNIQUE FK → users(id) ON DELETE CASCADE |
| balance | BIGINT | NOT NULL DEFAULT 0 |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

**`wallet_transactions`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| wallet_id | UUID | NOT NULL FK → wallets(id) |
| amount | BIGINT | NOT NULL |
| transaction_type | wallet_transaction_type | NOT NULL |
| reference | VARCHAR(255) | NULLABLE |
| description | TEXT | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_wallet_transactions_wallet_id`, `idx_wallet_transactions_reference`, `idx_wallet_transactions_created_at`

**`deliveries`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| order_id | UUID | NOT NULL UNIQUE FK → orders(id) |
| driver_id | UUID | NOT NULL FK → users(id) |
| status | delivery_status | NOT NULL DEFAULT 'pending' |
| current_lat | DOUBLE PRECISION | NULLABLE |
| current_lng | DOUBLE PRECISION | NULLABLE |
| picked_up_at | TIMESTAMPTZ | NULLABLE |
| delivered_at | TIMESTAMPTZ | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_deliveries_driver_id`, `idx_deliveries_status`

**`disputes`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| order_id | UUID | NOT NULL FK → orders(id) |
| reporter_id | UUID | NOT NULL FK → users(id) |
| dispute_type | dispute_type | NOT NULL |
| status | dispute_status | NOT NULL DEFAULT 'open' |
| resolution | TEXT | NULLABLE |
| resolved_by | UUID | FK → users(id) NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_disputes_order_id`, `idx_disputes_reporter_id`, `idx_disputes_status`

**`sponsorships`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| sponsor_id | UUID | NOT NULL FK → users(id) |
| sponsored_id | UUID | NOT NULL UNIQUE FK → users(id) |
| status | sponsorship_status | NOT NULL DEFAULT 'active' |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_sponsorships_sponsor_id`
Contrainte: `CHECK (sponsor_id != sponsored_id)`

**`kyc_documents`**

| Colonne | Type | Contraintes |
|---------|------|-------------|
| id | UUID | PK DEFAULT gen_random_uuid() |
| user_id | UUID | NOT NULL FK → users(id) ON DELETE CASCADE |
| document_type | kyc_document_type | NOT NULL |
| encrypted_path | TEXT | NOT NULL |
| verified_by | UUID | FK → users(id) NULLABLE |
| status | kyc_status | NOT NULL DEFAULT 'pending' |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() |

Index: `idx_kyc_documents_user_id`, `idx_kyc_documents_status`

### Organisation des fichiers de migration

Format SQLx 0.8 reversible (fichiers plats avec suffixes `.up.sql` / `.down.sql`) :

```
server/migrations/
├── 20260317000001_create_enums.up.sql
├── 20260317000001_create_enums.down.sql
├── 20260317000002_create_city_config.up.sql
├── 20260317000002_create_city_config.down.sql
├── 20260317000003_create_users.up.sql
├── 20260317000003_create_users.down.sql
├── 20260317000004_create_merchants.up.sql
├── 20260317000004_create_merchants.down.sql
├── 20260317000005_create_products.up.sql
├── 20260317000005_create_products.down.sql
├── 20260317000006_create_wallets.up.sql
├── 20260317000006_create_wallets.down.sql
├── 20260317000007_create_orders.up.sql
├── 20260317000007_create_orders.down.sql
├── 20260317000008_create_order_items.up.sql
├── 20260317000008_create_order_items.down.sql
├── 20260317000009_create_wallet_transactions.up.sql
├── 20260317000009_create_wallet_transactions.down.sql
├── 20260317000010_create_deliveries.up.sql
├── 20260317000010_create_deliveries.down.sql
├── 20260317000011_create_disputes.up.sql
├── 20260317000011_create_disputes.down.sql
├── 20260317000012_create_sponsorships.up.sql
├── 20260317000012_create_sponsorships.down.sql
├── 20260317000013_create_kyc_documents.up.sql
└── 20260317000013_create_kyc_documents.down.sql
```

**Note** : Supprimer le fichier `.gitkeep` existant dans `server/migrations/`.

### Integration dans `api/src/main.rs`

Ajouter l'execution automatique des migrations au demarrage :

```rust
// Apres creation du db_pool dans main()
sqlx::migrate!("./migrations")
    .run(&db_pool)
    .await
    .expect("Failed to run database migrations");
```

Cela necessite que le `db_pool` soit cree AVANT dans main.rs. Actuellement, la creation du pool est en commentaire (placeholder). Il faut:
1. Decommenter `infrastructure::database::create_pool()` dans main.rs
2. Ajouter `sqlx::migrate!()` apres le pool
3. Passer le pool comme app data: `web::Data::new(db_pool.clone())`

### Trigger updated_at automatique

Creer une fonction SQL + triggers pour mettre a jour `updated_at` automatiquement :

```sql
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Appliquer sur chaque table avec `updated_at` :
```sql
CREATE TRIGGER set_updated_at BEFORE UPDATE ON {table}
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
```

Inclure la fonction dans la migration 001 (enums) ou 002 (city_config). Appliquer les triggers dans chaque migration de table.

### Patterns etablis par les stories precedentes

**Story 1.3 (Docker Compose Infrastructure) :**
- PostgreSQL tourne sur port 5433 (host) / 5432 (Docker interne)
- `DATABASE_URL=postgres://mefali:mefali@localhost:5433/mefali` pour dev local
- `DATABASE_URL=postgres://mefali:mefali@postgres:5432/mefali` pour Docker
- Infrastructure crate : `create_pool()` dans `infrastructure/src/database/mod.rs` retourne `PgPool`
- Le `.env` racine et `server/.env.example` existent deja

**Story 1.2 (Rust Backend) :**
- `AppConfig::from_env()` dans `common/src/config.rs` charge `DATABASE_URL` depuis l'environnement
- Logging via `tracing-subscriber` avec format JSON
- Erreurs via `AppError` enum → JSON `{"error":{"code":"...","message":"..."}}`
- Health endpoint `GET /api/v1/health` retourne `{"data":{"status":"ok"}}`
- SQLx workspace dependency: version 0.8, features `[runtime-tokio, tls-rustls, postgres, uuid, chrono, migrate]`

**Story 1.1 (Flutter Monorepo) :**
- Pas d'impact direct, mais le package `mefali_core` contient les modeles Dart qui devront correspondre au schema DB

### Decisions de design

**Montants en BIGINT (pas NUMERIC/DECIMAL)** : Le FCFA est une monnaie entiere (pas de centimes). 1 FCFA = 1 unite. BIGINT evite les erreurs d'arrondi et est plus performant.

**Enums PostgreSQL (pas VARCHAR)** : Plus type-safe, valides par la DB. SQLx les supporte nativement avec `#[derive(sqlx::Type)]`. Le trade-off (modifier un enum = ALTER TYPE) est acceptable car les enums sont stables.

**ON DELETE CASCADE** : Uniquement sur les relations parent-enfant naturelles (merchant→products, order→order_items, user→merchant, user→wallet, user→kyc_documents). Les FK comme orders.customer_id ou orders.merchant_id n'ont PAS de CASCADE — on ne supprime pas les commandes quand un user est supprime.

**UUID gen_random_uuid()** : Genere cote PostgreSQL (pas cote Rust) via `DEFAULT gen_random_uuid()`. Permet l'insertion sans specifier l'ID. Extension `pgcrypto` requise (ou PG ≥ 13 qui l'a nativement).

### Anti-patterns a eviter

- **NE PAS** utiliser AUTO_INCREMENT / SERIAL — UUID v4 uniquement
- **NE PAS** utiliser DECIMAL/NUMERIC pour les montants FCFA — BIGINT suffit (monnaie entiere)
- **NE PAS** stocker les mots de passe — auth = phone + OTP uniquement
- **NE PAS** creer de table `sessions` — JWT stateless (access 15 min + refresh 7 jours)
- **NE PAS** utiliser `ON DELETE CASCADE` sur les FK orders → users — les commandes doivent survivre a la desactivation d'un compte
- **NE PAS** oublier les `down.sql` — toutes les migrations doivent etre reversibles
- **NE PAS** mettre les index dans une migration separee — les co-localiser avec la table (lisibilite)
- **NE PAS** utiliser `VARCHAR` sans limite raisonnable pour phone (20), noms (100/200), city (100)

### Verification post-implementation

```bash
# Depuis server/
export DATABASE_URL=postgres://mefali:mefali@localhost:5433/mefali
sqlx migrate run
# Verifier :
psql -h localhost -p 5433 -U mefali -d mefali -c "\dt"       # 12 tables
psql -h localhost -p 5433 -U mefali -d mefali -c "\dT+"       # 13 enums
psql -h localhost -p 5433 -U mefali -d mefali -c "\di"        # index
cargo test --workspace                                         # 30+ tests OK
cargo clippy --workspace                                       # 0 warning
```

### Project Structure Notes

Fichiers a creer :
```
server/migrations/20260317000001_create_enums.up.sql        # CREER
server/migrations/20260317000001_create_enums.down.sql      # CREER
... (13 paires au total, format plat SQLx 0.8)
server/migrations/20260317000013_create_kyc_documents.up.sql
server/migrations/20260317000013_create_kyc_documents.down.sql
```

Fichiers a modifier :
```
server/crates/api/src/main.rs                    # MODIFIER — ajouter sqlx::migrate!() + decommenter db_pool
```

Fichiers a supprimer :
```
server/migrations/.gitkeep                       # SUPPRIMER — remplace par les vrais fichiers
```

Fichiers existants a NE PAS modifier :
```
server/crates/domain/src/*/model.rs              # Pas dans cette story — alignement modele/DB dans les stories suivantes
server/crates/infrastructure/src/database/mod.rs  # create_pool() est deja correct
server/crates/common/src/config.rs                # AppConfig est deja correct
```

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data-Architecture] Schema DB 12 tables + conventions
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation-Patterns] snake_case, UUID v4, ISO 8601
- [Source: _bmad-output/planning-artifacts/epics.md#Story-1.4] Criteres d'acceptation
- [Source: _bmad-output/planning-artifacts/prd.md#FR1-FR59] Requirements fonctionnels mappes aux tables
- [Source: _bmad-output/planning-artifacts/prd.md#NFR9] Chiffrement KYC at rest AES-256
- [Source: _bmad-output/planning-artifacts/prd.md#NFR11] Aucun credit wallet sans transaction CinetPay confirmee
- [Source: _bmad-output/planning-artifacts/prd.md#NFR17] Partitionnement geographique par ville prepare (city_id partout)
- [Source: server/crates/domain/src/*/model.rs] Enums Rust existants a mapper
- [Source: server/crates/common/src/types.rs] Id = uuid::Uuid, Timestamp = DateTime<Utc>
- [Source: server/crates/common/src/config.rs] AppConfig avec DATABASE_URL
- [Source: server/crates/infrastructure/src/database/mod.rs] create_pool() avec PgPoolOptions
- [Source: _bmad-output/implementation-artifacts/1-3-docker-compose-infrastructure.md] Ports, variables d'environnement, Docker setup

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Format migration initial avec dossiers (001_create_enums/up.sql) ne fonctionnait pas — SQLx 0.8 utilise des fichiers plats avec suffixes .up.sql/.down.sql
- Restructuration vers format timestamp : `20260317000001_create_enums.up.sql`
- `sqlx::migrate!("./migrations")` echouait car le chemin est relatif a CARGO_MANIFEST_DIR (crates/api/), corrige vers `../../migrations`
- Import `use sqlx::PgPool` retire car inutilise (PgPool utilise indirectement via infrastructure::database)
- Ajout de `sqlx.workspace = true` dans api/Cargo.toml (manquant initialement)

### Completion Notes List

- AC1: 13 migrations appliquees avec succes via `sqlx migrate run` (total ~96ms)
- AC2: Toutes les tables ont UUID PK via gen_random_uuid(), FK correctes avec ON DELETE CASCADE sur relations parent-enfant (merchants→users, products→merchants, order_items→orders, wallets→users, kyc_documents→users)
- AC3: 12 tables creees + _sqlx_migrations systeme. Verifie via `\dt` psql
- AC4: 13 enums PostgreSQL creees correspondant aux enums Rust domain. Verifie via `SELECT typname FROM pg_type WHERE typtype = 'e'`
- AC5: 22 index custom crees + 20 index systeme (PK, UNIQUE). 42 index total via `\di`
- AC6: 30 tests passent sans regression (cargo test --workspace)
- AC7: `cargo build --workspace` compile sans erreur
- AC8: Reversibilite verifiee — `sqlx migrate revert` + `sqlx migrate run` fonctionnent correctement
- Bonus: Fonction trigger_set_updated_at() + triggers sur toutes les tables avec updated_at
- Bonus: CHECK constraints sur montants (>= 0), quantites (> 0), et sponsorships (sponsor != sponsored)

### Change Log

- 2026-03-17: Implementation complete des 13 migrations SQLx (Story 1.4)
- 2026-03-17: Integration sqlx::migrate!() dans api/src/main.rs avec db_pool
- 2026-03-17: Code review — Dev Notes corrigees (format fichiers migration), Cargo.lock ajoute au File List

### File List

- server/migrations/20260317000001_create_enums.up.sql (CREE)
- server/migrations/20260317000001_create_enums.down.sql (CREE)
- server/migrations/20260317000002_create_city_config.up.sql (CREE)
- server/migrations/20260317000002_create_city_config.down.sql (CREE)
- server/migrations/20260317000003_create_users.up.sql (CREE)
- server/migrations/20260317000003_create_users.down.sql (CREE)
- server/migrations/20260317000004_create_merchants.up.sql (CREE)
- server/migrations/20260317000004_create_merchants.down.sql (CREE)
- server/migrations/20260317000005_create_products.up.sql (CREE)
- server/migrations/20260317000005_create_products.down.sql (CREE)
- server/migrations/20260317000006_create_wallets.up.sql (CREE)
- server/migrations/20260317000006_create_wallets.down.sql (CREE)
- server/migrations/20260317000007_create_orders.up.sql (CREE)
- server/migrations/20260317000007_create_orders.down.sql (CREE)
- server/migrations/20260317000008_create_order_items.up.sql (CREE)
- server/migrations/20260317000008_create_order_items.down.sql (CREE)
- server/migrations/20260317000009_create_wallet_transactions.up.sql (CREE)
- server/migrations/20260317000009_create_wallet_transactions.down.sql (CREE)
- server/migrations/20260317000010_create_deliveries.up.sql (CREE)
- server/migrations/20260317000010_create_deliveries.down.sql (CREE)
- server/migrations/20260317000011_create_disputes.up.sql (CREE)
- server/migrations/20260317000011_create_disputes.down.sql (CREE)
- server/migrations/20260317000012_create_sponsorships.up.sql (CREE)
- server/migrations/20260317000012_create_sponsorships.down.sql (CREE)
- server/migrations/20260317000013_create_kyc_documents.up.sql (CREE)
- server/migrations/20260317000013_create_kyc_documents.down.sql (CREE)
- server/migrations/.gitkeep (SUPPRIME)
- server/crates/api/src/main.rs (MODIFIE — ajout db_pool + sqlx::migrate!())
- server/crates/api/Cargo.toml (MODIFIE — ajout sqlx.workspace = true)
- server/Cargo.lock (MODIFIE — auto-genere suite a ajout sqlx dans api)
