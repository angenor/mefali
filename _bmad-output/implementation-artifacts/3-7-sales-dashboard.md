# Story 3.7: Sales Dashboard

Status: done

## Story

As a marchand,
I want un dashboard de ventes hebdomadaire,
So that je comprenne la performance de mon commerce et optimise mon stock.

## Acceptance Criteria (BDD)

### AC1: Affichage dashboard en ligne
```gherkin
Given marchand connecté avec commandes livrées cette semaine
And connectivité internet disponible
When marchand navigue vers l'onglet Stats
Then le dashboard affiche :
  - Total ventes en FCFA (ex: "50 000 FCFA")
  - Nombre de commandes (ex: "47 commandes")
  - Répartition par produit avec unités et revenus
  - Comparaison semaine précédente avec % croissance
And données chargées en < 2 secondes
```

### AC2: Dashboard hors ligne (Drift cache)
```gherkin
Given marchand a synchronisé les données il y a 2 heures
And connectivité internet indisponible
When marchand navigue vers l'onglet Stats
Then le dashboard affiche les données en cache Drift
And horodatage dernière sync visible
And message : "Données en cache, synchronisation au retour de connexion"
```

### AC3: Comparaison semaine courante / semaine précédente
```gherkin
Given semaine courante : 50 000 FCFA, 10 commandes
And semaine précédente : 40 000 FCFA, 8 commandes
When marchand consulte le dashboard
Then affiche :
  - Semaine courante : 50 000 FCFA (10 commandes)
  - Semaine précédente : 40 000 FCFA (8 commandes)
  - Croissance : +10 000 FCFA (+25%) en vert
```

### AC4: Classement performance produits
```gherkin
Given marchand avec 5 produits vendus cette semaine
When marchand consulte la répartition
Then produits listés par revenu décroissant
And chaque produit affiche : nom, unités vendues, revenu total
And produit #1 mis en évidence (highlight)
```

### AC5: Aucune commande dans la semaine
```gherkin
Given marchand sans commande livrée cette semaine
When marchand navigue vers l'onglet Stats
Then dashboard affiche :
  - Total : 0 FCFA (0 commandes)
  - Comparaison semaine précédente (si disponible)
  - État vide : "Pas de commandes cette semaine"
  - Encouragement : "Continuez à améliorer votre catalogue !"
```

### AC6: Mise à jour après nouvelle commande livrée
```gherkin
Given dashboard Stats ouvert
When une commande est livrée (retour sur l'onglet ou pull-to-refresh)
Then dashboard se rafraîchit via invalidation provider
And nouveau total + répartition recalculés
```

## Tasks / Subtasks

### Backend Rust

- [x] **T1** Requête SQL agrégation ventes hebdomadaires (AC: 1, 3)
  - [x] T1.1 Ajouter `get_weekly_sales(pool, merchant_id, week_start, week_end)` dans `orders/repository.rs`
  - [x] T1.2 Retourne : total_sales (SUM total), order_count (COUNT), product_breakdown (GROUP BY product)
  - [x] T1.3 Requête optimisée : JOIN orders + order_items + products, WHERE status = 'delivered' AND merchant_id AND created_at BETWEEN

- [x] **T2** Service layer stats (AC: 1, 3, 5)
  - [x] T2.1 Ajouter `get_merchant_weekly_stats(pool, user_id)` dans `orders/service.rs`
  - [x] T2.2 Calcule semaine courante (lundi→dimanche) + semaine précédente
  - [x] T2.3 Ownership check via `merchants::repository::find_by_user_id`
  - [x] T2.4 Retourne struct `WeeklyStats { current_week, previous_week, product_breakdown }`

- [x] **T3** Endpoint API (AC: 1)
  - [x] T3.1 Ajouter `GET /api/v1/merchants/me/stats/weekly` dans `routes/orders.rs`
  - [x] T3.2 Handler : `get_weekly_stats(pool, auth)` → require_role Merchant
  - [x] T3.3 Enregistrer route dans `routes/mod.rs`
  - [x] T3.4 Response format : `{"data": {"period": {...}, "current_week": {...}, "previous_week": {...}, "product_breakdown": [...]}}`

- [x] **T4** Tests backend (AC: 1-6)
  - [x] T4.1 Tests unitaires model WeeklyStats serde roundtrip
  - [x] T4.2 Tests service : semaine avec commandes, semaine vide, ownership check — 3 tests #[sqlx::test] dans domain/orders/service.rs (test_weekly_stats_with_orders, test_weekly_stats_empty_week, test_weekly_stats_ownership_check)
  - [x] T4.3 Tests route : 200 OK, 401 unauthorized, 403 forbidden — 3 tests #[sqlx::test] dans api/routes/orders.rs (test_weekly_stats_200_ok, test_weekly_stats_401_no_token, test_weekly_stats_403_wrong_role)

### Flutter mefali_core

- [x] **T5** Modèle SalesStats (AC: 1, 3, 4)
  - [x] T5.1 Créer `packages/mefali_core/lib/models/weekly_sales.dart` avec `WeeklySales`, `WeekPeriod`, `ProductSales`
  - [x] T5.2 `@JsonSerializable(fieldRename: FieldRename.snake)` — montants en centimes (int)
  - [x] T5.3 Exporter dans `mefali_core.dart`

### Flutter mefali_api_client

- [x] **T6** Endpoint + Provider stats (AC: 1, 2, 6)
  - [x] T6.1 Ajouter `getWeeklyStats()` dans `order_endpoint.dart` → GET /merchants/me/stats/weekly
  - [x] T6.2 Créer `providers/sales_dashboard_provider.dart` avec `weeklyStatsProvider` (FutureProvider.autoDispose)
  - [x] T6.3 Exporter dans `mefali_api_client.dart`

### Flutter mefali_b2b

- [x] **T7** Écran SalesDashboardScreen (AC: 1-6)
  - [x] T7.1 Créer `apps/mefali_b2b/lib/features/sales/sales_dashboard_screen.dart`
  - [x] T7.2 ConsumerWidget, watch `weeklyStatsProvider`
  - [x] T7.3 Section résumé : 2 cartes (total FCFA + nombre commandes) avec indicateurs ↑↓ comparaison
  - [x] T7.4 Section comparaison : semaine courante vs précédente avec % croissance (vert hausse, rouge baisse)
  - [x] T7.5 Section répartition produits : liste triée par revenu décroissant, top produit highlight
  - [x] T7.6 État vide : icône + message encouragement
  - [x] T7.7 Pull-to-refresh via RefreshIndicator + `ref.invalidate(weeklyStatsProvider)`
  - [x] T7.8 Skeleton loading (jamais spinner seul)
  - [x] T7.9 Gestion offline : afficher données cache + timestamp + message

- [x] **T8** Intégration onglet Stats dans HomeScreen (AC: 1)
  - [x] T8.1 Remplacer placeholder `Center(child: Text('Statistiques (bientôt)'))` par `SalesDashboardScreen()`
  - [x] T8.2 S'assurer que TabBarView lazy-load le contenu Stats

### Offline / Drift (AC: 2)

- [x] **T9** Cache in-memory pour stats hebdomadaires *(cache Drift persistent a considerer pour survie au restart app)*
  - [x] T9.1 Stocker la réponse API en cache local (in-memory — JSON sérialisé)
  - [x] T9.2 Provider lit cache si offline (DioException reseau uniquement, pas catch-all)
  - [x] T9.3 Afficher timestamp dernière sync

### Tests Flutter

- [x] **T10** Tests widget + provider
  - [x] T10.1 Test SalesDashboardScreen avec données mockées (override provider)
  - [x] T10.2 Test état vide (0 commandes)
  - [x] T10.3 Test loading state (skeleton visible)
  - [x] T10.4 Test comparaison semaine (hausse vert, baisse rouge)

## Dev Notes

### Contexte métier critique

Le dashboard ventes est le **Trojan Horse de mefali** — c'est l'écran qui convertit Adjoua d'utilisatrice d'outil en marchande fidèle. Le PRD dit : "Adjoua ouvre l'app après la fermeture. Pour la première fois de sa vie, elle voit un écran qui lui dit : 'Cette semaine : 47 commandes. Garba : 23 (49%). Alloco-poisson : 15 (32%).' Elle comprend instantanément : le garba, c'est la moitié de son business." Les chiffres doivent être **lisibles sans explication**, actionnables immédiatement.

### Contraintes appareils cibles

- Tecno Spark / Infinix / Itel, 2GB RAM, écran 720p
- APK < 30 MB — **NE PAS ajouter de bibliothèque de charts lourde**
- Alternative : utiliser des widgets Flutter natifs (LinearProgressIndicator pour barres, Container peints pour indicateurs) plutôt que fl_chart si le poids est un problème
- Si fl_chart est choisi : ~300KB compilé, acceptable
- Animations réduites ou désactivées si RAM < 3 GB
- Boutons ≥ 48dp, texte minimum 14sp body

### Montants en centimes

Comme établi dans la story 3-6 : tous les montants sont en centimes (BIGINT). 2500 FCFA = 250000 centimes. Affichage : `(amount / 100).toStringAsFixed(0)` + " FCFA". Le calcul d'agrégation doit se faire en centimes côté serveur, la conversion en FCFA est uniquement côté UI.

### API Response Contract

```json
{
  "data": {
    "period": {
      "start": "2026-03-11",
      "end": "2026-03-17"
    },
    "current_week": {
      "total_sales": 4700000,
      "order_count": 47,
      "average_order": 100000
    },
    "previous_week": {
      "total_sales": 4000000,
      "order_count": 40,
      "average_order": 100000
    },
    "product_breakdown": [
      {
        "product_id": "uuid-here",
        "product_name": "Garba",
        "quantity_sold": 23,
        "revenue": 2300000,
        "percentage": 48.9
      }
    ]
  }
}
```

### Requête SQL d'agrégation (guide)

```sql
-- Ventes hebdomadaires par marchand
SELECT
  SUM(o.total) as total_sales,
  COUNT(DISTINCT o.id) as order_count
FROM orders o
WHERE o.merchant_id = $1
  AND o.status = 'delivered'
  AND o.created_at >= $2  -- week_start
  AND o.created_at < $3;  -- week_end

-- Répartition par produit
SELECT
  p.id as product_id,
  p.name as product_name,
  SUM(oi.quantity) as quantity_sold,
  SUM(oi.quantity * oi.unit_price) as revenue
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
JOIN products p ON p.id = oi.product_id
WHERE o.merchant_id = $1
  AND o.status = 'delivered'
  AND o.created_at >= $2
  AND o.created_at < $3
GROUP BY p.id, p.name
ORDER BY revenue DESC;
```

### Patterns à suivre (établis story 3-6)

| Pattern | Détail |
|---------|--------|
| **Ownership check** | `find_by_user_id(pool, auth.user_id)` → vérifie merchant_id |
| **Route handler** | `require_role(&auth, &[UserRole::Merchant])?;` + `ApiResponse::new(...)` |
| **Provider** | `FutureProvider.autoDispose` pour lecture, invalidate après mutation |
| **Écran** | `ConsumerWidget`, `.when(data/loading/error)`, `RefreshIndicator` |
| **Export barrel** | Ajouter exports dans `mefali_core.dart`, `mefali_api_client.dart` |
| **JSON serde** | `@JsonSerializable(fieldRename: FieldRename.snake)` Dart, `#[serde(rename_all = "snake_case")]` Rust |
| **Tests** | `ProviderScope(overrides: [...])` pour mock providers |

### UX critique — Design tokens

| Élément | Token/Couleur |
|---------|---------------|
| Hausse (+%) | success green #4CAF50 (light) / #81C784 (dark) |
| Baisse (-%) | error red #F44336 (light) / #EF9A9A (dark) |
| Total principal | `headlineMedium` (gros chiffre bien lisible) |
| Fond carte | `surfaceContainer` du thème Material 3 |
| Top produit | `primaryContainer` highlight |
| Message vide | `onSurfaceVariant` gris, icône centrée |

### Anti-patterns — NE PAS faire

- **NE PAS** utiliser de WebSocket — pull-to-refresh suffit pour le dashboard
- **NE PAS** créer de nouvelle migration DB — les tables orders, order_items, products existent déjà
- **NE PAS** ajouter de bibliothèque de charts lourde (> 1MB compilé) — vérifier la taille
- **NE PAS** calculer les totaux côté client à partir de la liste des commandes — faire l'agrégation SQL côté serveur
- **NE PAS** dupliquer les modèles Order/OrderItem — réutiliser ceux de mefali_core
- **NE PAS** ajouter un drawer ou une navigation supplémentaire — le dashboard est dans l'onglet Stats existant
- **NE PAS** hardcoder des périodes — calculer lundi→dimanche dynamiquement

### Fichiers existants à NE PAS recréer

| Fichier | Rôle |
|---------|------|
| `server/crates/domain/src/orders/model.rs` | Order struct + OrderStatus enum — enrichir, ne pas recréer |
| `server/crates/domain/src/orders/repository.rs` | Repository — ajouter requêtes agrégation |
| `server/crates/domain/src/orders/service.rs` | Service — ajouter get_merchant_weekly_stats |
| `server/crates/api/src/routes/orders.rs` | Routes — ajouter GET stats/weekly |
| `packages/mefali_core/lib/models/order.dart` | Modèle Order Dart existant |
| `packages/mefali_core/lib/models/order_item.dart` | Modèle OrderItem Dart existant |
| `packages/mefali_api_client/lib/endpoints/order_endpoint.dart` | Endpoint — ajouter getWeeklyStats() |
| `apps/mefali_b2b/lib/features/home/home_screen.dart` | HomeScreen — remplacer placeholder Stats tab |

### Fichiers à créer

| Fichier | Rôle |
|---------|------|
| `packages/mefali_core/lib/models/weekly_sales.dart` | Modèles WeeklySales, WeekPeriod, ProductSales |
| `packages/mefali_api_client/lib/providers/sales_dashboard_provider.dart` | weeklyStatsProvider (FutureProvider.autoDispose) |
| `apps/mefali_b2b/lib/features/sales/sales_dashboard_screen.dart` | Écran dashboard ventes |

### Project Structure Notes

- Organisation par feature : `features/sales/` (pas `features/dashboard/` ni `features/stats/`)
- snake_case pour les noms de fichiers : `sales_dashboard_screen.dart`, `weekly_sales.dart`
- L'onglet Stats dans HomeScreen est déjà positionné en index 2 du TabBar

### Dépendances story

- **Dépend de** : Story 3-6 (orders, order_items, routes existants)
- **Bloquée par** : Rien — toutes les données nécessaires existent
- **Alimente** : Story 3-9 (Agent Terrain Performance Dashboard — pattern réutilisable)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.7: Sales Dashboard]
- [Source: _bmad-output/planning-artifacts/prd.md#FR43]
- [Source: _bmad-output/planning-artifacts/architecture.md#API Patterns, Database Schema, Riverpod]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Dashboard ventes, Design Tokens, Responsive]
- [Source: _bmad-output/implementation-artifacts/3-6-order-reception-and-management-b2b.md#Dev Notes, Code Patterns]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Build: cargo build OK, cargo clippy OK (0 new warnings)
- Rust tests: 182 pass, 0 fail (8 new: 2 serde + 6 integration)
- Flutter analyze: 0 warnings/errors on mefali_core, mefali_api_client, mefali_b2b
- Flutter tests: 28 pass, 0 fail (7 new: data, empty, skeleton, green growth, red growth, cache banner, AC5 encouragement)

### Completion Notes List

- T1-T3: Backend Rust complet — structs WeeklyStats/WeekSummary/WeekPeriod/ProductBreakdown dans model.rs, requetes SQL aggregation dans repository.rs (get_weekly_sales, get_product_breakdown), service get_merchant_weekly_stats avec calcul semaine lundi→dimanche, endpoint GET /api/v1/merchants/me/stats/weekly enregistre dans routes/mod.rs
- T4: Tests backend — serde roundtrip pour WeeklyStats, test zero values pour WeekSummary, 3 tests integration service (#[sqlx::test] avec factories), 3 tests integration route (actix_web::test + test_app). Bug fix: SUM(BIGINT)::BIGINT cast dans les queries SQL d'agregation.
- T5: Modele Dart WeeklySales, WeekPeriod, WeekSummary, ProductSales avec @JsonSerializable(fieldRename: FieldRename.snake), exporte dans mefali_core.dart
- T6: getWeeklyStats() ajoute dans OrderEndpoint, weeklyStatsProvider (FutureProvider.autoDispose<WeeklySalesState>) avec cache memoire offline, exporte dans mefali_api_client.dart
- T7: SalesDashboardScreen (ConsumerWidget) avec summary cards, comparison section, product breakdown (LinearProgressIndicator), empty state, skeleton loading, cache banner offline, RefreshIndicator
- T8: Placeholder Stats remplace par SalesDashboardScreen dans HomeScreen, TabBarView lazy-load preserve
- T9: Cache memoire dans provider (JSON serialise in-memory), try/catch Dio pour detection offline, timestamp derniere sync affiche dans banner
- T10: 6 tests widget — donnees mockees, etat vide, skeleton loading, croissance positive/negative, banner cache offline

### Change Log

- 2026-03-18: Implementation complete story 3-7-sales-dashboard — backend + frontend + tests (10 taches, toutes completees)
- 2026-03-18: Code review fixes — M3: catch(e) remplace par on DioException (filtre erreurs reseau), L1: _DashboardContent refactored en ConsumerWidget, L2: 3 requetes DB parallelisees via tokio::try_join!, T4.2/T4.3 decoche (tests integration pas encore implantes), T9 clarifie (cache in-memory, pas Drift)
- 2026-03-18: T4.2/T4.3 completes — infrastructure tests integration backend (test_fixtures + test_helpers + #[sqlx::test]), 6 tests integration (3 service + 3 route), bug fix SUM(BIGINT)::BIGINT, adversarial review avec 7 findings corriges
- 2026-03-18: Code review final — M1 fixed (clearSalesCache() au logout pour eviter fuite cache entre marchands), L2 fixed (AC5: encouragement card quand semaine courante vide mais precedente a des donnees), 1 test widget ajoute. Story → done

### File List

- server/crates/domain/src/orders/model.rs (modified: added WeekPeriod, WeekSummary, ProductBreakdown, WeeklyStats structs + tests)
- server/crates/domain/src/orders/repository.rs (modified: added get_weekly_sales, get_product_breakdown functions)
- server/crates/domain/src/orders/service.rs (modified: added get_merchant_weekly_stats function, review: parallelized with tokio::try_join!)
- server/crates/domain/Cargo.toml (modified: added tokio dependency)
- server/crates/api/src/routes/orders.rs (modified: added get_weekly_stats handler)
- server/crates/api/src/routes/mod.rs (modified: registered /me/stats/weekly route)
- packages/mefali_core/lib/models/weekly_sales.dart (new: WeeklySales, WeekPeriod, WeekSummary, ProductSales models)
- packages/mefali_core/lib/models/weekly_sales.g.dart (new: generated json_serializable code)
- packages/mefali_core/lib/mefali_core.dart (modified: added weekly_sales.dart export)
- packages/mefali_api_client/lib/endpoints/order_endpoint.dart (modified: added getWeeklyStats method)
- packages/mefali_api_client/lib/providers/sales_dashboard_provider.dart (new: weeklyStatsProvider + WeeklySalesState + offline cache, review: DioException filter, review2: clearSalesCache())
- packages/mefali_api_client/lib/providers/auth_provider.dart (modified: review2: import + appel clearSalesCache() au logout)
- packages/mefali_api_client/lib/mefali_api_client.dart (modified: added sales_dashboard_provider export)
- apps/mefali_b2b/lib/features/sales/sales_dashboard_screen.dart (new: SalesDashboardScreen widget, review: _DashboardContent → ConsumerWidget, review2: _EmptyWeekEncouragement AC5)
- apps/mefali_b2b/lib/features/home/home_screen.dart (modified: replaced Stats placeholder with SalesDashboardScreen)
- apps/mefali_b2b/test/widget_test.dart (modified: added 7 Sales Dashboard tests, review2: AC5 encouragement test)
- server/crates/domain/src/test_fixtures.rs (new: factory functions for users, merchants, products, orders)
- server/crates/domain/src/lib.rs (modified: added #[cfg(any(test, feature = "testing"))] pub mod test_fixtures)
- server/crates/api/src/test_helpers.rs (new: test_config, create_test_jwt, test_app for route testing)
- server/crates/api/src/main.rs (modified: added #[cfg(test)] mod test_helpers)
- server/crates/api/Cargo.toml (modified: added domain[testing] + sqlx to dev-dependencies)
- server/Cargo.lock (modified: updated dependency tree)
