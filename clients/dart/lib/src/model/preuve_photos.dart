//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'preuve_photos.g.dart';

/// Preuve « photo » (FR-056).
///
/// Properties:
/// * [faites] - Photos déposées.
/// * [ok] - Preuve réunie.
/// * [requis] - Photos exigées.
@BuiltValue()
abstract class PreuvePhotos implements Built<PreuvePhotos, PreuvePhotosBuilder> {
  /// Photos déposées.
  @BuiltValueField(wireName: r'faites')
  int get faites;

  /// Preuve réunie.
  @BuiltValueField(wireName: r'ok')
  bool get ok;

  /// Photos exigées.
  @BuiltValueField(wireName: r'requis')
  int get requis;

  PreuvePhotos._();

  factory PreuvePhotos([void updates(PreuvePhotosBuilder b)]) = _$PreuvePhotos;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PreuvePhotosBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PreuvePhotos> get serializer => _$PreuvePhotosSerializer();
}

class _$PreuvePhotosSerializer implements PrimitiveSerializer<PreuvePhotos> {
  @override
  final Iterable<Type> types = const [PreuvePhotos, _$PreuvePhotos];

  @override
  final String wireName = r'PreuvePhotos';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PreuvePhotos object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'faites';
    yield serializers.serialize(
      object.faites,
      specifiedType: const FullType(int),
    );
    yield r'ok';
    yield serializers.serialize(
      object.ok,
      specifiedType: const FullType(bool),
    );
    yield r'requis';
    yield serializers.serialize(
      object.requis,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PreuvePhotos object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PreuvePhotosBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'faites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.faites = valueDes;
          break;
        case r'ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ok = valueDes;
          break;
        case r'requis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.requis = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PreuvePhotos deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PreuvePhotosBuilder();
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

