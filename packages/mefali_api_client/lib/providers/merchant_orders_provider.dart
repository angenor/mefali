import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/order_endpoint.dart';

/// Provider pour l'endpoint orders.
final orderEndpointProvider = Provider<OrderEndpoint>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderEndpoint(dio);
});

/// Provider pour les commandes actives du marchand.
final merchantOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final endpoint = ref.watch(orderEndpointProvider);
  return endpoint
      .getMerchantOrders(['pending', 'confirmed', 'preparing', 'ready']);
});

/// Notifier pour les actions sur les commandes (accepter, refuser, prete).
class OrderActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Accepte une commande.
  Future<void> acceptOrder(String orderId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = ref.read(orderEndpointProvider);
      await endpoint.acceptOrder(orderId);
      ref.invalidate(merchantOrdersProvider);
    });
  }

  /// Refuse une commande avec une raison.
  Future<void> rejectOrder(String orderId, String reason) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = ref.read(orderEndpointProvider);
      await endpoint.rejectOrder(orderId, reason);
      ref.invalidate(merchantOrdersProvider);
    });
  }

  /// Marque une commande comme prete.
  Future<void> markReady(String orderId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = ref.read(orderEndpointProvider);
      await endpoint.markReady(orderId);
      ref.invalidate(merchantOrdersProvider);
    });
  }
}

/// Provider pour les actions sur les commandes.
final orderActionProvider =
    NotifierProvider.autoDispose<OrderActionNotifier, AsyncValue<void>>(
  OrderActionNotifier.new,
);
