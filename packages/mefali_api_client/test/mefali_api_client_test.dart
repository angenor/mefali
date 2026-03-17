import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Mock HTTP adapter that always returns 401 Unauthorized.
class _Mock401Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error":{"code":"UNAUTHORIZED","message":"Token expired"}}',
      401,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('mefali_api_client', () {
    test('package is importable', () {
      expect(true, isTrue);
    });
  });

  group('AuthState', () {
    test('isAuthenticated returns true when accessToken present', () {
      const state = AuthState(accessToken: 'token');
      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false when accessToken null', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith preserves existing values', () {
      const state = AuthState(accessToken: 'a', refreshToken: 'r');
      final updated = state.copyWith(isLoading: true);
      expect(updated.accessToken, 'a');
      expect(updated.refreshToken, 'r');
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clears values with flags', () {
      const state = AuthState(accessToken: 'a', refreshToken: 'r');
      final updated = state.copyWith(
        clearAccessToken: true,
        clearRefreshToken: true,
      );
      expect(updated.accessToken, isNull);
      expect(updated.refreshToken, isNull);
    });

    test('copyWith updates specific fields', () {
      const state = AuthState(accessToken: 'a');
      final updated = state.copyWith(
        refreshToken: 'r',
        accessToken: 'b',
      );
      expect(updated.accessToken, 'b');
      expect(updated.refreshToken, 'r');
    });
  });

  group('AuthInterceptor', () {
    test('adds Authorization header when token present', () async {
      String? capturedAuth;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      dio.interceptors.add(AuthInterceptor(
        dio: dio,
        getAccessToken: () => 'test-access-token',
        getRefreshToken: () => 'test-refresh-token',
        onTokensRefreshed: (_, _) async {},
        onLogout: () async {},
      ));

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedAuth = options.headers['Authorization'] as String?;
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{'data': 'ok'},
          ));
        },
      ));

      await dio.get<dynamic>('/test');
      expect(capturedAuth, 'Bearer test-access-token');
    });

    test('does not add header when no token', () async {
      String? capturedAuth;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      dio.interceptors.add(AuthInterceptor(
        dio: dio,
        getAccessToken: () => null,
        getRefreshToken: () => null,
        onTokensRefreshed: (_, _) async {},
        onLogout: () async {},
      ));

      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedAuth = options.headers['Authorization'] as String?;
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{'data': 'ok'},
          ));
        },
      ));

      await dio.get<dynamic>('/test');
      expect(capturedAuth, isNull);
    });

    test('triggers logout on 401 when no refresh token', () async {
      var logoutCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      dio.interceptors.add(AuthInterceptor(
        dio: dio,
        getAccessToken: () => 'expired-token',
        getRefreshToken: () => null,
        onTokensRefreshed: (_, _) async {},
        onLogout: () async {
          logoutCalled = true;
        },
      ));

      // Use a mock HTTP adapter that returns 401 so the error flows
      // through the interceptor onError chain properly.
      dio.httpClientAdapter = _Mock401Adapter();

      try {
        await dio.get<dynamic>('/api/v1/users/me');
      } catch (_) {
        // Expected DioException
      }

      expect(logoutCalled, isTrue);
    });
  });

  group('JWT local expiration check', () {
    String createTestJwt({required int expInSeconds}) {
      final header = base64Url
          .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = base64Url.encode(utf8.encode(jsonEncode({
        'sub': 'test-user-id',
        'role': 'client',
        'iat': now,
        'exp': now + expInSeconds,
      })));
      final signature = base64Url.encode(utf8.encode('fake-signature'));
      return '$header.$payload.$signature';
    }

    test('valid token keeps user authenticated', () {
      final token = createTestJwt(expInSeconds: 900);
      final state = AuthState(accessToken: token);
      expect(state.isAuthenticated, isTrue);
    });

    test('expired token with refresh token keeps session', () {
      final token = createTestJwt(expInSeconds: -100);
      final state = AuthState(accessToken: token, refreshToken: 'refresh');
      expect(state.isAuthenticated, isTrue);
      expect(state.refreshToken, isNotNull);
    });

    test('no token means not authenticated', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
    });
  });
}
