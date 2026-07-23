//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_collecte.g.dart';

/// Résultat d'une collecte.
///
/// Properties:
/// * [arretStatut] - Statut de l'arrêt (`collecte`).
/// * [enLivraison] - Vrai si la livraison vient de basculer EN_LIVRAISON.
/// * [livraisonEtat] - État de la livraison (`en_collecte` | `en_livraison`).
/// * [nbArrets] - Total d'arrêts.
/// * [nbCollectes] - Arrêts collectés.
@BuiltValue()
abstract class ResultatCollecte implements Built<ResultatCollecte, ResultatCollecteBuilder> {
  /// Statut de l'arrêt (`collecte`).
  @BuiltValueField(wireName: r'arret_statut')
  String get arretStatut;

  /// Vrai si la livraison vient de basculer EN_LIVRAISON.
  @BuiltValueField(wireName: r'en_livraison')
  bool get enLivraison;

  /// État de la livraison (`en_collecte` | `en_livraison`).
  @BuiltValueField(wireName: r'livraison_etat')
  String get livraisonEtat;

  /// Total d'arrêts.
  @BuiltValueField(wireName: r'nb_arrets')
  int get nbArrets;

  /// Arrêts collectés.
  @BuiltValueField(wireName: r'nb_collectes')
  int get nbCollectes;

  ResultatCollecte._();

  factory ResultatCollecte([void updates(ResultatCollecteBuilder b)]) = _$ResultatCollecte;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatCollecteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatCollecte> get serializer => _$ResultatCollecteSerializer();
}

class _$ResultatCollecteSerializer implements PrimitiveSerializer<ResultatCollecte> {
  @override
  final Iterable<Type> types = const [ResultatCollecte, _$ResultatCollecte];

  @override
  final String wireName = r'ResultatCollecte';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatCollecte object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arret_statut';
    yield serializers.serialize(
      object.arretStatut,
      specifiedType: const FullType(String),
    );
    yield r'en_livraison';
    yield serializers.serialize(
      object.enLivraison,
      specifiedType: const FullType(bool),
    );
    yield r'livraison_etat';
    yield serializers.serialize(
      object.livraisonEtat,
      specifiedType: const FullType(String),
    );
    yield r'nb_arrets';
    yield serializers.serialize(
      object.nbArrets,
      specifiedType: const FullType(int),
    );
    yield r'nb_collectes';
    yield serializers.serialize(
      object.nbCollectes,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResultatCollecte object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatCollecteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.arretStatut = valueDes;
          break;
        case r'en_livraison':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enLivraison = valueDes;
          break;
        case r'livraison_etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonEtat = valueDes;
          break;
        case r'nb_arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbArrets = valueDes;
          break;
        case r'nb_collectes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbCollectes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResultatCollecte deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatCollecteBuilder();
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

