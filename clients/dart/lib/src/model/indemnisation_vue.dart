//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'indemnisation_vue.g.dart';

/// Une indemnisation, telle que la caisse l'affiche.
///
/// Properties:
/// * [commandeId] - Commande d'origine.
/// * [commandeReference] - Référence lisible de la commande.
/// * [creeLe] - Naissance de la demande.
/// * [decideLe] - Quand la décision a été prise.
/// * [decisionMotifCle] - Clé i18n du motif de décision (refus surtout).
/// * [devise] - Devise ISO 4217.
/// * [etat] - `demandee` | `validee` | `refusee`.
/// * [id] - Indemnisation.
/// * [litigeId] - Litige rattaché — **absent** tant qu'AVI-04 n'existe pas (R16).
/// * [montantUnites] - Montant (unités mineures, positif).
/// * [motifCle] - Clé i18n du motif.
@BuiltValue()
abstract class IndemnisationVue implements Built<IndemnisationVue, IndemnisationVueBuilder> {
  /// Commande d'origine.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Référence lisible de la commande.
  @BuiltValueField(wireName: r'commande_reference')
  String get commandeReference;

  /// Naissance de la demande.
  @BuiltValueField(wireName: r'cree_le')
  DateTime get creeLe;

  /// Quand la décision a été prise.
  @BuiltValueField(wireName: r'decide_le')
  DateTime? get decideLe;

  /// Clé i18n du motif de décision (refus surtout).
  @BuiltValueField(wireName: r'decision_motif_cle')
  String? get decisionMotifCle;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// `demandee` | `validee` | `refusee`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Indemnisation.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Litige rattaché — **absent** tant qu'AVI-04 n'existe pas (R16).
  @BuiltValueField(wireName: r'litige_id')
  String? get litigeId;

  /// Montant (unités mineures, positif).
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// Clé i18n du motif.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  IndemnisationVue._();

  factory IndemnisationVue([void updates(IndemnisationVueBuilder b)]) = _$IndemnisationVue;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IndemnisationVueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IndemnisationVue> get serializer => _$IndemnisationVueSerializer();
}

class _$IndemnisationVueSerializer implements PrimitiveSerializer<IndemnisationVue> {
  @override
  final Iterable<Type> types = const [IndemnisationVue, _$IndemnisationVue];

  @override
  final String wireName = r'IndemnisationVue';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IndemnisationVue object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'commande_reference';
    yield serializers.serialize(
      object.commandeReference,
      specifiedType: const FullType(String),
    );
    yield r'cree_le';
    yield serializers.serialize(
      object.creeLe,
      specifiedType: const FullType(DateTime),
    );
    if (object.decideLe != null) {
      yield r'decide_le';
      yield serializers.serialize(
        object.decideLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.decisionMotifCle != null) {
      yield r'decision_motif_cle';
      yield serializers.serialize(
        object.decisionMotifCle,
        specifiedType: const FullType.nullable(String),
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
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.litigeId != null) {
      yield r'litige_id';
      yield serializers.serialize(
        object.litigeId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'montant_unites';
    yield serializers.serialize(
      object.montantUnites,
      specifiedType: const FullType(int),
    );
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IndemnisationVue object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IndemnisationVueBuilder result,
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
        case r'commande_reference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeReference = valueDes;
          break;
        case r'cree_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.creeLe = valueDes;
          break;
        case r'decide_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.decideLe = valueDes;
          break;
        case r'decision_motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.decisionMotifCle = valueDes;
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'litige_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.litigeId = valueDes;
          break;
        case r'montant_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantUnites = valueDes;
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motifCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IndemnisationVue deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IndemnisationVueBuilder();
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

