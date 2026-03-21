import 'package:dio/dio.dart';
import 'package:mefali_core/mefali_core.dart';

/// Client pour les endpoints admin.
class AdminEndpoint {
  const AdminEndpoint(this._dio);

  final Dio _dio;

  /// Recupere les KPIs operationnels du dashboard admin.
  Future<DashboardStats> getDashboardStats() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/dashboard/stats',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return DashboardStats.fromJson(data);
  }

  /// Liste les litiges avec filtres optionnels et pagination.
  Future<({List<AdminDisputeListItem> items, int total})> listDisputes({
    int page = 1,
    int perPage = 20,
    String? status,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null) queryParams['status'] = status;
    if (type != null) queryParams['type'] = type;

    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/disputes',
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as List<dynamic>;
    final meta = response.data!['meta'] as Map<String, dynamic>;
    final items = data
        .map((e) => AdminDisputeListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (meta['total'] as num).toInt();

    return (items: items, total: total);
  }

  /// Recupere le detail complet d'un litige.
  Future<DisputeDetail> getDisputeDetail(String disputeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/disputes/$disputeId',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return DisputeDetail.fromJson(data);
  }

  /// Resout un litige avec une action.
  Future<Dispute> resolveDispute(
    String disputeId,
    ResolveDisputeRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/disputes/$disputeId/resolve',
      data: request.toJson(),
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return Dispute.fromJson(data);
  }

  // ── City Config ──────────────────────────────────────────────────

  /// Liste toutes les configurations de villes.
  Future<List<CityConfig>> listCities() async {
    final response = await _dio.get<Map<String, dynamic>>('/admin/cities');
    final data = response.data!['data'] as List<dynamic>;
    return data
        .map((e) => CityConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cree une nouvelle configuration de ville.
  Future<CityConfig> createCity({
    required String cityName,
    double? deliveryMultiplier,
    Map<String, dynamic>? zonesGeojson,
    bool? isActive,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/cities',
      data: {
        'city_name': cityName,
        'delivery_multiplier': ?deliveryMultiplier,
        'zones_geojson': ?zonesGeojson,
        'is_active': ?isActive,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CityConfig.fromJson(data);
  }

  /// Met a jour une configuration de ville existante.
  ///
  /// [zonesGeojson] is always sent so the backend can distinguish
  /// "not provided" (key absent) from "clear zones" (key = null).
  Future<CityConfig> updateCity(
    String cityId, {
    String? cityName,
    double? deliveryMultiplier,
    required Map<String, dynamic>? zonesGeojson,
    bool? isActive,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/admin/cities/$cityId',
      data: {
        'city_name': ?cityName,
        'delivery_multiplier': ?deliveryMultiplier,
        'zones_geojson': zonesGeojson,
        'is_active': ?isActive,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CityConfig.fromJson(data);
  }

  /// Active/desactive une ville.
  Future<CityConfig> toggleCityActive(String cityId, bool isActive) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/cities/$cityId/active',
      data: {'is_active': isActive},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CityConfig.fromJson(data);
  }

  // ── Account Management ─────────────────────────────────────────

  /// Liste les utilisateurs avec filtres et pagination.
  Future<({List<AdminUserListItem> items, int total})> listUsers({
    int page = 1,
    int perPage = 20,
    String? role,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (role != null) queryParams['role'] = role;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as List<dynamic>;
    final meta = response.data!['meta'] as Map<String, dynamic>;
    final items = data
        .map((e) => AdminUserListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (meta['total'] as num).toInt();

    return (items: items, total: total);
  }

  /// Recupere le detail complet d'un utilisateur.
  Future<AdminUserDetail> getUserDetail(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/users/$userId',
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return AdminUserDetail.fromJson(data);
  }

  /// Met a jour le statut d'un utilisateur.
  Future<User> updateUserStatus(
    String userId, {
    required String newStatus,
    String? reason,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/users/$userId/status',
      data: {
        'new_status': newStatus,
        'reason': ?reason,
      },
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return User.fromJson(data);
  }

  // ── Merchant History ──────────────────────────────────────────────

  /// Liste les marchands avec filtres et pagination.
  Future<({List<AdminMerchantListItem> items, int total})> listMerchants({
    int page = 1,
    int perPage = 20,
    String? status,
    String? cityId,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null) queryParams['status'] = status;
    if (cityId != null) queryParams['city_id'] = cityId;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/merchants',
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as List<dynamic>;
    final meta = response.data!['meta'] as Map<String, dynamic>;
    final items = data
        .map((e) => AdminMerchantListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (meta['total'] as num).toInt();

    return (items: items, total: total);
  }

  /// Recupere l'historique complet d'un marchand.
  Future<MerchantHistory> getMerchantHistory(
    String merchantId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/merchants/$merchantId/history',
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return MerchantHistory.fromJson(data);
  }

  // ── Driver History ────────────────────────────────────────────────

  /// Liste les livreurs avec filtres et pagination.
  Future<({List<AdminDriverListItem> items, int total})> listDrivers({
    int page = 1,
    int perPage = 20,
    String? status,
    String? cityId,
    String? search,
    bool? available,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null) queryParams['status'] = status;
    if (cityId != null) queryParams['city_id'] = cityId;
    if (search != null) queryParams['search'] = search;
    if (available != null) queryParams['available'] = available;

    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/drivers',
      queryParameters: queryParams,
    );

    final data = response.data!['data'] as List<dynamic>;
    final meta = response.data!['meta'] as Map<String, dynamic>;
    final items = data
        .map((e) => AdminDriverListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (meta['total'] as num).toInt();

    return (items: items, total: total);
  }

  /// Recupere l'historique complet d'un livreur.
  Future<DriverHistory> getDriverHistory(
    String driverId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/drivers/$driverId/history',
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    return DriverHistory.fromJson(data);
  }
}
