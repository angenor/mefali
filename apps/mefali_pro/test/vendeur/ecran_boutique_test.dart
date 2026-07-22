import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/vendeur/boutique/ecran_boutique.dart';

const _prestataire = '01900000-0000-7000-8000-000000000502';

Map<String, Object?> _pilotable() => {
      'id': _prestataire,
      'nom': 'Étal Tantie Affoué',
      'statut': 'agree',
      'boutique': {'ouvert': true, 'reouverture_estimee': null},
    };

List<List<Map<String, String>>> _semaine() => [
      for (var j = 0; j < 6; j++) [
        {'debut': '08:00', 'fin': '19:00'},
      ],
      <Map<String, String>>[],
    ];

Map<String, Object?> _boutique({
  String statut = 'ouvert',
  bool effectifOuvert = true,
  String? pauseFin,
  bool rappel = false,
  List<Map<String, String>>? horairesDuJour,
}) =>
    {
      'statut': statut,
      'pause_fin': pauseFin,
      'etat_effectif': {'ouvert': effectifOuvert, 'reouverture_estimee': null},
      'horaires': {'jours': _semaine()},
      'horaires_du_jour': horairesDuJour ??
          [
            {'debut': '08:00', 'fin': '19:00'},
          ],
      'rappel_ouverture': rappel,
    };

(ProviderContainer, TransportFake) _conteneur(Map<String, Object?> boutique) {
  final transport = TransportFake((requete) {
    if (requete.path.endsWith('/vendeur/prestataires')) {
      return reponseJson([_pilotable()]);
    }
    if (requete.path.endsWith('/boutique') ||
        requete.path.endsWith('/boutique/action')) {
      return reponseJson(boutique);
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: EcranBoutique()),
    );

RequestOptions _dernierPost(TransportFake transport) =>
    transport.recues.lastWhere((r) => r.method == 'POST');

void main() {
  group('EcranBoutique — V1 statut boutique (FR-044)', () {
    testWidgets('état 1a ouvert : interrupteur + pause 30 min / 1 h / 2 h',
        (tester) async {
      final (container, transport) = _conteneur(_boutique());
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(find.text('OUVERT'), findsNWidgets(2), reason: 'puce + moitié');
      expect(find.text('Votre boutique reçoit les commandes'), findsOneWidget);
      for (final duree in ['30 min', '1 h', '2 h']) {
        expect(find.text(duree), findsOneWidget);
      }

      // UN geste : la pause part avec sa durée (FR-033).
      await tester.tap(find.text('30 min'));
      await tester.pumpAndSettle();
      final corps =
          Map<String, Object?>.from(_dernierPost(transport).data as Map);
      expect(corps['action'], 'mettre_en_pause');
      expect(corps['duree_minutes'], 30);
    });

    testWidgets(
        'état 1b en pause : la pause remplace l\'interrupteur — prolonger, '
        'fermer pour aujourd\'hui, réouvrir', (tester) async {
      final echeance =
          DateTime.now().add(const Duration(minutes: 22)).toUtc().toIso8601String();
      final (container, transport) = _conteneur(_boutique(
        statut: 'en_pause',
        effectifOuvert: false,
        pauseFin: echeance,
      ));
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(find.text('EN PAUSE'), findsOneWidget);
      expect(find.text('Réouverture automatique dans'), findsOneWidget);
      expect(find.text('+ 30 min'), findsOneWidget);
      expect(find.text('Fermer pour aujourd\'hui'), findsOneWidget);
      expect(find.text('Réouvrir maintenant'), findsOneWidget);
      expect(
        find.text('Faire une pause'),
        findsNothing,
        reason: 'la carte de pause 1a est remplacée',
      );

      await tester.tap(find.text('+ 30 min'));
      await tester.pumpAndSettle();
      final corps =
          Map<String, Object?>.from(_dernierPost(transport).data as Map);
      expect(corps['action'], 'prolonger_pause');
      expect(corps['duree_minutes'], 30);
    });

    testWidgets(
        'état 1c fermé + rappel doux : « je reste fermé » = fermer pour la '
        'journée (FR-035, R4)', (tester) async {
      final (container, transport) = _conteneur(_boutique(
        statut: 'ferme',
        effectifOuvert: false,
        rappel: true,
      ));
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('D\'habitude, votre boutique est ouverte'),
        findsOneWidget,
      );
      expect(find.text('Ouvrir maintenant'), findsOneWidget);

      await tester.tap(find.text('Je reste fermé aujourd\'hui'));
      await tester.pumpAndSettle();
      final corps =
          Map<String, Object?>.from(_dernierPost(transport).data as Map);
      expect(corps['action'], 'fermer_pour_la_journee');
    });

    testWidgets(
        'carte horaires : un jour SANS plage affiche « Fermé aujourd\'hui » '
        'une seule fois (pas de « aujourd\'hui aujourd\'hui »)', (tester) async {
      final (container, _) = _conteneur(_boutique(
        statut: 'ferme',
        effectifOuvert: false,
        horairesDuJour: const [],
      ));
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(find.text('Fermé aujourd\'hui'), findsOneWidget);
      expect(
        find.textContaining('aujourd\'hui aujourd\'hui'),
        findsNothing,
        reason: 'le suffixe « aujourd\'hui » ne doit pas être doublé',
      );
    });

    testWidgets('carte horaires : un jour AVEC plages suffixe « aujourd\'hui »',
        (tester) async {
      final (container, _) = _conteneur(_boutique(horairesDuJour: const [
        {'debut': '08:00', 'fin': '19:00'},
      ]));
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(find.text('08:00 — 19:00 aujourd\'hui'), findsOneWidget);
    });
  });
}
