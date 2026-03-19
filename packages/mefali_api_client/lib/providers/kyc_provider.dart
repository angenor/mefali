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
class KycNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Upload un document KYC.
  Future<KycDocument> uploadDocument({
    required String userId,
    required KycDocumentType documentType,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final doc = await ref.read(kycEndpointProvider).uploadDocument(
            userId: userId,
            documentType: documentType,
            fileBytes: fileBytes,
            fileName: fileName,
          );
      state = const AsyncValue.data(null);
      ref.invalidate(kycSummaryProvider(userId));
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
      final user = await ref.read(kycEndpointProvider).activateDriver(userId);
      state = const AsyncValue.data(null);
      ref.invalidate(pendingDriversProvider);
      ref.invalidate(kycSummaryProvider(userId));
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider pour le notifier KYC.
final kycNotifierProvider =
    NotifierProvider.autoDispose<KycNotifier, AsyncValue<void>>(
  KycNotifier.new,
);
