//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'rattachement_dto.g.dart';

/// Rattachement compte ↔ prestataire.
///
/// Properties:
/// * [compteId] - Compte rattaché.
/// * [rattacheLe] - Depuis quand.
@BuiltValue()
abstract class RattachementDto implements Built<RattachementDto, RattachementDtoBuilder> {
  /// Compte rattaché.
  @BuiltValueField(wireName: r'compte_id')
  String get compteId;

  /// Depuis quand.
  @BuiltValueField(wireName: r'rattache_le')
  DateTime get rattacheLe;

  RattachementDto._();

  factory RattachementDto([void updates(RattachementDtoBuilder b)]) = _$RattachementDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RattachementDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RattachementDto> get serializer => _$RattachementDtoSerializer();
}

class _$RattachementDtoSerializer implements PrimitiveSerializer<RattachementDto> {
  @override
  final Iterable<Type> types = const [RattachementDto, _$RattachementDto];

  @override
  final String wireName = r'RattachementDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RattachementDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'compte_id';
    yield serializers.serialize(
      object.compteId,
      specifiedType: const FullType(String),
    );
    yield r'rattache_le';
    yield serializers.serialize(
      object.rattacheLe,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RattachementDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RattachementDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'compte_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.compteId = valueDes;
          break;
        case r'rattache_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.rattacheLe = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RattachementDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RattachementDtoBuilder();
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

