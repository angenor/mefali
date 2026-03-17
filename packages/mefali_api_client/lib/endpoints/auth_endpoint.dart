import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';

/// Client pour les endpoints d'authentification.
class AuthEndpoint {
  const AuthEndpoint(this._dio);

  final Dio _dio;

  /// Demande l'envoi d'un OTP par SMS au numero [phone].
  Future<void> requestOtp(String phone) async {
    await _dio.post<void>('/auth/request-otp', data: {'phone': phone});
  }

  /// Verifie l'OTP et retourne les tokens + utilisateur.
  ///
  /// [name] est optionnel, fourni uniquement lors de la premiere inscription.
  /// [role] et [sponsorPhone] sont optionnels, fournis pour l'inscription livreur.
  Future<AuthResponse> verifyOtp(
    String phone,
    String otp,
    String? name, {
    String? role,
    String? sponsorPhone,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {
        'phone': phone,
        'otp': otp,
        'name': ?name,
        'role': ?role,
        'sponsor_phone': ?sponsorPhone,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  /// Rafraichit les tokens avec un refresh token valide.
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return AuthResponse.fromJson(data);
  }

  /// Revoque le refresh token cote serveur.
  Future<void> logoutServer(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refresh_token': refreshToken},
    );
  }
}

/// Provider Riverpod pour [AuthEndpoint].
final authEndpointProvider = Provider<AuthEndpoint>(
  (ref) => AuthEndpoint(ref.watch(dioProvider)),
);
