# Quickstart — validation du socle (001-socle-monorepo)

Guide de validation de bout en bout. Chaque scénario prouve une story de la
spec ; les détails d'interface sont dans `contracts/` et `data-model.md`.

## Prérequis (poste dev)

- Docker Desktop (compose v2), Rust stable (via `rustup`, version épinglée par
  `rust-toolchain.toml`), Flutter stable (version épinglée), Node LTS + pnpm,
  Java ≥ 11 (openapi-generator CLI), `sqlx-cli`.
- Versions exactes : voir `research.md` (constitution X — figées par lockfiles).

## S1 — Environnement local et compilation (US1, SC-001 : < 30 min)

```bash
docker compose -f infra/docker-compose.yml up -d   # Postgres, Redis, Garage (init layout + buckets), OSRM (extrait OSM CI)
docker compose -f infra/docker-compose.yml ps      # attendu : 4 services healthy

cd backend && cargo sqlx migrate run && cargo build && cargo test
cd apps/mefali_client && flutter test && cd ../mefali_pro && flutter test
cd apps/packages/mefali_core && flutter test
cd web && pnpm install --frozen-lockfile && pnpm build
```

Attendu : tout compile et passe ; les 12 crates de domaine vides compilent ;
le trait `ServiceWorkflow` compile sans implémentation. OSRM indisponible ne
bloque ni compilation ni tests (edge case de la spec).

## S2 — Thème depuis les tokens (US1, SC-009)

```bash
cd apps/mefali_client && flutter run   # idem mefali_pro
```

Attendu : écran de démarrage thémé — primaire `#F97316`, police Inter, icônes
Material Symbols Rounded. Vérification : les tests widget de `mefali_core`
affirment que le `ThemeData` reflète `docs/design/tokens.md` (couleurs, échelle
typo, rayons) ; aucune valeur de style en dur dans `apps/`.

## S3 — Contrat et clients générés (US2, SC-003/SC-004)

```bash
./scripts/generate-clients.sh          # regénère openapi.json + clients/dart + clients/ts
git diff --exit-code                   # attendu : aucun diff (déterminisme)
curl -s localhost:8080/health          # {"status":"ok","version":"..."}
curl -s localhost:8080/api-docs/openapi.json | jq '.paths | keys'   # contient "/health"
```

Contre-épreuve CI : modifier une annotation utoipa sans régénérer → le job
`contrat-clients` échoue (voir `contracts/ci-cd.md`).

## S4 — Outbox (US3, SC-005)

```bash
cd backend && cargo test -p socle --test outbox
```

Attendu (tests d'intégration, contrat `contracts/outbox.md`) : commit →
événement présent ; rollback → absent ; worker → `publie_le` renseigné ;
rejeu → aucun double effet ; échec consommateur → `tentatives`++ puis reprise.

## S5 — Observabilité (US4, SC-006)

- Logs : chaque requête produit des lignes JSON corrélées (request id).
- Sentry : `panic!` de test en dev avec `SENTRY_DSN` renseigné → événement
  visible dans Sentry.
- Sonde : `/health` de la prod enregistré dans le service uptime (voir
  `research.md`) ; couper le service > 2 min → alerte reçue (test réel
  documenté dans `infra/README`).

## S6 — Sauvegardes (US5, SC-007)

```bash
infra/backups/backup.sh        # pg_dump chiffré (age) + sync Garage → bucket S3 tiers (rclone S3→S3)
infra/backups/restore-test.sh  # restaure l'archive dans un Postgres jetable, vérifie le schéma
```

Attendu : archive chiffrée présente sur le bucket ; restauration complète
verte ; rotation 30 jours appliquée. La restauration RÉELLE (VPS → poste)
est déroulée et documentée avant la bêta.

## S7 — Seeds (US6, SC-008 : 1 commande, < 5 min)

```bash
cargo run -p api --bin seed    # 1re fois : charge ; 2e fois : même état, zéro doublon
```

Ce cycle : structure + runner + marqueur (les données Tiassalé/vendeurs
arrivent avec les schémas des cycles ZON/CPT/VND/TRF — assumption de la spec).

## S8 — Déploiement production (US7, SC-011 : main → prod < 15 min)

```bash
git push origin main
# GitHub Actions : jobs CI verts → build image → GHCR → SSH VPS → compose up
curl -s https://<domaine-prod>/health            # {"status":"ok","version":<commit déployé>}
curl -s -o /dev/null -w '%{http_code}' https://<domaine-prod>/swagger-ui/   # 404 ou 401 (protégée)
git grep -iE '(password|secret|api_key)=' -- ':!*.example'   # aucun secret réel dans le dépôt
```

Garde-fou : si le lot VPS+déploiement dépasse 2 jours de tâches, dégradation
en « VPS provisionné, déploiement différé » (spec, clarification 2026-07-13).

## S9 — Lockfiles (SC-002)

```bash
ls backend/Cargo.lock apps/mefali_client/pubspec.lock apps/mefali_pro/pubspec.lock \
   apps/packages/mefali_core/pubspec.lock web/pnpm-lock.yaml
cat rust-toolchain.toml
```

Attendu : tous présents et commités, versions = celles de `research.md`.
