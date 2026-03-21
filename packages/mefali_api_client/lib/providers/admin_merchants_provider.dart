import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'admin_dashboard_provider.dart';

/// Parametres pour la liste des marchands admin.
class MerchantListParams {
  const MerchantListParams({
    this.page = 1,
    this.status,
    this.cityId,
    this.search,
  });

  final int page;
  final String? status;
  final String? cityId;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is MerchantListParams &&
      other.page == page &&
      other.status == status &&
      other.cityId == cityId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(page, status, cityId, search);
}

/// Provider pour la liste paginee des marchands admin.
final adminMerchantsProvider = FutureProvider.autoDispose
    .family<({List<AdminMerchantListItem> items, int total}), MerchantListParams>(
        (ref, params) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.listMerchants(
    page: params.page,
    status: params.status,
    cityId: params.cityId,
    search: params.search,
  );
});

/// Provider pour l'historique d'un marchand.
class MerchantHistoryParams {
  const MerchantHistoryParams({required this.merchantId, this.page = 1});

  final String merchantId;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is MerchantHistoryParams &&
      other.merchantId == merchantId &&
      other.page == page;

  @override
  int get hashCode => Object.hash(merchantId, page);
}

final merchantHistoryProvider = FutureProvider.autoDispose
    .family<MerchantHistory, MerchantHistoryParams>((ref, params) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.getMerchantHistory(params.merchantId, page: params.page);
});
