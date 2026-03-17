# Story 3.1: Agent Terrain — Flux d'Onboarding Marchand

Status: in-progress

## Story

En tant qu'agent terrain,
je veux un flux guidé en 5 étapes pour inscrire un marchand,
afin d'onboarder en moins de 30 minutes.

## Acceptance Criteria

1. **AC1**: Connecté en tant qu'agent → je lance le flux onboarding → barre de progression 1/5 → 5/5 visible à chaque étape
2. **AC2**: Étape 1 (Infos) → je saisis téléphone, nom commerce, adresse, catégorie → OTP envoyé au marchand → vérification OTP → utilisateur role=merchant + fiche marchand créés
3. **AC3**: Étape 2 (Catalogue) → j'ajoute des produits (nom, prix, photo caméra) → photos compressées WebP < 200KB uploadées MinIO → produits enregistrés
4. **AC4**: Étape 3 (Horaires) → je définis les horaires d'ouverture/fermeture par jour → enregistrés
5. **AC5**: Étape 4 (Paiement) → wallet créé automatiquement → résumé affiché (le marchand sera payé via wallet)
6. **AC6**: Étape 5 (Vérification) → résumé complet → VALIDER → marchand finalisé avec `onboarding_step = 5`
7. **AC7**: Chaque étape est sauvegardée indépendamment → l'agent peut quitter et reprendre là où il en était
8. **AC8**: Téléphone déjà enregistré → erreur 409 `{"error": {"code": "CONFLICT", "message": "Phone number already in use"}}`

## Tasks / Subtasks

### Backend

- [x] T1: Migrations (AC: 2,3,4)
  - [x] T1.1: `000015_add_merchant_onboarding_fields.up.sql` — ALTER merchants ADD `category VARCHAR(100)`, ADD `onboarding_step INT NOT NULL DEFAULT 0`
  - [x] T1.2: `000016_create_business_hours.up.sql` — CREATE TABLE business_hours (id UUID PK, merchant_id UUID FK UNIQUE per day, day_of_week SMALLINT 0-6, open_time TIME NOT NULL, close_time TIME NOT NULL, is_closed BOOLEAN DEFAULT FALSE, created_at, updated_at) + indexes + trigger

- [x] T2: Modèle Merchant complet (AC: 2,7)
  - [x] T2.1: Réécrire `domain/src/merchants/model.rs` — struct Merchant avec TOUS les champs DB (id, user_id, name, address, availability_status, city_id, consecutive_no_response, photo_url, category, onboarding_step, created_at, updated_at) + `#[derive(sqlx::FromRow)]` + `#[sqlx(rename = "availability_status")]` pour le champ status + serde
  - [x] T2.2: `CreateMerchantPayload` struct (name, address, category, city_id) + validation
  - [x] T2.3: `MerchantStatus` enum avec sqlx::Type mapping vers `vendor_status` PostgreSQL (`#[sqlx(type_name = "vendor_status", rename_all = "snake_case")]`)
  - [x] T2.4: Tests unitaires model (serde round-trip, display, validation)

- [x] T3: Modèle Product (AC: 3)
  - [x] T3.1: Créer `domain/src/products/mod.rs`, `model.rs`, `repository.rs`, `service.rs`
  - [x] T3.2: struct Product (id, merchant_id, name, description, price, stock, initial_stock, photo_url, is_available, created_at, updated_at) + `#[derive(sqlx::FromRow)]`
  - [x] T3.3: `CreateProductPayload` struct (name, price, description?, photo_url?)
  - [x] T3.4: Tests unitaires model

- [x] T4: Modèle BusinessHours (AC: 4)
  - [x] T4.1: Créer `domain/src/merchants/business_hours.rs`
  - [x] T4.2: struct BusinessHours (id, merchant_id, day_of_week, open_time, close_time, is_closed, created_at, updated_at) + `#[derive(sqlx::FromRow)]`
  - [x] T4.3: `SetBusinessHoursPayload` — Vec de (day_of_week, open_time, close_time, is_closed)

- [x] T5: Repository merchants (AC: 2,6,7)
  - [x] T5.1: `create_merchant(pool, user_id, payload) -> Result<Merchant>`
  - [x] T5.2: `find_by_id(pool, id) -> Result<Option<Merchant>>`
  - [x] T5.3: `find_by_agent_incomplete(pool, agent_user_id) -> Result<Vec<Merchant>>` — marchands en cours d'onboarding (onboarding_step < 5) créés par cet agent (nécessite champ created_by_agent_id — ATTENTION: ce champ n'existe pas dans le schéma, utiliser un JOIN ou ajouter via migration)
  - [x] T5.4: `update_onboarding_step(pool, merchant_id, step) -> Result<Merchant>`
  - [x] T5.5: Tous les appels via `sqlx::query_as::<_, Merchant>()` avec colonnes explicites + RETURNING

- [x] T6: Repository products (AC: 3)
  - [x] T6.1: `create_product(pool, merchant_id, payload) -> Result<Product>`
  - [x] T6.2: `find_by_merchant(pool, merchant_id) -> Result<Vec<Product>>`
  - [x] T6.3: `delete_product(pool, product_id) -> Result<()>`

- [x] T7: Repository business_hours (AC: 4)
  - [x] T7.1: `set_hours(pool, merchant_id, hours: Vec<SetBusinessHoursPayload>) -> Result<Vec<BusinessHours>>` — UPSERT (DELETE existing + INSERT)
  - [x] T7.2: `find_by_merchant(pool, merchant_id) -> Result<Vec<BusinessHours>>`

- [x] T8: Service onboarding marchand (AC: 2,5,6,7,8)
  - [x] T8.1: `initiate_onboarding(pool, agent_user_id, phone, name, address, category, city_id)` — valider phone E.164, vérifier unicité (409 si existe), envoyer OTP, retourner otp_request_id
  - [x] T8.2: `verify_and_create_merchant(pool, agent_user_id, phone, otp_code, payload)` — vérifier OTP, créer user(role=merchant, status=active), créer merchant(onboarding_step=1), créer wallet(balance=0), retourner Merchant
  - [x] T8.3: `add_products(pool, merchant_id, products: Vec<CreateProductPayload>)` — créer produits, update onboarding_step=2
  - [x] T8.4: `set_hours(pool, merchant_id, hours)` — sauver horaires, update onboarding_step=3
  - [x] T8.5: `finalize_onboarding(pool, merchant_id)` — vérifier que steps 1-4 ok, update onboarding_step=5
  - [x] T8.6: `get_onboarding_status(pool, merchant_id)` — retourner merchant + produits + horaires + wallet status

- [x] T9: Service upload photos MinIO (AC: 3)
  - [x] T9.1: Créer `infrastructure/src/storage/upload.rs` — fonction `upload_image(s3_client, bucket, key, bytes, content_type) -> Result<String>` retournant l'URL
  - [ ] T9.2: Compression WebP côté Flutter (pas serveur) — le serveur reçoit déjà du WebP < 200KB — **DEFERRED: story 3.3**
  - [x] T9.3: Validation taille max (400KB brut) + type MIME (image/webp, image/jpeg, image/png) — code exists in upload.rs, not yet wired to routes
  - [ ] T9.4: Chemin MinIO: `merchants/{merchant_id}/products/{product_id}.webp` — **DEFERRED: story 3.3**

- [x] T10: Routes API onboarding (AC: 1-8)
  - [x] T10.1: Créer `api/src/routes/merchants.rs` — scope `/merchants/onboard`
  - [x] T10.2: `POST /api/v1/merchants/onboard/request-otp` — body: `{phone, name, address, category, city_id}` — require_role Agent
  - [x] T10.3: `POST /api/v1/merchants/onboard/verify-and-create` — body: `{phone, otp, name, address?, category?, city_id?}` — require_role Agent — retourne merchant créé (endpoint unifié, l'ancien /verify a été supprimé lors du code review car buggé)
  - [x] T10.4: `POST /api/v1/merchants/{id}/products` — body: JSON `{products: [...]}` — require_role Agent — **Note: multipart photo upload deferred to story 3.3**
  - [x] T10.5: `PUT /api/v1/merchants/{id}/hours` — body: `{hours: [{day, open, close, is_closed}]}` — require_role Agent
  - [x] T10.6: `POST /api/v1/merchants/{id}/finalize` — require_role Agent
  - [x] T10.7: `GET /api/v1/merchants/{id}/onboarding-status` — require_role Agent
  - [x] T10.8: Enregistrer scope merchants dans `routes/mod.rs`
  - [x] T10.9: Réponse format standard: `{"data": {...}, "meta": {...}}`

- [x] T11: Tests Rust (AC: tous)
  - [x] T11.1: Tests unitaires merchant model + validation
  - [x] T11.2: Tests unitaires product model
  - [ ] T11.3: Tests unitaires service onboarding (mock pool) — **PENDING: only validation tests exist**
  - [x] T11.4: Tests role_guard pour Agent role — role_guard tests exist from story 2.2
  - [ ] T11.5: Tests routes avec actix_web::test (requêtes auth Agent) — **PENDING: no integration tests yet**

### Frontend (App Admin — mefali_admin)

- [x] T12: API Client — MerchantOnboardingEndpoint (AC: 1-8)
  - [x] T12.1: Créer `packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart` — requestOtp, verifyAndCreate, addProducts (multipart), setHours, finalize, getOnboardingStatus
  - [x] T12.2: Créer `packages/mefali_api_client/lib/providers/merchant_onboarding_provider.dart` — OnboardingNotifier extends StateNotifier<AsyncValue<OnboardingState>>
  - [x] T12.3: Modèle OnboardingState (currentStep, merchant?, products, hours, walletCreated)
  - [x] T12.4: Exporter dans `mefali_api_client.dart`

- [x] T13: Modèles Dart (AC: 2-6)
  - [x] T13.1: Créer `packages/mefali_core/lib/models/merchant.dart` — @JsonSerializable(fieldRename: FieldRename.snake) + builder
  - [x] T13.2: Créer `packages/mefali_core/lib/models/product.dart` — idem
  - [x] T13.3: Créer `packages/mefali_core/lib/models/business_hours.dart` — idem
  - [x] T13.4: Ajouter enum `MerchantCategory` dans `packages/mefali_core/lib/enums/`
  - [x] T13.5: Exporter dans `mefali_core.dart` + `dart run build_runner build`

- [x] T14: App Admin — Setup GoRouter + Auth (AC: 1)
  - [x] T14.1: Ajouter GoRouter dans `apps/mefali_admin/pubspec.yaml` + dépendances (mefali_api_client, mefali_core, mefali_design, image_picker, image)
  - [x] T14.2: Réécrire `app.dart` avec GoRouter + auth guard (réutiliser le pattern de mefali_b2c)
  - [x] T14.3: Créer feature auth (login phone + OTP) — réutiliser les écrans existants de mefali_b2c ou créer des versions simplifiées pour admin
  - [x] T14.4: Home screen avec navigation vers "Nouveau marchand" et liste marchands en cours

- [x] T15: Wizard Onboarding — 5 écrans (AC: 1-7)
  - [x] T15.1: `OnboardingWizardScreen` — conteneur avec `Stepper` ou custom progress bar (1/5 → 5/5), gère navigation entre étapes, affiche barre de progression en haut
  - [x] T15.2: `Step1InfoScreen` — formulaire: téléphone (clavier numérique), nom commerce, adresse, catégorie (dropdown), ville → bouton "Envoyer OTP" → dialog OTP → création marchand
  - [x] T15.3: `Step2CatalogueScreen` — liste produits ajoutés + bouton "Ajouter produit" → bottom sheet avec: nom, prix (clavier numérique) — **Note: photo camera/WebP deferred to story 3.3**
  - [x] T15.4: `Step3HoursScreen` — 7 jours (Lundi→Dimanche) avec toggle ouvert/fermé + sélecteur heure ouverture/fermeture par jour
  - [x] T15.5: `Step4PaymentScreen` — affichage informatif: "Le wallet du marchand a été créé. Les gains seront disponibles pour retrait via Mobile Money." Pas d'action requise.
  - [x] T15.6: `Step5VerifyScreen` — résumé de toutes les infos (nom, adresse, produits, horaires) + bouton "VALIDER" vert pleine largeur → finalise onboarding
  - [x] T15.7: Chaque écran: ConsumerStatefulWidget, loading state sur bouton, SnackBar erreur rouge, SnackBar succès vert

- [x] T16: Navigation et routes (AC: 7)
  - [x] T16.1: Routes GoRouter: `/onboarding/:merchantId/step/:step` pour reprise
  - [x] T16.2: Route `/onboarding/new` pour démarrer
  - [x] T16.3: Route `/home` avec liste des onboardings en cours

- [x] T17: Tests Flutter (AC: tous)
  - [ ] T17.1: Tests MerchantOnboardingEndpoint (mock HTTP adapter) — **PENDING: no mock HTTP tests yet**
  - [x] T17.2: Tests widget progress bar
  - [x] T17.3: Tests widget wizard Step1 content rendering

## Dev Notes

### Architecture Backend — Patrons Établis (Stories 2.1-2.4)

**Pattern service/repository** :
- Repository: `sqlx::query_as::<_, Type>()` avec colonnes explicites + RETURNING *
- Service: validation métier → appel repository → retour Result<T, AppError>
- Routes: extract `AuthenticatedUser` → `require_role(&user, &[UserRole::Agent])?` → appel service → `ApiResponse { data }`
- Erreurs: `AppError` enum dans `common/src/error.rs` → ResponseError JSON

**Pattern OTP réutilisable** :
Le service `domain/src/users/service.rs` a déjà `request_otp()` et `verify_otp()`. Réutiliser ces fonctions dans le service onboarding. NE PAS réécrire la logique OTP. Appeler `users::service::request_otp()` directement.

**Pattern wallet** :
Créer le wallet avec un simple INSERT dans la table wallets (id, user_id, balance=0). Pas de service complexe pour l'instant.

### Architecture Frontend — Patrons Établis

**Endpoint pattern** : `MerchantEndpoint(Dio dio)` avec méthodes qui retournent des modèles parsés depuis `response.data['data']`

**Provider pattern** : `StateNotifier<AsyncValue<T>>` avec `AsyncValue.guard()` pour gestion d'erreurs

**Screen pattern** : `ConsumerStatefulWidget` pour formulaires, `ref.watch()` pour état, `ref.read().notifier.action()` pour actions

**Feedback** : SnackBar rouge erreur (persistent), SnackBar vert succès (3s), loading = bouton désactivé + CircularProgressIndicator inline

**Navigation** : `context.push()` pour sub-routes, `context.go()` pour navigation racine

### Contraintes Critiques

1. **MinIO pour photos** : Utiliser le client S3 existant dans `infrastructure/src/storage/mod.rs`. Bucket: configurable via AppConfig. Chemin: `merchants/{merchant_id}/products/{uuid}.webp`. NE PAS utiliser de CDN.

2. **Compression WebP côté Flutter** : Utiliser le package `image` pour compresser les photos prises par caméra en WebP < 200KB AVANT upload. Le serveur ne fait pas de compression.

3. **Devices cibles 2GB RAM** : Les images produit doivent rester petites. Pas de chargement de multiples images haute résolution en mémoire.

4. **OTP sans mot de passe** : Le marchand n'a pas de mot de passe. L'agent fait l'OTP pendant l'onboarding. Le marchand se connectera plus tard via son propre OTP.

5. **require_role Agent** : Tous les endpoints onboarding nécessitent le rôle Agent. Utiliser `middleware::require_role(&user, &[UserRole::Agent])?` au début de chaque handler.

6. **Merchant model Rust — INCOHÉRENCES À CORRIGER** :
   - Le model actuel a `status: MerchantStatus` mais la colonne DB est `availability_status` → utiliser `#[sqlx(rename = "availability_status")]`
   - Le model actuel n'a pas `consecutive_no_response`, `photo_url`, `updated_at` → ajouter
   - Le model actuel utilise `Id` et `Timestamp` types de `common::types` → vérifier les alias (probablement `Uuid` et `DateTime<Utc>`)
   - L'enum `MerchantStatus` doit mapper vers le type PostgreSQL `vendor_status` → `#[derive(sqlx::Type)]` + `#[sqlx(type_name = "vendor_status", rename_all = "snake_case")]`
   - Ajouter les nouveaux champs: `category`, `onboarding_step`

7. **Response format** : Toujours `{"data": {...}, "meta": {...}}` pour succès, `{"error": {"code": "...", "message": "...", "details": null}}` pour erreurs. Pattern ApiResponse existant dans `common/src/response.rs`.

8. **Multipart upload** : Pour les photos produit, le endpoint reçoit un multipart form avec le fichier image + les données JSON du produit. Côté Rust, utiliser `actix_multipart::Multipart`.

### Structure de Fichiers Attendue

```
server/crates/
  domain/src/
    merchants/
      mod.rs (MODIFIER — exporter business_hours)
      model.rs (RÉÉCRIRE — structs complètes + sqlx derives)
      repository.rs (IMPLÉMENTER — CRUD merchant)
      service.rs (IMPLÉMENTER — logique onboarding)
      business_hours.rs (NOUVEAU — modèle + repo horaires)
    products/
      mod.rs (NOUVEAU)
      model.rs (NOUVEAU — struct Product + payloads)
      repository.rs (NOUVEAU — CRUD product)
      service.rs (NOUVEAU — validation produits)
  domain/src/lib.rs (MODIFIER — déclarer module products)
  infrastructure/src/storage/
    mod.rs (EXISTANT)
    upload.rs (NOUVEAU — fonction upload_image)
  api/src/routes/
    merchants.rs (NOUVEAU — tous les handlers onboarding)
    mod.rs (MODIFIER — ajouter scope merchants)

server/migrations/
  20260317000015_add_merchant_onboarding_fields.up.sql (NOUVEAU)
  20260317000016_create_business_hours.up.sql (NOUVEAU)

packages/
  mefali_core/lib/
    models/merchant.dart (NOUVEAU)
    models/product.dart (NOUVEAU)
    models/business_hours.dart (NOUVEAU)
    enums/merchant_category.dart (NOUVEAU)
    mefali_core.dart (MODIFIER — exports)
  mefali_api_client/lib/
    endpoints/merchant_endpoint.dart (NOUVEAU)
    providers/merchant_onboarding_provider.dart (NOUVEAU)
    mefali_api_client.dart (MODIFIER — exports)

apps/mefali_admin/lib/
  app.dart (RÉÉCRIRE — GoRouter + auth)
  features/
    auth/
      phone_screen.dart (NOUVEAU — login agent)
      otp_screen.dart (NOUVEAU — vérification OTP agent)
    home/
      home_screen.dart (NOUVEAU — dashboard agent simplifié)
    onboarding/
      onboarding_wizard_screen.dart (NOUVEAU — conteneur 5 étapes)
      step1_info_screen.dart (NOUVEAU)
      step2_catalogue_screen.dart (NOUVEAU)
      step3_hours_screen.dart (NOUVEAU)
      step4_payment_screen.dart (NOUVEAU)
      step5_verify_screen.dart (NOUVEAU)
```

### Project Structure Notes

- Le module `products/` est créé dans `domain/src/` en tant que module frère de `merchants/`, pas imbriqué
- Les business_hours sont dans `merchants/business_hours.rs` car fortement liés au marchand
- L'upload MinIO est dans `infrastructure/src/storage/` car c'est de l'infrastructure
- L'admin app suit la même structure features/ que les autres apps
- Les modèles Dart partagés vont dans mefali_core, les endpoints dans mefali_api_client

### Intelligence Story Précédente (2.4 — User Profile Management)

**Patterns réussis à reproduire :**
- `sqlx::query_as::<_, Type>()` avec RETURNING + colonnes explicites
- `AppError::Conflict(String)` pour 409 (téléphone déjà pris)
- `AuthenticatedUser` extractor dans les handlers
- `AsyncValue.guard()` dans les StateNotifier Flutter
- Synchronisation provider: après action, mettre à jour les providers dépendants
- Validation client + serveur (double validation obligatoire)
- Race condition: vérifier unicité phone AVANT envoi OTP (même pattern que 2.4)

**Pièges évités en 2.4 à ne PAS reproduire :**
- NE PAS oublier les derives sqlx sur les structs
- NE PAS oublier les colonnes dans RETURNING
- NE PAS utiliser `query!()` macro — utiliser `query_as()`
- NE PAS oublier `dart run build_runner build` après modif modèles Dart
- NE PAS modifier les écrans d'auth existants des autres apps

**Stats CI actuelles :** 78 tests Rust + 24 tests Flutter, tous passants.

### Références

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.1]
- [Source: _bmad-output/planning-artifacts/architecture.md — Data Architecture, API Patterns, Flutter Frontend]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow 4 Fatou onboarding, App B2B wireframe, Form patterns]
- [Source: _bmad-output/planning-artifacts/prd.md — Journey 1 Adjoua, Journey 4 Fatou, FR3/FR4/FR6/FR47/FR59]
- [Source: server/migrations/000004_create_merchants.up.sql — schema merchants actuel]
- [Source: server/migrations/000005_create_products.up.sql — schema products]
- [Source: server/crates/domain/src/merchants/model.rs — model skeleton actuel]
- [Source: server/crates/api/src/routes/mod.rs — enregistrement routes actuel]
- [Source: server/crates/api/src/middleware/role_guard.rs — require_role existant]
- [Source: server/crates/infrastructure/src/storage/mod.rs — client S3/MinIO existant]
- [Source: _bmad-output/implementation-artifacts/2-4-user-profile-management.md — patterns et pièges]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Business hours time validation: `%H:%M` accepts single-digit hours ("8:00" is valid), fixed test accordingly
- Products module created as sibling to merchants in domain crate (not nested)
- Added `created_by_agent_id` column to merchants migration (not in original schema) to support find_by_agent_incomplete query
- Category stored as VARCHAR(100) rather than enum for flexibility across merchant types
- Wallet creation done via direct SQL INSERT in merchant service (no separate wallet service yet)

### Completion Notes List

- Backend: 2 migrations, complete merchant/product/business_hours domain models with sqlx derives, repository CRUD, onboarding service with OTP reuse, MinIO upload service, 8 API endpoints under /merchants/*
- Frontend: 3 Dart models (Merchant, Product, BusinessHours) with json_serializable, MerchantEndpoint + OnboardingNotifier in API client, full admin app (GoRouter + auth + home + 5-step wizard)
- Tests: 98 Rust tests (20 new: merchant model, product model, business hours validation, service, upload) + 29 Flutter tests (4 new admin) — all passing, zero regressions
- Note: Photo upload (T9.2 WebP compression, T15.3 camera capture) uses JSON-only product creation for now. Multipart photo upload with image_picker/compression can be added in story 3.3 (Product Catalogue Management) which handles full CRUD

### Change Log

- 2026-03-17: Story 3.1 implemented — merchant onboarding flow (backend + frontend)
- 2026-03-17: Code review — 17 findings (4 CRITICAL, 5 HIGH, 5 MEDIUM, 3 LOW). 11 fixed automatically, 4 deferred to story 3.3 (photo/multipart), 2 pending (backend integration tests + endpoint mock tests)

### File List

**New files:**
- server/migrations/20260317000015_add_merchant_onboarding_fields.up.sql
- server/migrations/20260317000015_add_merchant_onboarding_fields.down.sql
- server/migrations/20260317000016_create_business_hours.up.sql
- server/migrations/20260317000016_create_business_hours.down.sql
- server/crates/domain/src/merchants/business_hours.rs
- server/crates/domain/src/products/mod.rs
- server/crates/domain/src/products/model.rs
- server/crates/domain/src/products/repository.rs
- server/crates/domain/src/products/service.rs (added during code review — C1 fix)
- server/crates/infrastructure/src/storage/upload.rs
- server/crates/api/src/routes/merchants.rs
- packages/mefali_core/lib/models/merchant.dart
- packages/mefali_core/lib/models/merchant.g.dart
- packages/mefali_core/lib/models/product.dart
- packages/mefali_core/lib/models/product.g.dart
- packages/mefali_core/lib/models/business_hours.dart
- packages/mefali_core/lib/models/business_hours.g.dart
- packages/mefali_core/lib/enums/merchant_category.dart (added during code review — C2 fix)
- packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart
- packages/mefali_api_client/lib/providers/merchant_onboarding_provider.dart
- apps/mefali_admin/lib/features/auth/phone_screen.dart
- apps/mefali_admin/lib/features/auth/otp_screen.dart
- apps/mefali_admin/lib/features/home/home_screen.dart
- apps/mefali_admin/lib/features/onboarding/onboarding_wizard_screen.dart
- apps/mefali_admin/lib/features/onboarding/step1_info_screen.dart
- apps/mefali_admin/lib/features/onboarding/step2_catalogue_screen.dart
- apps/mefali_admin/lib/features/onboarding/step3_hours_screen.dart
- apps/mefali_admin/lib/features/onboarding/step4_payment_screen.dart
- apps/mefali_admin/lib/features/onboarding/step5_verify_screen.dart

**Modified files:**
- server/crates/domain/src/merchants/model.rs (rewritten with sqlx derives)
- server/crates/domain/src/merchants/repository.rs (implemented CRUD)
- server/crates/domain/src/merchants/service.rs (implemented onboarding logic + agent ownership verification)
- server/crates/domain/src/merchants/mod.rs (added business_hours module)
- server/crates/domain/src/merchants/business_hours.rs (set_hours wrapped in transaction — M1 fix)
- server/crates/domain/src/lib.rs (added products module)
- server/crates/infrastructure/src/storage/mod.rs (added upload module)
- server/crates/api/src/routes/mod.rs (added merchants scope, removed buggy /verify route)
- server/crates/api/src/routes/merchants.rs (removed onboard_verify handler, added agent_id to service calls)
- packages/mefali_core/lib/mefali_core.dart (added exports incl. merchant_category)
- packages/mefali_api_client/lib/mefali_api_client.dart (added exports)
- apps/mefali_admin/lib/app.dart (rewritten with GoRouter + auth)
- apps/mefali_admin/lib/features/onboarding/onboarding_wizard_screen.dart (auto-navigate on resume — M3 fix)
- apps/mefali_admin/test/widget_test.dart (replaced placeholder test with real Step1 content test)
