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

  /// Recupere le marchand courant (pour le marchand connecte).
  Future<Merchant> getCurrentMerchant() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/me',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Merchant.fromJson(data['merchant'] as Map<String, dynamic>);
  }

  /// Met a jour le statut de disponibilite du marchand.
  Future<Merchant> updateStatus(VendorStatus status) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/merchants/me/status',
      data: {'status': status.apiValue},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Merchant.fromJson(data['merchant'] as Map<String, dynamic>);
  }

  // ---- Self-service business hours (Story 3.8) ----

  /// Recupere les horaires du marchand connecte.
  Future<List<BusinessHours>> getMyHours() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/me/hours',
    );

    final data = response.data!['data'] as List;
    return data
        .map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Met a jour les horaires du marchand connecte.
  Future<List<BusinessHours>> updateMyHours(
    List<Map<String, dynamic>> hours,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/merchants/me/hours',
      data: {'hours': hours},
    );

    final data = response.data!['data'] as List;
    return data
        .map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Self-service exceptional closures (Story 3.8) ----

  /// Recupere les fermetures exceptionnelles a venir.
  Future<List<ExceptionalClosure>> getMyClosures() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/merchants/me/closures',
    );

    final data = response.data!['data'] as List;
    return data
        .map((e) => ExceptionalClosure.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cree une fermeture exceptionnelle.
  Future<ExceptionalClosure> createClosure({
    required String closureDate,
    String? reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/merchants/me/closures',
      data: {
        'closure_date': closureDate,
        'reason': ?reason,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return ExceptionalClosure.fromJson(data);
  }

  /// Supprime une fermeture exceptionnelle.
  Future<void> deleteClosure(String closureId) async {
    await _dio.delete<void>('/merchants/me/closures/$closureId');
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
