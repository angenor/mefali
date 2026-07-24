//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'itineraire_simule.g.dart';

/// Itinéraire retenu par la simulation.
///
/// Properties:
/// * [degraded] - Vrai si la distance vient du repli vol d'oiseau × facteur de zone.
/// * [distanceM] - Distance routière totale (mètres).
/// * [etaS] - Durée estimée (secondes).
/// * [exhaustif] - Vrai si l'ordre est le meilleur de TOUTES les permutations (≤ 4 arrêts) ; faux si l'heuristique bornée a tranché (FR-031).
/// * [ordre] - Indices des vendeurs dans l'ordre de passage.
@BuiltValue()
abstract class ItineraireSimule implements Built<ItineraireSimule, ItineraireSimuleBuilder> {
  /// Vrai si la distance vient du repli vol d'oiseau × facteur de zone.
  @BuiltValueField(wireName: r'degraded')
  bool get degraded;

  /// Distance routière totale (mètres).
  @BuiltValueField(wireName: r'distance_m')
  int get distanceM;

  /// Durée estimée (secondes).
  @BuiltValueField(wireName: r'eta_s')
  int get etaS;

  /// Vrai si l'ordre est le meilleur de TOUTES les permutations (≤ 4 arrêts) ; faux si l'heuristique bornée a tranché (FR-031).
  @BuiltValueField(wireName: r'exhaustif')
  bool get exhaustif;

  /// Indices des vendeurs dans l'ordre de passage.
  @BuiltValueField(wireName: r'ordre')
  BuiltList<int> get ordre;

  ItineraireSimule._();

  factory ItineraireSimule([void updates(ItineraireSimuleBuilder b)]) = _$ItineraireSimule;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ItineraireSimuleBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ItineraireSimule> get serializer => _$ItineraireSimuleSerializer();
}

class _$ItineraireSimuleSerializer implements PrimitiveSerializer<ItineraireSimule> {
  @override
  final Iterable<Type> types = const [ItineraireSimule, _$ItineraireSimule];

  @override
  final String wireName = r'ItineraireSimule';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ItineraireSimule object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'degraded';
    yield serializers.serialize(
      object.degraded,
      specifiedType: const FullType(bool),
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
    yield r'exhaustif';
    yield serializers.serialize(
      object.exhaustif,
      specifiedType: const FullType(bool),
    );
    yield r'ordre';
    yield serializers.serialize(
      object.ordre,
      specifiedType: const FullType(BuiltList, [FullType(int)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ItineraireSimule object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ItineraireSimuleBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
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
        case r'exhaustif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.exhaustif = valueDes;
          break;
        case r'ordre':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(int)]),
          ) as BuiltList<int>;
          result.ordre.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ItineraireSimule deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ItineraireSimuleBuilder();
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

