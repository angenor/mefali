//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'corriger_dto.g.dart';

/// Corps de la correction (FR-056) — au moins un champ.
///
/// Properties:
/// * [categorieSlug] - Nouvelle catégorie de service (slug).
/// * [villeId] - Nouvelle ville de rattachement (type `ville` exigé).
@BuiltValue()
abstract class CorrigerDto implements Built<CorrigerDto, CorrigerDtoBuilder> {
  /// Nouvelle catégorie de service (slug).
  @BuiltValueField(wireName: r'categorie_slug')
  String? get categorieSlug;

  /// Nouvelle ville de rattachement (type `ville` exigé).
  @BuiltValueField(wireName: r'ville_id')
  String? get villeId;

  CorrigerDto._();

  factory CorrigerDto([void updates(CorrigerDtoBuilder b)]) = _$CorrigerDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CorrigerDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CorrigerDto> get serializer => _$CorrigerDtoSerializer();
}

class _$CorrigerDtoSerializer implements PrimitiveSerializer<CorrigerDto> {
  @override
  final Iterable<Type> types = const [CorrigerDto, _$CorrigerDto];

  @override
  final String wireName = r'CorrigerDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CorrigerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.categorieSlug != null) {
      yield r'categorie_slug';
      yield serializers.serialize(
        object.categorieSlug,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.villeId != null) {
      yield r'ville_id';
      yield serializers.serialize(
        object.villeId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CorrigerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CorrigerDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categorie_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categorieSlug = valueDes;
          break;
        case r'ville_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.villeId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CorrigerDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CorrigerDtoBuilder();
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

