//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/source_bascule.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'article_vendeur.g.dart';

/// Article du catalogue de PILOTAGE (écran V2) : ruptures, retirés et verrou admin visibles — contrairement à la consultation publique.
///
/// Properties:
/// * [categorieInterne] - Étiquette libre de regroupement.
/// * [devise] - Code ISO 4217 (posé par le serveur — R13).
/// * [disponible] - Faux = rupture.
/// * [id] - Identifiant.
/// * [nom] - Nom.
/// * [photoUrl] - URL présignée de la photo (TTL 10 min).
/// * [prixBarreUnites] - Prix barré (strictement supérieur — FR-023).
/// * [prixUnites] - Prix courant, entier en unités mineures.
/// * [retire] - Retiré du catalogue — remise possible sans ressaisie (FR-055).
/// * [ruptureAdmin] - Rupture posée par l'Admin — la bascule vendeur sera refusée (FR-041).
/// * [sourceDerniereBascule] - Source de la dernière bascule (FR-037).
@BuiltValue()
abstract class ArticleVendeur implements Built<ArticleVendeur, ArticleVendeurBuilder> {
  /// Étiquette libre de regroupement.
  @BuiltValueField(wireName: r'categorie_interne')
  String? get categorieInterne;

  /// Code ISO 4217 (posé par le serveur — R13).
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Faux = rupture.
  @BuiltValueField(wireName: r'disponible')
  bool get disponible;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nom.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// URL présignée de la photo (TTL 10 min).
  @BuiltValueField(wireName: r'photo_url')
  String? get photoUrl;

  /// Prix barré (strictement supérieur — FR-023).
  @BuiltValueField(wireName: r'prix_barre_unites')
  int? get prixBarreUnites;

  /// Prix courant, entier en unités mineures.
  @BuiltValueField(wireName: r'prix_unites')
  int get prixUnites;

  /// Retiré du catalogue — remise possible sans ressaisie (FR-055).
  @BuiltValueField(wireName: r'retire')
  bool get retire;

  /// Rupture posée par l'Admin — la bascule vendeur sera refusée (FR-041).
  @BuiltValueField(wireName: r'rupture_admin')
  bool get ruptureAdmin;

  /// Source de la dernière bascule (FR-037).
  @BuiltValueField(wireName: r'source_derniere_bascule')
  SourceBascule? get sourceDerniereBascule;
  // enum sourceDerniereBasculeEnum {  vendeur,  coursier,  admin,  };

  ArticleVendeur._();

  factory ArticleVendeur([void updates(ArticleVendeurBuilder b)]) = _$ArticleVendeur;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ArticleVendeurBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ArticleVendeur> get serializer => _$ArticleVendeurSerializer();
}

class _$ArticleVendeurSerializer implements PrimitiveSerializer<ArticleVendeur> {
  @override
  final Iterable<Type> types = const [ArticleVendeur, _$ArticleVendeur];

  @override
  final String wireName = r'ArticleVendeur';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ArticleVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.categorieInterne != null) {
      yield r'categorie_interne';
      yield serializers.serialize(
        object.categorieInterne,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'disponible';
    yield serializers.serialize(
      object.disponible,
      specifiedType: const FullType(bool),
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
    if (object.photoUrl != null) {
      yield r'photo_url';
      yield serializers.serialize(
        object.photoUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.prixBarreUnites != null) {
      yield r'prix_barre_unites';
      yield serializers.serialize(
        object.prixBarreUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'prix_unites';
    yield serializers.serialize(
      object.prixUnites,
      specifiedType: const FullType(int),
    );
    yield r'retire';
    yield serializers.serialize(
      object.retire,
      specifiedType: const FullType(bool),
    );
    yield r'rupture_admin';
    yield serializers.serialize(
      object.ruptureAdmin,
      specifiedType: const FullType(bool),
    );
    if (object.sourceDerniereBascule != null) {
      yield r'source_derniere_bascule';
      yield serializers.serialize(
        object.sourceDerniereBascule,
        specifiedType: const FullType.nullable(SourceBascule),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ArticleVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ArticleVendeurBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categorie_interne':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categorieInterne = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'disponible':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.disponible = valueDes;
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
        case r'photo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.photoUrl = valueDes;
          break;
        case r'prix_barre_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.prixBarreUnites = valueDes;
          break;
        case r'prix_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixUnites = valueDes;
          break;
        case r'retire':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.retire = valueDes;
          break;
        case r'rupture_admin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ruptureAdmin = valueDes;
          break;
        case r'source_derniere_bascule':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SourceBascule),
          ) as SourceBascule?;
          if (valueDes == null) continue;
          result.sourceDerniereBascule = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ArticleVendeur deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ArticleVendeurBuilder();
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

