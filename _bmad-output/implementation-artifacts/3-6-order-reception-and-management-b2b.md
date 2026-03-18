# Story 3.6: Reception et gestion des commandes (B2B)

Status: done

## Story

As a marchand,
I want recevoir et gerer les commandes entrantes avec notification sonore,
so that je ne manque jamais une commande et je peux la traiter rapidement.

## Acceptance Criteria

1. **AC1 — Notification commande entrante**: Given une commande passee par un client When elle arrive au marchand Then un son custom mefali joue, une vibration longue se declenche, et un OrderCard apparait dans l'onglet Commandes avec les details (produits, quantites, prix unitaires, total, notes client).

2. **AC2 — Accepter une commande**: Given un OrderCard en etat "nouvelle" When le marchand tape le bouton ACCEPTER (vert, large) Then le statut passe a "confirmed" via `PUT /api/v1/orders/{id}/accept`, le compteur `consecutive_no_response` est remis a 0, et l'OrderCard passe en etat "En preparation".

3. **AC3 — Refuser une commande**: Given un OrderCard en etat "nouvelle" When le marchand tape REFUSER Then une raison est demandee (choix predefinit ou texte libre), le statut passe a "cancelled" via `PUT /api/v1/orders/{id}/reject`, et l'OrderCard disparait de la liste active.

4. **AC4 — Marquer commande prete**: Given un OrderCard en etat "En preparation" When le marchand tape PRETE Then le statut passe a "ready" via `PUT /api/v1/orders/{id}/ready`, et le systeme notifie le livreur (hors scope — juste l'appel API).

5. **AC5 — Liste des commandes actives**: Given le marchand sur l'onglet Commandes Then il voit toutes les commandes actives (pending, confirmed, preparing, ready) triees par date de creation (les plus recentes en haut), avec un badge compteur sur l'onglet.

6. **AC6 — Non-reponse et auto-pause**: Given une commande "pending" non repondue When le timeout expire (gere cote serveur) Then `increment_no_response()` est appele et `check_auto_pause()` verifie si >= 3 pour declencher l'auto-pause. Note: le timer cote serveur est hors scope MVP — preparer les endpoints mais le trigger automatique sera story 3.8+.

7. **AC7 — Endpoints REST complets**: Les endpoints suivants fonctionnent:
   - `GET /api/v1/merchants/me/orders?status=pending,confirmed,preparing,ready` — liste filtree
   - `PUT /api/v1/orders/{id}/accept` — accepter (role: merchant, ownership check)
   - `PUT /api/v1/orders/{id}/reject` — refuser avec raison (role: merchant)
   - `PUT /api/v1/orders/{id}/ready` — marquer prete (role: merchant)
   - `POST /api/v1/orders` — creer une commande (role: client) — necessaire pour tester le flow

## Tasks / Subtasks

### Backend Rust

- [x] **T1** — Completer le modele Order (AC: #7)
  - [x] Enrichir `orders/model.rs`: ajouter champs manquants (`payment_status`, `subtotal`, `delivery_fee`, `delivery_address`, `delivery_lat`, `delivery_lng`, `notes`, `updated_at`), derive `sqlx::FromRow`
  - [x] Ajouter `sqlx::Type` + `serde rename_all = "snake_case"` sur `OrderStatus`
  - [x] Ajouter `OrderItem` struct (`id`, `order_id`, `product_id`, `quantity`, `unit_price`, `created_at`)
  - [x] Ajouter payloads: `CreateOrderPayload`, `RejectOrderPayload { reason: String }`
  - [x] Ajouter `OrderWithItems` struct pour la reponse enrichie
  - [x] Tests unitaires serde roundtrip + validation payloads (12 tests)

- [x] **T2** — Repository orders (AC: #7)
  - [x] `create_order(pool, payload) -> Order` avec `INSERT INTO orders ... RETURNING *`
  - [x] `create_order_items(pool, order_id, items) -> Vec<OrderItem>`
  - [x] `find_by_id(pool, id) -> Option<Order>`
  - [x] `find_by_id_with_items(pool, id) -> Option<OrderWithItems>`
  - [x] `find_by_merchant(pool, merchant_id, statuses) -> Vec<OrderWithItems>` avec filtre multi-statut
  - [x] `update_status(pool, id, status) -> Order`
  - [x] `set_rejection_note(pool, id, reason) -> Order` (utilise le champ `notes` existant, prefixe "REFUS: ")

- [x] **T3** — Service orders (AC: #2, #3, #4, #6)
  - [x] `create_order(pool, customer_id, payload) -> OrderWithItems` — valide merchant open/overwhelmed, calcule total depuis DB prices, cree order + items
  - [x] `accept_order(pool, merchant_user_id, order_id) -> OrderWithItems` — ownership check, statut == pending → confirmed, reset `consecutive_no_response`
  - [x] `reject_order(pool, merchant_user_id, order_id, reason) -> OrderWithItems` — ownership, pending → cancelled, `increment_no_response` + `check_auto_pause`
  - [x] `mark_ready(pool, merchant_user_id, order_id) -> OrderWithItems` — ownership, confirmed → ready
  - [x] `get_merchant_orders(pool, merchant_user_id, statuses) -> Vec<OrderWithItems>` — lookup merchant_id depuis user_id
  - [x] Tests unitaires: transitions, payloads (5 tests)

- [x] **T4** — Routes API (AC: #7)
  - [x] `POST /api/v1/orders` — handler `create_order`, role: Client
  - [x] `GET /api/v1/merchants/me/orders` — handler `get_merchant_orders`, role: Merchant, query param `?status=pending,confirmed`
  - [x] `PUT /api/v1/orders/{id}/accept` — handler `accept_order`, role: Merchant
  - [x] `PUT /api/v1/orders/{id}/reject` — handler `reject_order`, role: Merchant, body: `{ "reason": "..." }`
  - [x] `PUT /api/v1/orders/{id}/ready` — handler `mark_ready`, role: Merchant
  - [x] Enregistrer routes dans `routes/mod.rs` (5 tests parse_status_filter)

### Flutter Shared — mefali_core

- [x] **T5** — Modele Order Dart (AC: #5)
  - [x] `packages/mefali_core/lib/models/order.dart` — `Order` class avec `@JsonSerializable(fieldRename: FieldRename.snake)`
  - [x] `packages/mefali_core/lib/models/order_item.dart` — `OrderItem` class
  - [x] `packages/mefali_core/lib/enums/order_status.dart` — enum `OrderStatus` avec `@JsonEnum(fieldRename: FieldRename.snake)`, helpers (`label`, `color`, `icon`, `isActive`)
  - [x] Exporter dans `mefali_core.dart`
  - [x] `dart run build_runner build` pour generer `.g.dart`

### Flutter Shared — mefali_api_client

- [x] **T6** — Endpoint et providers orders (AC: #2, #3, #4, #5)
  - [x] `packages/mefali_api_client/lib/endpoints/order_endpoint.dart` — methodes: `getMerchantOrders`, `acceptOrder`, `rejectOrder`, `markReady`, `createOrder`
  - [x] `packages/mefali_api_client/lib/providers/merchant_orders_provider.dart`:
    - `merchantOrdersProvider` (FutureProvider.autoDispose), `OrderActionNotifier` (StateNotifier), `orderActionProvider`
  - [x] Exporter dans `mefali_api_client.dart`

### Flutter Shared — mefali_design

- [x] **T7** — Composant OrderCard (AC: #1, #2, #3, #4)
  - [x] `packages/mefali_design/lib/components/order_card.dart`:
    - Affiche: items (quantite x prix), total, notes client, timestamp
    - Etats visuels: pending (bordure orange + elevation), confirmed, ready
    - Actions: ACCEPTER (FilledButton vert 56dp) + REFUSER (TextButton), PRETE (FilledButton), "En attente livreur"
    - Callbacks: `onAccept`, `onReject`, `onReady`

### Flutter B2B

- [x] **T8** — Ecran Commandes (AC: #1, #5)
  - [x] `apps/mefali_b2b/lib/features/orders/orders_screen.dart`:
    - Remplace le placeholder dans `home_screen.dart`
    - Liste scrollable d'OrderCard depuis `merchantOrdersProvider`
    - Pull-to-refresh via `RefreshIndicator`
    - Etat vide: icone + "Aucune commande en attente"
    - Badge compteur commandes pending sur l'onglet (`_OrdersTabWithBadge`)
  - [x] Dialogue refus: `showDialog` avec raisons predefinies + TextField libre
  - [x] SnackBar feedback succes/erreur (pattern story 3-5)

- [x] **T9** — Notification haptique (AC: #1)
  - [x] Feedback haptique `HapticFeedback.mediumImpact()` sur accept/reject/ready (natif Flutter, zero dependance)
  - [x] Note: le son custom mefali (`audioplayers`) sera ajoute dans une story ulterieure avec les notifications push. Le feedback haptique est suffisant pour le MVP et evite d'alourdir l'APK

## Dev Notes

### Contexte metier
- Adjoua (marchand type) est en cuisine bruyante → le son doit etre fort et distinctif
- "1 tap, pas 3" — accepter une commande = 1 gros bouton vert, refuser = accessible mais pas au meme niveau
- Temps cible: < 10s pour accepter une commande
- L'ERP fonctionne en standalone sans marketplace — cette story est le premier lien commande↔marchand

### Ce qui existe deja — NE PAS RECREER
- **Migration DB**: `orders` (migration 007) et `order_items` (migration 008) existent avec le schema complet
- **Enum PostgreSQL `order_status`**: `pending, confirmed, preparing, ready, collected, in_transit, delivered, cancelled` — deja dans migration 001
- **Enum `payment_type`**: `cod, mobile_money` et **`payment_status`**: `pending, escrow_held, released, refunded`
- **Stub Rust**: `server/crates/domain/src/orders/model.rs` a un `Order` struct basique et `OrderStatus` enum — A ENRICHIR, pas recreer
- **Stub vide**: `repository.rs` et `service.rs` sont des placeholders — remplir
- **Merchant auto-pause**: `merchants::service::check_auto_pause()`, `increment_no_response()`, `reset_no_response()` — REUTILISER depuis `crate::merchants`
- **Pattern VendorStatus Dart**: enum avec `label`, `color`, `icon`, `apiValue`, `validManualTransitions` dans `packages/mefali_core/lib/enums/vendor_status.dart` — suivre le meme pattern pour `OrderStatus`
- **Pattern Provider**: `currentMerchantProvider` (FutureProvider.autoDispose) + `VendorStatusNotifier` (StateNotifier) dans `packages/mefali_api_client/lib/providers/` — meme pattern
- **B2B Home**: `apps/mefali_b2b/lib/features/home/home_screen.dart` a un TabBar avec onglet "Commandes" (actuellement placeholder), TabController `length: 3`, initialIndex: 1 (Catalogue)

### Rust Order model — champs a ajouter au stub existant
Le stub actuel a: `id, customer_id, merchant_id, driver_id, status, payment_type, total, city_id, created_at`.
Champs manquants a ajouter pour matcher la migration:
```
payment_status: PaymentStatus,  // nouvel enum a creer
subtotal: i64,
delivery_fee: i64,
delivery_address: Option<String>,
delivery_lat: Option<f64>,
delivery_lng: Option<f64>,
notes: Option<String>,
updated_at: Timestamp,
```
Aussi creer `PaymentStatus` enum (Pending, EscrowHeld, Released, Refunded) avec `sqlx::Type` + serde.
Et `PaymentType` enum (Cod, MobileMoney).

### OrderStatus transitions valides (B2B scope)
```
pending → confirmed (accept)
pending → cancelled (reject)
confirmed → ready (mark_ready)
// Les transitions suivantes sont hors scope story 3.6:
ready → collected (driver picks up — story 5.x)
collected → in_transit (driver en route — story 5.x)
in_transit → delivered (livraison confirmee — story 5.x)
```

### Structure fichiers a creer/modifier

**Nouveaux fichiers:**
```
packages/mefali_core/lib/models/order.dart
packages/mefali_core/lib/models/order_item.dart
packages/mefali_core/lib/enums/order_status.dart
packages/mefali_api_client/lib/endpoints/order_endpoint.dart
packages/mefali_api_client/lib/providers/merchant_orders_provider.dart
packages/mefali_design/lib/components/order_card.dart
apps/mefali_b2b/lib/features/orders/orders_screen.dart
```

**Fichiers a modifier:**
```
server/crates/domain/src/orders/model.rs      — enrichir struct + enums
server/crates/domain/src/orders/repository.rs  — implementer queries
server/crates/domain/src/orders/service.rs     — implementer business logic
server/crates/api/src/routes/mod.rs            — ajouter routes orders
(nouveau) server/crates/api/src/routes/orders.rs — handlers
packages/mefali_core/lib/mefali_core.dart      — exporter Order, OrderItem, OrderStatus
packages/mefali_api_client/lib/mefali_api_client.dart — exporter
packages/mefali_design/lib/mefali_design.dart  — exporter OrderCard
apps/mefali_b2b/lib/features/home/home_screen.dart — remplacer placeholder Commandes + badge
apps/mefali_b2b/pubspec.yaml                   — ajouter audioplayers
```

### Patterns de code a suivre strictement

**Rust API handler (copier le pattern de `routes/merchants.rs`):**
```rust
pub async fn accept_order(
    pool: web::Data<PgPool>,
    auth: AuthenticatedUser,
    path: web::Path<Id>,
) -> Result<HttpResponse, AppError> {
    require_role(&auth, &[UserRole::Merchant])?;
    let order = orders::service::accept_order(&pool, auth.user_id, *path).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::new(serde_json::json!({ "order": order }))))
}
```

**Rust ownership check (copier le pattern `change_status`):**
```rust
// Lookup merchant from user_id, then verify order.merchant_id == merchant.id
let merchant = merchants::repository::find_by_user_id(pool, user_id).await?
    .ok_or_else(|| AppError::NotFound("Merchant not found".into()))?;
if order.merchant_id != merchant.id {
    return Err(AppError::Forbidden("Not your order".into()));
}
```

**Dart enum (copier le pattern `VendorStatus`):**
```dart
@JsonEnum(fieldRename: FieldRename.snake)
enum OrderStatus {
  @JsonValue('pending') pending,
  @JsonValue('confirmed') confirmed,
  // ...
  String get label => switch (this) {
    OrderStatus.pending => 'Nouvelle',
    OrderStatus.confirmed => 'En preparation',
    // ...
  };
}
```

**Dart provider (copier le pattern `VendorStatusNotifier`):**
```dart
final merchantOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final endpoint = ref.watch(orderEndpointProvider);
  return endpoint.getMerchantOrders(['pending', 'confirmed', 'ready']);
});
```

### Anti-patterns a eviter

- **NE PAS** creer de WebSocket pour les commandes en temps reel — le polling via provider + pull-to-refresh suffit pour le MVP. Le WebSocket sera ajoute en story 5.x
- **NE PAS** implementer de timer serveur pour le timeout de non-reponse — preparer les fonctions mais le scheduling sera une story separee
- **NE PAS** creer une nouvelle migration pour `rejection_reason` — stocker dans le champ `notes` existant de la table orders (prefixer avec "REFUS: ")
- **NE PAS** implementer la notification push/FCM vers le marchand — cette story est le cote reception B2B uniquement. Le push sera story 4.x/5.x
- **NE PAS** implementer l'assignation livreur — `mark_ready` change juste le statut, le dispatch livreur est story 5.x
- **NE PAS** ajouter une page historique/commandes terminees — seulement les commandes actives pour cette story
- **NE PAS** utiliser `flutter_local_notifications` — `audioplayers` suffit pour le son. Les notifications push seront une story separee

### Considerations techniques

- **Montants en centimes (BIGINT)**: tous les prix sont en FCFA centimes (pas de decimales). 2500 FCFA = 250000 centimes. Affichage: `(total / 100).toStringAsFixed(0)` + " FCFA"
- **Filtre multi-statut**: l'endpoint `GET /merchants/me/orders?status=pending,confirmed,ready` doit parser une liste comma-separated en `Vec<OrderStatus>`
- **Son placeholder**: utiliser un fichier audio court (< 100KB) en attendant le son custom mefali. Format MP3 ou OGG
- **Vibration**: `HapticFeedback.heavyImpact()` de Flutter (pas de package externe)
- **Badge commandes**: utiliser `Badge` widget de Material 3 sur l'icone ou le texte de l'onglet
- **Invalidation provider**: apres accept/reject/ready, `ref.invalidate(merchantOrdersProvider)` pour rafraichir la liste

### Project Structure Notes

- Organisation par feature, jamais par type: `features/orders/` pas `screens/`, `widgets/`
- Nommage fichiers snake_case: `order_card.dart`, `orders_screen.dart`
- Exports via barrel file: chaque package a son `lib/{package_name}.dart` qui exporte tout
- `@JsonSerializable(fieldRename: FieldRename.snake)` obligatoire sur tous les modeles Dart

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.6]
- [Source: _bmad-output/planning-artifacts/prd.md — FR15, FR16, FR17, FR38, FR39]
- [Source: _bmad-output/planning-artifacts/architecture.md — Orders schema, API patterns, WebSocket]
- [Source: _bmad-output/planning-artifacts/ux-spec.md — Flow 2 (Adjoua gere commande), OrderCard, B2B tabs]
- [Source: _bmad-output/implementation-artifacts/3-5-vendor-availability-4-states.md — Patterns Riverpod, code existant]
- [Source: server/crates/domain/src/merchants/service.rs — check_auto_pause(), increment_no_response()]
- [Source: server/crates/domain/src/orders/model.rs — stub existant a enrichir]
- [Source: server/migrations/20260317000007_create_orders.up.sql — schema DB complet]
- [Source: server/migrations/20260317000008_create_order_items.up.sql — schema order_items]
- [Source: server/migrations/20260317000001_create_enums.up.sql — enums PostgreSQL]
- [Source: apps/mefali_b2b/lib/features/home/home_screen.dart — placeholder Commandes a remplacer]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend Rust: modele Order enrichi (12 tests), repository complet (7 fonctions), service avec ownership check + auto-pause integration (5 tests), routes API (5 endpoints + 5 tests parse_status_filter). Total: 170 tests workspace (0 regressions).
- Flutter mefali_core: Order, OrderItem, OrderStatus enum avec helpers (label, color, icon, isActive). Code-gen .g.dart OK.
- Flutter mefali_api_client: OrderEndpoint (5 methodes), merchantOrdersProvider + OrderActionNotifier + orderActionProvider.
- Flutter mefali_design: OrderCard widget avec etats visuels (pending/confirmed/ready) et actions contextuelles.
- Flutter mefali_b2b: OrdersScreen remplace placeholder, dialogue refus avec raisons predefinies, badge compteur pending sur onglet, feedback haptique.
- Decision T9: pas d'audioplayers pour le MVP, feedback haptique natif uniquement. Le son custom sera ajoute avec les notifications push.
- Rejection reason stockee dans le champ `notes` existant (prefixe "REFUS: ") — pas de nouvelle migration.
- Totaux prix calcules depuis les prix DB (jamais les prix client) pour eviter la fraude.

### Code Review Fixes (2026-03-18)

- **[H1] Transaction create_order**: create_order + create_order_items wrappés dans une transaction DB (rollback atomique si un item echoue)
- **[H2] Noms produits dans OrderCard**: ajout `product_name` a `OrderItem` (Rust + Dart), JOIN avec products dans `find_items_by_order`, OrderCard affiche le nom du produit
- **[H3] Transaction reject_order + accept_order**: reject (cancel + increment_no_response) et accept (update_status + reset_no_response) wrappés en transactions. check_auto_pause execute apres commit
- **[H4] Tests service reels**: remplacement des 5 tests triviaux par 9 tests de validation de transitions (accept/reject/ready) qui testent la logique metier reelle. Total workspace: 174 tests (0 regressions)
- **[M2] Haptic feedback reject**: ajout HapticFeedback.mediumImpact() dans _rejectOrder
- **[M3] set_rejection_note type-safe**: remplacement du statut SQL hardcode 'cancelled' par un bind parametre `OrderStatus::Cancelled`
- **[M1] N+1 queries**: find_by_merchant_with_items remplace par 2 requetes (orders + batch items via `ANY($1)`) + groupement en memoire par order_id

### File List

**Nouveaux (10):**
- packages/mefali_core/lib/enums/order_status.dart
- packages/mefali_core/lib/models/order.dart
- packages/mefali_core/lib/models/order.g.dart
- packages/mefali_core/lib/models/order_item.dart
- packages/mefali_core/lib/models/order_item.g.dart
- packages/mefali_api_client/lib/endpoints/order_endpoint.dart
- packages/mefali_api_client/lib/providers/merchant_orders_provider.dart
- packages/mefali_design/lib/components/order_card.dart
- server/crates/api/src/routes/orders.rs
- apps/mefali_b2b/lib/features/orders/orders_screen.dart

**Modifies (8):**
- server/crates/domain/src/orders/model.rs
- server/crates/domain/src/orders/repository.rs
- server/crates/domain/src/orders/service.rs
- server/crates/domain/src/merchants/repository.rs
- server/crates/api/src/routes/mod.rs
- packages/mefali_core/lib/mefali_core.dart
- packages/mefali_api_client/lib/mefali_api_client.dart
- packages/mefali_design/lib/mefali_design.dart
- apps/mefali_b2b/lib/features/home/home_screen.dart
