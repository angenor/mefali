import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/dio_client.dart';

/// Client pour les endpoints utilisateur (profil).
class UserEndpoint {
  const UserEndpoint(this._dio);

  final Dio _dio;

  /// Recupere le profil de l'utilisateur connecte.
  Future<User> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    final data = response.data!['data'] as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Met a jour le profil (nom).
  Future<User> updateProfile({String? name}) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me',
      data: {'name': ?name},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Demande un changement de telephone (envoie OTP au nouveau numero).
  Future<void> requestPhoneChange(String newPhone) async {
    await _dio.post<void>(
      '/users/me/change-phone/request',
      data: {'new_phone': newPhone},
    );
  }

  /// Verifie l'OTP et met a jour le telephone.
  Future<User> verifyPhoneChange(String newPhone, String otp) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/users/me/change-phone/verify',
      data: {'new_phone': newPhone, 'otp': otp},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }
}

/// Provider Riverpod pour [UserEndpoint].
final userEndpointProvider = Provider<UserEndpoint>(
  (ref) => UserEndpoint(ref.watch(dioProvider)),
);
