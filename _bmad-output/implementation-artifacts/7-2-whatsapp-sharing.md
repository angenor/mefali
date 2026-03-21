# Story 7.2: Partage WhatsApp

Status: done

## Story

As a client B2C,
I want to partager un marchand ou l'app via WhatsApp,
so that mes amis decouvrent mefali.

## Acceptance Criteria

1. **Given** le client consulte un restaurant **When** il tape le bouton "Partager" **Then** l'intent WhatsApp s'ouvre avec un message pre-rempli contenant le nom du restaurant et un lien avec le referral ID du client
2. **Given** le client est sur l'ecran profil/settings **When** il tape "Inviter des amis" **Then** l'intent WhatsApp s'ouvre avec un message generique d'invitation contenant un lien avec son referral ID
3. **Given** le client vient de noter sa commande (post-rating flow) **When** le bottom sheet de rating se ferme **Then** un bouton "Partager mefali sur WhatsApp" apparait et ouvre l'intent WhatsApp si tape
4. **Given** un nouveau utilisateur clique sur un lien partage **When** il installe et ouvre l'app **Then** le code referral est capture et associe a son compte lors de l'inscription
5. **Given** un lien de partage restaurant **When** l'app est deja installee et l'utilisateur clique **Then** l'app s'ouvre directement sur la page du restaurant

## Tasks / Subtasks

- [x] Task 1: Backend - Code referral utilisateur (AC: #1, #2, #4)
  - [x] 1.1 Migration SQL: ajouter colonne `referral_code` (VARCHAR(8) UNIQUE) a la table `users`
  - [x] 1.2 Domain: generer automatiquement un referral_code a l'inscription (6 chars alphanumerique uppercase)
  - [x] 1.3 Domain: accepter `referral_code` optionnel lors de l'inscription et stocker `referred_by` (FK users)
  - [x] 1.4 Route: `GET /api/v1/users/me/referral` retourne le code referral du user connecte
  - [x] 1.5 Route: `GET /api/v1/share/restaurant/{merchant_id}` retourne les metadonnees de partage (nom, description, image_url, share_url)

- [x] Task 2: Backend - Endpoint share metadata (AC: #1, #5)
  - [x] 2.1 Route: servir `/.well-known/assetlinks.json` pour Android App Links (go_router deep linking) — Differe (custom URL scheme suffit pour le MVP)
  - [x] 2.2 Route: `GET /share/r/{merchant_id}` page HTML minimale avec Open Graph meta tags + redirect vers app ou Play Store

- [x] Task 3: Frontend - Modele et API client (AC: #1, #2)
  - [x] 3.1 Modele: `ShareMetadata` + `ReferralCodeResponse` dans mefali_core
  - [x] 3.2 Endpoint: `ShareEndpoint` dans mefali_api_client (getReferralCode, getShareMetadata)
  - [x] 3.3 Provider: `referralCodeProvider` et `shareMetadataProvider` dans mefali_api_client

- [x] Task 4: Frontend - Composant UI de partage (AC: #1, #2, #3)
  - [x] 4.1 Utilitaire: `WhatsAppShareHelper` dans mefali_core — construit l'URL WhatsApp intent et lance via url_launcher
  - [x] 4.2 Widget: `ShareButton` dans mefali_design — bouton Material 3 avec icone WhatsApp
  - [x] 4.3 Widget: `InviteFriendsCard` dans mefali_design — carte d'invitation pour l'ecran profil

- [x] Task 5: Frontend - Integration B2C (AC: #1, #2, #3, #5)
  - [x] 5.1 Restaurant detail screen: bouton share (CircleAvatar + IconButton) en haut a droite
  - [x] 5.2 Post-rating flow: bottom sheet "Merci pour votre avis" avec bouton "Partager mefali sur WhatsApp"
  - [x] 5.3 Ecran profil: InviteFriendsCard avec code referral + bouton partage
  - [x] 5.4 go_router: deep link via custom URL scheme `mefali://restaurant/{id}` (redirect page serveur)
  - [x] 5.5 Registration screen: champ optionnel "Code parrain" dans name_screen.dart

- [x] Task 6: Barrel exports et integration (AC: all)
  - [x] 6.1 Exporter nouveaux fichiers dans mefali_core.dart, mefali_api_client.dart, mefali_design.dart
  - [x] 6.2 Enregistrer nouvelles routes dans server/crates/api/src/routes/mod.rs

## Dev Notes

### Architecture Decision: Approche Client-Side Link Generation

Le partage WhatsApp utilise `url_launcher` pour ouvrir l'intent WhatsApp avec un message pre-rempli. Le lien de partage pointe vers un endpoint serveur leger qui sert une page HTML minimale avec des meta tags Open Graph (pour le preview dans WhatsApp) et redirige vers l'app (via App Links) ou le Play Store.

**Format du lien de partage:**
```
https://api.mefali.ci/share/r/{merchant_id}?ref={referral_code}
```

**Message WhatsApp pre-rempli (restaurant):**
```
Decouvre {merchant_name} sur mefali ! Commande facilement depuis ton telephone.
https://api.mefali.ci/share/r/{merchant_id}?ref={ABCD12}
```

**Message WhatsApp pre-rempli (app generique):**
```
Rejoins mefali ! L'app pour commander a manger a Bouake.
https://api.mefali.ci/share?ref={ABCD12}
```

**Intent WhatsApp URL:**
```
https://wa.me/?text={urlEncode(message)}
```

### Patterns Backend a Suivre (etablis par story 7-1)

- **Module organisation:** `server/crates/domain/src/` — pas de nouveau module domain pour le sharing, c'est une extension de `users` (referral_code) + une route dans `api`
- **Route handler pattern:**
  ```rust
  pub async fn get_referral_code(
      auth: AuthenticatedUser,
      pool: web::Data<PgPool>,
  ) -> Result<HttpResponse, AppError> {
      let code = users::repository::get_referral_code(&pool, auth.user_id).await?;
      Ok(HttpResponse::Ok().json(ApiResponse::new(json!({"referral_code": code}))))
  }
  ```
- **Response format:** `{"data": {"referral_code": "ABCD12"}}` pour succes
- **Auth guard:** `AuthenticatedUser` extractor, `require_role(&auth, &[UserRole::Client])?;`
- **Error mapping:** `AppError::NotFound`, `AppError::BadRequest`

### Patterns Frontend a Suivre (etablis par story 7-1)

- **Modeles:** `@JsonSerializable(fieldRename: FieldRename.snake)` + `part 'xxx.g.dart'`
- **Endpoints:** Classe avec constructeur `const Endpoint(this._dio)`, methodes async typees
- **Providers:** `FutureProvider.autoDispose` par defaut, `.family<T, P>` pour parametrise
- **UI:** Material 3 standard, touch targets >= 48dp, `FilledButton` / `OutlinedButton`
- **Navigation:** go_router pour deep links

### Code Existant a Reutiliser

| Composant | Fichier | Usage |
|-----------|---------|-------|
| url_launcher | `apps/mefali_b2c/pubspec.yaml` (deja ^6.3.0) | Ouvrir intent WhatsApp |
| go_router | `apps/mefali_b2c/pubspec.yaml` (deja ^17.0.0) | Deep link handling |
| deep_link.rs | `server/crates/notification/src/deep_link.rs` | Pattern Base64 encode/decode (reference, pas reutilise directement) |
| RatingBottomSheet | `packages/mefali_design/lib/components/rating_bottom_sheet.dart` | Pattern UI pour bottom sheet post-delivery |
| delivery_tracking_screen.dart | `apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart` | Point d'integration post-rating share |
| dioProvider | `packages/mefali_api_client/lib/` | Injection Dio dans endpoints |

### Anti-patterns a Eviter

1. **NE PAS installer `share_plus`** — `url_launcher` suffit pour ouvrir WhatsApp. L'AC dit specifiquement "WhatsApp intent", pas un share sheet generique
2. **NE PAS creer de module domain `sharing/`** — Le referral code est un attribut de `users`, pas un domaine separe
3. **NE PAS utiliser Firebase Dynamic Links** — Deprece. Utiliser un endpoint serveur simple pour la page de redirect
4. **NE PAS hardcoder le domaine** — Utiliser une config (`SHARE_BASE_URL` dans .env)
5. **NE PAS creer de table `shares`** — Pas de tracking des partages pour le MVP. Le referral tracking (qui a parraine qui) suffit
6. **NE PAS oublier `urlEncode`** — Le message WhatsApp doit etre URL-encode dans l'intent

### Database Changes

```sql
-- Migration: ajouter referral a users
ALTER TABLE users ADD COLUMN referral_code VARCHAR(8) UNIQUE;
ALTER TABLE users ADD COLUMN referred_by UUID REFERENCES users(id);

-- Generer les codes pour les users existants
UPDATE users SET referral_code = UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6))
WHERE referral_code IS NULL;

-- Rendre NOT NULL apres backfill
ALTER TABLE users ALTER COLUMN referral_code SET NOT NULL;

-- Index pour lookup rapide
CREATE UNIQUE INDEX idx_users_referral_code ON users (referral_code);
```

### API Contracts

**GET /api/v1/users/me/referral**
- Auth: JWT (tout role)
- Response 200: `{"data": {"referral_code": "ABCD12"}}`

**GET /api/v1/share/restaurant/{merchant_id}**
- Auth: JWT Client
- Response 200:
```json
{
  "data": {
    "merchant_name": "Chez Adjoua",
    "merchant_description": "Garba, Alloco, Attieke",
    "share_url": "https://api.mefali.ci/share/r/{merchant_id}",
    "whatsapp_message": "Decouvre Chez Adjoua sur mefali ! ..."
  }
}
```

**GET /share/r/{merchant_id}?ref={code}** (public, pas /api/v1/)
- Pas d'auth
- Response: HTML avec Open Graph meta tags + redirect JavaScript
```html
<html>
<head>
  <meta property="og:title" content="Chez Adjoua sur mefali" />
  <meta property="og:description" content="Commande facilement depuis ton telephone" />
  <meta property="og:image" content="https://api.mefali.ci/assets/og-default.png" />
</head>
<body>
  <script>
    // Tente d'ouvrir l'app, sinon redirige vers Play Store
    window.location = 'mefali://restaurant/{merchant_id}?ref={code}';
    setTimeout(() => { window.location = 'https://play.google.com/store/apps/details?id=ci.mefali.b2c'; }, 2000);
  </script>
  <p>Redirection en cours...</p>
</body>
</html>
```

**POST /api/v1/auth/register** (modification existante)
- Ajouter champ optionnel `referral_code` au body
- Si present et valide: setter `referred_by = referrer.id` sur le nouveau user

### UX Layout

**Bouton partage sur restaurant detail:**
```
┌──────────────────────────────────┐
│  AppBar: [<-] Chez Adjoua [Share]│   ← IconButton share (Icons.share)
│                                  │
│  ... contenu restaurant ...      │
└──────────────────────────────────┘
```

**Post-rating share (apres RatingBottomSheet):**
```
┌──────────────────────────────────┐
│  Merci pour votre avis !         │
│                                  │
│  [Partager mefali sur WhatsApp]  │   ← OutlinedButton avec icone WhatsApp
│                                  │
│  couleur: vert WhatsApp #25D366  │
└──────────────────────────────────┘
```

**Ecran profil - Carte invitation:**
```
┌──────────────────────────────────┐
│  Invitez vos amis !             │
│  Votre code: ABCD12             │
│  [Partager sur WhatsApp]        │   ← FilledButton vert
└──────────────────────────────────┘
```

### Registrations et Exports a Mettre a Jour

**Flutter barrel exports:**
- `packages/mefali_core/lib/mefali_core.dart` → exporter `share_data.dart`
- `packages/mefali_api_client/lib/mefali_api_client.dart` → exporter `share_endpoint.dart`, `share_provider.dart`
- `packages/mefali_design/lib/mefali_design.dart` → exporter `share_button.dart`, `invite_friends_card.dart`

**Rust route registration (mod.rs):**
```rust
// Dans configure_routes:
.service(
    web::scope("/users")
        // ... routes existantes ...
        .route("/me/referral", web::get().to(users::get_referral_code)),
)
.service(
    web::scope("/share")
        .route("/restaurant/{merchant_id}", web::get().to(share::get_share_metadata)),
)
// Route publique (hors /api/v1/):
.route("/share/r/{merchant_id}", web::get().to(share::share_redirect_page))
```

### Project Structure Notes

- Le sharing n'est PAS un domaine metier separe — c'est une feature transversale
- `referral_code` est un attribut de User, gere dans `domain/users/`
- La route de redirect HTML (`/share/r/...`) est une route publique dans `api`, pas sous `/api/v1/`
- Les composants UI de partage vont dans `mefali_design/lib/components/`
- L'utilitaire WhatsApp va dans `mefali_core/lib/utils/` (ou directement dans un fichier utilitaire)

### References

- [Source: _bmad-output/planning-artifacts/epics.md] Epic 7, Story 7.2 — AC et user story
- [Source: _bmad-output/planning-artifacts/prd.md] FR42 — partage WhatsApp, KPI > 20% actifs
- [Source: _bmad-output/planning-artifacts/prd.md] Journey 3 Koffi — "son collegue lui a envoye un lien WhatsApp"
- [Source: _bmad-output/planning-artifacts/architecture.md] API patterns REST, go_router deep links, url_launcher
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md] Flow B2C ecran 6 Completion — "[Partager mefali sur WhatsApp]"
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md] KPI partage — "> 20% des actifs"
- [Source: _bmad-output/implementation-artifacts/7-1-double-rating.md] Patterns etablis backend + frontend

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend: Migration SQL ajoutant `referral_code` (VARCHAR(8) UNIQUE NOT NULL) et `referred_by` (UUID FK) a la table `users`, avec backfill des users existants
- Backend: `generate_referral_code()` dans users/service.rs — 6 chars uppercase alphanumerique via rand
- Backend: `create_user()` modifie pour accepter referral_code, `get_referral_code()`, `find_id_by_referral_code()`, `set_referred_by()` dans repository
- Backend: `verify_otp_and_register()` gere desormais `referral_code_input` pour l'attribution referral
- Backend: Route `GET /api/v1/users/me/referral` retourne le code referral
- Backend: Route `GET /api/v1/share/restaurant/{merchant_id}` retourne share metadata avec message WhatsApp pre-rempli
- Backend: Route publique `GET /share/r/{merchant_id}` sert page HTML avec OG tags + redirect app/Play Store
- Backend: `SHARE_BASE_URL` configurable via env var, defaut localhost
- Backend: Fix pre-existant — ajout routes `list_merchants` et `list_merchant_products` dans test_helpers.rs (6 tests corriges)
- Frontend: Modele `ShareMetadata` + `ReferralCodeResponse` avec JsonSerializable snake_case
- Frontend: `WhatsAppShareHelper` utilitaire — `shareOnWhatsApp()`, `buildRestaurantMessage()`, `buildAppInviteMessage()`
- Frontend: `ShareEndpoint` (getReferralCode, getShareMetadata) + providers Riverpod
- Frontend: `ShareButton` (IconButton ou OutlinedButton vert WhatsApp) + `InviteFriendsCard` (code + copie + partage)
- Frontend: Bouton share integre sur RestaurantCatalogueScreen (coin haut droite)
- Frontend: Post-rating share bottom sheet dans DeliveryTrackingScreen
- Frontend: InviteFriendsCard dans ProfileScreen
- Frontend: Champ "Code parrain" optionnel dans NameScreen (registration)
- Frontend: Auth flow (endpoint, provider, controller) mis a jour pour passer referral_code
- Tests: 273 tests Rust (0 echecs), 104 tests Flutter (0 echecs)

### Code Review Fixes (2026-03-21)

Reviewer: Claude Opus 4.6 — Code review adversariale

**CRITICAL fixes (4):**
- C1: XSS — echappement HTML dans share.rs (merchant name, category, ref param) + validation ref param format
- C2: Deep link crash — cast securise `state.extra as RestaurantSummary?` dans app.dart, fallback HomeScreen
- C3: Post-rating share sans referral code — refactor en ConsumerWidget `_PostRatingShareContent` qui fetch le referral code du user
- C4: Validation referral code backend — validation format alphanumerique <=8 chars avant query DB dans service.rs + logging codes invalides

**HIGH fixes (4):**
- H1: URL hardcodee — DeliveryTrackingScreen utilise desormais `WhatsAppShareHelper.buildAppInviteMessage()` au lieu d'un message hardcode
- H2: Error handling — try-catch + SnackBar feedback sur `_shareRestaurant()`, ProfileScreen `_InviteSection` (loading/error states), DeliveryTrackingScreen
- H3: Migration idempotente — backfill utilise `MD5(id::TEXT)` deterministe au lieu de `RANDOM()`, collisions resolues via compteur `attempt`
- H4: Validation frontend — regex `^[A-Z0-9]{6}$` sur le champ "Code parrain" dans NameScreen

**Fichiers modifies par la review:**
- server/crates/api/src/routes/share.rs (escape_html, validate_ref_param, tests)
- server/crates/domain/src/users/service.rs (validation referral code)
- server/migrations/20260322000002_add_user_referral.up.sql (backfill deterministe)
- apps/mefali_b2c/lib/app.dart (safe cast deep link)
- apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart (refactor post-rating share)
- apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart (error handling share)
- apps/mefali_b2c/lib/features/profile/profile_screen.dart (error handling + loading states)
- apps/mefali_b2c/lib/features/auth/name_screen.dart (validation regex referral code)

### File List

**Fichiers crees:**
- server/migrations/20260322000002_add_user_referral.up.sql
- server/migrations/20260322000002_add_user_referral.down.sql
- server/crates/api/src/routes/share.rs
- packages/mefali_core/lib/models/share_data.dart
- packages/mefali_core/lib/models/share_data.g.dart
- packages/mefali_core/lib/utils/whatsapp_share_helper.dart
- packages/mefali_api_client/lib/endpoints/share_endpoint.dart
- packages/mefali_api_client/lib/providers/share_provider.dart
- packages/mefali_design/lib/components/share_button.dart
- packages/mefali_design/lib/components/invite_friends_card.dart

**Fichiers modifies:**
- server/crates/domain/src/users/model.rs (ajout referral_code a VerifyOtpPayload)
- server/crates/domain/src/users/repository.rs (create_user +referral_code, get_referral_code, find_id_by_referral_code, set_referred_by)
- server/crates/domain/src/users/service.rs (generate_referral_code, referral attribution)
- server/crates/domain/src/merchants/service.rs (passer referral_code a create_user)
- server/crates/domain/src/test_fixtures.rs (passer referral_code a create_user)
- server/crates/api/src/routes/mod.rs (enregistrement routes share + referral)
- server/crates/api/src/routes/auth.rs (passer referral_code)
- server/crates/api/src/routes/users.rs (ajout get_referral_code)
- server/crates/api/src/main.rs (ajout SHARE_BASE_URL)
- server/crates/api/src/test_helpers.rs (fix routes list_merchants/products)
- server/.env.example (ajout SHARE_BASE_URL)
- packages/mefali_core/lib/mefali_core.dart (exports)
- packages/mefali_core/pubspec.yaml (ajout url_launcher)
- packages/mefali_api_client/lib/mefali_api_client.dart (exports)
- packages/mefali_api_client/lib/endpoints/auth_endpoint.dart (ajout referralCode)
- packages/mefali_api_client/lib/providers/auth_provider.dart (ajout referralCode)
- packages/mefali_design/lib/mefali_design.dart (exports)
- apps/mefali_b2c/lib/features/auth/auth_controller.dart (ajout referralCode)
- apps/mefali_b2c/lib/features/auth/name_screen.dart (champ code parrain)
- apps/mefali_b2c/lib/features/restaurant/restaurant_catalogue_screen.dart (share button)
- apps/mefali_b2c/lib/features/order/delivery_tracking_screen.dart (post-rating share)
- apps/mefali_b2c/lib/features/profile/profile_screen.dart (InviteFriendsCard)
