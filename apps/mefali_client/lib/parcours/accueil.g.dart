// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accueil.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les commandes du compte. `@riverpod` nu (autoDispose) : liste d'accueil,
/// rechargée à chaque venue — une commande avance pendant qu'on ne la regarde
/// pas. `retry: pasDeRetry` : hors ligne, `ActionsCommande` rend déjà celles du
/// cache ; réessayer en boucle ne ferait que vider la batterie.

@ProviderFor(mesCommandes)
final mesCommandesProvider = MesCommandesProvider._();

/// Les commandes du compte. `@riverpod` nu (autoDispose) : liste d'accueil,
/// rechargée à chaque venue — une commande avance pendant qu'on ne la regarde
/// pas. `retry: pasDeRetry` : hors ligne, `ActionsCommande` rend déjà celles du
/// cache ; réessayer en boucle ne ferait que vider la batterie.

final class MesCommandesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CommandeResumeeVue>>,
          List<CommandeResumeeVue>,
          FutureOr<List<CommandeResumeeVue>>
        >
    with
        $FutureModifier<List<CommandeResumeeVue>>,
        $FutureProvider<List<CommandeResumeeVue>> {
  /// Les commandes du compte. `@riverpod` nu (autoDispose) : liste d'accueil,
  /// rechargée à chaque venue — une commande avance pendant qu'on ne la regarde
  /// pas. `retry: pasDeRetry` : hors ligne, `ActionsCommande` rend déjà celles du
  /// cache ; réessayer en boucle ne ferait que vider la batterie.
  MesCommandesProvider._()
    : super(
        from: null,
        argument: null,
        retry: pasDeRetry,
        name: r'mesCommandesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mesCommandesHash();

  @$internal
  @override
  $FutureProviderElement<List<CommandeResumeeVue>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CommandeResumeeVue>> create(Ref ref) {
    return mesCommandes(ref);
  }
}

String _$mesCommandesHash() => r'ea4c5bfac23a605c6d4e41dc47d37cc53bcef82c';
