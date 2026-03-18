import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints de commandes.
class OrderEndpoint {
  const OrderEndpoint(this._dio);

  final Dio _dio;

  /// Recupere les commandes actives du marchand connecte.
  Future<List<Order>> getMerchantOrders([List<String>? statuses]) async {
    final queryParams = <String, dynamic>{};
    if (statuses != null && statuses.isNotEmpty) {
      queryParams['status'] = statuses.join(',');
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/me/orders',
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['orders'] as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Accepte une commande.
  Future<Order> acceptOrder(String orderId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/orders/$orderId/accept',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  /// Refuse une commande avec une raison.
  Future<Order> rejectOrder(String orderId, String reason) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/orders/$orderId/reject',
      data: {'reason': reason},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  /// Marque une commande comme prete.
  Future<Order> markReady(String orderId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/orders/$orderId/ready',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  /// Recupere les stats hebdomadaires du marchand connecte.
  Future<WeeklySales> getWeeklyStats() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/me/stats/weekly',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return WeeklySales.fromJson(data);
  }

  /// Cree une commande (role client, utilise pour les tests).
  Future<Order> createOrder({
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required String paymentType,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? cityId,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'merchant_id': merchantId,
        'items': items,
        'payment_type': paymentType,
        'delivery_address': deliveryAddress,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'city_id': cityId,
        'notes': notes,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }
}
