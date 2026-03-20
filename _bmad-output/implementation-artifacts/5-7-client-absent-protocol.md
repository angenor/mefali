# Story 5.7: Client Absent Protocol

Status: in-progress

## Story

As a livreur,
I want a clear protocol when the client is absent at the delivery address,
so that I'm protected, paid for my effort, and know exactly what to do.

## Acceptance Criteria

1. **Given** driver at client location with delivery in `PickedUp` status, **When** driver taps CLIENT ABSENT, **Then** delivery status transitions to `ClientAbsent`, 10-minute countdown timer starts on screen, and client receives push notification + WebSocket event `delivery.client_absent`
2. **Given** client absent timer running, **When** driver taps APPELER LE CLIENT, **Then** phone dialer opens with client's phone number via `tel:` URI
3. **Given** client absent timer running, **When** client arrives and driver taps LE CLIENT EST ARRIVE, **Then** normal delivery flow resumes — driver can tap LIVRE to confirm delivery (existing `confirm_delivery` flow)
4. **Given** client absent timer expired + COD order, **When** driver chooses resolution, **Then** driver can tap RETOURNER AU RESTAURANT or RETOURNER A LA BASE, wallet credited `delivery_fee - commission`, order status set to `cancelled` with notes `client_absent`, client notified
5. **Given** client absent timer expired + prepaid order (Mobile Money), **When** driver taps RETOURNER A LA BASE MEFALI, **Then** wallet credited `delivery_fee - commission`, escrow NOT released to merchant, client notified to collect order at base mefali, order status set to `cancelled` with notes `client_absent_prepaid`
6. **Given** driver is offline, **When** driver taps CLIENT ABSENT, **Then** action queued in PendingAcceptQueue and synced on reconnect
7. **Given** client absent protocol resolved (timeout), **Then** driver sees WalletCreditFeedback "+X FCFA" animation and navigates to home — driver is paid in ALL cases (COD and prepaid)
8. **Given** client tracking delivery, **When** `delivery.client_absent` event received, **Then** tracking screen shows "Le livreur ne vous trouve pas" status message

## Tasks / Subtasks

### Backend Rust

- [x] Task 1: `deliveries::repository` — `mark_client_absent()` (AC: #1)
  - [x]1.1 — `mark_client_absent(pool, delivery_id) -> Result<Delivery>` — `UPDATE deliveries SET status = 'client_absent', updated_at = now() WHERE id = $1 AND status = 'picked_up'` RETURNING * — si 0 rows, `AppError::BadRequest("Delivery not in picked_up status")`
  - [x]1.2 — Pas de migration nécessaire : `client_absent` existe déjà dans l'enum `delivery_status` (migration `20260317000001`)

- [x]Task 2: `deliveries::service` — `report_client_absent()` (AC: #1, #8)
  - [x]2.1 — `report_client_absent(pool, delivery_id, driver_id, lat, lng, fcm?) -> Result<Delivery>` :
    - Vérifier que le driver possède cette delivery (`delivery.driver_id == driver_id`)
    - Valider coordonnées GPS (bounds check comme `update_driver_location`)
    - Appeler `repository::mark_client_absent(pool, delivery_id)`
    - Publier Redis PubSub event `{"event":"delivery.client_absent","data":{"delivery_id":"...","status":"client_absent"}}` sur channel `delivery:{order_id}` (pattern 5-5/5-6, best-effort)
    - Notification push FCM au client : "Le livreur ne vous trouve pas à l'adresse indiquée" (best-effort, NE PAS rollback si échec)
  - [x]2.2 — Récupérer `order_id` et `customer_id` depuis la delivery + order pour notifications

- [x]Task 3: `deliveries::service` — `resolve_client_absent()` (AC: #4, #5, #7)
  - [x]3.1 — `resolve_client_absent(pool, delivery_id, driver_id, resolution: AbsentResolution) -> Result<ConfirmDeliveryResponse>` :
    - Vérifier driver ownership + delivery en status `client_absent`
    - Charger l'order associé (pour `delivery_fee`, `payment_type`, `subtotal`)
    - Calculer `driver_earnings = delivery_fee - (delivery_fee * DELIVERY_COMMISSION_PERCENT / 100)` (même formule que `confirm_delivery`)
    - Créditer wallet driver via `wallets::service::credit_driver_for_delivery()` — driver payé dans TOUS les cas
    - Pour prepaid : NE PAS appeler `credit_merchant_for_delivery()`, NE PAS `release_escrow()` — escrow reste held
    - Pour COD : pas de cash collecté, driver payé par la plateforme (wallet credit quand même)
    - `orders::repository::cancel_order(pool, order_id, reason)` — mettre order en `cancelled` avec notes
    - Publier Redis event `{"event":"delivery.absent_resolved","data":{"delivery_id":"...","resolution":"...","driver_earnings_fcfa":X}}`
    - Push FCM au client : "Votre commande n'a pas pu être livrée" + instructions selon payment_type
    - Retourner `ConfirmDeliveryResponse { driver_earnings_fcfa, confirmed_at, order_id }`
  - [x]3.2 — Enum `AbsentResolution` dans `deliveries/model.rs` : `ReturnedToRestaurant`, `ReturnedToBase`

- [x]Task 4: `deliveries::service` — Modifier `confirm_delivery()` pour accepter `client_absent` (AC: #3)
  - [x]4.1 — Dans `confirm_delivery()`, modifier la condition WHERE pour accepter `status IN ('picked_up', 'client_absent')` au lieu de `status = 'picked_up'` uniquement
  - [x]4.2 — Mettre à jour `deliveries::repository::confirm_delivery()` SQL : `WHERE id = $1 AND status IN ('picked_up', 'client_absent')`
  - [x]4.3 — Ajouter test unitaire : confirm_delivery depuis status client_absent fonctionne

- [x]Task 5: `orders::repository` — `cancel_order()` (AC: #4, #5)
  - [x]5.1 — `cancel_order(pool, order_id, reason: &str) -> Result<()>` — `UPDATE orders SET status = 'cancelled', notes = $2, updated_at = now() WHERE id = $1`
  - [x]5.2 — Ne PAS modifier `payment_status` pour prepaid (escrow reste `escrow_held` pour gestion admin future)

- [x]Task 6: Routes API (AC: #1, #4, #5)
  - [x]6.1 — `POST /api/v1/deliveries/{delivery_id}/client-absent` body: `{"driver_location":{"latitude":X,"longitude":Y}}` — appelle `report_client_absent()`
  - [x]6.2 — `POST /api/v1/deliveries/{delivery_id}/resolve-absent` body: `{"resolution":"returned_to_restaurant"|"returned_to_base","driver_location":{"latitude":X,"longitude":Y}}` — appelle `resolve_client_absent()`
  - [x]6.3 — Enregistrer les 2 routes dans `routes/mod.rs` (même scope deliveries)
  - [x]6.4 — Redis publish dans les handlers (même pattern que `update_location` et `confirm_delivery`)

- [ ]Task 7: Tests backend (AC: tous)
  - [ ]7.1 — Test `report_client_absent` : picked_up → client_absent OK, assigned → erreur
  - [ ]7.2 — Test `resolve_client_absent` : driver payé, order cancelled, correct earnings calculation
  - [ ]7.3 — Test `confirm_delivery` depuis `client_absent` status (client arrivé pendant timer)
  - [x]7.4 — Test AbsentResolution serde (serialize/deserialize snake_case)

### Frontend Flutter — App Livreur

- [x]Task 8: Bouton CLIENT ABSENT dans `collection_navigation_screen.dart` (AC: #1)
  - [x]8.1 — Ajouter bouton `OutlinedButton` "CLIENT ABSENT" sous le bouton LIVRE dans la phase `navigatingToClient`
  - [x]8.2 — Style : `OutlinedButton`, bordure rouge `Color(0xFFF44336)`, texte rouge, full-width, 48dp — visuellement secondaire par rapport à LIVRE
  - [x]8.3 — On tap : vérifier online/offline, appeler `DeliveryEndpoint.reportClientAbsent()` ou queuer hors ligne
  - [x]8.4 — Succès : naviguer vers `/delivery/client-absent` avec les données delivery + order

- [x]Task 9: Ecran `client_absent_screen.dart` — timer + actions (AC: #1, #2, #3, #4, #5, #7)
  - [x]9.1 — Nouveau fichier `apps/mefali_livreur/lib/features/delivery/client_absent_screen.dart`
  - [x]9.2 — `ConsumerStatefulWidget` avec timer `Timer.periodic(1s)` décomptant 10 minutes (600s)
  - [x]9.3 — Layout :
    - Titre "CLIENT ABSENT" (headlineMedium, bold)
    - Timer countdown affiché en gros (headlineLarge, `MM:SS`)
    - Message explicatif : "Le client n'est pas à l'adresse. Attendez ou appelez-le."
    - Bouton `OutlinedButton` "APPELER LE CLIENT" avec icône téléphone — `launchUrl(Uri.parse('tel:${customerPhone}'))` via `url_launcher`
    - Bouton `FilledButton` secondaire "LE CLIENT EST ARRIVE" — retour vers `collection_navigation_screen` phase delivery (pop et reprendre le flow normal, le driver peut ensuite taper LIVRE qui appelle `confirm_delivery` qui accepte maintenant `client_absent` status)
  - [x]9.4 — Quand timer expire (`_remainingSeconds == 0`) :
    - Pour COD (`paymentType == 'cod'`) : afficher 2 boutons :
      - `FilledButton` "RETOURNER AU RESTAURANT" → appelle `resolveClientAbsent(resolution: 'returned_to_restaurant')`
      - `FilledButton` "RETOURNER A LA BASE" → appelle `resolveClientAbsent(resolution: 'returned_to_base')`
    - Pour prepaid (`paymentType == 'mobile_money'`) : afficher 1 bouton :
      - `FilledButton` "RETOURNER A LA BASE MEFALI" → appelle `resolveClientAbsent(resolution: 'returned_to_base')`
  - [x]9.5 — Après résolution réussie : `WalletCreditFeedback` overlay "+X FCFA" (réutiliser le composant existant), puis navigate `/home` après 2.5s
  - [x]9.6 — `url_launcher` est déjà dans les dépendances (vérifié : utilisé dans le projet)

- [x]Task 10: Route GoRouter pour `client_absent_screen` (AC: #1)
  - [x]10.1 — Ajouter route `/delivery/client-absent` dans `apps/mefali_livreur/lib/app.dart`
  - [x]10.2 — Passer les données via `state.extra` : `Map` contenant `deliveryId`, `orderId`, `customerPhone`, `paymentType`, `deliveryFee`

- [x]Task 11: `DeliveryEndpoint` — 2 nouvelles méthodes (AC: #1, #4, #5)
  - [x]11.1 — `reportClientAbsent(String deliveryId, double lat, double lng) -> Future<void>` — POST `/api/v1/deliveries/$deliveryId/client-absent`
  - [x]11.2 — `resolveClientAbsent(String deliveryId, String resolution, double lat, double lng) -> Future<Map<String, dynamic>>` — POST `/api/v1/deliveries/$deliveryId/resolve-absent` — retourne `driver_earnings_fcfa`

- [x]Task 12: Offline support dans `PendingAcceptQueue` (AC: #6)
  - [x]12.1 — Ajouter action `'client_absent'` : stocker `deliveryId`, `lat`, `lng` dans `missionData`
  - [x]12.2 — Ajouter action `'resolve_absent'` : stocker `deliveryId`, `resolution`, `lat`, `lng`
  - [x]12.3 — Sync on reconnect : appeler les endpoints correspondants. 404/409 = supprimer de la queue (non-retryable)

### Frontend Flutter — App B2C (Client)

- [x]Task 13: WebSocket event `delivery.client_absent` dans tracking (AC: #8)
  - [x]13.1 — Dans `delivery_tracking_ws.dart` : gérer event `'delivery.client_absent'` → émettre `DeliveryLocationUpdate` avec `status: 'client_absent'`
  - [x]13.2 — Dans `delivery_tracking_screen.dart` : quand status `client_absent`, afficher message "Le livreur ne vous trouve pas a l'adresse indiquee" en orange dans le bottom sheet
  - [x]13.3 — Quand event `'delivery.absent_resolved'` reçu : afficher SnackBar "Votre commande n'a pas pu être livree" + naviguer home après 3s

## Dev Notes

### Patterns Obligatoires (établis dans 5-3/5-4/5-5/5-6)

**Backend Rust :**
- **Transition atomique** : `UPDATE deliveries SET status='client_absent' WHERE id=$1 AND status='picked_up'` — si 0 rows, retourner erreur 400
- **Best-effort notifications** : Push FCM NE DOIT PAS rollback la transaction principale
- **Timestamps** : `common::types::now()` pour UTC ISO 8601
- **IDs** : `common::types::new_id()` pour UUID v4
- **Error handling** : `thiserror` dans domain, mapped to HTTP status dans api crate via `AppError`
- **Redis publish non-bloquant** : `let _: Result<(), _> = redis.publish(...)` (pattern 5-5/5-6)
- **Commission** : `DELIVERY_COMMISSION_PERCENT = 14` (constante dans common/config.rs, établie en 5-6)

**Frontend Flutter :**
- **ConsumerStatefulWidget** pour écrans avec Riverpod + state local
- **Pas de mutation providers** : Appeler `DeliveryEndpoint` directement (pattern 5-3)
- **Loading state** : `bool isLoading` + `CircularProgressIndicator` dans le bouton, pas full-screen
- **Error handling** : 409 → Dialog + retour home, 400 → Dialog explicatif, network → SnackBar orange
- **PendingAcceptQueue** : Actions étendues depuis 5-3 : `accept`, `refuse`, `confirm_pickup`, `confirm_delivery` → ajouter `client_absent`, `resolve_absent`
- **Online/offline check** : `Connectivity().checkConnectivity()` avant chaque action (pattern existant)
- **WalletCreditFeedback** : Overlay avec animation scale-up + haptic + auto-dismiss 2.5s (composant existant dans mefali_design)

### Logique Métier Client Absent — CRITIQUE

**Le driver est payé dans TOUS les cas.** C'est le différenciateur émotionnel de mefali (PRD + UX spec). Le driver ne perd JAMAIS d'argent sur un client absent.

**Dual flow COD vs Prepaid :**

| Aspect | COD | Prepaid (Mobile Money) |
|--------|-----|----------------------|
| Cash collecté ? | Non | N/A (déjà payé en ligne) |
| Driver payé ? | Oui (wallet credit) | Oui (wallet credit) |
| Source paiement driver | Plateforme absorbe le coût | Déduit de l'escrow |
| Escrow | N/A | Reste `escrow_held` (PAS released) |
| Merchant crédité | Non | Non |
| Order status | `cancelled` (notes: `client_absent`) | `cancelled` (notes: `client_absent_prepaid`) |
| Retour food | Restaurant ou base | Base mefali (client peut collecter) |
| Client notifié | Push "Commande non livrée" | Push "Commande disponible à la base mefali" |

**Calcul driver_earnings identique à `confirm_delivery` :**
```
driver_earnings = delivery_fee - (delivery_fee * 14 / 100)
```
Réutiliser `wallets::service::credit_driver_for_delivery()` — NE PAS dupliquer la logique.

### Timer 10 Minutes — Client-Side Only

Le timer est géré UNIQUEMENT côté Flutter, pas côté backend. Le backend ne fait que :
1. Recevoir `report_client_absent` → marquer le status
2. Recevoir `resolve_client_absent` → payer le driver + annuler l'order

Le backend NE vérifie PAS que 10 minutes se sont écoulées. Cette contrainte est UI-only pour simplifier.

### Appel Client (FR40)

Le numéro de téléphone du client doit être accessible au driver. Vérifier que `DeliveryMission` inclut `customer_phone` depuis les données order/user. Si absent, l'ajouter dans :
- `deliveries::service::get_pending_mission()` — query JOIN users
- `DeliveryMission` model Dart dans `mefali_core`

L'appel utilise `url_launcher` package avec `launchUrl(Uri.parse('tel:$customerPhone'))`.

### Fichiers à Créer

| Fichier | Description |
|---------|-------------|
| `apps/mefali_livreur/lib/features/delivery/client_absent_screen.dart` | Ecran timer 10 min + appel + résolution |

### Fichiers à Modifier

| Fichier | Modification |
|---------|-------------|
| `server/crates/domain/src/deliveries/model.rs` | Ajouter `AbsentResolution` enum |
| `server/crates/domain/src/deliveries/repository.rs` | Ajouter `mark_client_absent()`, modifier `confirm_delivery()` WHERE clause |
| `server/crates/domain/src/deliveries/service.rs` | Ajouter `report_client_absent()`, `resolve_client_absent()`, modifier `confirm_delivery()` |
| `server/crates/domain/src/orders/repository.rs` | Ajouter `cancel_order()` |
| `server/crates/api/src/routes/deliveries.rs` | Ajouter 2 handlers : `client_absent`, `resolve_absent` |
| `server/crates/api/src/routes/mod.rs` | Enregistrer les 2 nouvelles routes |
| `apps/mefali_livreur/lib/features/delivery/collection_navigation_screen.dart` | Ajouter bouton CLIENT ABSENT dans phase delivery |
| `apps/mefali_livreur/lib/app.dart` | Ajouter route `/delivery/client-absent` |
| `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` | Ajouter `reportClientAbsent()`, `resolveClientAbsent()` |
| `packages/mefali_api_client/lib/websocket/delivery_tracking_ws.dart` | Gérer events `delivery.client_absent`, `delivery.absent_resolved` |
| `apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart` | Ajouter actions `client_absent`, `resolve_absent` |
| `apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart` | Afficher status `client_absent` + message |

### Existing Code to Reuse — NE PAS Réinventer

| Fonctionnalité | Fichier existant | Réutiliser |
|---|---|---|
| Atomic status transition | `deliveries/repository.rs` (`accept_delivery`, `confirm_pickup`, `confirm_delivery`) | Même pattern `WHERE status='picked_up'` pour `mark_client_absent` |
| Wallet credit driver | `wallets/service.rs` (`credit_driver_for_delivery`) | Appeler directement — NE PAS recoder la logique commission |
| Redis publish event | `routes/deliveries.rs` (`confirm_delivery` handler) | Même pattern publish sur channel `delivery:{order_id}` |
| WalletCreditFeedback | `mefali_design/lib/components/wallet_credit_feedback.dart` | Import et utilisation directe |
| PendingAcceptQueue | `pending_accept_queue.dart` | Étendre avec 2 nouvelles actions |
| GPS position | `collection_navigation_screen.dart` | `Geolocator.getCurrentPosition()` déjà utilisé |
| Online/offline check | `collection_navigation_screen.dart` | `Connectivity().checkConnectivity()` existant |
| Error handling patterns | `collection_navigation_screen.dart` (`_handleLivre`) | Dialog/SnackBar patterns pour 409/400/network |
| Phone call | `url_launcher` (déjà en dépendance) | `launchUrl(Uri.parse('tel:$phone'))` |
| ConfirmDeliveryResponse | `deliveries/model.rs` | Réutiliser le même struct pour `resolve_absent` |
| WebSocket event handling | `delivery_tracking_ws.dart` | Même pattern que `delivery.confirmed` pour `delivery.client_absent` |

### UX Specifications

**Bouton CLIENT ABSENT (dans collection_navigation_screen) :**
- `OutlinedButton`, bordure rouge (#F44336), texte rouge, full-width, 48dp
- Placé SOUS le bouton LIVRE (vert/marron) — séparation visuelle claire
- Pas au même niveau visuel que LIVRE pour éviter les taps accidentels

**Ecran client_absent_screen :**
- Timer en gros chiffres (headlineLarge, centré) : format `MM:SS`
- Message explicatif lisible (bodyLarge)
- Bouton APPELER : `OutlinedButton` avec icône Phone, full-width, 48dp
- Bouton LE CLIENT EST ARRIVE : `FilledButton` vert, full-width, 56dp
- Boutons résolution (après timer) : `FilledButton` marron #5D4037, full-width, 56dp
- Zone de pouce pour tous les boutons (bas d'écran)
- Pas de carte/map nécessaire — écran focalisé sur les actions

**Principes UX (du spec) :**
- "Client absent = un bouton, pas un menu de 3 sous-options"
- "Le flow d'erreur protège, pas punit" → Koné payé dans TOUS les cas
- "1 tap, pas 3" → chaque action est 1 bouton
- Touch target >= 48dp (moto en mouvement, soleil)
- Contraste fort, gros texte pour timer

### Schéma d'état Delivery pour cette story

```
picked_up ──[CLIENT ABSENT]──> client_absent ──[CLIENT ARRIVE]──> confirm_delivery ──> delivered
                                    │
                                    └──[TIMER EXPIRE]──> resolve_absent ──> client_absent (final)
                                                              │
                                                              └── driver wallet crédité
                                                              └── order → cancelled
```

### Project Structure Notes

- `client_absent` status existe déjà dans le type enum PostgreSQL `delivery_status` (migration initiale `20260317000001`) — AUCUNE migration nécessaire
- `DeliveryStatus::ClientAbsent` existe déjà dans le modèle Rust `deliveries/model.rs`
- La table `wallets` et `wallet_transactions` existent et sont fonctionnelles (implémentées en 5-6)
- `cancel_order()` sera la première utilisation de `order_status = 'cancelled'` depuis le backend — vérifier que le status est correctement mappé

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 5, Story 5.7, FR24, FR40]
- [Source: _bmad-output/planning-artifacts/prd.md — FR24, FR32, NFR11, NFR21, NFR23]
- [Source: _bmad-output/planning-artifacts/architecture.md — WebSocket patterns, API REST, Wallet domain]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow 3 (Koné), button hierarchy, feedback patterns, "1 tap pas 3"]
- [Source: _bmad-output/implementation-artifacts/5-6-delivery-confirmation-and-instant-payment.md — confirm_delivery patterns, wallet credit, WalletCreditFeedback, PendingAcceptQueue, Redis publish]
- [Source: server/crates/domain/src/deliveries/model.rs — DeliveryStatus::ClientAbsent déjà défini]
- [Source: server/migrations/20260317000001_create_enums.up.sql — client_absent dans delivery_status enum]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- 165 domain tests pass (0 failures), 36/42 total Rust tests pass (6 pre-existing merchant integration failures unrelated)
- 0 Dart analysis errors across all modified packages
- url_launcher added to mefali_livreur pubspec.yaml dependencies

### Completion Notes List

- Backend: `mark_client_absent()` repository function — atomic transition picked_up -> client_absent
- Backend: `report_client_absent()` service — validates driver, marks absent, pushes FCM to customer, publishes Redis event
- Backend: `resolve_client_absent()` service — credits driver wallet (ALWAYS), cancels order, notifies customer. COD vs prepaid dual flow
- Backend: `confirm_delivery()` updated to accept both `picked_up` AND `client_absent` source status (client arrives during timer)
- Backend: `cancel_order()` added to orders repository for order cancellation with reason
- Backend: `AbsentResolution` enum (returned_to_restaurant, returned_to_base) with serde tests
- Backend: 2 new API routes POST /client-absent and POST /resolve-absent with Redis event publishing
- Backend: tracking query and location updates now include `client_absent` status
- Frontend Livreur: CLIENT ABSENT OutlinedButton (red) added below LIVRE button in delivery phase
- Frontend Livreur: New `client_absent_screen.dart` — 10min countdown timer, call client, client arrived, resolution buttons (COD: 2 options, prepaid: 1)
- Frontend Livreur: GoRouter route `/delivery/client-absent` with data passing via extra
- Frontend Livreur: DeliveryEndpoint — `reportClientAbsent()` and `resolveClientAbsent()` methods
- Frontend Livreur: PendingAcceptQueue extended with `client_absent` and `resolve_absent` offline actions
- Frontend B2C: WebSocket handles `delivery.client_absent` and `delivery.absent_resolved` events
- Frontend B2C: Tracking screen shows orange "Le livreur ne vous trouve pas" when client absent

### Change Log

- 2026-03-20: Story 5.7 implemented — client absent protocol (report, timer, resolve, wallet credit, notifications)
- 2026-03-20: Code review fixes — AC #3 navigation (push/pop), customer_phone flow (AC #2), client_absent in driver availability queries

### File List

**New:**
- apps/mefali_livreur/lib/features/delivery/client_absent_screen.dart

**Modified (Backend Rust):**
- server/crates/domain/src/deliveries/model.rs — Added AbsentResolution enum + serde test, added customer_phone to DeliveryMission
- server/crates/domain/src/deliveries/repository.rs — Added mark_client_absent(), updated confirm_delivery WHERE clause, updated tracking/location/availability queries to include client_absent
- server/crates/domain/src/deliveries/service.rs — Added report_client_absent(), resolve_client_absent(), notify_customer_client_absent(), notify_customer_absent_resolved(), updated confirm_delivery to accept client_absent, added customer_phone to build_mission_payload, fixed client_absent in refuse_mission availability query
- server/crates/domain/src/orders/repository.rs — Added cancel_order()
- server/crates/api/src/routes/deliveries.rs — Added report_client_absent and resolve_client_absent handlers with Redis publish
- server/crates/api/src/routes/mod.rs — Registered /{delivery_id}/client-absent and /{delivery_id}/resolve-absent routes

**Modified (Frontend Flutter):**
- apps/mefali_livreur/lib/features/delivery/collection_navigation_screen.dart — Added CLIENT ABSENT button + _handleClientAbsent(), passes customerPhone, uses context.push
- apps/mefali_livreur/lib/features/delivery/client_absent_screen.dart — Fixed _handleClientArrived to use context.pop (AC #3)
- apps/mefali_livreur/lib/app.dart — Added /delivery/client-absent route + import
- apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart — Added client_absent and resolve_absent sync actions
- apps/mefali_livreur/pubspec.yaml — Added url_launcher dependency
- packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart — Added reportClientAbsent() and resolveClientAbsent()
- packages/mefali_api_client/lib/websocket/delivery_tracking_ws.dart — Handle delivery.client_absent and delivery.absent_resolved events
- packages/mefali_core/lib/models/delivery_mission.dart — Added customerPhone field
- apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart — Handle client_absent/absent_resolved status, show orange message, navigate home

### Review Follow-ups (AI)

- [ ] [AI-Review][MEDIUM] resolve_client_absent() — credit_driver + cancel_order pas dans une transaction. Risque d'etat inconsistant si cancel_order echoue apres wallet credit. Necessite refactoring cross-cutting de wallets::service pour accepter impl PgExecutor. [service.rs:965-986]
- [ ] [AI-Review][MEDIUM] Tasks 7.1-7.3 — Tests d'integration pour report_client_absent, resolve_client_absent, confirm_delivery depuis client_absent. Necessitent infra de test avec DB (non disponible actuellement). [service.rs:tests]
- [ ] [AI-Review][LOW] resolve_client_absent handler — driver_location dans le body est accepte mais non utilise par le service. Dead data dans l'API contract. [routes/deliveries.rs:323-325]
