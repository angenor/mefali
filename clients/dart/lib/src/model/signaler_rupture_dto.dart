//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'signaler_rupture_dto.g.dart';

/// Corps du signalement.
///
/// Properties:
/// * [articleId] - Article introuvable sur place.
/// * [horodatageLocal] - Horodatage LOCAL de l'appareil (file hors-ligne — FR-039).
@BuiltValue()
abstract class SignalerRuptureDto implements Built<SignalerRuptureDto, SignalerRuptureDtoBuilder> {
  /// Article introuvable sur place.
  @BuiltValueField(wireName: r'article_id')
  String get articleId;

  /// Horodatage LOCAL de l'appareil (file hors-ligne — FR-039).
  @BuiltValueField(wireName: r'horodatage_local')
  DateTime get horodatageLocal;

  SignalerRuptureDto._();

  factory SignalerRuptureDto([void updates(SignalerRuptureDtoBuilder b)]) = _$SignalerRuptureDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SignalerRuptureDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SignalerRuptureDto> get serializer => _$SignalerRuptureDtoSerializer();
}

class _$SignalerRuptureDtoSerializer implements PrimitiveSerializer<SignalerRuptureDto> {
  @override
  final Iterable<Type> types = const [SignalerRuptureDto, _$SignalerRuptureDto];

  @override
  final String wireName = r'SignalerRuptureDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SignalerRuptureDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'article_id';
    yield serializers.serialize(
      object.articleId,
      specifiedType: const FullType(String),
    );
    yield r'horodatage_local';
    yield serializers.serialize(
      object.horodatageLocal,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SignalerRuptureDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SignalerRuptureDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'article_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.articleId = valueDes;
          break;
        case r'horodatage_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.horodatageLocal = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SignalerRuptureDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SignalerRuptureDtoBuilder();
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

