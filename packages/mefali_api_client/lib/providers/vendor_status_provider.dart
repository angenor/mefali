import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'merchant_onboarding_provider.dart';

/// Provider pour le marchand courant (statut, infos).
final currentMerchantProvider =
    FutureProvider.autoDispose<Merchant>((ref) async {
  final endpoint = ref.watch(merchantEndpointProvider);
  return endpoint.getCurrentMerchant();
});

/// Notifier pour changer le statut de disponibilite du marchand.
class VendorStatusNotifier extends StateNotifier<AsyncValue<void>> {
  VendorStatusNotifier(this._ref)
      : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Change le statut de disponibilite.
  Future<void> changeStatus(VendorStatus newStatus) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = _ref.read(merchantEndpointProvider);
      await endpoint.updateStatus(newStatus);
      _ref.invalidate(currentMerchantProvider);
    });
  }
}

/// Provider pour le notifier de statut marchand.
final vendorStatusProvider =
    StateNotifierProvider.autoDispose<VendorStatusNotifier, AsyncValue<void>>(
  VendorStatusNotifier.new,
);
