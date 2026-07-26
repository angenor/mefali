//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_devis.g.dart';

/// Une ligne résolue contre le catalogue.
///
/// Properties:
/// * [articleId] - Article.
/// * [nom] - Nom de l'article.
/// * [preference] - Préférence de substitution retenue.
/// * [prixUnites] - Prix unitaire courant (unités mineures).
/// * [quantite] - Quantité.
/// * [sousTotalUnites] - Sous-total de la ligne (unités mineures).
@BuiltValue()
abstract class LigneDevis implements Built<LigneDevis, LigneDevisBuilder> {
  /// Article.
  @BuiltValueField(wireName: r'article_id')
  String get articleId;

  /// Nom de l'article.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Préférence de substitution retenue.
  @BuiltValueField(wireName: r'preference')
  String get preference;

  /// Prix unitaire courant (unités mineures).
  @BuiltValueField(wireName: r'prix_unites')
  int get prixUnites;

  /// Quantité.
  @BuiltValueField(wireName: r'quantite')
  int get quantite;

  /// Sous-total de la ligne (unités mineures).
  @BuiltValueField(wireName: r'sous_total_unites')
  int get sousTotalUnites;

  LigneDevis._();

  factory LigneDevis([void updates(LigneDevisBuilder b)]) = _$LigneDevis;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LigneDevisBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LigneDevis> get serializer => _$LigneDevisSerializer();
}

class _$LigneDevisSerializer implements PrimitiveSerializer<LigneDevis> {
  @override
  final Iterable<Type> types = const [LigneDevis, _$LigneDevis];

  @override
  final String wireName = r'LigneDevis';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LigneDevis object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'article_id';
    yield serializers.serialize(
      object.articleId,
      specifiedType: const FullType(String),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'preference';
    yield serializers.serialize(
      object.preference,
      specifiedType: const FullType(String),
    );
    yield r'prix_unites';
    yield serializers.serialize(
      object.prixUnites,
      specifiedType: const FullType(int),
    );
    yield r'quantite';
    yield serializers.serialize(
      object.quantite,
      specifiedType: const FullType(int),
    );
    yield r'sous_total_unites';
    yield serializers.serialize(
      object.sousTotalUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LigneDevis object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LigneDevisBuilder result,
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
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'preference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.preference = valueDes;
          break;
        case r'prix_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixUnites = valueDes;
          break;
        case r'quantite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.quantite = valueDes;
          break;
        case r'sous_total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sousTotalUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LigneDevis deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LigneDevisBuilder();
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

