import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/vendeur/articles/fiche_article.dart';

const _prestataire = '01900000-0000-7000-8000-000000000502';

(ProviderContainer, TransportFake) _conteneur() {
  final transport = TransportFake((requete) {
    if (requete.method == 'POST' && requete.path.endsWith('/articles')) {
      return reponseJson({
        'id': 'a9',
        'nom': 'Alloco',
        'prix_unites': 800,
        'devise': 'XOF',
        'prix_barre_unites': 1000,
        'photo_url': null,
        'categorie_interne': null,
        'disponible': true,
        'source_derniere_bascule': null,
        'rupture_admin': false,
        'retire': false,
      }, statut: 201);
    }
    return reponseJson([]);
  });
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

Widget _monter(ProviderContainer container, Widget home) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('FicheArticle — V2 1b (FR-045, FR-023)', () {
    testWidgets('steppers ± par pas de 100, aperçu « le client verra »',
        (tester) async {
      final (container, _) = _conteneur();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _monter(container, const FicheArticle(prestataireId: _prestataire)),
      );

      // Prix par défaut 1 000 ; un pas de stepper = 100 FCFA.
      expect(find.text(formaterMontant(1000, 'XOF')), findsOneWidget);
      await tester.tap(find.byTooltip('-'));
      await tester.pump();
      expect(find.text(formaterMontant(900, 'XOF')), findsOneWidget);

      // Activer la promo : prix normal barré + aperçu client.
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      expect(
        find.textContaining('Le client verra', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Par pas de 100 FCFA'), findsOneWidget);
    });

    testWidgets(
        'promo ≤ prix : message FR-023 et enregistrement désactivé — jamais '
        'de retrait silencieux', (tester) async {
      final (container, _) = _conteneur();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _monter(container, const FicheArticle(prestataireId: _prestataire)),
      );
      await tester.enterText(find.byType(TextField), 'Alloco');
      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      // Prix barré descend à l'égalité (1 100 → 1 000) : invalide.
      await tester.tap(find.byTooltip('-').last);
      await tester.pump();
      expect(
        find.text('Le prix barré doit rester supérieur au prix.'),
        findsOneWidget,
      );
      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Enregistrer'),
      );
      expect(bouton.onPressed, isNull, reason: 'promo invalide → pas d\'envoi');
    });

    testWidgets('création : POST /articles avec nom, prix et prix barré',
        (tester) async {
      final (container, transport) = _conteneur();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _monter(container, const FicheArticle(prestataireId: _prestataire)),
      );
      await tester.enterText(find.byType(TextField), 'Alloco');
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final creation = transport.recues
          .firstWhere((r) => r.method == 'POST' && r.path.endsWith('/articles'));
      final corps = Map<String, Object?>.from(creation.data as Map);
      expect(corps['nom'], 'Alloco');
      expect(corps['prix_unites'], 1000);
      expect(corps['prix_barre_unites'], 1100);
    });
  });
}
