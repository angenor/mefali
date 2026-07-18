import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/vendeur/articles/ecran_articles.dart';
import 'package:mefali_pro/vendeur/articles/mes_articles.dart';

const _prestataire = '01900000-0000-7000-8000-000000000502';

Map<String, Object?> _pilotable() => {
      'id': _prestataire,
      'nom': 'Boutique Kofi',
      'statut': 'agree',
      'boutique': {'ouvert': true, 'reouverture_estimee': null},
    };

Map<String, Object?> _article(
  String id,
  String nom,
  int prix, {
  int? barre,
  bool disponible = true,
  bool retire = false,
  bool ruptureAdmin = false,
}) =>
    {
      'id': id,
      'nom': nom,
      'prix_unites': prix,
      'devise': 'XOF',
      'prix_barre_unites': barre,
      'photo_url': null,
      'categorie_interne': null,
      'disponible': disponible,
      'source_derniere_bascule': null,
      'rupture_admin': ruptureAdmin,
      'retire': retire,
    };

/// Fixtures de la maquette V2 1a : promo, rupture grisée, retiré replié.
ResponseBody _repondre(RequestOptions requete) {
  if (requete.path.endsWith('/vendeur/prestataires')) {
    return reponseJson([_pilotable()]);
  }
  if (requete.path.endsWith('/articles')) {
    return reponseJson([
      _article('a1', 'Attiéké poisson', 1500),
      _article('a2', 'Alloco', 800, barre: 1000),
      _article('a3', 'Garba', 1200, disponible: false),
      _article('a4', 'Ancien plat', 2000, retire: true),
    ]);
  }
  return reponseJson({'code': 'introuvable'}, statut: 404);
}

(ProviderContainer, TransportFake) _conteneur() {
  final transport = TransportFake(_repondre);
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
      home: const Scaffold(body: EcranArticles()),
    );

void main() {
  group('EcranArticles — V2 catalogue & stock (FR-045)', () {
    testWidgets('compteur, promo barrée et rupture grisée (maquette V2 1a)',
        (tester) async {
      final (container, _) = _conteneur();
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      // Compteur : 3 AU CATALOGUE (le retiré n'y compte pas), 1 en rupture.
      expect(find.text('3 articles · 1 en rupture'), findsOneWidget);
      // Promo : badge + prix courant + prix barré (espace fine des tokens).
      expect(find.text('PROMO'), findsOneWidget);
      expect(find.text('800 FCFA'), findsOneWidget);
      expect(find.text('1 000 FCFA'), findsOneWidget);
      // Rupture : puce d'état.
      expect(find.text('Rupture'), findsOneWidget);
      // Retiré : section repliée, remise possible sans ressaisie (FR-055).
      expect(find.text('Articles retirés (1)'), findsOneWidget);
      expect(find.text('Ancien plat'), findsNothing,
          reason: 'replié tant qu\'on n\'ouvre pas la section');
      await tester.tap(find.text('Articles retirés (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Ancien plat'), findsOneWidget);
      expect(find.text('Remettre au catalogue'), findsOneWidget);
    });

    testWidgets('la recherche filtre localement', (tester) async {
      final (container, _) = _conteneur();
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'garba');
      await tester.pumpAndSettle();
      expect(find.text('Garba'), findsOneWidget);
      expect(find.text('Attiéké poisson'), findsNothing);
      expect(find.text('1 articles · 1 en rupture'), findsOneWidget);
    });
  });

  group('MesArticles — provider (moule AsyncNotifier, R9)', () {
    test('charge le catalogue du prestataire piloté', () async {
      final (container, transport) = _conteneur();
      addTearDown(container.dispose);
      // AutoDispose : garder un abonnement ouvert pendant le test (règle du
      // harnais du cycle 004).
      container.listen(mesArticlesProvider(_prestataire), (_, _) {});

      final articles =
          await container.read(mesArticlesProvider(_prestataire).future);
      expect(articles, hasLength(4));
      expect(articles[1].prixBarreUnites, 1000);
      expect(
        transport.recues.map((r) => r.path).join(','),
        contains('/vendeur/prestataires/$_prestataire/articles'),
      );
    });
  });
}
