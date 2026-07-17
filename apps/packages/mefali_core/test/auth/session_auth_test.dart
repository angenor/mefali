import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

/// Monte `RacineAuth` sous le harnais.
Widget _racine() => RacineAuth(
      nomAppareil: 'Test',
      demarrage: const Scaffold(body: Text('démarrage')),
      accueil: (_) => const AccueilProvisoire(),
    );

/// Démonte l'arbre PUIS dispose le conteneur, DANS le corps du test.
///
/// `RacineAuth` lit `serviceConfigProvider`, dont `ServiceConfig` porte un Timer
/// horaire (`keepAlive`). `addTearDown(container.dispose)` s'exécute APRÈS le
/// contrôle « Timer still pending » de flutter_test — trop tard. On démonte
/// l'arbre (plus personne ne lit le conteneur) puis on le dispose ici :
/// `serviceConfig.onDispose` annule le Timer SYNCHRONEMENT.
Future<void> _fin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

void main() {
  group('sessionProvider', () {
    test('naît déconnectée et non chargée', () {
      final container = conteneurMefali();
      addTearDown(container.dispose);

      final etat = container.read(sessionProvider);
      expect(etat.connecte, isFalse);
      expect(etat.charge, isFalse);
      expect(etat.acces, isNull);
    });

    test('relit les jetons conservés au démarrage', () async {
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'opaque'),
      );
      addTearDown(container.dispose);

      await container.read(sessionProvider.notifier).charger();

      final etat = container.read(sessionProvider);
      expect(etat.charge, isTrue);
      expect(etat.connecte, isTrue);
      expect(etat.acces, 'jwt');
      expect(etat.rafraichissement, 'opaque');
    });

    test('ouvrir persiste les jetons et notifie (une seule émission)', () async {
      final container = conteneurMefali();
      addTearDown(container.dispose);

      // `container.listen` SANS `fireImmediately` (⇔ `addListener`).
      var emissions = 0;
      container.listen(sessionProvider, (_, __) => emissions++);

      await container.read(sessionProvider.notifier).ouvrir(
            const JetonsSession(acces: 'a', rafraichissement: 'r'),
          );

      expect(container.read(sessionProvider).connecte, isTrue);
      // Égal STRICT (exception nommée de FR-003) — jamais greaterThanOrEqualTo.
      expect(emissions, 1);
      expect(
        await container.read(stockageJetonsProvider).lire(),
        const JetonsSession(acces: 'a', rafraichissement: 'r'),
        reason: 'relancer l\'app doit retrouver la session',
      );
    });

    test('deux ouvrir() à jetons IDENTIQUES émettent deux fois', () async {
      final container = conteneurMefali();
      addTearDown(container.dispose);

      var emissions = 0;
      container.listen(sessionProvider, (_, __) => emissions++);

      const jetons = JetonsSession(acces: 'a', rafraichissement: 'r');
      await container.read(sessionProvider.notifier).ouvrir(jetons);
      await container.read(sessionProvider.notifier).ouvrir(jetons);

      // Rougit si on retire `updateShouldNotify => true` : la v3 filtrerait les
      // écritures égales par `==` et prouverait MOINS (FR-003/FR-004).
      expect(emissions, 2,
          reason: 'notifyListeners émettait TOUJOURS, sans comparer');
    });

    test('charger() est monotone : `charge` ne redevient jamais false (FR-022)',
        () async {
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      addTearDown(container.dispose);

      await container.read(sessionProvider.notifier).charger();
      expect(container.read(sessionProvider).charge, isTrue);

      await container.read(sessionProvider.notifier).charger();
      expect(container.read(sessionProvider).charge, isTrue,
          reason: 'l\'écran de démarrage ne peut pas réapparaître');
    });

    test('fermer efface le stockage — un jeton oublié survivrait à jamais',
        () async {
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      addTearDown(container.dispose);

      await container.read(sessionProvider.notifier).charger();
      await container.read(sessionProvider.notifier).fermer();

      expect(container.read(sessionProvider).connecte, isFalse);
      expect(await container.read(stockageJetonsProvider).lire(), isNull);
    });

    test('pose Authorization: Bearer sur les requêtes, et rien sans session',
        () async {
      // Une VRAIE requête part et on lit `transport.recues` : plus aucune
      // position, plus aucun `onRequest` manuel.
      final transport = TransportFake((options) => reponseJson(const <Object>[]));
      final container = conteneurMefali(transport: transport);
      addTearDown(container.dispose);
      final moi = container.read(clientSessionProvider).getMoiApi();

      await moi.mesSessions();
      expect(transport.recues.last.headers['Authorization'], isNull,
          reason: 'déconnecté');

      await container.read(sessionProvider.notifier).ouvrir(
            const JetonsSession(acces: 'jwt-de-test', rafraichissement: 'r'),
          );
      await moi.mesSessions();
      expect(transport.recues.last.headers['Authorization'], 'Bearer jwt-de-test');
    });
  });

  group('RacineAuth', () {
    testWidgets('démarrage → authentification quand aucune session',
        (tester) async {
      final container = conteneurMefali();
      await tester.pumpWidget(
        harnaisApp(
          container: container,
          localizationsDelegates:
              MefaliCoreLocalizations.localizationsDelegates,
          supportedLocales: MefaliCoreLocalizations.supportedLocales,
          home: _racine(),
        ),
      );

      expect(find.text('démarrage'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Votre numéro'), findsOneWidget);
      expect(find.text('démarrage'), findsNothing);
      await _fin(tester, container);
    });

    testWidgets('démarrage → accueil quand une session est conservée',
        (tester) async {
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      await tester.pumpWidget(
        harnaisApp(
          container: container,
          localizationsDelegates:
              MefaliCoreLocalizations.localizationsDelegates,
          supportedLocales: MefaliCoreLocalizations.supportedLocales,
          home: _racine(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vous êtes connecté'), findsOneWidget);
      expect(
        find.text('Votre numéro'),
        findsNothing,
        reason: 'une session conservée ne doit pas redemander d\'OTP',
      );
      await _fin(tester, container);
    });

    testWidgets('la déconnexion ramène à l\'authentification', (tester) async {
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      await tester.pumpWidget(
        harnaisApp(
          container: container,
          localizationsDelegates:
              MefaliCoreLocalizations.localizationsDelegates,
          supportedLocales: MefaliCoreLocalizations.supportedLocales,
          home: _racine(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.text('Votre numéro'), findsOneWidget);
      await _fin(tester, container);
    });
  });
}
