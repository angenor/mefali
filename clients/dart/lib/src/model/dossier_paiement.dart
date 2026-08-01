//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dossier_paiement.g.dart';

/// Un dossier d'anomalie.
///
/// Properties:
/// * [arretId] - Arrêt concerné (retenue écrêtée).
/// * [closLe] - Clôture.
/// * [closMotifCle] - Motif de clôture — clé i18n également.
/// * [commandeId] - Commande concernée.
/// * [devise] - Devise ISO 4217.
/// * [etat] - `ouvert` | `clos`.
/// * [id] - Dossier.
/// * [montantAttendu] - Montant attendu.
/// * [montantConstate] - Montant constaté.
/// * [motifCle] - Motif — **clé i18n**, jamais un texte libre.
/// * [ouvertLe] - Ouverture.
/// * [transactionId] - Transaction concernée.
/// * [type] - Famille d'anomalie.
@BuiltValue()
abstract class DossierPaiement implements Built<DossierPaiement, DossierPaiementBuilder> {
  /// Arrêt concerné (retenue écrêtée).
  @BuiltValueField(wireName: r'arret_id')
  String? get arretId;

  /// Clôture.
  @BuiltValueField(wireName: r'clos_le')
  DateTime? get closLe;

  /// Motif de clôture — clé i18n également.
  @BuiltValueField(wireName: r'clos_motif_cle')
  String? get closMotifCle;

  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String? get commandeId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String? get devise;

  /// `ouvert` | `clos`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Dossier.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Montant attendu.
  @BuiltValueField(wireName: r'montant_attendu')
  int? get montantAttendu;

  /// Montant constaté.
  @BuiltValueField(wireName: r'montant_constate')
  int? get montantConstate;

  /// Motif — **clé i18n**, jamais un texte libre.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  /// Ouverture.
  @BuiltValueField(wireName: r'ouvert_le')
  DateTime get ouvertLe;

  /// Transaction concernée.
  @BuiltValueField(wireName: r'transaction_id')
  String? get transactionId;

  /// Famille d'anomalie.
  @BuiltValueField(wireName: r'type')
  String get type;

  DossierPaiement._();

  factory DossierPaiement([void updates(DossierPaiementBuilder b)]) = _$DossierPaiement;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DossierPaiementBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DossierPaiement> get serializer => _$DossierPaiementSerializer();
}

class _$DossierPaiementSerializer implements PrimitiveSerializer<DossierPaiement> {
  @override
  final Iterable<Type> types = const [DossierPaiement, _$DossierPaiement];

  @override
  final String wireName = r'DossierPaiement';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DossierPaiement object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.arretId != null) {
      yield r'arret_id';
      yield serializers.serialize(
        object.arretId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.closLe != null) {
      yield r'clos_le';
      yield serializers.serialize(
        object.closLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.closMotifCle != null) {
      yield r'clos_motif_cle';
      yield serializers.serialize(
        object.closMotifCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.commandeId != null) {
      yield r'commande_id';
      yield serializers.serialize(
        object.commandeId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.devise != null) {
      yield r'devise';
      yield serializers.serialize(
        object.devise,
        specifiedType: const FullType.nullable(String),
      );
    }
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
    if (object.montantAttendu != null) {
      yield r'montant_attendu';
      yield serializers.serialize(
        object.montantAttendu,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.montantConstate != null) {
      yield r'montant_constate';
      yield serializers.serialize(
        object.montantConstate,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
    yield r'ouvert_le';
    yield serializers.serialize(
      object.ouvertLe,
      specifiedType: const FullType(DateTime),
    );
    if (object.transactionId != null) {
      yield r'transaction_id';
      yield serializers.serialize(
        object.transactionId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DossierPaiement object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DossierPaiementBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.arretId = valueDes;
          break;
        case r'clos_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.closLe = valueDes;
          break;
        case r'clos_motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.closMotifCle = valueDes;
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.commandeId = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
        case r'montant_attendu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.montantAttendu = valueDes;
          break;
        case r'montant_constate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.montantConstate = valueDes;
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motifCle = valueDes;
          break;
        case r'ouvert_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.ouvertLe = valueDes;
          break;
        case r'transaction_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.transactionId = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DossierPaiement deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DossierPaiementBuilder();
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

