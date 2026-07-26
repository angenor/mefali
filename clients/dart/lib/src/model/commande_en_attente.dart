//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'commande_en_attente.g.dart';

/// Une commande en attente de coursier, telle que DSP la lira.
///
/// Properties:
/// * [ageS] - Ancienneté dans la file, en secondes — **c'est elle qui ordonne**.
/// * [commandeId] - Commande concernée.
/// * [devise] - Devise ISO 4217.
/// * [montantAAvancer] - Montant total que le coursier devra avancer (unités mineures).
/// * [nbCollectes] - Nombre d'arrêts de collecte à desservir.
/// * [premiereCollecteLat] - Latitude du premier site VENDEUR — donnée professionnelle. Aucune coordonnée du client n'est exposée ici (minimisation ARTCI).
/// * [premiereCollecteLon] - Longitude du premier site vendeur.
/// * [zoneId] - Zone de la commande.
@BuiltValue()
abstract class CommandeEnAttente implements Built<CommandeEnAttente, CommandeEnAttenteBuilder> {
  /// Ancienneté dans la file, en secondes — **c'est elle qui ordonne**.
  @BuiltValueField(wireName: r'age_s')
  int get ageS;

  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Montant total que le coursier devra avancer (unités mineures).
  @BuiltValueField(wireName: r'montant_a_avancer')
  int get montantAAvancer;

  /// Nombre d'arrêts de collecte à desservir.
  @BuiltValueField(wireName: r'nb_collectes')
  int get nbCollectes;

  /// Latitude du premier site VENDEUR — donnée professionnelle. Aucune coordonnée du client n'est exposée ici (minimisation ARTCI).
  @BuiltValueField(wireName: r'premiere_collecte_lat')
  double? get premiereCollecteLat;

  /// Longitude du premier site vendeur.
  @BuiltValueField(wireName: r'premiere_collecte_lon')
  double? get premiereCollecteLon;

  /// Zone de la commande.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  CommandeEnAttente._();

  factory CommandeEnAttente([void updates(CommandeEnAttenteBuilder b)]) = _$CommandeEnAttente;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CommandeEnAttenteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CommandeEnAttente> get serializer => _$CommandeEnAttenteSerializer();
}

class _$CommandeEnAttenteSerializer implements PrimitiveSerializer<CommandeEnAttente> {
  @override
  final Iterable<Type> types = const [CommandeEnAttente, _$CommandeEnAttente];

  @override
  final String wireName = r'CommandeEnAttente';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CommandeEnAttente object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'age_s';
    yield serializers.serialize(
      object.ageS,
      specifiedType: const FullType(int),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'montant_a_avancer';
    yield serializers.serialize(
      object.montantAAvancer,
      specifiedType: const FullType(int),
    );
    yield r'nb_collectes';
    yield serializers.serialize(
      object.nbCollectes,
      specifiedType: const FullType(int),
    );
    if (object.premiereCollecteLat != null) {
      yield r'premiere_collecte_lat';
      yield serializers.serialize(
        object.premiereCollecteLat,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.premiereCollecteLon != null) {
      yield r'premiere_collecte_lon';
      yield serializers.serialize(
        object.premiereCollecteLon,
        specifiedType: const FullType.nullable(double),
      );
    }
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CommandeEnAttente object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CommandeEnAttenteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'age_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ageS = valueDes;
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'montant_a_avancer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantAAvancer = valueDes;
          break;
        case r'nb_collectes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbCollectes = valueDes;
          break;
        case r'premiere_collecte_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.premiereCollecteLat = valueDes;
          break;
        case r'premiere_collecte_lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.premiereCollecteLon = valueDes;
          break;
        case r'zone_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CommandeEnAttente deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CommandeEnAttenteBuilder();
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

