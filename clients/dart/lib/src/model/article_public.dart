//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'article_public.g.dart';

/// Article du catalogue public.
///
/// Properties:
/// * [categorieInterne] - Étiquette libre de regroupement.
/// * [devise] - Code ISO 4217 de la zone.
/// * [disponible] - Faux = rupture (servi seulement si le mode de la catégorie est `grise`).
/// * [id] - Identifiant.
/// * [nom] - Nom.
/// * [photoUrl] - URL présignée de la photo (TTL 10 min).
/// * [prixBarreUnites] - Prix barré (présent ⇒ promotion, strictement supérieur — FR-023).
/// * [prixUnites] - Prix courant — ENTIER en unités mineures (constitution III).
@BuiltValue()
abstract class ArticlePublic implements Built<ArticlePublic, ArticlePublicBuilder> {
  /// Étiquette libre de regroupement.
  @BuiltValueField(wireName: r'categorie_interne')
  String? get categorieInterne;

  /// Code ISO 4217 de la zone.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Faux = rupture (servi seulement si le mode de la catégorie est `grise`).
  @BuiltValueField(wireName: r'disponible')
  bool get disponible;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nom.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// URL présignée de la photo (TTL 10 min).
  @BuiltValueField(wireName: r'photo_url')
  String? get photoUrl;

  /// Prix barré (présent ⇒ promotion, strictement supérieur — FR-023).
  @BuiltValueField(wireName: r'prix_barre_unites')
  int? get prixBarreUnites;

  /// Prix courant — ENTIER en unités mineures (constitution III).
  @BuiltValueField(wireName: r'prix_unites')
  int get prixUnites;

  ArticlePublic._();

  factory ArticlePublic([void updates(ArticlePublicBuilder b)]) = _$ArticlePublic;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ArticlePublicBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ArticlePublic> get serializer => _$ArticlePublicSerializer();
}

class _$ArticlePublicSerializer implements PrimitiveSerializer<ArticlePublic> {
  @override
  final Iterable<Type> types = const [ArticlePublic, _$ArticlePublic];

  @override
  final String wireName = r'ArticlePublic';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ArticlePublic object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.categorieInterne != null) {
      yield r'categorie_interne';
      yield serializers.serialize(
        object.categorieInterne,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'disponible';
    yield serializers.serialize(
      object.disponible,
      specifiedType: const FullType(bool),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    if (object.photoUrl != null) {
      yield r'photo_url';
      yield serializers.serialize(
        object.photoUrl,
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
    yield r'prix_unites';
    yield serializers.serialize(
      object.prixUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ArticlePublic object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ArticlePublicBuilder result,
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
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'disponible':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.disponible = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'photo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.photoUrl = valueDes;
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
  ArticlePublic deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ArticlePublicBuilder();
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

