import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'admin_dashboard_provider.dart';

/// Parametres pour la liste des utilisateurs admin.
class AdminUserListParams {
  const AdminUserListParams({
    this.page = 1,
    this.role,
    this.status,
    this.search,
  });

  final int page;
  final String? role;
  final String? status;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is AdminUserListParams &&
      other.page == page &&
      other.role == role &&
      other.status == status &&
      other.search == search;

  @override
  int get hashCode => Object.hash(page, role, status, search);
}

/// Provider pour la liste paginee des utilisateurs admin.
final adminUsersProvider = FutureProvider.autoDispose
    .family<({List<AdminUserListItem> items, int total}), AdminUserListParams>(
        (ref, params) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.listUsers(
    page: params.page,
    role: params.role,
    status: params.status,
    search: params.search,
  );
});

/// Provider pour le detail d'un utilisateur.
final adminUserDetailProvider =
    FutureProvider.autoDispose.family<AdminUserDetail, String>(
        (ref, userId) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.getUserDetail(userId);
});
