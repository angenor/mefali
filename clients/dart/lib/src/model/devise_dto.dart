//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'devise_dto.g.dart';

/// Devise (contrat) — montants entiers en unités mineures (principe III).
///
/// Properties:
/// * [code] - Code ISO 4217 (ex. XOF).
/// * [decimales] - Nombre de décimales des unités mineures (0 pour XOF).
@BuiltValue()
abstract class DeviseDto implements Built<DeviseDto, DeviseDtoBuilder> {
  /// Code ISO 4217 (ex. XOF).
  @BuiltValueField(wireName: r'code')
  String get code;

  /// Nombre de décimales des unités mineures (0 pour XOF).
  @BuiltValueField(wireName: r'decimales')
  int get decimales;

  DeviseDto._();

  factory DeviseDto([void updates(DeviseDtoBuilder b)]) = _$DeviseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeviseDto> get serializer => _$DeviseDtoSerializer();
}

class _$DeviseDtoSerializer implements PrimitiveSerializer<DeviseDto> {
  @override
  final Iterable<Type> types = const [DeviseDto, _$DeviseDto];

  @override
  final String wireName = r'DeviseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeviseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'decimales';
    yield serializers.serialize(
      object.decimales,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeviseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'decimales':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.decimales = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeviseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviseDtoBuilder();
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

