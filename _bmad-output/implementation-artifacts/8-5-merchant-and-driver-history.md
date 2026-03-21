# Story 8.5: Historique Marchand & Livreur

Status: done

## Story

As an **admin**,
I want **un historique détaillé des marchands et livreurs**,
so that **je comprends leur performance et peux prendre des décisions opérationnelles éclairées**.

## Acceptance Criteria

1. **Given** un profil marchand **When** je consulte son historique **Then** je vois : total commandes, taux de complétion, note moyenne, nombre de litiges, statut KYC
2. **Given** un profil livreur **When** je consulte son historique **Then** je vois : total livraisons, taux de complétion, note moyenne, nombre de litiges, statut KYC
3. **Given** la liste marchands **When** elle se charge **Then** elle affiche pagination, recherche par nom, filtres par statut/ville
4. **Given** la liste livreurs **When** elle se charge **Then** elle affiche pagination, recherche par nom, filtres par statut/ville
5. **Given** les onglets "Marchands" et "Livreurs" du shell admin **When** je clique **Then** ils remplacent les stubs "Bientôt disponible" par les écrans fonctionnels
6. **Given** le profil détaillé marchand/livreur **When** affiché **Then** inclut les dernières commandes/livraisons récentes (liste paginée)

## Tasks / Subtasks

### Backend (Rust)

- [x] Task 1 — Endpoint GET `/api/v1/admin/merchants` (AC: #3)
  - [x] 1.1 Ajouter handler `list_merchants_admin` dans `admin.rs` avec pagination (`page`, `per_page`), filtres (`status`, `city_id`, `search`)
  - [x] 1.2 Ajouter query dans `admin.rs` : JOIN city_config, subqueries ratings/orders/disputes, filtre dynamique
  - [x] 1.3 Tests intégration : 200 vide, 200 avec données, 200 recherche, 403 non-admin, 401 sans token

- [x] Task 2 — Endpoint GET `/api/v1/admin/merchants/{merchant_id}/history` (AC: #1, #6)
  - [x] 2.1 Ajouter handler `get_merchant_history` dans `admin.rs`
  - [x] 2.2 Query agrégée : total_orders, completed_orders, avg_rating (depuis ratings), total_disputes, kyc_status
  - [x] 2.3 Liste des dernières commandes paginées (id, status, total, date, client_name)
  - [x] 2.4 Utiliser `tokio::try_join!` pour paralléliser stats + commandes récentes + count
  - [x] 2.5 Tests intégration : 200 avec stats, 404 marchand inexistant, 403

- [x] Task 3 — Endpoint GET `/api/v1/admin/drivers` (AC: #4)
  - [x] 3.1 Ajouter handler `list_drivers_admin` dans `admin.rs` avec pagination, filtres (`status`, `city_id`, `search`, `available`)
  - [x] 3.2 Query : JOIN city_config + filtrer role=driver, COUNT total
  - [x] 3.3 Tests intégration : 200 vide, 200 avec données, 403, 401

- [x] Task 4 — Endpoint GET `/api/v1/admin/drivers/{driver_id}/history` (AC: #2, #6)
  - [x] 4.1 Ajouter handler `get_driver_history` dans `admin.rs`
  - [x] 4.2 Query agrégée : total_deliveries, completed_deliveries, avg_rating, total_disputes, kyc_status
  - [x] 4.3 Liste des dernières livraisons paginées (id, order_id, status, date, merchant_name)
  - [x] 4.4 `tokio::try_join!` pour paralléliser stats + livraisons récentes + count
  - [x] 4.5 Tests intégration : 200, 404, 403

### Frontend — Modèles (Dart)

- [x] Task 5 — Créer modèles dans `packages/mefali_core/lib/models/` (AC: #1-6)
  - [x] 5.1 `admin_merchant.dart` : `AdminMerchantListItem`, `MerchantProfileInfo`, `MerchantHistoryStats`, `MerchantRecentOrder`, `MerchantHistory`, `PaginatedRecentOrders`
  - [x] 5.2 `admin_driver.dart` : `AdminDriverListItem`, `DriverProfileInfo`, `DriverHistoryStats`, `DriverRecentDelivery`, `DriverHistory`, `PaginatedRecentDeliveries`
  - [x] 5.3 Exporter dans `mefali_core.dart`

### Frontend — API Client

- [x] Task 6 — Étendre `AdminEndpoint` dans `admin_endpoint.dart` (AC: #1-6)
  - [x] 6.1 `listMerchants({page, status, cityId, search})` → `({List<AdminMerchantListItem> items, int total})`
  - [x] 6.2 `getMerchantHistory(merchantId, {page})` → `MerchantHistory`
  - [x] 6.3 `listDrivers({page, status, cityId, search, available})` → `({List<AdminDriverListItem> items, int total})`
  - [x] 6.4 `getDriverHistory(driverId, {page})` → `DriverHistory`

- [x] Task 7 — Créer providers Riverpod (AC: #1-6)
  - [x] 7.1 `admin_merchants_provider.dart` : `MerchantListParams` + `adminMerchantsProvider` (FutureProvider.autoDispose.family) + `merchantHistoryProvider`
  - [x] 7.2 `admin_drivers_provider.dart` : `DriverListParams` + `adminDriversProvider` + `driverHistoryProvider`
  - [x] 7.3 Exporter dans `mefali_api_client.dart`

### Frontend — UI Screens

- [x] Task 8 — Écran liste marchands (AC: #3, #5)
  - [x] 8.1 Créer `apps/mefali_admin/lib/features/merchants/merchant_list_screen.dart`
  - [x] 8.2 Chips de filtre (statut marchand) + champ recherche
  - [x] 8.3 DataTable avec colonnes : nom, statut, ville, categorie, commandes, note, litiges
  - [x] 8.4 Pagination + asyncValue.when()
  - [x] 8.5 Tap → Navigator.push(MerchantDetailScreen)

- [x] Task 9 — Écran détail/historique marchand (AC: #1, #6)
  - [x] 9.1 Créer `apps/mefali_admin/lib/features/merchants/merchant_detail_screen.dart`
  - [x] 9.2 Card profil : nom, adresse, statut, catégorie, KYC status, date inscription
  - [x] 9.3 Cards stats : total commandes, taux complétion, note moyenne, litiges
  - [x] 9.4 Liste commandes récentes paginée (DataTable)

- [x] Task 10 — Écran liste livreurs (AC: #4, #5)
  - [x] 10.1 Créer `apps/mefali_admin/lib/features/drivers/driver_list_screen.dart`
  - [x] 10.2 Chips de filtre (statut, disponibilité) + champ recherche
  - [x] 10.3 DataTable avec colonnes : nom, statut, ville, livraisons, note, litiges, disponible
  - [x] 10.4 Pagination + asyncValue.when()
  - [x] 10.5 Tap → Navigator.push(DriverDetailScreen)

- [x] Task 11 — Écran détail/historique livreur (AC: #2, #6)
  - [x] 11.1 Créer `apps/mefali_admin/lib/features/drivers/driver_detail_screen.dart`
  - [x] 11.2 Card profil : nom, téléphone, statut, KYC status, sponsor, date inscription
  - [x] 11.3 Cards stats : total livraisons, taux complétion, note moyenne, litiges
  - [x] 11.4 Liste livraisons récentes paginée (DataTable)

### Navigation & Intégration

- [x] Task 12 — Remplacer stubs dans AdminShellScreen (AC: #5)
  - [x] 12.1 Index 2 ("Marchands") → MerchantListScreen
  - [x] 12.2 Index 3 ("Livreurs") → DriverListScreen
  - [x] 12.3 Conserver index 1 ("Commandes") en stub (hors scope)

### Tests

- [x] Task 13 — Tests widget Flutter (AC: #1-6)
  - [x] 13.1 Test MerchantListScreen : état vide, données, filtre (3 tests)
  - [x] 13.2 Test MerchantDetailScreen : stats affichées, commandes récentes (1 test)
  - [x] 13.3 Test DriverListScreen : état vide, données, filtre (3 tests)
  - [x] 13.4 Test DriverDetailScreen : stats affichées, livraisons récentes (1 test)

## Dev Notes

### Patterns obligatoires (établis dans 8-1 à 8-4)

**Backend :**
- Tous les handlers dans `server/crates/api/src/routes/admin.rs` (fichier unique)
- Guard : `require_role(&auth, &[UserRole::Admin])?;` en début de chaque handler
- Réponse : `ApiResponse::new(data)` pour objets, `ApiResponse::with_pagination(items, page, per_page, total)` pour listes
- Queries parallèles : `tokio::try_join!` (PAS `actix_web::rt::spawn`)
- Tests : `#[sqlx::test(migrations = "../../migrations")]` + `test_helpers::test_app(pool)`
- Enregistrer les routes dans `mod.rs` via scope admin

**Frontend :**
- Modèles dans `packages/mefali_core/lib/models/` avec `@JsonSerializable(fieldRename: FieldRename.snake)`
- Étendre `AdminEndpoint` existant (NE PAS créer de nouvelle classe endpoint)
- Providers dans `packages/mefali_api_client/lib/providers/admin_*_provider.dart`
- Type provider : `FutureProvider.autoDispose.family` pour requêtes paramétrées
- UI : `asyncValue.when(data:, loading:, error:)` avec shimmer pour loading
- Navigation : `Navigator.push` pour écrans détail (pas GoRouter dans le shell)
- Refresh : `ref.invalidate(provider)` après mutations

### Anti-patterns à éviter

- NE PAS créer de modules domain séparés pour admin — utiliser les repositories existants (`orders/repository.rs`, `deliveries/repository.rs`, `merchants/repository.rs`)
- NE PAS utiliser WebSocket/StreamProvider pour les listes — `ref.invalidate()` suffit
- NE PAS créer de migrations sauf si le schéma est incomplet — les données existent déjà dans les tables orders, deliveries, merchants, users, ratings, disputes
- NE PAS modifier les endpoints client B2C depuis cette story admin
- NE PAS implémenter de graphiques/charts — données tabulaires uniquement

### Calculs côté backend (SQL)

**Taux de complétion marchand :**
```sql
SELECT
  COUNT(*) AS total_orders,
  COUNT(*) FILTER (WHERE status = 'delivered') AS completed_orders,
  ROUND(COUNT(*) FILTER (WHERE status = 'delivered')::NUMERIC / NULLIF(COUNT(*), 0) * 100, 1) AS completion_rate
FROM orders WHERE merchant_id = $1
```

**Note moyenne :** Depuis table `ratings` en JOIN sur `order_id` → `merchant_id` ou `driver_id`

**Litiges :** `SELECT COUNT(*) FROM disputes d JOIN orders o ON d.order_id = o.id WHERE o.merchant_id = $1`

**KYC status :** Depuis `users.kyc_status` ou champ équivalent (vérifier le schéma existant)

### AdminShellScreen — État actuel des indices

| Index | Label | Icône | État actuel | Action 8-5 |
|-------|-------|-------|-------------|------------|
| 0 | Dashboard | dashboard | ✅ Fonctionnel | Aucune |
| 1 | Commandes | receipt_long | ⏳ Stub | Garder stub (hors scope) |
| 2 | Marchands | store | ⏳ Stub | → MerchantListScreen |
| 3 | Livreurs | moped | ⏳ Stub | → DriverListScreen |
| 4 | Litiges | warning_amber | ✅ Fonctionnel | Aucune |
| 5 | Villes | location_city | ✅ Fonctionnel | Aucune |
| 6 | Comptes | people | ✅ Fonctionnel | Aucune |

### Modèles de réponse API attendus

**GET /api/v1/admin/merchants?page=1&per_page=20&search=&status=&city_id=**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Restaurant Chez Amina",
      "status": "open",
      "city_name": "Bouake",
      "category": "restaurant",
      "orders_count": 47,
      "avg_rating": 4.2,
      "disputes_count": 2,
      "created_at": "2026-01-15T08:00:00Z"
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 85 }
}
```

**GET /api/v1/admin/merchants/{id}/history?page=1&per_page=10**
```json
{
  "data": {
    "merchant": {
      "id": "uuid",
      "name": "Restaurant Chez Amina",
      "address": "Rue du Commerce, Bouake",
      "status": "open",
      "category": "restaurant",
      "kyc_status": "verified",
      "created_at": "2026-01-15T08:00:00Z"
    },
    "stats": {
      "total_orders": 47,
      "completed_orders": 44,
      "completion_rate": 93.6,
      "avg_rating": 4.2,
      "total_disputes": 2,
      "resolved_disputes": 2
    },
    "recent_orders": {
      "items": [
        {
          "id": "uuid",
          "status": "delivered",
          "total": 3500,
          "customer_name": "Kouamé Jean",
          "created_at": "2026-03-20T12:00:00Z"
        }
      ],
      "page": 1,
      "per_page": 10,
      "total": 47
    }
  }
}
```

**GET /api/v1/admin/drivers?page=1&per_page=20&search=&status=&city_id=&available=**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Traoré Moussa",
      "status": "active",
      "city_name": "Bouake",
      "deliveries_count": 83,
      "avg_rating": 4.7,
      "disputes_count": 0,
      "available": true,
      "created_at": "2026-02-01T09:00:00Z"
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 32 }
}
```

**GET /api/v1/admin/drivers/{id}/history?page=1&per_page=10**
```json
{
  "data": {
    "driver": {
      "id": "uuid",
      "name": "Traoré Moussa",
      "phone": "+225xxxxxxxx",
      "status": "active",
      "kyc_status": "verified",
      "sponsor_name": "Koné Ibrahim",
      "available": true,
      "created_at": "2026-02-01T09:00:00Z"
    },
    "stats": {
      "total_deliveries": 83,
      "completed_deliveries": 80,
      "completion_rate": 96.4,
      "avg_rating": 4.7,
      "total_disputes": 0,
      "resolved_disputes": 0
    },
    "recent_deliveries": {
      "items": [
        {
          "id": "uuid",
          "order_id": "uuid",
          "status": "delivered",
          "merchant_name": "Restaurant Chez Amina",
          "delivered_at": "2026-03-20T12:45:00Z"
        }
      ],
      "page": 1,
      "per_page": 10,
      "total": 83
    }
  }
}
```

### Project Structure Notes

- Alignement total avec la structure existante du monorepo
- Pas de nouveau crate/package — tout s'intègre dans les fichiers existants
- Les queries SQL utilisent les tables existantes (orders, deliveries, merchants, users, ratings, disputes) — aucune migration nécessaire
- Vérifier l'existence de la table `ratings` et son schéma exact avant d'écrire les queries de note moyenne

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 8, Story 8.5]
- [Source: _bmad-output/planning-artifacts/prd.md — FR55: Admin peut consulter l'historique marchand et livreur]
- [Source: _bmad-output/planning-artifacts/prd.md — Journey 5 Awa: consulte merchant history 47 orders, driver history 83 deliveries]
- [Source: _bmad-output/planning-artifacts/architecture.md — API patterns, pagination, response wrapper]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — UX-DR8, sidebar navigation, responsive breakpoints]
- [Source: _bmad-output/implementation-artifacts/8-4-account-management.md — patterns établis Epic 8]
- [Source: server/crates/domain/src/disputes/repository.rs — pattern ActorStats et tokio::try_join!]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Completion Notes List

- Backend: 4 endpoints ajoutés dans admin.rs (list_merchants_admin, get_merchant_history, list_drivers_admin, get_driver_history) avec 15 tests d'intégration (tous passent)
- Modèles Dart: admin_merchant.dart (6 classes) et admin_driver.dart (6 classes) avec json_serializable
- API Client: AdminEndpoint étendu avec 4 nouvelles méthodes (listMerchants, getMerchantHistory, listDrivers, getDriverHistory)
- Providers: 2 fichiers (admin_merchants_provider.dart, admin_drivers_provider.dart) avec FutureProvider.autoDispose.family
- UI: 4 écrans créés (MerchantListScreen, MerchantDetailScreen, DriverListScreen, DriverDetailScreen) avec pagination, filtres, et stats cards
- Navigation: AdminShellScreen index 2 et 3 remplacés par les vrais écrans (index 1 reste stub)
- Tests widget: 10 nouveaux tests Flutter (3 merchant list + 1 merchant detail + 3 driver list + 1 driver detail + 2 filter)
- Pas de migration DB nécessaire — toutes les queries utilisent les tables existantes
- KYC status récupéré via subquery sur kyc_documents (pas de colonne kyc_status sur users)
- Note préexistante: le test AgentPerformanceScreen "shows error with retry" échoue indépendamment de cette story

### Debug Log References

### File List

- server/crates/api/src/routes/admin.rs (modified — added 4 handlers + types + helper functions + 15 integration tests)
- server/crates/api/src/routes/mod.rs (modified — registered /admin/merchants and /admin/drivers scopes)
- server/crates/api/src/test_helpers.rs (modified — registered merchant/driver admin routes in test app)
- packages/mefali_core/lib/models/admin_merchant.dart (new)
- packages/mefali_core/lib/models/admin_merchant.g.dart (generated)
- packages/mefali_core/lib/models/admin_driver.dart (new)
- packages/mefali_core/lib/models/admin_driver.g.dart (generated)
- packages/mefali_core/lib/mefali_core.dart (modified — added exports)
- packages/mefali_api_client/lib/endpoints/admin_endpoint.dart (modified — added 4 methods)
- packages/mefali_api_client/lib/providers/admin_merchants_provider.dart (new)
- packages/mefali_api_client/lib/providers/admin_drivers_provider.dart (new)
- packages/mefali_api_client/lib/mefali_api_client.dart (modified — added exports)
- apps/mefali_admin/lib/features/merchants/merchant_list_screen.dart (new)
- apps/mefali_admin/lib/features/merchants/merchant_detail_screen.dart (new)
- apps/mefali_admin/lib/features/drivers/driver_list_screen.dart (new)
- apps/mefali_admin/lib/features/drivers/driver_detail_screen.dart (new)
- apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart (modified — wired index 2 and 3)
- apps/mefali_admin/test/widget_test.dart (modified — added 10 tests)
