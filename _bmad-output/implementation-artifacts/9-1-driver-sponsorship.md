# Story 9.1: Driver Sponsorship

Status: in-progress

## Story

As a livreur,
I want to sponsor new drivers (max 3),
So that I grow the network.

## Acceptance Criteria

1. **Given** active driver with < 3 sponsorships **When** new driver registers with my phone as sponsor **Then** sponsorship recorded **And** max 3 enforced
2. **Given** active driver with 3 active sponsorships **When** new driver tries to register with my phone **Then** registration rejected with clear error "Votre parrain a atteint le maximum de 3 filleuls"
3. **Given** driver **When** viewing profile **Then** sees sponsorship section: count of filleuls, list of filleuls with status, remaining slots
4. **Given** sponsored driver account suspended/terminated **Then** sponsor's active count decremented (frees a slot)
5. **Given** non-driver user or inactive driver **When** used as sponsor_phone **Then** registration rejected "Ce numero n'est pas un livreur actif"

## Business Context

Le parrainage est un mecanisme social central de mefali : le parrain (max 3 filleuls) engage sa reputation. Ce systeme reproduit le mecanisme de confiance traditionnel africain (le garant) dans un contexte digital. En cas de probleme, c'est le parrain qui est contacte en premier (Story 9.2). Le parrain perd ses droits de parrainage si ses filleuls accumulent des problemes (Story 9.3).

**Validation success:** Taux de litiges des parraines vs non-parraines < 2%
**Fallback:** Penalite progressive si le parrain ne prend pas ses responsabilites au serieux.

## Tasks / Subtasks

### Backend Rust

- [ ] Task 1: Enrichir le module domain sponsorships (AC: #1, #2, #4)
  - [ ] 1.1 Enrichir `model.rs` : ajouter `MAX_ACTIVE_SPONSORSHIPS = 3`, `CreateSponsorshipError` enum, derive complets (`sqlx::FromRow`, `Serialize`, `Deserialize`, `sqlx::Type` sur SponsorshipStatus)
  - [ ] 1.2 Enrichir `repository.rs` : ajouter `count_active_by_sponsor(pool, sponsor_id) -> i64`, `find_by_sponsor(pool, sponsor_id) -> Vec<SponsorshipWithUser>`, `update_status(pool, sponsorship_id, status)`
  - [ ] 1.3 Implementer `service.rs` : `create_sponsorship(pool, sponsor_id, sponsored_id)` avec validation max 3, `list_sponsored_drivers(pool, sponsor_id)`, `get_sponsor_info(pool, driver_id)` pour le profil

- [ ] Task 2: Renforcer la validation dans le flux d'inscription (AC: #1, #2, #5)
  - [ ] 2.1 Modifier `users/service.rs::verify_otp_and_register()` : appeler `sponsorships::service::validate_can_sponsor()` AVANT de creer le user
  - [ ] 2.2 `validate_can_sponsor(pool, sponsor_phone)` verifie: sponsor existe, role = driver, statut actif, count < 3
  - [ ] 2.3 Retourner erreurs specifiques : `SponsorNotFound`, `SponsorNotDriver`, `SponsorNotActive`, `SponsorMaxReached`

- [ ] Task 3: Creer les endpoints API sponsorship (AC: #3)
  - [ ] 3.1 `GET /api/v1/sponsorships/me` — retourne filleuls du driver connecte + count + remaining slots
  - [ ] 3.2 `GET /api/v1/sponsorships/me/sponsor` — retourne info sur le parrain du driver connecte
  - [ ] 3.3 Ajouter les routes dans `routes/mod.rs`

- [ ] Task 4: Tests backend (AC: #1-#5)
  - [ ] 4.1 Tests unitaires service : sponsor valide, max 3, sponsor inactif, self-sponsor
  - [ ] 4.2 Tests integration API : registration avec sponsor valide, sponsor max atteint, sponsor inexistant
  - [ ] 4.3 Test decrementation : quand un filleul est desactive, le compteur diminue

### Frontend Flutter

- [ ] Task 5: Modele et API client (AC: #3)
  - [ ] 5.1 Creer `packages/mefali_core/lib/models/sponsorship.dart` : `Sponsorship`, `SponsorshipStatus`, `SponsorInfo`, `SponsoredDriver`
  - [ ] 5.2 Creer `packages/mefali_api_client/lib/endpoints/sponsorship_endpoint.dart` : `getMySponsored()`, `getMySponsor()`
  - [ ] 5.3 Creer `packages/mefali_api_client/lib/providers/sponsorship_provider.dart` : providers autoDispose

- [ ] Task 6: Ecran parrainage dans le profil livreur (AC: #3)
  - [ ] 6.1 Creer `apps/mefali_livreur/lib/features/profile/sponsorship_screen.dart`
  - [ ] 6.2 Afficher : nombre filleuls (X/3), liste filleuls avec nom/status/date, info parrain
  - [ ] 6.3 Ajouter entree dans le profil livreur pour naviguer vers cet ecran

- [ ] Task 7: Ameliorer les messages d'erreur d'inscription (AC: #2, #5)
  - [ ] 7.1 Mapper les erreurs backend vers messages FR dans `registration_screen.dart`

## Dev Notes

### Code existant a reutiliser (NE PAS reinventer)

**Migration DEJA EXISTANTE** — `server/migrations/20260317000012_create_sponsorships.up.sql` :
- Table `sponsorships(id, sponsor_id, sponsored_id, status, created_at, updated_at)`
- FK sur users(id), constraint `sponsor_id != sponsored_id`
- Index sur `sponsor_id`
- NE PAS creer de nouvelle migration sauf si colonnes manquantes

**Enums PostgreSQL DEJA EXISTANTS** — `server/migrations/20260317000001_create_enums.up.sql` :
- `sponsorship_status AS ENUM ('active', 'suspended', 'terminated')`
- Verifier l'existence exacte de ces valeurs avant d'implementer

**Domain module EXISTANT** — `server/crates/domain/src/sponsorships/` :
- `mod.rs` — exporte model, repository, service
- `model.rs` — `Sponsorship` struct (id, sponsor_id, sponsored_id, status, created_at) + `SponsorshipStatus` enum (Active, Suspended, Terminated)
- `repository.rs` — `create()` et `find_by_sponsored()` DEJA implementes
- `service.rs` — placeholder vide, A IMPLEMENTER
- `lib.rs` — `pub mod sponsorships;` DEJA declare

**ATTENTION : Duplication existante** — `users/model.rs` lignes 108-135 contient une copie de `SponsorshipStatus` et `Sponsorship`. REFACTORER pour utiliser `sponsorships::model` partout. Supprimer les duplications dans `users/model.rs`.

**Aussi dans users/sponsorship_repository.rs** — contient un `create()` duplique. SUPPRIMER et utiliser `sponsorships::repository::create()`.

**Flux d'inscription existant** — `users/service.rs::verify_otp_and_register()` :
- Accepte `sponsor_phone: Option<String>`
- Valide que le sponsor existe et est un driver
- Empeche le self-sponsoring
- Cree le sponsorship apres creation du user
- **MANQUE** : validation du max 3 filleuls. C'est le coeur de cette story.

**Frontend existant** :
- `mefali_livreur/features/auth/registration_screen.dart` — collecte deja le numero de parrain
- `mefali_livreur/features/auth/auth_controller.dart` — passe `sponsorPhone` au provider
- `mefali_api_client/endpoints/auth_endpoint.dart` — envoie `sponsor_phone` dans le body
- `mefali_admin/features/drivers/driver_detail_screen.dart` — affiche deja `sponsor_name`

### Patterns obligatoires (etablis dans epics 7-8)

**Backend Rust :**
- Enums serde : `#[derive(Serialize, Deserialize, sqlx::Type)] #[sqlx(type_name = "text", rename_all = "snake_case")]`
- Response : `ApiResponse::new(data)` succes, `ApiResponse::with_pagination(items, page, per_page, total)` listes
- Auth guard : `require_role(&auth, &[UserRole::Driver])?;`
- Tests : `#[sqlx::test(migrations = "../../migrations")]` + `test_helpers::test_app(pool)`
- Tracing : `info!()` / `tracing::warn!()` pour logging structure

**Frontend Flutter :**
- Models : `@JsonSerializable(fieldRename: FieldRename.snake)` + `part 'xxx.g.dart'`
- Providers : `FutureProvider.autoDispose.family<T, String>` ou `FutureProvider.autoDispose` sans parametre
- UI : Material 3, touch targets >= 48dp, `FilledButton` brun (`#5D4037`)
- Erreurs : `asyncValue.when(data:, loading:, error:)` avec shimmer pour loading
- SnackBar : vert succes, rouge erreur, 3s auto-dismiss

### Anti-patterns a eviter

1. NE PAS creer de migration sauf si la table/enums sont incomplets — verifier d'abord
2. NE PAS dupliquer les types Sponsorship/SponsorshipStatus — SUPPRIMER les copies dans `users/model.rs` et `users/sponsorship_repository.rs`, utiliser `sponsorships::*`
3. NE PAS implementer la notification au parrain (Story 9.2) ni les penalites (Story 9.3) — hors scope
4. NE PAS ajouter de fonctionnalite de partage de code parrainage — le mecanisme est le numero de telephone du parrain, pas un code
5. NE PAS modifier le flux KYC/admin — l'inscription livreur + parrain est deja fonctionnelle, on ajoute juste la validation max 3
6. NE PAS creer de nouveau crate/package — tout s'integre dans les modules existants

### Architecture des endpoints

```
GET /api/v1/sponsorships/me
  Auth: JWT (Driver role)
  Response 200:
  {
    "data": {
      "max_sponsorships": 3,
      "active_count": 2,
      "remaining_slots": 1,
      "can_sponsor": true,
      "sponsored_drivers": [
        {
          "id": "uuid",
          "name": "Kone Ibrahim",
          "phone": "+225xxxxxxxxxx",
          "status": "active",
          "created_at": "2026-01-15T08:00:00Z"
        }
      ]
    }
  }

GET /api/v1/sponsorships/me/sponsor
  Auth: JWT (Driver role)
  Response 200:
  {
    "data": {
      "id": "uuid",
      "name": "Traore Moussa",
      "phone": "+225xxxxxxxxxx",
      "sponsorship_status": "active",
      "sponsored_at": "2026-01-10T08:00:00Z"
    }
  }
  Response 200 (pas de parrain): { "data": null }

POST /api/v1/auth/verify-otp (EXISTANT, modifier comportement)
  Body: { "phone": "...", "otp": "...", "role": "driver", "sponsor_phone": "+225..." }
  Error 400 (nouveau): { "error": { "code": "SPONSOR_MAX_REACHED", "message": "Votre parrain a atteint le maximum de 3 filleuls" } }
  Error 400 (nouveau): { "error": { "code": "SPONSOR_NOT_ACTIVE", "message": "Ce numero n'est pas un livreur actif" } }
```

### Modele de donnees

```sql
-- Table EXISTANTE (aucune modification attendue)
sponsorships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sponsor_id UUID NOT NULL REFERENCES users(id),
  sponsored_id UUID NOT NULL REFERENCES users(id),
  status sponsorship_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (sponsor_id != sponsored_id)
);
CREATE INDEX idx_sponsorships_sponsor_id ON sponsorships(sponsor_id);
```

### Project Structure Notes

**Backend — fichiers a modifier :**
```
server/crates/domain/src/sponsorships/
  model.rs          <- ENRICHIR (constante MAX, error types, SponsoredDriverInfo struct)
  repository.rs     <- ENRICHIR (count_active, find_by_sponsor avec JOIN users, update_status)
  service.rs        <- IMPLEMENTER (validate_can_sponsor, create_sponsorship, list_sponsored)

server/crates/domain/src/users/
  model.rs          <- SUPPRIMER duplication Sponsorship/SponsorshipStatus
  service.rs        <- MODIFIER verify_otp_and_register (ajouter validation max 3)
  sponsorship_repository.rs  <- SUPPRIMER (duplique sponsorships::repository)

server/crates/api/src/routes/
  sponsorships.rs   <- CREER (2 handlers GET)
  mod.rs            <- MODIFIER (ajouter pub mod sponsorships + routes)
```

**Frontend — fichiers a creer :**
```
packages/mefali_core/lib/models/sponsorship.dart
packages/mefali_api_client/lib/endpoints/sponsorship_endpoint.dart
packages/mefali_api_client/lib/providers/sponsorship_provider.dart
apps/mefali_livreur/lib/features/profile/sponsorship_screen.dart
```

**Frontend — fichiers a modifier :**
```
packages/mefali_core/lib/mefali_core.dart              <- export sponsorship.dart
packages/mefali_api_client/lib/mefali_api_client.dart   <- exports
apps/mefali_livreur/lib/features/auth/registration_screen.dart  <- meilleurs messages erreur
apps/mefali_livreur/lib/features/profile/              <- lien vers SponsorshipScreen
```

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 9, Stories 9.1-9.3]
- [Source: _bmad-output/planning-artifacts/prd.md — FR56-FR58, Journey 2 Kone, Journey 4 Fatou]
- [Source: _bmad-output/planning-artifacts/architecture.md — Schema DB sponsorships, Parrainage FR56-58 mapping]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Emotional journey Kone fidélisation]
- [Source: server/crates/domain/src/sponsorships/ — module existant]
- [Source: server/migrations/20260317000012_create_sponsorships.up.sql — migration existante]
- [Source: _bmad-output/implementation-artifacts/8-5-merchant-and-driver-history.md — patterns admin]
- [Source: _bmad-output/implementation-artifacts/7-3-dispute-reporting.md — patterns domain]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
