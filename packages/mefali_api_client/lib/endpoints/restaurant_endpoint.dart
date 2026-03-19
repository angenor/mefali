import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour l'endpoint de découverte des restaurants (B2C).
class RestaurantEndpoint {
  const RestaurantEndpoint(this._dio);

  final Dio _dio;

  /// Liste les restaurants disponibles (onboarding_step = 5).
  /// [category] null = toutes catégories.
  Future<List<RestaurantSummary>> listRestaurants({
    String? category,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants',
      queryParameters: {
        'category': ?category,
        'per_page': 40,
      },
    );

    final list = response.data!['data'] as List;
    return list
        .map((e) => RestaurantSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
