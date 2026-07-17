# Data Model — Gestion d'état des apps Flutter (cycle 004)

Aucune migration ce cycle — aucun schéma Postgres, aucun `cargo sqlx prepare`, le
backend et le contrat d'API sont intouchés (FR-006). Ce document définit les
structures **CONTRACTUELLES** du cycle, au sens maison de « structures durables OU
contractuelles » (`001/data-model.md:1-5`) : les **porteurs d'état** des trois
paquets Flutter, leurs **durées de vie** — qui sont ici des comportements, pas des
réglages (spec, Key Entities) — et leur **surface de surcharge en test**. Les six
Key Entities de la spec sont la matière première ; elles deviennent ici des
tableaux. Décisions et alternatives enterrées : [research.md](research.md) R1–R13.
Vérifications par exécution : 2026-07-17, Flutter 3.44.6 / Dart 3.12.2.

## 1. Inventaire des porteurs (FR-007, FR-008, FR-009)

**11 providers, exhaustivement** — tout porteur d'état d'application ou de domaine
est exposé par un provider GÉNÉRÉ par annotation (FR-007), et il n'en reste AUCUN
hors du moule (SC-001 : 2 notificateurs manuels, 2 observateurs manuels et 6
notifications manuelles → **0**).

| Porteur | Fichier:ligne actuel | Provider cible | Type | Durée de vie | Réactif ? |
|---|---|---|---|---|---|
| URL de base de l'API | `main.dart:9-10` (pro et client), passée en paramètre | `urlApiProvider` | `Provider<String>` (fonction) — **`throw` par défaut** | `keepAlive` | non — constante de compilation du point d'entrée (FR-012, R3) |
| Client HTTP porteur d'`Authorization` | `session_auth.dart:25` (`SessionAuth.client`) — **champ public SUPPRIMÉ** | `clientSessionProvider` | `Provider<MefaliApiClient>` (fonction) — **pose l'intercepteur** + `ref.onDispose(remove)` | `keepAlive` | non | 
| Client HTTP de la configuration | `amorce_config.dart:16` — client construit **DANS** `demarrerServiceConfig`, hors de toute injection | `clientConfigProvider` | `Provider<MefaliApiClient>` (fonction) | `keepAlive` | non — porte **JAMAIS** d'`Authorization` (FR-017). C'est `sourceConfig` qui le `watch` : **`urlApi` descend par ici**, plus par un paramètre de `demarrerServiceConfig` (§2.1) |
| Stockage des jetons | `session_auth.dart:22` (`SessionAuth.stockage`) → `stockage_jetons.dart:44` | `stockageJetonsProvider` | `Provider<StockageJetons>` (fonction) | `keepAlive` | non |
| **Session d'authentification** (notificateur manuel n° 1) | `session_auth.dart:15` — `SessionAuth extends ChangeNotifier` | `sessionProvider` | `NotifierProvider<Session, EtatSession>` | **`keepAlive`** (FR-019) | **oui** — `updateShouldNotify => true` (§5) |
| Source distante de configuration | `source_config.dart:15` (`SourceConfigApi`) | `sourceConfigProvider` | `Provider<SourceConfig>` (fonction) — `SourceConfigApi(ref.watch(clientConfigProvider))` | `keepAlive` — dépendance d'un service `keepAlive` | non |
| Cache local de configuration | `cache_config.dart:16` (`CacheConfigPreferences`) | `cacheConfigProvider` | **`Provider<Raw<Future<CacheConfig>>>`** (fonction) — `CacheConfigPreferences(this._prefs)` exige un `SharedPreferences` (`cache_config.dart:16-20`) qui ne s'obtient que par `await SharedPreferences.getInstance()` : un `Provider<CacheConfig>` **synchrone NE COMPILE PAS** | `keepAlive` — dépendance d'un service `keepAlive` | non — `Raw`, donc AUCUN `AsyncValue`, AUCUN retry (§3, R5, R10) |
| **Service de configuration** (porteur SANS notificateur — classe nue, `service_config.dart:19`) | `main.dart:19` (pro) / `:18` (client), puis `racine_auth.dart:38` et `routeur_roles.dart:29` en paramètre | `serviceConfigProvider` | **`Provider<Raw<Future<ServiceConfig>>>`** (fonction) — `watch` **`sourceConfig` ET `cacheConfig`** (§2.1) + `ref.onDispose(arreter)` | **`keepAlive`** (FR-019) | **NON — non-réactivité GELÉE** (FR-021, clarification du 2026-07-17) |
| **État des rôles** (notificateur manuel n° 2) | `etat_roles.dart:100` — `EtatRoles extends ChangeNotifier` | `etatRolesProvider` | `NotifierProvider<EtatRoles, EtatRolesData>` | **`@riverpod` nu (autoDispose)** + `ref.watch(sessionProvider.select((e) => e.connecte))` | **oui** — `updateShouldNotify => true` (§5) |
| Liste des adresses | `liste_adresses.dart:31` — `late Future<List<Adresse>> _adresses` + `setState` (`:47-49`) | `mesAdressesProvider` | `AsyncNotifierProvider<MesAdresses, List<Adresse>>` | autoDispose | oui — `AsyncValue` |
| Liste des appareils | `ecran_appareils.dart:29` — `late Future<List<SessionAppareil>> _appareils` + `setState` (`:42-48`) | `mesSessionsProvider` | `AsyncNotifierProvider<MesSessions, List<SessionAppareil>>` | autoDispose | oui — `AsyncValue` |

**Trois lectures obligatoires de ce tableau.**

1. **`@riverpod` nu est autoDispose** — c'est le défaut du générateur
   (`riverpod_annotation-4.0.3/lib/src/riverpod_annotation.dart:24`,
   `Riverpod({this.keepAlive = false})`) et c'est le **mode de panne n° 2** nommé
   par la spec (`spec.md:147`) : sous le défaut, session et configuration seraient
   détruites dès le dernier auditeur parti — le rafraîchissement horaire
   s'arrêterait puis redémarrerait, comportement qui n'existe pas aujourd'hui.
   D'où **`@Riverpod(keepAlive: true)` × 8**, écrit à la main, huit fois (R4) :
   `urlApi`, `clientSession`, `clientConfig`, `stockageJetons`, `session`,
   `sourceConfig`, `cacheConfig`, `serviceConfig`. `sourceConfig` et `cacheConfig`
   en sont **parce qu'ils sont les dépendances d'un service `keepAlive`** : en
   autoDispose ils seraient reconstruits sous lui. Les **3 autoDispose** (`@riverpod`
   nu) : `etatRoles`, `mesAdresses`, `mesSessions`. **Le grep de contrôle de SC-010
   renvoie 8, pas 6** — tout artefact qui écrit 6 fait rougir le contrôle sur du code
   correct.
2. **AUCUN lint ne garde l'opposition `keepAlive` / autoDispose** — vérifié :
   `only_use_keep_alive_inside_keep_alive` porte sur `KeepAliveLink`, pas sur le
   sens des dépendances, et la règle `avoid_keep_alive_dependency_inside_auto_dispose`
   **N'EXISTE PAS** (R2, R4). L'invariant central du cycle n'est tenu que par les
   tests (§2) et la revue.
3. **Deux moules, assumés** (R5, R6, à graver dans la constitution — FR-040) :
   `Notifier<Etat…>` pour les porteurs à sémantique propre (session, rôles),
   `AsyncNotifier` pour les chargements de liste (adresses, appareils). Uniformiser
   derrière `AsyncValue` est le geste que l'idiome invite et il détruit les deux
   sémantiques opposées de FR-022 d'un seul coup.

**Supprimés, pas portés :**

| Symbole | Fichier:ligne | Sort |
|---|---|---|
| `RouteurRoles.etat` — couche d'injection de test des rôles | `routeur_roles.dart:20, :37, :44, :73` | **SUPPRIMÉE** (FR-043) — vérifié : AUCUN test ne la passe ⇒ code mort ; le porter dans le nouveau moule le graverait |
| `SessionAuth.client` | `session_auth.dart:25` | remplacé par `clientSessionProvider` — les 5 consommateurs (`etat_roles.dart:161`, `ListeAdresses`, `EcranAppareils`, `ParcoursAuth`, `FormulaireDossierCoursier`) le lisent (R3) |
| `SessionAuth.stockage` | `session_auth.dart:22` | remplacé par `stockageJetonsProvider` |
| `EtatRoles.session` | `etat_roles.dart:102, :105` | remplacé par `ref.read(clientSessionProvider)` + l'arête `sessionProvider.select` |
| `_InterceptorAutorisation` | `session_auth.dart:84` | **rendu PUBLIC** (`InterceptorAutorisation`) — prérequis de production : sans lui, `compteIntercepteursApp` ne peut pas compter **par type** et SC-005 retomberait sur le `.last` que ce cycle supprime (R11) |

## 2. Durées de vie — transitions (FR-019, FR-020, FR-022)

Les durées de vie **sont** des machines à états (spec, Key Entities : « caractéristique
FONCTIONNELLE et non technique, puisqu'elle décide de la persistance d'un timer, de
la réapparition d'un écran de chargement et de l'isolation des données entre deux
comptes »). **Chaque flèche = un test d'intégration (constitution VII)** — écart
unique, consigné au Complexity Tracking : les deux lectures d'instantané de
configuration (`racine_auth.dart:70-77`, `routeur_roles.dart:58-67`), que la
migration réécrit et qu'AUCUN des 86 cas ne couvre (`spec.md:274`) ; elles se
vérifient sur émulateur (SC-009), pas ici.

### 2.1 Le graphe d'objets — acyclique, deux racines indépendantes (R3)

```
urlApi ──▶ clientSession ──pose──▶ InterceptorAutorisation ──runtime read──▶ session
   │            │  ▲                                                            ▲
   │            └──┘ ref.onDispose(remove)  (FR-018)                            │
   │                                                          stockageJetons ───┘
   └──▶ clientConfig ──▶ sourceConfig ─────────────┐
                                                   ├──▶ serviceConfig ──▶ Timer 1 h ──▶ ∞ (FR-019)
 SharedPreferences.getInstance() ──▶ cacheConfig ──┘         │
        (canal de plateforme, hors graphe de providers)      │
                            container.dispose() ─────────────▶ arreter()  (FR-018)
```

**Les deux arêtes `sourceConfig`/`cacheConfig` ▶ `serviceConfig` n'existent PAS
aujourd'hui : ce cycle les crée, et c'est un CHANGEMENT DE SIGNATURE DE PRODUCTION
à nommer.** La signature actuelle — `Future<ServiceConfig> demarrerServiceConfig({String? urlApi})`
(`amorce_config.dart:14-22`) — construit **elle-même** `SourceConfigApi(MefaliApiClient(…))`
et `CacheConfigPreferences(prefs)`. Un `serviceConfigProvider` qui l'appellerait avec
`urlApi` ne consommerait **NI `sourceConfig` NI `cacheConfig`** : les surcharger ne
changerait **RIEN**, **FR-035 ne serait pas tenu**, les 23 cas de `mefali_pro`
appelleraient le vrai `SharedPreferences` (canal de plateforme) **et** le vrai réseau,
et **SC-004 se perdrait SANS QU'AUCUNE ASSERTION NE BRONCHE** (§3). `clientConfig`,
`sourceConfig` et `cacheConfig` resteraient de surcroît **orphelins** — rien ne les
lirait — et FR-017 serait **nominal** : le trafic de configuration passerait par le
client construit dans `demarrerServiceConfig`, pas par `clientConfigProvider`. D'où
l'**inversion d'injection** que le cycle demande explicitement (FR-010, FR-035) : la
fonction **REÇOIT** source et cache au lieu de les construire.

```dart
// amorce_config.dart — nouvelle signature de production.
Future<ServiceConfig> demarrerServiceConfig({
  required SourceConfig source,
  required CacheConfig cache,
}) async {
  final service = ServiceConfig(source: source, cache: cache);
  await service.demarrer();
  return service;
}
```

`urlApi` **n'y descend plus** : il descend dans `clientConfigProvider`, que
`sourceConfig` `watch` déjà — d'où l'arête `urlApi ▶ clientConfig ▶ sourceConfig`.
La fonction du provider reste **SYNCHRONE** et rend un `Raw` : `cacheConfig` étant un
`Raw<Future<CacheConfig>>` (§1), on le **CHAÎNE** par `.then` au lieu de l'`await`er —
les deux `ref.watch` doivent être évalués **AVANT** tout point de suspension (un
`watch` après un `await` est une arête non enregistrée), et un corps `async` rendrait
au générateur un `Future` à interpréter, alors que le `Raw` doit rester le **seul**
niveau de Future, sans quoi on retombe sur l'`AsyncValue` que FR-021 interdit (§1).
Forme exacte : [contracts/providers.md](contracts/providers.md) (R5).

L'arête `intercepteur → session` n'existe **QU'AU RUNTIME**, hors du graphe de
providers : l'intercepteur détient le `Ref` de `clientSession` — jamais le
notificateur, jamais `this` (R3). `sessionProvider` **ne dépend d'AUCUN** provider
(`stockageJetons` est lu en `read` dans les méthodes) : le `ref.watch(clientSessionProvider)`
que le réflexe suggère est une arête **inutile** et créerait le cycle. FR-013
devient **structurel, pas testé** : `clientSession` ne dépendant d'aucun état
mutable, une ré-évaluation de `sessionProvider` ne touche JAMAIS au dio — le mode
de panne n° 1 (`spec.md:146` : deux intercepteurs ⇒ deux renouvellements concurrents
⇒ jeton tourné rejoué ⇒ vol présumé ⇒ **session révoquée**) devient inatteignable.

| Flèche | Test |
|---|---|
| `clientSession` pose 1 intercepteur | `expect(compteIntercepteursApp(dio), 1)` après première évaluation — **cas NEUF** (SC-005) |
| ré-évaluation de `session` n'en empile pas un 2ᵉ | idem après `invalidate(sessionProvider)`, après `fermer()/ouvrir()/ouvrir()` — **cas NEUF** |
| `clientConfig` n'en porte AUCUN | `expect(compteIntercepteursApp(dioConfig), 0)` (FR-017) — **cas NEUF** |
| `ref.onDispose(remove)` | `0` après `invalidate(clientSessionProvider)` et après `container.dispose()` (FR-018) — **cas NEUF** ; sans le mécanisme de production, ces cas ÉCHOUENT : c'est leur travail |
| N requêtes 401 concurrentes → 1 renouvellement | `expect(renouvellements, 1)` puis `expect(rejeux, N)` (FR-014, SC-005) — **cas NEUF**, retenue par `Completer` obligatoire (R11) |
| `serviceConfig` → Timer → ∞ | `fakeAsync` : tic à 0 h, 1 h, **2 h sans aucun auditeur** (FR-019) |
| `container.dispose()` → `arreter()` | le timer cesse (FR-018) — conteneur créé, lu ET disposé **DANS** la zone `fakeAsync` (R11) |

⚠ **Ne JAMAIS écrire `dio.interceptors.removeWhere((i) => i is InterceptorAutorisation)`** :
dans l'ordre défavorable il en supprimerait deux → **0**, et l'app perdrait
`Authorization` en silence. `List.remove` compare par **identité** : le retrait de
l'instance capturée est ordre-indépendant (R11).

### 2.2 Les DEUX machines opposées de FR-022

`charge` de la session est **MONOTONE**, `charge` des rôles ne l'est PAS. C'est
l'exigence la plus contre-intuitive du cycle, et aucun défaut de framework ne
convient aux deux.

```
# SESSION — `charge` ne redevient JAMAIS false  (FR-022, session_auth.dart:28)
                             ┌────────────── quoi qu'il arrive ──────────────┐
                             │                                               │
  charge=false ──charger()──▶ charge=true ──ouvrir()/fermer()/rotation──▶ charge=true
       │                                                                     ▲
  ÉCRAN DE DÉMARRAGE                                                         │
  (racine_auth.dart:82)          l'écran de démarrage NE PEUT PAS réapparaître
                                 en plein parcours ⇒ `Notifier`, JAMAIS `AsyncNotifier`

# RÔLES — `charge` repasse à false À CHAQUE charger()  (FR-022, etat_roles.dart:156-158)
  charge=true ──charger()──▶ charge=false ──(succès OU échec)──▶ charge=true
                                  │                                   │
                          ChargementPro RÉAPPARAÎT            enErreur=true possible
                          (routeur_roles.dart:82)             AVEC charge=true
                                                              (etat_roles.dart:189-192)
                                                              ⇒ ErreurPro (routeur_roles.dart:83)
```

**Pourquoi `Notifier` et pas `AsyncNotifier` pour la session** : `AsyncNotifier.build()`
DÉMARRE en `AsyncLoading` et y RETOURNE à chaque `refresh`/`invalidate`/retry ⇒
l'écran de démarrage réapparaîtrait en plein parcours — ce que FR-022 interdit
nommément. Et `charger()` migrerait dans `build()`, alors que `racine_auth.dart:12-17`
documente l'inverse (« bloquer le lancement sur une lecture de Keystore ferait
clignoter un écran blanc ») (R6).

**Pourquoi PAS `AsyncValue` pour les rôles** : il **fusionnerait `charge` et
`enErreur`**, qui sont ici **ORTHOGONAUX** — sur erreur, `etat_roles.dart:189-192`
produit `charge: true` **ET** `enErreur: true`, **attributions conservées**. En
`AsyncError`, la branche `ErreurPro` devrait être reconstruite à partir d'un type
qui ne la modélise pas (R6).

### 2.3 La vie et la mort des rôles (FR-020, SC-010)

```
session.connecte :  false ──ouvrir()──▶ true ──fermer()──▶ false
                                 │                    │
                    rotation de jeton (ouvrir)        │
                                 │                    ▼
                                 ▼        etatRoles.build() REJOUÉ ⇒ état VIDE
                    AUCUN effet sur etatRoles         │   avant TOUT rendu
                    (`.select((e) => e.connecte)`)    ▼
                    ⇒ 0 rechargement (FR-002)   AUCUN rôle du compte précédent,
                                                à AUCUN instant (SC-010)

etatRoles.actif  :  null ──charger()──▶ coursier ──charger()──▶ coursier   (MÉMOIRE)
                                                       │
                              suspendu entre 2 chargements ──▶ null/autre  (US4 scénario 3, spec.md:99)
```

**`ref.watch(sessionProvider.select((e) => e.connecte))` dans `build()` GRAVE
l'arête** : session fermée ⇒ provider invalidé ⇒ `build()` rejoué ⇒ état vide
**avant tout rendu**, même si quelqu'un met `keepAlive: true` demain. `autoDispose`
seul ne suffit PAS : la destruction est *planifiée* et non synchrone, et Riverpod 3
**met en pause** (`TickerMode`) les providers hors-champ — un provider en pause
n'est PAS détruit (R4).

**`.select` n'est pas une optimisation, c'est une correction de bug** :
`ref.watch(sessionProvider)` nu serait **FAUX** — l'intercepteur appelle `ouvrir()`
à CHAQUE rotation de jeton ⇒ les rôles se rechargeraient à chaque renouvellement
silencieux ⇒ **requête ajoutée (FR-002)** + `ChargementPro` en plein parcours
(FR-001), sur un chemin que seul un 401 déclenche — **donc jamais en test** (R4).

**`build()` ne charge RIEN** : le chargement est déclenché par le routeur
(`routeur_roles.dart:50`) et `charger()` est rejouable sans que `build()` retourne
— c'est **exactement** ce qui laisse `actif` survivre. La **mémoire est dans `state`,
la destruction est dans `build()`**, et les deux exigences opposées cessent de se
marcher dessus (R8). `routeur_roles_test.dart:295-322` (deux `charger()` sur la
même instance, `actif: coursier` puis `actif: vendeur`) interdit à lui seul les
trois designs que Riverpod suggère spontanément : `Future<T> build() async`,
`AsyncNotifier`, et le rechargement par `invalidate`.

**Hypothèse datée, à consigner** : `connecte` est le **proxy d'identité de compte**
— `SessionAuth` n'expose aucun identifiant (`session_auth.dart:31-40`) et `acces`
tourne. Aucun changement de compte n'est possible sans passer par `fermer()` (le
parcours OTP l'exige), donc `true → false → true` encadre toujours une bascule. Le
jour où un « changement de compte à chaud » existera, **ce proxy tombe** (R4).

### 2.4 Le squelette des listes (FR-023)

```
AsyncData ──recharger()──▶ AsyncLoading (EXPLICITE) ──▶ AsyncData | AsyncError
                                  │
                        SQUELETTE RÉAFFICHÉ, comme le setState(() => _adresses =
                        _charger()) d'avant (liste_adresses.dart:47-49), qui
                        repartait en ConnectionState.waiting
```

`state = const AsyncLoading()` est écrit **explicitement** dans `recharger()`, et
`.when()` reste **aux défauts du framework dans tout le dépôt**. Motif : vérifié,
**`skipLoadingOnRefresh = true` par DÉFAUT** (`riverpod-3.3.2/lib/src/core/async_value.dart:198,244,277`)
⇒ `invalidate` + `.when(skipLoadingOnRefresh: false)` ferait porter FR-023 par un
booléen **à répéter à chaque site d'appel, dont le défaut fait exactement le
contraire** ; un site oublié ⇒ le squelette cesse d'apparaître ⇒ changement visible
⇒ **aucun des 86 cas ne le rattrape**. Le comportement est dans le code, à un seul
endroit, dans une méthode déjà nommée `recharger()` (`liste_adresses.dart:44`,
`ecran_appareils.dart:42`) ⇒ **pas de convention à écrire, donc pas de convention à
oublier** (R9).

## 3. Surface de surcharge en test (FR-035, FR-038)

**La règle du cycle, en une ligne : on surcharge les DÉPENDANCES, JAMAIS le sujet.**

| Provider | Surchargé en test ? | Par quoi / pourquoi pas |
|---|---|---|
| `urlApiProvider` | **OUI, obligatoire** | `overrideWithValue('http://test.invalid')` — il **`throw`** par défaut (FR-012) |
| `stockageJetonsProvider` | **OUI** | `StockageJetonsMemoire(jetons)` (`stockage_jetons.dart:84`) — double **déjà** en production, précédent assumé (FR-035, FR-039) |
| `sourceConfigProvider` | **OUI — PAR DÉFAUT dans le harnais** | double en mémoire. **Sans ce défaut, les 23 cas de `mefali_pro` déclencheraient le vrai `demarrerServiceConfig` ⇒ `SharedPreferences.getInstance()` (canal de plateforme) + appel réseau réel** : aujourd'hui `config: null` les protège (`routeur_roles_test.dart:99`), et **cette protection disparaît avec le provider**. C'est le mécanisme exact par lequel « 0 requête ajoutée » (SC-004) se perdrait **sans qu'aucune assertion ne bronche** (R5, R11). ⚠ Ce défaut n'a d'effet **QUE** parce que `serviceConfig` consomme désormais ce provider (§2.1) : sous l'ancienne signature, la surcharge serait **inerte** |
| `cacheConfigProvider` | **OUI — PAR DÉFAUT dans le harnais** | double en mémoire, rendu en **`Raw<Future<CacheConfig>>`** — même type que le provider (§1) : c'est lui qui tient le **canal de plateforme** hors des 23 cas (FR-035, FR-039). Même réserve qu'au-dessus : inerte sous l'ancienne signature |
| `serviceConfigProvider` | oui, si un cas l'exige | — |
| `clientSessionProvider` | **JAMAIS** | on substitue `dio.httpClientAdapter` sur le client **RÉEL** (FR-036). `overrideWith((ref) => MefaliApiClient(dio: dioFactice))` — le geste que l'idiome invite — est **doublement destructeur** : il perd l'intercepteur (le test ne prouve plus rien **tout en restant vert**) **et** les délais 5000/3000 ms qui ne vivent que dans la branche par défaut du client généré (`clients/dart/lib/src/api.dart:30-35`) (R11) |
| `clientConfigProvider` | **JAMAIS** | idem |
| **`sessionProvider`** | **JAMAIS — règle dure, voir ci-dessous** | on surcharge ses **dépendances** (`stockageJetons`, le transport) ⇒ verrou `_enCours`, anti-boucle et rejeu unique sont **ceux de production** (R11) |
| `etatRolesProvider` | **JAMAIS** | dépendances |
| `mesAdressesProvider`, `mesSessionsProvider` | **JAMAIS** | transport |

**Règle n° 1 — `sessionProvider` n'est JAMAIS surchargé, et JAMAIS dans une portée
imbriquée.** Le surcharger dans un `ProviderScope` imbriqué donne **DEUX notifiers
sur le même dio ⇒ 2 intercepteurs** — exactement le mode de panne n° 1 (`spec.md:146`),
reproduit **par le harnais**. AUCUNE construction Riverpod ne l'empêche : c'est une
**règle à écrire, pas un bug à corriger**. **Les surcharges vivent dans le conteneur
RACINE du test**, un seul, jamais deux étages (R11).

**Règle n° 2 — `retry: pasDeRetry` sur TOUTE création de portée** : 2 points
d'entrée + le harnais. `pasDeRetry` est une **constante de `mefali_core`, réutilisée
par le harnais** — **publique**, déclarée dans une bibliothèque de **PRODUCTION** (à
côté des providers, exportée par le barrel), et **NON** dans `harnais.dart` : un
top-level privé serait privé à sa bibliothèque, donc redéclaré dans chaque `main.dart`
⇒ « un réglage par site », que la règle n° 4 de [contracts/providers.md](contracts/providers.md)
interdit ; et faire importer le harnais par les 2 points d'entrée de production
contredirait le tree-shaking (R10, R11). Vérifié dans le code résolu : Riverpod 3 **RÉESSAIE les
providers en échec PAR DÉFAUT** — 10 essais, backoff 200 ms → 6,4 s
(`provider_container.dart:940-954`), et `if (error is ProviderException || error is Error) return null;`
⇒ **toutes les `Exception` sont réessayées, `DioException` comprise**. AUCUNE requête
n'était rejouée avant ce cycle : le défaut **viole FR-002 sans une ligne de code, et
les tests restent verts** (`ServiceConfig.rafraichir` avale ses erreurs —
`service_config.dart:64`). ⚠ Le `retry: null` que le générateur écrit signifie
« **hérite** », PAS « désactivé » (R10).

**Règle n° 3 — tout cas unitaire sur `etatRolesProvider` OUVRE un abonnement** :
`final sub = container.listen(etatRolesProvider, (_, __) {}); addTearDown(sub.close);`.
`container.read(…notifier)` **n'attache AUCUN auditeur** sur un autoDispose ⇒ le
notifier peut être rejeté entre deux `charger()` ⇒ `build()` rejoué ⇒ `actif` repart
à `null` ⇒ **`routeur_roles_test.dart:295-322` devient VERT SANS RIEN PROUVER** — le
pire résultat possible. C'est la **collision directe entre FR-020 (autoDispose) et
FR-038 (conteneur explicite)**, et elle ne se voit qu'ici (R8, R11).

**Règle n° 4 — `addTearDown(container.dispose)` dans CHAQUE cas.** Le harnais rend
un `ProviderContainer` construit avec le constructeur **public** et monte un
`UncontrolledProviderScope`, qui **NE dispose PAS** le conteneur — c'est sa raison
d'être (FR-038, R10, R11). Le harnais **n'appelle PAS `ProviderContainer.test()` :
il est `@visibleForTesting`** ⇒ depuis `lib/` → `invalid_use_of_visible_for_testing_member`
→ **EXIT 3 → SC-006 échoue** (vérifié) ; légal depuis `test/` seulement.

**Ce que le harnais ne peut PAS faire, vérifié** : annoter `List<Override>` —
`flutter_riverpod 3.3.2` a un `show` de 34 symboles qui **N'EXPORTE PAS `Override`**
⇒ `non_type_as_type_argument`, **même via `package:riverpod/riverpod.dart`**.
L'inférence marche, l'annotation non ⇒ **API centrée conteneur**, jamais fabrique
d'overrides (R11, [contracts/harnais-de-test.md](contracts/harnais-de-test.md)).

## 4. Registre du code généré (FR-029, FR-030, FR-031)

Key Entity « **Code généré commité** » (`spec.md:249`) : *fichiers dérivés
mécaniquement du code annoté, versionnés, dont toute dérive avec leur source casse le
build — même règle que les clients d'API dérivés du contrat*. Le cycle **ajoute un
graphe de génération de source là où il n'y en avait aucun** sous `apps/` (`spec.md:279`).
Ce qui suit est donc un inventaire **neuf**, pas un existant cartographié.

**La règle, en une ligne : un `.g.dart` est du code de `clients/dart`, pas du code à
soi** — commité (FR-029), régénéré à l'identique (FR-030), gardé par un contrôle de
dérive (FR-031), **JAMAIS édité à la main** (constitution I, `CLAUDE.md` §Sources de
vérité).

| Fichier généré | Paquet | Né de | Commité ? | Gardé par |
|---|---|---|---|---|
| un `.g.dart` **par bibliothèque annotée** sous `lib/src/**` (auth, config, adresses, appareils) — **10 providers** : `urlApi`, `clientSession`, `clientConfig`, `stockageJetons`, `session`, `sourceConfig`, `cacheConfig`, `serviceConfig`, `mesAdresses`, `mesSessions` | `mefali_core` — les providers rejoignent le fichier `lib/src/` de leur domaine (`session_auth.dart`, `service_config.dart`, `liste_adresses.dart`, `ecran_appareils.dart`) ; aucune réorganisation de fichiers (spec, Hors périmètre) | `@riverpod` / `@Riverpod(keepAlive: true)` + `part '<nom>.g.dart'` → `riverpod_generator` | **OUI** (FR-029) | `git diff --exit-code -- .` sous le paquet, **après** régénération et **avant** analyse (FR-034, [contracts/ci-apps.md](contracts/ci-apps.md) règles 2-4) |
| le `.g.dart` de `lib/roles/etat_roles.dart` — **1 provider** : `etatRoles` (`_$EtatRoles`) | `mefali_pro` | idem | **OUI** | idem |
| **aucun `.g.dart` de provider** | `mefali_client` | il ne porte **aucune** bibliothèque annotée — les 11 providers vivent dans les deux autres paquets | — | son contrôle de dérive tourne quand même : la portée est le **répertoire du paquet**, pas `*.g.dart` (ci-apps règle 4) |
| **aucun `.g.dart`** | `harnais.dart` (`mefali_core`) | il ne déclare **aucun** provider — il monte des conteneurs et réutilise `pasDeRetry` (§3) | — | — |

**Trois lectures de ce registre.**

1. **Le générateur écrit `retry: null`, et `null` signifie « HÉRITE », pas
   « désactivé »** (§3, règle n° 2) : aucun `.g.dart` ne portera jamais la parade —
   elle vit dans les 2 `ProviderScope` de production et dans le harnais, à la main.
   Un `.g.dart` relu comme une preuve mentirait ici (R10).
2. **La commande est `dart run build_runner build` NU** :
   `--delete-conflicting-outputs` a été **SUPPRIMÉ** de build_runner 2.15.x (« *These
   options have been removed and were ignored* ») — le réflexe le plus répandu du
   dépôt est devenu un drapeau mort (R2, ci-apps règle 3).
3. **Le contrôle de dérive est le SEUL garde-fou mécanique de FR-007** : aucun lint
   ne garde l'opposition `keepAlive`/autoDispose (§1, lecture n° 2), et le décompte
   de SC-010 est un `grep` — **8 `keepAlive`, 3 `@riverpod` nus** (§1). Un `.g.dart`
   désynchronisé ferait analyser du code qui ne correspond à aucune annotation ⇒
   diagnostics trompeurs : d'où l'ordre imposé `pub get` → régénération → dérive →
   analyse → tests (FR-034).

## 5. Les types d'état (FR-022)

Deux classes NUES, immuables, **volontairement SANS `operator ==`**, et
`updateShouldNotify => true` **explicite sur les deux**. On prend **les deux**
parades, pas une : la classe sans `==` marche **par accident** — le jour où
quelqu'un ajoute `Equatable`/`freezed`, les émissions fusionnent et
`expect(emissions, 1)` **reste vert en prouvant moins**, ce qui est exactement le
mode de panne que FR-004 nomme (R6).

```dart
/// État de session. Classe IMMUABLE, volontairement SANS `operator ==` : un
/// `record` ou une classe à égalité structurelle ferait qu'un `ouvrir()` aux
/// MÊMES jetons émettrait 0 au lieu de 1 (`JetonsSession` implémente déjà `==`,
/// stockage_jetons.dart:18-24) — FR-003.
@immutable
class EtatSession {
  const EtatSession({required this.charge, this.jetons});
  const EtatSession.initiale() : charge = false, jetons = null;

  /// `true` une fois le stockage relu. NE REDEVIENT JAMAIS `false` (FR-022).
  ///
  /// `charge` FAIT PARTIE DE LA VALEUR, comme `_charge` est un champ aujourd'hui
  /// (session_auth.dart:28). Si l'état était un `JetonsSession?` nu, `charger()`
  /// sur un stockage VIDE ferait `null → null` ⇒ AUCUNE émission ⇒ `RacineAuth`
  /// ne quitterait JAMAIS l'écran de démarrage ⇒ session_auth_test.dart:99-107
  /// échouerait. Mode de panne silencieux de ce fichier.
  final bool charge;

  final JetonsSession? jetons;

  bool get connecte => jetons != null;
  String? get acces => jetons?.acces;
  String? get rafraichissement => jetons?.rafraichissement;
}

@Riverpod(keepAlive: true)   // FR-019 — mode de panne n°2 si `@riverpod` nu
class Session extends _$Session {
  /// NE dépend d'AUCUN provider : le renouvellement vit dans l'intercepteur, qui
  /// capture le client. `ref.watch(clientSessionProvider)` créerait le cycle (R3).
  @override
  EtatSession build() => const EtatSession.initiale();

  /// Traduction FIDÈLE de `ChangeNotifier` : `notifyListeners()` émet TOUJOURS,
  /// sans comparer, et `RacineAuth` rebâtit à chaque appel (racine_auth.dart:82,
  /// `ListenableBuilder`, sans filtre). Le défaut v3 (« All providers now use `==`
  /// to filter updates ») filtrerait les écritures égales et rendrait
  /// `expect(emissions, 1)` plus FAIBLE que l'assertion d'origine (FR-003/FR-004).
  /// Ne JAMAIS « optimiser ». Le test « deux `ouvrir()` à jetons identiques ⇒
  /// 2 émissions » est ce qui rougit si on retire cette ligne.
  @override
  bool updateShouldNotify(EtatSession previous, EtatSession next) => true;

  /// Ordre `state =` PUIS `await` l'I/O (R3) : ce que l'intercepteur voit change
  /// IMMÉDIATEMENT, comme aujourd'hui. L'ordre inverse laisserait une requête
  /// concurrente porter l'ANCIEN jeton ⇒ 401 ⇒ requête AJOUTÉE ⇒ FR-002 violé.
  /// Un 401 surnuméraire est un absolu ; une frame ne l'est pas.
  Future<void> charger() async { … }
  Future<void> ouvrir(JetonsSession jetons) async { … }
  Future<void> fermer() async { … }
}
```

```dart
/// État des rôles pro. Mêmes règles (classe nue, pas d'`==`), sémantique INVERSE.
@immutable
class EtatRolesData {
  const EtatRolesData({
    this.attributions = const [],
    this.charge = false,
    this.enErreur = false,
    this.actif,
  });

  /// Tous les rôles pro du compte, quel que soit leur statut (etat_roles.dart:107).
  final List<AttributionPro> attributions;

  /// Le compte a-t-il été relu au moins une fois (succès OU échec) ?
  ///
  /// NON MONOTONE — contrairement à `EtatSession.charge` : `charger()` le remet à
  /// `false` ET notifie (etat_roles.dart:156-158) ⇒ `ChargementPro` RÉAPPARAÎT
  /// (routeur_roles.dart:82). FR-022 exige les DEUX sémantiques opposées.
  final bool charge;

  /// Le dernier chargement a-t-il échoué ? ORTHOGONAL à [charge] : sur erreur,
  /// etat_roles.dart:189-192 produit `charge: true` ET `enErreur: true`,
  /// attributions CONSERVÉES. `AsyncValue` fusionnerait les deux et la branche
  /// `ErreurPro` (routeur_roles.dart:83) deviendrait irreprésentable — d'où
  /// `Notifier`, PAS `AsyncNotifier` (R6).
  final bool enErreur;

  /// Rôle dont l'interface est affichée. Sa MÉMOIRE entre deux `charger()` est
  /// une exigence produit (etat_roles.dart:177-180) : la perdre renverrait
  /// l'utilisateur à l'autre interface SOUS SES DOIGTS à chaque rafraîchissement.
  final RolePro? actif;

  List<RolePro> get rolesValides => …;   // ordre du backend, stable (etat_roles.dart:122-128)
  StatutRolePro statut(RolePro role) => …;
}

@riverpod   // NU = autoDispose : garantie de SÉCURITÉ, pas de performance (FR-020)
class EtatRoles extends _$EtatRoles {
  @override
  EtatRolesData build() {
    // FR-020/SC-010 — l'arête GRAVÉE : session fermée ⇒ provider invalidé ⇒
    // build() rejoué ⇒ état VIDE avant tout rendu, même si quelqu'un met
    // `keepAlive: true` demain. `.select` et NON `ref.watch` nu : l'intercepteur
    // appelle `ouvrir()` à CHAQUE rotation de jeton (R4).
    ref.watch(sessionProvider.select((e) => e.connecte));
    // build() ne CHARGE rien : le chargement est déclenché par le routeur
    // (routeur_roles.dart:50) et `charger()` est rejouable sans que build()
    // retourne — c'est ce qui laisse `actif` survivre (R8).
    return const EtatRolesData();
  }

  @override
  bool updateShouldNotify(EtatRolesData p, EtatRolesData n) => true;

  Future<void> charger() async { … }   // corps identique à etat_roles.dart:155-194
  void basculer(RolePro role) { … }    // aucune requête, aucun jeton touché (etat_roles.dart:196-204)
}
```

`serviceConfigProvider` n'a **AUCUN type d'état** : `Raw<Future<ServiceConfig>>`
(`typedef Raw<WrappedT> = WrappedT;`) rend un `Provider` **de Future**, donc **PAS
de `FutureProvider`, AUCUN `AsyncValue` à émettre, AUCUN retry automatique**. FR-021
devient **impossible à violer** plutôt que tenu par la discipline `read` vs `watch` ;
un futur cycle qui voudrait rendre la config vivante devra **changer le type** —
geste visible en revue. Le type est **identique à aujourd'hui** (`racine_auth.dart:38`,
`routeur_roles.dart:29`) : les deux consommateurs gardent leur `await` en `try/catch`,
avec **`ref.read`, JAMAIS `ref.watch`** (R5).

## 6. Ce qui n'est PAS un porteur d'état (FR-009)

L'état strictement local — qui naît et meurt avec un widget, et que rien d'autre ne
lit — **reste local**. Le cycle ne le providerifie PAS (US3-7, US5-1). Le
providerifier serait une **amélioration**, donc une violation de l'invariant central.

| Ce qui reste local / paramètre | Fichier:ligne | Raison |
|---|---|---|
| **`modeDevOtp`** | `otp_dev.dart` | **FR-025 — `const`, AUCUN provider ne la remplace.** En provider, elle cesse d'être une constante de compilation ⇒ l'élimination de branche morte meurt ⇒ **le code de relecture entre dans le binaire de production**. Le garde serveur tiendrait, mais l'invariant côté app serait détruit **EN SILENCE — et le test qui le protège resterait VERT** (`spec.md:152`) |
| `_cleIdempotence` | `formulaire_dossier.dart:95` (`Uuid().v7()` en initialiseur de champ de `State`) | **FR-026** — portée **exactement** celle d'aujourd'hui, ni élargie ni rétrécie. `FormulaireDossierCoursier` reste un **`ConsumerStatefulWidget`** : le transformer en widget sans état est le geste naturel quand on supprime les `StatefulWidget`, et c'est le **SEUL chemin** par lequel un refactor « pur » ferait sortir **R14** de son isolement (`spec.md:153`, constitution V). Le cas `formulaire_dossier_test.dart:192-229` en est le garde-fou : s'il tombe, on n'a pas un test à réparer, **on a un périmètre violé** |
| `_vehicules` (`Set` muté en place) | `formulaire_dossier.dart:85` | état local du brouillon non soumis (FR-009). Défaut latent **consigné, NON corrigé** (FR-027) : la mutation en place fonctionne avec `setState`, un porteur comparant par identité ne notifierait pas (`spec.md:155`) — le formulaire reste à état, donc le défaut ne s'active pas |
| `_piece` (`PieceChoisie`) | `formulaire_dossier.dart:82-95` | ressource native liée au widget (FR-009) |
| Les **4 fonctions injectées** : `choisirPiece`, `jouerNote`, `capturerNote`, `lireCodeDevReseau(Dio)` | paramètres de widget | **FR-011 — paramètres de constructeur, TOUT OU RIEN, aucune ne bascule** (clarification du 2026-07-17). Ce cycle migre l'ÉTAT, pas les callbacks ; doctrine « on double la FONCTION, pas le canal » préservée (FR-039) |
| `versionConsentement`, `transportsActifs` | paramètres de `ParcoursAuth` / `EcranEtatDemande` / `FormulaireDossierCoursier` | **FR-021 rendu littéral** — instantané figé à l'entrée de l'écran |
| `_versionConsentement`, `_transportsActifs` | `racine_auth.dart:70-77`, `routeur_roles.dart:58-67` | ils **SONT** l'instantané (FR-021). Lus par `ref.read`, **JAMAIS `ref.watch`** |
| `TextEditingController`, `FocusNode`, compte à rebours 60 s | `ecran_telephone.dart`, `ecran_otp.dart`, `ecran_consentement.dart`, `_DialogueRenommer` (`liste_adresses.dart:154`) | saisies, focus, temporisation ergonomique (FR-009) |
| `_controleur.addListener` | `ecran_otp.dart:67` | ⚠ **DOIT RESTER** — SC-001 compte les **`ListenableBuilder`** (2 → 0), **PAS** les listeners de contrôleurs. `grep -rn 'addListener' apps` donne 2 hits ; exiger 0 exigerait une **régression de FR-009** (R13) |
| Enregistreur vocal (état + ressource native) | `note_vocale.dart` | FR-009 ; iOS et l'enregistrement vocal **hors périmètre** |
| `SplashScreen` (`StatelessWidget`) | `mefali_client/lib/splash_screen.dart`, `mefali_pro/lib/splash_screen.dart` | ne lit **AUCUN** état ⇒ **JAMAIS** converti en `ConsumerWidget`. C'est le seul chemin de casse des 2 goldens : FR-005/SC-002 sont tenus **mécaniquement** — les goldens montent un `StatelessWidget` nu, hors de toute portée. **Ne JAMAIS passer `--update-goldens` pendant le cycle** (R13) |

**Le compteur est le contrat** (SC-001, US5-1) : 2 `ChangeNotifier` → **0**, 2
`ListenableBuilder` (`racine_auth.dart:82`, `routeur_roles.dart:79`) → **0**, 6
`notifyListeners()` (`session_auth.dart:46,53,65` ; `etat_roles.dart:158,193,203`)
→ **0**. Tant qu'un porteur subsiste, la convention est « Riverpod sauf exceptions »,
ce qui n'est pas une convention (US5).

**Le commentaire normatif de `etat_roles.dart:98-99`** — « Convention de l'app :
`ChangeNotifier` nu (ni Provider ni Riverpod), passé par constructeur et consommé
via `ListenableBuilder` » — énonce l'ancienne convention **comme normative** : il
DOIT énoncer la nouvelle (FR-042), et la constitution DOIT nommer **les deux moules**
(FR-040, incrément mineur 1.0.1 → 1.1.0), sinon le prochain cycle uniformisera (R13).
