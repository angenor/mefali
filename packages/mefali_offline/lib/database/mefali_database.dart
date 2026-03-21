import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'mefali_database.g.dart';

/// Table des adresses sauvegardees localement.
class SavedAddressEntries extends Table {
  TextColumn get id => text()();
  TextColumn get address => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get label => text().nullable()();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// File d'attente pour les operations offline a synchroniser.
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [SavedAddressEntries, SyncQueueEntries])
class MefaliDatabase extends _$MefaliDatabase {
  MefaliDatabase() : super(_openConnection());

  MefaliDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncQueueEntries);
          }
        },
      );

  /// Recupere les adresses recentes, triees par derniere utilisation.
  Future<List<SavedAddressEntry>> getRecentAddresses({int limit = 3}) {
    return (select(savedAddressEntries)
          ..orderBy([
            (t) => OrderingTerm.desc(t.lastUsedAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Sauvegarde ou met a jour une adresse.
  Future<void> upsertAddress(SavedAddressEntriesCompanion entry) {
    return into(savedAddressEntries).insertOnConflictUpdate(entry);
  }

  /// Sauvegarde une adresse avec des parametres simples (sans exposer Drift).
  Future<void> saveAddress({
    required String id,
    required String address,
    required double lat,
    required double lng,
  }) {
    return upsertAddress(
      SavedAddressEntriesCompanion(
        id: Value(id),
        address: Value(address),
        lat: Value(lat),
        lng: Value(lng),
        lastUsedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- SyncQueue operations ---

  /// Ajoute une operation a la file d'attente de synchronisation.
  /// Deduplique par entityType + entityId (remplace le payload existant).
  Future<void> enqueueSync({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    // Remove existing entry for same entity to avoid duplicates.
    await (delete(syncQueueEntries)
          ..where(
              (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId)))
        .go();
    await into(syncQueueEntries).insert(
      SyncQueueEntriesCompanion(
        entityType: Value(entityType),
        entityId: Value(entityId),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Recupere les operations en attente de synchronisation.
  Future<List<SyncQueueEntry>> getPendingSyncEntries({int limit = 20}) {
    return (select(syncQueueEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Supprime une operation de la file apres synchronisation reussie.
  Future<void> removeSyncEntry(int entryId) {
    return (delete(syncQueueEntries)..where((t) => t.id.equals(entryId))).go();
  }

  /// Incremente le compteur de tentatives pour une operation echouee.
  Future<void> incrementRetryCount(int entryId) {
    return (update(syncQueueEntries)..where((t) => t.id.equals(entryId)))
        .write(SyncQueueEntriesCompanion.custom(
      retryCount: syncQueueEntries.retryCount + const Constant(1),
    ));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mefali.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
