import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints de livraison.
class DeliveryEndpoint {
  const DeliveryEndpoint(this._dio);

  final Dio _dio;

  /// Recupere la mission pending du livreur connecte.
  Future<DeliveryMission?> getPendingMission() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/deliveries/pending',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final mission = data['mission'];
    if (mission == null) return null;
    return DeliveryMission.fromJson(mission as Map<String, dynamic>);
  }
}
