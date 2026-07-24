//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'drapeaux_zone.g.dart';

/// Drapeaux de zone appliqués.
///
/// Properties:
/// * [gratuiteCommissions] - Marge forcée à 0.
/// * [livraisonOfferteMefali] - Prix client forcé à 0 (promo Mefali).
/// * [pluie] - Supplément de pluie actif.
@BuiltValue()
abstract class DrapeauxZone implements Built<DrapeauxZone, DrapeauxZoneBuilder> {
  /// Marge forcée à 0.
  @BuiltValueField(wireName: r'gratuite_commissions')
  bool get gratuiteCommissions;

  /// Prix client forcé à 0 (promo Mefali).
  @BuiltValueField(wireName: r'livraison_offerte_mefali')
  bool get livraisonOfferteMefali;

  /// Supplément de pluie actif.
  @BuiltValueField(wireName: r'pluie')
  bool get pluie;

  DrapeauxZone._();

  factory DrapeauxZone([void updates(DrapeauxZoneBuilder b)]) = _$DrapeauxZone;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DrapeauxZoneBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DrapeauxZone> get serializer => _$DrapeauxZoneSerializer();
}

class _$DrapeauxZoneSerializer implements PrimitiveSerializer<DrapeauxZone> {
  @override
  final Iterable<Type> types = const [DrapeauxZone, _$DrapeauxZone];

  @override
  final String wireName = r'DrapeauxZone';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DrapeauxZone object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'gratuite_commissions';
    yield serializers.serialize(
      object.gratuiteCommissions,
      specifiedType: const FullType(bool),
    );
    yield r'livraison_offerte_mefali';
    yield serializers.serialize(
      object.livraisonOfferteMefali,
      specifiedType: const FullType(bool),
    );
    yield r'pluie';
    yield serializers.serialize(
      object.pluie,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DrapeauxZone object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DrapeauxZoneBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'gratuite_commissions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.gratuiteCommissions = valueDes;
          break;
        case r'livraison_offerte_mefali':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.livraisonOfferteMefali = valueDes;
          break;
        case r'pluie':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.pluie = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DrapeauxZone deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DrapeauxZoneBuilder();
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

