//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'categorie_dto.g.dart';

/// Catégorie active (contrat).
///
/// Properties:
/// * [mixable] - Mixable au panier (CMD-01).
/// * [nomCle] - Clé i18n fr du nom.
/// * [slug] - Slug de la catégorie.
@BuiltValue()
abstract class CategorieDto implements Built<CategorieDto, CategorieDtoBuilder> {
  /// Mixable au panier (CMD-01).
  @BuiltValueField(wireName: r'mixable')
  bool get mixable;

  /// Clé i18n fr du nom.
  @BuiltValueField(wireName: r'nom_cle')
  String get nomCle;

  /// Slug de la catégorie.
  @BuiltValueField(wireName: r'slug')
  String get slug;

  CategorieDto._();

  factory CategorieDto([void updates(CategorieDtoBuilder b)]) = _$CategorieDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CategorieDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CategorieDto> get serializer => _$CategorieDtoSerializer();
}

class _$CategorieDtoSerializer implements PrimitiveSerializer<CategorieDto> {
  @override
  final Iterable<Type> types = const [CategorieDto, _$CategorieDto];

  @override
  final String wireName = r'CategorieDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CategorieDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mixable';
    yield serializers.serialize(
      object.mixable,
      specifiedType: const FullType(bool),
    );
    yield r'nom_cle';
    yield serializers.serialize(
      object.nomCle,
      specifiedType: const FullType(String),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CategorieDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CategorieDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mixable':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.mixable = valueDes;
          break;
        case r'nom_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nomCle = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CategorieDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CategorieDtoBuilder();
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

