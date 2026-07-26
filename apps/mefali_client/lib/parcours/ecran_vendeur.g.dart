// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ecran_vendeur.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La fiche publique d'un vendeur. `@riverpod` nu (autoDispose) : écran de
/// consultation, rien à faire survivre à sa fermeture.

@ProviderFor(ficheVendeur)
final ficheVendeurProvider = FicheVendeurFamily._();

/// La fiche publique d'un vendeur. `@riverpod` nu (autoDispose) : écran de
/// consultation, rien à faire survivre à sa fermeture.

final class FicheVendeurProvider
    extends
        $FunctionalProvider<
          AsyncValue<FichePublique>,
          FichePublique,
          FutureOr<FichePublique>
        >
    with $FutureModifier<FichePublique>, $FutureProvider<FichePublique> {
  /// La fiche publique d'un vendeur. `@riverpod` nu (autoDispose) : écran de
  /// consultation, rien à faire survivre à sa fermeture.
  FicheVendeurProvider._({
    required FicheVendeurFamily super.from,
    required String super.argument,
  }) : super(
         retry: pasDeRetry,
         name: r'ficheVendeurProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ficheVendeurHash();

  @override
  String toString() {
    return r'ficheVendeurProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FichePublique> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FichePublique> create(Ref ref) {
    final argument = this.argument as String;
    return ficheVendeur(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FicheVendeurProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ficheVendeurHash() => r'c4a9fa732e6cdc188b33eb254d60e654372e6cef';

/// La fiche publique d'un vendeur. `@riverpod` nu (autoDispose) : écran de
/// consultation, rien à faire survivre à sa fermeture.

final class FicheVendeurFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FichePublique>, String> {
  FicheVendeurFamily._()
    : super(
        retry: pasDeRetry,
        name: r'ficheVendeurProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// La fiche publique d'un vendeur. `@riverpod` nu (autoDispose) : écran de
  /// consultation, rien à faire survivre à sa fermeture.

  FicheVendeurProvider call(String prestataireId) =>
      FicheVendeurProvider._(argument: prestataireId, from: this);

  @override
  String toString() => r'ficheVendeurProvider';
}
