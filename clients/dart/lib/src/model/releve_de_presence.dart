//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'releve_de_presence.g.dart';

/// Un échantillon de présence tel que l'app le déclare.
///
/// Properties:
/// * [distanceM] - Éloignement du point de livraison, en mètres **arrondis**.  ⚠ Une distance, **jamais une position** : le serveur ne stocke aucune coordonnée, donc n'en fuite aucune (R8, patron ARTCI du cycle 006).
/// * [releveLeLocal] - Horodatage de l'échantillon sur l'appareil.
/// * [uuidClient] - Clé d'idempotence du relevé (UUIDv7 client, constitution V).
@BuiltValue()
abstract class ReleveDePresence implements Built<ReleveDePresence, ReleveDePresenceBuilder> {
  /// Éloignement du point de livraison, en mètres **arrondis**.  ⚠ Une distance, **jamais une position** : le serveur ne stocke aucune coordonnée, donc n'en fuite aucune (R8, patron ARTCI du cycle 006).
  @BuiltValueField(wireName: r'distance_m')
  int get distanceM;

  /// Horodatage de l'échantillon sur l'appareil.
  @BuiltValueField(wireName: r'releve_le_local')
  DateTime get releveLeLocal;

  /// Clé d'idempotence du relevé (UUIDv7 client, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  ReleveDePresence._();

  factory ReleveDePresence([void updates(ReleveDePresenceBuilder b)]) = _$ReleveDePresence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReleveDePresenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReleveDePresence> get serializer => _$ReleveDePresenceSerializer();
}

class _$ReleveDePresenceSerializer implements PrimitiveSerializer<ReleveDePresence> {
  @override
  final Iterable<Type> types = const [ReleveDePresence, _$ReleveDePresence];

  @override
  final String wireName = r'ReleveDePresence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReleveDePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'distance_m';
    yield serializers.serialize(
      object.distanceM,
      specifiedType: const FullType(int),
    );
    yield r'releve_le_local';
    yield serializers.serialize(
      object.releveLeLocal,
      specifiedType: const FullType(DateTime),
    );
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReleveDePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReleveDePresenceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'distance_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.distanceM = valueDes;
          break;
        case r'releve_le_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.releveLeLocal = valueDes;
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
  ReleveDePresence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReleveDePresenceBuilder();
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

