/// US2 (PAY-02) — ce que le compte à rebours fait, et surtout ce qu'il ne fait
/// pas.
///
/// Le tic local est **purement visuel**. Il descend entre deux lectures et se
/// recale sur `restant_s` à chacune ; arrivé à zéro il s'arrête **sans rien
/// conclure**. L'autorité sur « cette session vit-elle encore ? » est le
/// serveur, et lui seul (FR-017).
///
/// Le temps est avancé par `tester.pump(duration)` : `testWidgets` exécute son
/// corps dans une horloge FICTIVE, et `Timer.periodic` y obéit. Faire vraiment
/// attendre quinze minutes serait absurde — un test qui dort est un test que
/// personne ne relance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/paiement/ecran_paiement.dart';
import 'package:mefali_client/paiement/etat_session_paiement.dart';
import 'package:mefali_core/mefali_core.dart';

import 'ecran_paiement_test.dart' show sessionJson;

const String _commande = '0199-commande';

void main() {
  group('le compte à rebours', () {
    /// Prépare un porteur d'état sur une horloge fictive. `pumpWidget` d'abord :
    /// `pump` exige un arbre, même vide.
    Future<(ProviderContainer, SessionPaiement)> porteur(
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = ProviderContainer(retry: pasDeRetry);
      addTearDown(container.dispose);
      return (container, container.read(sessionPaiementProvider(_commande).notifier));
    }

    testWidgets('descend seconde par seconde, puis S\'ARRÊTE à zéro',
        (tester) async {
      final (container, porteurEtat) = await porteur(tester);
      porteurEtat.poser(EtatSessionPaiement.depuisJson(sessionJson(restantS: 3)));
      expect(porteurEtat.ticActif, isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(container.read(sessionPaiementProvider(_commande))!.restantS, 2);

      await tester.pump(const Duration(seconds: 5));
      final etat = container.read(sessionPaiementProvider(_commande))!;
      expect(etat.restantS, 0, reason: 'jamais de valeur négative à l\'écran');
      expect(
        porteurEtat.ticActif,
        isFalse,
        reason: 'à zéro le tic S\'ARRÊTE — il n\'annule rien, c\'est le '
            'serveur qui dit si la session a expiré',
      );
      // L'état, lui, n'a PAS changé : la session reste « ouverte » tant que le
      // serveur ne dit pas le contraire.
      expect(etat.etat, 'ouverte');
    });

    testWidgets('se RECALE sur la valeur du serveur à chaque lecture',
        (tester) async {
      final (container, porteurEtat) = await porteur(tester);
      porteurEtat.poser(EtatSessionPaiement.depuisJson(sessionJson(restantS: 60)));

      await tester.pump(const Duration(seconds: 10));
      expect(container.read(sessionPaiementProvider(_commande))!.restantS, 50);

      // Le serveur dit autre chose — par exemple parce que l'appareil a dormi,
      // ou que son horloge dérive. C'est LUI qui a raison.
      porteurEtat.poser(EtatSessionPaiement.depuisJson(sessionJson(restantS: 12)));
      expect(container.read(sessionPaiementProvider(_commande))!.restantS, 12);

      // La session vit encore : son minuteur tourne. Sans cet appel, le test
      // échoue sur « A Timer is still pending » — et c'est une bonne chose,
      // parce que c'est exactement ce qu'un écran qui oublierait `liberer()`
      // laisserait derrière lui sur un téléphone.
      porteurEtat.liberer();
    });

    testWidgets('ne démarre pas sur une session close', (tester) async {
      final (container, porteurEtat) = await porteur(tester);
      porteurEtat.poser(
        EtatSessionPaiement.depuisJson(
          sessionJson(etat: 'expiree', restantS: 0, acces: null),
        ),
      );
      expect(porteurEtat.ticActif, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(container.read(sessionPaiementProvider(_commande))!.restantS, 0);
    });
  });

  testWidgets(
    'le compte à rebours atteint zéro sans figer l\'écran',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        retry: pasDeRetry,
        overrides: [ouvrirUrlProvider.overrideWithValue((_) async => true)],
      );
      addTearDown(container.dispose);
      container
          .read(sessionPaiementProvider(_commande).notifier)
          .poser(EtatSessionPaiement.depuisJson(sessionJson(restantS: 2)));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              MefaliCoreLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: const EcranPaiement(commandeId: _commande),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Temps restant : 00:02'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Temps restant : 00:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Temps restant : 00:00'), findsOneWidget);

      // L'écran reste vivant et le bouton reste actionnable : rien n'est figé,
      // et surtout rien n'a été conclu.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Temps restant : 00:00'), findsOneWidget);
      expect(find.text('Payer maintenant'), findsOneWidget);
      expect(find.text('En attente de votre paiement'), findsOneWidget);
    },
  );

  testWidgets(
    'sur annulation par expiration, la reprise DISPARAÎT',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        retry: pasDeRetry,
        overrides: [ouvrirUrlProvider.overrideWithValue((_) async => true)],
      );
      addTearDown(container.dispose);
      final porteur = container.read(sessionPaiementProvider(_commande).notifier)
        ..poser(EtatSessionPaiement.depuisJson(sessionJson(restantS: 30)));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              MefaliCoreLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: const EcranPaiement(commandeId: _commande),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Payer maintenant'), findsOneWidget);

      // Le serveur a tranché : la session a expiré, la commande est annulée.
      porteur.poser(
        EtatSessionPaiement.depuisJson(
          sessionJson(etat: 'expiree', restantS: 0, acces: null),
        ),
      );
      await tester.pump();

      expect(find.text('Le délai de paiement est écoulé.'), findsOneWidget);
      expect(
        find.text('Payer maintenant'),
        findsNothing,
        reason: 'plus rien à payer : le bouton ne doit pas survivre à la session',
      );
      expect(find.text('Reprendre le paiement'), findsNothing);
      expect(find.textContaining('Temps restant'), findsNothing);
      expect(porteur.ticActif, isFalse);
    },
  );
}
