import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/roles/etat_roles.dart';
import 'package:mefali_pro/roles/routeur_roles.dart';

/// Adaptateur dio qui répond des réponses PRÉ-ÉCRITES, sans réseau.
///
/// On branche l'API générée sur un faux transport plutôt que de simuler
/// `MoiApi` : ce qui doit être prouvé, c'est que le routeur parle bien au client
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

const String _idCompte = '01900000-0000-7000-8000-000000000401';

/// Fixture = wireNames RÉELS du backend (contrat `CompteMoi`), jamais des
/// objets built_value : c'est le contrat que l'on veut tester, pas le mapping.
Map<String, Object?> _compte(List<Map<String, Object?>> roles) => {
      'id': _idCompte,
      'telephone_e164': '+2250701020304',
      'zone_id': '01900000-0000-7000-8000-000000000002',
      'roles': roles,
      'cree_le': '2026-07-14T10:00:00Z',
    };

Map<String, Object?> _role(String role, String statut, {String? motif}) => {
      'role': role,
      'statut': statut,
      'motif': ?motif,
      'decide_le': '2026-07-14T12:00:00Z',
    };

(SessionAuth, _Transport) _session(ResponseBody Function(RequestOptions) repondre) {
  final transport = _Transport(repondre);
  final client = MefaliApiClient(basePathOverride: 'http://test.invalid');
  client.dio.httpClientAdapter = transport;
  final session = SessionAuth(
    stockage: StockageJetonsMemoire(
      const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    ),
    client: client,
  );
  return (session, transport);
}

Widget _monter(Widget enfant) => MaterialApp(
      theme: MefaliTheme.light,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: enfant,
    );

void main() {
  group('RouteurRoles — porte de Mefali Pro (FR-013)', () {
    testWidgets(
      'un compte sans rôle pro validé voit l\'état de sa demande, pas une interface pro',
      (tester) async {
        final (session, _) = _session(
          (_) => _json(_compte([_role('client', 'valide')])),
        );
        await session.charger();

        await tester.pumpWidget(_monter(RouteurRoles(session: session)));
        await tester.pumpAndSettle();

        expect(
          find.text('Aucun rôle professionnel'),
          findsOneWidget,
          reason: 'un compte purement client n\'a aucune fonction pro (FR-011)',
        );
        expect(
          find.text('Espace coursier'),
          findsNothing,
          reason: 'aucune interface pro ne doit fuiter sans rôle validé',
        );
        expect(
          find.text('Le rôle vendeur est attribué par Mefali lors de votre agrément.'),
          findsOneWidget,
          reason: 'le vendeur ne se demande pas in-app (cadrage §5.1)',
        );
      },
    );

    testWidgets('une demande coursier en attente n\'ouvre AUCUN privilège', (tester) async {
      final (session, _) = _session(
        (_) => _json(
          _compte([_role('client', 'valide'), _role('coursier', 'en_attente')]),
        ),
      );
      await session.charger();

      await tester.pumpWidget(_monter(RouteurRoles(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Dossier en cours d\'examen'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget, reason: 'puce de statut du rôle');
      expect(find.text('Coursier'), findsOneWidget, reason: 'carte du rôle demandé');
      expect(
        find.text('Espace coursier'),
        findsNothing,
        reason: 'SC-005 — « en attente » ne franchit pas la porte',
      );
    });

    testWidgets('un refus affiche son motif, tel que l\'admin l\'a écrit', (tester) async {
      final (session, _) = _session(
        (_) => _json(
          _compte([
            _role('client', 'valide'),
            _role('coursier', 'refuse', motif: 'Pièce d\'identité illisible'),
          ]),
        ),
      );
      await session.charger();

      await tester.pumpWidget(_monter(RouteurRoles(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Dossier refusé'), findsOneWidget);
      expect(find.text('Refusé'), findsOneWidget);
      expect(
        find.text('Pièce d\'identité illisible'),
        findsOneWidget,
        reason: 'FR-014 — la décision est journalisée AVEC son motif, et rendue',
      );
    });

    testWidgets('un rôle suspendu referme la porte et le dit', (tester) async {
      final (session, _) = _session(
        (_) => _json(
          _compte([
            _role('client', 'valide'),
            _role('coursier', 'suspendu', motif: 'Plaintes répétées'),
          ]),
        ),
      );
      await session.charger();

      await tester.pumpWidget(_monter(RouteurRoles(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Rôle suspendu'), findsOneWidget);
      expect(find.text('Plaintes répétées'), findsOneWidget);
      expect(find.text('Espace coursier'), findsNothing);
    });

    testWidgets('un seul rôle validé ouvre son interface, sans sélecteur', (tester) async {
      final (session, _) = _session(
        (_) => _json(
          _compte([_role('client', 'valide'), _role('vendeur', 'valide')]),
        ),
      );
      await session.charger();

      await tester.pumpWidget(_monter(RouteurRoles(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Espace vendeur'), findsOneWidget);
      expect(
        find.byType(SegmentedButton<RolePro>),
        findsNothing,
        reason: 'un mono-rôle n\'a rien à basculer',
      );
    });

    testWidgets('un échec réseau affiche une erreur réessayable, pas un écran blanc',
        (tester) async {
      var appels = 0;
      final (session, _) = _session((_) {
        appels++;
        if (appels == 1) return _json({'code': 'x', 'message_cle': 'y'}, statut: 500);
        return _json(_compte([_role('client', 'valide'), _role('coursier', 'valide')]));
      });
      await session.charger();

      await tester.pumpWidget(_monter(RouteurRoles(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('Connexion impossible'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Espace coursier'),
        findsOneWidget,
        reason: 'le réseau revenu, l\'écran se répare sans redémarrage',
      );
    });
  });

  group('Bascule entre rôles validés (SC-006)', () {
    testWidgets('bascule_role_sans_reconnexion', (tester) async {
      final (session, transport) = _session(
        (_) => _json(
          _compte([
            _role('client', 'valide'),
            _role('coursier', 'valide'),
            _role('vendeur', 'valide'),
          ]),
        ),
      );
      await session.charger();
      final accesAvant = session.acces;

      await tester.pumpWidget(_monter(RouteurRoles(session: session)));
      await tester.pumpAndSettle();

      // Le premier rôle validé (ordre de l'énum backend) ouvre l'app.
      expect(find.text('Espace coursier'), findsOneWidget);
      final appelsApresChargement = transport.recues.length;

      await tester.tap(find.text('Vendeur'));
      await tester.pumpAndSettle();

      expect(
        find.text('Espace vendeur'),
        findsOneWidget,
        reason: 'FR-013 — la bascule change bien d\'interface',
      );
      expect(
        transport.recues.length,
        appelsApresChargement,
        reason: 'SC-006 — basculer ne parle PAS au réseau : rien à attendre, '
            'donc bien en dessous des 5 s même hors couverture',
      );
      expect(
        session.acces,
        accesAvant,
        reason: 'SC-006 — « sans reconnexion » : la session n\'est pas touchée',
      );

      await tester.tap(find.text('Coursier'));
      await tester.pumpAndSettle();
      expect(find.text('Espace coursier'), findsOneWidget, reason: 'et retour');
    });

    // À partir d'ici, des tests de LOGIQUE : `test` et non `testWidgets`.
    // `testWidgets` fait tourner une horloge SIMULÉE qu'aucun `pump` n'avance
    // ici — un `await` sur une réponse dio y resterait suspendu pour toujours.
    test('la bascule ignore un rôle non validé (SC-005)', () async {
      final (session, _) = _session((_) => _json(_compte([])));
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);

      await session.charger();
      await etat.charger();
      expect(etat.actif, isNull);

      etat.basculer(RolePro.coursier);

      expect(
        etat.actif,
        isNull,
        reason: 'la bascule n\'est pas un contournement de la validation admin',
      );
    });

    test('un rôle suspendu entre deux chargements ne reste pas affiché', () async {
      var appels = 0;
      final (session, _) = _session((_) {
        appels++;
        return _json(
          _compte([
            _role('client', 'valide'),
            // Le coursier est suspendu au 2e chargement.
            _role('coursier', appels == 1 ? 'valide' : 'suspendu'),
            _role('vendeur', 'valide'),
          ]),
        );
      });
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);
      await session.charger();

      await etat.charger();
      expect(etat.actif, RolePro.coursier);

      await etat.charger();

      expect(
        etat.actif,
        RolePro.vendeur,
        reason: 'un rôle suspendu ne peut pas rester l\'interface affichée',
      );
    });
  });

  group('EtatRoles — lecture du contrat', () {
    test('un statut inconnu du backend ferme la porte au lieu de l\'ouvrir', () async {
      final (session, _) = _session(
        (_) => _json(_compte([_role('coursier', 'statut_du_futur')])),
      );
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);
      await session.charger();

      await etat.charger();

      expect(etat.rolesValides, isEmpty, reason: 'SC-005 — fail-closed');
      expect(etat.statut(RolePro.coursier), StatutRolePro.aucun);
    });

    test('les rôles non professionnels sont ignorés', () async {
      final (session, _) = _session(
        (_) => _json(
          _compte([_role('client', 'valide'), _role('admin', 'valide')]),
        ),
      );
      final etat = EtatRoles(session: session);
      addTearDown(etat.dispose);
      await session.charger();

      await etat.charger();

      expect(
        etat.attributions,
        isEmpty,
        reason: 'ni client ni admin ne sont des rôles de Mefali Pro',
      );
      expect(etat.rolesValides, isEmpty);
    });
  });
}
