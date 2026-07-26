//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/position_suivi.dart';
import 'package:mefali_api_client/src/model/progression_suivi.dart';
import 'package:mefali_api_client/src/model/secrets_remise.dart';
import 'package:mefali_api_client/src/model/substitution_suivi.dart';
import 'package:mefali_api_client/src/model/coursier_suivi.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'suivi_commande.g.dart';

/// Vue de suivi complète (contrat §1.3).
///
/// Properties:
/// * [coursier] - Coursier affecté.
/// * [devise] - Devise ISO 4217.
/// * [etat] - État de très haut niveau.
/// * [etatCle] - **Clé i18n** de l'état affiché — jamais une phrase (constitution VII).
/// * [etatLe] - Instant du dernier changement d'état.
/// * [id] - Commande.
/// * [livraisonEtat] - État logistique.
/// * [livraisonId] - Livraison, si la commande en a une (composant 0..n).
/// * [montantArticlesUnites] - Montant des articles (révisé si des articles ont sauté).
/// * [position] - Dernière position connue — `null` si aucune (research R13).
/// * [progression] - Progression par arrêt.
/// * [remise] - Code et QR de remise — **propriétaire seul** (R6).
/// * [substitutionEnAttente] - Proposition de remplacement ouverte.
/// * [totalUnites] - Total à payer.
@BuiltValue()
abstract class SuiviCommande implements Built<SuiviCommande, SuiviCommandeBuilder> {
  /// Coursier affecté.
  @BuiltValueField(wireName: r'coursier')
  CoursierSuivi? get coursier;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// État de très haut niveau.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// **Clé i18n** de l'état affiché — jamais une phrase (constitution VII).
  @BuiltValueField(wireName: r'etat_cle')
  String get etatCle;

  /// Instant du dernier changement d'état.
  @BuiltValueField(wireName: r'etat_le')
  DateTime get etatLe;

  /// Commande.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// État logistique.
  @BuiltValueField(wireName: r'livraison_etat')
  String? get livraisonEtat;

  /// Livraison, si la commande en a une (composant 0..n).
  @BuiltValueField(wireName: r'livraison_id')
  String? get livraisonId;

  /// Montant des articles (révisé si des articles ont sauté).
  @BuiltValueField(wireName: r'montant_articles_unites')
  int get montantArticlesUnites;

  /// Dernière position connue — `null` si aucune (research R13).
  @BuiltValueField(wireName: r'position')
  PositionSuivi? get position;

  /// Progression par arrêt.
  @BuiltValueField(wireName: r'progression')
  ProgressionSuivi get progression;

  /// Code et QR de remise — **propriétaire seul** (R6).
  @BuiltValueField(wireName: r'remise')
  SecretsRemise get remise;

  /// Proposition de remplacement ouverte.
  @BuiltValueField(wireName: r'substitution_en_attente')
  SubstitutionSuivi? get substitutionEnAttente;

  /// Total à payer.
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  SuiviCommande._();

  factory SuiviCommande([void updates(SuiviCommandeBuilder b)]) = _$SuiviCommande;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SuiviCommandeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SuiviCommande> get serializer => _$SuiviCommandeSerializer();
}

class _$SuiviCommandeSerializer implements PrimitiveSerializer<SuiviCommande> {
  @override
  final Iterable<Type> types = const [SuiviCommande, _$SuiviCommande];

  @override
  final String wireName = r'SuiviCommande';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SuiviCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.coursier != null) {
      yield r'coursier';
      yield serializers.serialize(
        object.coursier,
        specifiedType: const FullType.nullable(CoursierSuivi),
      );
    }
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
    yield r'etat_cle';
    yield serializers.serialize(
      object.etatCle,
      specifiedType: const FullType(String),
    );
    yield r'etat_le';
    yield serializers.serialize(
      object.etatLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.livraisonEtat != null) {
      yield r'livraison_etat';
      yield serializers.serialize(
        object.livraisonEtat,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.livraisonId != null) {
      yield r'livraison_id';
      yield serializers.serialize(
        object.livraisonId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'montant_articles_unites';
    yield serializers.serialize(
      object.montantArticlesUnites,
      specifiedType: const FullType(int),
    );
    if (object.position != null) {
      yield r'position';
      yield serializers.serialize(
        object.position,
        specifiedType: const FullType.nullable(PositionSuivi),
      );
    }
    yield r'progression';
    yield serializers.serialize(
      object.progression,
      specifiedType: const FullType(ProgressionSuivi),
    );
    yield r'remise';
    yield serializers.serialize(
      object.remise,
      specifiedType: const FullType(SecretsRemise),
    );
    if (object.substitutionEnAttente != null) {
      yield r'substitution_en_attente';
      yield serializers.serialize(
        object.substitutionEnAttente,
        specifiedType: const FullType.nullable(SubstitutionSuivi),
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
    SuiviCommande object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SuiviCommandeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'coursier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CoursierSuivi),
          ) as CoursierSuivi?;
          if (valueDes == null) continue;
          result.coursier.replace(valueDes);
          break;
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
        case r'etat_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etatCle = valueDes;
          break;
        case r'etat_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.etatLe = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'livraison_etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.livraisonEtat = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.livraisonId = valueDes;
          break;
        case r'montant_articles_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantArticlesUnites = valueDes;
          break;
        case r'position':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PositionSuivi),
          ) as PositionSuivi?;
          if (valueDes == null) continue;
          result.position.replace(valueDes);
          break;
        case r'progression':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProgressionSuivi),
          ) as ProgressionSuivi;
          result.progression.replace(valueDes);
          break;
        case r'remise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SecretsRemise),
          ) as SecretsRemise;
          result.remise.replace(valueDes);
          break;
        case r'substitution_en_attente':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SubstitutionSuivi),
          ) as SubstitutionSuivi?;
          if (valueDes == null) continue;
          result.substitutionEnAttente.replace(valueDes);
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
  SuiviCommande deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SuiviCommandeBuilder();
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

