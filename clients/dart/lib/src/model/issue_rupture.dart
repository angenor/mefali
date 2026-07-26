//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'issue_rupture.g.dart';

/// Issue immédiate d'une rupture déclarée.
///
/// Properties:
/// * [ecartPourcent] - Écart de prix en pourcent (signé).
/// * [issue] - `ligne_retiree` | `proposition_ouverte`.
/// * [montantArticlesUnites] - Montant des articles après révision.
/// * [montantRetire] - Montant sorti du total (`null` si une proposition a été ouverte).
/// * [resteS] - Secondes dont dispose le client pour décider.
/// * [substitutionId] - Proposition créée (`null` si l'article a été retiré).
/// * [totalUnites] - Total après révision — **le devis de livraison n'a pas bougé** (FR-050).
@BuiltValue()
abstract class IssueRupture implements Built<IssueRupture, IssueRuptureBuilder> {
  /// Écart de prix en pourcent (signé).
  @BuiltValueField(wireName: r'ecart_pourcent')
  int? get ecartPourcent;

  /// `ligne_retiree` | `proposition_ouverte`.
  @BuiltValueField(wireName: r'issue')
  String get issue;

  /// Montant des articles après révision.
  @BuiltValueField(wireName: r'montant_articles_unites')
  int? get montantArticlesUnites;

  /// Montant sorti du total (`null` si une proposition a été ouverte).
  @BuiltValueField(wireName: r'montant_retire')
  int? get montantRetire;

  /// Secondes dont dispose le client pour décider.
  @BuiltValueField(wireName: r'reste_s')
  int? get resteS;

  /// Proposition créée (`null` si l'article a été retiré).
  @BuiltValueField(wireName: r'substitution_id')
  String? get substitutionId;

  /// Total après révision — **le devis de livraison n'a pas bougé** (FR-050).
  @BuiltValueField(wireName: r'total_unites')
  int? get totalUnites;

  IssueRupture._();

  factory IssueRupture([void updates(IssueRuptureBuilder b)]) = _$IssueRupture;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IssueRuptureBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IssueRupture> get serializer => _$IssueRuptureSerializer();
}

class _$IssueRuptureSerializer implements PrimitiveSerializer<IssueRupture> {
  @override
  final Iterable<Type> types = const [IssueRupture, _$IssueRupture];

  @override
  final String wireName = r'IssueRupture';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IssueRupture object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.ecartPourcent != null) {
      yield r'ecart_pourcent';
      yield serializers.serialize(
        object.ecartPourcent,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'issue';
    yield serializers.serialize(
      object.issue,
      specifiedType: const FullType(String),
    );
    if (object.montantArticlesUnites != null) {
      yield r'montant_articles_unites';
      yield serializers.serialize(
        object.montantArticlesUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.montantRetire != null) {
      yield r'montant_retire';
      yield serializers.serialize(
        object.montantRetire,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.resteS != null) {
      yield r'reste_s';
      yield serializers.serialize(
        object.resteS,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.substitutionId != null) {
      yield r'substitution_id';
      yield serializers.serialize(
        object.substitutionId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.totalUnites != null) {
      yield r'total_unites';
      yield serializers.serialize(
        object.totalUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    IssueRupture object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IssueRuptureBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ecart_pourcent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.ecartPourcent = valueDes;
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
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.montantArticlesUnites = valueDes;
          break;
        case r'montant_retire':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.montantRetire = valueDes;
          break;
        case r'reste_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.resteS = valueDes;
          break;
        case r'substitution_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.substitutionId = valueDes;
          break;
        case r'total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
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
  IssueRupture deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IssueRuptureBuilder();
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

