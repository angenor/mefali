//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/devis_livraison.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'livraison_commande.g.dart';

/// La livraison créée avec la commande.
///
/// Properties:
/// * [devis] - Devis FIGÉ copié à la création — jamais recalculé (R11).
/// * [etat] - État logistique initial.
/// * [id] - Identifiant.
/// * [nbArrets] - Nombre d'arrêts (collectes + remise).
@BuiltValue()
abstract class LivraisonCommande implements Built<LivraisonCommande, LivraisonCommandeBuilder> {
  /// Devis FIGÉ copié à la création — jamais recalculé (R11).
  @BuiltValueField(wireName: r'devis')
  DevisLivraison get devis;

  /// État logistique initial.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nombre d'arrêts (collectes + remise).
  @BuiltValueField(wireName: r'nb_arrets')
  int get nbArrets;

  LivraisonCommande._();

  factory LivraisonCommande([void updates(LivraisonCommandeBuilder b)]) = _$LivraisonCommande;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LivraisonCommandeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LivraisonCommande> get serializer => _$LivraisonCommandeSerializer();
}

class _$LivraisonCommandeSerializer implements PrimitiveSerializer<LivraisonCommande> {
  @override
  final Iterable<Type> types = const [LivraisonCommande, _$LivraisonCommande];

  @override
  final String wireName = r'LivraisonCommande';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LivraisonCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'devis';
    yield serializers.serialize(
      object.devis,
      specifiedType: const FullType(DevisLivraison),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'nb_arrets';
    yield serializers.serialize(
      object.nbArrets,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LivraisonCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LivraisonCommandeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'devis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DevisLivraison),
          ) as DevisLivraison;
          result.devis.replace(valueDes);
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nb_arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbArrets = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LivraisonCommande deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LivraisonCommandeBuilder();
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

