# Story 5.1: Notification de mission livraison (Push)

Status: done

## Story

As a livreur,
I want to receive mission notifications with restaurant, destination, distance, and earnings details,
So that I can decide whether to accept a delivery.

## Criteres d'acceptation

1. **AC1 — Enregistrement du token FCM**
   Given le livreur est connecte dans mefali_livreur
   When l'app demarre ou le token FCM change
   Then le token FCM est envoye au backend via `PUT /api/v1/users/me/fcm-token`
   And le token est stocke dans la colonne `users.fcm_token`

2. **AC2 — Declenchement notification quand commande prete**
   Given un marchand marque une commande comme "ready" (status = ready)
   When le backend traite le changement de statut
   Then le systeme recherche les livreurs disponibles (role=driver, status=active, fcm_token non null)
   And envoie une notification push FCM au livreur le plus proche (ou au premier disponible si pas de geolocalisation)

3. **AC3 — Contenu de la notification push**
   Given le livreur recoit la notification push
   When la notification arrive (foreground ou background)
   Then le payload contient: order_id, merchant_name, merchant_address, delivery_address, delivery_lat, delivery_lng, estimated_distance_m, delivery_fee (gain livreur), items_summary
   And le titre est "Nouvelle course mefali"
   And le body est "{merchant_name} -> {delivery_address}"

4. **AC4 — Affichage DeliveryMissionCard**
   Given la notification push est recue en foreground
   When le livreur voit l'ecran
   Then le DeliveryMissionCard s'affiche avec: nom restaurant, adresse destination, distance estimee, gain livreur en FCFA, bouton ACCEPTER pleine largeur (marron, >= 48dp)
   And la card se dismiss automatiquement apres 30 secondes

5. **AC5 — Notification en background/terminated**
   Given l'app est en background ou fermee
   When la notification push arrive
   Then une notification systeme s'affiche avec titre et corps
   And un tap sur la notification ouvre l'app et affiche le DeliveryMissionCard

6. **AC6 — Son de notification custom**
   Given une notification de mission arrive
   When le livreur la recoit
   Then un son distinctif mefali est joue (son systeme en MVP, custom post-MVP)

## Taches / Sous-taches

### Backend Rust

- [x] T1 — Implementer le client FCM (AC: 2,3)
  - [x] T1.1 Ajouter `reqwest` (si pas deja present) dans `notification/Cargo.toml` pour appels HTTP FCM v1
  - [x] T1.2 Implementer `send_push()` dans `server/crates/notification/src/fcm.rs` via Firebase HTTP v1 API (`POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send`)
  - [x] T1.3 Charger les credentials Firebase Service Account depuis `.env` (FIREBASE_PROJECT_ID, FIREBASE_SERVICE_ACCOUNT_KEY path ou inline JSON)
  - [x] T1.4 Gerer l'authentification OAuth2 pour FCM v1 (service account → access token, cache avec expiration)
  - [x] T1.5 Ajouter les variables FCM dans `server/.env.example`

- [x] T2 — Endpoint enregistrement token FCM (AC: 1)
  - [x] T2.1 Creer handler `register_fcm_token` dans `server/crates/api/src/routes/users.rs` : `PUT /api/v1/users/me/fcm-token` avec body `{"token": "..."}`
  - [x] T2.2 Ajouter `update_fcm_token(pool, user_id, token)` dans `server/crates/domain/src/users/repository.rs`
  - [x] T2.3 Enregistrer la route dans `server/crates/api/src/routes/mod.rs`

- [x] T3 — Service de notification de mission livreur (AC: 2,3)
  - [x] T3.1 Creer `notify_driver_for_order(pool, order_id)` dans `server/crates/domain/src/deliveries/service.rs`
  - [x] T3.2 La fonction : charge l'order + merchant + items, recherche les livreurs (role=driver, status=active, fcm_token IS NOT NULL), selectionne le premier disponible (tri par id en MVP — proximite GPS viendra story 5.3)
  - [x] T3.3 Construire le payload FCM : order_id, merchant_name, merchant_address, delivery_address, delivery_lat, delivery_lng, estimated_distance_m (calcul haversine si lat/lng disponibles), delivery_fee, items_summary
  - [x] T3.4 Appeler `send_push()` avec le token FCM du livreur selectionne
  - [x] T3.5 Creer un record `deliveries` avec status=pending et driver_id du livreur notifie

- [x] T4 — Declencher la notification quand commande prete (AC: 2)
  - [x] T4.1 Modifier `mark_ready()` dans `server/crates/domain/src/orders/service.rs` pour appeler `notify_driver_for_order()` apres le passage en status Ready

- [x] T5 — Implementer le repository deliveries (AC: 2)
  - [x] T5.1 Implementer `create_delivery(pool, order_id, driver_id)` dans `server/crates/domain/src/deliveries/repository.rs`
  - [x] T5.2 Implementer `find_delivery_by_order(pool, order_id)` pour verification
  - [x] T5.3 Ajouter `client_absent` au DeliveryStatus enum Rust (aligner avec DB)
  - [x] T5.4 Ajouter `picked_up_at`, `delivered_at`, `created_at` au struct Delivery Rust (aligner avec DB)

- [x] T6 — Endpoint GET mission details pour le livreur (AC: 4,5)
  - [x] T6.1 Creer `GET /api/v1/deliveries/pending` dans routes : retourne la delivery pending du livreur connecte avec details order+merchant
  - [x] T6.2 Response: `{data: {delivery_id, order_id, merchant_name, merchant_address, delivery_address, delivery_lat, delivery_lng, estimated_distance_m, delivery_fee, items_summary, created_at}}`

### Frontend Flutter — mefali_livreur

- [x] T7 — Setup Firebase dans mefali_livreur (AC: 1,5)
  - [x] T7.1 Ajouter `firebase_core` et `firebase_messaging` dans `apps/mefali_livreur/pubspec.yaml`
  - [ ] T7.2 Ajouter `google-services.json` dans `apps/mefali_livreur/android/app/` (depuis Firebase Console) — **REQUIERT ACTION MANUELLE: generer depuis Firebase Console**
  - [ ] T7.3 Ajouter `GoogleService-Info.plist` dans `apps/mefali_livreur/ios/Runner/` (depuis Firebase Console) — **REQUIERT ACTION MANUELLE: generer depuis Firebase Console**
  - [ ] T7.4 Configurer `firebase_options.dart` (FlutterFire CLI ou manuel) — **SKIP: init graceful sans options**
  - [x] T7.5 Initialiser Firebase dans `main()` de `apps/mefali_livreur/lib/main.dart`
  - [ ] T7.6 Ajouter classpath google-services dans `android/build.gradle` et plugin dans `android/app/build.gradle` — **REQUIERT ACTION MANUELLE apres google-services.json**

- [x] T8 — Service d'enregistrement token FCM (AC: 1)
  - [x] T8.1 Creer `FcmTokenEndpoint` ou ajouter `registerFcmToken(token)` dans `packages/mefali_api_client/lib/endpoints/user_endpoint.dart` — implemente via Dio directement dans fcm_token_provider.dart
  - [x] T8.2 Creer provider `fcmTokenProvider` dans `apps/mefali_livreur/lib/features/notification/` qui : demande permission, recupere le token FCM, l'envoie au backend, ecoute les changements de token
  - [x] T8.3 Appeler `fcmTokenProvider` apres login reussi et au demarrage de l'app (dans HomeScreen ou app.dart)

- [x] T9 — Gestionnaire de notifications push (AC: 4,5,6)
  - [x] T9.1 Creer `apps/mefali_livreur/lib/features/notification/push_notification_handler.dart`
  - [x] T9.2 Configurer `FirebaseMessaging.onMessage` (foreground) : extraire payload, afficher DeliveryMissionCard via overlay ou dialog
  - [x] T9.3 Configurer `FirebaseMessaging.onMessageOpenedApp` (background tap) : naviguer vers ecran mission
  - [x] T9.4 Configurer `FirebaseMessaging.onBackgroundMessage` (terminated) : handler top-level
  - [x] T9.5 Demander permission notification (iOS) au premier lancement

- [x] T10 — Composant DeliveryMissionCard (AC: 4) — UX-DR5
  - [x] T10.1 Creer `packages/mefali_design/lib/components/delivery_mission_card.dart`
  - [x] T10.2 Layout : nom restaurant (gras), fleche →, adresse destination, distance en km, gain livreur en FCFA (gros texte vert), bouton ACCEPTER pleine largeur (FilledButton marron, >= 48dp, idealement 56dp pour usage en mouvement)
  - [x] T10.3 Timer auto-dismiss 30s avec indicateur visuel (barre de progression ou countdown)
  - [x] T10.4 Callback `onAccept(deliveryId)` et `onDismiss()`
  - [x] T10.5 Exporter dans `packages/mefali_design/lib/mefali_design.dart`

- [x] T11 — Ecran/Overlay de mission entrante (AC: 4,5)
  - [x] T11.1 Creer `apps/mefali_livreur/lib/features/delivery/incoming_mission_screen.dart`
  - [x] T11.2 Afficher DeliveryMissionCard en plein ecran (ou overlay modal)
  - [x] T11.3 Ajouter route GoRouter `/delivery/incoming-mission` avec parametres (delivery_id ou payload complet)
  - [x] T11.4 ACCEPTER button : pour cette story, un tap affiche un SnackBar "Mission acceptee" (la logique complete viendra story 5.3)
  - [x] T11.5 Auto-dismiss apres 30s → retour home

- [x] T12 — Provider pour charger les details de mission (AC: 4)
  - [x] T12.1 Creer `DeliveryEndpoint` dans `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` avec `getPendingDelivery()`
  - [x] T12.2 Creer `deliveryEndpointProvider` dans `packages/mefali_api_client/lib/providers/`
  - [x] T12.3 Creer `pendingMissionProvider` (FutureProvider.autoDispose) dans mefali_api_client (shared, not in livreur)

### Tests

- [x] T13 — Tests backend (AC: tous)
  - [x] T13.1 Test unitaire DeliveryStatus serde/display (model.rs tests)
  - [x] T13.2 Test unitaire DeliveryMission serde (model.rs tests)
  - [x] T13.3 Test unitaire FcmClient creation + PushNotification (fcm.rs tests)
  - [x] T13.4 Tests existants ne regressent pas (142 unit tests Rust passent, clippy clean)

- [x] T14 — Tests Flutter (AC: tous)
  - [x] T14.1 Widget test DeliveryMissionCard : rendu, bouton ACCEPTER 56dp, callback onAccept, timer countdown, auto-dismiss onDismiss, gain FCFA, distance km (7 tests)
  - [ ] T14.2 Widget test IncomingMissionScreen — skip: necessite mock Firebase qui n'est pas configure
  - [x] T14.3 Tests existants ne regressent pas: 58 design (+7 new), 52 B2C, 24 api_client, 1 core = 135 total

## Dev Notes

### Infrastructure existante — NE PAS recreer

**DB deliveries table — deja creee :**
- Migration `20260317000010_create_deliveries.up.sql` : table `deliveries` avec id, order_id (UNIQUE), driver_id (NOT NULL), status (delivery_status), current_lat, current_lng, picked_up_at, delivered_at, created_at, updated_at
- Indexes : `idx_deliveries_driver_id`, `idx_deliveries_status`
- Enum `delivery_status` : 'pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'client_absent'

**Users.fcm_token — deja en DB :**
- Colonne `fcm_token TEXT` dans table `users` (migration `20260317000003_create_users.up.sql`)
- Champ `fcm_token: Option<String>` dans le struct Rust `User`
- Toutes les queries user selectionnent deja fcm_token

**Delivery model Rust — squelette existant :**
- `server/crates/domain/src/deliveries/model.rs` : struct `Delivery` (id, order_id, driver_id, status, lat, lng, updated_at)
- `DeliveryStatus` enum : Pending, Assigned, PickedUp, InTransit, Delivered, Failed
- **A ALIGNER** : manque `ClientAbsent` dans l'enum Rust (present dans DB), manque `picked_up_at`, `delivered_at`, `created_at` dans le struct

**Notification crate — partiellement pret :**
- `server/crates/notification/src/fcm.rs` : struct `PushNotification` defini (device_token, title, body, data), `send_push()` = stub qui retourne erreur
- `server/crates/notification/src/sms/mod.rs` : SmsRouter dual-provider PRET (production-ready)
- `server/crates/notification/src/deep_link.rs` : Base64 encode/decode PRET
- Le SMS fallback sera cable dans story 5.2, pas ici

**Order service — point d'integration :**
- `mark_ready()` dans `server/crates/domain/src/orders/service.rs` : transition Confirmed → Ready
- C'est le point de declenchement pour notifier un livreur
- `OrderStatus` enum a deja : Pending, Confirmed, Preparing, Ready, Collected, InTransit, Delivered, Cancelled
- Order model a `driver_id: Option<Id>` — a remplir lors de l'assignation

**mefali_livreur — etat actuel :**
- Features : auth (phone/otp/registration), home (placeholder dashboard), profile (view/edit/change-phone)
- GoRouter avec auth guard (unauthenticated → /auth/phone, authenticated → /home)
- Dependencies : flutter_riverpod 3.3.0, go_router 17.0.0, mefali_design, mefali_core, mefali_api_client, mefali_offline
- PAS de Firebase, PAS de notification, PAS de delivery features

### Patterns a suivre (etablis stories precedentes)

**Frontend Flutter :**
- Riverpod `autoDispose` obligatoire sur tous les providers
- `FutureProvider.autoDispose.family` pour donnees parametrees
- Skeleton loading : `ColorTween` animation (JAMAIS shimmer package)
- Erreurs : `AsyncValue.when(loading: skeleton, error: retry, data: content)`
- Navigation : GoRouter declaratif, routes dans `apps/mefali_livreur/lib/app.dart`
- Composants partages : `packages/mefali_design/lib/components/`
- Naming : camelCase pour providers (+Provider suffix), PascalCase pour widgets
- Montants en centimes partout (int, pas double) — `formatFcfa()` dans mefali_core pour affichage
- Labels en francais pour l'UI
- Touch targets >= 48dp (56dp pour actions en mouvement comme le bouton ACCEPTER)
- 1 seul bouton primaire par ecran (FilledButton marron pleine largeur)

**Backend Rust :**
- Repository pattern : `pub async fn xxx(pool: &PgPool, ...) -> Result<T, AppError>`
- SQLx : `sqlx::query_as!` avec verification compile-time
- Routes : `web::resource("/path").route(web::method().to(handler))` dans `routes/mod.rs`
- Response wrapper : `{"data": {...}}` pour succes, `{"error": {"code": "...", "message": "..."}}` pour erreurs
- IDs : UUID v4 partout (`common::types::new_id()`)
- Timestamps : `common::types::now()` pour UTC
- Erreurs : `AppError` enum dans common crate, mappe en HTTP status dans api crate
- snake_case pour tout JSON/DB/API

### Contraintes techniques critiques

- **Firebase Project requis** : creer un projet Firebase et generer `google-services.json` + `GoogleService-Info.plist` AVANT de coder le Flutter. Sans ces fichiers, l'app ne compile pas avec firebase_core.
- **Firebase Service Account Key** : necessaire cote backend pour envoyer des push via FCM v1 API. Fichier JSON a stocker de maniere securisee (jamais committe, charge via .env).
- **FCM v1 API** (pas legacy) : Firebase deprecie l'ancienne API. Utiliser `POST https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send` avec OAuth2 Bearer token.
- **Pas de driver proximity pour cette story** : la selection du livreur est basique (premier driver actif avec fcm_token). L'algorithme de proximite GPS viendra dans story 5.3 quand les livreurs auront un statut de disponibilite et une position connue.
- **Pas de SMS fallback** : le SMS fallback (story 5.2) viendra apres. Cette story gere uniquement le push FCM.
- **Pas de WebSocket** : le tracking temps reel viendra story 5.5. Ne pas introduire de WebSocket.
- **Auto-dismiss 30s** : le DeliveryMissionCard disparait apres 30s. Le timeout et le re-routing vers le prochain livreur seront geres dans story 5.3.
- **Le bouton ACCEPTER** est affiche mais la logique d'acceptation complete (mise a jour DB, transition statut, navigation GPS) sera dans story 5.3. Pour cette story, ACCEPTER affiche un feedback visuel simple.
- **Tests existants** : 52 tests B2C, 51 tests design, 19 tests Rust. Ne pas casser.

### UX — Composant DeliveryMissionCard (UX-DR5)

```
+----------------------------------+
|  Maman Adjoua                    |
|  Quartier Commerce               |
|         |                        |
|         v                        |
|  Quartier Belleville             |
|  ~800m                           |
|                                  |
|      +350 FCFA                   |  <- gros texte vert (success color)
|                                  |
|  Garba + Alloco (x1)            |  <- resume items
|                                  |
|  [========----] 24s              |  <- timer countdown
|                                  |
|  [     ACCEPTER     ]           |  <- FilledButton brown, full-width, 56dp
+----------------------------------+
```

- Fond : surface color (blanc casse / gris fonce en dark mode)
- Nom restaurant : `titleLarge`, bold
- Adresses : `bodyMedium`
- Distance : `bodySmall`
- Gain livreur : `headlineMedium`, `success` color (#4CAF50 light / #81C784 dark)
- Bouton ACCEPTER : `FilledButton`, `primary` color, pleine largeur, 56dp hauteur (livreur en mouvement)
- Timer : `LinearProgressIndicator` en marron, countdown 30s textuel
- Auto-dismiss : Timer(Duration(seconds: 30)) → callback onDismiss

### Dependances externes a ajouter

| Package | Crate/Pubspec | Usage |
|---------|---------------|-------|
| firebase_core | mefali_livreur pubspec.yaml | Initialisation Firebase |
| firebase_messaging | mefali_livreur pubspec.yaml | Reception push notifications |
| reqwest (si absent) | notification/Cargo.toml | Appels HTTP FCM v1 API |
| jsonwebtoken ou oauth2 | notification/Cargo.toml | Auth OAuth2 pour FCM v1 |

### Scope explicite — ce qui N'EST PAS dans cette story

- **Accept/Refuse logic backend** → Story 5.3
- **Re-routing vers livreur suivant si timeout/refus** → Story 5.3
- **SMS fallback si push echoue** → Story 5.2
- **Navigation GPS vers restaurant** → Story 5.4
- **Tracking temps reel WebSocket** → Story 5.5
- **Confirmation livraison + paiement wallet** → Story 5.6
- **Protocole client absent** → Story 5.7
- **Toggle disponibilite livreur (actif/pause)** → Story 5.8
- **Driver proximity algorithm** → Story 5.3

### Project Structure Notes

**Nouveaux fichiers :**
- `packages/mefali_design/lib/components/delivery_mission_card.dart` (composant partage)
- `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` (API client)
- `apps/mefali_livreur/lib/features/notification/push_notification_handler.dart`
- `apps/mefali_livreur/lib/features/notification/fcm_token_provider.dart`
- `apps/mefali_livreur/lib/features/delivery/incoming_mission_screen.dart`
- `apps/mefali_livreur/android/app/google-services.json` (Firebase — NE PAS committer en prod)
- `apps/mefali_livreur/ios/Runner/GoogleService-Info.plist` (Firebase — NE PAS committer en prod)

**Fichiers modifies :**
- `server/crates/notification/src/fcm.rs` (implementer send_push)
- `server/crates/notification/Cargo.toml` (ajouter reqwest, auth deps)
- `server/crates/domain/src/deliveries/model.rs` (aligner avec DB: ajouter ClientAbsent, timestamps)
- `server/crates/domain/src/deliveries/service.rs` (notify_driver_for_order)
- `server/crates/domain/src/deliveries/repository.rs` (create_delivery, find queries)
- `server/crates/domain/src/orders/service.rs` (modifier mark_ready pour trigger notification)
- `server/crates/api/src/routes/users.rs` (endpoint FCM token)
- `server/crates/api/src/routes/mod.rs` (enregistrer nouvelles routes)
- `server/.env.example` (ajouter FIREBASE_PROJECT_ID, FIREBASE_SERVICE_ACCOUNT_KEY)
- `apps/mefali_livreur/pubspec.yaml` (firebase_core, firebase_messaging)
- `apps/mefali_livreur/lib/main.dart` (Firebase.initializeApp)
- `apps/mefali_livreur/lib/app.dart` (nouvelle route /delivery/incoming-mission)
- `apps/mefali_livreur/lib/features/home/home_screen.dart` (init FCM token provider)
- `packages/mefali_design/lib/mefali_design.dart` (export delivery_mission_card)
- `packages/mefali_api_client/lib/providers/` (delivery_endpoint_provider)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 5, Story 5.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#Notification FCM + SMS dual-provider]
- [Source: _bmad-output/planning-artifacts/architecture.md#WebSocket architecture — Redis PubSub]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#UX-DR5 DeliveryMissionCard]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#UX-DR15 Son notification custom]
- [Source: _bmad-output/planning-artifacts/prd.md#FR18 Mission via push, FR38 Push notifications, NFR30 Push delivery rate]
- [Source: _bmad-output/implementation-artifacts/4-6-address-selection.md#Dev Notes, Patterns, File List]
- [Source: server/crates/notification/src/fcm.rs#PushNotification struct, send_push stub]
- [Source: server/crates/domain/src/deliveries/model.rs#Delivery struct, DeliveryStatus enum]
- [Source: server/crates/domain/src/orders/service.rs#mark_ready function]
- [Source: server/migrations/20260317000010_create_deliveries.up.sql#deliveries table schema]
- [Source: server/migrations/20260317000003_create_users.up.sql#fcm_token column]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- FcmClient implemente dans notification/src/fcm.rs : FCM HTTP v1 API avec OAuth2 JWT, token caching (tokio::sync::Mutex), FcmClient::from_env() pour init optionnelle
- Delivery model aligne avec DB : struct Delivery avec current_lat/lng, picked_up_at, delivered_at, created_at + sqlx::FromRow + DeliveryStatus enum avec ClientAbsent
- DeliveryMission struct pour enrichir les donnees mission (merchant_name, items_summary, etc.)
- Delivery repository : create_delivery, find_by_order, find_pending_for_driver, update_status, find_available_driver
- Delivery service : notify_driver_for_order (cherche driver, cree delivery, notifie via FCM), get_pending_mission, build_mission_payload
- Orders set_driver ajouté au repository pour assigner un livreur
- mark_ready() modifie pour accepter Option<&FcmClient> et declencher notify_driver_for_order
- Endpoint PUT /api/v1/users/me/fcm-token + DELETE pour enregistrement/suppression token FCM
- Endpoint GET /api/v1/deliveries/pending pour le livreur
- Routes enregistrees dans mod.rs, FcmClient injecte en web::Data dans main.rs
- test_helpers.rs mis a jour avec FcmClient None
- DeliveryMissionCard composant cree dans mefali_design : timer 30s, LinearProgressIndicator, ACCEPTER 56dp, gain vert, distance km
- DeliveryMission model cree dans mefali_core avec fromJson/toJson
- DeliveryEndpoint + pendingMissionProvider crees dans mefali_api_client
- Firebase deps ajoutees au pubspec livreur, main.dart init Firebase (graceful try/catch)
- PushNotificationHandler singleton : foreground/background/terminated handlers, permission request, token refresh listener
- FcmTokenProvider : enregistre token au backend, ecoute refresh
- IncomingMissionScreen : affiche DeliveryMissionCard depuis push data ou API, SnackBar "Mission acceptee" sur ACCEPTER
- Route GoRouter /delivery/incoming-mission ajoutee
- HomeScreen converti en ConsumerStatefulWidget : init FCM token + ecoute missions push
- 7 widget tests DeliveryMissionCard : rendu, ACCEPTER 56dp, callback, timer, dismiss, gain FCFA, distance
- NOTE: T7.2/T7.3/T7.4/T7.6 necessitent Firebase Console (google-services.json, GoogleService-Info.plist) — action manuelle requise

### Change Log

- 2026-03-20: Story 5-1 implementee — Notification de mission livraison (Push) avec FCM client backend, delivery service, DeliveryMissionCard, push notification handler Flutter
- 2026-03-20: Code review (AI) — 4 issues corrigees: H1 find_available_driver exclut drivers en mission active, M1 payload FCM omet les champs null au lieu de les envoyer comme "null", M2 DeliveryMissionCard utilise la couleur success du theme (dark mode), M3 subscription token refresh annulee on dispose

### File List

- server/crates/notification/Cargo.toml (modified — added reqwest, jsonwebtoken, chrono, tokio)
- server/crates/notification/src/fcm.rs (rewritten — FcmClient with OAuth2 + send_push)
- server/crates/domain/src/deliveries/model.rs (rewritten — aligned with DB, added ClientAbsent, DeliveryMission)
- server/crates/domain/src/deliveries/repository.rs (rewritten — create_delivery, find queries, find_available_driver)
- server/crates/domain/src/deliveries/service.rs (rewritten — notify_driver_for_order, get_pending_mission)
- server/crates/domain/src/orders/service.rs (modified — mark_ready accepts FcmClient, triggers notification)
- server/crates/domain/src/orders/repository.rs (modified — added set_driver)
- server/crates/domain/src/users/repository.rs (modified — added update_fcm_token)
- server/crates/api/src/routes/mod.rs (modified — added deliveries module + routes, FCM token routes)
- server/crates/api/src/routes/users.rs (modified — added register_fcm_token, clear_fcm_token endpoints)
- server/crates/api/src/routes/deliveries.rs (new — get_pending_mission handler)
- server/crates/api/src/routes/orders.rs (modified — mark_ready extracts FcmClient)
- server/crates/api/src/main.rs (modified — FcmClient init + injection)
- server/crates/api/src/test_helpers.rs (modified — added FcmClient None to test app)
- server/.env.example (modified — added FIREBASE_PROJECT_ID, FIREBASE_SERVICE_ACCOUNT_JSON)
- packages/mefali_core/lib/models/delivery_mission.dart (new — DeliveryMission model)
- packages/mefali_core/lib/mefali_core.dart (modified — export delivery_mission)
- packages/mefali_design/lib/components/delivery_mission_card.dart (new — UX-DR5 component)
- packages/mefali_design/lib/mefali_design.dart (modified — export delivery_mission_card)
- packages/mefali_design/test/mefali_design_test.dart (modified — 7 new DeliveryMissionCard tests)
- packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart (new — getPendingMission)
- packages/mefali_api_client/lib/providers/delivery_provider.dart (new — pendingMissionProvider)
- packages/mefali_api_client/lib/mefali_api_client.dart (modified — export delivery endpoint + provider)
- apps/mefali_livreur/pubspec.yaml (modified — added firebase_core, firebase_messaging)
- apps/mefali_livreur/lib/main.dart (modified — Firebase init + PushNotificationHandler)
- apps/mefali_livreur/lib/app.dart (modified — added incoming-mission route + import)
- apps/mefali_livreur/lib/features/home/home_screen.dart (rewritten — ConsumerStatefulWidget, FCM token + mission listener)
- apps/mefali_livreur/lib/features/notification/push_notification_handler.dart (new)
- apps/mefali_livreur/lib/features/notification/fcm_token_provider.dart (new)
- apps/mefali_livreur/lib/features/delivery/incoming_mission_screen.dart (new)
