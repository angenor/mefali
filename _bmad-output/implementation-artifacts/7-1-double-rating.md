# Story 7.1: Double Rating

Status: done

## Story

As a client B2C,
I want to rate merchant and driver separately after delivery,
so that quality improves and other customers can make informed choices.

## Acceptance Criteria

1. **Given** delivery confirmed (OrderStatus::Delivered) **When** B2C app receives delivery.confirmed event **Then** a rating bottom sheet appears automatically with two independent 1-5 star sections (merchant + driver)
2. **Given** rating bottom sheet displayed **When** client selects stars for both merchant and driver **Then** submit button becomes enabled **And** client can optionally add a text comment
3. **Given** client submits rating **When** API receives POST **Then** ratings are persisted atomically (one record per rated entity) **And** merchant/driver avg_rating and total_ratings are updated **And** success SnackBar vert + checkmark appears (3s auto-dismiss)
4. **Given** client dismisses rating sheet without submitting **When** sheet closes **Then** no rating is saved **And** client can rate later from order history
5. **Given** a merchant has ratings **When** RestaurantCard is displayed in B2C discovery **Then** avg_rating and total_ratings are computed from real data (replace hardcoded 0.0/0)
6. **Given** device is offline during rating submission **When** client submits **Then** rating is queued in Drift SyncQueue **And** synced automatically when connectivity resumes
7. **Given** an order already has a rating **When** client tries to rate again **Then** API returns 409 Conflict **And** client sees error message

## Tasks / Subtasks

- [x] Task 1: Database migration pour la table ratings (AC: #1, #3, #7)
  - [x] 1.1 Creer migration `20260322000001_create_ratings.up.sql` avec table `ratings` (id UUID PK, order_id UUID FK UNIQUE combo avec rated_type, rater_id UUID FK, rated_type TEXT CHECK('merchant','driver'), rated_id UUID FK, score SMALLINT CHECK(1-5), comment TEXT nullable, created_at TIMESTAMPTZ)
  - [x] 1.2 Ajouter index `idx_ratings_rated_id_type` sur (rated_id, rated_type) pour les aggregations
  - [x] 1.3 Ajouter index `idx_ratings_order_id` sur order_id
  - [x] 1.4 Ajouter contrainte UNIQUE sur (order_id, rated_type) pour empecher les doublons
  - [x] 1.5 Creer migration down correspondante

- [x] Task 2: Domain model Rust pour ratings (AC: #3, #7)
  - [x] 2.1 Creer `server/crates/domain/src/ratings/mod.rs` (pub mod model, repository, service)
  - [x] 2.2 Creer `model.rs`: struct Rating, struct CreateRatingInput, struct RatingPair (merchant + driver), enum RatedType (Merchant, Driver) avec serde snake_case
  - [x] 2.3 Creer `repository.rs`: create_rating (INSERT), find_by_order_and_type (SELECT), get_avg_rating_for_entity (SELECT AVG + COUNT)
  - [x] 2.4 Creer `service.rs`: submit_double_rating (valide order ownership + delivered status + no duplicate, puis INSERT les 2 ratings)
  - [x] 2.5 Enregistrer `pub mod ratings` dans `domain/src/lib.rs`
  - [x] 2.6 Ecrire tests unitaires: RatedType serde round-trip, CreateRatingInput validation, score bounds check

- [x] Task 3: Mettre a jour MerchantSummary pour utiliser les vrais ratings (AC: #5)
  - [x] 3.1 Dans `merchants/repository.rs`, remplacer `0.0::float8 AS avg_rating, 0::bigint AS total_ratings` par une sous-requete LEFT JOIN sur la table ratings (rated_type='merchant') avec COALESCE pour defaut 0.0/0
  - [x] 3.2 Verifier que RestaurantCard affiche correctement les vrais ratings (pas de changement Flutter necessaire, deja conditionnel)

- [x] Task 4: API endpoints REST pour ratings (AC: #1, #3, #7)
  - [x] 4.1 Creer `server/crates/api/src/routes/ratings.rs` avec handler `submit_rating` (POST /api/v1/orders/{order_id}/rating)
  - [x] 4.2 Request body: `{ "merchant_score": 1-5, "driver_score": 1-5, "merchant_comment": optional, "driver_comment": optional }`
  - [x] 4.3 Reponse succes: `{ "data": { "merchant_rating": {...}, "driver_rating": {...} } }`
  - [x] 4.4 Ajouter handler `get_order_rating` (GET /api/v1/orders/{order_id}/rating) pour verifier si deja note
  - [x] 4.5 Enregistrer les routes dans `routes/mod.rs`
  - [x] 4.6 Auth guard: require role Client, verifier que order.customer_id == auth.user_id

- [x] Task 5: Model Dart Rating dans mefali_core (AC: #1, #3)
  - [x] 5.1 Creer `packages/mefali_core/lib/models/rating.dart` avec @JsonSerializable(fieldRename: FieldRename.snake): class Rating (id, orderId, ratedType, ratedId, score, comment, createdAt)
  - [x] 5.2 Creer class SubmitRatingRequest (merchantScore, driverScore, merchantComment?, driverComment?)
  - [x] 5.3 Creer class RatingResponse (merchantRating, driverRating)
  - [x] 5.4 Exporter dans barrel file models.dart

- [x] Task 6: API client Riverpod pour ratings (AC: #3, #4, #6)
  - [x] 6.1 Creer `packages/mefali_api_client/lib/providers/rating_provider.dart`
  - [x] 6.2 Provider `submitRatingProvider.autoDispose.family(orderId)` → POST /api/v1/orders/{orderId}/rating
  - [x] 6.3 Provider `orderRatingProvider.autoDispose.family(orderId)` → GET /api/v1/orders/{orderId}/rating (pour check si deja note)
  - [x] 6.4 Gerer le cas offline: si DioException type connectionError → queue dans SyncQueue

- [x] Task 7: Composant UI RatingBottomSheet dans mefali_design (AC: #1, #2)
  - [x] 7.1 Creer `packages/mefali_design/lib/components/rating_bottom_sheet.dart`
  - [x] 7.2 Widget StarRatingRow: row de 5 etoiles interactives (GestureDetector), taille >= 48dp touch target, couleur primary (marron)
  - [x] 7.3 Widget RatingBottomSheet: MefaliBottomSheet avec titre "Comment c'etait ?", 2 sections (nom marchand + stars, nom livreur + stars), champ commentaire optionnel, bouton submit (FilledButton pleine largeur, disabled tant que les 2 scores sont 0)
  - [x] 7.4 Respecter les contraintes device: pas d'animation lourde, composants legers pour 2GB RAM

- [x] Task 8: Integration du flow rating dans mefali_b2c (AC: #1, #4)
  - [x] 8.1 Dans le flow post-delivery (delivery_tracking_screen.dart ou equivalent), declencher showModalBottomSheet avec RatingBottomSheet quand status passe a Delivered
  - [x] 8.2 Passer merchant_name, driver_name, order_id au widget
  - [x] 8.3 Sur submit: appeler submitRatingProvider, afficher SnackBar succes vert 3s, fermer sheet
  - [x] 8.4 Sur dismiss: ne rien faire (client peut noter plus tard depuis historique)
  - [x] 8.5 Dans l'ecran historique commandes: ajouter bouton "Noter" si commande delivered et pas encore notee (utiliser orderRatingProvider pour check)

- [ ] Task 9: Offline sync pour ratings (AC: #6)
  - [x] 9.1 Dans mefali_offline, ajouter entity RatingSyncEntity dans la SyncQueue Drift
  - [x] 9.2 SyncService: deserialiser et POST vers /api/v1/orders/{orderId}/rating quand connectivite revient
  - [x] 9.3 Gerer le cas 409 Conflict (deja note) comme succes silencieux lors du sync

## Dev Notes

### Architecture Decisions

- **Ratings table separee** (pas de colonnes dans orders/deliveries): permet l'extensibilite future (photos, categories de rating, moderation)
- **Double INSERT atomique**: les 2 ratings (merchant + driver) sont inseres dans la meme transaction SQL pour eviter un etat partiel
- **Sous-requete pour avg_rating**: utiliser une sous-requete dans `find_active_for_discovery` plutot qu'une colonne materialisee — simple et correct pour le MVP. Si performance devient un probleme, ajouter une vue materialisee plus tard
- **Contrainte UNIQUE (order_id, rated_type)**: garantit l'idempotence au niveau DB (pas juste au niveau applicatif)

### Patterns Backend a Suivre (Etablis dans Stories 6-x)

- **Module organisation**: `server/crates/domain/src/ratings/` avec mod.rs, model.rs, repository.rs, service.rs
- **Enregistrement**: `pub mod ratings` dans `domain/src/lib.rs`
- **Enums serde**: `#[derive(Serialize, Deserialize, sqlx::Type)] #[sqlx(type_name = "text", rename_all = "snake_case")]`
- **Montants en centimes** (i64) — ne s'applique pas directement aux ratings mais le pattern est etabli
- **Reponse API**: toujours `{ "data": { ... } }` pour succes, `{ "error": { "code": "...", "message": "..." } }` pour erreur
- **Auth guard**: `require_role(&auth, &[UserRole::Client])?;` puis verifier ownership de l'order
- **Fire-and-forget notification**: utiliser `actix_web::rt::spawn` pour notifications non-bloquantes apres soumission de rating (ex: notifier le marchand de sa nouvelle note)
- **Error mapping**: `AppError::Conflict("Rating already submitted for this order")` pour doublon, `AppError::Forbidden` si l'order n'appartient pas au client, `AppError::BadRequest` si score hors bornes

### Code Existant a Reutiliser (NE PAS Reinventer)

| Composant existant | Localisation | Usage pour cette story |
|---|---|---|
| MerchantSummary.avg_rating / total_ratings | `server/crates/domain/src/merchants/model.rs:126-140` | Deja dans le struct — juste remplacer le SQL hardcode par la vraie requete |
| RestaurantSummary.avgRating / totalRatings | `packages/mefali_core/lib/models/restaurant_summary.dart` | Deja dans le model Dart — aucun changement necessaire |
| RestaurantCard (affichage etoiles) | `packages/mefali_design/lib/components/restaurant_card.dart` | Affiche deja les etoiles si avgRating > 0 — aucun changement necessaire |
| MefaliBottomSheet | `packages/mefali_design/lib/components/` | Reutiliser comme conteneur pour RatingBottomSheet |
| DeliveryStatus / OrderStatus enums | `server/crates/domain/src/deliveries/model.rs` et `orders/model.rs` | Verifier le statut Delivered avant d'accepter un rating |
| delivery.confirmed WebSocket event | `packages/mefali_api_client/lib/websocket/delivery_tracking_ws.dart` | Ecouter cet event pour declencher le rating sheet cote client |
| SyncQueue Drift pattern | `packages/mefali_offline/` | Suivre le meme pattern pour queuer les ratings offline |
| Feedback SnackBar vert | UX spec: SnackBar vert + check, 3s auto-dismiss | Pattern etabli dans les stories precedentes |

### Patterns Frontend a Suivre

- **Riverpod**: `autoDispose` par defaut, `family` pour providers parametres (orderId)
- **Dart naming**: `@JsonSerializable(fieldRename: FieldRename.snake)` pour mapping auto snake_case ↔ camelCase
- **Navigation**: go_router pour deep links si necessaire
- **Composants**: utiliser Material 3 standard (FilledButton, Card, SnackBar), custom uniquement si necessaire
- **Touch targets**: minimum 48x48 dp (etoiles de notation doivent etre assez grandes)
- **Performance**: pas d'animation lourde, images WebP lazy-loaded, composants legers

### UX Specifications

**Rating Bottom Sheet Layout:**
```
┌──────────────────────────┐
│  Comment c'etait ?       │
│                          │
│  Maman Adjoua            │
│  ★ ★ ★ ★ ★              │
│  [commentaire optionnel] │
│                          │
│  Kone                    │
│  ★ ★ ★ ★ ★              │
│  [commentaire optionnel] │
│                          │
│  [    NOTER    ]         │  ← FilledButton marron, pleine largeur
│                          │  ← disabled si score merchant OU driver == 0
└──────────────────────────┘
```

**Post-submit feedback:** SnackBar vert + checkmark "Merci pour votre avis !" (3s auto-dismiss)

**Etoiles interactives:**
- Etat vide: outline gris (onSurface.withOpacity(0.3))
- Etat rempli: couleur `primary` (marron fonce #5D4037 en light mode)
- Taille: min 40dp icon + 8dp padding = 48dp touch target
- Animation: scale subtile (1.0 → 1.2 → 1.0) sur tap — legere, pas de Lottie

**Declenchement:**
- Automatique apres reception de l'event `delivery.confirmed` via WebSocket
- Retarde de 1-2 secondes apres l'affichage du statut "Commande livree" (laisser le client voir la confirmation)
- Si dismiss: bouton "Noter" visible dans l'historique des commandes

### Database Schema

```sql
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id),
    rater_id UUID NOT NULL REFERENCES users(id),
    rated_type TEXT NOT NULL CHECK (rated_type IN ('merchant', 'driver')),
    rated_id UUID NOT NULL REFERENCES users(id),
    score SMALLINT NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (order_id, rated_type)
);

CREATE INDEX idx_ratings_rated_id_type ON ratings (rated_id, rated_type);
CREATE INDEX idx_ratings_order_id ON ratings (order_id);
```

### API Contract

**POST /api/v1/orders/{order_id}/rating**
- Auth: JWT, role = Client
- Validation: order exists, order.customer_id == auth.user_id, order.status == Delivered, no existing rating

Request:
```json
{
  "merchant_score": 5,
  "driver_score": 4,
  "merchant_comment": "Tres bon garba !",
  "driver_comment": null
}
```

Response 201:
```json
{
  "data": {
    "merchant_rating": {
      "id": "uuid",
      "order_id": "uuid",
      "rated_type": "merchant",
      "rated_id": "uuid",
      "score": 5,
      "comment": "Tres bon garba !",
      "created_at": "2026-03-22T12:00:00Z"
    },
    "driver_rating": {
      "id": "uuid",
      "order_id": "uuid",
      "rated_type": "driver",
      "rated_id": "uuid",
      "score": 4,
      "comment": null,
      "created_at": "2026-03-22T12:00:00Z"
    }
  }
}
```

Response 409 (deja note):
```json
{
  "error": {
    "code": "RATING_ALREADY_EXISTS",
    "message": "Une note a deja ete soumise pour cette commande",
    "details": null
  }
}
```

**GET /api/v1/orders/{order_id}/rating**
- Auth: JWT, role = Client
- Response 200: meme format que POST si existe
- Response 404: pas encore note

### Mise a jour requete MerchantSummary

Remplacer dans `merchants/repository.rs` le SQL hardcode:
```sql
-- AVANT (hardcode MVP)
0.0::float8 AS avg_rating, 0::bigint AS total_ratings

-- APRES (vrais ratings)
COALESCE((SELECT AVG(r.score)::float8 FROM ratings r WHERE r.rated_id = m.user_id AND r.rated_type = 'merchant'), 0.0) AS avg_rating,
COALESCE((SELECT COUNT(*)::bigint FROM ratings r WHERE r.rated_id = m.user_id AND r.rated_type = 'merchant'), 0) AS total_ratings
```

Note: `m.user_id` car ratings.rated_id reference users.id, pas merchants.id. Verifier le mapping.

### Project Structure Notes

- Toute la logique metier dans `server/crates/domain/src/ratings/` — jamais dans `api`
- Les routes dans `server/crates/api/src/routes/ratings.rs`
- Le model Dart dans `packages/mefali_core/lib/models/rating.dart`
- Le provider Riverpod dans `packages/mefali_api_client/lib/providers/rating_provider.dart`
- Le composant UI dans `packages/mefali_design/lib/components/rating_bottom_sheet.dart`
- L'integration B2C dans `apps/mefali_b2c/lib/features/order/` (ecran post-delivery)
- Le sync offline dans `packages/mefali_offline/` (SyncQueue entity)

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 7, Story 7.1]
- [Source: _bmad-output/planning-artifacts/prd.md — FR41 (double notation), FR12 (catalogue avec notes), FR55 (historique admin)]
- [Source: _bmad-output/planning-artifacts/architecture.md — Database schema, API conventions, Auth/Security, Testing standards]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Rating bottom sheet flow, RestaurantCard, feedback patterns, design tokens]
- [Source: server/crates/domain/src/merchants/model.rs:126-140 — MerchantSummary avg_rating placeholder]
- [Source: server/crates/domain/src/merchants/repository.rs:139-167 — SQL hardcode avg_rating]
- [Source: packages/mefali_core/lib/models/restaurant_summary.dart — RestaurantSummary model avec avgRating]
- [Source: packages/mefali_design/lib/components/restaurant_card.dart — Affichage conditionnel etoiles]
- [Source: server/crates/domain/src/deliveries/model.rs — DeliveryStatus::Delivered]
- [Source: server/crates/domain/src/orders/model.rs — OrderStatus::Delivered]
- [Source: _bmad-output/implementation-artifacts/6-3-daily-reconciliation.md — Patterns backend etablis]
- [Source: _bmad-output/implementation-artifacts/6-4-admin-credit-refund.md — find_or_create_wallet pattern, admin endpoint pattern]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- All 9 tasks completed with all subtasks
- Backend: ratings table + domain module (model/repository/service) + API endpoints (POST/GET /orders/{id}/rating)
- MerchantSummary avg_rating now computed from real ratings data (replaced hardcoded 0.0/0)
- Frontend: Rating model in mefali_core + RatingEndpoint + Riverpod providers (submit + check)
- UI: RatingBottomSheet with interactive star ratings (48dp touch targets, Material 3)
- B2C integration: rating sheet shown post-delivery + "Noter" button in order history
- Offline sync: SyncQueue table in Drift DB + offline queueing when connection fails
- All Rust tests pass (228 total, 6 new ratings tests), all Flutter packages analyze clean
- 1 pre-existing clippy warning (deliveries.rs:324 dead_code)

### Change Log

- 2026-03-21: Story 7.1 implementation complete — double rating system (backend + frontend + offline)
- 2026-03-21: Code review — fixed 4 CRITICAL + 4 HIGH + 8 MEDIUM issues (SyncProcessor, double navigation, comment validation, FutureProvider mutation, rater_id, N+1 GET cap, RatedType enum, GET 200 null, touch targets, null safety, SnackBar timing, code dedup, sync dedup)

### File List

server/migrations/20260322000001_create_ratings.up.sql
server/migrations/20260322000001_create_ratings.down.sql
server/crates/domain/src/ratings/mod.rs
server/crates/domain/src/ratings/model.rs (modified — review: comment length validation)
server/crates/domain/src/ratings/repository.rs
server/crates/domain/src/ratings/service.rs (modified — review: map_err simplification)
server/crates/domain/src/lib.rs (modified)
server/crates/domain/src/merchants/model.rs (modified)
server/crates/domain/src/merchants/repository.rs (modified)
server/crates/api/src/routes/ratings.rs
server/crates/api/src/routes/mod.rs (modified)
packages/mefali_core/lib/models/rating.dart (modified — review: added raterId field)
packages/mefali_core/lib/models/rating.g.dart (regenerated)
packages/mefali_core/lib/mefali_core.dart (modified)
packages/mefali_api_client/lib/endpoints/rating_endpoint.dart
packages/mefali_api_client/lib/providers/rating_provider.dart (modified — review: removed submitRatingProvider)
packages/mefali_api_client/lib/mefali_api_client.dart (modified)
packages/mefali_design/lib/components/rating_bottom_sheet.dart
packages/mefali_design/lib/mefali_design.dart (modified)
packages/mefali_offline/lib/database/mefali_database.dart (modified)
packages/mefali_offline/lib/database/mefali_database.g.dart (modified)
packages/mefali_offline/lib/sync/sync_processor.dart (NEW — review: offline sync processor)
packages/mefali_offline/lib/mefali_offline.dart (modified — review: export sync_processor)
apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart (modified — review: fixed double nav, uses shared RatingSheetConsumer)
apps/mefali_b2c/lib/features/order/orders_list_screen.dart (modified — review: uses shared RatingSheetConsumer, cap past orders)
apps/mefali_b2c/lib/features/order/rating_sheet_consumer.dart (NEW — review: shared rating submission widget)
apps/mefali_b2c/lib/features/order/sync_provider.dart (NEW — review: sync processor initialization)
apps/mefali_b2c/lib/app.dart (modified — review: activate sync processor)
