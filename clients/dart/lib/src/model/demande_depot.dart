//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_depot.g.dart';

/// Ouverture ou fermeture de la voie « dépôt » sur une commande.
///
/// Properties:
/// * [autorise] - `true` ouvre la voie, `false` la referme.
/// * [motifCle] - Clé i18n du motif (obligatoire dans les deux sens).
@BuiltValue()
abstract class DemandeDepot implements Built<DemandeDepot, DemandeDepotBuilder> {
  /// `true` ouvre la voie, `false` la referme.
  @BuiltValueField(wireName: r'autorise')
  bool get autorise;

  /// Clé i18n du motif (obligatoire dans les deux sens).
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  DemandeDepot._();

  factory DemandeDepot([void updates(DemandeDepotBuilder b)]) = _$DemandeDepot;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeDepotBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeDepot> get serializer => _$DemandeDepotSerializer();
}

class _$DemandeDepotSerializer implements PrimitiveSerializer<DemandeDepot> {
  @override
  final Iterable<Type> types = const [DemandeDepot, _$DemandeDepot];

  @override
  final String wireName = r'DemandeDepot';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeDepot object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'autorise';
    yield serializers.serialize(
      object.autorise,
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
    DemandeDepot object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeDepotBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'autorise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.autorise = valueDes;
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
  DemandeDepot deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeDepotBuilder();
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

