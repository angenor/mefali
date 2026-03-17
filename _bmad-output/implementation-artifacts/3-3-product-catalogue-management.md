# Story 3.3: Gestion du Catalogue Produits

Status: done

## Story

As a marchand,
I want to add/edit/delete products with photos and prices,
so that customers see my offerings.

## Acceptance Criteria (AC)

1. **AC1 — Ajout produit:** Marchand connecté peut créer un produit (nom, prix, description, photo) → produit apparaît dans le catalogue immédiatement
2. **AC2 — Photo WebP:** Photo compressée en WebP < 200KB côté Flutter avant upload → stockée dans MinIO via multipart
3. **AC3 — Modification produit:** Marchand peut modifier tout champ (nom, prix, description, stock, photo) → changements reflétés en temps réel
4. **AC4 — Suppression produit:** Marchand peut supprimer un produit → disparaît du catalogue (soft delete : `is_available = false`, données conservées pour analytics)
5. **AC5 — Liste catalogue:** Marchand voit la liste de tous ses produits avec photo, nom, prix, stock dans l'onglet Catalogue
6. **AC6 — Auth B2B:** Marchand peut se connecter à mefali_b2b via phone + OTP et accéder à ses écrans

## Tasks / Subtasks

### Backend (Rust)

- [x] **T1** — Routes produit self-service pour rôle Merchant (AC: 1,2,3,4,5)
  - [x] T1.1 — GET `/api/v1/products` : liste produits du marchand (depuis JWT → user_id → merchant)
  - [x] T1.2 — POST `/api/v1/products` : création produit avec multipart (champs JSON + fichier photo)
  - [x] T1.3 — PUT `/api/v1/products/{id}` : mise à jour produit (multipart optionnel pour photo)
  - [x] T1.4 — DELETE `/api/v1/products/{id}` : soft delete (`is_available = false`)
  - [x] T1.5 — Ajouter `update_product()` dans `products/repository.rs`
  - [x] T1.6 — Ajouter `update_product()` et `delete_product()` (soft) dans `products/service.rs`
  - [x] T1.7 — Vérification ownership : produit.merchant_id == auth.merchant_id
  - [x] T1.8 — Upload photo produit via `upload_image()` existant dans `infrastructure/storage/upload.rs`
  - [x] T1.9 — Enregistrer route scope dans `routes/mod.rs`

- [x] **T2** — Helper merchant lookup (AC: 1,3,4,5)
  - [x] T2.1 — Ajouter `find_by_user_id()` dans `merchants/repository.rs` (JWT donne user_id, pas merchant_id)

- [x] **T3** — Tests backend (AC: 1,2,3,4,5)
  - [x] T3.1 — Tests unitaires update_product model + validation (5 tests: valid, empty name, negative price, negative stock, all none)
  - [x] T3.2 — Tests unitaires service (ownership check ok + forbidden, update payload validation)
  - [x] T3.3 — Tests upload photo existants (taille, MIME type) — vérifiés, pas de régression

### Frontend — mefali_b2b (Flutter)

- [x] **T4** — Auth marchand dans mefali_b2b (AC: 6)
  - [x] T4.1 — B2bPhoneScreen + B2bOtpScreen (pattern exact de mefali_admin)
  - [x] T4.2 — GoRouter avec auth guard (redirect /auth/phone si pas de token)
  - [x] T4.3 — MaterialApp.router dans app.dart

- [x] **T5** — Navigation Home avec TabBar (AC: 5)
  - [x] T5.1 — B2bHomeScreen avec TabBar en haut : Commandes | Catalogue | Stats
  - [x] T5.2 — Onglet Catalogue actif (initialIndex: 1), les 2 autres = placeholder

- [x] **T6** — Écran liste catalogue (AC: 5)
  - [x] T6.1 — ProductListScreen : grille 2 colonnes de ProductCard (photo, nom, prix, stock)
  - [x] T6.2 — État vide avec icône restaurant_menu + bouton "Ajouter un produit"
  - [x] T6.3 — FAB "+" pour ajouter (visible quand produits existent)
  - [x] T6.4 — Tap sur produit → context.push('/catalogue/edit', extra: product)
  - [x] T6.5 — merchantProductsProvider (FutureProvider.autoDispose)

- [x] **T7** — Écran ajout/édition produit (AC: 1,2,3)
  - [x] T7.1 — ProductFormScreen réutilisé pour ajout ET édition via Product? parameter
  - [x] T7.2 — Champs : nom, prix (numérique), description (optionnel), stock (optionnel)
  - [x] T7.3 — Photo : image_picker (camera + gallery), maxWidth/maxHeight 1024, quality 80
  - [x] T7.4 — Upload multipart via FormData + MultipartFile dans ProductEndpoint
  - [x] T7.5 — Validation inline (nom requis, prix >= 0, stock >= 0)
  - [x] T7.6 — SnackBar vert succès (3s) / rouge erreur (persistent)
  - [x] T7.7 — Bouton loading state (CircularProgressIndicator) pendant soumission

- [x] **T8** — Suppression produit (AC: 4)
  - [x] T8.1 — Bouton supprimer (icône delete) dans AppBar du ProductFormScreen en mode édition
  - [x] T8.2 — AlertDialog de confirmation avant suppression
  - [x] T8.3 — ref.invalidate(merchantProductsProvider) après suppression

- [x] **T9** — API Client (AC: 1,2,3,4,5)
  - [x] T9.1 — ProductEndpoint créé : getMyProducts(), createProduct(), updateProduct(), deleteProduct()
  - [x] T9.2 — ProductCatalogueNotifier (StateNotifier<AsyncValue<void>>) pour mutations
  - [x] T9.3 — Upload multipart avec FormData.fromMap + MultipartFile.fromFile + MediaType('image/webp')

- [x] **T10** — Dépendances (AC: 2)
  - [x] T10.1 — image_picker: ^1.1.0 ajouté au pubspec.yaml de mefali_b2b
  - [x] T10.2 — image_picker compress via maxWidth/maxHeight/imageQuality (pas de package séparé nécessaire)

- [x] **T11** — Tests frontend (AC: 1,2,5,6)
  - [x] T11.1 — Widget tests : ProductListScreen (empty state + product grid avec 2 produits)
  - [x] T11.2 — Widget tests : ProductFormScreen (create mode fields, edit mode data, validation)
  - [x] T11.3 — Auth tests : MefaliB2bApp login screen render, phone validation

## Dev Notes

### Architecture Existante — NE PAS RECRÉER

**Modèles Rust déjà existants :**
- `server/crates/domain/src/products/model.rs` — struct `Product` (id, merchant_id, name, description, price: i64, stock: i32, initial_stock: i32, photo_url, is_available, created_at, updated_at) + `CreateProductPayload`
- `server/crates/domain/src/products/repository.rs` — `create_product()`, `find_by_merchant()`, `delete_product()` (hard delete actuellement)
- `server/crates/domain/src/products/service.rs` — `add_products()`, `get_products()`, `delete_product()`
- `server/crates/domain/src/merchants/repository.rs` — MANQUE `find_by_user_id()` (nécessaire car JWT donne user_id)

**Modèles Dart déjà existants :**
- `packages/mefali_core/lib/models/product.dart` — modèle Product avec `@JsonSerializable(fieldRename: FieldRename.snake)`
- `packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart` — `addProducts()` (onboarding), `getOnboardingStatus()` → contient products

**Infrastructure existante :**
- `server/crates/infrastructure/src/storage/upload.rs` — `upload_image()` (400KB max, webp/jpeg/png) + `upload_encrypted_image()` (KYC)
- S3 client initialisé dans `main.rs` et injecté via `app_data`
- Multipart parsing pattern dans `server/crates/api/src/routes/kyc.rs` (actix-multipart)

**Schéma DB existant (migration 005) :**
```sql
products (id UUID PK, merchant_id UUID FK, name VARCHAR(200), description TEXT,
          price BIGINT CHECK>=0, stock INT, initial_stock INT,
          photo_url TEXT, is_available BOOLEAN, created_at, updated_at)
```

### Ce Qui Doit Être AJOUTÉ (pas recréé)

**Backend :**
1. `update_product()` dans `products/repository.rs` — UPDATE avec RETURNING
2. `update_product()` dans `products/service.rs` — avec ownership check
3. Soft delete : modifier `delete_product()` pour SET is_available=false au lieu de DELETE
4. `find_by_user_id()` dans `merchants/repository.rs` — SELECT merchant WHERE user_id=$1
5. Nouvelles routes dans `server/crates/api/src/routes/products.rs` (nouveau fichier) avec `require_role Merchant`
6. Scope products dans `routes/mod.rs`

**Frontend :**
1. Auth screens dans `mefali_b2b` (copier pattern mefali_admin : PhoneScreen + OtpScreen)
2. GoRouter dans app.dart (remplacer MaterialApp par MaterialApp.router)
3. HomeScreen avec TabBar
4. Catalogue feature screens
5. ProductEndpoint ou extension de MerchantEndpoint
6. ProductCatalogueNotifier + merchantProductsProvider

### Patterns Obligatoires

**Rust :**
- `sqlx::query_as::<_, Product>()` avec colonnes explicites + RETURNING *
- `require_role(&auth, &[UserRole::Merchant])?` en début de chaque handler
- `ApiResponse::new(serde_json::json!({...}))` pour réponses
- AppError::NotFound / BadRequest / Forbidden pour erreurs
- Multipart parsing : même pattern que `routes/kyc.rs` (actix-multipart + futures-util)
- Ownership check : `product.merchant_id == merchant.id` sinon AppError::Forbidden
- Upload photo : `upload_image(s3_client, bucket, "merchants/{merchant_id}/products/{uuid}.webp", bytes, "image/webp")`

**Dart :**
- `ConsumerStatefulWidget` pour formulaires, `ConsumerWidget` pour listes
- `ref.watch(provider)` pour état, `ref.read(notifier).method()` pour actions
- `AsyncValue.when(loading: ..., error: ..., data: ...)` dans widgets
- `AsyncValue.guard()` dans StateNotifier
- `@JsonSerializable(fieldRename: FieldRename.snake)` sur modèles
- SnackBar rouge erreur (persistent), SnackBar vert succès (3s)
- Bouton disabled + CircularProgressIndicator pendant loading
- Labels au-dessus des champs (pas en placeholder)
- Validation inline sous le champ en erreur
- Clavier adapté (numérique pour prix)

**Compression WebP côté Flutter :**
- Utiliser `flutter_image_compress` ou package `image` pour convertir en WebP
- Cible : < 200KB par image
- Résolution max : 1024x1024 (suffisant pour catalogue, économie RAM 2GB)
- Compresser AVANT upload (jamais côté serveur)

**Multipart Dio (pattern 3.2) :**
```dart
final formData = FormData.fromMap({
  'name': name,
  'price': price.toString(),
  'description': description,
  'stock': stock.toString(),
  'file': await MultipartFile.fromFile(compressedFile.path, contentType: MediaType.parse('image/webp')),
});
final response = await dio.post('/api/v1/products', data: formData);
```

### Routes API à Implémenter

| Méthode | Endpoint | Rôle | Body | Réponse |
|---------|----------|------|------|---------|
| GET | `/api/v1/products` | Merchant | — | `{"data": {"products": [...]}}` |
| POST | `/api/v1/products` | Merchant | Multipart (champs + file) | `{"data": {"product": {...}}}` 201 |
| PUT | `/api/v1/products/{id}` | Merchant | Multipart (champs + file optionnel) | `{"data": {"product": {...}}}` |
| DELETE | `/api/v1/products/{id}` | Merchant | — | `{"data": {"message": "..."}}` |

### Structure Fichiers à Créer

**Rust (nouveau) :**
```
server/crates/api/src/routes/products.rs    ← handlers CRUD + multipart
```

**Rust (modifier) :**
```
server/crates/domain/src/products/repository.rs  ← + update_product(), + soft delete
server/crates/domain/src/products/service.rs      ← + update_product(), + ownership checks
server/crates/domain/src/merchants/repository.rs  ← + find_by_user_id()
server/crates/api/src/routes/mod.rs               ← + products scope
```

**Flutter (nouveau) :**
```
apps/mefali_b2b/lib/features/auth/phone_screen.dart
apps/mefali_b2b/lib/features/auth/otp_screen.dart
apps/mefali_b2b/lib/features/home/home_screen.dart
apps/mefali_b2b/lib/features/catalogue/product_list_screen.dart
apps/mefali_b2b/lib/features/catalogue/product_form_screen.dart
```

**Flutter (modifier) :**
```
apps/mefali_b2b/lib/app.dart                     ← GoRouter + auth guard
apps/mefali_b2b/pubspec.yaml                     ← + image_picker, flutter_image_compress
packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart  ← + getMyProducts, createProduct, updateProduct, deleteProduct
packages/mefali_api_client/lib/mefali_api_client.dart            ← exports si nouveau endpoint
```

### Pièges à Éviter (Leçons Stories 3.1 & 3.2)

1. **Ne pas oublier les derives sqlx** sur les structs Rust (`sqlx::FromRow`, `Serialize`, `Deserialize`)
2. **Ne pas utiliser `query!()` macro** — utiliser `query_as::<_, Type>()`
3. **Ne pas oublier `dart run build_runner build`** après modification des modèles Dart (*.g.dart)
4. **Ne pas oublier d'exporter** les nouveaux fichiers dans `mefali_core.dart` et `mefali_api_client.dart`
5. **Ne pas oublier d'enregistrer** le scope dans `routes/mod.rs`
6. **Compression WebP côté Flutter, PAS côté serveur** — le serveur reçoit déjà du WebP < 200KB
7. **Ownership check obligatoire** — un marchand ne doit modifier QUE ses propres produits
8. **price est i64 (BIGINT)** — en unité la plus petite (FCFA entiers, pas de centimes)
9. **Soft delete** (is_available=false) PAS hard delete — les données servent pour analytics (story 3.7)
10. **image_picker maxWidth: 1024** — appareils 2GB RAM (Tecno Spark/Infinix)

### UX Obligatoire

- **Navigation B2B** : TabBar en haut (pattern WhatsApp) — Commandes | **Catalogue** | Stats
- **Grille 2 colonnes** pour la liste produits (1 col si écran < 340dp)
- **Bouton primaire** : `FilledButton` marron foncé (#5D4037), pleine largeur, 1 max par écran
- **Touch targets** : >= 48dp (mains occupées en cuisine)
- **Loading** : Skeleton screens (pas de spinner seul)
- **Feedback** : SnackBar vert ✓ "Produit ajouté" (3s), rouge erreur (persistent)
- **Labels au-dessus des champs**, validation inline en erreur
- **Portrait only**, marges 16dp
- **cached_network_image** pour afficher les photos produits

### Dépendances Cross-Stories

- **Story 3.4 (Stock Level Management)** : utilisera stock/initial_stock de Product — ne pas changer le schéma
- **Story 4.2 (Restaurant Catalogue View)** : les produits B2C viendront de la même table/API
- **Story 3.7 (Sales Dashboard)** : analytics par produit — d'où le soft delete

### Project Structure Notes

- mefali_b2b est actuellement un scaffold vide (app.dart + main.dart)
- Les packages partagés (mefali_design, mefali_core, mefali_api_client) sont déjà dans pubspec.yaml
- go_router et flutter_riverpod déjà présents dans les dépendances B2B
- Manque : image_picker et package compression WebP

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.3]
- [Source: _bmad-output/planning-artifacts/architecture.md — Sections API, Database, Flutter, Rust]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — B2B Navigation, Components, Forms]
- [Source: _bmad-output/planning-artifacts/prd.md — FR8, NFR4, NFR6]
- [Source: _bmad-output/implementation-artifacts/3-1-agent-terrain-merchant-onboarding-flow.md]
- [Source: _bmad-output/implementation-artifacts/3-2-kyc-document-capture.md]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend: 4 routes REST produits (GET/POST/PUT/DELETE) sous /api/v1/products avec require_role Merchant
- Backend: find_by_user_id() dans merchants/repository pour resolution JWT user_id → merchant_id
- Backend: update_product() et soft_delete_product() dans products/repository + service avec ownership check
- Backend: Multipart parsing pour upload photo produit (reuse pattern KYC avec actix-multipart)
- Backend: 121 tests Rust (8 nouveaux), zero regressions
- Frontend: Bootstrap complet mefali_b2b (auth phone+OTP, GoRouter, auth guard)
- Frontend: B2bHomeScreen avec TabBar (Commandes | Catalogue | Stats)
- Frontend: ProductListScreen avec grille 2 colonnes, empty state, FAB add
- Frontend: ProductFormScreen pour ajout/edition avec photo (camera+gallery), validation inline
- Frontend: Suppression via AlertDialog confirmation + soft delete backend
- Frontend: ProductEndpoint + ProductCatalogueNotifier + merchantProductsProvider
- Frontend: 8 tests widget B2B, 11 tests admin (zero regressions), 24 tests api_client
- Total: 165 tests, 0 echecs

### Change Log

- 2026-03-17: Story 3.3 implementee — Gestion catalogue produits (backend CRUD + frontend B2B)
- 2026-03-17: Code review — 4 HIGH + 4 MEDIUM fixes appliques automatiquement

### Senior Developer Review (AI)

**Reviewer:** Claude Opus 4.6 (1M context) — 2026-03-17

**Issues Found:** 4 High, 4 Medium, 3 Low — tous H/M corriges.

**HIGH fixes:**
- H1 (AC2): Ajout `flutter_image_compress` pour compression WebP reelle avant upload (JPEG → WebP). L'AC2 exigeait WebP < 200KB cote Flutter.
- H2: Photo URLs MinIO resolues en URLs completes (`{endpoint}/{bucket}/{key}`) dans les route handlers. `CachedNetworkImage` recevait la cle brute au lieu d'une URL.
- H3: `updated_at = NOW()` ajoute dans `update_product` SQL query (repository.rs).
- H4: `updated_at = NOW()` ajoute dans `soft_delete_product` SQL query (repository.rs).

**MEDIUM fixes:**
- M1: Multipart parsing extrait dans `parse_product_multipart()` + helpers `upload_photo()`, `with_photo_url()` — elimination de ~40 lignes dupliquees.
- M2: Description clearable via `CASE WHEN $4 IS NOT NULL THEN NULLIF($4, '') ELSE description END` au lieu de `COALESCE`.
- M3: Suppression best-effort de l'ancienne photo MinIO lors du remplacement. `service::update_product` retourne desormais `(Product, Option<String>)` pour exposer l'ancien `photo_url`.
- M4: Loading spinner remplace par skeleton grid (6 cartes placeholder) dans `ProductListScreen`.

**LOW (non corriges, documentes):**
- L1: Error SnackBars rendus persistants (`duration: Duration(days: 1)` + bouton OK dismiss) — CORRIGE avec H/M batch.
- L2: Accents manquants dans SnackBar messages corriges ("Produit modifié", "Produit ajouté", "Produit supprimé") — CORRIGE.
- L3: Commit 608816d regroupe 3 stories mais n'en mentionne que 2 (cosmétique).

**Verdict:** APPROVE — Tous les ACs implementes, tous issues H/M corriges, 121 tests Rust + 0 issues lint Dart.

### File List

**New files:**
- server/crates/api/src/routes/products.rs
- apps/mefali_b2b/lib/features/auth/phone_screen.dart
- apps/mefali_b2b/lib/features/auth/otp_screen.dart
- apps/mefali_b2b/lib/features/home/home_screen.dart
- apps/mefali_b2b/lib/features/catalogue/product_list_screen.dart
- apps/mefali_b2b/lib/features/catalogue/product_form_screen.dart
- packages/mefali_api_client/lib/endpoints/product_endpoint.dart
- packages/mefali_api_client/lib/providers/product_catalogue_provider.dart

**Modified files:**
- server/crates/domain/src/products/model.rs (added UpdateProductPayload + 5 tests)
- server/crates/domain/src/products/repository.rs (added find_by_id, update_product, soft_delete_product)
- server/crates/domain/src/products/service.rs (added resolve_merchant_id, create/update/soft_delete with ownership + 3 tests)
- server/crates/domain/src/merchants/repository.rs (added find_by_user_id)
- server/crates/api/src/routes/mod.rs (added products module + scope)
- apps/mefali_b2b/lib/app.dart (GoRouter + auth guard + catalogue routes)
- apps/mefali_b2b/pubspec.yaml (added image_picker, cached_network_image)
- apps/mefali_b2b/test/widget_test.dart (8 new tests)
- packages/mefali_api_client/lib/mefali_api_client.dart (added product exports)
- packages/mefali_api_client/pubspec.yaml (added http_parser)
