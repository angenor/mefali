//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'rattacher_compte_dto.g.dart';

/// Corps du rattachement.
///
/// Properties:
/// * [compteId] - Compte vérifié à rattacher.
@BuiltValue()
abstract class RattacherCompteDto implements Built<RattacherCompteDto, RattacherCompteDtoBuilder> {
  /// Compte vérifié à rattacher.
  @BuiltValueField(wireName: r'compte_id')
  String get compteId;

  RattacherCompteDto._();

  factory RattacherCompteDto([void updates(RattacherCompteDtoBuilder b)]) = _$RattacherCompteDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RattacherCompteDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RattacherCompteDto> get serializer => _$RattacherCompteDtoSerializer();
}

class _$RattacherCompteDtoSerializer implements PrimitiveSerializer<RattacherCompteDto> {
  @override
  final Iterable<Type> types = const [RattacherCompteDto, _$RattacherCompteDto];

  @override
  final String wireName = r'RattacherCompteDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RattacherCompteDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'compte_id';
    yield serializers.serialize(
      object.compteId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RattacherCompteDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RattacherCompteDtoBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RattacherCompteDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RattacherCompteDtoBuilder();
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

