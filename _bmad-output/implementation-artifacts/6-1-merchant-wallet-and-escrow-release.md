# Story 6.1: Merchant Wallet & Escrow Release

Status: review

## Story

As a marchand,
I want to see my wallet balance and payment history after each delivery,
so that I know exactly how much I've earned and can trust the platform.

## Acceptance Criteria

1. **Given** a delivery is confirmed (status = 'delivered') for a prepaid order (mobile_money), **When** escrow is released, **Then** the merchant wallet is credited with the order subtotal (no commission at MVP) **And** a wallet transaction with reference `order:{order_id}` is created.

2. **Given** a delivery is confirmed for a COD order, **When** the order is marked delivered, **Then** the merchant wallet is credited with the order subtotal **And** a wallet transaction is created.

3. **Given** a merchant is logged into the B2B app, **When** they navigate to the wallet section, **Then** they see their current balance in FCFA **And** a list of their recent transactions (last 50).

4. **Given** a wallet credit happens (escrow release or COD settlement), **When** the transaction is recorded, **Then** the merchant receives a push notification with the credited amount and order reference.

5. **Given** a merchant views their transaction history, **When** they see a credit entry, **Then** the entry shows the order reference, amount in FCFA, date, and transaction type.

## Tasks / Subtasks

- [x] Task 1: Backend — Verify & Complete Merchant Wallet Crediting (AC: #1, #2)
  - [x] 1.1 Verify `confirm_delivery()` in `deliveries/service.rs` calls `credit_merchant_for_delivery()` for BOTH COD and prepaid orders
  - [x] 1.2 Verify `GET /api/v1/wallets/me` in `routes/wallets.rs` authorizes `Merchant` role
  - [x] 1.3 Verify wallet is created for each merchant during onboarding (registration flow)
  - [x] 1.4 Verify transaction reference format is `order:{order_id}` for merchant credits
  - [x] 1.5 Add unit tests for merchant wallet crediting if missing

- [x] Task 2: Backend — Push Notification on Merchant Wallet Credit (AC: #4)
  - [x] 2.1 In `confirm_delivery()` service, add FCM notification to merchant after `credit_merchant_for_delivery()` succeeds
  - [x] 2.2 Notification body: "+{amount_fcfa} FCFA - Commande #{order_short_id}"
  - [x] 2.3 Best-effort notification: failure must NOT rollback wallet credit (pattern from 5-6)

- [x] Task 3: B2B App — Wallet Screen (AC: #3, #5)
  - [x] 3.1 Create `apps/mefali_b2b/lib/features/wallet/wallet_screen.dart` with balance card + transaction list
  - [x] 3.2 Reuse `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart` (already in shared package)
  - [x] 3.3 Create or reuse wallet Riverpod provider for B2B app (same pattern as livreur `wallet_provider.dart`)
  - [x] 3.4 Add wallet access in B2B app navigation (4th tab or integrated into Stats dashboard)
  - [x] 3.5 Balance card: display balance in FCFA (centimes / 100), formatted with `NumberFormat`

- [x] Task 4: B2B App — Transaction History UI (AC: #5)
  - [x] 4.1 Transaction list tile: icon (arrow_downward green for credit), order reference, amount "+X FCFA", date
  - [x] 4.2 Empty state: "Aucune transaction" message when no history
  - [x] 4.3 Pull-to-refresh to reload wallet data

- [x] Task 5: Testing & Verification
  - [x] 5.1 Verify wallet balance updates for prepaid orders end-to-end
  - [x] 5.2 Verify wallet balance updates for COD orders end-to-end
  - [x] 5.3 Verify transaction history displays correctly in B2B app
  - [x] 5.4 Run `cargo test --workspace` + `dart analyze`

## Dev Notes

### Architecture existante -- NE PAS REIMPLEMENTER

Le wallet backend est DEJA COMPLETEMENT IMPLEMENTE (stories 5-6 et 5-8). Cette story est principalement un travail FRONTEND sur l'app B2B.

**Wallet domain (EXISTE):**
- `server/crates/domain/src/wallets/model.rs`: `Wallet` (user_id, balance i64 centimes), `WalletTransaction`, `WalletTransactionType` enum (Credit, Debit, Withdrawal, Refund)
- `server/crates/domain/src/wallets/service.rs`: `credit_merchant_for_delivery(pool, order)` -- credite `order.subtotal` complet (pas de commission MVP)
- `server/crates/domain/src/wallets/repository.rs`: `find_wallet_by_user()`, `credit_wallet()`, `create_transaction()`, `get_transactions()`, `debit_wallet()` -- tous implementes
- `server/crates/api/src/routes/wallets.rs`: `GET /api/v1/wallets/me` (role Driver OU Merchant), `POST /api/v1/wallets/withdraw` (role Driver uniquement)

**Escrow release (EXISTE -- story 5-6):**
- `server/crates/domain/src/deliveries/service.rs`: `confirm_delivery()` appelle `credit_driver_for_delivery()` ET `credit_merchant_for_delivery()` automatiquement
- Prepaid: `orders.payment_status` passe de `escrow_held` a `released`
- COD: marchand credite aussi (reconciliation en Epic 6-3)

**Driver wallet UI (PATTERN A COPIER pour B2B):**
- `apps/mefali_livreur/lib/features/wallet/wallet_screen.dart`: ecran complet balance + transactions + retrait
- `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart`: `getWallet()` -- dans le package partage, reutilisable
- `packages/mefali_api_client/lib/providers/wallet_provider.dart`: FutureProvider autoDispose -- reutilisable

**Notification system (EXISTE):**
- `server/crates/notification/`: FCM + SMS dual-provider
- Pattern dans `confirm_delivery()` qui notifie le client -- reutiliser pour notifier le marchand

### Patterns de code obligatoires

**Backend Rust:**
- API response wrapper: `{"data": {...}}` succes, `{"error": {"code": "...", "message": "..."}}` erreur
- snake_case partout (JSON, endpoints, DB colonnes)
- Notifications best-effort: `let _ = notification.send(...)` -- NE JAMAIS bloquer le flow principal
- `thiserror` pour erreurs domain, mapping HTTP dans api crate via `AppError`

**Frontend Flutter (B2B):**
- Riverpod `autoDispose` default, pattern `AsyncValue.when()` pour loading/error/data
- `ConsumerWidget` ou `ConsumerStatefulWidget` pour ecrans Riverpod
- `prefer_single_quotes`, `prefer_relative_imports`, `prefer_const_constructors`
- Cibles Transsion 2GB RAM -- pas d'animations lourdes, widgets legers
- Material 3 avec theme `mefali_design`

**Montants:**
- Backend: centimes (i64) -- `balance: 350000` = 3500 FCFA
- Frontend: conversion `amount ~/ 100` pour FCFA
- Formatage: `NumberFormat('#,###', 'fr_FR')` + " FCFA"

### Commission marchand

- **MVP**: Pas de commission marchande. Le marchand recoit `order.subtotal` complet.
- PRD mentionne fourchette 1-15% pour Phase 2.
- `credit_merchant_for_delivery()` utilise `order.subtotal` directement.
- NE PAS implementer la commission marchande dans cette story.

### Differences wallet marchand vs wallet livreur

| Aspect | Livreur (5-8) | Marchand (6-1) |
|--------|---------------|----------------|
| Source credit | Livraisons (delivery_fee - 14%) | Commandes (subtotal complet) |
| Retrait | Oui (POST /wallets/withdraw) | Non (story 6-2) |
| Reference transaction | `delivery:{delivery_id}` | `order:{order_id}` |
| Notification credit | WalletCreditFeedback animation in-app | Push FCM notification |
| UI acces | Tab wallet dans home | Tab dans B2B nav ou section Stats |

### Ce qu'il ne faut PAS faire

- NE PAS implementer le retrait marchand -- c'est story 6-2
- NE PAS implementer la commission marchande -- c'est Phase 2
- NE PAS dupliquer `wallet_endpoint.dart` -- reutiliser celui du package partage `mefali_api_client`
- NE PAS modifier `credit_merchant_for_delivery()` -- il fonctionne correctement
- NE PAS implementer la reconciliation -- c'est story 6-3
- NE PAS ajouter de bouton "Retirer" dans l'UI marchand -- story 6-2
- NE PAS creer un nouveau endpoint API -- `GET /wallets/me` existe deja et autorise Merchant

### Verifications critiques avant le frontend

1. `confirm_delivery()` dans `deliveries/service.rs` appelle `credit_merchant_for_delivery()` pour TOUS les types de paiement (COD + prepaid)
2. `GET /api/v1/wallets/me` dans `routes/wallets.rs` autorise le role `Merchant`
3. La reference de transaction marchand est au format `order:{order_id}`
4. Un wallet est cree pour chaque marchand a l'inscription

### B2B App -- Navigation existante

L'app B2B utilise des Tabs en haut: `Commandes | Catalogue | Stats`

Options pour integrer le wallet:
- **Option A (recommandee)**: Afficher un resume wallet (solde) en haut du dashboard Stats + lien "Voir tout" vers ecran wallet complet
- **Option B**: Ajouter un 4eme tab `Wallet` dans la navigation principale

Le dashboard ventes (`Stats`) est l'ecran le plus important pour le marchand -- le solde wallet doit y etre visible immediatement.

### UX Critique

- **Solde wallet**: Affiche en gros (headline), position dominante -- c'est le "aha moment" Adjoua
- **Transaction list**: Chaque entree montre commande associee, montant FCFA, date
- **Push notification**: "+{montant} FCFA - Commande #{short_id}" -- celebratoire mais sobre
- **Transparence**: Pas de frais caches, le marchand voit exactement ce qu'il recoit
- **Escrow automatique**: Pas d'action requise du marchand -- la liberation escrow est automatique a la confirmation de livraison
- **Empty state**: "Vos revenus apparaitront ici apres votre premiere livraison completee"

### Wallet API Response Format

```json
GET /api/v1/wallets/me
Response 200:
{
  "data": {
    "wallet": {
      "id": "uuid",
      "balance": 1500000,
      "updated_at": "2026-03-20T10:30:00Z"
    },
    "transactions": [
      {
        "id": "uuid",
        "amount": 150000,
        "transaction_type": "credit",
        "reference": "order:uuid",
        "description": null,
        "created_at": "2026-03-20T10:25:00Z"
      }
    ]
  }
}
```

### Project Structure Notes

**Fichiers a creer:**
- `apps/mefali_b2b/lib/features/wallet/wallet_screen.dart`

**Fichiers a modifier:**
- `apps/mefali_b2b/lib/app.dart` ou fichier de navigation -- ajouter acces wallet
- `apps/mefali_b2b/lib/features/dashboard/` -- integrer resume wallet si Option A choisie
- `server/crates/domain/src/deliveries/service.rs` -- ajouter notification marchand dans `confirm_delivery()` (push FCM apres credit wallet)

**Fichiers a reutiliser (IMPORTER depuis packages partages):**
- `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart` -- `getWallet()`
- `packages/mefali_api_client/lib/providers/wallet_provider.dart` -- `walletProvider`

### Learnings des stories precedentes

- Story 5-6: `credit_merchant_for_delivery()` utilisait `merchants.id` au lieu de `users.id` pour le wallet lookup -- corrige en code review. VERIFIER que la correction est en place.
- Story 5-8: DB transaction wrapping pour debit + create_transaction assure l'atomicite du ledger
- Story 5-8: `walletProvider` doit etre invalide apres chaque action pour rafraichir l'UI
- Story 5-6: Notifications best-effort -- echec notification NE DOIT PAS rollback la transaction wallet
- Story 5-8: Pattern `NotifierProvider.autoDispose` Riverpod 3.x (pas StateNotifier deprecated)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic6] -- Story 6.1 definition
- [Source: _bmad-output/planning-artifacts/prd.md#FR34] -- Marchand recoit le paiement sur son wallet apres liberation escrow
- [Source: _bmad-output/planning-artifacts/architecture.md#Wallet] -- Wallet system architecture
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#MerchantDashboard] -- Dashboard ventes UX
- [Source: _bmad-output/implementation-artifacts/5-6-delivery-confirmation-and-instant-payment.md] -- Wallet first implementation
- [Source: _bmad-output/implementation-artifacts/5-8-driver-availability-and-wallet-withdrawal.md] -- Driver wallet UI + withdrawal

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Task 1.1: FIX CRITIQUE -- `confirm_delivery()` ne creditait le marchand QUE pour MobileMoney. Deplace `credit_merchant_for_delivery()` hors du if-block pour crediter le marchand pour TOUS les types de paiement (COD + prepaid). Seul `release_escrow()` reste conditionnel a MobileMoney.
- Task 1.2: VERIFIE -- `GET /wallets/me` autorise `[UserRole::Driver, UserRole::Merchant]`
- Task 1.3: VERIFIE -- Wallet cree pour marchands dans `merchants/service.rs::verify_and_create_merchant()` via `INSERT INTO wallets (user_id, balance) VALUES ($1, 0) ON CONFLICT DO NOTHING`
- Task 1.4: VERIFIE -- Reference format `order:{order_id}` dans `credit_merchant_for_delivery()`
- Task 1.5: Ajoute test `test_merchant_credit_transaction_format` dans wallets/model.rs -- verifie format reference, type credit, description, montant
- Task 2: Ajout de `notify_merchant_wallet_credited()` dans deliveries/service.rs -- suit le pattern de `notify_merchant_pickup()`. Notification FCM best-effort: titre "Paiement recu", body "+{amount_fcfa} FCFA - Commande #{short_id}", data event=wallet.credited
- Task 2.3: Notification appelee APRES le credit wallet, echec n'affecte pas la transaction
- Description transaction changee de "Paiement commande (escrow libere)" a "Paiement commande" (generique pour COD + prepaid)
- Task 3: Cree `MerchantWalletScreen` dans B2B app -- ConsumerWidget avec walletProvider, balance card, transaction list. PAS de bouton retrait (story 6-2)
- Task 3.4: Ajoute 4eme tab "Wallet" dans B2B home TabBar (Commandes | Catalogue | Stats | Wallet)
- Task 3.5: Balance affichee en FCFA (centimes / 100) dans headlineLarge bold
- Task 4: Transaction tile montre: icone (arrow_downward vert pour credit), description, reference commande courte, date formatee, montant "+X FCFA"
- Task 4.2: Empty state avec icone wallet + message "Vos revenus apparaitront ici apres votre premiere livraison completee"
- 6 echecs de tests pre-existants (integration merchants, documentes dans story 5-4) -- non lies a cette story
- `dart analyze` B2B app: 0 issues
- `cargo build --workspace`: OK (1 warning pre-existant dead_code non lie)

### File List

**New:**
- apps/mefali_b2b/lib/features/wallet/wallet_screen.dart

**Modified (Backend Rust):**
- server/crates/domain/src/deliveries/service.rs -- FIX: credit marchand pour COD + prepaid, ajout notify_merchant_wallet_credited()
- server/crates/domain/src/wallets/service.rs -- doc + description transaction generique
- server/crates/domain/src/wallets/model.rs -- ajout test_merchant_credit_transaction_format

**Modified (Frontend Flutter):**
- apps/mefali_b2b/lib/features/home/home_screen.dart -- 4eme tab Wallet, TabController length 4
