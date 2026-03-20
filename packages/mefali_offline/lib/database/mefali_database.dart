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

@DriftDatabase(tables: [SavedAddressEntries])
class MefaliDatabase extends _$MefaliDatabase {
  MefaliDatabase() : super(_openConnection());

  MefaliDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mefali.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
