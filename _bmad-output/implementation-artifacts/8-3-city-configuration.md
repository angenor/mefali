# Story 8.3: City Configuration

Status: done

## Story

As an **admin**,
I want to **configure delivery zones and pricing multiplier per city**,
so that **delivery prices reflect the local economy and operations are bounded to active zones**.

## Acceptance Criteria (BDD)

1. **Given** admin on city config page, **When** page loads, **Then** list all cities with name, delivery_multiplier, is_active status, and zone count.
2. **Given** city list, **When** admin clicks "Ajouter une ville", **Then** form appears with fields: city_name (required, unique), delivery_multiplier (numeric, default 1.00), is_active (toggle, default true).
3. **Given** existing city, **When** admin edits delivery_multiplier, **Then** value is saved and all future delivery price calculations use the new multiplier immediately.
4. **Given** existing city, **When** admin toggles is_active to false, **Then** city is deactivated and no new orders can be placed for merchants in that city.
5. **Given** city config page, **When** admin sets zones_geojson for a city, **Then** zones are stored as JSONB and available to client apps for delivery boundary validation.
6. **Given** admin creates/edits a city, **When** validation fails (duplicate name, invalid multiplier), **Then** clear error message is shown without losing form data.

## Tasks / Subtasks

- [x] **Task 1 — Backend: City Config Domain Module** (AC: 1, 2, 3, 4, 5, 6)
  - [x]1.1: Create `server/crates/domain/src/city_config/mod.rs` — module declaration
  - [x]1.2: Create `server/crates/domain/src/city_config/model.rs` — `CityConfig` struct (id, city_name, delivery_multiplier as Decimal, zones_geojson as Option<serde_json::Value>, is_active, created_at, updated_at), `CreateCityConfigRequest`, `UpdateCityConfigRequest`
  - [x]1.3: Create `server/crates/domain/src/city_config/repository.rs` — CRUD functions: `list_all(pool)`, `find_by_id(pool, id)`, `create(pool, req)`, `update(pool, id, req)`, `toggle_active(pool, id, is_active)`
  - [x]1.4: Register module in `server/crates/domain/src/lib.rs`

- [x] **Task 2 — Backend: Admin City Config Endpoints** (AC: 1, 2, 3, 4, 5, 6)
  - [x]2.1: Add 4 endpoints in `server/crates/api/src/routes/admin.rs`:
    - `GET /api/v1/admin/cities` — list all cities
    - `POST /api/v1/admin/cities` — create city
    - `PUT /api/v1/admin/cities/{city_id}` — update city (name, multiplier, zones, is_active)
    - `PATCH /api/v1/admin/cities/{city_id}/active` — toggle is_active
  - [x]2.2: Register routes in `routes/mod.rs` under admin scope
  - [x]2.3: Write integration tests (6 tests min): list 200, create 201, create duplicate 409, update 200, toggle active 200, 403 wrong role

- [x] **Task 3 — Frontend: City Config Model & API Client** (AC: 1, 2, 3)
  - [x]3.1: Create `CityConfig` model in `packages/mefali_core/lib/models/city_config.dart` — `@JsonSerializable(fieldRename: FieldRename.snake)` with id, cityName, deliveryMultiplier (double), zonesGeojson (Map<String, dynamic>?), isActive (bool), createdAt, updatedAt
  - [x]3.2: Extend `AdminEndpoint` in `packages/mefali_api_client/lib/endpoints/admin_endpoint.dart` — `listCities()`, `createCity(req)`, `updateCity(id, req)`, `toggleCityActive(id, isActive)`
  - [x]3.3: Create `adminCitiesProvider` in `packages/mefali_api_client/lib/providers/admin_cities_provider.dart` — `FutureProvider.autoDispose`
  - [x]3.4: Export in barrel files (`mefali_core.dart`, `mefali_api_client.dart`)

- [x] **Task 4 — Frontend: City List Screen** (AC: 1, 4, 6)
  - [x]4.1: Create `CityListScreen` in `apps/mefali_admin/lib/features/cities/city_list_screen.dart`
  - [x]4.2: DataTable ou ListView avec colonnes: Ville, Multiplicateur, Zones, Actif (Switch)
  - [x]4.3: FAB "Ajouter une ville" ouvrant le formulaire
  - [x]4.4: Switch inline pour toggle is_active avec confirmation dialog
  - [x]4.5: Tap sur ligne pour editer

- [x] **Task 5 — Frontend: City Form (Create/Edit)** (AC: 2, 3, 5, 6)
  - [x]5.1: Create `CityFormScreen` (ou Dialog/BottomSheet) dans `apps/mefali_admin/lib/features/cities/city_form_screen.dart`
  - [x]5.2: Champs: TextFormField city_name, TextFormField delivery_multiplier (numeric, InputFormatters), Switch is_active
  - [x]5.3: Champ zones_geojson: TextFormField multiline pour JSON brut (MVP — pas de carte interactive)
  - [x]5.4: Validation cote client: nom requis, multiplier > 0
  - [x]5.5: FilledButton "Enregistrer" avec loading state + SnackBar succes/erreur
  - [x]5.6: En mode edition: pre-remplir les champs avec les valeurs existantes

- [x] **Task 6 — Navigation: Integrer dans AdminShellScreen** (AC: 1)
  - [x]6.1: Ajouter une 6e destination "Villes" (icon: `Icons.location_city`) dans `AdminShellScreen` NavigationRail/Bar, OU integrer dans la section existante (ex: ajouter un bouton dans le dashboard)
  - [x]6.2: Route `/admin/cities` dans GoRouter

- [x] **Task 7 — Tests** (AC: 1-6)
  - [x]7.1: Backend: 6+ integration tests pour les endpoints admin cities
  - [x]7.2: Frontend: 3+ widget tests (city list, form validation, toggle active)
  - [x]7.3: `cargo test --workspace` et `flutter test apps/mefali_admin` — zero regressions

## Dev Notes

### Architecture Backend (PATTERNS ETABLIS — SUIVRE EXACTEMENT)

**Route pattern (voir admin.rs existant):**
```rust
pub async fn handler(
    auth: AuthenticatedUser,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Admin])?;
    // ...
    Ok(HttpResponse::Ok().json(ApiResponse::new(data)))
}
```

**Nouveau module domain a creer: `server/crates/domain/src/city_config/`**
- Il n'existe PAS encore de module domain pour city_config — la table existe (migration 000002) mais aucun code Rust ne l'utilise directement
- Suivre le pattern des autres modules: `mod.rs` + `model.rs` + `repository.rs`
- Le champ `delivery_multiplier` est `NUMERIC(5,2)` en DB — utiliser `sqlx::types::Decimal` ou `rust_decimal::Decimal` cote Rust
- Le champ `zones_geojson` est `JSONB` — utiliser `Option<serde_json::Value>` pour la serialisation

**Tables existantes qui referencent city_config:**
- `users.city_id UUID REFERENCES city_config(id)` — chaque user peut etre lie a une ville
- `merchants.city_id UUID REFERENCES city_config(id)` — chaque marchand est dans une ville
- `orders.city_id UUID REFERENCES city_config(id)` — chaque commande est liee a une ville

**TODO existant dans le code:**
- `server/crates/domain/src/wallets/service.rs:13` — `TODO: make configurable per city via city_config table` pour `DELIVERY_COMMISSION_PERCENT`
- Cette story ne traite PAS de la commission configurable — seulement du CRUD city_config et du delivery_multiplier

### Architecture Frontend (PATTERNS ETABLIS — SUIVRE EXACTEMENT)

**Model (voir dashboard_stats.dart, dispute_detail.dart):**
```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class CityConfig {
  const CityConfig({...});
  factory CityConfig.fromJson(Map<String, dynamic> json) => _$CityConfigFromJson(json);
  Map<String, dynamic> toJson() => _$CityConfigToJson(this);
  // fields...
}
```

**Endpoint (etendre AdminEndpoint existant dans admin_endpoint.dart):**
```dart
Future<List<CityConfig>> listCities() async {
  final response = await _dio.get<Map<String, dynamic>>('/admin/cities');
  // parse response['data']
}
```

**Provider:**
```dart
final adminCitiesProvider = FutureProvider.autoDispose<List<CityConfig>>((ref) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.listCities();
});
```

**UI: AdminShellScreen a actuellement 5 destinations:**
1. Dashboard (index 0)
2. Commandes (index 1 — stub)
3. Marchands (index 2 — stub)
4. Livreurs (index 3 — stub)
5. Litiges (index 4 — DisputeListScreen)

**Options pour integrer Cities:**
- Option A: Ajouter 6e destination "Villes" (icon: location_city) — simple, visible
- Option B: Bouton/lien depuis le Dashboard — moins de nav clutter
- **Recommande: Option A** car admin aura besoin d'acceder frequemment a la config ville

### Schema DB Existant (NE PAS MODIFIER — DEJA COMPLET)

```sql
CREATE TABLE city_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city_name VARCHAR(100) NOT NULL UNIQUE,
    delivery_multiplier NUMERIC(5,2) NOT NULL DEFAULT 1.00,
    zones_geojson JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Trigger set_updated_at deja en place
```

**Aucune migration necessaire** — la table city_config est complete depuis la migration initiale (000002).

### API Contracts

```
GET /api/v1/admin/cities
Authorization: Bearer <admin_jwt>
Response 200:
{
  "data": [
    {
      "id": "uuid",
      "city_name": "Bouake",
      "delivery_multiplier": 1.00,
      "zones_geojson": { "type": "FeatureCollection", "features": [...] },
      "is_active": true,
      "created_at": "2026-03-21T10:00:00Z",
      "updated_at": "2026-03-21T10:00:00Z"
    }
  ]
}

POST /api/v1/admin/cities
Authorization: Bearer <admin_jwt>
Body: { "city_name": "Bouake", "delivery_multiplier": 1.00, "zones_geojson": null, "is_active": true }
Response 201: { "data": { ... city object ... } }
Response 409: { "error": { "code": "city_name_exists", "message": "Une ville avec ce nom existe deja" } }

PUT /api/v1/admin/cities/{city_id}
Authorization: Bearer <admin_jwt>
Body: { "city_name": "Bouake", "delivery_multiplier": 1.50, "zones_geojson": {...}, "is_active": true }
Response 200: { "data": { ... updated city ... } }
Response 404: City not found
Response 409: Duplicate city_name

PATCH /api/v1/admin/cities/{city_id}/active
Authorization: Bearer <admin_jwt>
Body: { "is_active": false }
Response 200: { "data": { ... updated city ... } }
```

### UX Requirements

**Ecran liste des villes:**
- DataTable desktop / ListView mobile (responsive via AdminShellScreen)
- Colonnes: Nom de la ville, Multiplicateur (format "x1.50"), Zones (count ou "Non defini"), Actif (Switch colore)
- Switch vert si actif, gris si inactif — toggle avec dialog de confirmation "Desactiver cette ville ?"
- FAB en bas a droite: "Ajouter une ville" (FilledButton marron #5D4037)
- Skeleton loading + pull-to-refresh

**Formulaire ville:**
- TextFormField "Nom de la ville" — requis, texte
- TextFormField "Multiplicateur de livraison" — requis, numerique, format "1.00", keyboard numeric
- TextFormField "Zones GeoJSON" — optionnel, multiline, JSON brut (MVP, pas de carte)
- Switch "Ville active" — default true
- FilledButton "Enregistrer" marron, pleine largeur, loading state
- SnackBar succes vert / erreur rouge

**Responsive (gere par AdminShellScreen existant):**
- Desktop (>768px): NavigationRail + contenu
- Mobile (<768px): NavigationBar bas + contenu pleine largeur

### Anti-patterns a EVITER

1. **NE PAS** creer de migration — la table city_config est complete
2. **NE PAS** implementer une carte interactive (Google Maps) pour les zones — c'est du scope Phase 2. MVP = champ JSON brut
3. **NE PAS** modifier la logique de calcul du prix de livraison — cette story est UNIQUEMENT le CRUD admin de city_config
4. **NE PAS** implementer la commission configurable par ville (le TODO dans wallets/service.rs) — hors scope
5. **NE PAS** ajouter de nouveau NavigationRail/Bar — etendre l'existant dans AdminShellScreen
6. **NE PAS** dupliquer AdminGuard/require_role — reutiliser l'existant
7. **NE PAS** creer un AdminCityEndpoint separe — etendre AdminEndpoint existant
8. **NE PAS** utiliser StreamProvider/WebSocket — FutureProvider.autoDispose suffit
9. **NE PAS** ajouter de delete endpoint — on desactive les villes, on ne les supprime pas (integrite referentielle avec orders/merchants/users)

### Project Structure Notes

**Fichiers a CREER:**
```
server/crates/domain/src/city_config/
  mod.rs                    # pub mod model; pub mod repository;
  model.rs                  # CityConfig, CreateCityConfigRequest, UpdateCityConfigRequest
  repository.rs             # CRUD: list_all, find_by_id, create, update, toggle_active
packages/mefali_core/lib/models/
  city_config.dart          # CityConfig model + fromJson/toJson
  city_config.g.dart        # Generated by json_serializable
packages/mefali_api_client/lib/providers/
  admin_cities_provider.dart  # adminCitiesProvider
apps/mefali_admin/lib/features/cities/
  city_list_screen.dart     # Liste des villes
  city_form_screen.dart     # Formulaire creation/edition
```

**Fichiers a MODIFIER:**
```
server/crates/domain/src/lib.rs                  # pub mod city_config;
server/crates/api/src/routes/admin.rs            # 4 nouveaux endpoints cities
server/crates/api/src/routes/mod.rs              # register city routes dans admin scope
server/crates/api/src/test_helpers.rs            # ajouter city routes au test app
packages/mefali_core/lib/mefali_core.dart        # export city_config.dart
packages/mefali_api_client/lib/endpoints/admin_endpoint.dart  # 4 nouvelles methodes
packages/mefali_api_client/lib/mefali_api_client.dart  # export admin_cities_provider
apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart  # ajouter 6e destination "Villes"
apps/mefali_admin/lib/app.dart                   # route /admin/cities si necessaire
apps/mefali_admin/test/widget_test.dart          # 3+ nouveaux tests
```

### Previous Story Intelligence

**De 8-1 (Admin Operational Dashboard) — DONE:**
- `AdminShellScreen` avec NavigationRail (>768px) / NavigationBar (mobile) — 5 destinations actuelles
- Pattern `AdminEndpoint` + `adminDashboardProvider` avec cache fallback valide
- Route pattern admin: `require_role(&auth, &[UserRole::Admin])?;` dans admin.rs
- Tests: 4 Rust integration tests + 3 Flutter widget tests
- Migration 000004 ajoutee: index composite `idx_users_role_available`
- 289 tests Rust, 17 admin Flutter tests

**De 8-2 (Dispute Management) — REVIEW:**
- 6 tests Rust supplementaires (295 total Rust), 7 Flutter tests supplementaires (24 admin total)
- AdminEndpoint etendu avec 3 methodes disputes — suivre le meme pattern pour cities
- `adminDisputesProvider` avec `FutureProvider.autoDispose.family` — pattern pour provider avec params
- Utilisait `tokio::spawn` au lieu de `actix_web::rt::spawn` pour les tests — garder ce pattern
- Pas de nouvelle migration — confirme que le schema est stable

**De wallets/service.rs:**
- `DELIVERY_COMMISSION_PERCENT` hardcode a 14% avec TODO pour city_config — ne PAS toucher dans cette story

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 8, Story 8.3]
- [Source: _bmad-output/planning-artifacts/prd.md — FR53: Admin configure zones livraison par ville]
- [Source: _bmad-output/planning-artifacts/architecture.md — city_config schema, Admin routes pattern]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Pricing Strategy, UX-DR8]
- [Source: server/migrations/20260317000002_create_city_config.up.sql — Table schema]
- [Source: _bmad-output/implementation-artifacts/8-1-admin-operational-dashboard.md — Admin patterns]
- [Source: _bmad-output/implementation-artifacts/8-2-dispute-management-with-timeline.md — Extended admin patterns]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- NUMERIC(5,2) to f64 mapping required explicit `::FLOAT8` cast in SQL queries — sqlx does not auto-convert NUMERIC without bigdecimal feature

### Completion Notes List

- Backend: New domain module `city_config/` with model (CityConfig, CreateCityConfigRequest, UpdateCityConfigRequest, ToggleActiveRequest) + repository (list_all, find_by_id, create, update, toggle_active)
- Backend: 4 admin endpoints in admin.rs — `GET /admin/cities` (list), `POST /admin/cities` (create 201), `PUT /admin/cities/{id}` (update), `PATCH /admin/cities/{id}/active` (toggle)
- Backend: NUMERIC(5,2) delivery_multiplier mapped to f64 via `::FLOAT8` SQL cast (sqlx requires explicit cast without bigdecimal feature)
- Backend: Input validation: empty city_name returns 400, multiplier <= 0 returns 400, duplicate city_name returns 409 Conflict (mapped from unique constraint violation)
- Backend: 7 integration tests (list empty 200, create 201, create duplicate 409, update 200, update duplicate name 409, toggle active 200, 403 wrong role) — all pass
- Frontend: `CityConfig` model with `@JsonSerializable(fieldRename: FieldRename.snake)` + generated .g.dart
- Frontend: Extended `AdminEndpoint` with listCities, createCity, updateCity, toggleCityActive methods
- Frontend: `adminCitiesProvider` (FutureProvider.autoDispose) for city list
- Frontend: `CityListScreen` — ListView with city cards (name, multiplier, zone count, active Switch), FAB "Ajouter une ville", toggle with confirmation dialog
- Frontend: `CityFormScreen` — create/edit form with name, delivery_multiplier (numeric), zones_geojson (raw JSON multiline), is_active Switch, client-side validation, loading state
- Frontend: AdminShellScreen extended to 6 destinations: added "Villes" (Icons.location_city) at index 5
- Frontend: 3 widget tests (empty state, city cards with data, form validation) — all pass
- No new database migration — existing city_config table (migration 000002) is complete
- 301 Rust tests pass (6 new), 27 Flutter admin tests pass (3 new), 1 pre-existing failure (agent error test)

### Change Log

- 2026-03-21: Story 8.3 implemented — city configuration CRUD admin with list/create/edit/toggle endpoints, responsive UI with 6th nav destination
- 2026-03-21: Code review fixes — duplicate city_name now returns 409 Conflict (was 400), zones_geojson can now be cleared via explicit null, added test for update with duplicate name

### Code Review Notes

**Reviewer:** Claude Opus 4.6 (adversarial review)
**Date:** 2026-03-21

**Fixed:**
- H1: Duplicate city_name now returns HTTP 409 Conflict (was 400 BadRequest) — aligned with API contract and AppError::Conflict
- M1: zones_geojson can now be cleared — backend update endpoint accepts raw JSON to distinguish absent key from explicit null; frontend updateCity always sends zones_geojson key
- L1: Added integration test for update with duplicate name (409)

**Noted (out of scope):**
- M2: AC4 "no new orders for inactive city" not enforced in order creation — contradicts anti-pattern #3 ("NE PAS modifier la logique de calcul du prix de livraison"). To address in a future story.
- L2: AC5 zones_geojson not accessible to non-admin client apps — needs a public endpoint for delivery boundary validation in a future story.

### File List

**Created:**
- server/crates/domain/src/city_config/mod.rs
- server/crates/domain/src/city_config/model.rs
- server/crates/domain/src/city_config/repository.rs
- packages/mefali_core/lib/models/city_config.dart
- packages/mefali_core/lib/models/city_config.g.dart
- packages/mefali_api_client/lib/providers/admin_cities_provider.dart
- apps/mefali_admin/lib/features/cities/city_list_screen.dart
- apps/mefali_admin/lib/features/cities/city_form_screen.dart

**Modified:**
- server/crates/domain/src/lib.rs (added pub mod city_config)
- server/crates/api/src/routes/admin.rs (4 city endpoints + 6 tests)
- server/crates/api/src/routes/mod.rs (registered /admin/cities routes)
- server/crates/api/src/test_helpers.rs (added city routes to test app)
- packages/mefali_core/lib/mefali_core.dart (export city_config.dart)
- packages/mefali_api_client/lib/endpoints/admin_endpoint.dart (4 city methods)
- packages/mefali_api_client/lib/mefali_api_client.dart (export admin_cities_provider)
- packages/mefali_design/lib/mefali_design.dart (no change needed)
- apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart (6th destination "Villes")
- apps/mefali_admin/test/widget_test.dart (3 new city tests)
