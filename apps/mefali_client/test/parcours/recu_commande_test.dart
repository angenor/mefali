/// US5 (cycle PAY 011, T064) — le reçu de commande, côté cliente.
///
/// Ce que le test mesure :
/// - une ligne retirée reste VISIBLE, barrée, et pèse zéro : le reçu explique
///   pourquoi le total a bougé plutôt que de le faire bouger en silence ;
/// - une commande prépayée porte « Déjà réglé » et **aucun** montant à
///   remettre au coursier (FR-073) ;
/// - la retenue de livraison offerte n'apparaît que si elle joue — un
///   « 0 FCFA » ferait chercher à Awa une remise qu'elle n'a pas eue.
///
/// Aucune planche de reçu n'existe dans `docs/design/png/` : le test porte donc
/// sur le **comportement**, pas sur une comparaison visuelle (T085 vérifie à
/// l'œil, sur appareil).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/parcours/recu_commande.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const String _commande = '0199-commande';

Map<String, Object?> _recuJson({
  int retenue = 0,
  bool dejaRegle = false,
  String mode = 'cash',
  bool ligneRetiree = false,
}) =>
    <String, Object?>{
      'commande_id': _commande,
      'devise': 'XOF',
      'lignes': [
        {
          'libelle': 'Attiéké poisson',
          'quantite': 2,
          'prix_unitaire': 1500,
          'statut': 'presente',
          'sous_total_unites': 3000,
        },
        if (ligneRetiree)
          {
            'libelle': 'Igname braisée',
            'quantite': 1,
            'prix_unitaire': 800,
            'statut': 'retiree',
            'sous_total_unites': 0,
          },
      ],
      'montant_articles_unites': 3000,
      'frais_livraison_unites': retenue > 0 ? 0 : 500,
      'retenue_vendeur_unites': retenue,
      'total_du_unites': retenue > 0 ? 3000 : 3500,
      'mode_paiement': mode,
      'moyen': dejaRegle ? 'wave' : null,
      'deja_regle': dejaRegle,
      'montant_a_remettre_au_coursier_unites':
          dejaRegle || mode != 'cash' ? 0 : (retenue > 0 ? 3000 : 3500),
    };

Future<ProviderContainer> _monter(
  WidgetTester tester,
  Map<String, Object?> recu,
) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Le reçu est une LECTURE : un transport qui rend toujours le même corps
  // suffit, et rend le test indépendant de l'ordre des appels.
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'acces', rafraichissement: 'refresh'),
    transport: TransportFake((_) => reponseJson(recu)),
  );
  addTearDown(container.dispose);

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
        home: const PageRecu(commandeId: _commande),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('FR-072 : une ligne retirée reste visible et pèse zéro',
      (tester) async {
    await _monter(tester, _recuJson(ligneRetiree: true));

    expect(find.text('Igname braisée × 1'), findsOneWidget);
    expect(find.text('Retirée'), findsOneWidget);
    final texte = tester.widget<Text>(find.text('Igname braisée × 1'));
    expect(
      texte.style?.decoration,
      TextDecoration.lineThrough,
      reason: 'le reçu explique l\'écart au lieu de le faire disparaître',
    );
    // Le séparateur de milliers est une espace FINE insécable : on compare au
    // formateur, jamais à une chaîne écrite à la main.
    expect(find.text(formaterMontant(0, 'XOF')), findsOneWidget);
    expect(find.text(formaterMontant(3000, 'XOF')), findsWidgets);
  });

  testWidgets('FR-073 : une commande prépayée ne réclame rien au coursier',
      (tester) async {
    await _monter(
      tester,
      _recuJson(dejaRegle: true, mode: 'mobile_money'),
    );

    expect(find.text('Déjà réglé'), findsOneWidget);
    expect(find.text('Mobile money'), findsOneWidget);
    expect(
      find.text('À remettre au coursier'),
      findsNothing,
      reason: 'un montant à remettre, même nul, ferait chercher son porte-monnaie',
    );
  });

  testWidgets('une commande cash annonce ce qu\'il reste à sortir',
      (tester) async {
    await _monter(tester, _recuJson());

    expect(find.text('Espèces à la livraison'), findsOneWidget);
    expect(find.text('À remettre au coursier'), findsOneWidget);
    expect(find.text(formaterMontant(3500, 'XOF')), findsWidgets);
    expect(find.text('Déjà réglé'), findsNothing);
  });

  testWidgets('la livraison offerte apparaît quand elle joue', (tester) async {
    await _monter(tester, _recuJson(retenue: 500));

    expect(find.text('Livraison offerte par le vendeur'), findsOneWidget);
    expect(find.text('− ${formaterMontant(500, 'XOF')}'), findsOneWidget);
  });

  // Deux montages dans le MÊME test laisseraient le premier conteneur vivant
  // pendant le second : son `Timer` de session survivrait à la fin du test, et
  // Flutter le signalerait (« A Timer is still pending »). Un cas, un test.
  testWidgets('sans livraison offerte, aucune ligne de retenue', (tester) async {
    await _monter(tester, _recuJson());

    expect(
      find.text('Livraison offerte par le vendeur'),
      findsNothing,
      reason: 'un « 0 FCFA » ferait chercher une remise qui n\'existe pas',
    );
  });
}
