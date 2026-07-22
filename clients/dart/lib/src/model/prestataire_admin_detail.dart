//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/charte_admin_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/photo_admin_dto.dart';
import 'package:mefali_api_client/src/model/statut_prestataire.dart';
import 'package:mefali_api_client/src/model/site_admin_vue_dto.dart';
import 'package:mefali_api_client/src/model/rattachement_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'prestataire_admin_detail.g.dart';

/// Fiche COMPLÈTE, vue admin.
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
/// * [chartes] - Chartes déposées, la plus récente d'abord.
/// * [codeSecours] - Code de secours — AUCUNE recherche par ce code n'existe (FR-014).
/// * [jetonPlaque] - Jeton de plaque (posé au premier agrément, stable — FR-013).
/// * [photos] - Photos présignées.
/// * [rattachements] - Comptes rattachés.
/// * [site] - LE site unique, s'il est créé.
/// * [statutDecideLe] - Horodatage de la dernière décision.
/// * [statutDecidePar] - Auteur de la dernière décision de cycle de vie.
/// * [statutMotif] - Motif de la dernière décision (suspension).
@BuiltValue()
abstract class PrestataireAdminDetail implements Built<PrestataireAdminDetail, PrestataireAdminDetailBuilder> {
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

  /// Chartes déposées, la plus récente d'abord.
  @BuiltValueField(wireName: r'chartes')
  BuiltList<CharteAdminDto> get chartes;

  /// Code de secours — AUCUNE recherche par ce code n'existe (FR-014).
  @BuiltValueField(wireName: r'code_secours')
  String? get codeSecours;

  /// Jeton de plaque (posé au premier agrément, stable — FR-013).
  @BuiltValueField(wireName: r'jeton_plaque')
  String? get jetonPlaque;

  /// Photos présignées.
  @BuiltValueField(wireName: r'photos')
  BuiltList<PhotoAdminDto> get photos;

  /// Comptes rattachés.
  @BuiltValueField(wireName: r'rattachements')
  BuiltList<RattachementDto> get rattachements;

  /// LE site unique, s'il est créé.
  @BuiltValueField(wireName: r'site')
  SiteAdminVueDto? get site;

  /// Horodatage de la dernière décision.
  @BuiltValueField(wireName: r'statut_decide_le')
  DateTime? get statutDecideLe;

  /// Auteur de la dernière décision de cycle de vie.
  @BuiltValueField(wireName: r'statut_decide_par')
  String? get statutDecidePar;

  /// Motif de la dernière décision (suspension).
  @BuiltValueField(wireName: r'statut_motif')
  String? get statutMotif;

  PrestataireAdminDetail._();

  factory PrestataireAdminDetail([void updates(PrestataireAdminDetailBuilder b)]) = _$PrestataireAdminDetail;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrestataireAdminDetailBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PrestataireAdminDetail> get serializer => _$PrestataireAdminDetailSerializer();
}

class _$PrestataireAdminDetailSerializer implements PrimitiveSerializer<PrestataireAdminDetail> {
  @override
  final Iterable<Type> types = const [PrestataireAdminDetail, _$PrestataireAdminDetail];

  @override
  final String wireName = r'PrestataireAdminDetail';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrestataireAdminDetail object, {
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
    yield r'chartes';
    yield serializers.serialize(
      object.chartes,
      specifiedType: const FullType(BuiltList, [FullType(CharteAdminDto)]),
    );
    if (object.codeSecours != null) {
      yield r'code_secours';
      yield serializers.serialize(
        object.codeSecours,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jetonPlaque != null) {
      yield r'jeton_plaque';
      yield serializers.serialize(
        object.jetonPlaque,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'photos';
    yield serializers.serialize(
      object.photos,
      specifiedType: const FullType(BuiltList, [FullType(PhotoAdminDto)]),
    );
    yield r'rattachements';
    yield serializers.serialize(
      object.rattachements,
      specifiedType: const FullType(BuiltList, [FullType(RattachementDto)]),
    );
    if (object.site != null) {
      yield r'site';
      yield serializers.serialize(
        object.site,
        specifiedType: const FullType.nullable(SiteAdminVueDto),
      );
    }
    if (object.statutDecideLe != null) {
      yield r'statut_decide_le';
      yield serializers.serialize(
        object.statutDecideLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.statutDecidePar != null) {
      yield r'statut_decide_par';
      yield serializers.serialize(
        object.statutDecidePar,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.statutMotif != null) {
      yield r'statut_motif';
      yield serializers.serialize(
        object.statutMotif,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PrestataireAdminDetail object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PrestataireAdminDetailBuilder result,
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
        case r'chartes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CharteAdminDto)]),
          ) as BuiltList<CharteAdminDto>;
          result.chartes.replace(valueDes);
          break;
        case r'code_secours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.codeSecours = valueDes;
          break;
        case r'jeton_plaque':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jetonPlaque = valueDes;
          break;
        case r'photos':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PhotoAdminDto)]),
          ) as BuiltList<PhotoAdminDto>;
          result.photos.replace(valueDes);
          break;
        case r'rattachements':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RattachementDto)]),
          ) as BuiltList<RattachementDto>;
          result.rattachements.replace(valueDes);
          break;
        case r'site':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SiteAdminVueDto),
          ) as SiteAdminVueDto?;
          if (valueDes == null) continue;
          result.site.replace(valueDes);
          break;
        case r'statut_decide_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.statutDecideLe = valueDes;
          break;
        case r'statut_decide_par':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.statutDecidePar = valueDes;
          break;
        case r'statut_motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.statutMotif = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PrestataireAdminDetail deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrestataireAdminDetailBuilder();
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

