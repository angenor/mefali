# Contrat — Harnais de test partagé (FR-037)

Interface du cycle 004 vis-à-vis des cycles métier suivants (CRS, VND, CMD…) : comment on monte
une app Mefali sous portée de providers, comment on substitue une dépendance, et ce qu'on ne
substitue JAMAIS. Il n'existe aujourd'hui **aucun** helper — les doubles sont recopiés d'un
fichier de test à l'autre : **6 copies du transport HTTP** (5 × `_Transport` + `_AdaptateurFige`,
`otp_dev_test.dart:8`), **6 montages de session** (FR-037, SC-011), **9 montages d'app** — 9 helpers
privés `_monter`/`_app` rendant un `MaterialApp`, **un par fichier de test**, recopiés à
l'identique (vérifié par exécution le 2026-07-17 ; SC-011 `spec.md:265` ne chiffre que le
transport et la session, pas les montages d'app). Ce
contrat fixe l'API exacte du harnais, les **trois contraintes dures** qui en DÉTERMINENT la forme
— toutes trois établies par exécution réelle sous Flutter 3.44.6 / Dart 3.12.2, pas par lecture de
doc —, l'endroit où il vit, et les règles qu'aucun outil ne tient. FR-035, FR-036, FR-037, FR-038,
FR-039 ; SC-004, SC-005, SC-011. Détail des décisions : [research.md](research.md) R11 (le
harnais), R3 (le nœud), R5 (la configuration gelée), R10 (l'amorçage et le retry).

## Signature — l'API exacte du harnais

Fichier : `apps/packages/mefali_core/lib/harnais.dart` — bibliothèque **séparée**, **PAS** ajoutée
au barrel `mefali_core.dart` (R11).

```dart
/// Harnais de test partagé des apps Mefali (FR-037).
///
/// AUCUNE signature de ce fichier ne mentionne `flutter_test` ni `WidgetTester` :
/// `flutter_test` deviendrait une dépendance de PRODUCTION de `mefali_core`
/// (contrainte 1). L'appelant, resté dans `test/`, fait lui-même
/// `tester.pumpWidget(harnaisApp(...))` et `addTearDown(container.dispose)`.
library;

// `pasDeRetry` est RÉUTILISÉE, pas déclarée ici : c'est une constante de
// PRODUCTION de `mefali_core`, exportée par le barrel (voir plus bas).
import 'package:mefali_core/mefali_core.dart' show pasDeRetry;

/// Remplace les 6 copies de transport des fichiers de test (SC-011).
///
/// `repondre` rend un `FutureOr<ResponseBody>`, et NON un `ResponseBody` comme
/// les 6 copies actuelles : sans réponse RETENABLE, le test FR-014 serait vert
/// sans verrou — le 1er renouvellement aboutirait avant que la 2e requête
/// n'échoue (R7).
class TransportFake implements HttpClientAdapter {
  TransportFake(this.repondre);
  final FutureOr<ResponseBody> Function(RequestOptions options) repondre;
  final List<RequestOptions> recues = <RequestOptions>[];
}

/// Réponse JSON prête à l'emploi — le corps sérialisé, les en-têtes du client généré.
ResponseBody reponseJson(Object corps, {int statut = 200});

// FR-002 — Riverpod 3 RÉESSAIE les providers en échec PAR DÉFAUT (10 essais,
// backoff 200 ms → 6,4 s ; `provider_container.dart:940-954`). AUCUNE requête
// n'était rejouée avant ce cycle.
//
// `Duration? pasDeRetry(int tentative, Object erreur) => null;` N'EST PAS DÉCLARÉ
// ICI (cf. l'import en tête) : c'est une constante de `mefali_core`, PUBLIQUE,
// déclarée dans une bibliothèque de PRODUCTION (à côté des providers, exportée
// par le barrel `mefali_core.dart`) — le harnais la RÉUTILISE, au même titre que
// les 2 `main.dart`. Elle est posée sur TOUTE création de portée, JAMAIS réglée
// par site d'appel (R10, R11).
//
// Pourquoi pas ici : un top-level privé est privé À SA BIBLIOTHÈQUE — chaque
// `main.dart` qui redéclarerait `_pasDeRetry` SERAIT « un réglage par site », ce
// que la règle de fichier n°1 interdit. Et la déclarer dans `harnais.dart`
// forcerait les 2 `main.dart` de PRODUCTION à importer le harnais, ce qui
// détruirait l'argument de tree-shaking ci-dessous (« Où vit le harnais »).

/// Conteneur explicite pour les cas SANS arbre de widgets (FR-038).
///
/// Construit avec le constructeur PUBLIC de `ProviderContainer` — JAMAIS
/// `ProviderContainer.test()`, qui est `@visibleForTesting` et illégal depuis
/// `lib/` (contrainte 2). L'appelant DOIT faire `addTearDown(container.dispose)`.
///
/// Surcharge PAR DÉFAUT `sourceConfig` et `cacheConfig` (FR-035, SC-004) : sans
/// cela les 23 cas de `mefali_pro` appelleraient le vrai `SharedPreferences`
/// (canal de plateforme, FR-039) et le réseau réel — voir « Garanties ».
/// ⚠ Cette surcharge ne MORD que depuis la nouvelle signature de
/// `demarrerServiceConfig({required SourceConfig source, required CacheConfig
/// cache})` : tant qu'elle construisait elle-même sa source et son cache,
/// surcharger ces 2 providers ne changeait RIEN (R5, A1).
///
/// `sessionProvider` n'est PAS un paramètre : on ne le surcharge JAMAIS (R3).
ProviderContainer conteneurMefali({
  JetonsSession? jetons,      // → stockageJetonsProvider = StockageJetonsMemoire(jetons)
  TransportFake? transport,   // → posé sur `clientSession.dio.httpClientAdapter` APRÈS la pose
  SourceConfig? source,       // → sourceConfigProvider (défaut : double inerte)
  CacheConfig? cache,         // → cacheConfigProvider   (défaut : double en mémoire)
                              //   ⚠ le provider est `Raw<Future<CacheConfig>>` (A2 : le
                              //   constructeur réel est `CacheConfigPreferences(this._prefs)`
                              //   et les prefs s'obtiennent par un `await` — un provider
                              //   SYNCHRONE ne peut pas le construire). Le paramètre reste
                              //   un `CacheConfig` NU — c'est le harnais qui enveloppe :
                              //   `cacheConfigProvider.overrideWith((ref) => Future.value(cache))`.
                              //   L'appelant n'écrit jamais de `Future` à la main.
});

/// Monte l'app de test sous `UncontrolledProviderScope` — le conteneur PRÉEXISTE
/// toujours (cohérent avec l'amorçage impératif de R10), et c'est la seule forme
/// compatible avec le préchargement HORS arbre des 3 cas `runAsync`.
/// ⚠ `UncontrolledProviderScope` NE DISPOSE PAS le conteneur : c'est sa raison
/// d'être — la destruction reste au test (règle de fichier n°4).
Widget harnaisApp({
  required ProviderContainer container,
  required Widget home,
  Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates,
  Iterable<Locale>? supportedLocales,
});

/// SC-005 — compte les intercepteurs de l'application par TYPE, JAMAIS par
/// position : les 4 intercepteurs que le client généré installe d'office
/// (`api.dart:36-45`) sont des `Interceptor`, donc `whereType<Interceptor>()`
/// ne filtre RIEN et `.last` (`session_auth_test.dart:82-84`) est vert par
/// accident. Ce cycle supprime ce geste (FR-013).
int compteIntercepteursApp(Dio dio);   // → dio.interceptors.whereType<InterceptorAutorisation>().length
```

**Prérequis de production induit** : `_InterceptorAutorisation` (`session_auth.dart:84`) devient
**public** — `InterceptorAutorisation` —, sans quoi `compteIntercepteursApp` ne peut pas compter
par type et SC-005 retombe sur le `.last` que ce cycle supprime (R3).

## Les 3 contraintes DURES, vérifiées par exécution

Elles ne sont pas des préférences : chacune est un **échec de compilation ou d'analyse reproduit**,
et à elles trois elles DÉTERMINENT la forme du harnais — il n'en restait qu'une possible.

**1. AUCUNE signature de `lib/` ne mentionne `flutter_test`.** Une signature qui prend un
`WidgetTester` force `flutter_test` dans les `dependencies` de `mefali_core` — donc dans le graphe
de **production** des deux apps. Inacceptable (constitution II : le cœur reste propre).
→ **Conséquence de forme** : `pumpApp(tester, …)` est **REJETÉ**. Le harnais **rend** un `Widget`
(`harnaisApp`) et **rend** un `ProviderContainer` (`conteneurMefali`) ; c'est l'appelant, resté
dans `test/`, qui pompe et qui démonte. L'API est **descendante** — elle fabrique, elle ne pilote
pas.

**2. `ProviderContainer.test()` est `@visibleForTesting` → ILLÉGAL depuis `lib/`.** Vérifié :
appelé depuis `lib/` → `invalid_use_of_visible_for_testing_member` → **EXIT 3** → **SC-006 échoue**.
Appelé depuis `test/` → EXIT 0. C'est un diagnostic **cœur** de l'analyseur, hors de portée de
toute configuration de plugin : aucun réglage ne le tait (R11).
→ **Conséquence de forme** : `conteneurMefali` construit avec le constructeur **public**, et la
destruction que `.test()` aurait câblée automatiquement devient une **obligation de l'appelant** —
`addTearDown(container.dispose)` dans **chaque** cas (règle de fichier n°4). Bénéfice non
recherché mais décisif : c'est exactement ce que les 4 cas `fakeAsync` exigent — `.test()` diffère
son `dispose` au `tearDown`, **hors zone**, ce qui rend l'assertion « le timer est annulé à la
destruction » (FR-018/FR-019) **inexprimable** (R5).

**3. `Override` n'est PAS exporté par `flutter_riverpod 3.3.2`.** Vérifié : le `show` de 34
symboles ne l'expose pas — ni `package:riverpod/riverpod.dart`. `List<Override> f()` →
`non_type_as_type_argument`. L'**inférence** marche
(`ProviderContainer(overrides: [x.overrideWithValue(y)])` → EXIT 0), l'**annotation** non.
→ **Conséquence de forme** : le harnais **ne peut pas** être une fabrique d'overrides — pas de
`List<Override> surchargesParDefaut()`, pas de `List<Override> surchargesSession({…})`. L'API est
**centrée conteneur** : les overrides naissent et meurent à l'intérieur de `conteneurMefali`, où
l'inférence les tient. Ce n'est pas un contournement — c'est le seul contrat exprimable.

## Où vit le harnais — et le précédent `StockageJetonsMemoire`

**Décision : `apps/packages/mefali_core/lib/harnais.dart`**, bibliothèque séparée, hors barrel.

Un `test/harnais.dart` par paquet est **impossible sans 3 copies** : un paquet Dart ne peut pas
importer le `test/` d'un autre — **seul `lib/` est exposé sous `package:`**. La forme « propre »
violerait donc **SC-011 par construction** (« 0 copie dupliquée de double entre fichiers de
test »), et l'aurait violée au triple.

**Le précédent tranche, et il est déjà payé.** `StockageJetonsMemoire`
(`stockage_jetons.dart:84`) est **déjà** un double de test qui vit en production, **exporté** par
`mefali_core.dart:18`, avec son motif écrit dans le code (`:81-83` : « `flutter_secure_storage`
passe par un canal de plateforme, indisponible dans un test de widget : sans ce double, tout le
parcours d'auth serait intestable hors émulateur »). Le projet a consenti ce prix une fois, pour
la raison **exacte** qui se représente ici — et la doctrine FR-039 (« on double la fonction, pas
le canal ») en dépend.

Bibliothèque **séparée** plutôt qu'ajout au barrel : `import 'package:mefali_core/harnais.dart'`
est un **aveu lisible en revue** — un fichier de production qui l'importerait se verrait ; l'arbre
de production ne la référence jamais, donc le tree-shaking l'élimine.

**C'est exactement pourquoi `pasDeRetry` ne vit PAS ici** (R10, R11) : les 2 `main.dart` de
**production** doivent la poser sur leur portée. Déclarée dans `harnais.dart`, elle forcerait la
production à importer le harnais — l'arbre de production le référencerait, et les deux phrases
ci-dessus (« aveu lisible en revue », « le tree-shaking l'élimine ») deviendraient **fausses le
jour même**. Elle est donc **publique, dans une bibliothèque de production** de `mefali_core`, à
côté des providers et exportée par le barrel ; le harnais la **réutilise** comme n'importe quel
appelant. Le sens de la flèche est le contrat : le harnais dépend de la production, **jamais
l'inverse**.

**Nuance assumée et consignée** (constitution II, Complexity Tracking) : **la barrière est
conventionnelle, pas mécanique** — rien n'empêche mécaniquement un fichier de `lib/src/` d'importer
`harnais.dart`. C'est exactement le statut qu'a **déjà** `StockageJetonsMemoire`. Le dépôt écrit
cette divergence plutôt que de la taire.

## Garanties contractuelles

| Garantie | Détail |
|---|---|
| **Config surchargée PAR DÉFAUT** (FR-035, SC-004) — **repose sur un changement de signature de production, à nommer** | `conteneurMefali` surcharge `sourceConfig`/`cacheConfig` **même quand l'appelant ne demande rien**. **Cette garantie n'opère QUE depuis la nouvelle signature** `demarrerServiceConfig({required SourceConfig source, required CacheConfig cache})` : dans la forme d'origine (`{String? urlApi}`, `amorce_config.dart:14-22`), la fonction **construisait elle-même** `SourceConfigApi(MefaliApiClient(...))` et `CacheConfigPreferences(prefs)` après `await SharedPreferences.getInstance()` — un `serviceConfig` qui l'appelle avec `urlApi` ne consomme **NI** `sourceConfigProvider` **NI** `cacheConfigProvider`, donc **les surcharger ne changeait RIEN** : la garantie était **écrite et inopérante**, et **FR-035** (« source et cache DOIVENT devenir des surcharges de portée ») n'était pas tenu. C'est le risque n°5 du cycle, **déclaré fermé à tort** : `config` est **nullable** aujourd'hui et **tous les tests l'omettent** (`RouteurRoles(session: session)`, `routeur_roles_test.dart:99`) ⇒ `_lireTransports()` sort sans rien faire ; une fois `config` remplacée par un provider, **il n'y a plus de `null`**, et les **23 cas de `mefali_pro`** appelleraient le vrai `SharedPreferences.getInstance()` (**canal de plateforme**, FR-039) **+ le réseau réel**. **SC-004 se perdrait SANS QU'AUCUNE ASSERTION NE BRONCHE** — la protection `config: null` d'aujourd'hui **DISPARAÎT** avec le provider (R5). L'inversion d'injection (la fonction **reçoit** source et cache au lieu de les construire) est donc un **changement de production**, pas un détail de plomberie du harnais : c'est lui qui réalise FR-010/FR-035, et `urlApi` descend dans `clientConfigProvider`, que `sourceConfig` watch déjà. |
| **Retry neutralisé** (FR-002) | `pasDeRetry` — **constante de `mefali_core`, réutilisée par le harnais** (jamais déclarée par lui, voir « Où vit le harnais ») — posé sur **toute** portée créée par le harnais. Sans lui : jusqu'à 10 requêtes en backoff sur un provider en échec, **et les tests restent verts** (`ServiceConfig.rafraichir` avale ses erreurs, `service_config.dart:64`) pendant qu'adresses/rôles/appareils dérivent (R10). |
| **Ordre transport/intercepteur** (FR-036) | Tenu **par construction** : la pose de l'intercepteur est dans le `build` de `clientSessionProvider`, donc `container.read(clientSessionProvider).dio.httpClientAdapter = TransportFake(...)` est **ordonné après la pose**, sans aucune discipline à tenir (R3). |
| **Le sujet n'est jamais un mannequin** | On surcharge les **dépendances** (`stockageJetons`, `sourceConfig`, `cacheConfig`, `urlApi`) et le **transport** ; **JAMAIS** `sessionProvider`, `clientSessionProvider`, `etatRolesProvider`. Verrou `_enCours`, anti-boucle et rejeu unique testés sont ceux de **production** (R7). |
| **Aucun canal de plateforme simulé** (FR-039) | `StockageJetonsMemoire` remplace `flutter_secure_storage` ; le double de cache remplace `shared_preferences` ; `TransportFake` substitue l'**adaptateur** d'un `Dio` **réel**. Aucun `MethodChannel` mocké. |
| **Comptage par type** (SC-005) | `compteIntercepteursApp` compte `whereType<InterceptorAutorisation>()`. Les **4** intercepteurs du client généré (OAuth, Basic, Bearer, clé d'API) sont **hors décompte** (FR-013) : ils sont déjà là aujourd'hui et restent inertes faute de jeton. |
| **Rien n'est relâché** (FR-003, FR-004) | Le harnais ne fournit **aucun** helper d'assertion tolérante. `expect(emissions, 1)` est **égal strict**, jamais `greaterThanOrEqualTo` — FR-003 nomme ce relâchement comme un échec du cycle. |

**Contre-indication majeure, à citer en revue** : `clientSessionProvider.overrideWith((ref) =>
MefaliApiClient(dio: dioFactice))` — le geste que l'idiome invite — est **doublement destructeur**
: il perd l'**intercepteur** (le test ne prouve plus rien **tout en restant vert**) **et** les
délais 5000/3000 ms, qui ne vivent que dans la branche `dio ?? Dio(BaseOptions(...))`
(`clients/dart/lib/src/api.dart:30-35`). **On surcharge les dépendances, jamais le sujet.**

## Règles de fichier — ce qu'aucun outil ne tient

Aucune de ces six règles n'est vérifiée par un lint, un type ou un test : **aucun lint ne garde
l'opposition `keepAlive`/`autoDispose`** — `avoid_keep_alive_dependency_inside_auto_dispose`
**N'EXISTE PAS** (R2, R4). Elles sont écrites ici parce que c'est le seul endroit où elles peuvent
l'être.

1. **`retry: pasDeRetry` sur TOUTE création de portée** — les 2 points d'entrée **et** le harnais.
   C'est une **constante de `mefali_core`, réutilisée par le harnais** — **PAS un réglage par
   site** : un site oublié réintroduit 10 rejeux en backoff, et FR-002/SC-004 tombent **sans une
   ligne de code**, tests verts (R10). Elle est **publique** et vit dans une bibliothèque de
   **production** (exportée par le barrel), précisément pour que les 2 `main.dart` la posent
   **sans importer le harnais** : un `_pasDeRetry` privé redéclaré dans chaque `main.dart`
   **serait** le réglage par site que cette règle interdit (R11).
   ⚠ Le `retry: null` que le générateur écrit par défaut signifie **« hérite »**, pas
   « désactivé ».
2. **Tout cas unitaire sur `etatRolesProvider` OUVRE un abonnement** —
   `final sub = container.listen(etatRolesProvider, (_, __) {}); addTearDown(sub.close);`.
   `etatRolesProvider` est **autoDispose** (FR-020) : `container.read(…notifier)` n'attache
   **aucun** auditeur, la destruction est **planifiée**, et le notifier peut être **rejeté entre
   deux `charger()`** ⇒ `build()` rejoué ⇒ `actif` repart à `null` ⇒
   **`routeur_roles_test.dart:295-322` devient VERT SANS RIEN PROUVER** : le 2e chargement
   retombe sur vendeur **trivialement**. **C'est le pire résultat possible** — pire qu'un échec.
   Collision directe entre FR-020 (autoDispose) et FR-038 (conteneur explicite), et elle ne se
   voit **qu'ici** (R8).
3. **On ne surcharge JAMAIS `sessionProvider`** — y compris dans un `ProviderScope` imbriqué :
   deux notifiers sur le **même** dio = **2 intercepteurs** ⇒ 2 verrous ⇒ 2 renouvellements
   concurrents ⇒ jeton déjà tourné rejoué ⇒ vol présumé ⇒ **session révoquée** (mode de panne n°1,
   FR-013). **Aucune construction Riverpod ne l'empêche** : c'est une règle à écrire, pas un bug à
   corriger. Les surcharges vivent dans le conteneur **racine** du test (R3).
4. **`addTearDown(container.dispose)` dans CHAQUE cas** — `UncontrolledProviderScope` **NE DISPOSE
   PAS** le conteneur (c'est sa raison d'être) et le constructeur public de `ProviderContainer`
   n'a pas le câblage de `.test()` (contrainte 2). Conséquence à **écrire comme une règle**, pas à
   découvrir : sans elle, les timers fuient d'un cas à l'autre — la famille de bugs
   « timers pendants + autoDispose » est **toujours ouverte** en amont (R11).
5. **`--update-goldens` est INTERDIT pendant tout le cycle** — il transforme une régression FR-001
   en test vert. Les 2 goldens passent **sans régénération** (FR-005/SC-002), garanti
   structurellement : ils montent un `StatelessWidget` nu, hors de toute portée. Ils sont **hors
   CI** : à rejouer **à la main** avant fusion (R13).
6. **Un écran poussé HORS-CHAMP suspend ses listeners ⇒ `pumpAndSettle` peut FIGER.** Riverpod 3
   met en **pause** les abonnements d'un écran sorti du champ (`TickerMode`) : le provider n'est
   **pas détruit** (c'est l'argument de l'arête `.select`, R4), mais il **cesse de notifier**. Un
   `pumpAndSettle` qui attend une émission derrière une navigation **n'obtient jamais la main** —
   le test ne rougit pas, il **pend**. Amont : **« No way to disable this behavior globally »** —
   aucun réglage de portée, aucun paramètre de harnais ne le désarme. **Parade, à n'appliquer que
   si ça mord** : envelopper le sujet dans `TickerMode(enabled: true)`. **C'est un piège de
   portage, PAS une décision** : rien n'est à trancher, mais un fichier qui pend au premier
   `flutter test` se diagnostique en heures si la cause n'est écrite nulle part. Concerne les cas
   qui **naviguent** — `routeur_roles_test.dart` (#12) et `formulaire_dossier_test.dart` (#10) en
   premier.

## Plan de migration des 13 fichiers

⚠ **À AUDITER DÈS LA PREMIÈRE TÂCHE DU PORTAGE — `ProviderException` enveloppe les erreurs en
Riverpod 3.** Une erreur levée derrière un provider **ne ressort plus telle quelle** : elle est
**enveloppée**. Conséquence directe et mécanique : **tout `expect(..., throwsA(isA<DioException>()))`
sur un chemin qui traverse un provider CASSE** — l'exception attrapée est une `ProviderException`,
pas la `DioException` attendue. Ce n'est pas une hypothèse : c'est le même enveloppement que celui
déjà cité au défaut de retry (`if (error is ProviderException || error is Error) return null`).
**La spec ne nomme pas ce vecteur d'échec**, et il **rougira au premier `flutter test`** du portage
— avant toute autre difficulté de ce tableau. Donc : **auditer les 86 cas sur `throwsA` /
`isA<DioException>` dès la tâche T00x**, avant de migrer quoi que ce soit. Le geste correct est
`throwsA(isA<ProviderException>())` avec assertion sur la cause enveloppée, **jamais** un
`throwsA` relâché en `isA<Object>` — FR-003 nomme ce relâchement comme un échec du cycle.

86 cas, 13 fichiers — décompte **re-vérifié par exécution** (2+10+11+2+15+7+3+14+4+8+2+5+3 = **86**,
`spec.md:272`). Difficulté sur 5 ; le harnais est **piloté par le cas le plus dur** (US2,
`spec.md:48`).

| # | Fichier | Cas | Ce qui change | Diff. | Risque |
|---|---|---|---|---|---|
| 1 | `mefali_core/test/auth/contrat_oneof_test.dart` | 3 | **RIEN** — `standardSerializers` seuls (`:18`) ; aucun widget, aucune session, aucun dio. | 0 | nul |
| 2 | `mefali_core/test/mefali_theme_test.dart` | 3 | **RIEN** — `MefaliTheme.light`/`MefaliTokens` ; pas même un `pumpWidget`. | 0 | nul |
| 3 | `mefali_client/test/splash_golden_test.dart` | 2 (1 golden) | **RIEN** — `_app()` monte `const SplashScreen()` dans un `MaterialApp` nu. **Aucun `ProviderScope`, aucune session, `main.dart` hors arbre** (FR-005). | 0 | nul |
| 4 | `mefali_pro/test/splash_golden_test.dart` | 2 (1 golden) | **RIEN** — idem. | 0 | nul |
| 5 | `mefali_core/test/auth/ecrans_auth_test.dart` | 14 | **RIEN** — `_monter` ne prend que des widgets, des callbacks et des scalaires. Le compte à rebours 60 s (`:92-121`) et les `TextEditingController` sont l'état **local** que FR-009 gèle. | 0 | nul |
| 6 | `mefali_core/test/auth/otp_dev_test.dart` | 4 | Les 4 cas restent **LITTÉRALEMENT identiques** (`expect(modeDevOtp, isFalse)` inclus, FR-025). **Mais `_AdaptateurFige` (`:8`) est l'un des 6 transports de SC-011** → remplacé par `TransportFake`. Le `Dio` nu (`:38-40`) reste. ⇒ **`otp_dev_test.dart` n'est PAS intouché.** | 1 | nul |
| 7 | `mefali_core/test/auth/version_consentement_test.dart` | 2 | `_session()` + `_monter` → harnais ; `ParcoursAuth(session:)` → surcharges ; `versionConsentement:` **reste un paramètre** (FR-021). | 2 | faible |
| 8 | `mefali_core/test/adresses/adresses_test.dart` | 15 | **8 cas** (`ListeAdresses`, `:85-238`) migrent. **7 ne bougent PAS** : `FeuilleEnregistrerAdresse` (6, callbacks + scalaires) et `ConfigDistante.depuisJson` (décodage pur). `jouerNote:` reste un **callback** (FR-011). | 2 | faible |
| 9 | `mefali_core/test/config/service_config_test.dart` | 5 | Doubles → surcharges. **Conteneur créé, lu ET disposé DANS `fakeAsync`** : `Timer.periodic` capte `Zone.current` **à sa création** (`service_config.dart:51`) et le `build` d'un provider est **paresseux** — c'est le `container.read(...)` qui doit être dans la zone. `ProviderContainer` **nu**, pas `.test()` (contrainte 2). **Seul endroit du plan où `.test()` est déconseillé même depuis `test/`.** | 3 | **moyen** |
| 10 | `mefali_pro/test/roles/formulaire_dossier_test.dart` | 10 | 7 cas de formulaire : seul `session:` disparaît. 3 cas `EcranEtatDemande` : `runAsync` + préchargement hors arbre → `harnaisApp(container:)`. **`FormulaireDossierCoursier` reste `ConsumerStatefulWidget`** (FR-026) : le cas `:192-229` est **le garde-fou de R14** — s'il tombe, on n'a pas un test à réparer, **on a un périmètre violé**. | 4 | **moyen** |
| 11 | `mefali_core/test/appareils/ecran_appareils_test.dart` | 7 | 4 triviaux ; **3 cas de refresh 401** (`:166-238`) — les **seuls** à exercer l'intercepteur réel de bout en bout. On surcharge les **feuilles**, jamais `sessionProvider` (règle 3). ⚠ `:196-220` **n'appelle pas `charger()`** avant de pomper : il repose sur `RacineAuth.initState` (`racine_auth.dart:60`) — **le déclenchement doit rester là** (FR-002). | 4 | **élevé** |
| 12 | `mefali_pro/test/roles/routeur_roles_test.dart` | 11 | 7 widget ; 4 unitaires dont la **mémoire de `_actif`** (`:295-322`). **Tout cas unitaire ouvre un abonnement** (règle 2). | 4 | **élevé** |
| 13 | `mefali_core/test/auth/session_auth_test.dart` | 8 | **Le nœud.** Émissions (`:48-58`) → `container.listen` **sans `fireImmediately`** (⇔ `addListener`) + `expect(emissions, 1)` **égal strict** — exception nommée de FR-003. Intercepteur attrapé par `.last` (`:78-95`) → **une vraie requête part** et on lit `transport.recues` : plus aucune position, plus aucun `onRequest` manuel. `session.stockage` (`:60`, `:75`) → `container.read(stockageJetonsProvider)`. | **5** | **maximal** |

**Fichiers neufs** — `mefali_core/test/auth/session_intercepteur_test.dart` (`test()`, **pas**
`testWidgets()`) : FR-013/FR-018 (unicité de l'intercepteur, **déjà écrits et verts dans la sonde**)
+ FR-014 (N requêtes concurrentes → **1 seul** renouvellement, retenue par `Completer`).
**Décompte de sortie : 86 + 3 = 89**, conforme à « **≥ 86**, dont aucun des 86 n'a disparu »
(`spec.md:272`).

**Ordre d'exécution imposé par les dépendances** — le harnais (**#1**) puis
`session_auth_test.dart` + les 3 tests neufs (**#2**) : **rien ne migre avant**, et **s'il ne sert
pas ces 11 cas, il ne servira pas les autres**. Puis `ecran_appareils_test.dart` →
`adresses_test.dart` → `version_consentement_test.dart` → `service_config_test.dart` ;
puis `routeur_roles_test.dart` → `formulaire_dossier_test.dart` ; enfin `otp_dev_test.dart` (swap
du double, 1 ligne). Les **5 fichiers du lot facile (#1-#5) : on n'y touche PAS.**
