import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'admin_dashboard_provider.dart';

/// Parametres pour la liste des litiges admin.
class DisputeListParams {
  const DisputeListParams({this.page = 1, this.status, this.type});

  final int page;
  final String? status;
  final String? type;

  @override
  bool operator ==(Object other) =>
      other is DisputeListParams &&
      other.page == page &&
      other.status == status &&
      other.type == type;

  @override
  int get hashCode => Object.hash(page, status, type);
}

/// Provider pour la liste paginee des litiges admin.
final adminDisputesProvider = FutureProvider.autoDispose
    .family<({List<AdminDisputeListItem> items, int total}), DisputeListParams>(
        (ref, params) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.listDisputes(
    page: params.page,
    status: params.status,
    type: params.type,
  );
});

/// Provider pour le detail d'un litige.
final disputeDetailProvider =
    FutureProvider.autoDispose.family<DisputeDetail, String>(
        (ref, disputeId) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.getDisputeDetail(disputeId);
});
