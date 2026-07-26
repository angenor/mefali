//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_decision_substitution.g.dart';

/// Résultat d'une décision de substitution.
///
/// Properties:
/// * [devisPrixClientUnites] - Prix client du devis de livraison — **inchangé** (FR-050). Servi pour que le client le VOIE ne pas bouger, pas seulement pour l'affichage.
/// * [issue] - `acceptee` | `refusee`.
/// * [montantArticlesUnites] - Montant des articles après révision.
/// * [totalUnites] - Total à payer après révision.
@BuiltValue()
abstract class ResultatDecisionSubstitution implements Built<ResultatDecisionSubstitution, ResultatDecisionSubstitutionBuilder> {
  /// Prix client du devis de livraison — **inchangé** (FR-050). Servi pour que le client le VOIE ne pas bouger, pas seulement pour l'affichage.
  @BuiltValueField(wireName: r'devis_prix_client_unites')
  int get devisPrixClientUnites;

  /// `acceptee` | `refusee`.
  @BuiltValueField(wireName: r'issue')
  String get issue;

  /// Montant des articles après révision.
  @BuiltValueField(wireName: r'montant_articles_unites')
  int get montantArticlesUnites;

  /// Total à payer après révision.
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  ResultatDecisionSubstitution._();

  factory ResultatDecisionSubstitution([void updates(ResultatDecisionSubstitutionBuilder b)]) = _$ResultatDecisionSubstitution;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatDecisionSubstitutionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatDecisionSubstitution> get serializer => _$ResultatDecisionSubstitutionSerializer();
}

class _$ResultatDecisionSubstitutionSerializer implements PrimitiveSerializer<ResultatDecisionSubstitution> {
  @override
  final Iterable<Type> types = const [ResultatDecisionSubstitution, _$ResultatDecisionSubstitution];

  @override
  final String wireName = r'ResultatDecisionSubstitution';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatDecisionSubstitution object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'devis_prix_client_unites';
    yield serializers.serialize(
      object.devisPrixClientUnites,
      specifiedType: const FullType(int),
    );
    yield r'issue';
    yield serializers.serialize(
      object.issue,
      specifiedType: const FullType(String),
    );
    yield r'montant_articles_unites';
    yield serializers.serialize(
      object.montantArticlesUnites,
      specifiedType: const FullType(int),
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
    ResultatDecisionSubstitution object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatDecisionSubstitutionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'devis_prix_client_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.devisPrixClientUnites = valueDes;
          break;
        case r'issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.issue = valueDes;
          break;
        case r'montant_articles_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantArticlesUnites = valueDes;
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
  ResultatDecisionSubstitution deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatDecisionSubstitutionBuilder();
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

