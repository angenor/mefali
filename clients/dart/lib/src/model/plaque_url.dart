//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plaque_url.g.dart';

/// URL présignée de téléchargement du PDF de plaque (TTL 10 min).
///
/// Properties:
/// * [expireLe] - Expiration de l'URL.
/// * [url] - URL présignée de lecture.
@BuiltValue()
abstract class PlaqueUrl implements Built<PlaqueUrl, PlaqueUrlBuilder> {
  /// Expiration de l'URL.
  @BuiltValueField(wireName: r'expire_le')
  DateTime get expireLe;

  /// URL présignée de lecture.
  @BuiltValueField(wireName: r'url')
  String get url;

  PlaqueUrl._();

  factory PlaqueUrl([void updates(PlaqueUrlBuilder b)]) = _$PlaqueUrl;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlaqueUrlBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlaqueUrl> get serializer => _$PlaqueUrlSerializer();
}

class _$PlaqueUrlSerializer implements PrimitiveSerializer<PlaqueUrl> {
  @override
  final Iterable<Type> types = const [PlaqueUrl, _$PlaqueUrl];

  @override
  final String wireName = r'PlaqueUrl';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlaqueUrl object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'expire_le';
    yield serializers.serialize(
      object.expireLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlaqueUrl object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlaqueUrlBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'expire_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.expireLe = valueDes;
          break;
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlaqueUrl deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlaqueUrlBuilder();
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

