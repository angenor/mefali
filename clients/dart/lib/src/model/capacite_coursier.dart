//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'capacite_coursier.g.dart';

/// Une capacité déclarée, telle que l'app l'affiche.
///
/// Properties:
/// * [famille] - Famille de capacité (MVP : `transport`).
/// * [valeur] - Valeur dans la famille (slug de transport).
@BuiltValue()
abstract class CapaciteCoursier implements Built<CapaciteCoursier, CapaciteCoursierBuilder> {
  /// Famille de capacité (MVP : `transport`).
  @BuiltValueField(wireName: r'famille')
  String get famille;

  /// Valeur dans la famille (slug de transport).
  @BuiltValueField(wireName: r'valeur')
  String get valeur;

  CapaciteCoursier._();

  factory CapaciteCoursier([void updates(CapaciteCoursierBuilder b)]) = _$CapaciteCoursier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CapaciteCoursierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CapaciteCoursier> get serializer => _$CapaciteCoursierSerializer();
}

class _$CapaciteCoursierSerializer implements PrimitiveSerializer<CapaciteCoursier> {
  @override
  final Iterable<Type> types = const [CapaciteCoursier, _$CapaciteCoursier];

  @override
  final String wireName = r'CapaciteCoursier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CapaciteCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'famille';
    yield serializers.serialize(
      object.famille,
      specifiedType: const FullType(String),
    );
    yield r'valeur';
    yield serializers.serialize(
      object.valeur,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CapaciteCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CapaciteCoursierBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'famille':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.famille = valueDes;
          break;
        case r'valeur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.valeur = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CapaciteCoursier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CapaciteCoursierBuilder();
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

