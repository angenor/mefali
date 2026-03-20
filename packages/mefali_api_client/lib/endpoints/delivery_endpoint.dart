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

  /// Accepter une mission de livraison.
  /// Retourne la mission enrichie en cas de succes.
  /// Leve DioException avec 409 si deja assignee.
  Future<DeliveryMission> acceptMission(String deliveryId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/accept',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return DeliveryMission.fromJson(
      data['mission'] as Map<String, dynamic>,
    );
  }

  /// Refuser une mission de livraison avec raison obligatoire.
  Future<void> refuseMission(String deliveryId, String reason) async {
    await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/refuse',
      data: {'reason': reason},
    );
  }

  /// Confirmer la collecte de la commande chez le marchand.
  /// Leve DioException avec 409 si pas en statut assigned.
  Future<Map<String, dynamic>> confirmPickup(String deliveryId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/confirm-pickup',
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Mettre a jour la position GPS du livreur pendant une livraison active.
  Future<void> updateLocation(
    String deliveryId,
    double lat,
    double lng,
  ) async {
    await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/location',
      data: {'lat': lat, 'lng': lng},
    );
  }

  /// Confirmer la livraison au client.
  /// Retourne les gains du livreur pour le feedback wallet.
  Future<Map<String, dynamic>> confirmDelivery(
    String deliveryId,
    double lat,
    double lng,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/confirm',
      data: {
        'driver_location': {
          'latitude': lat,
          'longitude': lng,
        },
      },
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Signaler que le client est absent a l'adresse de livraison.
  Future<void> reportClientAbsent(
    String deliveryId,
    double lat,
    double lng,
  ) async {
    await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/client-absent',
      data: {
        'driver_location': {
          'latitude': lat,
          'longitude': lng,
        },
      },
    );
  }

  /// Resoudre le protocole client absent apres expiration du timer.
  /// Retourne les gains du livreur pour le feedback wallet.
  Future<Map<String, dynamic>> resolveClientAbsent(
    String deliveryId,
    String resolution,
    double lat,
    double lng,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/resolve-absent',
      data: {
        'resolution': resolution,
        'driver_location': {
          'latitude': lat,
          'longitude': lng,
        },
      },
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Recuperer les donnees de tracking temps reel (fallback REST).
  /// Retourne null si pas de livraison active pour cette commande.
  Future<DeliveryLocationUpdate?> getDeliveryTracking(
    String orderId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/deliveries/tracking/$orderId',
      );
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data == null || data['lat'] == null) return null;
      return DeliveryLocationUpdate.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
