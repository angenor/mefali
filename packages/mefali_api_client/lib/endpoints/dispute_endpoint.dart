import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints de signalement de litiges.
class DisputeEndpoint {
  const DisputeEndpoint(this._dio);

  final Dio _dio;

  /// Signale un litige pour une commande livree.
  Future<Dispute> createDispute(
    String orderId,
    CreateDisputeRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/dispute',
      data: request.toJson(),
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Invalid response: missing data field');
    }
    return Dispute.fromJson(data);
  }

  /// Recupere le litige associe a une commande (null si aucun).
  Future<Dispute?> getOrderDispute(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId/dispute',
    );

    final data = response.data?['data'];
    if (data == null) return null;
    return Dispute.fromJson(data as Map<String, dynamic>);
  }

  /// Liste les litiges du client connecte (pagines).
  Future<List<Dispute>> listMyDisputes({int page = 1, int perPage = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/disputes/me',
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final data = response.data?['data'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => Dispute.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
