# Story 9.2: Sponsor-First Contact

Status: done

## Story

As the system,
I want to contact the sponsor first when a sponsored driver is involved in a dispute,
so that social accountability works and the traditional African guarantor mechanism is effective.

## Business Context

Le parrainage mefali reproduit le mecanisme de confiance traditionnel africain (le garant) dans un contexte digital. Quand un filleul cause un probleme, le parrain est contacte en premier — avant toute escalade admin. Ce contact est enregistre dans la timeline du litige pour tracabilite. Ce mecanisme cree une pression sociale positive : le parrain a interet a bien choisir ses filleuls et a les encadrer.

Lien avec les autres stories :
- Story 9.1 (done) : creation du lien parrain/filleul, max 3, endpoints API
- Story 9.3 (backlog) : revocation des droits de parrainage si 3+ litiges accumules

## Acceptance Criteria

1. **Given** un livreur parraine implique dans un litige **When** le litige est cree **Then** le systeme identifie automatiquement le parrain via la table `sponsorships` **And** envoie une notification push (FCM) au parrain avec les details du litige **And** envoie un SMS de fallback si le parrain n'a pas de FCM token
2. **Given** le parrain est notifie **When** la notification est envoyee **Then** un evenement `sponsor_contacted` est enregistre dans la timeline du litige avec timestamp
3. **Given** un livreur sans parrain (pas de ligne dans sponsorships ou sponsorship inactive) **When** un litige est cree **Then** le flux normal continue sans notification parrain (pas d'erreur)
4. **Given** un litige cree pour un livreur parraine **When** l'admin consulte le detail du litige **Then** il voit l'evenement "Parrain contacte" dans la timeline avec le nom et telephone du parrain
5. **Given** un livreur parraine implique comme conducteur dans un litige **When** le litige concerne une commande ou ce livreur etait le driver **Then** le parrain est contacte (le livreur est identifie via `orders.driver_id`)

## Tasks / Subtasks

- [x] Task 1: Ajouter le champ `driver_id` dans la logique de notification parrain (AC: #1, #5)
  - [x] 1.1: Dans `routes/disputes.rs`, query directe `SELECT driver_id FROM orders WHERE id = $1` dans notify_sponsor_if_applicable()
  - [x] 1.2: Dans `sponsorships/service.rs`, ajouter `find_active_sponsor_for_driver(driver_id) -> Option<SponsorContactInfo>`
  - [x] 1.3: Dans `sponsorships/repository.rs`, ajouter la query `find_active_sponsor_with_contact(sponsored_id)` retournant (sponsor user_id, name, phone, fcm_token)

- [x] Task 2: Implementer la notification parrain lors de la creation d'un litige (AC: #1, #3)
  - [x] 2.1: Dans `routes/disputes.rs`, dans le handler `create_dispute`, apres la creation du litige, ajouter un spawn async fire-and-forget `notify_sponsor_if_applicable()`
  - [x] 2.2: `notify_sponsor_if_applicable()` : recuperer driver_id de la commande, chercher le parrain actif, si existe envoyer push FCM + fallback SMS, si pas de parrain ou sponsorship inactive → skip silencieusement
  - [x] 2.3: Message push : titre = "Litige signale pour votre filleul", body = "Un litige de type {type} a ete signale pour {driver_name}. En tant que parrain, vous etes informe en priorite."
  - [x] 2.4: SMS fallback : "mefali: Litige ({type}) signale pour votre filleul {driver_name}. Contactez-le. Ref: {dispute_id_short}"
  - [x] 2.5: Data JSON du push : `{"event": "sponsorship.dispute_alert", "dispute_id": "...", "driver_name": "..."}`

- [x] Task 3: Enregistrer le contact parrain dans la timeline du litige (AC: #2, #4)
  - [x] 3.1: Table `dispute_events(id, dispute_id, event_type, label, metadata JSONB, created_at)` + migration 20260322000006
  - [x] 3.2: Ajouter `insert_dispute_event(dispute_id, event_type, label, metadata)` dans le repository
  - [x] 3.3: Dans `notify_sponsor_if_applicable()`, apres envoi reussi de la notification, inserer l'evenement timeline : label = "Parrain contacte : {sponsor_name} ({sponsor_phone})", event_type = "sponsor_contacted"
  - [x] 3.4: Modifier `get_order_timeline()` dans `disputes/repository.rs` pour inclure les dispute_events via UNION

- [x] Task 4: Mettre a jour l'affichage admin de la timeline (AC: #4)
  - [x] 4.1: Verifie que le widget Flutter `OrderTimeline` est generique (label + timestamp) — aucune modification necessaire
  - [x] 4.2: Verifie que le modele `OrderTimelineEvent` deserialise correctement les nouveaux events — aucune modification necessaire

- [x] Task 5: Tests backend (AC: #1-#5)
  - [x] 5.1: Test integration : creer un litige pour un livreur parraine → verifier que l'evenement `sponsor_contacted` est dans la timeline
  - [x] 5.2: Test integration : creer un litige pour un livreur sans parrain → verifier qu'aucun evenement sponsor n'est cree, pas d'erreur
  - [x] 5.3: Test integration : `find_active_sponsor_for_driver` retourne None quand sponsorship `terminated`
  - [x] 5.4: Test unitaire : `find_active_sponsor_for_driver` retourne Some quand sponsorship active, None quand aucune
  - [x] 5.5: Test integration admin : GET dispute detail inclut l'evenement "Parrain contacte" dans la timeline

## Dev Notes

### Code existant a reutiliser (NE PAS reinventer)

**Pattern notification fire-and-forget** (deja utilise dans disputes.rs) :
```rust
// Dans routes/disputes.rs - notify_admins_new_dispute()
actix_web::rt::spawn(async move {
    notify_function(&pool, &fcm).await;
});
```

**Recuperation FCM token** (pattern existant) :
```rust
let token: Option<(String,)> = sqlx::query_as(
    "SELECT fcm_token FROM users WHERE id = $1 AND fcm_token IS NOT NULL AND fcm_token != ''",
)
.bind(user_id)
.fetch_optional(pool)
.await?;
```

**PushNotification struct** (crates/notification/src/fcm.rs) :
```rust
PushNotification { device_token, title, body, data: Option<serde_json::Value> }
```

**SMS fallback** (crates/notification/src/sms/) :
```rust
sms_router.send_sms(phone, message).await
```

**Timeline existante** (disputes/repository.rs::get_order_timeline) :
- Retourne Vec<OrderTimelineEvent> via UNION SQL sur les dates de la commande
- Format : `{ label: String, timestamp: DateTime }`
- Affiche dans dispute_detail_screen.dart sans logique specifique par type

### Fichiers a modifier

**Backend :**
- `server/crates/domain/src/sponsorships/repository.rs` — ajouter `find_active_sponsor_with_contact()`
- `server/crates/domain/src/sponsorships/service.rs` — ajouter `find_active_sponsor_for_driver()`
- `server/crates/domain/src/disputes/repository.rs` — ajouter table `dispute_events`, `insert_dispute_event()`, modifier `get_order_timeline()` UNION
- `server/crates/domain/src/disputes/service.rs` — ajouter constantes messages notification parrain
- `server/crates/api/src/routes/disputes.rs` — ajouter `notify_sponsor_if_applicable()` dans create_dispute handler

**Migration SQL :**
- `server/migrations/XXXXXX_create_dispute_events.up.sql` — table dispute_events

**Aucun fichier Flutter a modifier** — la timeline admin affiche deja les events avec label + timestamp generiquement.

### Architecture et patterns obligatoires

- **Notification async fire-and-forget** : le sponsor est notifie en arriere-plan, jamais bloquant pour la creation du litige
- **Pas de notification push sans fallback SMS** : si fcm_token absent, envoyer SMS au telephone du parrain
- **Pas d'erreur si pas de parrain** : le flux doit etre silencieux quand le livreur n'a pas de parrain actif
- **Timeline immutable** : les events sont inseres, jamais modifies ni supprimes
- **snake_case partout** : JSON fields, DB columns, endpoints
- **UUID v4** pour les IDs de dispute_events
- **sqlx::test avec migrations** pour les tests d'integration
- **Messages en francais** sans accents (limitations SMS/push)

### Anti-patterns a eviter

1. **NE PAS modifier le flux de creation de litige** — la notification parrain est un side-effect async, pas une etape bloquante
2. **NE PAS creer d'endpoint API pour notifier le parrain** — c'est automatique a la creation du litige
3. **NE PAS implementer la logique de penalites progressives** (Story 9.3)
4. **NE PAS modifier l'UI Flutter admin** sauf si le format timeline change (il ne devrait pas)
5. **NE PAS ajouter de champ dans la table `disputes`** — utiliser une table d'events separee
6. **NE PAS envoyer de notification au parrain lors de la resolution** — seulement a la creation
7. **NE PAS creer de nouveau crate ou package**
8. **NE PAS notifier le parrain pour les litiges ou le filleul est le client** — seulement quand il est le driver de la commande

### Decision architecturale : table dispute_events

Plutot que d'ajouter des colonnes a la table `disputes`, creer une table `dispute_events` :
```sql
CREATE TABLE dispute_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID NOT NULL REFERENCES disputes(id),
    event_type VARCHAR(50) NOT NULL,  -- 'sponsor_contacted', future: 'penalty_applied', etc.
    label TEXT NOT NULL,              -- Texte affiche dans la timeline
    metadata JSONB,                   -- Donnees supplementaires (sponsor_id, notification_type, etc.)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_dispute_events_dispute_id ON dispute_events(dispute_id);
```

Cette table est extensible pour Story 9.3 (penalties) et d'autres events futurs.

La query `get_order_timeline()` existante sera etendue avec un UNION :
```sql
-- ... existing order timeline UNIONs ...
UNION ALL
SELECT label, created_at AS timestamp FROM dispute_events WHERE dispute_id = $1
ORDER BY timestamp ASC
```

### Project Structure Notes

- Alignement complet avec la structure existante : domain logic dans `crates/domain/`, routes dans `crates/api/src/routes/`, notifications via `crates/notification/`
- La table `dispute_events` suit le pattern des autres tables (UUID PK, created_at, FK avec index)
- Le numero de migration doit suivre la sequence existante dans `server/migrations/`

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 9, Story 9.2]
- [Source: _bmad-output/planning-artifacts/prd.md — FR57: Systeme contacte le parrain en premier]
- [Source: _bmad-output/planning-artifacts/architecture.md — Notification system, Dispute system]
- [Source: _bmad-output/implementation-artifacts/9-1-driver-sponsorship.md — Previous story context]
- [Source: server/crates/api/src/routes/disputes.rs — Pattern notify_admins_new_dispute()]
- [Source: server/crates/domain/src/disputes/repository.rs — get_order_timeline() existing implementation]
- [Source: server/crates/notification/src/fcm.rs — PushNotification struct]
- [Source: server/crates/notification/src/sms/mod.rs — SmsRouter::send_sms()]

### Previous Story Intelligence (9-1-driver-sponsorship)

- **Sponsorship domain module complet** : model.rs, repository.rs, service.rs fonctionnels avec tests
- **Pattern de tests** : sqlx::test avec migrations, require_role auth guard, 12 tests integration
- **Refactoring fait** : plus de duplication dans users/model.rs, sponsorship_repository.rs supprime
- **API existante** : GET /api/v1/sponsorships/me et GET /api/v1/sponsorships/me/sponsor
- **Repository existant** : `find_sponsor_info()` fait un JOIN users mais ne retourne pas le fcm_token → nouvelle query necessaire
- **343 tests Rust OK** apres 9.1, 10 tests Flutter OK — baseline de non-regression

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

### Completion Notes List

- SponsorContactInfo struct added to sponsorships/model.rs with fcm_token field for notification
- find_active_sponsor_with_contact() query in sponsorships/repository.rs: JOINs users to get sponsor contact with fcm_token, filtered by status='active'
- find_active_sponsor_for_driver() service function wrapping the repository call
- notify_sponsor_if_applicable() async fire-and-forget function in routes/disputes.rs: gets driver_id from order, finds active sponsor, sends FCM push (with SMS fallback), records sponsor_contacted event in timeline
- Notification constants added to disputes/service.rs: SPONSOR_DISPUTE_ALERT_TITLE, SPONSOR_DISPUTE_ALERT_BODY_TEMPLATE, SPONSOR_DISPUTE_ALERT_SMS_TEMPLATE
- dispute_events table created via migration 20260322000006 with UUID PK, dispute_id FK, event_type, label, metadata JSONB
- insert_dispute_event() repository function for writing timeline events
- get_order_timeline() extended with UNION ALL on dispute_events table
- create_dispute handler updated to accept SmsRouter and spawn notify_sponsor_if_applicable
- Flutter: no changes needed — OrderTimeline widget and OrderTimelineEvent model are generic (label+timestamp)
- 6 new integration tests added (3 for find_active_sponsor_for_driver, 3 for dispute timeline with sponsor events)
- All 349 tests pass (was 343 before), 0 regressions

### Change Log

- 2026-03-21: Story 9.2 implemented — sponsor-first contact on disputes, dispute_events table, 6 new tests
- 2026-03-21: Code review fixes — H1: notification_type metadata now tracks actual delivery method (push vs sms), M1: replaced dead-code template constants with formatter functions, M2: added test_helpers.rs to File List, L1: removed redundant format_args wrapping

### File List

Backend Modified (5 files):
- server/crates/domain/src/sponsorships/model.rs (added SponsorContactInfo struct)
- server/crates/domain/src/sponsorships/repository.rs (added find_active_sponsor_with_contact)
- server/crates/domain/src/sponsorships/service.rs (added find_active_sponsor_for_driver)
- server/crates/domain/src/disputes/repository.rs (added insert_dispute_event, extended get_order_timeline UNION)
- server/crates/domain/src/disputes/service.rs (added sponsor notification constants)

Backend Modified (1 file — routes):
- server/crates/api/src/routes/disputes.rs (added notify_sponsor_if_applicable, updated create_dispute with SmsRouter)

Backend Modified (1 file — test helpers):
- server/crates/api/src/test_helpers.rs (added SmsRouter app_data, sponsorships import)

Backend Modified (1 file — tests):
- server/crates/api/src/routes/sponsorships.rs (added 6 integration tests for Story 9.2)

Backend Created (2 files — migration):
- server/migrations/20260322000006_create_dispute_events.up.sql
- server/migrations/20260322000006_create_dispute_events.down.sql
