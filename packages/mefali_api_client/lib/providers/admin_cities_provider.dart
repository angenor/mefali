import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

import 'admin_dashboard_provider.dart';

/// Provider pour la liste des villes configurees.
final adminCitiesProvider =
    FutureProvider.autoDispose<List<CityConfig>>((ref) async {
  final endpoint = ref.watch(adminEndpointProvider);
  return endpoint.listCities();
});
