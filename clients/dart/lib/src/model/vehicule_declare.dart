//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vehicule_declare.g.dart';

/// Véhicule déclaré au dossier (contrat).
///
/// Properties:
/// * [actifZone] - `false` si le type a été DÉSACTIVÉ dans la zone après la déclaration.
/// * [slug] - Slug du type (ex. `moto`).
/// * [typeTransportId] - Type de transport du référentiel ZON-03.
@BuiltValue()
abstract class VehiculeDeclare implements Built<VehiculeDeclare, VehiculeDeclareBuilder> {
  /// `false` si le type a été DÉSACTIVÉ dans la zone après la déclaration.
  @BuiltValueField(wireName: r'actif_zone')
  bool get actifZone;

  /// Slug du type (ex. `moto`).
  @BuiltValueField(wireName: r'slug')
  String get slug;

  /// Type de transport du référentiel ZON-03.
  @BuiltValueField(wireName: r'type_transport_id')
  String get typeTransportId;

  VehiculeDeclare._();

  factory VehiculeDeclare([void updates(VehiculeDeclareBuilder b)]) = _$VehiculeDeclare;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VehiculeDeclareBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VehiculeDeclare> get serializer => _$VehiculeDeclareSerializer();
}

class _$VehiculeDeclareSerializer implements PrimitiveSerializer<VehiculeDeclare> {
  @override
  final Iterable<Type> types = const [VehiculeDeclare, _$VehiculeDeclare];

  @override
  final String wireName = r'VehiculeDeclare';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VehiculeDeclare object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'actif_zone';
    yield serializers.serialize(
      object.actifZone,
      specifiedType: const FullType(bool),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'type_transport_id';
    yield serializers.serialize(
      object.typeTransportId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VehiculeDeclare object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VehiculeDeclareBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'actif_zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.actifZone = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'type_transport_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.typeTransportId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VehiculeDeclare deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VehiculeDeclareBuilder();
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

