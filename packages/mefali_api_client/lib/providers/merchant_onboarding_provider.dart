import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../endpoints/merchant_endpoint.dart';
import '../dio_client/dio_client.dart';

/// Etat de l'onboarding marchand dans le wizard.
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.merchant,
    this.products = const [],
    this.businessHours = const [],
    this.walletCreated = false,
  });

  final int currentStep;
  final Merchant? merchant;
  final List<Product> products;
  final List<BusinessHours> businessHours;
  final bool walletCreated;

  bool get isCreated => merchant != null;

  OnboardingState copyWith({
    int? currentStep,
    Merchant? merchant,
    List<Product>? products,
    List<BusinessHours>? businessHours,
    bool? walletCreated,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      merchant: merchant ?? this.merchant,
      products: products ?? this.products,
      businessHours: businessHours ?? this.businessHours,
      walletCreated: walletCreated ?? this.walletCreated,
    );
  }
}

/// Provider pour le endpoint marchand.
final merchantEndpointProvider = Provider<MerchantEndpoint>((ref) {
  return MerchantEndpoint(ref.watch(dioProvider));
});

/// Notifier gerant le flux d'onboarding marchand.
class OnboardingNotifier extends StateNotifier<AsyncValue<OnboardingState>> {
  OnboardingNotifier(this._endpoint) : super(const AsyncValue.data(OnboardingState()));

  final MerchantEndpoint _endpoint;

  /// Etape 1a: Envoie OTP au marchand.
  Future<void> requestOtp({
    required String phone,
    required String name,
    String? address,
    String? category,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _endpoint.requestOtp(
        phone: phone,
        name: name,
        address: address,
        category: category,
      );
      return state.value ?? const OnboardingState();
    });
  }

  /// Etape 1b: Verifie OTP et cree le marchand.
  Future<void> verifyAndCreate({
    required String phone,
    required String otp,
    required String name,
    String? address,
    String? category,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final merchant = await _endpoint.verifyAndCreate(
        phone: phone,
        otp: otp,
        name: name,
        address: address,
        category: category,
      );
      return OnboardingState(
        currentStep: 1,
        merchant: merchant,
        walletCreated: true,
      );
    });
  }

  /// Etape 2: Ajoute des produits.
  Future<void> addProducts(List<Map<String, dynamic>> products) async {
    final merchantId = state.value?.merchant?.id;
    if (merchantId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final created = await _endpoint.addProducts(
        merchantId: merchantId,
        products: products,
      );
      return (state.value ?? const OnboardingState()).copyWith(
        currentStep: 2,
        products: created,
      );
    });
  }

  /// Etape 3: Definit les horaires.
  Future<void> setHours(List<Map<String, dynamic>> hours) async {
    final merchantId = state.value?.merchant?.id;
    if (merchantId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saved = await _endpoint.setHours(
        merchantId: merchantId,
        hours: hours,
      );
      return (state.value ?? const OnboardingState()).copyWith(
        currentStep: 3,
        businessHours: saved,
      );
    });
  }

  /// Etape 5: Finalise l'onboarding.
  Future<void> finalize() async {
    final merchantId = state.value?.merchant?.id;
    if (merchantId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final merchant = await _endpoint.finalize(merchantId: merchantId);
      return (state.value ?? const OnboardingState()).copyWith(
        currentStep: 5,
        merchant: merchant,
      );
    });
  }

  /// Charge le statut d'onboarding pour reprendre.
  Future<void> loadOnboardingStatus(String merchantId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final status = await _endpoint.getOnboardingStatus(merchantId);
      return OnboardingState(
        currentStep: status.merchant.onboardingStep,
        merchant: status.merchant,
        products: status.products,
        businessHours: status.businessHours,
        walletCreated: status.walletCreated,
      );
    });
  }

  /// Reset l'etat pour un nouvel onboarding.
  void reset() {
    state = const AsyncValue.data(OnboardingState());
  }
}

/// Provider pour le notifier d'onboarding.
final onboardingProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, AsyncValue<OnboardingState>>((ref) {
  return OnboardingNotifier(ref.watch(merchantEndpointProvider));
});

/// Provider pour la liste des onboardings en cours de l'agent.
final inProgressMerchantsProvider =
    FutureProvider.autoDispose<List<Merchant>>((ref) async {
  final endpoint = ref.watch(merchantEndpointProvider);
  return endpoint.getInProgress();
});
