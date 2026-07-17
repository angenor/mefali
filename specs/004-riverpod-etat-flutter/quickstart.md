# Quickstart — Validation du cycle 004 (Riverpod codegen)

Guide de validation de bout en bout : une section par critère de succès
(SC-001 → SC-012). Références : [spec.md](spec.md) (les 43 FR et l'invariant
central), [research.md](research.md) R1–R13 (les décisions et leur preuve
d'exécution), [data-model.md](data-model.md) (la carte des 11 providers et
leurs durées de vie), [contracts/providers.md](contracts/providers.md),
[contracts/harnais-de-test.md](contracts/harnais-de-test.md),
[contracts/ci-apps.md](contracts/ci-apps.md). Ce cycle est un **REFACTOR PUR** :
tout ce qui suit prouve qu'il **ne s'est rien passé** côté utilisateur (FR-001).

## Prérequis

```bash
# 1. Flutter 3.44.6 / Dart 3.12.2 — épinglée en dur dans .github/workflows/apps.yml,
#    unique source de vérité (ni .fvmrc, ni gestionnaire de version) — R1
flutter --version

# 2. Dépendances — résolution INCRÉMENTALE, à partir des locks commités
for p in apps/packages/mefali_core apps/mefali_pro apps/mefali_client; do
  (cd "$p" && flutter pub get)
done
# ⚠ JAMAIS `rm pubspec.lock`, JAMAIS `flutter pub upgrade` : une résolution fraîche
#   fait dériver uuid 4.5.3 → 4.6.0 et CASSE l'accord des 3 locks (R1, SC-008).

# 3. Génération — mefali_core et mefali_pro SEULS : mefali_client n'a ni
#    riverpod_annotation ni build_runner (auto_apply: dependents — R2)
(cd apps/packages/mefali_core && dart run build_runner build)
(cd apps/mefali_pro && dart run build_runner build)
# ⚠ `--delete-conflicting-outputs` a été SUPPRIMÉ de build_runner 2.15.x : la
#   commande est nue (R1). build_runner est plafonné à ^2.15.1 (R1, écart X).

# 4. Analyse — `dart analyze`, JAMAIS `flutter analyze` (R2, R12)
for p in apps/packages/mefali_core apps/mefali_pro apps/mefali_client; do
  (cd "$p" && dart analyze)
done

# 5. Tests
for p in apps/packages/mefali_core apps/mefali_pro apps/mefali_client; do
  (cd "$p" && flutter test)
done
```

⚠ **`flutter analyze` NE CHARGE PAS les plugins de l'analysis server** : sur la
même faute, `dart analyze` sort en EXIT 2 et `flutter analyze` en EXIT 0
« No issues found! » (vérifié par exécution le 2026-07-17 — R2). La doc
officielle `using_plugins.md` prétend le contraire : **elle est fausse sur
Flutter 3.44.6**. Toute validation d'analyse de ce quickstart passe par
`dart analyze`, sinon riverpod_lint est un **no-op décoratif**.

Pour les scénarios sur émulateur (SC-003, SC-004, SC-009, SC-010), l'API doit
tourner et être joignable **par l'appareil**, avec l'IP LAN du poste (CLAUDE.md
§Commandes) :

```bash
docker compose -f infra/docker-compose.yml up -d
export DATABASE_URL='postgres://mefali:mefali@localhost:5433/mefali'   # port 5433 en dev local
export SMS_MODE=traces APP_ENV=dev
export S3_ENDPOINT="http://$(ipconfig getifaddr en0):3900"   # MÊME IP que l'appareil joint
(cd backend && cargo run -p api --bin api)                   # backend INTOUCHÉ ce cycle (FR-006)

flutter run --dart-define=MEFALI_API_URL="http://$(ipconfig getifaddr en0):8080" \
            --dart-define=MEFALI_DEV_OTP=true
```

⚠ Le défaut `localhost` désigne **l'appareil lui-même**, pas le poste. Le
provider `urlApi` **`throw`** au premier `read` si le point d'entrée ne le
surcharge pas (R3, FR-012) : un oubli d'override échoue au lancement, avec le
message qui dit quoi faire — il ne part **jamais** silencieusement sur localhost.

## SC-001 — 0 notificateur, 0 observateur, 0 notification manuelle

Les décomptes passent de **2, 2 et 6** à zéro (FR-008). On compte les
**implémentations**, pas les mentions :

```bash
grep -rn 'extends ChangeNotifier' apps --include='*.dart'   # 2 → 0
grep -rn 'ListenableBuilder('     apps --include='*.dart'   # 2 → 0
grep -rn 'notifyListeners()'      apps --include='*.dart'   # 6 → 0
```

**Attendu** : trois commandes sans aucune ligne (`grep` sort en 1). Avant
migration : `session_auth.dart:15` + `etat_roles.dart:100` ; `racine_auth.dart:82`
+ `routeur_roles.dart:79` ; `etat_roles.dart:158,193,203` +
`session_auth.dart:46,53,65`.

⚠ **`grep -rn 'addListener' apps` donne 2 hits, et l'un DOIT rester** :
`ecran_otp.dart:67` (`_controleur.addListener`) est de l'**état strictement
local** que FR-009 gèle. SC-001 compte les `ListenableBuilder`, **pas** les
listeners de contrôleurs — exiger 0 ici serait exiger une régression de FR-009.
Le second hit (`session_auth_test.dart:51`) migre vers
`container.listen(sessionProvider, …)` (FR-003, R11).

Le commentaire normatif de `etat_roles.dart:98-99` (« Convention de l'app :
`ChangeNotifier` nu (ni Provider ni Riverpod) ») énonce désormais la nouvelle
convention (FR-042) ; `racine_auth.dart:91` en fait autant.

```bash
grep -rn 'custom_lint' apps/                  # 0 — ÉCARTÉ, doit le rester (R2)
grep -rn 'RouteurRoles(\s*etat:' apps/        # 0 — couche d'injection SUPPRIMÉE (FR-043)
grep -rn '\.client\b' apps/mefali_pro/lib apps/packages/mefali_core/lib | grep -i session
                                              # 0 — SessionAuth.client n'existe plus (R3)
```

## SC-002 — 100 % des 86 cas verts, 0 test affaibli, 2 goldens à l'identique

```bash
(cd apps/packages/mefali_core && flutter test)   # 61 → 64 cas (les 3 neufs de SC-005)
(cd apps/mefali_pro          && flutter test)    # 23 cas (dont 1 golden)
(cd apps/mefali_client       && flutter test)    # 2 cas  (dont 1 golden)
```

**Attendu** : **≥ 89** cas verts, **0** supprimé, **0** `skip`, **0** assertion
relâchée. Le décompte de sortie de la spec est « **≥ 89**, dont aucun des 86 n'a
disparu » ([spec.md](spec.md) Assumptions) — plancher : les ajouts sont les cas
de SC-005 (`session_intercepteur_test`, FR-013/FR-018 et FR-014) **et** le
cas-garde d'`updateShouldNotify` verrouillé au portage de `session_auth_test`
(voir plus bas) ; le nombre exact dépend du découpage cas/assertions.

Les **2 goldens sont HORS CI** (`flutter test --exclude-tags golden`,
`apps.yml`) : ils se rejouent **à la main**, avant fusion, **sans jamais**
`--update-goldens` (FR-005) :

```bash
(cd apps/mefali_pro    && flutter test --tags golden)
(cd apps/mefali_client && flutter test --tags golden)
```

**Attendu** : verts, **0 diff**, **aucune image de référence réécrite**
(`git status --porcelain apps/*/test/` vide). FR-005 est tenu mécaniquement :
les deux goldens montent `const SplashScreen()` — un `StatelessWidget` — dans un
`MaterialApp` nu, hors de toute portée de providers (R13). **Seul chemin de
casse** : convertir `SplashScreen` en `ConsumerWidget` — rien ne l'exige, il ne
lit aucun état (FR-009).

Contrôle du non-affaiblissement, cas par cas — l'**exception nommée de FR-003**
(`session_auth_test.dart:48-58`) :

```bash
grep -rn 'expect(emissions' apps/packages/mefali_core/test/auth/session_auth_test.dart
```

**Attendu** : `expect(emissions, 1)` — **égalité stricte**, jamais
`greaterThanOrEqualTo` (FR-003 le nomme, FR-004 l'interdit). Et le cas
additionnel qui verrouille l'invariant : deux `ouvrir()` à jetons **identiques**
⇒ `expect(emissions, 2)` — c'est lui qui rougit si quelqu'un retire
`updateShouldNotify => true` (R6).

## SC-003 — 0 changement observable sur le parcours complet

Sur émulateur Android (iOS reste non vérifié — hors périmètre), dérouler le
parcours du cycle 003 : **inscription (OTP) → rôles → dossier coursier →
adresses**.

```bash
(cd apps/mefali_pro && flutter run \
  --dart-define=MEFALI_API_URL="http://$(ipconfig getifaddr en0):8080" \
  --dart-define=MEFALI_DEV_OTP=true)
```

**Attendu**, écran par écran, indiscernable d'avant migration (FR-001) : écran
de démarrage identique et **jamais réapparu** en plein parcours (FR-022) ; case
de consentement **jamais** pré-cochée ; renvoi verrouillé **60 s** puis compte à
rebours relancé et saisie vidée ; inscription **refusée** si la version de
consentement de la zone est absente ; squelette de chargement **qui réapparaît**
après un renommage, une suppression ou une révocation (FR-023, R9) ; écran
`ChargementPro` **qui réapparaît** à chaque rechargement des rôles (FR-022) ;
mêmes messages d'erreur.

**Attendu (US1, scénario 6)** : au lancement, l'arbre est enveloppé dans un
`UncontrolledProviderScope` porté par un `ProviderContainer` construit **avant**
`runApp` (R10) — et le démarrage est **inchangé** : même écran, mêmes appels,
même ordre (voir SC-004).

> **Note d'honnêteté sur l'acceptance 6 (armée en implémentation).** US1 (T008,
> T009) ne pose **AUCUN** `ProviderScope` jetable : elle arme et prouve
> l'outillage, rien de plus. L'enveloppement de l'arbre est réalisé
> **incrémentalement** — `mefali_pro` en US2 (T011), `mefali_client` en US5
> (T026) —, si bien que l'acceptance 6 se vérifie **à partir d'US2**, pas dès US1.
> Manifestation concrète et VÉRIFIÉE pendant l'outillage : une fois
> `flutter_riverpod` dépendance directe (T001) et le plugin actif (T003),
> `dart analyze` signale `missing_provider_scope` sur `mefali_pro/lib/main.dart`
> et `mefali_client/lib/main.dart` — c'est le plugin qui fait correctement son
> travail (ces `runApp` n'ont pas encore de portée), **pas** un faux positif à
> masquer (FR-032). Le warning **disparaît** quand T011/T026 posent le
> `UncontrolledProviderScope`. `mefali_core` (sans `runApp`) est vert dès US1.
> Le mécanisme `diagnostics: error` a été prouvé par exécution (Dart 3.12.2) :
> `avoid_public_notifier_properties` → **error, EXIT 3** ; et le déterminisme du
> `.g.dart` (deux builds → 0 sortie, 0 diff). Les deux volets de l'Independent
> Test ci-dessous (§SC-006, §SC-007) sont donc opposables aujourd'hui.

## SC-004 — 0 requête ajoutée, supprimée ou déplacée

Le fil réseau est l'invariant le moins tolérant du cycle (FR-002 : « aucune
ajoutée, aucune supprimée, aucune déplacée avant ou après le premier rendu »).
On le compare **avant/après** sur le même parcours, depuis les logs JSON
corrélés de l'API (cycle 001, observabilité) :

```bash
# Sur main (avant migration), puis sur 004-riverpod-etat-flutter (après) :
cargo run -p api --bin api 2>&1 | tee /tmp/fil-<avant|apres>.log
# … dérouler EXACTEMENT le parcours SC-003 sur l'émulateur …
grep -o '"method":"[A-Z]*","path":"[^"]*"' /tmp/fil-avant.log > /tmp/fil-avant.txt
grep -o '"method":"[A-Z]*","path":"[^"]*"' /tmp/fil-apres.log > /tmp/fil-apres.txt
diff /tmp/fil-avant.txt /tmp/fil-apres.txt
```

**Attendu** : `diff` **vide** — même séquence, même ordre, même cardinalité. En
particulier : `GET /config` part **une fois au lancement**, depuis le point
d'entrée, **non attendu** (FR-024, R10) — et **jamais** à l'entrée de l'étape de
consentement ni du formulaire de dossier, ce qui serait un **déplacement de
requête** au sens de FR-002 (edge case spec). L'en-tête `Authorization` est
présent sur les requêtes de session et **absent de `GET /config`** (FR-017,
FR-013).

⚠ **Les deux pièges qui violent FR-002 sans une seule ligne de code**, tous deux
vérifiés par exécution (R10, R4) :
1. **Riverpod 3 réessaie les providers en échec PAR DÉFAUT** — 10 essais,
   backoff 200 ms → 6,4 s, et `if (error is ProviderException || error is Error)
   return null` ⇒ **toutes les `Exception` sont réessayées, `DioException`
   compris**. Aucune requête n'était rejouée avant ce cycle. Parade :
   `retry: pasDeRetry` sur **TOUTE** création de portée — 2 points d'entrée +
   le harnais. `pasDeRetry` est une constante **de `mefali_core`**, publique,
   déclarée dans une bibliothèque de **production** (à côté des providers,
   exportée par le barrel) et **réutilisée par le harnais** : privée, chaque
   `main.dart` la redéclarerait — soit « un réglage par site », ce que les règles
   interdisent ; portée par le harnais, la production devrait l'importer, ce qui
   ruinerait le tree-shaking. Contrôle : `grep -rn 'retry:' apps/*/lib/main.dart
   apps/packages/mefali_core/lib/harnais.dart` → **3 hits**. ⚠ Le `retry: null`
   que le générateur écrit signifie **« hérite »**, pas « désactivé ».
2. **`ref.watch(sessionProvider)` nu dans les rôles** (au lieu de
   `.select((e) => e.connecte)`) ⇒ rechargement des rôles à **chaque rotation de
   jeton** ⇒ requête ajoutée + `ChargementPro` en plein parcours, sur un chemin
   que seul un 401 déclenche — **donc jamais en test** (R4). Contrôle :
   `grep -n 'sessionProvider.select' apps/mefali_pro/lib/roles/etat_roles.dart`
   → 1 hit ; le test « rotation ⇒ 0 rechargement » le couvre.

## SC-005 — Exactement 1 intercepteur, exactement 1 renouvellement

Les deux invariants les plus dangereux du cycle, **aujourd'hui couverts par
aucun test** : ce cycle les couvre (FR-013, FR-014).

```bash
(cd apps/packages/mefali_core && flutter test test/auth/session_intercepteur_test.dart)
```

**Attendu** — fichier neuf, `test()` et non `testWidgets()`, **3 cas verts** :

- **FR-013 / FR-018 — unicité** : `compteIntercepteursApp(client.dio) == 1`
  après la première évaluation, après `invalidate(sessionProvider)`, après
  `fermer()/ouvrir()/ouvrir()`, après `invalidate(clientSessionProvider)` ;
  **0** sur `clientConfig` (FR-017) ; **0** après `container.dispose()`
  (FR-018). Comptage **par TYPE** (`whereType<InterceptorAutorisation>()`),
  **JAMAIS par position** — le `.last` de `session_auth_test.dart:82-84` était
  vert par trois accidents cumulés, ce cycle le supprime (R3, R11). Les **4
  intercepteurs** que le client généré installe d'office (OAuth, Basic, Bearer,
  clé d'API) sont **hors décompte** (FR-013).
- **FR-014 — partage du renouvellement** : N requêtes concurrentes toutes
  refusées en 401 ⇒ `expect(renouvellements, 1)`, puis `expect(rejeux, N)` et
  `expect(jetons.acces, 'jwt-neuf')`. **La retenue EST le test** : le faux
  `/auth/rafraichir` attend un `Completer` ouvert — sans elle, le 1er
  renouvellement aboutirait avant que la 2ᵉ requête n'échoue et **le test
  serait VERT même si le verrou `_enCours` était supprimé** (R7, R11). Motif à
  écrire dans le `reason` : la rotation R2 (cycle 003) tourne le jeton ⇒ un 2ᵉ
  renouvellement rejouerait un jeton **mort** ⇒ vol présumé ⇒ **session
  révoquée**.

Les 3 cas de refresh 401 existants (`ecran_appareils_test.dart:166-238`) restent
verts : on surcharge les **feuilles** (`stockageJetons`, le transport), **jamais
`sessionProvider`** — le remplacer par un mannequin ne prouverait plus rien tout
en restant vert (R11).

## SC-006 — Analyse statique verte sur les 3 paquets, erreurs de provider en ÉCHEC

```bash
for p in apps/packages/mefali_core apps/mefali_pro apps/mefali_client; do
  (cd "$p" && dart analyze) || echo "ÉCHEC: $p"
done
```

**Attendu** : **pass** sur les 3 paquets — `dart analyze` sort en **0**, aucun
avertissement, aucune erreur ; **0** règle existante désactivée par confort
(FR-032) : `exclude: *.g.dart` est **INTERDIT** (le `.g.dart` s'auto-neutralise
par `// ignore_for_file: type=lint, type=warning` en tête, et l'exclure
supprimerait la seule vérification qu'il compile sous `strict-casts` +
`strict-raw-types` — R2).

⚠ **Le critère se formule en pass/fail, JAMAIS en nombre de diagnostics** :
plugin actif, les diagnostics **cœur** sont **dupliqués** (2 issues → 4 ;
reproduit, cause inconnue, aucune issue upstream — R2). Sans effet sur SC-006
(2 × 0 = 0), mais tout comptage littéral serait faux.

**Independent Test d'US1 — le garde-fou du mécanisme `diagnostics: error`**
([spec.md](spec.md) US1). `diagnostics: <règle>: error` est **UNDOCUMENTÉ** : la
doc ne montre que `true`/`false`. Il fonctionne sur Dart 3.12.2 — mais si un SDK
futur le retire, les **3 règles INFO** (`avoid_public_notifier_properties`,
`avoid_build_context_in_providers`, `protected_notifier_properties`) retombent
en info **en silence**, `dart analyze` sort en **0**, et FR-033 cesse d'être
tenu sans que rien ne rougisse (R2). **Ce test est le seul garde-fou — il se
rejoue à chaque montée de SDK** :

```bash
# Faute VOLONTAIRE : exposer une propriété publique sur un Notifier
cd apps/packages/mefali_core
printf '\n  String? get acces => state.acces;  // FAUTE VOLONTAIRE\n' \
  >> lib/src/auth/session.dart   # à retirer juste après
dart analyze ; echo "EXIT=$?"
git checkout -- lib/src/auth/session.dart
```

**Attendu** : `avoid_public_notifier_properties` signalée en **error**, `EXIT=3`.
Un `EXIT=0` signifie que le plugin ne tourne pas (`flutter analyze` déguisé, ou
bloc `plugins:` placé **sous `analyzer:`** — système legacy, ignoré) ; un
`EXIT=2` signifie que l'escalade `diagnostics:` ne mord plus — repli documenté :
`dart analyze --fatal-infos` (R2).

Contrôle du câblage lui-même :

```bash
grep -rn -A2 '^plugins:' apps/*/analysis_options.yaml apps/packages/*/analysis_options.yaml
grep -rn 'flutter analyze' .github/workflows/apps.yml   # 0 — bascule vers dart analyze
```

**Attendu** : `plugins:` **top-level** (jamais sous `analyzer:`) dans les **3**
paquets, `riverpod_lint: version: 3.1.4` — version **exacte**, sans caret ; et
**0** occurrence de `flutter analyze` en CI (R12). Laisser cette ligne =
riverpod_lint no-op silencieux, US1 réputée livrée, **rien de vérifié**.

## SC-007 — Génération déterministe, 0 dérive commitée

```bash
(cd apps/packages/mefali_core && dart run build_runner build && dart run build_runner build)
(cd apps/mefali_pro          && dart run build_runner build && dart run build_runner build)
git status --porcelain apps/
```

**Attendu** : `git status --porcelain apps/` **vide** (FR-030) ; **100 %** des
`.g.dart` commités (FR-029) — vérifié : aucun motif de `.gitignore` ne les
attrape, `FR-029 fonctionne sans rien toucher` (R2).

```bash
git ls-files 'apps/**/*.g.dart' | wc -l   # > 0 : le code GÉNÉRÉ est versionné
```

**Independent Test d'US1 (second volet) — la CI échoue sur la dérive.**
Modifier un fichier **annoté** sans régénérer :

```bash
# Ajouter un provider (ou changer keepAlive) sans lancer build_runner, committer, pousser.
# Localement, reproduire le job (contracts/ci-apps.md) :
cd apps/packages/mefali_core
flutter pub get && dart run build_runner build && git diff --exit-code -- .
```

**Attendu** : `git diff --exit-code` **échoue** (exit 1) et **nomme le
coupable** — le contrôle est scopé au répertoire du paquet (`-- .`), pas à
`apps/` (R12). Modèle : le garde-fou `contrat-clients` existant, qui ne couvre
**pas** `apps/` (FR-031). Ordre imposé par FR-034 : `pub get` → **régénération**
→ **contrôle de dérive** → `dart analyze` → tests — analyser du code
désynchronisé produirait des diagnostics trompeurs.

La portée **étendue au paquet** (option B, R12) couvre aussi les traductions de
`mefali_core` — commitées et gardées par rien avant ce cycle — et
`pubspec.lock`. Risque mesuré **nul** : après `flutter pub get` sur les 3
paquets, `git status --porcelain apps/ clients/` est **vide** ⇒ aucune dérive
l10n préexistante ⇒ **l'exception nommée de FR-027 n'a pas à être invoquée**.

## SC-008 — 3 lockfiles accordés, 0 désaccord

```bash
./scripts/verifier-accord-locks.sh
```

**Attendu** : **0 désaccord**. Le script compare (a) les versions des paquets
**communs aux 3 `pubspec.lock`** — l'accord existe **déjà** : 0 désaccord sur
111/112/112 paquets, il n'est pas à créer, **il est à ne pas casser** (R1) — et
(b) le pin `riverpod_lint: 3.1.4` **répété à l'identique dans les 3
`analysis_options.yaml`**.

```bash
grep -h 'riverpod\|analyzer\|build_runner' apps/*/pubspec.lock \
  apps/packages/*/pubspec.lock | grep -A1 version | sort -u
grep -c riverpod_lint apps/packages/mefali_core/pubspec.lock   # → 0, et c'est NORMAL
```

**Attendu** : `riverpod: 3.3.2` dans les **3** locks (la numérotation
`riverpod_annotation` 4.0.3 / `riverpod_generator` 4.0.4 ≠ 3.x est **normale**,
SC-008 se vérifie sur `riverpod` — R1) ; `build_runner ^2.15.1` et **pas 2.15.2**
(plafond **dur** : 2.15.2 exige `analyzer >=13.3.0` contre `^12.0.0` pour
`riverpod_generator` ⇒ *version solving failed*).

⚠ **Limite honnête de SC-008, écrite plutôt que tue** : `riverpod_lint` n'est
**dans AUCUN lockfile** (`grep -c` → 0) — l'analysis server le résout **hors
`pubspec.lock`**, par un paquet synthétique. « Figée par lockfile » y est
**mécaniquement inatteignable** : le gel est le pin exact ×3, vérifié par le
script, pas par pub. Les 3 écarts au principe X (prérelease
`riverpod_analyzer_utils 1.0.0-dev.10` imposée transitivement, plafond
`build_runner`, `riverpod_lint` hors lockfile) sont **nommés et justifiés** au
Complexity Tracking de [plan.md](plan.md), pas contournés (R1).

## SC-009 — 0 rebuild d'écran sur un rafraîchissement de configuration

FR-021 : le rafraîchissement horaire **NE DOIT JAMAIS** atteindre l'interface —
la version de consentement et la liste des transports restent celles lues **à
l'entrée de l'écran** (clarification du 2026-07-17). Rendre la configuration
vivante serait une **amélioration**, donc une **violation de l'invariant
central**.

```bash
(cd apps/packages/mefali_core && flutter test test/config/service_config_test.dart)
```

**Attendu** : 5 cas verts — timer à 0 h, 1 h, **2 h sans aucun auditeur** (le
service est `keepAlive`, il ne s'arrête ni ne redémarre — FR-019), version
identique ⇒ **aucune écriture** de cache, version nouvelle ⇒ valeur **et** cache
remplacés, démarrage hors ligne servi par le cache. ⚠ Le conteneur est créé,
**lu** ET disposé **DANS** la zone `fakeAsync` : `Timer.periodic` capte
`Zone.current` **à sa création** et le `build` d'un provider est **paresseux** —
c'est le `container.read(...)` qui doit être dans la zone, sinon `async.elapse`
ne déclenche rien (R5, R11).

Sur émulateur, **le seul contrôle qui vaille** — les deux lectures d'instantané
(`racine_auth.dart:70-77`, `routeur_roles.dart:58-67`) sont **les seules
méthodes que la migration réécrit sans qu'aucun des 86 cas ne les couvre**
([spec.md](spec.md) Assumptions ; écart VII au Complexity Tracking) :

```bash
(cd apps/mefali_pro && flutter run --dart-define=MEFALI_API_URL="http://$(ipconfig getifaddr en0):8080")
# Laisser l'app OUVERTE sur l'étape de consentement, puis sur le formulaire de
# dossier, > 1 h (au-delà d'un cycle de rafraîchissement). En parallèle, changer
# la config de zone en base (cf. 002/quickstart §3) pour que le rafraîchissement
# rapporte une version DIFFÉRENTE.
```

**Attendu** : **0** rebuild — rien ne bouge à l'écran, la version de consentement
affichée reste celle lue à l'entrée, la liste des véhicules du formulaire ne
change **pas** sous les doigts. Garantie **structurelle** et non disciplinaire :
`Provider<Raw<Future<ServiceConfig>>>` n'a **AUCUN `AsyncValue` à émettre** —
FR-021 devient impossible à violer sans changer le **type**, geste visible en
revue (R5). Contrôle statique :

```bash
grep -rn 'serviceConfigProvider' apps/ --include='*.dart' | grep -v '\.g\.dart' | grep 'watch'
```

**Attendu** : **aucune ligne** — `ref.read`, **JAMAIS** `ref.watch` (R5).

## SC-010 — 0 donnée d'un compte visible sous un autre

```bash
(cd apps/mefali_pro && flutter test test/roles/routeur_roles_test.dart)
```

**Attendu** : 11 cas verts, dont la **mémoire de `_actif`** (`:295-322` : deux
`charger()` sur la **même** instance ⇒ `actif: coursier` puis `actif: vendeur`).
⚠ **Le piège qui rend ce test VERT SANS RIEN PROUVER** : `etatRolesProvider` est
**autoDispose** ; `container.read(…notifier)` **n'attache aucun auditeur**, le
notifier peut être **rejeté entre les deux `charger()`** ⇒ `build()` rejoué ⇒
`actif` repart à `null` ⇒ le 2ᵉ chargement retombe sur vendeur **trivialement**
(R8, R11). **Règle du fichier : tout cas unitaire sur `etatRolesProvider` ouvre
un abonnement** — `final sub = container.listen(etatRolesProvider, (_, __) {});
addTearDown(sub.close);`.

Sur émulateur — le contrôle de **sécurité**, pas de performance (FR-020) :

```bash
(cd apps/mefali_pro && flutter run --dart-define=MEFALI_API_URL="http://$(ipconfig getifaddr en0):8080" \
                                   --dart-define=MEFALI_DEV_OTP=true)
# Compte A (coursier validé) → se connecter, charger les rôles, basculer.
# Se déconnecter. Compte B (vendeur seul) → se connecter.
```

**Attendu** : **aucun rôle du compte A visible**, à aucun instant, **même
fugitivement**. Le mécanisme est une **arête gravée dans le graphe** :
`ref.watch(sessionProvider.select((e) => e.connecte))` dans `build()` ⇒ session
fermée ⇒ provider invalidé ⇒ `build()` rejoué ⇒ **état vide AVANT tout rendu**,
même si un futur cycle y met `keepAlive: true` (R4).

⚠ **AUCUN lint ne garde l'opposition keepAlive / autoDispose** — l'invariant
central du cycle. `only_use_keep_alive_inside_keep_alive` porte sur
`KeepAliveLink`, pas sur le sens des dépendances, et
`avoid_keep_alive_dependency_inside_auto_dispose` **N'EXISTE PAS** (R2, R4). Les
deux réglages opposés ne tiennent que par les tests et la revue. Contrôle :

```bash
grep -rn '@Riverpod(keepAlive: true)' apps/ --include='*.dart' | grep -v '\.g\.dart' | wc -l   # 8
grep -rn '^@riverpod$' apps/ --include='*.dart' | grep -v '\.g\.dart' | wc -l                  # 3
```

**Attendu** : **8** `keepAlive` (`urlApi`, `clientSession`, `clientConfig`,
`stockageJetons`, `session`, `sourceConfig`, `cacheConfig`, `serviceConfig` —
FR-019) et **3** nus
(`etatRoles`, `mesAdresses`, `mesSessions` — FR-020, FR-023). ⚠ **`@riverpod` nu
= autoDispose** : c'est le **défaut du générateur** et le **mode de panne n°2**
de la spec — un `@riverpod` nu sur la session ou la config détruirait l'objet
dès le dernier auditeur parti (R4).

`sourceConfig` et `cacheConfig` comptent bien parmi les **8** : ce sont les
dépendances d'un service `keepAlive` (`serviceConfig` les reçoit par injection —
[contracts/providers.md](contracts/providers.md)), et en autoDispose elles
seraient **reconstruites sous lui**. Le grep ci-dessus renvoie donc **8** sur du
code correct : c'est le **seul contrôle chiffré de SC-010**, un attendu à 6 le
ferait rougir sur une implémentation juste — le compte est 8 (R4).

## SC-011 — 0 double injecté par constructeur, 0 copie dupliquée

```bash
grep -rn 'implements HttpClientAdapter' apps/*/test apps/packages/*/test   # 6 → 0
grep -rn 'SessionAuth('                 apps/*/test apps/packages/*/test   # 6 → 0
grep -rn 'class TransportFake'          apps/packages/mefali_core/lib/harnais.dart   # 1
```

**Attendu** : les **6** copies de transport (`_Transport` ×5 +
`_AdaptateurFige`, `otp_dev_test.dart:8` — le compte de SC-011 est le bon, celui
de 5 était faux) et les **6** montages de session sont remplacés par le harnais
partagé unique `package:mefali_core/harnais.dart` (FR-037), **bibliothèque
séparée**, **jamais** ajoutée au barrel `mefali_core.dart` — précédent assumé :
`StockageJetonsMemoire` (`stockage_jetons.dart:84`) est **déjà** un double de
test vivant en production (R11). La barrière est **conventionnelle, pas
mécanique** — consigné, comme le précédent.

Les doubles injectés par constructeur deviennent des **surcharges de portée**
(FR-035) : `stockageJetons`, `sourceConfig`, `cacheConfig`. Ces deux dernières ne
mordent que parce que `demarrerServiceConfig` **reçoit** désormais `source` et
`cache` au lieu de les construire (inversion d'injection — voir Pièges) ; sans ce
changement de signature, la surcharge serait **inerte**. On surcharge **les
dépendances, JAMAIS le sujet** :

```bash
grep -rn 'sessionProvider.overrideWith\|clientSessionProvider.overrideWith' apps/   # 0
```

**Attendu** : **0**. `clientSessionProvider.overrideWith((ref) =>
MefaliApiClient(dio: dioFactice))` — le geste que l'idiome invite — est
**doublement destructeur** : il perd l'intercepteur (le test ne prouve plus rien
**tout en restant vert**) **et** les délais d'attente 5000/3000 ms (R3, R11).
FR-036 est tenu **par construction** : la pose de l'intercepteur est dans le
`build` de `clientSessionProvider`, donc
`container.read(clientSessionProvider).dio.httpClientAdapter = TransportFake(…)`
est **ordonné après** la pose, sans discipline à tenir.

## SC-012 — La constitution nomme le pattern

```bash
grep -n 'Riverpod\|Notifier\|ProviderScope' .specify/memory/constitution.md
grep -n '\*\*Version\*\*' .specify/memory/constitution.md      # 1.0.1 → 1.1.0
grep -n 'Riverpod' CLAUDE.md
grep -n 'TRX-08' docs/user-stories-v2.md
```

**Attendu** : un principe **nommé et opposable**, citable en revue, qui tranche
sans discussion — provider **GÉNÉRÉ** par annotation, injection par la
**portée**, état local réservé à ce qui ne sort pas du widget (FR-040) — et qui
nomme **les DEUX moules** : `Notifier<Etat…>` pour les porteurs à sémantique
propre (session, rôles), `AsyncNotifier` pour les chargements de liste (adresses,
appareils) — **sinon le prochain cycle uniformisera derrière `AsyncValue` et
détruira les deux sémantiques d'un coup** (R13). Version **1.1.0** (ajout de
principe ⇒ incrément **mineur**), passée par `/speckit.constitution` avec rapport
d'impact et propagation aux templates — éditer la constitution hors de cette
procédure est interdit par la gouvernance. `CLAUDE.md` énonce la **même** règle
et ne la contredit pas (FR-041). TRX-08 (P1) figure toujours dans
`docs/user-stories-v2.md` avec ses critères, tableau §0.6 à jour — **prérequis
du cycle, pas son livrable** ; US6 n'en contrôle que la non-régression.

## Pièges — les gestes qui rendent un test vert en prouvant moins

Chacun est un mode de panne **silencieux** : rien ne rougit, et le cycle est
perdu.

- **`flutter analyze`** au lieu de `dart analyze` : EXIT 0 sur une faute que
  `dart analyze` sanctionne. riverpod_lint devient décoratif, FR-033/SC-006 sont
  **réputés** tenus (R2, R12).
- **`--update-goldens`** : transforme une régression FR-001 en test vert.
  **INTERDIT pendant tout le cycle** ; les 2 goldens se rejouent à la main
  (FR-005).
- **`container.read` sur un autoDispose sans abonnement** : le notifier meurt
  entre deux appels, `routeur_roles_test.dart:295-322` devient vert **sans rien
  prouver** — le pire résultat possible (R8).
- **Surcharger `sessionProvider` ou `clientSessionProvider`** : on remplace le
  sujet par un mannequin. On surcharge les **feuilles** (R11). Corollaire : les
  surcharges vivent dans le conteneur **racine** du test — un `ProviderScope`
  imbriqué qui surcharge `sessionProvider` donne **2 intercepteurs** sur le même
  dio, et **aucune construction Riverpod ne l'empêche**.
- **`TransportFake.repondre` rendant un `ResponseBody` au lieu d'un
  `FutureOr<ResponseBody>`** : sans réponse **retenable**, le test FR-014 est
  vert **sans verrou** (R11).
- **Le harnais qui ne surcharge pas la config par défaut** : `config` est
  nullable aujourd'hui et **tous les tests de `mefali_pro` l'omettent** ; le
  provider supprime ce `null` ⇒ les 23 cas appelleraient le **vrai**
  `SharedPreferences` (canal de plateforme) et le **réseau réel** ⇒ SC-004 se
  perd **sans qu'aucune assertion ne bronche** (R5).
- **`serviceConfig` qui CONSTRUIT sa source et son cache au lieu de les
  recevoir** — la variante inerte du piège précédent, et la plus coûteuse : la
  signature d'aujourd'hui, `demarrerServiceConfig({String? urlApi})`
  (`amorce_config.dart:14-22`), bâtit **elle-même** `SourceConfigApi(MefaliApiClient(…))`
  et `CacheConfigPreferences(prefs)`. Un `serviceConfigProvider` qui l'appellerait
  ainsi ne lirait **ni `sourceConfigProvider` ni `cacheConfigProvider`** : les
  surcharger **ne changerait RIEN**, FR-035 ne serait **pas tenu**, et les 23 cas
  toucheraient quand même le canal de plateforme et le réseau — le piège
  ci-dessus, mais **réputé fermé**. Le cycle **change donc la signature de
  production** (inversion d'injection, FR-010/FR-035) : `demarrerServiceConfig({
  required SourceConfig source, required CacheConfig cache })`, `urlApi`
  redescendant dans `clientConfigProvider` que `sourceConfig` watch déjà.
  Corollaire de type : `CacheConfigPreferences(this._prefs)` exige un
  `SharedPreferences` obtenu par un `await` (`cache_config.dart:16-20`) — un
  `Provider<CacheConfig>` **synchrone ne peut pas le construire**, d'où
  `Raw<Future<CacheConfig>>`. Côté service, on le **CHAÎNE** par `.then` et on ne
  l'`await` **JAMAIS** : la fonction du provider reste **SYNCHRONE** — un corps
  `async` lui ferait rendre `Future<Raw<Future<ServiceConfig>>>` et non
  `Raw<Future<ServiceConfig>>`, **ça ne compile pas** —, et les deux `ref.watch`
  doivent être évalués **AVANT** tout point de suspension. **Aucun `AsyncValue`,
  aucun retry** : la doctrine `Raw` tient (R5, forme exacte dans
  [contracts/providers.md](contracts/providers.md)).
- **`expect(emissions, greaterThanOrEqualTo(1))`** : relâchement interdit, FR-003
  le nomme, FR-004 en fait un **échec du cycle**.
- **`removeWhere((i) => i is InterceptorAutorisation)`** dans `onDispose` : dans
  l'ordre défavorable, supprime **les deux** → 0 → l'app perd `Authorization`
  **en silence**. `List.remove` compare par **identité** : retirer l'instance
  **capturée** est ordre-indépendant (R3, R11).
- **Providerifier `modeDevOtp`** : la constante de compilation meurt,
  l'élimination de branche morte aussi, le code de relecture entre dans le
  binaire de **release** — et `expect(modeDevOtp, isFalse)` **reste vert**
  (FR-025, edge case spec).
- **Transformer `FormulaireDossierCoursier` en widget sans état** : plus
  d'endroit où poser la clé d'idempotence ⇒ **R14 sort de son isolement**
  (FR-026). Si le cas `formulaire_dossier_test.dart:192-229` tombe, on n'a pas un
  test à réparer, **on a un périmètre violé**.

## Rappels DoD avant commit (§0.4 + CLAUDE.md)

**En négatif — ce que ce cycle ne fait pas** ([spec.md](spec.md) Assumptions) :
aucune API, donc **AUCUN** contrat ni client à régénérer (`openapi.json`,
`clients/dart`, `clients/ts` **INTOUCHÉS** — FR-006) ; aucun SQL, donc **AUCUNE**
migration, **AUCUN** `cargo sqlx prepare`, **AUCUN** `cargo test` ; aucune
transition d'état **métier**, donc **AUCUN** événement outbox et **AUCUNE**
entrée dans `docs/taxonomie-evenements.md` ; **AUCUN** paramètre « paramétrable »,
donc aucune configuration de zone ; aucun Nuxt. Le point « critères
d'acceptation couverts » se réinterprète : un refactor pur n'en crée pas, il
**PRÉSERVE** les 86 existants.

**Ce qui le remplace** :

```bash
dart run build_runner build            # ×2, dans mefali_core et mefali_pro
git status --porcelain apps/           # VIDE (FR-030, SC-007)
dart analyze                           # ×3 paquets, 0 avertissement (SC-006) — PAS flutter analyze
./scripts/verifier-accord-locks.sh     # 0 désaccord (SC-008)
flutter test                           # ×3 paquets, ≥ 89 verts (SC-002)
flutter test --tags golden             # ×2 apps, À LA MAIN, JAMAIS --update-goldens (FR-005)
grep -rn 'extends ChangeNotifier\|ListenableBuilder(\|notifyListeners()' apps --include='*.dart'
                                       # aucune ligne (SC-001)
```

Clés i18n fr **non régressées** (invariant à ne pas casser — aucune chaîne
utilisateur en dur) ; `.g.dart` commités, **JAMAIS édités à la main** (même règle
que les clients d'API — constitution I) ; message conventionnel référençant la
story : `refactor(apps): TRX-08 …`. Rien construit hors du périmètre du cycle :
R14, iOS et l'enregistrement vocal restent **exactement** dans l'état où le cycle
les a trouvés.
