import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'merchant_onboarding_provider.dart';

/// Provider pour lire les horaires du marchand connecte.
final merchantHoursProvider =
    FutureProvider.autoDispose<List<BusinessHours>>((ref) async {
  final endpoint = ref.watch(merchantEndpointProvider);
  return endpoint.getMyHours();
});

/// Notifier pour sauvegarder les horaires du marchand.
class BusinessHoursNotifier extends StateNotifier<AsyncValue<void>> {
  BusinessHoursNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Sauvegarde les horaires (7 jours).
  Future<void> saveHours(List<Map<String, dynamic>> hours) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = _ref.read(merchantEndpointProvider);
      await endpoint.updateMyHours(hours);
      _ref.invalidate(merchantHoursProvider);
    });
  }
}

/// Provider pour le notifier de sauvegarde horaires.
final businessHoursNotifierProvider =
    StateNotifierProvider.autoDispose<BusinessHoursNotifier, AsyncValue<void>>(
  BusinessHoursNotifier.new,
);
