import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cree une instance Dio configuree pour l'API mefali.
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8090/api/v1',
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  return dio;
}

/// Provider Riverpod pour l'instance Dio singleton.
final dioProvider = Provider<Dio>((ref) => createDio());
