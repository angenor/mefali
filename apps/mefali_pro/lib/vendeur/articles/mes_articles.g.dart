// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mes_articles.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
/// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
/// `MesAdresses` du cycle 003.

@ProviderFor(MesArticles)
final mesArticlesProvider = MesArticlesFamily._();

/// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
/// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
/// `MesAdresses` du cycle 003.
final class MesArticlesProvider
    extends $AsyncNotifierProvider<MesArticles, List<ArticleVendeur>> {
  /// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
  /// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
  /// `MesAdresses` du cycle 003.
  MesArticlesProvider._({
    required MesArticlesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mesArticlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mesArticlesHash();

  @override
  String toString() {
    return r'mesArticlesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MesArticles create() => MesArticles();

  @override
  bool operator ==(Object other) {
    return other is MesArticlesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mesArticlesHash() => r'5c7dd14e29ce088ec2e689d27b9148839d37ed3a';

/// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
/// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
/// `MesAdresses` du cycle 003.

final class MesArticlesFamily extends $Family
    with
        $ClassFamilyOverride<
          MesArticles,
          AsyncValue<List<ArticleVendeur>>,
          List<ArticleVendeur>,
          FutureOr<List<ArticleVendeur>>,
          String
        > {
  MesArticlesFamily._()
    : super(
        retry: null,
        name: r'mesArticlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
  /// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
  /// `MesAdresses` du cycle 003.

  MesArticlesProvider call(String prestataireId) =>
      MesArticlesProvider._(argument: prestataireId, from: this);

  @override
  String toString() => r'mesArticlesProvider';
}

/// Le catalogue du prestataire piloté (écran V2 — FR-045). Famille par
/// prestataire, `@riverpod` nu (autoDispose) : liste d'écran, patron
/// `MesAdresses` du cycle 003.

abstract class _$MesArticles extends $AsyncNotifier<List<ArticleVendeur>> {
  late final _$args = ref.$arg as String;
  String get prestataireId => _$args;

  FutureOr<List<ArticleVendeur>> build(String prestataireId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ArticleVendeur>>, List<ArticleVendeur>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ArticleVendeur>>,
                List<ArticleVendeur>
              >,
              AsyncValue<List<ArticleVendeur>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
