import 'package:mefali_api_client/mefali_api_client.dart';

import 'session_auth.dart';
import 'stockage_jetons.dart';

/// Construit la [SessionAuth] d'une application : client Dart GÉNÉRÉ + stockage
/// CHIFFRÉ du système. Point d'entrée unique des apps, comme
/// `demarrerServiceConfig` — elles n'importent que `mefali_core`.
///
/// `urlApi` est surchargeable au build (`--dart-define=MEFALI_API_URL=...`).
///
/// La relecture du stockage n'est PAS faite ici : `RacineAuth` s'en charge en
/// affichant l'écran de démarrage, plutôt que de retarder `runApp`.
SessionAuth construireSessionAuth({String? urlApi}) => SessionAuth(
      stockage: const StockageJetonsSecurise(),
      client: MefaliApiClient(basePathOverride: urlApi),
    );
