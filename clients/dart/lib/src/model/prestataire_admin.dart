//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/statut_prestataire.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'prestataire_admin.g.dart';

/// Résumé admin d'un prestataire.
///
/// Properties:
/// * [categorie] - Slug de la catégorie de service.
/// * [commandable] - FR-028, dérivé à la lecture.
/// * [contactTelephone] - Contact téléphonique — surface ADMIN uniquement.
/// * [delaiPreparationMin] - Délai de préparation (minutes).
/// * [id] - Identifiant.
/// * [nom] - Nom public.
/// * [statut] - Cycle de vie.
/// * [villeId] - Ville de rattachement.
@BuiltValue()
abstract class PrestataireAdmin implements Built<PrestataireAdmin, PrestataireAdminBuilder> {
  /// Slug de la catégorie de service.
  @BuiltValueField(wireName: r'categorie')
  String get categorie;

  /// FR-028, dérivé à la lecture.
  @BuiltValueField(wireName: r'commandable')
  bool get commandable;

  /// Contact téléphonique — surface ADMIN uniquement.
  @BuiltValueField(wireName: r'contact_telephone')
  String get contactTelephone;

  /// Délai de préparation (minutes).
  @BuiltValueField(wireName: r'delai_preparation_min')
  int get delaiPreparationMin;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nom public.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Cycle de vie.
  @BuiltValueField(wireName: r'statut')
  StatutPrestataire get statut;
  // enum statutEnum {  prospect,  agree,  suspendu,  };

  /// Ville de rattachement.
  @BuiltValueField(wireName: r'ville_id')
  String get villeId;

  PrestataireAdmin._();

  factory PrestataireAdmin([void updates(PrestataireAdminBuilder b)]) = _$PrestataireAdmin;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrestataireAdminBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PrestataireAdmin> get serializer => _$PrestataireAdminSerializer();
}

class _$PrestataireAdminSerializer implements PrimitiveSerializer<PrestataireAdmin> {
  @override
  final Iterable<Type> types = const [PrestataireAdmin, _$PrestataireAdmin];

  @override
  final String wireName = r'PrestataireAdmin';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrestataireAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categorie';
    yield serializers.serialize(
      object.categorie,
      specifiedType: const FullType(String),
    );
    yield r'commandable';
    yield serializers.serialize(
      object.commandable,
      specifiedType: const FullType(bool),
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
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(StatutPrestataire),
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
    PrestataireAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PrestataireAdminBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categorie':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.categorie = valueDes;
          break;
        case r'commandable':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.commandable = valueDes;
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatutPrestataire),
          ) as StatutPrestataire;
          result.statut = valueDes;
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
  PrestataireAdmin deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrestataireAdminBuilder();
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

