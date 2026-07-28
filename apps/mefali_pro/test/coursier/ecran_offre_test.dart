/// Tests widget de l'écran **K2 — offre de course** (DSP-04, T053/T054).
///
/// Cible visuelle : `docs/design/png/K2-offre-course.png`. Ce que ces tests
/// prouvent, et qui compte pour Yao :
///
/// - l'écran montre **tout ce qui décide** en 40 s : arrêts, gain détaillé,
///   avance et son plafond ;
/// - **aucune coordonnée du client** n'apparaît avant acceptation — seulement le
///   nom de la zone et la mention qui explique pourquoi (ARTCI) ;
/// - une échéance dépassée affiche **K2-1b sans aucun appel réseau
///   supplémentaire** : l'autorité est déjà dans l'état ;
/// - K2-1b est de ton **neutre** et dit « sans pénalité — n sur 3 aujourd'hui ».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/offre/ecran_offre.dart';
import 'package:mefali_pro/coursier/offre/etat_offre.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

/// Corps de `GET /courses/offre-courante`, tel que le contrat le rend.
Map<String, Object?> _offre({int dansSecondes = 31}) => {
      'offre_id': '019fa000-0000-7000-8000-000000000001',
      'commande_id': '019fa000-0000-7000-8000-000000000002',
      'mode': 'cascade',
      'echeance_le':
          DateTime.now().toUtc().add(Duration(seconds: dansSecondes)).toIso8601String(),
      'timer_s': 40,
      'restant_s': dansSecondes,
      'arrets': [
        {'ordre': 1, 'prestataire_id': null, 'nom': 'Étal Adjoua', 'distance_m': 800},
        {'ordre': 2, 'prestataire_id': null, 'nom': 'Étal Konan', 'distance_m': 40},
        {'ordre': 3, 'prestataire_id': null, 'nom': 'Boutique Yao', 'distance_m': 60},
      ],
      'destination': {
        'zone_nom': 'Tiassalé',
        'distance_m': 1800,
        'mention_cle': 'dispatch.offre.adresse_apres_acceptation',
      },
      'gain': {
        'total_unites': 450,
        'deplacement_unites': 250,
        'arrets_unites': 50,
        'effort_unites': 100,
        'devise': 'XOF',
      },
      'avance': {
        'montant_unites': 5550,
        'plafond_retenu_unites': 10000,
        'devise': 'XOF',
      },
      'degraded': false,
    };

(ProviderContainer, TransportFake) _conteneur({
  Map<String, Object?>? offre,
  int statutAcceptation = 200,
}) {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/offre-courante')) {
      if (offre == null) return reponseJson(<String, Object?>{}, statut: 204);
      return reponseJson(offre);
    }
    if (requete.path.contains('/accepter')) {
      if (statutAcceptation == 200) {
        return reponseJson({
          'commande_id': '019fa000-0000-7000-8000-000000000002',
          'livraison_id': '019fa000-0000-7000-8000-000000000003',
          'etat_livraison': 'assignee',
          'rejeu': false,
        });
      }
      return reponseJson(
        {'code': 'deja_prise', 'message_cle': 'dispatch.erreur.deja_prise'},
        statut: statutAcceptation,
      );
    }
    if (requete.path.contains('/refuser')) {
      return reponseJson({'issue': 'refusee'});
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

/// Écran de test assez HAUT pour que tout K2 soit construit : un `ListView` ne
/// bâtit que ce qui entre dans la fenêtre, et un `find` sur une carte hors
/// écran échouerait sans que rien ne soit cassé.
Future<void> _ecranHaut(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EcranOffre(),
    );

void main() {
  testWidgets('K2 montre tout ce qui décide en 40 secondes', (tester) async {
    await _ecranHaut(tester);
    final (container, _) = _conteneur(offre: _offre());
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Les trois arrêts, avec leurs distances inter-arrêts.
    expect(find.text('Étal Adjoua'), findsOneWidget);
    expect(find.text('Boutique Yao'), findsOneWidget);
    expect(find.text('à 800 m'), findsOneWidget);
    expect(find.text('+ 40 m'), findsOneWidget);

    // Le gain, en display success, avec son détail.
    expect(
      tester.widget<Text>(find.byKey(const Key('offre-gain'))).data,
      '450 FCFA',
    );
    // L'avance, et le plafond qui explique pourquoi il peut la prendre.
    expect(
      tester.widget<Text>(find.byKey(const Key('offre-avance'))).data,
      '5 550 FCFA',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('offre-plafond'))).data,
      contains('10 000 FCFA'),
    );

    // La décision, à une main, en bas.
    expect(find.byKey(const Key('offre-accepter')), findsOneWidget);
    expect(find.byKey(const Key('offre-refuser')), findsOneWidget);
  });

  testWidgets(
    'aucune coordonnée du client avant acceptation — seulement la zone et sa mention',
    (tester) async {
      await _ecranHaut(tester);
      final (container, _) = _conteneur(offre: _offre());
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final destination =
          tester.widget<Text>(find.byKey(const Key('offre-destination'))).data;
      expect(destination, 'Livraison — Tiassalé');
      expect(
        find.text('Adresse exacte après acceptation'),
        findsOneWidget,
        reason: 'la mention rend le manque compréhensible : ce n\'est pas une '
            'donnée absente, c\'est une donnée qui arrive après',
      );
    },
  );

  testWidgets(
    'une échéance dépassée affiche K2-1b SANS appel réseau supplémentaire',
    (tester) async {
      // L'offre est déjà échue au moment où l'écran la reçoit.
      final (container, transport) = _conteneur(offre: _offre(dansSecondes: -5));
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final appelsAvant = transport.recues.length;
      expect(find.byKey(const Key('offre-expiree-titre')), findsOneWidget);
      expect(find.text('Course attribuée à un autre coursier'), findsOneWidget);
      expect(
        transport.recues.length,
        appelsAvant,
        reason: 'l\'échéance persistée suffit à trancher : rien à redemander',
      );
    },
  );

  testWidgets('K2-1b est de ton neutre et dit « sans pénalité »', (tester) async {
    final (container, _) = _conteneur(offre: _offre(dansSecondes: -5));
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('offre-sans-penalite')), findsOneWidget);
    expect(find.textContaining('Sans pénalité'), findsOneWidget);
    expect(
      find.text('Vous n\'avez pas répondu à temps. Restez en ligne : une autre '
          'course arrive bientôt.'),
      findsOneWidget,
    );
    // Retour au tableau de bord en action UNIQUE.
    expect(find.byKey(const Key('offre-retour')), findsOneWidget);
  });

  testWidgets('un 409 « déjà prise » bascule en K2-1b, sans blâme', (tester) async {
    await _ecranHaut(tester);
    final (container, _) = _conteneur(offre: _offre(), statutAcceptation: 409);
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('offre-accepter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Le bandeau ET le corps portent la même phrase quand la course a été
    // prise : c'est voulu, le titre neutre remplace « Temps écoulé ».
    expect(find.text('Course attribuée à un autre coursier'), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const Key('offre-expiree-titre'))).data,
      'Course attribuée à un autre coursier',
    );
    expect(find.byKey(const Key('offre-sans-penalite')), findsOneWidget);
  });

  testWidgets('aucune offre en vol : K2-1b, jamais un écran blanc', (tester) async {
    final (container, _) = _conteneur();
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('offre-expiree-titre')), findsOneWidget);
  });

  test('l\'offre se construit depuis le corps JSON du contrat', () {
    final offre = OffreCourante.depuisJson(_offre());
    expect(offre.arrets.length, 3);
    expect(offre.arrets.first.nom, 'Étal Adjoua');
    expect(offre.zoneNom, 'Tiassalé');
    expect(offre.gainTotalUnites, 450);
    expect(offre.avanceUnites, 5550);
    expect(offre.plafondRetenuUnites, 10000);
    expect(offre.devise, 'XOF');

    // L'échéance est l'AUTORITÉ : c'est elle qui décide, pas le compteur local.
    final maintenant = offre.echeanceLe.subtract(const Duration(seconds: 9));
    expect(offre.restantS(maintenant), 9);
    expect(offre.estEchue(maintenant), isFalse);
    expect(offre.estEchue(offre.echeanceLe), isTrue);
    expect(
      offre.restantS(offre.echeanceLe.add(const Duration(minutes: 5))),
      0,
      reason: 'jamais de reste négatif',
    );
  });
}
