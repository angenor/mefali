import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';
import '../endpoints/kyc_endpoint.dart';

/// Provider pour le endpoint KYC.
final kycEndpointProvider = Provider<KycEndpoint>((ref) {
  return KycEndpoint(ref.watch(dioProvider));
});

/// Liste des livreurs en attente de KYC.
final pendingDriversProvider =
    FutureProvider.autoDispose<List<User>>((ref) async {
  final endpoint = ref.watch(kycEndpointProvider);
  return endpoint.getPendingDrivers();
});

/// Resume KYC pour un livreur specifique.
final kycSummaryProvider = FutureProvider.autoDispose
    .family<KycSummaryResponse, String>((ref, userId) async {
  final endpoint = ref.watch(kycEndpointProvider);
  return endpoint.getKycSummary(userId);
});

/// Notifier pour les actions KYC (upload, activation).
class KycNotifier extends StateNotifier<AsyncValue<void>> {
  KycNotifier(this._endpoint, this._ref)
      : super(const AsyncValue.data(null));

  final KycEndpoint _endpoint;
  final Ref _ref;

  /// Upload un document KYC.
  Future<KycDocument> uploadDocument({
    required String userId,
    required KycDocumentType documentType,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final doc = await _endpoint.uploadDocument(
        userId: userId,
        documentType: documentType,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(kycSummaryProvider(userId));
      return doc;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Active le livreur apres KYC.
  Future<User> activateDriver(String userId) async {
    state = const AsyncValue.loading();
    try {
      final user = await _endpoint.activateDriver(userId);
      state = const AsyncValue.data(null);
      _ref.invalidate(pendingDriversProvider);
      _ref.invalidate(kycSummaryProvider(userId));
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider pour le notifier KYC.
final kycNotifierProvider =
    StateNotifierProvider.autoDispose<KycNotifier, AsyncValue<void>>((ref) {
  return KycNotifier(ref.watch(kycEndpointProvider), ref);
});
