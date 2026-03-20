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

  /// Recupere les commandes du client connecte.
  Future<List<Order>> getCustomerOrders() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/me',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['orders'] as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Recupere une commande par ID (role client, verification ownership).
  Future<Order> getOrderById(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  /// Resultat de creation de commande — inclut payment_url pour mobile money.
  /// Cree une commande (role client).
  /// Retourne un [CreateOrderResult] contenant l'ordre et un eventuel payment_url.
  Future<CreateOrderResult> createOrder({
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
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (deliveryLat != null) 'delivery_lat': deliveryLat,
        if (deliveryLng != null) 'delivery_lng': deliveryLng,
        if (cityId != null) 'city_id': cityId,
        if (notes != null) 'notes': notes,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final order = Order.fromJson(data['order'] as Map<String, dynamic>);
    final paymentUrl = data['payment_url'] as String?;
    return CreateOrderResult(order: order, paymentUrl: paymentUrl);
  }
  /// M4: Retry payment for a mobile_money order stuck in pending.
  /// Returns a new payment_url from CinetPay.
  Future<String?> retryPayment(String orderId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/retry-payment',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return data['payment_url'] as String?;
  }
}

/// Resultat de creation de commande.
class CreateOrderResult {
  const CreateOrderResult({required this.order, this.paymentUrl});

  final Order order;
  final String? paymentUrl;
}

