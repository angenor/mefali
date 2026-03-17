# Story 3.2: Capture Documents KYC Livreur

Status: done

## Story

En tant qu'agent terrain,
je veux capturer les photos CNI/permis d'un livreur via caméra,
afin que son identité soit documentée et qu'il puisse commencer à livrer.

## Acceptance Criteria

1. **AC1**: Connecté en tant qu'agent → je vois la liste des livreurs en attente KYC (`status = pending_kyc`) → triée par date d'inscription
2. **AC2**: Je sélectionne un livreur → je vois ses infos (nom, téléphone, sponsor) → je peux capturer des photos
3. **AC3**: Je prends une photo CNI ou permis via caméra → photo uploadée vers MinIO avec chiffrement server-side AES-256 (SSE-S3) → entrée créée dans `kyc_documents` avec `status = pending`
4. **AC4**: Je peux uploader 1 à 2 documents (CNI et/ou permis) → chaque document est un upload séparé
5. **AC5**: Après upload des documents → je valide le KYC → le `user.status` passe de `pending_kyc` à `active` → les `kyc_documents.status` passent à `verified` → `kyc_documents.verified_by` = agent_user_id
6. **AC6**: Si le livreur n'a aucun document uploadé → le bouton "Activer" est désactivé
7. **AC7**: Si le livreur est déjà `active` → erreur 409 `{"error": {"code": "CONFLICT", "message": "User already active"}}`
8. **AC8**: Documents KYC stockés dans MinIO sous le chemin `kyc/{user_id}/{document_type}_{uuid}.{ext}` → chiffrement AES-256 at rest via SSE-S3

## Tasks / Subtasks

### Backend

- [x] T1: Modèle KYC Domain (AC: 3,4,5)
  - [x] T1.1: Créer `domain/src/kyc/mod.rs` — déclarer `pub mod model; pub mod repository; pub mod service;`
  - [x] T1.2: Créer `domain/src/kyc/model.rs` — struct `KycDocument { id: Id, user_id: Id, document_type: KycDocumentType, encrypted_path: String, verified_by: Option<Id>, status: KycStatus, created_at: Timestamp, updated_at: Timestamp }` avec `#[derive(sqlx::FromRow, Serialize)]`
  - [x] T1.3: Enum `KycDocumentType` — `Cni, Permis` avec `#[derive(sqlx::Type)] #[sqlx(type_name = "kyc_document_type", rename_all = "snake_case")]` + Serialize/Deserialize
  - [x] T1.4: Enum `KycStatus` — `Pending, Verified, Rejected` avec `#[derive(sqlx::Type)] #[sqlx(type_name = "kyc_status", rename_all = "snake_case")]` + Serialize/Deserialize
  - [x] T1.5: `UploadKycPayload { document_type: KycDocumentType }` — payload de la requête multipart
  - [x] T1.6: `KycSummary { user: User, documents: Vec<KycDocument>, sponsor: Option<User> }` — réponse détaillée pour l'agent
  - [x] T1.7: Tests unitaires model (serde round-trip, Display, validation document_type)
  - [x] T1.8: Modifier `domain/src/lib.rs` — ajouter `pub mod kyc;`

- [x] T2: Repository KYC (AC: 3,4,5)
  - [x] T2.1: `create_document(pool, user_id, document_type, encrypted_path) -> Result<KycDocument>` — INSERT INTO kyc_documents RETURNING *
  - [x] T2.2: `find_by_user(pool, user_id) -> Result<Vec<KycDocument>>` — SELECT WHERE user_id ORDER BY created_at
  - [x] T2.3: `verify_all_for_user(pool, user_id, verified_by) -> Result<Vec<KycDocument>>` — UPDATE kyc_documents SET status='verified', verified_by=$2 WHERE user_id=$1 AND status='pending' RETURNING *
  - [x] T2.4: Tous les appels via `sqlx::query_as::<_, KycDocument>()` avec colonnes explicites

- [x] T3: Service KYC (AC: 1-8)
  - [x] T3.1: `list_pending_kyc_users(pool) -> Result<Vec<User>>` — SELECT users WHERE role='driver' AND status='pending_kyc' ORDER BY created_at
  - [x] T3.2: `get_kyc_summary(pool, user_id) -> Result<KycSummary>` — charger user + documents + sponsor (via sponsorships table, JOIN sur sponsored_id=user_id → sponsor_id → users)
  - [x] T3.3: `upload_kyc_document(pool, s3_client, config, user_id, agent_id, document_type, file_bytes, content_type) -> Result<KycDocument>` — valider user est pending_kyc, valider fichier (type MIME, taille), uploader vers MinIO avec SSE-S3 (AES-256), créer entrée kyc_documents
  - [x] T3.4: `activate_driver(pool, user_id, agent_id) -> Result<User>` — vérifier au moins 1 document existe, vérifier user.status==pending_kyc (sinon 409), UPDATE kyc_documents status→verified + verified_by, UPDATE users status→active, RETURNING user
  - [x] T3.5: Validation agent_id: l'agent doit être un user avec role=Agent (vérifié par require_role dans la route, pas dans le service)

- [x] T4: Upload chiffré MinIO (AC: 3,8)
  - [x] T4.1: Créer `upload_encrypted_image()` dans `infrastructure/src/storage/upload.rs` — même signature que `upload_image()` + ajout `.server_side_encryption(aws_sdk_s3::types::ServerSideEncryption::Aes256)` sur put_object
  - [x] T4.2: Chemin MinIO: `kyc/{user_id}/{document_type}_{uuid}.{ext}` — ex: `kyc/550e8400-.../cni_a1b2c3d4.jpeg`
  - [x] T4.3: Taille max: 2MB (KYC nécessite plus de qualité que photos produit) — constante `MAX_KYC_IMAGE_SIZE = 2 * 1024 * 1024`
  - [x] T4.4: Types MIME autorisés: `image/jpeg`, `image/png` (pas de WebP pour KYC — docs officiels = JPEG/PNG)
  - [x] T4.5: Tests unitaires validation (taille, type MIME)

- [x] T5: Routes API KYC (AC: 1-8)
  - [x] T5.1: Créer `api/src/routes/kyc.rs`
  - [x] T5.2: `GET /api/v1/kyc/pending` — require_role Agent/Admin → list_pending_kyc_users → `{"data": {"users": [...]}}`
  - [x] T5.3: `GET /api/v1/kyc/{user_id}` — require_role Agent/Admin → get_kyc_summary → `{"data": {"user": {...}, "documents": [...], "sponsor": {...}}}`
  - [x] T5.4: `POST /api/v1/kyc/{user_id}/documents` — require_role Agent/Admin → **multipart** (champ `document_type` string + champ `file` binaire) → upload_kyc_document → `{"data": {"document": {...}}}`
  - [x] T5.5: `POST /api/v1/kyc/{user_id}/activate` — require_role Agent/Admin → activate_driver → `{"data": {"user": {...}}}`
  - [x] T5.6: Enregistrer scope kyc dans `routes/mod.rs` : `.service(web::scope("/kyc").route(...))`
  - [x] T5.7: Pour le multipart: utiliser `actix_multipart::Multipart` + itérer sur les champs → séparer champ texte (`document_type`) et champ fichier → accumuler bytes du fichier dans un Vec<u8>

- [x] T6: Repository Users — update_status (AC: 5)
  - [x] T6.1: Ajouter `update_status(pool, user_id, new_status) -> Result<User>` dans `domain/src/users/repository.rs` — UPDATE users SET status=$2 WHERE id=$1 RETURNING *
  - [x] T6.2: Ce repository sera appelé par le service KYC pour passer pending_kyc → active

- [x] T7: Tests Backend (AC: tous)
  - [x] T7.1: Tests unitaires KycDocument model + serde + enum mapping
  - [x] T7.2: Tests unitaires KycDocumentType/KycStatus Display + FromStr
  - [x] T7.3: Tests unitaires upload_encrypted_image validation (taille, MIME)
  - [x] T7.4: Tests service: activate_driver ne fonctionne que si documents existent (mock)
  - [x] T7.5: Tests service: erreur 409 si user déjà active

### Frontend (App Admin — mefali_admin)

- [x] T8: Modèles Dart KYC (AC: 3,5)
  - [x] T8.1: Créer `packages/mefali_core/lib/models/kyc_document.dart` — `@JsonSerializable(fieldRename: FieldRename.snake)` avec champs: id, userId, documentType, encryptedPath, verifiedBy, status, createdAt, updatedAt
  - [x] T8.2: Créer `packages/mefali_core/lib/enums/kyc_document_type.dart` — enum `KycDocumentType { cni, permis }` avec `@JsonValue('cni')` etc.
  - [x] T8.3: Créer `packages/mefali_core/lib/enums/kyc_status.dart` — enum `KycStatus { pending, verified, rejected }` avec `@JsonValue`
  - [x] T8.4: Exporter dans `mefali_core.dart`
  - [x] T8.5: `dart run build_runner build` dans mefali_core

- [x] T9: API Client KYC (AC: 1-7)
  - [x] T9.1: Créer `packages/mefali_api_client/lib/endpoints/kyc_endpoint.dart` — `KycEndpoint(Dio dio)`
  - [x] T9.2: `getPendingDrivers() -> List<User>` — GET /kyc/pending → parse response.data['data']['users']
  - [x] T9.3: `getKycSummary(String userId) -> KycSummary` — GET /kyc/{userId} → parse user + documents + sponsor
  - [x] T9.4: `uploadDocument(String userId, KycDocumentType type, File file) -> KycDocument` — POST /kyc/{userId}/documents avec `FormData.fromMap({'document_type': type.name, 'file': MultipartFile.fromFile(file.path)})` → parse response.data['data']['document']
  - [x] T9.5: `activateDriver(String userId) -> User` — POST /kyc/{userId}/activate → parse response.data['data']['user']
  - [x] T9.6: Exporter dans `mefali_api_client.dart`

- [x] T10: Provider KYC (AC: 1-7)
  - [x] T10.1: Créer `packages/mefali_api_client/lib/providers/kyc_provider.dart`
  - [x] T10.2: `pendingDriversProvider` — `FutureProvider.autoDispose` → kycEndpoint.getPendingDrivers()
  - [x] T10.3: `kycSummaryProvider(String userId)` — `FutureProvider.autoDispose.family` → kycEndpoint.getKycSummary(userId)
  - [x] T10.4: `kycNotifierProvider` — `StateNotifierProvider<KycNotifier, AsyncValue<void>>` pour actions (upload, activate)
  - [x] T10.5: KycNotifier: `uploadDocument()` + `activateDriver()` + invalidate providers après succès

- [x] T11: Écrans Admin — KYC (AC: 1-7)
  - [x] T11.1: Créer `apps/mefali_admin/lib/features/kyc/pending_drivers_screen.dart` — ConsumerWidget, `ref.watch(pendingDriversProvider)` → AsyncValue.when() → ListView des livreurs pending_kyc (nom, téléphone, date inscription) → tap → navigation vers capture
  - [x] T11.2: Créer `apps/mefali_admin/lib/features/kyc/kyc_capture_screen.dart` — ConsumerStatefulWidget:
    - En-tête: infos livreur (nom, téléphone, sponsor)
    - Section documents: 2 emplacements (CNI, Permis) avec état vide/uploadé
    - Bouton caméra via `image_picker` (source: camera) pour chaque type
    - Aperçu photo après capture (Image.file)
    - Upload automatique après capture ou bouton upload explicite
    - Bouton "Activer le livreur" (vert, pleine largeur) — désactivé si 0 document
    - Loading state sur chaque action, SnackBar erreur/succès
  - [x] T11.3: Ajouter route GoRouter: `/kyc` → PendingDriversScreen, `/kyc/:userId` → KycCaptureScreen

- [x] T12: Navigation Home (AC: 1)
  - [x] T12.1: Modifier `apps/mefali_admin/lib/features/home/home_screen.dart` — ajouter un bouton/card "KYC Livreurs" → navigation vers `/kyc`
  - [x] T12.2: Modifier GoRouter dans `app.dart` — ajouter les routes `/kyc` et `/kyc/:userId`

- [x] T13: Tests Frontend (AC: tous)
  - [x] T13.1: Tests widget PendingDriversScreen (rendu liste, état vide)
  - [x] T13.2: Tests widget KycCaptureScreen (rendu infos livreur, bouton activé/désactivé)
  - [x] T13.3: Tests KycDocument model serde

## Dev Notes

### Contexte Métier

Le livreur s'inscrit via l'app mefali_livreur (story 2.3) avec téléphone + sponsor → statut `pending_kyc`. L'agent terrain le rencontre physiquement, capture ses documents d'identité (CNI ou permis), et l'active. C'est une vérification en personne — l'agent voit le document physique.

Le parrainage est déjà enregistré lors de l'inscription (story 2.3 → `verify_otp_and_register()` crée la sponsorship). L'AC "sponsor recorded" signifie que l'agent confirme visuellement le parrain affiché, pas qu'il l'enregistre.

### Architecture Backend — Patrons Établis (Stories 2.1-2.4, 3.1)

**Pattern service/repository (RÉUTILISER EXACTEMENT)** :
- Repository: `sqlx::query_as::<_, Type>()` avec colonnes explicites + `RETURNING *`
- Service: validation métier → appel repository → `Result<T, AppError>`
- Routes: extract `AuthenticatedUser` → `require_role(&auth, &[UserRole::Agent, UserRole::Admin])?` → appel service → `ApiResponse::new(data)`
- Erreurs: `AppError::Conflict(String)` pour 409, `AppError::BadRequest(String)` pour 400, `AppError::NotFound(String)` pour 404

**Pattern multipart Actix (NOUVEAU pour ce story — référence)** :
```rust
use actix_multipart::Multipart;
use futures_util::StreamExt;

async fn handler(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let mut document_type: Option<String> = None;
    let mut file_bytes: Vec<u8> = Vec::new();
    let mut content_type: Option<String> = None;

    while let Some(item) = payload.next().await {
        let mut field = item.map_err(|e| AppError::BadRequest(e.to_string()))?;
        let field_name = field.name().unwrap_or("").to_string();

        match field_name.as_str() {
            "document_type" => {
                let mut data = Vec::new();
                while let Some(chunk) = field.next().await {
                    data.extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
                }
                document_type = Some(String::from_utf8(data).map_err(|_| AppError::BadRequest("Invalid UTF-8".into()))?);
            }
            "file" => {
                content_type = field.content_type().map(|ct| ct.to_string());
                while let Some(chunk) = field.next().await {
                    file_bytes.extend_from_slice(&chunk.map_err(|e| AppError::BadRequest(e.to_string()))?);
                }
            }
            _ => {}
        }
    }
    // ... validate and process
}
```

**Pattern SSE-S3 MinIO (NOUVEAU — AES-256 at rest)** :
```rust
client.put_object()
    .bucket(bucket)
    .key(key)
    .body(ByteStream::from(bytes))
    .content_type(content_type)
    .server_side_encryption(aws_sdk_s3::types::ServerSideEncryption::Aes256)
    .send()
    .await?;
```

**Réutiliser les fonctions existantes** :
- `infrastructure::storage::upload::upload_image()` — base pour `upload_encrypted_image()`
- `infrastructure::storage::create_s3_client()` — client MinIO déjà configuré
- `domain::users::repository::find_by_id()` — lookup user
- Types `Id` et `Timestamp` de `common::types` (alias pour `Uuid` et `DateTime<Utc>`)
- `AppConfig` dans `common::config` — contient déjà `minio_endpoint`, `minio_access_key`, `minio_secret_key`, `minio_bucket`

**Sponsorship query** — Pour afficher le sponsor du livreur dans le résumé KYC :
```sql
SELECT u.* FROM users u
INNER JOIN sponsorships s ON s.sponsor_id = u.id
WHERE s.sponsored_id = $1 AND s.status = 'active'
```
Le module `domain/src/sponsorships/` existe mais repository/service sont des placeholders. Ajouter la query directement dans le repository KYC ou dans sponsorships/repository.

### Architecture Frontend — Patrons Établis

**Endpoint pattern** : `KycEndpoint(Dio dio)` — méthodes retournent modèles parsés depuis `response.data['data']`

**Provider pattern** : `FutureProvider.autoDispose` pour données read-only, `StateNotifierProvider` pour actions mutables. Invalidation après action : `ref.invalidate(pendingDriversProvider)`

**Screen pattern** : `ConsumerStatefulWidget` pour écrans avec état local (photos en attente), `ConsumerWidget` pour listes simples

**Feedback** : SnackBar rouge erreur (persistent), SnackBar vert succès (3s), bouton désactivé + CircularProgressIndicator pendant loading

**Multipart Dio** :
```dart
final formData = FormData.fromMap({
  'document_type': documentType.name,
  'file': await MultipartFile.fromFile(file.path, contentType: MediaType.parse(mimeType)),
});
final response = await dio.post('/api/v1/kyc/$userId/documents', data: formData);
```

**image_picker** : Utiliser `ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1080, imageQuality: 85)` — qualité suffisante pour KYC sans dépasser 2MB. NE PAS compresser en WebP (documents officiels → garder JPEG).

### Contraintes Critiques

1. **Chiffrement AES-256 obligatoire** : Les documents KYC sont des données APDP sensibles. Utiliser `server_side_encryption(ServerSideEncryption::Aes256)` sur CHAQUE put_object KYC. NE PAS oublier ce paramètre.

2. **Taille max 2MB** (pas 400KB comme les photos produit) : Les documents d'identité nécessitent plus de qualité pour être lisibles. Constante séparée `MAX_KYC_IMAGE_SIZE`.

3. **Pas de WebP pour KYC** : Garder JPEG/PNG. Les documents officiels ne doivent pas être re-encodés dans un format potentiellement avec perte. Types autorisés: `image/jpeg`, `image/png` uniquement.

4. **MinIO même bucket, préfixe `kyc/`** : Utiliser `config.minio_bucket` existant avec chemin `kyc/{user_id}/{type}_{uuid}.{ext}`. Migration vers bucket séparé possible plus tard.

5. **Sponsor déjà enregistré** : NE PAS recréer de sponsorship. Le sponsor est créé lors de l'inscription livreur (story 2.3). Ici on affiche seulement le sponsor pour vérification visuelle par l'agent.

6. **require_role Agent/Admin** : Tous les endpoints KYC nécessitent `require_role(&auth, &[UserRole::Agent, UserRole::Admin])?`.

7. **Activation directe** : Pour le MVP, l'agent active directement le livreur (pas de review admin séparée). La validation admin (FR49) sera implémentée dans l'epic 8.

8. **Devices cibles 2GB RAM** : `image_picker` avec `maxWidth: 1920` limite la résolution. NE PAS charger plusieurs photos haute résolution en mémoire simultanément.

9. **Dépendance actix-multipart** : Ajouter `actix-multipart = "0.7"` et `futures-util = "0.3"` dans `server/crates/api/Cargo.toml` si pas déjà présents.

### Structure de Fichiers Attendue

```
server/crates/
  domain/src/
    kyc/                         (NOUVEAU — module complet)
      mod.rs                     (pub mod model/repository/service)
      model.rs                   (KycDocument, KycDocumentType, KycStatus, KycSummary)
      repository.rs              (CRUD kyc_documents)
      service.rs                 (logique upload + activation)
    users/
      repository.rs              (MODIFIER — ajouter update_status)
    lib.rs                       (MODIFIER — ajouter pub mod kyc)
  infrastructure/src/storage/
    upload.rs                    (MODIFIER — ajouter upload_encrypted_image)
  api/src/routes/
    kyc.rs                       (NOUVEAU — 4 handlers)
    mod.rs                       (MODIFIER — ajouter scope kyc)

packages/
  mefali_core/lib/
    models/kyc_document.dart     (NOUVEAU)
    models/kyc_document.g.dart   (GÉNÉRÉ par build_runner)
    enums/kyc_document_type.dart (NOUVEAU)
    enums/kyc_status.dart        (NOUVEAU)
    mefali_core.dart             (MODIFIER — exports)
  mefali_api_client/lib/
    endpoints/kyc_endpoint.dart  (NOUVEAU)
    providers/kyc_provider.dart  (NOUVEAU)
    mefali_api_client.dart       (MODIFIER — exports)

apps/mefali_admin/lib/
  features/
    kyc/                         (NOUVEAU)
      pending_drivers_screen.dart
      kyc_capture_screen.dart
  features/home/
    home_screen.dart             (MODIFIER — ajouter lien KYC)
  app.dart                       (MODIFIER — ajouter routes /kyc)
```

### Project Structure Notes

- Le module `kyc/` est créé dans `domain/src/` comme module frère de `merchants/`, `users/`, `products/`
- Les enums Dart (`KycDocumentType`, `KycStatus`) vont dans `mefali_core/lib/enums/` comme `MerchantCategory`
- L'endpoint KYC est dans `mefali_api_client/lib/endpoints/` suivant le pattern de `merchant_endpoint.dart`
- Les écrans KYC sont dans `mefali_admin/lib/features/kyc/` suivant la structure features/ existante

### Intelligence Story Précédente (3.1 — Agent Terrain Merchant Onboarding)

**Patterns réussis à reproduire :**
- `sqlx::query_as::<_, Type>()` avec RETURNING + colonnes explicites → toutes les queries
- `require_role(&auth, &[UserRole::Agent, UserRole::Admin])?` au début de chaque handler
- `ApiResponse::new(serde_json::json!({ "key": value }))` pour les réponses
- `ConsumerStatefulWidget` pour les écrans avec état local (photos capturées)
- `AsyncValue.when()` dans les widgets pour gérer loading/error/data
- SnackBar feedback pattern (rouge erreur, vert succès)
- Les modèles Dart avec `@JsonSerializable(fieldRename: FieldRename.snake)`

**Pièges de 3.1 à ne PAS reproduire :**
- NE PAS oublier les derives `sqlx::FromRow` et `Serialize` sur les structs Rust
- NE PAS oublier `dart run build_runner build` après création/modif modèles Dart
- NE PAS oublier d'exporter les nouveaux fichiers dans `mefali_core.dart` et `mefali_api_client.dart`
- NE PAS oublier d'enregistrer le scope dans `routes/mod.rs`
- NE PAS utiliser `query!()` macro — utiliser `query_as()`
- Le multipart photo upload a été deferred en 3.1 → c'est maintenant le moment de l'implémenter proprement

**Code review findings 3.1 à intégrer :**
- Toujours vérifier l'ownership agent (agent_id) dans le service → ici vérifier que l'agent est bien un agent via require_role
- Wraper les opérations multi-tables dans une transaction si nécessaire (activate: update kyc_documents + update users)
- Tests d'intégration manquants en 3.1 → essayer d'en ajouter pour KYC

**Stats CI actuelles :** 98 tests Rust + 29 tests Flutter, tous passants.

### Références

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.2]
- [Source: _bmad-output/planning-artifacts/architecture.md — Authentication & Security (KYC storage MinIO chiffré AES-256), Data Architecture (kyc_documents schema)]
- [Source: _bmad-output/planning-artifacts/prd.md — FR3 (agent onboarde livreur CNI/permis), FR48 (onboarding livreur KYC), FR49 (validation KYC admin)]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Flow 4 Fatou agent terrain, Camera capture patterns]
- [Source: server/migrations/20260317000001_create_enums.up.sql — kyc_document_type, kyc_status enums]
- [Source: server/migrations/20260317000013_create_kyc_documents.up.sql — table kyc_documents complète]
- [Source: server/migrations/20260317000003_create_users.up.sql — user_status enum inclut pending_kyc]
- [Source: server/migrations/20260317000012_create_sponsorships.up.sql — table sponsorships]
- [Source: server/crates/domain/src/users/service.rs — verify_otp_and_register() crée sponsorship + set pending_kyc pour drivers]
- [Source: server/crates/infrastructure/src/storage/upload.rs — upload_image() existant comme base]
- [Source: server/crates/infrastructure/src/storage/mod.rs — create_s3_client() MinIO]
- [Source: server/crates/api/src/routes/merchants.rs — pattern handlers Agent existant]
- [Source: server/crates/common/src/error.rs — AppError variants]
- [Source: server/crates/common/src/config.rs — AppConfig avec minio_* fields]
- [Source: _bmad-output/implementation-artifacts/3-1-agent-terrain-merchant-onboarding-flow.md — patterns, pièges, code review findings]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Added `aws-sdk-s3` to domain/Cargo.toml so service can use S3 Client type directly
- Added `actix-multipart` + `futures-util` to workspace/api Cargo.toml for multipart parsing
- Initialized S3 client in main.rs (was commented out as "Future:" from story 3.1)
- Widget tests for PendingDriversScreen/KycCaptureScreen use provider overrides to avoid async timer issues
- KycSummary Dart class created in kyc_endpoint.dart (same pattern as OnboardingStatusResponse in merchant_endpoint.dart)

### Completion Notes List

- Backend: New `kyc/` domain module (model + repository + service) with KycDocument struct, KycDocumentType/KycStatus enums, sponsorship query for sponsor display
- Backend: `upload_encrypted_image()` in infrastructure/storage with SSE-S3 AES-256 encryption, 2MB limit, JPEG/PNG only
- Backend: 4 API routes under `/api/v1/kyc/` (pending, summary, upload document, activate driver) with multipart parsing via actix-multipart
- Backend: `update_status()` added to users/repository for pending_kyc → active transition
- Backend: S3 client initialized in main.rs and injected as app_data
- Frontend: KycDocument model + KycDocumentType/KycStatus enums in mefali_core with build_runner codegen
- Frontend: KycEndpoint with multipart upload (FormData + MultipartFile.fromBytes) + KycSummaryResponse
- Frontend: KycNotifier StateNotifier with upload/activate + provider invalidation
- Frontend: PendingDriversScreen (list pending_kyc drivers) + KycCaptureScreen (camera capture + upload + activate)
- Frontend: GoRouter routes `/kyc` and `/kyc/:userId` + "KYC Livreurs" button on home screen
- Tests: 9 new Rust tests (model serde, enum display, key format, upload validation) — 113 total Rust tests pass
- Tests: 7 new Flutter tests (empty state, driver list, model serde, enum values, KycCaptureScreen) — 11 total admin tests pass
- Zero regressions across entire codebase

### Change Log

- 2026-03-17: Story 3.2 implemented — KYC document capture for drivers (backend + frontend)
- 2026-03-17: Code review — fixed 1 critical, 1 high, 4 medium issues:
  - [C1] Added missing KycCaptureScreen widget tests (T13.2)
  - [H1] Wrapped activate_driver verify+update in DB transaction
  - [M1] Moved list_pending_kyc_users SQL from service to repository
  - [M2] Moved sponsor lookup SQL from service to repository
  - [M3] KycDocument.dart: changed documentType/status from String to enum types
  - [M4] Added storage/mod.rs to File List

### File List

**New files:**
- server/crates/domain/src/kyc/mod.rs
- server/crates/domain/src/kyc/model.rs
- server/crates/domain/src/kyc/repository.rs
- server/crates/domain/src/kyc/service.rs
- server/crates/api/src/routes/kyc.rs
- server/crates/infrastructure/src/storage/upload.rs (modified — added upload_encrypted_image)
- packages/mefali_core/lib/models/kyc_document.dart
- packages/mefali_core/lib/models/kyc_document.g.dart
- packages/mefali_core/lib/enums/kyc_document_type.dart
- packages/mefali_core/lib/enums/kyc_status.dart
- packages/mefali_api_client/lib/endpoints/kyc_endpoint.dart
- packages/mefali_api_client/lib/providers/kyc_provider.dart
- apps/mefali_admin/lib/features/kyc/pending_drivers_screen.dart
- apps/mefali_admin/lib/features/kyc/kyc_capture_screen.dart

**Modified files:**
- server/Cargo.toml (added actix-multipart, futures-util workspace deps)
- server/crates/api/Cargo.toml (added actix-multipart, futures-util, aws-sdk-s3)
- server/crates/domain/Cargo.toml (added aws-sdk-s3)
- server/crates/domain/src/lib.rs (added pub mod kyc)
- server/crates/domain/src/users/repository.rs (added update_status function)
- server/crates/infrastructure/src/storage/upload.rs (added upload_encrypted_image + KYC constants)
- server/crates/infrastructure/src/storage/mod.rs (added pub mod upload)
- server/crates/api/src/routes/mod.rs (added kyc scope)
- server/crates/api/src/main.rs (added S3 client initialization + app_data)
- packages/mefali_core/lib/mefali_core.dart (added KYC exports)
- packages/mefali_api_client/lib/mefali_api_client.dart (added KYC exports)
- apps/mefali_admin/lib/app.dart (added /kyc routes + imports)
- apps/mefali_admin/lib/features/home/home_screen.dart (added KYC Livreurs button)
- apps/mefali_admin/pubspec.yaml (added image_picker dependency)
- apps/mefali_admin/test/widget_test.dart (added 7 KYC tests)
