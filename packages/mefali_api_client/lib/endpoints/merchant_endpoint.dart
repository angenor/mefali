import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints d'onboarding marchand.
class MerchantEndpoint {
  const MerchantEndpoint(this._dio);

  final Dio _dio;

  /// Envoie un OTP au numero du marchand pour demarrer l'onboarding.
  Future<void> requestOtp({
    required String phone,
    required String name,
    String? address,
    String? category,
    String? cityId,
  }) async {
    await _dio.post<void>('/merchants/onboard/request-otp', data: {
      'phone': phone,
      'name': name,
      'address': ?address,
      'category': ?category,
      'city_id': ?cityId,
    });
  }

  /// Verifie l'OTP et cree le compte marchand.
  Future<Merchant> verifyAndCreate({
    required String phone,
    required String otp,
    required String name,
    String? address,
    String? category,
    String? cityId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/merchants/onboard/verify-and-create',
      data: {
        'phone': phone,
        'otp': otp,
        'name': name,
        'address': ?address,
        'category': ?category,
        'city_id': ?cityId,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Merchant.fromJson(data['merchant'] as Map<String, dynamic>);
  }

  /// Ajoute des produits au marchand.
  Future<List<Product>> addProducts({
    required String merchantId,
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/merchants/$merchantId/products',
      data: {'products': products},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['products'] as List;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Definit les horaires d'ouverture du marchand.
  Future<List<BusinessHours>> setHours({
    required String merchantId,
    required List<Map<String, dynamic>> hours,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/merchants/$merchantId/hours',
      data: {'hours': hours},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['hours'] as List;
    return list
        .map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Finalise l'onboarding du marchand.
  Future<Merchant> finalize({required String merchantId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/merchants/$merchantId/finalize',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Merchant.fromJson(data['merchant'] as Map<String, dynamic>);
  }

  /// Recupere le statut d'onboarding d'un marchand.
  Future<OnboardingStatusResponse> getOnboardingStatus(
    String merchantId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/$merchantId/onboarding-status',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return OnboardingStatusResponse.fromJson(data);
  }

  /// Liste les onboardings en cours de l'agent.
  Future<List<Merchant>> getInProgress() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/onboard/in-progress',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['merchants'] as List;
    return list
        .map((e) => Merchant.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Reponse du statut d'onboarding.
class OnboardingStatusResponse {
  const OnboardingStatusResponse({
    required this.merchant,
    required this.products,
    required this.businessHours,
    required this.walletCreated,
  });

  factory OnboardingStatusResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusResponse(
      merchant:
          Merchant.fromJson(json['merchant'] as Map<String, dynamic>),
      products: (json['products'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      businessHours: (json['business_hours'] as List)
          .map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
          .toList(),
      walletCreated: json['wallet_created'] as bool,
    );
  }

  final Merchant merchant;
  final List<Product> products;
  final List<BusinessHours> businessHours;
  final bool walletCreated;
}
