import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Controleur orchestrant le flow d'authentification :
/// requestOtp → verifyOtp → home.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Demande l'envoi d'un OTP au [phone].
  Future<void> requestOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authEndpointProvider).requestOtp(phone);
    });
  }

  /// Verifie l'OTP et finalise l'inscription/connexion.
  Future<void> verifyOtp(
    String phone,
    String otp,
    String? name, {
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(phone, otp, name, referralCode: referralCode);
    });
  }
}

/// Provider pour le controleur d'authentification.
final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
