# Story 5.8: Driver Availability & Wallet Withdrawal

Status: done

## Story

As a livreur,
I want to toggle my availability and withdraw my earnings,
So that I control when I work and access my money instantly.

## Acceptance Criteria

1. **AC1 — Toggle disponibilite**: Given le livreur est connecte, When il toggle actif/pause, Then son statut change et seuls les livreurs actifs recoivent des missions.
2. **AC2 — Persistence statut**: Given le livreur met en pause, When il ferme et rouvre l'app, Then le statut reste "en pause" (persiste cote serveur).
3. **AC3 — Filtre assignation**: Given le livreur est en pause, When une nouvelle commande arrive, Then le systeme ne lui propose PAS de mission (filtre dans `find_available_driver`).
4. **AC4 — Solde wallet visible**: Given le livreur a effectue des livraisons, When il ouvre l'ecran wallet, Then il voit son solde actuel et l'historique des transactions.
5. **AC5 — Retrait mobile money**: Given le livreur a un solde > 0, When il demande un retrait, Then le montant est debite du wallet et transfere vers son numero mobile money en < 2 min.
6. **AC6 — Validation retrait**: Given le livreur demande un retrait superieur a son solde, When il soumet, Then le systeme refuse avec message d'erreur clair.
7. **AC7 — Transaction audit**: Given un retrait est effectue, When on consulte l'historique, Then une WalletTransaction de type Withdrawal est enregistree avec reference et description.
8. **AC8 — Offline toggle**: Given le livreur est hors connexion, When il toggle son statut, Then l'action est mise en file d'attente et synchronisee au retour de connexion.

## Tasks / Subtasks

### Backend Rust

- [x] **Task 1 — Migration: ajouter champ disponibilite livreur** (AC: 1,2,3)
  - [x] 1.1 Creer migration `add_driver_availability_status`: ajouter colonne `is_available BOOLEAN DEFAULT true NOT NULL` a la table `users`
  - [x] 1.2 Creer migration down correspondante

- [x] **Task 2 — Domain: driver availability** (AC: 1,2,3)
  - [x] 2.1 Dans `deliveries/repository.rs`: ajouter `set_driver_availability(driver_id, is_available) -> Result<bool>`
  - [x] 2.2 Dans `deliveries/repository.rs`: ajouter `get_driver_availability(driver_id) -> Result<bool>`
  - [x] 2.3 Modifier `find_available_driver()` pour filtrer `WHERE u.is_available = true` en plus du filtre existant (pas de livraison active)
  - [x] 2.4 Modifier `find_next_available_driver()` idem
  - [x] 2.5 Dans `deliveries/service.rs`: ajouter `toggle_driver_availability(driver_id, is_available) -> Result<bool>`
  - [x] 2.6 Dans `deliveries/service.rs`: ajouter `get_driver_availability(driver_id) -> Result<bool>`

- [x] **Task 3 — Domain: wallet withdrawal** (AC: 5,6,7)
  - [x] 3.1 Dans `wallets/repository.rs`: ajouter `debit_wallet(wallet_id, amount) -> Result<Wallet>` (atomic `balance -= amount` avec check `balance >= amount`)
  - [x] 3.2 Dans `wallets/service.rs`: ajouter `request_withdrawal(user_id, amount, phone_number) -> Result<WalletTransaction>`
  - [x] 3.3 Reutilise `PaymentProvider::initiate_withdrawal()` existant (pas besoin de nouvelle methode `transfer()`)
  - [x] 3.4 Dans `cinetpay.rs`: implementer `initiate_withdrawal()` via l'API CinetPay Transfer
  - [x] 3.5 Dans `wallets/service.rs`: ajouter `get_wallet_with_transactions(user_id) -> Result<(Wallet, Vec<WalletTransaction>)>`

- [x] **Task 4 — API routes** (AC: 1,4,5)
  - [x] 4.1 `PUT /api/v1/drivers/availability` — body: `{"is_available": bool}` — role: Driver
  - [x] 4.2 `GET /api/v1/drivers/availability` — retourne `{"is_available": bool}` — role: Driver
  - [x] 4.3 `GET /api/v1/wallets/me` — retourne wallet + transactions recentes — role: Driver/Merchant
  - [x] 4.4 `POST /api/v1/wallets/withdraw` — body: `{"amount": int, "phone_number": str}` — role: Driver
  - [x] 4.5 Enregistrer les routes dans `routes/mod.rs`

- [x] **Task 5 — Tests backend** (AC: tous)
  - [x] 5.1 Tests unitaires: wallet model serde (3 tests), mock withdrawal success/failure (2 tests)
  - [x] 5.2 201 tests passent (168 domain + 12 common + 11 payment_provider + 10 notification), 0 regressions

### Frontend Flutter (mefali_livreur)

- [x] **Task 6 — API client** (AC: 1,4,5)
  - [x] 6.1 Dans `delivery_endpoint.dart`: ajouter `setAvailability(bool)`, `getAvailability()`
  - [x] 6.2 Creer `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart`: `getWallet()`, `withdraw(amount, phoneNumber)`
  - [x] 6.3 Exporter wallet_endpoint + providers dans `mefali_api_client.dart`

- [x] **Task 7 — Riverpod providers** (AC: 1,4)
  - [x] 7.1 Creer `driver_availability_provider.dart` — NotifierProvider avec optimistic toggle + rollback
  - [x] 7.2 Creer `wallet_provider.dart` — FutureProvider.autoDispose pour wallet + transactions

- [x] **Task 8 — Ecran Home avec toggle** (AC: 1,2,8)
  - [x] 8.1 Ajouter un switch/toggle prominent sur l'ecran Home du livreur (actif/en pause)
  - [x] 8.2 Etat visuel clair: vert = actif (recoit missions), gris/orange = pause
  - [x] 8.3 Integrer avec PendingAcceptQueue pour offline: si hors connexion, queuer l'action `toggle_availability`

- [x] **Task 9 — Ecran Wallet** (AC: 4,5,6,7)
  - [x] 9.1 Creer `apps/mefali_livreur/lib/features/wallet/wallet_screen.dart`
  - [x] 9.2 Afficher solde en gros (FCFA), liste transactions recentes (credit livraison, retraits)
  - [x] 9.3 Bouton "Retirer" ouvre bottom sheet: champ montant + numero mobile money pre-rempli (profil)
  - [x] 9.4 Validation client: montant > 0, montant <= solde, numero valide (format CI)
  - [x] 9.5 Feedback: loading pendant transfert, confirmation succes SnackBar, erreur explicite si echec

- [x] **Task 10 — Navigation & integration** (AC: tous)
  - [x] 10.1 Ajouter route `/wallet` dans GoRouter (`app.dart`)
  - [x] 10.2 Ajouter icone wallet dans AppBar du Home
  - [x] 10.3 Toggle charge statut serveur au build via NotifierProvider

## Dev Notes

### Architecture existante a reutiliser

**Wallet (deja implemente):**
- `server/crates/domain/src/wallets/model.rs`: `Wallet` (user_id, balance en centimes FCFA), `WalletTransaction` (wallet_id, amount, transaction_type, reference, description)
- `WalletTransactionType` enum inclut deja: `Credit`, `Debit`, `Withdrawal`, `Refund` — le type Withdrawal existe, il suffit de l'utiliser
- `wallets/service.rs`: `credit_driver_for_delivery()` existe (commission 14%), `credit_merchant_for_delivery()` existe
- `wallets/repository.rs`: `find_wallet_by_user()`, `credit_wallet()`, `create_transaction()` existent — ajouter `debit_wallet()` sur le meme pattern

**Delivery assignation (a modifier):**
- `deliveries/repository.rs` ligne ~280: `find_available_driver()` = premier livreur sans livraison active, ORDER BY created_at ASC LIMIT 1
- `find_next_available_driver(excluded)` = idem avec exclusion
- Ces deux fonctions font un JOIN sur `users WHERE role = 'driver'` — ajouter `AND u.is_available = true`

**Offline queue (pattern a reutiliser):**
- `apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart`: JSON file queue avec Completer lock, sync on connectivity
- Reutiliser ce pattern pour le toggle availability offline (ajouter action type `toggle_availability`)

**PaymentProvider trait:**
- `server/crates/payment_provider/`: trait `PaymentProvider` avec `CinetPayAdapter`
- Ajouter methode `transfer()` au trait pour les retraits mobile money (CinetPay a une API Transfer/Payout)
- NE JAMAIS hardcoder CinetPay en dehors de `cinetpay.rs`

### Patterns de code a suivre

**API routes** — Suivre le pattern de `routes/deliveries.rs`:
- Extracteur `AuthUser` pour recuperer driver_id depuis JWT
- Verifier le role (Driver)
- Response wrapper: `{"data": ...}` success, `{"error": {"code": "...", "message": "..."}}` erreur
- snake_case partout (JSON, endpoints, DB)

**Atomic DB operations** — Pattern de `credit_wallet()`:
```sql
UPDATE wallets SET balance = balance + $2, updated_at = NOW() WHERE id = $1 RETURNING *
```
Pour `debit_wallet()`:
```sql
UPDATE wallets SET balance = balance - $2, updated_at = NOW()
WHERE id = $1 AND balance >= $2 RETURNING *
```
Si aucune row retournee = solde insuffisant.

**Flutter state** — Riverpod avec `autoDispose`, `family` pour parameterized. Pattern `AsyncValue.when()` pour loading/error/data.

**Boutons livreur** — minimum 56dp (cibles Tecno Spark 2GB RAM), contraste fort.

### Decisions techniques

1. **is_available sur table users** (pas de table separee): simple, un seul champ boolean. Les livreurs sont deja filtres par `role = 'driver'` dans les requetes. Pas besoin d'une table `driver_profiles` pour le MVP.

2. **Retrait = debit + transfer externe**: Le flow est debit optimiste avec compensation si le transfert echoue. Alternative (hold + confirm) trop complexe pour le MVP. Le risque est faible: si CinetPay est down, on re-credite immediatement.

3. **Pas de montant minimum de retrait pour le MVP**: Simplifier l'experience. Ajouter plus tard si les micro-retraits posent probleme.

4. **Numero mobile money = numero du profil livreur** par defaut (pre-rempli), modifiable dans le formulaire de retrait.

### Ce qu'il ne faut PAS faire

- NE PAS creer un systeme de 4 etats pour le livreur (c'est pour les marchands — FR10). Le livreur a 2 etats: actif / en pause (FR26).
- NE PAS dupliquer la logique de commission dans le withdrawal. La commission est calculee dans `credit_driver_for_delivery()` au moment de la livraison, pas au retrait.
- NE PAS implementer la reconciliation (c'est story 6-3).
- NE PAS implementer le wallet marchand (c'est story 6-1).
- NE PAS ajouter de GPS proximity dans `find_available_driver()` — le MVP utilise FIFO, la proximity viendra plus tard.

### Project Structure Notes

**Fichiers a creer:**
- `server/migrations/YYYYMMDD_add_driver_availability.up.sql`
- `server/migrations/YYYYMMDD_add_driver_availability.down.sql`
- `server/crates/api/src/routes/drivers.rs` (nouveau module routes livreur)
- `server/crates/api/src/routes/wallets.rs` (nouveau module routes wallet)
- `apps/mefali_livreur/lib/features/wallet/wallet_screen.dart`
- `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart`
- `packages/mefali_api_client/lib/providers/driver_availability_provider.dart`
- `packages/mefali_api_client/lib/providers/wallet_provider.dart`

**Fichiers a modifier:**
- `server/crates/domain/src/deliveries/repository.rs` — find_available_driver filtre, set/get availability
- `server/crates/domain/src/deliveries/service.rs` — toggle/get availability service
- `server/crates/domain/src/wallets/repository.rs` — debit_wallet
- `server/crates/domain/src/wallets/service.rs` — request_withdrawal, get_wallet_with_transactions
- `server/crates/payment_provider/src/lib.rs` (ou mod.rs) — trait transfer()
- `server/crates/payment_provider/src/cinetpay.rs` — impl transfer()
- `server/crates/api/src/routes/mod.rs` — enregistrer drivers + wallets routes
- `apps/mefali_livreur/lib/app.dart` — route /wallet
- `apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart` — action toggle_availability
- `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` — availability methods
- `packages/mefali_api_client/lib/mefali_api_client.dart` — export wallet_endpoint

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 5, Story 5.8]
- [Source: _bmad-output/planning-artifacts/prd.md — FR26, FR32, FR33]
- [Source: _bmad-output/planning-artifacts/architecture.md — Wallet schema, PaymentProvider trait, Offline sync pattern]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — WalletCreditFeedback component, Flow 3 Kone]
- [Source: _bmad-output/implementation-artifacts/5-7-client-absent-protocol.md — Previous story patterns]
- [Source: server/crates/domain/src/wallets/ — Existing wallet implementation]
- [Source: server/crates/domain/src/deliveries/repository.rs — find_available_driver logic]

### Previous Story Intelligence (5-7)

- Pattern `credit_driver_for_delivery()` confirme et fonctionne: 14% commission, atomic credit + transaction audit
- `PendingAcceptQueue` etendu avec succes pour `client_absent` et `resolve_absent` — meme pattern pour `toggle_availability`
- 165 domain tests pass, 0 Dart analysis errors — maintenir cette qualite
- url_launcher ajoute comme dependance (deja dans pubspec.yaml)
- Les transitions atomiques de statut fonctionnent bien: pattern `UPDATE ... WHERE status = 'expected' RETURNING *`

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Rust workspace: `cargo check` passes with 1 pre-existing warning (dead_code in deliveries.rs)
- Dart analysis: 0 errors, only info-level hints across mefali_api_client + mefali_livreur
- 201 total Rust tests pass (168 domain, 12 common, 11 payment_provider, 10 notification)
- 6 pre-existing failures in api merchants integration tests (not related to this story)

### Completion Notes List

- Task 3.3: Reutilise `PaymentProvider::initiate_withdrawal()` existant au lieu de creer nouvelle methode `transfer()` — le trait avait deja l'abstraction necessaire
- CinetPay withdrawal: implementee via `POST {base_url}/transfer` avec conversion centimes -> FCFA
- Wallet debit: atomic SQL `WHERE balance >= amount` retourne erreur BadRequest si solde insuffisant
- Withdrawal compensation: si le transfert externe echoue, le wallet est re-credite avec retry 3 tentatives
- Driver availability: `NotifierProvider.autoDispose` Riverpod 3.x pattern (pas StateNotifier deprecated), optimistic toggle avec rollback
- Offline toggle: PendingAcceptQueue etendu avec action `toggle_availability`, sync au retour de connexion, collapse des toggles multiples

### Code Review Fixes (2026-03-20)

- [C1] wallets/service.rs: debit + create_transaction wraps dans une DB transaction (atomicite ledger)
- [C2] pending_accept_queue.dart: collapse toggle_availability entries (garde seulement le dernier etat desire)
- [H1] wallet_screen.dart: gestion erreurs differenciee (400/409 → Dialog, reseau → SnackBar orange)
- [H2] wallets/service.rs: re-credit apres echec transfert avec retry 3 tentatives
- [M1] wallet_screen.dart: validation telephone format CI (regex +225 + 10 digits)
- [M2] home_screen.dart: SnackBar feedback quand toggle mis en file d'attente offline
- [M3] home_screen.dart: etat erreur affiche bouton refresh au lieu de Switch false
- [M4] driver_availability_provider.dart: NotifierProvider.autoDispose (convention projet)

### File List

**Fichiers crees:**
- `server/migrations/20260320000005_add_driver_availability.up.sql`
- `server/migrations/20260320000005_add_driver_availability.down.sql`
- `server/crates/api/src/routes/drivers.rs`
- `server/crates/api/src/routes/wallets.rs`
- `apps/mefali_livreur/lib/features/wallet/wallet_screen.dart`
- `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart`
- `packages/mefali_api_client/lib/providers/driver_availability_provider.dart`
- `packages/mefali_api_client/lib/providers/wallet_provider.dart`

**Fichiers modifies:**
- `server/crates/domain/src/deliveries/repository.rs` — set/get availability, filtre is_available dans find_available_driver/find_next_available_driver
- `server/crates/domain/src/deliveries/service.rs` — toggle_driver_availability, get_driver_availability
- `server/crates/domain/src/wallets/repository.rs` — debit_wallet, get_transactions
- `server/crates/domain/src/wallets/service.rs` — request_withdrawal, get_wallet_with_transactions
- `server/crates/domain/src/wallets/model.rs` — tests unitaires serde
- `server/crates/payment_provider/src/cinetpay.rs` — impl initiate_withdrawal via CinetPay Transfer
- `server/crates/payment_provider/src/mock.rs` — tests withdrawal success/failure
- `server/crates/api/src/routes/mod.rs` — enregistrement routes /drivers et /wallets
- `apps/mefali_livreur/lib/app.dart` — route /wallet, import WalletScreen
- `apps/mefali_livreur/lib/features/home/home_screen.dart` — toggle disponibilite, icone wallet
- `apps/mefali_livreur/lib/features/delivery/pending_accept_queue.dart` — action toggle_availability
- `packages/mefali_api_client/lib/endpoints/delivery_endpoint.dart` — setAvailability, getAvailability
- `packages/mefali_api_client/lib/mefali_api_client.dart` — exports wallet_endpoint + providers
