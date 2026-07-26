//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/composantes_devis.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'devis_livraison.g.dart';

/// Devis de livraison figé (cycle 007).
///
/// Properties:
/// * [composantes] - Détail des composantes.
/// * [degraded] - Vrai si la distance vient du repli vol d'oiseau (constitution IV).
/// * [devise] - Devise ISO 4217.
/// * [distanceM] - Distance routière totale (m).
/// * [etaS] - Durée estimée (s).
/// * [margeUnites] - Marge Mefali.
/// * [ordreArrets] - Ordre de passage retenu pour les retraits.
/// * [partCoursierUnites] - Part reversée au coursier.
/// * [prixClientUnites] - Prix payé par le client (unités mineures).
@BuiltValue()
abstract class DevisLivraison implements Built<DevisLivraison, DevisLivraisonBuilder> {
  /// Détail des composantes.
  @BuiltValueField(wireName: r'composantes')
  ComposantesDevis get composantes;

  /// Vrai si la distance vient du repli vol d'oiseau (constitution IV).
  @BuiltValueField(wireName: r'degraded')
  bool get degraded;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Distance routière totale (m).
  @BuiltValueField(wireName: r'distance_m')
  int get distanceM;

  /// Durée estimée (s).
  @BuiltValueField(wireName: r'eta_s')
  int get etaS;

  /// Marge Mefali.
  @BuiltValueField(wireName: r'marge_unites')
  int get margeUnites;

  /// Ordre de passage retenu pour les retraits.
  @BuiltValueField(wireName: r'ordre_arrets')
  BuiltList<int> get ordreArrets;

  /// Part reversée au coursier.
  @BuiltValueField(wireName: r'part_coursier_unites')
  int get partCoursierUnites;

  /// Prix payé par le client (unités mineures).
  @BuiltValueField(wireName: r'prix_client_unites')
  int get prixClientUnites;

  DevisLivraison._();

  factory DevisLivraison([void updates(DevisLivraisonBuilder b)]) = _$DevisLivraison;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DevisLivraisonBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DevisLivraison> get serializer => _$DevisLivraisonSerializer();
}

class _$DevisLivraisonSerializer implements PrimitiveSerializer<DevisLivraison> {
  @override
  final Iterable<Type> types = const [DevisLivraison, _$DevisLivraison];

  @override
  final String wireName = r'DevisLivraison';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DevisLivraison object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'composantes';
    yield serializers.serialize(
      object.composantes,
      specifiedType: const FullType(ComposantesDevis),
    );
    yield r'degraded';
    yield serializers.serialize(
      object.degraded,
      specifiedType: const FullType(bool),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'distance_m';
    yield serializers.serialize(
      object.distanceM,
      specifiedType: const FullType(int),
    );
    yield r'eta_s';
    yield serializers.serialize(
      object.etaS,
      specifiedType: const FullType(int),
    );
    yield r'marge_unites';
    yield serializers.serialize(
      object.margeUnites,
      specifiedType: const FullType(int),
    );
    yield r'ordre_arrets';
    yield serializers.serialize(
      object.ordreArrets,
      specifiedType: const FullType(BuiltList, [FullType(int)]),
    );
    yield r'part_coursier_unites';
    yield serializers.serialize(
      object.partCoursierUnites,
      specifiedType: const FullType(int),
    );
    yield r'prix_client_unites';
    yield serializers.serialize(
      object.prixClientUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DevisLivraison object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DevisLivraisonBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'composantes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ComposantesDevis),
          ) as ComposantesDevis;
          result.composantes.replace(valueDes);
          break;
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'distance_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.distanceM = valueDes;
          break;
        case r'eta_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.etaS = valueDes;
          break;
        case r'marge_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.margeUnites = valueDes;
          break;
        case r'ordre_arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(int)]),
          ) as BuiltList<int>;
          result.ordreArrets.replace(valueDes);
          break;
        case r'part_coursier_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.partCoursierUnites = valueDes;
          break;
        case r'prix_client_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixClientUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DevisLivraison deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DevisLivraisonBuilder();
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

