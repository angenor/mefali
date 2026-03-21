# Story 8.4: Account Management

Status: done

## Story

As an admin,
I want to list, search, suspend, deactivate and reactivate user accounts,
so that I handle violations and maintain platform integrity.

## Acceptance Criteria

1. **Given** admin logged in **When** navigating to Comptes tab **Then** paginated list of ALL users (all roles) with columns: name, phone, role, status, city, created_at **And** search by name or phone **And** filter by role and status
2. **Given** user list **When** admin taps a user row **Then** detail screen shows: full profile, city, role, status, referral_code, created_at, updated_at **And** counts: total orders, completion rate, disputes filed, average rating
3. **Given** active user account **When** admin suspends **Then** user status becomes `suspended` **And** user's active JWT refresh tokens are revoked **And** action is logged with admin_id, timestamp, reason
4. **Given** active user account **When** admin deactivates **Then** user status becomes `deactivated` **And** active orders are NOT cancelled (they complete normally) **And** user's refresh tokens are revoked **And** action logged
5. **Given** suspended user **When** admin reactivates **Then** status becomes `active` **And** action logged
6. **Given** any status change action **Then** audit log entry includes: admin_id, target_user_id, old_status, new_status, reason (free text), timestamp (NFR13)
7. **Given** admin attempts to deactivate another admin **Then** action is forbidden (403) — admins cannot deactivate admins

## Tasks / Subtasks

### Backend (Rust)

- [x] Task 1: Add admin user list endpoint (AC: #1)
  - [x] 1.1 Add `find_all_paginated(pool, role_filter, status_filter, search, page, per_page)` in `users/repository.rs`
  - [x] 1.2 Add `count_all_filtered(pool, role_filter, status_filter, search)` in `users/repository.rs`
  - [x] 1.3 Add `AdminUserListItem` struct in `users/model.rs` (id, phone, name, role, status, city_name, created_at)
  - [x] 1.4 Add `AdminUserListParams` query params struct in `users/model.rs`
  - [x] 1.5 Add `list_users` handler in `routes/admin.rs`
  - [x] 1.6 Register `GET /api/v1/admin/users` in `routes/mod.rs`

- [x] Task 2: Add admin user detail endpoint (AC: #2)
  - [x] 2.1 Add `find_detail_by_id(pool, user_id)` in `users/repository.rs` — JOIN with aggregates (orders count, disputes count, avg rating)
  - [x] 2.2 Add `AdminUserDetail` struct in `users/model.rs` (all User fields + city_name + stats)
  - [x] 2.3 Add `get_user_detail` handler in `routes/admin.rs`
  - [x] 2.4 Register `GET /api/v1/admin/users/{user_id}` in `routes/mod.rs`

- [x] Task 3: Add admin update user status endpoint (AC: #3, #4, #5, #6, #7)
  - [x] 3.1 Create `admin_audit_logs` table migration (admin_id, target_user_id, action, old_status, new_status, reason, created_at)
  - [x] 3.2 Add `insert_audit_log(pool, log)` in `users/repository.rs`
  - [x] 3.3 Add `UpdateUserStatusRequest` struct (new_status, reason) in `users/model.rs`
  - [x] 3.4 Add `admin_update_user_status(pool, admin_id, target_user_id, new_status, reason)` in `users/service.rs` — validates transitions, blocks admin-on-admin, revokes refresh tokens, inserts audit log
  - [x] 3.5 Add `update_user_status_admin` handler in `routes/admin.rs`
  - [x] 3.6 Register `PATCH /api/v1/admin/users/{user_id}/status` in `routes/mod.rs`
  - [x] 3.7 Revoke refresh tokens: add `revoke_all_for_user(pool, user_id)` in `users/refresh_token_repository.rs`

- [x] Task 4: Backend tests (AC: all)
  - [x] 4.1 Test list_users 200 with data + pagination meta
  - [x] 4.2 Test list_users 200 empty
  - [x] 4.3 Test list_users with role filter
  - [x] 4.4 Test list_users with search query
  - [x] 4.5 Test get_user_detail 200
  - [x] 4.6 Test get_user_detail 404
  - [x] 4.7 Test update_user_status suspend 200
  - [x] 4.8 Test update_user_status deactivate 200
  - [x] 4.9 Test update_user_status reactivate 200
  - [x] 4.10 Test update_user_status admin-on-admin 403
  - [x] 4.11 Test all endpoints 403 wrong role
  - [x] 4.12 Test all endpoints 401 no token

### Frontend (Flutter)

- [x] Task 5: Add admin user models and API client (AC: #1, #2)
  - [x] 5.1 Create `AdminUserListItem` model in `packages/mefali_core/lib/models/admin_user.dart`
  - [x] 5.2 Create `AdminUserDetail` model in same file
  - [x] 5.3 Add `listUsers()`, `getUserDetail()`, `updateUserStatus()` methods to `AdminEndpoint`
  - [x] 5.4 Create `admin_accounts_provider.dart` with `adminUsersProvider` (FutureProvider.autoDispose.family) and `adminUserDetailProvider`
  - [x] 5.5 Export new files in `mefali_api_client.dart` and `mefali_core.dart`

- [x] Task 6: Add Account List Screen (AC: #1)
  - [x] 6.1 Create `apps/mefali_admin/lib/features/accounts/account_list_screen.dart`
  - [x] 6.2 Search bar (name/phone) with debounce 500ms
  - [x] 6.3 Role filter chips (client, merchant, driver, agent)
  - [x] 6.4 Status filter chips (active, pending_kyc, suspended, deactivated)
  - [x] 6.5 DataTable (>768px) / ListView (mobile) responsive
  - [x] 6.6 Pagination controls
  - [x] 6.7 Tap row → Navigator.push to detail screen

- [x] Task 7: Add Account Detail Screen (AC: #2, #3, #4, #5)
  - [x] 7.1 Create `apps/mefali_admin/lib/features/accounts/account_detail_screen.dart`
  - [x] 7.2 Profile info card (name, phone, role, status badge, city, referral_code, dates)
  - [x] 7.3 Stats cards row (total orders, completion rate, disputes, avg rating)
  - [x] 7.4 Status action buttons: Suspendre / Desactiver / Reactiver (contextual)
  - [x] 7.5 Confirmation dialog with reason text field before status change
  - [x] 7.6 On status change success → invalidate both list and detail providers

- [x] Task 8: Integrate into AdminShellScreen (AC: #1)
  - [x] 8.1 Add 7th destination "Comptes" (Icons.people) at index 6 in NavigationRail/NavigationBar
  - [x] 8.2 Wire index 6 to AccountListScreen

- [x] Task 9: Flutter tests
  - [x] 9.1 Widget test: account list with data renders table
  - [x] 9.2 Widget test: account list empty state
  - [x] 9.3 Widget test: account detail renders profile + stats

## Dev Notes

### Architecture Compliance

**Backend pattern (identique aux stories 8.1–8.3) :**
- Guard: `require_role(&auth, &[UserRole::Admin])?;`
- Response: `HttpResponse::Ok().json(ApiResponse::new(data))` / `ApiResponse::paginated(data, meta)`
- Parallel queries: `tokio::try_join!` pour les agrégats du detail
- Tests: `#[sqlx::test(migrations = "../../migrations")]` + `test_helpers::test_app(pool)`
- Async spawn: `tokio::spawn` (PAS `actix_web::rt::spawn`)

**Frontend pattern (identique aux stories 8.1–8.3) :**
- Modeles: `@JsonSerializable(fieldRename: FieldRename.snake)` + `part 'xxx.g.dart'`
- Endpoint: etendre `AdminEndpoint` existant (NE PAS creer de nouveau endpoint class)
- Provider avec params: `FutureProvider.autoDispose.family<List<AdminUserListItem>, AdminUserListParams>`
- Provider detail: `FutureProvider.autoDispose.family<AdminUserDetail, String>`
- UI async: `asyncValue.when(data:, loading:, error:)` — skeleton shimmer pour loading, jamais spinner seul
- Navigation: `Navigator.push` pour aller au detail (PAS GoRouter)
- Refresh: `ref.invalidate(provider)` apres mutation

### Fichiers existants a modifier

| Fichier | Modification |
|---------|-------------|
| `server/crates/domain/src/users/model.rs` | Ajouter `AdminUserListItem`, `AdminUserDetail`, `AdminUserListParams`, `UpdateUserStatusRequest` |
| `server/crates/domain/src/users/repository.rs` | Ajouter `find_all_paginated`, `count_all_filtered`, `find_detail_by_id`, `insert_audit_log` |
| `server/crates/domain/src/users/service.rs` | Ajouter `admin_update_user_status` (validation transitions, guard admin-on-admin, revoke tokens, audit log) |
| `server/crates/domain/src/users/refresh_token_repository.rs` | Ajouter `revoke_all_for_user` |
| `server/crates/api/src/routes/admin.rs` | Ajouter handlers `list_users`, `get_user_detail`, `update_user_status_admin` |
| `server/crates/api/src/routes/mod.rs` | Enregistrer 3 nouvelles routes `/admin/users` |
| `packages/mefali_api_client/lib/endpoints/admin_endpoint.dart` | Ajouter `listUsers()`, `getUserDetail()`, `updateUserStatus()` |
| `packages/mefali_api_client/lib/mefali_api_client.dart` | Exporter nouveau provider |
| `packages/mefali_core/lib/mefali_core.dart` | Exporter nouveau modele |
| `apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart` | Ajouter 7e destination (Comptes) |

### Nouveaux fichiers a creer

| Fichier | Contenu |
|---------|---------|
| `server/migrations/2026XXXX_create_admin_audit_logs.up.sql` | Table `admin_audit_logs` |
| `server/migrations/2026XXXX_create_admin_audit_logs.down.sql` | DROP TABLE |
| `packages/mefali_core/lib/models/admin_user.dart` | `AdminUserListItem`, `AdminUserDetail` |
| `packages/mefali_api_client/lib/providers/admin_accounts_provider.dart` | Providers Riverpod |
| `apps/mefali_admin/lib/features/accounts/account_list_screen.dart` | Liste utilisateurs |
| `apps/mefali_admin/lib/features/accounts/account_detail_screen.dart` | Detail utilisateur |

### Migration SQL: admin_audit_logs

```sql
CREATE TABLE admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES users(id),
    target_user_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    old_status user_status,
    new_status user_status,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_logs_target ON admin_audit_logs(target_user_id);
CREATE INDEX idx_audit_logs_admin ON admin_audit_logs(admin_id);
CREATE INDEX idx_audit_logs_created ON admin_audit_logs(created_at DESC);
```

### Status Transitions valides

```
active       → suspended     (violation mineure)
active       → deactivated   (violation grave)
suspended    → active        (rehabilitation)
suspended    → deactivated   (escalade)
deactivated  → active        (decision exceptionnelle admin)
pending_kyc  → active        (KYC valide — deja gere par agent, pas dans cette story)
```

Le service `admin_update_user_status` DOIT valider ces transitions et retourner `AppError::BadRequest` si invalide.

### Revocation des tokens

Quand un user est suspendu ou desactive:
1. Revoquer TOUS ses refresh tokens en base (`UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL`)
2. L'access token (15 min) expirera naturellement — pas besoin de blacklist Redis
3. Le user ne pourra plus se reconnecter car le refresh echouera

### Guard admin-on-admin

```rust
if target_user.role == UserRole::Admin {
    return Err(AppError::Forbidden("Cannot modify admin accounts".into()));
}
```

### Recherche utilisateurs

La recherche doit etre case-insensitive sur `name` et `phone`:
```sql
WHERE (name ILIKE '%' || $search || '%' OR phone ILIKE '%' || $search || '%')
```

### Compteurs de tests attendus

Apres cette story:
- Rust: ~313 tests (+12)
- Flutter admin: ~30 tests (+3)

### Project Structure Notes

- Le dossier `apps/mefali_admin/lib/features/accounts/` est nouveau — s'aligne avec le pattern feature-based existant (`disputes/`, `cities/`, `dashboard/`)
- L'onglet Comptes va a l'index 6 du NavigationRail, apres Villes (index 5)
- Les stubs "Bientot disponible" aux index 1-3 (Commandes, Marchands, Livreurs) sont preserves — ils seront implementes dans la story 8-5

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 8, Story 8.4]
- [Source: _bmad-output/planning-artifacts/prd.md — FR7: Admin peut desactiver ou suspendre tout compte]
- [Source: _bmad-output/planning-artifacts/prd.md — NFR13: Logs d'audit toute action admin]
- [Source: _bmad-output/planning-artifacts/architecture.md — REST API patterns, JWT auth]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Admin nav laterale web]
- [Source: _bmad-output/implementation-artifacts/8-1-admin-operational-dashboard.md — AdminShellScreen pattern]
- [Source: _bmad-output/implementation-artifacts/8-2-dispute-management-with-timeline.md — AdminEndpoint extension pattern]
- [Source: _bmad-output/implementation-artifacts/8-3-city-configuration.md — City module pattern, DataTable responsive]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Fixed `rated_id` column name (was `ratee_id`) in admin user detail SQL query
- Fixed pool borrow issue in suspend test by cloning pool before `test_app()`
- Fixed ternary operator syntax error in Dart error handling for DioException

### Completion Notes List

- Backend: 3 new endpoints (GET /admin/users, GET /admin/users/{id}, PATCH /admin/users/{id}/status)
- Backend: admin_audit_logs migration for NFR13 compliance
- Backend: Status transition validation, admin-on-admin guard, token revocation on suspend/deactivate
- Backend: 12 new integration tests (all pass), total workspace 314 tests, 0 failures
- Frontend: AdminUserListItem + AdminUserDetail models with code generation
- Frontend: AdminEndpoint extended with listUsers, getUserDetail, updateUserStatus
- Frontend: adminUsersProvider + adminUserDetailProvider (FutureProvider.autoDispose.family)
- Frontend: AccountListScreen with search, role/status filters, pagination
- Frontend: AccountDetailScreen with profile card, stats row, contextual status actions with confirmation dialog
- Frontend: AdminShellScreen extended with 7th destination "Comptes" at index 6
- Frontend: 3 new widget tests (all pass), total 34 Flutter admin tests

### Change Log

- 2026-03-21: Story 8.4 implemented — account management with list/detail/status endpoints + admin UI

### File List

**New files:**
- server/migrations/20260322000005_create_admin_audit_logs.up.sql
- server/migrations/20260322000005_create_admin_audit_logs.down.sql
- packages/mefali_core/lib/models/admin_user.dart
- packages/mefali_core/lib/models/admin_user.g.dart
- packages/mefali_api_client/lib/providers/admin_accounts_provider.dart
- apps/mefali_admin/lib/features/accounts/account_list_screen.dart
- apps/mefali_admin/lib/features/accounts/account_detail_screen.dart

**Modified files:**
- server/crates/domain/src/users/model.rs
- server/crates/domain/src/users/repository.rs
- server/crates/domain/src/users/service.rs
- server/crates/api/src/routes/admin.rs
- server/crates/api/src/routes/mod.rs
- server/crates/api/src/test_helpers.rs
- packages/mefali_core/lib/mefali_core.dart
- packages/mefali_api_client/lib/endpoints/admin_endpoint.dart
- packages/mefali_api_client/lib/mefali_api_client.dart
- apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart
- apps/mefali_admin/test/widget_test.dart
