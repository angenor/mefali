import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'admin_dashboard_provider.dart';

/// Parametres pour la liste des livreurs admin.
class DriverListParams {
  const DriverListParams({
    this.page = 1,
    this.status,
    this.cityId,
    this.search,
    this.available,
  });

  final int page;
  final String? status;
  final String? cityId;
  final String? search;
  final bool? available;

  @override
  bool operator ==(Object other) =>
      other is DriverListParams &&
      other.page == page &&
      other.status == status &&
      other.cityId == cityId &&
      other.search == search &&
      other.available == available;

  @override
  int get hashCode => Object.hash(page, status, cityId, search, available);
}

/// Provider pour la liste paginee des livreurs admin.
final adminDriversProvider = FutureProvider.autoDispose
    .family<({List<AdminDriverListItem> items, int total}), DriverListParams>(
        (ref, params) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.listDrivers(
    page: params.page,
    status: params.status,
    cityId: params.cityId,
    search: params.search,
    available: params.available,
  );
});

/// Provider pour l'historique d'un livreur.
class DriverHistoryParams {
  const DriverHistoryParams({required this.driverId, this.page = 1});

  final String driverId;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is DriverHistoryParams &&
      other.driverId == driverId &&
      other.page == page;

  @override
  int get hashCode => Object.hash(driverId, page);
}

final driverHistoryProvider = FutureProvider.autoDispose
    .family<DriverHistory, DriverHistoryParams>((ref, params) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.getDriverHistory(params.driverId, page: params.page);
});
