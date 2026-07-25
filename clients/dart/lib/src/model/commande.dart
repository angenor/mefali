//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/livraison_commande.dart';
import 'package:mefali_api_client/src/model/paiement_commande.dart';
import 'package:mefali_api_client/src/model/secrets_remise.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'commande.g.dart';

/// Commande créée.
///
/// Properties:
/// * [devise] - Devise ISO 4217.
/// * [etat] - État de très haut niveau.
/// * [id] - Identifiant (= `Idempotency-Key`).
/// * [livraison] - Livraison.
/// * [montantArticlesUnites] - Montant des articles.
/// * [paiement] - Paiement.
/// * [remise] - Code et jeton de remise.
/// * [totalUnites] - Total à payer.
@BuiltValue()
abstract class Commande implements Built<Commande, CommandeBuilder> {
  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// État de très haut niveau.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Identifiant (= `Idempotency-Key`).
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Livraison.
  @BuiltValueField(wireName: r'livraison')
  LivraisonCommande get livraison;

  /// Montant des articles.
  @BuiltValueField(wireName: r'montant_articles_unites')
  int get montantArticlesUnites;

  /// Paiement.
  @BuiltValueField(wireName: r'paiement')
  PaiementCommande get paiement;

  /// Code et jeton de remise.
  @BuiltValueField(wireName: r'remise')
  SecretsRemise get remise;

  /// Total à payer.
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  Commande._();

  factory Commande([void updates(CommandeBuilder b)]) = _$Commande;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CommandeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Commande> get serializer => _$CommandeSerializer();
}

class _$CommandeSerializer implements PrimitiveSerializer<Commande> {
  @override
  final Iterable<Type> types = const [Commande, _$Commande];

  @override
  final String wireName = r'Commande';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Commande object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'livraison';
    yield serializers.serialize(
      object.livraison,
      specifiedType: const FullType(LivraisonCommande),
    );
    yield r'montant_articles_unites';
    yield serializers.serialize(
      object.montantArticlesUnites,
      specifiedType: const FullType(int),
    );
    yield r'paiement';
    yield serializers.serialize(
      object.paiement,
      specifiedType: const FullType(PaiementCommande),
    );
    yield r'remise';
    yield serializers.serialize(
      object.remise,
      specifiedType: const FullType(SecretsRemise),
    );
    yield r'total_unites';
    yield serializers.serialize(
      object.totalUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Commande object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CommandeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'livraison':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LivraisonCommande),
          ) as LivraisonCommande;
          result.livraison.replace(valueDes);
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
            specifiedType: const FullType(PaiementCommande),
          ) as PaiementCommande;
          result.paiement.replace(valueDes);
          break;
        case r'remise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SecretsRemise),
          ) as SecretsRemise;
          result.remise.replace(valueDes);
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
  Commande deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CommandeBuilder();
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

