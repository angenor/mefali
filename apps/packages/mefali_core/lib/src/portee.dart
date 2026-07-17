/// Primitives de portée de providers, partagées par les points d'entrée des
/// deux apps ET le harnais de test — jamais un réglage par site (R10/R11).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'portee.g.dart';

/// Politique de retry NEUTRE : aucune tentative, jamais.
///
/// Passée à `retry:` sur TOUTE création de portée — les 2 `main.dart` de
/// production ET le harnais de test. Riverpod 3 réessaie les providers en échec
/// PAR DÉFAUT (`maxRetries = 10`, `DioException` comprise), ce qui ajouterait
/// jusqu'à 10 requêtes en backoff là où AUCUNE n'était rejouée avant ce cycle —
/// FR-002/SC-004 violés sans une ligne écrite, et les tests resteraient verts
/// (aucune assertion ne compte les requêtes). Le `retry: null` du générateur
/// signifie « hérite », PAS « désactivé » : la désactivation est ce corps-ci.
///
/// PUBLIQUE et en PRODUCTION (exportée par le barrel `mefali_core.dart`) : un
/// top-level privé serait privé à sa bibliothèque, donc redéclaré dans chaque
/// `main.dart` = « un réglage par site » que la règle interdit ; la déclarer
/// dans le harnais forcerait les 2 `main.dart` à importer le harnais, ce que le
/// tree-shaking (R11) exclut. Signature = `Duration? Function(int, Object)`
/// attendue par `ProviderContainer(retry:)`.
Duration? pasDeRetry(int retryCount, Object error) => null;

/// L'URL de base de l'API. `throw` par DÉFAUT : le paquet cœur NE lit JAMAIS
/// l'environnement (FR-012) — la `const String _urlApi = String.fromEnvironment(…)`
/// reste dans le point d'entrée de chaque app et n'en bouge pas.
///
/// Un défaut `'http://localhost:8080'` ici ferait POSSÉDER au cœur la valeur
/// d'environnement que FR-012 lui interdit de connaître, et une app qui oublie
/// l'override partirait en silence sur l'appareil lui-même (CLAUDE.md §Commandes).
/// Le `throw` échoue au premier `read`, au lancement, avec le message qui dit
/// quoi faire (R3).
@Riverpod(keepAlive: true)
String urlApi(Ref ref) => throw UnimplementedError(
      'urlApiProvider doit être surchargé dans le point d\'entrée : '
      'ProviderContainer(overrides: [urlApiProvider.overrideWithValue(_urlApi)]).');
