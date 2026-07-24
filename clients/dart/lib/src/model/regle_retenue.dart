//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'regle_retenue.g.dart';

/// Règle retenue par l'évaluation.
///
/// Properties:
/// * [priorite] - Priorité.
/// * [regleId] - Identifiant de la règle.
/// * [transportSlug] - Véhicule.
@BuiltValue()
abstract class RegleRetenue implements Built<RegleRetenue, RegleRetenueBuilder> {
  /// Priorité.
  @BuiltValueField(wireName: r'priorite')
  int get priorite;

  /// Identifiant de la règle.
  @BuiltValueField(wireName: r'regle_id')
  String get regleId;

  /// Véhicule.
  @BuiltValueField(wireName: r'transport_slug')
  String get transportSlug;

  RegleRetenue._();

  factory RegleRetenue([void updates(RegleRetenueBuilder b)]) = _$RegleRetenue;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegleRetenueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegleRetenue> get serializer => _$RegleRetenueSerializer();
}

class _$RegleRetenueSerializer implements PrimitiveSerializer<RegleRetenue> {
  @override
  final Iterable<Type> types = const [RegleRetenue, _$RegleRetenue];

  @override
  final String wireName = r'RegleRetenue';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegleRetenue object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'priorite';
    yield serializers.serialize(
      object.priorite,
      specifiedType: const FullType(int),
    );
    yield r'regle_id';
    yield serializers.serialize(
      object.regleId,
      specifiedType: const FullType(String),
    );
    yield r'transport_slug';
    yield serializers.serialize(
      object.transportSlug,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegleRetenue object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegleRetenueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'priorite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.priorite = valueDes;
          break;
        case r'regle_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.regleId = valueDes;
          break;
        case r'transport_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.transportSlug = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegleRetenue deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegleRetenueBuilder();
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

