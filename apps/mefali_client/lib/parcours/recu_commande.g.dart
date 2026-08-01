// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recu_commande.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce
/// qui reste dû (FR-070, FR-073).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

@ProviderFor(recuCommande)
final recuCommandeProvider = RecuCommandeFamily._();

/// Le reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce
/// qui reste dû (FR-070, FR-073).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

final class RecuCommandeProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecuCommande>,
          RecuCommande,
          FutureOr<RecuCommande>
        >
    with $FutureModifier<RecuCommande>, $FutureProvider<RecuCommande> {
  /// Le reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce
  /// qui reste dû (FR-070, FR-073).
  ///
  /// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.
  RecuCommandeProvider._({
    required RecuCommandeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recuCommandeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recuCommandeHash();

  @override
  String toString() {
    return r'recuCommandeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecuCommande> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecuCommande> create(Ref ref) {
    final argument = this.argument as String;
    return recuCommande(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecuCommandeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recuCommandeHash() => r'ff5ab68a458af0041839c9c839a217ae01b59bda';

/// Le reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce
/// qui reste dû (FR-070, FR-073).
///
/// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

final class RecuCommandeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecuCommande>, String> {
  RecuCommandeFamily._()
    : super(
        retry: null,
        name: r'recuCommandeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le reçu d'une commande — ce qui a été commandé, ce qui en est sorti, et ce
  /// qui reste dû (FR-070, FR-073).
  ///
  /// `@riverpod` nu (autoDispose) : lecture d'écran, rien à faire survivre.

  RecuCommandeProvider call(String commandeId) =>
      RecuCommandeProvider._(argument: commandeId, from: this);

  @override
  String toString() => r'recuCommandeProvider';
}
