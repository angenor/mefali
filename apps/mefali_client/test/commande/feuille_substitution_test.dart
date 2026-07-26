/// US7 (CMD-06) — feuille de substitution, maquette C4-4c.
///
/// Ce que la maquette promet et que ces tests tiennent : l'écart de prix en
/// toutes lettres, un compte à rebours qui DESCEND réellement, la phrase
/// d'issue par défaut, et — à zéro — des boutons désarmés plutôt qu'une
/// décision qui partirait pour rien se faire refuser par le serveur.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/commande/etat_suivi.dart';
import 'package:mefali_client/commande/feuille_substitution.dart';
import 'package:mefali_core/mefali_core.dart';

/// La proposition de la maquette : 600 FCFA au lieu de 500, 47 s restantes.
SubstitutionVue proposition({int resteS = 47}) => SubstitutionVue(
      id: '01900000-0000-7000-8000-000000000a01',
      articleNom: 'Tomates en boîte 400 g × 2',
      prixUnites: 600,
      ancienPrixUnites: 500,
      resteS: resteS,
    );

Future<void> monter(
  WidgetTester tester, {
  required SubstitutionVue substitution,
  VoidCallback? onAccepter,
  VoidCallback? onRefuser,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        MefaliCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
      home: Scaffold(
        body: FeuilleSubstitution(
          substitution: substitution,
          devise: 'XOF',
          onAccepter: onAccepter,
          onRefuser: onRefuser,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets("l'écart de prix est écrit en toutes lettres", (tester) async {
    await monter(tester, substitution: proposition());
    // Les montants passent par `formaterMontant` : l'espace fine (U+202F) ne
    // se tape pas à l'identique dans un littéral.
    expect(
      find.text(
        'Tomates en boîte 400 g × 2 à ${formaterMontant(600, 'XOF')} '
        'au lieu de ${formaterMontant(500, 'XOF')}',
      ),
      findsOneWidget,
    );
  });

  testWidgets("l'issue par défaut est annoncée d'avance (FR-046)",
      (tester) async {
    await monter(tester, substitution: proposition());
    expect(
      find.text(
        'Sans réponse, on vous appelle. Injoignable : article retiré, '
        'rien à payer.',
      ),
      findsOneWidget,
      reason: 'un client qui sait ce que coûte son silence ne se presse pas',
    );
  });

  testWidgets('le compte à rebours DESCEND réellement', (tester) async {
    await monter(tester, substitution: proposition(resteS: 3));
    expect(find.text('3 s pour répondre'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 s pour répondre'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 s pour répondre'), findsOneWidget);

    // Le minuteur est annulé à zéro : sans quoi le test resterait pendant.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0 s pour répondre'), findsOneWidget);
  });

  testWidgets('les deux boutons agissent tant que la fenêtre est ouverte',
      (tester) async {
    var accepte = 0;
    var refuse = 0;
    await monter(
      tester,
      substitution: proposition(),
      onAccepter: () => accepte++,
      onRefuser: () => refuse++,
    );

    await tester.tap(find.text('Accepter'));
    await tester.tap(find.text('Refuser'));
    await tester.pump();
    expect((accepte, refuse), (1, 1));
  });

  testWidgets('à zéro, les boutons sont DÉSARMÉS et le refus est expliqué',
      (tester) async {
    var appuis = 0;
    await monter(
      tester,
      substitution: proposition(resteS: 0),
      onAccepter: () => appuis++,
      onRefuser: () => appuis++,
    );

    await tester.tap(find.text('Accepter'), warnIfMissed: false);
    await tester.tap(find.text('Refuser'), warnIfMissed: false);
    await tester.pump();
    expect(
      appuis,
      0,
      reason: 'la fenêtre est une promesse faite au coursier : passé le délai '
          'il a déjà agi, et le serveur refuserait de toute façon',
    );
    expect(find.text('Le délai de réponse est passé.'), findsOneWidget);
  });
}
