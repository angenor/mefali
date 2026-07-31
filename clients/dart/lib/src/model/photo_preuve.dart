//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'photo_preuve.g.dart';

/// Une photo de preuve, présignée.
///
/// Properties:
/// * [id] - Photo.
/// * [priseLe] - Prise le.
/// * [purgeeLe] - Purgée le — la preuve reste **datée**, ses octets sont partis.
/// * [url] - URL présignée de courte durée. Absente si purgée ou indisponible.
@BuiltValue()
abstract class PhotoPreuve implements Built<PhotoPreuve, PhotoPreuveBuilder> {
  /// Photo.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Prise le.
  @BuiltValueField(wireName: r'prise_le')
  DateTime get priseLe;

  /// Purgée le — la preuve reste **datée**, ses octets sont partis.
  @BuiltValueField(wireName: r'purgee_le')
  DateTime? get purgeeLe;

  /// URL présignée de courte durée. Absente si purgée ou indisponible.
  @BuiltValueField(wireName: r'url')
  String? get url;

  PhotoPreuve._();

  factory PhotoPreuve([void updates(PhotoPreuveBuilder b)]) = _$PhotoPreuve;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhotoPreuveBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhotoPreuve> get serializer => _$PhotoPreuveSerializer();
}

class _$PhotoPreuveSerializer implements PrimitiveSerializer<PhotoPreuve> {
  @override
  final Iterable<Type> types = const [PhotoPreuve, _$PhotoPreuve];

  @override
  final String wireName = r'PhotoPreuve';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhotoPreuve object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'prise_le';
    yield serializers.serialize(
      object.priseLe,
      specifiedType: const FullType(DateTime),
    );
    if (object.purgeeLe != null) {
      yield r'purgee_le';
      yield serializers.serialize(
        object.purgeeLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.url != null) {
      yield r'url';
      yield serializers.serialize(
        object.url,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PhotoPreuve object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhotoPreuveBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'prise_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.priseLe = valueDes;
          break;
        case r'purgee_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.purgeeLe = valueDes;
          break;
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  PhotoPreuve deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhotoPreuveBuilder();
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

