import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'merchant_onboarding_provider.dart';

/// Provider pour lire les fermetures exceptionnelles a venir.
final upcomingClosuresProvider =
    FutureProvider.autoDispose<List<ExceptionalClosure>>((ref) async {
  final endpoint = ref.watch(merchantEndpointProvider);
  return endpoint.getMyClosures();
});

/// Notifier pour creer/supprimer des fermetures exceptionnelles.
class ExceptionalClosuresNotifier extends StateNotifier<AsyncValue<void>> {
  ExceptionalClosuresNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Cree une fermeture exceptionnelle.
  Future<void> createClosure({
    required String closureDate,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = _ref.read(merchantEndpointProvider);
      await endpoint.createClosure(closureDate: closureDate, reason: reason);
      _ref.invalidate(upcomingClosuresProvider);
    });
  }

  /// Supprime une fermeture exceptionnelle.
  Future<void> deleteClosure(String closureId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final endpoint = _ref.read(merchantEndpointProvider);
      await endpoint.deleteClosure(closureId);
      _ref.invalidate(upcomingClosuresProvider);
    });
  }
}

/// Provider pour le notifier de fermetures exceptionnelles.
final exceptionalClosuresNotifierProvider = StateNotifierProvider.autoDispose<
    ExceptionalClosuresNotifier, AsyncValue<void>>(
  ExceptionalClosuresNotifier.new,
);
