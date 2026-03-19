import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/order_endpoint.dart';

/// Provider pour les commandes du client connecte.
final customerOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final endpoint = OrderEndpoint(ref.watch(dioProvider));
  return endpoint.getCustomerOrders();
});

/// Provider pour une commande specifique par ID.
final orderProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, orderId) async {
  final endpoint = OrderEndpoint(ref.watch(dioProvider));
  return endpoint.getOrderById(orderId);
});
