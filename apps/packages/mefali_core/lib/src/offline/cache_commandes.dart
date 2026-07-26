/// Cache local des commandes du CLIENT (cycle CMD 008, FR-042/043).
///
/// C'est ce cache — et lui seul — qui rend le bloc « À la livraison »
/// disponible **sans réseau** (SC-009, maquette C4-4d). Le code et le jeton y
/// sont écrits **dès la création** de la commande, pas au moment de la remise :
/// le réseau manque précisément quand le coursier arrive au portail.
///
/// Aucune I/O réseau ici, comme `FileActions` : seulement du stockage durable.
library;

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'action_en_attente.dart';
import 'file_actions.dart';

part 'cache_commandes.g.dart';

/// Cache des commandes du client — durée de vie du processus (`keepAlive`),
/// comme la base qu'il enveloppe.
@Riverpod(keepAlive: true)
CacheCommandes cacheCommandes(Ref ref) =>
    CacheCommandes(ref.watch(baseOfflineProvider));

/// Lecture et écriture du dernier état connu d'une commande.
class CacheCommandes {
  /// Construit le cache sur une base drift ouverte.
  CacheCommandes(this._base);

  final BaseOffline _base;

  /// Écrit (ou remplace) le dernier état connu d'une commande.
  ///
  /// `insertOnConflictUpdate` : une commande n'a qu'une entrée, et le suivi la
  /// réécrit à chaque rafraîchissement. Ne JAMAIS insérer sans remplacer —
  /// deux lignes pour une commande rendraient le hors-ligne indéterministe.
  Future<void> memoriser({
    required String commandeId,
    required String etat,
    required String codeLivraison,
    required String jetonReception,
    required DateTime majLeLocal,
    String etatCle = '',
    int collectesFaites = 0,
    int collectesTotal = 0,
    int totalUnites = 0,
    String devise = 'XOF',
    double? positionLat,
    double? positionLon,
    int? positionAgeS,
  }) async {
    await _base.into(_base.commandesCache).insertOnConflictUpdate(
          CommandesCacheCompanion.insert(
            commandeId: commandeId,
            etat: etat,
            codeLivraison: codeLivraison,
            jetonReception: jetonReception,
            majLeLocal: majLeLocal,
            etatCle: Value(etatCle),
            collectesFaites: Value(collectesFaites),
            collectesTotal: Value(collectesTotal),
            totalUnites: Value(totalUnites),
            devise: Value(devise),
            positionLat: Value(positionLat),
            positionLon: Value(positionLon),
            positionAgeS: Value(positionAgeS),
          ),
        );
  }

  /// Dernier état connu d'une commande, ou `null` si elle n'a jamais été vue.
  Future<CommandeCache?> lire(String commandeId) {
    return (_base.select(_base.commandesCache)
          ..where((t) => t.commandeId.equals(commandeId)))
        .getSingleOrNull();
  }

  /// Toutes les commandes en cache, la plus récemment vue d'abord — de quoi
  /// afficher la liste sans réseau.
  Future<List<CommandeCache>> toutes() {
    return (_base.select(_base.commandesCache)
          ..orderBy([(t) => OrderingTerm.desc(t.majLeLocal)]))
        .get();
  }

  /// Oublie une commande (terminée ou annulée) : le code de remise ne doit pas
  /// survivre à la course qu'il servait (minimisation ARTCI).
  Future<void> oublier(String commandeId) async {
    await (_base.delete(_base.commandesCache)
          ..where((t) => t.commandeId.equals(commandeId)))
        .go();
  }
}
