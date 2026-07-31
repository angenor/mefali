//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/releve_de_presence.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'lot_de_presence.g.dart';

/// Lot de relevés — la file peut en avoir accumulé plusieurs minutes.
///
/// Properties:
/// * [releves] - Les échantillons du lot.
@BuiltValue()
abstract class LotDePresence implements Built<LotDePresence, LotDePresenceBuilder> {
  /// Les échantillons du lot.
  @BuiltValueField(wireName: r'releves')
  BuiltList<ReleveDePresence> get releves;

  LotDePresence._();

  factory LotDePresence([void updates(LotDePresenceBuilder b)]) = _$LotDePresence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LotDePresenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LotDePresence> get serializer => _$LotDePresenceSerializer();
}

class _$LotDePresenceSerializer implements PrimitiveSerializer<LotDePresence> {
  @override
  final Iterable<Type> types = const [LotDePresence, _$LotDePresence];

  @override
  final String wireName = r'LotDePresence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LotDePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'releves';
    yield serializers.serialize(
      object.releves,
      specifiedType: const FullType(BuiltList, [FullType(ReleveDePresence)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LotDePresence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LotDePresenceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'releves':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ReleveDePresence)]),
          ) as BuiltList<ReleveDePresence>;
          result.releves.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LotDePresence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LotDePresenceBuilder();
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

