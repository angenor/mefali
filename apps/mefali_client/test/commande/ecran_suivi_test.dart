/// US6 (CMD-05) — écran de suivi, maquette C4.
///
/// Trois états couverts : collecte en cours (4a), recherche de coursier (4b) et
/// hors-ligne (4d). Ce qui est vérifié est ce que la maquette PROMET, et
/// surtout ce qu'elle interdit :
/// - la progression compte les collectes, **jamais** l'arrêt de remise ;
/// - la position n'apparaît **jamais** sans son âge ;
/// - hors ligne, l'écran annonce le **dernier état connu** et rend quand même
///   le bloc « À la livraison » — c'est tout l'objet de SC-009.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/commande/ecran_suivi.dart';
import 'package:mefali_client/commande/etat_suivi.dart';
import 'package:mefali_core/mefali_core.dart';

const _commande = '01900000-0000-7000-8000-000000000901';

/// Corps de `GET /commandes/{id}` : 3 collectes + 1 remise, 2 collectes faites
/// — exactement la course de la maquette C4-4a.
Map<String, Object?> suiviJson({
  String etat = 'en_cours',
  String etatCle = 'suivi.etat.collecte_en_cours',
  int faites = 2,
  Map<String, Object?>? position = const {
    'lat': 5.899,
    'lon': -4.821,
    'age_s': 12,
  },
  Map<String, Object?>? coursier = const {
    'id': '01900000-0000-7000-8000-000000000404',
    'prenom': null,
    'note': null,
    'appel_possible': true,
  },
}) =>
    {
      'id': _commande,
      'etat': etat,
      'etat_cle': etatCle,
      'etat_le': '2026-07-25T15:05:00Z',
      'montant_articles_unites': 5550,
      'total_unites': 5900,
      'devise': 'XOF',
      'livraison_id': '01900000-0000-7000-8000-000000000801',
      'livraison_etat': 'en_collecte',
      'progression': {
        'collectes_faites': faites,
        // 3, jamais 4 : l'arrêt de remise n'est pas une collecte (P1).
        'collectes_total': 3,
        'arret_courant': {
          'arret_id': '01900000-0000-7000-8000-000000000701',
          'prestataire_nom': 'Boutique Yao',
          'ordre': 2,
          'statut': 'a_collecter',
        },
      },
      'coursier': coursier,
      'position': position,
      'remise': {
        'code_livraison': '7341',
        'jeton_reception': 'jeton-de-reception-de-test',
      },
      'substitution_en_attente': null,
    };

/// Monte l'écran avec une source de suivi FIGÉE — aucun réseau, comme le
/// veut l'injection par la portée (constitution XII).
Future<void> monter(
  WidgetTester tester, {
  required EtatSuivi etat,
}) async {
  // Écran LONG : sans une surface haute, le `ListView` ne construit pas le
  // bloc de remise et le test mesurerait l'absence d'un widget qui existe.
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: pasDeRetry,
    overrides: [
      sourceSuiviProvider.overrideWithValue((_) async => etat),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          MefaliCoreLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('fr')],
        locale: Locale('fr'),
        home: EcranSuivi(commandeId: _commande),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('C4-4a — collecte en cours', () {
    testWidgets('la progression compte les COLLECTES, jamais la remise',
        (tester) async {
      await monter(tester, etat: EtatSuivi.depuisJson(suiviJson()));

      // Le stepper porte « 2/3 » : 3 collectes, pas 4 arrêts (P1).
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('2/4'), findsNothing);
      expect(find.text('Collecte en cours 2/3'), findsOneWidget);
    });

    testWidgets("l'arrêt courant est NOMMÉ", (tester) async {
      await monter(tester, etat: EtatSuivi.depuisJson(suiviJson()));
      expect(find.text('Chez Boutique Yao'), findsOneWidget);
    });

    testWidgets('la position est affichée AVEC son âge', (tester) async {
      await monter(tester, etat: EtatSuivi.depuisJson(suiviJson()));
      expect(find.text('Position il y a 12 s'), findsOneWidget);
      expect(find.text('Position non disponible'), findsNothing);
    });

    testWidgets(
        "sans position, l'écran l'AVOUE au lieu d'en inventer une (R13)",
        (tester) async {
      await monter(
        tester,
        etat: EtatSuivi.depuisJson(suiviJson(position: null)),
      );
      expect(find.text('Position non disponible'), findsOneWidget);
    });

    testWidgets('le bloc « À la livraison » porte le QR et les 4 chiffres',
        (tester) async {
      await monter(tester, etat: EtatSuivi.depuisJson(suiviJson()));
      expect(find.text('À la livraison'), findsOneWidget);
      for (final chiffre in ['7', '3', '4', '1']) {
        expect(find.text(chiffre), findsOneWidget);
      }
    });
  });

  group('C4-4b — recherche de coursier', () {
    testWidgets('explique l\'attente et offre l\'annulation SANS FRAIS',
        (tester) async {
      await monter(
        tester,
        etat: EtatSuivi.depuisJson(suiviJson(
          etat: 'en_attente_coursier',
          etatCle: 'suivi.etat.recherche_coursier',
          faites: 0,
          position: null,
          coursier: null,
        )),
      );

      expect(find.text("Recherche d'un coursier"), findsOneWidget);
      expect(
        find.text("L'attente est plus longue que d'habitude."),
        findsOneWidget,
      );
      expect(find.text('Annuler sans frais'), findsOneWidget);
      // Le total est affiché avec `formaterMontant` : l'espace fine (U+202F)
      // ne se tape pas à l'identique dans un littéral.
      expect(find.text(formaterMontant(5900, 'XOF')), findsOneWidget);
    });

    testWidgets(
        "l'annulation sans frais DISPARAÎT dès qu'un arrêt est collecté",
        (tester) async {
      await monter(tester, etat: EtatSuivi.depuisJson(suiviJson()));
      expect(
        find.text('Annuler sans frais'),
        findsNothing,
        reason: 'un article acheté est un article dû : les règles d\'échec '
            'prennent le relais (CMD-07)',
      );
    });
  });

  group('C4-4d — hors ligne', () {
    /// Le cache local, tel que la confirmation de commande l'a écrit.
    CommandeCache cache({int ageS = 40, required DateTime majLe}) =>
        CommandeCache(
          commandeId: _commande,
          etat: 'en_cours',
          etatCle: 'suivi.etat.en_route_vers_vous',
          collectesFaites: 3,
          collectesTotal: 3,
          codeLivraison: '7341',
          jetonReception: 'jeton-de-reception-de-test',
          totalUnites: 5900,
          devise: 'XOF',
          positionLat: 5.899,
          positionLon: -4.821,
          positionAgeS: ageS,
          majLeLocal: majLe,
        );

    testWidgets(
        'annonce le DERNIER ÉTAT CONNU et rend quand même le bloc de remise',
        (tester) async {
      final maintenant = DateTime(2026, 7, 25, 15, 30);
      await monter(
        tester,
        etat: EtatSuivi.depuisCache(
          cache(majLe: maintenant),
          maintenant: maintenant,
        ),
      );

      expect(find.text('Hors connexion'), findsOneWidget);
      expect(
        find.textContaining('Dernier état connu'),
        findsOneWidget,
        reason: 'hors ligne, l\'écran ne prétend pas connaître l\'état courant',
      );
      // SC-009 : le bloc de remise se rend SANS RÉSEAU, depuis le cache seul.
      expect(find.text('À la livraison — disponible sans réseau'),
          findsOneWidget);
      for (final chiffre in ['7', '3', '4', '1']) {
        expect(find.text(chiffre), findsOneWidget);
      }
    });

    testWidgets("l'âge de la position VIEILLIT avec le temps écoulé",
        (tester) async {
      final majLe = DateTime(2026, 7, 25, 15, 30);
      // 40 s d'âge au moment du cache + 3 minutes écoulées depuis.
      await monter(
        tester,
        etat: EtatSuivi.depuisCache(
          cache(ageS: 40, majLe: majLe),
          maintenant: majLe.add(const Duration(minutes: 3)),
        ),
      );
      expect(
        find.text('Position il y a 220 s'),
        findsOneWidget,
        reason: 'réafficher l\'âge FIGÉ rajeunirait la position à chaque '
            'ouverture de l\'écran (FR-040)',
      );
    });

    testWidgets('le stepper est MASQUÉ hors ligne', (tester) async {
      final maintenant = DateTime(2026, 7, 25, 15, 30);
      await monter(
        tester,
        etat: EtatSuivi.depuisCache(
          cache(majLe: maintenant),
          maintenant: maintenant,
        ),
      );
      expect(
        find.text('3/3'),
        findsNothing,
        reason: 'un stepper AFFIRME une progression — hors ligne, on ne peut '
            'rien affirmer (maquette C4-4d)',
      );
    });
  });
}
