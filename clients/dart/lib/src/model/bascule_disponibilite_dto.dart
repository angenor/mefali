//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'bascule_disponibilite_dto.g.dart';

/// Corps de la bascule.
///
/// Properties:
/// * [disponible] - `false` = rupture, `true` = retour en vente.
@BuiltValue()
abstract class BasculeDisponibiliteDto implements Built<BasculeDisponibiliteDto, BasculeDisponibiliteDtoBuilder> {
  /// `false` = rupture, `true` = retour en vente.
  @BuiltValueField(wireName: r'disponible')
  bool get disponible;

  BasculeDisponibiliteDto._();

  factory BasculeDisponibiliteDto([void updates(BasculeDisponibiliteDtoBuilder b)]) = _$BasculeDisponibiliteDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BasculeDisponibiliteDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BasculeDisponibiliteDto> get serializer => _$BasculeDisponibiliteDtoSerializer();
}

class _$BasculeDisponibiliteDtoSerializer implements PrimitiveSerializer<BasculeDisponibiliteDto> {
  @override
  final Iterable<Type> types = const [BasculeDisponibiliteDto, _$BasculeDisponibiliteDto];

  @override
  final String wireName = r'BasculeDisponibiliteDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BasculeDisponibiliteDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'disponible';
    yield serializers.serialize(
      object.disponible,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BasculeDisponibiliteDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BasculeDisponibiliteDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'disponible':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.disponible = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BasculeDisponibiliteDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BasculeDisponibiliteDtoBuilder();
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

