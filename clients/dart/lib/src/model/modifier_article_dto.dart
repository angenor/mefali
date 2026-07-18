//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'modifier_article_dto.g.dart';

/// Modification partielle — champ ABSENT = inchangé, `null` EXPLICITE = effacé (c'est ainsi qu'on retire une promotion : `prix_barre_unites: null`).
///
/// Properties:
/// * [categorieInterne] - Nouvelle étiquette — `null` l'efface.
/// * [nom] - Nouveau nom.
/// * [prixBarreUnites] - Nouveau prix barré — `null` retire la promotion EXPLICITEMENT (jamais en silence : un prix barré devenu ≤ prix fait échouer l'opération).
/// * [prixUnites] - Nouveau prix courant.
@BuiltValue()
abstract class ModifierArticleDto implements Built<ModifierArticleDto, ModifierArticleDtoBuilder> {
  /// Nouvelle étiquette — `null` l'efface.
  @BuiltValueField(wireName: r'categorie_interne')
  String? get categorieInterne;

  /// Nouveau nom.
  @BuiltValueField(wireName: r'nom')
  String? get nom;

  /// Nouveau prix barré — `null` retire la promotion EXPLICITEMENT (jamais en silence : un prix barré devenu ≤ prix fait échouer l'opération).
  @BuiltValueField(wireName: r'prix_barre_unites')
  int? get prixBarreUnites;

  /// Nouveau prix courant.
  @BuiltValueField(wireName: r'prix_unites')
  int? get prixUnites;

  ModifierArticleDto._();

  factory ModifierArticleDto([void updates(ModifierArticleDtoBuilder b)]) = _$ModifierArticleDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ModifierArticleDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ModifierArticleDto> get serializer => _$ModifierArticleDtoSerializer();
}

class _$ModifierArticleDtoSerializer implements PrimitiveSerializer<ModifierArticleDto> {
  @override
  final Iterable<Type> types = const [ModifierArticleDto, _$ModifierArticleDto];

  @override
  final String wireName = r'ModifierArticleDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ModifierArticleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.categorieInterne != null) {
      yield r'categorie_interne';
      yield serializers.serialize(
        object.categorieInterne,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.nom != null) {
      yield r'nom';
      yield serializers.serialize(
        object.nom,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.prixBarreUnites != null) {
      yield r'prix_barre_unites';
      yield serializers.serialize(
        object.prixBarreUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.prixUnites != null) {
      yield r'prix_unites';
      yield serializers.serialize(
        object.prixUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ModifierArticleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ModifierArticleDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categorie_interne':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categorieInterne = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nom = valueDes;
          break;
        case r'prix_barre_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.prixBarreUnites = valueDes;
          break;
        case r'prix_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.prixUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ModifierArticleDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ModifierArticleDtoBuilder();
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

