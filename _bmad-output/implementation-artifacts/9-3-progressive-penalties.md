# Story 9.3: Penalites Progressives du Parrainage

Status: done

## Story

As the system,
I want to revoke sponsorship rights on accumulated problems,
so that sponsors take responsibility.

## Acceptance Criteria

1. **Given** sponsor's drivers have 3+ disputes **When** threshold reached **Then** sponsorship rights revoked
2. **And** sponsor notified (FCM push + SMS fallback)
3. **And** existing sponsorships stay active (seuls les nouveaux parrainages sont bloques)
4. **Given** sponsor with revoked rights **When** they try to sponsor a new driver **Then** registration rejects with clear error message
5. **Given** admin reviews sponsor penalties **When** consulting history **Then** sees penalty events in audit log

## Tasks / Subtasks

- [x] Task 1: Ajouter le champ `can_sponsor` au modele User et migration (AC: #1, #4)
  - [x] 1.1 Migration SQL: `ALTER TABLE users ADD COLUMN can_sponsor BOOLEAN NOT NULL DEFAULT true`
  - [x] 1.2 Mettre a jour `User` struct dans `users/model.rs` avec `can_sponsor: bool`
  - [x] 1.3 Mettre a jour toutes les queries SQL users pour inclure `can_sponsor`
- [x] Task 2: Creer la logique de comptage des litiges par parrain (AC: #1)
  - [x] 2.1 Ajouter `count_disputes_for_sponsored_drivers(sponsor_id)` dans `disputes/repository.rs`
  - [x] 2.2 Query: COUNT disputes WHERE reporter's order involved a driver sponsored by sponsor_id (status = 'open' | 'in_progress' | 'resolved')
- [x] Task 3: Implementer la revocation automatique dans le flow de dispute (AC: #1, #2)
  - [x] 3.1 Ajouter `DISPUTE_THRESHOLD_FOR_REVOCATION: i64 = 3` constante dans `sponsorships/model.rs`
  - [x] 3.2 Creer `check_and_revoke_sponsor_rights(sponsor_id)` dans `sponsorships/service.rs`
  - [x] 3.3 Appeler cette fonction dans `notify_sponsor_if_applicable()` dans `disputes.rs` (apres notification sponsor)
  - [x] 3.4 Mettre a jour `users.can_sponsor = false` via `user_service`
  - [x] 3.5 Envoyer notification FCM au sponsor: "Vos droits de parrainage ont ete suspendus suite a des litiges repetes de vos filleuls"
  - [x] 3.6 SMS fallback: "mefali: Vos droits de parrainage sont suspendus. Litiges repetes de vos filleuls. Contactez le support."
  - [x] 3.7 Inserer un `dispute_event` type `sponsor_rights_revoked` dans la timeline
- [x] Task 4: Bloquer le parrainage dans le flow d'inscription (AC: #4)
  - [x] 4.1 Modifier `validate_can_sponsor()` dans `sponsorships/service.rs` pour verifier `user.can_sponsor`
  - [x] 4.2 Ajouter erreur `BadRequestWithCode("SPONSOR_RIGHTS_REVOKED", ...)` (coherent avec les autres erreurs sponsor)
  - [x] 4.3 Mapper vers HTTP 400 avec message: "Ce livreur n'a plus le droit de parrainer de nouveaux livreurs"
- [x] Task 5: Audit log pour les penalites (AC: #5)
  - [x] 5.1 Inserer un `AdminAuditLog` quand les droits sont revoques automatiquement
  - [x] 5.2 Utiliser `sponsor_id` comme admin_id (FK constraint, action identifiable via "revoke_sponsorship_rights")
- [x] Task 6: Flutter - Messages d'erreur cote livreur (AC: #4)
  - [x] 6.1 Mettre a jour `sponsorship_screen.dart` pour afficher le statut `can_sponsor` (badge "Parrainage suspendu")
  - [x] 6.2 Mettre a jour `registration_screen.dart` pour gerer l'erreur `SPONSOR_RIGHTS_REVOKED` avec message FR
- [x] Task 7: Tests d'integration (tous AC)
  - [x] 7.1 Test: sponsor avec 2 litiges filleuls -> droits maintenus
  - [x] 7.2 Test: sponsor avec 3 litiges filleuls -> droits revoques
  - [x] 7.3 Test: sponsor revoque tente de parrainer -> erreur 400
  - [x] 7.4 Test: parrainages existants restent actifs apres revocation
  - [x] 7.5 Test: dispute_event `sponsor_rights_revoked` enregistre dans timeline
  - [x] 7.6 Test: audit log cree pour revocation automatique
  - [x] 7.7 Test: GET /sponsorships/me shows can_sponsor=false after revocation

## Dev Notes

### Architecture et Patterns Existants

**Flow de creation de dispute (a etendre):**
1. Client cree dispute via `POST /api/v1/orders/{order_id}/dispute`
2. Route `disputes.rs` fire-and-forget: `notify_sponsor_if_applicable()` (lignes 154-298)
3. Cette fonction cherche le sponsor du livreur, envoie FCM+SMS, enregistre `dispute_event`
4. **POINT D'INSERTION:** Apres notification sponsor, appeler `check_and_revoke_sponsor_rights()`

**Validation du parrainage existante (a modifier):**
- `sponsorships/service.rs::validate_can_sponsor()` (lignes 16-52) verifie: sponsor existe, est livreur, est actif, a < 3 filleuls
- **AJOUTER:** verification `user.can_sponsor == true` comme premiere condition

**Gestion de statut utilisateur existante:**
- `users/service.rs::admin_update_user_status()` (lignes 382-448) gere Active/Suspended/Deactivated
- `AdminAuditLog` struct (users/model.rs:179-189) enregistre les changements
- **REUTILISER** ce pattern pour l'audit log des revocations automatiques

**Notifications existantes (reutiliser):**
- `disputes.rs` contient deja la logique FCM + SMS fallback pour contacter le sponsor
- Reutiliser exactement le meme pattern pour la notification de revocation
- `notification` crate: `send_fcm()` et `send_sms()` disponibles

### Constantes et Enums Existants

```rust
// sponsorships/model.rs
pub const MAX_ACTIVE_SPONSORSHIPS: i64 = 3;
// AJOUTER:
pub const DISPUTE_THRESHOLD_FOR_REVOCATION: i64 = 3;

// disputes/model.rs - DisputeType enum
DisputeType: Incomplete, Quality, WrongOrder, Other
// DisputeStatus enum
DisputeStatus: Open, InProgress, Resolved, Closed

// users/model.rs - UserStatus enum
UserStatus: Active, PendingKyc, Suspended, Deactivated
```

### Base de Donnees

**Tables impliquees:**
- `users` — ajouter colonne `can_sponsor BOOLEAN NOT NULL DEFAULT true`
- `disputes` — lecture seule pour compter
- `sponsorships` — lecture seule pour trouver les filleuls
- `dispute_events` — ecriture pour enregistrer l'evenement de revocation

**Query de comptage des litiges (coeur de la story):**
```sql
SELECT COUNT(DISTINCT d.id)
FROM disputes d
JOIN orders o ON d.order_id = o.id
JOIN sponsorships s ON o.driver_id = s.sponsored_id
WHERE s.sponsor_id = $1
  AND s.status = 'active'
  AND d.status IN ('open', 'in_progress', 'resolved')
```

### Decisions de Design

1. **`can_sponsor` sur users plutot que sur sponsorships:** Simple, un seul champ a verifier. Pas besoin d'un systeme de "strikes" complexe — le seuil est binaire (3+ litiges = revoque).
2. **Les parrainages existants restent actifs:** On ne change PAS le `sponsorship_status` des filleuls existants. Seul le droit de parrainer de nouveaux est bloque.
3. **Comptage ALL disputes (pas seulement confirmed):** Un litige ouvert ou en cours compte aussi — c'est l'accumulation qui compte, pas la resolution.
4. **Fire-and-forget pour la revocation:** Comme pour `notify_sponsor_if_applicable()`, la verification de seuil est async et ne bloque pas la creation de dispute.
5. **Pas de restauration automatique:** La restauration du droit de parrainage est une action admin manuelle (future story ou action admin existante via `PATCH /admin/users/{id}/status` etendu).
6. **BadRequestWithCode au lieu de Forbidden:** Utilisation de `BadRequestWithCode("SPONSOR_RIGHTS_REVOKED", ...)` pour la coherence avec le pattern `SPONSOR_MAX_REACHED`, `SPONSOR_NOT_ACTIVE`, etc. C'est une erreur de validation business, pas une erreur d'autorisation.
7. **sponsor_id comme admin_id dans audit log:** Le UUID nil viole la FK constraint sur `admin_audit_logs.admin_id -> users.id`. On utilise le sponsor_id comme actor et l'action "revoke_sponsorship_rights" identifie clairement que c'est une action systeme.

### Project Structure Notes

- Backend: `server/crates/domain/src/` pour logique metier, `server/crates/api/src/routes/` pour endpoints
- Migrations: `server/migrations/` avec format `YYYYMMDD00000N_description.{up,down}.sql`
- Prochaine migration: `20260322000007_add_can_sponsor_to_users.{up,down}.sql`
- Flutter: `apps/mefali_livreur/lib/features/profile/` pour ecrans livreur
- Erreurs: `server/crates/common/src/error.rs` pour `AppError` enum

### Anti-Patterns a Eviter

1. **NE PAS creer un systeme de "strikes" ou "warnings" complexe** — le seuil est simple: 3 litiges = revocation
2. **NE PAS suspendre/terminer les parrainages existants** — seul `can_sponsor` change
3. **NE PAS modifier le flow de resolution de dispute** — la verification se fait a la CREATION, pas a la resolution
4. **NE PAS ajouter d'endpoint admin specifique** — la revocation est automatique, la restauration utilise l'endpoint admin existant
5. **NE PAS toucher au modele Sponsorship** — pas de nouveau champ sur sponsorships, tout passe par `users.can_sponsor`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 9, Story 9.3]
- [Source: _bmad-output/planning-artifacts/prd.md#Innovation - Parrainage livreur avec responsabilite partagee]
- [Source: _bmad-output/planning-artifacts/prd.md#Risk Mitigation - Penalite progressive]
- [Source: _bmad-output/planning-artifacts/architecture.md#Database Schema - sponsorships, disputes]
- [Source: _bmad-output/implementation-artifacts/9-1-driver-sponsorship.md]
- [Source: _bmad-output/implementation-artifacts/9-2-sponsor-first-contact.md]
- [Source: server/crates/domain/src/disputes/service.rs - notification constants]
- [Source: server/crates/domain/src/sponsorships/service.rs - validate_can_sponsor()]
- [Source: server/crates/domain/src/users/service.rs - admin_update_user_status()]
- [Source: server/crates/api/src/routes/disputes.rs - notify_sponsor_if_applicable()]

### Intelligence Story 9-1

- `MAX_ACTIVE_SPONSORSHIPS = 3` defini dans `sponsorships/model.rs`
- Suppression de duplication: Sponsorship/SponsorshipStatus retires du module users
- `sponsorship_repository.rs` supprime — tout est dans `sponsorships/repository.rs`
- 12 tests d'integration couvrant tous les AC
- Frontend: messages d'erreur FR-specifiques pour le parrainage

### Intelligence Story 9-2

- `dispute_events` table creee (migration 20260322000006)
- `insert_dispute_event()` dans disputes/repository.rs (lignes 202-222)
- `notify_sponsor_if_applicable()` est fire-and-forget dans disputes.rs (lignes 154-298)
- `find_active_sponsor_with_contact()` retourne (id, name, phone, fcm_token)
- Pattern FCM + SMS fallback deja implemente et teste
- 349 tests passent, 0 regressions

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Completion Notes List

- Task 1: Migration `20260322000007_add_can_sponsor_to_users` + `User.can_sponsor: bool` + all SQL queries updated
- Task 2: `count_disputes_for_sponsored_drivers()` in disputes/repository.rs — JOIN disputes/orders/sponsorships
- Task 3: `check_and_revoke_sponsor_rights()` in sponsorships/service.rs + `check_sponsor_penalties()` in disputes.rs route (fire-and-forget after sponsor notification) — FCM + SMS fallback + dispute_event + audit log
- Task 4: `validate_can_sponsor()` now checks `can_sponsor` field first, returns SPONSOR_RIGHTS_REVOKED error code
- Task 5: Audit log with action "revoke_sponsorship_rights" using sponsor_id as actor (FK constraint)
- Task 6: Flutter sponsorship_screen.dart — warning card when rights revoked; registration_screen.dart — SPONSOR_RIGHTS_REVOKED error mapping
- Task 7: 8 new integration tests (7 story 9.3 + 1 API endpoint test), all passing. 356 total tests, 0 regressions.

### Debug Log References

### File List

- server/migrations/20260322000007_add_can_sponsor_to_users.up.sql (new)
- server/migrations/20260322000007_add_can_sponsor_to_users.down.sql (new)
- server/crates/domain/src/users/model.rs (modified — added can_sponsor field)
- server/crates/domain/src/users/repository.rs (modified — all queries updated + update_can_sponsor())
- server/crates/domain/src/users/service.rs (modified — test fixture updated)
- server/crates/domain/src/disputes/repository.rs (modified — count_disputes_for_sponsored_drivers())
- server/crates/domain/src/sponsorships/model.rs (modified — DISPUTE_THRESHOLD_FOR_REVOCATION constant)
- server/crates/domain/src/sponsorships/service.rs (modified — check_and_revoke_sponsor_rights(), validate_can_sponsor() guard, notification constants, get_my_sponsorships() uses user.can_sponsor)
- server/crates/api/src/routes/disputes.rs (modified — check_sponsor_penalties() fire-and-forget)
- server/crates/api/src/routes/sponsorships.rs (modified — 8 new integration tests)
- apps/mefali_livreur/lib/features/profile/sponsorship_screen.dart (modified — revocation warning card)
- apps/mefali_livreur/lib/features/auth/registration_screen.dart (modified — SPONSOR_RIGHTS_REVOKED error mapping)
