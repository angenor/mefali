import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'merchant_orders_provider.dart';

/// Etat du dashboard ventes : donnees + metadata cache.
class WeeklySalesState {
  final WeeklySales stats;
  final DateTime lastSync;
  final bool isCached;

  const WeeklySalesState({
    required this.stats,
    required this.lastSync,
    this.isCached = false,
  });
}

// Cache memoire pour le mode offline.
WeeklySales? _cachedStats;
DateTime? _cachedAt;

/// Purge le cache ventes. A appeler au logout pour eviter
/// qu'un autre marchand voie les stats du precedent en offline.
void clearSalesCache() {
  _cachedStats = null;
  _cachedAt = null;
}

/// Provider pour les stats hebdomadaires du marchand.
/// Tente l'API, retombe sur le cache en cas d'echec reseau.
final weeklyStatsProvider =
    FutureProvider.autoDispose<WeeklySalesState>((ref) async {
  final endpoint = ref.watch(orderEndpointProvider);

  try {
    final stats = await endpoint.getWeeklyStats();
    _cachedStats = stats;
    _cachedAt = DateTime.now();
    return WeeklySalesState(stats: stats, lastSync: DateTime.now());
  } on DioException catch (e) {
    // Retourner les donnees en cache uniquement pour les erreurs reseau
    if (_cachedStats != null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown)) {
      return WeeklySalesState(
        stats: _cachedStats!,
        lastSync: _cachedAt!,
        isCached: true,
      );
    }
    rethrow;
  }
});
