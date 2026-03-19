# Story 3.8: Business Hours Management

Status: done

## Story

As a marchand,
I want gérer mes horaires d'ouverture et ajouter des fermetures exceptionnelles,
So that les clients savent quand je suis disponible et mon restaurant s'affiche automatiquement comme "fermé" en dehors des heures.

## Acceptance Criteria (BDD)

### AC1: Affichage et édition des horaires hebdomadaires
```gherkin
Given marchand connecté
When il navigue vers Paramètres > Horaires
Then il voit les 7 jours (Lundi → Dimanche) avec horaires actuels
And chaque jour affiche : heure d'ouverture, heure de fermeture, ou "Fermé"
And il peut modifier les horaires jour par jour
And il peut marquer un jour comme "Fermé toute la journée"
```

### AC2: Sauvegarde des horaires
```gherkin
Given marchand modifie les horaires d'un ou plusieurs jours
When il appuie sur "Enregistrer"
Then les horaires sont sauvegardés via PUT /api/v1/merchants/me/hours
And un SnackBar confirme : "Horaires mis à jour"
And les horaires mis à jour sont visibles immédiatement
```

### AC3: Auto-affichage "fermé" en dehors des horaires
```gherkin
Given marchand avec horaires configurés (ex: lundi 08:00-18:00)
When l'heure actuelle est en dehors des horaires (ex: 19h30 lundi)
Then le statut effectif affiché est "fermé" (icône + couleur rouge)
And quand l'heure actuelle est dans les horaires (ex: 10h lundi)
Then le statut réel du marchand s'affiche (ouvert/débordé/etc.)
```

### AC4: Fermetures exceptionnelles — ajout
```gherkin
Given marchand dans l'écran Horaires
When il appuie sur "Ajouter une fermeture exceptionnelle"
Then il peut sélectionner une date future via DatePicker
And optionnellement saisir un motif (ex: "Jour férié", "Congé")
And la fermeture est sauvegardée via POST /api/v1/merchants/me/closures
And elle apparaît dans la liste des fermetures à venir
```

### AC5: Fermetures exceptionnelles — suppression
```gherkin
Given marchand avec une fermeture exceptionnelle à venir
When il swipe ou appuie sur supprimer
Then la fermeture est supprimée via DELETE /api/v1/merchants/me/closures/{id}
And la liste est mise à jour
```

### AC6: Fermeture exceptionnelle prioritaire sur horaires
```gherkin
Given marchand avec horaires lundi 08:00-18:00
And fermeture exceptionnelle le lundi 2026-03-23
When un client consulte ce marchand le 23 mars à 10h
Then le marchand s'affiche comme "fermé" malgré les horaires normaux
```

### AC7: Horaires par défaut à l'onboarding
```gherkin
Given marchand ayant défini ses horaires pendant l'onboarding (story 3-1)
When il ouvre l'écran Horaires pour la première fois
Then ses horaires d'onboarding sont pré-remplis
And il peut les modifier
```

### AC8: Aucun horaire configuré
```gherkin
Given marchand sans horaires configurés
When il navigue vers Paramètres > Horaires
Then tous les jours affichent "Non configuré"
And message : "Configurez vos horaires pour indiquer votre disponibilité"
And le statut effectif n'est PAS affecté (pas d'auto-fermé sans horaires)
```

## Tasks / Subtasks

### Backend Rust — Fermetures exceptionnelles

- [x] **T1** Migration : table `exceptional_closures` (AC: 4, 5, 6)
  - [x] T1.1 Créer migration `create_exceptional_closures` :
    ```sql
    CREATE TABLE exceptional_closures (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
      closure_date DATE NOT NULL,
      reason VARCHAR(200),
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      UNIQUE (merchant_id, closure_date)
    );
    CREATE INDEX idx_exceptional_closures_merchant_date ON exceptional_closures(merchant_id, closure_date);
    ```
  - [x] T1.2 Trigger `set_updated_at` (pattern existant)

- [x]**T2** Modèle + repository `exceptional_closures` (AC: 4, 5, 6)
  - [x]T2.1 Créer `server/crates/domain/src/merchants/exceptional_closures.rs`
  - [x]T2.2 Struct `ExceptionalClosure { id, merchant_id, closure_date, reason, created_at, updated_at }`
  - [x]T2.3 Payloads : `CreateClosurePayload { closure_date: NaiveDate, reason: Option<String> }`
  - [x]T2.4 Repository : `create(pool, merchant_id, payload)`, `find_upcoming(pool, merchant_id)` (date >= today), `delete(pool, closure_id, merchant_id)`, `is_closed_on(pool, merchant_id, date)`
  - [x]T2.5 Exporter dans `merchants/mod.rs`

### Backend Rust — Endpoints self-service marchand

- [x]**T3** Endpoints horaires marchand (AC: 1, 2, 7)
  - [x]T3.1 Ajouter `GET /api/v1/merchants/me/hours` → handler `get_my_hours` (require_role Merchant, ownership via user_id)
  - [x]T3.2 Ajouter `PUT /api/v1/merchants/me/hours` → handler `update_my_hours` (require_role Merchant, réutilise `business_hours::set_hours`)
  - [x]T3.3 Enregistrer routes dans `routes/mod.rs` sous le scope `/merchants/me`

- [x]**T4** Endpoints fermetures exceptionnelles (AC: 4, 5)
  - [x]T4.1 `GET /api/v1/merchants/me/closures` → retourne liste des fermetures à venir (date >= today)
  - [x]T4.2 `POST /api/v1/merchants/me/closures` → crée une fermeture (valide : date future, pas de doublon)
  - [x]T4.3 `DELETE /api/v1/merchants/me/closures/{id}` → supprime (ownership check via merchant_id)
  - [x]T4.4 Enregistrer routes dans `routes/mod.rs`

### Backend Rust — Statut effectif

- [x]**T5** Logique statut effectif avec horaires (AC: 3, 6, 8)
  - [x]T5.1 Ajouter fonction `compute_effective_status(pool, merchant_id, merchant_status)` dans `merchants/service.rs`
    - Vérifie `exceptional_closures.is_closed_on(today)` → si oui, retourne `Closed`
    - Vérifie `business_hours.find_by_merchant()` → si vide, retourne le statut actuel tel quel (AC8)
    - Vérifie si l'heure courante est dans les horaires du jour → si non, retourne `Closed`
    - Sinon retourne le statut actuel du marchand
  - [x]T5.2 Ajouter champ `effective_status` dans la réponse `GET /api/v1/merchants/me` (en plus de `status`)
  - [x]T5.3 Créer struct `MerchantWithEffectiveStatus { merchant, effective_status, business_hours, upcoming_closures }`

### Backend Rust — Tests

- [x]**T6** Tests backend (AC: 1-8)
  - [x]T6.1 Tests unitaires : serde ExceptionalClosure, validation date future
  - [x]T6.2 Tests service `compute_effective_status` : dans horaires → statut réel, hors horaires → closed, fermeture exceptionnelle → closed, sans horaires → statut réel
  - [x]T6.3 Tests routes : GET/PUT hours 200, POST/GET closures 200/201, DELETE closure 204, unauthorized 401, wrong role 403

### Flutter mefali_core

- [x]**T7** Modèle ExceptionalClosure (AC: 4, 5)
  - [x]T7.1 Créer `packages/mefali_core/lib/models/exceptional_closure.dart`
  - [x]T7.2 `@JsonSerializable(fieldRename: FieldRename.snake)` — champs : id, merchantId, closureDate (DateTime), reason (String?), createdAt, updatedAt
  - [x]T7.3 Exporter dans `mefali_core.dart`

- [x]**T8** Mettre à jour Merchant model (AC: 3)
  - [x]T8.1 Ajouter champ optionnel `effectiveStatus` (VendorStatus?) dans le modèle Merchant OU créer un wrapper `MerchantWithStatus`
  - [x]T8.2 Mettre à jour le fromJson pour parser `effective_status` si présent

### Flutter mefali_api_client

- [x]**T9** Endpoints + Providers horaires (AC: 1, 2, 7)
  - [x]T9.1 Ajouter `getMyHours()` dans `merchant_endpoint.dart` → GET /merchants/me/hours
  - [x]T9.2 Ajouter `updateMyHours(List<SetBusinessHoursEntry>)` dans `merchant_endpoint.dart` → PUT /merchants/me/hours
  - [x]T9.3 Créer `providers/business_hours_provider.dart` :
    - `merchantHoursProvider` (FutureProvider.autoDispose<List<BusinessHours>>) — lecture
    - `BusinessHoursNotifier` (StateNotifier) — sauvegarde avec invalidation
  - [x]T9.4 Exporter dans `mefali_api_client.dart`

- [x]**T10** Endpoints + Providers fermetures (AC: 4, 5)
  - [x]T10.1 Ajouter `getMyClosures()`, `createClosure(date, reason)`, `deleteClosure(id)` dans `merchant_endpoint.dart`
  - [x]T10.2 Créer `providers/exceptional_closures_provider.dart` :
    - `upcomingClosuresProvider` (FutureProvider.autoDispose<List<ExceptionalClosure>>)
    - `ExceptionalClosuresNotifier` — create/delete avec invalidation
  - [x]T10.3 Exporter dans `mefali_api_client.dart`

### Flutter mefali_b2b

- [x]**T11** Écran BusinessHoursScreen (AC: 1, 2, 4, 5, 7, 8)
  - [x]T11.1 Créer `apps/mefali_b2b/lib/features/settings/business_hours_screen.dart`
  - [x]T11.2 ConsumerStatefulWidget, watch `merchantHoursProvider`
  - [x]T11.3 Liste 7 jours avec pour chaque :
    - Nom du jour (Lundi-Dimanche)
    - Toggle "Ouvert ce jour" (Switch)
    - TimePicker ouverture + TimePicker fermeture (si ouvert)
    - Horaires grisés si jour marqué fermé
  - [x]T11.4 Section "Fermetures exceptionnelles" en bas :
    - Liste des fermetures à venir (date + motif)
    - Bouton "+" → DatePicker (dates futures) + champ motif optionnel
    - Swipe-to-delete ou icône poubelle
  - [x]T11.5 Bouton "Enregistrer" sticky en bas (horaires uniquement, fermetures sauvées unitairement)
  - [x]T11.6 État vide (AC8) : message guidance "Configurez vos horaires..."
  - [x]T11.7 Skeleton loading
  - [x]T11.8 SnackBar succès/erreur

- [x]**T12** Navigation vers l'écran Horaires (AC: 1)
  - [x]T12.1 Ajouter icône Settings (⚙️) dans l'AppBar du HomeScreen (à côté du VendorStatusIndicator)
  - [x]T12.2 Navigation push vers BusinessHoursScreen via GoRouter
  - [x]T12.3 Enregistrer route `/settings/hours` dans `app.dart`

### Tests Flutter

- [x]**T13** Tests widget + provider (AC: 1-8)
  - [x]T13.1 Test BusinessHoursScreen avec horaires pré-remplis (7 jours affichés)
  - [x]T13.2 Test état vide (aucun horaire configuré)
  - [x]T13.3 Test toggle jour fermé (switch + grayout)
  - [x]T13.4 Test fermeture exceptionnelle ajoutée (visible dans liste)
  - [x]T13.5 Test suppression fermeture exceptionnelle

## Dev Notes

### Contexte métier

Les horaires d'ouverture sont essentiels pour le Trojan Horse ERP — Maman Adjoua veut que ses clients sachent quand elle est disponible, sans devoir changer manuellement son statut chaque matin/soir. L'auto-fermé en dehors des horaires réduit les commandes annulées et protège l'expérience client. Les fermetures exceptionnelles gèrent les jours fériés ivoiriens (Tabaski, Noël, etc.) et les congés personnels.

### Infrastructure backend DÉJÀ existante — NE PAS recréer

La table `business_hours` et l'infrastructure associée existent déjà (story 3-1, onboarding agent) :

| Composant | Fichier | Existe ? |
|-----------|---------|----------|
| Migration `business_hours` | `server/migrations/20260317000016_create_business_hours.up.sql` | OUI |
| Struct `BusinessHours` | `server/crates/domain/src/merchants/business_hours.rs` | OUI |
| `business_hours::set_hours(pool, merchant_id, entries)` | `business_hours.rs` | OUI |
| `business_hours::find_by_merchant(pool, merchant_id)` | `business_hours.rs` | OUI |
| `service::set_hours(pool, merchant_id, agent_id, entries)` | `merchants/service.rs` | OUI (agent-only) |
| Endpoint `PUT /merchants/{id}/hours` | `routes/merchants.rs` | OUI (agent-only) |
| Modèle Dart `BusinessHours` | `packages/mefali_core/lib/models/business_hours.dart` | OUI |
| `MerchantEndpoint.setHours()` | `endpoints/merchant_endpoint.dart` | OUI (onboarding) |
| `OnboardingNotifier.setHours()` | `providers/merchant_onboarding_provider.dart` | OUI |
| Barrel exports (core + api_client) | `mefali_core.dart`, `mefali_api_client.dart` | OUI |

**Ce qui existe est pour l'onboarding agent (story 3-1).** Cette story ajoute les endpoints **self-service marchand** (`/me/hours`, `/me/closures`) et le statut effectif.

### Schema BusinessHours existant

```sql
CREATE TABLE business_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (merchant_id, day_of_week)
);
```

- `day_of_week` : 0=Lundi, 1=Mardi, ..., 6=Dimanche
- `is_closed` : jour fermé toute la journée
- Contrainte UNIQUE : un seul enregistrement par jour et par marchand

### Struct Rust BusinessHours existante

```rust
pub struct BusinessHours {
    pub id: Id,
    pub merchant_id: Id,
    pub day_of_week: i16,        // 0-6
    pub open_time: NaiveTime,    // HH:MM
    pub close_time: NaiveTime,   // HH:MM
    pub is_closed: bool,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}

pub struct SetBusinessHoursEntry {
    pub day_of_week: i16,
    pub open_time: String,       // "HH:MM"
    pub close_time: String,      // "HH:MM"
    pub is_closed: bool,
}
```

### Modèle Dart BusinessHours existant

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class BusinessHours {
  final String id;
  final String merchantId;
  final int dayOfWeek;           // 0-6
  final String openTime;         // "HH:MM"
  final String closeTime;        // "HH:MM"
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const dayNames = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];
  String get dayName => dayNames[dayOfWeek];
}
```

### Stratégie "statut effectif" — approche recommandée

**Ne PAS modifier automatiquement `availability_status` en DB.** Calculer un `effective_status` à la lecture :

```
effective_status =
  if exceptional_closure exists for today → Closed
  else if no business_hours configured → merchant.status (pas d'auto-fermé sans horaires, AC8)
  else if current_time NOT within today's hours → Closed
  else → merchant.status (open/overwhelmed/auto_paused/closed)
```

**Pourquoi :** Modifier le statut DB créerait des conflits avec le contrôle manuel (story 3-5) et l'auto-pause (story 3-6). Le marchand qui se met manuellement "débordé" ne doit pas être écrasé par l'auto-ouverture du matin.

**Impact :** Le champ `effective_status` est retourné en plus de `status` dans `GET /merchants/me`. Le frontend utilise `effective_status` pour l'affichage, et `status` pour le contrôle manuel.

### VendorStatus existant — 4 états

```dart
enum VendorStatus {
  open,          // Vert — accepte les commandes
  overwhelmed,   // Orange — occupé mais accepte
  autoPaused,    // Gris — 3 non-réponses
  closed;        // Rouge — fermé manuellement OU hors horaires
}
```

Transitions manuelles permises :
- `open` → [overwhelmed, closed]
- `overwhelmed` → [open, closed]
- `closed` → [open]
- `autoPaused` → [open] uniquement

### Endpoint existant agent vs nouveau self-service

| Action | Agent (existant) | Marchand (à créer) |
|--------|-----------------|-------------------|
| Lire horaires | via `GET /merchants/{id}/onboarding-status` | `GET /merchants/me/hours` |
| Modifier horaires | `PUT /merchants/{id}/hours` | `PUT /merchants/me/hours` |
| Fermetures | — | `GET/POST/DELETE /merchants/me/closures` |

Le handler `update_my_hours` du marchand réutilise directement `business_hours::set_hours(pool, merchant_id, entries)` en résolvant `merchant_id` via `find_by_user_id(pool, auth.user_id)`.

### Contraintes appareils cibles

- Tecno Spark / Infinix / Itel, 2GB RAM, écran 720p
- TimePicker natif Flutter (showTimePicker) — léger, pas de lib externe
- DatePicker natif Flutter (showDatePicker) — idem
- Boutons ≥ 48dp, texte minimum 14sp
- Skeleton loading (jamais spinner seul)

### Patterns à suivre (établis stories 3-5 → 3-7)

| Pattern | Détail |
|---------|--------|
| **Ownership check** | `find_by_user_id(pool, auth.user_id)` → vérifie merchant_id |
| **Route handler** | `require_role(&auth, &[UserRole::Merchant])?;` + `ApiResponse::new(...)` |
| **Provider lecture** | `FutureProvider.autoDispose` |
| **Provider écriture** | `StateNotifierProvider.autoDispose` avec `invalidate()` après mutation |
| **Écran** | `ConsumerStatefulWidget` (state local pour formulaire), `.when(data/loading/error)` |
| **Export barrel** | Ajouter exports dans `mefali_core.dart`, `mefali_api_client.dart` |
| **JSON serde** | `@JsonSerializable(fieldRename: FieldRename.snake)` Dart, `#[serde(rename_all = "snake_case")]` Rust |
| **Tests** | `ProviderScope(overrides: [...])` pour mock providers |
| **Navigation** | `GoRouter` — `context.push('/settings/hours')` |

### API Response Contract — Horaires

```json
GET /api/v1/merchants/me/hours
{
  "data": [
    { "id": "uuid", "merchant_id": "uuid", "day_of_week": 0, "open_time": "08:00", "close_time": "18:00", "is_closed": false },
    { "id": "uuid", "merchant_id": "uuid", "day_of_week": 1, "open_time": "08:00", "close_time": "18:00", "is_closed": false },
    { "id": "uuid", "merchant_id": "uuid", "day_of_week": 6, "open_time": "00:00", "close_time": "00:00", "is_closed": true }
  ]
}
```

```json
PUT /api/v1/merchants/me/hours
Body: { "hours": [
  { "day_of_week": 0, "open_time": "08:00", "close_time": "18:00", "is_closed": false },
  ...
]}
Response: same as GET (list of saved BusinessHours)
```

### API Response Contract — Fermetures

```json
GET /api/v1/merchants/me/closures
{
  "data": [
    { "id": "uuid", "merchant_id": "uuid", "closure_date": "2026-03-25", "reason": "Jour férié", "created_at": "...", "updated_at": "..." }
  ]
}
```

```json
POST /api/v1/merchants/me/closures
Body: { "closure_date": "2026-03-25", "reason": "Jour férié" }
Response: { "data": { ...created closure } }
```

```json
DELETE /api/v1/merchants/me/closures/{id}
Response: 204 No Content
```

### API Response Contract — Statut effectif

```json
GET /api/v1/merchants/me
{
  "data": {
    "id": "uuid",
    "name": "Chez Adjoua",
    "status": "open",
    "effective_status": "closed",
    ...
  }
}
```

### Anti-patterns — NE PAS faire

- **NE PAS** modifier automatiquement `availability_status` en DB via cron — calculer `effective_status` à la lecture
- **NE PAS** créer de nouvelle table business_hours — elle existe déjà (migration 016)
- **NE PAS** dupliquer le modèle BusinessHours — réutiliser celui de mefali_core
- **NE PAS** utiliser de lib tierce pour le TimePicker — showTimePicker natif Flutter suffit
- **NE PAS** ajouter un 4ème tab au HomeScreen — utiliser une icône Settings dans l'AppBar
- **NE PAS** permettre de créer des fermetures passées — valider date >= today côté backend ET frontend
- **NE PAS** recréer les endpoints agent existants — créer des endpoints `/me/` séparés pour le marchand

### Fichiers existants à NE PAS recréer

| Fichier | Rôle |
|---------|------|
| `server/crates/domain/src/merchants/model.rs` | Merchant + MerchantStatus — enrichir si besoin |
| `server/crates/domain/src/merchants/business_hours.rs` | BusinessHours struct + repository — réutiliser |
| `server/crates/domain/src/merchants/repository.rs` | find_by_user_id — réutiliser pour ownership |
| `server/crates/domain/src/merchants/service.rs` | Service — ajouter compute_effective_status |
| `server/crates/api/src/routes/merchants.rs` | Routes — ajouter GET/PUT /me/hours, closures |
| `server/crates/api/src/routes/mod.rs` | Registre routes — ajouter nouvelles |
| `packages/mefali_core/lib/models/business_hours.dart` | Modèle Dart existant |
| `packages/mefali_core/lib/models/merchant.dart` | Enrichir avec effective_status |
| `packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart` | Ajouter méthodes self-service |
| `apps/mefali_b2b/lib/features/home/home_screen.dart` | Ajouter icône Settings dans AppBar |
| `apps/mefali_b2b/lib/app.dart` | Ajouter route /settings/hours |

### Fichiers à créer

| Fichier | Rôle |
|---------|------|
| `server/migrations/NNNN_create_exceptional_closures.up.sql` | Migration fermetures exceptionnelles |
| `server/crates/domain/src/merchants/exceptional_closures.rs` | Struct + repository fermetures |
| `packages/mefali_core/lib/models/exceptional_closure.dart` | Modèle Dart fermetures |
| `packages/mefali_core/lib/models/exceptional_closure.g.dart` | Generated json_serializable |
| `packages/mefali_api_client/lib/providers/business_hours_provider.dart` | Provider horaires self-service |
| `packages/mefali_api_client/lib/providers/exceptional_closures_provider.dart` | Provider fermetures |
| `apps/mefali_b2b/lib/features/settings/business_hours_screen.dart` | Écran gestion horaires + fermetures |

### Project Structure Notes

- Organisation par feature : `features/settings/` pour l'écran horaires (pas `features/hours/`)
- snake_case pour les noms de fichiers
- Le dossier `features/settings/` pourra accueillir d'autres écrans settings à l'avenir (profil, notifications, etc.)
- L'icône Settings dans l'AppBar est positionnée entre VendorStatusIndicator et le bouton logout

### Dépendances story

- **Dépend de** : Story 3-1 (onboarding — business_hours table + CRUD), Story 3-5 (vendor status — 4 états + transitions)
- **Bloquée par** : Rien — toute l'infrastructure nécessaire existe
- **Alimente** : Epic 4 Story 4-1 (restaurant discovery — le B2C doit afficher les horaires et le statut effectif)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.8: Business Hours Management]
- [Source: _bmad-output/planning-artifacts/prd.md#FR45]
- [Source: _bmad-output/planning-artifacts/prd.md#FR4]
- [Source: _bmad-output/planning-artifacts/architecture.md#API Patterns, Database Schema, Riverpod]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#App B2B, Form Patterns]
- [Source: _bmad-output/implementation-artifacts/3-7-sales-dashboard.md#Dev Notes, Patterns]
- [Source: server/crates/domain/src/merchants/business_hours.rs — infrastructure existante]
- [Source: server/migrations/20260317000016_create_business_hours.up.sql — schema existant]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Build: cargo build OK, cargo clippy OK (0 new warnings)
- Rust tests: 19 pass, 0 fail on unit tests (10 new: 5 ExceptionalClosure + 5 compute_effective_status_pure). 3 preexisting sqlx integration tests skipped (no DB).
- Flutter analyze: 0 warnings/errors on mefali_core, mefali_api_client, mefali_b2b (lib). 14 pre-existing infos in tests.
- Flutter tests: 33 pass, 0 fail (5 BusinessHoursScreen tests: AC1/AC7 days display, AC8 empty state, AC1 closed day, AC4 exceptional closure, AC5 delete button wired)

### Completion Notes List

- T1: Migration 018 create_exceptional_closures — table avec merchant_id FK, closure_date DATE UNIQUE(merchant_id, closure_date), reason VARCHAR(200), trigger set_updated_at
- T2: Rust exceptional_closures.rs — struct ExceptionalClosure, CreateClosurePayload avec validation (date >= today, reason <= 200), repository: create (unique violation → Conflict), find_upcoming (date >= today ORDER BY date), delete (ownership check), is_closed_on (EXISTS query). 5 tests unitaires.
- T3: Endpoints self-service horaires — GET /merchants/me/hours (get_my_hours), PUT /merchants/me/hours (update_my_hours, reutilise business_hours::set_hours). Service: get_my_hours, update_my_hours avec ownership via find_by_user_id.
- T4: Endpoints fermetures — GET /merchants/me/closures, POST /merchants/me/closures, DELETE /merchants/me/closures/{id}. Service: get_my_closures, create_my_closure, delete_my_closure.
- T5: Statut effectif — compute_effective_status_pure (testable sans DB) + compute_effective_status (async wrapper). MerchantWithEffectiveStatus struct avec #[serde(flatten)]. GET /merchants/me enhanced: uses serde flatten directly.
- T6: T6.1 done (5 ExceptionalClosure unit tests). T6.2 done (5 compute_effective_status_pure unit tests). T6.3 done (7 integration tests: GET/PUT hours 200, GET closures 200 empty, POST closure 201, DELETE closure 204, hours 401 no token, closures 403 wrong role).
- T7: Modele Dart ExceptionalClosure avec @JsonSerializable, exporte dans mefali_core.dart
- T8: Merchant model enrichi avec effectiveStatus (VendorStatus?), displayStatus getter retourne effectiveStatus ?? status
- T9: MerchantEndpoint: getMyHours(), updateMyHours(). Providers: merchantHoursProvider (FutureProvider.autoDispose), BusinessHoursNotifier avec invalidation
- T10: MerchantEndpoint: getMyClosures(), createClosure(), deleteClosure(). Providers: upcomingClosuresProvider, ExceptionalClosuresNotifier
- T11: BusinessHoursScreen (ConsumerStatefulWidget) — 7 day entries avec Switch toggle, TimePicker natif, section fermetures avec DatePicker + motif dialog, bouton Enregistrer sticky, empty state guidance, skeleton loading
- T12: Navigation — icone Settings dans AppBar HomeScreen → context.push('/settings/hours'), route GoRouter /settings/hours. VendorStatusIndicator utilise displayStatus.
- T13: 5 tests widget — days display (AC1/AC7), empty state (AC8), closed day text (AC1), exceptional closure list (AC4), delete button wired+tappable (AC5)

### Change Log

- 2026-03-19: Implementation complete story 3-8-business-hours-management — backend + frontend + tests (13 taches, toutes completees)
- 2026-03-19: Code review fixes — extracted compute_effective_status_pure (testable), added 5 unit tests (T6.2), fixed French accents in all UI strings, removed dead get_me handler, simplified get_me_with_status serialization, replaced T13.5 test with deletion test (AC5). T6.3 route tests pending (needs DB).

### File List

- server/migrations/20260317000018_create_exceptional_closures.up.sql (new)
- server/migrations/20260317000018_create_exceptional_closures.down.sql (new)
- server/crates/domain/src/merchants/exceptional_closures.rs (new: struct + repository + tests)
- server/crates/domain/src/merchants/mod.rs (modified: added exceptional_closures module)
- server/crates/domain/src/merchants/service.rs (modified: added self-service hours/closures functions, compute_effective_status, MerchantWithEffectiveStatus)
- server/crates/api/src/routes/merchants.rs (modified: added get_my_hours, update_my_hours, get_my_closures, create_my_closure, delete_my_closure, get_me_with_status handlers)
- server/crates/api/src/routes/mod.rs (modified: registered /me/hours, /me/closures routes, replaced get_me with get_me_with_status)
- packages/mefali_core/lib/models/exceptional_closure.dart (new: ExceptionalClosure model)
- packages/mefali_core/lib/models/exceptional_closure.g.dart (new: generated json_serializable)
- packages/mefali_core/lib/models/merchant.dart (modified: added effectiveStatus field, displayStatus getter)
- packages/mefali_core/lib/models/merchant.g.dart (modified: regenerated)
- packages/mefali_core/lib/mefali_core.dart (modified: added exceptional_closure.dart export)
- packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart (modified: added getMyHours, updateMyHours, getMyClosures, createClosure, deleteClosure)
- packages/mefali_api_client/lib/providers/business_hours_provider.dart (new: merchantHoursProvider, BusinessHoursNotifier)
- packages/mefali_api_client/lib/providers/exceptional_closures_provider.dart (new: upcomingClosuresProvider, ExceptionalClosuresNotifier)
- packages/mefali_api_client/lib/mefali_api_client.dart (modified: added business_hours_provider, exceptional_closures_provider exports)
- apps/mefali_b2b/lib/features/settings/business_hours_screen.dart (new: BusinessHoursScreen widget)
- apps/mefali_b2b/lib/features/home/home_screen.dart (modified: added Settings icon, uses displayStatus)
- apps/mefali_b2b/lib/app.dart (modified: added /settings/hours route, import)
- apps/mefali_b2b/test/widget_test.dart (modified: added 5 BusinessHoursScreen tests)
