//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_photo_preuve.g.dart';

/// Partie `demande` du multipart de photo de preuve.
///
/// Properties:
/// * [priseLeLocal] - Horodatage de la prise de vue sur l'appareil. **Observation** — retenu comme date de prise pour que l'ordre des photos reste celui du terrain.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
@BuiltValue()
abstract class DemandePhotoPreuve implements Built<DemandePhotoPreuve, DemandePhotoPreuveBuilder> {
  /// Horodatage de la prise de vue sur l'appareil. **Observation** — retenu comme date de prise pour que l'ordre des photos reste celui du terrain.
  @BuiltValueField(wireName: r'prise_le_local')
  DateTime? get priseLeLocal;

  /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  DemandePhotoPreuve._();

  factory DemandePhotoPreuve([void updates(DemandePhotoPreuveBuilder b)]) = _$DemandePhotoPreuve;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandePhotoPreuveBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandePhotoPreuve> get serializer => _$DemandePhotoPreuveSerializer();
}

class _$DemandePhotoPreuveSerializer implements PrimitiveSerializer<DemandePhotoPreuve> {
  @override
  final Iterable<Type> types = const [DemandePhotoPreuve, _$DemandePhotoPreuve];

  @override
  final String wireName = r'DemandePhotoPreuve';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandePhotoPreuve object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.priseLeLocal != null) {
      yield r'prise_le_local';
      yield serializers.serialize(
        object.priseLeLocal,
        specifiedType: const FullType.nullable(DateTime),
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
    DemandePhotoPreuve object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandePhotoPreuveBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'prise_le_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.priseLeLocal = valueDes;
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
  DemandePhotoPreuve deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandePhotoPreuveBuilder();
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

