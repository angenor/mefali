// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portee.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// L'URL de base de l'API. `throw` par DÉFAUT : le paquet cœur NE lit JAMAIS
/// l'environnement (FR-012) — la `const String _urlApi = String.fromEnvironment(…)`
/// reste dans le point d'entrée de chaque app et n'en bouge pas.
///
/// Un défaut `'http://localhost:8080'` ici ferait POSSÉDER au cœur la valeur
/// d'environnement que FR-012 lui interdit de connaître, et une app qui oublie
/// l'override partirait en silence sur l'appareil lui-même (CLAUDE.md §Commandes).
/// Le `throw` échoue au premier `read`, au lancement, avec le message qui dit
/// quoi faire (R3).

@ProviderFor(urlApi)
final urlApiProvider = UrlApiProvider._();

/// L'URL de base de l'API. `throw` par DÉFAUT : le paquet cœur NE lit JAMAIS
/// l'environnement (FR-012) — la `const String _urlApi = String.fromEnvironment(…)`
/// reste dans le point d'entrée de chaque app et n'en bouge pas.
///
/// Un défaut `'http://localhost:8080'` ici ferait POSSÉDER au cœur la valeur
/// d'environnement que FR-012 lui interdit de connaître, et une app qui oublie
/// l'override partirait en silence sur l'appareil lui-même (CLAUDE.md §Commandes).
/// Le `throw` échoue au premier `read`, au lancement, avec le message qui dit
/// quoi faire (R3).

final class UrlApiProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// L'URL de base de l'API. `throw` par DÉFAUT : le paquet cœur NE lit JAMAIS
  /// l'environnement (FR-012) — la `const String _urlApi = String.fromEnvironment(…)`
  /// reste dans le point d'entrée de chaque app et n'en bouge pas.
  ///
  /// Un défaut `'http://localhost:8080'` ici ferait POSSÉDER au cœur la valeur
  /// d'environnement que FR-012 lui interdit de connaître, et une app qui oublie
  /// l'override partirait en silence sur l'appareil lui-même (CLAUDE.md §Commandes).
  /// Le `throw` échoue au premier `read`, au lancement, avec le message qui dit
  /// quoi faire (R3).
  UrlApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlApiHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return urlApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$urlApiHash() => r'b73ea45a65d4f69ff6834fce76feb37da286e150';
