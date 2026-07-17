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

// Types des paramètres de `conteneurMefali`. `pasDeRetry`, `StockageJetonsMemoire`
// et les providers surchargés sont ajoutés à ce `show` quand le corps naît
// (session US2 T012, config US3 T020) — jamais un `show` d'un symbole inutilisé.
import 'package:mefali_core/mefali_core.dart'
    show CacheConfig, JetonsSession, SourceConfig;

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
/// COMPLÉTÉ story par story : la partie session naît en US2 (T012), la partie
/// configuration en US3 (T020) — les deux quand leurs providers existent.
ProviderContainer conteneurMefali({
  JetonsSession? jetons,
  TransportFake? transport,
  SourceConfig? source,
  CacheConfig? cache,
}) =>
    throw UnimplementedError(
      'conteneurMefali : complété story par story '
      '(dépendances session en US2 T012, configuration en US3 T020).',
    );

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
/// COMPLÉTÉ en US2 (T012), quand `InterceptorAutorisation` devient public :
/// `dio.interceptors.whereType<InterceptorAutorisation>().length`.
int compteIntercepteursApp(Dio dio) => throw UnimplementedError(
      'compteIntercepteursApp : complété en US2 (T012), '
      'quand InterceptorAutorisation devient public.',
    );
