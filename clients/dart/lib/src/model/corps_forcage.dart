//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/forcage_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'corps_forcage.g.dart';

/// Corps de la requête de forçage.
///
/// Properties:
/// * [forcage] - Nouveau mode de forçage à appliquer.
@BuiltValue()
abstract class CorpsForcage implements Built<CorpsForcage, CorpsForcageBuilder> {
  /// Nouveau mode de forçage à appliquer.
  @BuiltValueField(wireName: r'forcage')
  ForcageDto get forcage;
  // enum forcageEnum {  automatique,  force_actif,  force_inactif,  };

  CorpsForcage._();

  factory CorpsForcage([void updates(CorpsForcageBuilder b)]) = _$CorpsForcage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CorpsForcageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CorpsForcage> get serializer => _$CorpsForcageSerializer();
}

class _$CorpsForcageSerializer implements PrimitiveSerializer<CorpsForcage> {
  @override
  final Iterable<Type> types = const [CorpsForcage, _$CorpsForcage];

  @override
  final String wireName = r'CorpsForcage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CorpsForcage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'forcage';
    yield serializers.serialize(
      object.forcage,
      specifiedType: const FullType(ForcageDto),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CorpsForcage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CorpsForcageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'forcage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ForcageDto),
          ) as ForcageDto;
          result.forcage = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CorpsForcage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CorpsForcageBuilder();
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

