# Story 2.2: JWT Authentication System

Status: ready-for-dev

## Story

En tant que **tout utilisateur (client, marchand, livreur, agent, admin)**,
Je veux **me connecter avec des tokens auto-rafraîchissants**,
Afin de **ne pas avoir à me reconnecter constamment**.

## Critères d'Acceptation

1. **AC1** : Étant donné un utilisateur existant, quand il saisit son téléphone + OTP, alors il reçoit un access token (15 min) + refresh token (7 jours) et voit l'écran d'accueil
2. **AC2** : Étant donné un access token expiré, quand le Dio interceptor détecte un 401, alors il appelle automatiquement `POST /api/v1/auth/refresh` avec le refresh token et rejoue la requête originale — transparence totale pour l'utilisateur
3. **AC3** : Étant donné un refresh valide, quand le serveur reçoit `POST /api/v1/auth/refresh`, alors il retourne un nouveau access token + un nouveau refresh token (rotation) et invalide l'ancien refresh token
4. **AC4** : Étant donné une requête vers un endpoint protégé, quand le header `Authorization: Bearer <token>` est présent et valide, alors le handler reçoit un `AuthenticatedUser` extrait du JWT
5. **AC5** : Étant donné un token invalide/expiré/absent sur un endpoint protégé, quand le middleware vérifie le JWT, alors il retourne 401 `{"error": {"code": "UNAUTHORIZED", "message": "..."}}`
6. **AC6** : Étant donné un endpoint restreint par rôle (ex: admin-only), quand un utilisateur avec un rôle insuffisant tente d'y accéder, alors il reçoit 403 `{"error": {"code": "FORBIDDEN", "message": "..."}}`
7. **AC7** : Étant donné un refresh token expiré ou invalide, quand le Dio interceptor échoue à rafraîchir, alors l'utilisateur est déconnecté et redirigé vers l'écran de login

## Tâches / Sous-tâches

- [ ] **T1** Endpoint login pour utilisateurs existants (AC: #1)
  - [ ] T1.1 Ajouter `POST /api/v1/auth/login` dans `routes/auth.rs` — body: `{"phone": "+225XXXXXXXXXX"}` → appelle `request_otp` existant. Même flow que registration mais sans création de compte
  - [ ] T1.2 Modifier `verify-otp` dans `service.rs` pour distinguer login vs registration : si user existe et `name` est absent → login (pas de création), si user n'existe pas et `name` présent → registration. Si user n'existe pas et `name` absent → erreur `USER_NOT_FOUND`
  - [ ] T1.3 Ajouter variante `NotFound` à `AppError` (HTTP 404) si pas déjà présente

- [ ] **T2** Refresh token avec rotation (AC: #3)
  - [ ] T2.1 Créer table `refresh_tokens` via migration SQLx : `id UUID PK`, `user_id UUID FK→users`, `token_hash VARCHAR(64) NOT NULL` (SHA-256 du token), `expires_at TIMESTAMPTZ NOT NULL`, `revoked_at TIMESTAMPTZ NULL`, `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`. Index sur `token_hash` et `user_id`
  - [ ] T2.2 Créer `domain/src/users/refresh_token_repository.rs` — `create(pool, user_id, token_hash, expires_at)`, `find_by_hash(pool, hash) -> Option<RefreshToken>`, `revoke(pool, id)`, `revoke_all_for_user(pool, user_id)`, `cleanup_expired(pool)`
  - [ ] T2.3 Modifier `generate_auth_response()` dans `service.rs` : le refresh token est un UUID v4 opaque (pas un JWT), hashé SHA-256 avant stockage en DB. L'access token reste un JWT signé HS256
  - [ ] T2.4 Créer `POST /api/v1/auth/refresh` dans `routes/auth.rs` — body: `{"refresh_token": "uuid"}`. Vérifie hash en DB, vérifie non-révoqué et non-expiré, révoque l'ancien, crée un nouveau couple access+refresh → retourne `{"data": {"access_token": "...", "refresh_token": "..."}}`
  - [ ] T2.5 Créer `POST /api/v1/auth/logout` dans `routes/auth.rs` — body: `{"refresh_token": "uuid"}`. Révoque le refresh token en DB. Endpoint protégé par auth middleware

- [ ] **T3** JWT middleware et extracteur Actix (AC: #4, #5, #6)
  - [ ] T3.1 Créer `api/src/extractors/authenticated_user.rs` — struct `AuthenticatedUser { user_id: Uuid, role: UserRole }` implémentant `FromRequest`. Extrait et décode le JWT du header `Authorization: Bearer <token>`, valide signature HS256 + expiration. Retourne 401 si invalide
  - [ ] T3.2 Créer `api/src/middleware/role_guard.rs` — fonction/guard `require_role(roles: &[UserRole])` qui vérifie que `AuthenticatedUser.role` est dans la liste. Retourne 403 sinon
  - [ ] T3.3 Mettre à jour `routes/mod.rs` : appliquer le middleware auth sur un nouveau scope `/api/v1/` pour les endpoints protégés. Les routes `/auth/*` restent publiques. Ajouter un endpoint test `GET /api/v1/users/me` qui retourne le user depuis le JWT
  - [ ] T3.4 Implémenter `GET /api/v1/users/me` dans `routes/users.rs` — utilise `AuthenticatedUser` extractor, charge le user depuis DB via `find_by_id()`, retourne `{"data": {"user": {...}}}`

- [ ] **T4** Dio interceptor auto-refresh Flutter (AC: #2, #7)
  - [ ] T4.1 Créer `packages/mefali_api_client/lib/dio_client/auth_interceptor.dart` — `QueuedInterceptorsWrapper` qui intercepte les réponses 401 : lock pour éviter les appels refresh concurrents, appelle `POST /auth/refresh` avec le refresh token stocké, met à jour les tokens dans SecureStorage, rejoue la requête originale avec le nouveau access token. Si refresh échoue → déclenche logout
  - [ ] T4.2 Modifier `dio_client.dart` pour ajouter `AuthInterceptor` dans la chaîne d'intercepteurs Dio, avec injection du `authProvider` pour accéder aux tokens et déclencher le logout
  - [ ] T4.3 Modifier `auth_provider.dart` : ajouter méthode `refreshTokens(accessToken, refreshToken)` pour mettre à jour les tokens en mémoire + SecureStorage. Ajouter `onLogout` callback pour la redirection

- [ ] **T5** Amélioration auth guard go_router (AC: #7)
  - [ ] T5.1 Modifier le redirect go_router dans `app.dart` : au démarrage, tenter `loadFromStorage()` puis valider le token côté Flutter (vérifier l'expiration du JWT décodé localement). Si access expiré mais refresh présent → laisser l'interceptor gérer. Si aucun token → redirect `/auth/phone`
  - [ ] T5.2 Écouter le `authProvider` pour détecter le logout (state.isAuthenticated passe à false) → redirect automatique vers `/auth/phone`

- [ ] **T6** Tests (AC: #1 à #7)
  - [ ] T6.1 Tests unitaires Rust — refresh token : création, recherche par hash, révocation, cleanup expiré
  - [ ] T6.2 Tests unitaires Rust — auth extracteur : token valide → AuthenticatedUser, token expiré → 401, token absent → 401, mauvaise signature → 401
  - [ ] T6.3 Tests unitaires Rust — role guard : rôle autorisé → pass, rôle non-autorisé → 403
  - [ ] T6.4 Tests unitaires Rust — refresh endpoint : refresh valide → nouveaux tokens, refresh expiré → 401, refresh révoqué → 401, rotation vérifie révocation de l'ancien
  - [ ] T6.5 Tests unitaires Rust — login vs registration : user existant sans name → login OK, user inexistant sans name → 404, user inexistant avec name → registration OK
  - [ ] T6.6 Tests unitaires Flutter — auth interceptor : mock 401 → vérifie appel refresh → vérifie replay requête, mock refresh fail → vérifie logout déclenché
  - [ ] T6.7 Tests widget Flutter — vérifier que le logout redirige vers phone_screen

## Dev Notes

### Architecture des fichiers — Ce qui est créé vs modifié

```
server/
  migrations/
    YYYYMMDDHHMMSS_create_refresh_tokens.up.sql    # NOUVEAU
    YYYYMMDDHHMMSS_create_refresh_tokens.down.sql   # NOUVEAU
  crates/
    api/src/
      extractors/
        mod.rs                                       # MODIFIÉ (export authenticated_user)
        authenticated_user.rs                        # NOUVEAU
      middleware/
        mod.rs                                       # MODIFIÉ (export role_guard)
        role_guard.rs                                # NOUVEAU
      routes/
        mod.rs                                       # MODIFIÉ (ajout scope protégé, route /users/me)
        auth.rs                                      # MODIFIÉ (ajout login, refresh, logout)
        users.rs                                     # NOUVEAU
    domain/src/users/
      mod.rs                                         # MODIFIÉ (export refresh_token_repository)
      service.rs                                     # MODIFIÉ (login logic, refresh token opaque)
      repository.rs                                  # MODIFIÉ (ajout find_by_id)
      refresh_token_repository.rs                    # NOUVEAU

packages/
  mefali_api_client/lib/
    dio_client/
      dio_client.dart                                # MODIFIÉ (ajout AuthInterceptor)
      auth_interceptor.dart                          # NOUVEAU
    endpoints/
      auth_endpoint.dart                             # MODIFIÉ (ajout refreshToken, logout)
    providers/
      auth_provider.dart                             # MODIFIÉ (ajout refreshTokens, onLogout)

apps/mefali_b2c/lib/
  app.dart                                           # MODIFIÉ (auth guard amélioré, listener logout)
```

### État actuel du code — Ce qui existe déjà (Story 2.1)

**Backend Rust :**
- `POST /api/v1/auth/request-otp` et `POST /api/v1/auth/verify-otp` fonctionnels
- `generate_auth_response()` dans `service.rs` génère déjà un access JWT (HS256) + refresh JWT — à modifier : le refresh doit devenir un UUID opaque hashé en DB au lieu d'un JWT
- `JwtClaims { sub, role, iat, exp }` déjà défini dans `service.rs`
- `jsonwebtoken = "9"` déjà dans workspace dependencies
- `AppConfig` charge déjà `jwt_secret`, `jwt_access_expiry` (900s), `jwt_refresh_expiry` (604800s)
- `AppError` avec `BadRequest`, `Unauthorized`, `Forbidden`, `TooManyRequests` — vérifier si `NotFound` existe, sinon l'ajouter
- `ApiResponse<T>` pour les réponses succès — pattern `{"data": ...}`
- `extractors/mod.rs` et `middleware/mod.rs` sont des fichiers VIDES avec commentaires placeholder
- `PgPool`, `RedisConnectionManager`, `AppConfig`, `SmsProvider` déjà injectés dans app state Actix

**Flutter :**
- `AuthEndpoint` avec `requestOtp()` et `verifyOtp()` — ajouter `refreshToken()` et `logout()`
- `AuthNotifier` (StateNotifier) stocke `accessToken`, `user` dans SecureStorage — ajouter logique refresh
- `Dio` singleton avec baseUrl `http://10.0.2.2:8090/api/v1` — ajouter interceptor
- `go_router` avec redirect basique si pas de token — améliorer avec écoute du state auth

### Décisions d'architecture pour cette story

1. **Refresh token = UUID opaque** (PAS un JWT) : stocké hashé (SHA-256) en DB, permet la révocation explicite et la rotation. L'access token reste un JWT stateless
2. **Table `refresh_tokens` en DB** : contrairement à Story 2.1 qui était full-stateless, la rotation nécessite un stockage server-side. Le coût DB est acceptable (1 row par session active)
3. **`QueuedInterceptorsWrapper`** (pas `InterceptorsWrapper`) : Dio queued interceptor garantit qu'un seul refresh s'exécute même si plusieurs requêtes échouent en 401 simultanément
4. **Extracteur `FromRequest`** (pas un middleware global) : l'`AuthenticatedUser` est extrait par endpoint, permettant de mixer endpoints publics et protégés dans le même scope si nécessaire
5. **Role guard séparé** : le middleware de rôle est distinct de l'extracteur auth, permettant une composition flexible `AuthenticatedUser` + `require_role()`

### Conventions backend critiques (rappel)

- **snake_case partout** : JSON fields, DB columns, endpoints
- **Response wrappers** : `{"data": ...}` succès, `{"error": {"code": "...", "message": "...", "details": null}}` erreur
- **UUID v4** pour tous les IDs (y compris refresh token)
- **`sqlx::query_as()`** avec structs `FromRow` — PAS `sqlx::query!()`
- **Workspace deps** : ajouter dans `server/Cargo.toml` `[workspace.dependencies]`, puis `.workspace = true` dans le crate
- **`thiserror`** dans domain, mappé à HTTP status dans api via `AppError`
- **SHA-256** : utiliser `sha2` crate (probablement à ajouter) pour hasher les refresh tokens

### Conventions Flutter critiques (rappel)

- **Riverpod** `autoDispose` par défaut
- **`@JsonSerializable(fieldRename: FieldRename.snake)`** pour tous les modèles
- **`prefer_single_quotes`**, **`prefer_const_constructors`**, **`avoid_print`**
- **`prefer_relative_imports`** dans chaque package
- **`dart run build_runner build`** si nouveaux modèles avec `@JsonSerializable`

### Pièges à éviter

1. **NE PAS** laisser le refresh token comme JWT — il DOIT devenir un UUID opaque hashé en DB pour permettre la révocation
2. **NE PAS** stocker le refresh token en clair en DB — hasher avec SHA-256
3. **NE PAS** utiliser `InterceptorsWrapper` classique pour le refresh — utiliser `QueuedInterceptorsWrapper` pour gérer les requêtes concurrentes
4. **NE PAS** mettre le middleware auth en global sur tout le serveur — les routes `/auth/*` doivent rester publiques
5. **NE PAS** oublier de révoquer l'ancien refresh token lors de la rotation — c'est le point clé de la sécurité
6. **NE PAS** décoder le JWT côté Flutter pour valider l'auth — la validation se fait côté serveur. Côté Flutter, on vérifie juste l'expiration localement pour décider si on tente le refresh avant l'appel API
7. **NE PAS** oublier le `down.sql` pour la migration refresh_tokens
8. **NE PAS** créer de nouvelle migration pour modifier la table `users` — elle est déjà complète
9. **NE PAS** utiliser `sqlx::query!()` — utiliser `sqlx::query_as()` ou `sqlx::query()`
10. **NE PAS** oublier de lancer les 6 commandes CI avant de considérer la tâche finie

### Intelligence story précédente (Story 2.1)

- **Pattern handler Actix** : `async fn handler(config: web::Data<AppConfig>, pool: web::Data<PgPool>, redis: web::Data<redis::aio::ConnectionManager>, body: web::Json<Request>) -> Result<HttpResponse, AppError>`
- **Pattern repository SQLx** : `sqlx::query_as::<_, User>("SELECT ... FROM users WHERE ...")`.fetch_optional(pool).await`
- **Pattern scope routes** : `web::scope("/auth").route("/request-otp", web::post().to(auth::request_otp))`
- **SMS provider** : injecté via `web::Data<Arc<dyn SmsProvider>>` dans app state
- **Redis ConnectionManager** : injecté via `web::Data<redis::aio::ConnectionManager>`
- **User upsert** : `ON CONFLICT (phone) DO UPDATE` dans `create_user`
- **Tous les 44 tests existants passent** — ne rien casser

### Project Structure Notes

- Extracteur auth → `crates/api/src/extractors/authenticated_user.rs`
- Role guard → `crates/api/src/middleware/role_guard.rs`
- Refresh token repo → `crates/domain/src/users/refresh_token_repository.rs`
- Routes users → `crates/api/src/routes/users.rs`
- Auth interceptor Dio → `packages/mefali_api_client/lib/dio_client/auth_interceptor.dart`

### Références

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 2, Story 2.2]
- [Source: _bmad-output/planning-artifacts/architecture.md — Authentication & Security, JWT multi-rôle]
- [Source: _bmad-output/planning-artifacts/architecture.md — API & Communication Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md — Data Architecture, users schema]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Empty States & Errors, Feedback Patterns]
- [Source: _bmad-output/implementation-artifacts/2-1-phone-otp-registration-b2c.md — Dev Notes complets]
- [Source: CLAUDE.md — Conventions, Constraints, Build Commands]
- [Source: server/crates/domain/src/users/service.rs — JwtClaims, generate_auth_response()]
- [Source: server/crates/api/src/extractors/mod.rs — placeholder vide]
- [Source: server/crates/api/src/middleware/mod.rs — placeholder vide]
- [Source: server/crates/common/src/error.rs — AppError enum]
- [Source: server/crates/common/src/config.rs — AppConfig jwt_secret, jwt_access_expiry, jwt_refresh_expiry]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### Change Log

### File List
