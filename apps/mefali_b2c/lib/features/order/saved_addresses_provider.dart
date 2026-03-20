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
