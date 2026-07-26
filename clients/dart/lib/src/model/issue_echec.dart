//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'issue_echec.g.dart';

/// Une issue de l'arbre §7.5, telle qu'elle est enregistrée.
///
/// Properties:
/// * [commandeId] - Commande concernée.
/// * [detenteurArgent] - Qui détient l'ARGENT.
/// * [detenteurMarchandise] - Qui détient la MARCHANDISE — axe indépendant du précédent (R14).
/// * [devise] - Devise ISO 4217.
/// * [indemnisationDue] - Le coursier doit être indemnisé (contrat CRS-06).
/// * [issueId] - Identifiant de l'issue.
/// * [litigeOuvert] - Un litige est ouvert (contrat AVI-04).
/// * [montantEnJeuUnites] - Montant en jeu (unités mineures).
/// * [relivraisonId] - Commande de re-livraison créée (§7.5-10 seulement).
/// * [sanction] - Sanction effectivement posée sur le compte client.
@BuiltValue()
abstract class IssueEchec implements Built<IssueEchec, IssueEchecBuilder> {
  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Qui détient l'ARGENT.
  @BuiltValueField(wireName: r'detenteur_argent')
  String get detenteurArgent;

  /// Qui détient la MARCHANDISE — axe indépendant du précédent (R14).
  @BuiltValueField(wireName: r'detenteur_marchandise')
  String get detenteurMarchandise;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Le coursier doit être indemnisé (contrat CRS-06).
  @BuiltValueField(wireName: r'indemnisation_due')
  bool get indemnisationDue;

  /// Identifiant de l'issue.
  @BuiltValueField(wireName: r'issue_id')
  String get issueId;

  /// Un litige est ouvert (contrat AVI-04).
  @BuiltValueField(wireName: r'litige_ouvert')
  bool get litigeOuvert;

  /// Montant en jeu (unités mineures).
  @BuiltValueField(wireName: r'montant_en_jeu_unites')
  int get montantEnJeuUnites;

  /// Commande de re-livraison créée (§7.5-10 seulement).
  @BuiltValueField(wireName: r'relivraison_id')
  String? get relivraisonId;

  /// Sanction effectivement posée sur le compte client.
  @BuiltValueField(wireName: r'sanction')
  String get sanction;

  IssueEchec._();

  factory IssueEchec([void updates(IssueEchecBuilder b)]) = _$IssueEchec;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IssueEchecBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IssueEchec> get serializer => _$IssueEchecSerializer();
}

class _$IssueEchecSerializer implements PrimitiveSerializer<IssueEchec> {
  @override
  final Iterable<Type> types = const [IssueEchec, _$IssueEchec];

  @override
  final String wireName = r'IssueEchec';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IssueEchec object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'detenteur_argent';
    yield serializers.serialize(
      object.detenteurArgent,
      specifiedType: const FullType(String),
    );
    yield r'detenteur_marchandise';
    yield serializers.serialize(
      object.detenteurMarchandise,
      specifiedType: const FullType(String),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'indemnisation_due';
    yield serializers.serialize(
      object.indemnisationDue,
      specifiedType: const FullType(bool),
    );
    yield r'issue_id';
    yield serializers.serialize(
      object.issueId,
      specifiedType: const FullType(String),
    );
    yield r'litige_ouvert';
    yield serializers.serialize(
      object.litigeOuvert,
      specifiedType: const FullType(bool),
    );
    yield r'montant_en_jeu_unites';
    yield serializers.serialize(
      object.montantEnJeuUnites,
      specifiedType: const FullType(int),
    );
    if (object.relivraisonId != null) {
      yield r'relivraison_id';
      yield serializers.serialize(
        object.relivraisonId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'sanction';
    yield serializers.serialize(
      object.sanction,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IssueEchec object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IssueEchecBuilder result,
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
        case r'detenteur_argent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.detenteurArgent = valueDes;
          break;
        case r'detenteur_marchandise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.detenteurMarchandise = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'indemnisation_due':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.indemnisationDue = valueDes;
          break;
        case r'issue_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.issueId = valueDes;
          break;
        case r'litige_ouvert':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.litigeOuvert = valueDes;
          break;
        case r'montant_en_jeu_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantEnJeuUnites = valueDes;
          break;
        case r'relivraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.relivraisonId = valueDes;
          break;
        case r'sanction':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sanction = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IssueEchec deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IssueEchecBuilder();
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

