# Story 2.3: Inscription Multi-Role (Livreur)

Status: done

## Story

En tant que **livreur souhaitant travailler sur mefali**,
Je veux **m'inscrire avec mon telephone et le telephone de mon sponsor**,
Afin de **creer mon compte livreur et commencer le processus de validation KYC**.

## Criteres d'Acceptation

1. **AC1** : Etant donne un nouveau livreur, quand il saisit son telephone + OTP + nom + telephone du sponsor, alors son compte est cree avec `role=driver`, `status=pending_kyc` et il voit un ecran d'accueil livreur
2. **AC2** : Etant donne un telephone sponsor valide, quand le serveur recoit l'inscription, alors une entree `sponsorships` est creee avec `sponsor_id` = l'utilisateur sponsor et `sponsored_id` = le nouveau livreur, `status=active`
3. **AC3** : Etant donne un telephone sponsor qui ne correspond a aucun utilisateur, quand le livreur tente de s'inscrire, alors il recoit une erreur 400 `{"error": {"code": "BAD_REQUEST", "message": "Sponsor not found. Ensure they are registered."}}`
4. **AC4** : Etant donne un livreur qui tente de s'inscrire sans fournir de telephone sponsor, quand le serveur recoit la requete avec `role=driver` et `sponsor_phone` absent, alors il retourne 400 `{"error": {"code": "BAD_REQUEST", "message": "Sponsor phone is required for driver registration"}}`
5. **AC5** : Etant donne un utilisateur existant avec n'importe quel role, quand il saisit son telephone + OTP (sans `name`), alors il se connecte normalement (login existant) quel que soit le role — pas de changement de role
6. **AC6** : Etant donne l'app `mefali_livreur`, quand un livreur non authentifie ouvre l'app, alors il voit l'ecran de saisie du telephone. Apres inscription, il voit l'ecran d'accueil livreur
7. **AC7** : Etant donne l'app `mefali_b2c`, quand un client s'inscrit, alors le comportement existant est inchange — role=client par defaut, pas de champ sponsor

## Taches / Sous-taches

- [x] **T1** Etendre le payload verify-otp pour multi-role (AC: #1, #4, #5, #7)
  - [x] T1.1 Ajouter `role: Option<String>` et `sponsor_phone: Option<String>` a `VerifyOtpPayload` dans `domain/src/users/model.rs`. Le champ `role` est optionnel (defaut "client"). Seules les valeurs "client" et "driver" sont acceptees a l'inscription — "merchant", "agent", "admin" sont crees par d'autres flows
  - [x] T1.2 Modifier `create_user()` dans `repository.rs` pour accepter un parametre `role: UserRole` et `status: UserStatus` au lieu de hardcoder `UserRole::Client` et `UserStatus::Active`
  - [x] T1.3 Modifier `verify_otp_and_register()` dans `service.rs` : si `role` absent ou "client" → flow actuel inchange (role=Client, status=Active). Si role="driver" → valider `sponsor_phone` present, creer user avec role=Driver et status=PendingKyc, puis creer le lien sponsorship

- [x] **T2** Repository sponsorship (AC: #2, #3)
  - [x] T2.1 Creer `domain/src/users/sponsorship_repository.rs` avec : `create(pool, sponsor_id, sponsored_id) -> Result<Sponsorship, AppError>` et `find_by_sponsored(pool, sponsored_id) -> Result<Option<Sponsorship>, AppError>`
  - [x] T2.2 Ajouter struct `Sponsorship` dans `model.rs` : `id: Id, sponsor_id: Id, sponsored_id: Id, status: SponsorshipStatus, created_at: Timestamp, updated_at: Timestamp`. Ajouter enum `SponsorshipStatus { Active, Suspended, Terminated }` avec derives sqlx/serde
  - [x] T2.3 Exporter le module dans `domain/src/users/mod.rs`

- [x] **T3** Logique d'inscription livreur cote serveur (AC: #1, #2, #3, #4)
  - [x] T3.1 Dans `verify_otp_and_register()`, apres creation du user driver : appeler `repository::find_by_phone(pool, sponsor_phone)` pour trouver le sponsor. Si sponsor non trouve → `AppError::BadRequest("Sponsor not found...")`. Si trouve → `sponsorship_repository::create(pool, sponsor.id, new_user.id)`
  - [x] T3.2 Valider que `role` ne peut etre que "client" ou "driver" a l'inscription. Rejeter tout autre role avec `AppError::BadRequest("Invalid role for self-registration")`

- [x] **T4** Etendre le client Flutter (AC: #6, #7)
  - [x] T4.1 Modifier `AuthEndpoint.verifyOtp()` dans `packages/mefali_api_client/lib/endpoints/auth_endpoint.dart` pour accepter `role` et `sponsorPhone` optionnels. Les envoyer dans le body uniquement s'ils sont non-null
  - [x] T4.2 Modifier `AuthNotifier.verifyOtp()` dans `packages/mefali_api_client/lib/providers/auth_provider.dart` pour propager `role` et `sponsorPhone` jusqu'a `AuthEndpoint`

- [x] **T5** App mefali_livreur — ecrans d'inscription (AC: #6)
  - [x] T5.1 Creer `apps/mefali_livreur/lib/features/auth/phone_screen.dart` — meme pattern que B2C (ConsumerStatefulWidget, validation 10 chiffres, prefixe +225, SnackBar erreur/succes). Titre : "Inscription Livreur"
  - [x] T5.2 Creer `apps/mefali_livreur/lib/features/auth/otp_screen.dart` — identique au B2C (6 chiffres, auto-advance, timer 60s resend)
  - [x] T5.3 Creer `apps/mefali_livreur/lib/features/auth/registration_screen.dart` — champs : nom (TextCapitalization.words) + telephone sponsor (meme validation que phone, prefixe +225). Appelle `authProvider.verifyOtp(phone, otp, name, role: 'driver', sponsorPhone: sponsorPhone)`. Navigue vers `/home` apres succes
  - [x] T5.4 Creer `apps/mefali_livreur/lib/features/home/home_screen.dart` — ecran placeholder livreur : affiche le nom de l'utilisateur, son statut (`pending_kyc` → "En attente de validation KYC"), et un message explicatif

- [x] **T6** App mefali_livreur — routing et auth guard (AC: #6)
  - [x] T6.1 Remplacer le contenu de `apps/mefali_livreur/lib/app.dart` par un setup GoRouter + auth guard identique au pattern B2C : `_AuthRouterNotifier` + `refreshListenable` + redirect (non-auth → `/auth/phone`, auth → `/home`). Routes : `/auth/phone`, `/auth/otp`, `/auth/register`, `/home`
  - [x] T6.2 Modifier `apps/mefali_livreur/lib/main.dart` si necessaire (verifier qu'il utilise `ProviderScope`)

- [x] **T7** Tests (AC: #1 a #7)
  - [x] T7.1 Tests unitaires Rust — `verify_otp_and_register` : role absent → client (backward compat), role=driver + sponsor_phone valide → user driver + sponsorship cree, role=driver + sponsor_phone absent → 400, role=driver + sponsor inexistant → 400, role=admin → 400 rejete
  - [x] T7.2 Tests unitaires Rust — sponsorship_repository (si testable sans DB) : struct Sponsorship serde, SponsorshipStatus Display/serde
  - [x] T7.3 Tests unitaires Flutter — AuthEndpoint/AuthNotifier acceptent role + sponsorPhone
  - [x] T7.4 Tests widget Flutter mefali_livreur — app renders phone screen, app title correct

## Dev Notes

### Architecture des fichiers — Ce qui est cree vs modifie

```
server/crates/
  domain/src/users/
    mod.rs                                     # MODIFIE (export sponsorship_repository)
    model.rs                                   # MODIFIE (ajout Sponsorship, SponsorshipStatus, extend VerifyOtpPayload)
    repository.rs                              # MODIFIE (create_user accepte role + status)
    service.rs                                 # MODIFIE (logique multi-role dans verify_otp_and_register)
    sponsorship_repository.rs                  # NOUVEAU

packages/
  mefali_api_client/lib/
    endpoints/auth_endpoint.dart               # MODIFIE (verifyOtp accepte role, sponsorPhone)
    providers/auth_provider.dart                # MODIFIE (verifyOtp propage role, sponsorPhone)

apps/mefali_livreur/lib/
  main.dart                                    # MODIFIE (si necessaire)
  app.dart                                     # MODIFIE (GoRouter + auth guard complet)
  features/auth/
    phone_screen.dart                          # NOUVEAU
    otp_screen.dart                            # NOUVEAU
    registration_screen.dart                   # NOUVEAU
  features/home/
    home_screen.dart                           # NOUVEAU

apps/mefali_livreur/test/
  widget_test.dart                             # MODIFIE (tests auth)
packages/mefali_api_client/test/
  mefali_api_client_test.dart                  # MODIFIE (3 tests AuthEndpoint role/sponsorPhone)
```

### Etat actuel du code — Ce qui existe deja (Stories 2.1 + 2.2)

**Backend Rust :**
- `POST /api/v1/auth/request-otp` et `POST /api/v1/auth/verify-otp` fonctionnels
- `verify_otp_and_register()` gere login (user existant) vs registration (nouveau user) — a etendre pour multi-role
- `create_user()` dans `repository.rs` hardcode `UserRole::Client` et `UserStatus::Active` → a parametrer
- `UserRole::Driver` et `UserStatus::PendingKyc` existent deja dans les enums Rust et DB
- JWT auth system complet (access 15min, refresh 7j, rotation, interceptor)
- `AuthenticatedUser` extractor et `require_role()` guard prets a l'emploi
- `AppError` avec `BadRequest`, `NotFound`, `Unauthorized`, etc.

**Base de donnees :**
- Table `sponsorships` existe deja (migration 012) : `id, sponsor_id, sponsored_id, status, created_at, updated_at` avec `CHECK (sponsor_id != sponsored_id)`, `UNIQUE (sponsored_id)`, index sur `sponsor_id`
- Type `sponsorship_status` existe deja : `active, suspended, terminated`
- NE PAS creer de nouvelle migration — tout est en place

**Flutter :**
- `AuthEndpoint` avec `requestOtp()`, `verifyOtp(phone, otp, name)`, `refreshToken()`, `logoutServer()` — a etendre
- `AuthNotifier` (StateNotifier) avec `requestOtp()`, `verifyOtp()`, `logout()`, `logoutAndRevoke()` — a etendre
- `AuthInterceptor` (QueuedInterceptorsWrapper) pour auto-refresh — reutiliser tel quel
- Shared packages : mefali_design (theme), mefali_core (User, UserRole, UserStatus, AuthResponse), mefali_api_client
- `mefali_livreur` app est un shell vide : juste `MaterialApp` avec `Text('mefali Livreur')`. Depend deja de mefali_design, mefali_core, mefali_api_client, mefali_offline, flutter_riverpod, go_router
- Ecrans B2C existants dans `apps/mefali_b2c/lib/features/auth/` : `phone_screen.dart`, `otp_screen.dart`, `name_screen.dart` → servir de modele pour livreur

### Patterns etablis a reproduire

**Flutter auth screens (du B2C) :**
- `ConsumerStatefulWidget` pour integration Riverpod
- `ref.read(authProvider.notifier).methodName()` pour les actions
- `go_router` avec `context.go()` / `context.push()` et donnees via `extra`
- Validation telephone : 10 chiffres exactement, prefixe `+225` auto
- OTP : auto-advance quand 6 chiffres saisis (via `onChanged`)
- Loading : spinner dans le bouton, inputs disabled pendant `isLoading`
- Erreurs : `SnackBar` rouge persistant avec action dismiss
- Succes : `SnackBar` vert bref

**Flutter GoRouter auth guard (du B2C) :**
- `_AuthRouterNotifier extends ChangeNotifier` ecoute `authProvider`
- `refreshListenable` sur le `GoRouter`
- Redirect : auth + route auth → `/home`, non-auth + route non-auth → `/auth/phone`

**Rust handler pattern :**
- `async fn handler(body: web::Json<Payload>, config: web::Data<AppConfig>, pool: web::Data<PgPool>, ...) -> Result<HttpResponse, AppError>`
- Repository : `sqlx::query_as::<_, Model>("SELECT ...").bind(param).fetch_optional(pool).await`

### Decisions d'architecture pour cette story

1. **Pas de nouvelle migration** : la table `sponsorships` et le type `sponsorship_status` existent deja (migration 001 + 012). Tout le schema DB est pret
2. **`role` optionnel dans le payload** : retrocompatibilite totale — si absent, defaut "client". L'app B2C n'envoie jamais `role`
3. **Seuls "client" et "driver" acceptes en self-registration** : les roles "merchant", "agent", "admin" sont crees par d'autres flows (agent terrain, admin dashboard). Rejeter avec 400
4. **Sponsor obligatoire pour driver** : pas de driver sans sponsor (contrainte business mefali). Le sponsor doit etre un utilisateur existant (n'importe quel role)
5. **Ecrans livreur dans l'app livreur** : PAS de code partage avec B2C pour les ecrans (chaque app a ses ecrans). Le code partage est dans les packages (mefali_api_client, mefali_core, mefali_design)
6. **Ecran d'accueil livreur = placeholder** : cette story ne gere pas les missions de livraison (Epic 5). Le home screen affiche juste le nom, le statut, et un message d'attente KYC

### Pieges a eviter

1. **NE PAS** creer de migration SQL — `sponsorships` et tous les enums existent deja
2. **NE PAS** modifier l'app `mefali_b2c` — cette story concerne uniquement le backend (multi-role) et l'app `mefali_livreur`
3. **NE PAS** accepter role="admin"/"agent"/"merchant" en self-registration — securite critique
4. **NE PAS** changer le role d'un utilisateur existant lors du login — le login retourne l'utilisateur tel quel
5. **NE PAS** oublier le `CHECK (sponsor_id != sponsored_id)` en DB — impossible de se sponsoriser soi-meme
6. **NE PAS** utiliser `sqlx::query!()` — utiliser `sqlx::query_as()` (convention projet)
7. **NE PAS** oublier `dart run build_runner build --delete-conflicting-outputs` si les modeles mefali_core changent
8. **NE PAS** ajouter `SponsorshipStatus` a mefali_core pour l'instant — seul le backend l'utilise. Le Flutter n'a pas besoin de connaitre les sponsorships dans cette story
9. **NE PAS** utiliser `MaterialApp` dans mefali_livreur — passer a `MaterialApp.router` avec `GoRouter` (comme B2C)
10. **NE PAS** oublier de lancer les 6 commandes CI avant de considerer la tache finie : `cargo build`, `cargo test`, `cargo clippy`, `cargo fmt`, `melos run analyze`, `melos run test`

### Intelligence story precedente (Story 2.2)

- **Code review findings fixes** : logout handler n'a plus besoin d'`AuthenticatedUser` (le refresh token sert de credential). `logoutAndRevoke()` utilise un Dio separe pour eviter deadlock QueuedInterceptor
- **Pattern handler Actix** : `async fn handler(body: web::Json<Payload>, config: web::Data<AppConfig>, pool: web::Data<PgPool>) -> Result<HttpResponse, AppError>`
- **Pattern repository SQLx** : `sqlx::query_as::<_, Model>("SELECT ... FROM table WHERE ...").bind(param).fetch_optional(pool).await`
- **Scope routes** : routes auth sous `web::scope("/auth")`, routes protegees sous `web::scope("/users")`
- **Tests Actix** : `test::init_service(App::new().app_data(web::Data::new(config)).route(...)).await`
- **71 tests total** (57 Rust + 14 Flutter) — ne rien casser
- **CI pipeline** : `melos run generate` (build_runner) doit etre execute avant `melos run analyze`

### Project Structure Notes

- Les ecrans auth livreur suivent la meme structure de repertoire que B2C : `features/auth/` et `features/home/`
- Le `sponsorship_repository.rs` est place dans `domain/src/users/` (pas de module `sponsorships` separe) car les sponsorships sont lies aux users dans cette phase
- Pas de nouveau endpoint REST — tout passe par `verify-otp` existant

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 2, Story 2.3]
- [Source: _bmad-output/planning-artifacts/architecture.md — Authentication & Security, Multi-role registration]
- [Source: _bmad-output/planning-artifacts/architecture.md — Data Architecture, sponsorships schema]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Registration Flows, Livreur]
- [Source: server/migrations/20260317000001_create_enums.up.sql — sponsorship_status enum]
- [Source: server/migrations/20260317000012_create_sponsorships.up.sql — sponsorships table]
- [Source: server/crates/domain/src/users/model.rs — UserRole::Driver, UserStatus::PendingKyc]
- [Source: server/crates/domain/src/users/repository.rs — create_user() a modifier]
- [Source: server/crates/domain/src/users/service.rs — verify_otp_and_register() a etendre]
- [Source: apps/mefali_b2c/lib/features/auth/ — patterns ecrans auth]
- [Source: apps/mefali_b2c/lib/app.dart — pattern GoRouter + _AuthRouterNotifier]
- [Source: _bmad-output/implementation-artifacts/2-2-jwt-authentication-system.md — Dev Notes, Code review fixes]
- [Source: CLAUDE.md — Conventions, Constraints, Build Commands]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- **T1 (Payload multi-role)**: Ajout `role` et `sponsor_phone` optionnels a `VerifyOtpPayload`. `create_user()` parametrise avec role+status. `verify_otp_and_register()` etendu : role absent → client (retrocompat), role=driver → PendingKyc + validation sponsor. `parse_registration_role()` rejette admin/merchant/agent.
- **T2 (Sponsorship repo)**: Cree `sponsorship_repository.rs` avec `create()` et `find_by_sponsored()`. Ajout `Sponsorship` struct + `SponsorshipStatus` enum avec derives sqlx/serde/Display. Exporte dans `mod.rs`.
- **T3 (Logique serveur)**: Integre dans `verify_otp_and_register()` : validation sponsor_phone requis pour driver, recherche sponsor par telephone, creation lien sponsorship. Messages d'erreur conformes aux ACs.
- **T4 (Flutter API client)**: `AuthEndpoint.verifyOtp()` accepte `role` et `sponsorPhone` named params optionnels. `AuthNotifier.verifyOtp()` propage ces parametres.
- **T5 (Ecrans livreur)**: 4 ecrans crees suivant le pattern B2C — PhoneScreen ("Inscription Livreur"), OtpScreen (auto-advance), RegistrationScreen (nom + sponsor phone +225), HomeScreen (statut pending_kyc affiché). AuthController local avec role=driver hardcode.
- **T6 (Routing livreur)**: `app.dart` reecrit avec GoRouter + `_AuthRouterNotifier` + `refreshListenable`. Routes: `/auth/phone`, `/auth/otp`, `/auth/register`, `/home`. `MaterialApp.router`.
- **T7 (Tests)**: 11 nouveaux tests Rust (parse_registration_role: 7 tests, payload backward compat: 2, sponsorship serde: 2). 68 tests Rust total. 2 tests widget livreur. 15 tests API client (+3 AuthEndpoint verifyOtp role/sponsorPhone). Pipeline CI complet OK (clippy, fmt, analyze, format, test).
- **Code review fixes**: C1 — race condition corrigee : sponsor valide AVANT creation user (evite drivers orphelins). M1 — self-sponsoring prevenu (phone == sponsor_phone → 400). C2 — 3 tests AuthEndpoint ajoutes (verifyOtp avec/sans role+sponsorPhone, login sans name).

### Change Log

- 2026-03-17: Story 2.3 Inscription Multi-Role Livreur — Implementation complete (T1-T7)
- 2026-03-17: Code review fixes — C1: race condition fix (sponsor validated before user creation), M1: self-sponsoring prevention, C2: 3 tests AuthEndpoint ajoutes, M2: Dev Notes architecture corrigee

### File List

- server/crates/domain/src/users/model.rs (MODIFIE — ajout role/sponsor_phone a VerifyOtpPayload, Sponsorship struct, SponsorshipStatus enum, tests)
- server/crates/domain/src/users/repository.rs (MODIFIE — create_user accepte role + status)
- server/crates/domain/src/users/service.rs (MODIFIE — parse_registration_role, logique multi-role, sponsorship creation, tests)
- server/crates/domain/src/users/sponsorship_repository.rs (NOUVEAU — create, find_by_sponsored)
- server/crates/domain/src/users/mod.rs (MODIFIE — export sponsorship_repository)
- server/crates/api/src/routes/auth.rs (MODIFIE — passe role/sponsor_phone a verify_otp_and_register)
- packages/mefali_api_client/lib/endpoints/auth_endpoint.dart (MODIFIE — verifyOtp accepte role, sponsorPhone)
- packages/mefali_api_client/lib/providers/auth_provider.dart (MODIFIE — verifyOtp propage role, sponsorPhone)
- apps/mefali_livreur/lib/app.dart (MODIFIE — GoRouter + auth guard complet)
- apps/mefali_livreur/lib/features/auth/auth_controller.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/auth/phone_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/auth/otp_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/auth/registration_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/home/home_screen.dart (NOUVEAU)
- packages/mefali_api_client/test/mefali_api_client_test.dart (MODIFIE — 3 tests AuthEndpoint role/sponsorPhone)
- apps/mefali_livreur/test/widget_test.dart (MODIFIE — 2 tests auth)
