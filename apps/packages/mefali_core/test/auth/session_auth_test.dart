import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Session montée sur un stockage MÉMOIRE : `flutter_secure_storage` passe par
/// un canal de plateforme, absent d'un test de widget.
SessionAuth _session([JetonsSession? jetons]) => SessionAuth(
      stockage: StockageJetonsMemoire(jetons),
      client: MefaliApiClient(basePathOverride: 'http://test.invalid'),
    );

Widget _monter(SessionAuth session) => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: RacineAuth(
        session: session,
        nomAppareil: 'Test',
        demarrage: const Scaffold(body: Text('démarrage')),
        accueil: (_) => AccueilProvisoire(session: session),
      ),
    );

void main() {
  group('SessionAuth', () {
    test('naît déconnectée et non chargée', () {
      final session = _session();
      expect(session.connecte, isFalse);
      expect(session.charge, isFalse);
      expect(session.acces, isNull);
    });

    test('relit les jetons conservés au démarrage', () async {
      final session = _session(
        const JetonsSession(acces: 'jwt', rafraichissement: 'opaque'),
      );
      await session.charger();

      expect(session.charge, isTrue);
      expect(session.connecte, isTrue);
      expect(session.acces, 'jwt');
      expect(session.rafraichissement, 'opaque');
    });

    test('ouvrir persiste les jetons et notifie', () async {
      final session = _session();
      var notifications = 0;
      session.addListener(() => notifications++);

      await session.ouvrir(
        const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );

      expect(session.connecte, isTrue);
      expect(notifications, 1);
      expect(
        await session.stockage.lire(),
        const JetonsSession(acces: 'a', rafraichissement: 'r'),
        reason: 'relancer l\'app doit retrouver la session',
      );
    });

    test('fermer efface le stockage — un jeton oublié survivrait à jamais',
        () async {
      final session = _session(
        const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      await session.charger();
      await session.fermer();

      expect(session.connecte, isFalse);
      expect(await session.stockage.lire(), isNull);
    });

    test('pose Authorization: Bearer sur les requêtes, et rien sans session',
        () async {
      final session = _session();
      final options = RequestOptions(path: '/moi');
      final intercepteur = session.client.dio.interceptors
          .whereType<Interceptor>()
          .last;

      intercepteur.onRequest(options, RequestInterceptorHandler());
      expect(options.headers['Authorization'], isNull, reason: 'déconnecté');

      await session.ouvrir(
        const JetonsSession(acces: 'jwt-de-test', rafraichissement: 'r'),
      );
      final options2 = RequestOptions(path: '/moi');
      intercepteur.onRequest(options2, RequestInterceptorHandler());
      expect(options2.headers['Authorization'], 'Bearer jwt-de-test');
    });
  });

  group('RacineAuth', () {
    testWidgets('démarrage → authentification quand aucune session',
        (tester) async {
      await tester.pumpWidget(_monter(_session()));

      expect(find.text('démarrage'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Votre numéro'), findsOneWidget);
      expect(find.text('démarrage'), findsNothing);
    });

    testWidgets('démarrage → accueil quand une session est conservée',
        (tester) async {
      await tester.pumpWidget(
        _monter(_session(const JetonsSession(acces: 'a', rafraichissement: 'r'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vous êtes connecté'), findsOneWidget);
      expect(
        find.text('Votre numéro'),
        findsNothing,
        reason: 'une session conservée ne doit pas redemander d\'OTP',
      );
    });

    testWidgets('la déconnexion ramène à l\'authentification', (tester) async {
      final session = _session(
        const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      await tester.pumpWidget(_monter(session));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.text('Votre numéro'), findsOneWidget);
    });
  });
}
