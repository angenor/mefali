//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'regler_creance_dto.g.dart';

/// Corps du règlement — motif **obligatoire**.
///
/// Properties:
/// * [motifCle] - Clé i18n du motif (`creance.reglement.virement_agence`, …). Sans lui, « réglée » ne dit pas COMMENT — et c'est la première question posée quand un coursier conteste.
@BuiltValue()
abstract class ReglerCreanceDto implements Built<ReglerCreanceDto, ReglerCreanceDtoBuilder> {
  /// Clé i18n du motif (`creance.reglement.virement_agence`, …). Sans lui, « réglée » ne dit pas COMMENT — et c'est la première question posée quand un coursier conteste.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  ReglerCreanceDto._();

  factory ReglerCreanceDto([void updates(ReglerCreanceDtoBuilder b)]) = _$ReglerCreanceDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReglerCreanceDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReglerCreanceDto> get serializer => _$ReglerCreanceDtoSerializer();
}

class _$ReglerCreanceDtoSerializer implements PrimitiveSerializer<ReglerCreanceDto> {
  @override
  final Iterable<Type> types = const [ReglerCreanceDto, _$ReglerCreanceDto];

  @override
  final String wireName = r'ReglerCreanceDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReglerCreanceDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReglerCreanceDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReglerCreanceDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motifCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReglerCreanceDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReglerCreanceDtoBuilder();
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

