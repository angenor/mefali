//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/lieu.dart';
import 'package:mefali_api_client/src/model/ligne_panier.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_creation_commande.g.dart';

/// Demande de création de commande.
///
/// Properties:
/// * [adresseId] - Adresse du carnet (CPT-05) — ou `lieu` + repère fournis en clair.
/// * [categorieSlug] - Catégorie de service.
/// * [lieu] - Pin GPS, si aucune adresse du carnet n'est utilisée.
/// * [lignes] - Lignes du panier.
/// * [modePaiement] - `cash` | `mobile_money`.
/// * [repereTexte] - Repère écrit.
/// * [repereVocalCle] - Clé S3 du repère vocal.
/// * [transportSlug] - Véhicule demandé.
/// * [zoneId] - Zone de la commande.
@BuiltValue()
abstract class DemandeCreationCommande implements Built<DemandeCreationCommande, DemandeCreationCommandeBuilder> {
  /// Adresse du carnet (CPT-05) — ou `lieu` + repère fournis en clair.
  @BuiltValueField(wireName: r'adresse_id')
  String? get adresseId;

  /// Catégorie de service.
  @BuiltValueField(wireName: r'categorie_slug')
  String get categorieSlug;

  /// Pin GPS, si aucune adresse du carnet n'est utilisée.
  @BuiltValueField(wireName: r'lieu')
  Lieu? get lieu;

  /// Lignes du panier.
  @BuiltValueField(wireName: r'lignes')
  BuiltList<LignePanier> get lignes;

  /// `cash` | `mobile_money`.
  @BuiltValueField(wireName: r'mode_paiement')
  String get modePaiement;

  /// Repère écrit.
  @BuiltValueField(wireName: r'repere_texte')
  String? get repereTexte;

  /// Clé S3 du repère vocal.
  @BuiltValueField(wireName: r'repere_vocal_cle')
  String? get repereVocalCle;

  /// Véhicule demandé.
  @BuiltValueField(wireName: r'transport_slug')
  String get transportSlug;

  /// Zone de la commande.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  DemandeCreationCommande._();

  factory DemandeCreationCommande([void updates(DemandeCreationCommandeBuilder b)]) = _$DemandeCreationCommande;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeCreationCommandeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeCreationCommande> get serializer => _$DemandeCreationCommandeSerializer();
}

class _$DemandeCreationCommandeSerializer implements PrimitiveSerializer<DemandeCreationCommande> {
  @override
  final Iterable<Type> types = const [DemandeCreationCommande, _$DemandeCreationCommande];

  @override
  final String wireName = r'DemandeCreationCommande';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeCreationCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.adresseId != null) {
      yield r'adresse_id';
      yield serializers.serialize(
        object.adresseId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'categorie_slug';
    yield serializers.serialize(
      object.categorieSlug,
      specifiedType: const FullType(String),
    );
    if (object.lieu != null) {
      yield r'lieu';
      yield serializers.serialize(
        object.lieu,
        specifiedType: const FullType.nullable(Lieu),
      );
    }
    yield r'lignes';
    yield serializers.serialize(
      object.lignes,
      specifiedType: const FullType(BuiltList, [FullType(LignePanier)]),
    );
    yield r'mode_paiement';
    yield serializers.serialize(
      object.modePaiement,
      specifiedType: const FullType(String),
    );
    if (object.repereTexte != null) {
      yield r'repere_texte';
      yield serializers.serialize(
        object.repereTexte,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.repereVocalCle != null) {
      yield r'repere_vocal_cle';
      yield serializers.serialize(
        object.repereVocalCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'transport_slug';
    yield serializers.serialize(
      object.transportSlug,
      specifiedType: const FullType(String),
    );
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeCreationCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeCreationCommandeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'adresse_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.adresseId = valueDes;
          break;
        case r'categorie_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.categorieSlug = valueDes;
          break;
        case r'lieu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Lieu),
          ) as Lieu?;
          if (valueDes == null) continue;
          result.lieu.replace(valueDes);
          break;
        case r'lignes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LignePanier)]),
          ) as BuiltList<LignePanier>;
          result.lignes.replace(valueDes);
          break;
        case r'mode_paiement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.modePaiement = valueDes;
          break;
        case r'repere_texte':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.repereTexte = valueDes;
          break;
        case r'repere_vocal_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.repereVocalCle = valueDes;
          break;
        case r'transport_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.transportSlug = valueDes;
          break;
        case r'zone_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeCreationCommande deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeCreationCommandeBuilder();
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

