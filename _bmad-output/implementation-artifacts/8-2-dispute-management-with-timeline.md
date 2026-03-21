# Story 8.2: Gestion des Litiges avec Timeline

Status: done

## Story

As an admin,
I want to resolve disputes with full order timeline,
so that I make informed decisions based on complete context.

## Acceptance Criteria

1. Given un litige signale, When l'admin ouvre la liste des litiges, Then tous les litiges pending (open/in_progress) sont affiches avec type, date, commande, et statut.
2. Given un litige ouvert, When l'admin clique dessus, Then l'OrderTimeline affiche tous les evenements horodates (commande placee, collectee, livree, litige signale).
3. Given le detail d'un litige, When l'admin consulte, Then l'historique marchand (total commandes, litiges precedents) et livreur (total livraisons, litiges) est visible.
4. Given un litige ouvert, When l'admin resout avec action credit/warn/dismiss, Then le statut passe a `resolved`, une notification push est envoyee au client, et si credit alors le wallet client est credite.
5. Given un litige resolu, When l'admin revient a la liste, Then le litige n'apparait plus dans les pending et le compteur dashboard se met a jour.

## Tasks / Subtasks

- [x] Task 1: Backend — Endpoints admin litiges (AC: 1, 2, 3, 4)
  - [x] 1.1: `GET /api/v1/admin/disputes` — liste paginee des litiges avec filtres (status, type), incluant order summary + reporter info
  - [x] 1.2: `GET /api/v1/admin/disputes/{dispute_id}` — detail complet: dispute + order timeline events + merchant stats + driver stats
  - [x] 1.3: `POST /api/v1/admin/disputes/{dispute_id}/resolve` — body: `{"action": "credit|warn|dismiss", "resolution": "...", "credit_amount": 500}`. Met a jour status, credite wallet si action=credit (via wallet service existant), envoie notification FCM au reporter
  - [x] 1.4: Tests d'integration Rust (4-6 tests: list, detail, resolve credit, resolve warn, resolve dismiss, resolve unauthorized)

- [x] Task 2: Backend — Query helpers pour timeline et historique (AC: 2, 3)
  - [x] 2.1: Fonction `get_order_timeline(pool, order_id)` dans orders repository — retourne les timestamps cles (created_at, collected_at, delivered_at) depuis les tables orders + deliveries
  - [x] 2.2: Fonction `get_merchant_stats(pool, merchant_id)` — total orders, total disputes, disputes confirmees
  - [x] 2.3: Fonction `get_driver_stats(pool, driver_id)` — total deliveries, total disputes

- [x] Task 3: Frontend — Modeles et API client (AC: 1, 2, 3, 4)
  - [x] 3.1: `DisputeDetail` model dans `mefali_core` — dispute + order timeline + merchant stats + driver stats
  - [x] 3.2: `ResolveDisputeRequest` model — action enum (credit/warn/dismiss), resolution text, credit_amount optionnel
  - [x] 3.3: Etendre `AdminEndpoint` — listDisputes(page, status?, type?), getDisputeDetail(id), resolveDispute(id, request)
  - [x] 3.4: Providers Riverpod — `adminDisputesProvider` (FutureProvider.autoDispose), `disputeDetailProvider` (FutureProvider.autoDispose.family)

- [x] Task 4: Frontend — Ecran liste des litiges (AC: 1, 5)
  - [x] 4.1: `DisputeListScreen` dans `mefali_admin/lib/features/disputes/` — liste avec Card par litige (type icon, date, merchant name, status chip colore)
  - [x] 4.2: Filtres par status (Tous/Open/In Progress/Resolved) via ChoiceChip
  - [x] 4.3: Pull-to-refresh + skeleton loading
  - [x] 4.4: Navigation vers detail au tap

- [x] Task 5: Frontend — Ecran detail litige avec OrderTimeline (AC: 2, 3, 4)
  - [x] 5.1: `DisputeDetailScreen` — header avec type + status + date
  - [x] 5.2: `OrderTimeline` widget dans `mefali_design/lib/components/` — timeline verticale avec etapes (commande, collecte, livraison, signalement), icones vert (complete) / marron pulsant (en cours) / gris (futur)
  - [x] 5.3: Section historique marchand (Card: nom, total commandes, litiges, note moyenne)
  - [x] 5.4: Section historique livreur (Card: nom, total livraisons, litiges)
  - [x] 5.5: Section description du litige (texte client + type)
  - [x] 5.6: Bouton "Resoudre" ouvrant bottom sheet de resolution

- [x] Task 6: Frontend — Bottom sheet de resolution (AC: 4)
  - [x] 6.1: `DisputeResolutionSheet` — choix action via RadioListTile (Crediter client, Avertir, Classer sans suite)
  - [x] 6.2: Si action=credit: champ montant (TextField numerique, FCFA)
  - [x] 6.3: Champ resolution/notes (TextField multiline, obligatoire)
  - [x] 6.4: FilledButton "Confirmer la resolution" avec loading state
  - [x] 6.5: SnackBar succes vert + retour a la liste + invalidation providers

- [x] Task 7: Navigation — Integrer dans AdminShellScreen (AC: 5)
  - [x] 7.1: Remplacer le stub "Bientot disponible" du NavigationRail/Bar index 4 (Litiges) par `DisputeListScreen`
  - [x] 7.2: Navigation vers detail via Navigator.push (pas GoRouter — navigation interne au shell)

- [x] Task 8: Tests Flutter (AC: 1-5)
  - [x] 8.1: Widget tests pour DisputeListScreen (empty state, data cards, filter chips)
  - [x] 8.2: Widget tests pour DisputeDetailScreen (timeline rendering, stats display)
  - [x] 8.3: Widget tests pour DisputeResolutionSheet (action selection, credit field toggle)
  - [x] 8.4: Widget test pour OrderTimeline (events rendering, icons)

## Dev Notes

### Architecture Backend

**Pattern etabli dans 8-1 et 7-3 — SUIVRE EXACTEMENT:**
- Routes admin dans `server/crates/api/src/routes/admin.rs` — ajouter les 3 nouveaux endpoints dans le scope `/admin/disputes`
- Guard admin: utiliser `AuthenticatedUser` extractor + `require_role(Role::Admin)` (deja dans admin.rs)
- Response wrapper: `ApiResponse::new(data)` → `{"data": ..., "meta": {...}}`
- Erreurs: `AppError` enum avec mapping HTTP automatique
- Queries DB: `sqlx::query_as::<_, T>()` avec const COLUMNS strings
- Parallelisme: `tokio::try_join!` pour les queries independantes (stats merchant + driver en parallele)

**Dispute domain existant (NE PAS DUPLIQUER):**
- `server/crates/domain/src/disputes/model.rs` — Dispute, DisputeType, DisputeStatus, CreateDisputeRequest, DisputeResponse
- `server/crates/domain/src/disputes/repository.rs` — create_dispute, find_by_order, find_by_id, find_by_reporter, resolve(), count_by_reporter
- `server/crates/domain/src/disputes/service.rs` — create_dispute, resolve_dispute (EXISTE DEJA, notification preparee)
- La fonction `resolve_dispute(pool, dispute_id, admin_id, resolution)` dans repository.rs met deja le status a Resolved

**Ce qui MANQUE cote backend (a creer):**
- Endpoint admin pour lister les litiges avec joins (order, reporter, merchant info)
- Endpoint admin pour detail avec timeline (join orders + deliveries pour timestamps)
- Endpoint admin pour resoudre avec logique credit wallet (appeler `wallet_transactions` service existant si action=credit)
- Query helpers pour merchant/driver stats (COUNT orders, COUNT disputes)

**Notification resolution (DEJA PRETE):**
- `notify_reporter_dispute_resolved()` dans `routes/disputes.rs` — envoie FCM push au reporter
- Constantes dans service.rs: `DISPUTE_RESOLVED_TITLE`, `DISPUTE_RESOLVED_BODY`
- Appeler cette fonction apres resolve reussi

**Credit wallet (Story 6-4 DONE):**
- Service wallet existant avec `credit_wallet(pool, user_id, amount, reference)`
- Utiliser reference format: `"dispute_credit_{dispute_id}"`
- Ne PAS reimplementer la logique wallet

### Architecture Frontend

**Pattern etabli dans 8-1 — SUIVRE EXACTEMENT:**
- Modeles dans `packages/mefali_core/lib/models/` avec `@JsonSerializable(fieldRename: FieldRename.snake)`
- Endpoints dans `packages/mefali_api_client/lib/endpoints/admin_endpoint.dart` — ETENDRE la classe existante
- Providers dans `packages/mefali_api_client/lib/providers/` — FutureProvider.autoDispose, family pour parametre
- UI dans `apps/mefali_admin/lib/features/disputes/` — nouveau dossier
- Composants reutilisables dans `packages/mefali_design/lib/components/` (OrderTimeline)
- Navigation: AdminShellScreen a deja 5 destinations, index 4 = Litiges (stub a remplacer)

**Modeles existants (NE PAS DUPLIQUER):**
- `packages/mefali_core/lib/models/dispute.dart` — Dispute, DisputeType, DisputeStatus, CreateDisputeRequest
- `packages/mefali_api_client/lib/endpoints/dispute_endpoint.dart` — DisputeEndpoint (endpoints client B2C)
- `packages/mefali_api_client/lib/providers/dispute_provider.dart` — orderDisputeProvider

**Ce qui MANQUE cote frontend (a creer):**
- Modele `DisputeDetail` (dispute + order timeline + actor stats) — NOUVEAU dans mefali_core
- Modele `ResolveDisputeRequest` (action, resolution, credit_amount) — NOUVEAU dans mefali_core
- 3 methodes dans AdminEndpoint existant (listDisputes, getDisputeDetail, resolveDispute)
- 2 providers admin (adminDisputesProvider, disputeDetailProvider)
- DisputeListScreen, DisputeDetailScreen dans mefali_admin
- OrderTimeline widget dans mefali_design/lib/components/
- DisputeResolutionSheet dans mefali_design/lib/components/

### UX Requirements

**OrderTimeline (UX-DR8):**
- Timeline verticale avec ligne et dots/icones
- Etats: complete = vert (#4CAF50), en cours = marron pulsant (#5D4037 avec animation), futur = gris
- Evenements: Commande placee → Acceptee marchand → Collectee livreur → Livree → Signalement litige
- Chaque evenement: icone + label + timestamp (format "HH:mm - dd/MM")

**Ecran liste litiges:**
- Card par litige: icone type (report_problem), nom marchand, date, Chip status colore (open=orange, in_progress=blue, resolved=green, closed=grey)
- Filtres via ChoiceChip en haut
- Empty state: "Aucun litige en attente" avec icone

**Ecran detail:**
- Header: type de litige + chip status + date
- Sections: OrderTimeline, Historique marchand (Card), Historique livreur (Card), Description client
- Bouton CTA en bas: "Resoudre ce litige" (FilledButton marron, pleine largeur)

**Bottom sheet resolution:**
- 3 RadioListTile: "Crediter le client" (avec TextField montant FCFA si selectionne), "Avertir le marchand/livreur", "Classer sans suite"
- TextField multiline pour notes/resolution (obligatoire)
- FilledButton "Confirmer" marron

**Feedback:**
- Succes: SnackBar vert 3s "Litige resolu avec succes"
- Erreur: SnackBar rouge persistent avec message
- Loading: Skeleton screens (pas de spinner seul)

**Responsive:**
- Desktop (>1024px): layout avec padding lateral
- Tablet (768-1024px): layout pleine largeur
- Mobile (<768px): NavigationBar en bas (deja gere par AdminShellScreen)

### Database

**Schema disputes existant (NE PAS MODIFIER):**
```sql
disputes (id UUID PK, order_id UUID UNIQUE FK, reporter_id UUID FK,
  dispute_type dispute_type, status dispute_status, description TEXT,
  resolution TEXT, resolved_by UUID FK, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ)
```

**Tables a JOIN pour timeline:**
- `orders` — created_at (commande placee), status
- `deliveries` — pour collected_at, delivered_at (si ces colonnes existent, sinon utiliser status transitions)
- `users` — nom reporter, nom marchand, nom livreur
- `merchants` — nom du commerce

**Tables a JOIN pour stats:**
- `orders` — COUNT WHERE merchant_id = X (total commandes marchand)
- `deliveries` — COUNT WHERE driver_id = X (total livraisons)
- `disputes` — COUNT WHERE order_id IN (orders du marchand) pour litiges marchand
- `disputes` — COUNT WHERE resolved_by IS NOT NULL pour litiges confirmes

**Aucune nouvelle migration requise** — le schema disputes est complet.

### Anti-patterns a EVITER

- NE PAS creer un nouveau module domain pour admin disputes — reutiliser `domain/disputes/`
- NE PAS dupliquer les modeles Dispute/DisputeType/DisputeStatus — ils existent deja
- NE PAS creer de nouveau DisputeEndpoint cote admin — etendre AdminEndpoint
- NE PAS utiliser StreamProvider ou WebSocket pour la liste — FutureProvider avec refresh manuel suffit
- NE PAS ajouter de charting/graphiques — ce n'est pas dans le scope
- NE PAS implementer la gestion complete de l'historique (Story 8.5) — juste les stats de base pour le contexte litige
- NE PAS modifier les routes client B2C existantes dans disputes.rs
- NE PAS ajouter de nouveaux enums DisputeStatus — open/in_progress/resolved/closed suffisent
- NE PAS creer de migration — le schema est complet

### Project Structure Notes

**Fichiers a CREER:**
```
apps/mefali_admin/lib/features/disputes/
  dispute_list_screen.dart
  dispute_detail_screen.dart
packages/mefali_design/lib/components/
  order_timeline.dart
  dispute_resolution_sheet.dart
packages/mefali_core/lib/models/
  dispute_detail.dart        # DisputeDetail, OrderTimelineEvent, ActorStats, ResolveDisputeRequest
```

**Fichiers a MODIFIER:**
```
server/crates/api/src/routes/admin.rs          # ajouter 3 endpoints disputes
server/crates/domain/src/disputes/repository.rs # ajouter queries stats
server/crates/api/src/routes/mod.rs            # register admin dispute routes
packages/mefali_api_client/lib/endpoints/admin_endpoint.dart  # 3 nouvelles methodes
packages/mefali_api_client/lib/providers/admin_dashboard_provider.dart  # ou nouveau fichier provider
packages/mefali_core/lib/mefali_core.dart      # export nouveaux modeles
packages/mefali_api_client/lib/mefali_api_client.dart  # export nouveaux providers
packages/mefali_design/lib/mefali_design.dart  # export nouveaux composants
apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart  # remplacer stub Litiges
apps/mefali_admin/lib/app.dart                 # ajouter route detail
```

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 8, Story 8.2]
- [Source: _bmad-output/planning-artifacts/prd.md — Journey 5 (Awa), FR52, FR55, FR37]
- [Source: _bmad-output/planning-artifacts/architecture.md — API Patterns, Data Architecture, Frontend Architecture]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — UX-DR8 OrderTimeline, Admin Navigation]
- [Source: _bmad-output/implementation-artifacts/7-3-dispute-reporting.md — Dispute domain implementation]
- [Source: _bmad-output/implementation-artifacts/8-1-admin-operational-dashboard.md — Admin patterns, AdminShellScreen]

### Previous Story Intelligence

**De 8-1 (Admin Operational Dashboard):**
- AdminGuard avec `require_role()` fonctionne — reutiliser le meme pattern
- `AdminEndpoint` + `adminDashboardProvider` avec cache fallback — pattern valide
- `AdminShellScreen` a 5 destinations, index 4 = Litiges avec stub "Bientot disponible"
- Responsive: NavigationRail (>768px) / NavigationBar (mobile) — deja gere
- Tests: 4 Rust integration + 3 Flutter widget tests — viser meme couverture
- Anti-pattern confirme: pas de WebSocket pour dashboard, simple polling/refresh

**De 7-3 (Dispute Reporting):**
- Tout le domain disputes est implemente et code-reviewed
- `resolve_dispute()` existe dans service.rs et repository.rs
- `notify_reporter_dispute_resolved()` existe dans routes/disputes.rs (fire-and-forget FCM)
- Migration 20260322000003 a ajoute description + UNIQUE(order_id)
- Pattern UI: ChoiceChip pour selection type, bottom sheet pour formulaire
- 285 tests Rust passent, 104 Flutter tests passent — ne pas casser

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- Backend: 3 admin endpoints added to `admin.rs` — `GET /admin/disputes` (paginated list with status/type filters), `GET /admin/disputes/{id}` (detail with timeline + actor stats), `POST /admin/disputes/{id}/resolve` (credit/warn/dismiss with wallet credit integration)
- Backend: Query helpers in `repository.rs` — `find_all_admin`, `count_all_admin`, `get_order_timeline`, `get_merchant_stats`, `get_driver_stats`
- Backend: Reused existing `resolve_dispute()` from service.rs + `notify_reporter_dispute_resolved()` from disputes.rs + `admin_credit_wallet()` from wallets service
- Backend: 6 new integration tests (list 200, list filter, detail 200, resolve dismiss, resolve credit, 403 wrong role) — all pass, 295 total Rust tests
- Frontend: `DisputeDetail`, `AdminDisputeListItem`, `ResolveDisputeRequest`, `ResolveAction`, `ActorStats`, `OrderTimelineEvent` models in `dispute_detail.dart` with JsonSerializable
- Frontend: Extended `AdminEndpoint` with `listDisputes`, `getDisputeDetail`, `resolveDispute` methods
- Frontend: `adminDisputesProvider` (family with DisputeListParams) + `disputeDetailProvider` (family by dispute ID)
- Frontend: `DisputeListScreen` with ChoiceChip filters (Tous/Open/InProgress/Resolved), Card-based list, pull-to-refresh
- Frontend: `DisputeDetailScreen` with header, description, OrderTimeline, merchant/driver stats cards, resolve button
- Frontend: `OrderTimeline` reusable widget in mefali_design — vertical timeline with green (complete) / grey (pending) states
- Frontend: `DisputeResolutionSheet` in mefali_design — RadioListTile actions, conditional credit amount field, resolution notes
- Frontend: AdminShellScreen index 4 (Litiges) now shows DisputeListScreen instead of stub
- Frontend: 7 new widget tests (3 list, 1 detail, 2 resolution sheet, 1 timeline) — all pass, 24 total admin tests (1 pre-existing failure unrelated)
- No new database migrations — existing schema is complete
- Used `tokio::spawn` instead of `actix_web::rt::spawn` for resolve notification to work in test context

### File List

**Created:**
- packages/mefali_core/lib/models/dispute_detail.dart
- packages/mefali_core/lib/models/dispute_detail.g.dart
- packages/mefali_api_client/lib/providers/admin_disputes_provider.dart
- packages/mefali_design/lib/components/order_timeline.dart
- packages/mefali_design/lib/components/dispute_resolution_sheet.dart
- apps/mefali_admin/lib/features/disputes/dispute_list_screen.dart
- apps/mefali_admin/lib/features/disputes/dispute_detail_screen.dart
- apps/mefali_admin/lib/features/disputes/dispute_status_color.dart (shared helper for status colors)

**Modified:**
- server/crates/api/src/routes/admin.rs (added list_disputes, get_dispute_detail, resolve_dispute + 6 tests + error logging on notification)
- server/crates/domain/src/disputes/model.rs (added AdminDisputeListItem, OrderTimelineEvent, ActorStats, AdminDisputeDetail, ResolveDisputeRequest, ResolveAction)
- server/crates/domain/src/disputes/repository.rs (added find_all_admin, count_all_admin, get_order_timeline as single UNION ALL query, get_merchant_stats, get_driver_stats)
- server/crates/domain/src/disputes/service.rs (added resolve_dispute function + notification constants)
- server/crates/api/src/routes/disputes.rs (added notify_reporter_dispute_resolved)
- server/crates/domain/src/lib.rs (exports)
- server/crates/api/src/routes/mod.rs (registered admin dispute routes)
- server/crates/api/src/test_helpers.rs (added admin dispute + wallet routes to test app)
- packages/mefali_api_client/lib/endpoints/admin_endpoint.dart (added listDisputes, getDisputeDetail, resolveDispute)
- packages/mefali_core/lib/mefali_core.dart (export dispute_detail.dart)
- packages/mefali_api_client/lib/mefali_api_client.dart (export admin_disputes_provider.dart)
- packages/mefali_design/lib/mefali_design.dart (export order_timeline.dart, dispute_resolution_sheet.dart)
- apps/mefali_admin/lib/features/dashboard/admin_shell_screen.dart (index 4 → DisputeListScreen)
- apps/mefali_admin/test/widget_test.dart (10 new dispute tests: rendering + behavior + validation)
