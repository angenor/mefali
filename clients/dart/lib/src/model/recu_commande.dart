//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/ligne_recu.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recu_commande.g.dart';

/// Reçu d'une commande, composé à la volée (aucune table — research R15).
///
/// Properties:
/// * [commandeId] - Commande.
/// * [dejaRegle] - La commande est-elle déjà réglée ? (FR-073)
/// * [devise] - Devise ISO 4217.
/// * [fraisLivraisonUnites] - Frais de livraison facturés.
/// * [lignes] - Lignes, **retirées comprises** : le reçu explique pourquoi le total a bougé plutôt que de le faire bouger en silence.
/// * [modePaiement] - `cash` | `mobile_money`.
/// * [montantARemettreAuCoursierUnites] - Ce qui reste à remettre au coursier — **0** sur une commande prépayée.
/// * [montantArticlesUnites] - Somme des lignes vivantes.
/// * [moyen] - Moyen employé — `null` tant que le fournisseur ne l'a pas dit (FR-012).
/// * [retenueVendeurUnites] - Part de frais prise en charge par le vendeur (VND-08), `0` sinon.
/// * [totalDuUnites] - Total dû, déjà ajusté par les retraits et les arrêts indisponibles.
@BuiltValue()
abstract class RecuCommande implements Built<RecuCommande, RecuCommandeBuilder> {
  /// Commande.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// La commande est-elle déjà réglée ? (FR-073)
  @BuiltValueField(wireName: r'deja_regle')
  bool get dejaRegle;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Frais de livraison facturés.
  @BuiltValueField(wireName: r'frais_livraison_unites')
  int get fraisLivraisonUnites;

  /// Lignes, **retirées comprises** : le reçu explique pourquoi le total a bougé plutôt que de le faire bouger en silence.
  @BuiltValueField(wireName: r'lignes')
  BuiltList<LigneRecu> get lignes;

  /// `cash` | `mobile_money`.
  @BuiltValueField(wireName: r'mode_paiement')
  String get modePaiement;

  /// Ce qui reste à remettre au coursier — **0** sur une commande prépayée.
  @BuiltValueField(wireName: r'montant_a_remettre_au_coursier_unites')
  int get montantARemettreAuCoursierUnites;

  /// Somme des lignes vivantes.
  @BuiltValueField(wireName: r'montant_articles_unites')
  int get montantArticlesUnites;

  /// Moyen employé — `null` tant que le fournisseur ne l'a pas dit (FR-012).
  @BuiltValueField(wireName: r'moyen')
  String? get moyen;

  /// Part de frais prise en charge par le vendeur (VND-08), `0` sinon.
  @BuiltValueField(wireName: r'retenue_vendeur_unites')
  int get retenueVendeurUnites;

  /// Total dû, déjà ajusté par les retraits et les arrêts indisponibles.
  @BuiltValueField(wireName: r'total_du_unites')
  int get totalDuUnites;

  RecuCommande._();

  factory RecuCommande([void updates(RecuCommandeBuilder b)]) = _$RecuCommande;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RecuCommandeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RecuCommande> get serializer => _$RecuCommandeSerializer();
}

class _$RecuCommandeSerializer implements PrimitiveSerializer<RecuCommande> {
  @override
  final Iterable<Type> types = const [RecuCommande, _$RecuCommande];

  @override
  final String wireName = r'RecuCommande';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RecuCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'deja_regle';
    yield serializers.serialize(
      object.dejaRegle,
      specifiedType: const FullType(bool),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'frais_livraison_unites';
    yield serializers.serialize(
      object.fraisLivraisonUnites,
      specifiedType: const FullType(int),
    );
    yield r'lignes';
    yield serializers.serialize(
      object.lignes,
      specifiedType: const FullType(BuiltList, [FullType(LigneRecu)]),
    );
    yield r'mode_paiement';
    yield serializers.serialize(
      object.modePaiement,
      specifiedType: const FullType(String),
    );
    yield r'montant_a_remettre_au_coursier_unites';
    yield serializers.serialize(
      object.montantARemettreAuCoursierUnites,
      specifiedType: const FullType(int),
    );
    yield r'montant_articles_unites';
    yield serializers.serialize(
      object.montantArticlesUnites,
      specifiedType: const FullType(int),
    );
    if (object.moyen != null) {
      yield r'moyen';
      yield serializers.serialize(
        object.moyen,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'retenue_vendeur_unites';
    yield serializers.serialize(
      object.retenueVendeurUnites,
      specifiedType: const FullType(int),
    );
    yield r'total_du_unites';
    yield serializers.serialize(
      object.totalDuUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RecuCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RecuCommandeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'deja_regle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.dejaRegle = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'frais_livraison_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.fraisLivraisonUnites = valueDes;
          break;
        case r'lignes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneRecu)]),
          ) as BuiltList<LigneRecu>;
          result.lignes.replace(valueDes);
          break;
        case r'mode_paiement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.modePaiement = valueDes;
          break;
        case r'montant_a_remettre_au_coursier_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantARemettreAuCoursierUnites = valueDes;
          break;
        case r'montant_articles_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantArticlesUnites = valueDes;
          break;
        case r'moyen':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.moyen = valueDes;
          break;
        case r'retenue_vendeur_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.retenueVendeurUnites = valueDes;
          break;
        case r'total_du_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalDuUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RecuCommande deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RecuCommandeBuilder();
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

