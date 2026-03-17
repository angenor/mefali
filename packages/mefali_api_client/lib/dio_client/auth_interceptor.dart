import 'package:dio/dio.dart';

/// Intercepteur Dio qui gere automatiquement les tokens JWT.
///
/// - Ajoute le header Authorization sur chaque requete
/// - Intercepte les 401, tente un refresh, et rejoue la requete originale
/// - Declenche le logout si le refresh echoue
///
/// Utilise [QueuedInterceptorsWrapper] pour eviter les refresh concurrents.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required Dio dio,
    required String? Function() getAccessToken,
    required String? Function() getRefreshToken,
    required Future<void> Function(String accessToken, String refreshToken)
    onTokensRefreshed,
    required Future<void> Function() onLogout,
  }) : _dio = dio,
       _getAccessToken = getAccessToken,
       _getRefreshToken = getRefreshToken,
       _onTokensRefreshed = onTokensRefreshed,
       _onLogout = onLogout;

  final Dio _dio;
  final String? Function() _getAccessToken;
  final String? Function() _getRefreshToken;
  final Future<void> Function(String, String) _onTokensRefreshed;
  final Future<void> Function() _onLogout;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Ne pas tenter de refresh sur les routes auth elles-memes
    if (err.requestOptions.path.contains('/auth/')) {
      return handler.next(err);
    }

    final refreshToken = _getRefreshToken();
    if (refreshToken == null) {
      await _onLogout();
      return handler.next(err);
    }

    try {
      // Utiliser un Dio sans intercepteur pour eviter la boucle infinie
      final plainDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          contentType: 'application/json',
        ),
      );

      final response = await plainDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;

      await _onTokensRefreshed(newAccessToken, newRefreshToken);

      // Rejouer la requete originale avec le nouveau token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh echoue → logout
      await _onLogout();
      return handler.next(err);
    }
  }
}
