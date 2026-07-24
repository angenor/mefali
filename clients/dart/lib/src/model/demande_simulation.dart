//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/point.dart';
import 'package:mefali_api_client/src/model/attente.dart';
import 'package:mefali_api_client/src/model/offre_livraison_vendeur.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_simulation.g.dart';

/// Course simulée — **pas de coursier** : le devis client précède le dispatch (CMD-01/TRF-03, research R11).
///
/// Properties:
/// * [attentes] - Attentes constatées, `null` = aucune.
/// * [categorieSlug] - Catégorie de service, `null` = aucune contrainte.
/// * [destination] - Destination client.
/// * [instant] - Instant d'évaluation (plages horaires, jours, dates d'effet).
/// * [monoVendeur] - Commande mono-vendeur — condition NÉCESSAIRE de VND-08.
/// * [montantPanier] - Montant du panier (unités mineures) — seuil VND-08.
/// * [nbArticles] - Nombre total d'articles de la commande (paliers d'effort).
/// * [offreLivraisonVendeur] - Offre de livraison du vendeur, `null` = aucune.
/// * [transportSlug] - Véhicule.
/// * [vendeurs] - Points de retrait (1..n), dans un ordre quelconque — le moteur optimise.
@BuiltValue()
abstract class DemandeSimulation implements Built<DemandeSimulation, DemandeSimulationBuilder> {
  /// Attentes constatées, `null` = aucune.
  @BuiltValueField(wireName: r'attentes')
  BuiltList<Attente>? get attentes;

  /// Catégorie de service, `null` = aucune contrainte.
  @BuiltValueField(wireName: r'categorie_slug')
  String? get categorieSlug;

  /// Destination client.
  @BuiltValueField(wireName: r'destination')
  Point get destination;

  /// Instant d'évaluation (plages horaires, jours, dates d'effet).
  @BuiltValueField(wireName: r'instant')
  DateTime get instant;

  /// Commande mono-vendeur — condition NÉCESSAIRE de VND-08.
  @BuiltValueField(wireName: r'mono_vendeur')
  bool get monoVendeur;

  /// Montant du panier (unités mineures) — seuil VND-08.
  @BuiltValueField(wireName: r'montant_panier')
  int? get montantPanier;

  /// Nombre total d'articles de la commande (paliers d'effort).
  @BuiltValueField(wireName: r'nb_articles')
  int get nbArticles;

  /// Offre de livraison du vendeur, `null` = aucune.
  @BuiltValueField(wireName: r'offre_livraison_vendeur')
  OffreLivraisonVendeur? get offreLivraisonVendeur;

  /// Véhicule.
  @BuiltValueField(wireName: r'transport_slug')
  String get transportSlug;

  /// Points de retrait (1..n), dans un ordre quelconque — le moteur optimise.
  @BuiltValueField(wireName: r'vendeurs')
  BuiltList<Point> get vendeurs;

  DemandeSimulation._();

  factory DemandeSimulation([void updates(DemandeSimulationBuilder b)]) = _$DemandeSimulation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeSimulationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeSimulation> get serializer => _$DemandeSimulationSerializer();
}

class _$DemandeSimulationSerializer implements PrimitiveSerializer<DemandeSimulation> {
  @override
  final Iterable<Type> types = const [DemandeSimulation, _$DemandeSimulation];

  @override
  final String wireName = r'DemandeSimulation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeSimulation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.attentes != null) {
      yield r'attentes';
      yield serializers.serialize(
        object.attentes,
        specifiedType: const FullType.nullable(BuiltList, [FullType(Attente)]),
      );
    }
    if (object.categorieSlug != null) {
      yield r'categorie_slug';
      yield serializers.serialize(
        object.categorieSlug,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'destination';
    yield serializers.serialize(
      object.destination,
      specifiedType: const FullType(Point),
    );
    yield r'instant';
    yield serializers.serialize(
      object.instant,
      specifiedType: const FullType(DateTime),
    );
    yield r'mono_vendeur';
    yield serializers.serialize(
      object.monoVendeur,
      specifiedType: const FullType(bool),
    );
    if (object.montantPanier != null) {
      yield r'montant_panier';
      yield serializers.serialize(
        object.montantPanier,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'nb_articles';
    yield serializers.serialize(
      object.nbArticles,
      specifiedType: const FullType(int),
    );
    if (object.offreLivraisonVendeur != null) {
      yield r'offre_livraison_vendeur';
      yield serializers.serialize(
        object.offreLivraisonVendeur,
        specifiedType: const FullType.nullable(OffreLivraisonVendeur),
      );
    }
    yield r'transport_slug';
    yield serializers.serialize(
      object.transportSlug,
      specifiedType: const FullType(String),
    );
    yield r'vendeurs';
    yield serializers.serialize(
      object.vendeurs,
      specifiedType: const FullType(BuiltList, [FullType(Point)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeSimulation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeSimulationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'attentes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(Attente)]),
          ) as BuiltList<Attente>?;
          if (valueDes == null) continue;
          result.attentes.replace(valueDes);
          break;
        case r'categorie_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categorieSlug = valueDes;
          break;
        case r'destination':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Point),
          ) as Point;
          result.destination.replace(valueDes);
          break;
        case r'instant':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.instant = valueDes;
          break;
        case r'mono_vendeur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.monoVendeur = valueDes;
          break;
        case r'montant_panier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.montantPanier = valueDes;
          break;
        case r'nb_articles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbArticles = valueDes;
          break;
        case r'offre_livraison_vendeur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(OffreLivraisonVendeur),
          ) as OffreLivraisonVendeur?;
          if (valueDes == null) continue;
          result.offreLivraisonVendeur.replace(valueDes);
          break;
        case r'transport_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.transportSlug = valueDes;
          break;
        case r'vendeurs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Point)]),
          ) as BuiltList<Point>;
          result.vendeurs.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeSimulation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeSimulationBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

