# Story 4.3: Panier & Passage de Commande

Status: done

## Story

As a client B2C,
I want to see transparent pricing before ordering,
so that I know exactly what I'll pay.

## Contexte Metier

FR13: Client B2C peut ajouter des produits au panier et passer commande.
FR14: Client B2C peut voir le prix total transparent avant confirmation (articles + frais de livraison).
UX-DR9: PriceBreakdownSheet — recapitulatif articles + livraison + total, total = texte le plus gros.
UX-DR2: MefaliBottomSheet progressif (3 etats : peek 25% / half 50% / expanded 85%).

Cible business: taux d'abandon panier < 30% (vs 69% moyen observe en CI). La transparence des prix est le levier principal.

Le parcours Koffi (PRD): "Il ajoute au panier. L'ecran de confirmation affiche clairement : plat 1 500 + livraison 500 = 2 000 FCFA total. Pas de surprise. Il choisit Payer a la livraison (cash)."

## Criteres d'Acceptation

AC1: **Given** articles dans le panier **When** je tape le CartBar **Then** PriceBreakdownSheet s'ouvre et affiche la liste des articles avec quantites, le sous-total, les frais de livraison, et le total.

AC2: **Given** PriceBreakdownSheet ouverte **When** je tape +/- sur un article **Then** la quantite se met a jour, le sous-total et le total se recalculent instantanement.

AC3: **Given** PriceBreakdownSheet ouverte **When** je decremente un article a 0 **Then** l'article est supprime du panier. Si le panier est vide, le sheet se ferme et le CartBar disparait.

AC4: **Given** PriceBreakdownSheet ouverte **Then** le TOTAL est affiche avec la police la plus grande de l'ecran (UX-DR9). Zero frais cache.

AC5: **Given** articles dans le panier et total affiche **When** je tape "Commander" **Then** un appel POST /api/v1/orders est envoye avec les articles, payment_type=cod (defaut), et une adresse par defaut (stub texte).

AC6: **Given** commande creee avec succes **When** API retourne 201 **Then** ecran de confirmation affiche le numero de commande, le recapitulatif, et un message de succes. Le panier est vide.

AC7: **Given** erreur API lors de la creation **When** API retourne une erreur **Then** un message d'erreur clair s'affiche avec option de reessayer. Le panier est preserve.

AC8: **Given** PriceBreakdownSheet en chargement **Then** skeleton screens affiches (jamais spinner seul — UX-DR14).

AC9: **Given** commande confirmee **Then** navigation vers l'ecran "Mes Commandes" ou retour home (selon flow disponible).

## Taches / Sous-taches

- [x] **Tache 1: Enrichir CartNotifier** (AC: 2, 3)
  - [x] 1.1 Ajouter `incrementProduct(String productId)` dans CartNotifier
  - [x] 1.2 Ajouter `decrementProduct(String productId)` — supprime si quantite = 0
  - [x] 1.3 Ajouter `removeProduct(String productId)`
  - [x] 1.4 Tests unitaires CartNotifier (increment, decrement, remove, decrement-to-zero)

- [x] **Tache 2: Modele Order frontend** (AC: 6) — DEJA EXISTANT (story 3.6)
  - [x] 2.1 Order model existe dans `packages/mefali_core/lib/models/order.dart`
  - [x] 2.2 CreateOrderPayload gere par OrderEndpoint.createOrder() avec params nommes
  - [x] 2.3 Deja exporte dans `packages/mefali_core/lib/mefali_core.dart`
  - [x] 2.4 .g.dart deja genere

- [x] **Tache 3: OrderEndpoint + Provider** (AC: 5, 7) — DEJA EXISTANT (story 3.6)
  - [x] 3.1 OrderEndpoint existe avec createOrder() dans `packages/mefali_api_client/lib/endpoints/order_endpoint.dart`
  - [x] 3.2 Deja enregistre dans MefaliApiClient
  - [x] 3.3 Deja exporte dans le barrel file `mefali_api_client.dart`

- [x] **Tache 4: PriceBreakdownSheet** (AC: 1, 2, 3, 4, 8)
  - [x] 4.1 Cree `packages/mefali_design/lib/components/price_breakdown_sheet.dart`
  - [x] 4.2 Layout: liste articles (nom, quantite +/-, prix ligne), separateur, ligne "Livraison", separateur, ligne TOTAL (headlineMedium = police la plus grande)
  - [x] 4.3 Boutons +/- par article avec callbacks onIncrement/onDecrement
  - [x] 4.4 Bouton "Commander — X FCFA" pleine largeur, FilledButton primary
  - [x] 4.5 Skeleton variant `PriceBreakdownSheetSkeleton` avec ColorTween animation
  - [x] 4.6 Exporte dans `packages/mefali_design/lib/mefali_design.dart`

- [x] **Tache 5: Ecran de confirmation de commande** (AC: 6, 9)
  - [x] 5.1 Cree `apps/mefali_b2c/lib/features/order/order_confirmation_screen.dart`
  - [x] 5.2 Affiche: icone succes, numero de commande (#ID tronque), recapitulatif items + livraison + total, message "Votre commande est en cours de preparation"
  - [x] 5.3 Bouton "Retour a l'accueil" (context.go('/home'))

- [x] **Tache 6: Connecter le flow dans RestaurantCatalogueScreen** (AC: 1, 5, 6, 7)
  - [x] 6.1 Remplace stub CartBar.onTap par _showPriceBreakdown() via showModalBottomSheet
  - [x] 6.2 Passe callbacks +/- vers CartNotifier.incrementProduct/decrementProduct
  - [x] 6.3 Sur tap "Commander": appel OrderEndpoint.createOrder() avec payment_type=cod
  - [x] 6.4 Sur succes: vider le panier, fermer sheet, naviguer vers /order/confirmation
  - [x] 6.5 Sur erreur: SnackBar rouge avec message + action "Reessayer"

- [x] **Tache 7: Route navigation** (AC: 9)
  - [x] 7.1 Ajoute route `/order/confirmation` dans app.dart avec extra: Order

- [x] **Tache 8: Tests** (AC: tous)
  - [x] 8.1 Tests widget PriceBreakdownSheet (affichage articles, +/-, total, commander, skeleton)
  - [x] 8.2 Tests widget OrderConfirmationScreen (affichage numero, recapitulatif, livraison, bouton retour)
  - [x] 8.3 Tests unitaires CartNotifier (increment, decrement, remove, decrement-to-zero, unknown id, totals)
  - [x] 8.4 `dart analyze packages/mefali_core packages/mefali_design packages/mefali_api_client` → 0 erreurs
  - [x] 8.5 `flutter test apps/mefali_b2c` → 41 tests passent (14 nouveaux + 27 existants)
  - [x] 8.6 `cargo test --workspace` → echecs pre-existants (tests integration DB), pas de regression

## Dev Notes

### Ce qui EXISTE deja (ne pas recreer)

**Backend Rust — COMPLET pour cette story:**
- `POST /api/v1/orders` existe dans `server/crates/api/src/routes/orders.rs` (role Client requis)
- `CreateOrderPayload` dans `server/crates/domain/src/orders/model.rs` — champs: merchant_id, items (Vec<CreateOrderItemPayload>), payment_type, delivery_address, lat/lng, city_id, notes
- `create_order` service dans `server/crates/domain/src/orders/service.rs` — valide le merchant, resout les prix depuis la DB (ne fait JAMAIS confiance aux prix client), creation atomique order + items en transaction
- Enums: `OrderStatus` (Pending, Confirmed, Preparing, Ready, Collected, InTransit, Delivered, Cancelled), `PaymentType` (Cod, MobileMoney), `PaymentStatus` (Pending, EscrowHeld, Released, Refunded)
- `OrderWithItems` struct pour la reponse enrichie

**Frontend Flutter — Composants existants:**
- `CartItem` model: `packages/mefali_core/lib/models/cart_item.dart` — fields: product (ProductItem), quantity. Computed: totalPrice = product.price * quantity
- `CartNotifier` + `cartProvider`: `packages/mefali_api_client/lib/providers/cart_provider.dart` — NotifierProvider.autoDispose, state = Map<String, CartItem>. Methodes existantes: addProduct(), totalItems, totalPrice, clear()
- `CartBar`: `packages/mefali_design/lib/components/cart_bar.dart` — barre sticky en bas, AnimatedSlide, "N article(s) — X FCFA [Commander]"
- `MefaliBottomSheet`: `packages/mefali_design/lib/components/mefali_bottom_sheet.dart` — DraggableScrollableSheet 3 snap points (0.25, 0.50, 0.85)
- `ProductItem` model: `packages/mefali_core/lib/models/product_item.dart` — id, name, price (centimes FCFA), stock, photoUrl, merchantId
- `RestaurantCatalogueScreen`: `apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart` — le CartBar.onTap montre actuellement un SnackBar stub "Recapitulatif a venir"
- `formatFcfa()` dans mefali_core — utiliser pour formater les prix

**Utilitaires et patterns:**
- `RestaurantEndpoint` dans `packages/mefali_api_client/lib/endpoints/restaurant_endpoint.dart` — modele a suivre pour OrderEndpoint
- `dioProvider` pour les appels HTTP
- `authProvider` pour l'authentification
- `ApiResponse` wrapper pour les reponses API
- `MefaliColors`, `MefaliTheme` pour les styles
- `CachedNetworkImage` pour les images

### Architecture et Patterns OBLIGATOIRES

**Riverpod:**
- `autoDispose` par defaut sur tous les providers
- `family` pour les providers parametres
- `AsyncValue.when()` pour gerer loading/error/data — JAMAIS FutureBuilder
- `StateNotifierProvider.autoDispose` pour le cart (deja en place)

**API:**
- Format reponse: `{"data": {...}, "meta": {...}}`
- snake_case partout (JSON, endpoints)
- `@JsonSerializable(fieldRename: FieldRename.snake)` sur les modeles Dart
- Prix en centimes FCFA (int, pas double)
- IDs = UUID v4

**UI:**
- Skeleton screens pour TOUS les loading states (jamais spinner seul)
- Touch targets >= 48dp
- Bouton principal: FilledButton marron fonce, pleine largeur, 1 max par ecran
- Pas de couleurs hardcodees — utiliser MefaliColors/Theme
- Mode clair + mode sombre supportes

**Navigation:**
- GoRouter avec `context.push()` et `extra` parameter
- Pattern existant: `/restaurant/:id` dans app.dart — suivre le meme modele

### Decisions de scope pour cette story

**Adresse de livraison:** Story 4.6 (Address Selection) n'est pas encore implementee. Pour cette story, utiliser un champ texte simple pour l'adresse de livraison. Le MapAddressPicker sera ajoute dans 4.6.

**Frais de livraison:** Utiliser un montant fixe de 500 FCFA (valeur du PRD Journey Koffi) en attendant le calcul dynamique base sur la distance (story 4.6 + city_config.delivery_multiplier).

**Methode de paiement:** Defaut COD (payment_type: cod). Pas de selection Mobile Money dans cette story — c'est story 4.5. Le PriceBreakdownSheet ne montre PAS le choix de paiement, seulement le recapitulatif et "Commander".

**Cart autoDispose:** Le cart actuel est autoDispose (se vide quand on quitte l'ecran restaurant). C'est acceptable pour le MVP — le panier est lie a un seul restaurant. Ne PAS changer ce comportement.

### Anti-patterns a EVITER

- NE PAS creer de nouveau package shimmer — utiliser ColorTween comme dans ProductListTileSkeleton
- NE PAS utiliser FutureBuilder — utiliser AsyncValue.when()
- NE PAS hardcoder les couleurs — utiliser MefaliColors/Theme
- NE PAS envoyer les prix depuis le client — le backend resout les prix depuis la DB
- NE PAS creer de nouveau fichier endpoint dans un dossier different — suivre le pattern de restaurant_endpoint.dart
- NE PAS oublier d'exporter dans les barrel files (mefali_core.dart, mefali_design.dart, mefali_api_client.dart)
- NE PAS oublier `dart run build_runner build` apres creation de modeles @JsonSerializable
- NE PAS utiliser de package externe pour le bottom sheet — DraggableScrollableSheet natif
- NE PAS utiliser avoid_print — utiliser debugPrint si necessaire
- NE PAS creer un nouveau CartNotifier — enrichir l'existant avec les nouvelles methodes

### Project Structure Notes

Fichiers a creer:
```
packages/mefali_core/lib/models/order.dart              # OrderResponse model
packages/mefali_core/lib/models/create_order_request.dart # CreateOrderRequest payload
packages/mefali_api_client/lib/endpoints/order_endpoint.dart # OrderEndpoint
packages/mefali_design/lib/components/price_breakdown_sheet.dart # PriceBreakdownSheet
apps/mefali_b2c/lib/features/order/order_confirmation_screen.dart # Confirmation screen
```

Fichiers a modifier:
```
packages/mefali_api_client/lib/providers/cart_provider.dart  # Ajouter increment/decrement/remove
packages/mefali_core/lib/mefali_core.dart                    # Exports
packages/mefali_design/lib/mefali_design.dart                # Exports
packages/mefali_api_client/lib/mefali_api_client.dart        # Exports + OrderEndpoint registration
apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart # Remplacer stub CartBar.onTap
apps/mefali_b2c/lib/app.dart                                 # Route /order/confirmation/:id
apps/mefali_b2c/test/widget_test.dart                        # Nouveaux tests
```

### UX Reference — PriceBreakdownSheet Layout

D'apres le spec UX (Flow B2C Step 4 Confirmation):
```
Bottom sheet recapitulatif :
  Garba + alloco     1 500 FCFA
  Jus gingembre        500 FCFA
  Livraison            500 FCFA
  ---------------------------------
  TOTAL              2 500 FCFA

[  COMMANDER — 2 500 FCFA  ]  <- Gros bouton marron fonce (FilledButton primary, pleine largeur)
```

Le total est le texte le plus gros de l'ecran. Zero frais cache. La confiance se construit par la transparence.

Note: Le choix de paiement (COD/Mobile Money) n'est PAS dans cette story. Il sera dans stories 4.4/4.5. Ici on envoie directement payment_type=cod.

### CreateOrderRequest Payload (aligne avec backend)

```dart
{
  "merchant_id": "uuid",
  "items": [
    {"product_id": "uuid", "quantity": 2}
  ],
  "payment_type": "cod",
  "delivery_address": "Texte saisi par l'utilisateur",
  "lat": null,   // Sera rempli par story 4.6
  "lng": null,   // Sera rempli par story 4.6
  "city_id": null, // Sera rempli par story 4.6
  "notes": null
}
```

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic-4-Story-4.3]
- [Source: _bmad-output/planning-artifacts/prd.md#Journey-3-Koffi]
- [Source: _bmad-output/planning-artifacts/architecture.md#API-Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Database-Schema-orders]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#UX-DR9-PriceBreakdownSheet]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Flow-B2C-Step-4-Confirmation]
- [Source: _bmad-output/implementation-artifacts/4-2-restaurant-catalogue-view.md]
- [Source: server/crates/domain/src/orders/model.rs]
- [Source: server/crates/domain/src/orders/service.rs]
- [Source: packages/mefali_api_client/lib/providers/cart_provider.dart]
- [Source: packages/mefali_design/lib/components/cart_bar.dart]

### Verifications Critiques Avant Soumission

1. `dart analyze packages/mefali_core packages/mefali_design packages/mefali_api_client` → 0 erreurs
2. `flutter test apps/mefali_b2c` → tous les tests passent
3. `cargo test --workspace` → pas de regression
4. `dart run build_runner build` si nouveaux modeles @JsonSerializable
5. Verifier les exports dans les barrel files
6. Verifier que le CartBar.onTap ouvre bien le PriceBreakdownSheet (plus de stub)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Taches 2-3 (Order model + OrderEndpoint) deja existantes depuis story 3.6 — reutilisation directe
- CartNotifier enrichi avec incrementProduct(), decrementProduct(), removeProduct()
- PriceBreakdownSheet cree avec layout UX-DR9 (total = headlineMedium, texte le plus gros)
- PriceBreakdownSheetSkeleton avec ColorTween animation (pas de shimmer package)
- OrderConfirmationScreen avec recapitulatif complet (items, livraison, total)
- Flow connecte: CartBar tap → showModalBottomSheet → PriceBreakdownSheet → Commander → OrderEndpoint.createOrder() → OrderConfirmationScreen
- Route /order/confirmation ajoutee dans GoRouter avec extra: Order
- Gestion erreur: SnackBar rouge avec action "Reessayer"
- Panier vide automatiquement apres commande reussie
- Fermeture auto du bottom sheet si panier vide (decrement dernier article)
- 14 nouveaux tests (6 CartNotifier + 5 PriceBreakdownSheet + 3 OrderConfirmationScreen)
- 41/41 tests passent, dart analyze 0 erreurs sur les 3 packages

### Change Log

- 2026-03-19: Implementation complete story 4.3 — cart management, price breakdown, order placement, confirmation screen

### File List

**Crees:**
- packages/mefali_design/lib/components/price_breakdown_sheet.dart
- apps/mefali_b2c/lib/features/order/order_confirmation_screen.dart

**Modifies:**
- packages/mefali_api_client/lib/providers/cart_provider.dart
- packages/mefali_design/lib/mefali_design.dart
- apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart
- apps/mefali_b2c/lib/app.dart
- apps/mefali_b2c/test/widget_test.dart
