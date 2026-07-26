/// US1 (CMD-01) — écran panier multi-vendeurs, maquette C3.
///
/// Trois états couverts : normal (3a), mixte avec proposition de scission (3d),
/// et hors ligne (3c). Ce qui est vérifié est ce que la maquette PROMET :
/// regroupement par vendeur avec sous-totaux, préférence par article, détail
/// des frais, et — hors ligne — un total annoncé comme ESTIMÉ.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/panier/ecran_panier.dart';
import 'package:mefali_client/panier/etat_panier.dart';
import 'package:mefali_core/mefali_core.dart';

/// Corps de `POST /paniers/devis` : 3 vendeurs, 12 articles, 5 900 FCFA au
/// total — exactement le panier de la maquette C3-3a.
Map<String, Object?> devisJson({Map<String, Object?>? scission}) => {
      'groupes': [
        _groupe('01900000-0000-7000-8000-000000000501', 'Étal Adjoua', 5, 2100),
        _groupe('01900000-0000-7000-8000-000000000502', 'Étal Konan', 4, 1650),
        _groupe('01900000-0000-7000-8000-000000000503', 'Boutique Yao', 3, 1800),
      ],
      'montant_articles_unites': 5550,
      'devis': {
        'prix_client_unites': 250,
        'part_coursier_unites': 250,
        'marge_unites': 0,
        'devise': 'XOF',
        'distance_m': 2400,
        'eta_s': 480,
        'degraded': false,
        'composantes': {
          'base': 200,
          'km': 0,
          'supplements': 0,
          'effort_paliers': 100,
          'effort_attente': 0,
          'effort_arrets': 0,
          'arrondi': 0,
          'retenue_vendeur': 0,
        },
        'ordre_arrets': [0, 1, 2],
      },
      'total_unites': 5900,
      'devise': 'XOF',
      'paiement': {
        'cash_autorise': true,
        'motif_cle': null,
        'plafond_unites': 15000,
      },
      'scission': scission,
    };

Map<String, Object?> _groupe(String id, String nom, int nb, int sousTotal) => {
      'prestataire_id': id,
      'nom': nom,
      'nb_articles': nb,
      'sous_total_unites': sousTotal,
      // Deux lignes dont la somme fait le sous-total : le test distingue ainsi
      // le montant de la CARTE de celui d'une ligne (la 1ʳᵉ carte est dépliée).
      'lignes': [
        {
          'article_id': '\$id-a',
          'nom': 'Tomates fraîches',
          'quantite': 1,
          'sous_total_unites': sousTotal - 500,
          'preference': 'appeler',
        },
        {
          'article_id': '\$id-b',
          'nom': 'Piment',
          'quantite': 1,
          'sous_total_unites': 500,
          'preference': 'appeler',
        },
      ],
    };

Future<ProviderContainer> monter(
  WidgetTester tester, {
  required Map<String, Object?> devis,
  bool horsLigne = false,
}) async {
  // Écran LONG (la maquette le montre en deux cadres) : sans une surface haute,
  // le ListView ne construit pas le récapitulatif et le test mesurerait
  // l'absence d'un widget qui existe.
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(retry: pasDeRetry);
  final notifier = container.read(panierProvider.notifier)
    ..demarrer(zoneId: 'zone', categorieSlug: 'marche')
    ..ajouter(const LignePanier(
      prestataireId: '01900000-0000-7000-8000-000000000501',
      articleId: '01900000-0000-7000-8000-000000000501-a',
      quantite: 1,
    ))
    ..poserDevis(DevisPanierVue.depuisJson(devis));
  if (horsLigne) notifier.marquerHorsLigne();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          MefaliCoreLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('fr')],
        locale: Locale('fr'),
        home: EcranPanier(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Fermeture PROPRE de la portée dans le corps du test : `addTearDown` passerait
/// après le contrôle des timers de `flutter_test` (piège du cycle 004).
Future<void> fin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

void main() {
  group('EcranPanier — C3-3a (normal)', () {
    testWidgets('un vendeur par carte, avec son sous-total', (tester) async {
      final container = await monter(tester, devis: devisJson());

      for (final nom in ['Étal Adjoua', 'Étal Konan', 'Boutique Yao']) {
        expect(find.text(nom), findsOneWidget, reason: 'carte de $nom');
      }
      // Sous-totaux formatés avec l'espace fine des tokens.
      expect(find.text(formaterMontant(2100, 'XOF')), findsOneWidget);
      expect(find.text(formaterMontant(1650, 'XOF')), findsOneWidget);
      expect(find.text(formaterMontant(1800, 'XOF')), findsOneWidget);

      await fin(tester, container);
    });

    testWidgets('le récapitulatif détaille articles, livraison et effort',
        (tester) async {
      final container = await monter(tester, devis: devisJson());

      expect(find.text('Articles'), findsOneWidget);
      expect(find.text(formaterMontant(5550, 'XOF')), findsOneWidget);
      expect(find.text('Livraison'), findsOneWidget);
      expect(find.text(formaterMontant(250, 'XOF')), findsOneWidget);
      expect(find.text('Effort de préparation'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(formaterMontant(5900, 'XOF')), findsOneWidget);

      await fin(tester, container);
    });

    testWidgets('la préférence par défaut affichée est « M\'appeler »',
        (tester) async {
      final container = await monter(tester, devis: devisJson());
      // La première carte est dépliée : son sélecteur est visible.
      expect(find.text("Si l'article manque"), findsWidgets);
      expect(find.text("M'appeler"), findsWidgets);
      await fin(tester, container);
    });
  });

  group('EcranPanier — C3-3d (mixte, scission proposée)', () {
    testWidgets('bandeau, bouton et prévisualisation chiffrée', (tester) async {
      final container = await monter(
        tester,
        devis: devisJson(scission: {
          'cause': 'categorie_non_mixable',
          'message_cle': 'panier.scission.categorie_non_mixable',
          'commandes_proposees': [
            {
              'libelle_cle': 'Commande 1 — repas chaud',
              'total_articles_unites': 3000,
              'articles': ['a'],
            },
            {
              'libelle_cle': 'Commande 2 — courses',
              'total_articles_unites': 5550,
              'articles': ['b', 'c'],
            },
          ],
        }),
      );

      expect(
        find.text('Les plats préparés se commandent séparément des courses.'),
        findsOneWidget,
      );
      expect(find.text('Scinder en 2 commandes'), findsOneWidget);
      // Prévisualisation CHIFFRÉE des deux commandes.
      expect(find.text(formaterMontant(3000, 'XOF')), findsOneWidget);
      // Et l'avertissement sur les DEUX frais, affiché avant la décision.
      expect(
        find.text('Deux commandes, deux frais de déplacement.'),
        findsOneWidget,
      );

      await fin(tester, container);
    });
  });

  group('EcranPanier — C3-3c (hors ligne)', () {
    testWidgets('total annoncé ESTIMÉ et envoi désactivé', (tester) async {
      final container =
          await monter(tester, devis: devisJson(), horsLigne: true);

      expect(find.text('Hors connexion — panier conservé'), findsOneWidget);
      expect(
        find.text('Total estimé'),
        findsOneWidget,
        reason: "hors ligne, l'app ne présente jamais un montant comme ferme",
      );
      expect(find.text('Total'), findsNothing);

      // Le bouton existe mais est DÉSACTIVÉ : rien n'est engagé sans réseau.
      final bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Commander'),
      );
      expect(bouton.onPressed, isNull);

      await fin(tester, container);
    });

    testWidgets('le panier reste composable hors ligne', (tester) async {
      final container =
          await monter(tester, devis: devisJson(), horsLigne: true);

      // Les cartes vendeur restent affichées : rien n'est perdu (C3-3c).
      expect(find.text('Étal Adjoua'), findsOneWidget);
      final panier = container.read(panierProvider);
      expect(panier.horsLigne, isTrue);
      expect(panier.estVide, isFalse);
      expect(panier.devis, isNotNull, reason: 'le dernier devis connu est gardé');

      await fin(tester, container);
    });
  });

  group('Panier — porteur de processus (constitution XII)', () {
    test('ajout, cumul, changement de préférence et retrait', () {
      final container = ProviderContainer(retry: pasDeRetry);
      addTearDown(container.dispose);
      final panier = container.read(panierProvider.notifier)
        ..demarrer(zoneId: 'z', categorieSlug: 'marche');

      panier.ajouter(
        const LignePanier(prestataireId: 'v1', articleId: 'a1', quantite: 2),
      );
      panier.ajouter(
        const LignePanier(prestataireId: 'v1', articleId: 'a1', quantite: 3),
      );
      expect(
        container.read(panierProvider).lignes.single.quantite,
        5,
        reason: 'le même article cumule, il ne se dédouble pas',
      );

      panier.ajouter(
        const LignePanier(prestataireId: 'v2', articleId: 'a2', quantite: 1),
      );
      expect(container.read(panierProvider).nbVendeurs, 2);
      expect(container.read(panierProvider).nbArticles, 6);

      panier.changerPreference('a1', 'retirer');
      expect(
        container.read(panierProvider).lignes.first.preference,
        'retirer',
      );

      panier.retirer('a1');
      expect(container.read(panierProvider).lignes.single.articleId, 'a2');

      panier.vider();
      expect(container.read(panierProvider).estVide, isTrue);
    });

    test('la préférence par défaut est « appeler » (CMD-01)', () {
      const ligne = LignePanier(
        prestataireId: 'v',
        articleId: 'a',
        quantite: 1,
      );
      expect(ligne.preference, 'appeler');
      expect(ligne.versJson()['preference'], 'appeler');
    });
  });
}
