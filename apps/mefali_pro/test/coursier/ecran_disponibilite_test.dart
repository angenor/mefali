/// Tests widget de l'écran **K1 — disponibilité** (DSP-01, T030/T031).
///
/// Cible visuelle : `docs/design/png/K1-disponibilite.png`. Ce que ces tests
/// prouvent, et qui compte pour Yao :
///
/// - le **plafond retenu** affiché est bien `min(déclaré, grille)`, et l'écran
///   dit **lequel** s'applique — sans quoi un refus de course paraîtrait être un
///   bug (FR-010) ;
/// - un **nouveau jour** redemande le plafond, jamais de report tacite (FR-011) ;
/// - le **bandeau de reconnexion** apparaît quand le réseau lâche, ce qui est
///   honnête : passé le TTL, Yao sera effectivement sorti du pool.
///
/// Les vues se construisent depuis le **corps JSON du contrat**, jamais depuis
/// un DTO : c'est ce chemin-là que couvre l'app (leçon du cycle 008).
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/coursier/disponibilite/ecran_disponibilite.dart';
import 'package:mefali_pro/coursier/disponibilite/emetteur_position.dart';
import 'package:mefali_pro/coursier/disponibilite/etat_disponibilite.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';

/// Corps de `GET|PUT /moi/disponibilite`, tel que le contrat le rend.
Map<String, Object?> _etat({
  bool enLigne = false,
  int? plafondDeclare = 15000,
  int plafondRetenu = 5000,
  String source = 'grille_note',
  String palier = 'dispatch.palier.entree',
  bool dansLePool = false,
}) =>
    {
      'en_ligne': enLigne,
      'plafond_declare_unites': plafondDeclare,
      'plafond_retenu_unites': plafondRetenu,
      'plafond_source': source,
      'palier_note_cle': palier,
      'note_centiemes': null,
      'devise': 'XOF',
      'jour': '2026-07-27',
      'capacites': [
        {'famille': 'transport', 'valeur': 'moto'},
      ],
      'dans_le_pool': dansLePool,
      'periode_position_s': 30,
    };

(ProviderContainer, TransportFake) _conteneur(
  Map<String, Object?> etat, {
  bool reseauCoupe = false,
}) {
  final transport = TransportFake((requete) {
    if (requete.path.contains('/moi/disponibilite')) {
      if (reseauCoupe) {
        throw DioException.connectionError(
          requestOptions: requete,
          reason: 'réseau coupé',
        );
      }
      return reponseJson(etat);
    }
    return reponseJson({'code': 'introuvable'}, statut: 404);
  });
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

/// Source de positions INERTE — un test widget n'a ni capteur ni permission,
/// et le vrai `geolocator` laisserait un minuteur pendant après la destruction
/// de l'arbre. Injectée par la PORTÉE (constitution XII), jamais par
/// constructeur : c'est ce qui prouve que l'écran ne connaît pas sa source.
Stream<Position> _aucunePosition(LocationSettings _) => const Stream.empty();

/// Permission ACCORDÉE sans dialogue — un test widget n'en ouvre aucun.
Future<bool> _permissionAccordee() async => true;

/// Position de Tiassalé, rendue par le relevé ponctuel du double.
Position _positionTiassale() => Position(
      latitude: 5.8960,
      longitude: -4.8210,
      timestamp: DateTime(2026, 7, 27, 12),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// Le capteur RÉPOND, sans jamais rien émettre de nouveau : c'est l'état
/// d'un coursier arrêté.
Future<Position?> _relevePonctuelFixe() async => _positionTiassale();

Widget _monter(ProviderContainer container) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(
        overrides: [
          sourcePositionsProvider.overrideWithValue(_aucunePosition),
          // Aucun dialogue système dans un test widget.
          permissionPositionProvider.overrideWithValue(_permissionAccordee),
          relevePonctuelProvider.overrideWithValue(_relevePonctuelFixe),
        ],
        child: const EcranDisponibilite(),
      ),
    );

void main() {
  testWidgets(
    'le plafond retenu est affiché avec sa source — Yao voit lequel s\'applique',
    (tester) async {
      final (container, _) = _conteneur(_etat());
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      // Déclaré 15 000, mais le palier d'entrée plafonne à 5 000 : c'est LUI
      // qui décide, et l'écran doit le dire (FR-010, research R7).
      expect(find.byKey(const Key('dispo-plafond-retenu')), findsOneWidget);
      expect(find.textContaining('5\u202f000'), findsWidgets);
      final source = tester.widget<Text>(find.byKey(const Key('dispo-plafond-source')));
      expect(
        source.data,
        'Votre palier limite l\'avance',
        reason: 'sans cette phrase, un refus de course paraîtrait être un bug',
      );
      final palier = tester.widget<Text>(find.byKey(const Key('dispo-palier')));
      expect(palier.data, 'Palier d\'entrée');
    },
  );

  testWidgets(
    'une déclaration plus basse que le palier s\'applique telle quelle',
    (tester) async {
      final (container, _) = _conteneur(
        _etat(plafondDeclare: 3000, plafondRetenu: 3000, source: 'declaration'),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      final source = tester.widget<Text>(find.byKey(const Key('dispo-plafond-source')));
      expect(source.data, 'C\'est votre déclaration qui s\'applique');
      expect(find.textContaining('3\u202f000'), findsWidgets);
    },
  );

  testWidgets(
    'un nouveau jour redemande le plafond — jamais de report tacite',
    (tester) async {
      final (container, _) = _conteneur(_etat(plafondDeclare: null));
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dispo-nouveau-jour')),
        findsOneWidget,
        reason: 'reporter le plafond de la veille exposerait un coursier qui '
            'n\'a plus l\'argent (FR-011)',
      );
      // Et le stepper propose le défaut, pas le montant d'hier.
      expect(find.textContaining('10\u202f000'), findsWidgets);
    },
  );

  testWidgets('le réseau coupé affiche le bandeau de reconnexion', (tester) async {
    final (container, _) = _conteneur(_etat(), reseauCoupe: true);
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    expect(
      find.byType(BandeauHorsLigne),
      findsOneWidget,
      reason: 'honnête : passé le TTL, Yao sera effectivement sorti du pool',
    );
  });

  testWidgets(
    'le plafond est verrouillé en ligne — on ne change pas son avance sous une offre en vol',
    (tester) async {
      final (container, _) = _conteneur(
        _etat(enLigne: true, dansLePool: true, plafondDeclare: 8000, plafondRetenu: 5000),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dispo-plafond-moins')), findsNothing);
      expect(find.byKey(const Key('dispo-plafond-plus')), findsNothing);
      expect(find.byKey(const Key('dispo-passer-hors-ligne')), findsOneWidget);
      expect(find.text('Verrouillé'), findsOneWidget);
    },
  );

  testWidgets('le stepper change le montant par pas de 1 000', (tester) async {
    final (container, _) = _conteneur(_etat(plafondDeclare: null));
    addTearDown(container.dispose);
    await tester.pumpWidget(_monter(container));
    await tester.pumpAndSettle();

    String? montant() => tester
        .widget<Text>(find.byKey(const Key('dispo-plafond-montant')))
        .data;
    expect(montant(), '10\u202f000\u202fFCFA');

    await tester.tap(find.byKey(const Key('dispo-plafond-plus')));
    await tester.pump();
    expect(montant(), '11\u202f000\u202fFCFA');

    await tester.tap(find.byKey(const Key('dispo-plafond-moins')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dispo-plafond-moins')));
    await tester.pump();
    expect(montant(), '9\u202f000\u202fFCFA');
  });

  testWidgets(
    'un refus métier est traduit par sa clé, pas par un message générique',
    (tester) async {
      final transport = TransportFake((requete) {
        if (requete.method == 'GET') return reponseJson(_etat());
        return reponseJson(
          {'code': 'course_active', 'message_cle': 'dispatch.erreur.course_active'},
          statut: 409,
        );
      });
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
        transport: transport,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dispo-passer-en-ligne')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dispo-erreur')), findsOneWidget);
      expect(
        find.text('Terminez votre course avant de passer hors ligne.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un coursier ARRÊTÉ reste dans le pool : la cadence de zone publie sans lui',
    (tester) async {
      // Ce que ce test protège : le capteur ne parle que si Yao BOUGE
      // (`distanceFilter`). Or le cas nominal de DSP-01 est un coursier arrêté,
      // qui attend au carrefour pendant que son écran dit « en attente de
      // courses ». Sans cadence, il ne publie plus rien et sort du pool par
      // expiration du TTL (90 s) — sans que rien ne le lui dise.
      //
      // Trouvé sur émulateur (T071) : le pool était VIDE pendant que K1
      // affichait « en attente de courses ».
      var publications = 0;
      final transport = TransportFake((requete) {
        if (requete.path.contains('/moi/position')) {
          publications++;
          return reponseJson({'dans_le_pool': true, 'prochaine_publication_s': 30});
        }
        if (requete.path.contains('/moi/disponibilite')) {
          return reponseJson(_etat(enLigne: true, dansLePool: true));
        }
        return reponseJson({'code': 'introuvable'}, statut: 404);
      });
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
        transport: transport,
      );
      addTearDown(container.dispose);

      // Le capteur ne dit RIEN — pas un seul relevé : c'est exactement l'état
      // d'un coursier arrêté, que `distanceFilter` rend muet.
      Stream<Position> capteurMuet(LocationSettings _) => const Stream.empty();

      await tester.pumpWidget(
        harnaisApp(
          container: container,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            MefaliCoreLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProviderScope(
            overrides: [
              sourcePositionsProvider.overrideWithValue(capteurMuet),
              permissionPositionProvider.overrideWithValue(_permissionAccordee),
              relevePonctuelProvider.overrideWithValue(_relevePonctuelFixe),
            ],
            child: const EcranDisponibilite(),
          ),
        ),
      );
      // Plusieurs tours : le chargement de la disponibilité, puis la demande
      // de PERMISSION, sont tous deux asynchrones — et c'est la permission qui
      // débloque l'abonnement au capteur (T071 : sans elle le flux reste muet,
      // et le coursier n'entre jamais dans le pool).
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final apresReleve = publications;
      expect(
        apresReleve,
        greaterThanOrEqualTo(1),
        reason: 'le premier relevé de CADENCE publie, même capteur muet',
      );

      // Deux cadences plus tard, immobile : la publication a CONTINUÉ.
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        publications,
        greaterThan(apresReleve),
        reason: 'immobile, Yao doit RESTER dans le pool — sinon il croit '
            'travailler pendant qu\'aucune course ne peut lui parvenir',
      );

      // L'écran doit alors être démonté proprement (le Timer de cadence est
      // annulé par `ref.onDispose`), sans minuteur pendant.
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('l\'état se construit depuis le corps JSON du contrat', () {
    final etat = EtatDisponibilite.depuisJson(_etat(enLigne: true, dansLePool: true));
    expect(etat.enLigne, isTrue);
    expect(etat.plafondDeclareUnites, 15000);
    expect(etat.plafondRetenuUnites, 5000);
    expect(etat.source, SourcePlafond.grilleNote);
    expect(etat.capacites, ['moto']);
    expect(etat.periodePositionS, 30);
    expect(etat.plafondADeclarer, isFalse);

    // Un jour sans déclaration se distingue d'un plafond nul.
    final neuf = EtatDisponibilite.depuisJson(_etat(plafondDeclare: null));
    expect(neuf.plafondADeclarer, isTrue);
  });
}
