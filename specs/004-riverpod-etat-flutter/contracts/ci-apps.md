# Contrat — CI des apps Flutter (`.github/workflows/apps.yml`)

Interface du cycle 004 vis-à-vis de tous les cycles Flutter suivants (CRS, VND,
CMD…) : ce qui casse le build des apps, et ce qu'aucun garde-fou ne rattrape.
FR-031, FR-032, FR-033, FR-034 ; SC-006, SC-007, SC-008. Successeur direct de
[`001/contracts/ci-cd.md`](../../001-socle-monorepo/contracts/ci-cd.md), dont la
ligne `apps` (`flutter analyze`, `flutter test`) est **remplacée** ici et dont la
règle 2 (« génération déterministe, sinon le contrôle produit des faux
positifs ») est le précédent direct de `build_runner`. Décisions et preuves
d'exécution : [research.md](../research.md) R2, R12 — vérifications du
2026-07-17 sous Flutter 3.44.6 / Dart 3.12.2.

## Le point du contrat : `dart analyze`, JAMAIS `flutter analyze`

`apps.yml:36` fait aujourd'hui `flutter analyze`. **`flutter analyze` NE CHARGE
PAS les plugins `analysis_server_plugin`** — donc AUCUNE des 15 règles de
`riverpod_lint 3.1.4` (R2). Vérifié par exécution, même répertoire, même
`analysis_options.yaml`, même faute volontaire :

```
dart analyze    → EXIT 2 | 2 issues : missing_provider_scope, avoid_public_notifier_properties
flutter analyze → EXIT 0 | "No issues found!"
```

Laisser cette ligne, c'est faire de `riverpod_lint` un **no-op décoratif** : la
CI reste verte, FR-033 et SC-006 sont réputés tenus, US1 est réputée livrée, et
**rien n'est vérifié** — exactement le mode de panne qu'US1 nomme (« un pattern
qu'aucun outil ne vérifie n'est pas un pattern, c'est une intention »,
spec US1). C'est le risque n°1 du cycle. La bascule est **sans effet de bord** :
`dart analyze` rend `No issues found!` sur les 3 paquets réels **aujourd'hui**,
avant toute migration (R2) — donc la première tâche du lot est cette bascule, et
elle doit être verte AVANT que quoi que ce soit migre.

⚠ **La doc officielle du SDK est fausse sur ce point.**
`analysis_server_plugin/doc/using_plugins.md` affirme que les diagnostics du
plugin sortent « *at the command line (with `dart analyze` or `flutter
analyze`)* ». Vérifié faux sous Flutter 3.44.6. **Ne pas la croire sur parole ;
ne pas revenir à `flutter analyze` sur la foi d'une doc** — le seul juge est
l'Independent Test d'US1 (faute volontaire ⇒ `dart analyze` sort en 3).

## Jobs, déclencheurs, contenu

| Job | Chemins déclencheurs | Contenu |
|---|---|---|
| `apps` (matrice ×3 : `mefali_core` `codegen:true`, `mefali_pro` `codegen:true`, `mefali_client` `codegen:false`) | `apps/**`, `clients/dart/**`, `.github/workflows/apps.yml` (INCHANGÉS) | `flutter pub get` → `dart run build_runner build` (si `codegen`) → `git diff --exit-code -- .` (FR-031) → **`dart analyze`** (FR-032/033) → `flutter test --exclude-tags golden` |
| `accord-locks` | `apps/**`, `scripts/verifier-accord-locks.sh`, `.github/workflows/apps.yml` | `./scripts/verifier-accord-locks.sh` — versions communes aux 3 `pubspec.lock` identiques, et pin `riverpod_lint` identique dans les 3 `analysis_options.yaml` (SC-008, R1) |
| `contrat-clients` | INCHANGÉ | INCHANGÉ — `clients/dart` reste hors périmètre (FR-006, FR-027) : les deux chaînes de génération sont **étanches**, prouvé (R2) |
| `backend`, `web`, `deploy` | INCHANGÉS | INCHANGÉS — AUCUN backend, AUCUN SQL, AUCUN Nuxt ce cycle (FR-006) |

Les chemins déclencheurs de `apps` ne changent PAS : le générateur de providers
ne lit rien hors `apps/**`, et `clients/dart/**` y est déjà pour la raison
inverse (le client est une dépendance `path:` des trois paquets).

## Règles contractuelles

1. **`dart analyze`, jamais `flutter analyze`** — voir ci-dessus. La commande
   d'analyse est la seule dans le dépôt à ne PAS être préfixée `flutter` ; c'est
   délibéré et c'est ce que ce contrat protège (R2).
2. **L'ordre est imposé, pas indicatif (FR-034)** : `pub get` → régénération →
   contrôle de dérive → analyse → tests. Le contrôle de dérive vient **après**
   la régénération (FR-034 le dit) et **avant** l'analyse — signal le plus
   spécifique et le moins cher d'abord ; analyser du code désynchronisé produit
   des diagnostics trompeurs. FR-034 « l'analyse s'exécute sur le code généré
   commité, présent dès la récupération du dépôt » est tenu : les `.g.dart` sont
   COMMITÉS (FR-029), donc présents dès `checkout`, et `build_runner` les
   réécrit à l'identique (déterminisme vérifié, R12).
3. **Génération déterministe, sinon le contrôle est un générateur de faux
   positifs** (FR-030, SC-007 ; règle 2 de `001/contracts/ci-cd.md`, reprise
   telle quelle) : deux `dart run build_runner build` successifs laissent **0**
   modification non commitée. La commande est **`dart run build_runner build`
   NU** — `--delete-conflicting-outputs` a été SUPPRIMÉ de build_runner 2.15.x
   (« *These options have been removed and were ignored* ») (R2).
4. **Portée du garde-fou anti-dérive : le répertoire du paquet, pas les
   `.g.dart`** (FR-031, tranché ici parce que la spec renvoie explicitement
   cette portée au plan) — `git diff --exit-code -- .` sous le
   `working-directory` de la matrice.
   - **Ce que ça couvre en plus** : `flutter pub get` REGÉNÈRE les traductions
     (`generate: true` dans les 3 `pubspec.yaml`), et celles de `mefali_core`
     sont **commitées et gardées par rien** (hors du motif d'exclusion de
     `.gitignore`) — troisième politique de code généré du dépôt. La portée
     large la ferme, gratuitement, et aligne le cycle sur son Assumption
     (« ce cycle tranche pour **commité + gardé** »). Elle couvre aussi
     `pubspec.lock` (SC-008).
   - **Ce que l'option étroite (`-- '*.g.dart'`) coûterait** : le trou l10n de
     `mefali_core` resterait ouvert et devrait être consigné au titre de FR-027,
     et une 3ᵉ politique de code généré continuerait de vivre dans un dépôt qui
     vient de trancher pour une seule. Son seul avantage — ne pas risquer de
     révéler une dérive préexistante, exception nommée de FR-027 — est **nul** :
     mesuré, après `flutter pub get` sur les 3 paquets,
     `git status --porcelain apps/ clients/` est **VIDE** ⇒ AUCUNE dérive
     préexistante ⇒ **l'exception FR-027 n'a pas à être invoquée** (R12).
   - **Scopé `-- .`, jamais `apps/`** : un échec doit NOMMER le paquet coupable.
5. **FR-033 tient par `diagnostics:`, et ce mécanisme n'est pas documenté.**
   Sur les 15 règles de `riverpod_lint 3.1.4` : 1 ERROR d'office
   (`riverpod_syntax_error`), 12 WARNING (`dart analyze` → EXIT 2), et **3 INFO**
   (`avoid_public_notifier_properties`, `avoid_build_context_in_providers`,
   `protected_notifier_properties`) — un INFO seul sort en **EXIT 0**, donc « un
   avertissement ignorable » au sens exact de FR-033. Escalade OBLIGATOIRE dans
   `analysis_options.yaml`, bloc `plugins:` **top-level** :
   `diagnostics: {<règle>: error}`. `analyzer: errors:` ne les atteint PAS
   (vérifié : `unrecognized_error_code`, forme nue comme namespacée) (R2).
   ⚠ **`diagnostics: <règle>: error` est UNDOCUMENTÉ** (la doc ne montre que
   `true`/`false`) : il fonctionne sur Dart 3.12.2 (vérifié, EXIT 3), mais si un
   SDK futur le retire, **les 3 règles retombent en info EN SILENCE** et FR-033
   cesse d'être tenu sans que rien ne rougisse. **Le garde-fou est l'Independent
   Test d'US1**, qui reste au quickstart : introduire volontairement
   `avoid_public_notifier_properties` et exiger `dart analyze` → **exit 3**.
   Repli documenté si le mécanisme tombe : `dart analyze --fatal-infos`
   (vérifié, EXIT 1) — écarté en premier choix parce qu'il vit dans le YAML de
   CI (donc ni dans l'IDE, ni en local) et change le régime de **tous** les infos
   de `flutter_lints`, ce qu'un refactor pur n'a pas à faire.
6. **SC-006 se lit en pass/fail, JAMAIS en nombre d'issues.** Avec le plugin
   actif, les diagnostics **cœur** sont DUPLIQUÉS — reproduit : plugin OFF → 2
   issues, plugin ON → **4** ; les règles riverpod, elles, ne sont PAS dupliquées.
   Cause inconnue, AUCUNE issue upstream trouvée (R2). Sans effet sur SC-006
   (2 × 0 = 0), mais **tout comptage littéral d'issues est faussé** : ni la CI ni
   le quickstart ne doivent asseoir une assertion sur un nombre.
7. **Aucun relâchement de lint (FR-032, SC-006)** : `dart analyze` est vert sous
   les options **exactes** de `mefali_core` (`strict-casts` + `strict-raw-types`)
   avec les `.g.dart` présents — vérifié, `No issues found!`. **`exclude:
   *.g.dart` : NON** — ce serait « désactiver par confort » alors que RIEN n'est
   à désactiver (le `.g.dart` s'auto-neutralise :
   `// ignore_for_file: type=lint, type=warning`), et l'exclusion supprimerait la
   seule vérification que le généré compile sous les options du paquet (R2). Les
   `errors: {invalid_annotation_target: ignore}` et `exclude:` de `mefali_pro` /
   `mefali_client` sont **préexistants** (gen-l10n) et restent INCHANGÉS : SEUL
   le bloc `plugins:` est ajouté.
8. **Le bloc `plugins:` ne marche PAS en fichier inclus — les 3 paquets portent
   chacun le leur.** Il n'est lu que dans l'`analysis_options.yaml` du paquet
   lui-même : un bloc placé dans un fichier tiré par `include:` n'est **pas
   hérité** (R2). Or le dépôt fait déjà `include: package:flutter_lints/flutter.yaml`
   dans les 3 paquets — factoriser le pin `riverpod_lint` et le bloc
   `diagnostics:` dans un fichier inclus partagé est donc le geste **naturel**,
   celui qu'un lecteur pressé fera pour honorer la règle 7 sans se répéter.
   **Il rend `riverpod_lint` silencieux** : les 15 règles disparaissent, l'analyse
   reste verte, FR-033 et SC-006 sont réputés tenus — **exactement le mode de
   panne de `flutter analyze`** (règle 1), c'est-à-dire le risque n°1 du cycle,
   par une autre porte. La duplication ×3 du bloc est **délibérée** ; c'est
   `accord-locks` qui la tient accordée (règle 9), pas `include:`. Garde-fou :
   l'Independent Test d'US1 (faute volontaire ⇒ EXIT 3), qui distingue les deux
   pannes du placement — voir règle 5 pour le bloc **sous `analyzer:`**.
9. **`riverpod_lint` est figé HORS lockfile — le script est son seul gel**
   (SC-008, R1). Il se déclare dans `analysis_options.yaml`, **JAMAIS dans
   `pubspec.yaml`** : `grep -c riverpod_lint pubspec.lock` → **0**, et le plugin
   fonctionne quand même. `custom_lint` est **ÉCARTÉ**, insoluble
   (`custom_lint 0.8.1` exige `analyzer ^8` vs `^12` pour riverpod) : la spec note
   « custom_lint : 0 occurrence », **il faut que ça le reste**. Le pin exact
   `3.1.4` (sans caret), identique dans les 3 `analysis_options.yaml`, est vérifié
   par `accord-locks` — par un script, pas par pub.
10. **Ne jamais re-résoudre** : `flutter pub add` incrémental en local, JAMAIS
    `rm pubspec.lock`, JAMAIS `pub upgrade`. Résolution fraîche mesurée :
    `uuid 4.5.3 → 4.6.0` ⇒ **casse l'accord des 3 locks** (SC-008). La CI n'exécute
    que `flutter pub get`, qui respecte le lock — c'est ce qui rend `accord-locks`
    vérifiable plutôt que fluctuant.
11. **Les 2 goldens restent HORS CI** — `--exclude-tags golden` est conservé tel
    quel (rendu pixel sensible à la plateforme, `apps.yml:37-38`). Ils sont
    **rejoués À LA MAIN avant fusion**, et `--update-goldens` est **INTERDIT
    pendant tout le cycle** : il transformerait une régression FR-001 en test
    vert. FR-005 est tenu mécaniquement — les 2 goldens montent un
    `StatelessWidget` nu, hors de toute portée de providers, ils ne voient ni
    provider ni session (R13).
12. **Les 3 tests neufs (FR-013, FR-014, FR-018) ne portent AUCUN tag** et
    `dart_test.yaml` n'est PAS touché : un tag les exposerait à une exclusion
    accidentelle, alors que SC-005 veut précisément les voir tourner à CHAQUE PR
    (R11).
13. **Toolchains figées** (règle 5 de `001/contracts/ci-cd.md`) : Flutter 3.44.6
    reste épinglé en dur dans `apps.yml` — ces fichiers de CI sont l'unique source
    de vérité de la version (ni `.fvmrc`, ni gestionnaire de version). Aucun
    « latest » flottant.

## Point ouvert — à mesurer AVANT de figer ce job

**`dart analyze` exige-t-il le RÉSEAU en CI ?** L'analysis server résout le
paquet synthétique du plugin par `dart pub upgrade` (doc `using_plugins.md`), et
le cache **n'a pas été localisé** — ni dans `.dart_tool/`, ni dans `~/.dartServer`
(R2). Si la résolution est réseau, **l'étape d'analyse devient dépendante de
pub.dev** : un incident pub.dev rougit la CI des apps sans qu'aucun code n'ait
bougé, et le graphe de dépendances du plugin n'est verrouillé par rien (limite
déjà nommée de SC-008, R1). **À mesurer en première tâche du lot**, en même temps
que la bascule `dart analyze` (règle 1) : runner sans réseau, ou observation des
requêtes sortantes. Si le réseau est requis : le consigner comme écart au
principe X plutôt que le contourner, et envisager un cache d'action sur le
répertoire de résolution UNE FOIS localisé — jamais l'inverse.

## Le job, prêt à coller

```yaml
name: apps

on:
  push:
    branches: [main]
    paths:
      - 'apps/**'
      - 'clients/dart/**'
      - 'scripts/verifier-accord-locks.sh'
      - '.github/workflows/apps.yml'
  pull_request:
    paths:
      - 'apps/**'
      - 'clients/dart/**'
      - 'scripts/verifier-accord-locks.sh'
      - '.github/workflows/apps.yml'

jobs:
  apps:
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix:
        include:
          - package: apps/packages/mefali_core
            codegen: true
          - package: apps/mefali_pro
            codegen: true
          # mefali_client n'a ni riverpod_annotation ni riverpod_generator :
          # riverpod_generator/build.yaml déclare `auto_apply: dependents`, donc
          # aucun builder ne s'y active. Il porte flutter_riverpod pour
          # ProviderScope (FR-010) et le pin riverpod_lint, rien d'autre (R1).
          - package: apps/mefali_client
            codegen: false
    defaults:
      run:
        working-directory: ${{ matrix.package }}
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.44.6
          channel: stable
      # Régénère AUSSI les l10n (generate: true dans les 3 pubspec.yaml) —
      # d'où la portée du contrôle de dérive ci-dessous (FR-031, règle 4).
      - run: flutter pub get
      # FR-034 : la régénération PRÉCÈDE le contrôle de dérive. Commande NUE :
      # --delete-conflicting-outputs est supprimé de build_runner 2.15.x.
      - if: matrix.codegen
        run: dart run build_runner build
      # FR-031 — tout diff = échec, sur le modèle de contrat-clients.yml:54-55.
      # Scopé `-- .` (le paquet de la matrice) : un échec nomme le coupable.
      - name: Aucun diff (dérive interdite)
        run: git diff --exit-code -- .
      # ⚠ dart analyze, PAS flutter analyze : flutter analyze NE CHARGE PAS les
      # plugins analysis_server_plugin ⇒ les 15 règles riverpod_lint seraient un
      # no-op silencieux et la CI resterait verte (FR-032/FR-033, règle 1).
      # La doc using_plugins.md prétend le contraire : elle est fausse (R2).
      - run: dart analyze
      # Goldens exclus : rendu pixel sensible à la plateforme (générés/vérifiés
      # en local). À rejouer À LA MAIN avant fusion, JAMAIS --update-goldens.
      - run: flutter test --exclude-tags golden

  accord-locks:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      # SC-008 : versions communes accordées entre les 3 pubspec.lock, ET pin
      # riverpod_lint identique dans les 3 analysis_options.yaml — riverpod_lint
      # n'est dans AUCUN lockfile, ce script est son seul gel (R1).
      - run: ./scripts/verifier-accord-locks.sh
```

## Sortie attendue

Sur toute PR touchant `apps/**` : 4 jobs (3 paquets + `accord-locks`). Un paquet
rouge NOMME son échec — dérive de généré (FR-031), règle de provider (FR-033),
lock désaccordé (SC-008) ou test cassé (FR-003). Aucun de ces échecs n'est
contournable par un réglage de confort : le seul geste autorisé face à un rouge
est de corriger le code annoté, jamais le `.g.dart` (INTERDIT à la main,
constitution I), jamais l'`analysis_options.yaml` (FR-032).

**Ce que ce contrat NE couvre PAS, et le dit** : `dart format` reste non vérifié
sur `apps/**` — défaut latent préexistant, consigné et NON corrigé (FR-027) ; les
2 goldens (hors CI par choix, règle 11) ; SC-003, SC-004 et SC-009, qui se
vérifient **sur émulateur** et qu'AUCUNE CI ne rattrape ; et l'opposition
`keepAlive`/`autoDispose` (FR-019/FR-020), **l'invariant central du cycle, qu'AUCUN
lint ne garde** — la règle `avoid_keep_alive_dependency_inside_auto_dispose`
**N'EXISTE PAS** (R4). Ces deux réglages ne sont tenus que par les tests SC-005 et
la revue.
