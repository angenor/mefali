/// Câblage du parcours de commande (cycle CMD 008, T067).
///
/// Ce qui est prouvé ici est ce que la validation sur émulateur a montré, mais
/// qu'aucun test ne tenait :
///
/// - la confirmation met le code et le QR **en cache** — c'est ce qui rend le
///   bloc « À la livraison » disponible sans réseau (SC-009) ;
/// - un suivi coupé du réseau bascule sur le **dernier état connu** au lieu
///   d'échouer (C4-4d) ;
/// - un devis coupé du réseau laisse le panier composable en montants ESTIMÉS
///   (C3-3c), sans annoncer une erreur que le serveur n'a jamais prononcée ;
/// - la clé d'idempotence **survit** à une tentative échouée : deux appuis sur
///   « Commander » portent la même clé, donc une seule commande (R7).
///
/// Aucun canal de plateforme : transport bouché, base drift en mémoire,
/// position injectée par la portée.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_client/panier/etat_confirmation.dart';
import 'package:mefali_client/panier/etat_panier.dart';
import 'package:mefali_client/parcours/actions_commande.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const _zone = '01900000-0000-7000-8000-000000000002';
const _vendeur = '01900000-0000-7000-8000-000000000502';
const _article = '01900000-0000-7000-8000-000000000552';

/// Corps de `POST /commandes` — réduit aux champs que la vue lit.
Map<String, Object?> _commandeCreee(String id) => {
      'id': id,
      'etat': 'nouvelle',
      'montant_articles_unites': 9000,
      'total_unites': 9800,
      'devise': 'XOF',
      'livraison': {
        'id': '019f0000-0000-7000-8000-000000000801',
        'etat': 'assignee',
        'nb_arrets': 2,
        'devis': _devisLivraison(),
      },
      'paiement': {
        'mode': 'cash',
        'etat': 'du',
        'appoint_exact_unites': 9800,
      },
      'remise': {
        'code_livraison': '5319',
        'jeton_reception': 'jeton-de-reception',
      },
    };

Map<String, Object?> _devisLivraison() => {
      'composantes': {
        'arrondi': 0,
        'base': 200,
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
      'part_coursier_unites': 150,
      'prix_client_unites': 0,
    };

Map<String, Object?> _devisPanier() => {
      'devis': _devisLivraison(),
      'devise': 'XOF',
      'groupes': [
        {
          'prestataire_id': _vendeur,
          'nom': 'Boutique Kofi',
          'nb_articles': 2,
          'sous_total_unites': 9000,
          'lignes': [
            {
              'article_id': _article,
              'nom': 'Riz parfumé 5 kg',
              'preference': 'appeler',
              'prix_unites': 4500,
              'quantite': 2,
              'sous_total_unites': 9000,
            },
          ],
        },
      ],
      'montant_articles_unites': 9000,
      'paiement': {
        'cash_autorise': true,
        'motif_cle': null,
        'plafond_unites': 15000,
      },
      'scission': null,
      'total_unites': 9800,
    };

/// Panne réseau : ce que dio lève quand l'appareil est en mode avion.
DioException _modeAvion(RequestOptions options) =>
    DioException.connectionError(requestOptions: options, reason: 'mode avion');

/// Configuration de zone servie par `/config` — `transports_actifs` en vient,
/// jamais d'une constante d'app (ZON-03).
class _SourceConfigFixe implements SourceConfig {
  @override
  Future<ConfigDistante> recuperer(String zone) async =>
      ConfigDistante.depuisJson({
        'zone': zone,
        'version': 'v1',
        'transports_actifs': ['moto', 'velo'],
      });
}

class _CacheConfigMemoire implements CacheConfig {
  ConfigDistante? _config;

  @override
  Future<ConfigDistante?> lire(String zone) async => _config;

  @override
  Future<void> ecrire(ConfigDistante config) async => _config = config;
}

({ProviderContainer container, BaseOffline base}) monter(
  FutureOr<ResponseBody> Function(RequestOptions) repondre,
) {
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
      cacheConfigProvider.overrideWith((ref) => Future.value(_CacheConfigMemoire())),
      // Base drift EN MÉMOIRE : le cache est réel, le fichier ne l'est pas.
      baseOfflineProvider.overrideWithValue(base),
      // Position injectée : aucun canal de plateforme dans un test (FR-039).
      positionAppareilProvider.overrideWithValue(() async => (lat: 5.896, lon: -4.821)),
    ],
  );
  addTearDown(container.dispose);
  container.read(clientSessionProvider).dio.httpClientAdapter =
      TransportFake(repondre);
  return (container: container, base: base);
}

void composerPanier(ProviderContainer container) {
  container.read(panierProvider.notifier)
    ..demarrer(zoneId: _zone, categorieSlug: 'boutique_superette')
    ..ajouter(const LignePanier(
      prestataireId: _vendeur,
      articleId: _article,
      quantite: 2,
    ));
  expect(container.read(panierProvider).estVide, isFalse);
}

void main() {
  group('confirmation (CMD-03)', () {
    test('met le code et le QR en cache, et vide le panier', () async {
      late String cleRecue;
      final m = monter((o) {
        cleRecue = o.headers['Idempotency-Key']! as String;
        return reponseJson(_commandeCreee(cleRecue), statut: 201);
      });
      composerPanier(m.container);
      m.container.read(confirmationProvider.notifier)
        ..poserPin(5.896, -4.821)
        ..saisirRepere('Portail bleu après la pharmacie');

      final issue = await m.container
          .read(actionsCommandeProvider)
          .confirmer(libelleAdresse: 'Adresse de livraison');

      expect(issue.codeErreur, isNull);
      expect(issue.commandeId, cleRecue);

      // SC-009 — la promesse tient au fait que ces deux valeurs sont EN BASE
      // avant que le réseau ne puisse manquer.
      final cache = await m.container.read(cacheCommandesProvider).lire(cleRecue);
      expect(cache, isNotNull);
      expect(cache!.codeLivraison, '5319');
      expect(cache.jetonReception, 'jeton-de-reception');
      expect(cache.totalUnites, 9800);

      expect(m.container.read(panierProvider).estVide, isTrue,
          reason: 'le panier est vidé : la commande existe désormais');
      expect(
        m.container.read(confirmationProvider).commandeCreee?.codeLivraison,
        '5319',
      );
    });

    test('la clé d\'idempotence SURVIT à une tentative échouée (R7)', () async {
      final cles = <String>[];
      var premier = true;
      final m = monter((o) {
        cles.add(o.headers['Idempotency-Key']! as String);
        if (premier) {
          premier = false;
          throw _modeAvion(o);
        }
        return reponseJson(_commandeCreee(cles.first), statut: 201);
      });
      composerPanier(m.container);
      m.container.read(confirmationProvider.notifier)
        ..poserPin(5.896, -4.821)
        ..saisirRepere('Portail bleu après la pharmacie');

      final actions = m.container.read(actionsCommandeProvider);
      final echec = await actions.confirmer(libelleAdresse: 'Adresse');
      expect(echec.commandeId, isNull);

      final reussite = await actions.confirmer(libelleAdresse: 'Adresse');
      expect(reussite.commandeId, isNotNull);
      expect(cles, hasLength(2));
      expect(cles.first, cles.last,
          reason: 'deux clés distinctes créeraient DEUX commandes payantes');
    });

    test('un refus rend son CODE, jamais une phrase', () async {
      final m = monter((o) => reponseJson(
            {
              'code': 'vendeur_indisponible',
              'message_cle': 'commande.erreur.vendeur_indisponible',
            },
            statut: 409,
          ));
      composerPanier(m.container);
      m.container.read(confirmationProvider.notifier)
        ..poserPin(5.896, -4.821)
        ..saisirRepere('Portail bleu après la pharmacie');

      final issue = await m.container
          .read(actionsCommandeProvider)
          .confirmer(libelleAdresse: 'Adresse');

      expect(issue.commandeId, isNull);
      expect(issue.codeErreur, 'vendeur_indisponible');
    });
  });

  group('suivi hors ligne (SC-009, C4-4d)', () {
    test('bascule sur le DERNIER ÉTAT CONNU quand le réseau manque', () async {
      var reseau = true;
      final m = monter((o) {
        if (!reseau) throw _modeAvion(o);
        return reponseJson(_commandeCreee('019f0000-0000-7000-8000-000000000601'),
            statut: 201);
      });
      composerPanier(m.container);
      m.container.read(confirmationProvider.notifier)
        ..poserPin(5.896, -4.821)
        ..saisirRepere('Portail bleu après la pharmacie');
      final issue = await m.container
          .read(actionsCommandeProvider)
          .confirmer(libelleAdresse: 'Adresse');
      final commande = issue.commandeId!;

      reseau = false;
      final suivi =
          await m.container.read(actionsCommandeProvider).chargerSuivi(commande);

      expect(suivi.horsLigne, isTrue);
      expect(suivi.codeLivraison, '5319',
          reason: 'le bloc « À la livraison » se rend SANS RÉSEAU');
      expect(suivi.jetonReception, 'jeton-de-reception');
      expect(suivi.commandeId, commande);
    });

    test('sans réseau NI cache, l\'erreur remonte — aucun suivi inventé',
        () async {
      final m = monter((o) => throw _modeAvion(o));

      await expectLater(
        m.container
            .read(actionsCommandeProvider)
            .chargerSuivi('019f0000-0000-7000-8000-000000000999'),
        throwsA(isA<DioException>()),
      );
    });

    test('la liste des commandes retombe sur le cache local', () async {
      var reseau = true;
      final m = monter((o) {
        if (!reseau) throw _modeAvion(o);
        return reponseJson(_commandeCreee('019f0000-0000-7000-8000-000000000602'),
            statut: 201);
      });
      composerPanier(m.container);
      m.container.read(confirmationProvider.notifier)
        ..poserPin(5.896, -4.821)
        ..saisirRepere('Portail bleu après la pharmacie');
      await m.container
          .read(actionsCommandeProvider)
          .confirmer(libelleAdresse: 'Adresse');

      reseau = false;
      final liste =
          await m.container.read(actionsCommandeProvider).mesCommandes();

      expect(liste, hasLength(1));
      expect(liste.single.totalUnites, 9800);
      expect(liste.single.nbVendeurs, 0,
          reason: 'le cache ne connaît pas le nombre de vendeurs : on ne '
              'l\'invente pas');
    });
  });

  group('devis (CMD-01)', () {
    test('un devis obtenu remplit le panier avec les montants du SERVEUR',
        () async {
      final m = monter((o) => reponseJson(_devisPanier()));
      composerPanier(m.container);

      final code =
          await m.container.read(actionsCommandeProvider).rafraichirDevis();

      expect(code, isNull);
      final devis = m.container.read(panierProvider).devis;
      expect(devis, isNotNull);
      expect(devis!.totalUnites, 9800);
      expect(devis.montantArticlesUnites, 9000);
      expect(devis.cashAutorise, isTrue);
      expect(m.container.read(panierProvider).horsLigne, isFalse);
    });

    test('hors ligne, le panier reste composable en montants ESTIMÉS (C3-3c)',
        () async {
      final m = monter((o) => throw _modeAvion(o));
      composerPanier(m.container);

      final code =
          await m.container.read(actionsCommandeProvider).rafraichirDevis();

      expect(code, isNull, reason: 'perdre le réseau n\'est pas une erreur');
      expect(m.container.read(panierProvider).horsLigne, isTrue);
      expect(m.container.read(panierProvider).estVide, isFalse,
          reason: 'rien n\'est perdu');
    });

    test('le véhicule demandé vient de la ZONE, pas d\'une constante', () async {
      final m = monter((o) => reponseJson(_devisPanier()));
      expect(
        await m.container.read(actionsCommandeProvider).transportDemande(),
        'moto',
        reason: 'premier transport actif servi par /config',
      );
    });
  });
}
