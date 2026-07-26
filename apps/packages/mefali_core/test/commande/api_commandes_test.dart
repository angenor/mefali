/// Couche d'appel de l'API commandes (cycle CMD 008, T067).
///
/// Ce qui est prouvé ici est ce dont dépend le parcours client réel :
/// - `POST /commandes` porte bien l'en-tête `Idempotency-Key` — sans elle, un
///   rejeu créerait un DOUBLON de commande, donc une double facturation ;
/// - le corps rendu porte les noms de champs du CONTRAT (`wireName`), ceux que
///   les vues d'écran lisent — un renommage serveur casse ici, pas chez Awa ;
/// - un refus métier rend son `code` (pour `messageErreurCommande`) tandis
///   qu'une panne réseau se distingue, ce qui autorise la bascule sur le cache.
///
/// Le transport est un `TransportFake` du harnais : aucun canal de plateforme,
/// aucune requête réelle, mais le client GÉNÉRÉ et ses intercepteurs au complet.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

const _commande = '01900000-0000-7000-8000-000000000601';
const _zone = '01900000-0000-7000-8000-000000000002';
const _vendeur = '01900000-0000-7000-8000-000000000301';
const _article = '01900000-0000-7000-8000-000000000401';

Map<String, Object?> _devisLivraison() => {
      'composantes': {
        'arrondi': 0,
        'base': 500,
        'effort_arrets': 100,
        'effort_attente': 0,
        'effort_paliers': 250,
        'km': 200,
        'retenue_vendeur': 0,
        'supplements': 0,
      },
      'degraded': false,
      'devise': 'XOF',
      'distance_m': 2400,
      'eta_s': 900,
      'marge_unites': 150,
      'ordre_arrets': [0, 1, 2],
      'part_coursier_unites': 900,
      'prix_client_unites': 1050,
    };

Map<String, Object?> _devisPanier() => {
      'devis': _devisLivraison(),
      'devise': 'XOF',
      'groupes': [
        {
          'prestataire_id': _vendeur,
          'nom': 'Boutique Yao',
          'nb_articles': 2,
          'sous_total_unites': 3000,
          'lignes': [
            {
              'article_id': _article,
              'nom': 'Riz 5 kg',
              'preference': 'appeler',
              'prix_unites': 1500,
              'quantite': 2,
              'sous_total_unites': 3000,
            },
          ],
        },
      ],
      'montant_articles_unites': 3000,
      'paiement': {
        'cash_autorise': false,
        'motif_cle': 'commande.cash.plafond_depasse',
        'plafond_unites': 2000,
      },
      'scission': null,
      'total_unites': 4050,
    };

Map<String, Object?> _commandeCreee() => {
      'devise': 'XOF',
      'etat': 'nouvelle',
      'id': _commande,
      'livraison': {
        'devis': _devisLivraison(),
        'etat': 'a_affecter',
        'id': '01900000-0000-7000-8000-000000000801',
        'nb_arrets': 2,
      },
      'montant_articles_unites': 3000,
      'paiement': {
        'appoint_exact_unites': 4050,
        'etat': 'a_encaisser',
        'mode': 'cash',
      },
      'remise': {
        'code_livraison': '7341',
        'jeton_reception': 'jeton-de-reception',
      },
      'total_unites': 4050,
    };

Map<String, Object?> _suivi() => {
      'coursier': null,
      'devise': 'XOF',
      'etat': 'en_cours',
      'etat_cle': 'suivi.etat.collecte_en_cours',
      'etat_le': '2026-07-25T15:05:00Z',
      'id': _commande,
      'livraison_etat': 'en_collecte',
      'livraison_id': '01900000-0000-7000-8000-000000000801',
      'montant_articles_unites': 3000,
      'position': {'lat': 5.899, 'lon': -4.821, 'age_s': 12},
      'progression': {
        'arret_courant': {
          'arret_id': '01900000-0000-7000-8000-000000000701',
          'prestataire_nom': 'Boutique Yao',
          'ordre': 2,
          'statut': 'a_collecter',
        },
        'collectes_faites': 2,
        'collectes_total': 3,
      },
      'remise': {
        'code_livraison': '7341',
        'jeton_reception': 'jeton-de-reception',
      },
      'substitution_en_attente': null,
      'total_unites': 4050,
    };

/// Monte la couche d'appel sur un transport bouché, et rend les deux.
({CommandesApi api, TransportFake transport}) monter(
  Object Function(RequestOptions options) corps, {
  int statut = 200,
}) {
  final transport = TransportFake((o) => reponseJson(corps(o), statut: statut));
  final container = conteneurMefali(
    jetons: const JetonsSession(acces: 'acces', rafraichissement: 'refresh'),
    transport: transport,
  );
  addTearDown(container.dispose);
  return (api: container.read(commandesApiProvider), transport: transport);
}

void main() {
  group('POST /paniers/devis (CMD-01)', () {
    test('envoie le panier composé et rend le corps du CONTRAT', () async {
      final m = monter((_) => _devisPanier());

      final json = await m.api.devis(
        zoneId: _zone,
        categorieSlug: 'marche',
        transportSlug: 'moto',
        lat: 5.898,
        lon: -4.822,
        lignes: [
          {
            'prestataire_id': _vendeur,
            'article_id': _article,
            'quantite': 2,
            'preference': 'appeler',
          },
        ],
      );

      final requete = m.transport.recues.single;
      expect(requete.path, '/paniers/devis');
      final envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
      expect(envoye['zone_id'], _zone);
      expect(envoye['categorie_slug'], 'marche');
      expect((envoye['lieu']! as Map)['lat'], 5.898);
      final lignes = envoye['lignes']! as List;
      expect(lignes, hasLength(1));
      expect((lignes.single as Map)['article_id'], _article);
      expect((lignes.single as Map)['preference'], 'appeler');

      // Les clés que `DevisPanierVue.depuisJson` lit — la boucle contrat↔vue.
      expect(json['montant_articles_unites'], 3000);
      expect(json['total_unites'], 4050);
      expect((json['devis']! as Map)['prix_client_unites'], 1050);
      expect(
        ((json['devis']! as Map)['composantes']! as Map)['effort_paliers'],
        250,
      );
      expect((json['paiement']! as Map)['cash_autorise'], false);
      expect(
        (json['paiement']! as Map)['motif_cle'],
        'commande.cash.plafond_depasse',
      );
      final groupe = (json['groupes']! as List).single! as Map;
      expect(groupe['prestataire_id'], _vendeur);
      expect((groupe['lignes']! as List).single! as Map, containsPair('nom', 'Riz 5 kg'));
    });
  });

  group('POST /commandes (CMD-03, SC-010)', () {
    test('porte la clé d\'idempotence en EN-TÊTE', () async {
      final m = monter((_) => _commandeCreee());

      await m.api.creer(
        idempotencyKey: _commande,
        zoneId: _zone,
        categorieSlug: 'marche',
        transportSlug: 'moto',
        modePaiement: 'cash',
        lignes: const [
          {
            'prestataire_id': _vendeur,
            'article_id': _article,
            'quantite': 2,
            'preference': 'appeler',
          },
        ],
        lat: 5.898,
        lon: -4.822,
        repereTexte: 'Portail bleu, après la pharmacie',
      );

      final requete = m.transport.recues.single;
      expect(requete.path, '/commandes');
      expect(requete.headers['Idempotency-Key'], _commande);
      final envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
      expect(envoye['mode_paiement'], 'cash');
      expect(envoye['repere_texte'], 'Portail bleu, après la pharmacie');
      expect((envoye['lieu']! as Map)['lon'], -4.822);
    });

    test('une adresse du carnet n\'envoie AUCUN lieu partiel', () async {
      final m = monter((_) => _commandeCreee());

      await m.api.creer(
        idempotencyKey: _commande,
        zoneId: _zone,
        categorieSlug: 'marche',
        transportSlug: 'moto',
        modePaiement: 'cash',
        lignes: const [
          {
            'prestataire_id': _vendeur,
            'article_id': _article,
            'quantite': 1,
            'preference': 'appeler',
          },
        ],
        adresseId: '01900000-0000-7000-8000-000000000501',
      );

      final envoye = jsonDecode(jsonEncode(m.transport.recues.single.data))
          as Map<String, Object?>;
      expect(envoye['adresse_id'], '01900000-0000-7000-8000-000000000501');
      expect(envoye.containsKey('lieu'), isFalse,
          reason: 'un lieu vide ferait échouer la création côté serveur');
    });

    test('rend le code et le jeton de remise, dès la création (R6)', () async {
      final m = monter((_) => _commandeCreee());
      final json = await m.api.creer(
        idempotencyKey: _commande,
        zoneId: _zone,
        categorieSlug: 'marche',
        transportSlug: 'moto',
        modePaiement: 'cash',
        lignes: const [
          {
            'prestataire_id': _vendeur,
            'article_id': _article,
            'quantite': 1,
            'preference': 'appeler',
          },
        ],
        lat: 5.898,
        lon: -4.822,
        repereTexte: 'Portail bleu, après la pharmacie',
      );

      expect(json['id'], _commande);
      expect(json['etat'], 'nouvelle');
      expect((json['remise']! as Map)['code_livraison'], '7341');
      expect((json['remise']! as Map)['jeton_reception'], 'jeton-de-reception');
    });
  });

  group('suivi, annulation, appel, substitution', () {
    test('GET /commandes/{id} rend la progression et la remise', () async {
      final m = monter((_) => _suivi());
      final json = await m.api.suivre(_commande);

      expect(m.transport.recues.single.path, '/commandes/$_commande');
      expect((json['progression']! as Map)['collectes_faites'], 2);
      expect((json['progression']! as Map)['collectes_total'], 3);
      expect((json['position']! as Map)['age_s'], 12);
      expect((json['remise']! as Map)['code_livraison'], '7341');
    });

    test('GET /moi/commandes rend la liste résumée', () async {
      final m = monter((_) => {
            'commandes': [
              {
                'cree_le': '2026-07-25T15:00:00Z',
                'devise': 'XOF',
                'etat': 'en_cours',
                'etat_cle': 'suivi.etat.collecte_en_cours',
                'id': _commande,
                'nb_vendeurs': 2,
                'total_unites': 4050,
              },
            ],
          });

      final liste = await m.api.mesCommandes();
      expect(m.transport.recues.single.path, '/moi/commandes');
      expect(liste, hasLength(1));
      expect(liste.single['id'], _commande);
      expect(liste.single['nb_vendeurs'], 2);
    });

    test('annuler sans motif reste sans motif (le client ne se justifie pas)',
        () async {
      final m = monter((_) => {
            'commande_id': _commande,
            'devise': 'XOF',
            'montant_avance': 0,
            'part_coursier_due': 0,
            'remboursement_du': false,
            'sans_frais': true,
          });

      final json = await m.api.annuler(_commande);
      final requete = m.transport.recues.single;
      expect(requete.path, '/commandes/$_commande/annuler');
      final envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
      expect(envoye.containsKey('motif_cle'), isFalse);
      expect(json['sans_frais'], true);
    });

    test('l\'intention d\'appel ne transporte AUCUN numéro', () async {
      final m = monter((_) => const <String, Object?>{});
      await m.api.signalerAppel(_commande);

      final requete = m.transport.recues.single;
      expect(requete.path, '/commandes/$_commande/appel');
      final envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
      expect(envoye, {'motif': 'suivi'});
    });

    test('la décision de substitution frappe la proposition visée', () async {
      final m = monter((_) => {
            'devis_prix_client_unites': 1050,
            'issue': 'acceptee',
            'montant_articles_unites': 3200,
            'total_unites': 4250,
          });

      final json = await m.api.deciderSubstitution(
        commandeId: _commande,
        substitutionId: '01900000-0000-7000-8000-000000000901',
        accepte: true,
      );

      final requete = m.transport.recues.single;
      expect(
        requete.path,
        '/commandes/$_commande/substitutions/'
        '01900000-0000-7000-8000-000000000901/decision',
      );
      final envoye = jsonDecode(jsonEncode(requete.data)) as Map<String, Object?>;
      expect(envoye['accepte'], true);
      expect(json['issue'], 'acceptee');
      // FR-050 — le devis de livraison ne bouge pas ; c'est la seule ligne du
      // corps qui prouve que la décision n'a pas retarifé la course.
      expect(json['devis_prix_client_unites'], 1050);
    });
  });

  group('refus et pannes', () {
    test('un refus métier rend son CODE, jamais une phrase', () async {
      final m = monter(
        (_) => {
          'code': 'categorie_non_mixable',
          'message_cle': 'commande.erreur.categorie_non_mixable',
        },
        statut: 409,
      );

      Object? capturee;
      try {
        await m.api.devis(
          zoneId: _zone,
          categorieSlug: 'marche',
          transportSlug: 'moto',
          lat: 5.898,
          lon: -4.822,
          lignes: const [
            {
              'prestataire_id': _vendeur,
              'article_id': _article,
              'quantite': 1,
              'preference': 'appeler',
            },
          ],
        );
      } catch (e) {
        capturee = e;
      }

      expect(capturee, isNotNull);
      expect(codeErreurApi(capturee!), 'categorie_non_mixable');
      expect(estPanneReseau(capturee), isFalse,
          reason: 'un 409 est un refus du serveur, pas une panne de réseau');
    });

    test('une panne réseau se distingue d\'un refus (bascule cache, SC-009)',
        () {
      final panne = DioException.connectionError(
        requestOptions: RequestOptions(path: '/commandes/$_commande'),
        reason: 'mode avion',
      );

      expect(estPanneReseau(panne), isTrue);
      // Aucun code : `messageErreurCommande(null)` rend le message générique
      // plutôt qu'un refus métier que le serveur n'a jamais prononcé.
      expect(codeErreurApi(panne), isNull);
    });
  });
}
