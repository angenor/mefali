import 'package:dio/dio.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';


part 'etat_vehicules.g.dart';

/// Ce que l'écran de déclaration doit connaître.
class EtatMesVehicules {
  /// Crée l'état.
  const EtatMesVehicules({
    this.actifsZone = const <String>[],
    this.declares = const <String>{},
    this.declaresInactifs = const <String>{},
    this.sansDossier = false,
  });

  /// Types de transport que la zone accepte (config, FR-021).
  final List<String> actifsZone;

  /// Ce que le coursier a déclaré, et que la zone accepte encore.
  final Set<String> declares;

  /// Déclarés mais désactivés en zone depuis : montrés, jamais renvoyés.
  ///
  /// Les renvoyer ferait refuser TOUT l'enregistrement (`vehicule_hors_zone`),
  /// y compris le changement que le coursier vient de faire.
  final Set<String> declaresInactifs;

  /// Aucun dossier coursier — l'écran le dit plutôt que d'afficher un vide.
  final bool sansDossier;
}

/// Les transports ACTIFS de la zone — injectés par la PORTÉE (constitution XII).
///
/// Le défaut lit le service de config. L'injecter permet à un test de servir
/// une liste figée sans armer le minuteur horaire du service, qui laisserait un
/// `Timer` pendant à la destruction de l'arbre (piège du cycle 010).
///
/// Surchargée sur le conteneur RACINE, pas par `ProviderScope` : l'écran est
/// poussé par `Navigator`, donc monté au-dessus de tout scope local. Une portée
/// déclarée (`dependencies: []`) n'y changerait rien, et propagerait
/// `@Dependencies` à chaque appelant jusqu'aux tests.
@Riverpod(keepAlive: true)
Future<List<String>> Function() sourceTransportsActifs(Ref ref) => () async {
      final service = await ref.read(serviceConfigProvider);
      return service.courante?.transportsActifs ?? const <String>[];
    };

/// Le geste « je change mes véhicules » (CPT-04).
///
/// Nommé `DeclarationVehicules` et non `MesVehicules` : ce dernier est le nom du
/// modèle GÉNÉRÉ du corps de requête, et deux `MesVehicules` dans le même
/// fichier ne se distingueraient que par leur import.
///
/// `@riverpod` NU (autoDispose, constitution XII) : l'écran est éphémère, et
/// l'état n'a aucune raison de lui survivre. La valeur qui DOIT survivre — les
/// capacités que K1 affiche — vit sur `disponibiliteProvider`, qui est rechargé
/// après un enregistrement réussi.
/// Porteur NU (autoDispose) : aucune portée déclarée. `sourceTransportsActifs`
/// est surchargée sur le conteneur RACINE, jamais dans un `ProviderScope`
/// imbriqué — l'écran étant poussé par `Navigator`, il est monté au-dessus de
/// tout scope local, et une portée déclarée n'y changerait rien tout en
/// propageant `@Dependencies` à chaque appelant.
@riverpod
class DeclarationVehicules extends _$DeclarationVehicules {
  /// Clé d'idempotence de l'ÉCRAN, pas du tap : deux appuis sur « Enregistrer »
  /// portent la même clé, donc un seul enregistrement (patron du formulaire de
  /// dossier).
  final String _cle = const Uuid().v7();

  @override
  Future<EtatMesVehicules> build() async {
    final actifs = await ref.read(sourceTransportsActifsProvider)();

    try {
      final reponse =
          await ref.read(clientSessionProvider).getMoiApi().monDossierCoursier();
      final vehicules = reponse.data?.vehicules.toList() ?? const [];
      return EtatMesVehicules(
        actifsZone: actifs,
        declares: {
          for (final v in vehicules)
            if (v.actifZone) v.slug,
        },
        declaresInactifs: {
          for (final v in vehicules)
            if (!v.actifZone) v.slug,
        },
      );
    } on DioException catch (e) {
      // 404 : le rôle existe, le dossier non. Ce n'est pas une panne — c'est un
      // état que l'écran doit savoir DIRE, sans quoi il proposerait un
      // enregistrement voué à échouer.
      if (e.response?.statusCode == 404) {
        return EtatMesVehicules(actifsZone: actifs, sansDossier: true);
      }
      rethrow;
    }
  }

  /// Envoie la flotte choisie. Rend `null` au succès, sinon la CLÉ d'un refus —
  /// l'appelant décide où l'afficher (patron des gestes du cycle 010).
  Future<String?> enregistrer(Set<String> slugs) async {
    try {
      await ref.read(clientSessionProvider).getMoiApi().remplacerMesVehicules(
            idempotencyKey: _cle,
            mesVehicules: MesVehicules(
              (b) => b..vehicules.replace(slugs.toList()),
            ),
          );
    } on DioException catch (e) {
      return switch (e.response?.statusCode) {
        403 || 409 => 'role_requis',
        404 => 'sans_dossier',
        422 => 'refuse',
        _ => 'erreur_interne',
      };
    }
    return null;
  }
}
