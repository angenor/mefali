/// Acceptation de la scission (cycle CMD 008, CMD-01 / C3-3d, SC-006).
///
/// Le geste manquant du cycle : le bandeau s'affichait, chiffré, mais son bouton
/// n'était branché sur rien. Ce fichier couvre le parcours ENTIER de
/// l'acceptation, écran compris, parce que c'est là que tout se joue :
///
/// - accepter crée **N commandes**, avec **N clés d'idempotence distinctes**,
///   chacune ne portant que ses lignes (aucune route ne scinde : accepter, c'est
///   appeler `POST /commandes` N fois) ;
/// - les **N frais de déplacement** sont chiffrés et affichés AVANT
///   confirmation — un par tronçon, obtenus du serveur, jamais estimés (R8) ;
/// - un **échec partiel** ne se cache pas : la commande passée reste due,
///   l'écran le dit, et le panier ne garde que le reste, clés inchangées (R7) ;
/// - **SC-006** — sans appui sur le bouton, une seule commande est tentée : le
///   serveur propose, il n'impose pas.
///
/// Aucun canal de plateforme : transport bouché, base drift en mémoire, position
/// injectée par la portée (FR-039).
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/l10n/app_localizations.dart';
import 'package:mefali_client/panier/etat_confirmation.dart';
import 'package:mefali_client/panier/etat_panier.dart';
import 'package:mefali_client/parcours/actions_commande.dart';
import 'package:mefali_client/parcours/pages_commande.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const _zone = '01900000-0000-7000-8000-000000000002';
const _vendeurA = '01900000-0000-7000-8000-000000000501';
const _vendeurB = '01900000-0000-7000-8000-000000000502';
const _articleA = '01900000-0000-7000-8000-000000000551';
const _articleB = '01900000-0000-7000-8000-000000000552';

/// Le devis de livraison, avec SON prix client — c'est lui qui diffère d'un
/// tronçon à l'autre, et c'est tout le sujet de C3-3d.
Map<String, Object?> _devisLivraison(int prixClient) => {
      'composantes': {
        'arrondi': 0,
        'base': prixClient,
        'effort_arrets': 0,
        'effort_attente': 0,
        'effort_paliers': 0,
        'km': 0,
        'retenue_vendeur': 0,
        'supplements': 0,
      },
      'degraded': true,
      'devise': 'XOF',
      'distance_m': 536,
      'eta_s': 96,
      'marge_unites': 0,
      'ordre_arrets': [0, 1],
      'part_coursier_unites': prixClient,
      'prix_client_unites': prixClient,
    };

Map<String, Object?> _groupe(
  String vendeur,
  String nom,
  String article,
  int montant,
) =>
    {
      'prestataire_id': vendeur,
      'nom': nom,
      'nb_articles': 1,
      'sous_total_unites': montant,
      'lignes': [
        {
          'article_id': article,
          'nom': 'Riz parfumé 5 kg',
          'preference': 'appeler',
          'prix_unites': montant,
          'quantite': 1,
          'sous_total_unites': montant,
        },
      ],
    };

/// Devis du panier ENTIER : deux vendeurs, UNE tournée à 250, et la proposition
/// de scission que le serveur y attache sans jamais l'appliquer (FR-010).
Map<String, Object?> devisEntier() => {
      'groupes': [
        _groupe(_vendeurA, 'Étal Adjoua', _articleA, 3000),
        _groupe(_vendeurB, 'Boutique Yao', _articleB, 5000),
      ],
      'montant_articles_unites': 8000,
      'devis': _devisLivraison(250),
      'total_unites': 8250,
      'devise': 'XOF',
      'paiement': {
        'cash_autorise': true,
        'motif_cle': null,
        'plafond_unites': 15000,
      },
      'scission': {
        'cause': 'categorie_non_mixable',
        'message_cle': 'panier.scission.categorie_non_mixable',
        // Le serveur rend les ARTICLES de chaque commande proposée : c'est ce
        // qui permet au client de savoir quelles lignes envoyer où.
        'commandes_proposees': [
          {
            'libelle_cle': 'panier.scission.par_vendeur',
            'total_articles_unites': 3000,
            'articles': [_articleA],
          },
          {
            'libelle_cle': 'panier.scission.par_vendeur',
            'total_articles_unites': 5000,
            'articles': [_articleB],
          },
        ],
      },
    };

/// Devis d'UN tronçon : un vendeur, SA livraison à 300. Deux tronçons coûtent
/// donc 600 de déplacement là où la tournée unique en coûtait 250 — l'écran doit
/// le montrer avant que le client ne s'engage.
Map<String, Object?> devisTroncon(String article) {
  final vendeur = article == _articleA ? _vendeurA : _vendeurB;
  final nom = article == _articleA ? 'Étal Adjoua' : 'Boutique Yao';
  final montant = article == _articleA ? 3000 : 5000;
  return {
    'groupes': [_groupe(vendeur, nom, article, montant)],
    'montant_articles_unites': montant,
    'devis': _devisLivraison(300),
    'total_unites': montant + 300,
    'devise': 'XOF',
    'devise_articles': 'XOF',
    'paiement': {
      'cash_autorise': true,
      'motif_cle': null,
      'plafond_unites': 15000,
    },
    'scission': null,
  };
}

/// Corps de `POST /commandes`. Le code de remise est PROPRE à chaque commande
/// (R6) : c'est ce qui interdit de n'en afficher qu'un pour deux livraisons.
///
/// `livraison` est présente parce que le CONTRAT la rend obligatoire sur
/// `Commande` : l'omettre ferait échouer la désérialisation du client généré, et
/// le test vérifierait alors le comportement d'un refus, pas d'une création.
Map<String, Object?> commandeCreee(String id, int total, String code) => {
      'id': id,
      'etat': 'nouvelle',
      'montant_articles_unites': total - 300,
      'total_unites': total,
      'devise': 'XOF',
      'livraison': {
        'id': '019f0000-0000-7000-8000-0000000008$code',
        'etat': 'assignee',
        'nb_arrets': 1,
        'devis': _devisLivraison(300),
      },
      'paiement': {
        'mode': 'cash',
        'etat': 'du',
        'appoint_exact_unites': total,
      },
      'remise': {
        'code_livraison': code,
        'jeton_reception': 'jeton-$code',
      },
    };

/// Les articles portés par une requête — c'est par là qu'on vérifie que chaque
/// commande ne transporte QUE ses lignes.
List<String> articlesDe(RequestOptions options) => [
      for (final ligne in (options.data! as Map)['lignes']! as List)
        (ligne as Map)['article_id']! as String,
    ];

/// Les requêtes reçues sur un chemin, dans l'ordre.
List<RequestOptions> requetes(TransportFake transport, String chemin) =>
    [for (final o in transport.recues) if (o.path == chemin) o];

String cleDe(RequestOptions options) =>
    options.headers['Idempotency-Key']! as String;

/// Le bloc de remise portant un code donné. `BlocRemise` rend le code CHIFFRE
/// PAR CHIFFRE (maquette C4, mode dégradé du scan) : `find.text('5311')` ne le
/// trouverait pas.
Finder blocRemise(String code) => find.byWidgetPredicate(
      (w) => w is BlocRemise && w.codeLivraison == code,
      description: 'BlocRemise du code $code',
    );

class _SourceConfigFixe implements SourceConfig {
  @override
  Future<ConfigDistante> recuperer(String zone) async =>
      ConfigDistante.depuisJson({
        'zone': zone,
        'version': 'v1',
        'transports_actifs': ['moto'],
      });
}

class _CacheConfigMemoire implements CacheConfig {
  ConfigDistante? _config;

  @override
  Future<ConfigDistante?> lire(String zone) async => _config;

  @override
  Future<void> ecrire(ConfigDistante config) async => _config = config;
}

/// Monte le panier RÉEL (`PagePanier`), déjà rempli de deux vendeurs, sur un
/// transport bouché. Le devis part de lui-même après la première frame.
Future<({ProviderContainer container, TransportFake transport})> monter(
  WidgetTester tester,
  FutureOr<ResponseBody> Function(RequestOptions) repondre,
) async {
  // Écran LONG : sans surface haute, le `ListView` ne construit pas les blocs
  // qu'on cherche et le test mesurerait l'absence d'un widget qui existe.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final base = BaseOffline.memoire();
  addTearDown(base.close);

  final container = ProviderContainer(
    retry: pasDeRetry,
    overrides: [
      urlApiProvider.overrideWithValue('http://test.invalid'),
      stockageJetonsProvider.overrideWith(
        (ref) => StockageJetonsMemoire(
          const JetonsSession(acces: 'acces', rafraichissement: 'refresh'),
        ),
      ),
      sourceConfigProvider.overrideWith((ref) => _SourceConfigFixe()),
      cacheConfigProvider
          .overrideWith((ref) => Future.value(_CacheConfigMemoire())),
      baseOfflineProvider.overrideWithValue(base),
      positionAppareilProvider
          .overrideWithValue(() async => (lat: 5.896, lon: -4.821)),
    ],
  );
  final transport = TransportFake(repondre);
  container.read(clientSessionProvider).dio.httpClientAdapter = transport;

  container.read(panierProvider.notifier)
    ..demarrer(zoneId: _zone, categorieSlug: 'boutique_superette')
    ..ajouter(const LignePanier(
      prestataireId: _vendeurA,
      articleId: _articleA,
      quantite: 1,
    ))
    ..ajouter(const LignePanier(
      prestataireId: _vendeurB,
      articleId: _articleB,
      quantite: 1,
    ));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          MefaliCoreLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const PagePanier(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, transport: transport);
}

/// Fermeture PROPRE de la portée dans le corps du test : `addTearDown` passerait
/// après le contrôle des timers de `flutter_test` (piège du cycle 004).
Future<void> fin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
}

/// Va du panier à l'écran adresse, pose le repère, et rend la main juste avant
/// le geste qui engage.
Future<void> allerAAdresse(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Commander'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField),
    'Portail bleu après la pharmacie',
  );
  await tester.pumpAndSettle();
}

void main() {
  group('C3-3d — accepter la scission', () {
    testWidgets('chiffre les N commandes et annonce les N frais AVANT tout',
        (tester) async {
      final m = await monter(tester, (o) {
        if (o.path == '/paniers/devis') {
          final articles = articlesDe(o);
          return reponseJson(articles.length == 2
              ? devisEntier()
              : devisTroncon(articles.single));
        }
        fail('aucune commande ne doit être créée par une acceptation');
      });

      // La proposition, telle que le serveur l'a rendue.
      expect(find.text('Scinder en 2 commandes'), findsOneWidget);
      expect(m.container.read(panierProvider).scissionAcceptee, isFalse);

      await tester.tap(find.text('Scinder en 2 commandes'));
      await tester.pumpAndSettle();

      // Deux tronçons, chacun avec SON devis serveur.
      final troncons = m.container.read(panierProvider).troncons;
      expect(troncons, hasLength(2));
      expect(troncons.first.lignes.single.articleId, _articleA);
      expect(troncons.last.lignes.single.articleId, _articleB);

      // La proposition a disparu, le bloc accepté l'a remplacée.
      expect(find.text('Scinder en 2 commandes'), findsNothing);
      expect(find.text('2 commandes séparées'), findsOneWidget);
      expect(find.text('Commande 1'), findsOneWidget);
      expect(find.text('Commande 2'), findsOneWidget);

      // LES DEUX FRAIS DE DÉPLACEMENT, chiffrés : 300 deux fois, et non les 250
      // de la tournée unique. C'est l'annonce que la maquette promet.
      expect(find.text('Livraison'), findsNWidgets(2));
      expect(find.text(formaterMontant(300, 'XOF')), findsNWidgets(2));
      expect(find.text(formaterMontant(250, 'XOF')), findsNothing,
          reason: 'le frais de la tournée unique ne sera facturé par personne');
      expect(
        find.text('Deux commandes, deux frais de déplacement.'),
        findsOneWidget,
      );
      // Les deux totaux : 3 300 et 5 300.
      expect(find.text(formaterMontant(3300, 'XOF')), findsOneWidget);
      expect(find.text(formaterMontant(5300, 'XOF')), findsOneWidget);

      await fin(tester, m.container);
    });

    testWidgets('crée N commandes, N clés distinctes, chacune avec SES lignes',
        (tester) async {
      var suivante = 0;
      final m = await monter(tester, (o) {
        if (o.path == '/paniers/devis') {
          final articles = articlesDe(o);
          return reponseJson(articles.length == 2
              ? devisEntier()
              : devisTroncon(articles.single));
        }
        suivante++;
        return reponseJson(
          commandeCreee(cleDe(o), suivante == 1 ? 3300 : 5300, '531$suivante'),
          statut: 201,
        );
      });

      await tester.tap(find.text('Scinder en 2 commandes'));
      await tester.pumpAndSettle();
      await allerAAdresse(tester);

      // Le total annoncé est la SOMME des deux commandes, frais compris.
      expect(
        find.widgetWithText(
          FilledButton,
          'Commander · ${formaterMontant(8600, 'XOF')}',
        ),
        findsOneWidget,
      );
      // Et l'appoint est donné par commande : deux livraisons, deux paiements.
      expect(
        find.text('Commande 1 · Préparez l\'appoint : '
            '${formaterMontant(3300, 'XOF')}'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(
        FilledButton,
        'Commander · ${formaterMontant(8600, 'XOF')}',
      ));
      await tester.pumpAndSettle();

      final creations = requetes(m.transport, '/commandes');
      expect(creations, hasLength(2), reason: 'N commandes, pas une');
      expect(
        cleDe(creations.first),
        isNot(cleDe(creations.last)),
        reason: 'une clé partagée rendrait DEUX FOIS la même commande (R7)',
      );
      expect(articlesDe(creations.first), [_articleA]);
      expect(articlesDe(creations.last), [_articleB]);

      // Les deux codes de remise sont rendus, chacun sous son rang.
      expect(blocRemise('5311'), findsOneWidget);
      expect(blocRemise('5312'), findsOneWidget);
      expect(m.container.read(confirmationProvider).commandesCreees,
          hasLength(2));
      expect(m.container.read(panierProvider).estVide, isTrue);
      expect(m.container.read(panierProvider).scissionAcceptee, isFalse);

      await fin(tester, m.container);
    });
  });

  group('échec partiel (le point qui décide)', () {
    testWidgets(
        'la 1ʳᵉ est conservée, l\'écran le dit, le panier ne garde que le reste',
        (tester) async {
      var creations = 0;
      final m = await monter(tester, (o) {
        if (o.path == '/paniers/devis') {
          final articles = articlesDe(o);
          return reponseJson(articles.length == 2
              ? devisEntier()
              : devisTroncon(articles.single));
        }
        creations++;
        // Le vendeur du 2ᵉ tronçon a fermé entre-temps.
        if (creations == 2) {
          return reponseJson(
            {
              'code': 'vendeur_indisponible',
              'message_cle': 'commande.erreur.vendeur_indisponible',
            },
            statut: 409,
          );
        }
        return reponseJson(commandeCreee(cleDe(o), 3300, '5311'), statut: 201);
      });

      await tester.tap(find.text('Scinder en 2 commandes'));
      await tester.pumpAndSettle();
      final clesAcceptees = [
        for (final t in m.container.read(panierProvider).troncons)
          t.cleIdempotence,
      ];
      await allerAAdresse(tester);
      await tester.tap(find.widgetWithText(
        FilledButton,
        'Commander · ${formaterMontant(8600, 'XOF')}',
      ));
      await tester.pumpAndSettle();

      // La 1ʳᵉ n'est PAS annulée : elle est valide et le client la doit.
      expect(m.container.read(confirmationProvider).commandesCreees,
          hasLength(1));
      expect(blocRemise('5311'), findsOneWidget);

      // L'écran dit EXACTEMENT ce qui a été créé et ce qui ne l'a pas été.
      expect(find.text('1 commande sur 2 a été créée.'), findsOneWidget);
      expect(
        find.text('La commande restante n\'a pas pu être créée.'),
        findsOneWidget,
      );
      expect(find.text('Reprendre le reste'), findsOneWidget);

      // Le panier ne garde que le reste — sinon un nouvel essai recommanderait
      // ce qui est déjà commandé.
      final panier = m.container.read(panierProvider);
      expect(panier.lignes.single.articleId, _articleB);
      expect(panier.troncons, hasLength(1));
      expect(panier.troncons.single.cleIdempotence, clesAcceptees.last,
          reason: 'la clé du reste est INCHANGÉE : elle sert au nouvel essai');

      await fin(tester, m.container);
    });

    testWidgets('reprendre rejoue la MÊME clé et ne double rien (R7)',
        (tester) async {
      var creations = 0;
      final m = await monter(tester, (o) {
        if (o.path == '/paniers/devis') {
          final articles = articlesDe(o);
          return reponseJson(articles.length == 2
              ? devisEntier()
              : devisTroncon(articles.single));
        }
        creations++;
        if (creations == 2) {
          return reponseJson(
            {'code': 'vendeur_indisponible', 'message_cle': 'x'},
            statut: 409,
          );
        }
        return reponseJson(
          commandeCreee(cleDe(o), creations == 1 ? 3300 : 5300,
              creations == 1 ? '5311' : '5312'),
          statut: 201,
        );
      });

      await tester.tap(find.text('Scinder en 2 commandes'));
      await tester.pumpAndSettle();
      await allerAAdresse(tester);
      await tester.tap(find.widgetWithText(
        FilledButton,
        'Commander · ${formaterMontant(8600, 'XOF')}',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reprendre le reste'));
      await tester.pumpAndSettle();

      final envoyees = requetes(m.transport, '/commandes');
      expect(envoyees, hasLength(3), reason: 'A, B refusée, B reprise');
      expect(
        cleDe(envoyees[1]),
        cleDe(envoyees[2]),
        reason: 'un nouvel essai qui changerait de clé créerait un doublon',
      );
      expect(articlesDe(envoyees[2]), [_articleB],
          reason: 'la reprise ne réenvoie QUE le reste');

      // Les deux commandes existent, le panier est vide, la scission est finie.
      expect(m.container.read(confirmationProvider).commandesCreees,
          hasLength(2));
      expect(m.container.read(panierProvider).estVide, isTrue);
      expect(find.text('Reprendre le reste'), findsNothing);
      expect(blocRemise('5311'), findsOneWidget);
      expect(blocRemise('5312'), findsOneWidget);

      await fin(tester, m.container);
    });
  });

  group('Panier — la scission acceptée ne survit pas à un changement', () {
    test('modifier le contenu ABANDONNE les tronçons', () {
      final container = ProviderContainer(retry: pasDeRetry);
      addTearDown(container.dispose);
      final panier = container.read(panierProvider.notifier)
        ..demarrer(zoneId: _zone, categorieSlug: 'boutique_superette')
        ..ajouter(const LignePanier(
          prestataireId: _vendeurA,
          articleId: _articleA,
          quantite: 1,
        ))
        ..ajouter(const LignePanier(
          prestataireId: _vendeurB,
          articleId: _articleB,
          quantite: 1,
        ))
        ..poserDevis(DevisPanierVue.depuisJson(devisEntier()));

      final devisA = DevisPanierVue.depuisJson(devisTroncon(_articleA));
      panier.accepterScission([
        TronconScission(
          cleIdempotence: 'cle-a',
          lignes: container.read(panierProvider).lignes.take(1).toList(),
          devis: devisA,
        ),
        TronconScission(
          cleIdempotence: 'cle-b',
          lignes: container.read(panierProvider).lignes.skip(1).toList(),
          devis: DevisPanierVue.depuisJson(devisTroncon(_articleB)),
        ),
      ]);
      expect(container.read(panierProvider).scissionAcceptee, isTrue);

      // Retirer un article rend les tronçons FAUX : ils désignent les lignes
      // d'avant, et leurs devis les chiffrent. Les garder ferait commander un
      // contenu que la cliente vient de changer.
      panier.retirer(_articleB);
      expect(container.read(panierProvider).scissionAcceptee, isFalse);
      expect(container.read(panierProvider).troncons, isEmpty);

      // Un devis frais, lui, ne touche pas à une scission acceptée.
      panier.accepterScission([
        TronconScission(
          cleIdempotence: 'cle-a',
          lignes: container.read(panierProvider).lignes,
          devis: devisA,
        ),
      ]);
      panier.poserDevis(DevisPanierVue.depuisJson(devisTroncon(_articleA)));
      expect(container.read(panierProvider).troncons, hasLength(1));
      expect(container.read(panierProvider).scissionAPresenter, isFalse,
          reason: 'un tronçon SEUL n\'est plus une scission à présenter');
    });
  });

  group('SC-006 — le serveur ne scinde jamais d\'office', () {
    testWidgets('sans appui sur le bouton, UNE seule commande est tentée',
        (tester) async {
      final m = await monter(tester, (o) {
        if (o.path == '/paniers/devis') {
          final articles = articlesDe(o);
          expect(articles, hasLength(2),
              reason: 'aucun tronçon ne doit être chiffré sans acceptation');
          return reponseJson(devisEntier());
        }
        return reponseJson(commandeCreee(cleDe(o), 8250, '5319'), statut: 201);
      });

      // La proposition est bien là — elle reste une PROPOSITION.
      expect(
        find.text('Les plats préparés se commandent séparément des courses.'),
        findsOneWidget,
      );
      expect(find.text('Scinder en 2 commandes'), findsOneWidget);

      await allerAAdresse(tester);
      await tester.tap(find.widgetWithText(
        FilledButton,
        'Commander · ${formaterMontant(8250, 'XOF')}',
      ));
      await tester.pumpAndSettle();

      final creations = requetes(m.transport, '/commandes');
      expect(creations, hasLength(1), reason: 'une seule commande tentée');
      expect(articlesDe(creations.single), [_articleA, _articleB],
          reason: 'le panier part ENTIER : rien n\'a été scindé d\'office');
      expect(m.container.read(confirmationProvider).commandesCreees,
          hasLength(1));
      expect(find.text('Commande 1'), findsNothing,
          reason: 'une commande unique ne se numérote pas');

      await fin(tester, m.container);
    });

    testWidgets('revenir à une seule commande rend la proposition intacte',
        (tester) async {
      final m = await monter(tester, (o) {
        if (o.path == '/paniers/devis') {
          final articles = articlesDe(o);
          return reponseJson(articles.length == 2
              ? devisEntier()
              : devisTroncon(articles.single));
        }
        fail('aucune commande ne doit être créée ici');
      });

      await tester.tap(find.text('Scinder en 2 commandes'));
      await tester.pumpAndSettle();
      expect(m.container.read(panierProvider).scissionAcceptee, isTrue);

      await tester.tap(find.text('Revenir à une seule commande'));
      await tester.pumpAndSettle();

      expect(m.container.read(panierProvider).scissionAcceptee, isFalse);
      expect(find.text('Scinder en 2 commandes'), findsOneWidget);
      expect(find.text('2 commandes séparées'), findsNothing);
      // Le récapitulatif de la tournée unique est de nouveau celui qui compte.
      expect(find.text(formaterMontant(8250, 'XOF')), findsOneWidget);

      await fin(tester, m.container);
    });
  });
}
