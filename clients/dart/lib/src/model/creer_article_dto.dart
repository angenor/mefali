//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'creer_article_dto.g.dart';

/// Création d'un article (disponible par défaut — FR-020).
///
/// Properties:
/// * [categorieInterne] - Étiquette libre de regroupement.
/// * [nom] - Nom.
/// * [prixBarreUnites] - Prix barré optionnel (strictement supérieur — FR-023).
/// * [prixUnites] - Prix courant, entier en unités mineures — la devise est POSÉE PAR LE SERVEUR depuis la zone (constitution III).
@BuiltValue()
abstract class CreerArticleDto implements Built<CreerArticleDto, CreerArticleDtoBuilder> {
  /// Étiquette libre de regroupement.
  @BuiltValueField(wireName: r'categorie_interne')
  String? get categorieInterne;

  /// Nom.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Prix barré optionnel (strictement supérieur — FR-023).
  @BuiltValueField(wireName: r'prix_barre_unites')
  int? get prixBarreUnites;

  /// Prix courant, entier en unités mineures — la devise est POSÉE PAR LE SERVEUR depuis la zone (constitution III).
  @BuiltValueField(wireName: r'prix_unites')
  int get prixUnites;

  CreerArticleDto._();

  factory CreerArticleDto([void updates(CreerArticleDtoBuilder b)]) = _$CreerArticleDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreerArticleDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreerArticleDto> get serializer => _$CreerArticleDtoSerializer();
}

class _$CreerArticleDtoSerializer implements PrimitiveSerializer<CreerArticleDto> {
  @override
  final Iterable<Type> types = const [CreerArticleDto, _$CreerArticleDto];

  @override
  final String wireName = r'CreerArticleDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreerArticleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.categorieInterne != null) {
      yield r'categorie_interne';
      yield serializers.serialize(
        object.categorieInterne,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    if (object.prixBarreUnites != null) {
      yield r'prix_barre_unites';
      yield serializers.serialize(
        object.prixBarreUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'prix_unites';
    yield serializers.serialize(
      object.prixUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreerArticleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreerArticleDtoBuilder result,
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
            specifiedType: const FullType(String),
          ) as String;
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
            specifiedType: const FullType(int),
          ) as int;
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
  CreerArticleDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreerArticleDtoBuilder();
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

