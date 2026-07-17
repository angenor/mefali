import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'etat_session.dart';
import 'stockage_jetons.dart';

part 'session.g.dart';

/// Le stockage sécurisé des jetons. Surchargé en test par `StockageJetonsMemoire`
/// (FR-035) — AUCUN canal de plateforme n'est simulé, on double la FONCTION, pas
/// le canal (FR-039). `keepAlive` : dépendance d'un porteur de processus.
@Riverpod(keepAlive: true)
StockageJetons stockageJetons(Ref ref) => const StockageJetonsSecurise();

/// La session d'authentification. `keepAlive` : elle naît au lancement et vit
/// tout le processus (FR-019 ; `@riverpod` nu = mode de panne n°2).
///
/// NE dépend d'AUCUN provider de client : le renouvellement vit dans
/// l'intercepteur, qui capture le client de `clientSession`. Un
/// `ref.watch(clientSessionProvider)` ici serait une arête INUTILE — donc une
/// ré-évaluation de trop (R3).
@Riverpod(keepAlive: true)
class Session extends _$Session {
  /// Rend l'état INITIAL et NE charge RIEN : `charger()` reste déclenché
  /// impérativement depuis `RacineAuth.initState`. `AsyncNotifier` est INTERDIT
  /// ici (son `build()` redémarre en `AsyncLoading` ⇒ écran de démarrage
  /// réapparu — FR-022, R6).
  @override
  EtatSession build() => const EtatSession.initiale();

  /// Traduction FIDÈLE de l'ancien `ChangeNotifier` : la notification émettait
  /// TOUJOURS, sans comparer (`RacineAuth` rebâtissait à chaque appel). Le défaut
  /// v3 (« all providers now use `==` to filter updates ») filtrerait les
  /// écritures égales et rendrait `expect(emissions, 1)` PLUS FAIBLE que
  /// l'assertion d'origine (FR-003/FR-004). NE PAS « optimiser ».
  @override
  bool updateShouldNotify(EtatSession previous, EtatSession next) => true;

  /// Relit le stockage au démarrage. À appeler avant le premier `build`.
  ///
  /// Lecture PUIS `state =` : l'état dépend de ce qui est lu. Une seule émission,
  /// comme l'unique notification d'origine.
  Future<void> charger() async {
    final jetons = await ref.read(stockageJetonsProvider).lire();
    state = EtatSession(charge: true, jetons: jetons);
  }

  /// Ouvre (ou remplace) la session — après vérification OTP ou inscription.
  ///
  /// `state =` PUIS `await` l'I/O (R3, décision a5) : ce que l'intercepteur voit
  /// change IMMÉDIATEMENT — l'ordre inverse laisserait une requête concurrente
  /// porter l'ANCIEN jeton ⇒ 401 ⇒ requête AJOUTÉE (FR-002). `charge` est
  /// préservé (il ne redevient jamais `false`).
  Future<void> ouvrir(JetonsSession jetons) async {
    state = EtatSession(charge: state.charge, jetons: jetons);
    await ref.read(stockageJetonsProvider).ecrire(jetons);
  }

  /// Ferme la session LOCALEMENT et efface les jetons.
  ///
  /// Ne révoque rien côté serveur : la révocation est un appel à part.
  /// `state =` PUIS `await` l'I/O, `charge` préservé.
  Future<void> fermer() async {
    state = EtatSession(charge: state.charge, jetons: null);
    await ref.read(stockageJetonsProvider).effacer();
  }
}
