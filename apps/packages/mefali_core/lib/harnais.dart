/// Harnais de test partagé des apps Mefali (FR-037).
///
/// Bibliothèque SÉPARÉE, volontairement HORS du barrel `mefali_core.dart` :
/// `import 'package:mefali_core/harnais.dart'` est un aveu lisible en revue — un
/// fichier de production qui l'importerait se verrait, et l'arbre de production
/// ne la référence jamais (tree-shaking). Même statut assumé que
/// `StockageJetonsMemoire` (barrière conventionnelle, pas mécanique — R11).
///
/// AUCUNE signature de ce fichier ne mentionne `flutter_test` ni `WidgetTester`
/// (contrainte 1) : sinon `flutter_test` deviendrait une dépendance de
/// PRODUCTION de `mefali_core`. L'appelant, resté dans `test/`, fait lui-même
/// `tester.pumpWidget(harnaisApp(...))` et `addTearDown(container.dispose)`.
/// AUCUNE ne renvoie `List<Override>` (contrainte 3 : `Override` non exporté par
/// flutter_riverpod 3.3.2 — l'annotation échoue, seule l'inférence tient) : les
/// overrides naissent et meurent DANS `conteneurMefali`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// `pasDeRetry` est RÉUTILISÉE (constante de PRODUCTION de mefali_core), pas
// déclarée ici. On surcharge les DÉPENDANCES (stockage, source, cache, url) et
// le transport ; JAMAIS le sujet (sessionProvider, clientSessionProvider).
import 'package:mefali_core/mefali_core.dart'
    show
        CacheConfig,
        ConfigDistante,
        InterceptorAutorisation,
        JetonsSession,
        SourceConfig,
        StockageJetonsMemoire,
        cacheConfigProvider,
        clientSessionProvider,
        pasDeRetry,
        sourceConfigProvider,
        stockageJetonsProvider,
        urlApiProvider;

/// Remplace les 6 copies de transport des fichiers de test (SC-011).
///
/// `repondre` rend un `FutureOr<ResponseBody>`, et NON un `ResponseBody` comme
/// les 6 copies actuelles : sans réponse RETENABLE, le test FR-014 serait vert
/// sans verrou — le 1er renouvellement aboutirait avant que la 2e requête
/// n'échoue (R7). Substitue l'ADAPTATEUR d'un `Dio` réel : aucun canal de
/// plateforme n'est simulé (FR-039).
class TransportFake implements HttpClientAdapter {
  /// Construit le transport sur la fonction qui décide de chaque réponse.
  TransportFake(this.repondre);

  /// Décide la réponse d'une requête. `FutureOr` : une réponse peut être
  /// RETENUE (par un `Completer`) pour prouver le partage du renouvellement.
  final FutureOr<ResponseBody> Function(RequestOptions options) repondre;

  /// Requêtes reçues, dans l'ordre — remplace les compteurs positionnels des
  /// tests d'origine (`transport.recues`, plus aucun `onRequest` manuel).
  final List<RequestOptions> recues = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recues.add(options);
    return repondre(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Réponse JSON prête à l'emploi — le corps sérialisé, les en-têtes que le
/// client GÉNÉRÉ sait lire. Remplace les 6 `_json` recopiés d'un test à l'autre.
ResponseBody reponseJson(Object corps, {int statut = 200}) =>
    ResponseBody.fromString(
      jsonEncode(corps),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Conteneur explicite pour les cas SANS arbre de widgets (FR-038).
///
/// Construit avec le constructeur PUBLIC de `ProviderContainer` — JAMAIS
/// `ProviderContainer.test()`, qui est `@visibleForTesting` et illégal depuis
/// `lib/` (contrainte 2). L'appelant DOIT faire `addTearDown(container.dispose)`
/// (règle de fichier n°4 : `UncontrolledProviderScope` ne dispose pas).
///
/// Surcharge PAR DÉFAUT `sourceConfig` et `cacheConfig` (FR-035, SC-004), pose
/// `retry: pasDeRetry` sur la portée (FR-002), et pose `transport` sur
/// `clientSession.dio.httpClientAdapter` APRÈS la pose de l'intercepteur
/// (FR-036, par construction). `sessionProvider`/`clientSessionProvider` ne sont
/// JAMAIS surchargés : on surcharge les DÉPENDANCES, jamais le sujet (R3).
///
ProviderContainer conteneurMefali({
  JetonsSession? jetons,
  TransportFake? transport,
  SourceConfig? source,
  CacheConfig? cache,
}) {
  final container = ProviderContainer(
    // FR-002 — retry NEUTRE sur TOUTE portée créée par le harnais (jamais réglé
    // par site). Le retry par défaut de Riverpod 3 (10 essais) ajouterait des
    // requêtes que ce cycle interdit, tests verts.
    retry: pasDeRetry,
    overrides: [
      // FR-012 — url factice : le cœur ne lit jamais l'environnement.
      urlApiProvider.overrideWithValue('http://test.invalid'),
      // On surcharge la DÉPENDANCE (stockage), JAMAIS le sujet (session).
      stockageJetonsProvider.overrideWith((ref) => StockageJetonsMemoire(jetons)),
      // Config surchargée PAR DÉFAUT (FR-035, SC-004) : sans ça, les 23 cas de
      // mefali_pro appelleraient le vrai SharedPreferences (canal de plateforme,
      // FR-039) + le réseau réel, et SC-004 se perdrait sans qu'aucune assertion
      // ne bronche. Ne MORD que grâce à la nouvelle signature de
      // demarrerServiceConfig (T017).
      sourceConfigProvider.overrideWith((ref) => source ?? _SourceConfigInerte()),
      // cacheConfig est un Raw<Future<CacheConfig>> : le harnais ENVELOPPE, le
      // paramètre reste un CacheConfig nu.
      cacheConfigProvider
          .overrideWith((ref) => Future.value(cache ?? _CacheConfigMemoire())),
    ],
  );
  if (transport != null) {
    // FR-036 — posé APRÈS la pose de l'intercepteur : `read(clientSessionProvider)`
    // exécute le `build` (qui ajoute l'intercepteur), PUIS on remplace
    // l'adaptateur. Ordre par construction, aucune discipline à tenir (R3).
    container.read(clientSessionProvider).dio.httpClientAdapter = transport;
  }
  return container;
}

/// Source de configuration INERTE — ne touche jamais le réseau. `recuperer`
/// lève, et `ServiceConfig.rafraichir` avale l'erreur : le service démarre sur
/// la valeur du cache (null par défaut). Double PAR DÉFAUT de `conteneurMefali`.
class _SourceConfigInerte implements SourceConfig {
  @override
  Future<ConfigDistante> recuperer(String zone) =>
      throw StateError('source de configuration inerte (harnais)');
}

/// Cache de configuration EN MÉMOIRE — vide par défaut, écriture sans effet.
/// Double PAR DÉFAUT de `conteneurMefali` (aucun canal de plateforme, FR-039).
class _CacheConfigMemoire implements CacheConfig {
  ConfigDistante? _config;

  @override
  Future<ConfigDistante?> lire(String zone) async => _config;

  @override
  Future<void> ecrire(ConfigDistante config) async => _config = config;
}

/// Monte l'app de test sous `UncontrolledProviderScope` — le conteneur PRÉEXISTE
/// toujours (cohérent avec l'amorçage impératif de R10), seule forme compatible
/// avec le préchargement HORS arbre des 3 cas `runAsync`.
///
/// ⚠ `UncontrolledProviderScope` NE DISPOSE PAS le conteneur : c'est sa raison
/// d'être — la destruction reste au test (`addTearDown(container.dispose)`).
Widget harnaisApp({
  required ProviderContainer container,
  required Widget home,
  Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates,
  Iterable<Locale>? supportedLocales,
}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr'),
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales ?? const [Locale('fr')],
        home: home,
      ),
    );

/// SC-005 — compte les intercepteurs d'autorisation de l'app par TYPE, JAMAIS
/// par position : les 4 intercepteurs que le client généré installe d'office
/// sont des `Interceptor`, donc `whereType<Interceptor>()` ne filtre RIEN et
/// `.last` est vert par accident. Ce cycle supprime ce geste (FR-013).
///
/// Les 4 intercepteurs que le client généré installe d'office sont des
/// `Interceptor` (donc `whereType<Interceptor>()` ne filtrerait RIEN) : on
/// compte par le TYPE exact `InterceptorAutorisation`.
int compteIntercepteursApp(Dio dio) =>
    dio.interceptors.whereType<InterceptorAutorisation>().length;
