//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'modifier_prestataire_dto.g.dart';

/// Modification partielle de la fiche.
///
/// Properties:
/// * [contactTelephone] - Nouveau contact.
/// * [delaiPreparationMin] - Nouveau délai (minutes).
/// * [nom] - Nouveau nom.
@BuiltValue()
abstract class ModifierPrestataireDto implements Built<ModifierPrestataireDto, ModifierPrestataireDtoBuilder> {
  /// Nouveau contact.
  @BuiltValueField(wireName: r'contact_telephone')
  String? get contactTelephone;

  /// Nouveau délai (minutes).
  @BuiltValueField(wireName: r'delai_preparation_min')
  int? get delaiPreparationMin;

  /// Nouveau nom.
  @BuiltValueField(wireName: r'nom')
  String? get nom;

  ModifierPrestataireDto._();

  factory ModifierPrestataireDto([void updates(ModifierPrestataireDtoBuilder b)]) = _$ModifierPrestataireDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ModifierPrestataireDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ModifierPrestataireDto> get serializer => _$ModifierPrestataireDtoSerializer();
}

class _$ModifierPrestataireDtoSerializer implements PrimitiveSerializer<ModifierPrestataireDto> {
  @override
  final Iterable<Type> types = const [ModifierPrestataireDto, _$ModifierPrestataireDto];

  @override
  final String wireName = r'ModifierPrestataireDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ModifierPrestataireDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.contactTelephone != null) {
      yield r'contact_telephone';
      yield serializers.serialize(
        object.contactTelephone,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.delaiPreparationMin != null) {
      yield r'delai_preparation_min';
      yield serializers.serialize(
        object.delaiPreparationMin,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.nom != null) {
      yield r'nom';
      yield serializers.serialize(
        object.nom,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ModifierPrestataireDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ModifierPrestataireDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'contact_telephone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.contactTelephone = valueDes;
          break;
        case r'delai_preparation_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.delaiPreparationMin = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nom = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ModifierPrestataireDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ModifierPrestataireDtoBuilder();
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

