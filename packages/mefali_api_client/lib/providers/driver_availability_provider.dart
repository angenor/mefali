import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/delivery_endpoint.dart';

/// Notifier pour le statut de disponibilite du livreur.
class DriverAvailabilityNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final endpoint = DeliveryEndpoint(ref.read(dioProvider));
      final isAvailable = await endpoint.getAvailability();
      state = AsyncValue.data(isAvailable);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle(bool isAvailable) async {
    final previous = state;
    state = AsyncValue.data(isAvailable); // optimistic update
    try {
      final endpoint = DeliveryEndpoint(ref.read(dioProvider));
      await endpoint.setAvailability(isAvailable);
    } catch (e, st) {
      state = previous; // rollback
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() => _load();
}

/// Provider pour le statut de disponibilite du livreur.
final driverAvailabilityProvider =
    NotifierProvider.autoDispose<DriverAvailabilityNotifier, AsyncValue<bool>>(
  DriverAvailabilityNotifier.new,
);
