# Tasks: Gestion d'état des apps Flutter — migration vers Riverpod codegen

**Input**: Design documents from `/specs/004-riverpod-etat-flutter/`

**Prerequisites**: plan.md, spec.md (43 FR, 12 SC, US1→US6), research.md (R1–R13, décisions ARRÊTÉES vérifiées par exécution), data-model.md (11 providers, durées de vie, registre `.g.dart`), contracts/providers.md (le moule), contracts/harnais-de-test.md (FR-037), contracts/ci-apps.md, quickstart.md (validation des 12 SC)

**Tests**: constitution VII — les durées de vie SONT des machines à états (data-model §2) ; **chaque flèche = un test** (transitions du graphe d'objets §2.1, des deux machines opposées de FR-022 §2.2, de la vie/mort des rôles §2.3, du squelette §2.4). Écart unique consigné (Complexity Tracking VII) : les **2 lectures d'instantané de configuration** (`racine_auth.dart:70-77`, `routeur_roles.dart:58-67`) qu'AUCUN des 86 cas ne couvre — elles se vérifient sur émulateur (SC-009), pas en test. Le cycle ajoute **3 cas** (unicité de l'intercepteur FR-013/018, renouvellement partagé FR-014) : décompte de sortie **≥ 89**, dont aucun des 86 n'a disparu (FR-004).

**Organization**: tâches groupées par user story (US1→US6, priorités **internes** P1→P6 de la spec — produit : toutes P1, TRX-08). **L'invariant central prime sur toutes les stories** : refactor pur, aucun écran/texte/enchaînement/requête ne change ; les **86 cas de test existants font contrat** (FR-003, SC-002). Mapping calqué sur 001 (« US1 = infra/outillage ») : US1 valide la chaîne, US2→US5 migrent cœur → pro → client, US6 verrouille. Consignes de l'input respectées : chaque tâche de migration de test **nomme son fichier** et ce qui change ; chemins exacts ; la DERNIÈRE tâche est la revue Definition of Done (§0.4).

## Format: `[ID] [P?] [Story] Description (estimation)`

- **[P]** : parallélisable (fichiers différents, aucune dépendance sur une tâche inachevée)
- **[Story]** : US1..US6 (phases de story UNIQUEMENT — jamais en Setup/Foundational/Polish)
- Chemins exacts dans chaque description ; estimation entre parenthèses

## Path Conventions

- Cœur partagé : `apps/packages/mefali_core/` — `lib/src/portee.dart` (primitives), `lib/src/auth/`, `lib/src/config/`, `lib/src/adresses/`, `lib/src/appareils/`, `lib/harnais.dart`, `lib/mefali_core.dart` (barrel), `analysis_options.yaml`, `pubspec.yaml`
- Pro : `apps/mefali_pro/` — `lib/main.dart`, `lib/roles/{etat_roles,routeur_roles,formulaire_dossier}.dart`
- Client : `apps/mefali_client/` — `lib/main.dart`, `lib/splash_screen.dart`
- CI : `.github/workflows/apps.yml` ; script `scripts/verifier-accord-locks.sh`
- Le `.g.dart` est **GÉNÉRÉ**, commité à côté de sa bibliothèque annotée, **JAMAIS édité** (constitution I, même règle que `clients/dart`)

## Règles constitutionnelles appliquées (adaptées — le cycle ne touche que `apps/` et sa CI)

- **AUCUN SQL** : aucune migration, aucun `cargo sqlx prepare`, aucun `cargo test` (FR-006).
- **AUCUNE API** : aucun endpoint utoipa ; `openapi.json`, `clients/dart`, `clients/ts` **INTOUCHÉS**, jamais régénérés (FR-006, constitution I) — les deux chaînes de génération sont étanches (R2).
- **AUCUN événement outbox** : aucune transition d'état **métier** ce cycle (constitution VI) ; les transitions de **durée de vie** relèvent de VII (tests, ci-dessus).
- **AUCUN paramètre « paramétrable »** : aucune configuration de zone (constitution — N/A).
- **Garde-fou de dérive** : porte sur les `.g.dart` (portée = répertoire du paquet, R12 option B), même règle que les clients dérivés du contrat (FR-029/030/031). `dart analyze`, **JAMAIS** `flutter analyze` (R2, R12).
- **i18n fr** : invariant à **NE PAS régresser** — aucune clé nouvelle, aucune chaîne utilisateur en dur introduite (FR-001).
- **Design** : les 2 goldens passent **sans régénération**, `--update-goldens` **INTERDIT** ; aucune transposition DOM/CSS ; `.adaptive` intact ; aucun Cupertino (constitution XI, FR-005, R13).
- **Versions** : exclusivement research R1 ; **3 lockfiles accordés** ; résolution **INCRÉMENTALE**, JAMAIS `rm pubspec.lock`, JAMAIS `pub upgrade` (SC-008).

---

## Phase 1: Setup

**Objectif** : dépendances Riverpod re-vérifiées (constitution X) et figées sur les 3 paquets, chaîne de génération prouvée — l'équivalent du « créer le workspace » de 001.

- [X] T001 Re-vérifier à l'OUVERTURE du cycle (constitution X, R1) les dernières versions stables et les figer par résolution **INCRÉMENTALE** (`flutter pub add` à partir des locks existants — JAMAIS `rm pubspec.lock`, JAMAIS `pub upgrade`, sous peine de faire dériver `uuid 4.5.3 → 4.6.0` et casser l'accord) : `apps/packages/mefali_core/pubspec.yaml` et `apps/mefali_pro/pubspec.yaml` → `flutter_riverpod: ^3.3.2` + `riverpod_annotation: ^4.0.3` (dependencies), `riverpod_generator: ^4.0.4` + `build_runner: ^2.15.1` (dev_dependencies) ; `apps/mefali_client/pubspec.yaml` → `flutter_riverpod: ^3.3.2` **SEUL** (ni annotation ni generator — `auto_apply: dependents`, R2). ⚠ **Re-tester le plafond `build_runner`** (2.15.2 exige `analyzer >=13.3.0` contre `^12` pour le generator → *version solving failed* — écart X n°2). **Point ouvert à mesurer ici** (ci-apps.md) : `dart analyze` exige-t-il le **réseau** en CI, et où l'analysis server cache-t-il le paquet synthétique de `riverpod_lint` ? Si réseau requis → consigner comme écart X, ne pas contourner. `flutter pub get` vert sur les 3 ; **3 `pubspec.lock` commités et accordés** (0 désaccord sur les versions communes — l'accord existe déjà, il est à **ne pas casser**). `custom_lint` : **0 occurrence, doit le rester** (insoluble, R2). (½ j)
- [X] T002 Prouver la chaîne `build_runner` : ajouter un `@riverpod` **trivial** dans `apps/packages/mefali_core/lib/src/_sonde.dart` (`part '_sonde.g.dart'`), `dart run build_runner build` **NU** (`--delete-conflicting-outputs` est **SUPPRIMÉ** de build_runner 2.15.x — R2), vérifier le **déterminisme** (2 exécutions → `git status --porcelain apps/` **VIDE**, FR-030/SC-007) et que le `.g.dart` n'est **pas** gitignoré (aucun motif `*.g.dart`, R2). **Retirer la sonde** une fois la chaîne prouvée (le premier provider réel commité est `urlApi`, T005). Dépend de T001. (½ j)

---

## Phase 2: Foundational (bloque TOUTES les stories)

**Objectif** : rendre le pattern vérifiable (l'analyse voit enfin le plugin) et poser les primitives que session, config et harnais consommeront. Rien ne peut migrer avant.

- [X] T003 Rendre `riverpod_lint` OPÉRANT — c'est le risque n°1 du cycle (R2, R12). (a) Bloc `plugins:` **top-level** (JAMAIS sous `analyzer:` = système legacy ignoré) dans **CHACUN** des 3 `analysis_options.yaml` — `apps/packages/mefali_core/`, `apps/mefali_pro/`, `apps/mefali_client/` — avec `riverpod_lint: version: 3.1.4` (**exact, sans caret**) + `diagnostics: {avoid_public_notifier_properties: error, avoid_build_context_in_providers: error, protected_notifier_properties: error}` (les 3 règles INFO sortent sinon en EXIT 0 = « avertissement ignorable » que FR-033 refuse ; `analyzer: errors:` ne les atteint PAS, SEUL `diagnostics:` fonctionne). ⚠ **JAMAIS en fichier inclus** : le bloc n'est lu que dans le fichier du paquet — la duplication ×3 est **STRUCTURELLE**, tenue accordée par T004, pas par `include:`. (b) `apps/packages/mefali_core/analysis_options.yaml` : **ZÉRO relâchement** (FR-032) — PAS d'`exclude: *.g.dart` (le `.g.dart` s'auto-neutralise par `// ignore_for_file: type=lint, type=warning`), PAS d'`invalid_annotation_target` (le generator ne le déclenche pas) ; `mefali_pro`/`mefali_client` gardent leur `errors: {invalid_annotation_target: ignore}` et `exclude:` **préexistants (gen-l10n) INCHANGÉS**. (c) `.github/workflows/apps.yml:36` : `flutter analyze` → **`dart analyze`** (`flutter analyze` NE charge PAS les plugins ⇒ no-op silencieux — vérifié EXIT 0 sur faute, la doc `using_plugins.md` est FAUSSE). Vérifier `dart analyze` **vert** sur les 3 paquets aujourd'hui (R2). Dépend de T001. (½ j)
- [X] T004 Accord mécanique des 3 lockfiles (SC-008) : écrire `scripts/verifier-accord-locks.sh` (compare les versions **communes** aux 3 `pubspec.lock` — `riverpod: 3.3.2` compris — **ET** le pin `riverpod_lint: 3.1.4` identique dans les 3 `analysis_options.yaml`, seul gel de cette brique **hors lockfile** — R1) ; ajouter le job `accord-locks` à `.github/workflows/apps.yml` (contrats/ci-apps.md). Dépend de T001, T003. (½ j)
- [X] T005 Primitives de portée de `mefali_core`, dans `apps/packages/mefali_core/lib/src/portee.dart`, **exportées par le barrel** `lib/mefali_core.dart` : (a) `Duration? pasDeRetry(int, Object) => null;` — **PUBLIQUE**, bibliothèque de **PRODUCTION** (les 2 `main.dart` et le harnais la RÉUTILISENT ; privée elle serait « un réglage par site », dans `harnais.dart` la production devrait l'importer — R10/R11) ; (b) `urlApiProvider` (`@Riverpod(keepAlive: true) String urlApi(Ref ref) => throw UnimplementedError(...)` avec le message qui dit d'`overrideWithValue` dans le point d'entrée — un défaut `localhost` ferait posséder au cœur la valeur d'env que FR-012 interdit, R3). `dart run build_runner build` → `.g.dart` commité (premier provider réel, valide la chaîne). Dépend de T002, T003. (½ j)
- [X] T006 [P] Les deux types d'état, classes IMMUABLES **volontairement SANS `operator ==`** (data-model §5, R6) : `EtatSession` dans `apps/packages/mefali_core/lib/src/auth/etat_session.dart` (`charge: bool` — fait partie de la valeur, NE REDEVIENT JAMAIS `false` —, `jetons`, getters `connecte`/`acces`/`rafraichissement`) et `EtatRolesData` dans `apps/mefali_pro/lib/roles/etat_roles_data.dart` (`attributions`, `charge` **non monotone**, `enErreur` **orthogonal** à `charge`, `actif`, `rolesValides`/`statut`). Leurs Notifiers (Session, EtatRoles) et le `updateShouldNotify => true` explicite naissent en US2/US4 : ⚠ un `record` ou `Equatable`/`freezed` ferait qu'un `ouvrir()` aux mêmes jetons émettrait 0 au lieu de 1 (FR-003). Dépend de T001. (½ j)
- [X] T007 Squelette du harnais partagé dans `apps/packages/mefali_core/lib/harnais.dart` — bibliothèque **SÉPARÉE, hors barrel** (`import 'package:mefali_core/harnais.dart'` = aveu lisible en revue ; précédent assumé `StockageJetonsMemoire`, R11) : implémenter `TransportFake` (`repondre` rend un **`FutureOr<ResponseBody>`** — sans réponse retenable le test FR-014 serait vert sans verrou, R7), `reponseJson`, `harnaisApp` (monte un `UncontrolledProviderScope` — il **NE dispose PAS** le conteneur) ; **AUCUNE signature ne mentionne `flutter_test`/`WidgetTester`** (contrainte 1), **AUCUNE n'annote `List<Override>`** (`Override` non exporté, contrainte 3), **JAMAIS `ProviderContainer.test()`** (`@visibleForTesting`, EXIT 3 depuis `lib/`, contrainte 2). Poser les **signatures** de `conteneurMefali({JetonsSession?, TransportFake?, SourceConfig?, CacheConfig?})` et `compteIntercepteursApp(Dio)` avec corps `throw UnimplementedError('complété story par story')` — ⚠ **conteneurMefali sera COMPLÉTÉ quand ses providers naissent** (session en US2 T012, config en US3 T020) ; `compteIntercepteursApp` a besoin de `InterceptorAutorisation` (public en US2). Réutilise `pasDeRetry` du barrel. Dépend de T005. (1 j)

**Checkpoint**: `dart analyze` voit le plugin (faute → EXIT 3), les 3 locks s'accordent, `urlApi`/`pasDeRetry`/les 2 types d'état/le harnais-socle existent. Rien de migré encore.

---

## Phase 3: User Story 1 — Le pattern armé et vérifié mécaniquement (P1) 🎯 MVP

**Goal**: la chaîne rend le pattern obligatoire SANS relecture humaine — génération déterministe commitée, analyse dédiée bloquante, garde-fou de dérive. C'est la seule story dont le bénéfice survit à une interruption.

**Test indépendant** (spec US1) : faute de provider volontaire → `dart analyze` EXIT 3 ; fichier annoté modifié sans régénération → CI rouge sur le diff.

- [X] T008 [US1] Compléter le job `apps` de `.github/workflows/apps.yml` (contrats/ci-apps.md, « prêt à coller ») : matrice ×3 avec `codegen: true` (`mefali_core`, `mefali_pro`) / `codegen: false` (`mefali_client`) ; ordre imposé FR-034 → `flutter pub get` → `dart run build_runner build` (si `codegen`) → **`git diff --exit-code -- .`** (garde-fou de dérive, scopé au **répertoire du paquet** pour NOMMER le coupable — R12 option B, ferme aussi le trou l10n de `mefali_core`) → `dart analyze` → `flutter test --exclude-tags golden`. Le contrôle de dérive tourne aussi sur `mefali_client` (portée = répertoire, pas `*.g.dart`). Modèle : le garde-fou `contrat-clients.yml` qui ne couvre PAS `apps/` (FR-031). Dépend de T003, T004, T005 (au moins un `.g.dart` à garder). (½ j)
- [X] T009 [US1] Armer et documenter l'**Independent Test** dans `specs/004-riverpod-etat-flutter/quickstart.md` (§SC-006/SC-007) — le SEUL garde-fou du mécanisme `diagnostics: error` (UNDOCUMENTÉ, à re-jouer à chaque montée de SDK) : (a) faute volontaire (propriété publique sur un Notifier, ou `missing_provider_scope`) → `dart analyze` **EXIT 3**, puis `git checkout` ; un EXIT 0 = plugin muet (`flutter analyze` déguisé ou bloc mal placé), un EXIT 2 = escalade `diagnostics:` tombée (repli `--fatal-infos`) ; (b) fichier annoté modifié sans régénération → `git diff --exit-code -- .` **échoue** et nomme le paquet. ⚠ **Note d'honnêteté sur l'acceptance 6** (« le point d'entrée enveloppe l'arbre dans la portée ») : US1 ne pose **AUCUN** `ProviderScope` jetable — l'enveloppement est réalisé **incrémentalement** (`mefali_pro` en US2 T011, `mefali_client` en US5 T026) et l'acceptance 6 se vérifie donc **à partir d'US2**. Dépend de T008. (½ j)

**Checkpoint US1**: outillage posé et prouvé — le reste peut être repris story par story même si le cycle s'interrompt ici.

---

## Phase 4: User Story 2 — Session + intercepteur, sans dédoubler le renouvellement (P2)

**Goal**: migrer le nœud le plus risqué — session, ses deux clients HTTP, l'intercepteur qui pose le jeton et renouvelle. Le harnais naît ici, piloté par le cas le plus dur, et sert ensuite à toutes les stories.

**Test indépendant** (spec US2) : rejouer les cas de session et d'appareils ; N requêtes concurrentes expirées → compter les renouvellements : **exactement 1**.

- [ ] T010 [US2] Le NŒUD, dans `apps/packages/mefali_core/lib/src/auth/` (`clients.dart` + `session.dart`, `part '*.g.dart'`) : `clientSessionProvider` et `clientConfigProvider` (`@Riverpod(keepAlive: true)`, `MefaliApiClient(basePathOverride: ref.watch(urlApiProvider))` — **NI `dio:` NI `interceptors:`**, les délais 5000/3000 ms ne vivent que dans la branche par défaut, FR-017), `stockageJetonsProvider` (`keepAlive`, `StockageJetonsSecurise()`), `sessionProvider` (`NotifierProvider<Session, EtatSession>` **`keepAlive`**, `build()` rend `EtatSession.initiale()` et NE charge RIEN, `updateShouldNotify => true` explicite, `charger/ouvrir/fermer` avec ordre **`state =` PUIS `await` l'I/O** — R3). `InterceptorAutorisation` devient **PUBLIC** (posé par `clientSession`, `ref.onDispose(remove)` par IDENTITÉ — **JAMAIS `removeWhere`**, FR-018 ; détient le `Ref` de `clientSession`, JAMAIS le notifier ; lit **l'ÉTAT** `ref.read(sessionProvider).acces` et appelle des **MÉTHODES** `.notifier` — seul montage qui passe `dart analyze`). **Verrou `_enCours` INCHANGÉ, zéro ligne** (R7). `SessionAuth.client`/`.stockage` **SUPPRIMÉS** (leurs 5 consommateurs liront `clientSessionProvider`). `dart run build_runner build`, `.g.dart` commités. Dépend de T005, T006. (1 j)
- [ ] T011 [US2] Réactivité de la racine + amorçage de la portée : `apps/packages/mefali_core/lib/src/auth/racine_auth.dart` `ListenableBuilder(session)` → `ConsumerStatefulWidget` qui **`watch(sessionProvider)`** ; `initState` appelle `ref.read(sessionProvider.notifier).charger()` (l'écran de démarrage tient l'attente, l'état chargé ne redevient JAMAIS « en cours » — FR-022) ; retour au parcours d'auth par **reconstruction de l'arbre**, sans navigation impérative, **sans double poussée** (FR-016). `apps/mefali_pro/lib/main.dart` : `UncontrolledProviderScope(container: ProviderContainer(retry: pasDeRetry, overrides: [urlApiProvider.overrideWithValue(_urlApi)]))` — la SEULE forme qui donne un handle avant `runApp` (R10). ⚠ **La config reste sur l'ancien rail** (`main.dart` construit encore `ServiceConfig` et le passe) **jusqu'à US3** T017, qui ajoute `unawaited(container.read(serviceConfigProvider))` et retire l'ancien montage ; `racine_auth.dart` est re-touché en US3 pour la lecture de config. Dépend de T010. (1 j)
- [ ] T012 [US2] Compléter `conteneurMefali` (partie session) dans `apps/packages/mefali_core/lib/harnais.dart` : `retry: pasDeRetry` sur la portée, `urlApiProvider.overrideWithValue('http://test.invalid')`, `stockageJetonsProvider.overrideWith(StockageJetonsMemoire(jetons))`, transport posé sur `container.read(clientSessionProvider).dio.httpClientAdapter` **APRÈS la pose** de l'intercepteur (FR-036, par construction) ; corps de `compteIntercepteursApp` → `dio.interceptors.whereType<InterceptorAutorisation>().length` (par TYPE, les 4 intercepteurs du client généré hors décompte). ⚠ **`sessionProvider` n'est JAMAIS un paramètre** : on surcharge les DÉPENDANCES, jamais le sujet ; les surcharges vivent dans le conteneur RACINE (imbriqué ⇒ 2 notifiers ⇒ 2 intercepteurs). Dépend de T007, T010. (½ j)
- [ ] T013 [P] [US2] **Audit `ProviderException` sur les 86 cas** — sweep préliminaire AVANT toute migration de test (harnais-de-test.md) : Riverpod 3 **enveloppe** les erreurs, donc tout `expect(..., throwsA(isA<DioException>()))` sur un chemin qui **traverse un provider** casse. Passer les 13 fichiers de test au crible `throwsA`/`isA<DioException>` ; verdict par cas : `isA<ProviderException>()` + assertion sur la **cause** enveloppée, OU constat que le chemin ne traverse aucun provider (assertion juste). **JAMAIS** relâcher en `isA<Object>` (FR-003). Consigner le verdict par cas (commentaire ou note de tâche) — pour ne pas le diagnostiquer 13 fois. ⚠ Verdict consommé par TOUTES les migrations de test qui suivent (T014/T016 en US2, T021/T022/T025 en US3-US4) via l'ordre de phase, pas seulement par les arêtes déclarées. Dépend de T010 (le graphe de providers est connu). (½ j)
- [ ] T014 [US2] Migrer `apps/packages/mefali_core/test/auth/session_auth_test.dart` (#13, le nœud, 8 cas) : émissions (`:48-58`) → `container.listen(sessionProvider, …)` **sans `fireImmediately`** (⇔ `addListener`) + `expect(emissions, 1)` **ÉGAL STRICT** (exception nommée de FR-003, jamais `greaterThanOrEqualTo`) ; **cas additionnel** deux `ouvrir()` à jetons **identiques** ⇒ `expect(emissions, 2)` (rougit si on retire `updateShouldNotify => true`) ; **assertion FR-022 versant session** : après `charger()` sur stockage peuplé, `read(sessionProvider).charge == true`, et un second `charger()` **ne le remet jamais à `false`** (monotone — l'écran de démarrage ne peut pas réapparaître) ; intercepteur attrapé par `.last` (`:78-95`) → **une vraie requête part**, on lit `transport.recues` (plus aucune position, plus aucun `onRequest` manuel) ; `session.stockage` (`:60`, `:75`) → `container.read(stockageJetonsProvider)` ; `addTearDown(container.dispose)`. Dépend de T012, T013. (1 j)
- [ ] T015 [US2] Fichier NEUF `apps/packages/mefali_core/test/auth/session_intercepteur_test.dart` (`test()`, **PAS** `testWidgets()`, AUCUN tag) — les 3 cas de SC-005 : **FR-013/FR-018** unicité par TYPE = 1 après première évaluation, après `invalidate(sessionProvider)`, après `fermer()/ouvrir()/ouvrir()`, après `invalidate(clientSessionProvider)` ; **0** sur `clientConfig` (FR-017) ; **0** après `container.dispose()` (FR-018) ; **FR-014** N requêtes 401 concurrentes ⇒ `expect(renouvellements, 1)` puis `expect(rejeux, N)` — **la retenue EST le test** : le faux `/auth/rafraichir` attend un `Completer` ouvert, sinon vert même sans verrou (`reason` : rotation R2 ⇒ jeton mort rejoué ⇒ vol présumé ⇒ session révoquée). Dépend de T012. (1 j)
- [ ] T016 [US2] Appareils (la surface d'intégration réelle de l'intercepteur — harnais-de-test.md #11 le tire en US2, avant les listes d'US3) : `apps/packages/mefali_core/lib/src/appareils/ecran_appareils.dart` `late Future + setState` → `mesSessionsProvider` (`AsyncNotifierProvider`, `@riverpod` nu autoDispose) avec `recharger()` portant **`state = const AsyncLoading()` EXPLICITE** (le squelette DOIT réapparaître, FR-023 ; `.when()` reste aux défauts) ; les gardes `if (mounted)` disparaissent (edge case) ; `.g.dart` commité. Migrer `apps/packages/mefali_core/test/appareils/ecran_appareils_test.dart` (#11, 7 cas dont **3 refresh 401** `:166-238` — on surcharge les **feuilles**, JAMAIS `sessionProvider` ; `:196-220` **n'appelle pas `charger()`**, il repose sur `RacineAuth.initState`, le déclenchement doit y rester — FR-002). Dépend de T012, T013. (1 j)

**Checkpoint US2**: le nœud migré, l'intercepteur unique et structurel, le renouvellement partagé couvert par un test qui n'existait pas — le harnais sert 11 cas.

---

## Phase 5: User Story 3 — Le paquet cœur, configuration gelée comprise (P3)

**Goal**: migrer les porteurs restants du cœur — parcours d'auth, racine, adresses, service de configuration **en non-réactivité GELÉE**. L'état strictement local (saisies, focus, compte à rebours, brouillons) reste où il est.

**Test indépendant** (spec US3) : rejouer auth/adresses/appareils/config ; sur émulateur, laisser tourner au-delà d'un rafraîchissement de config → aucun écran ne bouge.

- [ ] T017 [US3] La configuration gelée, dans `apps/packages/mefali_core/lib/src/config/` : `serviceConfigProvider` (`@Riverpod(keepAlive: true) Raw<Future<ServiceConfig>>` — **PAS `FutureProvider`** : aucun `AsyncValue` à émettre ⇒ FR-021 impossible à violer, aucun retry ⇒ pas de 2ᵉ Timer ; `watch` `sourceConfig` ET `cacheConfig`, les CHAÎNE par `.then` sans `await`, corps SYNCHRONE, `ref.onDispose(arreter)`), `sourceConfigProvider` (`SourceConfigApi(ref.watch(clientConfigProvider))`), `cacheConfigProvider` (`Raw<Future<CacheConfig>>`, `SharedPreferences.getInstance().then(CacheConfigPreferences.new)`), les 3 **`keepAlive`**. **CHANGEMENT DE SIGNATURE DE PRODUCTION** dans `amorce_config.dart` : `demarrerServiceConfig({required SourceConfig source, required CacheConfig cache})` — la fonction REÇOIT au lieu de construire (inversion d'injection FR-010/FR-035, **PAS** une correction opportuniste — sans elle les surcharges du harnais seraient INERTES et FR-035 non tenu). `apps/mefali_pro/lib/main.dart` : ajouter `unawaited(container.read(serviceConfigProvider))` **avant `runApp`, non attendu** (FR-024, R10) et **retirer l'ancien montage** de config. `.g.dart` commités. Dépend de T010, T011. (1 j)
- [ ] T018 [US3] Les 2 consommateurs de config en **`ref.read`, JAMAIS `ref.watch`** (instantané figé à l'entrée de l'écran — FR-021) : `apps/packages/mefali_core/lib/src/auth/racine_auth.dart` `_lireVersionConsentement()` et `apps/mefali_pro/lib/roles/routeur_roles.dart` `_lireTransports()` deviennent `ConsumerStatefulWidget`, corps conservé, `widget.config` → `ref.read(serviceConfigProvider)`, la garde `if (config == null)` disparaît ; `_versionConsentement`/`_transportsActifs` restent de l'**état local** (ils SONT l'instantané) ; `versionConsentement:`/`transportsActifs:` restent des **paramètres** de `ParcoursAuth`/`EcranEtatDemande`/`FormulaireDossierCoursier`. `ParcoursAuth` appelle `ref.read(sessionProvider.notifier).ouvrir()`. ⚠ **Ne touche que la lecture de config de `routeur_roles.dart`** ; sa migration des rôles (`watch(etatRolesProvider)`) est US4 T024 (split honnête). Dépend de T017. (½ j)
- [ ] T019 [US3] Adresses : `apps/packages/mefali_core/lib/src/adresses/liste_adresses.dart` `late Future + setState` → `mesAdressesProvider` (`AsyncNotifierProvider`, `@riverpod` nu, `recharger()` avec **`state = const AsyncLoading()` EXPLICITE**, FR-023) ; `_DialogueRenommer` garde son `TextEditingController` **local** (FR-009) ; gardes `if (mounted)` supprimées. `.g.dart` commité. Dépend de T010. (½ j)
- [ ] T020 [US3] Compléter `conteneurMefali` (partie config) dans `apps/packages/mefali_core/lib/harnais.dart` : surcharger `sourceConfigProvider` et `cacheConfigProvider` **PAR DÉFAUT** (double en mémoire, `cacheConfig` enveloppé `Future.value(cache)` — le paramètre reste un `CacheConfig` nu) — ⚠ sans ce défaut les **23 cas de `mefali_pro`** appelleraient le vrai `SharedPreferences` (canal de plateforme) + le réseau, et **SC-004 se perdrait sans qu'aucune assertion ne bronche** (la protection `config: null` disparaît avec le provider) ; ne MORD que grâce à la nouvelle signature T017. On surcharge les **dépendances**, jamais `serviceConfigProvider` (le vrai service reste sous test — R11). Dépend de T007, T012 (le squelette du harnais, complété ici), T017. (½ j)
- [ ] T021 [US3] Migrer `apps/packages/mefali_core/test/config/service_config_test.dart` (#9, 5 cas, difficulté moyenne) : doubles → surcharges ; **conteneur créé, LU et disposé DANS `fakeAsync`** — `Timer.periodic` capte `Zone.current` à sa création et le `build` d'un provider est **paresseux**, c'est le `container.read(...)` qui doit être dans la zone ; `ProviderContainer` **NU**, pas `.test()` (seul endroit du plan où `.test()` est déconseillé même depuis `test/`) ; assertions timer à 0 h / 1 h / **2 h sans aucun auditeur** (FR-019), version identique ⇒ 0 écriture, version neuve ⇒ valeur+cache remplacés, hors-ligne servi par le cache. Migrer aussi `apps/packages/mefali_core/test/auth/version_consentement_test.dart` (#7, 2 cas — `_session()`+`_monter` → harnais, `versionConsentement:` **reste un paramètre**). Dépend de T017, T020. (1 j)
- [ ] T022 [US3] Migrer `apps/packages/mefali_core/test/adresses/adresses_test.dart` (#8, 15 cas dont **8** migrent — `ListeAdresses` `:85-238` → harnais/`mesAdressesProvider` ; **7 ne bougent PAS** : `FeuilleEnregistrerAdresse` callbacks+scalaires et `ConfigDistante.depuisJson` décodage pur ; `jouerNote:` reste un **callback** FR-011) et `apps/packages/mefali_core/test/auth/otp_dev_test.dart` (#6, 4 cas **LITTÉRALEMENT identiques** dont `expect(modeDevOtp, isFalse)` FR-025 — **mais** `_AdaptateurFige` `:8`, l'un des 6 transports de SC-011, → `TransportFake`). ⚠ Les 5 fichiers du **lot facile #1–#5** (`contrat_oneof_test`, `mefali_theme_test`, les 2 `splash_golden_test`, `ecrans_auth_test`) sont **vérifiés-intouchés : on n'y touche PAS**. Dépend de T019, T020. (1 j)

**Checkpoint US3**: le cœur migré, la config gelée par son type (`Raw`, rien à émettre), les listes réaffichent leur squelette — `mefali_pro`/`mefali_client` peuvent enfin migrer.

---

## Phase 6: User Story 4 — Les rôles, sans fuite inter-comptes (P4)

**Goal**: migrer l'état des rôles de `mefali_pro`. Sa durée de vie est une **garantie de sécurité** : les rôles d'un compte ne survivent JAMAIS à un changement de compte.

**Test indépendant** (spec US4) : rejouer routeur de rôles et formulaire de dossier ; sur émulateur, compte A → déconnexion → compte B → aucune trace de A.

- [ ] T023 [US4] `apps/mefali_pro/lib/roles/etat_roles.dart` `EtatRoles extends ChangeNotifier` → `@riverpod` **NU (autoDispose)** `class EtatRoles extends _$EtatRoles` : `build()` fait `ref.watch(sessionProvider.select((e) => e.connecte))` (arête GRAVÉE FR-020/SC-010 — `.select` est une **correction de bug**, pas une optimisation : `watch` nu rechargerait à chaque rotation de jeton) **et NE charge RIEN** (la mémoire de `actif` vit dans `state`, la destruction dans `build()`) ; `charger()` corps identique à `:155-194`, `basculer()` ne parle NI au réseau NI à la session, `updateShouldNotify => true`. `EtatRoles.session` (`:102, :105`) → `ref.read(clientSessionProvider)`. ⚠ `keepAlive` ici = régression de sécurité silencieuse (mode de panne n°3). **`RouteurRoles.etat` SUPPRIMÉ** (`:20, :37, :44, :73` — couche d'injection câblée nulle part, code mort ; la porter le graverait — FR-043). `.g.dart` commité. Dépend de T010, T017, T018 (`routeur_roles.dart` déjà touché en US3 pour `_lireTransports`). (1 j)
- [ ] T024 [US4] `apps/mefali_pro/lib/roles/routeur_roles.dart` `ListenableBuilder(roles)` (`:79`) → `Consumer` qui **`watch(etatRolesProvider)`**, `charger()` déclenché depuis le routeur (`:50`), branches `ChargementPro`/`ErreurPro` reconstruites du même `EtatRolesData`. `apps/mefali_pro/lib/roles/formulaire_dossier.dart` **reste un `ConsumerStatefulWidget`** : `_cleIdempotence` (`:95`, `Uuid().v7()`) reste un **initialiseur de champ de `State`**, `_vehicules`/`_piece` restent locaux (FR-026) ; le rendre sans état est le SEUL chemin par lequel **R14** sortirait de son isolement — **INTERDIT**. Seul `session:` disparaît de sa construction. Dépend de T023. (½ j)
- [ ] T025 [US4] Migrer `apps/mefali_pro/test/roles/routeur_roles_test.dart` (#12, 11 cas — 7 widget, 4 unitaires dont la **mémoire de `_actif`** `:295-322` : deux `charger()` sur la MÊME instance ⇒ `actif: coursier` puis `actif: vendeur`) : ⚠ **règle du fichier — tout cas unitaire sur `etatRolesProvider` OUVRE un abonnement** `final sub = container.listen(etatRolesProvider, (_, __) {}); addTearDown(sub.close);` — sinon (autoDispose) le notifier est rejeté entre les deux `charger()`, `build()` rejoué, `actif` repart à `null` et le test devient **VERT SANS RIEN PROUVER** (pire résultat possible). Migrer `apps/mefali_pro/test/roles/formulaire_dossier_test.dart` (#10, 10 cas — 7 formulaire dont `session:` disparaît, 3 `EcranEtatDemande` en `runAsync` + préchargement hors arbre → `harnaisApp(container:)`) : le cas `:192-229` est le **garde-fou de R14** — s'il tombe, on a un **périmètre violé**, pas un test à réparer. ⚠ Piège de zone/`TickerMode` : un écran hors-champ suspend ses listeners, `pumpAndSettle` peut **figer** (parade `TickerMode(enabled: true)` seulement si ça mord). Dépend de T023, T020. (1 j)

**Checkpoint US4**: les rôles migrés, l'isolation inter-comptes gravée dans le graphe, R14 exactement où le cycle l'a trouvé.

---

## Phase 7: User Story 5 — Plus aucun porteur hors du moule (P5)

**Goal**: terminer par `mefali_client` (trivial), puis constater les compteurs à zéro. Le code mort qui documentait l'ancienne convention disparaît avec elle.

**Test indépendant** (spec US5) : rechercher les symboles de l'ancien pattern → aucun résultat ; rejouer les 86 + les 3 neufs.

- [ ] T026 [US5] `apps/mefali_client/lib/main.dart` (2 fichiers, aucun état) : `UncontrolledProviderScope(container: ProviderContainer(retry: pasDeRetry, overrides: [urlApiProvider.overrideWithValue(_urlApi)]))` + `unawaited(container.read(serviceConfigProvider))` non attendu — n'instancie **plus** ni session ni configuration à la main (FR-010) ; `_urlApi = String.fromEnvironment(...)` reste une **constante de compilation** du point d'entrée (FR-012). `apps/mefali_client/lib/splash_screen.dart` **INCHANGÉ** (`StatelessWidget` nu — **JAMAIS** `ConsumerWidget`, seul chemin de casse du golden). Écran de démarrage identique au pixel près. Dépend de T017. (½ j)
- [ ] T027 [US5] Fermeture du périmètre + nettoyage. **Greps SC-001 à zéro** (les décomptes 2/2/6 → 0) : `extends ChangeNotifier`, `ListenableBuilder(`, `notifyListeners()` → aucune ligne ; `custom_lint` → 0 ; `SessionAuth.client`/`RouteurRoles(etat:` → 0. ⚠ **`addListener` garde 2 hits légitimes** (`ecran_otp.dart:67` état local FR-009 ; le hit de test migre) — SC-001 compte les `ListenableBuilder`, pas les listeners de contrôleurs. **Grep de protection FR-025** (aucun test ne l'attrape — `otp_dev_test` reste vert même si violé) : `modeDevOtp` reste `const bool.fromEnvironment(...)` (`otp_dev.dart`) et **aucun provider ne le référence** ; par symétrie FR-011, les 4 fonctions injectées (`choisirPiece`, `jouerNote`, `capturerNote`, `lireCodeDevReseau`) restent des paramètres — aucune n'est devenue un provider. Réécrire le **commentaire normatif** `etat_roles.dart:98-99` (« Convention de l'app : `ChangeNotifier` nu… ») et `racine_auth.dart:91` pour énoncer la **nouvelle** convention (FR-042). **CONSIGNER (non corriger) les défauts latents** (FR-027) : `uuid 4.5.3` vs 4.6.0 ; `clients/dart` en `build_runner: any` + lock gitignoré ; `ServiceConfig.arreter()` que personne n'appelait (le Timer fuit — l'`onDispose` de T017 relève de FR-018, exception nommée) ; `dart format` non vérifié en CI ; `_vehicules` muté en place ; l'ordre A `state =`/I/O si l'écriture Keystore lève. Dépend de toutes les tâches US2–US4. (1 j)

**Checkpoint US5**: 0 notificateur, 0 observateur, 0 notification manuelle — la convention n'a plus d'exception.

---

## Phase 8: User Story 6 — Le moule opposable aux cycles suivants (P6)

**Goal**: verrouiller le résultat pour que CRS/VND/CMD/DSP partent du même moule sans avoir à choisir. On verrouille en dernier, sur du code prouvé.

**Test indépendant** (spec US6) : ouvrir la constitution, y trouver une règle opposable qui tranche sans discussion le choix de gestion d'état d'un futur cycle.

- [ ] T028 [US6] **PRÉPARER** l'amendement de constitution (FR-040) — ⚠ **NE PAS éditer `.specify/memory/constitution.md` à la main** (interdit par la gouvernance) : rédiger le **rapport d'impact** (propagation aux templates dépendants) et le **texte du principe** à soumettre via `/speckit.constitution`. Le principe DOIT nommer : provider **GÉNÉRÉ par annotation**, injection par la **portée**, état local réservé à ce qui ne sort pas du widget, `retry: pasDeRetry` sur toute portée, durée de vie **explicite et argumentée** (`@riverpod` nu = autoDispose, aucun lint ne garde l'opposition), et **LES DEUX MOULES** — `Notifier<Etat…>` (session, rôles) / `AsyncNotifier` (listes) — sinon le prochain cycle uniformisera derrière `AsyncValue` et détruira FR-022. Ajouter **Riverpod à la liste nommée du principe X**. Version **1.0.1 → 1.1.0** (ajout de principe ⇒ **MINOR**). Vérifier la **non-régression** de TRX-08 (P1) et du tableau §0.6 dans `docs/user-stories-v2.md` (prérequis du cycle, pas son livrable — US6 n'en contrôle que la non-régression). Dépend de T027 (pattern prouvé sur le code réel). (½ j)
- [ ] T029 [US6] `CLAUDE.md` : ajouter à la section « Règles impératives » que la gestion d'état des apps Flutter est **Riverpod codegen** (provider généré, injection par la portée, les deux moules, état local qui reste local) — **même règle que la constitution, sans la contredire** (FR-041). Dépend de T028. (½ j)

**Checkpoint US6**: la constitution nomme le pattern ; `CLAUDE.md` l'énonce ; les cycles suivants n'ont plus à choisir.

---

## Phase 9: Polish & transverse

**Objectif** : dérouler la validation des 12 SC, rejouer les goldens à la main, revue finale.

- [ ] T030 Dérouler `specs/004-riverpod-etat-flutter/quickstart.md` — les critères **hors émulateur** : SC-001 (3 greps à zéro), SC-002 (**≥ 89** cas verts, 0 affaibli), SC-005 (`session_intercepteur_test`), SC-006 (`dart analyze` ×3 pass + Independent Test EXIT 3), SC-007 (`build_runner` ×2 déterministe, `git status` vide, `.g.dart` versionnés), SC-008 (`verifier-accord-locks.sh` 0 désaccord), SC-010 (`grep` **8** `keepAlive` / **3** `@riverpod` nu — un attendu à 6 ferait rougir du code juste), SC-011 (6 transports + 6 montages → harnais unique, `overrideWith` session/clientSession → 0). Corriger ce qui échoue, consigner les résultats. Dépend de T027, T029. (½ j)
- [ ] T031 Validation sur **émulateur Android** (iOS hors périmètre) — les SC que la CI ne rattrape pas : parcours complet **inscription → rôles → dossier → adresses** indiscernable d'avant (SC-003) ; **fil réseau avant/après** (`diff` des `method`/`path` des logs API sur `main` puis `004` → **VIDE**, `GET /config` une fois au lancement, `Authorization` absent de `/config` — SC-004) ; app laissée **> 1 h** sur consentement puis formulaire, config de zone changée en base → **0 rebuild** (SC-009) ; compte A (coursier) → déconnexion → compte B (vendeur) → **aucun rôle de A**, même fugitivement (SC-010). **Rejouer les 2 goldens À LA MAIN** (`flutter test --tags golden` sur `mefali_pro` et `mefali_client`) → verts, **0 diff**, aucune image réécrite — **`--update-goldens` INTERDIT** (FR-005). Dépend de T030. (1 j)
- [ ] T032 Revue **Definition of Done** (`docs/user-stories-v2.md` §0.4 — DERNIÈRE tâche) : nommer les **points vacants** de ce refactor pur — (1) « critères d'acceptation couverts » se réinterprète : les **86 existants préservés** (pas de critère neuf) ; (2) **AUCUNE** API → openapi.json/`clients/dart`/`clients/ts` **INTOUCHÉS**, aucun `generate-clients.sh` ; (3) **AUCUN** SQL → aucune migration, aucun `cargo sqlx prepare`, aucun `cargo test` ; (4) **AUCUN** événement outbox → `docs/taxonomie-evenements.md` intouché ; (5) clés i18n fr **non régressées** (aucune chaîne en dur) ; (6) **AUCUN** paramètre paramétrable. Vérifier : les `.g.dart` commités et **jamais édités à la main**, les 2 goldens sans régénération, R14/iOS/enregistrement vocal **exactement** dans l'état trouvé, l'amendement constitution **passé via `/speckit.constitution`** (sinon **bloquant** de commit final — T028 n'a que préparé le texte), commits `refactor(apps): TRX-08 …`. Dépend de T031. (½ j)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 Setup (T001 → T002)
   └─▶ Phase 2 Foundational (T003, T004 ; T005, T006[P] ; T007) ── bloque TOUT
          └─▶ Phase 3 US1 (T008 → T009)                          ── outillage (MVP)
          └─▶ Phase 4 US2 (T010 → {T011, T012} ; T013[P] ; → T014, T015, T016)
                 └─▶ Phase 5 US3 (T017 → {T018, T019, T020} → {T021, T022})
                        └─▶ Phase 6 US4 (T023 → T024 → T025)
                               └─▶ Phase 7 US5 (T026 ; T027 après US2–US4)
                                      └─▶ Phase 8 US6 (T028 → T029)
                                             └─▶ Phase 9 Polish (T030 → T031 → T032)
```

### Chaîne critique

T001 → T002 → T003 → T005 → T007 → T010 → T012 → T014 → T017 → T020 → T023 → T025 → T027 → T028 → T031 → T032.

### Parallel Opportunities

```text
# Foundational, après T001/T003 :
T005 ∥ T006            # portee.dart (primitives) ∥ types d'état (2 fichiers)
# US2, après le nœud T010 :
T011 ∥ T012            # racine+main.dart ∥ harnais(session)   (fichiers disjoints)
T013 [P]               # audit ProviderException = lecture, dès que le graphe est connu
T015 ∥ T016            # test neuf ∥ appareils   (après T012)
# US3, après T017 :
T018 ∥ T019            # consommateurs config ∥ adresses   (T020 config-harnais avant les tests pro)
# US6 se prépare pendant que Polish n'a pas encore besoin de l'émulateur.
```

---

## Implementation Strategy

**MVP = US1 (outillage)** : Setup → Foundational → US1. Livré, le pattern est armé et vérifié mécaniquement ; c'est la seule story dont le bénéfice **survit à une interruption** — le reste se reprend story par story (garde-fou de périmètre de la spec, estimé ~1,5 j pour outillage + harnais, **sous le seuil de 2 j** ⇒ lot maintenu).

**Livraison incrémentale cœur → pro → client** (plan, Structure Decision) : US2 (le nœud de session, le plus risqué, avec son harnais piloté par le cas le plus dur) → US3 (le reste du cœur, config gelée) — rien de `mefali_pro`/`mefali_client` ne peut migrer avant. Puis US4 (rôles, la seule durée de vie qui est une garantie de sécurité) → US5 (`mefali_client` trivial ferme le périmètre). US6 verrouille **en dernier**, sur du code prouvé, pas sur l'intention.

**Développeur solo** : la revue est **outillée, pas humaine** — `dart analyze` (plugin actif), le garde-fou de dérive et `accord-locks` tiennent ce qu'une relecture tiendrait ; mais **AUCUN lint ne garde l'opposition `keepAlive`/autoDispose** (8 vs 3), ni `.select` vs `watch` nu, ni les deux sémantiques opposées de FR-022 : ces invariants-là ne tiennent que par les **tests** et la **revue**. Répartition exacte : l'opposition durée de vie et `.select` sont tenues par SC-005 (unicité) et SC-010 (isolation inter-comptes) ; les **deux sémantiques de FR-022** par SC-002 (les cas de rechargement de listes/rôles réaffichent le squelette) + l'assertion `charge` monotone de T014 + SC-003 (émulateur) — **pas** par SC-005/SC-010, qui ne les testent pas. Suivre la chaîne critique ; utiliser les fenêtres [P] quand une tâche attend.

---

## Notes

- **32 tâches**, calibrées ½ j – 1 j (~20,5 j-homme) ; refactor PUR — l'invariant central (FR-001/002) prime sur chaque story, et une story « verte » qui améliore un comportement au passage a **échoué**.
- Les `.g.dart` sont **GÉNÉRÉS, commités, JAMAIS édités à la main** — même règle que `clients/dart` (constitution I). Commande **`dart run build_runner build` NUE** (`--delete-conflicting-outputs` supprimé de 2.15.x).
- **Ne JAMAIS re-résoudre** les dépendances : `flutter pub add` incrémental, jamais `rm pubspec.lock` ni `pub upgrade` (`uuid 4.5.3 → 4.6.0` casserait l'accord des 3 locks, SC-008).
- Les **3 écarts au principe X** (prérelease `riverpod_analyzer_utils 1.0.0-dev.10`, plafond `build_runner 2.15.1`, `riverpod_lint` hors lockfile) et **l'écart VII** (2 lectures de config non couvertes, vérifiées sur émulateur) sont **nommés** au Complexity Tracking du plan — pas contournés.
- **`ProviderException` enveloppe les erreurs (T013)**, le **retry par défaut** (10 essais) viole FR-002 sans une ligne (parade `pasDeRetry` ×3 portées), et le **garde-fou de dérive** sont les trois pièges qui rougissent franchement — les moins coûteux. Les pièges **silencieux** (config vivante, `keepAlive` sur les rôles, `watch` nu, `--update-goldens`, surcharge du sujet) ne sont attrapés par **aucun outil** : voir contracts/providers.md « Les 5 gestes par défaut qui cassent le cycle EN SILENCE ».
- Committer après chaque tâche (message conventionnel référençant la story, ex. `refactor(apps): TRX-08 le nœud de session passe en providers …`).
- Chaque checkpoint de story est un point d'arrêt valide pour valider indépendamment.
