//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/groupe_vendeur.dart';
import 'package:mefali_api_client/src/model/paiement_panier.dart';
import 'package:mefali_api_client/src/model/scission_proposee.dart';
import 'package:mefali_api_client/src/model/devis_livraison.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'devis_panier.g.dart';

/// Réponse du devis de panier.
///
/// Properties:
/// * [devis] - Devis de livraison.
/// * [devise] - Devise ISO 4217.
/// * [groupes] - Regroupement par vendeur.
/// * [montantArticlesUnites] - Montant des ARTICLES seuls (unités mineures).
/// * [paiement] - Décision d'encaissement.
/// * [scission] - Proposition de scission, ou `null`.
/// * [totalUnites] - Total à payer = articles + prix client du devis.
@BuiltValue()
abstract class DevisPanier implements Built<DevisPanier, DevisPanierBuilder> {
  /// Devis de livraison.
  @BuiltValueField(wireName: r'devis')
  DevisLivraison get devis;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Regroupement par vendeur.
  @BuiltValueField(wireName: r'groupes')
  BuiltList<GroupeVendeur> get groupes;

  /// Montant des ARTICLES seuls (unités mineures).
  @BuiltValueField(wireName: r'montant_articles_unites')
  int get montantArticlesUnites;

  /// Décision d'encaissement.
  @BuiltValueField(wireName: r'paiement')
  PaiementPanier get paiement;

  /// Proposition de scission, ou `null`.
  @BuiltValueField(wireName: r'scission')
  ScissionProposee? get scission;

  /// Total à payer = articles + prix client du devis.
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  DevisPanier._();

  factory DevisPanier([void updates(DevisPanierBuilder b)]) = _$DevisPanier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DevisPanierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DevisPanier> get serializer => _$DevisPanierSerializer();
}

class _$DevisPanierSerializer implements PrimitiveSerializer<DevisPanier> {
  @override
  final Iterable<Type> types = const [DevisPanier, _$DevisPanier];

  @override
  final String wireName = r'DevisPanier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DevisPanier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'devis';
    yield serializers.serialize(
      object.devis,
      specifiedType: const FullType(DevisLivraison),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'groupes';
    yield serializers.serialize(
      object.groupes,
      specifiedType: const FullType(BuiltList, [FullType(GroupeVendeur)]),
    );
    yield r'montant_articles_unites';
    yield serializers.serialize(
      object.montantArticlesUnites,
      specifiedType: const FullType(int),
    );
    yield r'paiement';
    yield serializers.serialize(
      object.paiement,
      specifiedType: const FullType(PaiementPanier),
    );
    if (object.scission != null) {
      yield r'scission';
      yield serializers.serialize(
        object.scission,
        specifiedType: const FullType.nullable(ScissionProposee),
      );
    }
    yield r'total_unites';
    yield serializers.serialize(
      object.totalUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DevisPanier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DevisPanierBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'devis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DevisLivraison),
          ) as DevisLivraison;
          result.devis.replace(valueDes);
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'groupes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GroupeVendeur)]),
          ) as BuiltList<GroupeVendeur>;
          result.groupes.replace(valueDes);
          break;
        case r'montant_articles_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantArticlesUnites = valueDes;
          break;
        case r'paiement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PaiementPanier),
          ) as PaiementPanier;
          result.paiement.replace(valueDes);
          break;
        case r'scission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ScissionProposee),
          ) as ScissionProposee?;
          if (valueDes == null) continue;
          result.scission.replace(valueDes);
          break;
        case r'total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DevisPanier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DevisPanierBuilder();
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

