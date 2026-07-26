//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'intention_appel.g.dart';

/// Motif d'une intention d'appel.
///
/// Properties:
/// * [motif] - `suivi` (défaut) | `substitution` | `expiration`.
@BuiltValue()
abstract class IntentionAppel implements Built<IntentionAppel, IntentionAppelBuilder> {
  /// `suivi` (défaut) | `substitution` | `expiration`.
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  IntentionAppel._();

  factory IntentionAppel([void updates(IntentionAppelBuilder b)]) = _$IntentionAppel;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IntentionAppelBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IntentionAppel> get serializer => _$IntentionAppelSerializer();
}

class _$IntentionAppelSerializer implements PrimitiveSerializer<IntentionAppel> {
  @override
  final Iterable<Type> types = const [IntentionAppel, _$IntentionAppel];

  @override
  final String wireName = r'IntentionAppel';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IntentionAppel object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    IntentionAppel object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IntentionAppelBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motif = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IntentionAppel deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IntentionAppelBuilder();
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

