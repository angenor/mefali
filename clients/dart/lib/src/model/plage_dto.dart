//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plage_dto.g.dart';

/// Une plage d'ouverture, heures locales `HH:MM` (FR-031).
///
/// Properties:
/// * [debut] - Début (inclus), ex. `08:00`.
/// * [fin] - Fin (exclue), ex. `19:00`.
@BuiltValue()
abstract class PlageDto implements Built<PlageDto, PlageDtoBuilder> {
  /// Début (inclus), ex. `08:00`.
  @BuiltValueField(wireName: r'debut')
  String get debut;

  /// Fin (exclue), ex. `19:00`.
  @BuiltValueField(wireName: r'fin')
  String get fin;

  PlageDto._();

  factory PlageDto([void updates(PlageDtoBuilder b)]) = _$PlageDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlageDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlageDto> get serializer => _$PlageDtoSerializer();
}

class _$PlageDtoSerializer implements PrimitiveSerializer<PlageDto> {
  @override
  final Iterable<Type> types = const [PlageDto, _$PlageDto];

  @override
  final String wireName = r'PlageDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlageDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'debut';
    yield serializers.serialize(
      object.debut,
      specifiedType: const FullType(String),
    );
    yield r'fin';
    yield serializers.serialize(
      object.fin,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlageDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlageDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'debut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.debut = valueDes;
          break;
        case r'fin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fin = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlageDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlageDtoBuilder();
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

