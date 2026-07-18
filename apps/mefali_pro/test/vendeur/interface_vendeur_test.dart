import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/roles/etat_roles_data.dart';
import 'package:mefali_pro/vendeur/interface_vendeur.dart';

EtatRolesData _etat(List<AttributionPro> attributions) => EtatRolesData(
      attributions: attributions,
      charge: true,
      actif: RolePro.vendeur,
    );

const _vendeurSeul = AttributionPro(
  role: RolePro.vendeur,
  statut: StatutRolePro.valide,
);
const _coursierValide = AttributionPro(
  role: RolePro.coursier,
  statut: StatutRolePro.valide,
);

Widget _monter(ProviderContainer container, EtatRolesData etat) => harnaisApp(
      container: container,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        MefaliCoreLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: InterfaceVendeur(etat: etat),
    );

void main() {
  group('InterfaceVendeur — coquille V1/V2 (FR-044..046)', () {
    testWidgets('deux onglets seulement — PAS de « Commandes » (hors périmètre)',
        (tester) async {
      final container = conteneurMefali();
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container, _etat(const [_vendeurSeul])));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Boutique'), findsOneWidget);
      expect(find.text('Articles'), findsOneWidget);
      expect(
        find.text('Commandes'),
        findsNothing,
        reason: 'l\'onglet Commandes dépend du module CMD — hors périmètre',
      );
      // Un seul rôle validé : pas de sélecteur à une case (cycle 003).
      expect(find.byType(SegmentedButton<RolePro>), findsNothing);
    });

    testWidgets('le pied de page du cycle 003 reste accessible (FR-046)',
        (tester) async {
      final container = conteneurMefali();
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container, _etat(const [_vendeurSeul])));

      expect(
        find.text('Se déconnecter'),
        findsOneWidget,
        reason: 'PiedPro vit en fin d\'onglet Boutique, comportement intact',
      );
    });

    testWidgets('bi-rôle : la bascule du cycle 003 est rendue en tête',
        (tester) async {
      final container = conteneurMefali();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _monter(container, _etat(const [_coursierValide, _vendeurSeul])),
      );

      expect(find.byType(SegmentedButton<RolePro>), findsOneWidget);
    });

    testWidgets('la sélection d\'onglet est locale et bascule le contenu',
        (tester) async {
      final container = conteneurMefali();
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container, _etat(const [_vendeurSeul])));

      // Onglet Boutique par défaut : le pied y est.
      expect(find.text('Se déconnecter'), findsOneWidget);
      await tester.tap(find.text('Articles'));
      await tester.pumpAndSettle();
      expect(
        find.text('Se déconnecter'),
        findsNothing,
        reason: 'l\'onglet Articles n\'embarque pas le pied',
      );
    });
  });
}
