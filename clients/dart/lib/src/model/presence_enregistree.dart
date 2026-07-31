//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'presence_enregistree.g.dart';

/// Ce que le serveur rend après avoir enregistré un lot de présence.
///
/// Properties:
/// * [presenceS] - Présence **recalculée par le serveur**, en secondes (FR-060).
/// * [requisS] - Durée exigée par la zone.
/// * [retenus] - Relevés du lot connus du serveur — identique au rejeu (constitution V).
@BuiltValue()
abstract class PresenceEnregistree implements Built<PresenceEnregistree, PresenceEnregistreeBuilder> {
  /// Présence **recalculée par le serveur**, en secondes (FR-060).
  @BuiltValueField(wireName: r'presence_s')
  int get presenceS;

  /// Durée exigée par la zone.
  @BuiltValueField(wireName: r'requis_s')
  int get requisS;

  /// Relevés du lot connus du serveur — identique au rejeu (constitution V).
  @BuiltValueField(wireName: r'retenus')
  int get retenus;

  PresenceEnregistree._();

  factory PresenceEnregistree([void updates(PresenceEnregistreeBuilder b)]) = _$PresenceEnregistree;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PresenceEnregistreeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PresenceEnregistree> get serializer => _$PresenceEnregistreeSerializer();
}

class _$PresenceEnregistreeSerializer implements PrimitiveSerializer<PresenceEnregistree> {
  @override
  final Iterable<Type> types = const [PresenceEnregistree, _$PresenceEnregistree];

  @override
  final String wireName = r'PresenceEnregistree';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PresenceEnregistree object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'presence_s';
    yield serializers.serialize(
      object.presenceS,
      specifiedType: const FullType(int),
    );
    yield r'requis_s';
    yield serializers.serialize(
      object.requisS,
      specifiedType: const FullType(int),
    );
    yield r'retenus';
    yield serializers.serialize(
      object.retenus,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PresenceEnregistree object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PresenceEnregistreeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'presence_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.presenceS = valueDes;
          break;
        case r'requis_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.requisS = valueDes;
          break;
        case r'retenus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.retenus = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PresenceEnregistree deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PresenceEnregistreeBuilder();
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

