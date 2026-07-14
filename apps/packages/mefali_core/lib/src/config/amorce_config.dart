import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_config.dart';
import 'service_config.dart';
import 'source_config.dart';

/// Construit et démarre le [ServiceConfig] d'une application : client Dart
/// GÉNÉRÉ + cache `shared_preferences`. Point d'entrée unique des apps (elles
/// n'importent que `mefali_core`). À appeler après
/// `WidgetsFlutterBinding.ensureInitialized()`.
///
/// `urlApi` est surchargeable au build (`--dart-define=MEFALI_API_URL=...`).
Future<ServiceConfig> demarrerServiceConfig({String? urlApi}) async {
  final prefs = await SharedPreferences.getInstance();
  final service = ServiceConfig(
    source: SourceConfigApi(MefaliApiClient(basePathOverride: urlApi)),
    cache: CacheConfigPreferences(prefs),
  );
  await service.demarrer();
  return service;
}
