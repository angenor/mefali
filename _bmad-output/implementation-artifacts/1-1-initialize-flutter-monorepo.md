# Story 1.1: Initialize Flutter Monorepo

Status: ready-for-dev

## Story

As a developer,
I want a Melos monorepo with 4 apps and 4 shared packages,
so that the team can develop in parallel with shared code.

## Acceptance Criteria

1. **Given** un repository frais **When** je lance `melos bootstrap` **Then** les 4 apps et 4 packages sont creees et lies **And** chaque app peut importer les packages partages sans erreur
2. **Given** le monorepo initialise **When** je lance `melos run analyze` **Then** zero erreur d'analyse Dart sur les 4 apps et 4 packages
3. **Given** le monorepo initialise **When** je lance `flutter test` dans chaque package **Then** les tests unitaires de base passent (au minimum 1 test par package)
4. **Given** une app (ex: mefali_b2c) **When** j'importe `package:mefali_design/mefali_design.dart` **Then** le theme Material 3 marron est accessible via `MefaliTheme.light()` et `MefaliTheme.dark()`

## Tasks / Subtasks

- [ ] Task 1: Initialiser la structure racine du monorepo (AC: #1)
  - [ ] 1.1 Creer `melos.yaml` avec configuration Melos + Pub Workspaces
  - [ ] 1.2 Creer `pubspec.yaml` racine (workspace: apps/*, packages/*)
  - [ ] 1.3 Creer `.gitignore` adapte Flutter monorepo
  - [ ] 1.4 Creer `analysis_options.yaml` racine avec regles strictes

- [ ] Task 2: Creer les 4 apps Flutter (AC: #1, #2)
  - [ ] 2.1 `apps/mefali_b2c/` — App client B2C (Android + iOS)
  - [ ] 2.2 `apps/mefali_b2b/` — App marchand B2B (Android + iOS)
  - [ ] 2.3 `apps/mefali_livreur/` — App livreur (Android + iOS)
  - [ ] 2.4 `apps/mefali_admin/` — App admin (Flutter Web)
  - [ ] 2.5 Chaque app a sa structure `lib/features/` vide mais prete
  - [ ] 2.6 Chaque app depend des 4 packages partages dans son `pubspec.yaml`

- [ ] Task 3: Creer les 4 packages partages (AC: #1, #3)
  - [ ] 3.1 `packages/mefali_design/` — Theme M3 marron + composants
  - [ ] 3.2 `packages/mefali_core/` — Models, enums, utils
  - [ ] 3.3 `packages/mefali_api_client/` — Client HTTP Dio + WebSocket + providers
  - [ ] 3.4 `packages/mefali_offline/` — Drift database + SyncQueue + connectivity

- [ ] Task 4: Configurer mefali_design avec le theme de base (AC: #4)
  - [ ] 4.1 `mefali_theme.dart` — Point d'entree unique du theme
  - [ ] 4.2 `mefali_colors.dart` — Palette marron M3 light + dark
  - [ ] 4.3 `mefali_typography.dart` — TextTheme Roboto avec tailles min
  - [ ] 4.4 Export barrel `mefali_design.dart`

- [ ] Task 5: Valider le monorepo (AC: #1, #2, #3)
  - [ ] 5.1 `melos bootstrap` sans erreur
  - [ ] 5.2 `melos run analyze` sans erreur
  - [ ] 5.3 Au moins 1 test par package qui passe
  - [ ] 5.4 Chaque app build sans erreur (`flutter build apk --debug` pour mobile, `flutter build web` pour admin)

## Dev Notes

### Stack Technique Exacte

| Composant | Version | Notes |
|-----------|---------|-------|
| Flutter | 3.41.2 stable | Framework frontend |
| Dart | >= 3.10 | Requis pour Pub Workspaces |
| Melos | latest | Orchestration monorepo |
| Riverpod | latest | State management (toutes les apps) |
| go_router | latest | Navigation declarative |
| Dio | latest | Client HTTP avec interceptors |
| Drift | latest | SQLite offline (mefali_offline) |
| google_maps_flutter | latest | Cartes (pas encore utilise dans cette story) |
| cached_network_image | latest | Cache images (pas encore utilise dans cette story) |
| web_socket_channel | latest | WebSocket (pas encore utilise dans cette story) |

### Structure Cible Exacte du Monorepo

```
mefali/
├── melos.yaml
├── pubspec.yaml                         # workspace root
├── analysis_options.yaml
├── .gitignore
│
├── apps/
│   ├── mefali_b2c/
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart                 # MaterialApp avec MefaliTheme
│   │   │   └── features/               # Vide - sera rempli Story 4.x+
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── mefali_b2b/
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   └── features/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── mefali_livreur/
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   └── features/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── mefali_admin/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   └── features/
│       ├── test/
│       └── pubspec.yaml
│
├── packages/
│   ├── mefali_design/
│   │   ├── lib/
│   │   │   ├── mefali_design.dart       # Barrel export
│   │   │   ├── mefali_theme.dart        # MefaliTheme.light() / .dark()
│   │   │   ├── mefali_colors.dart       # MefaliColors (palette marron)
│   │   │   ├── mefali_typography.dart   # MefaliTypography
│   │   │   ├── theme/                   # (reserve pour light_theme.dart, dark_theme.dart)
│   │   │   └── components/              # (reserve pour les 10 composants custom)
│   │   ├── test/
│   │   │   └── mefali_theme_test.dart
│   │   └── pubspec.yaml
│   │
│   ├── mefali_core/
│   │   ├── lib/
│   │   │   ├── mefali_core.dart         # Barrel export
│   │   │   ├── models/                  # (reserve)
│   │   │   ├── enums/                   # (reserve)
│   │   │   └── utils/                   # (reserve)
│   │   ├── test/
│   │   │   └── mefali_core_test.dart
│   │   └── pubspec.yaml
│   │
│   ├── mefali_api_client/
│   │   ├── lib/
│   │   │   ├── mefali_api_client.dart   # Barrel export
│   │   │   ├── dio_client/              # (reserve)
│   │   │   ├── websocket/               # (reserve)
│   │   │   ├── endpoints/               # (reserve)
│   │   │   └── providers/               # (reserve)
│   │   ├── test/
│   │   │   └── mefali_api_client_test.dart
│   │   └── pubspec.yaml
│   │
│   └── mefali_offline/
│       ├── lib/
│       │   ├── mefali_offline.dart       # Barrel export
│       │   ├── database/                 # (reserve)
│       │   ├── sync/                     # (reserve)
│       │   └── connectivity/             # (reserve)
│       ├── test/
│       │   └── mefali_offline_test.dart
│       └── pubspec.yaml
│
└── server/                              # (Story 1.2 — Rust backend)
```

### Configuration Melos Requise

```yaml
# melos.yaml
name: mefali
packages:
  - apps/*
  - packages/*

scripts:
  analyze:
    exec: dart analyze --fatal-infos
    description: Analyse statique Dart
  test:
    exec: flutter test
    description: Tests unitaires
  format:
    exec: dart format --set-exit-if-changed .
    description: Formatage Dart
```

### Configuration Pub Workspaces

Le `pubspec.yaml` racine:
```yaml
name: mefali_workspace
publish_to: none

environment:
  sdk: '>=3.10.0 <4.0.0'

workspace:
  - apps/mefali_b2c
  - apps/mefali_b2b
  - apps/mefali_livreur
  - apps/mefali_admin
  - packages/mefali_design
  - packages/mefali_core
  - packages/mefali_api_client
  - packages/mefali_offline
```

### Palette de Couleurs Exacte (mefali_colors.dart)

| Token | Mode Clair | Mode Sombre | Usage |
|-------|-----------|-----------|-------|
| primary | #5D4037 (Brown 700) | #D7CCC8 | Boutons principaux, app bar |
| primaryContainer | #D7CCC8 (Brown 100) | #5D4037 | Fonds de cartes, highlights |
| onPrimary | #FFFFFF | — | Texte sur boutons marron |
| error | Rouge M3 standard | #EF9A9A | Alertes, erreurs |
| success | #4CAF50 | #81C784 | Confirmations, "+X FCFA" |
| surface | #FAFAFA | #1C1B1F | Fond d'ecran principal |
| onSurface | #212121 | #E6E1E5 | Texte body |

- Contraste marron fonce / blanc >= 4.5:1 (WCAG AA)
- `ThemeMode.system` par defaut (suit reglage telephone)

### Typographie (mefali_typography.dart)

- Police: Roboto (defaut Flutter, modifiable en 1 ligne)
- Body minimum: 14sp
- Labels minimum: 12sp
- Utiliser le `TextTheme` standard M3

### Dependencies par Package

**mefali_design** — aucune dependance externe (que Flutter SDK)

**mefali_core** — minimal:
```yaml
dependencies:
  flutter:
    sdk: flutter
  json_annotation: ^4.0.0
dev_dependencies:
  json_serializable: ^6.0.0
  build_runner: ^2.0.0
```

**mefali_api_client** — depend de mefali_core:
```yaml
dependencies:
  flutter:
    sdk: flutter
  mefali_core:
    path: ../mefali_core
  dio: # latest
  flutter_riverpod: # latest
  web_socket_channel: # latest
```

**mefali_offline** — depend de mefali_core:
```yaml
dependencies:
  flutter:
    sdk: flutter
  mefali_core:
    path: ../mefali_core
  drift: # latest
  sqlite3_flutter_libs: # latest
  path_provider: # latest
  connectivity_plus: # latest
```

**Chaque app** — depend des 4 packages:
```yaml
dependencies:
  flutter:
    sdk: flutter
  mefali_design:
    path: ../../packages/mefali_design
  mefali_core:
    path: ../../packages/mefali_core
  mefali_api_client:
    path: ../../packages/mefali_api_client
  mefali_offline:
    path: ../../packages/mefali_offline
  flutter_riverpod: # latest
  go_router: # latest
```

**mefali_admin** a aussi `flutter_web_plugins`.

### Conventions de Code CRITIQUES

| Scope | Convention |
|-------|-----------|
| Fichiers/packages Dart | snake_case |
| Classes/Widgets | PascalCase |
| Variables/fonctions | camelCase |
| Providers Riverpod | camelCase + suffixe Provider |
| JSON/API | snake_case |
| IDs | UUID v4 partout |
| Dates | ISO 8601 UTC |

**Mapping Dart ↔ API:** `@JsonSerializable(fieldRename: FieldRename.snake)`

### Contraintes Materielles Cibles

- Minimum Android API 21 (Android 5.0)
- Minimum iOS 13
- APK < 30 MB
- Cold start < 3s (Transsion 2 GB RAM)
- Portrait uniquement (apps mobiles), responsive (admin web)

### Ce qui est HORS SCOPE de cette Story

- Le theme complet des 10 composants custom (Story 1.5)
- Le backend Rust (Story 1.2)
- Docker Compose (Story 1.3)
- Les migrations DB (Story 1.4)
- CI/CD GitHub Actions (Story 1.6)
- Toute logique metier — les apps affichent juste un ecran vide avec le theme M3 marron

### Anti-Patterns a Eviter

1. **NE PAS** coder des couleurs en dur dans les apps — tout passe par mefali_design
2. **NE PAS** utiliser `flutter create` directement — configurer manuellement pour cohérence monorepo
3. **NE PAS** ajouter des dependances non listees — le scope est minimal
4. **NE PAS** creer de logique metier — juste le squelette avec un MaterialApp et le theme
5. **NE PAS** utiliser un state management autre que Riverpod
6. **NE PAS** utiliser de navigation autre que go_router
7. **NE PAS** creer les dossiers `features/auth/`, `features/home/` etc. — juste le dossier `features/` vide

### Project Structure Notes

- Organisation par feature/domaine (pas par type) — `features/auth/`, `features/home/`, etc. dans les stories suivantes
- Le monorepo est le fondement de tout le projet — chaque erreur ici se propage partout
- Pub Workspaces (Dart >= 3.10) remplace les anciens `dependency_overrides`
- Melos orchestre les commandes cross-packages (`analyze`, `test`, `format`)

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Technical Stack]
- [Source: _bmad-output/planning-artifacts/architecture.md#Folder Structure]
- [Source: _bmad-output/planning-artifacts/architecture.md#Coding Conventions]
- [Source: _bmad-output/planning-artifacts/architecture.md#Dependency Management]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Design System]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Color Palette]
- [Source: _bmad-output/planning-artifacts/prd.md#Technical Requirements]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
