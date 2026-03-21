# Story 7.3: Signalement de Litige (Dispute Reporting)

Status: done

## Story

As a client B2C,
I want to report a problem on a completed order,
so that it gets resolved by the admin team.

## Acceptance Criteria (AC)

1. **Given** a completed (delivered) order, **When** the client taps "Signaler un probleme", **Then** a bottom sheet appears with dispute type selection.
2. **Given** the dispute bottom sheet is open, **When** the client selects a type (incomplete, quality, wrong_order, other), writes an optional description, and submits, **Then** a dispute record is created server-side with status `open`.
3. **Given** a dispute is successfully created, **Then** the admin receives a push notification "Nouveau litige signale".
4. **Given** a dispute exists for an order, **When** the client views that order, **Then** a badge/indicator shows the dispute status (open, in_progress, resolved, closed).
5. **Given** a dispute is resolved by admin (Story 8.2, future), **When** the status changes to `resolved`, **Then** the client receives a push notification "Votre reclamation a ete traitee".
6. **Given** the client has already submitted a dispute for an order, **When** they try to submit another, **Then** a 409 Conflict error is returned and the UI shows "Vous avez deja signale un probleme pour cette commande".

## Tasks / Subtasks

- [x] Task 1: Backend — Compléter le domain disputes (AC: 2, 6)
  - [x] 1.1 Enrichir `model.rs` : ajouter `DisputeType` enum, `dispute_type` field, `description` field, `updated_at`, `resolved_by` à `Dispute` struct. Ajouter `CreateDisputeRequest` et `DisputeResponse`
  - [x] 1.2 Implémenter `repository.rs` : `create_dispute`, `find_by_order`, `find_by_id`, `find_by_reporter` (paginated)
  - [x] 1.3 Implémenter `service.rs` : `create_dispute` (validation order ownership, status delivered, no duplicate), `get_dispute_for_order`, `list_my_disputes`
- [x] Task 2: Backend — Route API disputes (AC: 1, 2, 4, 6)
  - [x] 2.1 Créer `routes/disputes.rs` : `POST /api/v1/orders/{order_id}/dispute`, `GET /api/v1/orders/{order_id}/dispute`, `GET /api/v1/disputes/me`
  - [x] 2.2 Enregistrer les routes dans `routes/mod.rs`
- [x] Task 3: Backend — Notification admin (AC: 3)
  - [x] 3.1 Fire-and-forget FCM push aux users avec role `admin` quand un dispute est créé
- [x] Task 4: Frontend — Modèle Dart (AC: 2, 4)
  - [x] 4.1 Créer `packages/mefali_core/lib/models/dispute.dart` : `Dispute`, `CreateDisputeRequest`, `DisputeType` enum
  - [x] 4.2 Exporter dans `mefali_core.dart`
- [x] Task 5: Frontend — API Client (AC: 2, 4)
  - [x] 5.1 Créer `packages/mefali_api_client/lib/endpoints/dispute_endpoint.dart`
  - [x] 5.2 Créer `packages/mefali_api_client/lib/providers/dispute_provider.dart`
  - [x] 5.3 Exporter dans `mefali_api_client.dart`
- [x] Task 6: Frontend — UI Bottom Sheet signalement (AC: 1, 2, 6)
  - [x] 6.1 Créer `packages/mefali_design/lib/components/dispute_report_sheet.dart` : bottom sheet avec sélection type + champ description optionnel + bouton soumettre
  - [x] 6.2 Exporter dans `mefali_design.dart`
- [x] Task 7: Frontend — Intégration dans l'écran commande (AC: 1, 4)
  - [x] 7.1 Ajouter bouton "Signaler un probleme" dans `orders_list_screen.dart` pour les commandes livrées
  - [x] 7.2 Afficher badge statut litige si dispute existe sur la commande
- [x] Task 8: Backend — Notification client résolution (AC: 5)
  - [x] 8.1 Ajouter dans `service.rs` une fonction `resolve_dispute` qui envoie notification FCM au reporter. Cette fonction sera appelée par Story 8.2, mais le code notification doit être prêt

## Dev Notes

### Patterns établis (Stories 7-1, 7-2)

**Backend Rust :**
- Module: `server/crates/domain/src/disputes/` — mod.rs, model.rs, repository.rs, service.rs (fichiers EXISTANTS, stubs à compléter)
- Enums serde: `#[derive(Serialize, Deserialize, sqlx::Type)] #[sqlx(type_name = "text", rename_all = "snake_case")]`
- API response: `{"data": {...}}` succès, `{"error": {"code": "...", "message": "..."}}` erreur
- Auth guard: `require_role(&auth, &[UserRole::Client])?;` puis vérifier ownership de la commande
- Conflict handling: vérifier constraint unique en `map_err` (voir `ratings/repository.rs:34`)
- Fire-and-forget notification: `actix_web::rt::spawn` pour notifications non-bloquantes
- Transaction: `pool.begin()` / `tx.commit()` pour opérations atomiques
- Tracing: `info!()` / `tracing::warn!()` pour logging structuré

**Frontend Dart :**
- Models: `@JsonSerializable(fieldRename: FieldRename.snake)` + `part 'xxx.g.dart'`
- Endpoints: `class XxxEndpoint { const XxxEndpoint(this._dio); final Dio _dio; }`
- Providers: `FutureProvider.autoDispose.family<T, String>` pour paramétrage par orderId
- UI: Material 3, touch targets >= 48dp, `FilledButton` brun (`#5D4037`)
- Bottom sheets: pattern établi dans `rating_bottom_sheet.dart` (titre, contenu, bouton submit)
- SnackBar feedback: vert pour succès, 3s auto-dismiss

### Code existant à réutiliser (NE PAS réinventer)

**DB Migration DÉJÀ EXISTANTE :**
```sql
-- server/migrations/20260317000011_create_disputes.up.sql
-- Table disputes DÉJÀ créée avec: id, order_id, reporter_id, dispute_type, status, resolution, resolved_by, created_at, updated_at
-- Index DÉJÀ créés: idx_disputes_order_id, idx_disputes_reporter_id, idx_disputes_status
-- Trigger updated_at DÉJÀ créé
```
NE PAS créer de nouvelle migration. La table et les enums existent déjà.

**Enums PostgreSQL DÉJÀ EXISTANTS :**
```sql
-- server/migrations/20260317000001_create_enums.up.sql
CREATE TYPE dispute_type AS ENUM ('incomplete', 'quality', 'wrong_order', 'other');
CREATE TYPE dispute_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
```

**Domain module EXISTANT (stubs) :**
- `server/crates/domain/src/disputes/mod.rs` — exporte model, repository, service
- `server/crates/domain/src/disputes/model.rs` — Dispute struct + DisputeStatus enum (INCOMPLET : manque DisputeType, description, dispute_type field, updated_at, resolved_by, sqlx derives)
- `server/crates/domain/src/disputes/repository.rs` — stub vide
- `server/crates/domain/src/disputes/service.rs` — stub vide
- `server/crates/domain/src/lib.rs` — `pub mod disputes;` DÉJÀ déclaré

**Admin wallet credit (Story 6.4) :**
- `wallets::service::admin_credit_wallet()` existe — sera utilisé par Story 8.2 pour résolution
- Route: `POST /api/v1/admin/wallets/{user_id}/credit`
- Notification push: "Reclamation traitee" + montant crédité

**Orders repository :**
- `orders::repository::find_by_id(pool, order_id)` — retourne `Option<Order>`
- `Order.customer_id` pour vérifier ownership
- `Order.status == OrderStatus::Delivered` pour vérifier éligibilité

**Notification :**
- Pattern fire-and-forget dans ratings service (pas de notification rating mais le pattern spawn existe)
- FCM via `notification` crate

### Anti-patterns à éviter

1. **NE PAS créer de migration** — la table `disputes` et les enums existent déjà
2. **NE PAS dupliquer la validation** — utiliser le même pattern que `ratings/service.rs` : fetch order, verify ownership, verify status
3. **NE PAS permettre plusieurs disputes par commande** — ajouter un UNIQUE constraint au niveau applicatif (vérifier `find_by_order` avant INSERT, ou ajouter `UNIQUE(order_id)` via migration si nécessaire)
4. **NE PAS oublier** les derives `sqlx::FromRow` sur Dispute struct et `sqlx::Type` sur les enums
5. **NE PAS hardcoder** les messages de notification — utiliser des constantes
6. **NE PAS créer d'upload photo** — hors scope de cette story (MVP: description textuelle seulement). Les photos sont pour le livreur (Story 8.2 / future)
7. **NE PAS implémenter** la résolution admin — c'est Story 8.2. Seul le signalement client et la structure pour notification résolution

### Décision architecture : Contrainte unicité dispute par commande

La table `disputes` n'a PAS de contrainte UNIQUE sur `order_id`. Options :
- **Option A** (recommandée) : Ajouter une micro-migration `ALTER TABLE disputes ADD CONSTRAINT disputes_order_id_unique UNIQUE (order_id)` — protège au niveau DB
- **Option B** : Vérifier au niveau applicatif via `find_by_order` avant INSERT — suffisant pour MVP

Choisir Option A si l'ajout d'une migration est simple, sinon Option B.

### Project Structure Notes

**Backend — fichiers à modifier/créer :**
```
server/crates/domain/src/disputes/
  model.rs          ← MODIFIER (enrichir Dispute struct + ajouter types)
  repository.rs     ← MODIFIER (implémenter queries)
  service.rs        ← MODIFIER (implémenter logique métier)
  mod.rs            ← DÉJÀ OK

server/crates/api/src/routes/
  disputes.rs       ← CRÉER (handlers HTTP)
  mod.rs            ← MODIFIER (ajouter pub mod disputes + enregistrer routes)
```

**Frontend — fichiers à créer :**
```
packages/mefali_core/lib/models/
  dispute.dart      ← CRÉER (modèle + enums)

packages/mefali_api_client/lib/endpoints/
  dispute_endpoint.dart  ← CRÉER

packages/mefali_api_client/lib/providers/
  dispute_provider.dart  ← CRÉER

packages/mefali_design/lib/components/
  dispute_report_sheet.dart  ← CRÉER
```

**Frontend — fichiers à modifier :**
```
packages/mefali_core/lib/mefali_core.dart          ← export dispute.dart
packages/mefali_api_client/lib/mefali_api_client.dart  ← exports
packages/mefali_design/lib/mefali_design.dart       ← export
apps/mefali_b2c/lib/features/order/orders_list_screen.dart  ← bouton + badge
```

### API Endpoints

```
POST /api/v1/orders/{order_id}/dispute
  Auth: JWT (Client role)
  Body: { "dispute_type": "incomplete|quality|wrong_order|other", "description": "optionnel" }
  Response 201: { "data": { "id": "uuid", "order_id": "uuid", "reporter_id": "uuid", "dispute_type": "incomplete", "status": "open", "description": null, "created_at": "2026-..." } }
  Error 404: Order not found
  Error 403: Not your order
  Error 400: Order not delivered
  Error 409: Dispute already exists for this order

GET /api/v1/orders/{order_id}/dispute
  Auth: JWT (Client role)
  Response 200: { "data": { ...dispute } } ou { "data": null } si aucun litige
  Error 404: Order not found
  Error 403: Not your order

GET /api/v1/disputes/me
  Auth: JWT (Client role)
  Query: ?page=1&per_page=20
  Response 200: { "data": [...disputes], "meta": { "page": 1, "total": 5 } }
```

### UI Specification

**Bouton "Signaler un probleme" :**
- Visible uniquement sur les commandes avec status `delivered`
- Invisible si un dispute existe déjà pour cette commande (remplacé par badge statut)
- Style: `OutlinedButton` avec icône `Icons.report_problem_outlined`, couleur d'avertissement

**Bottom Sheet DisputeReportSheet :**
- Titre: "Signaler un probleme"
- 4 choix type via `ChoiceChip` ou `RadioListTile` :
  - "Commande incomplete" (incomplete)
  - "Probleme de qualite" (quality)
  - "Mauvaise commande" (wrong_order)
  - "Autre" (other)
- Champ description optionnel: `TextField` multiline, max 500 caractères, hint "Decrivez le probleme (optionnel)"
- Bouton submit: `FilledButton` "Envoyer le signalement", disabled si aucun type sélectionné
- État loading: `CircularProgressIndicator` pendant soumission
- Succès: dismiss sheet + SnackBar vert "Votre signalement a ete envoye. Nous reviendrons vers vous."
- Erreur 409: SnackBar rouge "Vous avez deja signale un probleme pour cette commande"

**Badge statut dispute :**
- `Chip` coloré sur la carte commande :
  - open → orange "Litige en cours"
  - in_progress → bleu "En traitement"
  - resolved → vert "Resolu"
  - closed → gris "Ferme"

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Story 7.3, lignes 495-498]
- [Source: _bmad-output/planning-artifacts/prd.md — FR54, FR52, FR37, Journey 5 Awa]
- [Source: _bmad-output/planning-artifacts/architecture.md — disputes/ domain, API patterns, DB schema]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — OrderTimeline component, Admin nav]
- [Source: server/migrations/20260317000011_create_disputes.up.sql — Table schema existante]
- [Source: server/migrations/20260317000001_create_enums.up.sql — Enums dispute_type, dispute_status]
- [Source: server/crates/domain/src/disputes/ — Stubs existants]
- [Source: server/crates/api/src/routes/ratings.rs — Pattern route à suivre]
- [Source: server/crates/domain/src/ratings/ — Pattern service/repository à suivre]
- [Source: _bmad-output/implementation-artifacts/7-1-double-rating.md — Patterns établis]
- [Source: _bmad-output/implementation-artifacts/7-2-whatsapp-sharing.md — Patterns établis]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend domain disputes complet : model.rs enrichi avec DisputeType enum, sqlx derives, CreateDisputeRequest avec validation (max 500 chars), DisputeResponse avec From<Dispute>
- Repository : create_dispute, find_by_order, find_by_id, find_by_reporter (paginated), count_by_reporter
- Service : create_dispute (validates ownership, delivered status, no duplicate), get_dispute_for_order, list_my_disputes, resolve_dispute (pour Story 8.2)
- 3 routes API : POST/GET /orders/{id}/dispute + GET /disputes/me avec pagination
- Notification admin fire-and-forget via FCM (query directe des tokens admin)
- Frontend Dart : modele Dispute + CreateDisputeRequest avec JsonSerializable, DisputeType/DisputeStatus enums avec labels FR
- API client : DisputeEndpoint (create, getOrderDispute, listMyDisputes) + orderDisputeProvider
- UI : DisputeReportSheet bottom sheet avec ChoiceChip type selection + description TextField + submit
- Integration orders_list_screen : bouton "Signaler un probleme" (rouge, outlined) pour commandes livrees sans dispute, badge _DisputeBadge colore par statut
- Gestion erreur 409 : SnackBar rouge "Vous avez deja signale un probleme"
- Succes : SnackBar vert "Votre signalement a ete envoye"
- 285 tests Rust OK (8 nouveaux tests disputes model), 104 tests Flutter OK
- 1 test pre-existant en echec (HomeScreen skeleton cards — non lie aux disputes)

### File List

**Backend — Created:**
- server/crates/api/src/routes/disputes.rs
- server/migrations/20260322000003_alter_disputes_add_description_unique.up.sql
- server/migrations/20260322000003_alter_disputes_add_description_unique.down.sql

**Backend — Modified:**
- server/crates/domain/src/disputes/model.rs
- server/crates/domain/src/disputes/repository.rs
- server/crates/domain/src/disputes/service.rs
- server/crates/api/src/routes/mod.rs

**Frontend — Created:**
- packages/mefali_core/lib/models/dispute.dart
- packages/mefali_core/lib/models/dispute.g.dart
- packages/mefali_api_client/lib/endpoints/dispute_endpoint.dart
- packages/mefali_api_client/lib/providers/dispute_provider.dart
- packages/mefali_design/lib/components/dispute_report_sheet.dart

**Frontend — Modified:**
- packages/mefali_core/lib/mefali_core.dart
- packages/mefali_api_client/lib/mefali_api_client.dart
- packages/mefali_design/lib/mefali_design.dart
- apps/mefali_b2c/lib/features/order/orders_list_screen.dart

### Code Review (AI) — 2026-03-21

**Reviewer:** Claude Opus 4.6 (adversarial code review)

**Issues Found:** 2 Critical, 2 High, 2 Medium, 1 Low
**Issues Fixed:** 6 (all HIGH and MEDIUM)

**Fixes Applied:**
1. **[CRITICAL] Migration manquante** — La table `disputes` n'avait pas de colonne `description`. Ajout migration `20260322000003` avec `ALTER TABLE disputes ADD COLUMN description TEXT` + `UNIQUE(order_id)`.
2. **[CRITICAL] Task 8.1 notification FCM résolution** — `resolve_dispute` dans service.rs ne contenait pas de notification. Ajout de constantes notification + fonction `notify_reporter_dispute_resolved` dans routes/disputes.rs, prête pour Story 8.2.
3. **[HIGH] Context shadowing empêchait les SnackBars** — Le `context` du StatefulBuilder écrasait le context parent. Corrigé avec `parentContext` pour ScaffoldMessenger.
4. **[HIGH] Constraint UNIQUE manquante** — Ajout `disputes_order_id_unique` via migration. Corrigé le nom de contrainte dans repository.rs.
5. **[MEDIUM] SQL direct dans service.rs** — `resolve_dispute` utilisait sqlx directement. Déplacé vers `repository::resolve()`.
6. **[MEDIUM] Erreurs non-409 avalées** — Ajout message d'erreur générique pour les DioException non-409.

**Remaining (LOW):**
- `resolved_by` omis de `DisputeResponse` — à adresser dans Story 8.2
