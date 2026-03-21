# Story 6.2: Merchant Withdrawal

Status: done

## Story

As a marchand,
I want to withdraw my wallet balance to mobile money,
so that I can access my earnings anytime.

## Acceptance Criteria

1. **Given** positive wallet balance **When** marchand appuie sur "Retirer" **Then** formulaire de retrait affiche avec solde actuel
2. **Given** montant valide et numero mobile money **When** marchand confirme le retrait **Then** retrait traite via PaymentProvider **And** solde wallet debite immediatement **And** transaction type=withdrawal dans l'historique
3. **Given** retrait initie **When** PaymentProvider echoue **Then** wallet re-credite (compensation) **And** message d'erreur affiche **And** marchand peut reessayer
4. **Given** solde insuffisant **When** marchand tente un retrait **Then** bouton desactive ou erreur "Solde insuffisant"
5. **Given** retrait reussi **When** fonds envoyes **Then** notification push "Retrait effectue" avec montant et reference

## Tasks / Subtasks

- [x] Task 1: Etendre l'autorisation backend pour les marchands (AC: #1, #2)
  - [x] 1.1 Ajouter `UserRole::Merchant` a la route `POST /wallets/withdraw` dans `server/crates/api/src/routes/wallets.rs`
  - [x] 1.2 Verifier que `request_withdrawal()` dans `wallets/service.rs` fonctionne pour un user_id marchand (le service est deja generique, pas de changement attendu)

- [x] Task 2: UI de retrait dans l'app B2B (AC: #1, #2, #4)
  - [x] 2.1 Ajouter un bouton "Retirer" sur la `_BalanceCard` du `wallet_screen.dart` existant
  - [x] 2.2 Creer un bottom sheet ou dialog de retrait avec: champ montant, champ numero telephone, bouton confirmer
  - [x] 2.3 Afficher le solde disponible dans le formulaire
  - [x] 2.4 Desactiver le bouton si solde == 0
  - [x] 2.5 Validation: montant > 0 et montant <= solde, numero telephone non vide

- [x] Task 3: Appel API de retrait et gestion des etats (AC: #2, #3)
  - [x] 3.1 Utiliser `WalletEndpoint.withdraw(amount, phoneNumber)` deja existant dans `mefali_api_client`
  - [x] 3.2 Afficher un loading indicator pendant le traitement
  - [x] 3.3 En cas de succes: fermer le formulaire, invalider `walletProvider` pour rafraichir le solde, afficher un snackbar succes
  - [x] 3.4 En cas d'erreur: afficher le message d'erreur, permettre de reessayer

- [x] Task 4: Notification push retrait (AC: #5)
  - [x] 4.1 Ajouter `notify_withdrawal_completed()` dans `api/src/routes/wallets.rs` — pattern identique a `notify_merchant_wallet_credited()`
  - [x] 4.2 Titre: "Retrait effectue", Body: "-{amount_fcfa} FCFA vers {phone}", event: `wallet.withdrawal`
  - [x] 4.3 Best-effort: echec notification ne bloque PAS le retrait

- [x] Task 5: Tests (AC: #1-5)
  - [x] 5.1 Test unitaire Rust: `test_merchant_withdrawal_authorized` — verifier que le role Merchant est accepte
  - [x] 5.2 Test unitaire Rust: `test_withdrawal_transaction_format` — verifier format transaction retrait
  - [x] 5.3 Verification: `cargo build --workspace` et `dart analyze apps/mefali_b2b` sans erreur

## Dev Notes

### Architecture: Reutiliser, NE PAS Reimplementer

Le flux de retrait est deja completement implemente pour les livreurs (story 5-8). Le backend est generique (`request_withdrawal` prend un `user_id`, pas un `driver_id`). Le travail principal est:

1. **Backend**: Changer UNE ligne d'autorisation dans la route API
2. **Frontend**: Ajouter l'UI de retrait dans le wallet screen B2B existant
3. **Notification**: Ajouter une notification push (pattern copie de l'existant)

### Code Existant a Reutiliser (NE PAS recoder)

| Composant | Fichier | Fonction |
|-----------|---------|----------|
| Service retrait | `server/crates/domain/src/wallets/service.rs` | `request_withdrawal(pool, user_id, amount, phone, provider)` |
| Debit atomique | `server/crates/domain/src/wallets/repository.rs` | `debit_wallet(pool, wallet_id, amount)` — check balance atomique |
| Compensation | `server/crates/domain/src/wallets/service.rs` | Pattern re-credit 3 tentatives si PaymentProvider echoue |
| Route API | `server/crates/api/src/routes/wallets.rs` | `POST /wallets/withdraw` — body: `{amount, phone_number}` |
| Client API Flutter | `packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart` | `withdraw(amount, phoneNumber)` |
| Provider Riverpod | `packages/mefali_api_client/lib/providers/wallet_provider.dart` | `walletProvider` (autoDispose) |
| PaymentProvider trait | `server/crates/payment_provider/src/provider.rs` | `initiate_withdrawal(WithdrawalRequest)` |
| CinetPay adapter | `server/crates/payment_provider/src/cinetpay.rs` | Implementation concrete du retrait |
| Mock provider | `server/crates/payment_provider/src/mock.rs` | `MockPaymentProvider::new()`, `::failing()` |

### Changement Backend Precis

Dans `server/crates/api/src/routes/wallets.rs`, la fonction `withdraw()` a une verification de role:
```rust
require_role(&auth, &[UserRole::Driver])?;
```
Changer en:
```rust
require_role(&auth, &[UserRole::Driver, UserRole::Merchant])?;
```

C'est le SEUL changement backend requis pour la logique metier. Le service `request_withdrawal()` est generique.

### UI Frontend: Wallet Screen B2B

Fichier existant: `apps/mefali_b2b/lib/features/wallet/wallet_screen.dart`

Le screen affiche deja:
- `_BalanceCard` avec le solde
- Liste des transactions avec `_TransactionTile`
- Pull-to-refresh via `ref.invalidate(walletProvider)`
- Empty state

**A ajouter:**
- Bouton "Retirer" dans `_BalanceCard` (sous le solde, `ElevatedButton` ou `FilledButton`)
- Bottom sheet de retrait: `showModalBottomSheet` avec `TextFormField` montant + telephone + bouton confirmer
- Formatage montant: centimes (i64) pour l'API, FCFA affiche (`amount ~/ 100`)
- Numero telephone: pre-remplir avec le telephone du marchand si disponible

### Patterns a Respecter

- **Montants en centimes** (i64): 1 FCFA = 100 centimes. L'API attend des centimes.
- **Formatage FCFA**: `NumberFormat('#,###', 'fr_FR')` avec separateur espace + " FCFA"
- **snake_case partout**: JSON, endpoints, DB
- **Riverpod autoDispose**: toujours utiliser `ref.invalidate(walletProvider)` pour refresh
- **PaymentProvider trait**: JAMAIS reference directe a CinetPay dans le code
- **Best-effort notifications**: `let _ = notify...().await;`
- **Compensation pattern**: debit wallet d'abord, appel externe ensuite, re-credit si echec (3 tentatives max)
- **Devises**: currency = "XOF" (FCFA zone UEMOA)

### Erreurs Connues du Retrait Livreur (Story 5-8)

Le pattern de compensation (re-credit apres echec PaymentProvider) a un edge case:
- Si les 3 tentatives de re-credit echouent, le wallet est debite mais le paiement n'est pas parti.
- Log CRITICAL + intervention manuelle requise.
- Ce pattern est deja implemente, ne PAS le modifier.

### Formats de Reference

- Transaction retrait: `withdrawal:{uuid}` (genere dans `request_withdrawal`)
- Description: `"Retrait vers {phone_number}"`

### Project Structure Notes

- Le wallet screen B2B est dans `apps/mefali_b2b/lib/features/wallet/` — ajouter le formulaire de retrait dans le meme dossier ou directement dans `wallet_screen.dart`
- NE PAS creer de nouveau endpoint API, le `POST /wallets/withdraw` existant suffit
- NE PAS creer de nouveau provider Riverpod, le `walletProvider` existant couvre le refresh

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 6, Story 6.2]
- [Source: _bmad-output/planning-artifacts/architecture.md — Wallet Architecture, PaymentProvider Pattern]
- [Source: _bmad-output/planning-artifacts/prd.md — FR35: Marchand peut retirer son solde wallet vers mobile money]
- [Source: _bmad-output/planning-artifacts/ux-spec.md — UX-DR6: WalletCreditFeedback, Micro-Emotion: Autonomy]
- [Source: _bmad-output/implementation-artifacts/6-1-merchant-wallet-and-escrow-release.md — Previous story patterns]
- [Source: server/crates/domain/src/wallets/service.rs — request_withdrawal()]
- [Source: server/crates/api/src/routes/wallets.rs — withdraw() route, role check]
- [Source: apps/mefali_b2b/lib/features/wallet/wallet_screen.dart — Merchant wallet UI]
- [Source: packages/mefali_api_client/lib/endpoints/wallet_endpoint.dart — withdraw() client]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- AC #1: Bouton "Retirer" dans _BalanceCard avec solde affiche. Desactive si balance == 0.
- AC #2: Bottom sheet avec formulaire (montant FCFA + numero telephone). Appel via WalletEndpoint.withdraw(). Wallet debite via request_withdrawal() existant. Transaction type=withdrawal creee.
- AC #3: Compensation deja implementee dans wallets/service.rs (re-credit 3 tentatives). Erreur API affichee dans le bottom sheet, marchand peut reessayer.
- AC #4: Bouton desactive si solde == 0. Validation front: montant > 0 et montant <= solde_fcfa. Backend: balance check atomique (rows_affected == 0 → BadRequest).
- AC #5: Notification push "Retrait effectue" avec "-{amount} FCFA vers {phone}" et event wallet.withdrawal. Best-effort (echec ne bloque pas).
- Backend: 1 seule ligne de role changee (UserRole::Driver → [Driver, Merchant]). Ajout notification fn dans wallets.rs.
- Frontend: _BalanceCard etendue avec bouton + callback. _WithdrawSheet StatefulWidget avec Form, validation, loading, error handling, snackbar succes.
- Telephone pre-rempli depuis authProvider.user.phone.
- Tests: 2 nouveaux tests Rust (role_guard + model). cargo build OK, dart analyze 0 issues. 6 echecs pre-existants (integration merchants, non lies).

### Change Log

- 2026-03-20: Implementation complete story 6-2 merchant withdrawal
- 2026-03-20: Code review (adversarial) — 2 HIGH, 2 MEDIUM, 1 LOW trouvees. Fixes appliques:
  - H1/M2: Revert scope-creep refactorisation dans service.rs (inline SQL → repository layer restaure)
  - H2: Extraction message erreur API reel via DioException dans wallet_screen.dart
  - M1: Notification retrait en fire-and-forget (actix_web::rt::spawn) pour ne pas bloquer la reponse HTTP
  - Ajout re-export DioException dans mefali_api_client barrel

### File List

- server/crates/api/src/routes/wallets.rs (modified — role authorization + notification + spawn async)
- server/crates/api/src/middleware/role_guard.rs (modified — added test_merchant_withdrawal_authorized)
- server/crates/domain/src/wallets/model.rs (modified — added test_withdrawal_transaction_format)
- apps/mefali_b2b/lib/features/wallet/wallet_screen.dart (modified — withdraw button, bottom sheet, API integration, DioException error extraction)
- packages/mefali_api_client/lib/mefali_api_client.dart (modified — re-export DioException)
