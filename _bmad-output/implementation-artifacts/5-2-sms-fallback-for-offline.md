# Story 5.2: SMS Fallback pour livreurs hors connexion

Status: in-progress

## Story

As a livreur,
I want recevoir les missions par SMS quand je suis hors connexion,
So that je ne rate jamais une opportunite de course.

## Acceptance Criteria

1. **AC1 — Detection echec push et declenchement SMS**
   **Given** une commande prete et un livreur disponible
   **When** le push FCM echoue ou n'est pas acquitte dans 5s
   **Then** le systeme envoie un SMS au livreur avec les donnees de mission encodees en Base64 deep link
   **And** le SMS est livre en < 30s apres l'echec push (NFR22)

2. **AC2 — Format SMS avec deep link Base64**
   **Given** un SMS de mission a envoyer
   **When** le SMS est compose
   **Then** le texte contient: "Nouvelle commande #{order_number}. {merchant_name} -> {delivery_address}. {payment_type} {amount}F. {deep_link}"
   **And** le deep link contient toutes les donnees de mission encodees en Base64
   **And** le SMS total respecte la limite de caracteres (deep link tronque le texte si necessaire)

3. **AC3 — Dual SMS gateway avec failover automatique**
   **Given** le provider SMS primaire
   **When** l'envoi echoue
   **Then** le systeme bascule automatiquement sur le provider de fallback (NFR28)
   **And** l'echec est loge pour monitoring

4. **AC4 — Deep link ouvre l'app avec donnees de mission**
   **Given** un SMS recu avec un deep link Base64
   **When** le livreur tape sur le lien
   **Then** l'app mefali_livreur s'ouvre
   **And** les donnees de mission sont decodees du Base64
   **And** le DeliveryMissionCard s'affiche avec toutes les infos (identique au push)

5. **AC5 — Acceptation depuis donnees decodees**
   **Given** le DeliveryMissionCard affiche via deep link
   **When** le livreur appuie sur ACCEPTER
   **Then** l'action est mise en file d'attente locale (SyncQueue) si hors connexion
   **And** la synchronisation se fait automatiquement au retour de connexion
   **And** zero perte de donnees offline (NFR23)

6. **AC6 — Integration dans le flux existant notify_driver_for_order**
   **Given** le flux de notification existant (story 5-1)
   **When** `notify_driver_for_order()` est appele
   **Then** le push FCM est tente en premier
   **And** si echec, le SMS fallback est declenche automatiquement
   **And** le flux reste transparent pour le reste du systeme

## Tasks / Subtasks

- [x] Task 1: Backend — Integrer SmsRouter dans le delivery service (AC: 1, 3, 6)
  - [x] 1.1 Injecter `SmsRouter` dans `AppState` (main.rs) a cote du `FcmClient`
  - [x] 1.2 Modifier `notify_driver_for_order()` pour accepter `Option<&SmsRouter>`
  - [x] 1.3 Ajouter logique de fallback : si push echoue/pas d'ACK → appel SMS
  - [x] 1.4 Ajouter endpoint config pour un vrai SMS provider (Infobip/Twilio) via `SmsProvider` trait

- [x] Task 2: Backend — Composer le SMS avec deep link Base64 (AC: 2)
  - [x] 2.1 Creer `build_sms_mission_text()` dans delivery service utilisant `deep_link.rs`
  - [x] 2.2 Encoder les donnees DeliveryMission en JSON → Base64 via `encode_deep_link()`
  - [x] 2.3 Formater le texte SMS : info lisible + deep link
  - [x] 2.4 Gerer la limite de caracteres SMS (tronquer texte lisible si deep link long)

- [x] Task 3: Backend — Determiner le numero de telephone du livreur (AC: 1)
  - [x] 3.1 S'assurer que `find_available_driver()` retourne aussi le `phone` du driver
  - [x] 3.2 Passer le phone au SMS fallback

- [x] Task 4: Flutter — Gestion des deep links entrants (AC: 4)
  - [x] 4.1 Configurer le schema d'URL deep link dans Android (`AndroidManifest.xml`) et iOS (`Info.plist`)
  - [x] 4.2 Creer `deep_link_handler.dart` dans `features/notification/` pour ecouter les deep links entrants
  - [x] 4.3 Parser le Base64 → JSON → `DeliveryMission`
  - [x] 4.4 Router vers `IncomingMissionScreen` avec les donnees decodees

- [x] Task 5: Flutter — Acceptation offline avec SyncQueue (AC: 5)
  - [x] 5.1 Si hors connexion, stocker l'action "accept mission" dans la queue locale
  - [ ] 5.2 Au retour de connexion, synchroniser automatiquement avec le serveur — BLOCKED: requiert l'endpoint accept API (story 5.3)
  - [x] 5.3 Feedback visuel : indiquer que l'action est en attente de sync

- [x] Task 6: Tests (AC: tous)
  - [x] 6.1 Tests unitaires Rust : `build_sms_mission_text()`, integration SmsRouter dans delivery service
  - [ ] 6.2 Tests unitaires Rust : fallback push → SMS dans `notify_driver_for_order()` — requiert mock DB pour tester le flux complet
  - [x] 6.3 Tests Flutter : deep link parsing Base64 → DeliveryMission
  - [ ] 6.4 Tests Flutter : IncomingMissionScreen avec donnees deep link — requiert mock Firebase/providers
  - [x] 6.5 Tests existants : verifier que les 142 Rust + 135 Flutter passent toujours

## Dev Notes

### Infrastructure SMS deja en place (story 5-1)

Le crate `notification` contient deja tout le necessaire SMS :

- **`server/crates/notification/src/sms/mod.rs`** : `SmsProvider` trait, `SmsRouter` (primary + fallback), `SmsResult`, `SmsError`
- **`server/crates/notification/src/sms/dev_provider.rs`** : `DevSmsProvider` qui loge en console (pour dev local)
- **`server/crates/notification/src/deep_link.rs`** : `encode_deep_link()` / `decode_deep_link()` pour Base64 JSON
- **Tests existants** : scenarios primary success, fallback, all-fail sont deja couverts

**L'infrastructure est prete mais PAS ENCORE CONNECTEE au flux de livraison.** Cette story fait le branchement.

### Flux actuel notify_driver_for_order (a modifier)

```
mark_ready() → notify_driver_for_order()
                    ↓
              find_available_driver()
                    ↓
              create_delivery(status: pending)
                    ↓
              build_mission_payload()
                    ↓
              fcm_client.send_push()  ← ACTUELLEMENT: push seul, pas de fallback
```

**Flux cible :**

```
mark_ready() → notify_driver_for_order()
                    ↓
              find_available_driver() → retourne aussi phone
                    ↓
              create_delivery(status: pending)
                    ↓
              build_mission_payload()
                    ↓
              fcm_client.send_push()
                    ↓
              SI echec push (ou driver sans fcm_token)
                    ↓
              build_sms_mission_text(payload) → encode Base64
                    ↓
              sms_router.send(phone, sms_text)
```

### Deep link — Format et encodage

**Schema d'URL :** `mefali://delivery/mission?data={BASE64_ENCODED_JSON}`

**Donnees encodees (JSON → Base64) :**
```json
{
  "order_id": "uuid",
  "merchant_name": "Maman Adjoua",
  "merchant_address": "Quartier Commerce",
  "delivery_address": "Quartier Belleville",
  "delivery_lat": 7.69,
  "delivery_lng": -5.03,
  "estimated_distance_m": 800,
  "delivery_fee": 350,
  "items_summary": "Garba + Alloco (x1)",
  "payment_type": "cod",
  "amount": 3000,
  "client_phone": "0707070707"
}
```

**Format SMS final :**
```
Nouvelle commande #127. Maman Adjoua -> Quartier Belleville. COD 3000F. mefali://delivery/mission?data=eyJvcm...
```

**Note :** `deep_link.rs` encode/decode deja du JSON en Base64. Il faut juste s'assurer que le struct serialise inclut les champs necessaires (ajouter `payment_type`, `amount`, `client_phone` au payload si absents).

### Patterns Flutter a respecter

- **IncomingMissionScreen existe deja** et accepte les donnees en parametre (push payload OU API). Le deep link doit injecter les memes donnees → meme ecran, zero duplication.
- **Riverpod autoDispose** obligatoire sur tous les providers
- **GoRouter** : ajouter la route deep link dans `app.dart` — GoRouter supporte `redirect` pour intercepter les deep links
- Le `PushNotificationHandler` (singleton) gere deja foreground/background/terminated. Le deep link handler est un composant SEPARE (pas dans PushNotificationHandler).
- **Amounts en centimes (int)**, affichage via `formatFcfa()`
- **Labels en francais**
- **Touch targets >= 48dp** (56dp pour ACCEPTER)

### Patterns Backend Rust a respecter

- **Repository pattern** : `pub async fn xxx(pool: &PgPool, ...) -> Result<T, AppError>`
- **sqlx::query_as!** pour verification compile-time
- **Response wrapper** : `{"data": {...}}` succes, `{"error": {...}}` erreur
- **IDs UUID v4** via `common::types::new_id()`
- **snake_case** partout (JSON, DB, API)
- **AppError** enum dans common, mappe vers HTTP status dans api crate
- **FcmClient pattern** : `FcmClient::from_env()` optional. Faire pareil pour SmsRouter : `SmsRouter::from_env()` avec graceful init si config absente

### Offline sync (mefali_offline package)

Le package `packages/mefali_offline/` contient :
- **Drift (SQLite)** avec SyncQueue table
- **SyncService** : detecte reconnexion → POST actions en queue
- **Retry** : 3 tentatives, backoff exponentiel (1s, 2s, 4s)
- **Conflit** : last-write-wins avec timestamp serveur

Pour l'acceptation offline : stocker l'action dans SyncQueue, sync au retour de connexion. Le serveur doit gerer le cas ou la mission a deja ete prise par un autre livreur (reponse erreur gracieuse).

### Fichiers a creer/modifier

**Backend (Rust) — Modifier :**
- `server/crates/api/src/main.rs` — Injecter `SmsRouter` dans AppState
- `server/crates/domain/src/deliveries/service.rs` — Ajouter SMS fallback dans `notify_driver_for_order()`, creer `build_sms_mission_text()`
- `server/crates/domain/src/deliveries/repository.rs` — `find_available_driver()` doit retourner le phone
- `server/crates/domain/src/deliveries/model.rs` — Enrichir le payload si champs manquants (payment_type, amount, client_phone)
- `server/crates/api/src/routes/orders.rs` — Passer SmsRouter a `mark_ready()`
- `server/crates/api/src/test_helpers.rs` — Ajouter SmsRouter None aux tests

**Backend (Rust) — Potentiellement modifier :**
- `server/crates/notification/src/deep_link.rs` — Verifier que le format d'encodage convient au payload enrichi
- `server/.env.example` — Ajouter variables SMS provider si necessaire

**Flutter — Creer :**
- `apps/mefali_livreur/lib/features/notification/deep_link_handler.dart` — Ecoute et parsing des deep links

**Flutter — Modifier :**
- `apps/mefali_livreur/lib/main.dart` — Initialiser DeepLinkHandler
- `apps/mefali_livreur/lib/app.dart` — Route deep link dans GoRouter
- `apps/mefali_livreur/android/app/src/main/AndroidManifest.xml` — Intent filter pour schema `mefali://`
- `apps/mefali_livreur/ios/Runner/Info.plist` — URL scheme `mefali`

**Flutter — Potentiellement modifier :**
- `packages/mefali_core/lib/models/delivery_mission.dart` — Ajouter champs si manquants (payment_type, amount, client_phone)
- `packages/mefali_api_client/lib/mefali_api_client.dart` — Export si nouveaux composants

### Contraintes critiques

1. **SMS < 30s apres echec push (NFR22)** — Le fallback doit etre rapide, pas de retry complexe avant de basculer
2. **Dual SMS gateway (NFR28)** — SmsRouter gere deja le failover, il suffit de le brancher
3. **Zero perte offline (NFR23)** — SyncQueue + retry obligatoire
4. **Limite 160 chars SMS** — Le deep link Base64 peut etre long. Tronquer le texte lisible, jamais le deep link
5. **APK < 30MB (NFR3)** — Pas de nouvelle dependance lourde
6. **Devices 2GB RAM** — Deep link parsing doit etre leger

### Ce qui est HORS SCOPE

- Accept/refuse backend logic complete → Story 5.3
- Re-routing vers prochain livreur si timeout → Story 5.3
- GPS navigation → Story 5.4
- Real-time tracking WebSocket → Story 5.5
- Confirmation livraison + paiement wallet → Story 5.6
- Protocole client absent → Story 5.7
- Toggle disponibilite livreur → Story 5.8
- Configuration d'un vrai SMS provider en production (Infobip/Twilio) — l'interface est prete, le provider de dev suffit pour cette story. La configuration production sera faite lors du deploiement.

### Project Structure Notes

- Alignement avec la structure hexagonale Rust : la logique SMS fallback reste dans `domain/deliveries/service.rs`, le crate `notification` fournit l'infrastructure
- Le deep link handler Flutter est un composant separe du PushNotificationHandler (separation des responsabilites)
- Les donnees de mission deep link utilisent le meme modele `DeliveryMission` que le push (pas de modele duplique)

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 5, Story 5.2]
- [Source: _bmad-output/planning-artifacts/architecture.md — Notification system, Offline-first, SMS Gateway]
- [Source: _bmad-output/planning-artifacts/prd.md — FR19, FR28, NFR22, NFR23, NFR28, Journey 2 Kone]
- [Source: _bmad-output/planning-artifacts/ux-design-spec.md — Flow 3, SMS fallback UX, Critical Success Moment]
- [Source: _bmad-output/implementation-artifacts/5-1-delivery-mission-notification-push.md — Previous story intelligence]
- [Source: server/crates/notification/src/sms/mod.rs — SmsProvider trait, SmsRouter]
- [Source: server/crates/notification/src/deep_link.rs — encode_deep_link, decode_deep_link]
- [Source: server/crates/domain/src/deliveries/service.rs — notify_driver_for_order]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend: SmsRouter (dual-provider, failover) injecte dans main.rs et passe a travers la chaine mark_ready → notify_driver_for_order
- Backend: `try_send_push()` factorisee pour retourner bool, `build_sms_mission_text()` cree le SMS avec deep link Base64
- Backend: `AvailableDriver` enrichi avec `phone`, query SQL mise a jour (supprime filtre fcm_token IS NOT NULL pour permettre drivers SMS-only)
- Backend: `DeliveryMission` enrichi avec `payment_type` et `order_total` pour le SMS et le deep link
- Backend: 9 tests unitaires pour build_sms_mission_text (format, deep link decodable, payment type, truncation, fallback address)
- Flutter: `DeliveryMission.fromDeepLink()` decode Base64 → JSON → model
- Flutter: `DeepLinkHandler` singleton ecoute les deep links entrants via MethodChannel
- Flutter: `MefaliLivreurApp` converti en ConsumerStatefulWidget, ecoute les deep links entrants et route vers IncomingMissionScreen
- Flutter: AndroidManifest.xml avec intent-filter restreint a `mefali://delivery/mission`
- Flutter: iOS Info.plist avec CFBundleURLTypes pour schema `mefali://`
- Flutter: `PendingAcceptQueue` stocke les acceptations offline avec donnees mission completes dans un fichier JSON local
- Flutter: `IncomingMissionScreen._handleAccept()` detecte connectivity, queue si offline avec feedback visuel orange
- Flutter: 5 tests pour DeliveryMission (fromJson, toJson, fromDeepLink, numeric strings)
- Tests: 207 Rust unit tests OK, 88 Flutter tests OK, zero regression

### Change Log

- 2026-03-20: Story 5.2 implemented — SMS fallback for offline drivers
- 2026-03-20: Code review (AI) — Fixes: C1 SMS truncation + truncate_str helper, C2 iOS Info.plist URL scheme, M1 AndroidManifest intent-filter restreint host/path, M2 connectivity check example.com, M3 PendingAcceptQueue stocke mission complete, M4 payment_type match direct, L1 fallback adresse "Adresse a confirmer", L2 log SmsRouter init, L3 DeepLinkHandler guard double-init. Tasks 5.2/6.2/6.4 honnêtement marquees [ ].

### File List

**Backend (Rust) — Modified:**
- server/crates/api/src/main.rs
- server/crates/api/src/routes/orders.rs
- server/crates/api/src/test_helpers.rs
- server/crates/domain/src/deliveries/model.rs
- server/crates/domain/src/deliveries/repository.rs
- server/crates/domain/src/deliveries/service.rs
- server/crates/domain/src/orders/service.rs
- server/.env.example

**Flutter — Modified:**
- packages/mefali_core/lib/models/delivery_mission.dart
- packages/mefali_core/test/mefali_core_test.dart
- apps/mefali_livreur/lib/main.dart
- apps/mefali_livreur/lib/app.dart
- apps/mefali_livreur/lib/features/delivery/incoming_mission_screen.dart
- apps/mefali_livreur/pubspec.yaml
- apps/mefali_livreur/android/app/src/main/AndroidManifest.xml
- apps/mefali_livreur/ios/Runner/Info.plist

**Flutter — Created:**
- apps/mefali_livreur/lib/features/notification/deep_link_handler.dart
- apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart
