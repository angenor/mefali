//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offre_livraison_declaration.g.dart';

/// Déclaration d'offre de livraison — `seuil_unites` n'a de sens que pour `au_dela`, et y est alors **obligatoire**.
///
/// Properties:
/// * [offre] - `jamais` | `toujours` | `au_dela`.
/// * [seuilUnites] - Montant de panier à partir duquel l'offre joue (unités mineures).
@BuiltValue()
abstract class OffreLivraisonDeclaration implements Built<OffreLivraisonDeclaration, OffreLivraisonDeclarationBuilder> {
  /// `jamais` | `toujours` | `au_dela`.
  @BuiltValueField(wireName: r'offre')
  String get offre;

  /// Montant de panier à partir duquel l'offre joue (unités mineures).
  @BuiltValueField(wireName: r'seuil_unites')
  int? get seuilUnites;

  OffreLivraisonDeclaration._();

  factory OffreLivraisonDeclaration([void updates(OffreLivraisonDeclarationBuilder b)]) = _$OffreLivraisonDeclaration;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OffreLivraisonDeclarationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OffreLivraisonDeclaration> get serializer => _$OffreLivraisonDeclarationSerializer();
}

class _$OffreLivraisonDeclarationSerializer implements PrimitiveSerializer<OffreLivraisonDeclaration> {
  @override
  final Iterable<Type> types = const [OffreLivraisonDeclaration, _$OffreLivraisonDeclaration];

  @override
  final String wireName = r'OffreLivraisonDeclaration';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OffreLivraisonDeclaration object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'offre';
    yield serializers.serialize(
      object.offre,
      specifiedType: const FullType(String),
    );
    if (object.seuilUnites != null) {
      yield r'seuil_unites';
      yield serializers.serialize(
        object.seuilUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OffreLivraisonDeclaration object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OffreLivraisonDeclarationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'offre':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offre = valueDes;
          break;
        case r'seuil_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.seuilUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OffreLivraisonDeclaration deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OffreLivraisonDeclarationBuilder();
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

