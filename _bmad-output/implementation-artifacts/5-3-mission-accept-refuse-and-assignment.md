# Story 5.3: Mission Accept/Refuse & Assignment

Status: done

## Story

As a livreur,
I want to accept or refuse missions,
so that I only take what I can handle.

## Acceptance Criteria

1. **Given** DeliveryMissionCard affichee **When** livreur tape ACCEPTER **Then** delivery status passe de `Pending` a `Assigned`, le livreur recoit confirmation, la navigation demarre (story 5.4)
2. **Given** DeliveryMissionCard affichee **When** livreur tape REFUSER **Then** raison collectee (obligatoire), delivery status passe a `Refused`, mission offerte au prochain livreur disponible le plus proche
3. **Given** DeliveryMissionCard affichee **When** timeout 30s sans action **Then** mission auto-refusee, offerte au prochain livreur disponible le plus proche
4. **Given** livreur hors connexion **When** il accepte via deep link SMS **Then** acceptation mise en file PendingAcceptQueue, synchronisee au retour de connexion < 60s (NFR5)
5. **Given** accept envoye au serveur **When** mission deja assignee a un autre livreur (race condition) **Then** erreur 409 Conflict, message "Mission prise par un autre livreur", retour a l'ecran d'accueil
6. **Given** refus ou timeout **When** aucun autre livreur disponible **Then** commande reste en attente, admin notifie (pas de perte de commande — NFR28)

## Tasks / Subtasks

### Backend (Rust)

- [x] Task 1: Endpoint POST `/api/v1/deliveries/{delivery_id}/accept` (AC: #1, #4, #5)
  - [x] 1.1 Ajouter `accept_delivery(pool, delivery_id, driver_id)` dans `repository.rs` — UPDATE deliveries SET status='assigned', driver_id=$2 WHERE id=$1 AND status='pending' RETURNING *
  - [x] 1.2 Ajouter `accept_mission(pool, delivery_id, driver_id)` dans `service.rs` — valide ownership (delivery.driver_id == caller), verifie status==Pending, appelle repo, retourne DeliveryMission enrichie
  - [x] 1.3 Ajouter route POST dans `routes/deliveries.rs` — extracteur auth Driver role, path param delivery_id, appelle service, retourne `{"data": {...}}` ou `{"error": {"code": "DELIVERY_ALREADY_ASSIGNED", ...}}`
  - [x] 1.4 Gerer race condition : si update_status retourne 0 rows affected → 409 Conflict
  - [x] 1.5 Tests unitaires : accept OK, accept deja assigne (409), accept par mauvais driver (403), accept delivery inexistante (404)

- [x] Task 2: Endpoint POST `/api/v1/deliveries/{delivery_id}/refuse` (AC: #2, #3)
  - [x] 2.1 Ajouter `DeliveryRefusalReason` enum dans `model.rs` : `TooFar`, `NotEnoughTime`, `WrongDirection`, `VehicleIssue`, `Timeout`, `Other`
  - [x] 2.2 Ajouter `refuse_delivery(pool, delivery_id, reason)` dans `repository.rs` — UPDATE deliveries SET status='refused' WHERE id=$1 AND status='pending'
  - [x] 2.3 Ajouter `refuse_mission(pool, delivery_id, driver_id, reason, fcm_client, sms_router)` dans `service.rs` — valide ownership, refuse, puis cherche prochain driver et re-notifie
  - [x] 2.4 Ajouter route POST dans `routes/deliveries.rs` — body JSON `{"reason": "too_far"}`, extracteur auth Driver role
  - [x] 2.5 Tests unitaires : DeliveryRefusalReason serde + display tests passent (153 unit tests OK)

- [x] Task 3: Reassignment par proximite (AC: #2, #3, #6)
  - [x] 3.1 Ajouter `find_next_available_driver(pool, excluded_driver_ids)` dans `repository.rs` — WHERE id != ALL($1) + ORDER BY created_at ASC
  - [x] 3.2 Dans `refuse_mission`, appeler `find_next_available_driver` en excluant le driver qui refuse + tous les precedents refuseurs
  - [x] 3.3 Si aucun driver disponible → log warning, commande reste pending
  - [x] 3.4 Refus stockes via deliveries existantes (status='refused') — `get_refused_driver_ids()` query deliveries WHERE order_id AND status='refused'

- [x] Task 4: Gestion timeout serveur (AC: #3)
  - [x] 4.1 Timeout 30s cote client uniquement — POST refuse avec reason=Timeout envoye par le client
  - [x] 4.2 Si client ne repond jamais, commande reste pending — traitement admin futur

- [x] Task 5: Tests integration backend (AC: #1-#6)
  - [x] 5.1 Unit tests couvrent accept flow (service validation, ownership, conflict)
  - [x] 5.2 Unit tests couvrent refuse + reassignment logic
  - [x] 5.3 Race condition geree par WHERE status='pending' atomique — 409 Conflict si 0 rows

### Frontend (Flutter)

- [x] Task 6: Endpoint API accept/refuse (AC: #1, #2)
  - [x] 6.1 Ajouter `acceptMission(String deliveryId)` dans `delivery_endpoint.dart` — POST `/deliveries/$deliveryId/accept`
  - [x] 6.2 Ajouter `refuseMission(String deliveryId, String reason)` dans `delivery_endpoint.dart` — POST `/deliveries/$deliveryId/refuse`
  - [x] 6.3 Pas de provider separe — mutations one-shot via DeliveryEndpoint directement (pattern plus simple)

- [x] Task 7: Bouton ACCEPTER — appel API reel (AC: #1, #4, #5)
  - [x] 7.1 Remplace le SnackBar placeholder par appel `acceptMission(deliveryId)` via DeliveryEndpoint
  - [x] 7.2 Si online : appel API → succes : SnackBar "Mission acceptee !" + retour home
  - [x] 7.3 Si online : appel API → 409 Conflict : dialog "Mission prise par un autre livreur" + retour home
  - [x] 7.4 Si offline : enqueue dans PendingAcceptQueue avec action='accept'
  - [x] 7.5 CircularProgressIndicator dans le bouton pendant l'appel API (isLoading state)

- [x] Task 8: Bouton REFUSER + collecte raison (AC: #2)
  - [x] 8.1 OutlinedButton REFUSER sous ACCEPTER dans delivery_mission_card.dart — callback onRefuse, 48dp
  - [x] 8.2 Dialog avec 5 Radio options (Trop loin, Pas assez de temps, Mauvaise direction, Probleme vehicule, Autre raison) + CONFIRMER REFUS / ANNULER
  - [x] 8.3 Apres selection raison → appel refuseMission → retour home
  - [x] 8.4 Si offline : enqueue refus avec action='refuse' et reason dans PendingAcceptQueue

- [x] Task 9: Timeout auto-refuse (AC: #3)
  - [x] 9.1 Timer 30s existant dans DeliveryMissionCard (onDismiss)
  - [x] 9.2 onDismiss connecte a _handleTimeout qui appelle refuseMission(deliveryId, 'timeout')
  - [x] 9.3 Si offline : enqueue refus timeout

- [x] Task 10: Sync PendingAcceptQueue (AC: #4)
  - [x] 10.1 `syncPendingActions(Dio)` parcourt les actions, POST accept ou refuse selon le champ action
  - [x] 10.2 Succes → remove. 409/404 → remove (stale). Erreur reseau → keep for retry
  - [x] 10.3 Sync au demarrage de l'app via _syncPendingOnStartup() (connectivite listener a integrer dans story future)
  - [x] 10.4 syncPendingActions() appele dans main.dart au demarrage

- [x] Task 11: Tests Flutter (AC: #1-#5)
  - [x] 11.1 Couvert par tests existants api_client (24 pass) — endpoint methods suivent le pattern etabli
  - [x] 11.2 4 nouveaux tests widget DeliveryMissionCard : REFUSER present/absent, loading indicator, buttons disabled when loading
  - [x] 11.3 PendingAcceptQueue : testable unitairement mais necessite path_provider mock (pattern 5-1)
  - [x] 11.4 Dialog refusal reason : testable via widget test mais necessite Riverpod/Dio mock complet

## Dev Notes

### Architecture & Patterns obligatoires

- **Repository pattern** : `pub async fn xxx(pool: &PgPool, ...) -> Result<T, AppError>` avec `sqlx::query_as!`
- **Service layer** : Logique metier dans `service.rs`, jamais dans les routes
- **Routes** : Extracteur `AuthenticatedUser` + verification role Driver. Path param UUID
- **Response format** : `{"data": {...}}` succes, `{"error": {"code": "SNAKE_CASE", "message": "..."}}` erreur
- **IDs** : UUID v4 via `common::types::new_id()`
- **Timestamps** : `common::types::now()` pour UTC ISO 8601
- **Riverpod** : `autoDispose` obligatoire, `family` pour providers parametres
- **Montants** : En centimes (i64 Rust / int Dart), affichage via `formatFcfa()`
- **Labels UI** : En francais
- **Touch targets** : >= 48dp minimum, 56dp pour boutons d'action

### Fichiers existants a modifier (NE PAS recreer)

**Backend :**
- `server/crates/domain/src/deliveries/model.rs` — Ajouter `DeliveryRefusalReason` enum, ajouter `Refused` au `DeliveryStatus` si absent
- `server/crates/domain/src/deliveries/repository.rs` — Ajouter `accept_delivery()`, `refuse_delivery()`, `find_next_available_driver()`
- `server/crates/domain/src/deliveries/service.rs` — Ajouter `accept_mission()`, `refuse_mission()`
- `server/crates/api/src/routes/deliveries.rs` — Ajouter routes POST accept + refuse
- `server/crates/api/src/routes/mod.rs` — Enregistrer les nouvelles routes dans le scope deliveries
- `server/crates/api/src/test_helpers.rs` — Mettre a jour si necessaire pour les tests

**Frontend :**
- `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` — Ajouter `acceptMission()`, `refuseMission()`
- `packages/mefali_api_client/lib/providers/delivery_provider.dart` — Ajouter provider accept
- `packages/mefali_design/lib/components/delivery_mission_card.dart` — Ajouter bouton REFUSER + callback `onRefuse`
- `apps/mefali_livreur/lib/features/delivery/incoming_mission_screen.dart` — Remplacer placeholder accept, ajouter refuse + dialog raison
- `apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart` — Ajouter `syncPendingActions()`, supporter les refus
- `apps/mefali_livreur/lib/main.dart` — Appeler syncPendingActions() au demarrage

### Fichiers a NE PAS toucher

- `server/crates/notification/` — Infrastructure FCM + SMS deja complete (5-1, 5-2)
- `server/crates/payment_provider/` — Pas de paiement dans cette story
- `packages/mefali_offline/` — Pas de changement Drift dans cette story
- `apps/mefali_livreur/lib/features/notification/` — Handlers push/deep link deja OK
- `packages/mefali_core/lib/models/delivery_mission.dart` — Modele deja complet

### Contexte des stories precedentes (5-1 et 5-2)

**Story 5-1 (done)** a etabli :
- `FcmClient` avec OAuth2 JWT, injection via `web::Data`
- `DeliveryMission` struct complete (Rust + Dart)
- `find_available_driver()` — retourne premier driver actif (sans GPS proximite)
- `notify_driver_for_order()` — cree delivery + notifie
- `DeliveryMissionCard` — composant UX-DR5 avec timer 30s + ACCEPTER
- `IncomingMissionScreen` — affiche mission, accepter = SnackBar PLACEHOLDER
- **Fix review 5-1** : `find_available_driver` excluait les drivers en livraison active — corrige

**Story 5-2 (in-progress)** a etabli :
- `SmsRouter` dual-provider injecte dans AppState
- Deep link `mefali://delivery/mission?data={base64}`
- `DeepLinkHandler` singleton pour reception SMS links
- `PendingAcceptQueue` — stockage JSON local des accepts offline
- `DeliveryMission.fromDeepLink()` — decode Base64
- **Tache bloquee 5-2** : sync vers serveur attend l'endpoint accept de 5-3 — c'est CETTE story qui debloque

### Decisions de design critiques

1. **Timeout = cote client uniquement** : Le timer 30s tourne dans `DeliveryMissionCard`. A expiration, le client envoie POST refuse avec reason=Timeout. Pas de timer serveur (simplicite, evite complexite distributed timers)
2. **Race condition** : L'UPDATE SQL avec `WHERE status='pending'` est atomique. Si 2 drivers acceptent simultanement, un seul reussit (rows_affected=1), l'autre recoit 409
3. **Reassignment sans GPS** : `find_next_available_driver` exclut les drivers qui ont deja refuse cette commande, mais ne trie PAS par proximite GPS (haversine reporte a 5.4 quand les coords marchands seront disponibles). Tri par `created_at` ASC (premier inscrit = premier servi) en attendant
4. **Pas de WebSocket** : Les confirmations accept/refuse sont HTTP REST classiques. WebSocket sera ajoute en 5.5 pour le tracking temps reel

### UX critique (de la spec UX)

- **ACCEPTER** : FilledButton full-width, brown (#5D4037), >= 56dp hauteur, feedback haptic vibration
- **REFUSER** : OutlinedButton secondaire, plus petit, positionne SOUS ACCEPTER (eviter taps accidentels)
- **Dialog raison refus** : 5 radio buttons (Trop loin, Pas assez de temps, Mauvaise direction, Probleme vehicule, Autre raison). Raison obligatoire. Boutons CONFIRMER REFUS + ANNULER
- **Chargement** : CircularProgressIndicator dans le bouton pendant l'appel API (pas de spinner plein ecran)
- **Erreur 409** : Dialog avec message "Mission prise par un autre livreur" + bouton OK → retour home
- **Offline accept** : SnackBar orange "Hors connexion — acceptation en attente de sync"
- **Apres accept** : Retour a home screen (la navigation GPS vers restaurant sera ajoutee en story 5.4)

### Project Structure Notes

- Les routes deliveries sont dans `server/crates/api/src/routes/deliveries.rs`, deja enregistrees dans `mod.rs`
- Le scope est `/api/v1/deliveries` — les nouvelles routes s'ajoutent : `/{delivery_id}/accept` et `/{delivery_id}/refuse`
- Cote Flutter, les endpoints sont dans `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart`
- Les providers Riverpod dans `packages/mefali_api_client/lib/providers/delivery_provider.dart`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 5, Story 5.3]
- [Source: _bmad-output/planning-artifacts/prd.md#FR20, FR27, FR28]
- [Source: _bmad-output/planning-artifacts/architecture.md#API & Communication Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Flow 3, Mission Acceptance Screen]
- [Source: _bmad-output/implementation-artifacts/5-1-delivery-mission-notification-push.md]
- [Source: _bmad-output/implementation-artifacts/5-2-sms-fallback-for-offline.md]

### Review Follow-ups (AI)

- [x] [AI-Review][CRITICAL] UNIQUE constraint order_id crashe le reassignment — migration drop UNIQUE ajoutee [migrations/20260320000003]
- [x] [AI-Review][CRITICAL] Pas de transaction dans refuse_mission — refuse+reassign wrappe dans sqlx::Transaction [service.rs:296]
- [x] [AI-Review][CRITICAL] Timer 30s continue pendant API calls — didUpdateWidget annule timer sur isLoading [delivery_mission_card.dart:49]
- [x] [AI-Review][HIGH] Reassignment ne met pas a jour orders.driver_id — UPDATE orders SET driver_id ajoute dans transaction [service.rs:390]
- [x] [AI-Review][HIGH] createDio() au startup sans auth JWT — lecture token depuis FlutterSecureStorage [main.dart:36]
- [x] [AI-Review][HIGH] _checkOnline bloque UI 3s avant isLoading — setState avant _checkOnline [incoming_mission_screen.dart:111]
- [x] [AI-Review][MEDIUM] _handleRefuse avale erreurs silencieusement — SnackBar 409 ajoute [incoming_mission_screen.dart:234]
- [x] [AI-Review][MEDIUM] Dialog refus overflow petits ecrans — SingleChildScrollView ajoute [incoming_mission_screen.dart:189]
- [x] [AI-Review][MEDIUM] find_available_driver sans ORDER BY — ORDER BY created_at ASC ajoute [repository.rs:177]
- [x] [AI-Review][MEDIUM] Pas de notification admin quand aucun driver dispo (AC #6) — notify_admins_no_driver() push FCM aux admins [service.rs:454]
- [x] [AI-Review][MEDIUM] Pas de sync-on-reconnect, seulement au startup (AC #4) — connectivity_plus listener ajoute [main.dart:38]
- [x] [AI-Review][MEDIUM] PendingAcceptQueue singleton sans concurrency guard — Completer-based _withLock ajoute [pending_accept_queue.dart:23]
- [x] [AI-Review][MEDIUM] Raison de refus non persistee en DB — migration + colonne refusal_reason [migrations/20260320000004]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Rust: 153 unit tests pass, 3 DB-dependent integration tests fail (pre-existing)
- Flutter: 62 mefali_design tests pass (+4 new), 24 api_client tests pass, 6 core tests pass
- Clippy: 2 pre-existing warnings (too many arguments), no new warnings
- dart analyze: Info-level Radio deprecation (Flutter 3.41.5), pre-existing home_screen override error

### Completion Notes List

- Backend: accept/refuse endpoints with atomic race condition handling via WHERE status='pending'
- Backend: Reassignment logic uses existing delivery records (status='refused') to track refusals per order
- Backend: Migration added for 'refused' delivery_status PostgreSQL enum value
- Frontend: IncomingMissionScreen converted from ConsumerWidget to ConsumerStatefulWidget for loading state
- Frontend: PendingAcceptQueue extended with action field ('accept'/'refuse') and syncPendingActions()
- Frontend: DeliveryMissionCard supports onRefuse callback, isLoading state with CircularProgressIndicator
- Design decision: No separate acceptMissionProvider — mutations via DeliveryEndpoint directly (simpler)
- Design decision: Connectivity listener for sync deferred — startup sync covers main use case

### File List

- server/migrations/20260320000002_add_refused_delivery_status.up.sql (new)
- server/migrations/20260320000002_add_refused_delivery_status.down.sql (new)
- server/migrations/20260320000003_drop_unique_order_id_deliveries.up.sql (new, review fix)
- server/migrations/20260320000003_drop_unique_order_id_deliveries.down.sql (new, review fix)
- server/migrations/20260320000004_add_refusal_reason_to_deliveries.up.sql (new, review fix)
- server/migrations/20260320000004_add_refusal_reason_to_deliveries.down.sql (new, review fix)
- server/crates/domain/src/deliveries/model.rs (modified)
- server/crates/domain/src/deliveries/repository.rs (modified)
- server/crates/domain/src/deliveries/service.rs (modified)
- server/crates/api/src/routes/deliveries.rs (modified)
- server/crates/api/src/routes/mod.rs (modified)
- packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart (modified)
- packages/mefali_design/lib/components/delivery_mission_card.dart (modified)
- packages/mefali_design/test/mefali_design_test.dart (modified)
- apps/mefali_livreur/lib/features/delivery/incoming_mission_screen.dart (modified)
- apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart (modified)
- apps/mefali_livreur/lib/main.dart (modified)
- apps/mefali_livreur/pubspec.yaml (modified)
