# Story 2.4: Gestion du Profil Utilisateur

Status: review

## Story

En tant que **utilisateur connecte (client ou livreur)**,
Je veux **consulter et modifier mon profil (nom, telephone)**,
Afin de **garder mes informations a jour**.

## Criteres d'Acceptation

1. **AC1** : Etant donne un utilisateur connecte, quand il navigue vers l'ecran Profil, alors il voit son nom, son telephone, et son role affiches clairement
2. **AC2** : Etant donne l'ecran Profil, quand l'utilisateur modifie son nom et confirme, alors le serveur met a jour le nom et l'ecran reflete le changement immediatement
3. **AC3** : Etant donne l'ecran Profil, quand l'utilisateur tente de modifier son telephone, alors il est redirige vers un flow OTP : saisie du nouveau numero → reception OTP → verification → telephone mis a jour
4. **AC4** : Etant donne une modification de telephone, quand le nouveau numero est deja utilise par un autre compte, alors le serveur retourne 409 `{"error": {"code": "CONFLICT", "message": "Phone number already in use"}}`
5. **AC5** : Etant donne l'app `mefali_b2c`, quand un client connecte ouvre le tab Profil dans la bottom nav, alors il voit l'ecran Profil avec ses informations et un bouton Deconnexion
6. **AC6** : Etant donne l'app `mefali_livreur`, quand le livreur ouvre l'ecran Profil, alors il voit ses informations, son statut KYC, et un bouton Deconnexion
7. **AC7** : Etant donne un utilisateur qui clique sur Deconnexion, quand il confirme, alors les tokens sont revoques cote serveur, le stockage local est efface, et il est redirige vers l'ecran de connexion
8. **AC8** : Etant donne un nom invalide (vide ou > 100 caracteres), quand l'utilisateur tente de sauvegarder, alors une erreur de validation s'affiche inline sans appel API

## Taches / Sous-taches

- [x] **T1** Backend — endpoint PUT /api/v1/users/me (AC: #2, #8)
  - [x] T1.1 Ajouter `UpdateProfilePayload` dans `domain/src/users/model.rs` : `{ name: Option<String> }`. Validation : `name` non vide, max 100 caracteres
  - [x] T1.2 Ajouter `update_name(pool, user_id, name) -> Result<User, AppError>` dans `repository.rs` : UPDATE users SET name = $2, updated_at = now() WHERE id = $1 RETURNING *
  - [x] T1.3 Ajouter `update_profile(pool, user_id, payload) -> Result<User, AppError>` dans `service.rs` : valide le payload, appelle repository, retourne le user mis a jour
  - [x] T1.4 Ajouter route `PUT /api/v1/users/me` dans `routes/users.rs` : extrait `AuthenticatedUser`, parse `UpdateProfilePayload`, appelle `service::update_profile()`, retourne `ApiResponse { data: { user } }`

- [x] **T2** Backend — endpoint POST /api/v1/users/me/change-phone (AC: #3, #4)
  - [x] T2.1 Ajouter `ChangePhoneRequestPayload` dans `model.rs` : `{ new_phone: String }`. Validation : format E.164 (+225XXXXXXXXXX)
  - [x] T2.2 Ajouter `ChangePhoneVerifyPayload` dans `model.rs` : `{ new_phone: String, otp: String }`
  - [x] T2.3 Ajouter route `POST /api/v1/users/me/change-phone/request` dans `routes/users.rs` : verifie que le nouveau numero n'est pas deja pris (409 Conflict si oui), envoie OTP au nouveau numero via `otp_service::store_otp()` + SMS
  - [x] T2.4 Ajouter route `POST /api/v1/users/me/change-phone/verify` dans `routes/users.rs` : verifie OTP, met a jour le phone dans la DB, retourne le user mis a jour
  - [x] T2.5 Ajouter `update_phone(pool, user_id, new_phone) -> Result<User, AppError>` dans `repository.rs`

- [x] **T3** Flutter — endpoint et provider profil dans mefali_api_client (AC: #1, #2, #3)
  - [x] T3.1 Creer `packages/mefali_api_client/lib/endpoints/user_endpoint.dart` : classe `UserEndpoint(Dio)` avec `getProfile()` → GET /users/me, `updateProfile({String? name})` → PUT /users/me, `requestPhoneChange(String newPhone)` → POST /users/me/change-phone/request, `verifyPhoneChange(String newPhone, String otp)` → POST /users/me/change-phone/verify. Provider `userEndpointProvider`
  - [x] T3.2 Creer `packages/mefali_api_client/lib/providers/user_provider.dart` : `UserProfileNotifier extends StateNotifier<AsyncValue<User>>` avec `fetchProfile()`, `updateName(String name)`, `requestPhoneChange(String newPhone)`, `verifyPhoneChange(String newPhone, String otp)`. Provider `userProfileProvider`. Apres mise a jour, synchronise aussi `authProvider.state.user`
  - [x] T3.3 Exporter les nouveaux fichiers dans `packages/mefali_api_client/lib/mefali_api_client.dart`

- [x] **T4** Flutter — ecran Profil B2C (AC: #1, #5, #7)
  - [x] T4.1 Creer `apps/mefali_b2c/lib/features/profile/profile_screen.dart` : `ConsumerStatefulWidget`. Affiche : avatar placeholder (cercle avec initiale), nom (editable via bottom sheet ou navigation), telephone (avec bouton "Modifier"), role (badge), bouton Deconnexion en bas. Utilise `ref.watch(userProfileProvider)` avec `AsyncValue.when()` pour les etats loading/data/error
  - [x] T4.2 Creer `apps/mefali_b2c/lib/features/profile/edit_name_screen.dart` : ecran avec TextField pre-rempli du nom actuel, validation inline (non vide, max 100 chars), bouton Sauvegarder qui appelle `userProfileNotifier.updateName()`. Retour a l'ecran profil apres succes
  - [x] T4.3 Creer `apps/mefali_b2c/lib/features/profile/change_phone_screen.dart` : saisie du nouveau numero (+225), validation format, appel `requestPhoneChange()`, navigation vers ecran OTP de verification
  - [x] T4.4 Creer `apps/mefali_b2c/lib/features/profile/verify_phone_screen.dart` : saisie OTP 6 chiffres (meme pattern que auth), appel `verifyPhoneChange()`, retour au profil apres succes
  - [x] T4.5 Remplacer le `_PlaceholderTab` Profil dans `home_screen.dart` par `ProfileScreen()`
  - [x] T4.6 Ajouter les routes `/profile/edit-name`, `/profile/change-phone`, `/profile/verify-phone` dans `app.dart`

- [x] **T5** Flutter — ecran Profil Livreur (AC: #6, #7)
  - [x] T5.1 Creer `apps/mefali_livreur/lib/features/profile/profile_screen.dart` : similaire au B2C mais avec affichage du statut KYC (badge jaune "En attente KYC" si pending_kyc, badge vert "Actif" si active). Bouton Deconnexion
  - [x] T5.2 Creer les ecrans edit_name et change_phone comme pour B2C (memes patterns)
  - [x] T5.3 Ajouter une bottom nav au HomeScreen livreur (2 tabs : Accueil, Profil) OU un bouton/icone profil dans l'AppBar pour acceder au profil. Ajouter les routes correspondantes dans `app.dart`

- [x] **T6** Tests (AC: #1 a #8)
  - [x] T6.1 Tests Rust — `update_profile` : nom valide → user mis a jour, nom vide → 400, nom > 100 chars → 400
  - [x] T6.2 Tests Rust — `change-phone/request` : nouveau numero valide → OTP envoye, numero deja pris → 409, format invalide → 400
  - [x] T6.3 Tests Rust — `change-phone/verify` : OTP valide → phone mis a jour, OTP invalide → 401
  - [x] T6.4 Tests Flutter — `UserEndpoint` : getProfile retourne User, updateProfile envoie PUT, requestPhoneChange envoie POST
  - [x] T6.5 Tests Flutter — `UserProfileNotifier` : etat initial loading, fetchProfile → data, updateName → user mis a jour
  - [x] T6.6 Tests widget B2C — ProfileScreen affiche nom/phone/role, bouton Deconnexion present
  - [x] T6.7 Tests widget Livreur — ProfileScreen affiche statut KYC

## Dev Notes

### Architecture des fichiers — Ce qui est cree vs modifie

```
server/crates/
  domain/src/users/
    model.rs                                     # MODIFIE (ajout UpdateProfilePayload, ChangePhoneRequestPayload, ChangePhoneVerifyPayload)
    repository.rs                                # MODIFIE (ajout update_name, update_phone)
    service.rs                                   # MODIFIE (ajout update_profile, request_phone_change, verify_phone_change)
  api/src/routes/
    users.rs                                     # MODIFIE (ajout PUT /me, POST /me/change-phone/request, POST /me/change-phone/verify)
    mod.rs                                       # MODIFIE (si nouvelles routes necessitent reconfig)

packages/
  mefali_api_client/lib/
    endpoints/user_endpoint.dart                 # NOUVEAU
    providers/user_provider.dart                  # NOUVEAU
    mefali_api_client.dart                       # MODIFIE (export des nouveaux fichiers)

apps/mefali_b2c/lib/
  features/profile/
    profile_screen.dart                          # NOUVEAU
    edit_name_screen.dart                        # NOUVEAU
    change_phone_screen.dart                     # NOUVEAU
    verify_phone_screen.dart                     # NOUVEAU
  features/home/
    home_screen.dart                             # MODIFIE (remplacer placeholder Profil par ProfileScreen)
  app.dart                                       # MODIFIE (ajout routes /profile/*)

apps/mefali_livreur/lib/
  features/profile/
    profile_screen.dart                          # NOUVEAU
    edit_name_screen.dart                        # NOUVEAU
    change_phone_screen.dart                     # NOUVEAU
    verify_phone_screen.dart                     # NOUVEAU
  features/home/
    home_screen.dart                             # MODIFIE (ajout navigation vers profil)
  app.dart                                       # MODIFIE (ajout routes /profile/*)

tests/
  packages/mefali_api_client/test/               # MODIFIE (tests UserEndpoint + UserProfileNotifier)
  apps/mefali_b2c/test/                          # MODIFIE (tests widget ProfileScreen)
  apps/mefali_livreur/test/                      # MODIFIE (tests widget ProfileScreen)
  server/ (inline #[cfg(test)])                  # tests update_profile, change_phone
```

### Etat actuel du code — Ce qui existe deja (Stories 2.1 + 2.2 + 2.3)

**Backend Rust :**
- `GET /api/v1/users/me` existe deja dans `routes/users.rs` — retourne le user via `AuthenticatedUser` extractor
- `repository::find_by_id(pool, id) -> Option<User>` et `find_by_phone(pool, phone) -> Option<User>` existent
- `otp_service` complet : `generate_otp()`, `store_otp()`, `verify_otp()`, `check_rate_limit()` — reutiliser pour changement de telephone
- `request_otp()` dans service.rs envoie OTP via SMS provider — reutiliser la logique pour change-phone
- `AppError` avec `BadRequest`, `NotFound`, `Unauthorized`, `Forbidden`, etc. Il manque `Conflict` → ajouter `Conflict(String)` mappant vers HTTP 409
- Format reponse : `ApiResponse::new(data)` → `{"data": {...}}`
- User model : `id, phone, name, role, status, city_id, fcm_token, created_at, updated_at`
- `AuthenticatedUser` extractor : parse JWT, retourne `user_id` et `role` — pret a l'emploi

**Base de donnees :**
- Table `users` : `phone VARCHAR(20) UNIQUE NOT NULL`, `name VARCHAR(100)` — la contrainte UNIQUE sur phone empeche les doublons
- Trigger `trigger_set_updated_at` met a jour `updated_at` automatiquement
- NE PAS creer de nouvelle migration — le schema est suffisant pour cette story

**Flutter :**
- `User` model dans `mefali_core` : `id, phone, name?, role, status` avec `@JsonSerializable(fieldRename: FieldRename.snake)`
- `authProvider` (StateNotifier) stocke `AuthState { user, accessToken, refreshToken, isLoading, error }`
- `AuthNotifier.logoutAndRevoke()` existe : revoque le refresh token server-side + efface le storage → reutiliser pour le bouton Deconnexion
- `dioProvider` cree un Dio avec base URL `/api/v1`, interceptors, timeouts → reutiliser pour `UserEndpoint`
- `authEndpointProvider` = pattern a reproduire pour `userEndpointProvider`
- B2C `HomeScreen` utilise `IndexedStack` avec 4 tabs dont Profil est un `_PlaceholderTab` → remplacer
- Livreur `HomeScreen` affiche nom + statut KYC mais pas de navigation profil
- `FlutterSecureStorage` dans `AuthNotifier` pour persistance tokens
- OTP screens existants dans B2C et livreur → reutiliser le pattern pour verify_phone_screen

### Patterns etablis a reproduire

**Flutter endpoint pattern (de `AuthEndpoint`) :**
```dart
class UserEndpoint {
  final Dio _dio;
  UserEndpoint(this._dio);

  Future<User> getProfile() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data['data']['user']);
  }

  Future<User> updateProfile({String? name}) async {
    final response = await _dio.put('/users/me', data: {
      if (name != null) 'name': name,
    });
    return User.fromJson(response.data['data']['user']);
  }
}

final userEndpointProvider = Provider<UserEndpoint>((ref) {
  return UserEndpoint(ref.watch(dioProvider));
});
```

**Flutter StateNotifier pattern (de `AuthNotifier`) :**
```dart
class UserProfileNotifier extends StateNotifier<AsyncValue<User>> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref.read(userEndpointProvider).getProfile());
  }

  Future<void> updateName(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _ref.read(userEndpointProvider).updateProfile(name: name);
      // Synchroniser avec authProvider
      final authState = _ref.read(authProvider);
      _ref.read(authProvider.notifier).updateUser(user);
      return user;
    });
  }
}
```

**Flutter screen pattern (ConsumerStatefulWidget) :**
- `ConsumerStatefulWidget` pour les ecrans avec formulaires
- `ConsumerWidget` pour les ecrans read-only
- `ref.watch()` pour observer l'etat, `ref.read()` pour les actions
- `context.go()` pour navigation simple, `context.push()` pour empiler
- Erreurs : `SnackBar` rouge avec message
- Succes : `SnackBar` vert bref puis navigation retour
- Loading : bouton disabled avec `CircularProgressIndicator` inline

**Rust handler pattern :**
```rust
async fn update_profile(
    auth: AuthenticatedUser,
    body: web::Json<UpdateProfilePayload>,
    pool: web::Data<PgPool>,
) -> Result<HttpResponse, AppError> {
    let user = service::update_profile(&pool, auth.user_id, body.into_inner()).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::new(json!({ "user": user }))))
}
```

**Rust repository pattern (sqlx) :**
```rust
pub async fn update_name(pool: &PgPool, user_id: Id, name: &str) -> Result<User, AppError> {
    sqlx::query_as::<_, User>(
        "UPDATE users SET name = $2 WHERE id = $1 RETURNING id, phone, name, role, status, city_id, fcm_token, created_at, updated_at"
    )
    .bind(user_id)
    .bind(name)
    .fetch_one(pool)
    .await
    .map_err(|e| AppError::DatabaseError(e.to_string()))
}
```

### Decisions d'architecture pour cette story

1. **Pas de nouvelle migration** : le schema `users` est suffisant (name VARCHAR(100) permet la modification, phone UNIQUE gere les conflits)
2. **AppError::Conflict** : ajouter une variante `Conflict(String)` a l'enum `AppError` dans `common/src/error.rs` mappee vers HTTP 409. Necessaire pour le cas "phone already in use"
3. **Changement de telephone = flow en 2 etapes** : request (envoie OTP au nouveau numero) → verify (verifie OTP + met a jour). On reutilise `otp_service` existant
4. **Synchronisation authProvider** : apres `updateName` ou `verifyPhoneChange`, mettre a jour `authProvider.state.user` pour que toute l'app reflette le changement. Ajouter une methode `updateUser(User user)` a `AuthNotifier` si elle n'existe pas
5. **B2C : profil comme tab dans HomeScreen** : le 4eme tab (Profil) de la bottom nav est deja un placeholder dans `IndexedStack`. Le remplacer par le `ProfileScreen`. Les sous-ecrans (edit-name, change-phone, verify-phone) sont des routes GoRouter separees qui s'empilent par-dessus
6. **Livreur : profil accessible depuis le HomeScreen** : ajouter une icone profil dans l'AppBar du HomeScreen ou un lien textuel. PAS de bottom nav complete (le livreur n'a pas encore assez de features pour justifier 4 tabs). Ou bien, ajouter 2 tabs simples (Accueil, Profil)
7. **Ecrans profil livreur et B2C quasi-identiques** : meme structure, mais le livreur montre en plus le statut KYC. NE PAS partager les widgets entre apps — chaque app a ses propres ecrans (convention projet)
8. **Validation frontend + backend** : nom non vide et max 100 chars valide cote Flutter ET cote Rust. Phone valide format E.164 des 2 cotes

### Pieges a eviter

1. **NE PAS** creer de migration SQL — le schema existant suffit
2. **NE PAS** oublier d'ajouter `Conflict(String)` a `AppError` dans `common/src/error.rs` avec mapping HTTP 409
3. **NE PAS** oublier de synchroniser `authProvider` apres modification du profil — sinon le nom affiche dans les autres ecrans sera obsolete
4. **NE PAS** permettre le changement de role via l'endpoint update-profile — le role est immutable via cette route
5. **NE PAS** envoyer l'OTP de changement de phone a l'ANCIEN numero — l'envoyer au NOUVEAU numero (c'est le nouveau numero qu'on verifie)
6. **NE PAS** oublier de verifier que le nouveau telephone n'est pas deja pris AVANT d'envoyer l'OTP (sinon on gaspille un SMS)
7. **NE PAS** modifier les ecrans d'auth existants (phone_screen, otp_screen) — le flow de changement de telephone a ses propres ecrans
8. **NE PAS** utiliser `sqlx::query!()` — convention projet : `sqlx::query_as()` partout
9. **NE PAS** oublier de lister toutes les colonnes dans le RETURNING du UPDATE (comme dans les autres queries)
10. **NE PAS** ajouter de champs au User model Dart (comme avatar_url) — cette story se limite a name et phone
11. **NE PAS** oublier `dart run build_runner build --delete-conflicting-outputs` si les modeles mefali_core changent

### Intelligence story precedente (Story 2.3)

- **Pattern ecrans auth** : `ConsumerStatefulWidget` + `ref.read(provider.notifier).action()` + `SnackBar` pour feedback
- **GoRouter auth guard** : `_AuthRouterNotifier` + `refreshListenable` — ne pas casser ce pattern en ajoutant les routes profil
- **Tests CI** : 68 tests Rust + 17 tests Flutter au total actuellement — ne rien casser
- **Code review fix story 2.3** : race condition corrigee en validant le sponsor AVANT creation user — meme principe ici : verifier que le nouveau phone n'est pas pris AVANT d'envoyer l'OTP
- **AuthController pattern livreur** : utilise un `AutoDisposeAsyncNotifier` local pour orchestrer le flow auth — reproduire ce pattern pour le flow change-phone si necessaire
- **Pipeline CI** : `cargo build`, `cargo test`, `cargo clippy`, `cargo fmt --all -- --check`, `melos run analyze`, `melos run test` — les 6 doivent passer

### Scope et limites de cette story

- **INCLUS** : Vue profil (nom, phone, role), modification nom, changement telephone avec OTP, deconnexion, pour B2C et livreur
- **EXCLUS** : Avatar/photo de profil (pas dans les ACs), modification d'adresse (Epic 4), gestion profil marchand (Epic 3 FR4), suppression de compte, notifications preferences

### Project Structure Notes

- Les ecrans profil suivent la convention feature-first : `features/profile/` dans chaque app
- `UserEndpoint` et `UserProfileNotifier` dans `mefali_api_client` — partages entre B2C et livreur
- Pas de code partage d'ecrans entre apps — seuls les packages sont partages
- Les routes profil sont des sous-routes de la navigation principale, pas des tabs separees

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 2, Story 2.4]
- [Source: _bmad-output/planning-artifacts/prd.md — FR2: Client B2C peut consulter et modifier son profil (nom, telephone)]
- [Source: _bmad-output/planning-artifacts/architecture.md — Authentication & Security, API Patterns, Naming Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md — Data Architecture, users table schema]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Bottom nav B2C 4 items (Home, Recherche, Commandes, Profil)]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Form Patterns, Button Hierarchy, Feedback Patterns]
- [Source: _bmad-output/implementation-artifacts/2-3-multi-role-registration.md — Dev Notes, patterns etablis, CI pipeline]
- [Source: server/crates/api/src/routes/users.rs — GET /api/v1/users/me existant]
- [Source: server/crates/domain/src/users/model.rs — User struct, UserRole, UserStatus]
- [Source: server/crates/domain/src/users/repository.rs — find_by_id, find_by_phone, create_user]
- [Source: server/crates/domain/src/users/otp_service.rs — store_otp, verify_otp, check_rate_limit]
- [Source: server/crates/common/src/error.rs — AppError enum (manque Conflict)]
- [Source: packages/mefali_api_client/lib/endpoints/auth_endpoint.dart — pattern endpoint]
- [Source: packages/mefali_api_client/lib/providers/auth_provider.dart — AuthNotifier pattern]
- [Source: apps/mefali_b2c/lib/features/home/home_screen.dart — IndexedStack 4 tabs, Profil = placeholder]
- [Source: apps/mefali_livreur/lib/features/home/home_screen.dart — statut KYC affiche]
- [Source: CLAUDE.md — Conventions, Constraints, Build Commands]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- **T1 (PUT /users/me)**: Ajout `UpdateProfilePayload` dans model.rs. `update_name()` dans repository.rs (UPDATE + RETURNING). `update_profile()` dans service.rs avec validation nom (non vide, max 100 chars, trim). Route `PUT /me` dans users.rs. `AppError::Conflict` ajoute a error.rs (HTTP 409).
- **T2 (change-phone)**: Ajout `ChangePhoneRequestPayload` et `ChangePhoneVerifyPayload` dans model.rs. `update_phone()` dans repository.rs. `request_phone_change()` dans service.rs (valide format, verifie unicite 409, envoie OTP via SMS). `verify_phone_change()` re-verifie unicite + OTP + update phone. Routes `POST /me/change-phone/request` et `/verify`.
- **T3 (Flutter API client)**: `UserEndpoint` cree avec getProfile/updateProfile/requestPhoneChange/verifyPhoneChange. `UserProfileNotifier` (StateNotifier + AsyncValue) avec sync authProvider. `AuthNotifier.updateUser()` ajoute. Exports dans mefali_api_client.dart.
- **T4 (B2C profil)**: 4 ecrans crees : ProfileScreen (avatar + nom/phone/role + deconnexion), EditNameScreen (validation + save), ChangePhoneScreen (+225 prefix), VerifyPhoneScreen (OTP 6 chiffres auto-submit). Placeholder Profil remplace dans HomeScreen. Routes GoRouter ajoutees.
- **T5 (Livreur profil)**: 4 ecrans identiques + badge KYC status (jaune pending, vert actif). Icone profil ajoutee dans AppBar du HomeScreen. Routes GoRouter ajoutees.
- **T6 (Tests)**: 10 tests Rust ajoutes (model payload serde + service validation name/noop + Conflict status code). 6 tests Flutter ajoutes (UserEndpoint GET/PUT/POST + AuthNotifier.updateUser). 78 tests Rust total, 24 tests Flutter total. Tous passent. CI pipeline complet OK.

### Change Log

- 2026-03-17: Story 2.4 Gestion du Profil Utilisateur — Implementation complete (T1-T6)

### File List

- server/crates/common/src/error.rs (MODIFIE — ajout AppError::Conflict + HTTP 409 mapping + test)
- server/crates/domain/src/users/model.rs (MODIFIE — ajout UpdateProfilePayload, ChangePhoneRequestPayload, ChangePhoneVerifyPayload, tests)
- server/crates/domain/src/users/repository.rs (MODIFIE — ajout update_name, update_phone)
- server/crates/domain/src/users/service.rs (MODIFIE — ajout update_profile, request_phone_change, verify_phone_change, tests)
- server/crates/api/src/routes/users.rs (MODIFIE — ajout PUT /me, POST /me/change-phone/request, POST /me/change-phone/verify)
- server/crates/api/src/routes/mod.rs (MODIFIE — ajout routes users)
- packages/mefali_api_client/lib/endpoints/user_endpoint.dart (NOUVEAU)
- packages/mefali_api_client/lib/providers/user_provider.dart (NOUVEAU)
- packages/mefali_api_client/lib/providers/auth_provider.dart (MODIFIE — ajout updateUser())
- packages/mefali_api_client/lib/mefali_api_client.dart (MODIFIE — exports user_endpoint, user_provider)
- apps/mefali_b2c/lib/features/profile/profile_screen.dart (NOUVEAU)
- apps/mefali_b2c/lib/features/profile/edit_name_screen.dart (NOUVEAU)
- apps/mefali_b2c/lib/features/profile/change_phone_screen.dart (NOUVEAU)
- apps/mefali_b2c/lib/features/profile/verify_phone_screen.dart (NOUVEAU)
- apps/mefali_b2c/lib/features/home/home_screen.dart (MODIFIE — ProfileScreen remplace placeholder)
- apps/mefali_b2c/lib/app.dart (MODIFIE — routes profil)
- apps/mefali_livreur/lib/features/profile/profile_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/profile/edit_name_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/profile/change_phone_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/profile/verify_phone_screen.dart (NOUVEAU)
- apps/mefali_livreur/lib/features/home/home_screen.dart (MODIFIE — icone profil dans AppBar)
- apps/mefali_livreur/lib/app.dart (MODIFIE — routes profil)
- packages/mefali_api_client/test/mefali_api_client_test.dart (MODIFIE — 6 tests UserEndpoint + AuthNotifier)
