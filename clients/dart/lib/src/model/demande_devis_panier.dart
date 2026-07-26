//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/lieu.dart';
import 'package:mefali_api_client/src/model/ligne_panier.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_devis_panier.g.dart';

/// Demande de devis de panier — **aucun effet de bord** (P4).
///
/// Properties:
/// * [categorieSlug] - Catégorie de service (`marche`, `restauration`…).
/// * [lieu] - Lieu de prestation — destination de la course.
/// * [lignes] - Lignes du panier, dans l'ordre de composition.
/// * [transportSlug] - Véhicule demandé (`moto`, `velo`…).
/// * [zoneId] - Zone de la commande (résout mixage, plafonds, devise).
@BuiltValue()
abstract class DemandeDevisPanier implements Built<DemandeDevisPanier, DemandeDevisPanierBuilder> {
  /// Catégorie de service (`marche`, `restauration`…).
  @BuiltValueField(wireName: r'categorie_slug')
  String get categorieSlug;

  /// Lieu de prestation — destination de la course.
  @BuiltValueField(wireName: r'lieu')
  Lieu get lieu;

  /// Lignes du panier, dans l'ordre de composition.
  @BuiltValueField(wireName: r'lignes')
  BuiltList<LignePanier> get lignes;

  /// Véhicule demandé (`moto`, `velo`…).
  @BuiltValueField(wireName: r'transport_slug')
  String get transportSlug;

  /// Zone de la commande (résout mixage, plafonds, devise).
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  DemandeDevisPanier._();

  factory DemandeDevisPanier([void updates(DemandeDevisPanierBuilder b)]) = _$DemandeDevisPanier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeDevisPanierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeDevisPanier> get serializer => _$DemandeDevisPanierSerializer();
}

class _$DemandeDevisPanierSerializer implements PrimitiveSerializer<DemandeDevisPanier> {
  @override
  final Iterable<Type> types = const [DemandeDevisPanier, _$DemandeDevisPanier];

  @override
  final String wireName = r'DemandeDevisPanier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeDevisPanier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'categorie_slug';
    yield serializers.serialize(
      object.categorieSlug,
      specifiedType: const FullType(String),
    );
    yield r'lieu';
    yield serializers.serialize(
      object.lieu,
      specifiedType: const FullType(Lieu),
    );
    yield r'lignes';
    yield serializers.serialize(
      object.lignes,
      specifiedType: const FullType(BuiltList, [FullType(LignePanier)]),
    );
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
    DemandeDevisPanier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeDevisPanierBuilder result,
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
        case r'lieu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Lieu),
          ) as Lieu;
          result.lieu.replace(valueDes);
          break;
        case r'lignes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LignePanier)]),
          ) as BuiltList<LignePanier>;
          result.lignes.replace(valueDes);
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
  DemandeDevisPanier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeDevisPanierBuilder();
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

