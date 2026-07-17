# Research — Gestion d'état des apps Flutter : migration vers Riverpod codegen (cycle 004)

Phase 0 du plan : toutes les inconnues du Technical Context sont résolues ici. Le cycle porte
la story **TRX-08 (P1)** de `docs/user-stories-v2.md` (clarification du 2026-07-17). Versions et
comportements vérifiés le **2026-07-17** par **exécution réelle** sous Flutter 3.44.6 / Dart
3.12.2 — `flutter pub get` sur un paquet portant les contraintes exactes du dépôt, sonde de
compilation/génération/analyse/test rejouable — et **non relevés sur pub.dev** (constitution X).
Format : **Décision** / **Rationale** / **Alternatives considérées**, toujours les trois. Les
faits sur l'existant portent leur `fichier:ligne`. Le dépôt écrit ses divergences plutôt que de
les taire : trois écarts au principe X et un à VII sont nommés ici et justifiés au Complexity
Tracking du plan.

## R1 — Versions figées : `flutter_riverpod 3.3.2` / `riverpod_annotation 4.0.3` / `riverpod_generator 4.0.4`, trois lockfiles indépendants, AUCUN workspace pub

**Décision** : les six briques ci-dessous, résolues et non relevées (constitution X). Trois locks
indépendants, résolution **incrémentale** (`flutter pub add` en partant du lock existant),
**JAMAIS** `rm pubspec.lock`, **JAMAIS** `pub upgrade`. Accord des trois locks vérifié en CI par
`scripts/verifier-accord-locks.sh`, qui compare les versions communes aux 3 `pubspec.lock`
**et** le pin `riverpod_lint` des 3 `analysis_options.yaml` (SC-008).

| Brique | Version figée | Note |
|---|---|---|
| `flutter_riverpod` | **3.3.2** | `dependencies` des **3** paquets. Pas `riverpod` pur-Dart (il faut `ProviderScope`/`ConsumerWidget`, FR-010) ; pas `hooks_riverpod` (tire `flutter_hooks`, hors périmètre). |
| `riverpod_annotation` | **4.0.3** | `dependencies` de `mefali_core` et `mefali_pro` ; épingle `riverpod: 3.3.2`. La numérotation 4.x ≠ 3.x est **normale**, pas un piège : SC-008 se vérifie sur `riverpod: 3.3.2` dans les 3 locks. |
| `riverpod_generator` | **4.0.4** | `dev_dependencies` (core, pro). Livre son propre `build.yaml` (`auto_apply: dependents`, `generate_for: exclude [test, example]`, `build_to: cache`) — voir R2. |
| `build_runner` | **^2.15.1** ⚠ **PAS 2.15.2** | `dev_dependencies` (core, pro). Plafond **dur**, vérifié : *« build_runner >=2.15.2 depends on analyzer >=13.3.0 <15.0.0 and riverpod_generator 4.0.4 depends on analyzer ^12.0.0 → version solving failed »*. **Écart au principe X n°2** (2.15.2 est la dernière stable). |
| `riverpod_lint` | **3.1.4** — version **exacte, sans caret** | Déclaré dans **`analysis_options.yaml` → `plugins:`**, **JAMAIS** dans `pubspec.yaml`. Depuis 3.1.0 (2025-12-26) : `analysis_server_plugin`, plus `custom_lint`. **Hors lockfile** — voir écart X n°3. |
| `custom_lint` | — **ÉCARTÉ** | Insoluble : `custom_lint 0.8.1` exige `analyzer ^8.0.0` contre `^12.0.0` pour riverpod. La spec relève « custom_lint : 0 occurrence » : **il faut que ça le reste**. Toute la littérature antérieure à 2025-12 est périmée. |

Transitives verrouillées par la résolution : `riverpod 3.3.2`, `analyzer 12.1.0`, `build 4.0.7`,
`source_gen 4.2.3`, **`riverpod_analyzer_utils 1.0.0-dev.10`**.

**Rationale** : la note `specs/001-socle-monorepo/research.md:40` (« riverpod 3 / 3.3.2 »,
**Différés**) est **toujours exacte** au 2026-07-17 — mais **incomplète** : elle ne dit rien de la
numérotation divergente de la chaîne codegen, de la mort de `custom_lint`, ni du plafond
`build_runner`. La re-vérification qu'impose le principe X était justifiée et n'était pas une
formalité. **L'accord des trois locks n'est pas à créer, il est à ne pas casser** : ils s'accordent
**déjà** — **0 désaccord sur 111/112/112 paquets**. Le vrai risque n'est pas Riverpod, c'est de
**re-résoudre** : résolution fraîche (lock supprimé) → `uuid 4.5.3 → 4.6.0` ⇒ accord cassé (pro et
client épinglent 4.5.3, `mefali_pro/pubspec.yaml:39`) ; `flutter pub add` incrémental →
**0 paquet existant modifié** (mesuré).

**Trois écarts au principe X, nommés plutôt que contournés** (SC-008 les exige nommés) :
**(1)** `riverpod_analyzer_utils 1.0.0-dev.10` est une **PRÉRELEASE**, épinglée *exactement* par
`riverpod_generator 4.0.4` **et** par `riverpod_lint 3.1.4` ; elle entre dans le lockfile. Tension
frontale avec « dernière version **STABLE** » — non contournable sans renoncer au codegen.
**(2)** `build_runner` plafonné à 2.15.1 (ci-dessus) ; un `pub upgrade` futur re-cassera.
**(3)** `riverpod_lint` **n'est figé par AUCUN lockfile** — vérifié : `grep -c riverpod_lint
pubspec.lock` → **0**, et le plugin fonctionne quand même (prouvé, EXIT 3). L'analysis server
résout un paquet synthétique par `dart pub upgrade`. **« Figé par lockfile » est mécaniquement
inatteignable pour cette brique** : le pin exact `3.1.4`, identique dans les 3
`analysis_options.yaml` et contrôlé par script, gèle **le plugin**, pas son graphe. C'est la seule
limite honnête de SC-008 — elle est écrite, pas maquillée.

**À re-vérifier à l'ouverture du cycle (constitution X)** : rien de bloquant n'est en suspens — la
chaîne compile, génère, analyse et teste, vérifié de bout en bout. Le seul risque est le **temps** :
si une version paraît d'ici l'ouverture, rejouer `flutter pub add` sur les 3 paquets réels et
**re-tester le plafond `build_runner`**. Point non levé, à mesurer en première tâche : où
l'analysis server cache-t-il le paquet synthétique du plugin (ni `.dart_tool/`, ni `~/.dartServer`),
et **`dart analyze` exige-t-il le réseau en CI** ? Si oui, l'étape d'analyse devient dépendante de
pub.dev.

**Alternatives considérées** : **`resolution: workspace`** — pour : une seule résolution, accord par
construction ; contre, décisif : il **supprime** les 3 lockfiles au profit d'un seul à la racine, or
SC-008 exige littéralement « **les trois** lockfiles commités, accordés entre eux » — le critère
deviendrait invérifiable au sens où il est écrit ; `apps.yml:19-28` repose sur une matrice
`working-directory` par paquet, à refondre ; il faut un pubspec racine, donc englober ou exclure
`clients/dart`, `web/`, `backend/` — un choix de structure de monorepo. Et l'accord est **déjà** à
0 désaccord : gain réel **nul aujourd'hui**. **Un refactor d'état dont l'invariant est « aucun
changement visible » (FR-001) ne restructure pas la résolution du monorepo** → à proposer comme
cycle TRX distinct. · **Résolution fraîche des 3 paquets** (le geste « propre ») : casse l'accord
sur `uuid`, donc SC-008, pour zéro bénéfice. · **`custom_lint`** : insoluble (ci-dessus).

## R2 — Outillage et analyse statique : ZÉRO relâchement de lint, AUCUN `build.yaml`, AUCUNE ligne de `.gitignore`

**Décision** : l'outillage se réduit à trois ajouts de dépendances et trois blocs `plugins:`.

| Paquet | `dependencies` | `dev_dependencies` | `plugins:` |
|---|---|---|---|
| `mefali_core` | `flutter_riverpod: ^3.3.2`, `riverpod_annotation: ^4.0.3` | `riverpod_generator: ^4.0.4`, `build_runner: ^2.15.1` | `riverpod_lint: 3.1.4` |
| `mefali_pro` | idem | idem | `riverpod_lint: 3.1.4` |
| `mefali_client` | **`flutter_riverpod: ^3.3.2` SEUL** | **AUCUNE** | `riverpod_lint: 3.1.4` |

Fichier final de `mefali_core` — la section `plugins:` est **top-level**, pas sous `analyzer:` :

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true

# riverpod_lint ≥ 3.1.0 est un plugin `analysis_server_plugin` (plus de custom_lint).
# Section TOP-LEVEL : sous `analyzer:` c'est le système legacy, et il serait IGNORÉ.
# ⚠ Et le bloc `plugins:` NE MARCHE PAS EN FICHIER INCLUS/IMBRIQUÉ : il n'est lu que
# dans l'`analysis_options.yaml` du paquet lui-même. CHACUN des 3 paquets porte donc son
# propre bloc — la duplication est STRUCTURELLE, pas une négligence. Le dépôt utilise
# déjà `include: package:flutter_lints/flutter.yaml` : factoriser le bloc dans un fichier
# inclus est LE geste naturel, et il rend riverpod_lint SILENCIEUX — MÊME MODE DE PANNE
# que `flutter analyze` (R12), c'est-à-dire le risque n°1 du cycle : une CI verte qui ne
# vérifie rien. C'est aussi pourquoi le pin `3.1.4` est contrôlé par script sur les 3
# fichiers (SC-008) plutôt que tenu par un include.
# Version EXACTE : le plugin est résolu par l'analysis server HORS pubspec.lock ;
# ce pin est son seul gel (SC-008, R1) et doit être identique dans les 3 paquets.
# ⚠ `flutter analyze` NE charge PAS les plugins : la CI utilise `dart analyze` (R12).
plugins:
  riverpod_lint:
    version: 3.1.4
    # FR-033 — 12 des 15 règles sont WARNING (dart analyze → exit 2), riverpod_syntax_error
    # est ERROR. Les 3 ci-dessous sont INFO (LintCode.severity vaut INFO par défaut,
    # analyzer-12.1.0/lib/src/dart/error/lint_codes.dart:60) : sans escalade, `dart analyze`
    # sort en 0 et elles sont exactement les « avertissements ignorables » que FR-033 refuse.
    # `analyzer: errors:` NE LES ATTEINT PAS (vérifié : unrecognized_error_code, forme nue
    # comme namespacée) — SEUL `diagnostics:` fonctionne.
    diagnostics:
      avoid_public_notifier_properties: error
      avoid_build_context_in_providers: error
      protected_notifier_properties: error
```

`mefali_pro` / `mefali_client` : `errors: {invalid_annotation_target: ignore}` et `exclude:`
**inchangés** (gen-l10n, préexistants) ; **SEUL le bloc `plugins:` est ajouté**.

**Rationale** — chaque non-ajout est vérifié, aucun n'est une omission :
- **`mefali_client` n'a ni generator, ni `build_runner`, ni `riverpod_annotation`** :
  `riverpod_generator/build.yaml` déclare `auto_apply: dependents` — le builder ne s'active que sur
  les paquets dépendant de `riverpod_annotation`. Il lui faut `flutter_riverpod` pour
  `ProviderScope` (FR-010), et c'est tout — et c'est le paquet où `riverpod_lint` sert le plus
  (`missing_provider_scope`). Il ne dépend ni de `mefali_api_client` ni de `dio` : impact **nul**,
  les deux sont déjà `transitive` via `mefali_core` (path). **Le nœud session reste confiné à
  `mefali_core`** (R3).
- **`build.yaml` : AUCUN, dans les 3 paquets.** `riverpod_generator` livre le sien :
  `generate_for: exclude [test, example]` restreint **déjà** à `lib/**`, `auto_apply: dependents`
  câble déjà l'activation, `build_to: cache` fait déjà transiter par `.dart_tool/` (gitignoré,
  `.gitignore:23`). Un `build.yaml` local **recopierait le défaut et le figerait** — donc le ferait
  diverger silencieusement à la prochaine montée. **Aucun `build.yaml` n'existe dans le dépôt : ne
  pas en introduire.** Mesuré : 15 s à froid pour 1 input — il n'y a rien à accélérer.
  Corollaire : `--delete-conflicting-outputs` est **SUPPRIMÉ** de build_runner 2.15.x (« *These
  options have been removed and were ignored* ») — la commande est **`dart run build_runner build`**,
  nu.
- **`analysis_options.yaml` : le minimum nécessaire (FR-032) est ZÉRO relâchement.** Vérifié par
  exécution sous les options **exactes** de `mefali_core` (`strict-casts` + `strict-raw-types`),
  `.g.dart` généré présent → **`No issues found!`, EXIT 0**. Deux raisons : `riverpod_generator` **ne
  déclenche pas** `invalid_annotation_target` (ce diagnostic vient de `freezed`/`json_serializable`,
  absents du dépôt ; les deux apps le portent pour leur gen-l10n, pas pour Riverpod) ; et le `.g.dart`
  **s'auto-neutralise** — vérifié en tête du fichier généré : `// ignore_for_file: type=lint,
  type=warning`. ⇒ **`exclude: *.g.dart` : NON** — ce serait « désactiver par confort » au sens
  FR-032 alors que **rien n'est à désactiver**, et l'exclusion supprimerait la seule vérification que
  le GÉNÉRÉ compile sous les options du paquet.
- **`.gitignore` : AUCUNE modification.** Vérifié par `git check-ignore -v` : les `.g.dart` des 3
  paquets ne sont **pas** ignorés (aucun motif `*.g.dart` ; `.gitignore:21
  apps/*/lib/l10n/app_localizations*.dart` ne matche pas `apps/packages/mefali_core/`, dont la sortie
  s'appelle `mefali_core_localizations.dart`). **FR-029 fonctionne sans rien toucher.**
- **`clients/dart` : hors périmètre (FR-006/FR-027), risque prouvé nul.** Les `dev_dependencies`
  d'une dépendance `path:` **ne participent pas** à la résolution du paquet dépendant :
  `built_value_generator` est **ABSENT** du lock de `mefali_core`. Symétriquement, `riverpod_generator`
  n'entrera **jamais** dans la résolution de `clients/dart`. Deux chaînes **étanches**. Le
  `build_runner: any` (`clients/dart/pubspec.yaml:19`) + lock gitignoré (`.gitignore:28`) y est un
  défaut latent **préexistant** → consigné (FR-027), **non corrigé**.

⚠ **`diagnostics: <règle>: error` est UNDOCUMENTÉ** (la doc `using_plugins.md` ne montre que
`true`/`false`). Il fonctionne sur Dart 3.12.2 (vérifié : EXIT 3). Si un SDK futur le retire, les 3
règles INFO **retombent en silence** et FR-033 cesse d'être tenu sans que rien ne rougisse. **Le
garde-fou est l'Independent Test d'US1**, à conserver dans le quickstart : introduire volontairement
`avoid_public_notifier_properties` et exiger `dart analyze` → **exit 3**. Les **15 règles** (source :
`riverpod_lint-3.1.4/lib/main.dart` ; `grep -c registerWarningRule` → 15, `registerLintRule` → 0) :
`async_value_nullable_pattern`, `avoid_build_context_in_providers`ⁱ, `avoid_public_notifier_properties`ⁱ,
`avoid_ref_inside_state_dispose`, `functional_ref`, `missing_provider_scope`, `notifier_build`,
`notifier_extends`, `only_use_keep_alive_inside_keep_alive`, `protected_notifier_properties`ⁱ,
`provider_dependencies`, `provider_parameters`, `riverpod_syntax_error`ᴱ,
`scoped_providers_should_specify_dependencies`, `unsupported_provider_value` (ⁱ = INFO à escalader ;
ᴱ = ERROR d'office ; le reste = WARNING). Suppression ponctuelle si jamais nécessaire :
`// ignore: riverpod_lint/<code>` — **namespacé**.

**Alternatives considérées** : **`dart analyze --fatal-infos`** (vérifié : EXIT 1) — repli documenté
si `diagnostics:` disparaît, écarté en premier choix car il vit dans le YAML de CI (donc **ni dans
l'IDE ni en local**) et change le régime de **tous** les infos `flutter_lints`, ce qu'un refactor pur
n'a pas à faire. · **`analyzer: errors: avoid_public_notifier_properties: error`** : ne fonctionne
**pas** (vérifié : `unrecognized_error_code`, forme nue comme namespacée) — la voie intuitive est un
cul-de-sac. · **`exclude: '**/*.g.dart'`** : relâchement au sens FR-032, et perte de la seule preuve
que le généré passe les options strictes. · **`build.yaml` local par paquet** : fige un défaut qu'on
ne contrôle pas.

## R3 — Le nœud client/intercepteur/session : quatre unités, AUCUN cycle, l'intercepteur détient le `Ref` de `clientSession` — JAMAIS le notificateur

**Décision** : quatre providers `keepAlive`, un graphe acyclique à **deux racines indépendantes**,
et l'arête `intercepteur → session` reléguée au **runtime**, hors du graphe.

```dart
@Riverpod(keepAlive: true)                    // FR-012 : le cœur ne lit JAMAIS l'environnement
String urlApi(Ref ref) => throw UnimplementedError(
      'urlApiProvider doit être surchargé dans le point d\'entrée : '
      'ProviderContainer(overrides: [urlApiProvider.overrideWithValue(_urlApi)]).');

@Riverpod(keepAlive: true)
MefaliApiClient clientSession(Ref ref) {
  // Ni `dio:` ni `interceptors:` : les délais 5000/3000 ms ne vivent QUE dans la branche
  // `dio ?? Dio(BaseOptions(...))` (clients/dart/lib/src/api.dart:30-35), et passer
  // `interceptors:` REMPLACE les 4 intercepteurs générés (api.dart:36-45) au lieu de s'y
  // ajouter. Ce n'est PAS un point d'extension. (FR-017)
  final client = MefaliApiClient(basePathOverride: ref.watch(urlApiProvider));
  final intercepteur = InterceptorAutorisation(ref, client);
  client.dio.interceptors.add(intercepteur);
  ref.onDispose(() => client.dio.interceptors.remove(intercepteur));   // FR-018
  return client;
}

@Riverpod(keepAlive: true)
MefaliApiClient clientConfig(Ref ref) =>                                // FR-017
    MefaliApiClient(basePathOverride: ref.watch(urlApiProvider));

class InterceptorAutorisation extends Interceptor {
  InterceptorAutorisation(this._ref, this._client);
  final Ref _ref;                 // celui de clientSession — PAS celui de Session
  final MefaliApiClient _client;  // capturé : AUCUNE lecture de provider pour le dio
  Future<bool>? _enCours;         // INCHANGÉ (session_auth.dart:88) — voir R7

  @override
  void onRequest(o, h) {
    final acces = _ref.read(sessionProvider).acces;   // l'ÉTAT (classe nue), jamais le notifier
    if (acces != null) o.headers['Authorization'] = 'Bearer $acces';
    h.next(o);
  }
  // onError : _ref.read(sessionProvider.notifier).ouvrir/fermer   // ACTIONS (méthodes)
}
```

`sessionProvider` **n'a AUCUN besoin du client** — le renouvellement vit dans l'intercepteur, qui
capture `_client` : le `ref.watch(clientSessionProvider)` qu'invitait l'idiome est une arête
**inutile**, supprimée. Conséquence de découplage exigée par l'input du cycle : **`SessionAuth.client`
disparaît** (`session_auth.dart:25`) ; ses consommateurs (`etat_roles.dart:161`, `ListeAdresses`,
`EcranAppareils`, `ParcoursAuth`, `FormulaireDossierCoursier`) lisent `clientSessionProvider`. Idem
`SessionAuth.stockage` et `EtatRoles.session`.

**Décision jointe — l'ordre `state =` / I/O : `state = …` PUIS `await` l'I/O.** Le code réel fait
`_jetons = jetons;` → `await stockage.ecrire(jetons);` → `notifyListeners();`
(`session_auth.dart:51-53` ; idem `fermer()` `:63-65`) — trois temps. Sous Riverpod, `state =`
**fusionne** le 1ᵉʳ et le 3ᵉ : les deux ordres ne peuvent pas être préservés ensemble. On garde
l'ordre que l'intercepteur voit.

**Rationale** :
1. **C'est le SEUL montage qui passe `dart analyze`** — vérifié par exécution. La variante « `Session`
   expose `acces`/`rafraichissement` en getters publics » → `avoid_public_notifier_properties`
   **error**, EXIT 3 ⇒ SC-006 tombe. La variante « l'intercepteur lit `_session.state` » →
   `invalid_use_of_protected_member` **+** `invalid_use_of_visible_for_testing_member` — diagnostics
   **cœur**, hors de portée de **toute** configuration de plugin. Lire **l'état**
   (`ref.read(sessionProvider)` → `EtatSession`, une classe nue) et appeler des **méthodes**
   (`ref.read(sessionProvider.notifier).fermer()`) ne déclenche **rien** : sonde `dart analyze` →
   **EXIT 0**.
2. **FR-013 devient structurel, pas testé.** L'intercepteur est posé par `clientSession`, qui **ne
   dépend d'AUCUN état mutable** : une ré-évaluation de `sessionProvider` ne touche **JAMAIS** au dio.
   Le mode de panne n°1 de la spec (`spec.md:146` — deux intercepteurs, deux renouvellements
   concurrents, jeton tourné rejoué, vol présumé, **session révoquée**) devient **inatteignable**, pas
   seulement couvert.
3. **AUCUN notificateur zombie.** L'intercepteur tient un `Ref`, pas un `this` : après une
   invalidation, `_ref.read(sessionProvider.notifier)` résout la **nouvelle** instance. Capturer
   `this` laisserait un `Session` disposé joignable depuis le dio jusqu'à ce qu'`onDispose` coupe
   l'arête.
4. **Sanctionné en amont** : [riverpod#2107](https://github.com/rrousselGit/riverpod/discussions/2107)
   — « *You can't do that without passing `Ref`* » ; container global / get_it / event bus =
   anti-pattern explicite.
5. **`urlApi` `throw` plutôt qu'un défaut** : une valeur par défaut dans le cœur — même
   `'http://localhost:8080'`, littéralement celle des deux `main.dart:9-10` — reviendrait à faire
   **posséder au paquet cœur la valeur d'environnement que FR-012 lui interdit de connaître**. Et une
   app qui oublie l'override **partirait silencieusement sur `localhost`**, c'est-à-dire l'appareil
   lui-même — le piège documenté dans `CLAUDE.md` §Commandes. Le `throw` échoue **au premier `read`,
   au lancement, avec le message qui dit quoi faire**. Coût de l'override : nul. Coût de l'oubli : une
   heure de débogage réseau. Vérifié : `Override overrideWithValue(ValueT value)` existe bien sur
   `Provider` (`riverpod-3.3.2/lib/src/providers/provider.dart:114`) et fonctionne sur un provider
   généré depuis une fonction **synchrone** ; signature `Ref` **non générique** (`String urlApi(Ref
   ref)`) confirmée, `dart analyze` EXIT 0.
6. **L'ordre A (`state =` d'abord)** : ce que l'intercepteur voit (`state.acces`) change
   **immédiatement**, comme aujourd'hui. Sous B (`await ecrire(); state = …`), une requête concurrente
   partie pendant les deux écritures Keystore porterait **l'ancien jeton** → 401 → **une requête
   ajoutée** → **FR-002 violé** (« aucune ajoutée ») ; symétriquement, `fermer()` porterait encore
   l'en-tête d'un jeton mort. Sous A, la seule dérive est que `RacineAuth` rebâtit **une frame plus
   tôt**, et FR-001 borne à « mêmes temporisations **perceptibles** ». **Un 401 surnuméraire est un
   absolu (FR-002) ; une frame ne l'est pas.** *À consigner (FR-027)* : sous A, si
   `stockage.ecrire/effacer` **lève**, l'UI a déjà basculé — aujourd'hui elle ne bascule pas, mais
   l'état mémoire est déjà muté, donc le défaut existe déjà, dans l'autre sens. Aucun test ne
   l'atteint, aucun chemin produit ne le traverse.

**Vérifié par exécution** (`scratchpad/sonde/test/noeud_test.dart`, 4 tests verts) : lecture croisée
runtime `clientSession.ref → read(sessionProvider)` ⇒ **aucune erreur de cycle**, en-tête posé/absent
correctement ; **FR-013** ⇒ `poses() == 1` après première évaluation, après `invalidate(sessionProvider)`,
après `fermer()/ouvrir()/ouvrir()`, après `invalidate(clientSessionProvider)`, et `clientConfig` → **0** ;
**FR-018** ⇒ `container.dispose()` → **0** ; **FR-003** ⇒ `ouvrir()` → 1 émission, deux `ouvrir()` à
jetons identiques → **2** émissions.

**Alternatives considérées** : **provider HTTP unique** (`client(avecSession: bool)` en famille, ou
fusion pure) — le client de config porterait un `Authorization` qu'il n'a **jamais** porté (edge case
nommé, `spec.md:156`), et en famille l'invariant FR-017 devient **invisible en revue** sans que rien ne
l'empêche mécaniquement ; deux providers nommés d'une ligne chacun rendent FR-017 vérifiable **par
lecture du graphe** — `clientConfig` n'est lu que par `sourceConfig`, et seul `clientSession` pose un
intercepteur, **sans aucune assertion runtime**. · **`MefaliApiClient(dio: …)`** : perd les timeouts
5000/3000 ms (`api.dart:32-34`), qui ne vivent que dans la branche par défaut — FR-017. ·
**`ref.watch(clientSessionProvider)` dans `Session`** (proposé par deux rapports) : arête inutile qui
recouple ce que le cycle a pour mandat de découpler. · **Intercepteur capturant le `Session`
(`this`)** : notificateur zombie après invalidation. · **Ordre B (`await` l'I/O puis `state =`)** :
401 surnuméraire, FR-002.

## R4 — Les durées de vie : `keepAlive: true` ×8 contre `@riverpod` nu ×3, l'opposition centrale que AUCUN lint ne garde

**Décision** :

| Provider | Réglage | Pourquoi c'est un comportement, pas un réglage |
|---|---|---|
| `urlApi`, `clientSession`, `clientConfig`, `stockageJetons`, `session`, `serviceConfig` | `@Riverpod(keepAlive: true)` | FR-019 : ils naissent au lancement et vivent **tout le processus** ; le rafraîchissement horaire ne s'arrête **JAMAIS**. |
| `sourceConfig`, `cacheConfig` | `@Riverpod(keepAlive: true)` | Ce sont les **dépendances** de `serviceConfig`, lui-même `keepAlive` (R5) : en autoDispose elles seraient **reconstruites sous lui** — une source neuve, un cache neuf, sous un service qui, lui, ne redémarre jamais (FR-019). La durée de vie d'une dépendance ne peut pas être plus courte que celle de son consommateur. |
| `etatRoles` | `@riverpod` **nu** (autoDispose) **+ `ref.watch(sessionProvider.select((e) => e.connecte))`** | FR-020/SC-010 : **garantie de sécurité**, pas de performance. |
| `mesAdresses`, `mesSessions` | `@riverpod` nu | Écrans de listes ; aucun état à faire survivre. |

**Rationale** :
- **`@riverpod` nu EST autoDispose** — c'est **le défaut du générateur**, et **le mode de panne n°2 de
  la spec** (`spec.md:147`). Vérifié dans le `.g.dart` : `@Riverpod(keepAlive: true)` →
  `isAutoDispose: false`, `@riverpod` → `isAutoDispose: true` ; et `Riverpod({this.keepAlive = false,
  …})` (`riverpod_annotation-4.0.3/lib/src/riverpod_annotation.dart:24`). Un `@riverpod` nu sur la
  session ou la config détruirait l'objet dès le dernier auditeur parti : soit le rafraîchissement
  horaire s'arrête et redémarre — comportement **qui n'existe pas aujourd'hui** —, soit chaque nouvelle
  souscription relit le cache et redemande la config au serveur (FR-002).
- **`autoDispose` SEUL ne suffit PAS pour les rôles** : la destruction autoDispose est **planifiée**,
  pas synchrone ; Riverpod 3 **met en pause** les providers hors-champ (`TickerMode`) et **un provider
  en pause n'est PAS détruit** — qu'un futur cycle ajoute un `ref.listen` ou un provider `keepAlive` qui
  lise les rôles, et l'état survit au changement de compte ; enfin, rien dans le code ne dirait
  *pourquoi* c'est autoDispose. Le `ref.watch(sessionProvider.select(…))` **grave l'arête** : session
  fermée ⇒ provider invalidé ⇒ `build()` rejoué ⇒ **état vide AVANT tout rendu**, même si quelqu'un met
  `keepAlive: true` demain. C'est FR-020 rendu structurel.
- **`.select` n'est pas une optimisation, c'est une correction de bug.** `ref.watch(sessionProvider)`
  nu serait **FAUX** : l'intercepteur appelle `ouvrir()` à **chaque rotation de jeton** ⇒ les rôles se
  rechargeraient à chaque renouvellement silencieux ⇒ **requête ajoutée (FR-002)** + `ChargementPro` en
  plein parcours (FR-001), **sur un chemin que seul un 401 déclenche — donc jamais en test**.
- **`connecte` est le proxy d'identité de compte.** `SessionAuth` n'expose aucun identifiant
  (`session_auth.dart:31-40`) et `acces` tourne. Aucun changement de compte n'est possible sans passer
  par `fermer()` (le parcours OTP l'exige), donc `true → false → true` encadre **toujours** une bascule.
  **Hypothèse datée à consigner** : le jour où un « changement de compte à chaud » existera, ce proxy
  tombe.

⚠ **AUCUN lint ne garde cette opposition** — c'est l'invariant central du cycle et il n'a pas d'outil.
`only_use_keep_alive_inside_keep_alive` porte sur `KeepAliveLink`, **pas** sur le sens des dépendances,
et **`avoid_keep_alive_dependency_inside_auto_dispose` N'EXISTE PAS** (deux rapports l'avaient
inventée ; les 15 règles réelles sont listées en R2). Les deux réglages opposés ne sont tenus que par
les tests (SC-005, SC-010) et la revue.

**Vérifié par exécution** (`scratchpad/sonde/test/vies_test.dart`, 3 tests verts) : rotation de jeton →
**0 rechargement** des rôles ; `fermer()` → état des rôles **vide** ; `serviceConfig` keepAlive → timer
à 0 h, 1 h, **2 h sans aucun auditeur**, puis coupé par `container.dispose()`.

**Alternatives considérées** : **`ref.invalidate(etatRolesProvider)` dans `fermer()`** — inverse la
dépendance (`mefali_core` connaîtrait un provider de `mefali_pro` : impossible), et un `invalidate`
s'oublie tandis qu'un `watch` est une **arête**. · **`keepAlive` sur les rôles** : mode de panne n°3 de
la spec (`spec.md:148`) — les rôles du compte précédent fuitent, régression de sécurité **silencieuse**.
· **`autoDispose` sur session/config** : mode de panne n°2 (`spec.md:147`). · **`ref.watch(sessionProvider)`
sans `.select`** : rechargement à chaque rotation de jeton (ci-dessus).

## R5 — La configuration reste gelée : `Raw<Future<ServiceConfig>>`, `keepAlive`, le provider HÉBERGE le service et ne l'observe JAMAIS — et `demarrerServiceConfig` CHANGE DE SIGNATURE

**Décision** : `ServiceConfig` reste une **classe nue** (`service_config.dart:19`) ; le provider expose
un `Future` dessus, jamais une valeur observée (FR-021, clarification du 2026-07-17). **Et
`demarrerServiceConfig` reçoit désormais `source` et `cache` au lieu de les construire** — c'est un
**changement de code de PRODUCTION**, tranché ici et nommé comme tel.

```dart
// amorce_config.dart — l'inversion d'injection demandée par le cycle (FR-010, FR-035) :
// la fonction REÇOIT source et cache au lieu de les construire.
// AVANT (amorce_config.dart:14-22) : demarrerServiceConfig({String? urlApi}) faisait
// LUI-MÊME `await SharedPreferences.getInstance()`, `SourceConfigApi(MefaliApiClient(...))`
// et `CacheConfigPreferences(prefs)` — donc AUCUNE surcharge de portée ne pouvait l'atteindre.
Future<ServiceConfig> demarrerServiceConfig({
  required SourceConfig source,
  required CacheConfig cache,
}) async {
  final service = ServiceConfig(source: source, cache: cache);
  await service.demarrer();
  return service;
}

/// Le cache local de configuration. `CacheConfigPreferences(this._prefs)` exige un
/// `SharedPreferences` (`cache_config.dart:16-20`), obtenu par
/// `SharedPreferences.getInstance()` — ASYNCHRONE : un `Provider<CacheConfig>` synchrone ne
/// peut PAS le construire. Même doctrine `Raw` que `serviceConfig` : pas d'`AsyncValue`,
/// donc pas de retry (R10).
@Riverpod(keepAlive: true)
Raw<Future<CacheConfig>> cacheConfig(Ref ref) =>
    SharedPreferences.getInstance().then(CacheConfigPreferences.new);

/// FR-021 — le provider expose le SERVICE (un Future dessus), JAMAIS une valeur observée.
/// `Raw` rend un `Provider` de Future : PAS de FutureProvider, donc AUCUN AsyncValue à
/// émettre et AUCUN retry automatique (FR-019, R10).
@Riverpod(keepAlive: true)
Raw<Future<ServiceConfig>> serviceConfig(Ref ref) {
  // Les deux `ref.watch` sont SYNCHRONES — c'est ce qui garde la fonction du provider
  // synchrone, donc son type `Raw<…>` et non un `FutureProvider`. L'attente du cache vit
  // DANS le futur rendu, pas dans le corps du provider.
  final source = ref.watch(sourceConfigProvider);
  final cacheFutur = ref.watch(cacheConfigProvider);   // Raw<Future<CacheConfig>>
  final futur = cacheFutur.then(
    (cache) => demarrerServiceConfig(source: source, cache: cache),
  );
  ref.onDispose(() => futur.then((s) => s.arreter()).ignore());   // FR-018
  return futur;
}
```

`urlApi` **ne descend plus ici** : il descend dans `clientConfigProvider` (R3), que `sourceConfig`
`watch` déjà (`SourceConfigApi(ref.watch(clientConfigProvider))`). L'arête
`urlApi ▶ clientConfig ▶ sourceConfig ▶ serviceConfig` remplace le `ref.watch(urlApiProvider)` direct —
FR-017 cesse d'être nominal : le trafic de config passe **réellement** par `clientConfigProvider`.

Les **deux consommateurs** deviennent des `ConsumerStatefulWidget` ; `_lireVersionConsentement()`
(`racine_auth.dart:70-77`) et `_lireTransports()` (`routeur_roles.dart:58-67`) gardent leur corps, avec
**`ref.read`, JAMAIS `ref.watch`** — l'instantané est figé à l'entrée de l'écran. `_versionConsentement`
et `_transportsActifs` restent de l'**état local** (FR-009) : ils **SONT** l'instantané.
`versionConsentement:` / `transportsActifs:` restent des **paramètres** de `ParcoursAuth` /
`EcranEtatDemande` / `FormulaireDossierCoursier` — c'est FR-021 rendu littéral.

**Rationale** — quatre propriétés qu'aucune autre forme ne réunit :
0. **Le changement de signature EST l'inversion d'injection que le cycle demande (FR-010, FR-035) — ce
   n'est PAS une correction opportuniste au sens FR-027.** FR-035 exige littéralement que « la source et
   le cache de configuration **deviennent des surcharges de portée** ». Or `demarrerServiceConfig({String?
   urlApi})` **construit lui-même** ses deux collaborateurs (`amorce_config.dart:14-22`) : tant que la
   fonction les fabrique, **aucune surcharge de `sourceConfigProvider`/`cacheConfigProvider` ne peut
   l'atteindre** — les surcharger ne changerait **RIEN**, les 23 cas de `mefali_pro` appelleraient quand
   même le vrai `SharedPreferences` (canal de plateforme) et le vrai réseau. Sans ce changement,
   `clientConfig`, `sourceConfig` et `cacheConfig` sont **3 providers orphelins** que rien ne lit, FR-035
   n'est **pas** tenu, et le harnais livre sa garantie phare **en la croyant tenue**. FR-027 interdit de
   réparer *en passant* des défauts **hors périmètre** ; ici l'injection **est** le périmètre — c'est
   l'objet même de FR-010. La distinction est à tenir : on ne touche pas au **corps** de `demarrer()`, ni
   au comportement, seulement à **qui fournit** les collaborateurs.
1. **Type identique à aujourd'hui.** `Future<ServiceConfig>`, exactement `RacineAuth.config`
   (`racine_auth.dart:38`) et `RouteurRoles.config` (`routeur_roles.dart:29`). Les deux consommateurs
   gardent leur `await` dans un `try/catch`. Diff par méthode : `widget.config` →
   `ref.read(serviceConfigProvider)`, et la garde `if (config == null) return;` disparaît. **Portage
   relisible à l'œil — le seul critère qui vaille quand la couverture est nulle** (`spec.md:274`).
2. **Non-réactivité STRUCTURELLE, pas disciplinaire.** Un `Provider<Future<T>>` **n'a pas d'`AsyncValue`
   à émettre** : FR-021 devient **impossible à violer**, et un futur cycle qui voudrait rendre la config
   vivante devra **changer le type** — geste visible en revue. `typedef Raw<WrappedT> = WrappedT;`
   (`riverpod_annotation-4.0.3/lib/src/riverpod_annotation.dart:213`) ; vérifié dans le `.g.dart` :
   `$Provider<Raw<Future<ServiceConfig>>>`, `isAutoDispose: false`.
3. **Immunisé contre le retry.** Un `FutureProvider<ServiceConfig>` en échec serait **réessayé** (R10)
   ⇒ nouveau `ServiceConfig` ⇒ **nouveau Timer** ⇒ FR-019 (« ne jamais s'arrêter ni redémarrer ») **et**
   FR-002 violés d'un coup.

⚠ **Le piège que ce diff ouvre — le harnais DOIT le fermer (R11).** `config` est **nullable** aujourd'hui
et **tous les tests l'omettent** (`RouteurRoles(session: session)`, `routeur_roles_test.dart:99`) ⇒
`_lireTransports()` sort ligne 60 sans rien faire. Une fois `config` remplacée par un provider, **il n'y
a plus de `null`** : les 23 cas de `mefali_pro` déclencheraient le vrai `demarrerServiceConfig` →
`SharedPreferences.getInstance()` (canal de plateforme !) + appel réseau réel. `conteneurMefali` DOIT
surcharger `sourceConfigProvider`/`cacheConfigProvider` **par défaut** — c'est le mécanisme exact par
lequel « 0 requête ajoutée » (SC-004) se perdrait en test **sans qu'aucune assertion ne bronche**. **Et
ces deux surcharges ne mordent QUE grâce à la signature ci-dessus** : contre l'ancienne, elles seraient
un décor — le mode de panne serait **identique, en se croyant fermé**.

⚠ **Écart au principe VII, assumé et consigné** : les deux méthodes ci-dessus sont **les seules que la
migration réécrit sans qu'aucun des 86 cas ne les couvre** — aucun test ne passe de configuration
(`spec.md:274`). SC-009 se vérifie **sur émulateur**, pas en test. → Complexity Tracking du plan.

**Alternatives considérées** : **surcharger `serviceConfigProvider` par défaut dans `conteneurMefali`,
signature de production INCHANGÉE** — l'échappatoire tentante, et **ça marcherait** : les 23 cas ne
toucheraient ni le canal de plateforme ni le réseau. Écartée pour deux raisons : **FR-035 nomme *source
et cache*, pas le service** — surcharger le sujet plutôt que ses dépendances contredit frontalement la
règle du cycle (« on surcharge les DÉPENDANCES, JAMAIS le sujet », R11) ; et un `ServiceConfig` factice
en test **ne prouve plus** que le vrai service sait retomber sur son cache, alors qu'un faux `cache` +
un faux `source` laissent le service **réel** sous test. · **`ServiceConfig serviceConfig(Ref ref)`
synchrone** — impossible sans `async` : `demarrerServiceConfig` attend `demarrer()`, et le cache attend
`SharedPreferences.getInstance()` ; le rendre synchrone **déplacerait l'amorçage** (FR-002/FR-024). ·
**`CacheConfig cacheConfig(Ref ref)` synchrone** : **ne compile pas** — le constructeur exige un
`SharedPreferences` qui ne s'obtient qu'`await` (`cache_config.dart:16-20`). · **`FutureProvider<ServiceConfig>`** — le plus
idiomatique et le plus faux : il expose un `AsyncValue`, donc FR-021 ne tiendrait plus que par la
discipline `read` vs `watch` (un `watch` par inadvertance et la config devient vivante, `spec.md:149`),
et il est soumis au retry ⇒ FR-019. · **Instantané `ConfigDistante` figé dans un provider** : on perdrait
le Timer, pas la réactivité — FR-019.

## R6 — Les deux sémantiques de chargement : deux classes d'état nues, `Notifier`, `updateShouldNotify => true` EXPLICITE sur les deux

**Décision** : `session` et `etatRoles` sont des `Notifier<Etat…>` sur des classes immuables
**volontairement sans `operator ==`**, avec `updateShouldNotify` surchargé à `true`. FR-022 exige deux
sémantiques **opposées** : `session.charge` est **monotone** (l'écran de démarrage ne peut PAS
réapparaître), `etatRoles.charge` **ne l'est pas** (le rechargement réaffiche `ChargementPro`).

```dart
/// État de session. Classe IMMUABLE, volontairement SANS `operator ==`.
@immutable
class EtatSession {
  const EtatSession({required this.charge, this.jetons});
  const EtatSession.initiale() : charge = false, jetons = null;
  /// `true` une fois le stockage relu. NE REDEVIENT JAMAIS `false` (FR-022).
  final bool charge;
  final JetonsSession? jetons;
  bool get connecte => jetons != null;
  String? get acces => jetons?.acces;
  String? get rafraichissement => jetons?.rafraichissement;
}

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  EtatSession build() => const EtatSession.initiale();   // NE dépend PAS du client (R3)

  /// Traduction FIDÈLE de `ChangeNotifier` : `notifyListeners()` émet TOUJOURS, sans
  /// comparer, et `RacineAuth` rebâtit à chaque appel (racine_auth.dart:82,
  /// ListenableBuilder, sans filtre). Le défaut v3 (`==`) filtrerait les écritures égales
  /// et rendrait `expect(emissions, 1)` plus FAIBLE que l'assertion d'origine
  /// (FR-003/FR-004). Ne PAS « optimiser ».
  @override
  bool updateShouldNotify(EtatSession previous, EtatSession next) => true;
}
```

**Rationale** :
- **`Notifier`, PAS `AsyncNotifier`, pour la session.** `AsyncNotifier.build()` **démarre en
  `AsyncLoading`** et y **retourne** à chaque `refresh`/`invalidate`/retry ⇒ l'écran de démarrage
  **réapparaîtrait en plein parcours** — FR-022 l'interdit nommément. Et `charger()` migrerait dans
  `build()` : le premier rendu deviendrait contingent d'un `Future`, alors que `racine_auth.dart:12-17`
  documente l'inverse (« bloquer le lancement sur une lecture de Keystore ferait clignoter un écran
  blanc »). `Notifier<EtatSession>` + `charge: bool` + `charger()` impératif depuis `initState` est la
  transposition **exacte** de `racine_auth.dart:59`.
- **`charge` DOIT faire partie de la valeur d'état**, comme `_charge` est un champ aujourd'hui
  (`session_auth.dart:28`). Si l'état était `JetonsSession?` nu, `charger()` sur un stockage **vide**
  ferait `null → null` ⇒ **aucune émission** ⇒ `RacineAuth` ne quitterait **JAMAIS** l'écran de
  démarrage ⇒ `session_auth_test.dart:99-107` échouerait. Mode de panne silencieux du fichier.
- **`updateShouldNotify => true` plutôt que « classe sans `==` » seule.** La v3 a **changé** le filtrage
  : « *All providers now use `==` to filter updates* », et le guide de migration minimise ce changement
  ([#4310](https://github.com/rrousselGit/riverpod/issues/4310)). Une classe sans `==` marche **par
  accident** : le jour où quelqu'un ajoute `Equatable`/`freezed`, les émissions fusionnent et
  `expect(emissions, 1)` **reste vert en prouvant moins** — exactement le mode de panne que FR-004
  nomme. `updateShouldNotify` est `@visibleForOverriding` (`notifier_provider.dart:136`), l'override est
  légal et **ne déclenche AUCUN lint** (vérifié). **On prend les deux** : classe sans `==` *et* override
  explicite. Le test additionnel « deux `ouvrir()` à jetons identiques ⇒ `expect(emissions, 2)` » est ce
  qui rougit si quelqu'un retire l'override.
- **Les rôles sont l'inverse, et `AsyncValue` ne peut pas les modéliser** : `charge` y est **non
  monotone** (`etat_roles.dart:156-158` le remet à `false` **et notifie** ⇒ `ChargementPro` réapparaît,
  `routeur_roles.dart:82`), et `AsyncValue` **fusionnerait `charge` et `enErreur`**, qui sont
  **orthogonaux** ici : sur erreur, `etat_roles.dart:189-192` produit `charge: true` **ET**
  `enErreur: true`, **attributions conservées**. En `AsyncError`, la branche `ErreurPro`
  (`routeur_roles.dart:83`) devrait être reconstruite à partir d'un type qui ne la modélise pas.

**Alternatives considérées** : **uniformiser derrière `AsyncValue`** — le geste que l'idiome invite, et
il détruit les **deux** sémantiques d'un coup (FR-022). · **`record (bool, JetonsSession?)`** : égalité
structurelle, et `JetonsSession` implémente `==` (`stockage_jetons.dart:18-24`) ⇒ un `ouvrir()` aux
mêmes jetons émettrait **0** au lieu de 1 ⇒ l'exception nommée de FR-003 devient infalsifiable. ·
**`expect(emissions, greaterThanOrEqualTo(1))`** : relâchement **interdit**, FR-003/FR-004 le nomment
explicitement.

## R7 — Le verrou de renouvellement reste dans l'intercepteur, INCHANGÉ : zéro ligne modifiée, `_enCours ??=` et `finally`

**Décision** : `Future<bool>? _enCours` (`session_auth.dart:88, :111, :147`) **ne bouge pas**. Il reste
un champ privé de `InterceptorAutorisation`, avec son `??=` et son `finally`. FR-014 (N requêtes
concurrentes expirées ⇒ **un seul** renouvellement, partagé) est couvert par un **test neuf** —
`mefali_core/test/auth/session_intercepteur_test.dart`, en `test()` et non `testWidgets()` —, pas par un
changement de code.

**Rationale** : le verrou **y est déjà**, contrairement à ce qu'affirme un rapport (« *`_enCours` doit
vivre dans le notifier… il y est déjà* » — **FAUX** : `session_auth.dart:88` en fait un champ de
`_InterceptorAutorisation`, pas de `SessionAuth`). Et **FR-013 garantit une instance d'intercepteur par
client** (R3) : l'unicité du verrou en est le **corollaire**, pas une exigence séparée. Le remonter dans
`state` est **interdit par FR-001** — `RacineAuth` rebâtirait à chaque début et fin de renouvellement,
alors qu'aujourd'hui un renouvellement est **totalement invisible de l'UI**. Le remonter dans un champ
privé du notificateur serait correct mais **gratuit** : l'unique appelant est l'intercepteur. Le test
FR-014 exige en revanche un mécanisme de harnais : **la retenue est le cœur du test** — un
`Completer<void>` que le faux `/auth/rafraichir` attend, sinon le 1ᵉʳ renouvellement aboutirait avant que
la 2ᵉ requête n'échoue et **le test serait VERT même si `_enCours` était supprimé** ; d'où
`TransportFake.repondre` rendant un **`FutureOr<ResponseBody>`** (R11). Motif à écrire dans le `reason` :
la rotation R2 (cycle 003) tourne le jeton ⇒ un 2ᵉ renouvellement rejouerait un jeton **mort** ⇒ vol
présumé ⇒ **session révoquée**. FR-015 (anti-boucle, rejeu unique) est préservé par non-action.

**Alternatives considérées** : **`QueuedInterceptor`** — il existe, il sérialise bien les `onError`,
c'est le remplaçant officiel de `dio.lock()` ([cfug/dio#1308](https://github.com/cfug/dio/issues/1308)) —
**rejeté** : notre modèle laisse les N requêtes prendre leur 401 **en parallèle** et **partager** un
renouvellement (`_enCours ??=`) ; la file les **sérialise**. Même comptage (1 renouvellement), **fil
réseau et ordonnancement différents** ⇒ FR-002/FR-014 violés. **Un changement de comportement déguisé en
réglage.** · **`Completer` / `AsyncCache` / mutex** : sémantique de réentrance différente de `??=` +
`finally`, pour zéro bénéfice, dans le **seul endroit du cycle où une divergence déconnecte
l'utilisateur** (`spec.md:50`). · **Verrou remonté dans `Session`** (deux variantes ci-dessus) :
FR-001 ou gratuit.

## R8 — La mémoire du rôle actif : `build()` ne charge RIEN, `charger()` reste impératif et relit `state.actif`

**Décision** :

```dart
@riverpod
class EtatRoles extends _$EtatRoles {
  @override
  EtatRolesData build() {
    ref.watch(sessionProvider.select((e) => e.connecte));   // FR-020 (R4)
    // build() rend l'état INITIAL et ne charge PAS : le chargement est déclenché par le
    // routeur (routeur_roles.dart:50), et `charger()` est rejouable SANS que build()
    // retourne — c'est ce qui laisse `actif` survivre (US4 scénario 3, spec.md:99).
    return const EtatRolesData();
  }
  @override
  bool updateShouldNotify(EtatRolesData p, EtatRolesData n) => true;   // R6
  Future<void> charger() async { /* corps identique à etat_roles.dart:155-194 */ }
}
```

**Règle de fichier, non négociable** : **tout cas unitaire sur `etatRolesProvider` ouvre un
abonnement** — `final sub = container.listen(etatRolesProvider, (_, __) {}); addTearDown(sub.close);`.

**Rationale** : `routeur_roles_test.dart:295-322` appelle `charger()` **deux fois sur la même instance**
et exige `actif: coursier` puis `actif: vendeur`. **Ce seul test interdit les trois designs que Riverpod
suggère spontanément** : (1) `Future<T> build() async => _charger()` — le rechargement passe alors par
`ref.invalidate` ⇒ `build()` rejoué ⇒ **`actif` réinitialisé** ⇒ en production, l'utilisateur est renvoyé
à l'autre interface **sous ses doigts** à chaque rafraîchissement, ce que `etat_roles.dart:177-180`
documente exactement comme interdit ; (2) `AsyncNotifier` (R6) ; (3) le rechargement par `invalidate` en
général. **La mémoire est dans `state`, la destruction est dans `build()`** — et les deux exigences
opposées (US4 scénario 3 « reste actif » / FR-020 « meurt au changement de compte ») cessent de se
marcher dessus.

⚠ **Piège de portage qui rendrait le test VERT SANS RIEN PROUVER** — le pire résultat possible.
`etatRolesProvider` est **autoDispose** (R4) : `container.read(…notifier)` **n'attache aucun auditeur**,
la destruction est **planifiée**, et le notificateur peut être **rejeté entre les deux `charger()`** ⇒
`build()` rejoué ⇒ `actif` repart à `null` ⇒ le 2ᵉ chargement retombe sur vendeur **trivialement**. C'est
la **collision directe entre FR-020 (autoDispose) et FR-038 (conteneur explicite)**, et elle ne se voit
qu'ici. Vérifié par exécution : avec l'abonnement, deux `charger()` successifs partagent bien l'instance.

**Alternatives considérées** : **`Future<EtatRolesData> build() async` + `ref.invalidate` pour
recharger** — l'idiome canonique de Riverpod, et il **efface `actif`** (ci-dessus). ·
**`AsyncNotifier<List<Attribution>>` avec `actif` en provider séparé** : scinde un état que le code
tient ensemble, et `actif` ne serait plus détruit par le même `build()` ⇒ FR-020 retombe sur une
discipline. · **`ref.keepAlive()` ponctuel pour survivre entre deux `charger()` en test** : soigne le
symptôme du piège ci-dessus en cassant précisément l'invariant que SC-010 vérifie.

## R9 — Le squelette réapparaît par `state = const AsyncLoading()` EXPLICITE dans `recharger()` ; `.when()` reste aux défauts du framework PARTOUT

**Décision** : `mesAdresses` et `mesSessions` sont des `AsyncNotifier` ; l'intention FR-023 vit dans une
méthode **déjà nommée `recharger()`** (`liste_adresses.dart:44`, `ecran_appareils.dart:42`).

```dart
/// FR-023 — le squelette DOIT réapparaître, comme le `setState(() => _adresses = _charger())`
/// d'avant (liste_adresses.dart:47-49) : un nouveau Future repartait en
/// `ConnectionState.waiting`.
Future<void> recharger() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(_charger);
}
```

**Rationale** : le piège de la spec (`spec.md:150`) est **exact et actuel** — vérifié dans
`riverpod-3.3.2/lib/src/core/async_value.dart:198,244,277` : **`skipLoadingOnRefresh = true` par
DÉFAUT**, soit exactement l'inverse du comportement actuel. `ref.invalidate` +
`.when(skipLoadingOnRefresh: false)` fonctionne, mais fait porter FR-023 par **un booléen à répéter à
chaque site d'appel de `.when()`, dont le défaut fait le contraire** : un site oublié ⇒ le squelette
cesse d'apparaître ⇒ changement visible ⇒ **aucun des 86 cas ne le rattrape**. Mettre le comportement
dans le code, **à un seul endroit**, laisse `.when()` aux défauts dans tout le dépôt ⇒ **pas de
convention à écrire, donc pas de convention à oublier**. *Bénéfice second, gratuit et non visible* : les
gardes `if (mounted) _recharger();` (`liste_adresses.dart:68, :93` ; `ecran_appareils.dart:56-57`)
disparaissent — `ref.read(p.notifier).recharger()` n'est pas un `BuildContext` (edge case
`spec.md:154`). *Caveat connu, à vérifier par test et jamais par lecture de doc* :
`skipLoadingOnRefresh`/`skipLoadingOnReload` n'agissent pas toujours comme documenté
([#1568](https://github.com/rrousselGit/riverpod/issues/1568),
[#1570](https://github.com/rrousselGit/riverpod/issues/1570),
[#2450](https://github.com/rrousselGit/riverpod/discussions/2450)) — raison de plus de ne pas en
dépendre.

**Alternatives considérées** : **garder `FutureBuilder` + `ref.read`** — le plus sûr dans l'absolu, mais
laisse `_adresses`/`_appareils` **hors du moule** ⇒ FR-007 et US3 non tenus. · **`ref.invalidate` +
`.when(skipLoadingOnRefresh: false)`** : FR-023 porté par un booléen répété, défaut inverse (ci-dessus).
· **`ref.invalidate` au défaut** : c'est le piège nommé — le squelette **cesse** de réapparaître.

## R10 — L'amorçage reste impératif : `ProviderContainer` explicite dans `main()` + `UncontrolledProviderScope`, et `retry: pasDeRetry` sur TOUTE portée

**Décision** :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(
    // FR-002 : Riverpod 3 RÉESSAIE les providers en échec PAR DÉFAUT (10 essais, backoff
    // 200 ms → 6,4 s). AUCUNE requête n'était rejouée avant ce cycle.
    retry: pasDeRetry,
    // FR-012 : l'URL reste une constante de compilation du POINT D'ENTRÉE (R3).
    overrides: [urlApiProvider.overrideWithValue(_urlApi)],
  );
  // FR-024 — amorçage IMPÉRATIF, INCONDITIONNEL, ici, avant runApp, et NON ATTENDU :
  // bloquer le lancement sur un appel réseau ferait patienter devant un écran vide. Ne
  // JAMAIS déplacer cette lecture dans un écran : la config ne partirait qu'à l'entrée de
  // cet écran, et le rafraîchissement horaire ne démarrerait pas sur un lancement qui ne
  // l'atteint pas (edge case spec.md:157).
  unawaited(container.read(serviceConfigProvider));
  runApp(UncontrolledProviderScope(container: container, child: const MefaliProApp()));
}
```

`Duration? pasDeRetry(int n, Object e) => null;` — **PUBLIC**, déclaré dans une bibliothèque de
**PRODUCTION** de `mefali_core` (à côté des providers, **exportée par le barrel**) ; c'est une constante
de `mefali_core`, **réutilisée par le harnais** (R11), et **pas un réglage par site** : les **trois**
créations de portée du dépôt (2 points d'entrée + `conteneurMefali`) la portent. Les deux autres formes
sont fautives, chacune contre une règle écrite : **privé** (`_pasDeRetry`) — un top-level privé est
**privé à sa bibliothèque**, donc chaque `main.dart` devrait le **redéclarer**, ce qui **est**
littéralement « un réglage par site » (interdit par `providers.md` règle 4 et `harnais-de-test.md`
règle 1) ; **déclaré dans `harnais.dart`** — les 2 `main.dart` de **production** devraient importer le
harnais, ce qui contredit frontalement R11 (« l'arbre de production ne le référence **jamais** →
tree-shaking ; un fichier de production qui l'importerait **se verrait** »). Le sens de dépendance est
donc : production → `mefali_core`, et harnais → `mefali_core`. **Jamais** production → harnais.

**Rationale** :
- **`UncontrolledProviderScope` est la SEULE forme qui donne un handle sur le conteneur AVANT
  `runApp`.** Avec `ProviderScope(overrides: …)`, le conteneur naît dans le `build` de la portée : le
  point d'entrée n'a **rien à lire**, et le déclenchement devient forcément **contingent d'un
  consommateur**. FR-024 exige littéralement « déclenché impérativement depuis le point d'entrée » —
  cette forme le tient **à la ligne près**, en face de `main.dart:19` (pro) et `:18` (client). Elle porte
  aussi `retry` et `overrides` : **une construction, trois FR** (FR-002, FR-012, FR-024).
- **`unawaited(...)` et non `.ignore()`** : `.ignore()` **avale** l'erreur, alors qu'aujourd'hui le Future
  est bien attendu — en `try/catch` — par les deux consommateurs (`racine_auth.dart:72`,
  `routeur_roles.dart:62`). Gestion d'erreur identique, `unawaited_futures` satisfait **sans mentir**. Le
  conteneur n'est **jamais** détruit : **c'est la spécification** (FR-019), pas une négligence.
- **Le retry est le PREMIER réglage à écrire du cycle** — il viole FR-002 **sans une ligne de code, et
  les tests restent verts**. Vérifié dans le code résolu : `element.dart:764` → `origin.retry ??
  container.retry ?? ProviderContainer.defaultRetry` ; `provider_container.dart:940-954` →
  `maxRetries = 10`, `minDelay = 200ms`, `maxDelay = 6400ms`, et **`if (error is ProviderException ||
  error is Error) return null;`** ⇒ **toutes les `Exception` sont réessayées, `DioException` compris**.
  Poser `retry` sur le conteneur racine court-circuite `defaultRetry` pour tout l'arbre
  (`provider_container.dart:855` : `retry = retry ?? parent?.retry`). ⚠ Le `retry: null` que le
  générateur écrit par défaut signifie **« hérite »**, PAS « désactivé ». ⚠ Incohérence de doc :
  `riverpod_annotation.dart:45` dit « *unlimited retries* », le code dit `maxRetries = 10` — **le code
  fait foi**. Pourquoi les tests ne le rattraperaient pas : `ServiceConfig.rafraichir` **avale ses
  erreurs** (`service_config.dart:64`), donc les cas de config ne bronchent pas pendant que
  adresses/rôles/appareils dérivent.

**Alternatives considérées** : **`ProviderScope(overrides:)` + `ref.read` au premier `build` de
`RacineAuth`** — à consommateurs inchangés, le décalage est négligeable (`spec.md:157` le concède), mais
FR-024 est violé **en lettre** et le garde-fou disparaît : plus rien n'empêche le geste que l'idiome
invite juste après — lire la config à l'étape du consentement ou au formulaire —, qui est un
**déplacement de requête au sens de FR-002**. · **Provider « eager » via `ProviderObserver`** :
déclenchement **implicite et non relisable**, pour éviter trois lignes. · **`await` de l'amorçage** :
contredit FR-024 et le commentaire d'origine `main.dart:14-18`. · **`retry` posé provider par provider** :
un site oublié ⇒ 10 requêtes en backoff ⇒ SC-004 perdu en silence.

## R11 — Le harnais vit dans `apps/packages/mefali_core/lib/harnais.dart`, bibliothèque SÉPARÉE hors du barrel, sous trois contraintes dures vérifiées

**Décision** — API centrée **conteneur**, jamais fabrique d'overrides :

```dart
class TransportFake implements HttpClientAdapter { … }  // remplace les 6 copies (SC-011)
ResponseBody reponseJson(Object corps, {int statut = 200});
// `pasDeRetry` n'est PAS déclaré ici : c'est une constante de `mefali_core` (production,
// exportée par le barrel) que le harnais RÉUTILISE — `conteneurMefali` la passe en `retry:`
// exactement comme les 2 `main.dart` (R10). La déclarer ici forcerait la production à
// importer le harnais.
ProviderContainer conteneurMefali({JetonsSession? jetons, TransportFake? transport,
                                   SourceConfig? source, CacheConfig? cache});
Widget harnaisApp({required ProviderContainer container, required Widget home,
                   Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates,
                   Iterable<Locale>? supportedLocales});
int compteIntercepteursApp(Dio dio);   // par TYPE, JAMAIS par position
```

**Trois contraintes de conception dures, toutes établies par exécution** :
1. **AUCUNE signature ne mentionne `flutter_test` / `WidgetTester`.** Le harnais **rend** un `Widget` et
   **rend** un `ProviderContainer` ; l'appelant, resté dans `test/`, fait `tester.pumpWidget(...)` et
   `addTearDown(...)`. Sans cette contrainte, `flutter_test` deviendrait une dépendance de
   **production** de `mefali_core` — inacceptable. ⇒ **`pumpApp(tester, …)` est REJETÉ.**
2. **Le harnais N'APPELLE PAS `ProviderContainer.test()`.** Il est **`@visibleForTesting`** : vérifié,
   depuis `lib/` → `invalid_use_of_visible_for_testing_member` → **EXIT 3 ⇒ SC-006 échoue** ; depuis
   `test/` → EXIT 0. ⇒ `conteneurMefali` utilise le constructeur **public**, et chaque fichier de test
   fait `addTearDown(container.dispose)` — **règle à écrire, pas à découvrir**.
3. **AUCUNE signature n'annote `List<Override>`.** Vérifié : `flutter_riverpod 3.3.2` a un `show` de 34
   symboles qui **n'exporte PAS `Override`** ; `List<Override> f()` → `non_type_as_type_argument`, **même
   avec `package:riverpod/riverpod.dart`**. L'inférence marche
   (`ProviderContainer(overrides: [x.overrideWithValue(y)])` → EXIT 0), l'annotation non.

**Prérequis de production induit** : `_InterceptorAutorisation` devient **public**
(`InterceptorAutorisation`, R3), sans quoi `compteIntercepteursApp` ne peut compter **par type** et
SC-005 retombe sur le `.last` que ce cycle supprime.

**Rationale** :
- **`lib/` et non `test/`** : un `test/harnais.dart` par paquet est impossible sans **3 copies** — un
  paquet Dart ne peut pas importer le `test/` d'un autre, seul `lib/` est exposé sous `package:` — ce qui
  violerait **SC-011 par construction**. **Le précédent tranche** : `StockageJetonsMemoire`
  (`stockage_jetons.dart:84`) est **déjà** un double de test vivant en production, exporté par
  `mefali_core.dart:18`, avec son motif écrit dans le code (`:81-83`). Le projet a payé ce prix une fois,
  pour la raison exacte qui se représente. Bibliothèque **séparée**, **hors du barrel** :
  `import 'package:mefali_core/harnais.dart'` est un aveu **lisible en revue**, et l'arbre de production
  ne la référence jamais → tree-shaking. **Nuance assumée et consignée (constitution II) : la barrière
  est CONVENTIONNELLE, pas mécanique** — exactement le statut qu'a déjà `StockageJetonsMemoire`.
- **`TransportFake.repondre` rend un `FutureOr<ResponseBody>`** — et non un `ResponseBody` comme les 6
  copies actuelles : **sans réponse retenable, le test FR-014 serait vert sans verrou** (R7).
- **`harnaisApp` monte un `UncontrolledProviderScope`** (le conteneur préexiste toujours) — cohérent avec
  R10, et **seule forme compatible** avec le préchargement hors arbre des 3 cas `runAsync`.
  Conséquence à écrire comme règle : `UncontrolledProviderScope` **ne dispose pas** le conteneur (c'est
  sa raison d'être) ⇒ `addTearDown(container.dispose)` dans **chaque** cas.
- **FR-036 tenu par CONSTRUCTION** : la pose de l'intercepteur est dans le `build` de
  `clientSessionProvider` ; `container.read(clientSessionProvider).dio.httpClientAdapter =
  TransportFake(...)` est **ordonné après la pose**, sans discipline à tenir.
- **`conteneurMefali` surcharge `sourceConfig`/`cacheConfig` PAR DÉFAUT** — sans quoi les 23 cas de
  `mefali_pro` appellent le vrai `SharedPreferences` et le réseau, et **SC-004 se perd sans qu'aucune
  assertion ne bronche** (R5). Aujourd'hui `config: null` les protège ; cette protection **disparaît**
  avec le provider.
- **`ProviderException` ENVELOPPE les erreurs en v3 — vecteur d'échec silencieux que la spec ne nomme
  PAS.** Une erreur levée dans le `build` d'un provider ressort **emballée** : tout
  `expect(..., throwsA(isA<DioException>()))` sur un chemin qui **traverse un provider** cesse de
  matcher et **casse**. Le fait est le pendant exact du défaut de retry (R10,
  `provider_container.dart:940-954` : `if (error is ProviderException || error is Error) return null;`) :
  la même classe, lue une fois comme cause de non-retry, se retrouve ici comme cause de **rouge au
  portage**. **À AUDITER sur les 86 cas dès la PREMIÈRE tâche** (et non à découvrir un fichier à la
  fois) : le verdict par cas est soit `isA<ProviderException>()`, soit un dépaquetage sur `.cause`, soit
  — cas le plus fréquent — le constat que le chemin **ne traverse aucun provider** et que l'assertion
  reste juste. C'est un piège qui rougit **franchement**, donc le moins coûteux du lot : il se voit au
  premier `flutter test`. Il est nommé ici pour qu'il ne soit pas **diagnostiqué 13 fois**.
- **Règle du cycle : on surcharge les DÉPENDANCES, JAMAIS le sujet.** `sessionProvider` n'est **jamais**
  surchargé ; les surcharges vivent dans le conteneur **RACINE** du test — une surcharge de
  `sessionProvider` dans un `ProviderScope` imbriqué donnerait **deux notificateurs sur le même dio**,
  donc **2 intercepteurs**, et **aucune construction Riverpod ne l'empêche** : c'est une règle à écrire,
  pas un bug à corriger.

**Alternatives considérées** : **`clientSessionProvider.overrideWith((ref) => MefaliApiClient(dio:
dioFactice))`** — le geste que l'idiome invite, **doublement destructeur** : il perd l'intercepteur (le
test **ne prouve plus rien tout en restant vert**) **et** les timeouts 5000/3000 ms (FR-017/FR-036). ·
**`pumpApp(tester, …)`** : `flutter_test` en dépendance de production. · **`ProviderContainer.test()`
depuis le harnais** : EXIT 3, et il diffère `dispose` au `tearDown`, **hors zone** — or les 4 cas
`fakeAsync` exigent la destruction **dans** la zone (voir ci-dessous). · **Fabrique de `List<Override>`** :
ne compile pas. · **3 copies de `test/harnais.dart`** : SC-011 violé par construction.

⚠ **Le piège de la zone, seul endroit du plan où `.test()` est déconseillé** : `Timer.periodic` capte
`Zone.current` **à sa création** (`service_config.dart:51`), et le `build` d'un provider est
**paresseux** — c'est le **`container.read(...)`** qui doit être dans la zone. Un conteneur lu dehors →
vrai `Timer` → `async.elapse(Duration(hours: 1))` ne déclenche rien.

## R12 — La CI bascule sur `dart analyze` (JAMAIS `flutter analyze`) et le garde-fou anti-dérive est ÉTENDU au répertoire du paquet

**Décision — deux tranchages.**

**1) `dart analyze`, JAMAIS `flutter analyze`. C'est LE point du lot, et la première tâche.** Vérifié par
exécution — même répertoire, même `analysis_options.yaml`, **même faute** :

```
dart analyze    → EXIT=2 | missing_provider_scope + avoid_public_notifier_properties
flutter analyze → EXIT=0 | "No issues found!"
```

**2) Portée du garde-fou (FR-031), que la spec renvoie explicitement au plan (Assumptions
`spec.md:279`) : ÉTENDUE au répertoire du paquet — `git diff --exit-code -- .`, option B.**

| Option | Conséquence |
|---|---|
| **A — cadrée aux `*.g.dart`** | Le trou des l10n de `mefali_core` (**commitées et gardées par RIEN** — hors du motif d'exclusion `.gitignore:21`) reste ouvert → consigné au titre de FR-027. |
| **B — étendue au paquet** (**retenue**) | Ferme le trou l10n **et** couvre `.g.dart` + `pubspec.lock`. Risque théorique : révéler une dérive préexistante ⇒ exception nommée à FR-027. |

**Ordre imposé par FR-034** : `pub get` (nécessaire à build_runner **et** régénère les l10n) →
**régénération** (`dart run build_runner build`) → **contrôle de dérive** → **`dart analyze`** → tests.
La matrice `apps.yml` gagne une colonne `codegen: true|false` (`mefali_client` → `false`).

**Rationale** :
- **`apps.yml:36` fait `flutter analyze`. Laisser cette ligne = riverpod_lint est un no-op décoratif** :
  la CI reste verte, FR-033/SC-006 sont **réputés** tenus, et **RIEN n'est vérifié** — précisément le mode
  de panne qu'US1 nomme (« un pattern qu'aucun outil ne vérifie n'est pas un pattern, c'est une
  intention », `spec.md:31`). La bascule est **sans effet de bord** : vérifié, `dart analyze` sort **`No
  issues found!` sur les 3 paquets réels aujourd'hui**. ⚠ La doc
  `analysis_server_plugin/doc/using_plugins.md` affirme le contraire (« *at the command line (with `dart
  analyze` or `flutter analyze`)* ») : **elle est FAUSSE sur Flutter 3.44.6** — ne pas la croire sur
  parole.
- **B, parce que le risque est mesuré NUL** : après `flutter pub get` sur les 3 paquets (donc gen-l10n
  régénéré), `git status --porcelain apps/ clients/` = **vide** ⇒ **aucune dérive l10n préexistante** ⇒
  **l'exception FR-027 n'a pas à être invoquée**, et B ferme **gratuitement** un trou que A laisserait
  ouvert. B est aussi le seul choix cohérent avec l'Assumption « ce cycle tranche pour **commité +
  gardé** » (`spec.md:279`) : cadrer aux `.g.dart` laisserait vivre une **3ᵉ politique** de code généré
  dans le dépôt. Scopé `-- .` (working-directory du paquet) et **pas `apps/`** : un échec **nomme le
  coupable**.
- **La dérive est contrôlée APRÈS régénération (FR-034) et AVANT l'analyse** : signal le plus spécifique
  et le moins cher ; analyser du code désynchronisé produirait des diagnostics **trompeurs**. FR-034 (« l'analyse
  s'exécute sur le code généré commité, présent dès la récupération ») est tenu : les `.g.dart` sont
  commités (FR-029), donc présents dès `checkout` ; `build_runner` les réécrit **à l'identique**
  (déterminisme vérifié, FR-030/SC-007).
- **`dart_test.yaml` : AUCUN changement, et ne pas en ajouter à `mefali_core`** — il ne sert qu'à déclarer
  les tags employés, or `mefali_core` n'en a aucun ; et les **3 tests neufs ne doivent porter AUCUN tag**,
  sinon ils seraient exposés à une exclusion accidentelle alors que FR-013/FR-014 sont exactement ce que
  SC-005 veut voir tourner à chaque PR.
- **SC-006 se formule en pass/fail, JAMAIS en nombre** : la duplication des diagnostics **cœur** avec le
  plugin actif est **reproduite** (plugin OFF → 2 issues, ON → 4 ; les règles riverpod, elles, ne sont
  **pas** dupliquées), **aucune issue upstream trouvée**, cause inconnue. Sans effet sur SC-006 (2 × 0 = 0),
  mais **tout comptage littéral serait faux**.

**Alternatives considérées** : **garder `flutter analyze`** — la CI resterait verte en ne vérifiant rien :
c'est le risque **critique n°1** du cycle. · **Option A (garde-fou cadré aux `*.g.dart`)** : laisse la 3ᵉ
politique de code généré vivante et le trou l10n ouvert, pour éviter un risque mesuré à zéro. ·
**`git diff --exit-code -- apps/`** (portée large non scopée) : un échec ne nomme pas le paquet coupable,
et casse la matrice `working-directory` d'`apps.yml:19-28`.

## R13 — Périmètre non touché ce cycle, et les DEUX moules opposables aux cycles suivants

**Décision — périmètre non touché** : **AUCUN** crate Rust, **AUCUN** endpoint, **AUCUNE** migration
sqlx, **AUCUN** `cargo sqlx prepare`, **AUCUN** événement outbox, **AUCUNE** page Nuxt, **AUCUN**
paramètre de zone, **AUCUNE** clé i18n nouvelle. `openapi.json` et les clients GÉNÉRÉS `clients/dart` /
`clients/ts` **ne sont ni modifiés ni régénérés** (FR-006, constitution I). **R14** — double-submit
concurrent du dossier, décision produit du cycle 003 (`003/research.md:314`) — reste **exactement dans
l'état où le cycle l'a trouvé** (FR-026) : `FormulaireDossierCoursier` reste un
**`ConsumerStatefulWidget`**, `_cleIdempotence` (`formulaire_dossier.dart:95`) reste un initialiseur de
champ de `State`. **La seule chose que ce cycle doit à R14, c'est de ne pas le déplacer.** **Les 2
goldens ne sont ni régénérés ni touchés — FR-005 est tenu MÉCANIQUEMENT, pas par discipline** :
ils montent un **`StatelessWidget` nu**, **hors de toute portée** (aucun `ProviderScope`, aucun
`Consumer`) ⇒ le cycle ne peut pas changer un pixel de ce qu'ils rendent ⇒ **aucune régénération n'a de
raison d'être**. Corollaire opérationnel : **`--update-goldens` est INTERDIT pendant le cycle** — un
golden régénéré est un changement visible **accepté sans être vu**, exactement ce que FR-005 refuse ; si
un golden rougit, c'est un **signal**, pas une image à rafraîchir. **Seul chemin de casse** : convertir
`SplashScreen` en `ConsumerWidget` — que **rien n'exige** (il ne lit aucun état) et que ce cycle ne
fait pas. iOS et
l'enregistrement vocal : ni vérification, ni correction (mémoire projet, cycle plateformes) ;
l'enregistreur garde son état local (FR-009). Le routeur déclaratif et la base locale de la file
hors-ligne, repérés puis **différés au cycle 001** (`001/research.md:40`), restent différés — les
répertoires réservés restent **vides** (« Prêt ≠ construit », constitution IX). Les **défauts latents
préexistants** relevés à la cartographie sont **consignés et NON corrigés** (FR-027) : `uuid` à 4.5.3
contre 4.6.0 sur pub.dev ; `clients/dart` en `build_runner: any` + lock gitignoré ; `ServiceConfig.arreter()`
(`service_config.dart:70`) que **personne n'appelle** — le `Timer.periodic` fuit déjà, y compris entre
tests ; `apps.yml` qui ne vérifie **pas le format** (`dart format`) — FR-031 ferme la dérive, **pas le
format** ; `session_auth_test.dart:82-84` (`whereType<Interceptor>().last`) que ce cycle supprime.
**Exception unique et nommée à FR-027** : `ref.onDispose(arreter)` sur `serviceConfig` (R5) relève de
**FR-018** (« libérer ce qu'il acquiert ») et non d'une correction — il est **invisible en production**
(`keepAlive` ⇒ jamais détruit) et ne change que l'hygiène du harnais ; tranché explicitement ici plutôt
que par défaut.

**Décision — les DEUX moules, et c'est ce que l'amendement de constitution (FR-040) doit NOMMER** :

| Moule | Pour | Signature | Pourquoi pas l'autre |
|---|---|---|---|
| **`Notifier<Etat…>`** sur classe nue **sans `==`** + `updateShouldNotify => true` | les porteurs à **sémantique propre** : `session`, `etatRoles` | `@Riverpod(keepAlive: true) class Session extends _$Session` / `@riverpod class EtatRoles extends _$EtatRoles` | `AsyncValue` fusionne `charge` et `enErreur` (orthogonaux) et fait réapparaître l'écran de démarrage (FR-022, R6) |
| **`AsyncNotifier`** + `state = const AsyncLoading()` explicite dans `recharger()` | les **chargements de liste** : `mesAdresses`, `mesSessions` | `@riverpod class MesAdresses extends _$MesAdresses` | un `Notifier` obligerait à réécrire à la main ce qu'`AsyncValue` modélise déjà (FR-023, R9) |

Conventions du moule, opposables en revue (FR-007/FR-040/FR-041/FR-042, SC-012) : tout porteur d'état
d'app ou de domaine est un provider **GÉNÉRÉ par annotation** ; l'injection passe par la **portée**
(FR-010) ; l'état strictement local — contrôleurs, focus, compte à rebours, brouillons, ressources
natives — **reste local** (FR-009) ; on surcharge les **dépendances**, **JAMAIS** le sujet (R11) ; toute
création de portée porte `retry: pasDeRetry` (R10) ; la durée de vie est **explicite et argumentée**,
`@riverpod` nu étant autoDispose et **aucun lint ne gardant l'opposition** (R4).

**Rationale** : « rien construit hors du périmètre du cycle en cours » (constitution, Workflow) et « un
refactor pur ne répare pas en passant » — un refactor qui corrige au passage rend **impossible
d'attribuer une régression** (FR-027, SC-003). Le verrou documentaire est la **raison d'être du cycle**
(US6) : sans lui, le refactor n'est qu'un goût personnel exprimé une fois, et rien n'empêche le cycle CRS
de réintroduire un notificateur. La constitution **ne dit rien** du state management aujourd'hui — ses
onze principes encadrent l'UI (Material 3 thémé, `.adaptive`, pas de Cupertino) mais pas l'état ; la
convention actuelle n'est écrite que dans **un commentaire de code** (FR-042) et dans la mémoire projet.
L'amendement est donc un **ajout de principe** : **MINOR, 1.0.1 → 1.1.0**, passé par `/speckit.constitution`
avec rapport d'impact en tête et propagation aux templates (Governance) — éditer la constitution hors de
cette procédure est **interdit**. ⚠ **Riverpod n'est pas dans la liste nommée du principe X** :
l'amendement est l'occasion de l'y ajouter. **Et l'amendement doit nommer LES DEUX MOULES** — sinon le
prochain cycle **uniformisera** derrière `AsyncValue`, ce qui détruirait les deux sémantiques de FR-022
d'un seul geste, en toute bonne foi.

**Alternatives considérées** : **un moule unique `AsyncNotifier` partout** — l'uniformité que tout le
monde préfère lire, et elle est **incompatible avec FR-022** (R6/R9). · **Verrouiller le pattern dans
`CLAUDE.md` seul** : `CLAUDE.md` est un guide d'exécution, pas une norme opposable — FR-041 exige qu'il
**énonce la même règle**, pas qu'il la porte ; SC-012 demande une règle **citable en revue**. ·
**Corriger les défauts latents « pendant qu'on y est »** (le `Timer` qui fuit, le format en CI,
`uuid`) : rend inattribuable toute régression du cycle — FR-027 l'interdit, et chacun est consigné avec
son cycle de reprise.
