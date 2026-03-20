# Story 5.6: Delivery Confirmation & Instant Payment

Status: done

## Story

As a livreur,
I want to confirm delivery and get paid instantly,
so that I'm motivated to deliver quickly and reliably.

## Acceptance Criteria

1. **Given** driver at client location with delivery in `PickedUp` status, **When** driver taps LIVRÉ, **Then** delivery status transitions to `Delivered`, `delivered_at` set, driver wallet credited < 5 min
2. **Given** delivery confirmed, **Then** WalletCreditFeedback "+X FCFA" animation + son + vibration displays on driver app
3. **Given** prepaid order (Mobile Money), **When** delivery confirmed, **Then** escrow released: driver wallet credited (delivery_fee - commission), merchant wallet credited (subtotal — commission marchand non applicable au MVP, montant complet subtotal)
4. **Given** COD order, **When** delivery confirmed, **Then** driver wallet credited with delivery_fee - commission (driver collected cash already)
5. **Given** delivery confirmed, **Then** client reçoit WebSocket event `delivery.confirmed` + push notification, tracking screen ferme, écran de complétion affiché
6. **Given** driver is offline when tapping LIVRÉ, **Then** confirmation queued in PendingAcceptQueue, synced on reconnect
7. **Given** driver location > 200m from delivery address, **When** tap LIVRÉ, **Then** error "Vous êtes trop loin de l'adresse de livraison"
8. **Given** delivery already confirmed (duplicate request), **Then** idempotent response (200 OK, no double payment)

## Tasks / Subtasks

### Backend Rust

- [x] Task 1: Migration — `wallet_credits` logic preparation (AC: #3, #4)
  - [x] 1.1 — Implémenter `wallets::repository` : `credit_wallet(pool, wallet_id, amount) -> Result<Wallet>`, `create_transaction(pool, wallet_id, amount, type, reference) -> Result<WalletTransaction>`
  - [x] 1.2 — Implémenter `wallets::service` : `credit_driver_for_delivery(pool, delivery, order) -> Result<i64>` (retourne driver_earnings), `credit_merchant_for_delivery(pool, order) -> Result<()>`

- [x] Task 2: `confirm_delivery` endpoint + service (AC: #1, #3, #4, #7, #8)
  - [x] 2.1 — `deliveries::repository::confirm_delivery(pool, delivery_id, lat, lng) -> Result<Delivery>` — UPDATE SET status='delivered', delivered_at=now(), WHERE status='picked_up' (atomique)
  - [x] 2.2 — `deliveries::service::confirm_delivery(pool, delivery_id, driver_id, lat, lng) -> Result<ConfirmDeliveryResponse>` — Full implementation with haversine validation, wallet credits, escrow release, order status update, customer notification
  - [x] 2.3 — Route `POST /api/v1/deliveries/{delivery_id}/confirm` dans deliveries.rs
  - [x] 2.4 — Modèle `ConfirmDeliveryResponse` dans deliveries/model.rs

- [x] Task 3: Mise à jour order status + payment_status (AC: #3, #4)
  - [x] 3.1 — `orders::repository::mark_delivered(pool, order_id) -> Result<()>` — UPDATE status='delivered'
  - [x] 3.2 — `orders::repository::release_escrow(pool, order_id) -> Result<()>` — UPDATE payment_status='released' WHERE payment_status='escrow_held'

- [x] Task 4: WebSocket event `delivery.confirmed` (AC: #5)
  - [x] 4.1 — Publier sur Redis channel `delivery:{order_id}` le JSON `{"event":"delivery.confirmed","data":{"delivery_id":"...","status":"delivered"}}`
  - [x] 4.2 — Dans ws.rs, relayer cet event au client WebSocket (déjà en place, format identique à location_update)

- [x] Task 5: Tests backend (AC: tous)
  - [x] 5.1 — Test haversine_distance_same_point, within_200m, beyond_200m
  - [x] 5.2 — Test confirm_delivery_response_serde
  - [x] 5.3 — Tests unitaires haversine distance validation (< 200m OK, > 200m rejected)
  - [x] 5.4 — 164 domain tests pass, 196 total Rust unit tests pass
  - [x] 5.5 — 7 pre-existing merchant integration test failures documented (not from this story)

### Frontend Flutter — App Livreur

- [x] Task 6: Bouton LIVRÉ dans collection_navigation_screen.dart (AC: #1, #7)
  - [x] 6.1 — Bouton LIVRÉ (FilledButton, marron #5D4037, full-width, 56dp) dans phase livraison du bottom sheet
  - [x] 6.2 — On tap: GPS position + `DeliveryEndpoint.confirmDelivery(deliveryId, lat, lng)`
  - [x] 6.3 — Loading state: `isLoading` bool + CircularProgressIndicator dans le bouton
  - [x] 6.4 — Erreur 400 (trop loin): Dialog "Vous etes trop loin de l'adresse de livraison"
  - [x] 6.5 — Erreur 409 (déjà confirmé): Dialog + retour home
  - [x] 6.6 — Succès: WalletCreditFeedback overlay, puis navigate home après 2.5s

- [x] Task 7: WalletCreditFeedback component dans mefali_design (AC: #2)
  - [x] 7.1 — Widget `WalletCreditFeedback` dans `packages/mefali_design/lib/components/wallet_credit_feedback.dart`
  - [x] 7.2 — Animation scale-up 0→1.0 sur 300ms (easeOutQuart), texte "+X FCFA" en headlineMedium, couleur success vert
  - [x] 7.3 — Son: omis (pas d'asset son disponible), vibration seule via HapticFeedback
  - [x] 7.4 — Vibration: `HapticFeedback.mediumImpact()`
  - [x] 7.5 — Auto-dismiss: fade out 500ms démarrant à 2s, remove à 2.5s
  - [x] 7.6 — Affichage en overlay (OverlayEntry) par dessus l'écran courant

- [x] Task 8: Offline support pour confirmation (AC: #6)
  - [x] 8.1 — Action `confirm_delivery` dans PendingAcceptQueue sync logic
  - [x] 8.2 — Stocke `deliveryId`, `lat`, `lng` dans missionData de la queue
  - [x] 8.3 — Sync on reconnect: `endpoint.confirmDelivery(deliveryId, lat, lng)`
  - [x] 8.4 — Stale (404/409) = supprimé de la queue (non-retryable)

- [x] Task 9: `DeliveryEndpoint.confirmDelivery()` dans mefali_api_client (AC: #1)
  - [x] 9.1 — Méthode `confirmDelivery(String deliveryId, double lat, double lng) -> Future<Map<String, dynamic>>`
  - [x] 9.2 — POST `/api/v1/deliveries/$deliveryId/confirm` body: `{"driver_location":{"latitude":lat,"longitude":lng}}`
  - [x] 9.3 — Response parsed as Map (driver_earnings_fcfa, confirmed_at) — pas de modèle dédié, simple Map

### Frontend Flutter — App B2C (Client)

- [x] Task 10: Réception event `delivery.confirmed` (AC: #5)
  - [x] 10.1 — DeliveryTrackingWs émet `DeliveryLocationUpdate(status:'delivered')` sur event `delivery.confirmed`
  - [x] 10.2 — DeliveryTrackingScreen affiche snackbar "Commande livree !" vert + navigate home après 2s
  - [x] 10.3 — Variable `_isDelivered` empêche le traitement multiple de l'event

## Dev Notes

### Patterns Obligatoires (établis dans 5-3/5-4/5-5)

**Backend Rust :**
- **Transition atomique** : `UPDATE deliveries SET status='delivered' WHERE id=$1 AND status='picked_up'` — si 0 rows affected, retourner erreur 400/409
- **Best-effort notifications** : Push/SMS failures NE DOIVENT PAS rollback la transaction principale
- **Timestamps** : `common::types::now()` pour UTC ISO 8601
- **IDs** : `common::types::new_id()` pour UUID v4
- **Error handling** : `thiserror` dans domain, mapped to HTTP status dans api crate via `AppError`
- **Redis publish non-bloquant** : `let _: Result<(), _> = redis.publish(...)` (pattern 5-5)
- **Haversine** : Réutiliser la fonction existante dans deliveries/service.rs pour valider distance <= 200m

**Frontend Flutter :**
- **ConsumerStatefulWidget** pour écrans avec Riverpod + state local
- **Pas de mutation providers** : Appeler `DeliveryEndpoint` directement (pattern 5-3)
- **Loading state** : `bool isLoading` + `CircularProgressIndicator` dans le bouton, pas full-screen
- **Error handling** : 409 → Dialog + retour home, 400 → Dialog explicatif, network → SnackBar orange
- **PendingAcceptQueue** : Ajouter action `confirm_delivery` (pattern extensible depuis 5-3/5-4)

### Commission & Payment Logic

**Calcul de la commission :**
- Le modèle exact de commission n'est PAS encore défini dans les artefacts (1-15% mentionné dans le PRD comme fourchette)
- Pour le MVP : utiliser un pourcentage configurable stocké en constante dans `common/config.rs`
- Suggestion : `DELIVERY_COMMISSION_PERCENT = 14` (basé sur le user journey Koné: 350 FCFA sur 2500 FCFA)
- `driver_earnings = delivery_fee - (delivery_fee * commission_percent / 100)`
- `merchant_credit = subtotal` (pour prepaid, le montant total moins frais de livraison)

**Dual flow COD vs Prepaid :**
- **COD** : Driver a déjà collecté le cash. On crédite son wallet uniquement avec ses gains (delivery_fee - commission). Le marchand sera crédité lors de la réconciliation (Epic 6)
- **Prepaid (Mobile Money)** : Escrow libéré. Driver wallet crédité + merchant wallet crédité. Order.payment_status = 'released'

**NFR11 CRITIQUE** : Aucun crédit wallet sans transaction CinetPay confirmée pour prepaid. Pour le MVP, le crédit wallet se fait immédiatement de manière optimiste (la réconciliation quotidienne EP6 vérifiera). Le PaymentProvider.release_escrow() n'est PAS nécessaire dans cette story — l'escrow est un concept comptable interne, pas une API CinetPay (CinetPay a déjà débité le client, l'argent est sur le compte mefali)

### Wallet Repository/Service — Premier Implementation

Les fichiers `wallets/service.rs` et `wallets/repository.rs` sont actuellement des stubs vides. Cette story est la PREMIERE à les implémenter. Patterns à suivre :

```rust
// repository.rs
pub async fn credit_wallet(pool: &PgPool, wallet_id: Uuid, amount: i64) -> Result<(), AppError> {
    sqlx::query!("UPDATE wallets SET balance = balance + $1, updated_at = $2 WHERE id = $3",
        amount, now(), wallet_id)
    .execute(pool).await?;
    Ok(())
}

pub async fn create_transaction(pool: &PgPool, wallet_id: Uuid, amount: i64,
    tx_type: WalletTransactionType, reference: String) -> Result<WalletTransaction, AppError> {
    // INSERT INTO wallet_transactions ...
}

pub async fn find_wallet_by_user(pool: &PgPool, user_id: Uuid) -> Result<Wallet, AppError> {
    // SELECT * FROM wallets WHERE user_id = $1
}
```

```rust
// service.rs
pub async fn credit_driver_for_delivery(pool: &PgPool, delivery: &Delivery, order: &Order) -> Result<i64, AppError> {
    let commission_percent = 14; // TODO: configurable
    let driver_earnings = order.delivery_fee - (order.delivery_fee * commission_percent / 100);
    let wallet = repository::find_wallet_by_user(pool, delivery.driver_id).await?;
    repository::credit_wallet(pool, wallet.id, driver_earnings).await?;
    repository::create_transaction(pool, wallet.id, driver_earnings,
        WalletTransactionType::Credit, format!("delivery:{}", delivery.id)).await?;
    Ok(driver_earnings)
}
```

### Fichiers à Créer/Modifier

**Nouveau :**
- `packages/mefali_design/lib/components/wallet_credit_feedback.dart`
- `packages/mefali_core/lib/models/confirm_delivery_response.dart`

**Modifier :**
- `server/crates/domain/src/deliveries/service.rs` — ajouter `confirm_delivery()`
- `server/crates/domain/src/deliveries/repository.rs` — ajouter `confirm_delivery()`
- `server/crates/domain/src/deliveries/model.rs` — ajouter `ConfirmDeliveryResponse`
- `server/crates/domain/src/wallets/service.rs` — implémenter (actuellement stub vide)
- `server/crates/domain/src/wallets/repository.rs` — implémenter (actuellement stub vide)
- `server/crates/domain/src/orders/repository.rs` — ajouter `mark_delivered()`, `release_escrow()`
- `server/crates/api/src/routes/deliveries.rs` — ajouter route confirm
- `server/crates/api/src/routes/mod.rs` — register route
- `apps/mefali_livreur/lib/features/delivery/collection_navigation_screen.dart` — bouton LIVRÉ + WalletCreditFeedback
- `apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart` — écouter event confirmed
- `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` — ajouter `confirmDelivery()`
- `apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart` — ajouter action `confirm_delivery`

### Existing Code to Reuse — NE PAS Réinventer

| Fonctionnalité | Fichier existant | Réutiliser |
|---|---|---|
| Haversine distance | `deliveries/service.rs` (calculate_eta_seconds, utilise haversine) | Extraire en fonction utilitaire pour valider distance <= 200m |
| Atomic status update | `deliveries/repository.rs` (accept_delivery, confirm_pickup) | Même pattern WHERE status='picked_up' |
| Redis publish | `routes/deliveries.rs` (update_location handler) | Même pattern publish sur channel `delivery:{order_id}` |
| PendingAcceptQueue | `pending_accept_queue.dart` | Ajouter action type `confirm_delivery` |
| GPS position | `collection_navigation_screen.dart` | Geolocator.getCurrentPosition() déjà utilisé |
| Error handling patterns | `incoming_mission_screen.dart` | Dialog/SnackBar patterns pour 409/400/network |
| AuthenticatedUser extractor | `routes/deliveries.rs` | Même extractor pour vérifier rôle driver |

### UX Critique

- **Bouton LIVRÉ** : FilledButton marron #5D4037, full-width, >= 56dp, zone du pouce (bas d'écran)
- **WalletCreditFeedback** : Scale-up "+X FCFA" (headline4, vert success), son célébratoire, vibration medium, auto-dismiss 2s
- **1 tap, pas 3** : Le driver confirme en 1 seul tap LIVRÉ (principe UX #1)
- **Feedback immédiat** : Animation wallet AVANT la réponse serveur (optimistic UI), puis sync
- **Accessibilité moto** : Bouton >= 56dp (plus grand que standard 48dp), contraste élevé pour soleil

### Project Structure Notes

- Alignement avec la structure hexagonale : domain/ pour logique, api/ pour routes, infrastructure/ pour DB
- Wallet domain `server/crates/domain/src/wallets/` existe déjà (model.rs peuplé, service.rs et repository.rs vides)
- Les tables `wallets` et `wallet_transactions` existent déjà (migrations 20260317000008 et 20260317000009)
- Le champ `delivered_at` existe déjà dans la table `deliveries`
- `PaymentStatus::Released` existe déjà dans orders/model.rs

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 5, Story 5.6]
- [Source: _bmad-output/planning-artifacts/prd.md — FR23, FR31, FR32, FR34, NFR11, NFR21, NFR23]
- [Source: _bmad-output/planning-artifacts/architecture.md — API patterns, WebSocket, Payment Provider]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — WalletCreditFeedback, Flow 3, Button hierarchy]
- [Source: _bmad-output/implementation-artifacts/5-5-real-time-tracking-client-side.md — WebSocket patterns, Redis PubSub]
- [Source: _bmad-output/implementation-artifacts/5-4-order-collection-and-navigation.md — collection_navigation_screen, GPS patterns]
- [Source: _bmad-output/implementation-artifacts/5-3-mission-accept-refuse-and-assignment.md — PendingAcceptQueue, atomic transitions, error handling]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Wallet domain implemented from scratch (repository + service) — first implementation of wallets module
- confirm_delivery service: validates driver ownership, haversine distance <= 200m, atomic status transition, credits wallets, releases escrow for prepaid, updates order status, publishes Redis event, notifies customer
- Idempotency: if delivery already delivered, returns success with 0 earnings (no double payment)
- Dual flow: COD credits driver only (merchant reconciled in Epic 6), MobileMoney credits both + releases escrow
- Commission: 14% hardcoded (configurable via constant, story notes say PRD range is 1-15%)
- WalletCreditFeedback: scale-up animation + fade out overlay, HapticFeedback, auto-dismiss 2.5s
- Offline support: PendingAcceptQueue extended with `confirm_delivery` action storing lat/lng
- B2C WebSocket: `delivery.confirmed` event emits synthetic DeliveryLocationUpdate(status:'delivered'), tracking screen navigates home
- 7 pre-existing merchant integration test failures (documented in 5-4, unrelated to this story)

### Change Log

- 2026-03-20: Story 5.6 implemented — delivery confirmation, wallet credits, WebSocket event, LIVRE button, offline support
- 2026-03-20: Code Review — 6 issues fixed:
  - [C1] credit_merchant_for_delivery() used merchants.id instead of users.id for wallet lookup (wallets/service.rs)
  - [C2] Offline sync confirm_delivery read lat/lng at wrong JSON level (pending_accept_queue.dart)
  - [H1] credit_wallet() SQL missing updated_at = NOW() (wallets/repository.rs)
  - [H2] AC #3 clarified: merchant gets full subtotal (no commission at MVP)
  - [M1] Removed redundant DB query in confirm_delivery route by adding order_id to ConfirmDeliveryResponse (model.rs + routes/deliveries.rs)
  - [M2] Added GPS coordinate bounds validation in confirm_delivery service (service.rs)

### File List

**New:**
- packages/mefali_design/lib/components/wallet_credit_feedback.dart

**Modified (Backend Rust):**
- server/crates/domain/src/wallets/model.rs — Added WalletTransaction struct, sqlx derives
- server/crates/domain/src/wallets/repository.rs — Implemented find_wallet_by_user, credit_wallet, create_transaction
- server/crates/domain/src/wallets/service.rs — Implemented credit_driver_for_delivery, credit_merchant_for_delivery
- server/crates/domain/src/deliveries/model.rs — Added ConfirmDeliveryResponse
- server/crates/domain/src/deliveries/repository.rs — Added confirm_delivery()
- server/crates/domain/src/deliveries/service.rs — Added confirm_delivery(), haversine_distance_m(), notify_customer_delivery_confirmed(), 4 unit tests
- server/crates/domain/src/orders/repository.rs — Added mark_delivered(), release_escrow()
- server/crates/api/src/routes/deliveries.rs — Added confirm_delivery handler + Redis publish
- server/crates/api/src/routes/mod.rs — Registered /{delivery_id}/confirm route

**Modified (Frontend Flutter):**
- apps/mefali_livreur/lib/features/delivery/collection_navigation_screen.dart — Added LIVRE button + _handleLivre() with online/offline support
- apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart — Added confirm_delivery action in sync
- packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart — Added confirmDelivery() method
- packages/mefali_api_client/lib/websocket/delivery_tracking_ws.dart — Handle delivery.confirmed event
- packages/mefali_design/lib/mefali_design.dart — Export wallet_credit_feedback.dart
- apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart — Handle delivered status, navigate home
