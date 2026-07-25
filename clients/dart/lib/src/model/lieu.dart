//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'lieu.g.dart';

/// Position d'un lieu (pin GPS).
///
/// Properties:
/// * [lat] - Latitude.
/// * [lon] - Longitude.
@BuiltValue()
abstract class Lieu implements Built<Lieu, LieuBuilder> {
  /// Latitude.
  @BuiltValueField(wireName: r'lat')
  double get lat;

  /// Longitude.
  @BuiltValueField(wireName: r'lon')
  double get lon;

  Lieu._();

  factory Lieu([void updates(LieuBuilder b)]) = _$Lieu;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LieuBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Lieu> get serializer => _$LieuSerializer();
}

class _$LieuSerializer implements PrimitiveSerializer<Lieu> {
  @override
  final Iterable<Type> types = const [Lieu, _$Lieu];

  @override
  final String wireName = r'Lieu';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Lieu object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'lat';
    yield serializers.serialize(
      object.lat,
      specifiedType: const FullType(double),
    );
    yield r'lon';
    yield serializers.serialize(
      object.lon,
      specifiedType: const FullType(double),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Lieu object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LieuBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lat = valueDes;
          break;
        case r'lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lon = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Lieu deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LieuBuilder();
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

