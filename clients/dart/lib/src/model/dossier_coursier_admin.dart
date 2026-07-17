//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/vehicule_declare.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dossier_coursier_admin.g.dart';

/// Dossier complet pour la revue admin (contrat `DossierCoursierAdmin`).
///
/// Properties:
/// * [compteId] - Compte du coursier.
/// * [motif] - Motif de la dernière décision admin.
/// * [pieceUrl] - URL présignée de la pièce (TTL 10 min) — DÉTAIL uniquement, absente en liste : présigner N pièces pour un tableau serait du gaspillage, et autant de liens vivants qu'aucun œil n'ouvrira.
/// * [referentNom] - Référent local.
/// * [referentTelephoneE164] - Téléphone du référent.
/// * [soumisLe] - Dernier dépôt.
/// * [statut] - Statut = celui de l'attribution `coursier`.
/// * [telephoneE164] - Numéro du coursier — l'admin doit pouvoir le rappeler (FR-017).
/// * [vehicules] - Véhicules déclarés.
@BuiltValue()
abstract class DossierCoursierAdmin implements Built<DossierCoursierAdmin, DossierCoursierAdminBuilder> {
  /// Compte du coursier.
  @BuiltValueField(wireName: r'compte_id')
  String get compteId;

  /// Motif de la dernière décision admin.
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  /// URL présignée de la pièce (TTL 10 min) — DÉTAIL uniquement, absente en liste : présigner N pièces pour un tableau serait du gaspillage, et autant de liens vivants qu'aucun œil n'ouvrira.
  @BuiltValueField(wireName: r'piece_url')
  String? get pieceUrl;

  /// Référent local.
  @BuiltValueField(wireName: r'referent_nom')
  String get referentNom;

  /// Téléphone du référent.
  @BuiltValueField(wireName: r'referent_telephone_e164')
  String get referentTelephoneE164;

  /// Dernier dépôt.
  @BuiltValueField(wireName: r'soumis_le')
  DateTime get soumisLe;

  /// Statut = celui de l'attribution `coursier`.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  /// Numéro du coursier — l'admin doit pouvoir le rappeler (FR-017).
  @BuiltValueField(wireName: r'telephone_e164')
  String get telephoneE164;

  /// Véhicules déclarés.
  @BuiltValueField(wireName: r'vehicules')
  BuiltList<VehiculeDeclare> get vehicules;

  DossierCoursierAdmin._();

  factory DossierCoursierAdmin([void updates(DossierCoursierAdminBuilder b)]) = _$DossierCoursierAdmin;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DossierCoursierAdminBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DossierCoursierAdmin> get serializer => _$DossierCoursierAdminSerializer();
}

class _$DossierCoursierAdminSerializer implements PrimitiveSerializer<DossierCoursierAdmin> {
  @override
  final Iterable<Type> types = const [DossierCoursierAdmin, _$DossierCoursierAdmin];

  @override
  final String wireName = r'DossierCoursierAdmin';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DossierCoursierAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'compte_id';
    yield serializers.serialize(
      object.compteId,
      specifiedType: const FullType(String),
    );
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.pieceUrl != null) {
      yield r'piece_url';
      yield serializers.serialize(
        object.pieceUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'referent_nom';
    yield serializers.serialize(
      object.referentNom,
      specifiedType: const FullType(String),
    );
    yield r'referent_telephone_e164';
    yield serializers.serialize(
      object.referentTelephoneE164,
      specifiedType: const FullType(String),
    );
    yield r'soumis_le';
    yield serializers.serialize(
      object.soumisLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
    yield r'telephone_e164';
    yield serializers.serialize(
      object.telephoneE164,
      specifiedType: const FullType(String),
    );
    yield r'vehicules';
    yield serializers.serialize(
      object.vehicules,
      specifiedType: const FullType(BuiltList, [FullType(VehiculeDeclare)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DossierCoursierAdmin object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DossierCoursierAdminBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'compte_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.compteId = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motif = valueDes;
          break;
        case r'piece_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.pieceUrl = valueDes;
          break;
        case r'referent_nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.referentNom = valueDes;
          break;
        case r'referent_telephone_e164':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.referentTelephoneE164 = valueDes;
          break;
        case r'soumis_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.soumisLe = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        case r'telephone_e164':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.telephoneE164 = valueDes;
          break;
        case r'vehicules':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VehiculeDeclare)]),
          ) as BuiltList<VehiculeDeclare>;
          result.vehicules.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DossierCoursierAdmin deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DossierCoursierAdminBuilder();
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

