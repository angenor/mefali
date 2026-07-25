//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'action_arret.g.dart';

/// Corps commun des actions déclaratives d'arrêt.
///
/// Properties:
/// * [horodatageLocal] - Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien, parce que `arrive_le` fonde une prime (TRF-06).
/// * [motif] - Pour `indisponible` : `vendeur_ferme` (défaut) ou `toutes_lignes_retirees`. Ignoré par les autres actions.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
@BuiltValue()
abstract class ActionArret implements Built<ActionArret, ActionArretBuilder> {
  /// Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien, parce que `arrive_le` fonde une prime (TRF-06).
  @BuiltValueField(wireName: r'horodatage_local')
  DateTime get horodatageLocal;

  /// Pour `indisponible` : `vendeur_ferme` (défaut) ou `toutes_lignes_retirees`. Ignoré par les autres actions.
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  ActionArret._();

  factory ActionArret([void updates(ActionArretBuilder b)]) = _$ActionArret;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ActionArretBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ActionArret> get serializer => _$ActionArretSerializer();
}

class _$ActionArretSerializer implements PrimitiveSerializer<ActionArret> {
  @override
  final Iterable<Type> types = const [ActionArret, _$ActionArret];

  @override
  final String wireName = r'ActionArret';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ActionArret object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'horodatage_local';
    yield serializers.serialize(
      object.horodatageLocal,
      specifiedType: const FullType(DateTime),
    );
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ActionArret object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ActionArretBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'horodatage_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.horodatageLocal = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motif = valueDes;
          break;
        case r'uuid_client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uuidClient = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ActionArret deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ActionArretBuilder();
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

