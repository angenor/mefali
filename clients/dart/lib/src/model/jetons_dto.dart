//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'jetons_dto.g.dart';

/// Paire de jetons (contrat).
///
/// Properties:
/// * [acces] - JWT HS256, 15 min (claims sub/sid).
/// * [rafraichissement] - Opaque 256 bits — tourne à chaque usage.
@BuiltValue()
abstract class JetonsDto implements Built<JetonsDto, JetonsDtoBuilder> {
  /// JWT HS256, 15 min (claims sub/sid).
  @BuiltValueField(wireName: r'acces')
  String get acces;

  /// Opaque 256 bits — tourne à chaque usage.
  @BuiltValueField(wireName: r'rafraichissement')
  String get rafraichissement;

  JetonsDto._();

  factory JetonsDto([void updates(JetonsDtoBuilder b)]) = _$JetonsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JetonsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JetonsDto> get serializer => _$JetonsDtoSerializer();
}

class _$JetonsDtoSerializer implements PrimitiveSerializer<JetonsDto> {
  @override
  final Iterable<Type> types = const [JetonsDto, _$JetonsDto];

  @override
  final String wireName = r'JetonsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JetonsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'acces';
    yield serializers.serialize(
      object.acces,
      specifiedType: const FullType(String),
    );
    yield r'rafraichissement';
    yield serializers.serialize(
      object.rafraichissement,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    JetonsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JetonsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'acces':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.acces = valueDes;
          break;
        case r'rafraichissement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rafraichissement = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JetonsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JetonsDtoBuilder();
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

