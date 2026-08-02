/// Reçu vendeur d'un arrêt collecté (cycle PAY 011, T063 — FR-071, SC-009).
///
/// Ce que le test mesure : les TROIS montants s'affichent séparément, la
/// retenue porte son motif en clair, et une collecte ordinaire n'affiche
/// aucune ligne de retenue — un « − 0 FCFA » ferait chercher au vendeur ce
/// qu'on lui a prélevé.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/vendeur/recu_arret.dart';

const _arret = '01900000-0000-7000-8000-0000000005a1';

Map<String, Object?> _recu({int retenue = 0, bool ligneRetiree = false}) => {
      'arret_id': _arret,
      'prestataire_id': '01900000-0000-7000-8000-000000000502',
      'devise': 'XOF',
      'collecte_le': '2026-08-01T09:41:12Z',
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
      'retenue_livraison_offerte_unites': retenue,
      'net_verse_unites': 3000 - retenue,
      'motif_retenue_cle':
          retenue > 0 ? 'recu.retenue.livraison_offerte_vendeur' : null,
    };

ProviderContainer _conteneur(Map<String, Object?> recu) {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/recu')) return reponseJson(recu);
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  return conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
}

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EcranRecuArret(arretId: _arret),
    );

void main() {
  testWidgets('FR-071 : les trois montants, séparés et lisibles',
      (tester) async {
    final container = _conteneur(_recu(retenue: 500));
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    expect(find.text('Articles'), findsOneWidget);
    expect(find.text(formaterMontant(3000, 'XOF')), findsWidgets);
    expect(find.text('Livraison offerte'), findsOneWidget);
    expect(find.text('− ${formaterMontant(500, 'XOF')}'), findsOneWidget);
    expect(find.text('Net versé'), findsOneWidget);
    expect(find.text(formaterMontant(2500, 'XOF')), findsOneWidget);

    // Le motif, en clair : sans lui, le vendeur voit un versement plus bas que
    // sa facture et croit à une erreur du coursier.
    expect(
      find.text('Vous offrez la livraison sur cette commande.'),
      findsOneWidget,
    );
  });

  testWidgets('sans retenue, aucune ligne de retenue ne vient troubler',
      (tester) async {
    final container = _conteneur(_recu());
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    expect(find.text('Livraison offerte'), findsNothing,
        reason: 'un « − 0 FCFA » ferait chercher ce qu\'on a prélevé');
    expect(find.text('Net versé'), findsOneWidget);
    expect(find.text(formaterMontant(3000, 'XOF')), findsWidgets);
  });

  testWidgets('une ligne retirée reste visible, barrée, et pèse zéro',
      (tester) async {
    final container = _conteneur(_recu(ligneRetiree: true));
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    expect(find.text('Igname braisée — 1'), findsOneWidget);
    final texte = tester.widget<Text>(find.text('Igname braisée — 1'));
    expect(
      texte.style?.decoration,
      TextDecoration.lineThrough,
      reason: 'le reçu explique l\'écart au lieu de le faire disparaître',
    );
    expect(find.text(formaterMontant(0, 'XOF')), findsOneWidget);
  });
}
