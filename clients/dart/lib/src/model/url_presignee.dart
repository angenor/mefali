//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'url_presignee.g.dart';

/// URL présignée de lecture (contrat).
///
/// Properties:
/// * [expireLe] - Expiration.
/// * [url] - URL opaque, à durée courte.
@BuiltValue()
abstract class UrlPresignee implements Built<UrlPresignee, UrlPresigneeBuilder> {
  /// Expiration.
  @BuiltValueField(wireName: r'expire_le')
  DateTime get expireLe;

  /// URL opaque, à durée courte.
  @BuiltValueField(wireName: r'url')
  String get url;

  UrlPresignee._();

  factory UrlPresignee([void updates(UrlPresigneeBuilder b)]) = _$UrlPresignee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UrlPresigneeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UrlPresignee> get serializer => _$UrlPresigneeSerializer();
}

class _$UrlPresigneeSerializer implements PrimitiveSerializer<UrlPresignee> {
  @override
  final Iterable<Type> types = const [UrlPresignee, _$UrlPresignee];

  @override
  final String wireName = r'UrlPresignee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UrlPresignee object, {
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
    UrlPresignee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UrlPresigneeBuilder result,
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
  UrlPresignee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UrlPresigneeBuilder();
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

