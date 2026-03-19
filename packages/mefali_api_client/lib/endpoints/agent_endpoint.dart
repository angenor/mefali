import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints agent terrain.
class AgentEndpoint {
  const AgentEndpoint(this._dio);

  final Dio _dio;

  /// Recupere les stats de performance de l'agent connecte.
  Future<AgentPerformanceStats> getMyStats() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/agents/me/stats',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return AgentPerformanceStats.fromJson(data);
  }
}
