//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'creer_prestataire_dto.g.dart';

/// Création d'une fiche (statut initial : prospect).
///
/// Properties:
/// * [categorieSlug] - Slug de la catégorie de service (référentiel ZON).
/// * [contactTelephone] - Contact téléphonique (servi à l'admin seulement).
/// * [delaiPreparationMin] - Délai de préparation moyen déclaré (minutes).
/// * [nom] - Nom public.
/// * [villeId] - Ville de rattachement — type `ville` exigé (FR-002).
@BuiltValue()
abstract class CreerPrestataireDto implements Built<CreerPrestataireDto, CreerPrestataireDtoBuilder> {
  /// Slug de la catégorie de service (référentiel ZON).
  @BuiltValueField(wireName: r'categorie_slug')
  String get categorieSlug;

  /// Contact téléphonique (servi à l'admin seulement).
  @BuiltValueField(wireName: r'contact_telephone')
  String get contactTelephone;

  /// Délai de préparation moyen déclaré (minutes).
  @BuiltValueField(wireName: r'delai_preparation_min')
  int get delaiPreparationMin;

  /// Nom public.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Ville de rattachement — type `ville` exigé (FR-002).
  @BuiltValueField(wireName: r'ville_id')
  String get villeId;

  CreerPrestataireDto._();

  factory CreerPrestataireDto([void updates(CreerPrestataireDtoBuilder b)]) = _$CreerPrestataireDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreerPrestataireDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreerPrestataireDto> get serializer => _$CreerPrestataireDtoSerializer();
}

class _$CreerPrestataireDtoSerializer implements PrimitiveSerializer<CreerPrestataireDto> {
  @override
  final Iterable<Type> types = const [CreerPrestataireDto, _$CreerPrestataireDto];

  @override
  final String wireName = r'CreerPrestataireDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreerPrestataireDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categorie_slug';
    yield serializers.serialize(
      object.categorieSlug,
      specifiedType: const FullType(String),
    );
    yield r'contact_telephone';
    yield serializers.serialize(
      object.contactTelephone,
      specifiedType: const FullType(String),
    );
    yield r'delai_preparation_min';
    yield serializers.serialize(
      object.delaiPreparationMin,
      specifiedType: const FullType(int),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'ville_id';
    yield serializers.serialize(
      object.villeId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreerPrestataireDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreerPrestataireDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categorie_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.categorieSlug = valueDes;
          break;
        case r'contact_telephone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contactTelephone = valueDes;
          break;
        case r'delai_preparation_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.delaiPreparationMin = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'ville_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.villeId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreerPrestataireDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreerPrestataireDtoBuilder();
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

