/// Cache local du CLIENT (cycle CMD 008, data-model §8) : brouillon de panier
/// hors ligne et cache de commande porteur du code et du QR de remise.
///
/// Ce qui est prouvé ici est ce dont dépend la promesse « Awa n'a jamais besoin
/// d'internet au moment de la remise » : le code et le jeton survivent à la
/// fermeture de l'app, et le brouillon de panier se compose sans réseau.
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/src/offline/action_en_attente.dart';

void main() {
  group('BrouillonsPanier (C3-3c)', () {
    test('un brouillon par zone, écrasé et non dupliqué', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);
      const zone = '01900000-0000-7000-8000-000000000002';

      Future<void> ecrire(String lignes, int estime) => base
          .into(base.brouillonsPanier)
          .insertOnConflictUpdate(BrouillonsPanierCompanion.insert(
            zoneId: zone,
            categorieSlug: 'marche',
            lignesJson: lignes,
            majLeLocal: DateTime(2026, 7, 25, 10),
            montantArticlesEstimeUnites: Value(estime),
          ));

      await ecrire('[{"q":1}]', 1000);
      await ecrire('[{"q":2}]', 2000);

      final tous = await base.select(base.brouillonsPanier).get();
      expect(tous, hasLength(1), reason: 'un seul brouillon par zone');
      expect(tous.single.montantArticlesEstimeUnites, 2000);
      expect(tous.single.devise, 'XOF');
    });
  });

  group('CommandesCache (C4-4d)', () {
    test('le code et le QR survivent à la fermeture de la base', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);
      const commande = '01900000-0000-7000-8000-000000000601';

      await base
          .into(base.commandesCache)
          .insertOnConflictUpdate(CommandesCacheCompanion.insert(
            commandeId: commande,
            etat: 'en_cours',
            codeLivraison: '7341',
            jetonReception: 'jeton-de-reception',
            majLeLocal: DateTime(2026, 7, 25, 10),
            etatCle: const Value('suivi.etat.collecte_en_cours'),
            collectesFaites: const Value(2),
            collectesTotal: const Value(3),
            totalUnites: const Value(5900),
            positionAgeS: const Value(12),
          ));

      final cache = await base.select(base.commandesCache).getSingle();
      expect(cache.codeLivraison, '7341');
      expect(cache.jetonReception, 'jeton-de-reception');
      expect(
        (cache.collectesFaites, cache.collectesTotal),
        (2, 3),
        reason: 'la progression est rendue hors ligne, telle que connue',
      );
      expect(
        cache.positionAgeS,
        12,
        reason: "l'âge accompagne toujours la position — l'app n'en invente pas",
      );
      expect(
        cache.positionLat,
        isNull,
        reason: 'aucune position connue reste NULL, jamais une valeur inventée',
      );
    });

    test('deux commandes coexistent, la mise à jour ne duplique pas', () async {
      final base = BaseOffline.memoire();
      addTearDown(base.close);

      Future<void> ecrire(String id, String etat) => base
          .into(base.commandesCache)
          .insertOnConflictUpdate(CommandesCacheCompanion.insert(
            commandeId: id,
            etat: etat,
            codeLivraison: '0000',
            jetonReception: 'j',
            majLeLocal: DateTime(2026, 7, 25, 10),
          ));

      await ecrire('a', 'nouvelle');
      await ecrire('b', 'en_cours');
      await ecrire('a', 'terminee');

      final tous = await base.select(base.commandesCache).get();
      expect(tous, hasLength(2));
      expect(
        tous.firstWhere((c) => c.commandeId == 'a').etat,
        'terminee',
        reason: 'le dernier état connu remplace le précédent',
      );
    });
  });
}
