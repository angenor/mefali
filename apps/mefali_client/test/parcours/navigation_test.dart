/// Les trois fonctions pures du parcours (cycle CMD 008, T067).
///
/// Petites, mais chacune garde une promesse : ouvrir la BONNE fiche vendeur,
/// ne jamais afficher une clé i18n brute, et ne jamais composer un message
/// d'erreur à partir d'un code serveur (constitution VII).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/parcours/accueil.dart';
import 'package:mefali_client/parcours/pages_commande.dart';
import 'package:mefali_core/mefali_core.dart';

const _vendeur = '01900000-0000-7000-8000-000000000502';

/// Rend les deux jeux de localisations résolus dans un arbre réel — un
/// `AppLocalizations.of(context)` ne se fabrique pas hors widget.
Future<({AppLocalizations app, MefaliCoreLocalizations core})> localisations(
  WidgetTester tester,
) async {
  late AppLocalizations app;
  late MefaliCoreLocalizations core;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        MefaliCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
      home: Builder(
        builder: (context) {
          app = AppLocalizations.of(context)!;
          core = MefaliCoreLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (app: app, core: core);
}

void main() {
  group('identifiantVendeur', () {
    test('accepte les trois formes qui circulent', () {
      expect(identifiantVendeur(_vendeur), _vendeur);
      expect(identifiantVendeur('https://mefali.com/v/$_vendeur'), _vendeur);
      expect(
        identifiantVendeur('http://localhost:8080/prestataires/$_vendeur'),
        _vendeur,
      );
    });

    test('normalise la casse — un UUID reste le même identifiant', () {
      expect(identifiantVendeur(_vendeur.toUpperCase()), _vendeur);
    });

    test('rend null plutôt que d\'ouvrir une fiche au hasard', () {
      expect(identifiantVendeur(''), isNull);
      expect(identifiantVendeur('   '), isNull);
      expect(identifiantVendeur('boutique kofi'), isNull);
      expect(identifiantVendeur('01900000-0000-7000'), isNull);
    });
  });

  group('libelleEtatSuivi', () {
    testWidgets('rend le libellé de l\'état, sans compteur inventé',
        (tester) async {
      final l = await localisations(tester);

      expect(
        libelleEtatSuivi(l.core, l.app, 'suivi.etat.livree'),
        l.core.suiviEtatLivree,
      );
      // La liste ne connaît pas la progression : elle dit « Collecte en cours »
      // sans chiffres, plutôt que « 0 sur 0 ».
      expect(
        libelleEtatSuivi(l.core, l.app, 'suivi.etat.collecte_en_cours'),
        l.app.accueilEtatCollecte,
      );
    });

    testWidgets('une clé inconnue ne fuit JAMAIS à l\'écran', (tester) async {
      final l = await localisations(tester);
      final rendu = libelleEtatSuivi(l.core, l.app, 'suivi.etat.venu_du_futur');

      expect(rendu, l.core.suiviEtatRecue);
      expect(rendu, isNot(contains('suivi.etat')));
    });
  });

  group('messageErreurParcours', () {
    testWidgets('les codes SERVEUR passent par messageErreurCommande',
        (tester) async {
      final l = await localisations(tester);

      expect(
        messageErreurParcours(l.core, l.app, 'vendeur_indisponible'),
        l.core.commandeErreurVendeurIndisponible,
      );
      // Forme longue acceptée comme la courte — les deux circulent.
      expect(
        messageErreurParcours(
            l.core, l.app, 'commande.erreur.categorie_non_mixable'),
        l.core.commandeErreurCategorieNonMixable,
      );
    });

    testWidgets('les deux codes LOCAUX ont leur propre message',
        (tester) async {
      final l = await localisations(tester);

      expect(
        messageErreurParcours(l.core, l.app, 'lieu_indisponible'),
        l.app.parcoursErreurLieu,
      );
      expect(
        messageErreurParcours(l.core, l.app, 'zone_indisponible'),
        l.app.parcoursErreurZone,
      );
    });

    testWidgets('un code inconnu rend le message générique', (tester) async {
      final l = await localisations(tester);

      expect(
        messageErreurParcours(l.core, l.app, 'panne_inedite'),
        l.core.commandeErreurInterne,
      );
      expect(
        messageErreurParcours(l.core, l.app, null),
        l.core.commandeErreurInterne,
      );
    });
  });
}
