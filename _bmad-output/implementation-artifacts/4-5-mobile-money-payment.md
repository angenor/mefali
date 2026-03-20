# Story 4.5 : Paiement Mobile Money

Status: done

## Story

En tant que client B2C,
Je veux payer via mobile money (Orange Money, MTN MoMo, Wave),
Afin de payer ma commande de maniere digitale et securisee.

## Contexte Metier

Le COD (story 4.4) couvre 95% des transactions actuelles a Bouake. Le Mobile Money est l'option secondaire mais strategique — il permet l'escrow (retention paiement jusqu'a livraison) et prepare l'infrastructure pour les fonctionnalites wallet/retrait (Epics 5-6). CinetPay est l'agregateur de paiement qui porte la licence BCEAO — mefali n'a pas besoin de sa propre licence.

**Flux de fonds :** Client → CinetPay escrow → wallet marchand (a confirmation livraison) → retrait mobile money.

**Contraintes NFR :**
- NFR11 : Aucun credit wallet sans transaction CinetPay confirmee
- NFR26 : API CinetPay latence < 3s
- NFR27 : Gestion indisponibilites CinetPay avec queue + retry

## Criteres d'Acceptation

### AC1 : Activation de l'option Mobile Money
- **Given** le PriceBreakdownSheet est affiche avec des articles dans le panier
- **When** l'ecran de recapitulatif s'ouvre
- **Then** les deux options de paiement sont actives : "Cash a la livraison" (pre-selectionne) et "Mobile Money" (selectionnable)

### AC2 : Initiation du paiement Mobile Money
- **Given** le client selectionne "Mobile Money" et appuie sur "Confirmer — {TOTAL} FCFA"
- **When** la requete est envoyee au serveur
- **Then** le serveur cree la commande avec `payment_type: mobile_money` et `payment_status: pending`, initie le paiement via PaymentProvider, et retourne le `payment_url` pour redirection CinetPay

### AC3 : Redirection vers CinetPay
- **Given** le serveur retourne un `payment_url`
- **When** le client recoit la reponse
- **Then** l'app ouvre la page de paiement CinetPay dans un navigateur in-app (WebView), le client choisit son operateur (Orange Money, MTN MoMo, Wave) et complete le paiement sur l'interface CinetPay

### AC4 : Succes du paiement — Escrow
- **Given** le paiement CinetPay est complete avec succes
- **When** le webhook CinetPay notifie le serveur (ou le client poll le statut)
- **Then** le `payment_status` passe a `escrow_held`, le panier est vide, et le client est redirige vers `OrderTrackingScreen`

### AC5 : Echec du paiement — Retry
- **Given** le paiement CinetPay echoue ou expire
- **When** le client revient a l'app
- **Then** un message d'erreur clair est affiche (ex: "Paiement echoue. Verifiez votre solde et reessayez.") avec un bouton "Reessayer" qui reinitie le flux de paiement, et le panier n'est PAS vide

### AC6 : Webhook CinetPay
- **Given** CinetPay envoie une notification webhook au serveur
- **When** le serveur recoit le callback
- **Then** la signature est verifiee, le paiement est verifie via `verify_payment()`, et le `payment_status` est mis a jour (escrow_held ou refunded), sans aucun credit wallet (credit wallet vient avec Epic 5/6)

### AC7 : Idempotence des paiements
- **Given** un paiement est deja initie pour une commande
- **When** le client reessaie ou un doublon webhook arrive
- **Then** le systeme utilise l'idempotency key (order_id) pour eviter les doubles charges et retourne le statut existant

### AC8 : Indisponibilite CinetPay
- **Given** l'API CinetPay est indisponible ou timeout (> 3s)
- **When** le client tente de payer
- **Then** un message d'erreur clair est affiche ("Service de paiement temporairement indisponible. Vous pouvez payer en cash a la livraison ou reessayer.") avec option de basculer vers COD

### AC9 : Verification du statut paiement
- **Given** le client est redirige apres paiement CinetPay
- **When** l'app verifie le statut
- **Then** `GET /api/v1/orders/{id}` retourne le `payment_status` a jour, et l'ecran affiche le resultat en consequence

## Taches / Sous-taches

- [x] **Tache 1 : Backend — Implementation CinetPay adapter** (AC: 2, 6, 7)
  - [x] 1.1 Implementer `initiate_payment()` dans `cinetpay.rs` : appel API CinetPay `POST /payment`, passer `amount`, `currency: XOF`, `transaction_id: order_id`, `return_url`, `notify_url`
  - [x] 1.2 Implementer `verify_payment()` dans `cinetpay.rs` : appel API CinetPay pour verifier le statut d'une transaction par `transaction_id`
  - [x] 1.3 Gerer les erreurs CinetPay : timeout 3s, mapping des codes erreur CinetPay vers `PaymentError`
  - [x] 1.4 Ajouter configuration CinetPay dans `.env` : `CINETPAY_API_KEY`, `CINETPAY_SITE_ID`, `CINETPAY_BASE_URL`, `CINETPAY_NOTIFY_URL`
  - [x] 1.5 Mettre a jour `MockPaymentProvider` pour couvrir les nouveaux scenarios (succes avec payment_url, echec, timeout)

- [x] **Tache 2 : Backend — Endpoint webhook CinetPay** (AC: 6, 7)
  - [x] 2.1 Ajouter route `POST /api/v1/payments/webhook` dans `routes/orders.rs` (pas d'auth JWT — CinetPay appelle directement)
  - [x] 2.2 Valider la signature CinetPay du webhook (HMAC ou API key verification)
  - [x] 2.3 Verifier le paiement via `verify_payment()` apres reception du webhook
  - [x] 2.4 Mettre a jour `payment_status` : succes → `escrow_held`, echec → laisser `pending`
  - [x] 2.5 Idempotence : si `payment_status` est deja `escrow_held`, retourner 200 sans rien faire
  - [x] 2.6 Logger la transaction webhook pour audit (structured JSON log)

- [x] **Tache 3 : Backend — Modifier create_order pour Mobile Money** (AC: 2)
  - [x] 3.1 Dans `orders/service.rs`, ajouter la branche `PaymentType::MobileMoney` dans `create_order()`
  - [x] 3.2 Quand `payment_type == MobileMoney` : creer la commande d'abord, puis appeler `payment_provider.initiate_payment()`
  - [x] 3.3 Retourner `payment_url` dans la reponse de creation de commande (ajouter champ optionnel a la reponse)
  - [x] 3.4 Si `initiate_payment()` echoue : la commande reste creee avec `payment_status: pending`, retourner l'erreur au client pour retry
  - [x] 3.5 Injecter `PaymentProvider` dans le service orders (Arc<dyn PaymentProvider>)

- [x] **Tache 4 : Backend — Reponse API enrichie** (AC: 2, 9)
  - [x] 4.1 Ajouter champ optionnel `payment_url: Option<String>` a la reponse de `POST /api/v1/orders` et `GET /api/v1/orders/{id}`
  - [x] 4.2 Le `payment_url` n'est present que pour les commandes `mobile_money` avec `payment_status: pending`
  - [x] 4.3 Tests unitaires pour les deux flux (COD sans payment_url, MobileMoney avec payment_url)

- [x] **Tache 5 : Frontend — Activer Mobile Money dans PaymentMethodSelector** (AC: 1)
  - [x] 5.1 Dans `payment_method_selector.dart`, retirer le `enabled: false` et le label "Bientot disponible" de l'option Mobile Money
  - [x] 5.2 Les deux options sont selectionnables, COD reste le defaut

- [x] **Tache 6 : Frontend — Flux de paiement CinetPay** (AC: 3, 4, 5, 8)
  - [x] 6.1 Ajouter package `url_launcher` (ou `webview_flutter` si necessaire) pour ouvrir le `payment_url`
  - [x] 6.2 Dans `RestaurantCatalogueScreen._placeOrder()`, quand `paymentType == 'mobile_money'` et que la reponse contient `payment_url` : ouvrir l'URL CinetPay
  - [x] 6.3 Creer `PaymentStatusScreen` dans `apps/mefali_b2c/lib/features/order/` : ecran intermediaire qui poll le statut de la commande apres retour de CinetPay
  - [x] 6.4 Polling : appeler `GET /api/v1/orders/{id}` toutes les 3s pendant 60s max, arreter des que `payment_status != pending`
  - [x] 6.5 Si `payment_status == escrow_held` : succes → vider panier → naviguer vers `OrderTrackingScreen`
  - [x] 6.6 Si `payment_status == pending` apres timeout 60s : afficher erreur + bouton "Reessayer" + bouton "Payer en cash"
  - [x] 6.7 Ajouter route GoRouter `/order/payment-status/:orderId`

- [x] **Tache 7 : Frontend — Provider de paiement** (AC: 9)
  - [x] 7.1 Ajouter methode `initiatePayment(String orderId)` dans `OrderEndpoint` si necessaire (ou reutiliser createOrder avec payment_url)
  - [x] 7.2 Creer `paymentStatusProvider` (FutureProvider.autoDispose.family) qui poll le statut de commande
  - [x] 7.3 Mettre a jour le modele `Order` Flutter pour inclure `paymentUrl` optionnel

- [x] **Tache 8 : Frontend — Gestion erreurs et UX** (AC: 5, 8)
  - [x] 8.1 Ecran erreur paiement : message clair en francais, bouton "Reessayer", bouton "Payer en cash a la livraison" comme fallback
  - [x] 8.2 Loading state pendant l'initiation du paiement : spinner sur le bouton "Confirmer" (comme pour COD)
  - [x] 8.3 Loading state pendant le polling de statut : animation de chargement avec message "Verification du paiement en cours..."
  - [x] 8.4 Skeleton screens pour les etats de chargement (jamais spinner seul, sauf sur bouton)

- [x] **Tache 9 : Tests** (AC: tous)
  - [x] 9.1 Tests unitaires Rust : `CinetPayAdapter` avec mock HTTP, `create_order` branche MobileMoney, webhook handler, idempotence
  - [x] 9.2 Tests MockPaymentProvider mis a jour pour les nouveaux scenarios
  - [x] 9.3 Tests widgets Flutter : PaymentMethodSelector avec Mobile Money actif, PaymentStatusScreen, flux complet
  - [x] 9.4 `dart analyze` zero erreurs sur le code source
  - [x] 9.5 `cargo clippy --workspace` zero nouveaux warnings
  - [x] 9.6 Tests existants (41 tests Flutter) ne regressent pas

## Dev Notes

### Ce qui existe deja — NE PAS recreer

**Backend (Rust) :**
- `PaymentProvider` trait dans `server/crates/payment_provider/src/provider.rs` avec :
  - `initiate_payment(PaymentRequest) -> Result<PaymentResponse, PaymentError>`
  - `verify_payment(transaction_id) -> Result<PaymentStatus, PaymentError>`
  - `initiate_withdrawal(WithdrawalRequest) -> Result<WithdrawalResponse, PaymentError>`
- `PaymentRequest` : `order_id: Id`, `amount: i64`, `currency: String`, `customer_phone: String`, `description: String`
- `PaymentResponse` : `transaction_id: String`, `payment_url: Option<String>`, `status: PaymentStatus`
- `PaymentStatus` (payment_provider) : `Pending`, `Completed`, `Failed`, `Cancelled`
- `PaymentError` : `InitiationFailed`, `VerificationFailed`, `WithdrawalFailed`, `NetworkError`
- `CinetPayAdapter` struct dans `cinetpay.rs` : stub avec `_api_key` et `_site_id` — a implementer
- `MockPaymentProvider` dans `mock.rs` avec flag `should_fail` — a enrichir
- `PaymentType::MobileMoney` enum existe dans `domain/orders/model.rs`
- `PaymentStatus::EscrowHeld` enum existe dans `domain/orders/model.rs`
- `Order` struct avec `payment_type`, `payment_status` — schema DB pret
- `create_order()` dans `orders/service.rs` : cree la commande mais ne touche PAS au PaymentProvider (COD only)
- `POST /api/v1/orders` endpoint dans `routes/orders.rs`
- Wallet structs (Wallet, WalletTransaction) dans `domain/wallets/` — stubs, NE PAS toucher

**Frontend (Flutter) :**
- `PaymentMethodSelector` widget dans `packages/mefali_design/lib/components/` : COD actif, Mobile Money desactive — a modifier
- `PriceBreakdownSheet` avec `onOrder(String paymentType)` callback — passe deja le type de paiement
- `Order` model avec `paymentType`, `paymentStatus` dans `packages/mefali_core/lib/models/order.dart`
- `OrderEndpoint` avec `createOrder()` dans `packages/mefali_api_client/lib/endpoints/order_endpoint.dart`
- `orderProvider` et `customerOrdersProvider` dans `packages/mefali_api_client/lib/providers/order_provider.dart`
- `OrderTrackingScreen` avec polling 30s dans `apps/mefali_b2c/lib/features/order/`
- `OrdersListScreen` dans `apps/mefali_b2c/lib/features/order/`
- `RestaurantCatalogueScreen._placeOrder()` dans `apps/mefali_b2c/lib/features/restaurant/`
- `cartProvider` avec `clear()` — existe et fonctionne
- `formatFcfa()` dans `packages/mefali_core/lib/utils/formatting.dart`
- Routes GoRouter : `/order/tracking/:orderId`, `/orders` — existent

### Patterns a suivre (etablis par stories 4.2, 4.3, 4.4)

**Backend Rust :**
- Repository pattern : `pub async fn` avec `pool: &PgPool`, retour `Result<T, AppError>`
- SQLx queries : `sqlx::query_as!` avec compile-time checking
- Verification ownership : toujours verifier que la ressource appartient a l'utilisateur authentifie
- Routes : `web::resource("/path").route(web::post().to(handler))` dans `routes/mod.rs`
- Auth : `require_role(&auth, &[UserRole::Client])` en debut de handler
- Erreurs : `thiserror` enums dans domain, mappes vers HTTP status dans api crate
- Response wrapper : `json!({"data": {...}})` pour succes, `AppError` pour erreurs
- Webhook : pas de JWT auth (CinetPay appelle directement), mais verifier signature/API key

**Frontend Flutter :**
- Providers Riverpod : `FutureProvider.autoDispose.family` pour donnees parametrees
- Skeleton loading : `ColorTween` animation (PAS de package shimmer)
- Erreurs : `AsyncValue.when(loading: skeleton, error: retry, data: content)`
- Navigation : GoRouter declaratif, routes dans le routeur principal de mefali_b2c
- Composants partages : dans `packages/mefali_design/lib/components/`
- Format prix : `formatFcfa(centimes)` depuis `mefali_core`
- Montants en centimes partout (int, pas double)
- Naming : `camelCase` pour providers (+ suffix `Provider`), `PascalCase` pour widgets
- autoDispose obligatoire sur tous les providers

### Contraintes techniques critiques

- **PaymentProvider APPELE pour MobileMoney** : Contrairement a COD, quand `payment_type == MobileMoney`, le service `create_order` DOIT appeler `payment_provider.initiate_payment()` et retourner le `payment_url`.
- **Pas de credit wallet dans cette story** : Le credit wallet (escrow → wallet marchand/livreur) vient dans Epic 5 (story 5.6) et Epic 6. Ici on gere uniquement l'escrow hold.
- **Idempotency key = order_id** : L'`order_id` (UUID) sert de cle d'idempotence pour eviter les doubles charges. 0 retry automatique cote serveur.
- **Prix resolus cote serveur** : Ne JAMAIS faire confiance aux prix envoyes par le client. Le service `create_order` charge deja les prix depuis la DB.
- **Frais de livraison fixes 500 FCFA** : `delivery_fee` reste hardcode a 50000 centimes (500 FCFA) en attendant story 4.6.
- **autoDispose obligatoire** : Tous les providers Riverpod doivent utiliser `autoDispose`.
- **Pas de WebSocket** : Le suivi utilise du polling. WebSocket vient avec Epic 5.
- **Currency : XOF** : Toutes les transactions sont en Francs CFA (FCFA = XOF).
- **Webhook non authentifie JWT** : L'endpoint webhook CinetPay ne doit PAS exiger de JWT. Utiliser la verification de signature CinetPay a la place.
- **CinetPay porte la licence BCEAO** : mefali n'est pas un instrument de paiement reglemente. Le wallet interne est un solde app (modele Yango).

### CinetPay API — Informations cles

**Integration CinetPay :**
- Endpoint initiation : `POST https://api-checkout.cinetpay.com/v2/payment`
- Parametres requis : `apikey`, `site_id`, `transaction_id` (= order_id), `amount`, `currency` (XOF), `description`, `return_url`, `notify_url`
- Reponse : `payment_url` (URL de redirection pour le client)
- Verification : `POST https://api-checkout.cinetpay.com/v2/payment/check` avec `apikey`, `site_id`, `transaction_id`
- Webhook (notify_url) : CinetPay POST les notifications de paiement a cette URL
- Statuts CinetPay : `ACCEPTED` (succes), `REFUSED` (refuse), `ERROR` (erreur)
- HTTP client Rust : utiliser `reqwest` (async, deja dans l'ecosysteme Actix)

**Configuration .env a ajouter :**
```
CINETPAY_API_KEY=votre_api_key
CINETPAY_SITE_ID=votre_site_id
CINETPAY_BASE_URL=https://api-checkout.cinetpay.com/v2
CINETPAY_NOTIFY_URL=https://api.mefali.ci/api/v1/payments/webhook
CINETPAY_RETURN_URL=https://api.mefali.ci/payment/return
```

### UX Specifications

```
Bottom sheet recapitulatif (PriceBreakdownSheet — identique a story 4.4) :

  Garba + alloco     1 500 FCFA    [- 1 +]
  Jus gingembre        500 FCFA    [- 1 +]
  ──────────────────────────────────────
  Sous-total          2 000 FCFA
  Livraison             500 FCFA
  ──────────────────────────────────────
  TOTAL               2 500 FCFA   ← texte le plus gros (primary color)

  Mode de paiement :
  (o) Cash a la livraison           ← pre-selectionne
  ( ) Mobile Money                  ← MAINTENANT ACTIF (plus grise)

  [  CONFIRMER — 2 500 FCFA  ]     ← FilledButton pleine largeur, marron fonce
```

```
Ecran intermediaire (PaymentStatusScreen) — apres retour de CinetPay :

  ┌─────────────────────────────────────┐
  │                                     │
  │     [Animation chargement]          │
  │                                     │
  │  Verification du paiement           │
  │  en cours...                        │
  │                                     │
  │  Commande #a1b2c3d4                 │
  │  Total : 2 500 FCFA                 │
  │                                     │
  └─────────────────────────────────────┘

  Succes → navigation vers OrderTrackingScreen
  Echec →
  ┌─────────────────────────────────────┐
  │                                     │
  │     [Icone erreur rouge]            │
  │                                     │
  │  Paiement echoue                    │
  │  Verifiez votre solde et            │
  │  reessayez.                         │
  │                                     │
  │  [  REESSAYER  ]  ← primary         │
  │  [  PAYER EN CASH  ]  ← secondary  │
  │                                     │
  └─────────────────────────────────────┘
```

Erreur paiement : SnackBar rouge + message clair + bouton Reessayer (UX spec).
Succes : SnackBar vert + ✓ (3s auto-dismiss) avant navigation.

### Project Structure Notes

**Nouveaux fichiers a creer :**
```
apps/mefali_b2c/lib/features/order/payment_status_screen.dart
```

**Fichiers a modifier :**
```
server/crates/payment_provider/src/cinetpay.rs          (implementer les methodes stub)
server/crates/payment_provider/src/mock.rs              (enrichir scenarios de test)
server/crates/payment_provider/Cargo.toml               (ajouter reqwest, serde_json si absent)
server/crates/domain/src/orders/service.rs              (branche MobileMoney dans create_order)
server/crates/api/src/routes/orders.rs                  (ajouter webhook endpoint)
server/crates/api/src/routes/mod.rs                     (enregistrer route webhook)
server/crates/common/src/config.rs                      (ajouter config CinetPay)
server/.env.example                                     (ajouter variables CinetPay)
packages/mefali_design/lib/components/payment_method_selector.dart  (activer Mobile Money)
packages/mefali_core/lib/models/order.dart              (ajouter paymentUrl optionnel)
packages/mefali_api_client/lib/endpoints/order_endpoint.dart  (parser paymentUrl)
apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart  (flux MobileMoney)
apps/mefali_b2c/lib/app.dart                            (ajouter route /order/payment-status/:id)
apps/mefali_b2c/pubspec.yaml                            (ajouter url_launcher si absent)
```

### Intelligence story precedente (4-4-cod-payment-flow)

**Learnings de la story 4.4 :**
- `PriceBreakdownSheet` est passe de `StatelessWidget` a `StatefulWidget` pour gerer l'etat du mode de paiement — ne pas revenir en arriere
- `onOrder` callback prend `String paymentType` (pas `PaymentType` enum) — garder ce pattern
- `OrderTrackingScreen` utilise `Timer.periodic(30s)` pour polling — ne pas changer, WebSocket viendra avec Epic 5
- 41 tests Flutter passent actuellement — ne pas casser
- `cargo build + clippy` OK — maintenir zero warnings
- Le bouton est labelle "Confirmer" (pas "Commander") depuis story 4.4

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 4, Story 4.5]
- [Source: _bmad-output/planning-artifacts/architecture.md — PaymentProvider trait, CinetPay adapter, Escrow]
- [Source: _bmad-output/planning-artifacts/prd.md — FR30, FR31, NFR11, NFR26, NFR27, CinetPay integration]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow B2C Confirmation, Erreur paiement]
- [Source: _bmad-output/implementation-artifacts/4-4-cod-payment-flow.md — Patterns et learnings]
- [Source: server/crates/payment_provider/src/provider.rs — PaymentProvider trait definition]
- [Source: server/crates/payment_provider/src/cinetpay.rs — CinetPay stub]
- [Source: server/crates/domain/src/orders/model.rs — Order, PaymentType, PaymentStatus enums]
- [Source: server/crates/domain/src/orders/service.rs — create_order service]
- [Source: packages/mefali_design/lib/components/payment_method_selector.dart — PaymentMethodSelector widget]

## Dev Agent Record

### Agent Model Used
Claude Opus 4.6 (1M context)

### Debug Log References
- Rust 139 unit tests pass, 3 integration tests skipped (need DB)
- Flutter 41 tests pass (no regression)
- dart analyze: 0 errors, 0 warnings (info only on existing code)
- cargo clippy: 0 new warnings (2 pre-existing about too many args)

### Completion Notes List
- CinetPay adapter implemented with reqwest HTTP client, 3s timeout, error mapping
- MockPaymentProvider enriched with Success/Failure/Timeout behaviors and configurable verify_status
- AppConfig extended with CinetPay fields (api_key, site_id, base_url, notify_url, return_url)
- PaymentProvider injected into Actix app via web::Data<Arc<dyn PaymentProvider>>
- create_order service modified: MobileMoney branch calls payment_provider.initiate_payment()
- CreateOrderResult struct wraps OrderWithItems + optional payment_url
- Webhook endpoint POST /api/v1/payments/webhook with idempotence (escrow_held check)
- process_payment_webhook service: verify_payment -> update_payment_status
- update_payment_status repository function added
- PaymentMethodSelector: Mobile Money now active and selectable
- Order model: paymentUrl optional field added
- OrderEndpoint.createOrder returns CreateOrderResult with payment_url
- PaymentStatusScreen: polls order status every 3s for 60s, navigates on success
- url_launcher used to open CinetPay payment URL in external browser
- GoRouter route /order/payment-status/:orderId added
- Error handling: CinetPay unavailable shows clear French error with COD fallback option

### Review Follow-ups (AI)
- [x] [AI-Review][MEDIUM] Persister `external_transaction_id` CinetPay en base — migration + repository + service
- [x] [AI-Review][MEDIUM] Gerer les commandes orphelines — endpoint `POST /orders/{id}/retry-payment` + Flutter retryPayment
- [x] [AI-Review][MEDIUM] Ajouter tests widget pour PaymentStatusScreen — 3 tests ajoutes

### Change Log
- 2026-03-20: Code review round 2 — 3 remaining MEDIUM issues fixed (M3-M5), all 13 issues resolved
- 2026-03-20: Code review — 10 issues fixes (C1-C3 critical, H1-H5 high, M1-M2 medium), 3 action items crees (M3-M5)
- 2026-03-20: Story 4-5 implemented — Full Mobile Money payment flow via CinetPay

### File List
**New files:**
- apps/mefali_b2c/lib/features/order/payment_status_screen.dart

**Modified files:**
- server/Cargo.toml (added reqwest workspace dep)
- server/crates/payment_provider/Cargo.toml (added reqwest, tracing)
- server/crates/payment_provider/src/cinetpay.rs (full implementation)
- server/crates/payment_provider/src/mock.rs (enriched with MockBehavior enum)
- server/crates/domain/Cargo.toml (added payment_provider dep)
- server/crates/domain/src/orders/service.rs (MobileMoney branch, webhook, CreateOrderResult)
- server/crates/domain/src/orders/repository.rs (update_payment_status)
- server/crates/domain/src/orders/model.rs (no changes needed — enums pre-existed)
- server/crates/domain/src/users/service.rs (AppConfig test fixture)
- server/crates/api/src/main.rs (PaymentProvider injection)
- server/crates/api/src/routes/orders.rs (create_order with PaymentProvider, webhook handler)
- server/crates/api/src/routes/mod.rs (webhook route)
- server/crates/api/src/test_helpers.rs (AppConfig test fixture)
- server/crates/api/src/extractors/authenticated_user.rs (AppConfig test fixture)
- server/crates/common/src/config.rs (CinetPay config fields)
- server/.env.example (CinetPay env vars)
- packages/mefali_core/lib/models/order.dart (paymentUrl field)
- packages/mefali_core/lib/models/order.g.dart (regenerated)
- packages/mefali_design/lib/components/payment_method_selector.dart (Mobile Money active)
- packages/mefali_api_client/lib/endpoints/order_endpoint.dart (CreateOrderResult)
- apps/mefali_b2c/lib/app.dart (payment-status route)
- apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart (Mobile Money flow)
- apps/mefali_b2c/pubspec.yaml (url_launcher dep)
