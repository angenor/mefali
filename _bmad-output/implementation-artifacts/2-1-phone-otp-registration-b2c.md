# Story 2.1: Phone + OTP Registration (B2C)

Status: done

## Story

En tant que **client B2C**,
Je veux **m'inscrire avec mon numero de telephone et un SMS OTP**,
Afin de **commencer a utiliser l'app en 30 secondes**.

## Criteres d'Acceptation

1. **AC1**: Quand j'ouvre l'app pour la premiere fois et que je saisis mon telephone + OTP, mon compte est cree avec le role `client` et le status `active`
2. **AC2**: Apres l'inscription, je vois l'ecran d'accueil (home placeholder avec bottom nav 4 items)
3. **AC3**: L'inscription complete prend < 30 secondes (3 ecrans : telephone, OTP, prenom)
4. **AC4**: Le endpoint `POST /api/v1/auth/request-otp` genere un OTP 6 chiffres, le stocke dans Redis (TTL 5 min), et l'envoie via SMS
5. **AC5**: Le endpoint `POST /api/v1/auth/verify-otp` verifie l'OTP, cree l'utilisateur si nouveau, et retourne des JWT tokens (access 15 min + refresh 7 jours)
6. **AC6**: Les tokens JWT sont stockes dans `flutter_secure_storage` et l'auth state Riverpod est mis a jour
7. **AC7**: Les endpoints auth repondent en < 500ms (p95) et le rate limiting Redis empeche le spam OTP (max 3 requetes/minute/telephone)

## Taches / Sous-taches

- [x] **T1** Infrastructure backend pour OTP (AC: #4, #7)
  - [x] T1.1 Ajouter `jsonwebtoken`, `rand` aux workspace dependencies dans `server/Cargo.toml`
  - [x] T1.2 Injecter `web::Data<redis::aio::ConnectionManager>` dans l'app state Actix (`main.rs`)
  - [x] T1.3 Creer `server/crates/domain/src/users/otp_service.rs` — generation OTP 6 chiffres, stockage Redis (cle `otp:{phone}`, TTL 300s), verification
  - [x] T1.4 Creer un dev SMS provider dans `server/crates/notification/src/sms/dev_provider.rs` — log l'OTP en console avec `tracing::info!` au lieu d'envoyer un vrai SMS
  - [x] T1.5 Ajouter `TooManyRequests` a `AppError` dans `common/src/error.rs` (HTTP 429)
  - [x] T1.6 Ajouter config OTP dans `AppConfig` : `otp_length` (6), `otp_expiry_seconds` (300), `otp_max_attempts` (3)

- [x] **T2** User repository et service (AC: #1, #5)
  - [x] T2.1 Completer `domain/src/users/model.rs` — ajouter champs manquants : `status: UserStatus`, `fcm_token: Option<String>`, `updated_at: Timestamp`. Ajouter `UserStatus` enum (Active, PendingKyc, Suspended, Deactivated). Ajouter DTOs : `CreateUserRequest`, `AuthResponse` (access_token, refresh_token, user)
  - [x] T2.2 Implementer `domain/src/users/repository.rs` — `find_by_phone(&PgPool, &str) -> Option<User>`, `create_user(&PgPool, CreateUserRequest) -> User`
  - [x] T2.3 Implementer `domain/src/users/service.rs` — `request_otp(phone)` (valide format, rate limit, genere OTP, envoie SMS), `verify_otp_and_register(phone, otp, name) -> AuthResponse` (verifie OTP, cree user si nouveau, genere JWT)

- [x] **T3** Routes auth backend (AC: #4, #5, #7)
  - [x] T3.1 Creer `server/crates/api/src/routes/auth.rs` avec 2 endpoints :
    - `POST /api/v1/auth/request-otp` body: `{"phone": "+225XXXXXXXXXX"}` → `{"data": {"message": "OTP envoye"}}`
    - `POST /api/v1/auth/verify-otp` body: `{"phone": "...", "otp": "123456", "name": "Koffi"}` → `{"data": {"access_token": "...", "refresh_token": "...", "user": {...}}}`
  - [x] T3.2 Ajouter scope `/auth` dans `routes/mod.rs`
  - [x] T3.3 Implementer generation JWT dans `domain/src/users/service.rs` avec claims : `sub` (user_id), `role`, `exp`, `iat`

- [x] **T4** Packages Flutter partages (AC: #1, #6)
  - [x] T4.1 Creer `packages/mefali_core/lib/models/user.dart` — `User` model avec `@JsonSerializable(fieldRename: FieldRename.snake)`. Champs : id, phone, name, role, status. Creer `packages/mefali_core/lib/enums/user_role.dart` et `user_status.dart`
  - [x] T4.2 Creer `packages/mefali_api_client/lib/dio_client/dio_client.dart` — instance Dio singleton avec baseUrl, JSON content-type, logging interceptor. Creer le provider Riverpod `dioProvider`
  - [x] T4.3 Creer `packages/mefali_api_client/lib/endpoints/auth_endpoint.dart` — `requestOtp(phone)`, `verifyOtp(phone, otp, name)`. Retourne les DTOs type-safe
  - [x] T4.4 Ajouter `flutter_secure_storage: ^9.2.0` dans `packages/mefali_api_client/pubspec.yaml`. Creer `lib/providers/auth_provider.dart` — `authStateProvider` (StateNotifier) gerant tokens + User. Persistence dans SecureStorage

- [x] **T5** Ecrans d'inscription B2C (AC: #1, #2, #3)
  - [x] T5.1 Creer `apps/mefali_b2c/lib/features/auth/phone_screen.dart` — champ telephone avec clavier numerique, label au-dessus, validation inline format CI (+225), `FilledButton` pleine largeur "Continuer" en bas (touch >= 48dp), skeleton screen pendant loading
  - [x] T5.2 Creer `apps/mefali_b2c/lib/features/auth/otp_screen.dart` — 6 champs OTP, auto-focus, timer resend (60s), SnackBar rouge si code incorrect (persistent), SnackBar vert si succes (3s auto-dismiss)
  - [x] T5.3 Creer `apps/mefali_b2c/lib/features/auth/name_screen.dart` — champ prenom (clavier texte), `FilledButton` pleine largeur "Commencer"
  - [x] T5.4 Creer `apps/mefali_b2c/lib/features/auth/auth_controller.dart` — Riverpod `AsyncNotifier` orchestrant le flow : requestOtp → verifyOtp → navigate home

- [x] **T6** Navigation et auth state (AC: #2, #6)
  - [x] T6.1 Configurer `go_router` dans `apps/mefali_b2c/lib/app.dart` — routes : `/auth/phone`, `/auth/otp`, `/auth/name`, `/home`. Redirect vers `/auth/phone` si pas de token
  - [x] T6.2 Creer `apps/mefali_b2c/lib/features/home/home_screen.dart` — placeholder avec texte "Bienvenue {prenom}" + `NavigationBar` M3 (4 items : Home, Recherche, Commandes, Profil)
  - [x] T6.3 Integrer auth guard dans go_router : verifie token au demarrage, redirige vers auth si absent

- [x] **T7** Tests (AC: #1 a #7)
  - [x] T7.1 Tests unitaires Rust : OTP generation/verification, JWT creation, user service, rate limiting
  - [x] T7.2 Tests unitaires Rust : auth routes (mock pool/redis) — request-otp retourne 200, verify-otp retourne tokens
  - [x] T7.3 Tests widget Flutter : PhoneScreen affiche champ + bouton, OTPScreen affiche 6 inputs, NameScreen affiche champ + bouton, navigation flow

## Dev Notes

### Architecture des fichiers — Ce qui est cree vs modifie

```
server/
  Cargo.toml                              # MODIFIE (ajout jsonwebtoken, rand)
  crates/
    api/
      Cargo.toml                          # MODIFIE (ajout jsonwebtoken si necessaire)
      src/
        main.rs                           # MODIFIE (ajout Redis dans app state, SMS provider)
        routes/
          mod.rs                          # MODIFIE (ajout scope /auth)
          auth.rs                         # NOUVEAU
    domain/src/users/
      model.rs                            # MODIFIE (ajout status, fcm_token, updated_at, DTOs)
      repository.rs                       # MODIFIE (implementation queries SQLx)
      service.rs                          # MODIFIE (implementation logique OTP + registration)
      otp_service.rs                      # NOUVEAU
    notification/src/sms/
      dev_provider.rs                     # NOUVEAU
      mod.rs                              # MODIFIE (export dev_provider)
    common/src/
      error.rs                            # MODIFIE (ajout TooManyRequests)
      config.rs                           # MODIFIE (ajout config OTP)

packages/
  mefali_core/lib/
    mefali_core.dart                      # MODIFIE (barrel exports)
    models/user.dart                      # NOUVEAU
    enums/user_role.dart                  # NOUVEAU
    enums/user_status.dart                # NOUVEAU
  mefali_api_client/
    pubspec.yaml                          # MODIFIE (ajout flutter_secure_storage)
    lib/
      mefali_api_client.dart              # MODIFIE (barrel exports)
      dio_client/dio_client.dart          # NOUVEAU
      endpoints/auth_endpoint.dart        # NOUVEAU
      providers/auth_provider.dart        # NOUVEAU

apps/mefali_b2c/lib/
  app.dart                                # MODIFIE (go_router setup)
  features/auth/
    phone_screen.dart                     # NOUVEAU
    otp_screen.dart                       # NOUVEAU
    name_screen.dart                      # NOUVEAU
    auth_controller.dart                  # NOUVEAU
  features/home/
    home_screen.dart                      # NOUVEAU
```

### Etat actuel du code — Ce qui existe deja

**Backend Rust (pret a utiliser) :**
- `PgPool` cree et injecte dans app state (`main.rs`)
- `sqlx::migrate!("../../migrations")` execute au demarrage — table `users` avec phone UNIQUE, role enum, status enum existent deja
- `AppConfig::from_env()` charge deja `jwt_secret`, `jwt_access_expiry` (900s), `jwt_refresh_expiry` (604800s), `redis_url`
- `SmsProvider` trait + `SmsRouter` (primary+fallback) dans `notification/src/sms/` — prets avec tests
- `AppError` avec `ResponseError` pour Actix — retourne `{"error": {"code": "...", "message": "..."}}`
- `ApiResponse<T>` pour les reponses succes — retourne `{"data": ...}`
- `Id = uuid::Uuid`, `Timestamp = DateTime<Utc>`, `new_id()`, `now()` dans `common/types.rs`
- `redis::aio::ConnectionManager` cree dans `infrastructure/redis/mod.rs` via `create_connection(url)` — mais PAS ENCORE injecte dans app state
- Health check existant : `GET /api/v1/health` → `{"data": {"status": "ok"}}` — suivre ce pattern

**Backend Rust (incomplet, a completer) :**
- `domain/src/users/model.rs` : `User` struct INCOMPLETE — manque `status`, `fcm_token`, `updated_at`
- `domain/src/users/repository.rs` : VIDE (commentaire placeholder)
- `domain/src/users/service.rs` : VIDE (commentaire placeholder)
- `api/src/extractors/mod.rs` : VIDE (JWT extractor sera Story 2.2)
- `api/src/middleware/mod.rs` : VIDE (auth middleware sera Story 2.2)

**Flutter (pret a utiliser) :**
- `MefaliTheme.light()/.dark()` avec palette marron, M3 complet — `InputDecorationTheme` (OutlineInputBorder, labels au-dessus), `FilledButton` min 48dp, `NavigationBarTheme`, `SnackBarTheme` (floating)
- `ProviderScope` deja wrappé dans `main.dart` (Riverpod pret)
- `flutter_riverpod: ^2.6.0` et `go_router: ^14.6.0` deja dans les dependencies B2C
- `dio: ^5.7.0` deja dans `mefali_api_client` dependencies
- `json_annotation: ^4.9.0` + `json_serializable: ^6.8.0` deja dans `mefali_core` dependencies

**Flutter (a creer) :**
- Feature folders `auth/` et `home/` dans `apps/mefali_b2c/lib/features/`
- Tout le contenu de `mefali_core/lib/models/` et `mefali_core/lib/enums/`
- Tout le contenu de `mefali_api_client/lib/dio_client/`, `endpoints/`, `providers/`

### Contraintes UX critiques

- **3 ecrans, < 30 secondes, 0 email, 0 mot de passe** — ne RIEN ajouter au flow
- **Labels au-dessus des champs** (pas en placeholder) — `floatingLabelBehavior: FloatingLabelBehavior.always` est deja dans le theme
- **Validation inline** sous le champ en erreur — pas de dialog, pas de SnackBar pour validation
- **Clavier adapte** : numerique pour telephone, texte pour prenom
- **Pas de splash screen, pas de tutorial** — directement le contenu
- **Skeleton screens pour le loading** — jamais de spinner seul (`Shimmer` ou container anime)
- **SnackBar rouge persistent** pour erreurs, **SnackBar vert 3s** pour succes
- **Touch target >= 48dp** pour tous les boutons — deja dans le theme (`_minButtonHeight`)
- **Portrait uniquement** pour B2C
- **Marges 16dp fixe**
- **Bottom nav B2C** : Home, Recherche, Commandes, Profil — avec icones + labels visibles, `NavigationBar` M3

### Conventions backend critiques

- **API REST** : `/api/v1/auth/...`, `snake_case` JSON fields
- **Response wrappers** : `{"data": ...}` succes, `{"error": {"code": "...", "message": "..."}}` erreur
- **Phone format** : `+225XXXXXXXXXX` (indicatif Cote d'Ivoire) — valider format au backend
- **OTP dans Redis** : cle `otp:{phone}`, valeur `{code}:{attempts}`, TTL 300s
- **Rate limiting** : max 3 `request-otp` par minute par telephone (Redis compteur avec TTL 60s)
- **JWT claims** : `{"sub": "uuid", "role": "client", "iat": timestamp, "exp": timestamp}`
- **Pas de table OTP en DB** — Redis seulement (ephemere, TTL 5 min)
- **Pas de table refresh_tokens** — JWT stateless. Le refresh sera gere dans Story 2.2
- **Pas de `sqlx::query!()`** — utiliser `sqlx::query_as()` avec des structs derives `FromRow`
- **Erreurs** : `thiserror` dans domain, mappe a HTTP status dans api via `AppError`
- **Workspace deps** : toujours ajouter dans `server/Cargo.toml` `[workspace.dependencies]`, puis `.workspace = true` dans le crate

### Conventions Flutter critiques

- **Riverpod** : `autoDispose` par defaut, `AsyncNotifier` pour le flow auth
- **go_router** : routes declaratives, `redirect` pour auth guard
- **Dio** : singleton via Riverpod provider, JSON content-type par defaut
- **`@JsonSerializable(fieldRename: FieldRename.snake)`** — Dart recoit snake_case, mappe en camelCase
- **`prefer_single_quotes`**, **`prefer_const_constructors`**, **`avoid_print`** — lint strict
- **`prefer_relative_imports`** dans chaque package
- **Generated files** : lancer `dart run build_runner build` pour `*.g.dart`
- **Barrel exports** : chaque package exporte via son fichier principal (`mefali_core.dart`, `mefali_api_client.dart`)

### Pieges a eviter

1. **NE PAS** creer de table `sessions` ou `refresh_tokens` — JWT stateless
2. **NE PAS** stocker de mot de passe — auth est phone + OTP uniquement
3. **NE PAS** utiliser `sqlx::query!()` — pas de `.sqlx/` offline cache. Utiliser `sqlx::query_as()` ou `sqlx::query()`
4. **NE PAS** oublier `#[derive(Deserialize)]` sur les request bodies et `#[derive(Serialize)]` sur les responses
5. **NE PAS** oublier de lancer `melos bootstrap` apres ajout de dependencies
6. **NE PAS** oublier `dart run build_runner build` dans `mefali_core` apres creation des models
7. **NE PAS** ajouter PostgreSQL en service CI — les tests unitaires ne touchent pas la DB
8. **NE PAS** utiliser `print()` en Flutter — utiliser `debugPrint()` ou `log()` si absolument necessaire
9. **NE PAS** creer de `melos.yaml` separe — config dans root `pubspec.yaml`
10. **NE PAS** mettre le `jwt_secret` en dur — lire depuis `AppConfig`
11. **NE PAS** oublier les `down.sql` pour toute nouvelle migration (ici pas de migration prevue)
12. **NE PAS** ajouter de splash screen ou tutorial — le user doit voir le contenu directement

### Intelligence story precedente (Epic 1)

- **Migration path** : `sqlx::migrate!("../../migrations")` — path relatif a `CARGO_MANIFEST_DIR` (`crates/api/`)
- **Pattern health.rs** : suivre exactement le meme pattern pour `auth.rs` — handler async, `web::Data<T>` extractors, `ApiResponse::new()`
- **Redis** : `create_connection(url)` dans `infrastructure/redis/` retourne `ConnectionManager` — deja teste mais pas injecte dans main.rs
- **SMS** : `SmsRouter` avec primary + fallback providers, trait `SmsProvider` — creer un `DevSmsProvider` qui implemente le trait et log en console
- **Money = BIGINT** : les montants en FCFA sont des entiers (pas de decimales)
- **Verification post-modif** : toujours lancer les 6 commandes CI avant de considerer une tache finie

### Scope de cette story vs Story 2.2

| Responsabilite | Story 2.1 (cette story) | Story 2.2 (JWT Auth System) |
|---|---|---|
| Registration flow B2C | OUI | Non |
| OTP generate + verify | OUI | Non |
| User creation en DB | OUI | Non |
| JWT token generation | OUI (basique) | Amelioration (rotation) |
| Token storage Flutter | OUI (SecureStorage) | Non (deja fait) |
| Login (user existant) | Non | OUI |
| Dio interceptor refresh | Non | OUI |
| JWT middleware Actix | Non | OUI |
| Token rotation | Non | OUI |
| Auth guard go_router | OUI (basique redirect) | Amelioration |

### Project Structure Notes

- Organisation par feature/domaine : `features/auth/`, `features/home/` dans l'app B2C
- Les auth routes backend vont dans `crates/api/src/routes/auth.rs`, la logique dans `crates/domain/src/users/`
- Les models partages dans `packages/mefali_core/lib/models/`, les enums dans `lib/enums/`
- Le client API dans `packages/mefali_api_client/` — partage entre les 4 apps

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 2, Story 2.1]
- [Source: _bmad-output/planning-artifacts/architecture.md — Section Authentication & Security]
- [Source: _bmad-output/planning-artifacts/architecture.md — Section Data Architecture, users schema]
- [Source: _bmad-output/planning-artifacts/architecture.md — Section API & Communication Patterns]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow 5 Koffi s'inscrit, Form Patterns]
- [Source: _bmad-output/planning-artifacts/prd.md — FR1, Journey 3 Koffi, NFR1/NFR2/NFR8/NFR10/NFR19/NFR28]
- [Source: CLAUDE.md — Build & Dev Commands, Conventions, Constraints]
- [Source: server/crates/common/src/config.rs — AppConfig jwt_secret, jwt_access_expiry, jwt_refresh_expiry]
- [Source: server/crates/notification/src/sms/mod.rs — SmsProvider trait, SmsRouter]
- [Source: server/crates/infrastructure/src/redis/mod.rs — create_connection()]
- [Source: server/migrations/20260317000003_create_users.up.sql — users table schema]
- [Source: server/migrations/20260317000001_create_enums.up.sql — user_role, user_status enums]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- `cargo build --workspace` : SUCCESS — 6 crates compilent
- `cargo test --workspace` : SUCCESS — 44 tests (30 existants + 14 nouveaux)
- `cargo clippy --workspace -- -D warnings` : SUCCESS — 0 warnings
- `cargo fmt --all -- --check` : SUCCESS — 0 fichiers non formates
- `dart analyze` : SUCCESS — 0 issues dans 8 packages
- `flutter test` : SUCCESS — tous tests passent dans les 8 packages

### Completion Notes List

- Backend Rust : OTP infrastructure (generation, stockage Redis, verification, rate limiting), user repository (find_by_phone, create_user via SQLx), user service (request_otp, verify_otp_and_register avec JWT), auth routes (POST /auth/request-otp, POST /auth/verify-otp), dev SMS provider
- Flutter shared : User model + enums (mefali_core), Dio client + auth endpoint + auth provider avec SecureStorage (mefali_api_client)
- Flutter B2C : 3 ecrans inscription (phone, OTP, name), home screen avec NavigationBar 4 items, go_router avec auth guard
- 14 nouveaux tests Rust : OTP generation, phone validation, JWT creation/decoding, serde models, dev SMS provider, error status codes
- Tests widget Flutter mis a jour pour le nouveau flow d'inscription

### Change Log

- 2026-03-17 : Implementation complete Phone + OTP Registration B2C (T1-T7)
- 2026-03-17 : Code review fixes — C3 (error sanitization), H1 (SMS provider injection via app state), H2 (INSERT ON CONFLICT), H3 (OTP screen dead code), H4 (rate limit config separation), C1 (auth_controller.dart AsyncNotifier created), C2 (loadFromStorage on startup), M1-M7 (padding 16dp, persistent SnackBar, success feedback, skeleton loading, SafeArea, label "Accueil")

### File List

- server/Cargo.toml (modifie)
- server/crates/api/Cargo.toml (modifie)
- server/crates/api/src/main.rs (modifie)
- server/crates/api/src/routes/mod.rs (modifie)
- server/crates/api/src/routes/auth.rs (nouveau)
- server/crates/domain/Cargo.toml (modifie)
- server/crates/domain/src/users/mod.rs (modifie)
- server/crates/domain/src/users/model.rs (modifie)
- server/crates/domain/src/users/repository.rs (modifie)
- server/crates/domain/src/users/service.rs (modifie)
- server/crates/domain/src/users/otp_service.rs (nouveau)
- server/crates/notification/Cargo.toml (modifie)
- server/crates/notification/src/sms/mod.rs (modifie)
- server/crates/notification/src/sms/dev_provider.rs (nouveau)
- server/crates/common/src/error.rs (modifie)
- server/crates/common/src/config.rs (modifie)
- packages/mefali_core/lib/mefali_core.dart (modifie)
- packages/mefali_core/lib/enums/user_role.dart (nouveau)
- packages/mefali_core/lib/enums/user_status.dart (nouveau)
- packages/mefali_core/lib/models/user.dart (nouveau)
- packages/mefali_core/lib/models/user.g.dart (genere)
- packages/mefali_core/lib/models/auth_response.dart (nouveau)
- packages/mefali_core/lib/models/auth_response.g.dart (genere)
- packages/mefali_api_client/pubspec.yaml (modifie)
- packages/mefali_api_client/lib/mefali_api_client.dart (modifie)
- packages/mefali_api_client/lib/dio_client/dio_client.dart (nouveau)
- packages/mefali_api_client/lib/endpoints/auth_endpoint.dart (nouveau)
- packages/mefali_api_client/lib/providers/auth_provider.dart (nouveau)
- apps/mefali_b2c/lib/app.dart (modifie)
- apps/mefali_b2c/lib/features/auth/phone_screen.dart (nouveau)
- apps/mefali_b2c/lib/features/auth/otp_screen.dart (nouveau)
- apps/mefali_b2c/lib/features/auth/name_screen.dart (nouveau)
- apps/mefali_b2c/lib/features/home/home_screen.dart (nouveau)
- apps/mefali_b2c/test/widget_test.dart (modifie)
