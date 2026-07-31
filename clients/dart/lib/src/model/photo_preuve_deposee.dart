//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'photo_preuve_deposee.g.dart';

/// Ce que le serveur rend après le dépôt d'une photo de preuve.
///
/// Properties:
/// * [photoId] - Photo enregistrée.
/// * [photos] - Photos de preuve de cette livraison après dépôt.
/// * [rejeu] - `true` si la photo existait déjà (rejeu de la file) — rien n'a été redéposé.
@BuiltValue()
abstract class PhotoPreuveDeposee implements Built<PhotoPreuveDeposee, PhotoPreuveDeposeeBuilder> {
  /// Photo enregistrée.
  @BuiltValueField(wireName: r'photo_id')
  String get photoId;

  /// Photos de preuve de cette livraison après dépôt.
  @BuiltValueField(wireName: r'photos')
  int get photos;

  /// `true` si la photo existait déjà (rejeu de la file) — rien n'a été redéposé.
  @BuiltValueField(wireName: r'rejeu')
  bool get rejeu;

  PhotoPreuveDeposee._();

  factory PhotoPreuveDeposee([void updates(PhotoPreuveDeposeeBuilder b)]) = _$PhotoPreuveDeposee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PhotoPreuveDeposeeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PhotoPreuveDeposee> get serializer => _$PhotoPreuveDeposeeSerializer();
}

class _$PhotoPreuveDeposeeSerializer implements PrimitiveSerializer<PhotoPreuveDeposee> {
  @override
  final Iterable<Type> types = const [PhotoPreuveDeposee, _$PhotoPreuveDeposee];

  @override
  final String wireName = r'PhotoPreuveDeposee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PhotoPreuveDeposee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'photo_id';
    yield serializers.serialize(
      object.photoId,
      specifiedType: const FullType(String),
    );
    yield r'photos';
    yield serializers.serialize(
      object.photos,
      specifiedType: const FullType(int),
    );
    yield r'rejeu';
    yield serializers.serialize(
      object.rejeu,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PhotoPreuveDeposee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PhotoPreuveDeposeeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'photo_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.photoId = valueDes;
          break;
        case r'photos':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.photos = valueDes;
          break;
        case r'rejeu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.rejeu = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PhotoPreuveDeposee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PhotoPreuveDeposeeBuilder();
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

