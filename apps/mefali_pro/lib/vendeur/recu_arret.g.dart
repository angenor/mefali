// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recu_arret.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le reçu d'un arrêt **collecté** — les trois montants qui font le versement
/// du coursier au vendeur (FR-071).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

@ProviderFor(recuArret)
final recuArretProvider = RecuArretFamily._();

/// Le reçu d'un arrêt **collecté** — les trois montants qui font le versement
/// du coursier au vendeur (FR-071).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

final class RecuArretProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecuArret>,
          RecuArret,
          FutureOr<RecuArret>
        >
    with $FutureModifier<RecuArret>, $FutureProvider<RecuArret> {
  /// Le reçu d'un arrêt **collecté** — les trois montants qui font le versement
  /// du coursier au vendeur (FR-071).
  ///
  /// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.
  RecuArretProvider._({
    required RecuArretFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recuArretProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recuArretHash();

  @override
  String toString() {
    return r'recuArretProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecuArret> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RecuArret> create(Ref ref) {
    final argument = this.argument as String;
    return recuArret(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecuArretProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recuArretHash() => r'f5079a5f58815664fb492c0e5624b9dc68dd4641';

/// Le reçu d'un arrêt **collecté** — les trois montants qui font le versement
/// du coursier au vendeur (FR-071).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

final class RecuArretFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecuArret>, String> {
  RecuArretFamily._()
    : super(
        retry: null,
        name: r'recuArretProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le reçu d'un arrêt **collecté** — les trois montants qui font le versement
  /// du coursier au vendeur (FR-071).
  ///
  /// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

  RecuArretProvider call(String arretId) =>
      RecuArretProvider._(argument: arretId, from: this);

  @override
  String toString() => r'recuArretProvider';
}
