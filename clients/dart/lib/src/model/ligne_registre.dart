//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_registre.g.dart';

/// Une ligne du registre.
///
/// Properties:
/// * [commandeId] - Commande rapprochée — le rapprochement se lit sans jointure manuelle.
/// * [devise] - Devise ISO 4217.
/// * [etat] - État de la transaction.
/// * [fournisseur] - Fournisseur qui a encaissé.
/// * [id] - Transaction.
/// * [issueLe] - Issue définitive.
/// * [montantUnites] - Montant figé.
/// * [moyen] - Moyen employé — `inconnu` tant que le fournisseur ne l'a pas dit.
/// * [orpheline] - De l'argent encaissé qu'aucune commande vivante n'attend (FR-082).
/// * [ouverteLe] - Ouverture.
/// * [referenceFournisseur] - Référence côté fournisseur — le rapprochement dans l'AUTRE sens.
@BuiltValue()
abstract class LigneRegistre implements Built<LigneRegistre, LigneRegistreBuilder> {
  /// Commande rapprochée — le rapprochement se lit sans jointure manuelle.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// État de la transaction.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Fournisseur qui a encaissé.
  @BuiltValueField(wireName: r'fournisseur')
  String get fournisseur;

  /// Transaction.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Issue définitive.
  @BuiltValueField(wireName: r'issue_le')
  DateTime? get issueLe;

  /// Montant figé.
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// Moyen employé — `inconnu` tant que le fournisseur ne l'a pas dit.
  @BuiltValueField(wireName: r'moyen')
  String get moyen;

  /// De l'argent encaissé qu'aucune commande vivante n'attend (FR-082).
  @BuiltValueField(wireName: r'orpheline')
  bool get orpheline;

  /// Ouverture.
  @BuiltValueField(wireName: r'ouverte_le')
  DateTime get ouverteLe;

  /// Référence côté fournisseur — le rapprochement dans l'AUTRE sens.
  @BuiltValueField(wireName: r'reference_fournisseur')
  String? get referenceFournisseur;

  LigneRegistre._();

  factory LigneRegistre([void updates(LigneRegistreBuilder b)]) = _$LigneRegistre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LigneRegistreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LigneRegistre> get serializer => _$LigneRegistreSerializer();
}

class _$LigneRegistreSerializer implements PrimitiveSerializer<LigneRegistre> {
  @override
  final Iterable<Type> types = const [LigneRegistre, _$LigneRegistre];

  @override
  final String wireName = r'LigneRegistre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LigneRegistre object, {
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
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'fournisseur';
    yield serializers.serialize(
      object.fournisseur,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.issueLe != null) {
      yield r'issue_le';
      yield serializers.serialize(
        object.issueLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'montant_unites';
    yield serializers.serialize(
      object.montantUnites,
      specifiedType: const FullType(int),
    );
    yield r'moyen';
    yield serializers.serialize(
      object.moyen,
      specifiedType: const FullType(String),
    );
    yield r'orpheline';
    yield serializers.serialize(
      object.orpheline,
      specifiedType: const FullType(bool),
    );
    yield r'ouverte_le';
    yield serializers.serialize(
      object.ouverteLe,
      specifiedType: const FullType(DateTime),
    );
    if (object.referenceFournisseur != null) {
      yield r'reference_fournisseur';
      yield serializers.serialize(
        object.referenceFournisseur,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    LigneRegistre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LigneRegistreBuilder result,
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
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'fournisseur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fournisseur = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'issue_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.issueLe = valueDes;
          break;
        case r'montant_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantUnites = valueDes;
          break;
        case r'moyen':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.moyen = valueDes;
          break;
        case r'orpheline':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.orpheline = valueDes;
          break;
        case r'ouverte_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.ouverteLe = valueDes;
          break;
        case r'reference_fournisseur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.referenceFournisseur = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LigneRegistre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LigneRegistreBuilder();
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

