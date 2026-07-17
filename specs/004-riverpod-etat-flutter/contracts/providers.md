# Contrat — Providers de `mefali_core` et des apps (le moule)

Interface du cycle 004 vis-à-vis de tous les cycles métier suivants (CRS, VND, CMD, DSP) :
**le moule qu'ils copient, et les gestes qui le cassent**. Story TRX-08 (P1, `docs/user-stories-v2.md`,
module « Transverse & infrastructure »). La constitution nomme Riverpod codegen comme LE pattern de
gestion d'état des apps Flutter par amendement MINOR 1.0.1 → 1.1.0 (FR-040, SC-012) — ce fichier en
est la forme exécutable. Toutes les signatures ci-dessous sont **vérifiées par exécution** sous
Flutter 3.44.6 / Dart 3.12.2 le 2026-07-17 ([research.md](research.md) R1) : elles compilent,
génèrent, et sortent `dart analyze` EXIT 0 sous les options strictes de `mefali_core`.

Ce contrat est un **refactor pur** : AUCUN comportement observable ne change (FR-001, FR-002).
Une signature qui améliorerait un comportement au passage a échoué, même verte (`spec.md:26`).

## Signature des 11 providers

```dart
// ─── mefali_core/lib/src/** (auth, config, adresses, appareils) ─────────────
// GÉNÉRÉ : chaque fichier annoté a son `.g.dart` COMMITÉ et gardé par un
// contrôle de dérive, sous la MÊME règle que `clients/dart` (constitution I,
// FR-029/FR-030/FR-031). NE JAMAIS éditer un `.g.dart` à la main.

/// L'URL de base de l'API. `throw` par DÉFAUT : le paquet cœur NE lit JAMAIS
/// l'environnement (FR-012) — la `const String _urlApi = String.fromEnvironment(…)`
/// reste dans le point d'entrée de chaque app et n'en bouge pas.
/// Un défaut `'http://localhost:8080'` ici ferait POSSÉDER au cœur la valeur
/// d'environnement que FR-012 lui interdit de connaître, et une app qui oublie
/// l'override partirait en silence sur l'appareil lui-même (CLAUDE.md §Commandes).
/// Le `throw` échoue au premier `read`, au lancement, avec le message qui dit
/// quoi faire (R3).
@Riverpod(keepAlive: true)
String urlApi(Ref ref) => throw UnimplementedError(
      'urlApiProvider doit être surchargé dans le point d\'entrée : '
      'ProviderContainer(overrides: [urlApiProvider.overrideWithValue(_urlApi)]).');

/// Le client HTTP PORTEUR d'`Authorization`, et le SEUL. Il pose l'unique
/// instance de `InterceptorAutorisation` de l'app (FR-013) et la retire à sa
/// destruction (FR-018).
/// `keepAlive` OBLIGATOIRE : sous `@riverpod` nu, une ré-évaluation empilerait
/// un 2ᵉ intercepteur ⇒ 2 renouvellements concurrents ⇒ jeton déjà tourné
/// rejoué ⇒ vol présumé ⇒ **session révoquée** (mode de panne n°1, `spec.md:146`).
/// NI `dio:` NI `interceptors:` : les délais 5000/3000 ms ne vivent QUE dans la
/// branche `dio ?? Dio(BaseOptions(…))` (`clients/dart/lib/src/api.dart:30-35`),
/// et passer `interceptors:` REMPLACE les 4 intercepteurs générés
/// (`api.dart:36-45`) au lieu de s'y ajouter — ce n'est PAS un point d'extension
/// (FR-017, R3).
@Riverpod(keepAlive: true)
MefaliApiClient clientSession(Ref ref) {
  final client = MefaliApiClient(basePathOverride: ref.watch(urlApiProvider));
  final intercepteur = InterceptorAutorisation(ref, client);
  client.dio.interceptors.add(intercepteur);
  ref.onDispose(() => client.dio.interceptors.remove(intercepteur));   // FR-018
  return client;
}

/// Le client HTTP qui NE porte JAMAIS d'`Authorization` (FR-017). Deux clients
/// distincts, JAMAIS un : fusionnés, celui de la configuration porterait un
/// en-tête qu'il n'a jamais porté (edge case `spec.md:156`).
/// La garantie ne repose sur AUCUNE assertion runtime — c'est une propriété du
/// graphe : seul `clientSession` pose un intercepteur (R3).
@Riverpod(keepAlive: true)
MefaliApiClient clientConfig(Ref ref) =>
    MefaliApiClient(basePathOverride: ref.watch(urlApiProvider));

/// Le stockage sécurisé des jetons. Surchargé en test par
/// `StockageJetonsMemoire` (FR-035) — AUCUN canal de plateforme n'est simulé,
/// on double la FONCTION, pas le canal (FR-039).
@Riverpod(keepAlive: true)
StockageJetons stockageJetons(Ref ref) => StockageJetonsSecurise();

/// La session d'authentification. `keepAlive` : elle naît au lancement et vit
/// tout le processus (FR-019).
/// NE dépend PAS du client : le renouvellement est dans l'intercepteur, qui
/// capture son `_client`. Le `ref.watch(clientSessionProvider)` que l'idiome
/// suggère est une arête INUTILE — et une arête inutile ici est une
/// ré-évaluation de trop (R3).
@Riverpod(keepAlive: true)
class Session extends _$Session {
  /// Rend l'état INITIAL et NE charge RIEN : `charger()` reste déclenché
  /// impérativement depuis `RacineAuth.initState` (`racine_auth.dart:59`).
  /// `AsyncNotifier` est INTERDIT ici : son `build()` démarre en `AsyncLoading`
  /// et y RETOURNE à chaque `refresh`/`invalidate` ⇒ l'écran de démarrage
  /// réapparaîtrait en plein parcours — FR-022 l'interdit nommément (R6).
  @override
  EtatSession build() => const EtatSession.initiale();

  /// Traduction FIDÈLE de `ChangeNotifier` : `notifyListeners()` émet TOUJOURS,
  /// sans comparer, et `RacineAuth` rebâtit à chaque appel (`racine_auth.dart:82`,
  /// `ListenableBuilder`, sans filtre). Le défaut v3 (« all providers now use
  /// `==` to filter updates ») filtrerait les écritures égales et rendrait
  /// `expect(emissions, 1)` PLUS FAIBLE que l'assertion d'origine — exactement
  /// le mode de panne que FR-004 nomme. NE PAS « optimiser » (R6).
  @override
  bool updateShouldNotify(EtatSession previous, EtatSession next) => true;

  Future<void> charger() async { /* … */ }
  Future<void> ouvrir(JetonsSession jetons) async { /* … */ }
  Future<void> fermer() async { /* … */ }
}

/// État de session. Classe IMMUABLE, volontairement SANS `operator ==` — et
/// `updateShouldNotify => true` par-dessus : on prend LES DEUX. Une classe sans
/// `==` marche par ACCIDENT ; le jour où quelqu'un ajoute `Equatable`/`freezed`,
/// les émissions fusionnent et `expect(emissions, 1)` reste vert en prouvant
/// moins (R6).
@immutable
class EtatSession {
  const EtatSession({required this.charge, this.jetons});
  const EtatSession.initiale() : charge = false, jetons = null;

  /// `true` une fois le stockage relu. NE REDEVIENT JAMAIS `false` (FR-022).
  /// `charge` DOIT faire partie de la VALEUR, comme `_charge` est un champ
  /// aujourd'hui (`session_auth.dart:28`) : sur un état `JetonsSession?` nu,
  /// `charger()` sur un stockage vide ferait `null → null` ⇒ AUCUNE émission
  /// ⇒ `RacineAuth` ne quitterait JAMAIS l'écran de démarrage (R6).
  final bool charge;
  final JetonsSession? jetons;

  bool get connecte => jetons != null;
  String? get acces => jetons?.acces;
  String? get rafraichissement => jetons?.rafraichissement;
}

/// L'intercepteur d'autorisation — PUBLIC (il était `_InterceptorAutorisation`),
/// sans quoi le harnais ne peut le compter PAR TYPE et SC-005 retomberait sur le
/// `.last` positionnel que ce cycle supprime (R11).
/// Il détient le `Ref` de `clientSession` et le client — JAMAIS le notificateur :
/// un `this` capturé laisserait un `Session` disposé joignable depuis le dio ;
/// un `Ref` résout toujours l'instance COURANTE (R3).
class InterceptorAutorisation extends Interceptor {
  InterceptorAutorisation(this._ref, this._client);
  final Ref _ref;
  final MefaliApiClient _client;

  /// Le verrou de renouvellement. INCHANGÉ, zéro ligne modifiée
  /// (`session_auth.dart:88, :111, :147`) : FR-013 garantit une instance
  /// d'intercepteur par client ⇒ l'unicité du verrou en est le COROLLAIRE, pas
  /// une exigence séparée. Le remonter dans `state` est interdit par FR-001
  /// (`RacineAuth` rebâtirait à chaque début/fin de renouvellement, alors
  /// qu'aujourd'hui un renouvellement est totalement invisible de l'UI) (R7).
  Future<bool>? _enCours;

  /// On lit l'ÉTAT (`EtatSession`, classe nue) et on appelle des MÉTHODES
  /// (`.notifier`). Exposer `acces`/`rafraichissement` en getters de notificateur
  /// → `avoid_public_notifier_properties` **error** ; lire `_session.state`
  /// → `invalid_use_of_protected_member` + `invalid_use_of_visible_for_testing_member`
  /// (diagnostics CŒUR, hors de portée de toute config de plugin). Les deux
  /// vérifiés par exécution ; ce montage est le SEUL qui passe `dart analyze` (R3).
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    final acces = _ref.read(sessionProvider).acces;
    if (acces != null) o.headers['Authorization'] = 'Bearer $acces';
    h.next(o);
  }
  // onError : `_ref.read(sessionProvider.notifier).ouvrir/fermer`, anti-boucle et
  // rejeu unique INCHANGÉS (FR-015, FR-016).
}

/// La source distante de configuration. Surchargée en test (FR-035).
@Riverpod(keepAlive: true)
SourceConfig sourceConfig(Ref ref) => SourceConfigApi(ref.watch(clientConfigProvider));

/// Le cache local de configuration (shared_preferences). Surchargé en test —
/// le canal de plateforme n'est pas simulé, le double remplace la fonction
/// (FR-035, FR-039).
/// `Raw<Future<…>>` et NON `CacheConfig` nu : `CacheConfigPreferences(this._prefs)`
/// exige un `SharedPreferences` (`cache_config.dart:16-20`) qui ne s'obtient que
/// par `await SharedPreferences.getInstance()` — **asynchrone**. Un
/// `Provider<CacheConfig>` synchrone NE COMPILE PAS. `Raw` et non `FutureProvider` :
/// même doctrine que `serviceConfig` — aucun `AsyncValue`, aucun retry (R5, R10).
@Riverpod(keepAlive: true)
Raw<Future<CacheConfig>> cacheConfig(Ref ref) =>
    SharedPreferences.getInstance().then(CacheConfigPreferences.new);

/// FR-021 — le provider HÉBERGE le service, il ne l'OBSERVE JAMAIS : il expose
/// le SERVICE (un Future dessus), jamais une valeur observée.
/// `Raw` rend un `Provider` de Future : PAS de `FutureProvider`, donc AUCUN
/// `AsyncValue` à émettre ⇒ FR-021 devient IMPOSSIBLE à violer, et non tenu par
/// la discipline `read` vs `watch` ; et AUCUN retry automatique ⇒ un échec ne
/// refabriquerait pas un `ServiceConfig`, donc pas un 2ᵉ Timer (FR-019).
/// Le type reste `Future<ServiceConfig>`, EXACTEMENT `RacineAuth.config`
/// (`racine_auth.dart:38`) et `RouteurRoles.config` (`routeur_roles.dart:29`) :
/// portage relisible à l'œil — le seul critère qui vaille quand la couverture
/// est nulle (`spec.md:274`, R5).
/// Il consomme `sourceConfig` ET `cacheConfig` : c'est la seule forme qui tienne
/// FR-035. La signature d'aujourd'hui — `demarrerServiceConfig({String? urlApi})`,
/// qui construit ELLE-MÊME `SourceConfigApi(MefaliApiClient(…))` et
/// `CacheConfigPreferences(prefs)` (`amorce_config.dart:14-22`) — rendrait les
/// surcharges de `sourceConfig`/`cacheConfig` SANS EFFET : les 23 cas de
/// `mefali_pro` appelleraient quand même le vrai canal de plateforme et le vrai
/// réseau, et SC-004 se perdrait SANS QU'AUCUNE ASSERTION NE BRONCHE. Elle ferait
/// aussi de FR-017 une exigence nominale (le trafic de config passerait par le
/// client construit dans `demarrerServiceConfig`, pas par `clientConfigProvider`)
/// et laisserait `clientConfig`, `sourceConfig`, `cacheConfig` ORPHELINS — rien ne
/// les lirait. D'où le **changement de signature de production** ci-dessous : c'est
/// l'inversion d'injection que le cycle demande (FR-010, FR-035), pas un détail de
/// plume. `urlApi` n'y descend plus : il descend dans `clientConfigProvider`, que
/// `sourceConfig` watch déjà.
///
/// ```dart
/// // amorce_config.dart — la fonction REÇOIT source et cache au lieu de les construire.
/// Future<ServiceConfig> demarrerServiceConfig({
///   required SourceConfig source,
///   required CacheConfig cache,
/// }) async {
///   final service = ServiceConfig(source: source, cache: cache);
///   await service.demarrer();
///   return service;
/// }
/// ```
///
/// La fonction du provider reste SYNCHRONE et rend un `Raw` : `cacheConfig` est un
/// `Raw<Future<CacheConfig>>` (voir ci-dessus), on le CHAÎNE par `.then` au lieu de
/// l'`await`er.
/// Deux raisons : les deux `ref.watch` doivent être évalués AVANT tout point de
/// suspension (un `watch` après un `await` est une arête non enregistrée) ; et un
/// corps `async` rendrait au générateur un `Future` à interpréter — le `Raw` doit
/// rester le seul niveau de Future, sans quoi on retombe sur l'`AsyncValue` que
/// FR-021 interdit (R5).
@Riverpod(keepAlive: true)
Raw<Future<ServiceConfig>> serviceConfig(Ref ref) {
  final source = ref.watch(sourceConfigProvider);
  final futurCache = ref.watch(cacheConfigProvider);
  final futur = futurCache.then(
      (cache) => demarrerServiceConfig(source: source, cache: cache));
  ref.onDispose(() => futur.then((s) => s.arreter()).ignore());   // FR-018
  return futur;
}

/// La liste des adresses. `@riverpod` nu (autoDispose) : écran de liste, aucun
/// état à faire survivre.
@riverpod
class MesAdresses extends _$MesAdresses {
  @override
  Future<List<Adresse>> build() => _charger();

  /// FR-023 — le squelette DOIT réapparaître, comme le
  /// `setState(() => _adresses = _charger())` d'avant (`liste_adresses.dart:47-49`),
  /// qui repartait en `ConnectionState.waiting`.
  /// `skipLoadingOnRefresh = true` est le DÉFAUT du framework
  /// (`riverpod-3.3.2/lib/src/core/async_value.dart:198,244,277`) : `ref.invalidate`
  /// + `.when(skipLoadingOnRefresh: false)` marcherait, mais ferait porter FR-023
  /// par un booléen à répéter à CHAQUE site d'appel de `.when()`, dont le défaut
  /// fait exactement le contraire. Un site oublié ⇒ le squelette cesse
  /// d'apparaître ⇒ changement visible ⇒ AUCUN des 86 cas ne le rattrape.
  /// L'intention vit ici, à un seul endroit ; `.when()` reste AUX DÉFAUTS dans
  /// tout le dépôt (R9).
  Future<void> recharger() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_charger);
  }
}

/// La liste des appareils/sessions. `@riverpod` nu (autoDispose) ; `recharger()`
/// identique à `MesAdresses` (FR-023, `ecran_appareils.dart:42`).
@riverpod
class MesSessions extends _$MesSessions { /* … */ }

// ─── mefali_pro/lib/roles/ ─────────────────────────────────────────────────

/// L'état des rôles. `@riverpod` NU (autoDispose) — le DÉFAUT du générateur est
/// ici le bon réglage, et c'est le SEUL provider du cycle dans ce cas.
/// `keepAlive` ici serait une RÉGRESSION DE SÉCURITÉ silencieuse : les rôles
/// survivraient au changement de compte (mode de panne n°3, `spec.md:148`).
@riverpod
class EtatRoles extends _$EtatRoles {
  @override
  EtatRolesData build() {
    /// FR-020/SC-010 — l'arête GRAVÉE. `autoDispose` seul NE SUFFIT PAS : la
    /// destruction est PLANIFIÉE et non synchrone, et Riverpod 3 met en PAUSE les
    /// providers hors-champ (`TickerMode`) — un provider en pause n'est PAS
    /// détruit. Qu'un futur cycle ajoute un `ref.listen` ou un provider
    /// `keepAlive` qui lise les rôles, et l'état survit. Le `watch` grave :
    /// session fermée ⇒ invalidation ⇒ `build()` rejoué ⇒ état vide AVANT tout
    /// rendu, même si quelqu'un met `keepAlive: true` demain.
    /// `.select` n'est PAS une optimisation, c'est une CORRECTION DE BUG :
    /// `ref.watch(sessionProvider)` nu rechargerait les rôles à chaque rotation
    /// de jeton (`ouvrir()` est appelé par l'intercepteur) ⇒ requête ajoutée
    /// (FR-002) + `ChargementPro` en plein parcours (FR-001), sur un chemin que
    /// seul un 401 déclenche — donc JAMAIS en test (R4, R8).
    ref.watch(sessionProvider.select((e) => e.connecte));

    // `build()` NE charge RIEN : le chargement est déclenché par le routeur
    // (`routeur_roles.dart:50`), et `charger()` est rejouable SANS que `build()`
    // retourne — c'est ce qui laisse `actif` survivre à un rechargement
    // (US4 scénario 3, `spec.md:99`, `routeur_roles_test.dart:295-322`). La mémoire
    // est dans `state`, la destruction est dans `build()` (R8).
    return const EtatRolesData();
  }

  /// Les rôles sont l'INVERSE de la session : `charge` est NON MONOTONE
  /// (`etat_roles.dart:156-158` le remet à `false` ET notifie ⇒ `ChargementPro`
  /// réapparaît). `AsyncValue` est INTERDIT ici : il fusionnerait `charge` et
  /// `enErreur`, qui sont ORTHOGONAUX — sur erreur, `etat_roles.dart:189-192`
  /// produit `charge: true` ET `enErreur: true`, attributions CONSERVÉES (R6).
  @override
  bool updateShouldNotify(EtatRolesData p, EtatRolesData n) => true;

  Future<void> charger() async { /* corps identique à etat_roles.dart:155-194 */ }
  void basculer(RolePro role) {
    /* ne parle NI au réseau NI à la session (etat_roles.dart:196-204) */
  }
}
```

**Le graphe est ACYCLIQUE**, et ses feuilles sont TROIS sources indépendantes : `urlApi` (lue par
`clientSession` ET par `clientConfig → sourceConfig → serviceConfig`), `stockageJetons` (lue par
`session`), `cacheConfig` (lue par `serviceConfig`). Les deux CHAÎNES — authentification
(`clientSession`, `session`) et configuration (`serviceConfig`) — ne se touchent QUE par la feuille
`urlApi` : aucune ne dépend de l'état de l'autre, et c'est ce qui tient FR-017 (le trafic de config
ne peut pas porter d'`Authorization` : il passe par `clientConfig`, qui ne pose aucun intercepteur).
L'arête `intercepteur → session` n'existe QU'AU RUNTIME, hors du graphe (R3). Sanctionné en amont : [riverpod#2107](https://github.com/rrousselGit/riverpod/discussions/2107)
— container global / get_it / event bus = anti-pattern explicite.

## Hors moule — et c'est la moitié du contrat

| Symbole | Statut | Pourquoi il NE devient PAS un provider |
|---|---|---|
| `modeDevOtp` | **`const`** — FR-025 | Providerifié, il cesse d'être une constante de compilation, l'élimination de branche morte meurt, le code de relecture entre dans le binaire de RELEASE — **et le test qui le protège reste vert** (`spec.md:152`). |
| `lireCodeDevReseau(Dio)`, `choisirPiece`, `jouerNote`, `capturerNote` | **paramètres de constructeur** — FR-011 | Ce cycle migre l'ÉTAT, pas les callbacks. Tout ou rien : AUCUNE des quatre ne bascule (clarification du 2026-07-17). |
| `versionConsentement`, `transportsActifs` | **paramètres / instantanés** — FR-021 | Ils SONT l'instantané. Lus par `ref.read`, **JAMAIS `ref.watch`**, à l'entrée de l'écran (R5). |
| `_cleIdempotence` (`formulaire_dossier.dart:95`), `_vehicules` (`:85`), `_piece`, contrôleurs, focus, compte à rebours 60 s | **état strictement local** — FR-009, FR-026 | `FormulaireDossierCoursier` reste **`ConsumerStatefulWidget`** : le rendre sans état est le SEUL chemin par lequel un refactor « pur » ferait sortir **R14** de son isolement (`spec.md:153`). |
| `RouteurRoles.etat` (`routeur_roles.dart:20, :37, :44, :73`) | **SUPPRIMÉ** — FR-043 | Couche d'injection de test câblée NULLE PART : code mort. Porter du code mort dans le nouveau moule le graverait. |
| `SessionAuth.client`, `SessionAuth.stockage`, `EtatRoles.session` | **SUPPRIMÉS** | Champs publics remplacés par des providers — c'est le découplage demandé (R3). |

## Garanties contractuelles

| Garantie | Mécanisme | FR / SC | Ce qui la casserait |
|---|---|---|---|
| **Exactement 1** intercepteur sur `clientSession`, **0** sur `clientConfig`, sur toute la vie du processus | L'intercepteur est posé par `clientSession`, qui ne dépend d'AUCUN état mutable : une ré-évaluation de `sessionProvider` ne touche JAMAIS au dio. **Structurel, pas testé.** | FR-013, FR-017, SC-005 | `@riverpod` nu sur `clientSession` ; `ref.watch(clientSessionProvider)` dans `Session` ; surcharger `sessionProvider` dans un `ProviderScope` IMBRIQUÉ (2 notifiers sur le même dio — aucune construction Riverpod ne l'empêche). |
| L'intercepteur est **retiré** à la destruction de son poseur | `ref.onDispose(() => …interceptors.remove(intercepteur))` — `List.remove` compare par IDENTITÉ, donc ORDRE-INDÉPENDANT. **JAMAIS `removeWhere((i) => i is InterceptorAutorisation)`** : dans l'ordre défavorable, il en supprimerait deux → 0 → l'app perd `Authorization` en silence. | FR-018, SC-005 | Omettre le `onDispose` (le cas `invalidate` échoue — c'est son travail). |
| **1 seul** renouvellement pour N requêtes concurrentes expirées, toutes rejouées une fois | `_enCours ??=` + `finally` dans l'intercepteur, INCHANGÉ. | FR-014, FR-015, SC-005 | `QueuedInterceptor` — il sérialise les `onError` là où notre modèle laisse les N prendre leur 401 EN PARALLÈLE et PARTAGER un refresh : même comptage, **fil réseau et ordonnancement différents** ⇒ FR-002 violé (R7). |
| Session et configuration vivent **tout le processus** ; le rafraîchissement horaire ne s'arrête NI ne redémarre | `@Riverpod(keepAlive: true)` ×8 + conteneur JAMAIS détruit (c'est la SPÉCIFICATION, pas une négligence) | FR-019, SC-009 | `@riverpod` nu (le DÉFAUT du générateur) ; `FutureProvider<ServiceConfig>` (retry ⇒ nouveau service ⇒ **nouveau Timer**). |
| **0** donnée d'un compte visible sous un autre | `@riverpod` nu **+** `ref.watch(sessionProvider.select((e) => e.connecte))` | FR-020, SC-010 | `keepAlive` sur `etatRoles` ; `ref.invalidate(etatRolesProvider)` dans `fermer()` (inverse la dépendance — `mefali_core` connaîtrait un provider de `mefali_pro` — et un `invalidate` s'oublie, un `watch` est une arête). |
| **0** rebuild d'écran sur rafraîchissement de configuration | `Provider<Raw<Future<ServiceConfig>>>` : **rien à émettre** | FR-021, SC-009 | `FutureProvider` — le plus idiomatique et le plus faux. |
| L'état chargé de la session ne redevient JAMAIS « en cours » ; un rechargement des rôles réaffiche bien l'écran de chargement | Deux sémantiques OPPOSÉES tenues par deux `Notifier` à état nu — **JAMAIS `AsyncNotifier`** pour ces deux-là | FR-022 | Uniformiser derrière `AsyncValue` : le geste que l'idiome invite, et il détruit les DEUX sémantiques d'un coup. |
| Le squelette réapparaît à chaque rechargement de liste | `state = const AsyncLoading()` EXPLICITE dans `recharger()` ; `.when()` reste aux défauts partout | FR-023, SC-003 | S'en remettre à `invalidate` + `skipLoadingOnRefresh` (défaut = `true`, l'inverse du besoin). |
| **0** requête ajoutée, supprimée ou déplacée | Amorçage impératif depuis `main()` + `retry: pasDeRetry` sur TOUTE portée | FR-002, FR-024, SC-004 | Amorçage paresseux ; retry laissé au défaut (voir geste n°2). |
| L'URL d'API reste une constante de compilation du POINT D'ENTRÉE | `urlApiProvider` qui `throw` + `overrideWithValue(_urlApi)` par app | FR-012 | Un défaut dans le cœur — même `'http://localhost:8080'`, littéralement celle des deux `main.dart`. |
| **R14 reste exactement où le cycle l'a trouvé** | `FormulaireDossierCoursier` reste `ConsumerStatefulWidget` ; `_cleIdempotence` reste un champ de `State` | FR-026 | Le rendre sans état. Le cas `formulaire_dossier_test.dart:192-229` est le GARDE-FOU : s'il tombe, on n'a pas un test à réparer, **on a un périmètre violé** (R11). |

## Les 5 gestes par défaut qui cassent le cycle EN SILENCE

Chacun est le geste que l'idiome Riverpod invite, chacun laisse **les tests verts**, et
**AUCUN outil ne les attrape** — les 15 règles de `riverpod_lint 3.1.4` sont énumérées en R2 et
aucune ne couvre ce qui suit (R2, R13).

**1. `@riverpod` nu sur la session, la configuration ou les clients.**
L'idiome l'invite : `@riverpod` est la forme courte, celle de toute la documentation, et
`keepAlive: true` a l'air d'une optimisation qu'on ajoute « si besoin ». C'est l'inverse : le défaut
du générateur est `keepAlive = false` (`riverpod_annotation-4.0.3/lib/src/riverpod_annotation.dart:24`
— vérifié aussi dans le `.g.dart` : `isAutoDispose: true`). Ce qui casse : la session et la config
naissent au lancement et vivent tout le processus (FR-019) ; détruites dès le dernier auditeur parti,
soit le rafraîchissement horaire **s'arrête et redémarre** — comportement qui n'existe pas aujourd'hui
— soit chaque souscription relit le cache et **redemande la configuration au serveur** (FR-002) ;
et sur `clientSession`, une seconde évaluation empile un **2ᵉ intercepteur** ⇒ session révoquée
(mode de panne n°1 et n°2, `spec.md:146-147`). **Aucun lint** : `only_use_keep_alive_inside_keep_alive`
porte sur `KeepAliveLink`, pas sur le sens des dépendances ; la règle
`avoid_keep_alive_dependency_inside_auto_dispose` **N'EXISTE PAS** — deux rapports de recherche
l'avaient inventée (R2). L'opposition centrale du cycle n'est tenue que par les tests et la revue.

**2. Laisser `retry` au défaut.**
L'idiome l'invite en n'en parlant pas : on ne configure pas ce dont on ignore l'existence, et le
`retry: null` que le générateur écrit signifie **« hérite »**, pas « désactivé ». Riverpod 3
**réessaie les providers en échec PAR DÉFAUT** — vérifié dans le code résolu :
`element.dart:764` → `origin.retry ?? container.retry ?? ProviderContainer.defaultRetry` ;
`provider_container.dart:940-954` → `maxRetries = 10`, `minDelay = 200ms`, `maxDelay = 6400ms`, et
`if (error is ProviderException || error is Error) return null` ⇒ **toutes les `Exception` sont
réessayées, `DioException` compris**. Ce qui casse : **jusqu'à 10 requêtes en backoff** sur un
provider en échec, alors qu'AUCUNE requête n'était rejouée avant ce cycle — FR-002/SC-004 violés
**sans une seule ligne de code écrite**. Et **les tests restent verts** : `ServiceConfig.rafraichir`
avale ses erreurs (`service_config.dart:64`), donc les cas de configuration ne bronchent pas pendant
qu'adresses, rôles et appareils dérivent. **Aucun lint** ; aucune assertion existante ne compte les
requêtes. Parade contractuelle : `retry: pasDeRetry` sur **TOUTE** création de portée — les 2 points
d'entrée **et** le harnais (R10, R11) — jamais un réglage par site. ⚠ La doc se contredit :
`riverpod_annotation.dart:45` dit « unlimited retries », le code dit `maxRetries = 10` — **le code
fait foi**.

**3. `ref.watch(sessionProvider)` nu au lieu de `.select((e) => e.connecte)`.**
L'idiome l'invite : `.select` est présenté partout comme une optimisation de performance, donc
facultative. Ici c'est une **correction de bug**. L'intercepteur appelle `ouvrir()` à **chaque
rotation de jeton** ⇒ nouvel `EtatSession` ⇒ `etatRoles.build()` rejoué ⇒ les rôles se
**rechargent à chaque renouvellement silencieux** ⇒ requête ajoutée (FR-002) **et** `ChargementPro`
en plein parcours (FR-001). Le chemin n'est déclenché que par un 401 : **jamais en test**, jamais en
développement, seulement chez l'utilisateur après expiration. **Aucun lint** ne distingue un `watch`
d'un `select`. Parade : le cas « rotation de jeton ⇒ 0 rechargement des rôles », écrit et vert dans
la sonde (R4, R11).

**4. `AsyncNotifier` pour la session.**
L'idiome l'invite frontalement : la session est un chargement asynchrone, `AsyncNotifier` est LA
forme pour ça, et `AsyncValue` supprime le champ `charge` qui a l'air redondant. Ce qui casse, deux
fois : (a) `AsyncNotifier.build()` **démarre en `AsyncLoading`** et y **retourne** à chaque
`refresh`/`invalidate`/retry ⇒ **l'écran de démarrage réapparaît en plein parcours** — FR-022
l'interdit nommément ; (b) `charger()` migrerait dans `build()` ⇒ le premier rendu deviendrait
contingent d'un `Future`, alors que `racine_auth.dart:12-17` documente l'inverse (« bloquer le
lancement sur une lecture de Keystore ferait clignoter un écran blanc ») ⇒ FR-024. Variante du même
geste : remplacer `EtatSession` par un `record (bool, JetonsSession?)` — égalité structurelle, et
`JetonsSession` implémente `==` (`stockage_jetons.dart:18-24`) ⇒ un `ouvrir()` aux mêmes jetons
émettrait **0** au lieu de 1, et le test d'émissions **resterait vert en prouvant moins** (R6).
**Aucun lint** : `notifier_extends` vérifie qu'on étend le bon `_$`, pas qu'on a choisi la bonne
famille.

**5. `keepAlive` sur les rôles.**
L'idiome l'invite comme un confort : recharger les rôles à chaque entrée d'écran « coûte une
requête », donc on les garde. Se tromper sur la session coûte des requêtes ; se tromper ici est une
**régression de sécurité silencieuse** — l'état survit au changement de compte et les rôles du compte
précédent s'affichent sous l'autre (FR-020, SC-010, mode de panne n°3 `spec.md:148`). Les deux
réglages sont **opposés et aucun défaut ne convient aux deux** ; c'est précisément pourquoi le
`ref.watch(session.select(…))` est OBLIGATOIRE **en plus** d'`autoDispose` : il rend le geste
inoffensif même si quelqu'un met `keepAlive: true` demain. **Aucun lint**, et le test de
non-régression ne le voit qu'en émulateur (SC-010, R4).

## Règles de conception verrouillées

Opposables en revue. Toute violation est un échec du cycle, pas une préférence.

1. **`@Riverpod(keepAlive: true)` est EXPLICITE sur les 8 porteurs de processus** — `urlApi`,
   `clientSession`, `clientConfig`, `stockageJetons`, `session`, `sourceConfig`, `cacheConfig`,
   `serviceConfig`. `sourceConfig` et `cacheConfig` en sont : ce sont les dépendances d'un service
   `keepAlive` ; en `autoDispose` elles seraient reconstruites sous lui. `@riverpod` nu est RÉSERVÉ à
   `etatRoles`, `mesAdresses`, `mesSessions` — soit ×3. La durée de vie est un **comportement**,
   jamais un réglage (FR-019, FR-020, `spec.md:248`). Le grep de contrôle de SC-010 renvoie **8**.
2. **On surcharge les DÉPENDANCES, JAMAIS le sujet.** `sessionProvider` et `clientSessionProvider`
   ne sont JAMAIS surchargés :
   `clientSessionProvider.overrideWith((ref) => MefaliApiClient(dio: dioFactice))` — le geste que
   l'idiome invite — est **doublement destructeur** : il perd l'intercepteur (le test ne prouve plus
   rien **tout en restant vert**) ET les timeouts 5000/3000 ms (FR-036, R11).
3. **Les surcharges vivent dans le conteneur RACINE du test.** Un `ProviderScope` imbriqué qui
   surcharge `sessionProvider` pose deux notifiers sur le même dio ⇒ **2 intercepteurs**. Aucune
   construction Riverpod ne l'empêche : **c'est une règle à écrire, pas un bug à corriger** (FR-013).
4. **`retry: pasDeRetry` sur toute création de portée** — 2 points d'entrée + harnais. Constante de
   `mefali_core`, réutilisée par le harnais, jamais un réglage par site (FR-002, geste n°2).
   Elle est **publique** et vit dans une bibliothèque de **production** de `mefali_core`, à côté des
   providers et exportée par le barrel : un top-level privé est privé à SA bibliothèque, donc
   redéclaré dans chaque `main.dart` — soit exactement « un réglage par site », que la règle interdit ;
   et la déclarer dans le harnais forcerait les 2 `main.dart` de production à importer le harnais,
   ce que le tree-shaking de R11 exclut.
5. **Deux moules, nommés, et la constitution les nomme aussi** (FR-040) : `Notifier<Etat…>` pour les
   porteurs à sémantique propre (session, rôles) ; `AsyncNotifier` pour les chargements de liste
   (adresses, appareils). Sans cette règle écrite, le prochain cycle **uniformisera** derrière
   `AsyncValue` et détruira FR-022 d'un geste.
6. **`updateShouldNotify => true` explicite sur tout `Notifier` traduit d'un `ChangeNotifier`** — la
   v3 filtre par `==` (« all providers now use `==` to filter updates »,
   [#4310](https://github.com/rrousselGit/riverpod/issues/4310)) ; une classe sans `==` marche par
   accident (FR-003, FR-004).
7. **`.select` sur toute dépendance à `sessionProvider`.** Un `watch` nu sur la session est un bug de
   fil réseau, pas une inefficacité (FR-002, geste n°3).
8. **AUCUN provider n'est lu par `ref.watch` pour la configuration** : `ref.read` seulement, à
   l'entrée de l'écran. L'instantané EST le comportement gelé (FR-021).
9. **Le `.g.dart` est GÉNÉRÉ, commité, et JAMAIS édité** — même règle que `clients/dart`
   (constitution I, FR-029). `dart run build_runner build` **nu** : `--delete-conflicting-outputs`
   est SUPPRIMÉ de build_runner 2.15.x (R2).
10. **`dart analyze`, JAMAIS `flutter analyze`.** Vérifié, même faute, même `analysis_options.yaml` :
    `dart analyze` → **EXIT 2**, `flutter analyze` → **EXIT 0 / « No issues found! »**. La doc
    officielle (`analysis_server_plugin/doc/using_plugins.md`) affirme le contraire : **elle est
    fausse sur Flutter 3.44.6**. Laisser `flutter analyze` en CI (`apps.yml:36`), c'est faire de
    `riverpod_lint` un **no-op décoratif** — la CI reste verte, FR-033/SC-006 sont réputés tenus, et
    rien n'est vérifié (R2, R12).
11. **Un provider par porteur d'état, l'état local reste local** (FR-007, FR-009). Un cycle suivant
    qui introduit un porteur d'état introduit un provider généré ; un contrôleur de saisie, un focus,
    un compte à rebours ergonomique, un brouillon non soumis ou une ressource native liée au widget
    **ne migrent PAS** — et `grep addListener` donne 2 hits dont `ecran_otp.dart:67`
    (`_controleur.addListener`) qui **DOIT rester** : SC-001 compte les `ListenableBuilder`, pas les
    listeners de contrôleurs (R13).
