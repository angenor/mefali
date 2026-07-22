import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_pro/l10n/app_localizations.dart';
import 'package:mefali_pro/vendeur/articles/ecran_articles.dart';

const _prestataire = '01900000-0000-7000-8000-000000000502';

Map<String, Object?> _article(String id, String nom,
        {bool disponible = true, bool ruptureAdmin = false}) =>
    {
      'id': id,
      'nom': nom,
      'prix_unites': 1000,
      'devise': 'XOF',
      'prix_barre_unites': null,
      'photo_url': null,
      'categorie_interne': null,
      'disponible': disponible,
      'source_derniere_bascule': ruptureAdmin ? 'admin' : null,
      'rupture_admin': ruptureAdmin,
      'retire': false,
    };

(ProviderContainer, TransportFake) _conteneur(
  List<Map<String, Object?>> articles, {
  int basculeStatut = 200,
}) {
  final transport = TransportFake((requete) {
    if (requete.path.endsWith('/vendeur/prestataires')) {
      return reponseJson([
        {
          'id': _prestataire,
          'nom': 'Boutique Kofi',
          'statut': 'agree',
          'boutique': {'ouvert': true, 'reouverture_estimee': null},
        }
      ]);
    }
    if (requete.method == 'POST' && requete.path.endsWith('/disponibilite')) {
      if (basculeStatut != 200) {
        return reponseJson(
          {'code': 'prestataire_non_agree'},
          statut: basculeStatut,
        );
      }
      return reponseJson(_article('a1', 'Garba'));
    }
    if (requete.path.endsWith('/articles')) {
      return reponseJson(articles);
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
      home: const Scaffold(body: EcranArticles()),
    );

void main() {
  group('BasculeStock — un geste (FR-045, FR-041)', () {
    testWidgets('basculer une rupture en stock envoie la bascule',
        (tester) async {
      final (container, transport) =
          _conteneur([_article('a1', 'Garba', disponible: false)]);
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rupture'));
      await tester.pumpAndSettle();

      final bascule = transport.recues
          .firstWhere((r) => r.path.endsWith('/disponibilite'));
      final corps = Map<String, Object?>.from(bascule.data as Map);
      expect(corps['disponible'], true, reason: 'UN geste : rupture → en stock');
    });

    testWidgets('rupture ADMIN : verrouillée, le tap explique sans agir',
        (tester) async {
      final (container, transport) = _conteneur(
          [_article('a1', 'Savon', disponible: false, ruptureAdmin: true)]);
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rupture'));
      await tester.pumpAndSettle();

      expect(
        find.text('Rupture posée par Mefali — seule l\'équipe peut la lever.'),
        findsOneWidget,
      );
      expect(
        transport.recues.any((r) => r.path.endsWith('/disponibilite')),
        isFalse,
        reason: 'FR-041 — la bascule vendeur n\'est même pas tentée',
      );
    });

    testWidgets('refus serveur (403 après suspension) : message, pas de silence',
        (tester) async {
      final (container, transport) = _conteneur(
        [_article('a1', 'Garba', disponible: true)],
        basculeStatut: 403,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_monter(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('En stock'));
      await tester.pumpAndSettle();

      expect(
        transport.recues.any((r) => r.path.endsWith('/disponibilite')),
        isTrue,
        reason: 'la bascule est bien tentée...',
      );
      expect(
        find.text('Bascule refusée — cette boutique n\'est plus agréée.'),
        findsOneWidget,
        reason: '...et son échec est montré, jamais avalé en silence',
      );
    });
  });
}
