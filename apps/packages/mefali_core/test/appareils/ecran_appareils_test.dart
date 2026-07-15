import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Adaptateur dio qui répond des réponses PRÉ-ÉCRITES, sans réseau.
///
/// On branche l'API générée sur un faux transport plutôt que de simuler
/// `MoiApi` : ce qui doit être prouvé, c'est que l'écran parle bien au client
/// GÉNÉRÉ et sait lire ce que le backend émet réellement.
class _Transport implements HttpClientAdapter {
  _Transport(this.repondre);

  final ResponseBody Function(RequestOptions requete) repondre;
  final List<RequestOptions> recues = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recues.add(options);
    return repondre(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object corps, {int statut = 200}) => ResponseBody.fromString(
      jsonEncode(corps),
      statut,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, Object?> _appareil(
  String id,
  String nom, {
  bool courante = false,
}) =>
    {
      'id': id,
      'appareil_nom': nom,
      'appareil_plateforme': 'android',
      'cree_le': '2026-07-14T10:00:00Z',
      'derniere_activite_le': '2026-07-14T12:00:00Z',
      'courante': courante,
    };

const String _idA = '01900000-0000-7000-8000-0000000000a1';
const String _idB = '01900000-0000-7000-8000-0000000000b2';

(SessionAuth, _Transport) _session(
  ResponseBody Function(RequestOptions) repondre, {
  JetonsSession? jetons = const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
}) {
  final transport = _Transport(repondre);
  final client = MefaliApiClient(basePathOverride: 'http://test.invalid');
  client.dio.httpClientAdapter = transport;
  final session = SessionAuth(
    stockage: StockageJetonsMemoire(jetons),
    client: client,
  );
  return (session, transport);
}

Widget _monter(Widget enfant) => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: enfant,
    );

void main() {
  group('EcranAppareils', () {
    testWidgets('liste les appareils et marque celui-ci', (tester) async {
      final (session, _) = _session(
        (_) => _json([
          _appareil(_idA, 'Pixel de poche', courante: true),
          _appareil(_idB, 'Téléphone perdu'),
        ]),
      );
      await session.charger();

      await tester.pumpWidget(_monter(EcranAppareils(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Pixel de poche'), findsOneWidget);
      expect(find.text('Téléphone perdu'), findsOneWidget);
      expect(find.text('Cet appareil'), findsOneWidget);
    });

    testWidgets(
        'la session courante n\'offre PAS de déconnexion à distance — se couper '
        'soi-même laisserait un écran mort', (tester) async {
      final (session, _) = _session(
        (_) => _json([
          _appareil(_idA, 'Pixel de poche', courante: true),
          _appareil(_idB, 'Téléphone perdu'),
        ]),
      );
      await session.charger();

      await tester.pumpWidget(_monter(EcranAppareils(session: session)));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Symbols.logout),
        findsOneWidget,
        reason: 'un seul bouton : celui de l\'appareil distant',
      );
    });

    testWidgets('révoquer appelle DELETE puis recharge la liste',
        (tester) async {
      var supprime = false;
      final (session, transport) = _session((requete) {
        if (requete.method == 'DELETE') {
          supprime = true;
          return ResponseBody.fromString('', 204);
        }
        return _json([
          _appareil(_idA, 'Pixel de poche', courante: true),
          if (!supprime) _appareil(_idB, 'Téléphone perdu'),
        ]);
      });
      await session.charger();

      await tester.pumpWidget(_monter(EcranAppareils(session: session)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Symbols.logout));
      await tester.pumpAndSettle();

      expect(supprime, isTrue);
      expect(
        transport.recues.any((r) => r.method == 'DELETE' && r.path.contains(_idB)),
        isTrue,
        reason: 'c\'est bien l\'appareil DISTANT qui est révoqué',
      );
      expect(find.text('Téléphone perdu'), findsNothing);
      expect(find.text('Pixel de poche'), findsOneWidget);
    });

    testWidgets('un échec réseau affiche un message, pas un écran blanc',
        (tester) async {
      final (session, _) = _session((_) => _json({'code': 'x'}, statut: 500));
      await session.charger();

      await tester.pumpWidget(_monter(EcranAppareils(session: session)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Impossible de charger'), findsOneWidget);
    });
  });

  group('Rafraîchissement automatique (US2 scénario 2)', () {
    testWidgets('un 401 déclenche le renouvellement et rejoue la requête',
        (tester) async {
      var appelsMoi = 0;
      final (session, transport) = _session((requete) {
        if (requete.path.contains('/auth/rafraichir')) {
          return _json({'acces': 'jwt-neuf', 'rafraichissement': 'r-neuf'});
        }
        appelsMoi++;
        // Le premier appel tombe sur un accès expiré ; le rejeu passe.
        if (appelsMoi == 1) {
          return _json({'code': 'non_authentifie'}, statut: 401);
        }
        return _json([_appareil(_idA, 'Pixel de poche', courante: true)]);
      });
      await session.charger();

      await tester.pumpWidget(_monter(EcranAppareils(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Pixel de poche'), findsOneWidget,
          reason: 'le renouvellement est SILENCIEUX — aucun OTB redemandé');
      expect(session.acces, 'jwt-neuf');
      expect(session.rafraichissement, 'r-neuf');
      expect(
        transport.recues.where((r) => r.path.contains('/auth/rafraichir')).length,
        1,
        reason: 'un seul renouvellement',
      );
    });

    testWidgets(
        'un refresh REFUSÉ ferme la session : l\'appareil révoqué à distance '
        'repart sur l\'authentification (SC-004)', (tester) async {
      final (session, _) = _session((requete) {
        if (requete.path.contains('/auth/rafraichir')) {
          return _json({'code': 'non_authentifie'}, statut: 401);
        }
        return _json({'code': 'non_authentifie'}, statut: 401);
      });

      await tester.pumpWidget(
        _monter(
          RacineAuth(
            session: session,
            nomAppareil: 'Test',
            demarrage: const Scaffold(body: Text('démarrage')),
            accueil: (_) => EcranAppareils(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(session.connecte, isFalse, reason: 'les jetons sont effacés');
      expect(find.text('Votre numéro'), findsOneWidget);
    });

    testWidgets('le renouvellement ne se renouvelle pas lui-même (anti-boucle)',
        (tester) async {
      var appels = 0;
      final (session, _) = _session((requete) {
        if (requete.path.contains('/auth/rafraichir')) {
          appels++;
          return _json({'code': 'non_authentifie'}, statut: 401);
        }
        return _json({'code': 'non_authentifie'}, statut: 401);
      });
      await session.charger();

      await tester.pumpWidget(_monter(EcranAppareils(session: session)));
      await tester.pumpAndSettle();

      expect(appels, 1, reason: 'un 401 sur /auth/rafraichir ne se rejoue jamais');
    });
  });
}
