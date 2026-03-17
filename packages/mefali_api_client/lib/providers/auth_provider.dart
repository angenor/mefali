import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mefali_core/mefali_core.dart';

import '../dio_client/auth_interceptor.dart';
import '../dio_client/dio_client.dart';
import '../endpoints/auth_endpoint.dart';

const _keyAccessToken = 'access_token';
const _keyRefreshToken = 'refresh_token';

/// Etat de l'authentification.
class AuthState {
  const AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => accessToken != null;

  AuthState copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearAccessToken = false,
    bool clearRefreshToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
      refreshToken: clearRefreshToken
          ? null
          : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier gerant l'etat d'authentification et le stockage securise.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authEndpoint, this._dio) : super(const AuthState()) {
    _setupInterceptor();
    _init();
  }

  final AuthEndpoint _authEndpoint;
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Configure l'intercepteur d'authentification sur l'instance Dio.
  void _setupInterceptor() {
    _dio.interceptors.insert(
      0,
      AuthInterceptor(
        dio: _dio,
        getAccessToken: () => state.accessToken,
        getRefreshToken: () => state.refreshToken,
        onTokensRefreshed: refreshTokens,
        onLogout: logout,
      ),
    );
  }

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
  ///
  /// [role] et [sponsorPhone] sont optionnels, utilises pour l'inscription livreur.
  Future<void> verifyOtp(
    String phone,
    String otp,
    String? name, {
    String? role,
    String? sponsorPhone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authEndpoint.verifyOtp(
        phone,
        otp,
        name,
        role: role,
        sponsorPhone: sponsorPhone,
      );
      await _storage.write(key: _keyAccessToken, value: response.accessToken);
      await _storage.write(key: _keyRefreshToken, value: response.refreshToken);
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Met a jour les tokens en memoire et dans SecureStorage.
  /// Appele par l'intercepteur apres un refresh reussi.
  Future<void> refreshTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Charge les tokens depuis le stockage securise au demarrage.
  ///
  /// Verifie l'expiration du JWT localement :
  /// - Access valide → authentifie
  /// - Access expire + refresh present → authentifie (interceptor gerera)
  /// - Access expire + pas de refresh → pas authentifie, nettoyage
  Future<void> loadFromStorage() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    final refreshToken = await _storage.read(key: _keyRefreshToken);

    if (accessToken == null) return;

    final expired = _isJwtExpired(accessToken);

    if (!expired || refreshToken != null) {
      // Token valide, ou expire mais refresh present (interceptor gerera)
      state = state.copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } else {
      // Token expire et pas de refresh → nettoyage
      await _storage.delete(key: _keyAccessToken);
    }
  }

  /// Decode le payload JWT localement pour verifier l'expiration.
  /// Pas de verification de signature — juste le champ `exp`.
  static bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = payload['exp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
      ).isBefore(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  /// Met a jour l'utilisateur en memoire (apres modification du profil).
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Deconnecte l'utilisateur et supprime les tokens locaux.
  ///
  /// Utilisee par l'intercepteur quand le refresh echoue (le token est
  /// deja invalide, pas besoin de revoquer cote serveur).
  Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    state = const AuthState();
  }

  /// Deconnecte l'utilisateur en revoquant le refresh token cote serveur,
  /// puis nettoie l'etat local.
  ///
  /// A utiliser pour les deconnexions initiees par l'utilisateur.
  /// Utilise un Dio sans intercepteur pour eviter un deadlock avec le
  /// QueuedInterceptorsWrapper.
  Future<void> logoutAndRevoke() async {
    final currentRefreshToken = state.refreshToken;
    if (currentRefreshToken != null) {
      try {
        final plainDio = Dio(
          BaseOptions(
            baseUrl: _dio.options.baseUrl,
            contentType: 'application/json',
          ),
        );
        await plainDio.post<void>(
          '/auth/logout',
          data: {'refresh_token': currentRefreshToken},
        );
      } catch (_) {
        // Best effort — nettoyer l'etat local meme si le serveur est injoignable.
      }
    }
    await logout();
  }
}

/// Provider Riverpod pour l'etat d'authentification.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) =>
      AuthNotifier(ref.watch(authEndpointProvider), ref.watch(dioProvider)),
);
