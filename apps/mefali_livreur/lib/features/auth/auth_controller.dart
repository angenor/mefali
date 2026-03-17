import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Controleur orchestrant le flow d'authentification livreur :
/// requestOtp → verifyOtp (role=driver, sponsorPhone) → home.
class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Demande l'envoi d'un OTP au [phone].
  Future<void> requestOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authEndpointProvider).requestOtp(phone);
    });
  }

  /// Verifie l'OTP et finalise l'inscription livreur.
  Future<void> verifyOtp(
    String phone,
    String otp,
    String name,
    String sponsorPhone,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(
            phone,
            otp,
            name,
            role: 'driver',
            sponsorPhone: sponsorPhone,
          );
    });
  }
}

/// Provider pour le controleur d'authentification livreur.
final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(AuthController.new);
