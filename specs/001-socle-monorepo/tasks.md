# Tasks: Socle technique du monorepo Mefali

**Input**: Design documents from `/specs/001-socle-monorepo/`

**Prerequisites**: plan.md, spec.md, research.md (versions figées), data-model.md, contracts/, quickstart.md

**Tests**: constitution VII — les transitions du cycle de vie outbox reçoivent des tests d'intégration OBLIGATOIRES (T1–T3 du plan) ; tout changement SQL inclut `cargo sqlx prepare`.

**Organization**: tâches groupées par user story (US1–US7 de spec.md), ordonnées par dépendance. Calibrage demandé : ½ journée à 1 journée par tâche.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1–US7 (phases de story uniquement)

## Règles transverses (s'appliquent à toutes les tâches concernées)

1. **Toute tâche qui touche l'API se termine par** : annotations utoipa à jour → `scripts/generate-clients.sh` (openapi.json + clients Dart/TS régénérés, commités) → build vert.
2. **Toute tâche qui touche le schéma commence par** sa NOUVELLE migration sqlx (`backend/migrations/`) puis finit par `cargo sqlx prepare` (jamais de modification d'une migration appliquée).
3. **Toute tâche d'UI référence sa cible design** : capture `docs/design/png/` correspondante quand elle existe ; sinon `docs/design/tokens.md` (+ `docs/design/Mefali_DESIGN.md` §10) fait foi. Jamais de transposition DOM/CSS de `docs/design/html/` en Flutter (exception : admin Nuxt).
4. Toute chaîne utilisateur → clés i18n fr. Aucun paramètre métier en dur (aucun attendu ce cycle).
5. Versions : exclusivement celles de `research.md` — lockfiles commités à chaque tâche qui en crée un.

---

## Phase 1: Setup

**Purpose**: vérification design (première tâche obligatoire de la spec) et racine du monorepo

- [X] T001 Vérifier `docs/design/tokens.md` complet et exploitable (FR-001, PREMIÈRE tâche) : hex couleurs (14 tokens), échelle typo (5 niveaux), espacements (grille 8px), rayons (16/12/999), élévation, cibles tactiles — croiser avec `docs/design/html/*.html` ; compléter `docs/design/tokens.md` si une valeur manque ; toute valeur absente des deux sources est signalée pour arbitrage (jamais inventée). Livrable : tokens.md confirmé/complété + note de vérification dans le commit.
- [X] T002 Créer la racine du monorepo : `.gitignore` (Rust, Flutter, Node, .env), `README.md` (prérequis quickstart), `rust-toolchain.toml` (1.97.0), dossiers `backend/ apps/ clients/ web/ infra/ scripts/ .github/workflows/`, emplacements hors périmètre `infra/shorebird/README.md` (TRX-06, T4) et `infra/artci/README.md` (TRX-07, P1) — READMEs d'un paragraphe, aucune logique (FR-008).

---

## Phase 2: Foundational (bloquant pour toutes les stories)

**Purpose**: environnement conteneurisé + workspace Rust compilable — rien d'autre ne peut avancer sans

- [X] T003 Écrire `infra/docker-compose.yml` (dev) : `postgres:18.4`, `redis:8.8.0-alpine`, Garage v2.3.0 **épinglé par digest** avec `infra/garage/garage.toml` (`replication_mode = 1`) + `infra/garage/init.sh` (layout mono-nœud assigné explicitement, création buckets, 2 clés d'accès : backend / backup) ; volumes nommés ; `infra/.env.example` (contrat data-model.md §4, sans valeurs). Validation : `docker compose up -d` → Postgres/Redis/Garage healthy, `aws s3 ls --endpoint` sur Garage OK.
- [X] T004 Ajouter OSRM au compose : `infra/osrm/prepare.sh` (téléchargement `https://download.geofabrik.de/africa/ivory-coast-latest.osm.pbf` ~80 Mo, `osrm-extract` profil car, `osrm-partition`, `osrm-customize`) + service `ghcr.io/project-osrm/osrm-backend:v26.7.3` (`osrm-routed --algorithm mld`). Contrainte edge case spec : l'échec OSRM ne bloque PAS le démarrage des autres services (pas de `depends_on` vers OSRM).
- [X] T005 Créer le workspace Rust : `backend/Cargo.toml` (workspace resolver 2, dépendances partagées research.md R1), 12 crates de domaine VIDES compilables `backend/crates/{zones,comptes,prestataires,qr,tarification,commandes,dispatch,coursier,paiements,notifications,avis,metriques}/` (Cargo.toml + lib.rs), crate `backend/crates/socle/` (vide à ce stade), binaire `backend/api/` (main.rs actix minimal qui démarre), `Cargo.lock` commité. Validation : `cargo build` + `cargo test` verts.
- [X] T006 Implémenter le tronc du crate `socle` : `Config` (crate config 0.15.25 + variables data-model.md §4), helper `PgPool`, `backend/sqlx.toml` (preferred-crates = chrono — note sqlx 0.9 de research.md R1), harnais migrations (`cargo sqlx migrate run` opérationnel, répertoire `backend/migrations/` vide), installation `sqlx-cli 0.9.0` documentée dans `README.md` (sans `--locked`).
- [X] T007 [P] Définir le trait `ServiceWorkflow` dans `backend/crates/commandes/src/lib.rs` : `EtatCommande`, `EtatIntermediaire`, `ContexteWorkflow`, `AjustementTarif` (entiers unités mineures + ISO 4217), `WorkflowError` — signature de `contracts/service-workflow.md`, AUCUNE implémentation, rien de logistique. Validation : `cargo build -p commandes` vert + doc rustdoc sur chaque item.

**Checkpoint**: env dev démarré en 1 commande ; workspace 14 membres compile.

---

## Phase 3: User Story 1 — Monorepo compilable et environnement de développement (P1) 🎯 MVP

**Goal**: arborescence complète, thème M3 depuis les tokens, apps + web compilables, versions figées.

**Independent Test**: quickstart S1/S2/S9 — poste avec prérequis → env complet < 30 min, apps affichent l'écran de démarrage thémé, lockfiles présents.

- [X] T008 [US1] Créer `apps/packages/mefali_core/` : package Flutter (Dart 3.12.2), embarquer Inter v4.1 (.ttf du zip officiel rsms/inter + licence OFL dans `apps/packages/mefali_core/assets/fonts/`), dépendance `material_symbols_icons: 4.2951.0` (variante Rounded par défaut), dossiers réservés VIDES `lib/src/components/` et `lib/src/offline/` (constitution IX), `pubspec.lock` commité.
- [X] T009 [US1] Implémenter `lib/src/theme/tokens.dart` + `lib/src/theme/mefali_theme.dart` dans `apps/packages/mefali_core/` : constantes 1:1 depuis `docs/design/tokens.md` (14 couleurs, échelle typo 40/22/18/16/13, espacements 4–32, rayons 16/12/999, élévation unique, tap ≥ 48, bouton 56) ; `MefaliTheme.light` = `ColorScheme.fromSeed(#F97316)` AJUSTÉ aux tokens + TextTheme Inter + shapes ; conventions `.adaptive` documentées (DESIGN §10) ; pas de mode sombre. Tests widget : thème reflète les tokens (plan T7). **Cible design : docs/design/tokens.md — pas de capture dédiée ; interdiction de transposer docs/design/html/.**
- [X] T010 [P] [US1] Créer `apps/mefali_client/` : app Flutter branchée sur `MefaliTheme`, écran de démarrage thémé (nom + pictogramme Material Symbols Rounded), chaînes en clés i18n fr (`lib/l10n/app_fr.arb`, intl 0.20.3), `pubspec.lock` commité, test golden de l'écran. **Cible design : identité docs/design/tokens.md (cadre mobile 360×800) — aucune capture png dédiée au démarrage ; C1-accueil.png = ambiance de référence, pas la cible de cet écran.**
- [X] T011 [P] [US1] Créer `apps/mefali_pro/` : identique à T010 pour l'app pro (coursier + vendeur), test golden. **Cible design : idem T010 ; K1-disponibilite.png = ambiance de référence pro.**
- [X] T012 [P] [US1] Créer `web/` : Nuxt 4.4.8 (pnpm 11, Node 24 LTS), `nuxt.config.ts` avec `routeRules: {'/admin/**': {ssr: false}}`, `@nuxtjs/i18n` 10.4.1 (fr), `web/app/assets/tokens.css` (variables 1:1 depuis `docs/design/tokens.md`), pages minimales `web/app/pages/index.vue` (SSR) et `web/app/pages/admin/index.vue`, `@nuxt/eslint` + vitest, `pnpm-lock.yaml` commité. AUCUNE bibliothèque UI (choix différé, research.md R4). **Cible design : tokens.css depuis tokens.md ; pour la page admin minimale, docs/design/html/A1-ecran-operations.html peut inspirer la structure (exception admin Nuxt) et docs/design/png/A1-ecran-operations.png reste la cible visuelle ultérieure.**
- [ ] T013 [US1] Valider US1 : dérouler quickstart S1/S2/S9 sur poste chronométré (< 30 min, SC-001), vérifier les 6 lockfiles (`Cargo.lock`, `pubspec.lock` ×3, `pnpm-lock.yaml`, `rust-toolchain.toml`) + versions = research.md, compléter `README.md` racine (prérequis, commandes). Rejeu `grep` : zéro valeur de style en dur dans `apps/` hors mefali_core (SC-009).

**Checkpoint**: US1 démontrable — monorepo compilable, env 1 commande, thème prouvé.

---

## Phase 4: User Story 2 — Contrat d'API et clients générés (TRX-01, P2)

**Goal**: openapi.json généré (≥ /health), clients Dart/TS dérivés, CI en échec sur diff.

**Independent Test**: quickstart S3 — contrat servi, régénération 2× sans diff, CI rouge sur diff simulé.

- [X] T014 [US2] Implémenter `GET /health` dans `backend/api/src/` : `HealthResponse {status, version}` (`ToSchema`) dans `backend/crates/socle/`, handler `#[utoipa::path]`, montage via `utoipa-actix-web 0.1.2`, export `openapi.json` À LA RACINE (commande `cargo run -p api --bin export-openapi` ou test dédié), Swagger UI `utoipa-swagger-ui 9.0.2` servie en dev et ABSENTE si `APP_ENV=production` + test d'intégration (plan T4, T9 ; contrat `contracts/openapi-health.yaml`). **Fin de tâche : annotations utoipa à jour + openapi.json régénéré/commité + build vert.**
- [ ] T015 [US2] Écrire `scripts/generate-clients.sh` : openapi-generator CLI 7.23.0 (générateur `dart-dio`, `hideGenerationTimestamp: true`) → `clients/dart/` ; openapi-typescript 7.13.0 + openapi-fetch 0.17.0 → `clients/ts/` ; exécution 2× consécutives = `git diff` vide (déterminisme, plan T5) ; clients commités ; prérequis Java ≥ 11 documenté dans `README.md`. **Fin de tâche : clients régénérés + build vert.**
- [ ] T016 [US2] Créer `.github/workflows/contrat-clients.yml` : déclencheurs `paths: [backend/**, clients/**, openapi.json]` + PR/push ; job = build backend → export openapi.json → `scripts/generate-clients.sh` → `git diff --exit-code` (contrat `contracts/ci-cd.md`, règle 1 et 2). Validation : PR de test avec diff simulé → CI rouge (SC-004) ; PR propre → verte.

**Checkpoint**: contrat = source de vérité outillée ; dérive impossible à fusionner.

---

## Phase 5: User Story 3 — Journal d'événements métier, outbox (TRX-02, P3)

**Goal**: écriture transactionnelle, worker at-least-once, consommateurs idempotents.

**Independent Test**: quickstart S4 — `cargo test -p socle --test outbox` couvre commit/rollback/publication/rejeu/échec.

- [X] T017 [US3] **Commencer par la migration** : créer `backend/migrations/0001_outbox.sql` (schéma `outbox`, table `outbox.evenement` conforme data-model.md §1, index partiel `WHERE publie_le IS NULL`) ; `cargo sqlx migrate run` ; **finir par `cargo sqlx prepare`** (nouveau format 0.9, commité).
- [X] T018 [US3] Implémenter l'écriture dans `backend/crates/socle/src/outbox/` : `NouvelEvenement`, `EvenementPublie`, `ecrire_evenement(&mut PgTransaction, …)` (uuid v7, chrono — contrat `contracts/outbox.md`) + tests d'intégration OBLIGATOIRES sur Postgres réel : commit → présent, rollback → absent (plan T1). `cargo sqlx prepare` en fin de tâche.
- [X] T019 [US3] Implémenter `WorkerOutbox` + `trait ConsommateurOutbox` dans `backend/crates/socle/src/outbox/` : lots `FOR UPDATE SKIP LOCKED`, marquage `publie_le`, `tentatives`/`derniere_erreur`, consommateur de test en mémoire ; démarrage du worker comme tâche tokio dans `backend/api/src/main.rs` ; tests d'intégration OBLIGATOIRES : publication, rejeu idempotent (zéro double effet), échec → reprise (plan T2/T3). `cargo sqlx prepare` en fin de tâche.
- [X] T020 [P] [US3] Créer `docs/taxonomie-evenements.md` : conventions de nommage (`<entite>.<action>`), propriétés standard (zone, catégorie, rôle, version d'app — cadrage §10.9), registre vide + `socle.ping` documenté comme événement technique de test (résout le TODO de la constitution, principe VI).

**Checkpoint**: chaque flèche du cycle de vie outbox testée — prérequis de toute story métier de T1.

---

## Phase 6: User Story 4 — Observabilité (TRX-03, P4)

**Goal**: logs corrélés, Sentry, sonde uptime + alerte > 2 min.

**Independent Test**: quickstart S5 — logs JSON corrélés, erreur visible dans Sentry, alerte reçue après coupure.

- [ ] T021 [US4] Implémenter la télémétrie dans `backend/crates/socle/src/telemetry.rs` : tracing-subscriber 0.3.23 (JSON, stdout) + tracing-actix-web 0.7.22 (request id de corrélation), init sentry 0.48.4 + sentry-actix (lockstep, activé si `SENTRY_DSN`) ; intégration `backend/api/src/main.rs` ; test d'intégration : une requête `/health` produit des logs corrélés ; compte Sentry (plan Developer gratuit) créé, DSN en `.env` (jamais commité).
- [ ] T022 [US4] Brancher les sondes sur `/health` de la PROD (dépend de T028/US7) : cron-job.org (1×/min, alerte email échec/rétablissement → détection < 2 min) + Better Stack free (email + push, status page) ; documenter dans `infra/README.md` le test réel : arrêt du service > 2 min → alerte reçue (SC-006), redémarrage → rétablissement notifié.

**Checkpoint**: US4 complet en local après T021 ; en conditions réelles après T022 (post-US7).

---

## Phase 7: User Story 5 — Sauvegardes (TRX-04, P5)

**Goal**: pg_dump quotidien chiffré → B2, sync Garage→B2, restauration testée et documentée.

**Independent Test**: quickstart S6 — `backup.sh` puis `restore-test.sh` verts en local ; cron en prod après US7.

- [ ] T023 [US5] Créer `infra/backups/backup.sh` : `pg_dump | age -r $BACKUP_AGE_RECIPIENT` (age v1.3.1) → bucket Backblaze B2 (object lock + lifecycle 30 j côté B2), sync `rclone` Garage→B2 (clé Garage dédiée backup), rotation 30 jours glissants ; bucket B2 créé et configuré ; clé PRIVÉE age générée et conservée HORS VPS (gestionnaire de mots de passe + copie hors-ligne) ; variables `BACKUP_*` dans `infra/.env.example`. Testable en local contre le compose dev.
- [ ] T024 [US5] Créer `infra/backups/restore-test.sh` (restauration de l'archive chiffrée dans un Postgres jetable + vérification du schéma — plan T8, automatisable en local) + `infra/backups/README.md` : procédure de restauration COMPLÈTE pas à pas (récupération B2, déchiffrement age avec gestion de la clé, restore, bascule), planification quotidienne sur le VPS (systemd timer — l'activation effective dépend de T028/US7). Rappel spec : restauration réelle déroulée et documentée AVANT la bêta.

**Checkpoint**: perte maximale bornée à 24 h ; procédure prouvée en local, planifiée en prod.

---

## Phase 8: User Story 6 — Seeds & démo (TRX-05, P6)

**Goal**: mécanisme de seed rechargeable en 1 commande (< 5 min), idempotent.

**Independent Test**: quickstart S7 — seed sur base vierge puis re-seed → état identique, zéro doublon.

- [ ] T025 [US6] Créer `backend/seeds/` (README expliquant l'ordre `NN_<module>.sql` et la complétion par les cycles ZON/CPT/VND/TRF, `00_demo_marker.sql`) + binaire `backend/api/src/bin/seed.rs` : UNE transaction, remise à zéro des tables seedées puis rejeu ordonné (idempotent par construction, rollback si interruption — data-model.md §3) ; test d'intégration : double exécution → état identique (plan T6) ; chrono < 5 min (SC-008). `cargo sqlx prepare` en fin de tâche.

**Checkpoint**: la démo se recharge en 1 commande ; les cycles suivants ne feront qu'ajouter des fichiers SQL.

---

## Phase 9: User Story 7 — Déploiement production minimal (P7) — garde-fou ≤ 2 jours

**Goal**: UN VPS, compose en prod, GitHub Action sur main (SSH : pull + compose up), secrets hors Git.

**Independent Test**: quickstart S8 — push sur main → prod reflète le commit < 15 min ; /health public ; Swagger absente ; zéro secret dans le dépôt.

**⚠ Garde-fou (spec, clarification 2026-07-13)** : si T026+T027+T028 dépassent 2 jours en exécution, dégrader — garder T026 (VPS provisionné), sortir T028 du cycle (déploiement différé), T022/T024-prod suivent.

- [ ] T026 [US7] Écrire `infra/vps/provision.sh` (Docker Engine 29 + compose v5, utilisateur deploy, UFW 22/80/443, dossiers `/srv/mefali` + `.env` hors Git) et `infra/vps/compose.prod.yml` (backend image GHCR, `postgres:18.4`, `redis:8.8.0-alpine`, Garage par digest + init, OSRM v26.7.3, Caddy 2 par digest pour TLS auto) ; provisionner le VPS réel, DNS du domaine API, exécuter le script. Livrable : `curl https://<domaine>/health` (déploiement manuel initial).
- [ ] T027 [P] [US7] Écrire `backend/Dockerfile` : multi-stage avec cargo-chef 0.1.77, binaire `api` + `seed`, image minimale (debian-slim), build local vert et image < 150 Mo. Parallélisable avec T026 (fichiers disjoints).
- [ ] T028 [US7] Créer `.github/workflows/deploy.yml` : sur `main` après CI verte → docker/build-push-action@v7 + docker/login-action@v4 → GHCR → appleboy/ssh-action@v1 (pull + `docker compose -f compose.prod.yml up -d`) ; secrets GitHub (clé SSH, hôte) ; charger les seeds en prod (`docker compose exec api seed`) ; valider SC-011 (merge → prod < 15 min) + scénario US7-3 (audit zéro secret : `git grep` + revue `.env.example`).

**Checkpoint**: prod = seul environnement, reflet de `main`, seeds chargés — TRX-03/04 vérifiables en réel (T022, cron T024).

---

## Phase 10: Polish & transverse

**Purpose**: CI par chemins restante, validation de bout en bout, revue finale

- [ ] T029 [P] Créer `.github/workflows/backend.yml` : `paths: [backend/**, openapi.json]` ; jobs `cargo fmt --check`, `clippy -D warnings`, `cargo test` + `cargo sqlx prepare --check` (service `postgres:18.4`) ; runner épinglé `ubuntu-24.04`, actions versions research.md R6.
- [ ] T030 [P] Créer `.github/workflows/apps.yml` : `paths: [apps/**, clients/dart/**]` ; `flutter analyze` + `flutter test` sur mefali_core, mefali_client, mefali_pro (subosito/flutter-action@v2, Flutter 3.44.6 épinglé).
- [ ] T031 [P] Créer `.github/workflows/web.yml` : `paths: [web/**, clients/ts/**]` ; lint (@nuxt/eslint), typecheck, `pnpm build`, vitest (pnpm/action-setup@v6, Node 24).
- [ ] T032 Dérouler la validation complète quickstart S1→S9 + vérifier chaque Success Criterion SC-001→SC-011 de `specs/001-socle-monorepo/spec.md` ; corriger ce qui échoue ; consigner les résultats (durées mesurées) dans `specs/001-socle-monorepo/quickstart.md` (section résultats).
- [ ] T033 Revue **Definition of Done** (`docs/user-stories-v2.md` §0.4, DERNIÈRE tâche) : 1) critères TRX-01→05 couverts par les tests listés au plan (T1–T9) ; 2) annotations utoipa à jour + clients régénérés SANS diff ; 3) migration 0001 versionnée + seeds à jour ; 4) événements outbox : `socle.ping` seul, taxonomie créée ; 5) clés i18n fr partout (apps + web) ; 6) aucun paramètre « paramétrable » introduit (aucune config de zone attendue ce cycle) ; + vérifier que l'amendement constitution MinIO→Garage (principes II & X) a été passé via `/speckit.constitution`, sinon le signaler comme bloquant de commit final.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** : T001 d'abord (obligation de spec), T002 ensuite ou en parallèle.
- **Foundational (P2)** : T003 → T004 ; T005 → T006/T007 ; bloque toutes les stories.
- **US1** : T008 → T009 (dépend aussi de T001) → T010/T011/T012 [P] → T013.
- **US2** : T014 (dépend T005/T006) → T015 → T016.
- **US3** : T017 (dépend T003/T006) → T018 → T019 ; T020 [P] à tout moment.
- **US4** : T021 (dépend T014) ; T022 dépend de T028 → en pratique après US7.
- **US5** : T023 (dépend T003) → T024 ; activation cron en prod après US7.
- **US6** : T025 (dépend T006, T017).
- **US7** : T026 et T027 [P] (T027 dépend T005) → T028 (dépend T016, T026, T027).
- **Polish** : T029/T030/T031 [P] dès que leur composant existe ; T032 après toutes les stories ; **T033 en dernier**.

### Chemin critique

T001 → T002 → T003 → T005 → T006 → T014 → T015 → T016 → T028 → T022/T032 → T033.

### Parallel Opportunities

```text
# Après T005/T006 (fondations backend) :
US2 (T014…) ∥ US3 (T017…) ∥ T007 ∥ T027
# Après T009 (thème) :
T010 ∥ T011 ∥ T012
# À tout moment après leur composant :
T020 ∥ T029 ∥ T030 ∥ T031
# US5 (T023) ∥ US6 (T025) après fondations.
```

---

## Implementation Strategy

**MVP d'abord (US1)** : Setup → Foundational → US1 → checkpoint quickstart S1/S2/S9. À ce stade le monorepo est démontrable et chaque cycle suivant peut démarrer.

**Livraison incrémentale** : US2 (contrat outillé) puis US3 (outbox) sont les deux verrous des stories métier de T1 — les livrer avant tout le reste. US5/US6 sont indépendantes et parallélisables. US7 en avant-dernier (1,5–2 j estimés, garde-fou actif), puis T022/T024-prod, T032, T033.

**Développeur solo** : suivre l'ordre du chemin critique ; utiliser les fenêtres [P] quand une tâche attend (téléchargement OSM, provisioning VPS, DNS).

---

## Notes

- 33 tâches, calibrées ½ j – 1 j ; le lot US7 (T026–T028) porte le garde-fou 2 jours de la spec.
- `clients/dart/` et `clients/ts/` ne sont JAMAIS édités à la main — uniquement régénérés (T015/T016).
- Committer après chaque tâche (message conventionnel référençant la story, ex. `feat(socle): TRX-02 outbox worker …`).
- Chaque checkpoint de story est un point d'arrêt valide pour valider indépendamment.
