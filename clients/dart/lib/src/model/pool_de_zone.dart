//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/coursier_du_pool.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pool_de_zone.g.dart';

/// Le pool d'une zone.
///
/// Properties:
/// * [coursiers] - Coursiers présents dans le pool.
/// * [zoneId] - Zone interrogée.
@BuiltValue()
abstract class PoolDeZone implements Built<PoolDeZone, PoolDeZoneBuilder> {
  /// Coursiers présents dans le pool.
  @BuiltValueField(wireName: r'coursiers')
  BuiltList<CoursierDuPool> get coursiers;

  /// Zone interrogée.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  PoolDeZone._();

  factory PoolDeZone([void updates(PoolDeZoneBuilder b)]) = _$PoolDeZone;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PoolDeZoneBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PoolDeZone> get serializer => _$PoolDeZoneSerializer();
}

class _$PoolDeZoneSerializer implements PrimitiveSerializer<PoolDeZone> {
  @override
  final Iterable<Type> types = const [PoolDeZone, _$PoolDeZone];

  @override
  final String wireName = r'PoolDeZone';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PoolDeZone object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'coursiers';
    yield serializers.serialize(
      object.coursiers,
      specifiedType: const FullType(BuiltList, [FullType(CoursierDuPool)]),
    );
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PoolDeZone object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PoolDeZoneBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'coursiers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CoursierDuPool)]),
          ) as BuiltList<CoursierDuPool>;
          result.coursiers.replace(valueDes);
          break;
        case r'zone_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PoolDeZone deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PoolDeZoneBuilder();
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

