/// US1 (PAY-01/PAY-02) — écran de règlement d'une commande prépayée.
///
/// Le test qui compte ici est celui du **retour sans confirmation** (FR-025) :
/// revenir du navigateur ne crédite rien. L'écran ne doit ni annoncer un
/// paiement, ni annoncer un échec — il doit dire ce que le serveur sait, et
/// relire.
///
/// Aucune planche de paiement n'existe dans `docs/design/png/` : ces tests
/// portent donc sur le **comportement**, pas sur une comparaison visuelle. La
/// vérification à l'œil est portée par T085, sur appareil.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/paiement/ecran_paiement.dart';
import 'package:mefali_client/paiement/etat_session_paiement.dart';
import 'package:mefali_core/mefali_core.dart';

const String _commande = '0199-commande';

/// Corps d'une session, tel que l'API le rend.
Map<String, Object?> sessionJson({
  String etat = 'ouverte',
  int restantS = 873,
  Object? acces = 'https://paiement.invalid/sim/x',
  int montant = 12500,
}) =>
    <String, Object?>{
      'transaction_id': '0199-transaction',
      'etat': etat,
      'montant_unites': montant,
      'devise': 'XOF',
      'moyen': 'inconnu',
      'acces_paiement': acces,
      'expire_le': '2026-08-01T10:15:00Z',
      'restant_s': restantS,
    };

Future<ProviderContainer> monter(
  WidgetTester tester, {
  Map<String, Object?>? session,
  Future<bool> Function(String)? ouvrirUrl,
  Future<void> Function()? onRelire,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: pasDeRetry,
    overrides: [
      // Le navigateur système est injecté par la PORTÉE : le test exerce le
      // chemin réel sans toucher au canal de plateforme.
      ouvrirUrlProvider.overrideWithValue(
        ouvrirUrl ?? (_) async => true,
      ),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(sessionPaiementProvider(_commande).notifier)
      .poser(EtatSessionPaiement.depuisJson(session ?? sessionJson()));

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
        home: EcranPaiement(commandeId: _commande, onRelire: onRelire),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('le montant et le compte à rebours sont lisibles', (tester) async {
    await monter(tester);

    // Le séparateur de milliers est une espace FINE insécable : on compare au
    // formateur, jamais à une chaîne écrite à la main.
    expect(find.text(formaterMontant(12500, 'XOF')), findsOneWidget);
    expect(find.text('Temps restant : 14:33'), findsOneWidget);
    expect(find.text('Payer maintenant'), findsOneWidget);
  });

  testWidgets(
    'FR-025 — revenu du navigateur SANS confirmation : rien n\'est crédité',
    (tester) async {
      var relectures = 0;
      await monter(
        tester,
        onRelire: () async => relectures++,
      );

      // Avant l'ouverture, aucun message de retour : il n'y a eu aucun retour.
      expect(find.textContaining('pas encore reçu la confirmation'), findsNothing);

      await tester.tap(find.text('Payer maintenant'));
      await tester.pumpAndSettle();

      expect(
        relectures,
        1,
        reason: 'le retour DÉCLENCHE une relecture — il ne conclut rien lui-même',
      );
      expect(
        find.textContaining('pas encore reçu la confirmation'),
        findsOneWidget,
        reason:
            'le texte ne dit ni « payé » ni « échoué » : il dit ce que le serveur sait',
      );
      // L'état affiché n'a pas bougé : la session est toujours « en attente ».
      expect(find.text('En attente de votre paiement'), findsOneWidget);
      expect(find.text('Paiement confirmé'), findsNothing);
      // Et le bouton devient une REPRISE : le geste n'est plus le même.
      expect(find.text('Reprendre le paiement'), findsOneWidget);
    },
  );

  testWidgets('un navigateur absent le dit, sans rien créditer', (tester) async {
    var relectures = 0;
    await monter(
      tester,
      ouvrirUrl: (_) async => false,
      onRelire: () async => relectures++,
    );

    await tester.tap(find.text('Payer maintenant'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Impossible d'ouvrir la page de paiement"),
      findsOneWidget,
    );
    expect(
      relectures,
      0,
      reason: 'rien ne s\'est ouvert : il n\'y a rien à relire',
    );
  });

  testWidgets('une session réglée ne propose plus de payer', (tester) async {
    await monter(
      tester,
      session: sessionJson(etat: 'reglee', restantS: 0, acces: null),
    );

    expect(find.text('Paiement confirmé'), findsOneWidget);
    expect(find.text('Payer maintenant'), findsNothing);
    expect(
      find.textContaining('Temps restant'),
      findsNothing,
      reason: 'plus rien à attendre : un « 00:00 » serait une inquiétude gratuite',
    );
  });

  testWidgets('une session expirée ne propose plus de payer', (tester) async {
    await monter(
      tester,
      session: sessionJson(etat: 'expiree', restantS: 0, acces: null),
    );

    expect(find.text('Le délai de paiement est écoulé.'), findsOneWidget);
    expect(find.text('Payer maintenant'), findsNothing);
  });

  testWidgets('un refus d\'opérateur laisse réessayer (FR-026)', (tester) async {
    await monter(tester, session: sessionJson(etat: 'echouee'));

    expect(
      find.text('Paiement refusé. Vous pouvez réessayer.'),
      findsOneWidget,
    );
    expect(
      find.text('Payer maintenant'),
      findsOneWidget,
      reason: 'la session VIT encore : le client réessaie sur le même accès',
    );
  });
}
