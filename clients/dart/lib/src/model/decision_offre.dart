//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decision_offre.g.dart';

/// Décision sur une offre — accepter ou refuser.
///
/// Properties:
/// * [horodatageLocal] - Horodatage de l'appareil — **observation seulement**.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
@BuiltValue()
abstract class DecisionOffre implements Built<DecisionOffre, DecisionOffreBuilder> {
  /// Horodatage de l'appareil — **observation seulement**.
  @BuiltValueField(wireName: r'horodatage_local')
  DateTime get horodatageLocal;

  /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  DecisionOffre._();

  factory DecisionOffre([void updates(DecisionOffreBuilder b)]) = _$DecisionOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecisionOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecisionOffre> get serializer => _$DecisionOffreSerializer();
}

class _$DecisionOffreSerializer implements PrimitiveSerializer<DecisionOffre> {
  @override
  final Iterable<Type> types = const [DecisionOffre, _$DecisionOffre];

  @override
  final String wireName = r'DecisionOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecisionOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'horodatage_local';
    yield serializers.serialize(
      object.horodatageLocal,
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
    DecisionOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DecisionOffreBuilder result,
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
  DecisionOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecisionOffreBuilder();
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

