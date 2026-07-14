# Tasks: Arbre de zones et configuration héritée

**Input**: Design documents from `/specs/002-zones-config-heritee/`

**Prerequisites**: plan.md, spec.md, research.md (R1–R10), data-model.md, contracts/openapi-zones.yaml, quickstart.md

**Tests**: transitions d'état et matrice de résolution = tests d'intégration OBLIGATOIRES (constitution VII + FR-008) ; chaque tâche SQL inclut `cargo sqlx prepare`.

**Organization**: tâches groupées par user story (US1→US4 de spec.md). Granularité : ½ à 1 journée par tâche, ordonnées par dépendance (demande utilisateur).

**Règles transverses appliquées** (demande utilisateur) :

- Toute tâche touchant l'API (T012, T015) SE TERMINE par : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert (backend + diff clients commité).
- Toute tâche touchant le schéma COMMENCE par sa migration sqlx : une seule ici, T002 (`0002_zones.sql`) — les seeds (T009) ne modifient pas le schéma.
- Tâches UI : AUCUNE ce cycle (spec — écrans admin en T3) → aucune référence `docs/design/png/` requise.
- Dernière tâche = revue Definition of Done (T019, §0.4 de docs/user-stories-v2.md).

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, dépendances satisfaites)
- **[Story]** : US1 (résolution héritée), US2 (catégories), US3 (transports), US4 (config distante)

## Path Conventions

Monorepo Mefali — chemins réels du plan : crate `backend/crates/zones/`, surface HTTP `backend/api/src/`, migrations `backend/migrations/`, seeds `backend/seeds/`, module partagé `apps/packages/mefali_core/`. `clients/dart` et `clients/ts` : régénération UNIQUEMENT, jamais d'édition manuelle.

---

## Phase 1: Setup

**Purpose**: dépendances nouvelles vérifiées et figées (constitution X)

- [X] T001 Vérifier sur crates.io les dernières versions STABLES de `sha2` (version de config, R3) et `actix-governor` (rate-limit /config, R4), les ajouter à `backend/Cargo.toml` (workspace.dependencies) et aux crates consommateurs ; `cargo build` vert, lockfile commité. (½ j)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: schéma, types de base, taxonomie, écritures de domaine — bloque toutes les stories

**⚠️ CRITICAL**: aucune story ne démarre avant la fin de cette phase

- [X] T002 COMMENCE par la migration sqlx : créer `backend/migrations/0002_zones.sql` (data-model §1–2 : types `type_zone`/`politique_photo`/`forcage_categorie`, tables `zone` + `parametre_zone` + `type_transport` + `categorie` + `activation_categorie` avec colonne générée `actif`, trigger anti-cycle `zone_sans_cycle`, index, FK ON DELETE RESTRICT) ; `cargo sqlx migrate run` puis `cargo sqlx prepare --workspace` verts ; mettre à jour `backend/migrations/README.md`. (1 j)
- [X] T003 [P] Types publics du crate : `backend/crates/zones/src/modele.rs` (Zone, Devise, ConfigurationEffective + ValeurProvenance, CategorieActive, ErreurZones — data-model §5) et exports dans `backend/crates/zones/src/lib.rs` ; dépendances du crate (`socle`, sqlx, serde, uuid, chrono, thiserror, async-trait) dans `backend/crates/zones/Cargo.toml`. (½ j)
- [X] T004 [P] Déclarer AVANT implémentation (constitution VI) les 3 événements dans `docs/taxonomie-evenements.md` : `zone.parametre_modifie`, `categorie.forcage_change`, `categorie.activation_changee` (payloads de research R9 / data-model §3). (½ j)
- [ ] T005 Arbre : `backend/crates/zones/src/arbre.rs` — `PgZones::creer_zone` et re-parentage sur `&mut PgTransaction` avec validation anti-cycle applicative (erreur `CycleDetecte` explicite, en plus du trigger) ; tests `#[sqlx::test(migrations = "../../migrations")]` : création, cycle refusé (app ET trigger), suppression avec enfants/références refusée (RESTRICT). Dépend de T002, T003. (1 j)
- [ ] T006 Paramètres : `backend/crates/zones/src/parametre.rs` — `PgZones::definir_parametre` avec validation par namespace (registre data-model §4 : devise, drapeau.*, transport.actifs, categorie.*.seuil_activation/mixable, texte.*, client.*, namespaces libres acceptés) + événement outbox `zone.parametre_modifie` (avant/après/acteur) via `socle::ecrire_evenement` dans la MÊME transaction ; tests : validation par clé, rollback → aucun événement. Dépend de T002, T003, T004. (1 j)

**Checkpoint**: schéma appliqué, écritures de domaine testées — les stories peuvent démarrer

---

## Phase 3: User Story 1 — Arbre de zones et résolution de configuration héritée (ZON-01, P1) 🎯 MVP

**Goal**: la résolution parent → enfant avec surcharge au paramètre près, exposée comme trait consommé par TOUS les modules suivants (FR-006..009)

**Independent Test**: seeds exécutés + arbre de test ≥ 3 niveaux avec surcharges partielles → chaque paramètre résolu vaut la valeur de l'ancêtre le plus proche qui le définit, ou une absence explicite (spec US1)

- [ ] T007 [US1] Résolution : `backend/crates/zones/src/resolution.rs` — trait `ConfigurationZones` (signature research R2) + implémentation `PgZones` : CTE récursive de chaîne d'ancêtres, fusion en Rust avec provenance, `configuration_effective()`, `parametre()` (None = absent explicite), `devise()` (erreur `DeviseIrresolvable` si non résolue — FR-010), `drapeau()` ; exports lib.rs. Dépend de T005, T006. (1 j)
- [ ] T008 [US1] Tests d'intégration EXHAUSTIFS de la résolution (FR-008, SC-001, SC-006 — OBLIGATOIRES) dans `backend/crates/zones/tests/resolution.rs` : matrice {sans surcharge, partielle, totale} × ≥ 3 niveaux, niveau intermédiaire vide transparent, paramètre absent partout → absence explicite, valeur définie à `false`/`""` ≠ absente, devise héritée / irrésolvable, paramètre fictif inconnu défini puis résolu de bout en bout (SC-006), re-parentage → nouvelle résolution. Dépend de T007. (1 j)
- [ ] T009 [P] [US1] Seeds Tiassalé : `backend/seeds/10_zones_tiassale.sql` (data-model §6 — UUID FIXES, `ON CONFLICT DO UPDATE` partout : CI + Tiassalé, devise et mixable au niveau pays, drapeaux/seuils/transport.actifs au niveau ville, 8 types de transport, 6 catégories avec workflow/politique photo/véhicule minimal, 6 activations `automatique`+`actif_auto=false`) ; test d'idempotence double seed → état strictement identique (SC-008) à côté de `seed_idempotent` existant. Dépend de T002. (1 j)

**Checkpoint**: US1 livrable seule — le trait de résolution est consommable et prouvé

---

## Phase 4: User Story 2 — Catégories activables par configuration (ZON-02, P2)

**Goal**: catégories = enregistrements ; activation automatique au seuil, forçage admin prioritaire à 3 états, événements outbox (FR-012..016)

**Independent Test**: seeds vérifiés (6 catégories, seuils, mixable) ; simulation d'agréments jusqu'au seuil → activation auto ; forçage dans les deux sens → prioritaire (spec US2)

- [ ] T010 [US2] Domaine activation : `backend/crates/zones/src/categorie.rs` — `PgZones::recalculer_activation(tx, ville, categorie, nb_vendeurs_agrees)` (règle R6 : `actif_auto := actif_auto OR nb ≥ seuil résolu` ; seuil absent → inerte ; JAMAIS de désactivation auto — FR-015), `PgZones::forcer_categorie` (3 états), `categories_actives()` du trait (slug, nom_cle, mixable résolu) ; événements `categorie.forcage_change` (toujours) + `categorie.activation_changee` (si l'état EFFECTIF bascule) dans la MÊME transaction. Dépend de T007 (seuil résolu par héritage). (1 j)
- [ ] T011 [P] [US2] Tests d'intégration des TRANSITIONS (OBLIGATOIRES — data-model §3) dans `backend/crates/zones/tests/activation.rs` : franchissement du seuil → activation + événement ; seuil−1 → rien ; repli sous le seuil → reste active ; forcé inactif au-dessus du seuil / forcé actif en dessous ; retour à `automatique` réapplique la règle ; seuil non défini → pas d'auto, forçage possible ; rollback → aucun événement ; payloads conformes à la taxonomie. Dépend de T010. (1 j)
- [ ] T012 [US2] Endpoint forçage (SEULE écriture admin du cycle — clarification Q2) : extracteur `AdminAuth` (en-tête `X-Admin-Token`, comparaison à temps constant, `ADMIN_API_TOKEN` documenté dans `infra/.env.example` — R5) + handler `PUT /admin/zones/{zone_id}/categories/{categorie_slug}/forcage` dans `backend/api/src/zones_http.rs` conforme à `contracts/openapi-zones.yaml` (200 EtatCategorie / 401 / 404 / 422, erreurs `message_cle` i18n fr) + enregistrement dans `backend/api/src/lib.rs` ; tests Actix 200/401/404/422. SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff `openapi.json` + `clients/` commité. Dépend de T010, T001. (1 j)

**Checkpoint**: US1 + US2 fonctionnelles — activation pilotable et journalisée

---

## Phase 5: User Story 3 — Référentiel des types de transport (ZON-03, P3)

**Goal**: référentiel extensible de 8 types, activation par zone via la configuration héritée (FR-017)

**Independent Test**: seeds → 8 types au référentiel, `transports_actifs` de Tiassalé = [a_pied, velo, moto] ; activation posée sur un parent héritée par les descendantes, surcharge locale prioritaire (spec US3)

- [ ] T013 [P] [US3] `transports_actifs()` du trait dans `backend/crates/zones/src/resolution.rs` (lecture de `transport.actifs` résolu) + validation des slugs contre `zones.type_transport` dans `definir_parametre` (`backend/crates/zones/src/parametre.rs`) ; tests dans `backend/crates/zones/tests/transport.rs` : seed Tiassalé = 3 slugs, héritage depuis un parent, surcharge locale en bloc, slug inconnu refusé (`ValeurInvalide`), ajout d'un 9e type = INSERT seul (SC — aucune modification structurelle). Dépend de T007, T009. (½ j)

**Checkpoint**: US1 + US2 + US3 — toutes les lectures du trait sont en place

---

## Phase 6: User Story 4 — Configuration produit distante (ZON-04, P4)

**Goal**: `GET /config?zone=` public versionné (liste blanche R4, empreinte R3) + cache/rafraîchissement côté apps (FR-018..021)

**Independent Test**: `/config` de Tiassalé restitue SC-003 en une consultation ; changement sur un ancêtre → nouvelle version ; app hors ligne au démarrage → dernière config en cache (spec US4)

- [ ] T014 [US4] Assemblage du document public : `backend/crates/zones/src/config_publique.rs` — construction depuis `ConfigurationEffective` avec LISTE BLANCHE de namespaces (devise, drapeau.*, texte.*, client.* + vues `categories` actives et `transports_actifs` — R4, `dispatch.*` ne sort JAMAIS) + `version` = SHA-256 du JSON canonique (clés triées, R3) ; tests : déterminisme (2 appels = même version), changement d'un paramètre PARENT → version change (FR-019), paramètre interne absent du document. Dépend de T007, T010, T013. (1 j)
- [ ] T015 [US4] Endpoint public : handler `GET /config?zone=` dans `backend/api/src/zones_http.rs` conforme à `contracts/openapi-zones.yaml` (200 + ETag / 304 If-None-Match / 400 / 404 explicite — FR-021 / 429) + rate-limit `actix-governor` par IP ; tests Actix : SC-003 exact sur seeds (devise XOF/0, 3 drapeaux, 3 transports, categories=[] sans vendeurs), 404, 304, 429, liste blanche. SE TERMINE PAR : annotations utoipa à jour → `./scripts/generate-clients.sh` → build vert, diff `openapi.json` + `clients/` commité. Dépend de T014, T009, T001. (1 j)
- [ ] T016 [US4] Module config de `mefali_core` : `apps/packages/mefali_core/lib/src/config/` — service consommant le client Dart GÉNÉRÉ (`mefali_api_client`, dépendance path + `shared_preferences` dernière stable dans `apps/packages/mefali_core/pubspec.yaml`) derrière une interface injectable ; cache local, chargement au démarrage, `Timer.periodic` horaire, comparaison de `version`, constante zone bootstrap Tiassalé `01900000-0000-7000-8000-000000000002` (R7) ; tests `fake_async` dans `apps/packages/mefali_core/test/config/` : hors-ligne → cache (SC-007), refresh horaire, nouvelle version remplace le cache. AUCUN écran (pas de référence design requise). Dépend de T015 (client régénéré avec /config). (1 j)
- [ ] T017 [US4] Branchement des apps : initialiser le service config au démarrage de `apps/mefali_client/lib/main.dart` et `apps/mefali_pro/lib/main.dart` (aucun écran nouveau — spec Assumptions) ; `flutter analyze` + `flutter test` verts dans les 2 apps. Dépend de T016. (½ j)

**Checkpoint**: toutes les stories fonctionnelles de bout en bout

---

## Phase 7: Polish & validation finale

- [ ] T018 Passe complète de `specs/002-zones-config-heritee/quickstart.md` sur environnement dev (docker compose) : SC-001 → SC-008, double seed, forçage curl + événements outbox constatés, `./scripts/generate-clients.sh` puis `git status --porcelain` vide (CI contrat-clients). Dépend de toutes les stories. (½ j)
- [ ] T019 Revue Definition of Done (`docs/user-stories-v2.md` §0.4 — DERNIÈRE tâche, demande utilisateur) : (1) critères d'acceptation ZON-01→04 couverts par tests unitaires + intégration sur transitions ; (2) annotations utoipa à jour, clients Dart/TS régénérés SANS diff manuel ; (3) migration `0002_zones.sql` versionnée + seeds à jour ; (4) événements outbox pour chaque changement d'état + taxonomie MET (aucun parcours utilisateur ce cycle → pas d'événement métrique app) ; (5) clés i18n fr externalisées (`nom_cle`, `message_cle`) ; (6) paramètres « paramétrables » en configuration de zone — AUCUNE constante en dur ; puis re-passer `specs/002-zones-config-heritee/checklists/requirements.md`, `cargo test` + `cargo sqlx prepare` verts, commits conventionnels `feat(zones): ZON-0x …`. Dépend de T018. (½ j)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** : immédiat. **Foundational (P2)** : T002 d'abord ; T003/T004 en parallèle ; T005, T006 ensuite — BLOQUE toutes les stories.
- **US1 (P3)** : après T005+T006. **US2 (P4)** et **US3 (P5)** : après T007 (la résolution est la colonne vertébrale — dépendance assumée, spec « priorités = ordre de livraison interne »). **US4 (P6)** : après US1+US2+US3 (le document public agrège leurs lectures). **Polish (P7)** : après tout.

### Chaîne critique

T002 → T005/T006 → T007 → T010 → T014 → T015 → T016 → T017 → T018 → T019

### Parallel Opportunities

- T003 ∥ T004 (pendant T002 pour T004 — fichiers distincts)
- T008 ∥ T009 (tests résolution ∥ seeds)
- T011 ∥ T012 (tests transitions ∥ endpoint forçage) ; T013 ∥ Phase 4 entière (ne dépend que de T007+T009)

---

## Implementation Strategy

**MVP = Phases 1+2+3 (T001→T009)** : le trait `ConfigurationZones` testé exhaustivement + seeds — c'est la brique que CPT/VND/TRF attendent ; livrable et démontrable seul (quickstart §1). Ensuite incréments indépendants : US2 (activation pilotable), US3 (transports), US4 (config servie aux apps), chacun validable à son checkpoint. Développeur solo : suivre l'ordre T001→T019 ; commits par tâche ou groupe logique.

## Notes

- Aucune tâche UI ce cycle → aucune capture `docs/design/png/` référencée (écrans admin au cycle ADM, tranche T3 — clarification Q2 de la spec).
- PROVISION respectée : `village`/`quartier` n'apparaissent que dans l'énum de T002 et un test de T008 (création par données) — aucune tâche d'écran ni de logique dédiée (constitution IX).
- Conventions de code : identifiants français du socle 001 (research R10).
