import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/agent_endpoint.dart';

/// Provider pour l'endpoint agent.
final agentEndpointProvider = Provider<AgentEndpoint>((ref) {
  final dio = ref.watch(dioProvider);
  return AgentEndpoint(dio);
});

/// Etat du dashboard performance agent : donnees + metadata cache.
class AgentPerformanceState {
  final AgentPerformanceStats stats;
  final DateTime lastSync;
  final bool isCached;

  const AgentPerformanceState({
    required this.stats,
    required this.lastSync,
    this.isCached = false,
  });
}

// Cache memoire pour le mode offline.
AgentPerformanceStats? _cachedStats;
DateTime? _cachedAt;

/// Purge le cache agent. A appeler au logout pour eviter
/// qu'un autre agent voie les stats du precedent en offline.
void clearAgentStatsCache() {
  _cachedStats = null;
  _cachedAt = null;
}

/// Provider pour les stats de performance de l'agent.
/// Tente l'API, retombe sur le cache en cas d'echec reseau.
final agentPerformanceProvider =
    FutureProvider.autoDispose<AgentPerformanceState>((ref) async {
  final endpoint = ref.watch(agentEndpointProvider);

  try {
    final stats = await endpoint.getMyStats();
    _cachedStats = stats;
    _cachedAt = DateTime.now();
    return AgentPerformanceState(stats: stats, lastSync: DateTime.now());
  } on DioException catch (e) {
    // Retourner les donnees en cache uniquement pour les erreurs reseau
    if (_cachedStats != null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown)) {
      return AgentPerformanceState(
        stats: _cachedStats!,
        lastSync: _cachedAt!,
        isCached: true,
      );
    }
    rethrow;
  }
});
