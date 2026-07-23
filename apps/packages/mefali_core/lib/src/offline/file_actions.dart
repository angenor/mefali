/// File d'actions coursier hors-ligne — API de haut niveau (constitution V, R5).
///
/// `FileActions` enveloppe la base drift : enfiler une action idempotente
/// (`uuidClient`), lire/écrire le cache de course pré-provisionné, cocher un
/// arrêt de façon optimiste, et parcourir la file pour le rejeu. Le rejeu HTTP
/// lui-même vit dans le provider de course (il connaît le client généré) — ici,
/// seulement le stockage durable.
library;

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'action_en_attente.dart';

part 'file_actions.g.dart';

/// Base drift de la file offline — durée de vie du processus (`keepAlive`).
/// Surchargée en test par une base mémoire.
@Riverpod(keepAlive: true)
BaseOffline baseOffline(Ref ref) {
  final base = BaseOffline.ouvrir();
  ref.onDispose(base.close);
  return base;
}

/// File d'actions coursier idempotente + cache de course pré-provisionné.
@Riverpod(keepAlive: true)
FileActions fileActions(Ref ref) => FileActions(ref.watch(baseOfflineProvider));

/// API de stockage de la file offline (drift). Aucune I/O réseau ici (R5).
class FileActions {
  /// Construit sur une base drift ouverte.
  FileActions(this._base);

  final BaseOffline _base;

  /// Enfile une action POST idempotente. Un `uuidClient` déjà présent est
  /// laissé tel quel (rejeu d'une même action = aucun doublon, V).
  Future<void> enfiler({
    required String uuidClient,
    required String endpoint,
    required String payloadJson,
    List<int>? photoOctets,
    required DateTime creeLeLocal,
  }) async {
    await _base.into(_base.actionsEnAttente).insert(
          ActionsEnAttenteCompanion.insert(
            uuidClient: uuidClient,
            endpoint: endpoint,
            payloadJson: payloadJson,
            photoOctets: Value(photoOctets == null ? null : Uint8List.fromList(photoOctets)),
            creeLeLocal: creeLeLocal,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Actions en attente de rejeu, les plus anciennes d'abord.
  Future<List<ActionEnAttente>> enAttente() {
    return (_base.select(_base.actionsEnAttente)
          ..orderBy([(a) => OrderingTerm(expression: a.creeLeLocal)]))
        .get();
  }

  /// Retire une action de la file (rejeu abouti ou refus définitif réconcilié).
  Future<void> retirer(String uuidClient) async {
    await (_base.delete(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .go();
  }

  /// Marque un échec de rejeu RETRYABLE (réseau) : incrémente le compteur et
  /// mémorise le motif, sans retirer l'action.
  Future<void> marquerEchec(String uuidClient, String motif) async {
    final ligne = await (_base.select(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .getSingleOrNull();
    if (ligne == null) return;
    await (_base.update(_base.actionsEnAttente)
          ..where((a) => a.uuidClient.equals(uuidClient)))
        .write(ActionsEnAttenteCompanion(
      tentatives: Value(ligne.tentatives + 1),
      dernierMotif: Value(motif),
    ));
  }

  /// Remplace le cache de course par les arrêts pré-provisionnés fournis.
  Future<void> remplacerCache(List<ArretsPreprovisionnesCompanion> arrets) async {
    await _base.transaction(() async {
      await _base.delete(_base.arretsPreprovisionnes).go();
      await _base.batch((b) => b.insertAll(_base.arretsPreprovisionnes, arrets));
    });
  }

  /// Arrêts pré-provisionnés en cache (course active hors-ligne).
  Future<List<ArretPreprovisionne>> arretsCache() {
    return _base.select(_base.arretsPreprovisionnes).get();
  }

  /// Coche optimiste locale d'un arrêt (avant réconciliation serveur).
  Future<void> cocherOptimiste(String arretId) async {
    await (_base.update(_base.arretsPreprovisionnes)
          ..where((a) => a.arretId.equals(arretId)))
        .write(const ArretsPreprovisionnesCompanion(
      statutLocal: Value('collecte'),
    ));
  }
}
