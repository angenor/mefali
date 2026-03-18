# Story 3.5: Disponibilite marchand 4 etats (Vendor Availability)

Status: in-progress

## Story

As a marchand,
I want to definir et changer mon etat de disponibilite (ouvert / deborde / auto-pause / ferme),
so that les clients voient mon etat reel et que le systeme me protege si je ne reponds pas aux commandes.

## Acceptance Criteria (AC)

1. **AC1 — Changement manuel de statut (FR10)** : Le marchand peut basculer entre `open`, `overwhelmed` et `closed` via le VendorStatusIndicator dans l'AppBar B2B. Le changement est persiste cote serveur via `PUT /api/v1/merchants/me/status`. Le nouveau statut est visible immediatement dans l'UI.

2. **AC2 — Reactivation depuis auto-pause (FR10, FR17)** : Un marchand en etat `auto_paused` voit un indicateur gris "Auto-pause". En 1 tap il revient a `open`. Le compteur `consecutive_no_response` est remis a 0. Les etats `overwhelmed` et `closed` ne sont pas directement accessibles depuis `auto_paused` — il faut d'abord reactiver.

3. **AC3 — Mecanisme auto-pause (FR17)** : Une fonction service `check_auto_pause()` verifie si `consecutive_no_response >= 3` et bascule automatiquement le statut a `auto_paused`. Cette fonction sera appelee par story 3.6 (Order Reception) quand une commande n'est pas repondue. Le compteur est incremente via `increment_no_response()`.

4. **AC4 — VendorStatusIndicator widget (UX-DR7)** : Un composant partage dans `mefali_design` affiche une pastille coloree avec texte : vert "Ouvert", orange "Deborde", gris "Auto-pause", rouge "Ferme". En mode interactif (B2B) le tap ouvre un bottom sheet de selection. En mode read-only (B2C) il affiche simplement l'etat.

5. **AC5 — Endpoint GET marchand courant** : `GET /api/v1/merchants/me` retourne les donnees du marchand connecte (dont `status` et `consecutive_no_response`). Cet endpoint est necessaire pour que l'app B2B affiche l'etat courant.

6. **AC6 — Transitions valides uniquement** : Le backend valide les transitions de statut :
   - `open` → `overwhelmed`, `closed`
   - `overwhelmed` → `open`, `closed`
   - `closed` → `open`
   - `auto_paused` → `open` (seule transition permise, reset counter)
   - Toute autre transition retourne 400 Bad Request.

## Tasks / Subtasks

### Backend Rust

- [ ] **T1** — Domain : logique changement statut (AC: #1, #2, #3, #6)
  - [ ] T1.1 — `model.rs` : `UpdateStatusPayload { status: MerchantStatus }` + `validate()` + `MerchantStatus::valid_transitions()` retournant les transitions autorisees depuis chaque etat
  - [ ] T1.2 — `repository.rs` : `update_status(pool, merchant_id, new_status) -> Merchant` — `UPDATE merchants SET availability_status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`
  - [ ] T1.3 — `repository.rs` : `increment_no_response(pool, merchant_id) -> Merchant` — `UPDATE merchants SET consecutive_no_response = consecutive_no_response + 1, updated_at = NOW() WHERE id = $1 RETURNING *`
  - [ ] T1.4 — `repository.rs` : `reset_no_response(pool, merchant_id) -> Merchant` — `UPDATE merchants SET consecutive_no_response = 0, updated_at = NOW() WHERE id = $1 RETURNING *`
  - [ ] T1.5 — `service.rs` : `change_status(pool, user_id, new_status)` — resolve merchant, valide transition, execute update. Si `auto_paused → open` : reset counter en plus.
  - [ ] T1.6 — `service.rs` : `check_auto_pause(pool, merchant_id)` — charge merchant, si `consecutive_no_response >= 3` ET statut != `auto_paused` → bascule a `auto_paused`. Retourne bool (true si auto-pause declenche).
  - [ ] T1.7 — `service.rs` : `get_current_merchant(pool, user_id)` — resolve merchant par user_id, retourne Merchant ou NotFound.

- [ ] **T2** — Routes API (AC: #1, #2, #5)
  - [ ] T2.1 — `PUT /api/v1/merchants/me/status` — JSON body `{ "status": "open" }`, require_role Merchant. Appelle `service::change_status()`.
  - [ ] T2.2 — `GET /api/v1/merchants/me` — require_role Merchant. Appelle `service::get_current_merchant()`.
  - [ ] T2.3 — Routes enregistrees dans `mod.rs` sous le scope `/merchants`

- [ ] **T3** — Tests backend (AC: tous)
  - [ ] T3.1 — Tests unitaires transitions : `valid_transitions()` pour chaque etat, payload validation
  - [ ] T3.2 — Tests unitaires service : transition valide/invalide, auto_paused → open reset counter
  - [ ] T3.3 — Tests serde : `UpdateStatusPayload` deserialise correctement les 4 valeurs snake_case

### Flutter Shared

- [ ] **T4** — Enum VendorStatus dans mefali_core (AC: #4)
  - [ ] T4.1 — `packages/mefali_core/lib/enums/vendor_status.dart` : enum `VendorStatus { open, overwhelmed, autoPaused, closed }` avec `@JsonEnum(fieldRename: FieldRename.snake)` + helpers (`label`, `color`, `icon`)
  - [ ] T4.2 — Modifier `Merchant` model : changer `final String status` en `final VendorStatus status`
  - [ ] T4.3 — Exporter depuis barrel file `mefali_core.dart`
  - [ ] T4.4 — Regenerer `merchant.g.dart` via `dart run build_runner build`

- [ ] **T5** — VendorStatusIndicator widget dans mefali_design (AC: #4)
  - [ ] T5.1 — `packages/mefali_design/lib/components/vendor_status_indicator.dart` : widget avec 2 modes (`interactive: true/false`). Affiche pastille coloree + texte. Mode interactif : `onTap` callback.
  - [ ] T5.2 — Bottom sheet de selection statut : 3 options (Ouvert / Deborde / Ferme) si etat != auto_paused, sinon bouton unique "Reactiver" pour revenir a open.

- [ ] **T6** — API Client (AC: #1, #2, #5)
  - [ ] T6.1 — `MerchantEndpoint` : ajouter `updateStatus(VendorStatus status)` → PUT, `getCurrentMerchant()` → GET
  - [ ] T6.2 — Provider : `currentMerchantProvider` (FutureProvider.autoDispose) qui appelle `getCurrentMerchant()`
  - [ ] T6.3 — Provider : `VendorStatusNotifier` (StateNotifier) avec methode `changeStatus(VendorStatus)` qui appelle endpoint + invalide `currentMerchantProvider`

### Flutter B2B

- [ ] **T7** — Integration VendorStatusIndicator dans B2B Home (AC: #1, #2, #4)
  - [ ] T7.1 — `B2bHomeScreen` AppBar : ajouter VendorStatusIndicator interactif a droite du titre (avant le bouton logout). Watcher `currentMerchantProvider` pour l'etat courant.
  - [ ] T7.2 — Tap → bottom sheet selection statut. Appel `vendorStatusProvider.changeStatus()`. SnackBar succes vert / erreur rouge.
  - [ ] T7.3 — Si auto_paused : afficher bandeau orange en haut du body "Vous etes en pause automatique — 3 commandes sans reponse" + bouton "Reactiver".

- [ ] **T8** — Tests Flutter (AC: #1, #2, #4)
  - [ ] T8.1 — Widget test VendorStatusIndicator : 4 couleurs, 4 textes, mode interactif vs read-only
  - [ ] T8.2 — Widget test bottom sheet : 3 options visibles, tap change statut
  - [ ] T8.3 — Widget test bandeau auto-pause : visible quand auto_paused, cache sinon

## Dev Notes

### Contexte metier

Les plateformes existantes (Glovo, Jumia) n'ont qu'un binaire ouvert/ferme. mefali ajoute 2 etats intermediaires : "deborde" (le marchand accepte mais previent du delai → badge orange "~30 min" cote B2C) et "auto-pause" (protection systeme apres 3 non-reponses). L'objectif : **< 5% annulation vendeur**. L'emotion cible pour Adjoua est "Autonomie" — elle controle son statut en 1 tap sans demander de permission.

### Ce qui EXISTE deja (NE PAS recreer)

**Base de donnees :**
- Enum PostgreSQL `vendor_status` avec 4 valeurs : `open`, `overwhelmed`, `auto_paused`, `closed` (migration `20260317000001_create_enums.up.sql`)
- Colonne `merchants.availability_status vendor_status NOT NULL DEFAULT 'closed'` (migration `20260317000004_create_merchants.up.sql`)
- Colonne `merchants.consecutive_no_response INT NOT NULL DEFAULT 0`
- Index `idx_merchants_availability_status`

**Rust :**
- `MerchantStatus` enum dans `server/crates/domain/src/merchants/model.rs:23-32` avec serde snake_case + sqlx Type. Tests Display et Serde existants.
- `Merchant` struct avec `#[sqlx(rename = "availability_status")] pub status: MerchantStatus` et `pub consecutive_no_response: i32`
- Toutes les queries repository SELECT/INSERT/UPDATE incluent deja `availability_status` et `consecutive_no_response`

**Dart :**
- `Merchant` model dans `packages/mefali_core/lib/models/merchant.dart` avec `final String status` (String, pas enum — a changer en T4.2)
- `merchant.g.dart` genere par json_serializable
- Pattern enum deja etabli : `packages/mefali_core/lib/enums/user_status.dart` utilise `@JsonEnum(fieldRename: FieldRename.snake)` + `@JsonValue('snake_value')` pour les valeurs multi-mots

**Design system :**
- Couleur orange warning `#FF9800` deja definie dans `mefali_colors.dart` (pour etat "overwhelmed")
- Couleur success `#4CAF50` (pour "open")
- Couleur error `#F44336` (pour "closed")
- Pas de composant `components/` existant — ce sera le premier fichier dans ce dossier

**B2B Home :**
- `B2bHomeScreen` dans `apps/mefali_b2b/lib/features/home/home_screen.dart` avec TabBar 3 onglets (Commandes | Catalogue | Stats). AppBar actuelle : titre "mefali Marchand" + bouton logout. L'indicateur de statut sera ajoute dans `actions:[]` avant le bouton logout.

### Fichiers a ETENDRE (pas de nouveau fichier sauf enum + widget + provider)

| Fichier | Modification |
|---------|-------------|
| `server/crates/domain/src/merchants/model.rs` | Ajouter `UpdateStatusPayload`, `MerchantStatus::valid_transitions()` |
| `server/crates/domain/src/merchants/repository.rs` | Ajouter `update_status()`, `increment_no_response()`, `reset_no_response()` |
| `server/crates/domain/src/merchants/service.rs` | Ajouter `change_status()`, `check_auto_pause()`, `get_current_merchant()` |
| `server/crates/api/src/routes/merchants.rs` | Ajouter handlers `update_status()`, `get_me()` |
| `server/crates/api/src/routes/mod.rs` | Ajouter routes `/merchants/me` et `/merchants/me/status` |
| `packages/mefali_core/lib/models/merchant.dart` | Changer `String status` → `VendorStatus status` |
| `packages/mefali_core/lib/mefali_core.dart` | Ajouter export `vendor_status.dart` |
| `packages/mefali_api_client/lib/endpoints/merchant_endpoint.dart` | Ajouter `updateStatus()`, `getCurrentMerchant()` |
| `packages/mefali_api_client/lib/providers/merchant_onboarding_provider.dart` | Ajouter `currentMerchantProvider`, `VendorStatusNotifier` (ou nouveau fichier provider) |
| `apps/mefali_b2b/lib/features/home/home_screen.dart` | Integrer VendorStatusIndicator + bandeau auto-pause |

### Nouveaux fichiers

| Fichier | Contenu |
|---------|---------|
| `packages/mefali_core/lib/enums/vendor_status.dart` | Enum `VendorStatus` avec `@JsonEnum` |
| `packages/mefali_design/lib/components/vendor_status_indicator.dart` | Widget VendorStatusIndicator |
| `packages/mefali_api_client/lib/providers/vendor_status_provider.dart` | Providers pour statut marchand (OU ajouter dans merchant_onboarding_provider.dart) |

### Patterns a suivre (etablis par stories 3.3 et 3.4)

**Rust :**
- Ownership check : `find_by_user_id(pool, auth.user_id)` pour `/merchants/me/*` (le marchand accede a SES propres donnees, pas besoin de verify_agent_ownership)
- Auth : `require_role(&auth, &[UserRole::Merchant])?` pour les endpoints marchand
- Reponse : `ApiResponse::new(json!({ "merchant": merchant }))` wrappee dans `{"data": {...}}`
- Erreur transition invalide : `AppError::BadRequest("Transition de statut invalide: {current} → {new}")`
- SQL : `RETURNING *` sur les mutations, `updated_at = NOW()`

**Flutter :**
- Provider lecture : `FutureProvider.autoDispose` pour `currentMerchantProvider`
- Provider mutations : `StateNotifier<AsyncValue<void>>` pour `VendorStatusNotifier`
- Invalidation apres mutation : `ref.invalidate(currentMerchantProvider)`
- SnackBar succes : vert, 3s, texte francais ("Statut mis a jour")
- SnackBar erreur : rouge, persistent
- Enums : suivre le pattern de `user_status.dart` — `@JsonEnum(fieldRename: FieldRename.snake)` + `@JsonValue('auto_paused')` pour `autoPaused`
- Touch targets : >= 48dp pour l'indicateur dans l'AppBar

### Couleurs VendorStatusIndicator (UX-DR7)

| Etat | Valeur DB | Light | Dark | Texte FR | Icone |
|------|-----------|-------|------|----------|-------|
| Ouvert | `open` | `#4CAF50` (success) | `#81C784` | "Ouvert" | `Icons.check_circle` |
| Deborde | `overwhelmed` | `#FF9800` (warning) | `#FFB74D` | "Deborde" | `Icons.schedule` |
| Auto-pause | `auto_paused` | `#9E9E9E` (grey) | `#BDBDBD` | "Auto-pause" | `Icons.pause_circle` |
| Ferme | `closed` | `#F44336` (error) | `#EF9A9A` | "Ferme" | `Icons.cancel` |

### Logique transitions statut

```
Transitions manuelles (par le marchand) :
  open → overwhelmed ✓
  open → closed ✓
  overwhelmed → open ✓
  overwhelmed → closed ✓
  closed → open ✓
  auto_paused → open ✓ (reset consecutive_no_response = 0)

Transitions systeme (story 3.6) :
  * → auto_paused (quand consecutive_no_response >= 3)

Transitions interdites :
  closed → overwhelmed ✗ (doit d'abord ouvrir)
  closed → auto_paused ✗ (pas de sens)
  auto_paused → overwhelmed ✗ (doit reactiver d'abord)
  auto_paused → closed ✗ (doit reactiver d'abord)
  open → auto_paused ✗ (systeme uniquement)
  overwhelmed → auto_paused ✗ (systeme uniquement)
```

Implementer `valid_transitions()` sur `MerchantStatus` :
```rust
impl MerchantStatus {
    pub fn valid_manual_transitions(&self) -> Vec<MerchantStatus> {
        match self {
            Self::Open => vec![Self::Overwhelmed, Self::Closed],
            Self::Overwhelmed => vec![Self::Open, Self::Closed],
            Self::Closed => vec![Self::Open],
            Self::AutoPaused => vec![Self::Open],
        }
    }
    pub fn can_transition_to(&self, target: &MerchantStatus) -> bool {
        self.valid_manual_transitions().contains(target)
    }
}
```

### Route placement dans mod.rs

Les routes `/merchants/me` et `/merchants/me/status` doivent etre enregistrees AVANT les routes parametriques `/{id}/*` pour eviter que `me` soit capture comme un UUID. Placer dans le scope `/merchants` :

```rust
.route("/me", web::get().to(merchants::get_me))
.route("/me/status", web::put().to(merchants::update_status))
// ... puis les routes /{id}/* existantes
```

### Preparation story 3.6 (Order Reception)

Cette story expose `check_auto_pause()` et `increment_no_response()` comme API interne du module merchants. La story 3.6 les appellera quand un marchand ne repond pas a une commande dans le delai imparti. Le flow sera :
1. Commande arrive → timer demarre
2. Pas de reponse → `increment_no_response(pool, merchant_id)`
3. → `check_auto_pause(pool, merchant_id)` → si 3+ → auto_pause
4. Quand commande acceptee → `reset_no_response(pool, merchant_id)` (retour a 0)

**NE PAS implementer le timer ni le trigger dans cette story** — seulement les fonctions service/repository.

### Anti-patterns a eviter

- NE PAS creer un nouveau module Rust `server/crates/domain/src/vendor_status/` — les fonctions restent dans `merchants/`
- NE PAS ajouter WebSocket pour les changements de statut — polling via provider suffit pour le MVP
- NE PAS implementer les notifications push de changement de statut — sera fait plus tard
- NE PAS modifier le modele B2C pour l'instant — le mode read-only sera utilise dans story 4.2
- NE PAS ajouter de table `status_history` — le changement est direct, pas d'audit trail pour le MVP
- NE PAS implementer la logique de timer de non-reponse — c'est story 3.6
- NE PAS creer le dossier `packages/mefali_design/lib/components/` en tant que package ou library — juste un fichier dans le dossier existant
- NE PAS oublier de regenerer `merchant.g.dart` apres avoir change le type de `status` (String → VendorStatus) — sinon le build casse

### Impact sur le modele Merchant Dart

Changer `String status` → `VendorStatus status` dans `merchant.dart` est un **breaking change** pour tout code qui compare `merchant.status` a une string. Verifier :
- `merchant_onboarding_provider.dart` — aucune comparaison directe de status trouvee
- `merchant.g.dart` — sera regenere automatiquement par build_runner
- Aucun autre fichier Flutter n'utilise `merchant.status` actuellement

### Git intelligence

Derniers commits : pattern `{story-key}: {status}`. Story 3.4 livree et reviewee. Total tests : ~131 Rust, ~18 Flutter B2B. Aucun changement non-commite lie a cette story (les fichiers modifies dans git status sont les artefacts de story 3.4).

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 3, Story 3.5, FR10, FR17]
- [Source: _bmad-output/planning-artifacts/architecture.md — schema merchants, API patterns, MerchantStatus enum]
- [Source: _bmad-output/planning-artifacts/prd.md — FR10, FR17, success metric < 5% annulation vendeur]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — UX-DR7 VendorStatusIndicator, couleurs, interactions]
- [Source: _bmad-output/implementation-artifacts/3-4-stock-level-management.md — patterns, fichiers, learnings code review]
- [Source: server/crates/domain/src/merchants/model.rs — MerchantStatus enum, Merchant struct]
- [Source: server/crates/domain/src/merchants/repository.rs — queries existantes avec availability_status]
- [Source: server/migrations/20260317000001_create_enums.up.sql — vendor_status enum DB]
- [Source: server/migrations/20260317000004_create_merchants.up.sql — availability_status column + index]
- [Source: packages/mefali_core/lib/enums/user_status.dart — pattern enum Dart avec @JsonEnum]

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
