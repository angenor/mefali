//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'publication_position.g.dart';

/// Publication de position.
///
/// Properties:
/// * [horodatageLocal] - Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien (FR-055).
/// * [lat] - Latitude.
/// * [lon] - Longitude.
/// * [precisionM] - Précision annoncée par le téléphone (mètres), informative.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
@BuiltValue()
abstract class PublicationPosition implements Built<PublicationPosition, PublicationPositionBuilder> {
  /// Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien (FR-055).
  @BuiltValueField(wireName: r'horodatage_local')
  DateTime get horodatageLocal;

  /// Latitude.
  @BuiltValueField(wireName: r'lat')
  double get lat;

  /// Longitude.
  @BuiltValueField(wireName: r'lon')
  double get lon;

  /// Précision annoncée par le téléphone (mètres), informative.
  @BuiltValueField(wireName: r'precision_m')
  int? get precisionM;

  /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  PublicationPosition._();

  factory PublicationPosition([void updates(PublicationPositionBuilder b)]) = _$PublicationPosition;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PublicationPositionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PublicationPosition> get serializer => _$PublicationPositionSerializer();
}

class _$PublicationPositionSerializer implements PrimitiveSerializer<PublicationPosition> {
  @override
  final Iterable<Type> types = const [PublicationPosition, _$PublicationPosition];

  @override
  final String wireName = r'PublicationPosition';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PublicationPosition object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'horodatage_local';
    yield serializers.serialize(
      object.horodatageLocal,
      specifiedType: const FullType(DateTime),
    );
    yield r'lat';
    yield serializers.serialize(
      object.lat,
      specifiedType: const FullType(double),
    );
    yield r'lon';
    yield serializers.serialize(
      object.lon,
      specifiedType: const FullType(double),
    );
    if (object.precisionM != null) {
      yield r'precision_m';
      yield serializers.serialize(
        object.precisionM,
        specifiedType: const FullType.nullable(int),
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
    PublicationPosition object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PublicationPositionBuilder result,
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
        case r'lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lat = valueDes;
          break;
        case r'lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lon = valueDes;
          break;
        case r'precision_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.precisionM = valueDes;
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
  PublicationPosition deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PublicationPositionBuilder();
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

