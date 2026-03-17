import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mefali_core/mefali_core.dart';

import '../endpoints/auth_endpoint.dart';

const _keyAccessToken = 'access_token';
const _keyRefreshToken = 'refresh_token';

/// Etat de l'authentification.
class AuthState {
  const AuthState({
    this.user,
    this.accessToken,
    this.isLoading = false,
    this.error,
  });

  final User? user;
  final String? accessToken;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => accessToken != null;

  AuthState copyWith({
    User? user,
    String? accessToken,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearAccessToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier gerant l'etat d'authentification et le stockage securise.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authEndpoint) : super(const AuthState()) {
    _init();
  }

  final AuthEndpoint _authEndpoint;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Charge les tokens depuis SecureStorage au demarrage.
  Future<void> _init() async {
    try {
      await loadFromStorage();
    } on Exception {
      // SecureStorage indisponible (ex: tests) — ignorer.
    }
  }

  /// Demande l'envoi d'un OTP au numero [phone].
  Future<void> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authEndpoint.requestOtp(phone);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Verifie l'OTP et stocke les tokens.
  Future<void> verifyOtp(String phone, String otp, String? name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authEndpoint.verifyOtp(phone, otp, name);
      await _storage.write(key: _keyAccessToken, value: response.accessToken);
      await _storage.write(key: _keyRefreshToken, value: response.refreshToken);
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        accessToken: response.accessToken,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Charge les tokens depuis le stockage securise au demarrage.
  Future<void> loadFromStorage() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    if (accessToken != null) {
      state = state.copyWith(accessToken: accessToken);
    }
  }

  /// Deconnecte l'utilisateur et supprime les tokens.
  Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    state = const AuthState();
  }
}

/// Provider Riverpod pour l'etat d'authentification.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authEndpointProvider)),
);
