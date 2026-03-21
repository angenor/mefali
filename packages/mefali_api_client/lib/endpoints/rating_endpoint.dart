import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints de notation.
class RatingEndpoint {
  const RatingEndpoint(this._dio);

  final Dio _dio;

  /// Soumet une double notation (marchand + livreur) pour une commande livree.
  Future<RatingPair> submitRating(
    String orderId,
    SubmitRatingRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/rating',
      data: request.toJson(),
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Invalid response: missing data field');
    }
    return RatingPair.fromJson(data);
  }

  /// Verifie si une commande a deja ete notee.
  /// Retourne null si pas encore notee (404).
  Future<RatingPair?> getOrderRating(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId/rating',
    );

    final data = response.data?['data'];
    if (data == null) return null;
    return RatingPair.fromJson(data as Map<String, dynamic>);
  }
}
