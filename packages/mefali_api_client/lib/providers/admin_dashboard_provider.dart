import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/admin_endpoint.dart';

/// Provider pour l'endpoint admin.
final adminEndpointProvider = Provider<AdminEndpoint>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminEndpoint(dio);
});

/// Etat du dashboard admin : donnees + metadata cache.
class AdminDashboardState {
  final DashboardStats stats;
  final DateTime lastSync;
  final bool isCached;

  const AdminDashboardState({
    required this.stats,
    required this.lastSync,
    this.isCached = false,
  });
}

// Cache memoire pour le mode offline.
DashboardStats? _cachedStats;
DateTime? _cachedAt;

/// Purge le cache dashboard admin. A appeler au logout.
void clearAdminDashboardCache() {
  _cachedStats = null;
  _cachedAt = null;
}

/// Provider pour les stats du dashboard admin.
/// Tente l'API, retombe sur le cache en cas d'echec reseau.
final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardState>((ref) async {
  final endpoint = ref.watch(adminEndpointProvider);

  try {
    final stats = await endpoint.getDashboardStats();
    _cachedStats = stats;
    _cachedAt = DateTime.now();
    return AdminDashboardState(stats: stats, lastSync: DateTime.now());
  } on DioException catch (e) {
    if (_cachedStats != null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown)) {
      return AdminDashboardState(
        stats: _cachedStats!,
        lastSync: _cachedAt!,
        isCached: true,
      );
    }
    rethrow;
  }
});
