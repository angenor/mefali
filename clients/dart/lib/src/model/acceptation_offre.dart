//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'acceptation_offre.g.dart';

/// Résultat d'une acceptation.
///
/// Properties:
/// * [commandeId] - Commande affectée.
/// * [etatLivraison] - État de la livraison après affectation.
/// * [livraisonId] - Livraison assignée.
/// * [rejeu] - Vrai si l'appel était un rejeu — même corps, aucune seconde affectation.
@BuiltValue()
abstract class AcceptationOffre implements Built<AcceptationOffre, AcceptationOffreBuilder> {
  /// Commande affectée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// État de la livraison après affectation.
  @BuiltValueField(wireName: r'etat_livraison')
  String get etatLivraison;

  /// Livraison assignée.
  @BuiltValueField(wireName: r'livraison_id')
  String get livraisonId;

  /// Vrai si l'appel était un rejeu — même corps, aucune seconde affectation.
  @BuiltValueField(wireName: r'rejeu')
  bool get rejeu;

  AcceptationOffre._();

  factory AcceptationOffre([void updates(AcceptationOffreBuilder b)]) = _$AcceptationOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcceptationOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcceptationOffre> get serializer => _$AcceptationOffreSerializer();
}

class _$AcceptationOffreSerializer implements PrimitiveSerializer<AcceptationOffre> {
  @override
  final Iterable<Type> types = const [AcceptationOffre, _$AcceptationOffre];

  @override
  final String wireName = r'AcceptationOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcceptationOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'etat_livraison';
    yield serializers.serialize(
      object.etatLivraison,
      specifiedType: const FullType(String),
    );
    yield r'livraison_id';
    yield serializers.serialize(
      object.livraisonId,
      specifiedType: const FullType(String),
    );
    yield r'rejeu';
    yield serializers.serialize(
      object.rejeu,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AcceptationOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AcceptationOffreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'etat_livraison':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etatLivraison = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonId = valueDes;
          break;
        case r'rejeu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.rejeu = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AcceptationOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcceptationOffreBuilder();
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

