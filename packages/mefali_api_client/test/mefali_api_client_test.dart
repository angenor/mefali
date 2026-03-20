import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

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
      final updated = state.copyWith(refreshToken: 'r', accessToken: 'b');
      expect(updated.accessToken, 'b');
      expect(updated.refreshToken, 'r');
    });
  });

  group('AuthInterceptor', () {
    test('adds Authorization header when token present', () async {
      String? capturedAuth;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          getAccessToken: () => 'test-access-token',
          getRefreshToken: () => 'test-refresh-token',
          onTokensRefreshed: (_, _) async {},
          onLogout: () async {},
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedAuth = options.headers['Authorization'] as String?;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'data': 'ok'},
              ),
            );
          },
        ),
      );

      await dio.get<dynamic>('/test');
      expect(capturedAuth, 'Bearer test-access-token');
    });

    test('does not add header when no token', () async {
      String? capturedAuth;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          getAccessToken: () => null,
          getRefreshToken: () => null,
          onTokensRefreshed: (_, _) async {},
          onLogout: () async {},
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedAuth = options.headers['Authorization'] as String?;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'data': 'ok'},
              ),
            );
          },
        ),
      );

      await dio.get<dynamic>('/test');
      expect(capturedAuth, isNull);
    });

    test('triggers logout on 401 when no refresh token', () async {
      var logoutCalled = false;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));

      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          getAccessToken: () => 'expired-token',
          getRefreshToken: () => null,
          onTokensRefreshed: (_, _) async {},
          onLogout: () async {
            logoutCalled = true;
          },
        ),
      );

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

  group('AuthEndpoint', () {
    /// Helper: creates a Dio instance with an interceptor that captures
    /// the request body and returns a mock [AuthResponse] JSON.
    (Dio, Map<String, dynamic> Function()) dioWithCapture({
      String role = 'client',
      String status = 'active',
    }) {
      Map<String, dynamic>? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options.data as Map<String, dynamic>?;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'data': {
                    'access_token': 'test-at',
                    'refresh_token': 'test-rt',
                    'user': {
                      'id': '00000000-0000-0000-0000-000000000001',
                      'phone': '+2250700000000',
                      'name': 'Test',
                      'role': role,
                      'status': status,
                    },
                  },
                },
              ),
            );
          },
        ),
      );
      return (dio, () => captured!);
    }

    test('verifyOtp sends role and sponsorPhone when provided', () async {
      final (dio, getBody) = dioWithCapture(
        role: 'driver',
        status: 'pending_kyc',
      );
      final endpoint = AuthEndpoint(dio);

      await endpoint.verifyOtp(
        '+2250700000000',
        '123456',
        'Moussa',
        role: 'driver',
        sponsorPhone: '+2250700000001',
      );

      final body = getBody();
      expect(body['role'], 'driver');
      expect(body['sponsor_phone'], '+2250700000001');
      expect(body['phone'], '+2250700000000');
      expect(body['otp'], '123456');
      expect(body['name'], 'Moussa');
    });

    test('verifyOtp omits role and sponsorPhone when null', () async {
      final (dio, getBody) = dioWithCapture();
      final endpoint = AuthEndpoint(dio);

      await endpoint.verifyOtp('+2250700000000', '123456', 'Koffi');

      final body = getBody();
      expect(body.containsKey('role'), isFalse);
      expect(body.containsKey('sponsor_phone'), isFalse);
      expect(body['phone'], '+2250700000000');
      expect(body['name'], 'Koffi');
    });

    test('verifyOtp omits name when null (login flow)', () async {
      final (dio, getBody) = dioWithCapture();
      final endpoint = AuthEndpoint(dio);

      await endpoint.verifyOtp('+2250700000000', '123456', null);

      final body = getBody();
      expect(body.containsKey('name'), isFalse);
      expect(body.containsKey('role'), isFalse);
      expect(body.containsKey('sponsor_phone'), isFalse);
    });
  });

  group('UserEndpoint', () {
    (Dio, Map<String, dynamic> Function()) dioWithCapture() {
      Map<String, dynamic>? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options.data as Map<String, dynamic>?;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'data': {
                    'user': {
                      'id': '00000000-0000-0000-0000-000000000001',
                      'phone': '+2250700000000',
                      'name': 'Koffi Updated',
                      'role': 'client',
                      'status': 'active',
                    },
                    'message': 'OTP envoye au nouveau numero',
                  },
                },
              ),
            );
          },
        ),
      );
      return (dio, () => captured ?? {});
    }

    test('getProfile sends GET /users/me', () async {
      String? method;
      String? path;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            method = options.method;
            path = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'data': {
                    'user': {
                      'id': '00000000-0000-0000-0000-000000000001',
                      'phone': '+2250700000000',
                      'name': 'Koffi',
                      'role': 'client',
                      'status': 'active',
                    },
                  },
                },
              ),
            );
          },
        ),
      );
      final endpoint = UserEndpoint(dio);
      final user = await endpoint.getProfile();
      expect(method, 'GET');
      expect(path, '/users/me');
      expect(user.name, 'Koffi');
    });

    test('updateProfile sends PUT /users/me with name', () async {
      final (dio, getBody) = dioWithCapture();
      final endpoint = UserEndpoint(dio);
      final user = await endpoint.updateProfile(name: 'Koffi Updated');
      expect(getBody()['name'], 'Koffi Updated');
      expect(user.name, 'Koffi Updated');
    });

    test('requestPhoneChange sends POST with new_phone', () async {
      final (dio, getBody) = dioWithCapture();
      final endpoint = UserEndpoint(dio);
      await endpoint.requestPhoneChange('+2250700000001');
      expect(getBody()['new_phone'], '+2250700000001');
    });

    test('verifyPhoneChange sends POST with new_phone and otp', () async {
      final (dio, getBody) = dioWithCapture();
      final endpoint = UserEndpoint(dio);
      final user = await endpoint.verifyPhoneChange('+2250700000001', '123456');
      expect(getBody()['new_phone'], '+2250700000001');
      expect(getBody()['otp'], '123456');
      expect(user.name, 'Koffi Updated');
    });
  });

  group('DeliveryEndpoint', () {
    test('confirmPickup sends POST /deliveries/{id}/confirm-pickup', () async {
      String? method;
      String? path;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            method = options.method;
            path = options.path;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'data': {
                    'delivery_id': 'test-delivery-id',
                    'status': 'picked_up',
                    'picked_up_at': '2026-03-20T12:00:00Z',
                  },
                },
              ),
            );
          },
        ),
      );
      final endpoint = DeliveryEndpoint(dio);
      final result = await endpoint.confirmPickup('test-delivery-id');
      expect(method, 'POST');
      expect(path, '/deliveries/test-delivery-id/confirm-pickup');
      expect(result['status'], 'picked_up');
    });

    test('updateLocation sends POST /deliveries/{id}/location with lat/lng', () async {
      String? method;
      String? path;
      Map<String, dynamic>? body;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            method = options.method;
            path = options.path;
            body = options.data as Map<String, dynamic>?;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'data': {'status': 'location_updated'},
                },
              ),
            );
          },
        ),
      );
      final endpoint = DeliveryEndpoint(dio);
      await endpoint.updateLocation('test-delivery-id', 7.69, -5.03);
      expect(method, 'POST');
      expect(path, '/deliveries/test-delivery-id/location');
      expect(body!['lat'], 7.69);
      expect(body!['lng'], -5.03);
    });

    test('confirmPickup throws on 409 Conflict', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: <String, dynamic>{
                    'error': {
                      'code': 'CONFLICT',
                      'message': 'Not in assigned status',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );
      final endpoint = DeliveryEndpoint(dio);
      expect(
        () => endpoint.confirmPickup('test-id'),
        throwsA(isA<DioException>()),
      );
    });

    test('confirmPickup throws on 403 Forbidden', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  data: <String, dynamic>{
                    'error': {
                      'code': 'FORBIDDEN',
                      'message': 'This delivery is not assigned to you',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );
      final endpoint = DeliveryEndpoint(dio);
      expect(
        () => endpoint.confirmPickup('test-id'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    test('confirmPickup throws on 404 Not Found', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: <String, dynamic>{
                    'error': {
                      'code': 'NOT_FOUND',
                      'message': 'Delivery not found',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );
      final endpoint = DeliveryEndpoint(dio);
      expect(
        () => endpoint.confirmPickup('nonexistent-id'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('updateLocation throws on 409 when delivery not active', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: <String, dynamic>{
                    'error': {
                      'code': 'CONFLICT',
                      'message':
                          'Delivery is not in an active status for location updates',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );
      final endpoint = DeliveryEndpoint(dio);
      expect(
        () => endpoint.updateLocation('test-id', 7.69, -5.03),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });
  });

  group('AuthNotifier.updateUser', () {
    test('updateUser updates user in notifier state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authProvider);
      expect(container.read(authProvider).user, isNull);

      const user = User(
        id: '00000000-0000-0000-0000-000000000001',
        phone: '+2250700000000',
        name: 'Updated',
        role: UserRole.client,
        status: UserStatus.active,
      );

      container.read(authProvider.notifier).updateUser(user);
      expect(container.read(authProvider).user?.name, 'Updated');
      expect(container.read(authProvider).user?.phone, '+2250700000000');
    });
  });

  group('JWT local expiration check', () {
    String createTestJwt({required int expInSeconds}) {
      final header = base64Url.encode(
        utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
      );
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = base64Url.encode(
        utf8.encode(
          jsonEncode({
            'sub': 'test-user-id',
            'role': 'client',
            'iat': now,
            'exp': now + expInSeconds,
          }),
        ),
      );
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

  group('UserProfileNotifier', () {
    const testUser = User(
      id: '00000000-0000-0000-0000-000000000001',
      phone: '+2250700000000',
      name: 'Koffi',
      role: UserRole.client,
      status: UserStatus.active,
    );

    ProviderContainer createTestContainer({Dio? mockDio, User? user}) {
      final container = ProviderContainer(
        overrides: [
          userEndpointProvider.overrideWith(
            (ref) => UserEndpoint(
              mockDio ?? Dio(BaseOptions(baseUrl: 'http://localhost')),
            ),
          ),
        ],
      );
      // Pre-initialize authProvider, then seed user if needed.
      container.read(authProvider);
      if (user != null) container.read(authProvider.notifier).updateUser(user);
      return container;
    }

    Dio mockDioWithUserResponse({String name = 'Koffi Updated'}) {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'data': {
                    'user': {
                      'id': '00000000-0000-0000-0000-000000000001',
                      'phone': '+2250700000000',
                      'name': name,
                      'role': 'client',
                      'status': 'active',
                    },
                  },
                },
              ),
            );
          },
        ),
      );
      return dio;
    }

    test('initial state loads user from authProvider', () {
      final container = createTestContainer(user: testUser);
      final sub = container.listen(userProfileProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final state = container.read(userProfileProvider);
      expect(state.value?.name, 'Koffi');
    });

    test('initial state is loading when no user in authProvider', () {
      final container = createTestContainer();
      final sub = container.listen(userProfileProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final state = container.read(userProfileProvider);
      expect(state.isLoading, isTrue);
    });

    test('updateName calls API and updates state', () async {
      final container = createTestContainer(
        user: testUser,
        mockDio: mockDioWithUserResponse(),
      );
      final sub = container.listen(userProfileProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container
          .read(userProfileProvider.notifier)
          .updateName('Koffi Updated');

      final state = container.read(userProfileProvider);
      expect(state.value?.name, 'Koffi Updated');
    });

    test('updateName syncs with authProvider', () async {
      final container = createTestContainer(
        user: testUser,
        mockDio: mockDioWithUserResponse(),
      );
      final sub = container.listen(userProfileProvider, (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container
          .read(userProfileProvider.notifier)
          .updateName('Koffi Updated');

      final authState = container.read(authProvider);
      expect(authState.user?.name, 'Koffi Updated');
    });
  });

  group('DeliveryEndpoint - getDeliveryTracking', () {
    test('returns DeliveryLocationUpdate on success', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, contains('/deliveries/tracking/'));
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': {
                'lat': 7.69,
                'lng': -5.03,
                'eta_seconds': 120,
                'status': 'picked_up',
                'driver_name': 'Kone',
                'driver_phone': '+2250700000000',
                'updated_at': '2026-03-20T10:00:00Z',
              }
            },
          ));
        },
      ));

      final endpoint = DeliveryEndpoint(dio);
      final result = await endpoint.getDeliveryTracking('order-123');
      expect(result, isNotNull);
      expect(result!.lat, 7.69);
      expect(result.etaSeconds, 120);
      expect(result.driverName, 'Kone');
    });

    test('returns null on 404', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 404,
              data: {'error': {'code': 'NOT_FOUND', 'message': 'Not found'}},
            ),
            type: DioExceptionType.badResponse,
          ));
        },
      ));

      final endpoint = DeliveryEndpoint(dio);
      final result = await endpoint.getDeliveryTracking('order-123');
      expect(result, isNull);
    });
  });
}
