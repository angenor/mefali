import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import '../endpoints/user_endpoint.dart';
import 'auth_provider.dart';

/// Notifier gerant le profil utilisateur.
class UserProfileNotifier extends Notifier<AsyncValue<User>> {
  @override
  AsyncValue<User> build() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      return AsyncValue.data(user);
    }
    return const AsyncValue.loading();
  }

  /// Recupere le profil depuis le serveur.
  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(userEndpointProvider).getProfile(),
    );
    // Synchroniser avec authProvider
    state.whenData((user) {
      ref.read(authProvider.notifier).updateUser(user);
    });
  }

  /// Met a jour le nom de l'utilisateur.
  Future<void> updateName(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(userEndpointProvider).updateProfile(name: name),
    );
    state.whenData((user) {
      ref.read(authProvider.notifier).updateUser(user);
    });
  }

  /// Demande un changement de telephone (envoie OTP).
  Future<void> requestPhoneChange(String newPhone) async {
    await ref.read(userEndpointProvider).requestPhoneChange(newPhone);
  }

  /// Verifie l'OTP et met a jour le telephone.
  Future<void> verifyPhoneChange(String newPhone, String otp) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(userEndpointProvider).verifyPhoneChange(newPhone, otp),
    );
    state.whenData((user) {
      ref.read(authProvider.notifier).updateUser(user);
    });
  }
}

/// Provider Riverpod pour le profil utilisateur.
final userProfileProvider =
    NotifierProvider.autoDispose<UserProfileNotifier, AsyncValue<User>>(
  UserProfileNotifier.new,
);
