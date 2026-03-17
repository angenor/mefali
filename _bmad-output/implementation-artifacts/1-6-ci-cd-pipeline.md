# Story 1.6: CI/CD Pipeline

Status: done

## Story

En tant que **developpeur**,
Je veux **des workflows GitHub Actions pour le CI Flutter et Rust**,
Afin que **la qualite du code soit validee automatiquement a chaque push**.

## Criteres d'Acceptation

1. **AC1**: Quand un push est fait sur n'importe quelle branche, le workflow Flutter CI execute `dart pub global run melos run analyze`, `dart pub global run melos run format`, et `dart pub global run melos run test` — et les 3 passent
2. **AC2**: Quand un push est fait sur n'importe quelle branche, le workflow Rust CI execute `cargo clippy --workspace -- -D warnings`, `cargo fmt --all -- --check`, et `cargo test --workspace` — et les 3 passent
3. **AC3**: Les workflows se declenchent aussi sur les pull requests vers `main`
4. **AC4**: Les dependances Dart (pub cache) et Rust (cargo registry + target) sont mises en cache pour accelerer les builds suivants
5. **AC5**: Le fichier `.github/workflows/flutter_ci.yml` existe et contient le pipeline Flutter complet
6. **AC6**: Le fichier `.github/workflows/rust_ci.yml` existe et contient le pipeline Rust complet
7. **AC7**: Les workflows existants passent sur l'etat actuel du code (0 echec sur main)

## Taches / Sous-taches

- [x] **T1** Creer le workflow Flutter CI (AC: #1, #3, #4, #5)
  - [x] T1.1 Creer `.github/workflows/flutter_ci.yml`
  - [x] T1.2 Configurer les triggers : `push` (toutes branches) + `pull_request` (vers main)
  - [x] T1.3 Setup Flutter SDK via `subosito/flutter-action` avec la version `3.41.2` (channel stable)
  - [x] T1.4 Installer melos : `dart pub global activate melos`
  - [x] T1.5 Bootstrap : `dart pub global run melos bootstrap`
  - [x] T1.6 Step Analyze : `dart pub global run melos run analyze`
  - [x] T1.7 Step Format check : `dart pub global run melos run format`
  - [x] T1.8 Step Test : `dart pub global run melos run test`
  - [x] T1.9 Configurer le cache pub (`~/.pub-cache`) via `subosito/flutter-action` cache: true

- [x] **T2** Creer le workflow Rust CI (AC: #2, #3, #4, #6)
  - [x] T2.1 Creer `.github/workflows/rust_ci.yml`
  - [x] T2.2 Configurer les triggers : `push` (toutes branches) + `pull_request` (vers main)
  - [x] T2.3 Setup Rust stable via `dtolnay/rust-toolchain` avec composants `clippy, rustfmt`
  - [x] T2.4 Configurer le cache cargo via `Swatinem/rust-cache` (crate workspace `server/`)
  - [x] T2.5 Step Clippy : `cargo clippy --workspace -- -D warnings` (depuis `server/`)
  - [x] T2.6 Step Format check : `cargo fmt --all -- --check` (depuis `server/`)
  - [x] T2.7 Step Test : `cargo test --workspace` (depuis `server/`)

- [x] **T3** Valider que les workflows passent (AC: #7)
  - [x] T3.1 Verifier que `dart pub global run melos run analyze` passe localement
  - [x] T3.2 Verifier que `cargo clippy --workspace -- -D warnings` passe localement (depuis `server/`)
  - [x] T3.3 Verifier que `cargo fmt --all -- --check` passe localement (depuis `server/`)
  - [x] T3.4 Verifier que `cargo test --workspace` passe localement (depuis `server/`)

## Dev Notes

### Architecture des fichiers — Exactement 2 fichiers a creer

```
.github/
  workflows/
    flutter_ci.yml    # NOUVEAU
    rust_ci.yml       # NOUVEAU
```

Le dossier `.github/workflows/` n'existe PAS encore — il faut le creer.

### Flutter CI — Details techniques critiques

**Melos n'est PAS installe globalement** sur le runner GH Actions. Il faut :
1. `dart pub global activate melos` pour l'installer
2. `dart pub global run melos bootstrap` pour lier les packages

**Workspace Flutter (Pub Workspaces)** — le `pubspec.yaml` racine definit 8 packages :
- 4 apps : `apps/mefali_b2c`, `apps/mefali_b2b`, `apps/mefali_livreur`, `apps/mefali_admin`
- 4 packages : `packages/mefali_design`, `packages/mefali_core`, `packages/mefali_api_client`, `packages/mefali_offline`

**Scripts melos** definis dans `pubspec.yaml` (pas de `melos.yaml` separe) :
- `analyze` : `dart analyze --fatal-infos` (exec sur chaque package)
- `test` : `flutter test` (exec sur chaque package)
- `format` : `dart format --set-exit-if-changed .` (exec sur chaque package)

**Version Flutter** : `3.41.2` stable (Dart SDK `>= 3.10.0 < 4.0.0`)

**Linting** : `analysis_options.yaml` racine avec `flutter_lints`, regles strictes (`prefer_const_constructors`, `avoid_print`, `prefer_single_quotes`, `prefer_relative_imports`). Les apps heritent via `include: ../../analysis_options.yaml`.

### Rust CI — Details techniques critiques

**Working directory** : Tous les cargo commands doivent s'executer depuis `server/` (pas la racine du repo).

**Workspace Cargo** : 6 crates dans `server/crates/` : `api`, `domain`, `infrastructure`, `payment_provider`, `notification`, `common`.

**SQLx** : Le code utilise `sqlx::migrate!()` mais PAS `sqlx::query!()` (pas de compile-time checked queries). Le macro `migrate!()` lit les fichiers SQL a la compilation sans base de donnees. **Donc PAS besoin de PostgreSQL dans le CI pour le moment.**

**Dependances cles** : actix-web 4, sqlx 0.8, redis 0.27, aws-sdk-s3 1, tokio 1, serde 1, thiserror 2.

**Tests existants** : ~30 tests unitaires repartis dans les 6 crates. Tous `#[test]` ou `#[tokio::test]` — aucun ne necessite de connexion base de donnees.

**Clippy** : Utiliser `-D warnings` pour traiter les warnings comme des erreurs (zero tolerance).

### Actions GitHub recommandees et versions

| Action | Version | Usage |
|--------|---------|-------|
| `actions/checkout` | `v4` | Checkout du repo |
| `subosito/flutter-action` | `v2` | Setup Flutter SDK |
| `actions/cache` | `v4` | Cache pub (Flutter) |
| `dtolnay/rust-toolchain` | `stable` | Setup Rust + composants |
| `Swatinem/rust-cache` | `v2` | Cache cargo (Rust) |

### Pattern de workflow recommande

**Flutter CI** :
```yaml
name: Flutter CI
on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]
jobs:
  analyze-format-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.2'
          channel: stable
          cache: true
      - run: dart pub global activate melos
      - run: dart pub global run melos bootstrap
      - run: dart pub global run melos run analyze
      - run: dart pub global run melos run format
      - run: dart pub global run melos run test
```

**Rust CI** :
```yaml
name: Rust CI
on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]
jobs:
  clippy-fmt-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: server
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy, rustfmt
      - uses: Swatinem/rust-cache@v2
        with:
          workspaces: server -> target
      - run: cargo clippy --workspace -- -D warnings
      - run: cargo fmt --all -- --check
      - run: cargo test --workspace
```

### Pieges a eviter

1. **NE PAS** utiliser `actions/setup-flutter` — c'est `subosito/flutter-action` le standard
2. **NE PAS** oublier `working-directory: server` pour les jobs Rust — sinon cargo ne trouve pas le workspace
3. **NE PAS** ajouter de service PostgreSQL dans le CI Rust — les tests actuels n'en ont pas besoin
4. **NE PAS** utiliser `melos run ...` sans le prefixe `dart pub global run` — melos n'est pas dans le PATH par defaut
5. **NE PAS** creer de `melos.yaml` separe — la config melos est dans `pubspec.yaml` racine
6. **NE PAS** ajouter `SQLX_OFFLINE=true` — aucun `sqlx::query!()` n'est utilise, pas de `.sqlx/` a generer
7. **NE PAS** mettre les workflows dans un seul fichier — l'architecture exige 2 fichiers separes (`flutter_ci.yml` et `rust_ci.yml`)

### Intelligence Story Precedente (1-5)

- 43 tests Flutter passent (package mefali_design)
- ~30 tests Rust passent (`cargo test --workspace`)
- `dart analyze` : 0 issues sur tout le workspace
- Convention `snake_case` pour les noms de fichiers
- Les analysis_options.yaml des apps heritent du fichier racine
- `NavigationBar` (M3) utilise a la place de `BottomNavigationBar` (M2)
- Pas de regressions backend apres l'ajout du design system

### Contraintes techniques cles

- **Zero tolerance warnings** : `cargo clippy -- -D warnings` et `dart analyze --fatal-infos` font echouer le CI au moindre warning
- **Format strict** : `dart format --set-exit-if-changed` et `cargo fmt -- --check` echouent si le code n'est pas formate
- **Cache obligatoire** : sans cache, le build Rust prend 5-10 min et Flutter 3-5 min. Avec cache, divisé par 3-5x
- **Runners** : `ubuntu-latest` pour les deux workflows (standard GitHub Actions gratuit)

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.6]
- [Source: _bmad-output/planning-artifacts/architecture.md — Section Infrastructure & Deployment, CI/CD]
- [Source: _bmad-output/planning-artifacts/architecture.md — Section Directory Structure (.github/workflows/)]
- [Source: _bmad-output/planning-artifacts/prd.md — Risk Mitigation: CI/CD stricte, tests d'integration]
- [Source: CLAUDE.md — Build & Dev Commands, Conventions]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- `melos run analyze` : SUCCESS — 0 issues dans 8 packages
- `melos run format` : SUCCESS — 0 fichiers non formates (apres correction de formatage pre-existant dans 5 packages)
- `melos run test` : SUCCESS — tous tests passent dans 8 packages
- `cargo clippy --workspace -- -D warnings` : SUCCESS — 0 warnings dans 6 crates
- `cargo fmt --all -- --check` : SUCCESS — 0 fichiers non formates
- `cargo test --workspace` : SUCCESS — 30 tests passent (1 api + 12 common + 1 domain + 3 infrastructure + 6 notification + 7 payment_provider)

### Completion Notes List

- 2 fichiers workflow GitHub Actions crees : `flutter_ci.yml` et `rust_ci.yml`
- Flutter CI : subosito/flutter-action@v2 avec cache integre, melos bootstrap puis analyze/format/test
- Rust CI : dtolnay/rust-toolchain@stable + Swatinem/rust-cache@v2, working-directory server, clippy/fmt/test
- Triggers configures : push sur toutes branches + pull_request vers main
- Cache pub gere via `subosito/flutter-action` `cache: true` (plus simple et fiable que `actions/cache` separe)
- Cache cargo gere via `Swatinem/rust-cache@v2` avec `workspaces: server -> target`
- Correction de formatage pre-existant dans 5 packages Flutter (apps + mefali_design) pour que le CI format check passe
- Pas de PostgreSQL dans le CI — confirme qu'aucun `sqlx::query!()` n'est utilise

### Change Log

- 2026-03-17 : Implementation complete CI/CD pipeline (T1-T3)
- 2026-03-17 : Correction formatage Dart pre-existant dans 5 packages
- 2026-03-17 : Code review — Ajout concurrency group + timeout-minutes (30min) aux 2 workflows

### File List

- .github/workflows/flutter_ci.yml (nouveau)
- .github/workflows/rust_ci.yml (nouveau)
- apps/mefali_admin/lib/app.dart (formate)
- apps/mefali_admin/lib/main.dart (formate)
- apps/mefali_admin/test/widget_test.dart (formate)
- apps/mefali_b2b/lib/app.dart (formate)
- apps/mefali_b2b/lib/main.dart (formate)
- apps/mefali_b2b/test/widget_test.dart (formate)
- apps/mefali_b2c/lib/app.dart (formate)
- apps/mefali_b2c/lib/main.dart (formate)
- apps/mefali_b2c/test/widget_test.dart (formate)
- apps/mefali_livreur/lib/app.dart (formate)
- apps/mefali_livreur/lib/main.dart (formate)
- apps/mefali_livreur/test/widget_test.dart (formate)
- packages/mefali_design/lib/mefali_theme.dart (formate)
- packages/mefali_design/lib/mefali_typography.dart (formate)
- packages/mefali_design/lib/theme/mefali_custom_colors.dart (formate)
- packages/mefali_design/test/mefali_design_test.dart (formate)
