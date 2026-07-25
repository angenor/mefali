//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_panier.g.dart';

/// Une ligne de panier soumise.
///
/// Properties:
/// * [articleId] - Article demandé.
/// * [preference] - Que faire si l'article manque : `remplacer` | `appeler` | `retirer`. Absent = `appeler`, le défaut produit (CMD-01).
/// * [prestataireId] - Vendeur chez qui l'article est pris.
/// * [quantite] - Quantité (> 0).
@BuiltValue()
abstract class LignePanier implements Built<LignePanier, LignePanierBuilder> {
  /// Article demandé.
  @BuiltValueField(wireName: r'article_id')
  String get articleId;

  /// Que faire si l'article manque : `remplacer` | `appeler` | `retirer`. Absent = `appeler`, le défaut produit (CMD-01).
  @BuiltValueField(wireName: r'preference')
  String? get preference;

  /// Vendeur chez qui l'article est pris.
  @BuiltValueField(wireName: r'prestataire_id')
  String get prestataireId;

  /// Quantité (> 0).
  @BuiltValueField(wireName: r'quantite')
  int get quantite;

  LignePanier._();

  factory LignePanier([void updates(LignePanierBuilder b)]) = _$LignePanier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LignePanierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LignePanier> get serializer => _$LignePanierSerializer();
}

class _$LignePanierSerializer implements PrimitiveSerializer<LignePanier> {
  @override
  final Iterable<Type> types = const [LignePanier, _$LignePanier];

  @override
  final String wireName = r'LignePanier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LignePanier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'article_id';
    yield serializers.serialize(
      object.articleId,
      specifiedType: const FullType(String),
    );
    if (object.preference != null) {
      yield r'preference';
      yield serializers.serialize(
        object.preference,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'prestataire_id';
    yield serializers.serialize(
      object.prestataireId,
      specifiedType: const FullType(String),
    );
    yield r'quantite';
    yield serializers.serialize(
      object.quantite,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LignePanier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LignePanierBuilder result,
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
        case r'preference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.preference = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prestataireId = valueDes;
          break;
        case r'quantite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.quantite = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LignePanier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LignePanierBuilder();
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

