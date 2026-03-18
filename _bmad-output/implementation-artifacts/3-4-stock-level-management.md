# Story 3.4: Gestion des niveaux de stock

Status: done

## Story

As a marchand,
I want to gérer les niveaux de stock de mes produits et recevoir des alertes,
so that je ne vende pas de produits indisponibles et que j'anticipe les ruptures.

## Acceptance Criteria (AC)

1. **AC1 — Ajustement stock manuel (FR9)** : Le marchand peut modifier le stock d'un produit via un bottom sheet dédié (champ numérique, validation >= 0).

2. **AC2 — Alerte stock bas (FR44)** : Quand le stock d'un produit descend sous 20% du `initial_stock`, une alerte est créée automatiquement en DB. L'alerte apparaît dans une section dédiée côté B2B. Le marchand peut acquitter l'alerte. Maximum 1 alerte non-acquittée par produit.

3. **AC3 — Produit indisponible à stock 0 (FR9)** : Un produit avec `stock = 0` affiche "Indisponible" (badge rouge) dans le catalogue B2B.

4. **AC4 — Badges stock sur liste produits (FR9)** : La grille produits affiche un badge coloré par produit : vert (stock OK > 20%), orange (stock bas <= 20%), rouge (stock = 0). Filtres chips : "Tous", "Stock bas", "Indisponible" (filtrage client-side sur la liste déjà chargée).

5. **AC5 — Décrément atomique (préparation commandes)** : Un endpoint `POST /api/v1/products/{id}/decrement-stock` permet de décrémenter le stock de manière atomique (`UPDATE ... WHERE stock >= $2`, single-row atomic en PostgreSQL). Retourne 409 Conflict si stock insuffisant.

## Tasks / Subtasks

### Backend Rust

- [x] **T1** — Migration `server/migrations/20260317000017_create_stock_alerts.up.sql` (AC: #2)
  - [x] T1.1 — CREATE TABLE stock_alerts with all columns
  - [x] T1.2 — Index idx_stock_alerts_merchant_id, idx_stock_alerts_product_id
  - [x] T1.3 — Fichier down: DROP TABLE stock_alerts;

- [x] **T2** — Domain : module stock alerts (AC: #2)
  - [x] T2.1 — model.rs : StockAlert (sqlx::FromRow) + UpdateStockPayload + DecrementStockPayload with validation
  - [x] T2.2 — repository.rs : create_stock_alert(), find_alerts_by_merchant(), acknowledge_alert(), find_unacknowledged_alert()
  - [x] T2.3 — service.rs : check_and_create_alert() — seuil 20%, anti-doublon

- [x] **T3** — Domain : ajustement et décrément stock (AC: #1, #5)
  - [x] T3.1 — service.rs : update_stock() — validation + ownership + alert check
  - [x] T3.2 — repository.rs : update_stock() — SET stock = $2, updated_at = NOW()
  - [x] T3.3 — repository.rs : decrement_stock_atomic() — SET stock = stock - $2 WHERE stock >= $2
  - [x] T3.4 — service.rs : decrement_stock() — ownership + atomic + alert + AppError::Conflict

- [x] **T4** — Routes API (AC: #1, #2, #5)
  - [x] T4.1 — PUT /api/v1/products/{id}/stock — JSON body, require_role Merchant
  - [x] T4.2 — GET /api/v1/merchants/me/stock-alerts — unacknowledged alerts
  - [x] T4.3 — POST /api/v1/stock-alerts/{id}/acknowledge
  - [x] T4.4 — POST /api/v1/products/{id}/decrement-stock — JSON body, 409 on insufficient
  - [x] T4.5 — Routes registered in mod.rs

- [x] **T5** — Tests backend (AC: tous)
  - [x] T5.1 — Model validation tests: UpdateStockPayload (valid, zero, negative), DecrementStockPayload (valid, zero, negative)
  - [x] T5.2 — Service tests: UpdateStockPayload + DecrementStockPayload validation in service module
  - [x] T5.3 — Service tests: ownership check (existing tests cover verify_ownership)
  - [x] T5.4 — Service tests: decrement payload validation (quantity=0 fails)

### Flutter B2B

- [x] **T6** — Modèles Dart (AC: #2)
  - [x] T6.1 — StockAlert model with @JsonSerializable + build_runner generated
  - [x] T6.2 — Exported from mefali_core barrel file

- [x] **T7** — API Client (AC: #1, #2, #4, #5)
  - [x] T7.1 — ProductEndpoint: updateProductStock(), getStockAlerts(), acknowledgeAlert(), decrementStock()
  - [x] T7.2 — Providers: stockAlertsProvider + updateStock()/acknowledgeAlert() in ProductCatalogueNotifier

- [x] **T8** — UI : Badges stock sur ProductListScreen (AC: #4)
  - [x] T8.1 — _StockBadge widget: green check / orange warning / red error based on stock ratio
  - [x] T8.2 — FilterChip row: "Tous", "Stock bas", "Indisponible" with client-side filtering

- [x] **T9** — UI : Modification stock inline (AC: #1)
  - [x] T9.1 — Bottom sheet with TextFormField numeric + "Mettre a jour" button, opened via badge tap
  - [x] T9.2 — Inline validation (>= 0, numeric), green SnackBar success / red persistent error
  - [x] T9.3 — Invalidates merchantProductsProvider + stockAlertsProvider after update

- [x] **T10** — UI : Liste alertes stock (AC: #2)
  - [x] T10.1 — _StockAlertsSection at top of Catalogue tab (hidden if no alerts)
  - [x] T10.2 — Alert card: product name, stock/initial, "Vu" acknowledge button
  - [x] T10.3 — Orange color scheme, notification_important icon
  - [x] T10.4 — Invalidates stockAlertsProvider after acknowledgement

- [x] **T11** — Tests Flutter (AC: #1, #2, #4)
  - [x] T11.1 — Widget tests: green/orange/red badges, filter chips, stock count display
  - [x] T11.2 — Widget test: badge icon rendering (check_circle/warning/error)
  - [x] T11.3 — Widget test: alerts section with product name, stock counts, "Vu" button

## Dev Notes

### Contexte métier

Le stock est LE facteur de rétention marchand. Métrique nord : **réduction ruptures de stock > 30% en 60 jours**. L'émotion cible est "Compétence" — Adjoua anticipe au lieu de subir. Le stock = 0 DOIT bloquer les commandes B2C (story 4.3, pas cette story).

### Ce qui EXISTE déjà (NE PAS recréer)

La table `products` contient déjà `stock INT` et `initial_stock INT`. Le modèle Rust `Product` et le modèle Dart `Product` incluent ces champs. Le CRUD produit complet (GET/POST/PUT/DELETE `/api/v1/products`) est fonctionnel. `ProductFormScreen` a déjà un champ stock lors de la création/édition. Le endpoint `PUT /api/v1/products/{id}` accepte déjà `stock` dans le payload multipart.

**Fichiers existants à ÉTENDRE (pas de nouveau fichier sauf `stock_alert.dart` et migration) :**
- `server/crates/domain/src/products/model.rs` — ajouter `StockAlert` struct
- `server/crates/domain/src/products/repository.rs` — ajouter queries alertes + décrément atomique
- `server/crates/domain/src/products/service.rs` — ajouter logique alertes + décrément
- `server/crates/api/src/routes/products.rs` — ajouter handlers stock
- `packages/mefali_api_client/lib/endpoints/product_endpoint.dart` — ajouter méthodes stock
- `packages/mefali_api_client/lib/providers/product_catalogue_provider.dart` — ajouter providers alertes
- `apps/mefali_b2b/lib/features/catalogue/product_list_screen.dart` — badges + filtre + bottom sheet

### Patterns à suivre (établis par story 3.3)

**Rust :**
- Ownership check obligatoire : `product.merchant_id == merchant.id` via `service::verify_ownership()`
- Résolution merchant : `service::resolve_merchant_id(pool, auth.user_id)` avant toute opération
- Auth : `require_role(&auth, &[UserRole::Merchant])?`
- Réponse : `ApiResponse::new(json!({ "key": value }))` wrappé dans `{"data": {...}}`
- Erreur : `AppError::BadRequest`, `AppError::NotFound`, `AppError::Forbidden`. Si `AppError::Conflict` n'existe pas, l'ajouter dans `common/src/error.rs` avec `fn error_response() → HttpResponse::Conflict()`
- SQL : `RETURNING *` sur les mutations, `COALESCE` pour les updates partiels
- Timestamps : `updated_at = NOW()` sur toute mutation

**Flutter :**
- Provider lecture : `FutureProvider.autoDispose`
- Provider mutations : `StateNotifier<AsyncValue<void>>` avec `AsyncValue.guard()`
- Invalidation après mutation : `ref.invalidate(merchantProductsProvider)`
- SnackBar succès : vert, 3s, texte en français
- SnackBar erreur : rouge, persistent (`Duration(days: 1)`), bouton "OK" dismiss
- Loading : skeleton cards (pas spinner seul)
- Bouton submit : `FilledButton` marron `#5D4037`, pleine largeur, disabled + spinner pendant loading
- Clavier : `TextInputType.number` pour stock
- Touch targets : >= 48dp

### Schéma DB existant (migration 005)

```sql
products (
  id UUID PK DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL FK → merchants(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  price BIGINT NOT NULL CHECK (price >= 0),
  stock INT NOT NULL DEFAULT 0,
  initial_stock INT NOT NULL DEFAULT 0,
  photo_url TEXT,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)
```

### Logique alerte seuil 20% (FR44)

```
alert_threshold = initial_stock * 0.20
trigger_alert = stock <= alert_threshold AND initial_stock > 0
```

Règles anti-spam :
- 1 seule alerte non-acquittée par produit à la fois
- Avant de créer, vérifier `SELECT ... WHERE product_id = $1 AND acknowledged_at IS NULL`
- Si déjà une alerte active → ne pas en créer une nouvelle
- L'acquittement ne reset pas le seuil — si le marchand restock au-dessus de 20% puis redescend, une nouvelle alerte peut être créée

### Décrément atomique (pour story 3.6 — commandes)

L'endpoint `POST /api/v1/products/{id}/decrement-stock` est préparé ici mais sera consommé par story 3.6 (Order Reception). La requête SQL `UPDATE products SET stock = stock - $2 WHERE id = $1 AND stock >= $2 RETURNING *` est atomique en PostgreSQL pour les single-row updates (pas besoin de `SELECT ... FOR UPDATE` explicite). Si 0 rows retournées → `AppError::Conflict("Stock insuffisant")`.

### Project Structure Notes

- Les alertes stock restent dans le module `products/` (pas un module séparé) car elles sont intrinsèquement liées au produit
- Pas de table `stock_movements` dans cette story — le tracking détaillé (audit trail complet) sera ajouté si nécessaire en story 3.7 (dashboard). Les `stock_alerts` couvrent FR44
- L'onglet Catalogue du `B2bHomeScreen` (TabBar: Commandes | **Catalogue** | Stats) est le point d'entrée

### Anti-patterns à éviter

- NE PAS créer un nouveau module `server/crates/domain/src/stocks/` — les alertes sont un sous-domaine des produits
- NE PAS ajouter WebSocket pour les alertes — polling via provider suffit pour le MVP
- NE PAS implémenter la notification push/SMS des alertes — sera fait dans une story dédiée
- NE PAS modifier `ProductFormScreen` pour la gestion stock — utiliser un bottom sheet séparé depuis la liste
- NE PAS ajouter `flutter_image_compress` ou multipart — pas de photos dans cette story
- NE PAS implémenter le filtrage B2C des produits stock=0 — c'est story 4.2

### Couleurs badges stock (depuis mefali_design)

| État | Light | Dark | Texte |
|------|-------|------|-------|
| Stock OK (> 20%) | `#4CAF50` (success) | `#81C784` | "En stock" |
| Stock bas (<= 20%) | `#FF9800` (orange) | `#FFB74D` | "Stock bas" |
| Indisponible (= 0) | `#F44336` (error) | `#EF9A9A` | "Indisponible" |

### Git intelligence

Derniers commits : pattern `{story-key}: {status}`. Stories 3.1, 3.2, 3.3 livrées ensemble dans commit 608816d. Code review 3.3 dans b9eb298. Tests : 121 Rust, 165 Flutter, 0 échecs.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.4, FR9, FR44]
- [Source: _bmad-output/planning-artifacts/architecture.md — schema products, API patterns, offline sync]
- [Source: _bmad-output/planning-artifacts/prd.md — FR9, FR44, success metric stock ruptures > 30%]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — badges, couleurs, emotional design "Compétence"]
- [Source: _bmad-output/implementation-artifacts/3-3-product-catalogue-management.md — patterns, fichiers, learnings]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- T1: Migration `20260317000017_create_stock_alerts` created with up/down files, indexes on merchant_id and product_id
- T2: StockAlert struct + UpdateStockPayload + DecrementStockPayload added to model.rs with validation. Repository functions for CRUD alerts + unacknowledged check. Service check_and_create_alert() with 20% threshold and anti-spam logic
- T3: update_stock() and decrement_stock() in service with ownership check. decrement_stock_atomic() in repository returns None if insufficient stock. AppError::Conflict already existed
- T4: 4 new route handlers (update_stock, decrement_stock, list_stock_alerts, acknowledge_alert) registered in mod.rs. Stock routes under /products scope, alerts under /merchants and /stock-alerts scopes
- T5: 10 new Rust unit tests (6 model validation + 4 service validation). Total Rust: 131 tests, 0 failures
- T6: StockAlert Dart model with json_serializable, build_runner generated .g.dart, exported from mefali_core
- T7: 4 new endpoint methods + stockAlertsProvider + updateStock()/acknowledgeAlert() in ProductCatalogueNotifier
- T8: _StockBadge widget with 3 levels (ok/low/unavailable), FilterChip row with client-side filtering
- T9: Stock bottom sheet with numeric input, validation, SnackBar feedback, provider invalidation
- T10: _StockAlertsSection with alert cards, product name resolution, acknowledge button, orange theme
- T11: 6 new widget tests covering badges, filters, alerts section, icon rendering. Total Flutter B2B: 14 tests, 0 failures

### Code Review (2026-03-17)

**Reviewer:** Claude Opus 4.6 (adversarial code review)

**Findings Fixed (3):**
1. **HIGH — Security: acknowledge_alert ownership bypass** — Added `merchant_id` verification to `acknowledge_alert()` in repository SQL (`AND merchant_id = $2`), service, and route handler. A merchant can no longer acknowledge another merchant's alerts.
2. **MEDIUM — Provider invalidation fragility** — Moved `ref.invalidate(merchantProductsProvider + stockAlertsProvider)` from UI layer into `ProductCatalogueNotifier._invalidateLists()`. All mutations now self-invalidate on success. Removed redundant invalidation from `product_list_screen.dart`.
3. **MEDIUM — Test coverage gaps** — Added 4 widget tests: filter chip "Indisponible" interaction, "Stock bas" interaction, "Tous" restore, alert section hidden when empty. Total: 18 tests, 0 failures.

**Verdict:** All ACs implemented, all tasks done, all issues fixed → **done**

### File List

- server/migrations/20260317000017_create_stock_alerts.up.sql (new)
- server/migrations/20260317000017_create_stock_alerts.down.sql (new)
- server/crates/domain/src/products/model.rs (modified)
- server/crates/domain/src/products/repository.rs (modified)
- server/crates/domain/src/products/service.rs (modified)
- server/crates/api/src/routes/products.rs (modified)
- server/crates/api/src/routes/mod.rs (modified)
- packages/mefali_core/lib/models/stock_alert.dart (new)
- packages/mefali_core/lib/models/stock_alert.g.dart (generated)
- packages/mefali_core/lib/mefali_core.dart (modified)
- packages/mefali_api_client/lib/endpoints/product_endpoint.dart (modified)
- packages/mefali_api_client/lib/providers/product_catalogue_provider.dart (modified)
- apps/mefali_b2b/lib/features/catalogue/product_list_screen.dart (modified)
- apps/mefali_b2b/test/widget_test.dart (modified)
