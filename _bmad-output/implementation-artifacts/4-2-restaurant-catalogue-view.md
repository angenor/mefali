# Story 4.2: Restaurant Catalogue View

Status: done

## Story

As a client B2C,
I want to view a restaurant's products in a progressive bottom sheet,
so that I choose what to order and add items to my cart.

## Business Context

- FR12 : Client B2C peut consulter le catalogue d'un marchand avec photos, prix et notes
- C'est le deuxieme ecran du parcours commande B2C (apres la decouverte restaurants story 4.1)
- UX-DR2 : MefaliBottomSheet progressif (3 etats : peek 25% / half 50% / expanded 85%)
- Le "+" ajoute au panier local (le panier complet est story 4.3, ici on pose les fondations)
- Temps cible : ouverture app -> confirmation < 60s (inclut browse catalogue)
- Cible devices : Tecno Spark / Infinix / Itel avec 2GB RAM, reseau 3G instable
- NFR6 : Chargement catalogue marchand < 2s (images comprises), WebP < 200KB, lazy loading

## Acceptance Criteria

**AC1 — Navigation vers catalogue :**
Given je suis sur le HomeScreen avec la grille restaurants,
When je tape sur une RestaurantCard active (status open ou overwhelmed),
Then l'ecran RestaurantCatalogueScreen s'ouvre avec le MefaliBottomSheet en etat peek (25%).

**AC2 — MefaliBottomSheet 3 etats :**
Given le catalogue restaurant est ouvert,
When je drag le sheet vers le haut,
Then le sheet passe par 3 etats : peek (25%), half (50%), expanded (85%),
And le contenu scrolle fluidement dans chaque etat,
And je peux revenir en arriere en draggant vers le bas.

**AC3 — En-tete restaurant :**
Given le catalogue est visible (peek ou plus),
Then je vois : nom du restaurant, badge VendorStatus (read-only), note moyenne (si > 0), frais de livraison en FCFA.

**AC4 — Liste produits :**
Given le catalogue est en half ou expanded,
When les produits chargent,
Then je vois une liste verticale scrollable avec pour chaque produit : photo WebP (CachedNetworkImage), nom, prix en FCFA.

**AC5 — Skeleton loading produits :**
Given les produits sont en cours de chargement,
Then des skeleton cards s'affichent (meme pattern que RestaurantCardSkeleton, pas de spinner seul — UX-DR14).

**AC6 — Bouton "+" ajout panier :**
Given un produit est affiche,
When je tape le bouton "+",
Then le produit est ajoute au panier local (Riverpod state),
And un feedback visuel confirme l'ajout (SnackBar vert ou animation compteur),
And le compteur du panier s'incremente.

**AC7 — Barre panier sticky :**
Given j'ai au moins 1 article dans le panier,
Then une barre sticky apparait en bas : "N article(s) — X FCFA -> Commander",
And la barre reste visible quel que soit l'etat du bottom sheet.

**AC8 — Produit en rupture de stock :**
Given un produit a stock = 0,
Then le produit est affiche en opacite reduite (0.5),
And le bouton "+" est desactive (AbsorbPointer),
And un label "Rupture" est visible.

**AC9 — Empty state catalogue :**
Given le marchand n'a aucun produit actif,
Then message humain : "Ce restaurant n'a pas encore de produits — revenez bientot !",
And jamais un ecran vide.

**AC10 — Error state catalogue :**
Given l'API echoue (timeout, 5xx),
Then message d'erreur clair + bouton "Reessayer" (invalidate provider),
And pas de crash.

**AC11 — Tap barre panier (stub) :**
Given j'ai des articles dans le panier,
When je tape la barre panier sticky,
Then SnackBar temporaire "Recapitulatif a venir" (stub — real navigation story 4.3).

## Tasks / Subtasks

### Task 1 — Backend Rust : Endpoint produits par marchand (AC: 4, 5, 8, 9, 10)

- [x]1.1 Verifier si `GET /api/v1/merchants/{merchant_id}/products` existe deja dans `server/crates/api/src/routes/merchants.rs`
  ```bash
  grep -r "products\|get_merchant_products" server/crates/api/src/ --include="*.rs"
  ```
- [x]1.2 Si absent : ajouter handler `GET /api/v1/merchants/{merchant_id}/products` dans `server/crates/api/src/routes/merchants.rs`
  - Path param : `merchant_id: Uuid`
  - Query params : `page: Option<u32>` (default 1), `per_page: Option<u32>` (default 50)
  - Auth : accessible aux roles `Client` et `Admin` (JWT requis)
  - Response : `ApiResponse::with_pagination()` (meme pattern que `list_merchants`)
- [x]1.3 Ajouter `list_merchant_products_public(merchant_id, page, per_page)` dans `server/crates/domain/src/merchants/service.rs`
  - Retourne uniquement les produits du marchand dont `onboarding_step = 5` (marchand finalise)
  - Inclut les produits avec stock = 0 (affiches en rupture cote Flutter)
- [x]1.4 Ajouter query SQL dans `server/crates/domain/src/merchants/repository.rs`
  ```sql
  SELECT p.id, p.name, p.price, p.stock, p.photo_url, p.merchant_id
  FROM products p
  INNER JOIN merchants m ON m.id = p.merchant_id
  WHERE p.merchant_id = $1 AND m.onboarding_step = 5
  ORDER BY p.name
  LIMIT $2 OFFSET $3
  ```
- [x]1.5 Creer `ProductSummary` dans `server/crates/domain/src/merchants/model.rs` (si pas deja present) :
  - `id: Id`, `name: String`, `price: i64` (centimes FCFA), `stock: i32`, `photo_url: Option<String>`, `merchant_id: Id`
  - Serialisation snake_case avec serde
- [x]1.6 Enregistrer la route dans le scope merchants existant dans `server/crates/api/src/routes/mod.rs`
- [x]1.7 Tests Rust :
  - `test_list_merchant_products_200` — retourne produits d'un marchand finalise
  - `test_list_merchant_products_empty` — retourne data vide si aucun produit
  - `test_list_merchant_products_401` — rejette sans token
  - `test_list_merchant_products_404` — marchand inexistant ou non finalise

### Task 2 — mefali_api_client : Endpoint + Provider produits B2C (AC: 4, 5, 10)

- [x]2.1 Etendre `packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart` :
  - Ajouter methode `listProducts({required String merchantId})` dans `RestaurantEndpoint`
  - `GET /merchants/{merchantId}/products?per_page=50`
  - Extraire `response.data!['data']` et mapper vers modele Dart
- [x]2.2 Creer provider dans `packages/mefali_api_client/lib/providers/restaurant_products_provider.dart` :
  ```dart
  final restaurantProductsProvider = FutureProvider.autoDispose
      .family<List<ProductItem>, String>((ref, merchantId) async {
    final endpoint = RestaurantEndpoint(ref.watch(dioProvider));
    return endpoint.listProducts(merchantId: merchantId);
  });
  ```
- [x]2.3 Exporter depuis `packages/mefali_api_client/lib/mefali_api_client.dart`

### Task 3 — mefali_core : Modele ProductItem B2C (AC: 4, 8)

- [x]3.1 Verifier si le modele `Product` existant dans `packages/mefali_core/lib/models/` convient pour le B2C
  - Le modele B2B Product peut avoir des champs specifiques marchand (stock alerts, etc.)
  - Si trop specifique B2B : creer `packages/mefali_core/lib/models/product_item.dart`
- [x]3.2 Modele `ProductItem` (si nouveau) :
  ```dart
  @JsonSerializable(fieldRename: FieldRename.snake)
  class ProductItem {
    const ProductItem({
      required this.id,
      required this.name,
      required this.price,
      required this.stock,
      this.photoUrl,
      required this.merchantId,
    });
    final String id;
    final String name;
    final int price;      // centimes FCFA
    final int stock;
    final String? photoUrl;
    final String merchantId;

    bool get isOutOfStock => stock <= 0;
    factory ProductItem.fromJson(Map<String, dynamic> json) => _$ProductItemFromJson(json);
    Map<String, dynamic> toJson() => _$ProductItemToJson(this);
  }
  ```
- [x]3.3 `dart run build_runner build` pour generer `product_item.g.dart`
- [x]3.4 Exporter depuis `packages/mefali_core/lib/mefali_core.dart`

### Task 4 — mefali_core : CartState local (AC: 6, 7, 11)

- [x]4.1 Creer `packages/mefali_core/lib/models/cart_item.dart` :
  ```dart
  class CartItem {
    const CartItem({required this.product, this.quantity = 1});
    final ProductItem product;
    final int quantity;
    int get totalPrice => product.price * quantity;
    CartItem copyWith({int? quantity}) => CartItem(product: product, quantity: quantity ?? this.quantity);
  }
  ```
- [x]4.2 Creer `packages/mefali_api_client/lib/providers/cart_provider.dart` :
  ```dart
  final cartProvider = StateNotifierProvider.autoDispose<CartNotifier, Map<String, CartItem>>(
    (ref) => CartNotifier(),
  );

  class CartNotifier extends StateNotifier<Map<String, CartItem>> {
    CartNotifier() : super({});

    void addProduct(ProductItem product) {
      final existing = state[product.id];
      state = {
        ...state,
        product.id: existing != null
            ? existing.copyWith(quantity: existing.quantity + 1)
            : CartItem(product: product),
      };
    }

    int get totalItems => state.values.fold(0, (sum, item) => sum + item.quantity);
    int get totalPrice => state.values.fold(0, (sum, item) => sum + item.totalPrice);

    void clear() => state = {};
  }
  ```
  **ATTENTION** : `autoDispose` sur le cart signifie qu'il se vide si on quitte l'ecran. Pour le MVP c'est acceptable (le panier est lie a un restaurant). Story 4.3 pourra le rendre persistent si necessaire.
- [x]4.3 Exporter depuis `packages/mefali_api_client/lib/mefali_api_client.dart` et `packages/mefali_core/lib/mefali_core.dart`

### Task 5 — mefali_design : Composant MefaliBottomSheet (AC: 2)

- [x]5.1 Creer `packages/mefali_design/lib/components/mefali_bottom_sheet.dart`
- [x]5.2 Utiliser `DraggableScrollableSheet` de Flutter (PAS de package externe) :
  ```dart
  class MefaliBottomSheet extends StatelessWidget {
    const MefaliBottomSheet({
      required this.builder,
      this.initialChildSize = 0.25,
      this.minChildSize = 0.25,
      this.maxChildSize = 0.85,
      this.snapSizes = const [0.25, 0.5, 0.85],
      super.key,
    });

    final ScrollableWidgetBuilder builder;
    final double initialChildSize;
    final double minChildSize;
    final double maxChildSize;
    final List<double> snapSizes;

    @override
    Widget build(BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        snap: true,
        snapSizes: snapSizes,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
            ),
            child: builder(context, scrollController),
          );
        },
      );
    }
  }
  ```
  - 3 snap points : 0.25 (peek), 0.50 (half), 0.85 (expanded)
  - Drag handle en haut (petit rectangle gris centre)
  - Border radius top 16dp
  - Ombre portee
- [x]5.3 Exporter depuis `packages/mefali_design/lib/mefali_design.dart`

### Task 6 — mefali_design : Composant ProductListTile (AC: 4, 6, 8)

- [x]6.1 Creer `packages/mefali_design/lib/components/product_list_tile.dart`
- [x]6.2 Layout horizontal :
  ```
  ┌──────────────────────────────────────────┐
  │ ┌──────┐  Nom produit              [+]  │
  │ │ Photo│  500 FCFA                       │
  │ │ 64dp │  (Rupture)  ← si stock=0       │
  │ └──────┘                                 │
  └──────────────────────────────────────────┘
  ```
  - Image : 64x64dp, `ClipRRect` borderRadius 8, `CachedNetworkImage` avec placeholder `primaryContainer`
  - Nom : `bodyMedium` bold, max 2 lignes, overflow ellipsis
  - Prix : `bodySmall`, `formatFcfa(product.price)` — **REUTILISER `formatFcfa()` de `mefali_core/lib/utils/formatting.dart`**
  - Bouton "+" : `IconButton` avec `Icons.add_circle_outline`, couleur `primary`
  - Etat rupture : `Opacity(0.5)` + `AbsorbPointer` + label "Rupture" en rouge
- [x]6.3 Skeleton variant `ProductListTileSkeleton` dans le meme fichier :
  - Memes dimensions, rectangles animes (meme pattern que `RestaurantCardSkeleton` : `ColorTween` sans package shimmer)
- [x]6.4 Signature :
  ```dart
  class ProductListTile extends StatelessWidget {
    const ProductListTile({
      required this.product,
      required this.onAdd,
      super.key,
    });
    final ProductItem product;
    final VoidCallback? onAdd; // null si rupture
  }
  ```
- [x]6.5 Exporter depuis `packages/mefali_design/lib/mefali_design.dart`

### Task 7 — mefali_design : Composant CartBar sticky (AC: 7, 11)

- [x]7.1 Creer `packages/mefali_design/lib/components/cart_bar.dart`
- [x]7.2 Barre fixe en bas de l'ecran :
  ```
  ┌──────────────────────────────────────────┐
  │  2 article(s) — 3 000 FCFA   [Commander]│
  └──────────────────────────────────────────┘
  ```
  - Background : `colorScheme.primary` (marron fonce)
  - Texte : blanc, `bodyMedium`
  - Bouton "Commander" : texte blanc, bold
  - Animation slide-up a l'apparition (quand premier article ajoute)
  - `Visibility` conditionnel : visible uniquement si `totalItems > 0`
- [x]7.3 Signature :
  ```dart
  class CartBar extends StatelessWidget {
    const CartBar({
      required this.itemCount,
      required this.totalPrice,
      required this.onTap,
      super.key,
    });
    final int itemCount;
    final int totalPrice; // centimes FCFA
    final VoidCallback onTap;
  }
  ```
- [x]7.4 Exporter depuis `packages/mefali_design/lib/mefali_design.dart`

### Task 8 — B2C app : RestaurantCatalogueScreen (AC: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)

- [x]8.1 Creer `apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart`
- [x]8.2 `ConsumerStatefulWidget` recevant `restaurantId` et `RestaurantSummary` en parametres
- [x]8.3 Layout :
  ```
  ┌─────────────────────────────────────┐
  │         [Image fond restaurant]     │  ← Fond : photo restaurant en plein ecran
  │                                     │
  │  ┌─────────────────────────────┐    │
  │  │ ── drag handle ──           │    │  ← MefaliBottomSheet
  │  │ Nom restaurant    [Status]  │    │
  │  │ ★ 4.7  •  500 FCFA livr.   │    │
  │  │─────────────────────────────│    │
  │  │ [Photo] Garba        [+]   │    │  ← ProductListTile
  │  │         1 500 FCFA         │    │
  │  │ [Photo] Alloco       [+]   │    │
  │  │         1 000 FCFA         │    │
  │  │ [Photo] Jus          [+]   │    │
  │  │         500 FCFA           │    │
  │  └─────────────────────────────┘    │
  │                                     │
  │  ┌─────────────────────────────┐    │  ← CartBar (si items > 0)
  │  │ 2 article(s) — 3 000 FCFA  │    │
  │  └─────────────────────────────┘    │
  └─────────────────────────────────────┘
  ```
- [x]8.4 Structure widget :
  ```dart
  Scaffold(
    body: Stack(
      children: [
        // Fond : photo restaurant ou couleur primaire
        _RestaurantBackground(restaurant: restaurant),
        // Bottom sheet avec catalogue
        MefaliBottomSheet(
          builder: (context, scrollController) {
            return CustomScrollView(
              controller: scrollController,
              slivers: [
                // Header restaurant (nom, status, rating, delivery fee)
                SliverToBoxAdapter(child: _RestaurantHeader(restaurant)),
                // Liste produits
                Consumer(builder: (_, ref, __) {
                  return ref.watch(restaurantProductsProvider(restaurantId)).when(
                    loading: () => _buildSkeletonList(),
                    data: (products) => products.isEmpty
                        ? _buildEmptyState()
                        : _buildProductList(products, ref),
                    error: (err, _) => _buildErrorState(ref),
                  );
                }),
              ],
            );
          },
        ),
        // CartBar sticky en bas
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Consumer(builder: (_, ref, __) {
            final cart = ref.watch(cartProvider);
            final notifier = ref.read(cartProvider.notifier);
            if (notifier.totalItems == 0) return const SizedBox.shrink();
            return CartBar(
              itemCount: notifier.totalItems,
              totalPrice: notifier.totalPrice,
              onTap: () => _showCartStub(context),
            );
          }),
        ),
      ],
    ),
  )
  ```
- [x]8.5 Back navigation : `AppBar` transparent avec bouton retour, ou swipe back iOS standard
- [x]8.6 Ajout panier : `ref.read(cartProvider.notifier).addProduct(product)` + SnackBar vert court "Ajoute au panier"
- [x]8.7 Stub barre panier : `ScaffoldMessenger.showSnackBar("Recapitulatif a venir")` (story 4.3)

### Task 9 — B2C app : Mise a jour navigation (AC: 1)

- [x]9.1 Modifier `apps/mefali_b2c/lib/app.dart` : ajouter route `/restaurant/:id`
  ```dart
  GoRoute(
    path: '/restaurant/:id',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      final restaurant = state.extra as RestaurantSummary;
      return RestaurantCatalogueScreen(restaurantId: id, restaurant: restaurant);
    },
  ),
  ```
- [x]9.2 Modifier `apps/mefali_b2c/lib/features/home/home_screen.dart` :
  - Remplacer le SnackBar "Catalogue a venir" dans `onTap` de `RestaurantCard`
  - Par : `context.push('/restaurant/${restaurant.id}', extra: restaurant)`
  - Importer `go_router` si pas deja fait

### Task 10 — Tests (AC: 1-11)

- [x]10.1 Tests widget `ProductListTile` :
  - Photo affichee, nom affiche, prix affiche via `formatFcfa`
  - Bouton "+" fonctionnel (callback appele)
  - Etat rupture : opacite reduite, bouton desactive, label "Rupture" visible
- [x]10.2 Tests widget `CartBar` :
  - Affiche count et total
  - onTap callback appele
- [x]10.3 Tests widget `MefaliBottomSheet` :
  - Se rend sans crash
  - Contenu builder affiche
- [x]10.4 Tests widget `RestaurantCatalogueScreen` :
  - Skeleton pendant loading
  - Produits affiches apres chargement
  - Empty state si aucun produit
  - Error state avec retry
  - Ajout panier : compteur incremente, SnackBar confirme
  - CartBar apparait quand items > 0
- [x]10.5 Tests Rust backend :
  - `test_list_merchant_products_200`
  - `test_list_merchant_products_empty`
  - `test_list_merchant_products_401`
- [x]10.6 Pattern mock provider :
  ```dart
  testWidgets('...', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        restaurantProductsProvider('merchant-id').overrideWith(
          (ref, _) async => [testProduct1, testProduct2],
        ),
      ],
      child: MaterialApp(home: RestaurantCatalogueScreen(...)),
    ));
  });
  ```

## Dev Notes

### Composants existants a REUTILISER obligatoirement

| Composant | Source | Usage |
|-----------|--------|-------|
| `VendorStatusIndicator` | `packages/mefali_design/lib/components/vendor_status_indicator.dart` | Badge status dans header restaurant (read-only, `isInteractive: false`) |
| `RestaurantSummary` | `packages/mefali_core/lib/models/restaurant_summary.dart` | Donnees restaurant passees via `extra` GoRouter |
| `VendorStatus` enum | `packages/mefali_core/lib/enums/vendor_status.dart` | Logique status |
| `formatFcfa()` | `packages/mefali_core/lib/utils/formatting.dart` | Affichage prix — **NE PAS RECREER** |
| `MefaliColors` | `packages/mefali_design/lib/mefali_colors.dart` | Couleurs placeholder, skeleton |
| `MefaliTheme` | `packages/mefali_design/lib/mefali_theme.dart` | Theme global |
| `CachedNetworkImage` | Package `cached_network_image` | Images produits et restaurant |
| `dioProvider` | `packages/mefali_api_client/lib/dio_client/dio_client.dart` | HTTP client dans RestaurantEndpoint |
| `RestaurantEndpoint` | `packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart` | Etendre (ne pas creer un nouveau endpoint) |
| `authProvider` | `apps/mefali_b2c/lib/app.dart` | GoRouter auth redirect — NE PAS MODIFIER |
| `ApiResponse` | `server/crates/common/src/response.rs` | Response wrapper backend |
| `AppError` | `server/crates/common/src/error.rs` | Errors backend |

### Anti-patterns a EVITER

- **JAMAIS** de spinner `CircularProgressIndicator` seul → skeleton obligatoire (UX-DR14)
- **JAMAIS** de couleurs hardcodees → `Theme.of(context).colorScheme`, `MefaliColors`
- **JAMAIS** de `FutureBuilder` → `AsyncValue.when()` Riverpod uniquement
- **JAMAIS** oublier `autoDispose` sur les providers → fuite memoire sur 2GB RAM
- **JAMAIS** de scroll horizontal sur la liste produits (anti-pattern UX explicite)
- **NE PAS** ajouter de package externe pour le bottom sheet → `DraggableScrollableSheet` natif Flutter
- **NE PAS** ajouter de package shimmer → animation `ColorTween` custom (APK < 30MB)
- **NE PAS** creer un nouveau fichier endpoint pour les produits B2C → etendre `RestaurantEndpoint` existant
- **NE PAS** dupliquer `formatFcfa()` — importer depuis `mefali_core`
- **NE PAS** oublier les exports dans les barrel files (`mefali_design.dart`, `mefali_core.dart`, `mefali_api_client.dart`)

### Patterns Riverpod (identiques a story 4.1)

```dart
// FutureProvider.autoDispose.family — OBLIGATOIRE
final restaurantProductsProvider = FutureProvider.autoDispose
    .family<List<ProductItem>, String>((ref, merchantId) async {
  return ref.watch(restaurantEndpointProvider).listProducts(merchantId: merchantId);
});

// StateNotifierProvider pour le cart
final cartProvider = StateNotifierProvider.autoDispose<CartNotifier, Map<String, CartItem>>(
  (ref) => CartNotifier(),
);

// AsyncValue.when() — OBLIGATOIRE (jamais FutureBuilder)
ref.watch(restaurantProductsProvider(merchantId)).when(
  data: (products) => _buildProductList(products),
  loading: () => _buildSkeletonList(),
  error: (err, _) => _buildErrorState(err, ref),
);
```

### API Response format attendu (backend)

```json
{
  "data": [
    {
      "id": "uuid-v4",
      "name": "Garba classique",
      "price": 150000,
      "stock": 25,
      "photo_url": "http://minio:9000/products/photo.webp",
      "merchant_id": "uuid-v4"
    }
  ],
  "meta": {"page": 1, "total": 12, "per_page": 50}
}
```

Prix en centimes FCFA (convention du projet). 150000 centimes = 1 500 FCFA. `formatFcfa(150000)` → "1 500 FCFA".

### Backend Rust — Pattern a suivre

Meme pattern que `list_merchants` dans `merchants.rs` :
- Handler Actix avec `AuthenticatedUser` extracteur
- `require_role()` pour verifier le role
- Delegation au service domain
- `ApiResponse::with_pagination()` pour la reponse
- Tests avec `TestApp::new()` (pattern existant dans le fichier)

### Navigation GoRouter — Pattern

```dart
// Dans HomeScreen, remplacer le SnackBar stub par :
onTap: () => context.push(
  '/restaurant/${restaurant.id}',
  extra: restaurant,  // passer RestaurantSummary pour affichage immediat
),

// Route dans app.dart :
GoRoute(
  path: '/restaurant/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final restaurant = state.extra as RestaurantSummary;
    return RestaurantCatalogueScreen(restaurantId: id, restaurant: restaurant);
  },
),
```

### Gestion offline

- Catalogue consultable offline (derniere version cachee) — mentionee dans PRD
- Pour le MVP : pas d'implementation offline specifique pour le catalogue produits
- Le `CachedNetworkImage` cache deja les images sur disque
- L'offline complet sera gere via `mefali_offline` package dans une story future

### Verifications critiques avant de soumettre

1. `dart analyze packages/mefali_design packages/mefali_core packages/mefali_api_client apps/mefali_b2c` → 0 errors
2. `flutter test apps/mefali_b2c` → tous les tests passent
3. `cargo test --workspace` → pas de regression Rust
4. `dart run build_runner build` dans `packages/mefali_core` si nouveau modele genere
5. Verifier que tous les barrel files exportent les nouveaux fichiers

### Project Structure Notes

**Fichiers a CREER :**
```
packages/mefali_design/lib/components/mefali_bottom_sheet.dart
packages/mefali_design/lib/components/product_list_tile.dart
packages/mefali_design/lib/components/cart_bar.dart
packages/mefali_core/lib/models/product_item.dart
packages/mefali_core/lib/models/cart_item.dart
packages/mefali_api_client/lib/providers/restaurant_products_provider.dart
packages/mefali_api_client/lib/providers/cart_provider.dart
apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart
```

**Fichiers a MODIFIER :**
```
packages/mefali_design/lib/mefali_design.dart                      ← exports
packages/mefali_core/lib/mefali_core.dart                          ← exports
packages/mefali_api_client/lib/mefali_api_client.dart              ← exports
packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart  ← ajouter listProducts()
apps/mefali_b2c/lib/app.dart                                       ← route /restaurant/:id
apps/mefali_b2c/lib/features/home/home_screen.dart                 ← onTap → context.push
apps/mefali_b2c/test/widget_test.dart                              ← nouveaux tests
server/crates/api/src/routes/merchants.rs                           ← handler GET products
server/crates/api/src/routes/mod.rs                                 ← register route
server/crates/domain/src/merchants/service.rs                       ← list_merchant_products_public
server/crates/domain/src/merchants/repository.rs                    ← query SQL products
server/crates/domain/src/merchants/model.rs                         ← ProductSummary struct
```

### Previous Story Intelligence (4.1)

- HomeScreen utilise `NavigationBar` + `IndexedStack` (PAS ShellRoute contrairement au plan initial)
- Le pattern fonctionne — ne pas refactorer vers ShellRoute pour cette story
- `RestaurantCard` a un callback `onTap` qui fait actuellement un SnackBar "Catalogue a venir" → remplacer par navigation
- Le `RestaurantEndpoint` existe deja avec `listRestaurants()` → etendre avec `listProducts()`
- Les produits B2B existent via `ProductEndpoint` et `productCatalogueProvider` — NE PAS les reutiliser pour B2C (endpoint different, roles differents)
- La grid utilise `mainAxisExtent: 250` et `crossAxisSpacing: 8` — garder la coherence visuelle
- Le skeleton pattern est etabli dans `RestaurantCardSkeleton` — reproduire le meme pattern pour `ProductListTileSkeleton`

### Git Intelligence

Derniers commits pertinents :
- `ec6270f` — 4-1-restaurant-discovery-and-home: done
- `b961856` — 3-10-demo-mode: done, 4-1 in-progress
- Fichiers modifies dans 4.1 : `home_screen.dart`, `restaurant_endpoint.dart`, `restaurant_card.dart`, `merchants.rs`

Les patterns de code, conventions de nommage et structure de fichiers sont bien etablis par les stories precedentes. Suivre exactement les memes conventions.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 4, Story 4.2, FR12, UX-DR2/DR3]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — "Experience Mechanics Flow B2C Etape 3 Commande", "MefaliBottomSheet 3 etats", "ProductCard layout"]
- [Source: _bmad-output/planning-artifacts/architecture.md — Frontend Architecture Flutter, Riverpod patterns, REST endpoints, DraggableScrollableSheet]
- [Source: _bmad-output/planning-artifacts/prd.md — FR12 catalogue marchand, NFR6 < 2s chargement, Journey Koffi]
- [Source: _bmad-output/implementation-artifacts/4-1-restaurant-discovery-and-home.md — RestaurantEndpoint pattern, skeleton pattern, navigation pattern]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend: Added `GET /api/v1/merchants/{id}/products` endpoint with pagination, auth (Client/Admin), and 404 for non-finalized merchants
- Created `ProductSummary` struct in merchants domain (lightweight, excludes internal fields)
- Added repository functions `find_products_for_discovery` and `count_products_for_discovery`
- Added service function `list_merchant_products_public` with merchant existence + finalization check
- 4 Rust integration tests added (200, 200 empty, 401, 404)
- Flutter: Created `ProductItem` model (lightweight B2C product) + `CartItem` model
- Created `RestaurantEndpoint.listProducts()` extending existing endpoint
- Created `restaurantProductsProvider` (FutureProvider.autoDispose.family)
- Created `CartNotifier` + `cartProvider` (NotifierProvider.autoDispose, Riverpod 3.x pattern)
- Created `MefaliBottomSheet` component (DraggableScrollableSheet, 3 snap points, drag handle)
- Created `ProductListTile` + `ProductListTileSkeleton` (photo 64x64, name, price, "+", rupture state)
- Created `CartBar` sticky bottom component (item count, total price, "Commander" button)
- Created `RestaurantCatalogueScreen` combining all components with Stack layout
- Updated HomeScreen: replaced SnackBar stub with `context.push('/restaurant/:id', extra: restaurant)`
- Added GoRoute `/restaurant/:id` in app.dart
- 14 new widget tests added (ProductListTile, CartBar, MefaliBottomSheet, RestaurantCatalogueScreen)
- All 27 tests pass, 0 errors on dart analyze
- **Code Review Fixes (2026-03-19):**
  - [H1] _ProductsList: replaced WidgetRef field anti-pattern with ConsumerWidget
  - [H2] Rust test_list_merchant_products_404_not_finalized: now uses actual non-finalized merchant ID instead of random UUID
  - [M1] _RestaurantBackground: replaced Image.network with CachedNetworkImage (perf/caching)
  - [M2] SnackBar "ajouté au panier": changed from colorScheme.primary (brown) to Colors.green (AC6)
  - [M3] CartBar: added AnimatedSlide slide-up animation at appearance (AC7)
  - [L1] _EmptyState: added const constructor (prefer_const_constructors)
  - Added cached_network_image dependency to mefali_b2c/pubspec.yaml

### File List

- packages/mefali_core/lib/models/product_item.dart (created)
- packages/mefali_core/lib/models/product_item.g.dart (generated)
- packages/mefali_core/lib/models/cart_item.dart (created)
- packages/mefali_core/lib/mefali_core.dart (modified — exports)
- packages/mefali_design/lib/components/mefali_bottom_sheet.dart (created)
- packages/mefali_design/lib/components/product_list_tile.dart (created)
- packages/mefali_design/lib/components/cart_bar.dart (created)
- packages/mefali_design/lib/mefali_design.dart (modified — exports)
- packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart (modified — listProducts)
- packages/mefali_api_client/lib/providers/restaurant_products_provider.dart (created)
- packages/mefali_api_client/lib/providers/cart_provider.dart (created)
- packages/mefali_api_client/lib/mefali_api_client.dart (modified — exports)
- apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart (created)
- apps/mefali_b2c/lib/features/home/home_screen.dart (modified — navigation)
- apps/mefali_b2c/lib/app.dart (modified — route /restaurant/:id)
- apps/mefali_b2c/test/widget_test.dart (modified — 14 new tests)
- server/crates/domain/src/merchants/model.rs (modified — ProductSummary)
- server/crates/domain/src/merchants/repository.rs (modified — find/count products)
- server/crates/domain/src/merchants/service.rs (modified — list_merchant_products_public)
- server/crates/api/src/routes/merchants.rs (modified — list_merchant_products handler + 4 tests)
- server/crates/api/src/routes/mod.rs (modified — GET route registered)
- apps/mefali_b2c/pubspec.yaml (modified — added cached_network_image dependency)
