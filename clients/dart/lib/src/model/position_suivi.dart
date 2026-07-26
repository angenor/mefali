//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'position_suivi.g.dart';

/// Position du coursier, **toujours accompagnée de son âge**.
///
/// Properties:
/// * [ageS] - Ancienneté du relevé, en secondes. L'app affiche « il y a 12 s » et n'invente JAMAIS une position (FR-040, maquette C4-4d).
/// * [lat] - Latitude.
/// * [lon] - Longitude.
@BuiltValue()
abstract class PositionSuivi implements Built<PositionSuivi, PositionSuiviBuilder> {
  /// Ancienneté du relevé, en secondes. L'app affiche « il y a 12 s » et n'invente JAMAIS une position (FR-040, maquette C4-4d).
  @BuiltValueField(wireName: r'age_s')
  int get ageS;

  /// Latitude.
  @BuiltValueField(wireName: r'lat')
  double get lat;

  /// Longitude.
  @BuiltValueField(wireName: r'lon')
  double get lon;

  PositionSuivi._();

  factory PositionSuivi([void updates(PositionSuiviBuilder b)]) = _$PositionSuivi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PositionSuiviBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PositionSuivi> get serializer => _$PositionSuiviSerializer();
}

class _$PositionSuiviSerializer implements PrimitiveSerializer<PositionSuivi> {
  @override
  final Iterable<Type> types = const [PositionSuivi, _$PositionSuivi];

  @override
  final String wireName = r'PositionSuivi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PositionSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'age_s';
    yield serializers.serialize(
      object.ageS,
      specifiedType: const FullType(int),
    );
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
    PositionSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PositionSuiviBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'age_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ageS = valueDes;
          break;
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
  PositionSuivi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PositionSuiviBuilder();
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

