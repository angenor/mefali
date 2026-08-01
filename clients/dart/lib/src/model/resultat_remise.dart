//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_remise.g.dart';

/// Résultat d'une remise validée.
///
/// Properties:
/// * [commandeId] - Commande close.
/// * [essaisCode] - Essais de code consommés (consolidés serveur + hors ligne).
/// * [livraisonId] - Livraison close.
/// * [modeRemise] - Mode retenu.
/// * [rejeu] - `true` si l'appel n'était qu'un **rejeu** du même `uuid_client` : rien n'a été réécrit ni ré-émis (R4).
@BuiltValue()
abstract class ResultatRemise implements Built<ResultatRemise, ResultatRemiseBuilder> {
  /// Commande close.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Essais de code consommés (consolidés serveur + hors ligne).
  @BuiltValueField(wireName: r'essais_code')
  int get essaisCode;

  /// Livraison close.
  @BuiltValueField(wireName: r'livraison_id')
  String get livraisonId;

  /// Mode retenu.
  @BuiltValueField(wireName: r'mode_remise')
  String get modeRemise;

  /// `true` si l'appel n'était qu'un **rejeu** du même `uuid_client` : rien n'a été réécrit ni ré-émis (R4).
  @BuiltValueField(wireName: r'rejeu')
  bool get rejeu;

  ResultatRemise._();

  factory ResultatRemise([void updates(ResultatRemiseBuilder b)]) = _$ResultatRemise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatRemiseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatRemise> get serializer => _$ResultatRemiseSerializer();
}

class _$ResultatRemiseSerializer implements PrimitiveSerializer<ResultatRemise> {
  @override
  final Iterable<Type> types = const [ResultatRemise, _$ResultatRemise];

  @override
  final String wireName = r'ResultatRemise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'essais_code';
    yield serializers.serialize(
      object.essaisCode,
      specifiedType: const FullType(int),
    );
    yield r'livraison_id';
    yield serializers.serialize(
      object.livraisonId,
      specifiedType: const FullType(String),
    );
    yield r'mode_remise';
    yield serializers.serialize(
      object.modeRemise,
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
    ResultatRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatRemiseBuilder result,
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
        case r'essais_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.essaisCode = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonId = valueDes;
          break;
        case r'mode_remise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.modeRemise = valueDes;
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
  ResultatRemise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatRemiseBuilder();
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

