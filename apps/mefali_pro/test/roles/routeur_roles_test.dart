import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/roles/etat_roles.dart';
import 'package:mefali_pro/roles/routeur_roles.dart';

ResponseBody _json(Object corps, {int statut = 200}) => reponseJson(corps, statut: statut);

const String _idCompte = '01900000-0000-7000-8000-000000000401';

/// Fixture = wireNames RÉELS du backend (contrat `CompteMoi`).
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

/// Conteneur monté sur un transport factice, session connectée. On surcharge les
/// DÉPENDANCES (stockage via `jetons`, transport) ; JAMAIS `sessionProvider` ni
/// `etatRolesProvider` (le sujet reste sous test).
(ProviderContainer, TransportFake) _conteneur(
  ResponseBody Function(RequestOptions requete) repondre,
) {
  final transport = TransportFake(repondre);
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'jwt', rafraichissement: 'r'),
    transport: transport,
  );
  return (container, transport);
}

Widget _monter(ProviderContainer container, Widget enfant) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: enfant,
    );

/// Démonte l'arbre puis dispose le conteneur DANS le corps : RouteurRoles lit
/// serviceConfig, dont le Timer horaire serait « pending » sinon.
Future<void> _fin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

void main() {
  group('RouteurRoles — porte de Mefali Pro (FR-013)', () {
    testWidgets(
      'un compte sans rôle pro validé voit l\'état de sa demande, pas une interface pro',
      (tester) async {
        final (container, _) = _conteneur(
          (_) => _json(_compte([_role('client', 'valide')])),
        );
        await container.read(sessionProvider.notifier).charger();

        await tester.pumpWidget(_monter(container, const RouteurRoles()));
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
        await _fin(tester, container);
      },
    );

    testWidgets('une demande coursier en attente n\'ouvre AUCUN privilège', (tester) async {
      final (container, _) = _conteneur(
        (_) => _json(
          _compte([_role('client', 'valide'), _role('coursier', 'en_attente')]),
        ),
      );
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const RouteurRoles()));
      await tester.pumpAndSettle();

      expect(find.text('Dossier en cours d\'examen'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget, reason: 'puce de statut du rôle');
      expect(find.text('Coursier'), findsOneWidget, reason: 'carte du rôle demandé');
      expect(
        find.text('Espace coursier'),
        findsNothing,
        reason: 'SC-005 — « en attente » ne franchit pas la porte',
      );
      await _fin(tester, container);
    });

    testWidgets('un refus affiche son motif, tel que l\'admin l\'a écrit', (tester) async {
      final (container, _) = _conteneur(
        (_) => _json(
          _compte([
            _role('client', 'valide'),
            _role('coursier', 'refuse', motif: 'Pièce d\'identité illisible'),
          ]),
        ),
      );
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const RouteurRoles()));
      await tester.pumpAndSettle();

      expect(find.text('Dossier refusé'), findsOneWidget);
      expect(find.text('Refusé'), findsOneWidget);
      expect(
        find.text('Pièce d\'identité illisible'),
        findsOneWidget,
        reason: 'FR-014 — la décision est journalisée AVEC son motif, et rendue',
      );
      await _fin(tester, container);
    });

    testWidgets('un rôle suspendu referme la porte et le dit', (tester) async {
      final (container, _) = _conteneur(
        (_) => _json(
          _compte([
            _role('client', 'valide'),
            _role('coursier', 'suspendu', motif: 'Plaintes répétées'),
          ]),
        ),
      );
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const RouteurRoles()));
      await tester.pumpAndSettle();

      expect(find.text('Rôle suspendu'), findsOneWidget);
      expect(find.text('Plaintes répétées'), findsOneWidget);
      expect(find.text('Espace coursier'), findsNothing);
      await _fin(tester, container);
    });

    testWidgets('un seul rôle validé ouvre son interface, sans sélecteur', (tester) async {
      final (container, _) = _conteneur(
        (_) => _json(
          _compte([_role('client', 'valide'), _role('vendeur', 'valide')]),
        ),
      );
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const RouteurRoles()));
      await tester.pumpAndSettle();

      expect(find.text('Espace vendeur'), findsOneWidget);
      expect(
        find.byType(SegmentedButton<RolePro>),
        findsNothing,
        reason: 'un mono-rôle n\'a rien à basculer',
      );
      await _fin(tester, container);
    });

    testWidgets('un échec réseau affiche une erreur réessayable, pas un écran blanc',
        (tester) async {
      var appels = 0;
      final (container, _) = _conteneur((_) {
        appels++;
        if (appels == 1) return _json({'code': 'x', 'message_cle': 'y'}, statut: 500);
        return _json(_compte([_role('client', 'valide'), _role('coursier', 'valide')]));
      });
      await container.read(sessionProvider.notifier).charger();

      await tester.pumpWidget(_monter(container, const RouteurRoles()));
      await tester.pumpAndSettle();

      expect(find.text('Connexion impossible'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Espace coursier'),
        findsOneWidget,
        reason: 'le réseau revenu, l\'écran se répare sans redémarrage',
      );
      await _fin(tester, container);
    });
  });

  group('Bascule entre rôles validés (SC-006)', () {
    testWidgets('bascule_role_sans_reconnexion', (tester) async {
      final (container, transport) = _conteneur(
        (_) => _json(
          _compte([
            _role('client', 'valide'),
            _role('coursier', 'valide'),
            _role('vendeur', 'valide'),
          ]),
        ),
      );
      await container.read(sessionProvider.notifier).charger();
      final accesAvant = container.read(sessionProvider).acces;

      await tester.pumpWidget(_monter(container, const RouteurRoles()));
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
        container.read(sessionProvider).acces,
        accesAvant,
        reason: 'SC-006 — « sans reconnexion » : la session n\'est pas touchée',
      );

      await tester.tap(find.text('Coursier'));
      await tester.pumpAndSettle();
      expect(find.text('Espace coursier'), findsOneWidget, reason: 'et retour');
      await _fin(tester, container);
    });

    // À partir d'ici, des tests de LOGIQUE : `test` et non `testWidgets`.
    // ⚠ RÈGLE DU FICHIER — tout cas unitaire sur etatRolesProvider OUVRE un
    // abonnement : etatRolesProvider est autoDispose, `read(...notifier)`
    // n'attache aucun auditeur, le notifier serait rejeté ENTRE deux charger()
    // ⇒ build() rejoué ⇒ actif repart à null ⇒ le test devient VERT SANS RIEN
    // PROUVER (le pire résultat). L'abonnement le maintient vivant (règle 2).
    test('la bascule ignore un rôle non validé (SC-005)', () async {
      final (container, _) = _conteneur((_) => _json(_compte([])));
      addTearDown(container.dispose);
      final sub = container.listen(etatRolesProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(sessionProvider.notifier).charger();
      await container.read(etatRolesProvider.notifier).charger();
      expect(container.read(etatRolesProvider).actif, isNull);

      container.read(etatRolesProvider.notifier).basculer(RolePro.coursier);

      expect(
        container.read(etatRolesProvider).actif,
        isNull,
        reason: 'la bascule n\'est pas un contournement de la validation admin',
      );
    });

    test('un rôle suspendu entre deux chargements ne reste pas affiché', () async {
      var appels = 0;
      final (container, _) = _conteneur((_) {
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
      addTearDown(container.dispose);
      final sub = container.listen(etatRolesProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(sessionProvider.notifier).charger();

      await container.read(etatRolesProvider.notifier).charger();
      expect(container.read(etatRolesProvider).actif, RolePro.coursier);

      // Deux charger() sur la MÊME instance (l'abonnement la maintient).
      await container.read(etatRolesProvider.notifier).charger();

      expect(
        container.read(etatRolesProvider).actif,
        RolePro.vendeur,
        reason: 'un rôle suspendu ne peut pas rester l\'interface affichée',
      );
    });
  });

  group('EtatRoles — lecture du contrat', () {
    test('un statut inconnu du backend ferme la porte au lieu de l\'ouvrir', () async {
      final (container, _) = _conteneur(
        (_) => _json(_compte([_role('coursier', 'statut_du_futur')])),
      );
      addTearDown(container.dispose);
      final sub = container.listen(etatRolesProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(sessionProvider.notifier).charger();

      await container.read(etatRolesProvider.notifier).charger();

      expect(container.read(etatRolesProvider).rolesValides, isEmpty,
          reason: 'SC-005 — fail-closed');
      expect(container.read(etatRolesProvider).statut(RolePro.coursier),
          StatutRolePro.aucun);
    });

    test('les rôles non professionnels sont ignorés', () async {
      final (container, _) = _conteneur(
        (_) => _json(
          _compte([_role('client', 'valide'), _role('admin', 'valide')]),
        ),
      );
      addTearDown(container.dispose);
      final sub = container.listen(etatRolesProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(sessionProvider.notifier).charger();

      await container.read(etatRolesProvider.notifier).charger();

      expect(
        container.read(etatRolesProvider).attributions,
        isEmpty,
        reason: 'ni client ni admin ne sont des rôles de Mefali Pro',
      );
      expect(container.read(etatRolesProvider).rolesValides, isEmpty);
    });
  });
}
