//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'photo_admin_dto.g.dart';

/// Photo de fiche, présignée pour l'admin.
///
/// Properties:
/// * [id] - Identifiant (pour la suppression).
/// * [position] - Ordre d'affichage.
/// * [url] - URL présignée (TTL 10 min).
@BuiltValue()
abstract class PhotoAdminDto implements Built<PhotoAdminDto, PhotoAdminDtoBuilder> {
  /// Identifiant (pour la suppression).
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Ordre d'affichage.
  @BuiltValueField(wireName: r'position')
  int get position;

  /// URL présignée (TTL 10 min).
  @BuiltValueField(wireName: r'url')
  String get url;

  PhotoAdminDto._();

  factory PhotoAdminDto([void updates(PhotoAdminDtoBuilder b)]) = _$PhotoAdminDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhotoAdminDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhotoAdminDto> get serializer => _$PhotoAdminDtoSerializer();
}

class _$PhotoAdminDtoSerializer implements PrimitiveSerializer<PhotoAdminDto> {
  @override
  final Iterable<Type> types = const [PhotoAdminDto, _$PhotoAdminDto];

  @override
  final String wireName = r'PhotoAdminDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhotoAdminDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'position';
    yield serializers.serialize(
      object.position,
      specifiedType: const FullType(int),
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
    PhotoAdminDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhotoAdminDtoBuilder result,
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
        case r'position':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.position = valueDes;
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
  PhotoAdminDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhotoAdminDtoBuilder();
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

