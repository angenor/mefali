import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/mefali_core.dart';

/// Monte un écran dans le thème et la localisation fr réels : un test qui
/// stubberait le thème ne prouverait rien sur les tokens.
Widget _monter(Widget enfant) => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: enfant,
    );

void main() {
  group('EcranTelephone', () {
    testWidgets('remonte la saisie BRUTE — la normalisation est au serveur',
        (tester) async {
      String? recu;
      await tester.pumpWidget(
        _monter(EcranTelephone(onValider: (t) => recu = t)),
      );

      await tester.enterText(find.byType(TextField), ' 0701020304 ');
      await tester.tap(find.text('Recevoir le code'));
      await tester.pump();

      expect(recu, '0701020304', reason: 'espaces coupés, rien de plus');
    });

    testWidgets('refuse une saisie vide sans appeler le serveur',
        (tester) async {
      var appels = 0;
      await tester.pumpWidget(
        _monter(EcranTelephone(onValider: (_) => appels++)),
      );

      await tester.tap(find.text('Recevoir le code'));
      await tester.pump();

      expect(appels, 0);
      expect(find.text('Saisissez votre numéro de mobile.'), findsOneWidget);
    });

    testWidgets('affiche l\'erreur du serveur', (tester) async {
      await tester.pumpWidget(
        _monter(EcranTelephone(onValider: (_) {}, erreur: 'Numéro invalide')),
      );
      expect(find.text('Numéro invalide'), findsOneWidget);
    });
  });

  group('EcranOtp', () {
    testWidgets('la saisie remplit les 6 cases et n\'active qu\'à 6 chiffres',
        (tester) async {
      String? code;
      await tester.pumpWidget(
        _monter(EcranOtp(onValider: (c) => code = c, onRenvoyer: () {})),
      );

      // Incomplet : le bouton reste inerte.
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      final bouton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(bouton.onPressed, isNull, reason: '5 chiffres ne suffisent pas');
      expect(find.text('5'), findsOneWidget, reason: 'la case affiche le chiffre');

      // Complet : le bouton s'active et remonte le code.
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Valider'));
      await tester.pump();
      expect(code, '123456');
    });

    testWidgets('n\'accepte que des chiffres, et jamais plus de 6',
        (tester) async {
      String? code;
      await tester.pumpWidget(
        _monter(EcranOtp(onValider: (c) => code = c, onRenvoyer: () {})),
      );

      await tester.enterText(find.byType(TextField), 'abc12x3456789');
      await tester.pump();
      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(code, '123456', reason: 'lettres filtrées, longueur bornée à 6');
    });

    testWidgets('le renvoi est verrouillé puis s\'ouvre au bout du compte à rebours',
        (tester) async {
      var renvois = 0;
      await tester.pumpWidget(
        _monter(EcranOtp(onValider: (_) {}, onRenvoyer: () => renvois++)),
      );

      expect(find.text('Renvoyer le code dans 60 s'), findsOneWidget);
      final verrouille = tester.widget<TextButton>(find.byType(TextButton));
      expect(verrouille.onPressed, isNull);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Renvoyer le code dans 30 s'), findsOneWidget);
      expect(renvois, 0, reason: 'toujours verrouillé à mi-parcours');

      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Renvoyer le code'), findsOneWidget);
      await tester.tap(find.text('Renvoyer le code'));
      await tester.pump();
      expect(renvois, 1);

      // Le renvoi relance le compte à rebours ET vide la saisie : l'ancien
      // code est caduc (FR-002), le laisser affiché induirait en erreur.
      expect(find.text('Renvoyer le code dans 60 s'), findsOneWidget);
      final champ = tester.widget<TextField>(find.byType(TextField));
      expect(champ.controller!.text, isEmpty);

      // Laisse le minuteur s'éteindre pour ne pas fuir hors du test.
      await tester.pump(const Duration(seconds: 61));
    });
  });

  group('EcranConsentement', () {
    testWidgets('la case n\'est JAMAIS pré-cochée (FR-006)', (tester) async {
      await tester.pumpWidget(_monter(EcranConsentement(onAccepter: () {})));

      final case_ = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(case_.value, isFalse,
          reason: 'un consentement pré-coché n\'est pas un consentement');
    });

    testWidgets('l\'action reste inerte tant que la case n\'est pas cochée',
        (tester) async {
      var acceptations = 0;
      await tester.pumpWidget(
        _monter(EcranConsentement(onAccepter: () => acceptations++)),
      );

      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();
      expect(acceptations, 0, reason: 'sans consentement, aucun compte');

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();
      expect(acceptations, 1);
    });

    testWidgets('cocher se fait sur toute la ligne (cible ≥ 48 dp)',
        (tester) async {
      await tester.pumpWidget(_monter(EcranConsentement(onAccepter: () {})));

      // Le libellé, pas la case : la case seule ferait 24 dp.
      await tester.tap(
        find.text('J\'accepte le traitement de mes données personnelles.'),
      );
      await tester.pump();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('affiche le texte ARTCI', (tester) async {
      await tester.pumpWidget(_monter(EcranConsentement(onAccepter: () {})));
      expect(find.textContaining('ARTCI'), findsOneWidget);
    });
  });

  group('Conformité aux tokens (docs/design/tokens.md)', () {
    testWidgets('le bouton principal fait 56 px et vit EN BAS de l\'écran',
        (tester) async {
      await tester.pumpWidget(
        _monter(EcranTelephone(onValider: (_) {})),
      );

      final bouton = find.byType(FilledButton);
      expect(tester.getSize(bouton).height, MefaliTokens.buttonHeight);

      // Règle d'or 3 : action principale en bas (usage à une main).
      final hauteurEcran = tester.getSize(find.byType(Scaffold)).height;
      expect(
        tester.getCenter(bouton).dy,
        greaterThan(hauteurEcran / 2),
        reason: 'l\'action principale ne doit jamais être en haut',
      );
    });

    testWidgets('aucun texte courant sous le plancher de 16 px',
        (tester) async {
      await tester.pumpWidget(_monter(EcranConsentement(onAccepter: () {})));

      final textes = tester.widgetList<Text>(find.byType(Text));
      for (final texte in textes) {
        final taille = texte.style?.fontSize;
        if (taille != null && texte.data != null && texte.data!.length > 3) {
          expect(taille, greaterThanOrEqualTo(MefaliTokens.bodySize),
              reason: 'texte « ${texte.data} » sous le plancher');
        }
      }
    });
  });
}
