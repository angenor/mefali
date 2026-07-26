//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_annulation.g.dart';

/// Ce qu'une annulation a produit.
///
/// Properties:
/// * [commandeId] - Commande annulée.
/// * [devise] - Devise ISO 4217.
/// * [montantAvance] - Montant déjà avancé chez les vendeurs.
/// * [partCoursierDue] - Part due au coursier (unités mineures) — 0 si sans frais.
/// * [remboursementDu] - Vrai si la commande était prépayée : un remboursement est dû.
/// * [sansFrais] - Vrai si rien n'avait encore été acheté : annulation SANS FRAIS.
@BuiltValue()
abstract class ResultatAnnulation implements Built<ResultatAnnulation, ResultatAnnulationBuilder> {
  /// Commande annulée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Montant déjà avancé chez les vendeurs.
  @BuiltValueField(wireName: r'montant_avance')
  int get montantAvance;

  /// Part due au coursier (unités mineures) — 0 si sans frais.
  @BuiltValueField(wireName: r'part_coursier_due')
  int get partCoursierDue;

  /// Vrai si la commande était prépayée : un remboursement est dû.
  @BuiltValueField(wireName: r'remboursement_du')
  bool get remboursementDu;

  /// Vrai si rien n'avait encore été acheté : annulation SANS FRAIS.
  @BuiltValueField(wireName: r'sans_frais')
  bool get sansFrais;

  ResultatAnnulation._();

  factory ResultatAnnulation([void updates(ResultatAnnulationBuilder b)]) = _$ResultatAnnulation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatAnnulationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatAnnulation> get serializer => _$ResultatAnnulationSerializer();
}

class _$ResultatAnnulationSerializer implements PrimitiveSerializer<ResultatAnnulation> {
  @override
  final Iterable<Type> types = const [ResultatAnnulation, _$ResultatAnnulation];

  @override
  final String wireName = r'ResultatAnnulation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatAnnulation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'montant_avance';
    yield serializers.serialize(
      object.montantAvance,
      specifiedType: const FullType(int),
    );
    yield r'part_coursier_due';
    yield serializers.serialize(
      object.partCoursierDue,
      specifiedType: const FullType(int),
    );
    yield r'remboursement_du';
    yield serializers.serialize(
      object.remboursementDu,
      specifiedType: const FullType(bool),
    );
    yield r'sans_frais';
    yield serializers.serialize(
      object.sansFrais,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResultatAnnulation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatAnnulationBuilder result,
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
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'montant_avance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantAvance = valueDes;
          break;
        case r'part_coursier_due':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.partCoursierDue = valueDes;
          break;
        case r'remboursement_du':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.remboursementDu = valueDes;
          break;
        case r'sans_frais':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.sansFrais = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResultatAnnulation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatAnnulationBuilder();
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

