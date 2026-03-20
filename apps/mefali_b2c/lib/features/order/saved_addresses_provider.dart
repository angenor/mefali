import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_offline/mefali_offline.dart';

/// Instance partagee de la base de donnees Drift.
final mefaliDatabaseProvider = Provider<MefaliDatabase>((ref) {
  final db = MefaliDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider des adresses recentes (autoDispose).
final savedAddressesProvider =
    FutureProvider.autoDispose<List<SavedAddressEntry>>((ref) async {
  final db = ref.watch(mefaliDatabaseProvider);
  return db.getRecentAddresses();
});

/// Sauvegarde une adresse dans Drift.
Future<void> saveAddress(
  MefaliDatabase db, {
  required String id,
  required String address,
  required double lat,
  required double lng,
}) async {
  await db.upsertAddress(
    SavedAddressEntriesCompanion(
      id: Value(id),
      address: Value(address),
      lat: Value(lat),
      lng: Value(lng),
      lastUsedAt: Value(DateTime.now()),
    ),
  );
}
