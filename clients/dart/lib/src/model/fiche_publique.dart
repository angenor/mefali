//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/affichage_rupture.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/horaires_semaine_dto.dart';
import 'package:mefali_api_client/src/model/article_public.dart';
import 'package:mefali_api_client/src/model/etat_effectif_boutique.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fiche_publique.g.dart';

/// Fiche publique : le sous-ensemble EXACT de FR-027 — ni contact téléphonique, ni coordonnées de site, ni donnée d'exploitation (SC-013).
///
/// Properties:
/// * [affichageRupture] - Mode de rendu des ruptures, résolu pour la catégorie.
/// * [articles] - Catalogue servi (retirés absents ; ruptures selon le mode).
/// * [boutique] - État effectif de la boutique.
/// * [categorie] - Slug de la catégorie de service.
/// * [commandable] - FR-028 — la SEULE définition de « commandable ».
/// * [delaiPreparationMin] - Délai de préparation moyen déclaré (minutes).
/// * [horaires] - Horaires hebdomadaires.
/// * [id] - Identifiant du prestataire.
/// * [nom] - Nom public.
/// * [photos] - URLs présignées des photos de fiche.
@BuiltValue()
abstract class FichePublique implements Built<FichePublique, FichePubliqueBuilder> {
  /// Mode de rendu des ruptures, résolu pour la catégorie.
  @BuiltValueField(wireName: r'affichage_rupture')
  AffichageRupture get affichageRupture;
  // enum affichageRuptureEnum {  grise,  masque,  };

  /// Catalogue servi (retirés absents ; ruptures selon le mode).
  @BuiltValueField(wireName: r'articles')
  BuiltList<ArticlePublic> get articles;

  /// État effectif de la boutique.
  @BuiltValueField(wireName: r'boutique')
  EtatEffectifBoutique get boutique;

  /// Slug de la catégorie de service.
  @BuiltValueField(wireName: r'categorie')
  String get categorie;

  /// FR-028 — la SEULE définition de « commandable ».
  @BuiltValueField(wireName: r'commandable')
  bool get commandable;

  /// Délai de préparation moyen déclaré (minutes).
  @BuiltValueField(wireName: r'delai_preparation_min')
  int get delaiPreparationMin;

  /// Horaires hebdomadaires.
  @BuiltValueField(wireName: r'horaires')
  HorairesSemaineDto get horaires;

  /// Identifiant du prestataire.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nom public.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// URLs présignées des photos de fiche.
  @BuiltValueField(wireName: r'photos')
  BuiltList<String> get photos;

  FichePublique._();

  factory FichePublique([void updates(FichePubliqueBuilder b)]) = _$FichePublique;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FichePubliqueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FichePublique> get serializer => _$FichePubliqueSerializer();
}

class _$FichePubliqueSerializer implements PrimitiveSerializer<FichePublique> {
  @override
  final Iterable<Type> types = const [FichePublique, _$FichePublique];

  @override
  final String wireName = r'FichePublique';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FichePublique object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'affichage_rupture';
    yield serializers.serialize(
      object.affichageRupture,
      specifiedType: const FullType(AffichageRupture),
    );
    yield r'articles';
    yield serializers.serialize(
      object.articles,
      specifiedType: const FullType(BuiltList, [FullType(ArticlePublic)]),
    );
    yield r'boutique';
    yield serializers.serialize(
      object.boutique,
      specifiedType: const FullType(EtatEffectifBoutique),
    );
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
    yield r'delai_preparation_min';
    yield serializers.serialize(
      object.delaiPreparationMin,
      specifiedType: const FullType(int),
    );
    yield r'horaires';
    yield serializers.serialize(
      object.horaires,
      specifiedType: const FullType(HorairesSemaineDto),
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
    yield r'photos';
    yield serializers.serialize(
      object.photos,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FichePublique object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FichePubliqueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'affichage_rupture':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AffichageRupture),
          ) as AffichageRupture;
          result.affichageRupture = valueDes;
          break;
        case r'articles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ArticlePublic)]),
          ) as BuiltList<ArticlePublic>;
          result.articles.replace(valueDes);
          break;
        case r'boutique':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EtatEffectifBoutique),
          ) as EtatEffectifBoutique;
          result.boutique.replace(valueDes);
          break;
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
        case r'delai_preparation_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.delaiPreparationMin = valueDes;
          break;
        case r'horaires':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HorairesSemaineDto),
          ) as HorairesSemaineDto;
          result.horaires.replace(valueDes);
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
        case r'photos':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.photos.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FichePublique deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FichePubliqueBuilder();
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

