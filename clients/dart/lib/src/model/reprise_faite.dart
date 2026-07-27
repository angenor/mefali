//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reprise_faite.g.dart';

/// Résultat d'une reprise manuelle.
///
/// Properties:
/// * [commandeId] - Commande concernée.
/// * [etatCommande] - État du tronc après reprise.
/// * [incidentId] - Incident tracé.
@BuiltValue()
abstract class RepriseFaite implements Built<RepriseFaite, RepriseFaiteBuilder> {
  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// État du tronc après reprise.
  @BuiltValueField(wireName: r'etat_commande')
  String get etatCommande;

  /// Incident tracé.
  @BuiltValueField(wireName: r'incident_id')
  String get incidentId;

  RepriseFaite._();

  factory RepriseFaite([void updates(RepriseFaiteBuilder b)]) = _$RepriseFaite;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RepriseFaiteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RepriseFaite> get serializer => _$RepriseFaiteSerializer();
}

class _$RepriseFaiteSerializer implements PrimitiveSerializer<RepriseFaite> {
  @override
  final Iterable<Type> types = const [RepriseFaite, _$RepriseFaite];

  @override
  final String wireName = r'RepriseFaite';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RepriseFaite object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'etat_commande';
    yield serializers.serialize(
      object.etatCommande,
      specifiedType: const FullType(String),
    );
    yield r'incident_id';
    yield serializers.serialize(
      object.incidentId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RepriseFaite object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RepriseFaiteBuilder result,
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
        case r'etat_commande':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etatCommande = valueDes;
          break;
        case r'incident_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.incidentId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RepriseFaite deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RepriseFaiteBuilder();
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

