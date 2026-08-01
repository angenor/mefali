//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decision_depot.g.dart';

/// État de la voie dépôt après décision.
///
/// Properties:
/// * [commandeId] - Commande concernée.
/// * [depotAutorise] - La voie dépôt est-elle ouverte ?
/// * [motifCle] - Motif retenu.
@BuiltValue()
abstract class DecisionDepot implements Built<DecisionDepot, DecisionDepotBuilder> {
  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// La voie dépôt est-elle ouverte ?
  @BuiltValueField(wireName: r'depot_autorise')
  bool get depotAutorise;

  /// Motif retenu.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  DecisionDepot._();

  factory DecisionDepot([void updates(DecisionDepotBuilder b)]) = _$DecisionDepot;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecisionDepotBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecisionDepot> get serializer => _$DecisionDepotSerializer();
}

class _$DecisionDepotSerializer implements PrimitiveSerializer<DecisionDepot> {
  @override
  final Iterable<Type> types = const [DecisionDepot, _$DecisionDepot];

  @override
  final String wireName = r'DecisionDepot';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecisionDepot object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'depot_autorise';
    yield serializers.serialize(
      object.depotAutorise,
      specifiedType: const FullType(bool),
    );
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DecisionDepot object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DecisionDepotBuilder result,
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
        case r'depot_autorise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.depotAutorise = valueDes;
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motifCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DecisionDepot deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecisionDepotBuilder();
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

