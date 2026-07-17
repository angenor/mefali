import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

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

/// Conteneur monté sur un transport factice. On surcharge les DÉPENDANCES
/// (stockage via `jetons`, transport) ; JAMAIS `sessionProvider`.
(ProviderContainer, TransportFake) _conteneur(
  FutureOr<ResponseBody> Function(RequestOptions) repondre, {
  JetonsSession? jetons = const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
}) {
  final transport = TransportFake(repondre);
  final container = conteneurMefali(jetons: jetons, transport: transport);
  return (container, transport);
}

Widget _monter(ProviderContainer container, Widget home) => harnaisApp(
      container: container,
      localizationsDelegates: MefaliCoreLocalizations.localizationsDelegates,
      supportedLocales: MefaliCoreLocalizations.supportedLocales,
      home: home,
    );

/// Démonte l'arbre puis dispose le conteneur DANS le corps (cas montant
/// RacineAuth : ServiceConfig porte un Timer que flutter_test verrait « pending »
/// si le conteneur n'était disposé qu'en addTearDown).
Future<void> _fin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

void main() {
  group('EcranAppareils', () {
    testWidgets('liste les appareils et marque celui-ci', (tester) async {
      final (container, _) = _conteneur(
        (_) => reponseJson([
          _appareil(_idA, 'Pixel de poche', courante: true),
          _appareil(_idB, 'Téléphone perdu'),
        ]),
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const EcranAppareils()));
      await tester.pumpAndSettle();

      expect(find.text('Pixel de poche'), findsOneWidget);
      expect(find.text('Téléphone perdu'), findsOneWidget);
      expect(find.text('Cet appareil'), findsOneWidget);
    });

    testWidgets(
        'la session courante n\'offre PAS de déconnexion à distance — se couper '
        'soi-même laisserait un écran mort', (tester) async {
      final (container, _) = _conteneur(
        (_) => reponseJson([
          _appareil(_idA, 'Pixel de poche', courante: true),
          _appareil(_idB, 'Téléphone perdu'),
        ]),
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const EcranAppareils()));
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
      final (container, transport) = _conteneur((requete) {
        if (requete.method == 'DELETE') {
          supprime = true;
          return ResponseBody.fromString('', 204);
        }
        return reponseJson([
          _appareil(_idA, 'Pixel de poche', courante: true),
          if (!supprime) _appareil(_idB, 'Téléphone perdu'),
        ]);
      });
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const EcranAppareils()));
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
      final (container, _) = _conteneur((_) => reponseJson({'code': 'x'}, statut: 500));
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const EcranAppareils()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Impossible de charger'), findsOneWidget);
    });
  });

  group('Rafraîchissement automatique (US2 scénario 2)', () {
    testWidgets('un 401 déclenche le renouvellement et rejoue la requête',
        (tester) async {
      var appelsMoi = 0;
      final (container, transport) = _conteneur((requete) {
        if (requete.path.contains('/auth/rafraichir')) {
          return reponseJson({'acces': 'jwt-neuf', 'rafraichissement': 'r-neuf'});
        }
        appelsMoi++;
        // Le premier appel tombe sur un accès expiré ; le rejeu passe.
        if (appelsMoi == 1) {
          return reponseJson({'code': 'non_authentifie'}, statut: 401);
        }
        return reponseJson([_appareil(_idA, 'Pixel de poche', courante: true)]);
      });
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const EcranAppareils()));
      await tester.pumpAndSettle();

      expect(find.text('Pixel de poche'), findsOneWidget,
          reason: 'le renouvellement est SILENCIEUX — aucun OTP redemandé');
      expect(container.read(sessionProvider).acces, 'jwt-neuf');
      expect(container.read(sessionProvider).rafraichissement, 'r-neuf');
      expect(
        transport.recues.where((r) => r.path.contains('/auth/rafraichir')).length,
        1,
        reason: 'un seul renouvellement',
      );
    });

    testWidgets(
        'un refresh REFUSÉ ferme la session : l\'appareil révoqué à distance '
        'repart sur l\'authentification (SC-004)', (tester) async {
      // Ne PAS appeler charger() : le déclenchement repose sur RacineAuth.initState
      // (FR-002) — le trigger doit y rester.
      final (container, _) = _conteneur(
        (requete) => reponseJson({'code': 'non_authentifie'}, statut: 401),
      );

      await tester.pumpWidget(
        _monter(
          container,
          RacineAuth(
            nomAppareil: 'Test',
            demarrage: const Scaffold(body: Text('démarrage')),
            accueil: (_) => const EcranAppareils(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).connecte, isFalse,
          reason: 'les jetons sont effacés');
      expect(find.text('Votre numéro'), findsOneWidget);
      await _fin(tester, container);
    });

    testWidgets('le renouvellement ne se renouvelle pas lui-même (anti-boucle)',
        (tester) async {
      var appels = 0;
      final (container, _) = _conteneur((requete) {
        if (requete.path.contains('/auth/rafraichir')) {
          appels++;
          return reponseJson({'code': 'non_authentifie'}, statut: 401);
        }
        return reponseJson({'code': 'non_authentifie'}, statut: 401);
      });
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const EcranAppareils()));
      await tester.pumpAndSettle();

      expect(appels, 1, reason: 'un 401 sur /auth/rafraichir ne se rejoue jamais');
    });
  });
}
