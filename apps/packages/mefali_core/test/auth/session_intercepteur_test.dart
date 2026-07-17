import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_core/harnais.dart';
import 'package:mefali_core/mefali_core.dart';

// Fichier NEUF (T015) — les 3 cas de SC-005 qu'aucun test ne couvrait :
// l'unicité STRUCTURELLE de l'intercepteur (FR-013/FR-017/FR-018) et le
// renouvellement PARTAGÉ (FR-014). `test()`, PAS `testWidgets()`, AUCUN tag.
void main() {
  group('unicité de l\'intercepteur (FR-013/FR-017/FR-018)', () {
    test(
        'exactement 1 sur clientSession, 0 sur clientConfig, invariant aux '
        'ré-évaluations de session', () async {
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'a', rafraichissement: 'r'),
      );
      addTearDown(container.dispose);
      final dio = container.read(clientSessionProvider).dio;

      expect(compteIntercepteursApp(dio), 1, reason: 'première évaluation');
      expect(compteIntercepteursApp(container.read(clientConfigProvider).dio), 0,
          reason: 'FR-017 : 0 intercepteur sur le client de configuration');

      // Une ré-évaluation de la session ne touche JAMAIS le dio.
      container.invalidate(sessionProvider);
      container.read(sessionProvider);
      expect(compteIntercepteursApp(dio), 1);

      await container.read(sessionProvider.notifier).fermer();
      await container.read(sessionProvider.notifier).ouvrir(
            const JetonsSession(acces: 'b', rafraichissement: 'r2'),
          );
      await container.read(sessionProvider.notifier).ouvrir(
            const JetonsSession(acces: 'c', rafraichissement: 'r3'),
          );
      expect(compteIntercepteursApp(dio), 1,
          reason: 'fermer()/ouvrir()/ouvrir() ne posent aucun intercepteur');
    });

    test('invalidate(clientSession) recrée exactement 1 ; l\'ancien est retiré',
        () {
      final container = conteneurMefali();
      addTearDown(container.dispose);
      final dio1 = container.read(clientSessionProvider).dio;
      expect(compteIntercepteursApp(dio1), 1);

      container.invalidate(clientSessionProvider);
      final dio2 = container.read(clientSessionProvider).dio;
      expect(compteIntercepteursApp(dio2), 1,
          reason: 'le nouveau client porte exactement 1 intercepteur');
      expect(compteIntercepteursApp(dio1), 0,
          reason: 'l\'ancien a été retiré par onDispose, par IDENTITÉ');
    });

    test('la destruction du conteneur retire l\'intercepteur (FR-018)', () {
      final container = conteneurMefali();
      final dio = container.read(clientSessionProvider).dio;
      expect(compteIntercepteursApp(dio), 1);

      container.dispose();
      expect(compteIntercepteursApp(dio), 0, reason: '0 après container.dispose()');
    });
  });

  group('renouvellement partagé (FR-014)', () {
    test('N requêtes 401 concurrentes ⇒ 1 seul renouvellement, N rejeux',
        () async {
      var renouvellements = 0;
      var rejeux = 0;
      final retenue = Completer<void>();
      final transport = TransportFake((options) async {
        if (options.path.contains('/auth/rafraichir')) {
          renouvellements++;
          // LA RETENUE EST LE TEST : sans elle, le 1er renouvellement aboutirait
          // avant que la 2e requête n'échoue, et le test serait vert MÊME SANS
          // verrou (rotation R2 ⇒ jeton mort rejoué ⇒ vol présumé ⇒ session
          // révoquée en production).
          await retenue.future;
          return reponseJson({'acces': 'neuf', 'rafraichissement': 'r-neuf'});
        }
        if (options.extra['mefali.rejouee'] == true) {
          rejeux++;
          return reponseJson(const <Object>[]);
        }
        return reponseJson({'code': 'expire'}, statut: 401);
      });
      final container = conteneurMefali(
        jetons: const JetonsSession(acces: 'vieux', rafraichissement: 'r'),
        transport: transport,
      );
      addTearDown(container.dispose);
      await container.read(sessionProvider.notifier).charger();
      final moi = container.read(clientSessionProvider).getMoiApi();

      const n = 3;
      final futures = List.generate(n, (_) => moi.mesSessions());
      // Laisse les N requêtes partir, se prendre le 401, et s'attacher au MÊME
      // renouvellement (retenu ouvert).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(renouvellements, 1,
          reason: 'un seul renouvellement pour N requêtes (verrou _enCours)');

      retenue.complete();
      await Future.wait(futures);

      expect(renouvellements, 1, reason: 'toujours un seul, même après rejeu');
      expect(rejeux, n, reason: 'chaque requête est rejouée exactement une fois');
    });
  });
}
