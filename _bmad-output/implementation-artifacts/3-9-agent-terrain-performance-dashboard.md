# Story 3.9: Agent Terrain Performance Dashboard

Status: done

## Story

As an agent terrain,
I want my onboarding stats (marchands onboardés, KYC validés, premières commandes reçues),
so that I track my daily performance and atteins mes objectifs quotidiens.

## Acceptance Criteria

1. **AC1 — Merchants Onboarded Count**
   Given I am logged in as agent terrain
   When I view my performance dashboard
   Then I see the count of merchants I have fully onboarded (onboarding_step = 5), broken down by: today, this week (lundi→dimanche), total

2. **AC2 — KYC Validated Count**
   Given I have validated KYC documents for drivers
   When I view my performance dashboard
   Then I see the count of KYC documents I verified (verified_by = my user_id), broken down by: today, this week, total

3. **AC3 — Merchants with First Order**
   Given merchants I onboarded have received orders
   When I view my performance dashboard
   Then I see the count of my onboarded merchants who received at least one delivered order, broken down by: this week, total

4. **AC4 — Recent Onboarded Merchants List**
   Given I view the dashboard
   When data loads
   Then I see a list of the 5 most recently onboarded merchants (name, date, first order status: "Commande reçue" or "En attente")

5. **AC5 — Role Protection**
   Given I am NOT agent or admin role
   When I try to access the agent stats endpoint
   Then I get 403 Forbidden

6. **AC6 — Offline Cache**
   Given I previously loaded stats successfully
   When I lose connectivity and view the dashboard
   Then I see the last cached stats with a banner "Données hors ligne — il y a X min"

7. **AC7 — Loading & Error States**
   Given I open the dashboard
   When stats are loading Then I see skeleton placeholders (never a spinner alone)
   When stats fail to load Then I see an error message with a retry button

## Tasks / Subtasks

### Backend Rust

- [x] T1: Créer le module `agents` dans domain (AC: 1,2,3,4)
  - [x] T1.1: Créer `server/crates/domain/src/agents/mod.rs` — exports module
  - [x] T1.2: Créer `server/crates/domain/src/agents/model.rs` — structs `AgentPerformanceStats`, `PeriodCount`, `RecentMerchant`
  - [x] T1.3: Enregistrer module dans `server/crates/domain/src/lib.rs`

- [x] T2: Créer le repository agents (AC: 1,2,3,4)
  - [x] T2.1: Créer `server/crates/domain/src/agents/repository.rs`
  - [x] T2.2: Implémenter `count_merchants_onboarded(pool, agent_id, start_date, end_date)`
  - [x] T2.3: Implémenter `count_kyc_validated(pool, agent_id, start_date, end_date)`
  - [x] T2.4: Implémenter `count_merchants_with_first_order(pool, agent_id, start_date, end_date)`
  - [x] T2.5: Implémenter `count_merchants_with_first_order_total(pool, agent_id)`
  - [x] T2.6: Implémenter `find_recent_onboarded(pool, agent_id, limit)`

- [x] T3: Créer le service agents (AC: 1,2,3,4)
  - [x] T3.1: Créer `server/crates/domain/src/agents/service.rs`
  - [x] T3.2: Implémenter `get_agent_performance_stats(pool, agent_user_id)` via `tokio::try_join!`

- [x] T4: Créer l'endpoint API (AC: 1,2,3,4,5)
  - [x] T4.1: Créer `server/crates/api/src/routes/agents.rs`
  - [x] T4.2: Implémenter handler `get_my_stats` sur `GET /api/v1/agents/me/stats`
  - [x] T4.3: Enregistrer les routes dans `server/crates/api/src/routes/mod.rs`

- [x] T5: Tests unitaires Rust (AC: 1,2,3,4,5)
  - [x] T5.1: Tests model serde dans `agents/model.rs` (3 tests)
  - [x] T5.2: Tests service dans `agents/service.rs` — calcul bornes semaine/jour (2 tests)
  - [x] T5.3: Tests d'intégration endpoint dans `api/routes/agents.rs` — 200 empty, 200 data, 403 wrong role, 401 no token, 200 admin, isolation (6 tests)

### Flutter Shared (mefali_core)

- [x] T6: Créer le modèle Dart AgentPerformanceStats (AC: 1,2,3,4)
  - [x] T6.1: Créer `packages/mefali_core/lib/models/agent_stats.dart` — classes `AgentPerformanceStats`, `PeriodCount`, `RecentMerchant` avec `@JsonSerializable(fieldRename: FieldRename.snake)`
  - [x] T6.2: Exporter dans `packages/mefali_core/lib/mefali_core.dart`
  - [x] T6.3: Lancer `dart run build_runner build` dans mefali_core pour générer `.g.dart`

### Flutter API Client (mefali_api_client)

- [x] T7: Créer l'endpoint agent (AC: 1,2,3,4)
  - [x] T7.1: Créer `packages/mefali_api_client/lib/endpoints/agent_endpoint.dart`
  - [x] T7.2: Exporter dans `packages/mefali_api_client/lib/mefali_api_client.dart`

- [x] T8: Créer le provider Riverpod (AC: 1,2,3,4,6)
  - [x] T8.1: Créer `packages/mefali_api_client/lib/providers/agent_performance_provider.dart`
  - [x] T8.2: Implémenter `agentPerformanceProvider` — `FutureProvider.autoDispose` avec in-memory cache
  - [x] T8.3: Implémenter `AgentPerformanceState` avec `stats`, `lastSync`, `isCached`
  - [x] T8.4: Implémenter `clearAgentStatsCache()` à appeler au logout
  - [x] T8.5: Exporter dans `packages/mefali_api_client/lib/mefali_api_client.dart`

### Flutter Admin App (mefali_admin)

- [x] T9: Créer l'écran de performance (AC: 1,2,3,4,6,7)
  - [x] T9.1: Créer `apps/mefali_admin/lib/features/dashboard/agent_performance_screen.dart`
  - [x] T9.2: Widget `AgentPerformanceScreen extends ConsumerWidget` avec `AsyncValue.when()`
  - [x] T9.3: Widget `_StatsCards` — 3 cartes avec today/week/total
  - [x] T9.4: Widget `_RecentMerchantsList` — 5 derniers marchands avec badges
  - [x] T9.5: Widget `_CacheBanner` — bandeau offline
  - [x] T9.6: Widget `_SkeletonLoading` — placeholder chargement
  - [x] T9.7: Widget `_ErrorState` — message erreur + retry

- [x] T10: Intégrer dans la navigation admin (AC: 1)
  - [x] T10.1: Ajouter route `/dashboard/performance` dans `apps/mefali_admin/lib/app.dart`
  - [x] T10.2: Ajouter bouton "Mes performances" sur `home_screen.dart`

- [x] T11: Widget tests Flutter (AC: 1,2,3,4,6,7)
  - [x] T11.1: Tester affichage des stats avec mock provider data
  - [x] T11.2: Tester état loading (skeleton, pas de spinner)
  - [x] T11.3: Tester état erreur (retry button)
  - [x] T11.4: Tester bandeau cache offline

## Dev Notes

### Contexte métier

L'agent terrain (Fatou, 29 ans) onboarde 3-5 marchands/jour à Bouaké. En fin de journée, elle consulte son dashboard pour voir : "4/4 objectif atteint". Elle voit aussi que 2 marchands onboardés la semaine dernière ont déjà reçu leurs premières commandes. Ce dashboard est son outil de suivi quotidien.

### Architecture patterns à suivre

**Pattern identique à Story 3-7 (Sales Dashboard)** — ce dashboard est architecturalement le même que le sales dashboard du marchand. Suivre exactement les mêmes patterns :

- **Backend Rust** : Module domain dédié (`agents/`) avec model.rs, repository.rs, service.rs. Requêtes d'agrégation SQL avec `COALESCE(COUNT(...)::BIGINT, 0)`. Orchestration service via `tokio::try_join!` pour les requêtes parallèles. Calcul des bornes de semaine : `today - today.weekday().num_days_from_monday()` pour obtenir lundi.
- **Frontend Flutter** : `FutureProvider.autoDispose` avec in-memory cache global. `ConsumerWidget` avec `AsyncValue.when()`. Skeleton loading, never spinner alone.

### Modèle de réponse API

```json
{
  "data": {
    "merchants_onboarded": {
      "today": 4,
      "this_week": 12,
      "total": 47
    },
    "kyc_validated": {
      "today": 1,
      "this_week": 3,
      "total": 15
    },
    "merchants_with_first_order": {
      "this_week": 2,
      "total": 35
    },
    "recent_merchants": [
      {
        "id": "uuid",
        "name": "Chez Dramane",
        "created_at": "2026-03-19T09:00:00Z",
        "has_first_order": true
      }
    ]
  }
}
```

### Requêtes SQL clés

```sql
-- Marchands onboardés par cet agent dans une période
SELECT COUNT(*) FROM merchants
WHERE created_by_agent_id = $1
  AND onboarding_step = 5
  AND created_at >= $2 AND created_at < $3;

-- KYC validés par cet agent dans une période
SELECT COUNT(*) FROM kyc_documents
WHERE verified_by = $1
  AND status = 'verified'
  AND updated_at >= $2 AND updated_at < $3;

-- Marchands de cet agent ayant reçu au moins 1 commande livrée (cette semaine)
SELECT COUNT(DISTINCT m.id) FROM merchants m
JOIN orders o ON o.merchant_id = m.id
WHERE m.created_by_agent_id = $1
  AND o.status = 'delivered'
  AND o.created_at >= $2 AND o.created_at < $3;

-- 5 derniers marchands onboardés avec statut première commande
SELECT m.id, m.name, m.created_at,
  EXISTS(SELECT 1 FROM orders o WHERE o.merchant_id = m.id AND o.status = 'delivered') as has_first_order
FROM merchants m
WHERE m.created_by_agent_id = $1 AND m.onboarding_step = 5
ORDER BY m.created_at DESC LIMIT 5;
```

### Tables DB existantes utilisées (pas de migration nécessaire)

| Table | Champ clé | Usage |
|-------|-----------|-------|
| `merchants` | `created_by_agent_id` | Lien agent → marchand (déjà en place depuis Story 3-1) |
| `merchants` | `onboarding_step` | 5 = complètement onboardé |
| `kyc_documents` | `verified_by` | UUID de l'agent qui a validé |
| `kyc_documents` | `status` | 'verified' = KYC approuvé |
| `orders` | `merchant_id`, `status` | 'delivered' = commande livrée avec succès |

### Anti-patterns à éviter

- **NE PAS créer de nouvelle migration** — toutes les tables/colonnes nécessaires existent déjà
- **NE PAS hardcoder les bornes de semaine** — utiliser `chrono::Weekday` et `NaiveDate::from_isoywd` pour calculer lundi courant
- **NE PAS utiliser Drift/SQLite** pour le cache — in-memory cache comme le sales dashboard (app admin pas offline-first)
- **NE PAS réutiliser le module `orders/`** — créer un module `agents/` dédié pour la séparation des responsabilités
- **NE PAS oublier `require_role(&auth, &[UserRole::Agent, UserRole::Admin])`** — les deux rôles doivent pouvoir accéder
- **NE PAS utiliser `COUNT(*)` sans `COALESCE`** — pour éviter les NULL en cas de résultat vide, utiliser `COALESCE(COUNT(...)::BIGINT, 0)`

### Code existant à réutiliser

| Composant | Localisation | Pourquoi |
|-----------|-------------|----------|
| Calcul bornes semaine | `orders/service.rs:get_merchant_weekly_stats()` | Pattern identique pour Monday→Sunday |
| `tokio::try_join!` | `orders/service.rs:~ligne 280` | Paralléliser les requêtes d'agrégation |
| `require_role()` | `middleware/role_guard.rs` | Protection d'accès par rôle |
| `AuthenticatedUser` | `extractors/authenticated_user.rs` | Extraire user_id et role du JWT |
| `FutureProvider.autoDispose` | `sales_dashboard_provider.dart` | Pattern provider avec cache |
| `_CacheBanner` / `_SkeletonLoading` | `sales_dashboard_screen.dart` | Widgets UI réutilisables |
| `_formatFcfa` | `sales_dashboard_screen.dart` | Si besoin affichage montants |
| `test_fixtures.rs` | `domain/test_fixtures.rs` | Factories pour tests (users, merchants, orders) |
| `test_helpers.rs` | `api/test_helpers.rs` | `test_app()`, `create_test_jwt()` pour tests d'intégration |

### UX — Design guidelines

- **3 cartes stat** en haut : Marchands Onboardés, KYC Validés, Premières Commandes — chacune avec today/week/total
- **Couleurs** : Vert si valeur > 0 aujourd'hui, gris sinon
- **Grands chiffres** lisibles (TextTheme.headlineLarge pour le nombre principal "today")
- **Liste des 5 derniers marchands** en bas : nom + date + badge "Commande reçue" (vert) ou "En attente" (orange)
- **Touch targets** : ≥ 48dp (Tecno Spark devices)
- **Skeleton loading** : jamais de spinner seul
- **Performance** : < 3s sur 2GB RAM devices

### Project Structure Notes

```
# Backend (nouveau module)
server/crates/domain/src/agents/
  ├── mod.rs
  ├── model.rs      # AgentPerformanceStats, PeriodCount, RecentMerchant
  ├── repository.rs # Requêtes agrégation SQL
  └── service.rs    # get_agent_performance_stats()

server/crates/api/src/routes/agents.rs  # GET /api/v1/agents/me/stats

# Flutter shared (nouveau modèle)
packages/mefali_core/lib/models/agent_stats.dart

# Flutter API client (nouveau endpoint + provider)
packages/mefali_api_client/lib/endpoints/agent_endpoint.dart
packages/mefali_api_client/lib/providers/agent_performance_provider.dart

# Flutter admin app (nouvel écran)
apps/mefali_admin/lib/features/dashboard/agent_performance_screen.dart
```

### Dépendances inter-stories

- **Story 3-1** (done) : `created_by_agent_id` sur merchants, routes onboarding agent
- **Story 3-2** (done) : `verified_by` sur kyc_documents, routes KYC agent
- **Story 3-6** (done) : Table orders avec statut 'delivered'
- **Story 3-7** (done) : Pattern dashboard, agrégation, provider cache — **modèle à suivre**

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 3.9 AC]
- [Source: _bmad-output/planning-artifacts/prd.md — FR50, Journey 4 Fatou]
- [Source: _bmad-output/planning-artifacts/architecture.md — API patterns, Riverpod, DB schemas]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Agent terrain flows, KPI visualizations]
- [Source: _bmad-output/implementation-artifacts/3-7-sales-dashboard.md — Pattern dashboard complet]
- [Source: _bmad-output/implementation-artifacts/3-8-business-hours-management.md — Learnings story précédente]
- [Source: server/crates/domain/src/orders/service.rs — Pattern week calculation + tokio::try_join!]
- [Source: server/crates/domain/src/merchants/model.rs — created_by_agent_id field]
- [Source: server/crates/domain/src/kyc/repository.rs — verified_by usage]
- [Source: packages/mefali_api_client/lib/providers/sales_dashboard_provider.dart — Pattern provider cache]
- [Source: apps/mefali_b2b/lib/features/sales/sales_dashboard_screen.dart — Pattern UI dashboard]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend Rust: Module `agents/` complet (model, repository, service) avec 7 fonctions d'agregation SQL (COALESCE/COUNT), orchestration `tokio::try_join!` pour 9 requetes paralleles
- API: `GET /api/v1/agents/me/stats` avec `require_role(Agent, Admin)`, 6 tests d'integration (200 empty, 200 data, 403 role, 401 token, 200 admin, isolation)
- Test fixtures: `create_test_merchant_for_agent()` et `create_test_verified_kyc()` ajoutees
- Flutter model: `AgentPerformanceStats`, `PeriodCount`, `FirstOrderCount`, `RecentMerchant` avec `@JsonSerializable`
- Flutter provider: `agentPerformanceProvider` FutureProvider.autoDispose avec cache in-memory et fallback DioException
- Flutter UI: `AgentPerformanceScreen` avec 3 cartes stat (today/week/total), liste recents, skeleton loading, cache banner, error+retry
- Navigation: Route `/dashboard/performance` + bouton "Mes performances" sur home
- 4 widget tests: data, skeleton, error, cache
- Aucune migration DB requise (toutes colonnes existaient deja)

### Change Log

- 2026-03-19: Implementation complete story 3.9 — backend + frontend + tests
- 2026-03-19: Code review — H1 fixed (clearAgentStatsCache() au logout pour eviter fuite cache entre agents), L1 fixed (commentaire modules domain 7→10). Story → done

### File List

server/crates/domain/src/agents/mod.rs (new)
server/crates/domain/src/agents/model.rs (new)
server/crates/domain/src/agents/repository.rs (new)
server/crates/domain/src/agents/service.rs (new)
server/crates/domain/src/lib.rs (modified)
server/crates/domain/src/test_fixtures.rs (modified)
server/crates/api/src/routes/agents.rs (new)
server/crates/api/src/routes/mod.rs (modified)
server/crates/api/src/test_helpers.rs (modified)
packages/mefali_core/lib/models/agent_stats.dart (new)
packages/mefali_core/lib/models/agent_stats.g.dart (generated)
packages/mefali_core/lib/mefali_core.dart (modified)
packages/mefali_api_client/lib/endpoints/agent_endpoint.dart (new)
packages/mefali_api_client/lib/providers/agent_performance_provider.dart (new)
packages/mefali_api_client/lib/mefali_api_client.dart (modified)
apps/mefali_admin/lib/features/dashboard/agent_performance_screen.dart (new)
apps/mefali_admin/lib/app.dart (modified)
apps/mefali_admin/lib/features/home/home_screen.dart (modified)
apps/mefali_admin/test/widget_test.dart (modified)
packages/mefali_api_client/lib/providers/auth_provider.dart (modified: review: import + appel clearAgentStatsCache() au logout)
