# Story 4.1: Restaurant Discovery & Home

Status: done

## Story

As a client B2C,
I want to see restaurants near me in a 2-column grid with category filter chips,
so that I can quickly find where to order.

## Business Context

Epic 4 : le client B2C entre en scène. FR11 (browse restaurants) est le premier touch-point de Koffi avec la marketplace. Si cet écran est lent ou confus, il ferme l'app et ne revient pas. Sur Tecno Spark (2 GB RAM, 3G), la performance n'est pas optionnelle — cold start < 3s (NFR2), skeleton immédiat obligatoire.

Cette story établit aussi l'infrastructure de navigation B2C (`ShellRoute` + bottom nav), réutilisée par toutes les stories 4.x suivantes. L'architecture multi-services est anticipée : `ServiceGrid` masqué (1 seul service "food" pour l'instant), la grille restaurants apparaît directement. Quand un 2ème service est ajouté post-MVP, le ServiceGrid apparaît sans refonte (UX-DR12).

**FRs couverts :** FR11 (browse restaurants/marchands à proximité)
**UX-DR couverts :** UX-DR3 (RestaurantCard), UX-DR12 (ServiceGrid masqué 1 service), UX-DR13 (Bottom nav B2C), UX-DR14 (Skeleton screens)

## Acceptance Criteria

**AC1 — Skeleton loading** : Given logged in AND home screen loads, When API request in-flight, Then 2-column skeleton cards display immediately (jamais un spinner seul — UX-DR14 strict).

**AC2 — Restaurant grid** : Given API responds with active merchants, When home renders, Then `RestaurantCard` widgets display in 2-column grid (UX-DR3), marchands `open` et `busy` affichés, `closed` et `auto_paused` grisés mais visibles.

**AC3 — RestaurantCard content** : Given a merchant, When `RestaurantCard` renders, Then shows: photo WebP (cached), nom, note ★ (si avg_rating > 0 seulement), prix livraison formaté en FCFA (ex: "500 FCFA"), badge statut VendorStatus read-only.

**AC4 — Vendor status sur card** : Given merchant `status = open`, Then badge vert "Ouvert". Given `busy`, Then badge orange "~30 min". Given `closed` ou `auto_paused`, Then card à opacity 0.5, `AbsorbPointer` actif (non-tappable).

**AC5 — Filter chips catégorie** : Given restaurant list visible, When user tape un chip (ex: "Garba"), Then grille filtre localement (pas de nouvel appel API). When "Tout" tappé, Then toutes les restaurants actives ré-apparaissent.

**AC6 — Bottom navigation** : Given n'importe quel écran du shell B2C, Then bottom nav fixe avec 4 items labels visibles : "Accueil" (🏠), "Recherche" (🔍), "Commandes" (📦), "Profil" (👤) — UX-DR13. Onglet actif mis en surbrillance avec la couleur `primary`.

**AC7 — Empty state** : Given API retourne 0 marchands actifs, Then message humain (ex: "Aucun restaurant disponible pour le moment — revenez bientôt !") + icône marché. Jamais un écran blanc.

**AC8 — Error state** : Given API échoue (timeout, 5xx), Then message d'erreur clair + bouton "Réessayer" (force-refresh du provider). Pas de crash.

**AC9 — Image loading** : Given `photo_url` depuis MinIO, When card rend l'image, Then `CachedNetworkImage` avec fond `MefaliColors.primaryContainer` comme placeholder (couleur unie — pas de spinner dans la carte).

**AC10 — Tap sur restaurant** : Given card d'un marchand actif, When tappée, Then `SnackBar` temporaire "Catalogue à venir" (stub — la navigation réelle est implémentée en story 4.2).

## Tasks / Subtasks

- [ ] Task 1 — Backend Rust : Endpoint liste restaurants (AC: 2, 3, 4, 5)
  - [ ] 1.1 Vérifier si `GET /api/v1/merchants` existe déjà dans `server/crates/api/src/routes/merchants.rs` (chercher `async fn list_merchants` ou `get("/merchants")`)
  - [ ] 1.2 Si absent : ajouter handler `GET /api/v1/merchants` avec query params `category: Option<String>`, `page: Option<u32>` (défaut 1), `per_page: Option<u32>` (défaut 20)
  - [ ] 1.3 Ajouter méthode `list_active_merchants(category, page, per_page)` dans `server/crates/domain/src/merchants/service.rs` — retourne marchands avec status ≠ closed uniquement (inclure auto_paused pour visibilité mais non-tappable côté Flutter)
  - [ ] 1.4 Response JSON inclut : `id`, `name`, `address`, `status` (snake_case: open/busy/auto_paused/closed), `category`, `photo_url`, `avg_rating` (0.0 par défaut), `total_ratings` (0 par défaut), `delivery_fee` (500 fixe ou depuis city_config si configuré), `city_id`
  - [ ] 1.5 Auth: endpoint accessible aux clients authentifiés (JWT avec role = "client"). Pas d'accès non-authentifié.
  - [ ] 1.6 Enregistrer route dans `server/crates/api/src/routes/mod.rs` (pattern existant)
  - [ ] 1.7 Tests Rust : `test_list_active_merchants_excludes_closed`, `test_list_merchants_filter_by_category`, `test_list_merchants_pagination`

- [ ] Task 2 — mefali_core : Modèle RestaurantSummary (AC: 2, 3)
  - [ ] 2.1 Lire `packages/mefali_core/lib/models/merchant.dart` pour vérifier si `avg_rating` et `delivery_fee` existent
  - [ ] 2.2 Si absents du modèle `Merchant` : créer `packages/mefali_core/lib/models/restaurant_summary.dart` avec : `id`, `name`, `address`, `status` (VendorStatus), `category` (MerchantCategory), `photoUrl`, `avgRating` (double, défaut 0.0), `totalRatings` (int), `deliveryFee` (int, centimes FCFA), `cityId`
  - [ ] 2.3 `@JsonSerializable(fieldRename: FieldRename.snake)` — générer `restaurant_summary.g.dart` avec `dart run build_runner build`
  - [ ] 2.4 Exporter depuis `packages/mefali_core/lib/mefali_core.dart`

- [ ] Task 3 — mefali_api_client : Provider restaurant discovery (AC: 2, 5, 8)
  - [ ] 3.1 Créer `packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart`
     ```dart
     class RestaurantEndpoint {
       const RestaurantEndpoint(this._client);
       final Dio _client;
       Future<List<RestaurantSummary>> getRestaurants({String? category, int page = 1, int perPage = 20}) async { ... }
     }
     final restaurantEndpointProvider = Provider.autoDispose((ref) => RestaurantEndpoint(ref.watch(dioClientProvider)));
     ```
  - [ ] 3.2 Créer `packages/mefali_api_client/lib/providers/restaurant_discovery_provider.dart`
     ```dart
     // Paramètre = category filter (null = Tout)
     final restaurantDiscoveryProvider = FutureProvider.autoDispose.family<List<RestaurantSummary>, String?>(
       (ref, category) async => ref.watch(restaurantEndpointProvider).getRestaurants(category: category),
     );
     ```
  - [ ] 3.3 Exporter depuis `packages/mefali_api_client/lib/mefali_api_client.dart`

- [ ] Task 4 — mefali_design : Composant RestaurantCard (AC: 3, 4, 9)
  - [ ] 4.1 Créer `packages/mefali_design/lib/components/restaurant_card.dart`
  - [ ] 4.2 Layout vertical dans un `Card` M3 : image en haut (120dp de hauteur, `ClipRRect` borderRadius: 8), puis padding 8dp avec nom (`bodyLarge` bold), note ★ (si `avgRating > 0` → "★ 4.7" sinon rien), prix livraison via `formatFcfa(deliveryFee)` de mefali_core
  - [ ] 4.3 `VendorStatusIndicator` réutilisé (existant dans mefali_design) avec param `isInteractive: false` (read-only B2C — VÉRIFIER si ce param existe, sinon l'ajouter à `VendorStatusIndicator`)
  - [ ] 4.4 État grisé : `Opacity(opacity: 0.5)` + `AbsorbPointer(absorbing: true)` quand status = closed ou auto_paused
  - [ ] 4.5 Image : `CachedNetworkImage(imageUrl: photoUrl ?? '', placeholder: (_, __) => Container(color: MefaliColors.primaryContainer), errorWidget: (_, __, ___) => Container(color: MefaliColors.primaryContainer))`
  - [ ] 4.6 ATTENTION : `cached_network_image` doit être dans `packages/mefali_design/pubspec.yaml` OU importé via l'app B2C. Vérifier les pubspecs.
  - [ ] 4.7 Touch target: le `GestureDetector` couvre tout la carte (≥ 48dp de hauteur minimum — respecté car ~200dp)
  - [ ] 4.8 Signature : `RestaurantCard({required RestaurantSummary restaurant, required VoidCallback? onTap})`
  - [ ] 4.9 Exporter depuis `packages/mefali_design/lib/mefali_design.dart`

- [ ] Task 5 — mefali_design : RestaurantCardSkeleton (AC: 1)
  - [ ] 5.1 Créer `RestaurantCardSkeleton` dans le même fichier `restaurant_card.dart`
  - [ ] 5.2 Mêmes dimensions que `RestaurantCard` (pas de layout shift au chargement)
  - [ ] 5.3 Animation shimmer avec `AnimatedContainer` ou `TweenAnimationBuilder` sur `ColorTween` entre `MefaliColors.primaryContainer` et `Colors.white24` — NE PAS ajouter le package `shimmer` (APK < 30MB)
  - [ ] 5.4 Pas de texte dans le skeleton — seulement des rectangles colorés

- [ ] Task 6 — B2C app : Navigation shell (AC: 6)
  - [ ] 6.1 Créer `apps/mefali_b2c/lib/features/shell/main_shell.dart`
     ```dart
     class MainShell extends StatelessWidget {
       const MainShell({super.key, required this.child});
       final Widget child;
       // BottomNavigationBar 4 items + selectedIndex basé sur context.location (go_router)
     }
     ```
  - [ ] 6.2 Modifier `apps/mefali_b2c/lib/app.dart` : remplacer la route `/home` par un `ShellRoute` avec `MainShell`
  - [ ] 6.3 Routes dans le shell : `/home`, `/search` (stub), `/orders` (stub), `/profile` (existant Epic 2)
  - [ ] 6.4 Créer `apps/mefali_b2c/lib/features/search/search_screen.dart` (stub : "Recherche — bientôt disponible")
  - [ ] 6.5 Créer `apps/mefali_b2c/lib/features/orders/orders_screen.dart` (stub : "Mes commandes — bientôt disponible")
  - [ ] 6.6 L'index actif du `BottomNavigationBar` se détermine via `GoRouterState.of(context).matchedLocation`
  - [ ] 6.7 Couleur `selectedItemColor: Theme.of(context).colorScheme.primary` (marron foncé)

- [ ] Task 7 — B2C app : HomeScreen (AC: 1, 2, 3, 5, 7, 8, 10)
  - [ ] 7.1 Réécrire `apps/mefali_b2c/lib/features/home/home_screen.dart` comme `ConsumerStatefulWidget`
  - [ ] 7.2 State local : `String? _selectedCategory` (null = "Tout")
  - [ ] 7.3 Header : `SliverAppBar` avec titre "Bouaké" + icône localisation (statique MVP)
  - [ ] 7.4 Filter chips : `SliverToBoxAdapter` + `SingleChildScrollView(scrollDirection: Axis.horizontal)` + `FilterChip` M3 pour "Tout" + valeurs `MerchantCategory` — MAJ `_selectedCategory` setState
  - [ ] 7.5 Body : `Consumer` sur `restaurantDiscoveryProvider(_selectedCategory)` avec `AsyncValue.when()`
     - `loading`: `SliverGrid` de 6 `RestaurantCardSkeleton`
     - `data`: `SliverGrid` de `RestaurantCard` widgets, ou `SliverFillRemaining` si vide (AC7)
     - `error`: `SliverFillRemaining` avec message + bouton retry `ref.invalidate(restaurantDiscoveryProvider(...))`
  - [ ] 7.6 `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75)`
  - [ ] 7.7 Padding global : `EdgeInsets.symmetric(horizontal: 16)` (convention 16dp)
  - [ ] 7.8 Tap sur card active → `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Catalogue à venir')))` (stub pour story 4.2)

- [ ] Task 8 — Tests widget Flutter (AC: 1-10)
  - [ ] 8.1 Test `RestaurantCard` : photo affichée, nom affiché, rating absent si 0, rating affiché si > 0, opacity 0.5 si closed
  - [ ] 8.2 Test `HomeScreen` : skeleton présent pendant chargement, grille après data, message vide si liste vide, snackbar si tap (stub), retry si erreur
  - [ ] 8.3 Test `MainShell` : 4 items bottom nav présents avec labels corrects
  - [ ] 8.4 Pattern mock : `ProviderScope(overrides: [restaurantDiscoveryProvider(null).overrideWith(...)])`

## Dev Notes

### Architecture : Epic 4 est Frontend-Heavy

Le backend n'a qu'un endpoint REST simple à ajouter. L'essentiel du travail est Flutter B2C. S'assurer que le backend endpoint marche d'abord (tester avec curl), puis brancher le Flutter.

### Patterns Riverpod établis (Epic 3, à réutiliser)

```dart
// Pattern FutureProvider.autoDispose.family — OBLIGATOIRE
final restaurantDiscoveryProvider = FutureProvider.autoDispose
    .family<List<RestaurantSummary>, String?>((ref, category) async {
  return ref.watch(restaurantEndpointProvider).getRestaurants(category: category);
});

// Pattern AsyncValue.when() — OBLIGATOIRE (jamais de FutureBuilder)
ref.watch(restaurantDiscoveryProvider(selectedCategory)).when(
  data: (restaurants) => _buildGrid(restaurants),
  loading: () => _buildSkeletonGrid(),
  error: (err, _) => _buildErrorState(err, ref),
);
```

### Réutilisation obligatoire — composants existants

| Composant | Source | Usage |
|-----------|--------|-------|
| `VendorStatusIndicator` | `packages/mefali_design/lib/components/vendor_status_indicator.dart` | Badge statut sur RestaurantCard (read-only) |
| `MefaliTheme.light() / .dark()` | `packages/mefali_design/lib/mefali_theme.dart` | Styles, couleurs |
| `MefaliColors` | `packages/mefali_design/lib/mefali_colors.dart` | Placeholder skeleton (`primaryContainer`) |
| `formatFcfa()` | `packages/mefali_core/lib/utils/formatting.dart` | Prix livraison — **NE PAS recréer** |
| `VendorStatus` enum | `packages/mefali_core/lib/enums/vendor_status.dart` | Logique grisage card |
| `MerchantCategory` enum | `packages/mefali_core/lib/enums/merchant_category.dart` | Labels filter chips |
| `authProvider` + `_AuthRouterNotifier` | `apps/mefali_b2c/lib/app.dart` | GoRouter redirect auth — NE PAS modifier le pattern |
| `dioClientProvider` | `packages/mefali_api_client/lib/dio_client/dio_client.dart` | HTTP dans RestaurantEndpoint |

### Anti-patterns à éviter absolument

- **JAMAIS** de spinner/`CircularProgressIndicator` seul pendant le loading → skeleton (UX-DR14 strict)
- **JAMAIS** de couleurs hardcodées → `MefaliTheme`, `MefaliColors`, `Theme.of(context).colorScheme`
- **JAMAIS** de `FutureBuilder` → `AsyncValue.when()` Riverpod uniquement
- **JAMAIS** oublier `autoDispose` sur providers → mémoire leak sur appareils 2 GB RAM
- **JAMAIS** de scroll horizontal sur la grille restaurants (anti-pattern UX explicite dans spec)
- **NE PAS** appeler `/api/v1/merchants` à chaque rebuild setState (filter chips) → filtrer la liste localement côté Flutter, pas un nouvel appel API
- **NE PAS** oublier d'exporter les nouveaux fichiers dans les `package.dart` barrel files
- **NE PAS** naviguer vers `/restaurant/:id` pour l'instant — juste un `SnackBar` stub

### Rust Backend — Vérifications préalables

Avant d'écrire le code backend, chercher dans le projet Rust :
```bash
grep -r "list_merchants\|GET.*merchants" server/crates/api/src/ --include="*.rs"
```

Si l'endpoint existe déjà (possible qu'il ait été créé partiellement pour Epic 3), l'étendre plutôt que recréer.

Format de réponse API obligatoire (architecture.md) :
```json
{
  "data": [{
    "id": "uuid-v4",
    "name": "Chez Adjoua",
    "status": "open",
    "category": "garba",
    "photo_url": "http://minio:9000/merchants/photo.webp",
    "avg_rating": 0.0,
    "total_ratings": 0,
    "delivery_fee": 500,
    "city_id": "uuid-v4"
  }],
  "meta": {"page": 1, "total": 5, "per_page": 20}
}
```

Erreur Rust : enum `AppError` existant dans `server/crates/common/src/error.rs` — réutiliser.

### Navigation ShellRoute — go_router

Pattern exact pour `app.dart` B2C (ShellRoute go_router) :

```dart
ShellRoute(
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
)
```

**Déterminer l'index actif du BottomNavigationBar :**
```dart
int _currentIndex(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  if (location.startsWith('/search')) return 1;
  if (location.startsWith('/orders')) return 2;
  if (location.startsWith('/profile')) return 3;
  return 0; // /home
}
```

### RestaurantCard — Layout et dimensions

Sur 360dp de largeur totale :
- Padding horizontal : 16dp × 2 = 32dp
- Gap inter-colonnes : 12dp
- Largeur de colonne ≈ 156dp

```dart
SliverGrid(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 0.75, // 156 × 1.33 ≈ 208dp de hauteur
  ),
  delegate: SliverChildBuilderDelegate(...),
)
```

Image height dans la carte : `120dp` fixe (pas `Expanded` — layout prévisible).

### Skeleton Animation sans package externe

```dart
class RestaurantCardSkeleton extends StatefulWidget { ... }
class _RestaurantCardSkeletonState extends State<RestaurantCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = ColorTween(
      begin: MefaliColors.primaryContainer,
      end: Colors.grey.shade200,
    ).animate(_ctrl);
  }
  // Rectangles : image zone (120dp), nom (16dp), sous-ligne (12dp)
}
```

### Tests — Pattern mock provider

```dart
testWidgets('HomeScreen shows skeleton while loading', (tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      restaurantDiscoveryProvider(null).overrideWith(
        (ref, _) => Future.delayed(const Duration(seconds: 10), () => []),
      ),
    ],
    child: MaterialApp(home: HomeScreen()),
  ));
  expect(find.byType(RestaurantCardSkeleton), findsWidgets);
});
```

### Vérifications critiques avant de soumettre

1. `dart analyze packages/mefali_design packages/mefali_core packages/mefali_api_client apps/mefali_b2c` → 0 erreur
2. `flutter test apps/mefali_b2c` → tous les tests passent
3. `cargo test --workspace` → aucune régression Rust
4. `dart run build_runner build` dans mefali_core si nouveau modèle généré

### Project Structure — Fichiers à créer/modifier

```
# NOUVEAUX fichiers
packages/mefali_design/lib/components/restaurant_card.dart        ← RestaurantCard + Skeleton
packages/mefali_core/lib/models/restaurant_summary.dart           ← si Merchant n'a pas avg_rating
packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart ← RestaurantEndpoint
packages/mefali_api_client/lib/providers/restaurant_discovery_provider.dart
apps/mefali_b2c/lib/features/shell/main_shell.dart                ← BottomNav shell
apps/mefali_b2c/lib/features/search/search_screen.dart            ← stub
apps/mefali_b2c/lib/features/orders/orders_screen.dart            ← stub
server/crates/api/src/routes/merchants.rs                          ← GET list (si absent)

# MODIFIER
apps/mefali_b2c/lib/app.dart                                       ← ShellRoute + routes
apps/mefali_b2c/lib/features/home/home_screen.dart                ← RÉÉCRIRE
packages/mefali_design/lib/mefali_design.dart                     ← export restaurant_card
packages/mefali_api_client/lib/mefali_api_client.dart             ← export nouveaux providers
packages/mefali_core/lib/mefali_core.dart                         ← export si nouveau modèle
apps/mefali_b2c/test/widget_test.dart                             ← ajouter tests
server/crates/domain/src/merchants/service.rs                      ← list_active_merchants
```

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 4, Story 4.1, FR11, UX-DR3/12/13/14]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — "Design Direction B2C", "Experience Mechanics Flow B2C Étapes 1-2", "Component Strategy RestaurantCard, MefaliBottomSheet", "Navigation Patterns"]
- [Source: _bmad-output/planning-artifacts/architecture.md — Frontend Architecture Flutter, go_router ShellRoute, Riverpod patterns, REST format responses, `cached_network_image`]
- [Source: _bmad-output/implementation-artifacts/3-10-demo-mode.md — formatFcfa shared util, VendorStatusIndicator patterns, Riverpod StateNotifier patterns]
- [Source: apps/mefali_b2c/lib/app.dart — Pattern GoRouter existant à étendre avec ShellRoute]
- [Source: packages/mefali_design/lib/mefali_design.dart — Composants existants à réutiliser]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6

### Debug Log References

### Completion Notes List

### File List

- packages/mefali_design/lib/components/restaurant_card.dart (créé)
- packages/mefali_core/lib/models/restaurant_summary.dart (créé)
- packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart (créé)
- packages/mefali_api_client/lib/providers/restaurant_discovery_provider.dart (créé)
- apps/mefali_b2c/lib/features/home/home_screen.dart (modifié — réécrit avec NavigationBar intégré)
- apps/mefali_b2c/test/widget_test.dart (modifié — tests AC1-AC10 ajoutés)
- server/crates/api/src/routes/merchants.rs (modifié — GET /api/v1/merchants + format pagination standard)
- server/crates/domain/src/merchants/service.rs (modifié — list_active_merchants)
