//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'charte_admin_dto.g.dart';

/// Charte signée, présignée pour l'admin (pièce contractuelle — FR-003).
///
/// Properties:
/// * [deposeeLe] - Dépôt du scan.
/// * [id] - Identifiant.
/// * [signeeLe] - Date de signature manuscrite.
/// * [url] - URL présignée de lecture (TTL 10 min).
/// * [versionCharte] - Version de charte en vigueur à la signature.
@BuiltValue()
abstract class CharteAdminDto implements Built<CharteAdminDto, CharteAdminDtoBuilder> {
  /// Dépôt du scan.
  @BuiltValueField(wireName: r'deposee_le')
  DateTime get deposeeLe;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Date de signature manuscrite.
  @BuiltValueField(wireName: r'signee_le')
  Date get signeeLe;

  /// URL présignée de lecture (TTL 10 min).
  @BuiltValueField(wireName: r'url')
  String get url;

  /// Version de charte en vigueur à la signature.
  @BuiltValueField(wireName: r'version_charte')
  String get versionCharte;

  CharteAdminDto._();

  factory CharteAdminDto([void updates(CharteAdminDtoBuilder b)]) = _$CharteAdminDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CharteAdminDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CharteAdminDto> get serializer => _$CharteAdminDtoSerializer();
}

class _$CharteAdminDtoSerializer implements PrimitiveSerializer<CharteAdminDto> {
  @override
  final Iterable<Type> types = const [CharteAdminDto, _$CharteAdminDto];

  @override
  final String wireName = r'CharteAdminDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CharteAdminDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'deposee_le';
    yield serializers.serialize(
      object.deposeeLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'signee_le';
    yield serializers.serialize(
      object.signeeLe,
      specifiedType: const FullType(Date),
    );
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
    yield r'version_charte';
    yield serializers.serialize(
      object.versionCharte,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CharteAdminDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CharteAdminDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'deposee_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deposeeLe = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'signee_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.signeeLe = valueDes;
          break;
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        case r'version_charte':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.versionCharte = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CharteAdminDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CharteAdminDtoBuilder();
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

