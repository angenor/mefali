/// Cache des commandes du client (cycle CMD 008, T067) — l'API de haut niveau.
///
/// `cache_client_test.dart` prouve que la TABLE tient ses promesses ; ici, que
/// la couche que le parcours appelle réellement les tient aussi : une commande
/// n'a qu'une entrée, le rafraîchissement du suivi la met à jour au lieu de la
/// dupliquer, et l'oubli efface le code de remise avec elle.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/src/offline/action_en_attente.dart';
import 'package:mefali_core/src/offline/cache_commandes.dart';

const _commande = '01900000-0000-7000-8000-000000000601';

void main() {
  late BaseOffline base;
  late CacheCommandes cache;

  setUp(() {
    base = BaseOffline.memoire();
    cache = CacheCommandes(base);
  });
  tearDown(() => base.close());

  test('la création écrit le code et le jeton, relisibles hors ligne', () async {
    await cache.memoriser(
      commandeId: _commande,
      etat: 'nouvelle',
      codeLivraison: '7341',
      jetonReception: 'jeton-de-reception',
      majLeLocal: DateTime(2026, 7, 25, 10),
      totalUnites: 4050,
    );

    final lu = await cache.lire(_commande);
    expect(lu, isNotNull);
    expect(lu!.codeLivraison, '7341');
    expect(lu.jetonReception, 'jeton-de-reception');
    expect(lu.totalUnites, 4050);
    expect(lu.devise, 'XOF');
  });

  test('un rafraîchissement MET À JOUR, il ne duplique pas', () async {
    await cache.memoriser(
      commandeId: _commande,
      etat: 'nouvelle',
      codeLivraison: '7341',
      jetonReception: 'jeton-de-reception',
      majLeLocal: DateTime(2026, 7, 25, 10),
    );
    await cache.memoriser(
      commandeId: _commande,
      etat: 'en_cours',
      etatCle: 'suivi.etat.collecte_en_cours',
      codeLivraison: '7341',
      jetonReception: 'jeton-de-reception',
      majLeLocal: DateTime(2026, 7, 25, 10, 5),
      collectesFaites: 2,
      collectesTotal: 3,
      positionLat: 5.899,
      positionLon: -4.821,
      positionAgeS: 12,
    );

    expect(await cache.toutes(), hasLength(1));
    final lu = (await cache.lire(_commande))!;
    expect(lu.etat, 'en_cours');
    expect(lu.collectesFaites, 2);
    expect(lu.positionAgeS, 12);
  });

  test('une commande inconnue rend null, jamais une entrée inventée', () async {
    expect(await cache.lire(_commande), isNull);
  });

  test('l\'oubli emporte le code de remise avec la commande', () async {
    await cache.memoriser(
      commandeId: _commande,
      etat: 'terminee',
      codeLivraison: '7341',
      jetonReception: 'jeton-de-reception',
      majLeLocal: DateTime(2026, 7, 25, 11),
    );

    await cache.oublier(_commande);
    expect(await cache.lire(_commande), isNull);
    expect(await cache.toutes(), isEmpty);
  });

  test('la liste rend la commande vue le plus récemment en premier', () async {
    await cache.memoriser(
      commandeId: '01900000-0000-7000-8000-000000000601',
      etat: 'terminee',
      codeLivraison: '1111',
      jetonReception: 'j1',
      majLeLocal: DateTime(2026, 7, 25, 9),
    );
    await cache.memoriser(
      commandeId: '01900000-0000-7000-8000-000000000602',
      etat: 'en_cours',
      codeLivraison: '2222',
      jetonReception: 'j2',
      majLeLocal: DateTime(2026, 7, 25, 12),
    );

    final toutes = await cache.toutes();
    expect(toutes.map((c) => c.codeLivraison), ['2222', '1111']);
  });
}
